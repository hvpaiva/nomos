# frozen_string_literal: true

require 'open3'
require 'rbconfig'
require 'tmpdir'
require_relative 'nomos_support'

# nomos check as keryx runs it: a cleared environment, the working directory /, the envelope on stdin.
class NomosCliTest < Minitest::Test
  include NomosSupport

  CLEARED = { 'PATH' => '/usr/bin:/bin', 'LANG' => 'C.UTF-8', 'KERYX_CHECK' => '1' }.freeze

  def run_check(input, env: CLEARED, args: [])
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    stdout, stderr, status = Open3.capture3(env, RbConfig.ruby, '--disable-gems', ENTRY, 'check', *args,
                                            stdin_data: input, chdir: '/', unsetenv_others: true)
    [status.exitstatus, stderr.force_encoding('UTF-8'), stdout, Process.clock_gettime(Process::CLOCK_MONOTONIC) - started]
  end

  def input(body, **options) = "#{JSON.generate(envelope(body, **options))}\n"

  def test_accepts_refuses_and_fails_closed
    status, stderr, stdout, elapsed = run_check(input(ASK))
    assert_equal [0, '', ''], [status, stderr, stdout]
    assert_operator elapsed, :<, 1
    status, stderr, = run_check(input("[notice] #{'T' * 90}\nText.\n", kind: 'message', due: nil))
    assert_equal 1, status
    assert_equal ['10.5', '10.5', '10.7', '10.7'], stderr.lines.map { |line| line[/\A\S+/] }.sort
    ['', 'not json', '[]', '{"check": 2}', JSON.generate(envelope(ASK).merge('event' => 'relay')),
     JSON.generate(envelope(ASK).tap { |data| data['message']['kind'] = 'note' }),
     JSON.generate(envelope(ASK).tap { |data| data['message']['due_at'] = 'soon' }),
     "{\"check\": 1, \"body\": \"\xFF\"}"].each do |text|
      status, stderr, = run_check(text)
      assert_equal 2, status, text
      assert_match(/\Anomos check: /, stderr, text)
    end
  end

  def test_reasons_fit_in_four_kibibytes
    labels = (1..6).map { |n| "{\"id\": \"o#{n}\", \"label\": \"#{'L' * 50}#{n}\"}" }.join(', ')
    body = "[x] #{'T' * 90}\n```nomos\n{\"kind\": \"choice\", \"options\": [#{labels}], \"html\": \"<b>#{'a' * 80}\", " \
           "\"meanwhile\": \"#{'m' * 81}\", \"if_silent\": \"at 10:00 UTC\", \"blocks\": \"<i>\", \"due\": 1}\n```\nNo text.\n"
    status, stderr, = run_check(input(body, kind: 'reply', due: nil))
    assert_equal 1, status
    assert_operator stderr.bytesize, :<=, 4096
    assert stderr.valid_encoding?
  end

  def test_reads_no_environment
    refused = input("Hello\nText.\n", kind: 'message', due: nil)
    expected = run_check(refused).first(3)
    [{ 'HOME' => '/nonexistent', 'NOMOS_PRESEND_CONFIRMED' => '1', 'KERYX_AS' => 'ana.local' }, { 'LANG' => 'C', 'LC_ALL' => 'C' },
     { 'TZ' => 'Pacific/Kiritimati', 'RUBYOPT' => '' }].each do |extra|
      assert_equal expected, run_check(refused, env: CLEARED.merge(extra)).first(3), extra.inspect
    end
  end

  def test_words_option_and_receive_event
    Dir.mktmpdir('nomos-cli-') do |dir|
      path = File.join(dir, 'words')
      File.write(path, WORDS)
      local = ASK.sub('2026-10-26 08:00 -03:00', '26/10 klo 08h00')
      assert_equal 1, run_check(input(local)).first
      assert_equal 0, run_check(input(local), args: ['--words', path]).first
      assert_equal 0, run_check(input(local, event: 'receive'), args: ['--words', path]).first
      File.write(path, "[zone]\nnope\n")
      assert_equal 2, run_check(input(ASK), args: ['--words', path]).first
    end
  end

  def test_help_version_and_unknown_command
    stdout, _, status = Open3.capture3(RbConfig.ruby, ENTRY, 'help')
    assert_equal 0, status.exitstatus
    assert_match(/nomos check reads one keryx check envelope/, stdout)
    assert_equal ["nomos v0\n", 0], Open3.capture3(RbConfig.ruby, ENTRY, 'version').values_at(0, 2).then { |out, st| [out, st.exitstatus] }
    assert_equal 2, Open3.capture3(RbConfig.ruby, ENTRY, 'send')[2].exitstatus
    assert_equal 2, Open3.capture3(RbConfig.ruby, ENTRY, 'check', 'extra', stdin_data: input(ASK))[2].exitstatus
  end
end
