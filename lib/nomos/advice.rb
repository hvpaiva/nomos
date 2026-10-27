# frozen_string_literal: true

require 'date'
require_relative 'clock'
require_relative 'flag'
require_relative 'text'

module Nomos
  # What a literal match can point at but not judge: relative dates and future times (protocol 5.7), leftover
  # placeholders (11.3), a filled form's missing headings (6.4) and findings without a rank (8.1) or an evidence
  # class (7.2). Every flag is advice, read outside code and quoted text.
  class Advice
    FOOTER = /^nomos v\d+ [a-z][a-z ]*$/
    MULTIPART = %w[first-prompt handover plan-review].freeze
    RELATIVE = [
      'today', 'tomorrow', 'yesterday', 'tonight', 'this morning', 'this afternoon', 'this evening',
      'last night', 'next week', 'last week', 'this week', 'next month', 'last month', 'this month',
      'next year', 'last year', 'this year', 'next Monday', 'next Tuesday', 'next Wednesday',
      'next Thursday', 'next Friday', 'next Saturday', 'next Sunday'
    ].freeze
    PLACEHOLDER = /(?<![$\\{])\{[\p{L}][\p{L}\p{N}\s_@.'?|\/-]*\}(?!\})/
    DEADLINE_WORDS = %w[by until before due deadline].freeze
    STAMP_WORDS = %w[at sent checked ran].freeze

    def self.alternation(words) = words.map { |word| Regexp.escape(word).gsub('\ ', '\s+') }.join('|')

    # TEMPLATES is the directory of forms whose headings are read; nil skips the form checks.
    def initialize(templates: nil, words: [], now: Time.now, vocabulary: {})
      @deadline_words = (DEADLINE_WORDS + vocabulary.fetch('deadline', [])).map(&:downcase)
      @stamp_words = (STAMP_WORDS + vocabulary.fetch('stamp', [])).map(&:downcase)
      @joined_words = ['at', *vocabulary.fetch('clock-prefix', [])].map(&:downcase)
      @time_word = /(?<![\p{L}\p{N}_])(#{Advice.alternation(@deadline_words + @stamp_words)})(?![\p{L}\p{N}_])/i
      @templates = templates
      @now = now
      terms = (RELATIVE + words + vocabulary.fetch('relative', [])).map(&:strip).reject(&:empty?).uniq
      @relative = /(?<![\p{L}\p{N}_])(?:#{terms.map { |term| Regexp.escape(term).gsub('\\ ', '\\s+') }.join('|')})(?![\p{L}\p{N}_])/i
    end

    # DEADLINE, when the message is a request with one, is a time a future time may name.
    def check(body, deadline: nil)
      clean = Text.prose(body)
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
        flags << flag(match.begin(0), 'placeholder', match[0], '11.3')
      end
      mentioned = mentions(clean)
      relative_prose(mentioned).to_enum(:scan, @relative).each do
        match = Regexp.last_match
        flags << flag(match.begin(0), 'relative time', match[0], '5.7')
      end
      previous = 0
      mentioned.to_enum(:scan, Clock::TIME).each do
        match = Regexp.last_match
        from = previous
        previous = match.end(0)
        time = Clock.timestamp(match, @now)
        next unless time && time > @now + 300
        next if time.to_date > @now.getlocal(time.utc_offset).to_date
        next if deadline ? (time - deadline).abs <= 300 : deadline_word?(mentioned, match.begin(0), from)

        flags << flag(match.begin(0), 'future time', match[0], '5.7')
      end
      check_form(clean, flags) if @templates
      flags
    end

    private

    def flag(position, kind, text, section) = Flag.new(@line_numbers.fetch(position), kind, text, section, :advice)

    def mentions(text)
      text.lines.map do |line|
        pattern = line.count('"').even? ? /(?:(?<=\A|[\s(])"[^"\n]*")|“[^”\n]*”|«[^»\n]*»/ : /“[^”\n]*”|«[^»\n]*»/
        line.gsub(pattern) { |span| span.gsub(/[^\n]/, ' ') }
      end.join
    end

    def deadline_word?(text, position, from = 0)
      start = [(text.rindex("\n", position - 1) || -1) + 1, position - 200, from].max
      clause = text[start...position].split(/[.;,](?=\s)/, -1).last.to_s
      window = clause.split(/(?<=\s)(?=\S)/).last(6).join
      found = window.to_enum(:scan, @time_word).map do
        match = Regexp.last_match
        [match[1].downcase.gsub(/\s+/, ' '), match.begin(0), match.end(0)]
      end
      direct = ->(ending) { window[ending..].strip.empty? }
      deadline = found.select { |word, _, ending| @deadline_words.include?(word) && (word != 'by' || direct.call(ending)) }
      stamps = found.select do |word, opening, ending|
        next false unless @stamp_words.include?(word)

        joined = @joined_words.include?(word) && direct.call(ending) &&
                 deadline.any? { |_, _, close| window[close...opening].match?(/\A[\s:]*\z/) }
        !joined
      end
      deadline.any? && stamps.empty?
    end

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

    def check_form(clean, flags)
      lines = clean.lines.map(&:strip)
      footer_index = lines.rindex { |line| !line.empty? }
      return unless footer_index && lines[footer_index].match?(FOOTER)

      footer = lines[footer_index]
      paths = Dir.glob(File.join(@templates, '*.md')).sort
      raise IOError, "no templates in #{@templates}" if paths.empty?

      forms = paths.filter_map do |path|
        template = Text.read(path)
        sections = template.split(/^(nomos v\d+ [a-z][a-z ]*)\s*$/)
        index = sections.index(footer)
        [path, template, sections[index - 1]] if index
      end
      return unless forms.length == 1

      path, template, form = forms.first
      return if MULTIPART.include?(File.basename(path, '.md'))

      headings = Text.prose(form).scan(/^\#{2,6}\s+(.+?)\s*#*$/).flatten
      headings.reject! { |heading| heading.include?('{') }
      if File.basename(path) == 'report.md' && template.include?('any section with nothing to say')
        headings = []
      else
        headings.reject! { |heading| optional_heading?(heading, template) }
      end
      present = clean.scan(/^\#{1,6}\s+(.+?)\s*#*$/).flatten.map { |heading| normalize(heading) }
      headings.each do |heading|
        next if present.include?(normalize(heading))

        flags << Flag.new(footer_index + 1, 'missing heading', heading, '6.4', :advice)
      end
      check_findings(clean, flags) if File.basename(path) == 'review-findings.md'
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
        steps = false if steps && match[1].to_i > last_number && previous_blank
        next if steps && !ranked

        steps = false
        last_number = match[1].to_i
        starts << start
      end
      starts.each_with_index do |start, index|
        block = content[start...(starts[index + 1] || content.length)]
        line = @line_numbers.fetch(offset + start)
        title = block.lines.first.strip
        flags << Flag.new(line, 'finding missing rank', title, '8.1', :advice) unless block.match?(rank)
        unless block.match?(/\b(?:observed|code-grounded|sourced|hypothesis)\b/i)
          flags << Flag.new(line, 'finding missing evidence class', title, '7.2', :advice)
        end
      end
    end
  end
end
