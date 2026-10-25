#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require 'json'
require 'optparse'
require 'shellwords'
require 'time'

module Nomos
  module PreSend
    def self.warning(message, harness:, output:, error:, check: false)
      text = "NOMOS pre-send warning: #{message}; #{check ? 'check incomplete' : 'command passed unchecked'}."
      text += ' Run --check on the resolved body file.' unless check
      error.puts text
      if !check && harness == 'cursor'
        output.puts JSON.generate(permission: 'allow', agent_message: text, user_message: text)
      elsif !check
        output.puts JSON.generate(hookSpecificOutput: { hookEventName: 'PreToolUse', additionalContext: text })
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

    def self.read_text(path)
      raise IOError, "not a regular file: #{path}" unless File.file?(path)

      text = File.read(path, encoding: 'UTF-8')
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

          flags << Flag.new(line_number(clean, match.begin(0)), 'future time', match[0])
        end
        check_form(clean, flags)
        flags.sort_by { |flag| [flag.line, flag.kind, flag.text] }
      end

      private

      def line_number(text, position) = text[0...position].count("\n") + 1

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
        content.to_enum(:scan, /^(\d+)[.)][ \t]+[^\n]*/).each do
          match = Regexp.last_match
          ranked = match[0].match?(rank)
          steps = !ranked if match[1].to_i <= last_number
          next if steps && !ranked

          steps = false
          last_number = match[1].to_i
          starts << match.begin(0)
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
      def initialize(text, cwd: Dir.pwd)
        @text = text
        @cwd = cwd
      end

      def bodies
        segments = split_commands
        return [] if confirmed?(Shellwords.split(segments.first.to_s))

        segments.each_with_index.filter_map do |segment, index|
          words = Shellwords.split(segment)
          next if words.empty?
          next if confirmed?(words)

          words.shift while assignment?(words.first)
          if words.first == 'cd'
            if index.zero? && words.length == 2 && @separators[index] == '&&' && !words.last.start_with?('-')
              directory = File.expand_path(words.last, @cwd)
              @cwd = File.directory?(directory) ? directory : nil
            else
              @cwd = nil
            end
            next
          end
          executable = File.basename(words.first.to_s)
          if %w[env command exec sudo doas bash sh zsh dash fish if then elif else for while until case time ! {].include?(executable)
            raise ArgumentError, "unsupported shell wrapper or control flow: #{executable}"
          end
          next unless executable == 'keryx'

          body(words, stdin: @stdin_bodies[index])
        end
      end

      private

      def assignment?(word) = word&.match?(/\A[A-Za-z_][A-Za-z0-9_]*=/)

      def confirmed?(words)
        assignments = words.take_while { |word| assignment?(word) }.map { |word| word.split('=', 2) }.to_h
        assignments[CONFIRMATION] == '1'
      end

      def split_commands
        segments = []
        @separators = []
        @stdin_bodies = {}
        pending = nil
        current = +''
        quote = nil
        escaped = false
        index = 0
        while index < @text.length
          char = @text[index]
          if escaped
            current << char
            escaped = false
          elsif char == '\\' && quote != "'"
            current << char
            escaped = true
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
          elsif char == '#' && (index.zero? || @text[index - 1].match?(/[\s;&|]/))
            index = @text.index("\n", index) || @text.length
            next
          elsif @text[index, 2] == '<<'
            raise ArgumentError, 'multiple stdin here-documents are not supported' if pending

            header = heredoc_header(index)
            descriptor = current[/\b\d+\z/] if current.match?(/(?:\A|\s)\d+\z/)
            raise ArgumentError, 'only stdin here-documents are supported' if descriptor && descriptor != '0'

            current = current.delete_suffix(descriptor) if descriptor
            current << ' '
            pending = [segments.length, header[2], header[1] == '-']
            index += header[0].length
            next
          elsif char == '>' || @text[index, 2] == '&>'
            redirection = @text[index..].match(/\A(?:>&(?:\d+|-)|(?:&?>>?|>\|)[ \t]*\/dev\/null)(?=\s|[;&|]|\z)/)
            raise ArgumentError, 'unsupported shell redirection' unless redirection
            raise ArgumentError, 'stdin redirection is not supported' if current.match?(/(?:\A|\s)0\z/)

            current.sub!(/(?<=\s)\d+\z|\A\d+\z/, '')
            current << ' '
            index += redirection[0].length
            next
          elsif ['$', '`', '(', ')', '<'].include?(char)
            raise ArgumentError, 'shell expansion, subshells and redirections are not supported'
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
              @separators << operator
            end
            current = +''
            if char == "\n" && pending
              segment, delimiter, tabs = pending
              @stdin_bodies[segment], index = heredoc_body(index + 1, delimiter, tabs)
              pending = nil
              next
            end
          else
            current << char
          end
          index += 1
        end
        raise ArgumentError, 'unclosed shell quote or escape' if quote || escaped
        raise ArgumentError, 'missing here-document body' if pending

        segments << current unless current.strip.empty?
        segments
      end

      def heredoc_header(index)
        match = @text[index..].match(/\A<<(-?)[ \t]*(?:'([^'\n]+)'|"([^"$`\\\n]+)")(?=\s|[;&|<>]|\z)/)
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
        prefix = @text[index..].match(/\A\$\([ \t]*cat[ \t]+(?=<<)/)
        raise ArgumentError, 'only literal cat here-document substitutions are supported' unless prefix

        header = heredoc_header(index + prefix[0].length)
        after_header = index + prefix[0].length + header[0].length
        newline = @text[after_header..].match(/\A[ \t]*\n/)
        raise ArgumentError, 'unsupported here-document substitution header' unless newline

        literal, ending = heredoc_body(after_header + newline[0].length, header[2], header[1] == '-')
        closing = @text[ending..].match(/\A[ \t]*\)/)
        raise ArgumentError, 'unsupported command after here-document substitution' unless closing

        [literal.sub(/\n+\z/, ''), ending + closing[0].length]
      end

      def body(words, stdin: nil)
        words = words.drop(1)
        while words.first == '--as' || words.first&.start_with?('--as=')
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

          PreSend.read_text(File.expand_path(options['--file'], @cwd))
        else
          raise ArgumentError, 'missing body or stdin body' if positional.empty? || positional == ['-']

          positional.join(' ')
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
        words_paths = []
        check = nil
        parser = OptionParser.new do |options|
          options.banner = 'Usage: pre-send.rb (--harness claude|codex|cursor | --check FILE) [--words FILE]'
          options.on('--harness NAME', %w[claude codex cursor]) { |name| @harness = name }
          options.on('--check FILE') { |path| check = path }
          options.on('--words FILE') { |path| words_paths << path }
          options.on('-h', '--help') { @output.puts options; return 0 }
        end
        parser.parse!(argv)
        raise ArgumentError, parser.banner unless argv.empty? && (!!check ^ !!@harness)

        words = words_paths.flat_map { |path| PreSend.read_text(path).lines }
        checker = Checker.new(words: words)
        if check
          flags = checker.check(PreSend.read_text(check))
          flags.each { |flag| @output.puts flag }
          return flags.empty? ? 0 : 1
        end
        data = JSON.parse(@input.read)
        raise ArgumentError, 'hook input must be an object' unless data.is_a?(Hash)

        if @harness == 'cursor'
          return pass if data['hook_event_name'] && data['hook_event_name'] != 'beforeShellExecution'

          command = data.fetch('command')
        else
          return pass if data['hook_event_name'] && data['hook_event_name'] != 'PreToolUse'
          return pass if data['tool_name'] && data['tool_name'] != 'Bash'

          command = data.fetch('tool_input').fetch('command')
        end
        raise ArgumentError, 'command must be a string' unless command.is_a?(String)
        return pass unless command.match?(/\bkeryx\b/)

        cwd = data.fetch('cwd', Dir.pwd)
        flags = Command.new(command, cwd: cwd).bodies.flat_map { |body| checker.check(body) }
        return pass if flags.empty?

        reason = "NOMOS pre-send found:\n#{flags.map(&:to_s).join("\n")}\n" \
                 "Check these flags. To confirm, resend the same command prefixed with #{CONFIRMATION}=1."
        if @harness == 'cursor'
          @output.puts JSON.generate(permission: 'deny', user_message: reason, agent_message: reason)
        else
          @output.puts JSON.generate(hookSpecificOutput: {
            hookEventName: 'PreToolUse', permissionDecision: 'deny', permissionDecisionReason: reason
          })
        end
        0
      rescue StandardError => error
        PreSend.warning(error.message, harness: @harness, output: @output, error: @error, check: !!check)
      end

      private

      def pass
        @output.puts JSON.generate(permission: 'allow') if @harness == 'cursor'
        0
      end
    end
  end
end

exit Nomos::PreSend::Runner.new.run(ARGV) if $PROGRAM_NAME == __FILE__
