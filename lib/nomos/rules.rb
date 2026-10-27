# frozen_string_literal: true

require_relative 'address'
require_relative 'advice'
require_relative 'block'
require_relative 'flag'
require_relative 'text'

module Nomos
  # The one place every rule is run from. A rule of level :must reads the message alone, never the clock, the
  # command, the event, the host or the id, so a message accepted where it is sent is accepted where it arrives.
  module Rules
    # A reply whose first line is a progress note closes the request without what it asked for (5.3).
    PROGRESS = /\A\s*\[progress\]/i

    module_function

    # Every flag on MESSAGE, sorted by line. ADVICE false runs only what nomos check needs: no clock, no file system
    # and no templates. NOW and TEMPLATES serve the advice.
    def check(message, vocabulary: {}, now: Time.now, templates: nil, words: [], advice: true)
      return [] if Address.person?(message.from)

      flags = []
      if advice
        deadline = message.kind == 'request' ? message.due : nil
        flags.concat(Advice.new(templates: templates, words: words, now: now, vocabulary: vocabulary).check(message.body, deadline: deadline))
      end
      if message.kind == 'reply' && message.body.lines.first.to_s.match?(PROGRESS)
        flags << Flag.new(1, 'progress reply', 'a progress note does not replace the result a request asked for; send it with keryx send --re', '5.3', :must)
      end
      unless message.human == false
        flags.concat(Block.new(message.body, kind: message.kind, due: message.due, human: message.human,
                                             vocabulary: vocabulary, advice: advice).flags)
      end
      flags.sort_by { |flag| [flag.line, flag.kind, flag.text] }
    end

    def refusals(flags) = flags.select(&:must?)

    # Whether nomos check reads ADDRESS as a person: the team segment local or no team segment (D2).
    def human?(address) = Address.form(address) != :agent
  end
end
