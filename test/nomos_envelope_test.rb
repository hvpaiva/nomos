# frozen_string_literal: true

require 'stringio'
require_relative 'nomos_support'

class NomosEnvelopeTest < Minitest::Test
  include NomosSupport

  def read(text) = Nomos::Envelope.read(StringIO.new(text))

  def test_reads_a_send_and_a_receive
    sent = read("#{JSON.generate(envelope(ASK))}\n")
    assert_equal ['send', 'box', 'ask'], [sent.event, sent.host, sent.command]
    message = sent.to_message
    assert_equal ['request', 'orq.alpha@box', 'ana.local@box', DUE, true], [message.kind, message.from, message.to, message.due, message.human]
    received = read(JSON.generate(envelope(ASK, event: 'receive')))
    assert_nil received.command
    assert_equal message, received.to_message
    assert_equal false, read(JSON.generate(envelope('x', to: 'rev-1.alpha@box', due: nil))).to_message.human
  end

  def test_refuses_what_is_no_version_one_envelope
    base = envelope(ASK)
    [
      'x', '[]', JSON.generate(base.merge('check' => '1')), JSON.generate(base.merge('event' => nil)),
      JSON.generate(base.merge('command' => 3)), JSON.generate(base.merge('message' => 'x')),
      JSON.generate(base.merge('message' => base['message'].merge('body' => nil))),
      JSON.generate(base.merge('message' => base['message'].merge('to' => 1))),
      JSON.generate(base.merge('message' => base['message'].merge('due_at' => 5))),
      "{\"check\": 1, \"x\": \"\xC3\"}"
    ].each do |text|
      assert_raises(Nomos::Envelope::Invalid, text) { read(text) }
    end
    assert_raises(Nomos::Envelope::Invalid) { read(' ' * (Nomos::Envelope::MAX_BYTES + 1)) }
  end
end
