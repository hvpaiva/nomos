# frozen_string_literal: true

require 'stringio'
require 'tmpdir'
require_relative 'nomos_support'

class NomosComposeTest < Minitest::Test
  include NomosSupport

  NOW = '2026-10-26T10:00:00Z'
  CHOICE = ['--title', 'Where process decisions live', '--kind', 'choice', '--option', 'keep=Keep as it is',
            '--option', 'move=Move to the Project', '--blocks-none', '--meanwhile', 'I continue with the file',
            '--if-silent', 'I keep it as it is', '--default', 'keep'].freeze

  def compose(*argv, text: "Nothing waits on this; I continue with the file.\n")
    stdout = StringIO.new
    stderr = StringIO.new
    status = Nomos::CLI.main(['compose', *argv, '--now', NOW], stdin: StringIO.new(text), stdout: stdout, stderr: stderr)
    [status, stdout.string, stderr.string]
  end

  def check(body, **options)
    stderr = StringIO.new
    status = Nomos::CLI.main(['check'], stdin: StringIO.new(JSON.generate(envelope(body, **options))), stderr: stderr)
    [status, stderr.string]
  end

  def test_an_ask_to_a_person
    status, body, advice = compose('ask', '--to', 'ana.local@box', '--within', '1h', *CHOICE)
    assert_equal 0, status, advice
    assert_equal <<~BODY, body
      Where process decisions live
      ```nomos
      {"kind": "choice",
       "options": [{"id":"keep","label":"Keep as it is"},{"id":"move","label":"Move to the Project"}],
       "default": "keep",
       "blocks": null,
       "meanwhile": "I continue with the file",
       "if_silent": "I keep it as it is"}
      ```

      Nothing waits on this; I continue with the file.

      1. Keep as it is (`keep`)
      2. Move to the Project (`move`)

      Answer by 2026-10-26 11:00 +00:00.

      nomos v0 human message
    BODY
    assert_equal [0, ''], check(body)
  end

  def test_the_text_keeps_its_own_options_and_deadline
    text = "Pick one.\n\n1. Keep as it is (`keep`).\n2. Move to the Project (`move`).\n\nAnswer by 11:00 UTC.\n"
    status, body, = compose('ask', '--to', 'ana.local@box', '--within', '1h', *CHOICE, text: text)
    assert_equal 0, status
    assert_equal 1, body.scan('(`keep`)').size
    assert_equal 1, body.scan('11:00').size
  end

  def test_the_words_file_writes_the_deadline
    Dir.mktmpdir('nomos-compose-') do |dir|
      path = File.join(dir, 'words')
      File.write(path, WORDS)
      status, body, = compose('ask', '--to', 'ana.local@box', '--within', '3h', '--words', path, *CHOICE)
      assert_equal 0, status
      assert_includes body, "Answer zuntil 26/10 klo 10h00 (-03:00).\n"
    end
  end

  def test_a_notice_reply_and_a_block_file
    status, body, = compose('reply', '--to', 'ana.local@box', '--title', 'The usage page answers again', '--kind', 'notice',
                            text: "The page answers again.\n")
    assert_equal 0, status
    assert_equal NOTICE.sub("```\nThe", "```\n\nThe"), body
    Dir.mktmpdir('nomos-compose-') do |dir|
      path = File.join(dir, 'block.json')
      File.write(path, '{"kind": "notice", "links": [{"url": "https://example.com/?a=b", "label": "Page"}]}')
      status, body, = compose('send', '--to', 'ana.local@box', '--title', 'Moved', '--block', path, text: "Moved.\n")
      assert_equal 0, status
      assert_includes body, '"links": [{"url":"https://example.com/?a=b","label":"Page"}]'
    end
  end

  def test_pairs_split_where_the_argument_says
    status, body, = compose('send', '--to', 'ana.local@box', '--title', 'Moved', '--kind', 'notice',
                            '--link', 'https://example.com/?a=b=Page', '--attach', '/srv/notes/a.md=Notes', text: "Moved.\n")
    assert_equal 0, status
    assert_includes body, '{"url":"https://example.com/?a=b","label":"Page"}'
    assert_includes body, '{"path":"/srv/notes/a.md","label":"Notes"}'
    status, body, = compose('ask', '--to', 'ana.local@box', '--within', '1h', *CHOICE, '--option', 'x=a=b',
                            '--answer-text', 'required')
    assert_equal 0, status
    assert_includes body, '{"id":"x","label":"a=b"}'
    assert_includes body, '"text": "required"'
  end

  def test_an_agent_recipient_gets_the_text
    assert_equal [0, "Review done.\n", ''], compose('send', '--to', 'rev-1.alpha@box', text: "Review done.\n\n\n")
    status, body, error = compose('reply', '--to', 'rev-1.alpha@box', text: "[progress] half done\n")
    assert_equal [0, "[progress] half done\n"], [status, body]
    assert_match(/\Aadvice 5\.3 /, error)
  end

  def test_refusals_print_no_body
    status, body, error = compose('send', '--to', 'ana.local@box', '--title', 'T' * 81, '--kind', 'notice', text: "x\n")
    assert_equal [1, ''], [status, body]
    assert_match(/\A10\.7 title over 80 characters/, error)
    status, body, error = compose('send', '--to', 'ana.local@box', *CHOICE, text: "x\n")
    assert_equal [1, ''], [status, body]
    assert_match(/10\.5 a choice goes as keryx ask/, error)
  end

  def test_advice_goes_to_stderr_with_the_body
    status, body, error = compose('send', '--to', 'rev-1.alpha@box', text: "Back tomorrow.\n")
    assert_equal [0, "Back tomorrow.\n"], [status, body]
    assert_equal "advice 5.7 tomorrow (line 1)\n", error
  end

  def test_usage_errors_exit_two
    [['ask', '--to', 'ana.local@box', *CHOICE], ['send', '--to', 'ana.local@box', '--within', '1h', *CHOICE],
     ['ask', '--to', 'ana.local@box', '--within', 'soon', *CHOICE], ['send', '--to', 'rev-1.alpha@box', '--title', 'T'],
     ['send', '--to', 'ana.local@box', '--kind', 'notice'], ['send', '--to', 'ana.local@box', '--title', 'T'],
     ['send', '--to', 'ana.local@box', '--title', 'T', '--kind', 'answer'], ['send', '--to', 'orq', 'x'],
     ['shout', '--to', 'ana.local@box'], ['send'], ['send', '--to', 'ana.local@box', '--title', 'T', '--option', 'novalue'],
     ['send', '--to', 'ana.local@box', '--title', 'T', '--block', '/nonexistent/block.json']].each do |argv|
      status, body, error = compose(*argv)
      assert_equal [2, ''], [status, body], argv.inspect
      assert_match(/\Anomos compose: /, error, argv.inspect)
    end
  end

  def test_a_refusal_prints_no_advice
    status, body, error = compose('send', '--to', 'ana.local@box', '--title', 'Bad', '--kind', 'decision', '--option', 'a=A',
                                  '--option', 'b=B', '--blocks-none', '--meanwhile', 'w', '--if-silent', 'w')
    assert_equal [1, ''], [status, body]
    refute_match(/^advice /, error)
    assert_match(/^10\.5 /, error)
  end

  def test_the_terminal_flag_writes_the_field_and_leaves_the_text_to_the_sender
    action = ['--title', 'Approve the push', '--kind', 'action', '--blocks', 'The push', '--meanwhile', 'I wait',
              '--if-silent', 'I do not push', '--terminal', 'approve the push']
    status, body, advice = compose('ask', '--to', 'ana.local@box', '--within', '1h', *action,
                                   text: "Type this in my terminal and press Enter.\n\n`approve the push`\n")
    assert_equal 0, status, advice
    assert_includes body, %("if_silent": "I do not push",\n "terminal": {"text":"approve the push"}}\n```\n)
    assert_equal [0, ''], check(body)
    ["Type this in my terminal and press Enter.\n", "Type approve the push and press Enter.\n"].each do |text|
      status, body, error = compose('ask', '--to', 'ana.local@box', '--within', '1h', *action, text: text)
      assert_equal [1, ''], [status, body]
      assert_includes error, "10.7 terminal text is not the whole content of a code span after the block (line 7)\n"
    end
    status, = compose('send', '--to', 'ana.local@box', '--title', 'T', '--kind', 'notice', '--terminal', 'x', text: "x\n")
    assert_equal 1, status
    Dir.mktmpdir('nomos-compose-') do |dir|
      path = File.join(dir, 'block.json')
      File.write(path, '{"kind": "notice"}')
      status, body, error = compose('send', '--to', 'ana.local@box', '--title', 'T', '--block', path, '--terminal', 'x')
      assert_equal [2, '', "nomos compose: --block FILE and block flags are given together\n"], [status, body, error]
    end
  end

  def test_the_terminal_key_comes_before_files_and_links
    status, body, advice = compose('ask', '--to', 'ana.local@box', '--within', '1h', '--title', 'Approve the push',
                                   '--kind', 'action', '--blocks', 'The push', '--meanwhile', 'I wait', '--if-silent',
                                   'I do not push', '--link', 'https://example.com/push=Push', '--attach',
                                   '/srv/notes/a.md=Notes', '--terminal', 'approve the push',
                                   text: "Type `approve the push` and press Enter.\n")
    assert_equal 0, status, advice
    keys = body.lines[2..].take_while { |line| !line.start_with?('```') }.map { |line| line[/"(\w+)":/, 1] }
    assert_equal %w[kind blocks meanwhile if_silent terminal files links], keys
  end

  def test_an_empty_text_is_a_usage_error
    ["", "\n \n"].each do |text|
      status, body, error = compose('send', '--to', 'rev-1.alpha@box', text: text)
      assert_equal [2, '', "nomos compose: the text is empty\n"], [status, body, error], text.inspect
    end
  end

  def test_a_zoneless_deadline_in_the_text_gets_the_sentence
    Dir.mktmpdir('nomos-compose-') do |dir|
      path = File.join(dir, 'words')
      File.write(path, WORDS)
      status, body, = compose('ask', '--to', 'ana.local@box', '--within', '3h', '--words', path, *CHOICE,
                              text: "Nothing waits on this; answer by 26/10 klo 10h00.\n")
      assert_equal 0, status
      assert_includes body, "Answer zuntil 26/10 klo 10h00 (-03:00).\n"
      assert_equal [0, ''], check(body, due: Time.iso8601(NOW) + 10_800)
    end
  end
end
