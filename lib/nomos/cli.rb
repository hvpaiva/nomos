# frozen_string_literal: true

require 'json'
require 'optparse'
require 'time'
require_relative 'clock'
require_relative 'compose'
require_relative 'envelope'
require_relative 'json'
require_relative 'rules'
require_relative 'text'
require_relative 'vocabulary'

module Nomos
  # nomos check and nomos compose. Exit 0 accepts, 1 refuses with one reason per line on stderr, 2 is a usage or
  # internal error, which keryx counts as a refusal too.
  module CLI
    MAX_REASONS = 4096
    USAGE = <<~TEXT
      Usage: nomos check [--words FILE]
             nomos compose send|ask|reply --to ADDRESS [--within DURATION] [--text FILE] [--from ADDRESS]
                           [--words FILE] [--now TIME] [--title TEXT] [--kind KIND | --block FILE] [block options]
             nomos help | version

      nomos check reads one keryx check envelope (version 1) on stdin and exits 0 to accept the message, 1 to
      refuse it, with one reason per line on stderr starting with the protocol section, or 2 on an internal error.
      It reads the words file at #{Vocabulary::PATH} when one is there, and no environment variable.

      nomos compose prints a message body on stdout and its advice on stderr, and exits 1 without a body when the
      rules of nomos check refuse it. It never sends. Toward a person (the team segment local, or no team segment)
      it takes --title and the block: --kind KIND with --option ID=LABEL (repeat), --select one|many,
      --recommended ID (repeat), --default ID, --answer-text optional|required, --blocks TEXT or --blocks-none,
      --meanwhile TEXT, --if-silent TEXT, --terminal TEXT (an action only, with TEXT as a code span in the text),
      --outcome done|partial|failed, --follows ID, --replaces ID, --attach PATH=LABEL (repeat) and
      --link URL=LABEL (repeat); or --block FILE, one JSON object of the fields.
    TEXT

    module_function

    def main(argv, stdin: $stdin, stdout: $stdout, stderr: $stderr)
      command, *rest = argv
      case command
      when 'check' then check(rest, stdin, stderr)
      when 'compose' then compose(rest, stdin, stdout, stderr)
      when 'help', '-h', '--help'
        stdout.puts USAGE
        0
      when 'version', '--version'
        stdout.puts 'nomos v0'
        0
      else
        stderr.puts internal("nomos: unknown command #{command.inspect}"), USAGE
        2
      end
    rescue Exception => e
      raise if e.is_a?(SystemExit) || e.is_a?(SignalException)

      stderr.puts internal("nomos #{command}: #{e.class}: #{e.message.lines.first.to_s.strip}")
      2
    end

    def check(argv, stdin, stderr)
      words = nil
      OptionParser.new { |options| options.on('--words FILE') { |path| words = path } }.parse!(argv)
      raise ArgumentError, "unexpected argument #{argv.first}" unless argv.empty?

      vocabulary = words ? Vocabulary.load(words) : Vocabulary.installed
      message = Envelope.read(stdin).to_message
      refusals = Rules.refusals(Rules.check(message, vocabulary: vocabulary, advice: false))
      return 0 if refusals.empty?

      stderr.write(limited(refusals.map(&:reason)))
      1
    rescue Envelope::Invalid, Vocabulary::Invalid, OptionParser::ParseError, ArgumentError, IOError, SystemCallError => e
      stderr.puts internal("nomos check: #{e.message}")
      2
    end

    def compose(argv, stdin, stdout, stderr)
      settings = { block: {} }
      block_file = nil
      parser = OptionParser.new do |options|
        options.on('--to ADDRESS') { |value| settings[:to] = value }
        options.on('--from ADDRESS') { |value| settings[:from] = value }
        options.on('--within DURATION') do |value|
          settings[:within] = Clock.duration(value) or raise ArgumentError, "invalid --within #{value}; use a form such as 30m or 1h30m"
        end
        options.on('--text FILE') { |value| settings[:text] = value }
        options.on('--words FILE') { |value| settings[:words] = value }
        options.on('--now TIME') { |value| settings[:now] = Time.iso8601(value) }
        options.on('--title TEXT') { |value| settings[:title] = value }
        options.on('--block FILE') { |value| block_file = value }
        block_options(options, settings[:block])
      end
      transport, *extra = parser.parse(argv)
      raise ArgumentError, "unexpected argument #{extra.first}" unless extra.empty?
      raise ArgumentError, 'compose takes --to ADDRESS' unless settings[:to]

      text = settings[:text] && settings[:text] != '-' ? Text.read(settings[:text], max_bytes: Envelope::MAX_BYTES) : read_stdin(stdin)
      vocabulary = settings[:words] ? Vocabulary.load(settings[:words]) : Vocabulary.installed
      result = Compose.new(transport: transport, to: settings[:to], from: settings[:from], within: settings[:within],
                           text: text, title: settings[:title], block: block(settings[:block], block_file),
                           vocabulary: vocabulary, now: settings[:now] || Time.now).call
      if result.body
        result.advice.each { |flag| stderr.puts "advice #{flag.reason}" }
        stdout.write(result.body)
        0
      else
        stderr.write(limited(result.refusals.map(&:reason)))
        1
      end
    rescue Compose::Usage, Vocabulary::Invalid, OptionParser::ParseError, ArgumentError, IOError, SystemCallError,
           JSON::ParserError => e
      stderr.puts internal("nomos compose: #{e.message}")
      2
    end

    def block_options(options, block)
      many = ->(key, value) { (block[key] ||= []) << value }
      options.on('--kind KIND') { |value| block['kind'] = value }
      options.on('--option ID=LABEL') { |value| many.call('options', pair(value, :first)) }
      options.on('--select WHICH') { |value| block['select'] = value }
      options.on('--recommended ID') { |value| many.call('recommended', value) }
      options.on('--default ID') { |value| block['default'] = value }
      options.on('--answer-text WHICH') { |value| block['text'] = value }
      options.on('--blocks TEXT') { |value| block['blocks'] = value }
      options.on('--blocks-none') { block['blocks'] = nil }
      options.on('--meanwhile TEXT') { |value| block['meanwhile'] = value }
      options.on('--if-silent TEXT') { |value| block['if_silent'] = value }
      options.on('--terminal TEXT') { |value| block['terminal'] = { 'text' => value } }
      options.on('--outcome OUTCOME') { |value| block['outcome'] = value }
      options.on('--follows ID') { |value| block['follows'] = value }
      options.on('--replaces ID') { |value| block['replaces'] = value }
      options.on('--attach PATH=LABEL') { |value| many.call('files', pair(value, :last, 'path')) }
      options.on('--link URL=LABEL') { |value| many.call('links', pair(value, :last, 'url')) }
    end

    # ID=LABEL split at the first "=", PATH=LABEL and URL=LABEL at the last, since a URL's query holds "=".
    def pair(value, at, key = 'id')
      index = at == :first ? value.index('=') : value.rindex('=')
      raise ArgumentError, "#{value} is not NAME=LABEL" unless index

      { key => value[0...index], 'label' => value[(index + 1)..] }
    end

    def block(flags, file)
      kind = flags['kind']
      if file
        raise ArgumentError, '--block FILE and block flags are given together' unless (flags.keys - ['kind']).empty?

        data = Nomos.strict_json(Text.read(file, max_bytes: Block::MAX_BYTES * 4))
        raise ArgumentError, '--block FILE holds no JSON object' unless data.is_a?(Hash)
        raise ArgumentError, "--kind #{kind} differs from the block's kind #{data['kind']}" if kind && data['kind'] && kind != data['kind']

        return kind && !data.key?('kind') ? { 'kind' => kind }.merge(data) : data
      end
      return nil if flags.empty?

      block = flags.dup
      recommended = block['recommended']
      block['recommended'] = recommended.first if recommended&.one? && block['select'] != 'many'
      block
    end

    def read_stdin(stdin)
      stdin.binmode
      text = String.new(stdin.read(Envelope::MAX_BYTES + 1).to_s).force_encoding(Encoding::UTF_8)
      raise IOError, "the text exceeds #{Envelope::MAX_BYTES} bytes" if text.bytesize > Envelope::MAX_BYTES
      raise IOError, 'the text is not UTF-8' unless text.valid_encoding?

      text
    end

    # The one line of an exit 2, on one line and within 4 KiB, since it may echo input.
    def internal(line) = line.gsub(/\s+/, ' ').byteslice(0, MAX_REASONS - 1).scrub('')

    # LINES joined, cut to fit 4 KiB with a closing count of what was left out.
    def limited(lines)
      kept = []
      size = 0
      lines.each_with_index do |line, index|
        rest = lines.size - index - 1
        reserve = rest.zero? ? 0 : 40
        break if size + line.bytesize + 1 + reserve > MAX_REASONS

        kept << line
        size += line.bytesize + 1
      end
      kept << "#{lines.size - kept.size} more reasons omitted" if kept.size < lines.size
      kept.map { |line| "#{line}\n" }.join.byteslice(0, MAX_REASONS).scrub('')
    end
  end
end
