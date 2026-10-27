# frozen_string_literal: true

require 'shellwords'

module Nomos
  module PreSend
    class Command
      SHELLS =%w[bash sh zsh dash fish ksh mksh tcsh csh su].freeze
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
            confirmed_body(words, prefix, index)
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

          value = body(words, stdin: @stdin_bodies[index], offset: @segment_ranges[index].first.first, sender: prefix['KERYX_AS'])
          @checked_ranges.concat(@segment_ranges[index]) unless value.nil?
          value
        end
      end

      private

      # A confirmed segment's message is still read, since a confirmation passes only advice; one the parser cannot
      # read passes as before.
      def confirmed_body(words, prefix, index)
        words = words.drop_while { |word| assignment?(word) }
        return unless File.basename(words.first.to_s) == 'keryx'

        body(words, stdin: @stdin_bodies[index], offset: @segment_ranges[index].first.first, sender: prefix['KERYX_AS'], confirmed: true)
      rescue ArgumentError, IOError
        nil
      end

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

      def body(words, stdin: nil, offset: 0, sender: nil, confirmed: false)
        words = words.drop(1)
        while %w[--as --color].include?(words.first) || words.first&.start_with?('--as=', '--color=')
          sender = words.first == '--as' ? words[1] : words.first.split('=', 2).last if words.first.start_with?('--as')
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
        target = positional.shift unless action == 'send' && options['--re']
        sender = options['--as'] if options.key?('--as')
        within = options['--within'] && Nomos::Clock.duration(options['--within'])
        raise ArgumentError, "invalid --within #{options['--within']}" if options['--within'] && within.nil?

        text = message_text(options, positional, stdin, offset)
        recipient = %w[send ask].include?(action) ? target : nil
        messages << Message.new(body: text, action: action, recipient: recipient, within: within, sender: sender, confirmed: confirmed)
        text
      end

      public

      def messages = @messages ||= []

      private

      def message_text(options, positional, stdin, offset)
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
  end
end
