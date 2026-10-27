# frozen_string_literal: true

module Nomos
  module PreSend
    class Command
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
    end
  end
end
