# frozen_string_literal: true

require 'minitest/autorun'
require 'json'
require 'time'
require_relative '../lib/nomos/cli'

# Synthetic messages for the nomos library tests: the agent orq.alpha@box writes to the person ana.local@box.
module NomosSupport
  DUE = Time.utc(2026, 10, 26, 11, 0, 0)
  ENTRY = File.expand_path('../bin/nomos', __dir__)
  ASK = <<~BODY
    Where process decisions live
    ```nomos
    {"kind": "choice",
     "options": [{"id": "keep", "label": "Keep as it is"}, {"id": "move", "label": "Move to the Project"}],
     "blocks": null, "meanwhile": "I continue with the file", "if_silent": "I keep it as it is",
     "default": "keep"}
    ```
    Nothing waits on this; I continue with the file.

    1. Keep as it is (`keep`).
    2. Move to the Project (`move`).

    If no answer comes by 2026-10-26 08:00 -03:00, I keep it as it is.

    nomos v0 human message
  BODY
  NOTICE = <<~BODY
    The usage page answers again
    ```nomos
    {"kind": "notice"}
    ```
    The page answers again.

    nomos v0 human message
  BODY
  WORDS = <<~TEXT
    [deadline]
    zuntil
    [deadline-sentence]
    Answer zuntil %{time}.
    [clock]
    %d/%m klo %Hh%M
    [zone]
    -03:00
  TEXT

  def envelope(body, kind: 'request', from: 'orq.alpha@box', to: 'ana.local@box', due: DUE, event: 'send', command: 'ask')
    { 'check' => 1, 'event' => event, 'host' => 'box', 'command' => event == 'receive' ? nil : command,
      'message' => { 'keryx' => 2, 'id' => 'ZZZZZZZZZZZZZZZZZZZZZZZZZZ', 'kind' => kind, 'from' => from, 'to' => to,
                     'thread' => nil, 'in_reply_to' => nil, 'created_at' => '2026-10-26T10:00:00Z',
                     'due_at' => due&.iso8601, 'body' => body } }
  end

  def nomos_message(body, **options) = Nomos::Envelope.new(envelope(body, **options)).to_message

  def refused(body, vocabulary: {}, **options)
    Nomos::Rules.refusals(Nomos::Rules.check(nomos_message(body, **options), vocabulary: vocabulary, advice: false))
  end

  def refused_kinds(body, **options) = refused(body, **options).map(&:kind).uniq.sort

  def all_kinds(body, vocabulary: {}, **options)
    Nomos::Rules.check(nomos_message(body, **options), vocabulary: vocabulary, now: DUE - 3600).map(&:kind).uniq.sort
  end

  def words = Nomos::Vocabulary.parse(WORDS.lines)
end
