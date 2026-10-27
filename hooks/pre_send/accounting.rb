# frozen_string_literal: true

module Nomos
  module PreSend
    class Command
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
            command_words = command_words.drop_while { |word| word != "--" }.drop(1) if command_words.first == "mise" && %w[exec x].include?(command_words[1])
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
            elsif word == 'timeout' && (count = timeout_words(tokens))
              tokens.shift(count)
            elsif word == 'env' && tokens[1]&.dig(:value) == '--'
              tokens.shift(2)
            else
              break
            end
          end
          tokens
        end

        def timeout_words(tokens)
          index = 1
          loop do
            token = tokens[index]
            return unless token && token[:literal]

            value = token[:value]
            if %w[--foreground --preserve-status -v --verbose].include?(value) || value.match?(/\A(?:--kill-after=|--signal=|-[ks].)/)
              index += 1
            elsif %w[-k -s --kill-after --signal].include?(value)
              return unless tokens[index + 1]&.dig(:literal)

              index += 2
            elsif value.match?(/\A\d+(?:\.\d+)?[smhd]?\z/)
              return index + 1
            else
              return
            end
          end
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
    end
  end
end
