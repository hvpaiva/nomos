# frozen_string_literal: true

module Nomos
  module PreSend
    # The rules of lib/nomos, run on one message the command sends. A flag of level must is refused every time.
    class Checker
      def initialize(templates: File.join(ROOT, 'templates'), words: [], now: Time.now, vocabulary: {})
        @templates = templates
        @words = words
        @now = now
        @vocabulary = vocabulary
      end

      def check(body, context = nil)
        unless context
          advice = Nomos::Advice.new(templates: @templates, words: @words, now: @now, vocabulary: @vocabulary)
          return advice.check(body).sort_by { |flag| [flag.line, flag.kind, flag.text] }
        end

        due = context.action == 'ask' && context.within ? @now + context.within : nil
        message = Nomos::Message.new(body: body, kind: KINDS.fetch(context.action, 'reply'), from: nil,
                                     to: context.recipient, due: due, human: context.human)
        Nomos::Rules.check(message, vocabulary: @vocabulary, now: @now, templates: @templates, words: @words)
      end
    end
  end
end
