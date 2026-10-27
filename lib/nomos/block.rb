# frozen_string_literal: true

require 'json'
require 'uri'
require_relative 'clock'
require_relative 'flag'
require_relative 'json'
require_relative 'text'
require_relative 'vocabulary'

module Nomos
  # The form of a message to a human (protocol 10.5 to 10.9): the title on line 1, the nomos block on line 2, the
  # text that stands alone, the deadline it states and the footer. Toward a human every flag of a broken MUST is
  # level :must; toward a recipient only a claim in the body points at (human nil) and in a withdrawal they are
  # :advice, since the rule may not apply.
  class Block
    OPENING = /\A(`{3,}|~{3,})nomos[ \t]*\z/
    CLAIM = /\A {0,3}(?:`{3,}|~{3,})nomos/
    FENCE = /\A {0,3}(`{3,}|~{3,})[ \t]*(\S*)/
    MAX_LINES = 16
    MAX_BYTES = 1024
    FACT_MAX = 80
    LABEL_MAX = 60
    TOLERANCE = 300
    ASKS = %w[decision choice question action].freeze
    COMMON = %w[kind files links replaces follows].freeze
    FIELDS = {
      'decision' => %w[options select recommended text blocks meanwhile if_silent],
      'choice' => %w[options select recommended text blocks meanwhile if_silent default],
      'question' => %w[options select recommended text blocks meanwhile if_silent],
      'action' => %w[blocks meanwhile if_silent],
      'suggestion' => [], 'notice' => [], 'result' => %w[outcome], 'answer' => %w[answer]
    }.freeze
    KNOWN = (COMMON + FIELDS.values.flatten).uniq.freeze
    OPTION_ID = /\A[a-z][a-z0-9-]{0,23}\z/
    MESSAGE_ID = /\A[0-9A-HJKMNP-TV-Z]{26}\z/
    HTML = %r{<[\p{L}/]}
    FIELD_TIME = /(?<![\w:])(?:\d{4}-\d{2}-\d{2}[T ])?\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?\s*(?:#{Clock::ZONE})(?![\w:+-])/
    DATE = %r{(?<![\d/-])(?:\d{4}-\d{2}-\d{2}|\d{2}/\d{2})(?![\d/])}
    CLOCK = /(?<![\w:])\d{1,2}(?::\d{2}|h\d{2})(?![\w:])/
    EXTENSIONS = %w[md markdown txt rb erb yml yaml json toml sh bash py go rs tf hcl js ts css html sql csv log conf
                    ini].freeze
    DENIED = /secret|credential|password|token|kubeconfig|\.env|id_rsa|id_ed25519|\.pem|\.key/i
    MAX_FILE = 1024 * 1024
    DECISION_HEADINGS = %w[Situation Background Assessment Recommendation].freeze
    OPEN_HINT = 'the block opens on line 2 with a ```nomos fence'

    def self.bare?(line, after = nil)
      line.to_s.match?(/\A\s*\{\s*"kind"/) || (line.to_s.strip == '{' && after.to_s.match?(/\A\s*"kind"/))
    end

    # Whether BODY says it follows the form: a nomos fence on lines 1 to 3, the footer, or a bare object of a kind.
    def self.claimed?(body)
      lines = body.lines.map(&:chomp)
      lines.first(3).any? { |line| line.match?(CLAIM) } || Text.footer?(lines) || bare?(lines[1], lines[2]) ||
        bare?(lines[2], lines[3])
    end

    attr_reader :flags

    # KIND is the transport kind and DUE the request's deadline. ADVICE false skips what reads the file system.
    def initialize(body, kind:, due:, human:, vocabulary: {}, advice: true)
      @body = body
      @lines = body.lines
      @kind = kind
      @due = due
      @human = human
      @strict = human == true && kind != 'withdrawal'
      @advice = advice
      @vocabulary = vocabulary
      @translations = vocabulary.fetch('headings', [])
      prefixes = (['at'] + vocabulary.fetch('clock-prefix', [])).map { |word| Regexp.escape(word).gsub('\ ', '\s+') }.join('|')
      @clock = /#{CLOCK}|(?<![\p{L}])(?:#{prefixes})\s+\d{1,2}h(?![\w:])/i
      @flags = []
      run
    end

    private

    def must(line, kind, text, section) = @flags << Flag.new(line, kind, text, section, @strict ? :must : :advice)

    def advise(line, kind, text, section) = @flags << Flag.new(line, kind, text, section, :advice)

    def run
      chomped = @lines.map(&:chomp)
      if @human == true && chomped[0].to_s.match?(Text::TAG)
        must(1, 'title tag', 'a message to a human opens with no bracketed tag', '10.5')
      end
      footer if @human == true
      fence = chomped[1].to_s[OPENING, 1]
      unless fence
        placed = placement(chomped)
        title(chomped[0].to_s) if @human == true || placed || self.class.claimed?(@body)
        missing unless placed || @human != true
        return
      end
      title(chomped[0].to_s)
      data = parse(fence) or return
      kind = data['kind']
      if kind == 'answer'
        advise(line_of('kind'), 'block kind', 'an agent message carries no answer block; the page draws nothing for it', '10.9')
        return
      end
      unless FIELDS.key?(kind)
        must(line_of('kind'), 'block field', "kind #{kind.inspect} is not one of the seven kinds or answer", '10.7')
        return
      end
      fields(data, kind)
      asks(kind)
      deadline(kind)
      headings if kind == 'decision'
    end

    def footer
      return if Text.footer?(@lines)

      must(@lines.length, 'block footer', "an agent message to a human ends with the line #{Text::HUMAN_FOOTER}", '10.5')
    end

    def missing
      if @kind == 'request'
        must(1, 'ask without block', 'an ask to a human carries a nomos block on line 2', '10.7')
      else
        must(2, 'block missing', "every agent message to a human carries a nomos block on line 2; #{OPEN_HINT}", '10.7')
      end
    end

    def placement(chomped)
      second = chomped[1].to_s
      found = chomped.first(3).each_with_index.find { |line, _| line.match?(CLAIM) }
      reason =
        if (index = [1, 2].find { |number| self.class.bare?(chomped[number], chomped[number + 1]) && !(number == 2 && second.match?(FENCE)) })
          [index + 1, "line #{index + 1} holds a bare JSON object; #{OPEN_HINT}"]
        elsif (match = second.match(FENCE)) && (match[2].start_with?('nomos') || self.class.bare?(chomped[2], chomped[3]))
          info = match[2].empty? ? 'no info string' : "info string #{match[2]}"
          [2, "line 2 opens a fence with #{info}; #{OPEN_HINT}"]
        elsif found
          [found[1] + 1, "the nomos fence is on line #{found[1] + 1}; #{OPEN_HINT}"]
        elsif Text.footer?(chomped)
          [2, "the body ends with the human message footer and line 2 opens no nomos block; #{OPEN_HINT}"]
        end
      must(reason.first, 'block placement', reason.last, '10.7') if reason
      !reason.nil?
    end

    def title(line)
      problem = Text.title_problem(line) or return

      must(1, 'block title', "#{problem}; line 1 is a plain title of at most 80 characters, not a heading, list, quote or fence", '10.7')
    end

    def parse(fence)
      closing = /\A#{Regexp.escape(fence[0])}{#{fence.size},}[ \t]*\z/
      @inner = @lines[2, MAX_LINES - 1].to_a
      close = @inner.index { |line| line.chomp.match?(closing) }
      unless close
        later = @lines.drop(2).index { |line| line.chomp.match?(closing) }
        return must(2, 'block placement', 'the nomos block does not close', '10.7') && nil unless later

        return must(2, 'block size', "the block runs #{later + 2} lines, over 16 including its fences", '10.7') && nil
      end
      @inner = @inner.first(close)
      @after = @lines.drop(close + 3).join
      bytes = @lines[1, close + 2].sum(&:bytesize)
      data = begin
        Nomos.strict_json(@inner.join)
      rescue JSON::ParserError, EncodingError
        nil
      end
      if bytes > MAX_BYTES
        name, size = data.is_a?(Hash) ? data.map { |key, value| [key, JSON.generate(value).bytesize] }.max_by(&:last) : nil
        longest = name ? "longest field #{name} (#{size} bytes)" : "longest line #{@inner.map(&:bytesize).max} bytes"
        must(2, 'block size', "the block is #{bytes} bytes, over 1,024 including its fences; #{longest}", '10.7')
        return
      end
      return data if data.is_a?(Hash)

      must(2, 'block json', 'the block does not hold one JSON object (RFC 8259, no comment or repeated key)', '10.7')
      nil
    end

    def line_of(key)
      index = @inner.index { |line| line.include?("\"#{key}\"") }
      index ? index + 3 : 2
    end

    def fields(data, kind)
      @kind_of_block = kind
      %w[due deadline].each do |key|
        must(line_of(key), 'block time', "the block has #{key}; the deadline goes in the request and once in the text", '10.7') if data.key?(key)
      end
      must(line_of('title'), 'block field', 'the block has title; the title is line 1', '10.7') if data.key?('title')
      ((data.keys & KNOWN) - COMMON - FIELDS.fetch(kind)).each do |key|
        if key == 'default' && kind == 'decision'
          must(line_of(key), 'block default', 'a decision has no default; silence never decides it', '10.8')
        elsif key == 'options'
          must(line_of(key), 'block options', "#{kind} takes no options", '10.7')
        else
          must(line_of(key), 'block field', "#{kind} takes no #{key}", '10.7')
        end
      end
      strings(data).each { |text| must(2, 'block html', "a string holds HTML: #{text}", '10.7') if text.match?(HTML) }
      @ids = options(data, kind)
      choices(data, @ids)
      facts(data, kind, @ids)
      identifiers(data, kind)
      entries(data)
    end

    def strings(value)
      case value
      when String then [value]
      when Hash then value.flat_map { |key, item| [key, *strings(item)] }
      when Array then value.flat_map { |item| strings(item) }
      else []
      end
    end

    def free(value, max, what, key)
      unless value.is_a?(String) && !value.strip.empty? && value.length <= max && !value.match?(/[[:cntrl:]]/)
        return must(line_of(key), 'block field', "#{what} is a non-blank single-line text of at most #{max} characters", '10.7')
      end

      if value.match?(FIELD_TIME) || value.match?(DATE)
        must(line_of(key), 'block time', "#{what} holds a time or a date: #{value}", '10.7')
      elsif value.match?(@clock)
        advise(line_of(key), 'block time', "#{what} holds a clock time: #{value}", '10.7')
      end
    end

    def options(data, kind)
      @labels = []
      return [] if kind == 'action' || !(data.key?('options') || %w[decision choice].include?(kind))

      list = data['options']
      range = kind == 'question' ? 1..6 : 2..6
      unless list.is_a?(Array) && range.cover?(list.size)
        must(line_of('options'), 'block options', "#{kind} needs #{range.first} to 6 options", '10.7')
        return [] unless list.is_a?(Array)
      end
      ids = list.map do |entry|
        id, label = entry.values_at('id', 'label') if entry.is_a?(Hash)
        must(line_of('options'), 'block options', "option id #{id.inspect} breaks the id rule", '10.7') unless id.is_a?(String) && id.match?(OPTION_ID)
        free(label, LABEL_MAX, "option #{id}'s label", 'options')
        @labels << label if label.is_a?(String)
        id
      end
      must(line_of('options'), 'block options', 'two options share an id', '10.7') unless ids.uniq.size == ids.size
      ids
    end

    def choices(data, ids)
      if data.key?('select') && !(%w[one many].include?(data['select']) && ids.any?)
        must(line_of('select'), 'block field', 'select is one or many, with options', '10.7')
      end
      if data.key?('recommended')
        value = data['recommended']
        list = value.is_a?(Array) && data['select'] == 'many' ? value : [value]
        unless list.any? && list.uniq.size == list.size && list.all? { |id| ids.include?(id) }
          must(line_of('recommended'), 'block options', "recommended names no option: #{value.inspect}", '10.7')
        end
      end
      return unless data.key?('default') && @kind_of_block == 'choice' && !ids.include?(data['default'])

      must(line_of('default'), 'block default', "default names no option: #{data['default'].inspect}", '10.8')
    end

    def facts(data, kind, ids)
      return unless ASKS.include?(kind)

      if kind != 'action' && data.key?('text')
        must(line_of('text'), 'block field', 'text is optional or required', '10.7') unless %w[optional required].include?(data['text'])
        if data['text'] == 'optional' && ids.empty? && kind == 'question'
          advise(line_of('text'), 'block field', 'a question without options requires words', '10.7')
        end
      end
      if !data.key?('blocks')
        must(2, 'block field', 'an ask says what blocks, or null', '10.7')
      elsif !data['blocks'].nil?
        free(data['blocks'], FACT_MAX, 'blocks', 'blocks')
      end
      %w[meanwhile if_silent].each do |key|
        data.key?(key) ? free(data[key], FACT_MAX, key, key) : must(2, 'block field', "an ask says #{key}", '10.7')
      end
    end

    def identifiers(data, kind)
      if kind == 'result'
        must(line_of('outcome'), 'block field', 'a result says its outcome: done, partial or failed', '10.7') unless %w[done partial failed].include?(data['outcome'])
        must(2, 'block id', 'a result says the request it follows', '10.7') unless data.key?('follows')
      end
      %w[replaces follows].each do |key|
        next unless data.key?(key)

        must(line_of(key), 'block id', "#{key} is not a transport message id", '10.7') unless data[key].is_a?(String) && data[key].match?(MESSAGE_ID)
      end
    end

    def entries(data)
      { 'files' => 'path', 'links' => 'url' }.each do |key, target|
        next unless data.key?(key)

        list = data[key]
        unless list.is_a?(Array) && list.size <= 3 && list.all?(Hash)
          must(line_of(key), 'block field', "#{key} holds at most 3 entries", '10.7')
          next
        end
        list.each do |entry|
          free(entry['label'], LABEL_MAX, "a #{key.delete_suffix('s')} label", key)
          target == 'path' ? file(entry['path']) : link(entry['url'])
        end
      end
    end

    def link(url)
      uri = URI.parse(url.to_s)
      return if uri.is_a?(URI::HTTPS) && !uri.host.to_s.empty?

      must(line_of('links'), 'block field', "a link is an https URL: #{url}", '10.7')
    rescue URI::InvalidURIError
      must(line_of('links'), 'block field', "a link is an https URL: #{url}", '10.7')
    end

    def file(path)
      unless path.is_a?(String) && path.match?(%r{\A~?/})
        return must(line_of('files'), 'block file', "#{path}: a file path is absolute or starts with ~/", '10.7')
      end
      return unless @advice

      problem = file_problem(path)
      advise(line_of('files'), 'block file', "#{path}: #{problem}", '10.7') if problem
    end

    def file_problem(path)
      real = File.realpath(File.expand_path(path))
      home = File.join(File.realpath(Dir.home), '')
      parts = [path.delete_prefix('~/'), real.start_with?(home) ? real.delete_prefix(home) : real].flat_map do |text|
        text.split('/').reject(&:empty?)
      end
      return 'a folder or name in the path starts with a dot' if parts.any? { |part| part.start_with?('.') }
      return 'the path has a secret-like name' if parts.any? { |part| part.match?(DENIED) }
      return 'not a text extension the page opens' unless EXTENSIONS.include?(File.extname(real).delete_prefix('.').downcase)

      stat = File.stat(real)
      return 'not a regular file' unless stat.file?
      return 'over 1 MiB' if stat.size > MAX_FILE
      return 'not readable' unless File.readable?(real)

      nil
    rescue SystemCallError, ArgumentError
      'no such readable file'
    end

    def asks(kind)
      @labels.each do |label|
        must(line_of('options'), 'label not in text', label, '10.7') unless @after.include?(label)
      end
      @ids.each do |id|
        next unless id.is_a?(String) && id.match?(OPTION_ID)
        next if @after.match?(/(?<![A-Za-z0-9_-])#{Regexp.escape(id)}(?![A-Za-z0-9_-])/)

        must(line_of('options'), 'id not in text', id, '10.7')
      end
      if ASKS.include?(kind)
        must(2, 'ask not a request', "a #{kind} goes as keryx ask with --within", '10.5') unless @kind == 'request'
        must(2, 'ask without deadline', "a #{kind} goes with --within", '10.5') unless @kind == 'request' && @due
      elsif @kind == 'request'
        must(2, 'request without ask', "a request to a human carries one ask, and a #{kind} is none", '10.6')
      end
    end

    # The text states the request's deadline once, equal to the transport's (10.7).
    def deadline(kind)
      return unless ASKS.include?(kind) && @kind == 'request' && @due

      zone = Vocabulary.setting(@vocabulary, 'zone')
      text = @after.sub(/\n*^#{Regexp.escape(Text::HUMAN_FOOTER)}\s*\z/, "\n")
      found = Clock.written(text, zone: zone, reference: @due)
      equal = found.count { |time, _| (time - @due).abs <= TOLERANCE }
      line = @lines.length
      if equal.zero?
        stated = Clock.write(@due, clock: Vocabulary.setting(@vocabulary, 'clock'), zone: zone)
        must(line, 'deadline not in text', "the text after the block states the request's deadline, #{stated}", '10.7')
      elsif equal > 1
        advise(line, 'deadline repeated', 'the text states the deadline more than once', '10.7')
      end
      words = (%w[by until before due deadline] + @vocabulary.fetch('deadline', [])).map(&:downcase)
      found.each do |time, position|
        next if (time - @due).abs <= TOLERANCE

        before = text[[position - 40, 0].max...position].downcase
        next unless words.any? { |word| before.match?(/(?<![\p{L}])#{Regexp.escape(word)}(?![\p{L}])/) }

        advise(line, 'deadline differs', "a time after a deadline word differs from the request's deadline: #{text[position, 24].lines.first.strip}", '10.7')
      end
    end

    def headings
      present = Text.prose(@body).scan(/^\#{1,6}\s+(.+?)\s*#*$/).flatten.map { |heading| heading.strip.downcase }
      line = @lines.rindex { |text| !text.strip.empty? }.to_i + 1
      DECISION_HEADINGS.each_with_index do |heading, index|
        names = [heading, @translations[index]].compact.map(&:downcase)
        advise(line, 'missing heading', heading, '10.4') if (names & present).empty?
      end
    end
  end
end
