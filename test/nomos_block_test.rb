# frozen_string_literal: true

require_relative 'nomos_support'

class NomosBlockTest < Minitest::Test
  include NomosSupport

  def notice(**options) = { kind: 'message', due: nil, command: 'send' }.merge(options)

  def test_well_formed_messages_to_a_person_pass
    assert_empty refused(ASK)
    assert_empty refused(NOTICE, **notice)
    assert_empty refused(NOTICE, **notice(kind: 'reply', command: 'reply'))
    result = "Report delivered\n```nomos\n{\"kind\": \"result\", \"outcome\": \"done\", \"follows\": \"ZZZZZZZZZZZZZZZZZZZZZZZZZZ\"}\n```\nDone.\n\nnomos v0 human message\n"
    assert_empty refused(result, **notice(kind: 'reply'))
  end

  def test_an_ask_goes_as_a_request_with_a_deadline
    assert_equal ['ask not a request', 'ask without deadline'], refused_kinds(ASK, **notice)
    assert_equal ['ask without deadline'], refused_kinds(ASK, due: nil)
    assert_equal ['10.5'], refused(ASK, due: nil).map(&:section)
  end

  def test_line_one_carries_no_bracketed_tag
    assert_equal ['title tag'], refused_kinds(NOTICE.sub(/\A/, '[notice] '), **notice)
    assert_empty refused(NOTICE.sub(/\A/, '[The page](https://example.com) '), **notice)
  end

  def test_every_message_to_a_person_carries_a_block_and_the_footer
    assert_equal ['ask without block', 'block footer'], refused_kinds("May I delete the old branch?\nText.\n")
    assert_equal ['block footer', 'block missing'], refused_kinds("The page is back\nNothing to do.\n", **notice)
    assert_equal ['block footer'], refused_kinds(NOTICE.sub("\nnomos v0 human message\n", ''), **notice)
    assert_equal ['block placement'], refused_kinds("The page is back\nNothing to do.\n\nnomos v0 human message\n", **notice)
    assert_equal ['block placement'], refused_kinds(NOTICE.sub('```nomos', '```nomos-1'), **notice)
    assert_equal ['block placement'], refused_kinds(NOTICE.sub("```nomos\n", "\n```nomos\n"), **notice)
    assert_equal %w[10.5 10.7], refused("Back\nText.\n", **notice).map(&:section).sort
  end

  def test_a_request_carries_one_ask
    assert_equal ['request without ask'], refused_kinds(NOTICE)
    assert_equal ['10.6'], refused(NOTICE).map(&:section)
  end

  def test_title_rule
    assert_empty refused(NOTICE.sub(/\A.*\n/, "#{'λ' * 80}\n"), **notice)
    ['## Title', '- Title', '> Title', '1. Title', ' ', 'T' * 81].each do |title|
      assert_equal ['block title'], refused_kinds(NOTICE.sub(/\A.*\n/, "#{title}\n"), **notice), title
    end
    assert_match(/title over 80 characters \(81\)/, refused(NOTICE.sub(/\A.*\n/, "#{'T' * 81}\n"), **notice).first.reason)
  end

  def test_block_limits_and_strict_json
    assert_equal ['block placement'], refused_kinds(NOTICE.sub("```\nThe page", "\nThe page"), **notice)
    assert_equal ['block json'], refused_kinds(NOTICE.sub('{"kind": "notice"}', '{"kind": "notice", "kind": "notice"}'), **notice)
    assert_equal ['block json'], refused_kinds(NOTICE.sub('{"kind": "notice"}', '{"kind": "notice" /* c */}'), **notice)
    assert_equal ['block json'], refused_kinds(NOTICE.sub('{"kind": "notice"}', '["notice"]'), **notice)
    big = NOTICE.sub('{"kind": "notice"}', "{\"kind\": \"notice\", \"x\": \"#{'a' * 1000}\"}")
    assert_equal ['block size'], refused_kinds(big, **notice)
    long = NOTICE.sub('{"kind": "notice"}', "{\"kind\": \"notice\"#{"\n" * 14}}")
    assert_equal ['block size'], refused_kinds(long, **notice)
    assert_empty refused(NOTICE.sub('{"kind": "notice"}', "{\"kind\": \"notice\"#{"\n" * 13}}"), **notice)
  end

  def test_field_rules
    {
      '{"kind": "eighth"}' => 'block field', '{"kind": "notice", "x": "a<b"}' => 'block html',
      '{"kind": "notice", "due": "x"}' => 'block time', '{"kind": "notice", "title": "T"}' => 'block field',
      '{"kind": "notice", "outcome": "done"}' => 'block field', '{"kind": "notice", "replaces": "x"}' => 'block id',
      '{"kind": "result", "outcome": "done"}' => 'block id', '{"kind": "result", "outcome": "maybe", "follows": "ZZZZZZZZZZZZZZZZZZZZZZZZZZ"}' => 'block field',
      '{"kind": "notice", "links": [{"url": "http://example.com", "label": "L"}]}' => 'block field',
      '{"kind": "notice", "links": [{"url": "https://example.com", "label": "Until 26/10"}]}' => 'block time',
      '{"kind": "notice", "files": [{"path": "notes/a.md", "label": "Notes"}]}' => 'block file',
      '{"kind": "notice", "files": [1, 2, 3, 4]}' => 'block field'
    }.each { |json, kind| assert_equal [kind], refused_kinds(NOTICE.sub('{"kind": "notice"}', json), **notice), json }
    {
      '"meanwhile": "I continue with the file"' => ['"meanwhile": "I continue until 10:00 UTC"', 'block time'],
      '"blocks": null' => ['"blocks": " "', 'block field'],
      '{"id": "move"' => ['{"id": "Move"', 'block options'],
      '"default": "keep"' => ['"default": "drop"', 'block default']
    }.each do |old, (new, kind)|
      assert_includes refused_kinds(ASK.sub(old, new)), kind, new
    end
  end

  def test_a_zoneless_clock_and_file_problems_are_advice
    zoneless = ASK.sub('I keep it as it is"', 'I keep it, 08h00"')
    assert_empty refused(zoneless)
    assert_includes all_kinds(zoneless), 'block time'
    missing = NOTICE.sub('{"kind": "notice"}', '{"kind": "notice", "files": [{"path": "/nonexistent/nomos/a.md", "label": "A"}]}')
    assert_empty refused(missing, **notice)
    assert_includes all_kinds(missing, **notice), 'block file'
  end

  def test_a_decision_has_no_default
    decision = ASK.sub('"choice"', '"decision"')
    assert_equal ['block default'], refused_kinds(decision)
    assert_equal ['10.8'], refused(decision).map(&:section)
  end

  def test_the_text_states_the_deadline
    assert_equal ['deadline not in text'], refused_kinds(ASK.sub('by 2026-10-26 08:00 -03:00', 'soon'))
    assert_match(/2026-10-26 11:00 \+00:00/, refused(ASK.sub('by 2026-10-26 08:00 -03:00', 'soon')).first.text)
    assert_empty refused(ASK, due: DUE + 299)
    assert_equal ['deadline not in text'], refused_kinds(ASK, due: DUE + 301)
    ['2026-10-26T11:00:00Z', '26/10 08:00 (-03)', '26/10/2026 08h00 -0300', '11:00 UTC', '08h (-03:00)'].each do |written|
      assert_empty refused(ASK.sub('2026-10-26 08:00 -03:00', written)), written
    end
    zoneless = ASK.sub('2026-10-26 08:00 -03:00', '26/10 klo 08h00')
    assert_equal ['deadline not in text'], refused_kinds(zoneless, vocabulary: words)
    assert_equal ['deadline not in text'], refused_kinds(zoneless)
    assert_empty refused(ASK.sub('2026-10-26 08:00 -03:00', '26/10 klo 08h00 (-03:00)'), vocabulary: words)
    twice = ASK.sub('Nothing waits on this;', 'Answer by 2026-10-26 08:00 -03:00. Nothing waits on this;')
    assert_empty refused(twice)
    assert_includes all_kinds(twice), 'deadline repeated'
    other = ASK.sub('Nothing waits on this;', 'The build ends by 2026-10-26 07:30 -03:00. Nothing waits on this;')
    assert_empty refused(other)
    assert_includes all_kinds(other), 'deadline differs'
  end

  def test_each_option_label_and_id_is_in_the_text
    assert_equal ['label not in text'], refused_kinds(ASK.sub('2. Move to the Project', '2. Move it'))
    assert_equal ['id not in text'], refused_kinds(ASK.sub('(`move`)', '(`moved`)'))
    assert_empty refused(ASK.sub('(`keep`)', '(`keeper`)')), 'keep stays a whole token in "I keep it"'
  end

  def test_a_withdrawal_to_a_person_gets_advice_only
    assert_empty refused("Withdrawn, the question is moot\n", kind: 'withdrawal', due: nil, command: 'withdraw')
    refute_empty all_kinds("Withdrawn, the question is moot\n", kind: 'withdrawal', due: nil, command: 'withdraw')
  end

  def test_an_agent_recipient_gets_no_block_rule
    assert_empty refused(ASK, to: 'rev-1.alpha@box', kind: 'message', due: nil)
    assert_empty refused('[accept] plain text', to: 'rev-1.alpha@box', kind: 'message', due: nil)
  end

  def test_an_answer_block_from_an_agent_is_refused_on_every_transport
    answer = "Keep as it is\n```nomos\n{\"kind\": \"answer\", \"answer\": \"keep\"}\n```\nKept.\n\nnomos v0 human message\n"
    assert_equal ['block kind', 'request without ask'], refused_kinds(answer)
    assert_equal ['block kind'], refused_kinds(answer, **notice)
    assert_equal ['block kind'], refused_kinds(answer, **notice(kind: 'reply', command: 'reply'))
    assert_equal ['10.5'], refused(answer, **notice).map(&:section)
    broken = answer.sub('"answer": "keep"', '"answer": "NOT AN ID"')
    assert_equal ['block id', 'block kind'], refused_kinds(broken, **notice)
    assert_equal ['block html', 'block kind'], refused_kinds(answer.sub('"keep"}', '"keep", "files": [{"path": "/a.md", "label": "<b>x</b>"}]}'), **notice)
  end

  def test_an_unknown_kind_still_gets_the_field_rules
    eighth = NOTICE.sub('{"kind": "notice"}', '{"kind": "eighth", "replaces": "nope"}')
    assert_equal ['block field', 'block id'], refused_kinds(eighth, **notice)
    assert_equal ['block field', 'request without ask'], refused_kinds(NOTICE.sub('"notice"', '"eighth"'))
  end

  def test_a_free_field_time_follows_the_pages_pattern
    refused_forms = ['12:00 (-03)', '12:00(-03)', '12:00 (UTC)', '12:00 (UTC-03)', '12:00 (-03:00)', '12:00 (-0300)',
                     '2026-10-27 12:00 (GMT+01)', '12:00:30 (Z)', '12:00  (-03)', '12:00 (-03)x',
                     '12:00 (-03)-ish', '12:00 -03', '12:00 UTC']
    refused_forms.each do |written|
      assert_equal ['block time'], refused_kinds(ASK.sub('I keep it as it is"', "I keep it by #{written}\"")), written
    end
    ['12:00', '12:00 (or earlier)', '12:00 (-)', '12:00 (+3 days)', '12:00 ( -03 )', '12:00 UTC-3'].each do |written|
      assert_empty refused(ASK.sub('I keep it as it is"', "I keep it by #{written}\"")), written
    end
    assert_match Nomos::Block::FIELD_TIME, "12:00\t(-03)", 'a tab before the parenthesis, as the page reads it'
  end

  def test_the_footer_is_the_pages_pattern
    { 'a leading space' => NOTICE.sub("\nnomos v0", "\n nomos v0"), 'CRLF' => NOTICE.sub("message\n", "message\r\n"),
      'two blank lines after it' => "#{NOTICE}\n\n" }.each do |name, body|
      assert_includes refused_kinds(body, **notice), 'block footer', name
    end
    assert_empty refused(NOTICE.sub("message\n", "message \t"), **notice)
  end

  def test_any_bracketed_text_opening_a_persons_title_is_refused
    ['[1]Pick', '[Pick one] the branch', '[2026-10-26] report'].each do |title|
      flags = refused(NOTICE.sub('The usage page answers again', title), **notice)
      assert_equal ['title tag'], flags.map(&:kind), title
      assert_match(/a person's title opens with no bracketed text; a tag line is for agents/, flags.first.text)
    end
  end

  def test_every_reason_says_what_is_wrong
    bodies = [ASK.sub('2. Move to the Project', '2. Move it'), ASK.sub('(`move`)', '(`moved`)'),
              ASK.sub('by 2026-10-26 08:00 -03:00', 'soon'), NOTICE.sub(/\A/, '[notice] '), "Hi\nText.\n"]
    flags = bodies.flat_map { |body| refused(body, **(body == ASK || body.include?('Keep as it is') ? {} : notice)) }
    assert_operator flags.map(&:kind).uniq.size, :>=, 5
    flags.each do |flag|
      assert_operator flag.text.split.size, :>=, 4, flag.reason
    end
    assert_includes flags.map(&:text), 'option label not in the text after the block: Move to the Project'
    assert_includes flags.map(&:text), 'option id not in the text as a whole word: move'
    heading = Nomos::Rules.check(nomos_message(ASK.sub('"kind": "choice"', '"kind": "decision"').sub(",\n \"default\": \"keep\"", '')), now: DUE - 3600)
    assert_includes heading.map(&:text), 'missing heading: Assessment'
  end

  def test_json_depth_counts_containers_only
    nested = ->(depth) { "#{'[' * depth}1#{']' * depth}" }
    assert_equal JSON.parse(nested.call(100)), Nomos.strict_json(nested.call(100))
    assert_raises(JSON::ParserError) { Nomos.strict_json(nested.call(101)) }
    assert_raises(JSON::ParserError) { JSON.parse(nested.call(101)) }
  end
end
