# frozen_string_literal: true

require_relative 'clock'
require_relative 'text'

module Nomos
  # The human's words, read from one sectioned file. Plain lines before any header are relative-time words; each
  # [section] adds to the English set built in. Only English ships with nomos; another language's words come from a
  # local file, installed at PATH for nomos check.
  module Vocabulary
    class Invalid < ArgumentError; end

    PATH = '/etc/nomos/words'
    MAX_BYTES = 65_536
    SECTIONS = %w[relative deadline stamp clock-prefix headings deadline-sentence clock zone].freeze
    SINGLE = %w[deadline-sentence clock zone].freeze
    ENGLISH = { 'deadline-sentence' => 'Answer by %{time}.', 'clock' => '%Y-%m-%d %H:%M %:z', 'zone' => '+00:00' }.freeze
    TIME_SLOT = '%{time}'

    module_function

    def parse(lines)
      sections = SECTIONS.to_h { |name| [name, []] }
      current = 'relative'
      lines.each do |line|
        text = line.strip
        next if text.empty? || text.start_with?('#')

        if (header = text[/\A\[([a-z-]+)\]\z/, 1])
          raise Invalid, "unknown words section [#{header}]" unless sections.key?(header)

          current = header
        else
          sections[current] << text
        end
      end
      validate(sections)
    end

    def load(path) = parse(Text.read(path, max_bytes: MAX_BYTES).lines)

    # The words at PATH, or the English set when no file is there.
    def installed(path = PATH) = File.exist?(path) ? load(path) : parse([])

    def setting(vocabulary, name) = vocabulary.fetch(name, []).first || ENGLISH.fetch(name)

    def validate(sections)
      unless [0, 4].include?(sections['headings'].length)
        raise Invalid, '[headings] needs four lines: Situation, Background, Assessment, Recommendation'
      end
      SINGLE.each { |name| raise Invalid, "[#{name}] holds one line" if sections[name].length > 1 }
      sentence = setting(sections, 'deadline-sentence')
      raise Invalid, "[deadline-sentence] holds #{TIME_SLOT} once" unless sentence.scan(TIME_SLOT).one?

      zone = setting(sections, 'zone')
      raise Invalid, "[zone] is an offset such as +00:00, not #{zone}" unless zone.match?(Clock::OFFSET)
      raise Invalid, "[clock] #{setting(sections, 'clock')} does not read back as a time" unless Clock.readable?(setting(sections, 'clock'), zone)

      sections
    end
  end
end
