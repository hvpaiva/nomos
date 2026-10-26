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

  def with_method(object, name, replacement)
    original = object.method(name)
    owned = object.singleton_class.instance_methods(false).include?(name)
    object.define_singleton_method(name, replacement)
    yield
  ensure
    owned ? object.define_singleton_method(name, original) : object.singleton_class.remove_method(name)
  end

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
    harness == 'cursor' ? assert_equal(Hook::CURSOR_PASS.transform_keys(&:to_s), JSON.parse(output), options[:command]) : assert_empty(output, options[:command])
    [output, error]
  end

  def assert_unchecked(harness, **options)
    if harness == 'cursor' && options[:command]
      document = File.read(File.expand_path('../bootstrap.md', __dir__))
      block = document.scan(/```json\n(.*?)```/m).flatten.find { |json| json.include?('"beforeShellExecution"') }
      matcher = JSON.parse(block).fetch('hooks').fetch('beforeShellExecution').first.fetch('matcher')
      assert_match Regexp.new(matcher), options[:command]
    end
    output, error, status = run_hook(harness, **options)
    assert_equal 0, status
    data = JSON.parse(output)
    if harness == 'cursor'
      assert_equal Hook::CURSOR_PASS[:permission], data.fetch('permission')
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

  def test_only_later_calendar_dates_are_exempt
    ['Due 2026-10-26 12:00 UTC.', 'Sent at 2026-10-26 12:00 UTC.',
     'Expected for 2026-10-26 06:00 -03.'].each do |body|
      assert_empty flags(body), body
    end
    ['Reply by 18:06 UTC.', 'Wait until 18:06 UTC.', 'Due 18:06 UTC.',
     'Prazo de entrega: 18:06 UTC.', 'Sent by nomos at 18:06 UTC.'].each do |body|
      assert_equal ['18:06 UTC'], flags(body).map(&:text), body
    end
    assert_empty flags('Observed 18:05 UTC.')
    assert_equal ['18:05:01 UTC'], flags('Due 18:05:01 UTC.').map(&:text)
  end

  def test_calendar_day_comparison_uses_the_timestamp_zone
    assert_equal ['2026-10-26 01:06 +07'], flags('2026-10-26 01:06 +07').map(&:text)
    assert_equal ['2026-10-25 23:30 -07'], flags('2026-10-25 23:30 -07').map(&:text)
    assert_empty flags('2026-10-26 00:00 -03', now: Time.utc(2026, 10, 26, 0, 10))
    assert_empty flags('2026-10-27 00:00 +07')
    assert_equal [2], flags("Due 2026-10-26 12:00 UTC.\nSent 18:06 UTC.").map(&:line)
  end

  def test_reviewed_future_event_sentences_are_all_flagged
    ['The job failed due to a timeout at 19:30 UTC.',
     'The request due then arrived at 19:30 UTC.', 'Deadline met: merged at 19:30 UTC.',
     'Finished by 19:30 UTC.', 'Sent by 19:30 UTC.',
     'The run took longer than expected and ended at 19:30 UTC.', 'It worked until 19:30 UTC.',
     "- Due: Monday\n- Pushed 19:30 UTC", "## Due\nMerged at 19:30 UTC.",
     'Expected output appeared at 19:30 UTC.', 'Due diligence done at 19:30 UTC.',
     'The deadline passed and I replied at 19:30 UTC.', 'Observed 19:30 UTC.',
     'Sent at 19:30 UTC.'].each do |body|
      assert_equal ['19:30 UTC'], flags(body).map(&:text), body
    end
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

  def test_unranked_finding_after_restarted_steps_is_checked
    text = "1. Must-fix. Observed. Failed.\n\n1. run a\n2. run b\n\n2. Another bug."
    ['', "## Findings\n\n"].each do |prefix|
      result = flags(review("#{prefix}#{text}"))
      assert_equal ['finding missing evidence class', 'finding missing rank'], result.map(&:kind)
      assert_equal [prefix.empty? ? 6 : 8] * 2, result.map(&:line)
    end
    nested = "1. Must-fix. Observed. Failed.\n\n   1. run a\n\n   2. run b\n\n2. Another bug."
    assert_equal ['finding missing evidence class', 'finding missing rank'], flags(review(nested)).map(&:kind)
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
    assert_raises(ArgumentError) { bodies("date && cd elsewhere; keryx send peer --file #{FIXTURES}/flagged.txt") }
    assert_equal ["tomorrow\n"], bodies("date && cd elsewhere; keryx send peer --file - <<'EOF'\ntomorrow\nEOF")
  end

  def test_directory_stack_and_builtin_cd_do_not_read_the_wrong_file
    Dir.mktmpdir('nomos-presend-') do |dir|
      File.write(File.join(dir, 'body.md'), 'Clean.')
      Dir.mkdir(File.join(dir, 'work'))
      File.write(File.join(dir, 'work/body.md'), 'tomorrow')
      ['pushd work', 'popd', 'builtin cd work', 'command cd work',
       'command -- cd work', 'builtin pushd work', 'eval cd work', "eval 'cd work'",
       'time cd work', 'command builtin cd work', 'builtin command cd work',
       "command builtin eval 'cd work'", 'time command builtin cd work', 'source ./setup.sh', '. ./setup.sh',
       'command source ./setup.sh', 'builtin . ./setup.sh',
       "CDPATH=#{dir}/other cd work", 'X=ok CDPATH= cd work'].each do |change|
        command = "#{change} && keryx send peer --file body.md"
        assert_raises(ArgumentError) { bodies(command, cwd: dir) }
        %w[claude codex cursor].each do |harness|
          data = JSON.parse(fixture("#{harness}.json"))
          data['cwd'] = dir
          harness == 'cursor' ? data['command'] = command : data['tool_input']['command'] = command
          _, error = assert_unchecked(harness, input: JSON.generate(data))
          assert_match(/known directory/, error)
        end
        checked = ["#{change} && keryx send peer tomorrow",
                   "#{change} && keryx send peer --file - <<'EOF'\ntomorrow\nEOF"]
        %w[claude codex cursor].each do |harness|
          checked.each do |command|
            data = JSON.parse(fixture("#{harness}.json"))
            data['cwd'] = dir
            harness == 'cursor' ? data['command'] = command : data['tool_input']['command'] = command
            output, error, status = run_hook(harness, input: JSON.generate(data))
            assert_equal 0, status
            assert_empty error, command
            result = JSON.parse(output)
            assert_equal 'deny', harness == 'cursor' ? result['permission'] : result['hookSpecificOutput']['permissionDecision']
          end
        end
        assert_equal ['tomorrow'], bodies("#{change} && keryx send peer tomorrow", cwd: dir)
        absolute = "#{change} && keryx send peer --file #{dir}/work/body.md"
        if change.match?(/eval|time|source|\. \.\//)
          assert_raises(ArgumentError) { bodies(absolute, cwd: dir) }
        else
          assert_equal ['tomorrow'], bodies(absolute, cwd: dir)
        end
      end
    end
  end

  def test_wrapped_keryx_warns_but_text_searches_are_silent
    wrappers = ['timeout 30', 'nohup', 'nice -n 2', 'eval', 'ssh host', 'xargs',
                'stdbuf -oL', 'setsid', 'flock /tmp/unused-lock', 'watch', 'custom-wrapper',
                'env', 'exec', 'command', 'time', 'sudo', 'bash -c', 'sh -c']
    %w[claude codex cursor].each do |harness|
      wrappers.each do |wrapper|
        assert_unchecked(harness, command: "#{wrapper} keryx send peer tomorrow")
      end
      ['eval', 'ssh host', 'bash -c', 'sh -c'].each do |wrapper|
        assert_unchecked(harness, command: "#{wrapper} 'keryx send peer tomorrow'")
      end
      assert_unchecked(harness, command: 'other /opt/bin/keryx reply id tomorrow')
      ["rg 'keryx send' notes.md", "grep 'keryx send' notes.md", 'rg keryx notes.md',
       "sed -n '/keryx send/p' notes.md", 'cat keryx.md', "echo 'keryx send peer tomorrow'",
       "printf '%s' 'keryx send peer tomorrow'", 'echo keryx send peer tomorrow', 'printf %s keryx send peer tomorrow'].each do |command|
        _, error = assert_pass(harness, command: command)
        assert_empty error
      end
    end
  end

  def test_plain_cd_still_checks_relative_files_in_each_harness
    Dir.mktmpdir('nomos-presend-') do |dir|
      File.write(File.join(dir, 'body.md'), 'Clean.')
      Dir.mkdir(File.join(dir, 'work'))
      File.write(File.join(dir, 'work/body.md'), 'tomorrow')
      %w[claude codex cursor].each do |harness|
        data = JSON.parse(fixture("#{harness}.json"))
        data['cwd'] = dir
        command = 'cd work && keryx send peer --file body.md'
        harness == 'cursor' ? data['command'] = command : data['tool_input']['command'] = command
        output, error, status = run_hook(harness, input: JSON.generate(data))
        assert_equal 0, status
        assert_empty error
        result = JSON.parse(output)
        assert_equal 'deny', harness == 'cursor' ? result['permission'] : result['hookSpecificOutput']['permissionDecision']
      end
    end
  end

  def test_shell_comments_are_not_part_of_the_body
    assert_equal ['ok'], bodies("keryx send peer 'ok' # today $(touch never)")
    assert_equal ['ok', 'tomorrow'], bodies("keryx send peer ok # today\nkeryx reply id tomorrow")
    assert_equal ['ok # today'], bodies("keryx send peer 'ok # today'")
    assert_equal ['ok#today'], bodies('keryx send peer ok#today')
    assert_equal ['# today'], bodies('keryx send peer \\# today')
    assert_equal ['# today'], bodies('keryx send peer "# today"')
    assert_equal ['a #today'], bodies('keryx send peer a\\ #today')
    assert_equal ["a\t#today"], bodies("keryx send peer a\\\t#today")
    assert_equal ['a #today'], bodies("keryx send peer 'a '#today")
    assert_equal ['a #today'], bodies('keryx send peer "a "#today')
    assert_equal ['a '], bodies('keryx send peer a\\  #today')
    assert_equal ['a\\'], bodies('keryx send peer a\\\\ #today')
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
    assert_equal ['tomorrow'], bodies('NOMOS_PRESEND_CONFIRMED=1 cd /tmp && keryx send peer tomorrow')
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
    assert_empty bodies("echo 'keryx send reader tomorrow'")
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

  def test_unsupported_read_commands_mentioning_keryx_stay_silent
    commands = ['diff -r keryx "$OTHER"', 'sed -n "1,20p" keryx-help.txt > output.txt',
                'rg "keryx send" "$ROOT"', "grep 'keryx reply' < notes.md",
                "echo 'keryx send peer tomorrow' > output.txt", 'keryx read "$ID"',
                "cat <<'EOF'\nkeryx send peer tomorrow\nEOF",
                "echo ok # keryx send peer tomorrow\ncat < notes.md",
                "bash -c 'rg \"keryx send\" \"$ROOT\"'", "ssh host 'rg \"keryx reply\" notes'"]
    %w[claude codex cursor].each do |harness|
      commands.each do |command|
        _, error = assert_pass(harness, command: command)
        assert_empty error, command
      end
    end
  end

  def test_indirect_read_commands_remain_silent
    commands = ['echo "$(keryx inbox)"', 'id=`keryx inbox`', 'echo "`keryx inbox`"',
                'echo "$(echo "$(keryx inbox)")"', 'echo \'$(keryx send peer tomorrow)\'',
                'echo \'`keryx send peer tomorrow`\'',
                "cat <<<'keryx send peer tomorrow'",
                "cat <<'EOF'\n$(keryx send peer tomorrow)\nEOF",
                "cat <<EOF\nkeryx send peer tomorrow\nEOF",
                "ssh box2 cat <<'EOF'\nkeryx send peer tomorrow\nEOF",
                "echo 'keryx send peer tomorrow'; bash", "echo 'keryx send peer tomorrow' && bash",
                "echo 'keryx send peer tomorrow' | cat; bash",
                "echo 'keryx inbox' | bash", "bash <<'EOF'\nrg 'keryx send' notes\nEOF",
                "cat <<'EOF' | sh\nrg 'keryx send' notes\nEOF",
                "mise exec -- bash -c 'rg \"keryx send\" notes'",
                "watch -n 60 'rg \"keryx send\" notes'", "su --command='rg \"keryx send\" notes' user",
                "keryx send peer \"$(cat <<'EOF'\nkeryx send peer Clean\nEOF\n)\""]
    %w[claude codex cursor].each do |harness|
      commands.each do |command|
        _, error = assert_pass(harness, command: command)
        assert_empty error, command
      end
    end
  end

  def test_unsupported_sends_and_quoted_wrapper_payloads_warn
    commands = ['keryx --as writer send peer "$TEXT"', '/opt/keryx ask peer "$TEXT"',
                "keryx reply id 'unclosed", "bash -lc 'keryx send peer tomorrow'",
                "sh -c '/opt/keryx reply id tomorrow'", "eval 'keryx ask peer tomorrow'",
                "ssh -p 22 host 'keryx send peer tomorrow'", "su -c 'keryx reply id tomorrow' user",
                "timeout 30 bash -c 'keryx send peer tomorrow'",
                "command eval 'keryx send peer tomorrow'", "'keryx' 'send' peer > output.txt"]
    commands.concat([
      'id="$(keryx ask peer "Is it done tomorrow?" --within 10m)"',
      'echo "$(keryx send peer tomorrow)"', 'id=`keryx send peer tomorrow`',
      'echo "`keryx send peer tomorrow`"', "cat <<<'x'\nkeryx send peer tomorrow",
      "bash <<<'keryx send peer tomorrow'",
      "bash <<'EOF'\nkeryx send peer tomorrow\nEOF",
      "bash -s <<'EOF'\nkeryx send peer tomorrow\nEOF",
      "ssh box2 <<'EOF'\nkeryx send peer tomorrow\nEOF",
      "cat <<'EOF' | sh\nkeryx send peer tomorrow\nEOF",
      "echo 'keryx send peer tomorrow' | bash",
      "echo 'keryx send peer tomorrow' 2>&1 | bash",
      "echo 'keryx send peer tomorrow' |& bash",
      "echo 'keryx send peer tomorrow' |\n bash",
      "cat <<<'keryx send peer tomorrow' | bash",
      "mise exec -- bash -c 'keryx send peer tomorrow'",
      "pkexec /usr/bin/sh -c 'keryx send peer tomorrow'",
      "systemd-run --user sh -c 'keryx send peer tomorrow'",
      "ksh -c 'keryx send peer tomorrow'", "flock /tmp/l -c 'keryx send peer tomorrow'",
      "watch -n 60 'keryx send peer tomorrow'", "script -qc 'keryx send peer tomorrow' /dev/null",
      "su --command='keryx send peer tomorrow' user",
      'echo "$(echo "$(keryx send peer tomorrow)")"', 'echo "$(keryx send peer tomorrow',
      'echo "`keryx send peer tomorrow', "bash <<<'keryx send peer tomorrow",
      "bash <<'EOF'\nkeryx send peer tomorrow", "cat <<<'x' && keryx send peer tomorrow",
      "keryx send peer Clean; echo 'keryx send peer tomorrow' | bash",
      "cat <<EOF\n$(keryx send peer tomorrow)\nEOF",
      "cat <<EOF\n`keryx send peer tomorrow`\nEOF",
      "bash -s -- arg <<'EOF'\nkeryx send peer tomorrow\nEOF",
      "ssh -o BatchMode=yes -p22 box2 <<'EOF'\nkeryx send peer tomorrow\nEOF",
      "cat <<-'EOF' | cat | /usr/bin/sh\n\tkeryx send peer tomorrow\n\tEOF",
      "printf '%s\\n' 'keryx send peer tomorrow' | bash",
      "cat <<'EOF'\nkeryx inbox\nEOF\nbash <<'END'\nkeryx send peer tomorrow\nEND"
    ])
    %w[bash sh zsh dash fish ksh mksh tcsh csh].each do |shell|
      commands << "launcher #{shell} -lc 'keryx send peer tomorrow'"
      commands << "#{shell} <<'EOF'\nkeryx send peer tomorrow\nEOF"
    end
    commands.concat(["busybox sh -c 'keryx send peer tomorrow'",
                     "busybox sh <<'EOF'\nkeryx send peer tomorrow\nEOF",
                     "script --command='keryx send peer tomorrow' /dev/null",
                     "flock --command 'keryx send peer tomorrow' /tmp/l"])
    %w[claude codex cursor].each do |harness|
      commands.each { |command| assert_unchecked(harness, command: command) }
    end
  end

  def test_rev20_unresolved_shell_forms_warn_in_each_harness
    commands = [
      'cat <(keryx send peer tomorrow)', 'echo x | tee >(keryx send peer tomorrow)',
      "bash <(echo 'keryx send peer tomorrow')", "source <(echo 'keryx send peer tomorrow')",
      "bash -euo pipefail <<'EOF'\nkeryx send peer tomorrow\nEOF",
      "bash -eo pipefail <<'EOF'\nkeryx send peer tomorrow\nEOF",
      "ssh box2 'bash -s' <<'EOF'\nkeryx send peer tomorrow\nEOF",
      "su peer <<'EOF'\nkeryx send peer tomorrow\nEOF",
      "bash -c -- 'keryx send peer tomorrow'", "sh -c -e 'keryx send peer tomorrow'",
      "bash -c $'keryx send peer tomorrow\\n'", 'bash -c $"keryx send peer tomorrow"',
      "trap 'keryx send peer tomorrow' EXIT; true", "env -S 'keryx send peer tomorrow'",
      "parallel 'keryx send {} tomorrow' ::: peer", 'echo send peer tomorrow | xargs keryx',
      'echo "$(case x in x) keryx send peer tomorrow;; esac)"',
      "unknown 'keryx send peer tomorrow'", "bash script.sh <<'EOF'\nkeryx send peer tomorrow\nEOF",
      "echo 'keryx send peer tomorrow' | bash script.sh",
      "grep 'keryx send peer tomorrow' notes; trap 'keryx send peer tomorrow' EXIT",
      "keryx send peer 'Use keryx send peer Clean'; env -S 'keryx send peer Clean'",
      'grep "$(keryx send peer tomorrow)" notes', "cat <<EOF\n$(keryx send peer tomorrow)\nEOF",
      "grep 'keryx send' notes; mystery 'keryx send'",
      "mystery 'keryx \\\n --as peer \\\n send peer tomorrow'",
      "mystery 'keryx    --as=peer     reply id tomorrow'",
      "bash -c 'keryx send peer tomorrow' -n",
      "find . -exec keryx send peer tomorrow \\;",
      "awk 'BEGIN { system(\"keryx send peer tomorrow\") }'",
      "awk 'BEGIN { print \"keryx send peer tomorrow\" | \"bash\" }'",
      "rg --pre 'keryx send peer tomorrow' notes",
      "printf -v command 'keryx send peer tomorrow'; eval \"$command\"",
      "value=$(echo 'keryx send peer tomorrow'); eval \"$value\"",
      "echo 'keryx send peer tomorrow' > >(bash)"
    ]
    %w[claude codex cursor].each do |harness|
      commands.each { |command| assert_unchecked(harness, command: command) }
    end
  end

  def test_occurrences_are_accounted_at_their_own_positions
    commands = ["grep -n -e eval -e 'keryx send' hooks/pre-send.rb",
                "git log --grep watch --grep 'keryx send' --oneline",
                "grep 'keryx send' notes; rg 'keryx send' docs",
                "echo 'keryx send peer Clean'; keryx send peer 'Use keryx send peer Clean'",
                "bash -c 'grep \"keryx send\" notes'", "ssh box2 'grep \"keryx send\" notes'",
                "diff <(grep 'keryx send' a) <(grep 'keryx send' b)",
                "echo 'keryx send peer tomorrow' | bash -n",
                "echo 'keryx \\\n send peer Clean'",
                "keryx \\\n --as peer \\\n send peer Clean"]
    %w[claude codex cursor].each do |harness|
      commands.each do |command|
        _, error = assert_pass(harness, command: command)
        assert_empty error, command
      end
    end
  end
  def assert_denied(harness, command)
    output, error, status = run_hook(harness, command: command)
    assert_equal 0, status
    assert_empty error, command
    refute_empty output, command
    data = JSON.parse(output)
    assert_equal 'deny', harness == 'cursor' ? data['permission'] : data.dig('hookSpecificOutput', 'permissionDecision'), command
    assert_includes output, 'relative time', command
  end

  def test_rev23_global_options_and_continuations_check_the_body
    commands = ['keryx --color send peer tomorrow', 'keryx --color=never send peer tomorrow',
                'keryx --as rev-1.nomos --color send peer tomorrow',
                'keryx --as "rev-1".nomos send peer tomorrow',
                'keryx --as="rev-1"."nomos" send peer tomorrow',
                'keryx --color=auto --as rev-1 --color=never reply id tomorrow',
                "keryx \\\nsend peer tomorrow", "keryx --as \\\n rev-1.nomos \\\nsend peer tomorrow"]
    %w[claude codex cursor].each do |harness|
      commands.each do |command|
        assert_denied(harness, command)
        _, error = assert_pass(harness, command: command.sub('tomorrow', 'Clean'))
        assert_empty error
      end
      ['M=rev-1; keryx --as "$M".nomos send peer tomorrow',
       'M=rev-1; keryx --as "$M"@box1 ask peer tomorrow'].each do |command|
        assert_unchecked(harness, command: command)
      end
    end
  end

  def test_rev23_executing_consumers_do_not_discharge_data
    commands = ["sed e <<'EOF'\nkeryx send peer tomorrow\nEOF",
                "echo 'keryx send peer tomorrow' | sed e",
                "echo 'keryx send peer tomorrow' | sed 's/^/ /e'",
                "sed -f - x.txt <<'EOF'\n1e keryx send peer tomorrow\nEOF",
                "awk -f - x.txt <<'EOF'\nBEGIN { system(\"keryx send peer tomorrow\") }\nEOF",
                "awk \"$(cat <<'EOF'\nBEGIN { system(\"keryx send peer tomorrow\") }\nEOF\n)\" x.txt",
                "git grep --no-index -O'keryx send peer tomorrow' -e hello",
                "git grep --no-index --open-files-in-pager='keryx send peer tomorrow' -e hello",
                "sed -e \"$PROGRAM\" <<'EOF'\nkeryx send peer tomorrow\nEOF",
                "echo 'keryx send peer tomorrow' | sed 's/a/b/w run.sh'; sh run.sh",
                "gh alias set --shell execute 'keryx send peer tomorrow'",
                "gh search code 'keryx send peer tomorrow' --template '{{exec}}'",
                "gh search code 'keryx send peer tomorrow' --web",
                "gh issue list --search 'keryx send peer tomorrow' --web",
                "printf 'keryx send peer tomorrow' | xargs sh -c"]
    %w[ruby python python3 perl node].each do |interpreter|
      commands << "#{interpreter} <<'EOF'\nsystem('keryx send peer tomorrow')\nEOF"
      commands << "timeout 5 #{interpreter} -e \"$(cat <<'EOF'\nsystem('keryx send peer tomorrow')\nEOF\n)\""
    end
    %w[claude codex cursor].each do |harness|
      commands.each { |command| assert_unchecked(harness, command: command) }
      ["sed -n '/keryx send/,+3p' notes", "awk '/keryx ask/ {print $0}' notes",
       "gh search code 'keryx send' --owner example", "gh issue list --search 'keryx send' -R hvpaiva/keryx",
       "grep 'keryx send' docs | xargs wc -l"].each do |command|
        _, error = assert_pass(harness, command: command)
        assert_empty error, command
      end
    end
  end

  def test_rev23_stored_data_cannot_be_run_in_the_same_command
    commands = ["read c <<< 'keryx send peer tomorrow'; eval \"$c\"",
                "read -r c <<'EOF'\nkeryx send peer tomorrow\nEOF\neval \"$c\"",
                "echo 'keryx send peer tomorrow' > run.sh; bash run.sh",
                "cat > run.sh <<'EOF'\nkeryx send peer tomorrow\nEOF\nsh run.sh",
                "printf 'keryx send peer tomorrow\n' | tee run.sh >/dev/null; . ./run.sh",
                "cat <<'EOF' > run.sh\nkeryx send peer tomorrow\nEOF\nsource run.sh",
                "tee run.sh <<'EOF' >/dev/null\nkeryx send peer tomorrow\nEOF\nbash run.sh",
                "/usr/bin/tee run.sh <<'EOF' >/dev/null\nkeryx send peer tomorrow\nEOF\nbash run.sh",
                "echo 'keryx send peer tomorrow' >> run.sh; bash < run.sh",
                "printf '%s\n' '#!/bin/sh' 'keryx send peer tomorrow' > s.sh; chmod +x s.sh; ./s.sh",
                "read c <<< 'keryx send peer tomorrow'; $c",
                "echo \"$(cat <<'EOF'\nkeryx send peer tomorrow\nEOF\n)\" > run.sh; sh run.sh"]
    %w[claude codex cursor].each do |harness|
      commands.each { |command| assert_unchecked(harness, command: command) }
      ["echo 'keryx send peer tomorrow' > saved.sh; cat saved.sh"].each do |command|
        _, error = assert_pass(harness, command: command)
        assert_empty error, command
      end
    end
  end

  def test_rev23_file_bodies_must_not_be_rewritten_before_sending
    Dir.mktmpdir('nomos-presend-') do |dir|
      path = File.join(dir, 'body.md')
      File.write(path, 'Clean body.')
      writers = ["tee #{path} <<'EOF' >/dev/null\ntomorrow\nEOF\n",
                 "/usr/bin/tee #{path} <<'EOF' >/dev/null\ntomorrow\nEOF\n",
                 "cp draft.md #{path} && ", "sed -i 's/Clean/tomorrow/' #{path} && ",
                 "printf tomorrow | tee #{path} >/dev/null; ", "mv draft.md #{path} && ",
                 "install draft.md #{path}; ", "dd if=draft.md of=#{path}; ",
                 "mystery #{path}; ", "echo tomorrow > #{path}; "]
      %w[claude codex cursor].each do |harness|
        writers.each do |writer|
          ['send peer --file', 'send peer -f', 'ask peer --file', 'reply id --file'].each do |action|
            assert_unchecked(harness, command: "#{writer}keryx #{action} #{path}")
          end
        end
        ["keryx send peer --file #{path}", "cat #{path}; keryx send peer --file #{path}",
         "printf x >/dev/null; keryx send peer --file #{path}"].each do |command|
          _, error = assert_pass(harness, command: command)
          assert_empty error, command
        end
        ['{to,x}morrow', '*orrow', '?omorrow', '[t]omorrow'].each do |body|
          assert_unchecked(harness, command: "keryx send peer #{body}")
        end
      end
    end
  end

  def test_rev23_terminal_keryx_is_only_a_command_position
    commands = ['cd ~/src/keryx && git log --oneline', 'ls ~/src/keryx',
                'command -v keryx', 'which keryx', 'type -a keryx', 'mise which keryx',
                'file ~/.local/bin/keryx', 'stat ~/.local/bin/keryx', 'test -x ~/.local/bin/keryx',
                'sha256sum ~/.local/bin/keryx', 'pgrep -fa keryx', 'bundle exec rake test -C ~/src/keryx']
    %w[claude codex cursor].each do |harness|
      commands.each do |command|
        _, error = assert_pass(harness, command: command)
        assert_empty error, command
      end
      ['keryx', 'echo send peer tomorrow | xargs keryx', 'env keryx', 'nohup keryx'].each do |command|
        assert_unchecked(harness, command: command)
      end
    end
  end

  def test_rev23_size_gate_precedes_scan_and_warning_tolerates_closed_streams
    %w[claude codex cursor].each do |harness|
      with_method(Hook::Command, :occurrences, ->(*) { raise 'occurrence scan reached' }) do
        _, error = assert_unchecked(harness, command: "keryx send peer '#{'a' * 70_000}'")
        assert_match(/exceeds 64 KiB/, error)
      end
      [[true, false], [false, true], [true, true]].each do |close_output, close_error|
        output = StringIO.new
        error = StringIO.new
        output.close if close_output
        error.close if close_error
        assert_equal 0, Hook.warning('failed', harness: harness, output: output, error: error)
      end
    end
  end

  def test_no_occurrence_fast_path_and_nested_send_are_bounded
    read = "grep #{(['-e eval'] * 22).join(' ')} -e 'keryx inbox' notes.md"
    deep = "echo #{'$(' * 3000}keryx send peer tomorrow#{')' * 3000}"
    %w[claude codex cursor].each do |harness|
      [read, deep].each do |command|
        data = JSON.parse(fixture("#{harness}.json"))
        harness == 'cursor' ? data['command'] = command : data['tool_input']['command'] = command
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        stdout, stderr, status = Open3.capture3(RbConfig.ruby, SCRIPT, '--harness', harness, stdin_data: JSON.generate(data))
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
        assert_operator elapsed, :<, 10.0, "#{harness}: #{elapsed}s"
        assert_equal 0, status.exitstatus
        if command == read
          assert_empty stderr
          harness == 'cursor' ? assert_equal(Hook::CURSOR_PASS.transform_keys(&:to_s), JSON.parse(stdout)) : assert_empty(stdout)
        else
          assert_match(/warning.*(?:nesting|200 ms)/, stderr)
          assert_match(/command passed unchecked/, stdout)
        end
      end
    end
  end

  def test_scan_limits_and_unexpected_errors_warn_without_a_fallback_scan
    commands = ["keryx send peer '#{'x' * 65_536}'",
                "grep #{(['word'] * 4097).join(' ')} 'keryx send'"]
    %w[claude codex cursor].each do |harness|
      commands.each { |command| assert_unchecked(harness, command: command) }
      [RuntimeError, SystemStackError, SyntaxError].each do |failure|
        with_method(Hook::Command::Accounting, :new, ->(*) { raise failure, 'forced scanner failure' }) do
          assert_unchecked(harness, command: 'keryx send peer Clean')
          _, error = assert_pass(harness, command: 'echo "$(keryx inbox)"')
          assert_empty error
        end
      end
      with_method(Hook::Command::Budget, :new, ->(*) { raise Hook::Command::Limit, 'shell scan exceeded 200 ms' }) do
        assert_unchecked(harness, command: 'keryx send peer Clean')
      end
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
        assert_equal Hook::CURSOR_PASS[:permission], data['permission']
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
    assert_unchecked('codex', input: JSON.generate(tool_name: 'apply_patch', tool_input: { command: 'keryx send reader tomorrow' }))
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
  def test_rev24_raw_escape_boundaries_and_identifier_noise
    %w[claude codex cursor].each do |harness|
      %w[n t r x41 040 u0020 U00000020].each do |escape|
        assert_unchecked(harness, command: "printf 'true\\#{escape}keryx send peer tomorrow\\n' | sh")
      end
      %w[mykeryx-send keryx_send mykeryx].each do |identifier|
        _, error = assert_pass(harness, command: "unknown '#{identifier} send peer tomorrow'")
        assert_empty error
      end
    end
  end

  def test_rev24_reader_allowlists_reject_executors_prefixes_and_writers
    commands = [
      "RIPGREP_CONFIG_PATH=cfg rg 'keryx send peer tomorrow' .",
      "GIT_PAGER=sh git log --grep='keryx send peer tomorrow'",
      "X=ok grep 'keryx send peer tomorrow' notes",
      "env -- grep 'keryx send peer tomorrow' notes",
      "grep() { sh -c \"$1\"; }; grep 'keryx send peer tomorrow'",
      "function grep { sh -c \"$1\"; }; grep 'keryx send peer tomorrow'",
      "alias grep=sh; grep 'keryx send peer tomorrow'",
      "hash -p /bin/sh grep; grep 'keryx send peer tomorrow'",
      "command hash -p /bin/sh grep; grep 'keryx send peer tomorrow'",
      "{ alias grep=sh; }; grep 'keryx send peer tomorrow'",
      "eval 'alias grep=sh'; grep 'keryx send peer tomorrow'",
      "source setup.sh; grep 'keryx send peer tomorrow'",
      "enable -n echo; echo 'keryx send peer tomorrow'",
      "builtin echo x; grep 'keryx send peer tomorrow' notes",
      "PATH=/tmp/other; grep 'keryx send peer tomorrow' notes",
      "export PATH=/tmp/other; grep 'keryx send peer tomorrow' notes",
      "git grep --open-files-in-pa=sh 'keryx send peer tomorrow'",
      "sort --compress-prog=sh 'keryx send peer tomorrow'",
      "sed -n p -i <<'EOF'\nkeryx send peer tomorrow\nEOF",
      "./grep 'keryx send peer tomorrow' notes",
      "/tmp/evil/cat 'keryx send peer tomorrow'",
      "find . -exec ./grep 'keryx send peer tomorrow' {} \\;",
      "find . -exec grep --invented 'keryx send peer tomorrow' {} +",
      "xargs grep --invented 'keryx send peer tomorrow'",
      "uniq source output <<'EOF'\nkeryx send peer tomorrow\nEOF"
    ]
    (%w[grep rg head tail sort uniq wc cut tr diff cat tee read echo] +
     ['git log', 'git show', 'git grep', 'gh search code', 'gh issue list']).each do |reader|
      commands << "#{reader} --invented 'keryx send peer tomorrow'"
      commands << "#{reader} --invented=value 'keryx send peer tomorrow'"
    end
    %w[claude codex cursor].each do |harness|
      commands.each { |command| assert_unchecked(harness, command: command) }
    end
  end

  def test_rev24_common_reader_options_are_silent
    commands = [
      "grep -rn -e 'keryx send peer tomorrow' notes", "rg -n --hidden -g '*.md' 'keryx send peer tomorrow' .",
      "head -n 5", "tail -n 5", "sort -t: -k2 -nr", "uniq -c -i", "wc -l", "cut -d: -f1",
      "tr -ds ' ' '\\n'", "diff -u a b", "cat -n", "tee -a saved",
      "echo -ne 'keryx send peer tomorrow'", "printf -- '%s\\n' 'keryx send peer tomorrow'",
      "git log -S'keryx send peer tomorrow' --oneline", "git show --format='keryx send peer tomorrow' HEAD",
      "git grep -n -e 'keryx send peer tomorrow'", "gh search code 'keryx send peer tomorrow' --owner owner",
      "gh issue list --search 'keryx send peer tomorrow' -R owner/repo", "sed -n '/keryx send peer tomorrow/p'",
      "awk -F : '/keryx send peer tomorrow/ {print $0}'", "find . -name '*.md' -exec grep -l 'keryx send peer tomorrow' {} +",
      "xargs grep -l 'keryx send peer tomorrow'", "/usr/bin/grep 'keryx send peer tomorrow' notes",
      "/bin/grep 'keryx send peer tomorrow' notes", "bash -o noexec", "bash -n"
    ]
    commands.map! { |command| command.include?('keryx send') ? command : "#{command} <<'EOF'\nkeryx send peer tomorrow\nEOF" }
    %w[claude codex cursor].each do |harness|
      commands.each do |command|
        _, error = assert_pass(harness, command: command)
        assert_empty error, command
      end
    end
  end

  def test_rev24_writing_readers_invalidate_file_bodies
    Dir.mktmpdir('nomos-presend-') do |dir|
      path = File.join(dir, 'body')
      File.write(path, 'Clean.')
      File.write(File.join(dir, 'source'), 'tomorrow')
      writers = ["sort -o #{path} #{dir}/source", "sort --output=#{path} #{dir}/source", "uniq #{dir}/source #{path}",
                 "sed -n p -i #{path}", "sed -n p --in-place #{path}", "find #{dir}/source -fprint #{path}",
                 "find #{dir}/source -fprintf #{path} %p", "find #{dir}/source -fls #{path}"]
      %w[claude codex cursor].each do |harness|
        writers.each { |writer| assert_unchecked(harness, command: "#{writer}; keryx send peer --file #{path}") }
        File.write(path, 'tomorrow ' + 'x' * 65_536)
        _, error = assert_unchecked(harness, command: "keryx send peer --file #{path}")
        assert_match(/body file exceeds 64 KiB/, error)
        File.write(path, 'Clean.')
      end
    end
  end

  def test_rev24_confirmation_is_segment_scoped_and_persistent_only_when_set
    %w[claude codex cursor].each do |harness|
      assert_denied(harness, 'NOMOS_PRESEND_CONFIRMED=1 true; keryx send peer tomorrow')
      assert_unchecked(harness, command: "NOMOS_PRESEND_CONFIRMED=1 keryx send peer tomorrow; sh -c 'keryx send peer tomorrow'")
      ['NOMOS_PRESEND_CONFIRMED=1', 'export NOMOS_PRESEND_CONFIRMED=1'].each do |setting|
        _, error = assert_pass(harness, command: "#{setting}; keryx send peer tomorrow; sh -c 'keryx send peer tomorrow'")
        assert_empty error
        assert_denied(harness, "#{setting}; NOMOS_PRESEND_CONFIRMED=0; keryx send peer tomorrow")
        assert_denied(harness, "#{setting}; NOMOS_PRESEND_CONFIRMED=0 keryx send peer tomorrow")
      end
    end
  end

  def test_rev24_inline_message_consumers_are_data
    commands = %w[-m --message].map { |option| "git commit #{option} 'keryx send peer tomorrow'" }
    ['gh pr create', 'gh issue create', 'gh pr comment 1'].each do |consumer|
      %w[-t --title -b --body].each { |option| commands << "#{consumer} #{option} 'keryx send peer tomorrow'" }
    end
    %w[claude codex cursor].each do |harness|
      commands.each do |command|
        _, error = assert_pass(harness, command: command)
        assert_empty error
      end
    end
  end

  def test_rev25_tools_contract_and_unknown_serialized_inputs
    %w[claude codex].each do |harness|
      tools = harness == 'claude' ? %w[Bash Monitor] : %w[Bash]
      tools.each do |name|
        output, error, status = run_hook(harness, input: JSON.generate(tool_name: name, tool_input: { command: 'keryx send peer tomorrow' }))
        assert_equal 0, status
        assert_empty error
        assert_equal 'deny', JSON.parse(output).dig('hookSpecificOutput', 'permissionDecision')
      end
      %w[PowerShell unknown exec_command shell apply_patch].each do |name|
        assert_unchecked(harness, input: JSON.generate(tool_name: name, tool_input: { command: 'keryx send peer tomorrow' }))
        assert_unchecked(harness, input: JSON.generate(tool_name: name, tool_input: { script: ['keryx send peer tomorrow'] }))
        _, error = assert_pass(harness, input: JSON.generate(tool_name: name, tool_input: { script: ['clean'] }))
        assert_empty error
      end
    end
    _, error = assert_pass('cursor', input: JSON.generate(hook_event_name: 'preToolUse', command: 'keryx send peer tomorrow'))
    assert_empty error
  end

  def test_rev25_words_in_hook_mode_and_default_cwd
    Dir.mktmpdir('nomos-presend-') do |dir|
      File.write(File.join(dir, 'words'), "amanha\n")
      File.write(File.join(dir, 'body'), 'tomorrow')
      %w[claude codex cursor].each do |harness|
        output, error, status = run_hook(harness, command: 'keryx send peer amanha', extra: ['--words', File.join(dir, 'words')])
        assert_equal 0, status
        assert_empty error
        assert_match(/deny/, output)
        data = JSON.parse(fixture("#{harness}.json"))
        data.delete('cwd')
        command = 'keryx send peer --file body'
        harness == 'cursor' ? data['command'] = command : data['tool_input']['command'] = command
        Dir.chdir(dir) do
          output, error, status = run_hook(harness, input: JSON.generate(data))
          assert_equal 0, status
          assert_empty error
          assert_match(/deny/, output)
        end
      end
    end
  end

  def test_rev25_invalid_arguments_and_help
    [[], ['--harness', 'cursr'], ['--harness', 'claud'], ['--harness']].each do |arguments|
      output, error, status = Open3.capture3(RbConfig.ruby, SCRIPT, *arguments, stdin_data: fixture('claude.json'))
      assert_equal 0, status.exitstatus
      assert_empty output
      assert_match(/Repair the pre-send hook/, error)
    end
    %w[-h --help].each do |argument|
      output, error, status = Open3.capture3(RbConfig.ruby, SCRIPT, argument)
      assert_equal 0, status.exitstatus
      assert_match(/Usage:/, output)
      assert_empty error
    end
    output, error, status = Open3.capture3(RbConfig.ruby, SCRIPT, '--check', 'unused', '--harness', 'claude')
    assert_equal 2, status.exitstatus
    assert_empty output
    assert_match(/check incomplete/, error)
  end

  def test_rev27_tool_input_strings_are_walked_without_encoding
    inputs = [
      { command: '& "keryx" send peer tomorrow' }, { command: 'keryx.exe send peer tomorrow' },
      { command: "keryx `\nsend peer tomorrow" }, { command: 'KERYX.EXE SEND peer tomorrow' },
      { command: "keryx\tsend peer tomorrow" }, { command: "/usr/bin/keryx \\\nreply peer tomorrow" },
      { command: "keryx a b \\\nc send peer tomorrow" },
      { args: ['keryx', 'ask', 'peer', 'tomorrow'] }, { first: 'clean', second: 'keryx send peer tomorrow' },
      { nested: [{ deeper: ['clean', { command: 'keryx send peer tomorrow' }] }] },
      { 'keryx reply peer tomorrow' => 'clean' }, { script: 'x' * 1200 + ' keryx send peer tomorrow' },
      { script: 'keryx a b c send peer tomorrow' }, { args: ['keryx', { ignored: 'clean' }, 'send', 'peer', 'tomorrow'] }
    ]
    %w[claude codex].each do |harness|
      %w[PowerShell unknown].each do |tool|
        inputs.each { |input| assert_unchecked(harness, input: JSON.generate(tool_name: tool, tool_input: input)) }
      end
      %w[Bash Monitor].each do |tool|
        assert_unchecked(harness, input: JSON.generate(tool_name: tool, tool_input: { args: ['keryx', 'send', 'peer', 'tomorrow'] }))
      end
      %w[PowerShell unknown Bash Monitor].each do |tool|
        [{ tool_name: tool }, { tool_name: tool, tool_input: nil }].each do |data|
          _, error = assert_unchecked(harness, input: JSON.generate(data))
          assert_match(/Repair/, error)
        end
      end
    end
  end

  def test_rev27_tool_input_noise_size_and_depth
    quiet = [
      { command: 'keryx inbox' }, { command: 'mykeryx send peer tomorrow' },
      { command: 'keryx_send peer tomorrow' }, { command: 'keryx a b c d send peer tomorrow' },
      { command: 'The keryx program has several documented uses. We send reports.' },
      { command: 'x' * 70_000 }, { data: ['x' * 600_000] }, { ws: { url: 'wss://example.test/watch' } },
      { command: false }, { command: ['clean'] }
    ]
    %w[claude codex].each do |harness|
      %w[PowerShell unknown Monitor Bash].each do |tool|
        quiet.each do |input|
          next if tool == 'Bash' && input[:command].is_a?(String) && input[:command].bytesize > 65_536
          next if harness == 'claude' && tool == 'Monitor' && input[:command].is_a?(String) && input[:command].bytesize > 65_536
          _, error = assert_pass(harness, input: JSON.generate(tool_name: tool, tool_input: input))
          assert_empty error, [tool, input.keys].inspect
        end
      end
      _, error = assert_unchecked(harness, input: JSON.generate(tool_name: 'unknown', tool_input: { data: 'x' * 70_000 + ' keryx inbox' }))
      assert_match(/64 KiB/, error)
      refute_match(/Repair/, error)
      nested = 'keryx send peer tomorrow'
      34.times { nested = [nested] }
      _, error = assert_unchecked(harness, input: JSON.generate(tool_name: 'unknown', tool_input: nested))
      assert_match(/nesting/, error)
    end
  end

  def test_rev27_cursor_literal_and_messages
    output, error, status = run_hook('cursor', command: 'keryx inbox')
    assert_equal 0, status
    assert_empty error
    # Changing this decision reopens the HN37 live approval probe.
    assert_equal({ 'permission' => 'allow' }, JSON.parse(output))
    output, = assert_unchecked('cursor', command: "sh -c 'keryx send peer tomorrow'")
    data = JSON.parse(output)
    assert_match(/command passed unchecked/, data.fetch('user_message'))
    assert_equal data.fetch('agent_message'), data.fetch('user_message')
    _, error = assert_unchecked('cursor', input: JSON.generate(tool_input: { command: 'keryx send peer tomorrow' }))
    assert_match(/Repair/, error)
  end

  def test_rev27_error_contracts_and_exit_signals
    %w[claude codex cursor].each do |harness|
      _, error = assert_unchecked(harness, command: "keryx send peer '#{'x' * 70_000}'")
      refute_match(/Repair/, error)
      [SystemExit.new(7), SignalException.new('TERM')].each do |failure|
        with_method(Hook::Command::Accounting, :new, ->(*) { raise failure }) do
          assert_raises(failure.class) { run_hook(harness, command: 'keryx send peer tomorrow') }
          assert_raises(failure.class) { Hook::Command.invocation?('keryx send peer tomorrow') }
        end
      end
    end
    %w[claude codex].each do |harness|
      output, error, status = run_hook(harness, input: JSON.generate(tool_input: { command: 'keryx send peer tomorrow' }))
      assert_equal 0, status
      assert_empty error
      assert_equal 'deny', JSON.parse(output).dig('hookSpecificOutput', 'permissionDecision')
    end
    stub = "Object.send(:remove_const, :RUBY_VERSION); RUBY_VERSION = '3.1.9'; Object.send(:remove_const, :Data); load ARGV.shift"
    %w[claude codex cursor].each do |harness|
      output, error, status = Open3.capture3(RbConfig.ruby, '-e', stub, SCRIPT, "--harness=#{harness}")
      assert_equal 0, status.exitstatus
      assert_match(/Ruby 3.2 or later/, error)
      assert_match(/Ruby 3.2 or later/, output)
      refute_match(/deny/, output)
    end
    output, error, status = Open3.capture3(RbConfig.ruby, SCRIPT, '--check', File.join(FIXTURES, 'excluded.txt'), '--harness', 'claude')
    assert_equal 2, status.exitstatus
    assert_empty output
    assert_match(/check incomplete/, error)
  end

  def test_rev26_variable_changes_disable_reads_across_all_segments
    changes = [
      'export RIPGREP_CONFIG_PATH=cfg', 'RIPGREP_CONFIG_PATH=cfg', 'declare -x RIPGREP_CONFIG_PATH=cfg',
      'export GIT_PAGER=sh', 'GIT_PAGER=sh', 'declare -x GIT_PAGER=sh',
      'x=1', 'x+=1', 'x[0]=1', 'typeset x=1', 'local x', 'readonly x', 'declare -n x=y',
      'read -r PATH <<< /tmp/example', 'unset PATH', 'printf -v PATH %s /tmp/example',
      'read -r x', 'mapfile x', 'readarray x', 'getopts a x', 'unset x', 'printf -vx %s value',
      'command export x=1', 'timeout 1 env x=1 true', 'mise exec -- read x'
    ]
    reads = ["rg 'keryx send peer tomorrow' .", "git log --grep='keryx send peer tomorrow'"]
    %w[claude codex cursor].each do |harness|
      changes.product(reads).each do |change, reader|
        assert_unchecked(harness, command: "#{change}; #{reader}")
        assert_unchecked(harness, command: "#{reader}; #{change}")
      end
      assert_unchecked(harness, command: "printf -- '--pre=sh\\n' > cfg; export RIPGREP_CONFIG_PATH=cfg; rg 'keryx send peer tomorrow' .")
      assert_unchecked(harness, command: "read -r value <<'EOF'\nkeryx send peer tomorrow\nEOF")
      assert_unchecked(harness, command: "sh -c 'x=1'; grep 'keryx send peer tomorrow' notes")
      assert_unchecked(harness, command: "grep -c 'keryx send' log | bash -c 'read n; echo \"$n\"'")
      assert_unchecked(harness, command: "read -r c <<'EOF'\nkeryx send peer tomorrow\nEOF\nprintf '%s' \"$c\"")
    end
  end

  def test_rev26_no_pager_commit_clusters_and_octal_boundaries
    %w[claude codex cursor].each do |harness|
      ['log --grep=', 'show --format=', 'grep -e '].each do |reader|
        ['', '-C example '].each do |prefix|
          _, error = assert_pass(harness, command: "git #{prefix}--no-pager #{reader}'keryx send peer tomorrow'")
          assert_empty error
        end
      end
      %w[-am -sm -asm].each do |option|
        _, error = assert_pass(harness, command: "git commit #{option} 'keryx send peer tomorrow'")
        assert_empty error
      end
      assert_unchecked(harness, command: "git commit -Zam 'keryx send peer tomorrow'")
      assert_unchecked(harness, command: "echo -e 'true\\0012keryx send peer tomorrow' | sh")
      assert_unchecked(harness, command: "printf '%b' 'true\\0012keryx send peer tomorrow' | sh")
    end
  end

  def test_rev26_checker_lines_flags_cap_and_file_bound
    assert_equal [2, 3, 4], flags("é漢\ntoday\n{revision}\ntomorrow").map(&:line)
    body = ("today\n" * 1000)
    %w[claude codex cursor].each do |harness|
      output, error, status = run_hook(harness, command: "keryx send peer '#{body}'")
      assert_equal 0, status
      assert_empty error
      data = JSON.parse(output)
      reason = harness == 'cursor' ? data.fetch('agent_message') : data.fetch('hookSpecificOutput').fetch('permissionDecisionReason')
      assert_equal 50, reason.lines.count { |line| line.start_with?('line ') }
      assert_match(/950 more flags/, reason)
      assert_operator reason.bytesize, :<, 5000
    end
    Dir.mktmpdir('nomos-presend-') do |dir|
      path = File.join(dir, 'body')
      File.write(path, body)
      output, error, status = Open3.capture3(RbConfig.ruby, SCRIPT, '--check', path)
      assert_equal 1, status.exitstatus
      assert_empty error
      assert_equal 50, output.lines.count { |line| line.start_with?('line ') }
      assert_match(/950 more flags/, output)
      File.write(path, 'x' * 65_537)
      output, error, status = Open3.capture3(RbConfig.ruby, SCRIPT, '--check', path)
      assert_equal 2, status.exitstatus
      assert_empty output
      assert_match(/64 KiB.*check incomplete/, error)
    end
  end

  def test_rev26_checker_time_does_not_consume_command_budget
    original = Hook::Checker.method(:new)
    with_method(Hook::Checker, :new, ->(**options) {
      checker = original.call(**options)
      check = checker.method(:check)
      checker.define_singleton_method(:check) { |body| sleep 0.25; check.call(body) }
      checker
    }) do
      %w[claude codex cursor].each { |harness| assert_denied(harness, 'keryx send peer tomorrow') }
    end
    body = "## Findings\n1. suggestion, start\nObserved.\n" + (1..4500).map { |n| "#{n}. step\n" }.join + "\nnomos v0 review findings\n"
    Dir.mktmpdir('nomos-presend-') do |dir|
      path = File.join(dir, 'body')
      File.write(path, body)
      %w[claude codex cursor].each do |harness|
        output, error, status = run_hook(harness, command: "keryx send peer --file #{path}")
        assert_equal 0, status
        assert_empty error
        assert_match(/deny/, output)
        assert_match(/missing heading/, output)
      end
    end
  end

end
