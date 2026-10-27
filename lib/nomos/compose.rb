# frozen_string_literal: true

require 'json'
require_relative 'address'
require_relative 'clock'
require_relative 'flag'
require_relative 'rules'
require_relative 'text'
require_relative 'vocabulary'

module Nomos
  # Builds the body of one message and judges it by the rules nomos check applies; it never sends. Toward a human it
  # writes the title, the block, the text, the options and the deadline the text lacks, and the footer
  # (protocol 10.5 to 10.9); toward an agent the body is the text.
  class Compose
    class Usage < ArgumentError; end

    Result = Data.define(:body, :refusals, :advice)

    TRANSPORTS = { 'send' => 'message', 'ask' => 'request', 'reply' => 'reply' }.freeze
    KINDS = %w[decision choice question action suggestion notice result].freeze
    ORDER = %w[kind options select recommended default text blocks meanwhile if_silent outcome follows replaces files
               links].freeze
    TEMPLATES = File.expand_path('../../templates', __dir__)

    # WITHIN is the ask's deadline in seconds from NOW; BLOCK the block's fields as a Hash, kind included.
    def initialize(transport:, to:, text:, from: nil, within: nil, title: nil, block: nil, vocabulary: {}, now: Time.now,
                   templates: (File.directory?(TEMPLATES) ? TEMPLATES : nil))
      raise Usage, "unknown transport #{transport.inspect}; use send, ask or reply" unless TRANSPORTS.key?(transport)
      raise Usage, 'an ask takes --within' if transport == 'ask' && within.nil?
      raise Usage, 'only an ask takes --within' if transport != 'ask' && within
      raise Usage, "--to #{to.inspect} is not MEMBER.TEAM or a full address" if Address.form(to) == :unknown
      raise Usage, 'the text is empty' if text.strip.empty?

      @transport = transport
      @to = to
      @from = from
      @text = text
      @title = title
      @block = block
      @vocabulary = vocabulary
      @now = now
      @due = within && now + within
      @templates = templates
      @human = Rules.human?(to)
      validate
    end

    def call
      body = @human ? human_body : @text.sub(/\n*\z/, "\n")
      message = Message.new(body: body, kind: TRANSPORTS.fetch(@transport), from: @from.to_s, to: @to, due: @due, human: @human)
      flags = Rules.check(message, vocabulary: @vocabulary, now: @now, templates: @templates)
      refusals = flags.select(&:must?)
      Result.new(body: refusals.empty? ? body : nil, refusals: refusals, advice: flags.reject(&:must?))
    end

    private

    def validate
      unless @human
        raise Usage, 'a title or a block is only for a human recipient' if @title || @block

        return
      end
      raise Usage, 'a message to a human takes --title' if @title.to_s.strip.empty?
      raise Usage, 'a message to a human takes a block kind (--kind or --block)' unless @block.is_a?(Hash)
      raise Usage, "unknown block kind #{@block['kind'].inspect}" unless KINDS.include?(@block['kind'])
    end

    def human_body
      text = @text.sub(/\A(?:[ \t]*\n)+/, '').rstrip
      parts = [text]
      parts << option_list if listed?(text) == false
      parts << deadline_sentence if @due && !states_deadline?(text)
      parts.reject!(&:empty?)
      "#{@title}\n#{fence}\n\n#{parts.join("\n\n")}\n\n#{Text::HUMAN_FOOTER}\n"
    end

    def fence
      keys = @block.keys.sort_by { |key| [ORDER.index(key) || ORDER.size, key] }
      "```nomos\n{#{keys.map { |key| "#{JSON.generate(key)}: #{JSON.generate(@block[key])}" }.join(",\n ")}}\n```"
    end

    def options = @block['options'].is_a?(Array) ? @block['options'].grep(Hash) : []

    # nil when the block has no options; false when the text misses a label or an id.
    def listed?(text)
      return nil if options.empty?

      options.all? do |option|
        id = option['id'].to_s
        text.include?(option['label'].to_s) && text.match?(/(?<![A-Za-z0-9_-])#{Regexp.escape(id)}(?![A-Za-z0-9_-])/)
      end
    end

    def option_list = options.each_with_index.map { |option, index| "#{index + 1}. #{option['label']} (`#{option['id']}`)" }.join("\n")

    # Read as nomos check reads it: only a time written with its offset counts.
    def states_deadline?(text)
      Clock.written(text, zone: nil, reference: @due).any? { |time, _| (time - @due).abs <= Block::TOLERANCE }
    end

    def deadline_sentence
      zone = Vocabulary.setting(@vocabulary, 'zone')
      written = Clock.write(@due, clock: Vocabulary.setting(@vocabulary, 'clock'), zone: zone)
      Vocabulary.setting(@vocabulary, 'deadline-sentence').sub(Vocabulary::TIME_SLOT, written)
    end
  end
end
