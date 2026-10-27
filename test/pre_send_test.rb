# frozen_string_literal: true

require 'minitest/autorun'
require 'open3'
require 'stringio'
require 'tmpdir'
require 'fileutils'
require_relative '../hooks/pre-send'

class PreSendTest < Minitest::Test
  Hook = Nomos::PreSend
  FIXTURES = File.expand_path('fixtures/pre-send', __dir__)
  SCRIPT = File.expand_path('../hooks/pre-send.rb', __dir__)
  NOW = Time.utc(2026, 10, 25, 18, 0, 0)
  # A keryx on PATH that lists no address and records each call, so no hook-mode run reaches the real keryx who.
  KERYX_STUB = Dir.mktmpdir('nomos-keryx-stub-')
  KERYX_CALLS = File.join(KERYX_STUB, 'calls')
  File.write(File.join(KERYX_STUB, 'keryx'), "#!/bin/sh\necho \"$*\" >> '#{KERYX_CALLS}'\necho '{\"addresses\": []}'\n", perm: 0o755)
  Minitest.after_run { FileUtils.rm_rf(KERYX_STUB) }
  HERMETIC = { 'PATH' => "#{KERYX_STUB}:#{ENV.fetch('PATH', '/usr/bin:/bin')}", 'KERYX_AS' => nil }.freeze

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
    runner = Hook::Runner.new(input: StringIO.new(input || JSON.generate(data)), output: output, error: error, directory: -> { [] })
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
    result = flags('glimdä GLIMDÄ zør lo a+b cglimdä', words: ['glimdä', 'zør lo', 'a+b'])
    assert_equal ['glimdä', 'GLIMDÄ', 'zør lo', 'a+b'], result.map(&:text).sort_by { |t| ['glimdä', 'GLIMDÄ', 'zør lo', 'a+b'].index(t) }
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
    assert_empty flags('I will return "tomorrow".')
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
    # Carried rule of hook-spec-r2: a deadline word exempts a same-day time unless a stamp word is near it.
    ['Reply by 18:06 UTC.', 'Wait until 18:06 UTC.', 'Due 18:06 UTC.',
     'Due 18:05:01 UTC.'].each do |body|
      assert_empty flags(body), body
    end
    ['Sent by nomos at 18:06 UTC.', 'Prazo de entrega: 18:06 UTC.'].each do |body|
      assert_equal ['18:06 UTC'], flags(body).map(&:text), body
    end
    assert_empty flags('Observed 18:05 UTC.')
    assert_equal ['18:05:01 UTC'], flags('Observed 18:05:01 UTC.').map(&:text)
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
     'Sent by 19:30 UTC.', 'The run took longer than expected and ended at 19:30 UTC.',
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
      assert_equal ['missing heading: Required field'], flags("Done.\nnomos v0 custom\n", templates: dir).map(&:text)
      assert_empty flags("## Required field\nDone.\nnomos v0 custom\n", templates: dir)
      File.write(template, "# A form\n## New field\nnomos v0 custom\n")
      result = flags("## Required field\nDone.\nnomos v0 custom\n", templates: dir)
      assert_equal ['missing heading: New field'], result.map(&:text)
      assert_equal [3], result.map(&:line)
    end
  end

  def test_footer_must_be_last_nonempty_prose_line
    refute_empty flags("Done.\nnomos v0 review brief\n")
    assert_empty flags("nomos v0 review brief\nUnrelated text\n")
    assert_empty flags("`nomos v0 review brief`\n")
    assert_empty flags("> nomos v0 review brief\n")
    assert_empty flags('Text without a form')
    assert_empty flags("Done.\nnomos v1 review brief\n")
  end

  def test_footer_shared_by_templates_checks_no_headings
    assert_empty flags("Done.\nnomos v0 human message\n\n")
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'one.md'), "# One\n## First field\nnomos v0 shared\n")
      File.write(File.join(dir, 'two.md'), "# Two\n## Second field\nnomos v0 shared\n")
      assert_empty flags("Done.\nnomos v0 shared\n", templates: dir)
      File.delete(File.join(dir, 'two.md'))
      assert_equal ['missing heading: First field'], flags("Done.\nnomos v0 shared\n", templates: dir).map(&:text)
    end
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
        stdout, stderr, status = Open3.capture3(HERMETIC, RbConfig.ruby, SCRIPT, '--harness', harness, stdin_data: JSON.generate(data))
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
      output, error, status = Open3.capture3(HERMETIC, RbConfig.ruby, '-e', stub, SCRIPT, '--harness', harness)
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
      File.write(File.join(dir, 'words'), "glimdä\n")
      File.write(File.join(dir, 'body'), "Back glimdä.\n")
      stdout, stderr, status = Open3.capture3(RbConfig.ruby, SCRIPT, '--check', File.join(dir, 'body'), '--words', File.join(dir, 'words'))
      assert_equal 1, status.exitstatus
      assert_match(/glimdä/, stdout.force_encoding('UTF-8'))
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
      stdout, stderr, status = Open3.capture3(HERMETIC, RbConfig.ruby, SCRIPT, '--harness', harness, stdin_data: fixture("#{harness}.json"))
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
      output, error, status = Open3.capture3(HERMETIC, RbConfig.ruby, SCRIPT, *arguments, stdin_data: fixture('claude.json'))
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
      output, error, status = Open3.capture3(HERMETIC, RbConfig.ruby, '-e', stub, SCRIPT, "--harness=#{harness}")
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
      checker.define_singleton_method(:check) { |body, context = nil| sleep 0.25; check.call(body, context) }
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

  BLOCK_NOW = Time.new(2026, 10, 26, 7, 0, 0, '-03:00')
  CHOICE = <<~BODY
    Where process decisions live
    ```nomos
    {"kind": "choice",
     "options": [{"id": "keep", "label": "Keep as it is"},
                 {"id": "move", "label": "Move to the Project"}],
     "blocks": null, "meanwhile": "I continue with the file", "if_silent": "I keep it as it is",
     "default": "keep"}
    ```
    Nothing waits on this; I continue with the file.

    1. Keep as it is (`keep`).
    2. Move to the Project (`move`).

    If no answer comes until 2026-10-26 08:00 -0300, I keep it as it is.

    nomos v0 human message
  BODY
  NOTICE = "The usage page answers again\n```nomos\n{\"kind\": \"notice\"}\n```\nThe page answers again.\n"

  # A body to a human gets the footer it lacks, so each test sees only the rule it is about; footer: false keeps it out.
  def human(body, action: 'ask', within: 3600, human: true, now: BLOCK_NOW, vocabulary: {}, footer: true)
    body += "\n#{Nomos::Text::HUMAN_FOOTER}\n" if footer && human == true && !Nomos::Text.footer?(body)
    Hook::Checker.new(now: now, vocabulary: vocabulary).check(body, Hook::Context.new(action: action, recipient: 'ana.local', within: within, human: human))
  end

  def kinds(body, **options) = human(body, **options).map(&:kind).uniq.sort

  def test_block_spec_passes_and_ask_rules
    assert_empty human(CHOICE)
    assert_empty human(NOTICE, action: 'send', within: nil)
    assert_equal ['block placement'], kinds("The page is back\nNothing to do.\n", action: 'send', within: nil)
    assert_equal ['block footer', 'block missing'], kinds("The page is back\nNothing to do.\n", action: 'send', within: nil, footer: false)
    assert_equal ['block kind'], kinds("Keep as it is\n```nomos\n{\"kind\": \"answer\", \"answer\": \"keep\"}\n```\n", action: 'reply', within: nil, human: nil)
    assert_equal ['ask without block', 'block footer'], kinds('May I delete the old branch?', footer: false)
    assert_equal ['ask not a request', 'ask without deadline'], kinds(CHOICE, action: 'send', within: nil)
    assert_equal ['deadline differs', 'deadline not in text', 'future time'], kinds(CHOICE, within: 7200)
  end

  def test_block_placement_json_and_size
    lines = CHOICE.lines
    assert_includes kinds(([lines[1]] + [lines[0]] + lines[2..]).join), 'block placement'
    assert_includes kinds(([lines[0], "\n"] + lines[1..]).join), 'block placement'
    assert_equal ['block json'], kinds("Question\n```nomos\n{\"kind\": \"question\",\n```\nText.\n")
    big = CHOICE.sub('"I continue with the file"', "\"#{'λ' * 40}\"").sub('"if_silent": "I keep it as it is"', "\"if_silent\": \"I keep it\", \"x\": \"#{'λ' * 400}\"")
    flags = human(big)
    assert_equal ['block size'], flags.map(&:kind).uniq, flags.inspect
    assert_match(/longest field x/, flags.first.text)
    pad = 1024 - CHOICE.lines[1..7].sum(&:bytesize)
    exact = CHOICE.sub('"default": "keep"}', "\"default\": \"keep\", \"z\": \"#{'a' * (pad - 9)}\"}")
    assert_equal 1024, exact.lines[1..7].sum(&:bytesize)
    assert_empty human(exact)
    assert_equal ['block size'], kinds(exact.sub('"z": "', '"z": "a'))
    sixteen = CHOICE.sub("\"default\": \"keep\"}\n", "\"default\": \"keep\"\n#{" \n" * 8}}\n")
    assert_equal 16, sixteen.lines[1..].index { |line| line.start_with?('```') && !line.include?('nomos') } + 2 - 1
    assert_empty human(sixteen)
    assert_equal ['block size'], kinds(sixteen.sub(" \n", " \n \n"))
  end

  def test_block_fields_options_default_time_title_labels
    assert_equal ['block default'], kinds(CHOICE.sub('"choice"', '"decision"') + "## Situation\n## Background\n## Assessment\n## Recommendation\n")
    assert_equal ['block options'], kinds(CHOICE.sub('"default": "keep"', '"recommended": "drop"'))
    assert_includes kinds(CHOICE.sub('"id": "move"', '"id": "keep"')), 'block options'
    one = CHOICE.sub('"choice"', '"decision"').sub(/,\n +\{"id": "move".*\}\]/, ']').sub(",\n \"default\": \"keep\"", '')
    assert_includes kinds(one), 'block options'
    [[%q("meanwhile": "I continue with the file"), %Q("meanwhile": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")], [%q("blocks": null), %q("blocks": " ")],
     [%q("blocks": null), %q("blocks": null, "text": "only")]].each do |old, field|
      assert_equal ["block field"], kinds(CHOICE.sub(old, field)), field
    end
    assert_equal ['block field', 'label not in text'], kinds(CHOICE.sub('Move to the Project"', "#{'b' * 61}\""))
    four = Array.new(4) { |n| "{\"url\": \"https://example.com/#{n}\", \"label\": \"L#{n}\"}" }.join(', ')
    assert_equal ['block field'], kinds(NOTICE.sub('"notice"', "\"notice\", \"links\": [#{four}]"), action: 'send', within: nil)
    assert_equal ['block time'], kinds(CHOICE.sub('I keep it as it is"', 'I keep it, 08h00"'))
    ['## Title', '- Title', '> Title', '```', '', 'T' * 81].each do |title|
      assert_includes kinds(CHOICE.sub(/\A.*\n/, "#{title}\n")), 'block title', title
    end
    assert_equal ['id not in text', 'label not in text'], kinds(CHOICE.sub("2. Move to the Project (`move`).\n", ''))
    assert_equal ['id not in text'], kinds(CHOICE.sub("(`move`)", ''))
    decision = CHOICE.sub('"choice"', '"decision"').sub(",\n \"default\": \"keep\"", '')
    assert_equal ['missing heading: Background'], human(decision + "## Situation\n## Assessment\n## Recommendation\n").map(&:text)
    assert_empty human("Done\n```nomos\n{\"kind\": \"notice\"}\n```\nReady.\n\nnomos v0 human message\n", action: 'send', within: nil)
  end

  def test_block_files
    file_flags = ->(path) { human(NOTICE.sub('"notice"', "\"notice\", \"files\": [{\"path\": #{path.to_json}, \"label\": \"Nota\"}]"), action: 'send', within: nil) }
    Dir.mktmpdir('nomos-files-') do |dir|
      base = File.realpath(dir)
      File.write(File.join(base, 'note.md'), "ok\n")
      File.write(File.join(base, 'exact.md'), 'a' * (1024 * 1024))
      File.write(File.join(base, 'big.md'), 'a' * (1024 * 1024 + 1))
      File.write(File.join(base, 'image.bin'), "x\n")
      File.write(File.join(base, 'shut.md'), "x\n", perm: 0o000)
      Dir.mkdir(File.join(base, '.hidden'))
      File.write(File.join(base, '.hidden', 'note.md'), "x\n")
      Dir.mkdir(File.join(base, 'folder.md'))
      File.symlink(File.join(base, '.hidden', 'note.md'), File.join(base, 'link.md'))
      File.write(File.join(base, 'tokens.md'), "x\n")
      File.symlink(File.join(base, 'tokens.md'), File.join(base, 'plain.md'))
      secrets = %w[secret credential password token kubeconfig .env id_rsa id_ed25519 .pem .key].map do |word|
        File.join(base, "a#{word}b.md").tap { |path| File.write(path, "x\n") }
      end
      home = ENV.fetch('HOME', nil)
      begin
        ENV['HOME'] = base
        assert_empty file_flags.call('~/note.md')
        assert_empty file_flags.call('~/exact.md')
        cases = {
          '~/folder.md' => 'not a regular file', '~/missing.md' => 'no such readable file', '~/big.md' => 'over 1 MiB',
          '~/image.bin' => 'not a text extension', '~/.hidden/note.md' => 'starts with a dot',
          '~/link.md' => 'starts with a dot', '~/plain.md' => 'secret-like name', "~/no\0ta.md" => 'no such readable file',
          'notes/note.md' => 'absolute or starts with ~/'
        }.merge(Process.uid.zero? ? {} : { '~/shut.md' => 'not readable' })
        cases.each do |path, reason|
          flags = file_flags.call(path)
          assert_equal ['block file'], flags.map(&:kind), path
          assert_match(/#{reason}/, flags.first.text, path)
        end
        secrets.each do |path|
          flags = file_flags.call("~/#{File.basename(path)}")
          assert_equal ['block file'], flags.map(&:kind), path
          assert_match(/secret-like name|starts with a dot/, flags.first.text, path)
        end
        assert_match(/secret-like name/, file_flags.call('~/asecretb.md').first.text)
      ensure
        ENV['HOME'] = home
      end
      if base.split('/').any? { |part| part.start_with?('.') }
        assert_match(/starts with a dot/, file_flags.call(File.join(base, 'note.md')).first.text)
      else
        assert_empty file_flags.call(File.join(base, 'note.md'))
      end
    end
  end

  def test_claimed_form_and_recipients
    bare = "Report delivered\n{\"kind\": \"result\", \"outcome\": \"done\", \"follows\": \"ZZZZZZZZZZZZZZZZZZZZZZZZZZ\"}\n\nText.\n\nnomos v0 human message\n\n"
    assert_equal ['block placement'], kinds(bare, action: 'reply', within: nil, human: nil)
    fenced = bare.sub(/^\{.*\}\n/) { |json| "```nomos\n#{json}```\n" }
    assert_empty human(fenced, action: 'reply', within: nil, human: nil)
    assert_equal ['block placement'], kinds("Done\nText.\n\nnomos v0 human message\n", action: 'send', within: nil)
    assert_empty human("Done\nText.\n", action: 'reply', within: nil, human: nil)
    assert_empty human(bare, action: 'send', within: nil, human: false)
    assert_empty human(CHOICE, action: 'send', within: nil, human: false)
    assert_empty human("Review\n````text\n#{CHOICE}````\n", action: 'reply', within: nil, human: nil)
    %w[json nomos-1].push('').each do |info|
      assert_equal ['block placement'], kinds(fenced.sub('```nomos', "```#{info}"), action: 'reply', within: nil, human: nil), info
    end
    rows = [{ 'address' => 'ana.ops@box', 'member' => 'ana', 'team' => 'ops', 'host' => 'box', 'role' => 'human' },
            { 'address' => 'orq.alpha@box', 'member' => 'orq', 'team' => 'alpha', 'host' => 'box', 'role' => 'orchestrator',
              'join' => { 'session_id' => 's-1' } },
            { 'address' => 'rev-1.alpha@box', 'member' => 'rev-1', 'team' => 'alpha', 'host' => 'box', 'role' => 'reviewer' }]
    directory = Hook::Recipients.new(source: -> { rows })
    assert directory.human?('ana.local')
    refute directory.human?('ana.ops')
    refute directory.human?('orq.alpha@box')
    assert directory.human?('ana@box')
    assert_equal false, directory.human?('rev-1', session_id: 's-1')
    assert_equal false, directory.human?('rev-1', sender: 'orq.alpha')
    assert_equal false, directory.human?('rev-1', sender: 'orq.beta')
    assert_equal false, directory.human?('ana')
    assert Hook::Recipients.new(source: -> { [{ 'member' => 'bob', 'team' => 'local' }] }).human?('bob')
    assert Hook::Recipients.new(source: -> { [] }).human?('ana.local')
    assert_nil Hook::Recipients.new(source: -> { raise 'down' }).human?('rev-1')
    Dir.mktmpdir('nomos-who-') do |dir|
      slow = File.join(dir, 'slow')
      File.write(slow, "#!#{RbConfig.ruby}\nsleep 5\n", perm: 0o755)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      assert_nil Hook::Recipients.new(command: [slow], timeout: 0.2).human?('ana')
      assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 2
      assert_nil Hook::Recipients.new(command: [File.join(dir, 'missing')]).human?('orq')
      refute Hook::Recipients.new(command: [File.join(dir, 'missing')]).human?('orq.alpha')
      bad = File.join(dir, 'bad')
      File.write(bad, "#!#{RbConfig.ruby}\nputs 'no json'\n", perm: 0o755)
      assert Hook::Recipients.new(command: [bad]).human?('ana.local')
    end
  end

  def test_hook_runs_block_checks_for_human_recipients_only
    rows = [{ 'member' => 'ana', 'team' => 'local', 'host' => 'box', 'role' => 'human' },
            { 'member' => 'orq', 'team' => 'ops', 'host' => 'box', 'role' => 'orchestrator' }]
    Dir.mktmpdir('nomos-hook-') do |dir|
      path = File.join(dir, 'choice.md')
      File.write(path, CHOICE)
      %w[claude codex cursor].each do |harness|
        data = JSON.parse(fixture("#{harness}.json"))
        command = "keryx send ana.local --file #{path}"
        harness == 'cursor' ? data['command'] = command : data['tool_input']['command'] = command
        output = StringIO.new
        Hook::Runner.new(input: StringIO.new(JSON.generate(data)), output: output, error: StringIO.new,
                         directory: -> { rows }).run(['--harness', harness])
        assert_match(/ask not a request/, output.string, harness)
        data = JSON.parse(JSON.generate(data).sub('ana.local', 'orq.ops'))
        output = StringIO.new
        Hook::Runner.new(input: StringIO.new(JSON.generate(data)), output: output, error: StringIO.new,
                         directory: -> { rows }).run(['--harness', harness])
        refute_match(/block|ask not/, output.string, harness)
      end
    end
  end

  def test_check_inputs_and_exit_codes
    Dir.mktmpdir('nomos-check-') do |dir|
      path = File.join(dir, 'choice.md')
      File.write(path, CHOICE)
      base = [RbConfig.ruby, SCRIPT, '--check', path, '--action', 'ask', '--to', 'ana.local', '--now', '2026-10-26T07:00:00-03:00']
      stdout, _, status = Open3.capture3(*base, '--within', '1h')
      assert_equal [0, ''], [status.exitstatus, stdout]
      stdout, _, status = Open3.capture3(*base, '--within', '2h')
      assert_equal 1, status.exitstatus
      assert_match(/future time/, stdout)
      [%w[--action shout], %w[--within soon], %w[--now never]].each do |option|
        assert_equal 2, Open3.capture3(*base, *option)[2].exitstatus, option.inspect
      end
    end
  end

  def test_quoted_mentions_and_deadline_words
    assert_empty flags('## Never "today"')
    assert_empty flags('For example “glimday”.', words: ['glimday'])
    assert_equal 1, flags('Quote "today without a close.').length
    assert_equal 1, flags("Return 'today'.").length
    assert_equal 1, flags('Back today.').length
    # Carried rule of hook-spec-r2: a deadline word exempts a same-day time unless a stamp word is near it.
    ['I will deliver the plan by 2026-10-25 21:00 UTC.', 'Finished by 19:30 UTC.', 'It worked until 19:30 UTC.'].each do |body|
      assert_empty flags(body), body
    end
    assert_equal ['19:30 UTC'], flags('Sent at 19:30 UTC.').map(&:text)
    assert_equal ['19:00 UTC'], flags('Ran at 19:00 UTC and I deliver by 21:00 UTC.').map(&:text)
  end

  def test_h5_wrapper_rows
    reads = { 'mise exec -- grep' => true, 'mise x -- grep' => true, 'nohup grep' => false, 'exec grep' => false,
              'timeout --foreground 5 grep' => false, 'timeout -k 1 5 grep' => false, 'command -p grep' => false }
    %w[claude codex cursor].each do |harness|
      reads.each do |wrapper, warns|
        command = "#{wrapper} 'keryx send orq hi' notes"
        warns ? assert_unchecked(harness, command: command) : assert_pass(harness, command: command)
      end
    end
  end

  def notice_with(fields) = "Notice\n```nomos\n{\"kind\": \"notice\"#{fields}}\n```\nText.\n"

  def test_fix_round_block_json_is_strict_on_every_json_gem
    ['{"kind":"notice","kind":"notice"}', '{"kind":"notice","files":[],"files":[]}', '{"kind":"nope","kind":"notice"}',
     '{"kind":"notice","kind":"nope"}', '{"kind":"notice"} // c', '{"kind":"notice"} /* c */',
     '{"kind":"notice", /* c */ "files": []}', '{"kind":"notice","x":"\q"}', '{"kind":"notice",}', "{'kind':'notice'}",
     '{"kind":"notice","x":NaN}', '{"kind":"notice","x":01}', '{"kind":"notice","x":' + '[' * 100 + ']' * 100 + '}',
     '{"kind":"notice","kind":"notice"}'].each do |json|
      assert_equal ['block json'], kinds("Notice\n```nomos\n#{json}\n```\nText.\n", action: 'send', within: nil), json
    end
    assert_empty human("Notice\n```nomos\n{\"kind\": \"notice\", \"x\": [#{'[' * 98}#{']' * 98}], \"y\": \"a\\u00e7\\n\"}\n```\nText.\n", action: 'send', within: nil)
  end

  def test_fix_round_limits_at_and_past_each_bound
    title = ->(text) { kinds(CHOICE.sub(/\A.*\n/, "#{text}\n")) }
    assert_empty title.call('T' * 80)
    assert_empty title.call('λ' * 80)
    assert_equal ['block title'], title.call('λ' * 81)
    label = ->(text) { kinds(CHOICE.gsub('Move to the Project', text)) }
    assert_empty label.call('b' * 60)
    assert_equal ['block field'], label.call('b' * 61)
    assert_empty kinds(CHOICE.sub('"blocks": null', "\"blocks\": \"#{'w' * 80}\""))
    assert_equal ['block field'], kinds(CHOICE.sub('"blocks": null', "\"blocks\": \"#{'w' * 81}\""))
    id = ->(text) { kinds(CHOICE.gsub('move', text)) }
    assert_empty id.call("m#{'a' * 23}")
    assert_equal ['block options'], id.call("m#{'a' * 24}")
    Dir.mktmpdir('nomos-limit-') do |dir|
      home = ENV.fetch('HOME', nil)
      ENV['HOME'] = File.realpath(dir)
      File.write(File.join(dir, 'a.md'), "x\n")
      files = ->(count) { notice_with(", \"files\": [#{Array.new(count) { '{"path": "~/a.md", "label": "A"}' }.join(', ')}]") }
      assert_empty human(files.call(3), action: 'send', within: nil)
      assert_equal ['block field'], kinds(files.call(4), action: 'send', within: nil)
    ensure
      ENV['HOME'] = home
    end
    over = "Notice\n```nomos\n{\"kind\": \"notice\",\n#{"\"x\": 1,\n" * 15}\"y\": 1}\n```\nText.\n"
    assert_match(/runs 19 lines/, human(over, action: 'send', within: nil).first.text)
  end

  def test_fix_round_field_rules_each_pinned
    send = { action: 'send', within: nil }
    {
      '{"kind": "result", "outcome": "done"}' => 'block id', '{"kind": "result", "follows": "ZZZZZZZZZZZZZZZZZZZZZZZZZZ"}' => 'block field',
      '{"kind": "notice", "replaces": "01-not-an-id"}' => 'block id',
      '{"kind": "notice", "links": [{"url": "http://example.com", "label": "L"}]}' => 'block field',
      '{"kind": "notice", "links": [{"url": "https://", "label": "L"}]}' => 'block field',
      '{"kind": "notice", "x": "a</b"}' => 'block html', '{"kind": "notice", "<b": 1}' => 'block html',
      '{"kind": "notice", "title": "T"}' => 'block field', '{"kind": "notice", "due": "x"}' => 'block time',
      '{"kind": "notice", "links": [{"url": "https://example.com", "label": "Until 26/10"}]}' => 'block time',
      '{"kind": "notice", "links": [{"url": "https://example.com", "label": "a\u0007b"}]}' => 'block field',
      '{"kind": "notice", "answer": "keep"}' => 'block field', '{"kind": "eighth"}' => 'block field'
    }.each { |json, kind| assert_equal [kind], kinds("Notice\n```nomos\n#{json}\n```\nText.\n", **send), json }
    ask = ->(fields) { "Question\n```nomos\n{\"kind\": \"question\", \"blocks\": null, \"meanwhile\": \"I continue\", \"if_silent\": \"I continue\"#{fields}}\n```\nText 1. Yes (`yes`). Answer by 2026-10-26 08:00 -03:00.\n" }
    assert_empty human(ask.call(''))
    assert_equal ['block field'], kinds(ask.call(', "text": "optional"'))
    assert_equal ['block options'], kinds(ask.call(', "options": []'))
    assert_equal ['block field'], kinds(ask.call(', "options": [{"id": "yes", "label": "Yes"}], "select": "all"'))
    assert_equal ['block default'], kinds(CHOICE.sub('"default": "keep"', '"default": "drop"'))
    seven = (1..7).map { |n| "{\"id\": \"o#{n}\", \"label\": \"O#{n}\"}" }.join(', ')
    assert_includes kinds(CHOICE.sub(/"options": \[.*?\],\n/m, "\"options\": [#{seven}],\n")), 'block options'
    assert_equal ['block time'], kinds(CHOICE.sub('I keep it as it is"', 'I keep it at 8h"'))
    assert_empty kinds(CHOICE.sub('I continue with the file"', 'I continue for 2h"'))
    decision = CHOICE.sub('"choice"', '"decision"').sub(",\n \"default\": \"keep\"", '')
    assert_equal ['missing heading: Recommendation'], human(decision + "## Situation\n## Background\n## Assessment\n").map(&:text)
    translated = decision.sub("\nnomos v0 human message\n", '') + "## Lorem\n## ipsum\n## Dolor\n## Assessment\n## AMET\n\nnomos v0 human message\n"
    assert_equal ["missing heading: Background", "missing heading: Recommendation", "missing heading: Situation"], human(translated).map(&:text)
    vocabulary = Hook.vocabulary(fixture('vocabulary.txt').lines)
    context = Hook::Context.new(action: 'ask', recipient: 'ana.local', within: 3600, human: true)
    assert_empty Hook::Checker.new(now: BLOCK_NOW, vocabulary: vocabulary).check(translated, context)
    Dir.mktmpdir('nomos-headings-') do |dir|
      body = File.join(dir, 'decision.md')
      File.write(body, translated)
      base = [RbConfig.ruby, SCRIPT, '--check', body, '--action', 'ask', '--to', 'ana.local', '--within', '1h', '--now', '2026-10-26T07:00:00-03:00']
      assert_equal 0, Open3.capture3(*base, '--words', File.join(FIXTURES, 'vocabulary.txt'))[2].exitstatus
      assert_equal 1, Open3.capture3(*base)[2].exitstatus
      File.write(File.join(dir, 'three'), "[headings]\nLorem\nIpsum\nDolor\n")
      assert_equal 2, Open3.capture3(*base, '--words', File.join(dir, 'three'))[2].exitstatus
    end
  end

  def test_fix_round_claimed_forms_and_placement
    unknown = { action: 'reply', within: nil, human: nil }
    bare = "Done\n%s\nText.\n"
    ['{ "kind": "notice" }', "{\n  \"kind\": \"notice\"\n}", "Line\n{\"kind\": \"notice\"}"].each do |json|
      assert_equal ['block placement'], kinds(format(bare, json), **unknown), json
    end
    assert_equal ['block placement'], kinds("Done\n```json\n{\"kind\": \"notice\"}\n```\n", **unknown)
    assert_equal ['block placement', 'block title'], kinds("   ```nomos\nDone\n{\"kind\": \"notice\"}\n```\n", **unknown)
    assert_equal ['block title'], kinds("## Done\n```nomos\n{\"kind\": \"notice\"}\n```\n", **unknown)
    assert_empty human("Done\n```text\nnada\n```\n", **unknown)
    Dir.mktmpdir('nomos-m1-') do |dir|
      path = File.join(dir, 'bare.md')
      File.write(path, "Done\n{\"kind\": \"notice\"}\nText.\n")
      stdout, _, status = Open3.capture3(RbConfig.ruby, SCRIPT, '--check', path)
      assert_equal 1, status.exitstatus
      assert_match(/block placement/, stdout)
    end
  end

  def test_fix_round_mentions_and_deadline_words
    silent = ['Ran at 18:00 UTC, deliver by 21:00 UTC.', 'I ran the job. Reply by 21:00 UTC.', 'Look at the plan; I deliver by 21:00 UTC.',
              'Event ran 17:00 UTC; next by 21:00 UTC', 'Due at 21:00 UTC.', 'Deadline: at 21:00 UTC.', 'I deliver zuntil klo 21:00 UTC.',
              'Ante zo 21:00 UTC.', 'I deliver ante zo 21:00 UTC.', '«glimday» is an example.']
    flagged = ['Pushed by Ana 21:00 UTC.', 'Reviewed by rev-1, 21:00 UTC.', 'By the way, observed 21:00 UTC.',
               'Written by Ana, covers 21:00 UTC.', 'Stampo 21:00 UTC.', 'The job failed due to a timeout at 21:00 UTC.',
               "Reply by\n21:00 UTC.", 'A 5" pipe is due tomorrow, then "x".', 'Use 5" screws, back tomorrow at 19:30 UTC, said "ok".']
    vocabulary = Hook.vocabulary(fixture('vocabulary.txt').lines)
    silent.each { |body| assert_empty flags(body, vocabulary: vocabulary), body }
    flagged.each { |body| refute_empty flags(body, vocabulary: vocabulary), body }
    assert_equal ['today'], flags('He said "today" and later today').map(&:text)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    flags("#{'Reply by 19:30 UTC and ' * 3000}\n")
    assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 1
    assert_equal ['future time'], kinds(CHOICE.sub('until 2026-10-26 08:00', 'at 2026-10-26 08:00'), action: 'send', within: 3600) - ['ask not a request', 'ask without deadline']
  end

  def test_fix_round_recipient_resolution_and_bounds
    rows = [{ 'address' => 'ana.ops@box', 'member' => 'ana', 'team' => 'ops', 'host' => 'box', 'role' => 'human' },
            { 'address' => 'ana.alpha@box', 'member' => 'ana', 'team' => 'alpha', 'host' => 'box', 'role' => 'implementer',
              'join' => { 'session_id' => 's-1' } },
            { 'address' => 'bob.local@box', 'member' => 'bob', 'team' => 'local', 'host' => 'box', 'role' => 'assistant' },
            { 'address' => 'x.beta@box', 'member' => 'x', 'team' => 'beta', 'host' => 'box', 'role' => 'human', 'join' => 'gone' }]
    directory = Hook::Recipients.new(source: -> { rows })
    assert_equal false, directory.human?('ana', sender: 'orq.ops')
    assert_equal false, directory.human?('ana', session_id: 's-1')
    assert_equal false, directory.human?('ana', sender: 'orq.alpha@box/abcdef')
    assert_nil directory.human?('ana')
    assert_equal false, directory.human?('ana.ops@other')
    assert_equal false, directory.human?('ana.ops@other', sender: 'x')
    assert_equal true, directory.human?('bob.local')
    assert_equal true, directory.human?('bob')
    assert_equal false, directory.human?('x', session_id: 'none')
    assert_equal true, directory.human?('carla.local')
    assert_equal true, directory.human?('carla@box')
    assert_nil directory.human?('carla', sender: 'me.local')
    Dir.mktmpdir('nomos-who-') do |dir|
      held = File.join(dir, 'held')
      File.write(held, "#!/bin/sh\n(sleep 5) &\necho '{}'\n", perm: 0o755)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      assert_nil Hook::Recipients.new(command: [held], timeout: 0.3).human?('orq')
      assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 2.5
      failing = File.join(dir, 'failing')
      File.write(failing, "#!/bin/sh\necho '{\"addresses\": [{\"member\": \"orq\", \"team\": \"alpha\", \"role\": \"human\"}]}'\nexit 3\n", perm: 0o755)
      assert_nil Hook::Recipients.new(command: [failing]).human?('orq')
      listing = File.join(dir, 'listing')
      File.write(listing, "#!/bin/sh\n[ \"$*\" = 'who --all -o json' ] || exit 4\necho '{\"addresses\": [{\"member\": \"orq\", \"team\": \"local\", \"role\": \"human\"}]}'\n", perm: 0o755)
      assert_equal true, Hook::Recipients.new(command: [listing, *Hook::Recipients::COMMAND.drop(1)]).human?('orq')
    end
  end

  def test_fix_round_hook_level_sender_within_and_wrappers
    rows = [{ 'member' => 'ana', 'team' => 'ops', 'host' => 'box', 'role' => 'human' },
            { 'member' => 'ana', 'team' => 'alpha', 'host' => 'box', 'role' => 'reviewer' }]
    Dir.mktmpdir('nomos-hook-') do |dir|
      path = File.join(dir, 'choice.md')
      File.write(path, CHOICE)
      run = lambda do |command, env: {}|
        data = JSON.parse(fixture('claude.json'))
        data['tool_input']['command'] = command
        output = StringIO.new
        saved = env.to_h { |key, _| [key, ENV.fetch(key, nil)] }
        env.each { |key, value| ENV[key] = value }
        Hook::Runner.new(input: StringIO.new(JSON.generate(data)), output: output, error: StringIO.new, directory: -> { rows }).run(['--harness', 'claude'])
        output.string
      ensure
        saved.each { |key, value| ENV[key] = value }
      end
      refute_match(/ask not a request/, run.call("keryx --as orq.ops send ana --file #{path}", env: { 'KERYX_AS' => nil }))
      refute_match(/ask not a request/, run.call("keryx send --as=orq.ops ana --file #{path}", env: { 'KERYX_AS' => nil }))
      refute_match(/ask not a request/, run.call("KERYX_AS=orq.ops keryx send ana --file #{path}", env: { 'KERYX_AS' => nil }))
      refute_match(/ask not a request/, run.call("keryx send ana --file #{path}", env: { 'KERYX_AS' => 'orq.alpha' }))
      assert_match(/ask not a request/, run.call("keryx send ana --file #{path}", env: { 'KERYX_AS' => nil }))
      assert_match(/ask not a request/, run.call("keryx send ana.local --file #{path}", env: { 'KERYX_AS' => nil }))
      assert_empty run.call("keryx ask ana.ops --within 1h --file #{path}").then { |out| out.include?('future time') ? out : '' }
      refute_match(/ask without deadline/, run.call("keryx ask ana.ops --within 60m --file #{path}"))
      assert_match(/ask without deadline/, run.call("keryx ask ana.local --file #{path}"))
    end
    %w[claude codex cursor].each do |harness|
      ['timeout --kill-after=1 5', 'timeout -s KILL 5', 'timeout --signal=TERM 5', 'timeout -k1 5', 'timeout --preserve-status -v 5s'].each do |wrapper|
        assert_pass(harness, command: "#{wrapper} grep 'keryx send orq hi' notes")
      end
      assert_unchecked(harness, command: "timeout --bogus 5 grep 'keryx send orq hi' notes")
    end
  end

  def test_fix_round_vocabulary_sections
    assert_equal({ 'relative' => %w[glimday], 'deadline' => [], 'stamp' => [], 'clock-prefix' => [], 'headings' => [],
                   'deadline-sentence' => [], 'clock' => [], 'zone' => [] },
                 Hook.vocabulary(["glimday\n", "\n"]))
    vocabulary = Hook.vocabulary(fixture('vocabulary.txt').lines)
    assert_equal [%w[glimday], ['zuntil', 'ante zo'], %w[stampo], %w[klo], %w[Lorem Ipsum Dolor Amet]],
                 vocabulary.values_at('relative', 'deadline', 'stamp', 'clock-prefix', 'headings')
    assert_raises(ArgumentError) { Hook.vocabulary(["[other]\n", "x\n"]) }
    assert_raises(ArgumentError) { Hook.vocabulary(["[headings]\n", "Lorem\n"]) }
    assert_equal ['glimday'], flags('Back glimday.', vocabulary: vocabulary).map(&:text)
    assert_equal ['21:00 UTC'], flags('Klo 21:00 UTC.', vocabulary: vocabulary).map(&:text)
    assert_empty flags('Zuntil klo 21:00 UTC.', vocabulary: vocabulary)
    assert_equal ['block time'], kinds(CHOICE.sub('I keep it as it is"', 'I keep it klo 8h"'), vocabulary: vocabulary)
    assert_empty kinds(CHOICE.sub('I keep it as it is"', 'I keep it klo 8h"'))
    Dir.mktmpdir('nomos-words-') do |dir|
      body = File.join(dir, 'body')
      File.write(body, "Ready zuntil 2026-10-25 21:00 UTC, glimday.\n")
      stdout, _, status = Open3.capture3(RbConfig.ruby, SCRIPT, '--check', body, '--now', '2026-10-25T18:00:00Z',
                                         '--words', File.join(FIXTURES, 'vocabulary.txt'))
      assert_equal [1, "line 1: relative time: glimday\n"], [status.exitstatus, stdout]
      File.write(File.join(dir, 'bad'), "[nope]\nx\n")
      assert_equal 2, Open3.capture3(RbConfig.ruby, SCRIPT, '--check', body, '--words', File.join(dir, 'bad'))[2].exitstatus
    end
  end

  def test_fix_round_rules_named_by_surviving_mutants
    unknown = { action: 'reply', within: nil, human: nil }
    assert_empty flags('He wrote "merged at 19:30 UTC" as an example.')
    assert_empty flags('Due for the whole team 21:00 UTC.')
    fenced = human("Done\n```json\n{\"kind\": \"notice\"}\n```\n", **unknown)
    assert_match(/line 2 opens a fence with info string json/, fenced.first.text)
    assert_includes kinds("   ```nomos\nDone\nnothing\n```\n", **unknown), 'block placement'
    assert_equal ['block placement'], kinds("Done\nText.\n\nnomos v0 human message\n", **unknown)
    assert_equal ['block field'], kinds("Done\n```nomos\n{\"kind\": \"result\", \"follows\": \"ZZZZZZZZZZZZZZZZZZZZZZZZZZ\", \"outcome\": \"maybe\"}\n```\n", **unknown)
    assert_equal ['block id'], kinds("Done\n```nomos\n{\"kind\": \"notice\", \"replaces\": \"01abcdefghijklmnopqrstuvwx\"}\n```\n", **unknown)
    message = ->(command) { Hook::Command.new(command).tap(&:bodies).messages.first }
    assert_equal 5400, message.call("keryx ask ana.ops --within 1h30m 'Hi'").within
    assert_equal 90, message.call("keryx ask ana.ops --within 1m30s 'Hi'").within
    assert_equal 'orq.ops', message.call("keryx --as orq.ops send ana 'Hi'").sender
    assert_equal 'orq.ops', message.call("keryx send --as=orq.ops ana 'Hi'").sender
    assert_equal 'orq.ops', message.call("KERYX_AS=orq.ops keryx send ana 'Hi'").sender
    assert_nil message.call("keryx reply ZZZZZZZZZZZZZZZZZZZZZZZZZZ 'Hi'").recipient
    assert_equal 'ana', message.call("keryx send ana 'Hi'").recipient
    %w[claude codex cursor].each do |harness|
      assert_unchecked(harness, command: "mise x -- read x; rg 'keryx send peer tomorrow' .")
    end
    Dir.mktmpdir('nomos-kill-') do |dir|
      pids = File.join(dir, 'pids')
      held = File.join(dir, 'held')
      File.write(held, "#!/bin/sh\nsleep 30 &\necho $! > #{pids}\nwait\n", perm: 0o755)
      assert_nil Hook::Recipients.new(command: [held], timeout: 0.3).human?('orq')
      pid = File.read(pids).to_i
      gone = 20.times.any? do
        Process.kill(0, pid)
        sleep 0.05
        false
      rescue Errno::ESRCH
        true
      end
      assert gone, 'the directory call left its process group running'
    end
  end

  def test_within_takes_only_keryx_form
    %w[1x 30 1h30 h 1.5h -1h 1H].each do |within|
      error = assert_raises(ArgumentError, within) { Hook::Command.new("keryx ask ana.local --within #{within} 'Hi'").bodies }
      assert_match(/invalid --within/, error.message, within)
      %w[claude codex cursor].each do |harness|
        output, error_text, status = run_hook(harness, command: "keryx ask ana.local --within #{within} 'Hi'")
        assert_equal 0, status
        assert_match(/invalid --within.*command passed unchecked/, error_text, "#{harness} #{within}")
        refute_match(/deny/, output)
      end
    end
    assert_equal 5400, Hook::Command.new("keryx ask ana.local --within 1h30m 'Hi'").tap(&:bodies).messages.first.within
  end

  def test_hook_mode_runs_never_reach_the_real_keryx
    File.write(KERYX_CALLS, '')
    stdout, _, status = Open3.capture3(HERMETIC, RbConfig.ruby, SCRIPT, '--harness', 'claude',
                                       stdin_data: JSON.generate(JSON.parse(fixture('claude.json')).tap { |data| data['tool_input']['command'] = "keryx send orq 'Done.'" }))
    assert_equal 0, status.exitstatus
    assert_empty stdout
    assert_equal "who --all -o json\n", File.read(KERYX_CALLS)
  end
end
