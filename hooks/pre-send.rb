#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require 'json'
require 'optparse'
require 'shellwords'
require 'time'

module Nomos
  module PreSend
    CURSOR_PASS = { permission: 'allow' }.freeze

    def self.warning(message, harness:, output:, error:, check: false)
      text = "NOMOS pre-send warning: #{message}; #{check ? 'check incomplete' : 'command passed unchecked'}."
      text += ' Run --check on the resolved body file.' unless check
      begin
        error.puts text
      rescue IOError, SystemCallError
        nil
      end
      begin
        if !check && harness == 'cursor'
          output.puts JSON.generate(CURSOR_PASS.merge(agent_message: text, user_message: text))
        elsif !check && %w[claude codex].include?(harness)
          output.puts JSON.generate(hookSpecificOutput: { hookEventName: 'PreToolUse', additionalContext: text })
        end
      rescue IOError, SystemCallError
        nil
      end
      check ? 2 : 0
    end

    major, minor = RUBY_VERSION.split('.').map(&:to_i)
    if major < 3 || (major == 3 && minor < 2)
      harness_arg = ARGV.find { |arg| arg.start_with?('--harness=') }
      harness_index = ARGV.index('--harness')
      harness = harness_arg ? harness_arg.split('=', 2).last : (harness_index && ARGV[harness_index + 1])
      check = ARGV.any? { |arg| arg == '--check' || arg.start_with?('--check=') }
      exit warning("Ruby 3.2 or later is required (running #{RUBY_VERSION})",
                   harness: harness, output: $stdout, error: $stderr, check: check)
    end

    ROOT = File.expand_path('..', __dir__)
    CONFIRMATION = 'NOMOS_PRESEND_CONFIRMED'
    FOOTER = /^nomos v\d+ [a-z][a-z ]*$/
    MULTIPART = %w[first-prompt handover plan-review].freeze
    RELATIVE = [
      'today', 'tomorrow', 'yesterday', 'tonight', 'this morning', 'this afternoon', 'this evening',
      'last night', 'next week', 'last week', 'this week', 'next month', 'last month', 'this month',
      'next year', 'last year', 'this year', 'next Monday', 'next Tuesday', 'next Wednesday',
      'next Thursday', 'next Friday', 'next Saturday', 'next Sunday'
    ].freeze
    ZONE = /(?:Z|UTC|GMT)(?:[+-]\d{2}(?::?\d{2})?)?|[+-]\d{2}(?::?\d{2})?/
    TIME = /(?<![\w:])(?!\d{2}:\d{2}-\d{2}:\d{2})(?:(\d{4}-\d{2}-\d{2})[T ])?(\d{2}):(\d{2})(?::(\d{2})(\.\d+)?)?\s*(#{ZONE})(?![\w:+-])/
    PLACEHOLDER = /(?<![$\\{])\{[\p{L}][\p{L}\p{N}\s_@.'?|\/-]*\}(?!\})/
    Flag = Data.define(:line, :kind, :text) do
      def to_s = "line #{line}: #{kind}: #{text.gsub(/\s+/, ' ')}"
    end

    def self.read_text(path, max_bytes: nil)
      raise IOError, "not a regular file: #{path}" unless File.file?(path)

      raise IOError, 'body file exceeds 64 KiB' if max_bytes && File.size(path) > max_bytes

      text = File.open(path, 'rb') { |file| max_bytes ? file.read(max_bytes + 1) : file.read }.force_encoding('UTF-8')
      raise IOError, 'body file exceeds 64 KiB' if max_bytes && text.bytesize > max_bytes
      raise IOError, "invalid UTF-8: #{path}" unless text.valid_encoding?

      text
    end

    def self.prose(body)
      fence = nil
      masked = body.lines.map do |line|
        if line.match?(/^\s*>/)
          line.gsub(/[^\n]/, ' ')
        elsif fence
          closing = /^ {0,3}#{Regexp.escape(fence[0])}{#{fence[1]},}\s*$/
          fence = nil if line.match?(closing)
          line.gsub(/[^\n]/, ' ')
        elsif (match = line.match(/^ {0,3}(`{3,}|~{3,})/))
          fence = [match[1][0], match[1].length]
          line.gsub(/[^\n]/, ' ')
        else
          line
        end
      end.join
      boundary = /\A(?:\s*\z| {0,3}\#+(?:\s|\z)| {0,3}(?:=+|-+)\s*\z)/
      masked.lines.slice_when { |before, after| before.match?(boundary) || after.match?(boundary) }.map do |block|
        block.join.gsub(/(?<!`)(`+)(?!`)(.*?)(?<!`)\1(?!`)/m) { |span| span.gsub(/[^\n]/, ' ') }
      end.join
    end

    class Checker
      def initialize(templates: File.join(ROOT, 'templates'), words: [], now: Time.now)
        @templates = templates
        @now = now
        terms = (RELATIVE + words).map(&:strip).reject(&:empty?).uniq
        @relative = /(?<![\p{L}\p{N}_])(?:#{terms.map { |term| Regexp.escape(term).gsub('\\ ', '\\s+') }.join('|')})(?![\p{L}\p{N}_])/i
      end

      def check(body)
        clean = PreSend.prose(body)
        line = 1
        @line_numbers = clean.each_char.map do |char|
          current = line
          line += 1 if char == "\n"
          current
        end
        @line_numbers << line
        flags = []
        clean.to_enum(:scan, PLACEHOLDER).each do
          match = Regexp.last_match
          flags << Flag.new(line_number(clean, match.begin(0)), 'placeholder', match[0])
        end
        relative_prose(clean).to_enum(:scan, @relative).each do
          match = Regexp.last_match
          flags << Flag.new(line_number(clean, match.begin(0)), 'relative time', match[0])
        end
        clean.to_enum(:scan, TIME).each do
          match = Regexp.last_match
          time = timestamp(match)
          next unless time && time > @now + 300
          next if time.to_date > @now.getlocal(time.utc_offset).to_date

          flags << Flag.new(line_number(clean, match.begin(0)), 'future time', match[0])
        end
        check_form(clean, flags)
        flags.sort_by { |flag| [flag.line, flag.kind, flag.text] }
      end

      private

      def line_number(_text, position) = @line_numbers.fetch(position)

      def relative_prose(clean)
        text = clean.gsub(/\b(?:examples?|e\.g\.|such as|built in)\s*\(([^()]*)\)/im) do |span|
          list = Regexp.last_match(1)
          rest = list.gsub(/\band the like\b.*\z/im, '').gsub(@relative, '').gsub(/\band\b/i, '').gsub(/[\s,;]+/, '')
          rest.empty? ? span.gsub(/[^\n]/, ' ') : span
        end
        text.gsub(/\b(?:never|no)\s+["“](today|tomorrow|yesterday|tonight)["”]/i) do |span|
          span.gsub(/[^\n]/, ' ')
        end
      end

      def timestamp(match)
        date, hour, minute, second, fraction, zone = match.captures
        offset = zone.sub(/\A(?:UTC|GMT|Z)/, '')
        offset = '+00:00' if offset.empty?
        offset += ':00' if offset.match?(/\A[+-]\d{2}\z/)
        offset = "#{offset[0..2]}:#{offset[3..4]}" if offset.match?(/\A[+-]\d{4}\z/)
        return unless offset[1..2].to_i < 24 && offset[-2..].to_i < 60
        return unless hour.to_i < 24 && minute.to_i < 60 && second.to_i < 60

        date ||= @now.getlocal(offset).strftime('%Y-%m-%d')
        Date.iso8601(date)
        Time.iso8601("#{date}T#{hour}:#{minute}:#{second || '00'}#{fraction}#{offset}")
      rescue ArgumentError
        nil
      end

      def check_form(clean, flags)
        lines = clean.lines.map(&:strip)
        footer_index = lines.rindex { |line| !line.empty? }
        return unless footer_index && lines[footer_index].match?(FOOTER)

        footer = lines[footer_index]
        paths = Dir.glob(File.join(@templates, '*.md')).sort
        raise IOError, "no templates in #{@templates}" if paths.empty?

        paths.each do |path|
          template = PreSend.read_text(path)
          sections = template.split(/^(nomos v\d+ [a-z][a-z ]*)\s*$/)
          index = sections.index(footer)
          next unless index
          return if MULTIPART.include?(File.basename(path, '.md'))

          form = sections[index - 1]
          headings = PreSend.prose(form).scan(/^\#{2,6}\s+(.+?)\s*#*$/).flatten
          headings.reject! { |heading| heading.include?('{') }
          if File.basename(path) == 'report.md' && template.include?('any section with nothing to say')
            headings = []
          else
            headings.reject! do |heading|
              optional_heading?(heading, template)
            end
          end
          present = clean.scan(/^\#{1,6}\s+(.+?)\s*#*$/).flatten.map { |heading| normalize(heading) }
          headings.each do |heading|
            next if present.include?(normalize(heading))

            flags << Flag.new(footer_index + 1, 'missing heading', heading)
          end
          check_findings(clean, flags) if File.basename(path) == 'review-findings.md'
          return
        end
      end

      def optional_heading?(heading, template)
        guidance = template.gsub(/^>\s?/, '').gsub(/\s+/, ' ')
        names = guidance.scan(/delete the section (?:on|for) (.+?)(?: in |[.,])/i).flatten
        words = ->(text) { normalize(text).split.reject { |word| %w[a an the for on].include?(word) }.map { |word| word.delete_suffix('s') } }
        names.any? { |name| words.call(name) == words.call(heading) }
      end

      def normalize(heading) = heading.downcase.strip.gsub(/\s+/, ' ')

      def check_findings(clean, flags)
        heading = clean.match(/^ {0,3}\#{2,6}[ \t]+Findings[ \t]*#*[ \t]*$/i)
        offset = heading ? heading.end(0) : 0
        content = clean[offset..].split(/^ {0,3}\#{2,6}[ \t]+/, 2).first.to_s
        rank = /\A\d+[.)]\s+(?:\*\*)?\[?(?:must-fix|suggestion)\b/i
        starts = []
        last_number = 0
        steps = false
        position = 0
        blank = false
        content.each_line do |line|
          start = position
          position += line.length
          previous_blank = blank
          blank = line.match?(/\A[ \t]*\n\z/)
          match = line.match(/\A(\d+)[.)][ \t]+[^\n]*/)
          next unless match

          ranked = match[0].match?(rank)
          steps = !ranked if match[1].to_i <= last_number
          if steps && match[1].to_i > last_number && previous_blank
            steps = false
          end
          next if steps && !ranked

          steps = false
          last_number = match[1].to_i
          starts << start
        end
        starts.each_with_index do |position, index|
          block = content[position...(starts[index + 1] || content.length)]
          line = line_number(clean, offset + position)
          title = block.lines.first.strip
          unless block.match?(rank)
            flags << Flag.new(line, 'finding missing rank', title)
          end
          unless block.match?(/\b(?:observed|code-grounded|sourced|hypothesis)\b/i)
            flags << Flag.new(line, 'finding missing evidence class', title)
          end
        end
      end
    end

    class Command
      SHELLS = %w[bash sh zsh dash fish ksh mksh tcsh csh su].freeze
      RAW_ESCAPE = /\\(?:[abefnrtv]|0[0-7]{1,3}|[0-7]{1,3}|x[0-9a-fA-F]{1,2}|u[0-9a-fA-F]{1,4}|U[0-9a-fA-F]{1,8})/
      RAW_INCOMPLETE = /(?:\A|[;|&(\n`]|#{RAW_ESCAPE})\s*(?:(?:command|builtin|exec|nohup|env|time|xargs|parallel)\s+)*(?:[^\s'";|&()]*\/)?['"]?keryx['"]?(?=\s*(?:\z|[;|&)`]))/
      RAW_SPACE = /(?:\s|\\\r?\n)+/
      RAW_WORD = /(?:[^\s'"\\;|&()]+|'[^']*'|"[^"\n]*"|\\[^\n])+/
      Limit = Class.new(StandardError)

      class Budget
        MAX_BYTES = 65_536
        MAX_DEPTH = 32
        MAX_TOKENS = 4096
        MAX_SECONDS = 0.2

        def initialize(text)
          raise Limit, 'command exceeds 64 KiB' if text.bytesize > MAX_BYTES

          @deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + MAX_SECONDS
          @tokens = 0
        end

        def check(depth = 0)
          raise Limit, 'shell nesting exceeds 32 levels' if depth > MAX_DEPTH
          raise Limit, 'shell scan exceeded 200 ms' if Process.clock_gettime(Process::CLOCK_MONOTONIC) > @deadline
        end

        def token
          @tokens += 1
          raise Limit, 'shell scan exceeds 4096 tokens' if @tokens > MAX_TOKENS
        end
      end

      def self.occurrences(text)
        raise Limit, 'command exceeds 64 KiB' if text.bytesize > Budget::MAX_BYTES

        found = []
        text.to_enum(:scan, /(?:\b|#{RAW_ESCAPE}\K)keryx['"]?#{RAW_SPACE}/).each do
          start, index = Regexp.last_match.offset(0)
          loop do
            action = /\G['"]?(send|ask|reply)(?=\b)/.match(text, index)
            if action
              found << [start, action.end(0)]
              break
            end
            option = /\G--[a-z][a-z-]*(?:=#{RAW_WORD})?/.match(text, index)
            break unless option

            index = option.end(0)
            gap = /\G#{RAW_SPACE}/.match(text, index)
            break unless gap

            index = gap.end(0)
            if option[0] == '--as' || (option[0] != '--color' && !option[0].include?('=') && !/\G(?:send|ask|reply|--)/.match?(text, index))
              value = /\G#{RAW_WORD}/.match(text, index)
              break unless value

              gap = /\G#{RAW_SPACE}/.match(text, value.end(0))
              break unless gap

              index = gap.end(0)
            end
          end
        end
        found + text.to_enum(:scan, RAW_INCOMPLETE).map { Regexp.last_match.offset(0) }
      end

      class ShellScan
        attr_reader :segments, :nested, :index, :comments, :depth, :output_consumer

        def initialize(text, index: 0, closing: nil, expansions_only: false, budget: Budget.new(text), depth: 0, mapping: nil, output_consumer: false)
          budget.check(depth)
          @depth = depth
          @output_consumer = output_consumer
          @segments = [{ words: [], tokens: [], input: [], separator: nil }]
          @nested = []
          @comments = []
          @index = index
          chars = text.chars
          mapping ||= (0...chars.length).to_a
          word = +''
          offsets = []
          children = []
          literal = true
          word_start = nil
          quote = nil
          escaped = false
          target = nil
          heredocs = []
          parentheses = 0
          flush = lambda do
            if word_start
              budget.token
              token = { value: word, map: offsets, range: [mapping[word_start], mapping[@index - 1].to_i + 1],
                        literal: literal, children: children }
              if target == :input
                @segments.last[:input] << token
              elsif target == :write
                (@segments.last[:writes] ||= []) << token
              elsif target != :discard
                @segments.last[:words] << word
                @segments.last[:tokens] << token
              end
              @segments.last[:children] ||= []
              @segments.last[:children].concat(children)
              target = nil
            end
            word = +''
            offsets = []
            children = []
            literal = true
            word_start = nil
          end
          while @index < chars.length
            budget.check(depth) if (@index & 255).zero?
            char = chars[@index]
            if escaped
              unless char == "\n"
                word << char
                offsets << mapping[@index]
              end
              escaped = false
            elsif char == '\\' && quote != "'"
              escaped = true
              word_start ||= @index
            elsif closing && char == closing && !quote && parentheses.zero?
              flush.call unless expansions_only
              @index += 1
              return
            elsif quote != "'" && ((char == '$' && chars[@index + 1] == '(') || char == '`' || (!quote && %w[< >].include?(char) && chars[@index + 1] == '('))
              word_start ||= @index
              child = self.class.new(text, index: @index + (char == '`' ? 1 : 2), closing: char == '`' ? '`' : ')',
                                     budget: budget, depth: depth + 1, mapping: mapping, output_consumer: char == '>')
              @nested << child
              children << child
              literal = false
              word << '?'
              offsets << mapping[@index]
              @index = child.index
              next
            elsif expansions_only
              @index += 1
              next
            elsif quote
              if char == quote
                quote = nil
              else
                literal = false if quote == '"' && char == '$'
                word << char
                offsets << mapping[@index]
              end
            elsif ["'", '"'].include?(char)
              word_start ||= @index
              quote = char
            elsif char == '#' && !word_start
              ending = text.index("\n", @index) || chars.length
              @comments << [mapping[@index], mapping[ending - 1].to_i + 1]
              @index = ending
              next
            elsif char == '<' || char == '>' || (char == '&' && chars[@index + 1] == '>')
              if word.match?(/\A\d+\z/)
                word_start = nil
              end
              flush.call
              if (descriptor = /\G[<>]&(?:\d+|-)/.match(text, @index))
                @index = descriptor.end(0)
                next
              elsif chars[@index, 3].join == '<<<'
                target = :input
                @index += 3
                next
              elsif (header = /\G<<(-?)[ \t]*(?:'([^'\n]+)'|"([^"\n]+)"|([A-Za-z_][A-Za-z0-9_]*))(?=\s|[;&|<>)]|\z)/.match(text, @index))
                heredocs << [@segments.last, header[2] || header[3] || header[4], header[1] == '-', !header[4].nil?]
                @index = header.end(0)
                next
              end
              target = char == '<' ? :discard : :write
              if char == '&'
                @index += 1
                char = '>'
              end
              @index += 1 while chars[@index + 1] == char
            elsif char.match?(/[\s;&|()]/)
              flush.call
              unless char.match?(/[ \t\r]/)
                target = nil
                parentheses += 1 if char == '(' && closing == ')'
                parentheses -= 1 if char == ')' && parentheses.positive?
                operator = char
                if %w[& |].include?(char) && chars[@index + 1] == char
                  operator += char
                  @index += 1
                elsif char == '|' && chars[@index + 1] == '&'
                  @index += 1
                end
                @segments.last[:separator] = operator
                @segments << { words: [], tokens: [], input: [], separator: nil }
              end
              if char == "\n" && !heredocs.empty?
                @index += 1
                heredocs.each do |segment, delimiter, tabs, expand|
                  start = @index
                  ending = start
                  complete = false
                  while @index < chars.length
                    budget.check(depth)
                    ending = text.index("\n", @index) || chars.length
                    line = text[@index...ending]
                    line = line.sub(/\A\t+/, '') if tabs
                    if line == delimiter
                      complete = true
                      ending = @index
                      @index = [text.index("\n", @index).to_i + 1, chars.length].min
                      @index = chars.length if @index <= ending
                      break
                    end
                    @index = [ending + 1, chars.length].min
                  end
                  ending = chars.length unless complete
                  value = text[start...ending]
                  body = { value: value, map: mapping[start...ending], range: [mapping[start] || mapping.last.to_i + 1, mapping[ending - 1].to_i + 1],
                           literal: complete && (!expand || !value.match?(/[$`]/)), children: [] }
                  if expand
                    child = self.class.new(value, expansions_only: true, budget: budget, depth: depth + 1, mapping: body[:map])
                    body[:children] << child
                    @nested << child
                  end
                  segment[:input] << body
                end
                heredocs.clear
                next
              end
            else
              word_start ||= @index
              literal = false if char == '$'
              word << char
              offsets << mapping[@index]
            end
            @index += 1
          end
          literal = false if quote || escaped
          flush.call unless expansions_only
          @segments.last[:children] = children if expansions_only
        end
      end

      class Reader
        OPTIONS = {
          'grep' => [%w[-E -F -G -P -i -v -w -x -n -H -h -l -L -c -q -s -r -R -a -I -o -z -Z -rn -nr -rin -rni -in -ni --ignore-case --invert-match --line-number --files-with-matches --count --recursive --extended-regexp --fixed-strings --quiet --no-messages --text], %w[-e -f -A -B -C -m --regexp --file --after-context --before-context --context --max-count --include --exclude --exclude-dir --color], %w[-e -f -A -B -C -m]],
          'rg' => [%w[-n -i -v -w -x -l -L -c -q -s -F -a -o -U -uu -uuu --hidden --no-ignore --files --files-with-matches --count --line-number --fixed-strings --no-heading --heading --json --glob-case-insensitive --no-config --text --multiline], %w[-e -f -g -t -T -A -B -C -m --regexp --file --glob --iglob --type --type-not --context --max-count --max-depth --color --encoding --pre-glob], %w[-e -f -g -t -T -A -B -C -m]],
          'head' => [%w[-q -v -z --quiet --silent --verbose --zero-terminated], %w[-n -c --lines --bytes], %w[-n -c]],
          'tail' => [%w[-q -v -z -f -F --quiet --silent --verbose --zero-terminated], %w[-n -c --lines --bytes --sleep-interval --pid], %w[-n -c]],
          'sort' => [%w[-b -d -f -g -h -i -M -n -R -r -s -u -V -z -c -C -nr -rn --numeric-sort --reverse --unique --stable --check --ignore-case --human-numeric-sort --version-sort --zero-terminated], %w[-t -k -S --field-separator --key --buffer-size --parallel], %w[-t -k -S]],
          'uniq' => [%w[-c -d -u -i -z --count --repeated --unique --ignore-case --zero-terminated], %w[-f -s -w --skip-fields --skip-chars --check-chars], %w[-f -s -w]],
          'wc' => [%w[-c -m -l -L -w --bytes --chars --lines --max-line-length --words], [], []],
          'cut' => [%w[-s -z --only-delimited --complement --zero-terminated], %w[-b -c -f -d --bytes --characters --fields --delimiter --output-delimiter], %w[-b -c -f -d]],
          'tr' => [%w[-c -C -d -s -t -cd -dc -cs -ds --complement --delete --squeeze-repeats --truncate-set1], [], []],
          'diff' => [%w[-r -q -s -u -c -a -b -w -B -i -N --recursive --brief --report-identical-files --text --ignore-all-space --ignore-space-change --unified], %w[-U -C -I -x -X --ignore-matching-lines --exclude --exclude-from --label], %w[-U -C -I -x -X]],
          'cat' => [%w[-A -b -e -E -n -s -t -T -v --show-all --number-nonblank --show-ends --number --squeeze-blank --show-tabs --show-nonprinting], [], []],
          'tee' => [%w[-a -i --append --ignore-interrupts], [], []],
          'read' => [%w[-r -s], %w[-a -d -n -N -p -t -u], []],
          'echo' => [%w[-n -e -E -ne -en], [], []],
          'git log' => [%w[--oneline --all --decorate --no-decorate --stat --patch -p --no-patch --name-only --name-status --reverse --no-merges --merges --first-parent --no-ext-diff --no-textconv], %w[--grep --author --committer --since --until --format --pretty -n -S -G], %w[-n -S -G]],
          'git show' => [%w[--oneline --stat --patch -p --no-patch --name-only --name-status --no-ext-diff --no-textconv], %w[--format --pretty], []],
          'git grep' => [%w[-n -i -v -w -l -L -c -q -E -F -P -h -H -z --no-index --cached --untracked --recurse-submodules --line-number --fixed-strings --ignore-case], %w[-e -f -A -B -C --max-depth], %w[-e -f -A -B -C]],
          'gh search code' => [[], %w[--owner --repo -R --limit -L --language --filename --extension --match], %w[-R -L]],
          'gh issue list' => [[], %w[--search -S --repo -R --limit -L --state -s --label -l --author -A --assignee -a --milestone -m], %w[-S -R -L -s -l -A -a -m]]
        }.freeze

        def self.name(word)
          return unless word
          return word unless word.include?('/')
          return File.basename(word) if %w[/bin /usr/bin].include?(File.dirname(word))
        end

        def self.operands(tokens, specification, numeric: false)
          flags, values, attached = specification
          result = []
          args = tokens.dup
          parsing = true
          until args.empty?
            token = args.shift
            word = token[:value]
            if parsing && word == '--'
              return unless token[:literal]

              parsing = false
            elsif parsing && word.start_with?('-') && word != '-'
              return unless token[:literal]
              next if flags.include?(word) || (numeric && word.match?(/\A-\d+\z/))
              if values.include?(word)
                value = args.shift
                return unless value && value[:literal]
              elsif word.start_with?('--') && word.include?('=') && values.include?(word.split('=', 2).first)
                next
              elsif attached.any? { |option| word.start_with?(option) && word.length > option.length }
                next
              else
                return
              end
            else
              result << token
            end
          end
          result
        end

        def self.accept?(tokens)
          executable = name(tokens.first&.dig(:value))
          return false unless executable && tokens.first[:literal]

          args = tokens.drop(1)
          if executable == 'xargs'
            return false unless %w[grep wc].include?(name(args.first&.dig(:value)))

            return accept?(args)
          end
          if executable == 'git'
            while %w[-C --no-pager].include?(args.first&.dig(:value))
              return false unless args[0][:literal]
              if args[0][:value] == '-C'
                return false unless args[1]&.dig(:literal)

                args = args.drop(2)
              else
                args = args.drop(1)
              end
            end
            subcommand = args.shift
            return false unless subcommand && subcommand[:literal]

            executable += " #{subcommand[:value]}"
          elsif executable == 'gh'
            return false unless args.first(2).length == 2 && args.first(2).all? { |token| token[:literal] }

            executable += " #{args.shift(2).map { |token| token[:value] }.join(' ')}"
          end
          return program?(executable, args) if %w[sed awk].include?(executable)
          return find?(args) if executable == 'find'
          if executable == 'printf'
            args = args.drop(1) if args.first&.dig(:value) == '--'
            return args.first && args.first[:literal] && !args.first[:value].start_with?('-')
          end
          specification = OPTIONS[executable]
          return false unless specification

          operands = operands(args, specification, numeric: %w[head tail git\ log].include?(executable))
          return false unless operands
          return false if executable == 'uniq' && operands.length > 1

          true
        end

        def self.program?(executable, tokens)
          args = tokens.dup
          programs = []
          operands = []
          parsing = true
          until args.empty?
            token = args.shift
            value = token[:value]
            if parsing && value == '--'
              return false unless token[:literal]

              parsing = false
            elsif parsing && value.start_with?('-') && value != '-'
              return false unless token[:literal]
              if executable == 'sed' && %w[-n -E -r --quiet --silent --regexp-extended].include?(value)
                next
              elsif executable == 'sed' && %w[-e --expression].include?(value)
                programs << args.shift
              elsif executable == 'sed' && (value.start_with?('-e') || value.start_with?('--expression='))
                programs << token.merge(value: value.sub(/\A(?:-e|--expression=)/, ''))
              elsif executable == 'awk' && %w[-F -v].include?(value)
                return false unless args.shift&.dig(:literal)
              elsif executable == 'awk' && %w[-F -v].any? { |option| value.start_with?(option) && value.length > 2 }
                next
              else
                return false
              end
            elsif programs.empty?
              programs << token
            else
              operands << token
            end
          end
          return false if programs.empty? || programs.any? { |token| !token || !token[:literal] }
          return false if executable == 'awk' && operands.any? { |token| token[:value].include?('=') }

          programs.all? do |token|
            if executable == 'sed'
              token[:value].match?(%r{\A(?:(?:\d+|\$|/(?:\\.|[^/])*/)(?:,(?:\+?\d+|\$|/(?:\\.|[^/])*/))?)?[pqd]\z})
            else
              token[:value].match?(%r{\A(?:/(?:\\.|[^/])*/\s*)?\{\s*print(?:\s+\$(?:0|[1-9]\d*))?\s*\}\z})
            end
          end
        end

        def self.find?(tokens)
          args = tokens.dup
          flags = %w[-H -L -P -print -print0 -ls -prune -quit -depth -mount -xdev -empty -readable -writable -executable -true -false -a -and -o -or -not !]
          values = %w[-name -iname -path -ipath -regex -iregex -type -maxdepth -mindepth -mtime -mmin -size -user -group -perm]
          until args.empty?
            token = args.shift
            value = token[:value]
            if value == '-exec'
              ending = args.index { |item| %w[; +].include?(item[:value]) }
              return false unless token[:literal] && ending
              return false unless name(args.first&.dig(:value)) == 'grep' && accept?(args.first(ending))

              args.shift(ending + 1)
            elsif flags.include?(value)
              return false unless token[:literal]
            elsif values.include?(value)
              return false unless token[:literal] && args.shift&.dig(:literal)
            elsif value.start_with?('-')
              return false
            end
          end
          true
        end
      end

      class Accounting
        attr_reader :ranges

        def initialize(text, budget: Budget.new(text))
          @text = text
          @budget = budget
          @ranges = []
          @root = describe(ShellScan.new(text, budget: budget))
          invalidate_reads(@root) if @read_disabled
        end

        def unresolved?(occurrences, checked: [])
          walk(@root, stored_exec: execution?(@root))
          coverage = Array.new(@text.length + 1, 0)
          (@ranges + checked).each do |start, ending|
            next unless start && ending && ending > start

            coverage[start] += 1
            coverage[ending] -= 1
          end
          total = 0
          missing = [0]
          @text.each_char.with_index do |char, index|
            total += coverage[index]
            missing << missing.last + (total.zero? && !char.match?(/[\s'"\\]/) ? 1 : 0)
          end
          occurrences.any? { |start, ending| missing[ending] != missing[start] }
        end

        def file_stable_before?(offset)
          @root[:parts].all? do |part|
            segment = part[:segment]
            first = segment[:tokens].first
            next true unless first && first[:range][0] < offset

            (part[:kind] == :read || %w[cd pushd popd].include?(part[:tokens].first&.dig(:value))) && !storage?(part) &&
              part[:children].all? { |child| !execution?(child) }
          end
        end

        private

        def invalidate_reads(description)
          description[:safe] = false
          description[:parts].each do |part|
            part[:kind] = :unknown
            invalidate_reads(part[:payload]) if part[:payload]
            part[:children].each { |child| invalidate_reads(child) }
          end
        end

        def redefines?(scan)
          scan.segments.each_with_index.any? do |segment, index|
            words = segment[:words]
            assignment = /\A[A-Za-z_][A-Za-z0-9_]*(?:\[[^\]]*\])?\+?=/
            original = words.drop_while { |word| word.match?(assignment) }
            original.shift while %w[command exec nohup time ! { then do else -- -p].include?(original.first)
            command_words = unwrap(segment[:tokens]).map { |token| token[:value] }
            command_words.shift while %w[command exec nohup time ! { then do else -- -p].include?(command_words.first)
            command = Reader.name(command_words.first)
            words.any? { |word| word.match?(assignment) } ||
              %w[export readonly declare typeset local env read mapfile readarray getopts unset].include?(command) ||
              (command == 'printf' && command_words.drop(1).take_while { |word| word != '--' }.any? { |word| word.start_with?('-v') }) ||
              %w[function alias hash enable builtin eval source .].include?(Reader.name(original.first)) ||
              (words.length == 1 && segment[:separator] == '(' && scan.segments[index + 1]&.dig(:separator) == ')')
          end || scan.nested.any? { |child| redefines?(child) }
        end

        def describe(scan)
          @read_disabled ||= redefines?(scan)
          upstream = []
          parts = scan.segments.map do |segment|
            tokens = segment[:tokens]
            tokens = unwrap(tokens)
            words = tokens.map { |token| token[:value] }
            executable = Reader.name(words.first)
            kind = :unknown
            payload = nil
            original = segment[:words]
            eligible = !original.first.to_s.match?(/\A[A-Za-z_][A-Za-z0-9_]*=/) && !original.include?('env')
            if eligible && readers?(executable, words, tokens)
              kind = (%w[read tee].include?(executable) || (segment[:writes] || []).any? { |token| token[:value] != '/dev/null' || !token[:literal] }) ? :store : :read
            elsif eligible && data_input?(executable, words)
              kind = :data
            elsif eligible && SHELLS.include?(executable) && noexec?(words.drop(1))
              kind = :read
            else
              carried = command_tokens(executable, tokens.drop(1))
              if !carried && SHELLS.include?(executable) && executable != 'su' && Command.shell_stdin?(words.drop(1))
                carried = segment[:input]
                if carried.empty?
                  carried = upstream.last(1).flat_map do |previous|
                    if %w[cat tee].include?(previous[:words].first)
                      previous[:input]
                    elsif %w[echo printf].include?(previous[:words].first)
                      previous[:tokens].drop(1)
                    else
                      []
                    end
                  end
                end
                carried = nil if carried.empty?
              end
              if carried && carried.all? { |token| token[:literal] }
                value, mapping = join_tokens(carried)
                payload = describe(ShellScan.new(value, budget: @budget, depth: scan.depth + 1, mapping: mapping))
                kind = :read if eligible && payload[:safe]
              end
            end
            segment[:separator] == '|' ? upstream << segment : upstream.clear
            children = ((segment[:children] || []) + segment[:input].flat_map { |token| token[:children] }).map { |child| describe(child) }
            { segment: segment, tokens: tokens, kind: kind, payload: payload, children: children }
          end
          { scan: scan, parts: parts, safe: parts.all? { |part| part[:segment][:words].empty? || %i[read store].include?(part[:kind]) } }
        end

        def unwrap(tokens)
          tokens = tokens.dup
          tokens.shift while tokens.first&.dig(:value)&.match?(/\A[A-Za-z_][A-Za-z0-9_]*=/)
          loop do
            word = tokens.first&.dig(:value)
            if %w[command builtin exec nohup].include?(word)
              tokens.shift
              tokens.shift while %w[-- -p].include?(tokens.first&.dig(:value))
            elsif word == 'timeout' && tokens[1]&.dig(:value)&.match?(/\A\d+(?:\.\d+)?[smhd]?\z/)
              tokens.shift(2)
            elsif word == 'env' && tokens[1]&.dig(:value) == '--'
              tokens.shift(2)
            elsif word == 'mise' && tokens[1]&.dig(:value) == 'exec' && tokens[2]&.dig(:value) == '--'
              tokens.shift(3)
            else
              break
            end
          end
          tokens
        end

        def data_input?(executable, words)
          (executable == 'git' && words[1] == 'commit') ||
            (executable == 'gh' && [%w[pr create], %w[issue create], %w[pr comment]].include?(words[1, 2]))
        end

        def message_tokens(tokens)
          words = tokens.map { |token| token[:value] }
          options = Reader.name(words.first) == 'git' ? %w[-m --message] : %w[-t --title -b --body]
          selected = []
          args = tokens.drop(Reader.name(words.first) == 'git' ? 2 : 3)
          until args.empty?
            option = args.shift
            break if option[:value] == '--'
            next unless option[:literal]

            if options.include?(option[:value]) || (Reader.name(words.first) == 'git' && option[:value].match?(/\A-[asqve]+m\z/))
              value = args.shift
              selected << value if value && value[:literal]
            elsif options.any? { |name| option[:value].start_with?(name.start_with?('--') ? "#{name}=" : name) && option[:value].length > name.length }
              selected << option
            end
          end
          selected
        end

        def readers?(executable, words, tokens)
          Reader.accept?(tokens)
        end

        def storage?(part)
          part[:kind] == :store || (part[:kind] == :unknown && !%w[cd pushd popd].include?(part[:tokens].first&.dig(:value))) ||
            (part[:segment][:writes] || []).any? { |token| token[:value] != '/dev/null' || !token[:literal] }
        end

        def execution?(description)
          description[:parts].any? do |part|
            (part[:kind] == :unknown && !part[:tokens].empty? && File.basename(part[:tokens].first[:value]) != 'keryx') ||
              (part[:payload] && execution?(part[:payload])) || part[:children].any? { |child| execution?(child) }
          end
        end

        def noexec?(arguments)
          arguments = arguments.dup
          noexec = false
          until arguments.empty?
            option = arguments.shift
            break if option == '--' || !option.match?(/\A[-+]/)

            if %w[-n -en -ne -nu -un].include?(option)
              noexec = true
            elsif option == '+n'
              noexec = false
            elsif %w[-o +o].include?(option)
              return false unless arguments.shift == 'noexec'

              noexec = option == '-o'
            elsif !%w[-e -u -s -c -ec -ce --norc --noprofile].include?(option)
              return false
            end
          end
          noexec
        end

        def command_tokens(executable, arguments)
          if executable == 'ssh'
            arguments = arguments.dup
            until arguments.empty? || !arguments.first[:value].start_with?('-')
              option = arguments.shift[:value]
              break if option == '--'

              arguments.shift if %w[-B -b -c -D -E -e -F -I -i -J -L -l -m -O -o -p -Q -R -S -W -w].include?(option)
            end
            return arguments.drop(1) unless arguments.length < 2
          elsif executable == 'watch'
            arguments = arguments.dup
            while arguments.first&.dig(:value)&.start_with?('-')
              option = arguments.shift[:value]
              arguments.shift if %w[-n --interval].include?(option)
            end
            return arguments unless arguments.empty?
          elsif SHELLS.include?(executable)
            inline = arguments.find { |token| token[:value].start_with?('--command=') }
            if inline
              prefix = '--command='.length
              return [inline.merge(value: inline[:value][prefix..], map: inline[:map][prefix..],
                                   range: [inline[:map][prefix], inline[:range][1]])]
            end
            option = arguments.index { |token| token[:value] == '--command' || token[:value].match?(/\A-[^-]*c[^-]*\z/) }
            if option
              after = arguments.drop(option + 1)
              after.shift while after.first&.dig(:value)&.start_with?('-')
              return [after.first] unless after.empty?
            end
          end
          nil
        end

        def join_tokens(tokens)
          text = +''
          mapping = []
          tokens.each do |token|
            unless text.empty?
              text << ' '
              mapping << token[:range][0]
            end
            text << token[:value]
            mapping.concat(token[:map])
          end
          [text, mapping]
        end

        def walk(description, output_exec: false, stored_exec: false)
          @budget.check(description[:scan].depth)
          @ranges.concat(description[:scan].comments)
          groups = description[:parts].slice_after { |part| part[:segment][:separator] != '|' }
          groups.each do |group|
            downstream_safe = !output_exec
            group.reverse_each do |part|
              segment = part[:segment]
              safe_output = downstream_safe
              child_descriptions = part[:children]
              safe_output &&= child_descriptions.none? { |child| child[:scan].output_consumer && !child[:safe] }
              safe_output &&= !(stored_exec && storage?(part))
              if %i[read store].include?(part[:kind]) && safe_output && !part[:payload]
                part[:tokens].drop(1).each { |token| @ranges << token[:range] if token[:literal] }
              end
              if part[:kind] == :data && safe_output
                message_tokens(part[:tokens]).each { |token| @ranges << token[:range] }
              end
              if safe_output && %i[read store data].include?(part[:kind])
                segment[:input].each { |token| @ranges << token[:range] if token[:literal] }
              end
              walk(part[:payload], output_exec: !safe_output, stored_exec: stored_exec) if part[:payload]
              child_descriptions.each do |child|
                walk(child, output_exec: !safe_output || part[:kind] == :unknown, stored_exec: stored_exec)
              end
              downstream_safe &&= %i[read store].include?(part[:kind]) && safe_output
            end
          end
        end
      end

      def self.invocation?(text, nested_only: false)
        occurrences = occurrences(text)
        return false if occurrences.empty?

        Accounting.new(text).unresolved?(occurrences)
      rescue Exception => error
        raise if error.is_a?(SystemExit) || error.is_a?(SignalException)

        true
      end

      def self.lexical_segments(text) = ShellScan.new(text).segments.map { |segment| segment[:words] }
      def self.carried_commands(words)
        tokens = words.each_with_index.map { |value, index| { value: value, literal: true, map: [], range: [index, index + 1] } }
        payload = Accounting.allocate.send(:command_tokens, words.first, tokens.drop(1))
        [payload ? [payload.map { |token| token[:value] }.join(' ')] : [], !payload && shell_stdin?(words.drop(1))]
      end

      def self.shell_stdin?(arguments)
        arguments = arguments.dup
        stdin = false
        until arguments.empty?
          option = arguments.shift
          break if option == '--'
          return stdin unless option.match?(/\A[-+]/)

          return false if option.match?(/\A-[^-]*c[^-]*\z/)
          stdin ||= option.match?(/\A-[^-]*s[^-]*\z/)
          arguments.shift if option.match?(/\A[-+][^-]*[oO]\z/) || %w[--rcfile --init-file].include?(option)
        end
        stdin || arguments.empty?
      end

      attr_reader :checked_ranges

      def initialize(text, cwd: Dir.pwd, budget: nil, accounting: nil)
        @text = text
        @chars = text.chars
        @cwd = cwd
        @budget = budget || Budget.new(text)
        @checked_ranges = []
        @accounting = accounting
      end

      def bodies
        segments = split_commands
        persistent_confirmation = false

        segments.each_with_index.filter_map do |segment, index|
          words = Shellwords.split(segment)
          next if words.empty?
          assignment_words = words.first == 'export' ? words.drop(1) : words
          if assignment_words.all? { |word| assignment?(word) }
            setting = assignment_words.map { |word| word.split('=', 2) }.to_h
            persistent_confirmation = setting[CONFIRMATION] == '1' if setting.key?(CONFIRMATION)
          end
          prefix = words.take_while { |word| assignment?(word) }.map { |word| word.split('=', 2) }.to_h
          if prefix.key?(CONFIRMATION) ? prefix[CONFIRMATION] == '1' : persistent_confirmation
            @checked_ranges.concat(@segment_ranges[index])
            next
          end

          assignments = words.take_while { |word| assignment?(word) }
          words.shift(assignments.length)
          executable = File.basename(words.first.to_s)
          directory_words = words
          while %w[builtin command].include?(directory_words.first)
            directory_words = directory_words.drop(1)
            directory_words.shift while %w[-- -p].include?(directory_words.first)
          end
          @cwd = nil if %w[eval time source .].include?(directory_words.first)
          if %w[cd pushd popd].include?(directory_words.first)
            if words.first == 'cd' && assignments.none? { |word| word.start_with?('CDPATH=') } && index.zero? && words.length == 2 && @separators[index] == '&&' && !words.last.start_with?('-')
              directory = File.expand_path(words.last, @cwd)
              @cwd = File.directory?(directory) ? directory : nil
            else
              @cwd = nil
            end
            next
          end
          control = %w[if then elif else for while until case ! {].include?(executable)
          if control
            raise ArgumentError, "unsupported shell wrapper or control flow: #{executable}"
          end
          next unless executable == 'keryx'

          value = body(words, stdin: @stdin_bodies[index], offset: @segment_ranges[index].first.first)
          @checked_ranges.concat(@segment_ranges[index]) unless value.nil?
          value
        end
      end

      private

      def assignment?(word) = word&.match?(/\A[A-Za-z_][A-Za-z0-9_]*=/)

      def split_commands
        segments = []
        @segment_ranges = []
        segment_start = 0
        @separators = []
        @stdin_bodies = {}
        pending = nil
        current = +''
        quote = nil
        escaped = false
        word_start = true
        index = 0
        while index < @text.length
          @budget.check if (index & 255).zero?
          char = @chars[index]
          if escaped
            current << char
            escaped = false
            word_start = false
          elsif char == '\\' && quote != "'"
            if @text[index + 1] == "\n"
              index += 2
              next
            end
            current << char
            escaped = true
            word_start = false
          elsif quote
            if quote == '"' && @text[index, 2] == '$('
              literal, index = literal_substitution(index)
              current << literal.gsub(/[\\"$`]/) { |value| "\\#{value}" }
              next
            end
            raise ArgumentError, 'shell expansion is not supported' if quote == '"' && ['$', '`'].include?(char)

            current << char
            quote = nil if char == quote
          elsif ["'", '"'].include?(char)
            quote = char
            current << char
            word_start = false
          elsif char == '#' && word_start
            index = @text.index("\n", index) || @text.length
            next
          elsif @text[index, 2] == '<<'
            raise ArgumentError, 'multiple stdin here-documents are not supported' if pending

            header = heredoc_header(index)
            descriptor = current[/\b\d+\z/] if current.match?(/(?:\A|\s)\d+\z/)
            raise ArgumentError, 'only stdin here-documents are supported' if descriptor && descriptor != '0'

            current = current.delete_suffix(descriptor) if descriptor
            current << ' '
            word_start = true
            pending = [segments.length, header[2], header[1] == '-']
            index += header[0].length
            next
          elsif char == '>' || @text[index, 2] == '&>'
            redirection = /\G(?:>&(?:\d+|-)|(?:&?>>?|>\|)[ \t]*\/dev\/null)(?=\s|[;&|]|\z)/.match(@text, index)
            raise ArgumentError, 'unsupported shell redirection' unless redirection
            raise ArgumentError, 'stdin redirection is not supported' if current.match?(/(?:\A|\s)0\z/)

            current.sub!(/(?<=\s)\d+\z|\A\d+\z/, '')
            current << ' '
            word_start = true
            index += redirection[0].length
            next
          elsif ['$', '`', '(', ')', '<'].include?(char)
            raise ArgumentError, 'shell expansion, subshells and redirections are not supported'
          elsif ['{', '*', '?', '[', '~'].include?(char)
            raise ArgumentError, 'unquoted shell word expansion is not supported'
          elsif [';', '|', '&', "\n"].include?(char)
            if char == '&' && @text[index + 1] != '&'
              raise ArgumentError, 'background commands are not supported'
            end
            operator = char
            if ['&', '|'].include?(char) && @text[index + 1] == char
              operator += char
              index += 1
            end
            unless current.strip.empty?
              segments << current
              @segment_ranges << [[segment_start, index]]
              @separators << operator
            end
            current = +''
            segment_start = index + 1
            word_start = true
            if char == "\n" && pending
              segment, delimiter, tabs = pending
              start = index + 1
              @stdin_bodies[segment], index = heredoc_body(start, delimiter, tabs)
              @segment_ranges[segment] << [start, index]
              segment_start = index
              pending = nil
              next
            end
          else
            current << char
            word_start = char.match?(/\s/)
          end
          index += 1
        end
        raise ArgumentError, 'unclosed shell quote or escape' if quote || escaped
        raise ArgumentError, 'missing here-document body' if pending

        unless current.strip.empty?
          segments << current
          @segment_ranges << [[segment_start, @text.length]]
        end
        segments
      end

      def heredoc_header(index)
        match = /\G<<(-?)[ \t]*(?:'([^'\n]+)'|"([^"$`\\\n]+)")(?=\s|[;&|<>]|\z)/.match(@text, index)
        raise ArgumentError, 'only literal quoted here-document delimiters are supported' unless match

        [match[0], match[1], match[2] || match[3]]
      end

      def heredoc_body(index, delimiter, tabs)
        body = +''
        while index < @text.length
          ending = @text.index("\n", index)
          line = @text[index...(ending || @text.length)]
          line = line.sub(/\A\t+/, '') if tabs
          next_index = ending ? ending + 1 : @text.length
          return [body, next_index] if line == delimiter

          body << line
          body << "\n" if ending
          index = next_index
        end
        raise ArgumentError, 'unclosed here-document'
      end

      def literal_substitution(index)
        prefix = /\G\$\([ \t]*cat[ \t]+(?=<<)/.match(@text, index)
        raise ArgumentError, 'only literal cat here-document substitutions are supported' unless prefix

        header = heredoc_header(index + prefix[0].length)
        after_header = index + prefix[0].length + header[0].length
        newline = /\G[ \t]*\n/.match(@text, after_header)
        raise ArgumentError, 'unsupported here-document substitution header' unless newline

        literal, ending = heredoc_body(after_header + newline[0].length, header[2], header[1] == '-')
        closing = /\G[ \t]*\)/.match(@text, ending)
        raise ArgumentError, 'unsupported command after here-document substitution' unless closing

        [literal.sub(/\n+\z/, ''), ending + closing[0].length]
      end

      def body(words, stdin: nil, offset: 0)
        words = words.drop(1)
        while %w[--as --color].include?(words.first) || words.first&.start_with?('--as=', '--color=')
          words.first == '--as' ? words.shift(2) : words.shift
        end
        action = words.shift
        return unless %w[send ask reply].include?(action)

        options = {}
        positional = []
        parsing = true
        until words.empty?
          word = words.shift
          if parsing && word == '--'
            parsing = false
          elsif parsing && word.start_with?('-') && word != '-'
            key, value = word.split('=', 2)
            key = '--file' if key == '-f'
            if %w[--file --as --within --re].include?(key)
              value ||= words.shift
              raise ArgumentError, "missing value for #{key}" unless value

              options[key] = value
            elsif %w[--help -h --version -V].include?(key)
              return
            elsif key != '--color'
              raise ArgumentError, "unsupported keryx option #{key}"
            end
          else
            positional << word
          end
        end
        positional.shift unless action == 'send' && options['--re']
        if options['--file']
          raise ArgumentError, 'both a body file and inline body' unless positional.empty?
          if options['--file'] == '-'
            raise ArgumentError, 'stdin body needs a literal here-document' unless stdin

            return stdin
          end

          if !@cwd && !options['--file'].start_with?('/')
            raise ArgumentError, 'relative body file needs a known directory after cd'
          end

          @accounting ||= Accounting.new(@text, budget: @budget)
          raise ArgumentError, 'body file may be changed by an earlier command' unless @accounting.file_stable_before?(offset)

          PreSend.read_text(File.expand_path(options['--file'], @cwd), max_bytes: Budget::MAX_BYTES)
        else
          raise ArgumentError, 'missing body or stdin body' if positional.empty? || positional == ['-']

          positional.join(' ')
        end
      end
    end

    class ToolInput
      def initialize(input)
        raise ArgumentError, 'tool_input must not be null' if input.nil?

        @strings = []
        @arrays = []
        walk(input, 0)
      end

      def occurrence?
        return false unless @strings.any? { |text| text.match?(/\bkeryx\b/i) }
        raise Command::Limit, 'tool input exceeds 64 KiB' if @strings.sum(&:bytesize) > Command::Budget::MAX_BYTES

        (@strings + @arrays.map { |array| array.grep(String).join(' ') }).any? do |text|
          remaining = 0
          text.split(/(?:\\\r?\n|[\s'"`])+/).any? do |word|
            found = remaining.positive? && word.match?(/\A(?:send|ask|reply)\b/i)
            remaining -= 1
            remaining = 4 if word.match?(/\bkeryx(?:\.exe)?\b/i)
            found
          end
        end
      end

      private

      def walk(input, depth)
        raise Command::Limit, 'tool input nesting exceeds 32 levels' if depth > Command::Budget::MAX_DEPTH

        case input
        when String
          @strings << input
        when Hash
          input.each { |key, value| walk(key, depth + 1); walk(value, depth + 1) }
        when Array
          @arrays << input
          input.each { |value| walk(value, depth + 1) }
        end
      end
    end

    class Runner
      def initialize(input: $stdin, output: $stdout, error: $stderr)
        @input = input
        @output = output
        @error = error
      end

      def run(argv)
        @harness = nil
        contract = true
        words_paths = []
        check = nil
        parser = OptionParser.new do |options|
          options.banner = 'Usage: pre-send.rb (--harness claude|codex|cursor | --check FILE) [--words FILE]'
          options.on('--harness NAME') do |name|
            @harness = nil
            raise ArgumentError, 'unknown --harness' unless %w[claude codex cursor].include?(name)

            @harness = name
          end
          options.on('--check FILE') { |path| check = path }
          options.on('--words FILE') { |path| words_paths << path }
          options.on('-h', '--help') { @output.puts options; return 0 }
        end
        parser.parse!(argv)
        raise ArgumentError, parser.banner unless argv.empty? && (!!check ^ !!@harness)

        words = words_paths.flat_map { |path| PreSend.read_text(path).lines }
        checker = Checker.new(words: words)
        if check
          flags = checker.check(PreSend.read_text(check, max_bytes: Command::Budget::MAX_BYTES))
          flag_lines(flags).each { |line| @output.puts line }
          return flags.empty? ? 0 : 1
        end
        data = JSON.parse(@input.read)
        raise ArgumentError, 'hook input must be an object' unless data.is_a?(Hash)

        if @harness == 'cursor'
          return pass if data['hook_event_name'] && data['hook_event_name'] != 'beforeShellExecution'

          command = data.fetch('command')
        else
          return pass if data['hook_event_name'] && data['hook_event_name'] != 'PreToolUse'

          known = @harness == 'claude' ? %w[Bash Monitor] : %w[Bash]
          tool_input = data.fetch('tool_input')
          command = tool_input['command'] if tool_input.is_a?(Hash)
          if (data['tool_name'] && !known.include?(data['tool_name'])) || !command.is_a?(String)
            input = ToolInput.new(tool_input)
            contract = false
            return pass unless input.occurrence?

            return PreSend.warning('tool input is not supported POSIX shell', harness: @harness, output: @output, error: @error)
          end
        end
        raise ArgumentError, 'command must be a string' unless command.is_a?(String)
        contract = false
        raise Command::Limit, 'command exceeds 64 KiB' if command.bytesize > Command::Budget::MAX_BYTES

        occurrences = Command.occurrences(command)
        return pass if occurrences.empty?

        budget = Command::Budget.new(command)
        accounting = Command::Accounting.new(command, budget: budget)
        parsed = Command.new(command, cwd: data.fetch('cwd', Dir.pwd), budget: budget, accounting: accounting)
        parse_error = nil
        begin
          bodies = parsed.bodies
        rescue ArgumentError, IOError => error
          parse_error = error.message
        end
        checked = parse_error ? [] : parsed.checked_ranges
        if accounting.unresolved?(occurrences, checked: checked)
          return PreSend.warning(parse_error || 'unaccounted keryx send, ask or reply occurrence',
                                 harness: @harness, output: @output, error: @error)
        end
        flags = bodies&.flat_map { |body| checker.check(body) } || []
        return pass if flags.empty?

        reason = "NOMOS pre-send found:\n#{flag_lines(flags).join("\n")}\n" \
                 "Check these flags. To confirm, resend the same command prefixed with #{CONFIRMATION}=1."
        if @harness == 'cursor'
          @output.puts JSON.generate(permission: 'deny', user_message: reason, agent_message: reason)
        else
          @output.puts JSON.generate(hookSpecificOutput: {
            hookEventName: 'PreToolUse', permissionDecision: 'deny', permissionDecisionReason: reason
          })
        end
        0
      rescue Exception => error
        raise if error.is_a?(SystemExit) || error.is_a?(SignalException)

        message = contract && !check ? "Repair the pre-send hook or its wiring and tell the human: #{error.message}" : error.message
        PreSend.warning(message, harness: @harness, output: @output, error: @error, check: !!check)
      end

      private

      def flag_lines(flags)
        lines = flags.first(50).map(&:to_s)
        lines << "#{flags.length - 50} more flags omitted." if flags.length > 50
        lines
      end

      def pass
        @output.puts JSON.generate(CURSOR_PASS) if @harness == 'cursor'
        0
      end
    end
  end
end

exit Nomos::PreSend::Runner.new.run(ARGV) if $PROGRAM_NAME == __FILE__
