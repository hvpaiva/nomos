# frozen_string_literal: true

module Nomos
  # One finding on a body. A flag of level :must breaks a MUST or MUST NOT of the protocol and is refused every
  # time; a flag of level :advice is printed and never refused.
  Flag = Data.define(:line, :kind, :text, :section, :level) do
    def initialize(line:, kind:, text:, section: nil, level: :advice) = super

    def must? = level == :must

    def to_s = "line #{line}: #{kind}: #{text.gsub(/\s+/, ' ')}"

    def reason = "#{section} #{text.gsub(/\s+/, ' ')} (line #{line})"
  end

  # A message as the rules read it. kind is the transport kind (request, message, reply or withdrawal), due the
  # request's deadline as a Time or nil, and human true for a person, false for an agent and nil when only a claim
  # in the body can tell.
  Message = Data.define(:body, :kind, :from, :to, :due, :human)
end
