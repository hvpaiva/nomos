# frozen_string_literal: true

require 'minitest/autorun'
require 'open3'
require 'stringio'
require 'tmpdir'
require_relative '../hooks/pre-send'

class PreSendTest < Minitest::Test
  Hook = Nomos::PreSend
  FIXTURES = File.expand_path('fixtures/pre-send', __dir__)
  SCRIPT = File.expand_path('../hooks/pre-send.rb', __dir__)
  NOW = Time.utc(2026, 10, 25, 18, 0, 0)

  def flags(text, **options) = Hook::Checker.new(now: NOW, **options).check(text)
  def fixture(name) = File.read(File.join(FIXTURES, name), encoding: 'UTF-8')
  def bodies(command, **options) = Hook::Command.new(command, **options).bodies

  def run_hook(harness, command: nil, input: nil, extra: [])
    data = JSON.parse(fixture("#{harness}.json"))
    if command
      harness == 'cursor' ? data['command'] = command : data['tool_input']['command'] = command
    end
    output = StringIO.new
    error = StringIO.new
    runner = Hook::Runner.new(input: StringIO.new(input || JSON.generate(data)), output: output, error: error)
    status = runner.run(['--harness', harness, *extra])
    [output.string, error.string, status]
  end

  def assert_pass(harness, **options)
    output, error, status = run_hook(harness, **options)
    assert_equal 0, status
    harness == 'cursor' ? assert_equal({ 'permission' => 'allow' }, JSON.parse(output)) : assert_empty(output)
    [output, error]
  end

  def assert_unchecked(harness, **options)
    output, error, status = run_hook(harness, **options)
    assert_equal 0, status
    data = JSON.parse(output)
    if harness == 'cursor'
      assert_equal 'allow', data.fetch('permission')
      warning = data.fetch('agent_message')
    else
      context = data.fetch('hookSpecificOutput')
      assert_equal 'PreToolUse', context.fetch('hookEventName')
      refute context.key?('permissionDecision')
      refute context.key?('permissionDecisionReason')
      warning = context.fetch('additionalContext')
    end
    assert_match(/command passed unchecked/, warning)
    assert_match(/--check/, warning)
    assert_match(/warning/, error)
    [output, error]
  end

  def test_placeholder_with_words_and_line
    result = flags("Saved.\nUse {the revision} and {member.team@host}.\n")
    assert_equal [[2, 'placeholder', '{member.team@host}'], [2, 'placeholder', '{the revision}']], result.map { |flag| [flag.line, flag.kind, flag.text] }
  end

  def test_placeholder_multiline_and_single_word
    assert_equal [1, 3], flags("{the\nrevision}\n{revision}").map(&:line)
  end

  def test_braces_that_are_not_placeholders
    assert_empty flags('${HOME} {a,b} {1..3} {"name":"value"} {{name}} \\{escaped}')
  end

  def test_relative_words_whole_words_case_and_phrases
    result = flags("TODAY and Tomorrow. yesterday tonight\nThis morning, last night, next week.")
    assert_equal 7, result.count { |flag| flag.kind == 'relative time' }
    assert_empty flags('todays tomorrowish yesterday_count next weekly')
  end

  def test_custom_relative_words_use_unicode_boundaries_and_literal_text
    result = flags('amanhã AMANHÃ até logo a+b camanhã', words: ['amanhã', 'até logo', 'a+b'])
    assert_equal ['amanhã', 'AMANHÃ', 'até logo', 'a+b'], result.map(&:text).sort_by { |t| ['amanhã', 'AMANHÃ', 'até logo', 'a+b'].index(t) }
  end

  def test_phrase_spanning_lines_keeps_original_line
    result = flags("A\nnext\nweek")
    assert_equal 2, result.fetch(0).line
  end

  def test_explicit_relative_word_examples_are_not_event_dates
    assert_empty flags("Relative words built in (today, tomorrow, this\n morning and the like, whole words, any case).")
    assert_empty flags('Use absolute dates, never "today".')
    assert_empty flags('Use no "tomorrow" in the document.')
    assert_equal 1, flags('Examples (deploy tomorrow).').length
    assert_equal 1, flags('I will return "tomorrow".').length
    assert_equal 1, flags('No delivery tomorrow.').length
  end

  def test_multiline_flag_prints_on_one_line
    flag = flags("next\nweek").first
    assert_equal 'line 1: relative time: next week', flag.to_s
  end

  def test_code_and_quote_exclusions

    assert_empty flags(fixture('excluded.txt'))
    assert_empty flags("`today\n{the revision}`\n")
    assert_equal [4], flags("```\ntomorrow\n```\nyesterday").map(&:line)
  end

  def test_longer_fence_requires_matching_close
    assert_empty flags("````\n```\ntomorrow\n````\n")
    assert_empty flags("~~~\n```\nyesterday\n~~~\n")
  end

  def test_unclosed_inline_tick_does_not_hide_prose
    assert_equal ['tomorrow'], flags('An unmatched ` then tomorrow').map(&:text)
  end

  def test_stray_backtick_does_not_shift_masking_after_a_blank_line
    assert_empty flags(fixture('backtick.txt'))
    assert_equal ['tomorrow'], flags("Ruby said `it'.\n\ntomorrow `example`\n").map(&:text)
    assert_equal ['tomorrow'], flags("stray `\n \t\n`tomorrow").map(&:text)
  end

  def test_inline_code_cannot_span_a_heading
    text = "stray `\n## Checks run\n`tomorrow`\nyesterday"
    assert_equal ['yesterday'], flags(text).map(&:text)
    assert_includes Hook.prose(text), '## Checks run'
    assert_equal ['tomorrow'], flags("stray `\nHeading\n---\ntomorrow `example`").map(&:text)
    assert_empty flags('``a ` tomorrow``')
  end

  def test_absolute_time_boundary
    assert_empty flags('2026-10-25T18:05:00Z')
    assert_equal ['future time'], flags('2026-10-25T18:05:01Z').map(&:kind)
    assert_empty flags('2026-10-25 18:00 UTC 2026-10-24 23:59 GMT')
  end

  def test_time_offsets_and_fraction
    text = '2026-10-25 15:06 -03 2026-10-25T15:06:00-0300 2026-10-25T18:05:00.1Z'
    assert_equal 3, flags(text).length
    assert_empty flags('2026-10-25 15:04 UTC-03 2026-10-25 20:04 +02:00')
  end

  def test_time_without_date_uses_current_date_in_its_zone
    assert_equal 3, flags('18:06 UTC, 15:06 -0300, 15:06 -03').length
    assert_empty flags('18:05 UTC, 15:05 -03')
    result = flags('01:06 +07', now: Time.utc(2026, 10, 25, 18))
    assert_equal 1, result.length
  end

  def test_time_ranges_do_not_turn_into_negative_offsets
    assert_empty flags('The window was 10:00-12:00 UTC.')
    assert_empty flags('The window was 10:00 - 12:00 UTC.')
    assert_equal ['19:00 UTC'], flags('The window is 10:00-19:00 UTC.').map(&:text)
    assert_equal ['2026-10-25T10:00-12:00'], flags('2026-10-25T10:00-12:00').map(&:text)
    assert_equal ['10:00:00-12:00'], flags('10:00:00-12:00').map(&:text)
    assert_equal ['10:00 -12:00'], flags('10:00 -12:00').map(&:text)
  end

  def test_invalid_and_zoneless_dates_are_not_invented
    assert_empty flags('2099-02-30 19:00 UTC 2099-01-01 25:00 UTC 2099-01-01 18:00 +99:99')
    assert_empty flags('2099-01-01 18:00 18:00 Tuesday 2099-01-01')
  end

  def test_headings_are_loaded_from_template_not_copied
    Dir.mktmpdir('nomos-presend-') do |dir|
      template = File.join(dir, 'custom.md')
      File.write(template, "# A form\n\n## Required field\n## What {the task} does\nnomos v0 custom\n")
      assert_equal ['Required field'], flags("Done.\nnomos v0 custom\n", templates: dir).map(&:text)
      assert_empty flags("## Required field\nDone.\nnomos v0 custom\n", templates: dir)
      File.write(template, "# A form\n## New field\nnomos v0 custom\n")
      result = flags("## Required field\nDone.\nnomos v0 custom\n", templates: dir)
      assert_equal ['New field'], result.map(&:text)
      assert_equal [3], result.map(&:line)
    end
  end

  def test_footer_must_be_last_nonempty_prose_line
    assert_empty flags("nomos v0 escalation\nUnrelated text\n")
    assert_empty flags("`nomos v0 escalation`\n")
    assert_empty flags("> nomos v0 escalation\n")
    assert_empty flags('Text without a form')
    assert_empty flags("Done.\nnomos v1 escalation\n")
  end

  def test_escalation_checks_its_template_headings
    result = flags("Done.\nnomos v0 escalation\n\n")
    assert_equal %w[Assessment Background Recommendation Situation], result.map(&:text).sort
  end

  def test_multipart_forms_skip_headings_silently
    %w[plan\ review handover orchestrator\ handover first\ prompt].each do |form|
      assert_empty flags("Done.\nnomos v0 #{form}\n")
    end
  end

  def test_review_brief_optional_later_round_section
    body = File.read(File.join(Hook::ROOT, 'templates/review-brief.md'))
    headings = Hook.prose(body).scan(/^\#{2,6}\s+(.+)$/).flatten
    headings.reject! { |heading| heading == 'For a later round' }
    message = headings.map { |heading| "## #{heading}\nRecorded." }.join("\n")
    assert_empty flags("#{message}\nnomos v0 review brief\n")
  end

  def test_report_sections_can_be_omitted_as_its_guidance_says
    assert_empty flags("Nothing remains.\nnomos v0 report\n")
  end

  def review(body)
    "#{body}\n## Checks run\n## What I did not check\n## State left behind\n## Repeating the probes\nnomos v0 review findings\n"
  end

  def test_review_findings_rank_and_evidence
    result = flags(review("1. Error on startup.\n\n2. Must-fix, small. Another error.\n\n3. Missing rank. Observed. Probe failed."))
    assert_equal 2, result.count { |flag| flag.kind == 'finding missing rank' }
    assert_equal 2, result.count { |flag| flag.kind == 'finding missing evidence class' }
    refute result.any? { |flag| flag.kind == 'missing heading' }
  end

  def test_good_findings_each_evidence_class_and_empty_review
    %w[Observed Code-grounded Sourced Hypothesis].each do |kind|
      assert_empty flags(review("# The review\n\n1. **Must-fix**, small.\n\n   #{kind}. Probe recorded.\n\n2. Suggestion. #{kind}. Evidence recorded."))
    end
    assert_empty flags(review('No findings.'))
  end

  def test_quoted_evidence_and_rank_do_not_count
    result = flags(review("1. Error.\n\n   > Observed.\n   `Hypothesis`\n\n2. `Must-fix` error. Sourced."))
    assert_equal 3, result.count { |flag| flag.kind.start_with?('finding') }
  end

  def test_findings_under_a_heading_are_checked_with_their_original_line_numbers
    result = flags(review("Preface.\n\n## Findings\n\n1. A bug without rank.\n\n2. [must-fix] high. Observed. Failed."))
    assert_equal ['finding missing evidence class', 'finding missing rank'], result.map(&:kind)
    assert_equal [5, 5], result.map(&:line)
  end

  def test_numbered_steps_outside_findings_are_not_findings
    body = "## Setup\n\n1. Run a.\n2. Run b.\n\n## Findings\n\n1. Must-fix. Observed. Failed.\n"
    assert_empty flags(review(body))
    assert_empty flags(review('No findings.').sub('## Checks run', "## Checks run\n\n1. Run a.\n2. Run b."))
    assert_empty flags(review("## Findings\n\nNo findings.\n\n## Reproduction\n\n1. Run a.\n2. Run b."))
  end

  def test_restarted_step_list_inside_a_finding_is_not_rank_checked
    text = "1. Must-fix. Observed. Failed.\n\n1. run a\n2. run b\n\n2. Suggestion. Sourced. Reference."
    assert_empty flags(review(text))
    assert_empty flags(review("## Findings\n\n#{text}"))
  end

  def test_shell_action_body_and_options
    assert_equal ['Tomorrow'], bodies("keryx send reader 'Tomorrow'")
    assert_equal ['Tomorrow'], bodies("keryx --as writer ask reader 'Tomorrow' --within 30m")
    assert_equal ['Tomorrow'], bodies("keryx --as=writer reply request -- 'Tomorrow'")
    assert_equal ['Tomorrow'], bodies("keryx send --re=request 'Tomorrow'")
    assert_equal ['Tomorrow'], bodies("KERYX_AS=writer /opt/bin/keryx send --re request 'Tomorrow'")
    assert_equal ['Tomorrow and yesterday'], bodies('keryx send reader Tomorrow and yesterday')
  end

  def test_file_body_relative_to_hook_cwd
    %w[--file -f].each do |option|
      assert_equal [fixture('flagged.txt')], bodies("keryx send reader #{option} flagged.txt", cwd: FIXTURES)
    end
    assert_equal [fixture('flagged.txt')], bodies('keryx reply request --file=flagged.txt', cwd: FIXTURES)
  end

  def test_codex_relative_file_uses_the_documented_session_directory
    data = JSON.parse(fixture('codex.json'))
    data['cwd'] = FIXTURES
    data['tool_input']['command'] = 'keryx reply id --file flagged.txt'
    output, error, status = run_hook('codex', input: JSON.generate(data))
    assert_equal 0, status
    assert_empty error
    assert_equal 'deny', JSON.parse(output)['hookSpecificOutput']['permissionDecision']
  end

  def test_compound_commands_and_cd
    assert_equal ['tomorrow', 'yesterday'], bodies("echo ok && keryx send peer tomorrow; keryx reply id yesterday; date")
    assert_equal ['tomorrow'], bodies('false || keryx ask peer tomorrow | cat')
    assert_equal [fixture('flagged.txt')], bodies("cd #{Shellwords.escape(FIXTURES)} && keryx send peer --file flagged.txt")
    assert_equal ['tomorrow'], bodies("date\nkeryx send peer tomorrow")
  end

  def test_harmless_redirections_preserve_the_literal_body
    ['2>&1', '>/dev/null', '2>/dev/null', '1>> /dev/null', '2>&1 | tail -5',
     '>/dev/null 2>&1', '3>&-', '>&2', '&>/dev/null', '&>> /dev/null'].each do |redirection|
      assert_equal ['tomorrow'], bodies("keryx send peer 'tomorrow' #{redirection}"), redirection
    end
    assert_equal ['tomorrow'], bodies('2>/dev/null keryx send peer tomorrow')
    assert_equal ['ok2'], bodies('keryx send peer ok2>/dev/null')
    assert_equal ['2>&1'], bodies("keryx send peer '2>&1'")
  end

  def test_quoted_heredoc_stdin_preserves_literal_content_and_checks_following_commands
    literal = "tomorrow $TEXT `date` $(touch never)\n{the revision}\n"
    ["'EOF'", '"EOF"'].each do |delimiter|
      command = "keryx send peer --file - <<#{delimiter} 2>&1 | tail -5\n#{literal}EOF\nkeryx reply id yesterday"
      assert_equal [literal, 'yesterday'], bodies(command)
    end
    assert_equal ["tomorrow\n"], bodies("keryx send peer -f - 0<<-'EOF'\n\ttomorrow\n\tEOF")
    assert_equal ["tomorrow\n"], bodies("keryx reply id --file=- <<'EOF'\ntomorrow\nEOF")
  end

  def test_literal_cat_substitution_preserves_text_without_shell_evaluation
    literal = "tomorrow $TEXT `date` $(touch never) \\\"\n{the revision}\n\n"
    command = "keryx reply id \"$(cat <<'EOF'\n#{literal}EOF\n)\""
    assert_equal [literal.sub(/\n+\z/, '')], bodies(command)
    assert_equal ['before tomorrow after'], bodies("keryx send peer \"before $(cat <<'EOF'\ntomorrow\nEOF\n) after\"")
    assert_equal ["tomorrow\nquoted"], bodies("keryx send peer \"$(cat <<-\"EOF\"\n\ttomorrow\n\tquoted\n\tEOF\n)\"")
  end

  def test_redirection_and_heredoc_bodies_are_denied_by_each_adapter
    commands = ["keryx send peer 'tomorrow {the revision}' 2>&1",
                "keryx send peer --file - <<'EOF'\ntomorrow {the revision}\nEOF",
                "keryx reply id \"$(cat <<'EOF'\ntomorrow {the revision}\nEOF\n)\""]
    %w[claude codex cursor].each do |harness|
      commands.each do |command|
        output, error, status = run_hook(harness, command: command)
        assert_equal 0, status
        assert_empty error
        data = JSON.parse(output)
        reason = if harness == 'cursor'
                   assert_equal 'deny', data['permission']
                   data['agent_message']
                 else
                   assert_equal 'deny', data['hookSpecificOutput']['permissionDecision']
                   data['hookSpecificOutput']['permissionDecisionReason']
                 end
        assert_match(/relative time: tomorrow/, reason)
        assert_match(/placeholder: \{the revision\}/, reason)
      end
    end
  end

  def test_dynamic_and_incomplete_heredocs_warn_without_executing
    ["keryx send peer --file - <<EOF\n$TEXT\nEOF",
     "keryx send peer --file - <<'EOF'\nmissing close",
     "keryx send peer --file - <<'ONE' <<'TWO'\ntomorrow\nONE\nTWO",
     "keryx send peer \"$(cat <<'EOF'\ntomorrow\nEOF\necho extra)\"",
     "keryx send peer \"$(printf '%s' tomorrow)\""].each do |command|
      assert_unchecked('claude', command: command)
    end
  end

  def test_ambiguous_cd_does_not_read_a_body_from_the_wrong_directory
    ["cd #{FIXTURES} || keryx send reader --file flagged.txt",
     "cd #{FIXTURES} | keryx send reader --file flagged.txt",
     "false && cd #{FIXTURES}; keryx send reader --file flagged.txt"].each do |command|
      assert_raises(ArgumentError) { bodies(command) }
      _, error = assert_unchecked('codex', command: command)
      assert_match(/known directory/, error)
    end
  end

  def test_noninitial_cd_does_not_prevent_inline_or_absolute_file_checks
    assert_equal ['tomorrow'], bodies("cd work && make && cd .. && keryx send peer 'tomorrow'")
    assert_equal ['tomorrow'], bodies('date && cd elsewhere; keryx send peer tomorrow')
    assert_equal [fixture('flagged.txt')], bodies("date && cd elsewhere; keryx send peer --file #{FIXTURES}/flagged.txt")
    assert_equal ["tomorrow\n"], bodies("date && cd elsewhere; keryx send peer --file - <<'EOF'\ntomorrow\nEOF")
  end

  def test_shell_comments_are_not_part_of_the_body
    assert_equal ['ok'], bodies("keryx send peer 'ok' # today $(touch never)")
    assert_equal ['ok', 'tomorrow'], bodies("keryx send peer ok # today\nkeryx reply id tomorrow")
    assert_equal ['ok # today'], bodies("keryx send peer 'ok # today'")
    assert_equal ['ok#today'], bodies('keryx send peer ok#today')
    assert_equal ['# today'], bodies('keryx send peer \\# today')
    assert_equal ['# today'], bodies('keryx send peer "# today"')
    assert_empty bodies('# keryx send peer tomorrow')
  end

  def test_quoted_shell_punctuation_is_body_not_control
    assert_equal [';', 'a && b; tomorrow'], bodies(%q{keryx send reader ';'; keryx reply id 'a && b; tomorrow'})
    assert_equal ['x; tomorrow'], bodies(%q{keryx send reader x\;\ tomorrow})
    assert_equal ['`today` $EXAMPLE'], bodies(%q{keryx send reader '`today` $EXAMPLE'})
  end

  def test_confirmation_only_as_actual_leading_assignment
    assert_empty bodies('NOMOS_PRESEND_CONFIRMED=1 keryx send reader tomorrow')
    assert_empty bodies("X=ok NOMOS_PRESEND_CONFIRMED=1 keryx send reader tomorrow")
    assert_empty bodies('NOMOS_PRESEND_CONFIRMED=1 cd /tmp && keryx send peer tomorrow')
    assert_equal ['tomorrow'], bodies('NOMOS_PRESEND_CONFIRMED=0 keryx send reader tomorrow')
    assert_equal ['NOMOS_PRESEND_CONFIRMED=1 tomorrow'], bodies("keryx send reader 'NOMOS_PRESEND_CONFIRMED=1 tomorrow'")
    assert_equal ['yesterday'], bodies('echo ok; NOMOS_PRESEND_CONFIRMED=1 keryx send reader tomorrow; keryx send peer yesterday')
    assert_equal ['tomorrow'], bodies('NOMOS_PRESEND_CONFIRMED=1 NOMOS_PRESEND_CONFIRMED=0 keryx send reader tomorrow')
  end

  def test_unsupported_shell_is_never_executed
    ["keryx send reader \"$(date)\"", 'keryx send reader "$TEXT"', 'keryx send reader `date`',
     '(keryx send reader tomorrow)', 'keryx send reader --file - <<EOF', 'keryx send reader tomorrow &',
     "keryx send reader 'unclosed", 'keryx send reader --file missing', 'keryx reply id --unknown tomorrow'].each do |command|
      assert_raises(ArgumentError, IOError) { bodies(command) }
      _, error = assert_unchecked('codex', command: command)
      assert_match(/warning/, error)
    end
  end

  def test_non_keryx_and_non_send_actions
    assert_empty bodies('echo keryx send reader tomorrow')
    assert_empty bodies('keryx inbox')
    assert_empty bodies('keryx send --help')
    %w[claude codex cursor].each do |harness|
      _, error = assert_pass(harness, command: 'echo tomorrow')
      assert_empty error
    end
  end

  def test_all_harness_decisions_and_confirmation
    %w[claude codex cursor].each do |harness|
      output, error, status = run_hook(harness)
      assert_equal 0, status
      assert_empty error
      data = JSON.parse(output)
      if harness == 'cursor'
        assert_equal 'deny', data['permission']
        assert_equal data['agent_message'], data['user_message']
        reason = data['agent_message']
      else
        expected = data.fetch('hookSpecificOutput')
        assert_equal 'PreToolUse', expected['hookEventName']
        assert_equal 'deny', expected['permissionDecision']
        reason = expected['permissionDecisionReason']
      end
      assert_match(/line 1: placeholder: \{the revision\}/, reason)
      assert_match(/relative time: Tomorrow/, reason)
      assert_match(/NOMOS_PRESEND_CONFIRMED=1/, reason)
      assert_pass(harness, command: 'NOMOS_PRESEND_CONFIRMED=1 keryx send reader tomorrow')
      assert_pass(harness, command: "keryx send reader 'Saved at revision abc123.'")
    end
  end

  def test_malformed_input_passes_with_warning
    %w[claude codex cursor].each do |harness|
      ['{', 'null', '[]', '{}'].each do |input|
        _, error = assert_unchecked(harness, input: input)
        assert_match(/warning/, error)
      end
    end
  end

  def test_unsupported_shell_warning_reaches_each_harness_without_approval
    %w[claude codex cursor].each do |harness|
      assert_unchecked(harness, command: 'keryx send reader "$TEXT"')
      assert_unchecked(harness, command: "env NOMOS_PRESEND_CONFIRMED=0 keryx send reader 'tomorrow'")
      assert_unchecked(harness, command: "command keryx send reader 'tomorrow'")
      assert_unchecked(harness, command: 'if true; then keryx send reader tomorrow; fi')
    end
  end

  def test_unsupported_ruby_warns_before_using_data_and_only_check_exits_nonzero
    stub = "Object.send(:remove_const, :RUBY_VERSION); RUBY_VERSION = '3.1.9'; " \
           "Object.send(:remove_const, :Data); load ARGV.shift"
    %w[claude codex cursor].each do |harness|
      output, error, status = Open3.capture3(RbConfig.ruby, '-e', stub, SCRIPT, '--harness', harness)
      assert_equal 0, status.exitstatus
      assert_match(/Ruby 3.2 or later/, error)
      data = JSON.parse(output)
      if harness == 'cursor'
        assert_equal 'allow', data['permission']
        assert_match(/Ruby 3.2 or later/, data['agent_message'])
      else
        context = data.fetch('hookSpecificOutput')
        assert_match(/Ruby 3.2 or later/, context['additionalContext'])
        refute context.key?('permissionDecision')
      end
    end
    output, error, status = Open3.capture3(RbConfig.ruby, '-e', stub, SCRIPT, '--check', 'unused')
    assert_equal 2, status.exitstatus
    assert_empty output
    assert_match(/Ruby 3.2 or later.*check incomplete/, error)
  end

  def test_wrong_event_and_tool_pass_without_checking_message_like_input
    _, error = assert_pass('claude', input: JSON.generate(hook_event_name: 'PostToolUse'))
    assert_empty error
    _, error = assert_pass('codex', input: JSON.generate(tool_name: 'apply_patch', tool_input: { command: 'keryx send reader tomorrow' }))
    assert_empty error
  end

  def test_executable_check_exit_codes_and_words_file
    stdout, stderr, status = Open3.capture3(RbConfig.ruby, SCRIPT, '--check', File.join(FIXTURES, 'flagged.txt'))
    assert_equal 1, status.exitstatus
    assert_match(/relative time/, stdout)
    assert_empty stderr
    stdout, stderr, status = Open3.capture3(RbConfig.ruby, SCRIPT, '--check', File.join(FIXTURES, 'excluded.txt'))
    assert_equal 0, status.exitstatus
    assert_empty stdout
    assert_empty stderr
    Dir.mktmpdir('nomos-presend-') do |dir|
      File.write(File.join(dir, 'words'), "amanhã\n")
      File.write(File.join(dir, 'body'), "Retorno amanhã.\n")
      stdout, stderr, status = Open3.capture3(RbConfig.ruby, SCRIPT, '--check', File.join(dir, 'body'), '--words', File.join(dir, 'words'))
      assert_equal 1, status.exitstatus
      assert_match(/amanhã/, stdout.force_encoding('UTF-8'))
      assert_empty stderr
    end
  end

  def test_check_errors_have_distinct_exit_and_no_false_clean_result
    _, stderr, status = Open3.capture3(RbConfig.ruby, SCRIPT, '--check', File.join(FIXTURES, 'missing'))
    assert_equal 2, status.exitstatus
    assert_match(/check incomplete/, stderr)
  end

  def test_subprocess_contract_for_each_harness
    %w[claude codex cursor].each do |harness|
      stdout, stderr, status = Open3.capture3(RbConfig.ruby, SCRIPT, '--harness', harness, stdin_data: fixture("#{harness}.json"))
      assert_equal 0, status.exitstatus
      assert_empty stderr
      assert_match(/deny/, stdout)
    end
  end
end
