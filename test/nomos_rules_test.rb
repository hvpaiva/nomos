# frozen_string_literal: true

require_relative 'nomos_support'

class NomosRulesTest < Minitest::Test
  include NomosSupport

  def test_a_progress_reply_is_refused_between_agents
    reply = { to: 'rev-1.alpha@box', kind: 'reply', due: nil, command: 'reply' }
    assert_equal ['progress reply'], refused_kinds("[progress] half of the tests run\n", **reply)
    assert_equal ['5.3'], refused("[Progress] half done\n", **reply).map(&:section)
    assert_empty refused("[accept] readback confirmed; go ahead\n", **reply)
    assert_empty refused("[progress] half of the tests run\n", **reply, kind: 'message', command: 'send --re')
    assert_empty refused("Result: the tests pass\n[progress] was sent before\n", **reply)
  end

  def test_a_person_sender_gets_no_rule
    garbage = "## [notice] no form\n"
    refute_empty refused(garbage, kind: 'message', due: nil)
    assert_empty refused(garbage, from: 'ana.local@box', kind: 'message', due: nil)
    assert_empty refused(garbage, from: 'ana@box', kind: 'message', due: nil)
    assert_empty refused("[progress] x\n", from: 'ana.local@box', to: 'orq.alpha@box', kind: 'reply', due: nil)
  end

  def test_an_address_without_a_team_is_a_person
    assert_equal ['block footer', 'block missing'], refused_kinds("Hello\nText.\n", to: 'ana@box', kind: 'message', due: nil)
    assert Nomos::Rules.human?('ana.local@box/0193')
    refute Nomos::Rules.human?('orq.alpha@box')
    assert_equal :unknown, Nomos::Address.form('orq')
    assert_equal :agent, Nomos::Address.form('orq.alpha')
    assert_equal :person, Nomos::Address.form('ana@box')
    assert_equal 'alpha', Nomos::Address.team('orq.alpha@box/s1')
  end

  def test_must_rules_read_neither_the_clock_nor_the_event
    bodies = [ASK, ASK.sub('2026-10-26 08:00', '2026-10-26 09:00'), "Hi\nText.\n", NOTICE.sub(/\A/, '[x] ')]
    bodies.each do |body|
      sent = Nomos::Rules.refusals(Nomos::Rules.check(nomos_message(body), now: Time.utc(2000, 1, 1)))
      later = Nomos::Rules.refusals(Nomos::Rules.check(nomos_message(body, event: 'receive'), now: Time.utc(2099, 1, 1)))
      quick = Nomos::Rules.refusals(Nomos::Rules.check(nomos_message(body), advice: false))
      assert_equal sent, later, body
      assert_equal sent, quick, body
    end
  end

  def test_every_flag_names_a_section_and_a_level
    flags = Nomos::Rules.check(nomos_message("## [x] #{'t' * 90}\n{\"kind\": \"notice\"}\ntomorrow {placeholder}\n"), now: DUE)
    refute_empty flags
    flags.each do |flag|
      assert_match(/\A\d+\.\d+\z/, flag.section, flag.inspect)
      assert_includes %i[must advice], flag.level
    end
    assert flags.any?(&:must?)
    refute flags.select { |flag| %w[relative time placeholder].include?(flag.kind) }.any?(&:must?)
  end
end
