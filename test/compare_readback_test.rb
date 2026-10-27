require 'minitest/autorun'
require 'open3'
require 'stringio'
require 'tmpdir'
require 'timeout'
require_relative '../bin/compare-readback'

class CompareReadbackTest < Minitest::Test
  Comparator = Nomos::CompareReadback
  SCRIPT = File.expand_path('../bin/compare-readback.rb', __dir__)
  WORDS_FILE = File.expand_path('fixtures/compare-readback/vocabulary.txt', __dir__)
  VOCABULARY = Comparator::Vocabulary.load([WORDS_FILE])
  RECORD = <<~TEXT
    You are impl-1.alpha@box1, the implementer of team alpha, started by orq.alpha@box1.
    Before you act on your first request, send orq.alpha@box1 a readback with your address, role,
    task, authority and next action, and wait for its confirmation.
    The principal is Ana, who talks to this team only through orq.alpha@box1.
    The delegator is orq.alpha@box1, acting within the delegation it holds from the principal.
    As the implementer you may read and edit files under /work/alpha, run checks, and message orq.alpha@box1.
    You may not merge, publish, install or configure settings.
    Reserved to the principal are push, deploy and anything off this machine.
    You may not redelegate.
    This record holds for the life of this session.
    orq.alpha@box1 or the principal may change or revoke this record, by a message that names the part it
    changes and carries an absolute time.
    Task: Build the readback comparator.
    nomos v0 first prompt
  TEXT
  READBACK = <<~TEXT
    Address: impl-1.alpha@box1
    Role: implementer
    Task: Build the readback comparator.
    Authority: I may edit and read /work/alpha, message orq.alpha@box1 and run checks.
    I may not configure settings, install, publish or merge.
    Reserved to the principal are anything off this machine, deploy and push.
    I may not redelegate.
    Next action: Wait for confirmation.
  TEXT

  def compare(record = RECORD, readback = READBACK, brief: nil, vocabulary: Comparator::Vocabulary::ENGLISH)
    Comparator.compare(record: record, readback: readback, brief: brief, vocabulary: vocabulary)
  end

  def placeholder(record = RECORD, readback = READBACK, brief: nil) = compare(record, readback, brief: brief, vocabulary: VOCABULARY)

  def field(result, name) = result.fetch('fields').fetch(name)
  def status(result, name) = field(result, name).fetch('status')

  def assert_match_all(result)
    assert_equal %w[address role task authority next_action], result.fetch('fields').keys
    assert_equal ['matched'] * 5, result.fetch('fields').values.map { |entry| entry.fetch('status') }, result.inspect
    assert_empty result.fetch('authority_added')
    assert_empty result.fetch('authority_missing')
  end

  def test_member_record_and_summarized_readback_match
    result = compare
    assert_match_all result
    assert_equal 'v0', result.fetch('version')
    assert_includes field(result, 'authority').fetch('record').join, '/work/alpha'
    result.fetch('fields').each_value do |entry|
      entry.fetch('record').each { |span| assert_includes RECORD, span }
      entry.fetch('readback').each { |span| assert_includes READBACK, span }
    end
  end

  def test_template_example_authority
    record = File.read(File.expand_path('../templates/first-prompt.md', __dir__), encoding: 'UTF-8').split('You are impl-1.alpha@box1').last
    record = "You are impl-1.alpha@box1#{record}\nTask: Build the readback comparator.\n"
    readback = record.sub(/You are ([^,]+), the (\w+) of team alpha, started by orq.alpha@box1\./, "Address: \\1\nRole: \\2")
    readback += "\nNext action: Wait for confirmation.\n"
    assert_match_all compare(record, readback)
  end

  def test_numbered_record_fields
    record = <<~TEXT
      1. Principal: Ana.
      2. Delegator: orq.alpha@box1.
      3. Delegate: impl-1.alpha@box1, role implementer.
      4. Actions and resources granted: read and edit /work/alpha,
         run checks and message orq.alpha@box1.
      5. Decisions reserved to the principal: push, deploy and anything off this machine.
      6. Redelegation: may not redelegate.
      7. Duration: for the life of this session.
      8. Change authority: Ana or orq.alpha@box1.
      You may not merge, publish, install or configure settings.
      Task: Build the readback comparator.
      Next action: Wait for confirmation.
    TEXT
    assert_match_all compare(record)
    assert_nil compare(record).fetch('version')
  end

  def test_root_role_and_first_person_identity
    record = RECORD.sub('impl-1.alpha@box1, the implementer', 'orq.alpha@box1, the orchestrator')
    readback = READBACK.sub("Address: impl-1.alpha@box1\nRole: implementer", 'I am orq.alpha@box1, the orchestrator of team alpha.')
    assert_match_all compare(record, readback)
  end

  def test_opening_identity_with_tag_and_vocabulary_sentence_forms
    ['[readback] impl-1.alpha@box1, implementer, awaq konfirq.',
     'Soq impl-1.alpha@box1, implementer of team alpha.',
     'Miq esq impl-1.alpha@box1, impqo of team alpha.',
     "[accept] Readback of impl-1.alpha@box1.\nSoq impl-1.alpha@box1, implementer of team alpha."].each do |opening|
      readback = READBACK.sub("Address: impl-1.alpha@box1\nRole: implementer", opening)
      assert_match_all placeholder(RECORD, readback)
      result = placeholder(RECORD, readback.sub('impl-1.alpha@box1', 'impl-2.alpha@box1'))
      assert_equal 'differs', status(result, 'address')
    end
  end

  def test_opening_role_comes_from_the_fixed_list_next_to_the_address
    roles = %w[orchestrator implementer reviewer writer qa auditor]
    roles.zip(roles, %w[orqo impqo revqo wriqo qa auditor]).each do |english, opening, translated|
      record = RECORD.sub('the implementer of team', "the #{english} of team")
      readback = READBACK.sub("Address: impl-1.alpha@box1\nRole: implementer", "[readback] impl-1.alpha@box1, #{opening} of team alpha.")
      assert_match_all compare(record, readback)
      assert_match_all placeholder(record, readback.sub(", #{opening} of", ", #{translated} of"))
    end
    readback = READBACK.sub("Address: impl-1.alpha@box1\nRole: implementer", 'impl-1.alpha@box1, ready to consult the reviewer.')
    assert_equal 'missing', status(compare(RECORD, readback), 'role')
  end

  def test_markdown_labels_crlf_and_wrapped_values
    readback = READBACK.gsub(/^([A-Z][a-z ]+): /, '**\\1:** ').gsub("edit and read", "edit\r\nand read").gsub("\n", "\r\n")
    assert_match_all compare(RECORD.gsub("\n", "\r\n"), readback)
    headings = READBACK.gsub(/^([A-Z][a-z ]+): /, "## \\1\n")
    assert_match_all compare(RECORD, headings)
  end

  VOCABULARY_READBACK = <<~TEXT
    Zadrez: impl-1.alpha@box1
    Rolka: implementer
    Qatko: Build the readback comparator.
    Xauto: Zmay lexo ek edqo /work/alpha, runqo checks ek sendqo mesqo to orq.alpha@box1.
    Naq zmay merqo, pubqo, insqo or konqo konqoj.
    Rezq zu principal esq pusqo, depqo ek qany thing foz diz masq.
    Naq zmay redqo.
    Neqo axo: Wait for confirmation.
  TEXT

  def test_vocabulary_labels_and_clauses
    assert_match_all placeholder(RECORD, VOCABULARY_READBACK)
    assert_equal ['missing'] * 5, compare(RECORD, VOCABULARY_READBACK).fetch('fields').values.map { |entry| entry.fetch('status') }
  end

  def test_each_vocabulary_translation
    pairs = {
      'read' => 'lexo', 'edit' => 'edqo', 'create' => 'krexo', 'remove' => 'remqo',
      'write' => 'wrixo', 'run' => 'runqo', 'message' => 'sendqo mesqo',
      'commit' => 'komqo', 'push' => 'pusqo', 'publish' => 'pubqo', 'merge' => 'merqo',
      'delete' => 'delqo', 'deploy' => 'depqo', 'install' => 'insqo',
      'configure' => 'konqo', 'settings' => 'konqoj',
      'off this machine' => 'foz diz masq', 'redelegate' => 'redqo',
      'open' => 'opqo', 'update' => 'upqo', 'tag' => 'tagqo',
      'change' => 'alqo', 'grant' => 'donqo'
    }
    pairs.each do |english, translated|
      result = placeholder("#{RECORD}\nYou may #{english}.", "#{READBACK}\nZmay #{translated}.")
      assert_equal 'matched', status(result, 'authority'), "#{english}: #{result}"
    end
  end

  def test_foreign_unlabeled_prose_is_missing
    result = compare(RECORD, 'Je suis le responsable et attends la confirmation.')
    assert_equal ['missing'] * 5, result.fetch('fields').values.map { |entry| entry.fetch('status') }
  end

  def test_labels_accept_short_connectors_and_sentence_starts
    ['Task is', 'My task is', 'Task as assigned:'].each do |label|
      readback = READBACK.sub('Task:', label)
      assert_equal 'matched', status(compare(RECORD, readback), 'task'), label
    end
    ['Mu qatko esq', 'Qatko zu zorq esq', 'Qatko zu zorq.'].each do |label|
      readback = READBACK.sub('Task:', label)
      assert_equal 'matched', status(placeholder(RECORD, readback), 'task'), label
    end
    readback = READBACK.sub('Task:', "\nReady. My task is")
    assert_equal 'matched', status(compare(RECORD, readback), 'task')
    ['Authority as my first prompt gives it.', 'My authority is'].each do |label|
      assert_match_all compare(RECORD, READBACK.sub('Authority:', label))
    end
    assert_match_all placeholder(RECORD, READBACK.sub('Authority:', 'Mu xauto esq'))
  end

  def test_label_connectors_are_bounded_and_do_not_match_inside_a_word
    readback = READBACK.sub('Task:', 'Task one two three four five six seven eight:')
    assert_equal 'matched', status(compare(RECORD, readback), 'task')
    readback = READBACK.sub('Task:', 'Task one two three four five six seven eight nine:')
    assert_equal 'missing', status(compare(RECORD, readback), 'task')
    readback = READBACK.sub('Task:', 'Taskmaster:')
    assert_equal 'missing', status(compare(RECORD, readback), 'task')
  end

  def test_next_action_connectors_keep_the_source_span
    line = 'Neqo axo posq konfirq esq lexo the files.'
    result = placeholder(RECORD, READBACK.sub('Next action: Wait for confirmation.', line))
    assert_includes field(result, 'next_action').fetch('readback'), line
  end

  def test_modal_grants_inside_task_need_review
    ['My task is', 'Mu qatko esq'].each do |label|
      readback = READBACK.sub("Task: Build the readback comparator.\nAuthority: ", "#{label} Build the readback comparator. ")
      result = placeholder(RECORD, readback)
      assert_equal 'differs', status(result, 'authority')
      refute_empty result.fetch('authority_added')
    end
  end

  def test_missing_on_either_side_never_matches
    assert_equal ['missing'] * 5, compare('', '').fetch('fields').values.map { |entry| entry.fetch('status') }
    %w[address role task authority next_action].each do |name|
      assert_equal 'missing', status(compare('', READBACK), name)
      assert_equal 'missing', status(compare(RECORD, ''), name)
    end
  end

  def test_wrong_identity_and_conflicting_duplicates
    assert_equal 'differs', status(compare(RECORD, READBACK.sub('impl-1.alpha@box1', 'impl-2.alpha@box1')), 'address')
    assert_equal 'differs', status(compare(RECORD, "#{READBACK}\nRole: reviewer"), 'role')
    assert_equal 'differs', status(compare(RECORD, "#{READBACK}\nAddress: impl-2.alpha@box1"), 'address')
    assert_equal 'differs', status(compare(RECORD, READBACK.sub('box1', 'box2')), 'address')
    assert_equal 'differs', status(compare(RECORD, READBACK.sub('impl-1', 'IMPL-1')), 'address')
  end

  def test_delegator_address_is_not_the_delegate
    result = compare("The delegator is orq.alpha@box1.\n#{RECORD}")
    assert_equal 'matched', status(result, 'address')
    result = compare(RECORD.sub(/You are .*?\n/, ''))
    assert_equal 'missing', status(result, 'address')
  end

  def test_brief_supplies_task_only
    record = RECORD.sub(/^Task:.*\n/, '')
    assert_equal 'missing', status(compare(record), 'task')
    assert_match_all compare(record, brief: "# Brief, nomos v0\n\nBuild the readback comparator.\n\nYou may publish.\n")
    assert_match_all compare(record, brief: "# Brief\n\nTask: Build the readback comparator.\n")
    assert_equal 'differs', status(compare(RECORD, brief: 'Build something else.'), 'task')
    assert_empty compare(record, brief: 'You may publish.').fetch('authority_added')
  end

  def test_task_and_next_action_are_not_word_overlap
    assert_equal 'differs', status(compare(RECORD, READBACK.sub('Build the readback', 'Do not build the readback')), 'task')
    assert_equal 'matched', status(compare(RECORD, READBACK.sub('Wait for confirmation.', 'Wait for confirmation, then read the files.')), 'next_action')
    assert_equal 'differs', status(compare(RECORD, READBACK.sub('Wait for confirmation.', 'Start coding.')), 'next_action')
  end

  def test_task_starts_with_the_brief_line_and_keeps_added_detail
    brief = "Build the readback comparator.\nDetails follow.\n"
    readback = READBACK.sub('Task: Build the readback comparator.', 'Task: Build the readback comparator. Add tests and report the result.')
    assert_equal 'matched', status(compare(RECORD, readback, brief: brief), 'task')
    assert_equal 'differs', status(compare(RECORD, readback), 'task')
    readback = READBACK.sub('Task: Build the readback comparator.', 'Task: My assignment is to Build the readback comparator and report the result.')
    assert_equal 'differs', status(compare(RECORD, readback, brief: brief), 'task')
    assert_equal 'differs', status(compare(RECORD, readback, brief: 'Build a different comparator.'), 'task')
  end

  def test_waiting_phrases_allow_the_next_step
    ['Wait for your [accept], checking the inbox.', 'After confirmation, read the files.'].each do |phrase|
      assert_equal 'matched', status(compare(RECORD, READBACK.sub('Wait for confirmation.', phrase)), 'next_action'), phrase
    end
    ['Awaq konfirq to lexo the files.', 'Awaq zu konfirq ek lexo the files.', 'Awaqi konfirq ek lexo the files.',
     'Posq konfirq, lexo the files.', 'Posq zu konfirq, lexo the files.', 'Dopq konfirq, lexo the files.'].each do |phrase|
      assert_equal 'matched', status(placeholder(RECORD, READBACK.sub('Wait for confirmation.', phrase)), 'next_action'), phrase
    end
    ['Neqo axo posq konfirq esq lexo the files.', 'Mu neqo axo, posq zu konfirq, esq lexo the files.'].each do |line|
      assert_equal 'matched', status(placeholder(RECORD, READBACK.sub('Next action: Wait for confirmation.', line)), 'next_action'), line
    end
    result = compare(RECORD, READBACK.sub('Next action: Wait for confirmation.', 'I will not wait for confirmation.'))
    refute_equal 'matched', status(result, 'next_action')
  end

  def test_added_grant_and_changed_resource
    result = compare(RECORD, "#{READBACK}\nI may publish.")
    assert_equal 'differs', status(result, 'authority')
    assert_includes result.fetch('authority_added'), 'publish'
    result = compare(RECORD, READBACK.sub('/work/alpha', '/work'))
    assert_includes result.fetch('authority_added'), '/work'
    assert_includes result.fetch('authority_missing'), '/work/alpha'
    result = compare(RECORD, READBACK.sub('message orq.alpha@box1', 'message reviewer.alpha@box1'))
    assert_includes result.fetch('authority_added'), 'reviewer.alpha@box1'
    assert_includes result.fetch('authority_missing'), 'orq.alpha@box1'
  end

  def test_missing_prohibition_reservation_and_redelegation
    ['publish or ', 'deploy and ', "I may not redelegate.\n"].each do |omission|
      result = compare(RECORD, READBACK.sub(omission, ''))
      assert_equal 'differs', status(result, 'authority'), omission
      refute_empty result.fetch('authority_missing')
    end
  end

  def test_inverted_negation_and_redelegation
    result = compare(RECORD, READBACK.sub('I may not configure', 'I may configure'))
    assert_includes result.fetch('authority_added'), 'publish'
    assert_includes result.fetch('authority_missing'), 'not publish'
    result = compare(RECORD, READBACK.sub('I may not redelegate', 'I may redelegate'))
    assert_includes result.fetch('authority_added'), 'redelegate'
    assert_includes result.fetch('authority_missing'), 'not redelegate'
  end

  def test_limited_redelegation_keeps_resource_atoms
    record = RECORD.sub('You may not redelegate.', 'You may grant members read access to /work/alpha.')
    readback = READBACK.sub('I may not redelegate.', 'I may grant members read access to /work/alpha.')
    assert_match_all compare(record, readback)
    result = compare(record, readback.sub('grant members read access to /work/alpha', 'grant members write access to /work'))
    assert_equal 'differs', status(result, 'authority')
    assert_includes result.fetch('authority_added'), '/work'
    assert_empty result.fetch('authority_missing')
  end

  def test_redelegation_does_not_change_other_atoms_categories
    ['I may not redelegate, install or configure settings.', 'Naq zmay redqo, insqo or konqo konqoj.'].each do |clause|
      readback = READBACK.sub("I may not configure settings, install, publish or merge.\n", "I may not publish or merge.\n")
      readback = readback.sub('I may not redelegate.', clause)
      assert_match_all placeholder(RECORD, readback)
    end
    record = RECORD.sub('You may not redelegate.', 'You may redelegate.')
    readback = READBACK.sub('I may not redelegate.', 'I may redelegate, read /work/alpha and run checks.')
    assert_match_all compare(record, readback)
  end

  def test_reservations_and_prohibitions_satisfy_each_other
    readback = READBACK.sub('Reserved to the principal are anything off this machine, deploy and push.', 'I may not push or deploy anything off this machine.')
    assert_match_all compare(RECORD, readback)
    readback = READBACK.sub('I may not configure settings, install, publish or merge.', 'Reserved to the principal are configure settings, install, publish and merge.')
    assert_match_all compare(RECORD, readback)
    result = compare(RECORD, readback.sub('deploy and push', 'deploy'))
    assert_includes result.fetch('authority_missing'), 'reserved push'
  end

  def test_publication_installs_and_off_machine_forms
    record = RECORD.sub('merge, publish, install or configure settings', 'merge, publication, installs or configure settings')
    ['foz masq', 'por foz masq', 'foz diz masq'].each do |phrase|
      readback = READBACK.sub('anything off this machine', phrase)
      assert_match_all placeholder(record, readback)
    end
    assert_match_all compare(record, READBACK.sub('anything off this machine', 'anything that leaves this machine'))
  end

  def test_template_example_act_words_are_in_the_vocabulary
    template = File.read(File.expand_path('../templates/first-prompt.md', __dir__), encoding: 'UTF-8')
    example = template.split('You are impl-1.alpha@box1').last
    clauses = example.scan(/(?:As the implementer you may|You may not) (.*?)\.(?=\s|\z)/m).flatten
    acts = clauses.flat_map do |clause|
      clause.gsub(/\s+/, ' ').split(/,|\band\b|\bor\b/).filter_map do |part|
        first = part.strip.split.first
        first unless %w[for personal].include?(first)
      end
    end
    assert_includes acts, 'open'
    assert_includes acts, 'update'
    assert_includes acts, 'tag'
    assert_includes acts, 'change'
    acts.each { |act| assert Comparator::WORDS.key?(act), "Missing template act #{act}" }
    %w[publication installs publishing tags grant].each do |act|
      assert Comparator::WORDS.key?(act), "Missing record act #{act}"
    end
  end

  def test_unknown_authority_matches_only_a_whole_record_sentence
    assert_equal 'matched', status(compare("#{RECORD}\nAuthority: Handle matters as appropriate.", "#{READBACK}\nAuthority: Handle matters as appropriate."), 'authority')
    assert_equal 'differs', status(compare(RECORD, "#{READBACK}\nAuthority: Unlimited access."), 'authority')
  end

  def test_negation_inside_affirmative_clause_is_not_a_grant
    result = compare(RECORD, "#{READBACK}\nI may read but not publish.")
    refute_includes result.fetch('authority_added'), 'publish'
    result = compare(RECORD, "#{READBACK}\nI may not publish, but may deploy.")
    assert_includes result.fetch('authority_added'), 'deploy'
  end

  def test_omitted_grant_acts_are_reported_as_missing_authority
    readback = READBACK.sub('edit and read /work/alpha, message orq.alpha@box1 and run checks', 'read /work/alpha and message orq.alpha@box1')
    result = assert_cli_result(RECORD, readback, 1)
    assert_equal 'differs', status(result, 'authority')
    assert_equal %w[edit run], result.fetch('authority_missing')
  end

  def test_paths_keep_case_and_vocabulary_in_paths_is_not_an_act
    result = compare(RECORD, READBACK.sub('/work/alpha', '/work/Alpha'))
    assert_includes result.fetch('authority_added'), '/work/Alpha'
    assert_includes result.fetch('authority_missing'), '/work/alpha'
    result = compare(RECORD, READBACK.sub('/work/alpha', '/work/publish'))
    assert_includes result.fetch('authority_added'), '/work/publish'
    refute_includes result.fetch('authority_added'), 'publish'
  end

  def test_relative_paths_and_file_names_are_resources
    %w[src/alpha ./alpha ../alpha ~/alpha README.md /].each do |path|
      record = RECORD.sub('/work/alpha', path)
      readback = READBACK.sub('/work/alpha', path)
      assert_match_all compare(record, readback)
      result = compare(record, readback.sub(path, '/other'))
      assert_includes result.fetch('authority_missing'), path == './alpha' ? 'alpha' : path
      assert_includes result.fetch('authority_added'), '/other'
    end
  end

  def test_quoted_paths_keep_spaces_and_punctuation
    ['`/work/alpha one`', '"/work/alpha two"', "'/work/alpha.'", '`/work/alpha  three`'].each do |quoted|
      record = RECORD.sub('/work/alpha', quoted)
      readback = READBACK.sub('/work/alpha', quoted)
      assert_match_all compare(record, readback)
      result = compare(record, READBACK)
      assert_includes result.fetch('authority_missing'), quoted[1...-1]
    end
    record = RECORD.sub('/work/alpha', '`/work/alpha  one`')
    result = compare(record, READBACK.sub('/work/alpha', '`/work/alpha one`'))
    assert_equal 'differs', status(result, 'authority')
  end

  def test_lowercase_sentences_keep_their_negation
    readback = READBACK.sub("I may not configure settings, install, publish or merge.\n", 'i may not configure settings, install, publish or merge. ')
    assert_match_all compare(RECORD, readback)
    result = compare(RECORD, readback.sub('i may not configure', 'i may configure'))
    assert_includes result.fetch('authority_added'), 'publish'
  end

  def test_unrelated_extra_restriction_does_not_flag_and_spans_keep_original_wording
    result = compare(RECORD, "#{READBACK}\nI may not delete.")
    assert_equal 'matched', status(result, 'authority')
    assert_empty result.fetch('authority_added')
    assert_includes field(result, 'authority').fetch('readback'), 'I may not delete.'
  end

  def test_extra_restriction_that_denies_a_granted_act_is_missing_authority
    ['I may not edit.', 'Reserved to the principal are edit.'].each do |clause|
      result = compare(RECORD, "#{READBACK}\n#{clause}")
      assert_equal 'differs', status(result, 'authority')
      assert_includes result.fetch('authority_missing'), 'edit'
      assert_empty result.fetch('authority_added')
    end
  end

  def test_extra_restriction_that_denies_a_granted_resource_is_missing_authority
    ['I may not access /work/alpha.', 'Reserved to the principal are /work/alpha.'].each do |clause|
      result = compare(RECORD, "#{READBACK}\n#{clause}")
      assert_equal 'differs', status(result, 'authority')
      assert_includes result.fetch('authority_missing'), '/work/alpha'
      assert_empty result.fetch('authority_added')
    end
  end

  def test_quoted_or_fenced_examples_do_not_supply_fields
    text = "> Address: impl-1.alpha@box1\n```\n#{READBACK}\n```\n"
    assert_equal ['missing'] * 5, compare(RECORD, text).fetch('fields').values.map { |entry| entry.fetch('status') }
    text = "````text\n```\n~~~\n#{READBACK}\n~~~\n````\n"
    assert_equal ['missing'] * 5, compare(RECORD, text).fetch('fields').values.map { |entry| entry.fetch('status') }
  end

  def assert_cli_result(record, readback, expected_exit, brief: nil, words: false)
    with_files(record, readback) do |directory, args|
      if brief
        path = File.join(directory, 'brief.txt')
        File.binwrite(path, brief)
        args += ['--brief', path]
      end
      args += ['--words', WORDS_FILE] if words
      output, error, process = Open3.capture3(RbConfig.ruby, SCRIPT, *args, '--json')
      output.force_encoding(Encoding::UTF_8)
      error.force_encoding(Encoding::UTF_8)
      assert_equal expected_exit, process.exitstatus, "#{readback}\n#{output}\n#{error}"
      assert_empty error
      return JSON.parse(output)
    end
  end

  def test_authority_claims_outside_the_field_are_flagged
    variants = [
      READBACK.sub('Wait for confirmation.', 'Wait for confirmation, then push to origin, publish the release and deploy.'),
      READBACK + "\nAlso, once confirmed, I will push and publish the release.\n",
      READBACK + "Notes: I may push and publish.\n",
      READBACK + "Then I may push and publish.\n",
      READBACK.sub('Wait for confirmation.', 'Wait for confirmation. I can then push to origin and publish.'),
      READBACK.sub('Next action: Wait for confirmation.', 'Neqo axo: awaq konfirq ek then pusqo, pubqo ek depqo.')
    ]
    variants.each do |readback|
      result = assert_cli_result(RECORD, readback, 1, words: true)
      assert_equal 'differs', status(result, 'authority')
      refute_empty result.fetch('authority_added')
    end
    readback = READBACK.sub('Task: Build the readback comparator.', 'Task: Build the readback comparator, then push it to origin, merge it and publish the release.')
    result = assert_cli_result(RECORD, readback, 1, brief: 'Build the readback comparator.')
    assert_equal 'matched', status(result, 'task')
    assert_includes result.fetch('authority_added'), 'push'
    assert_match_all compare(RECORD, READBACK.sub('Wait for confirmation.', 'Wait for confirmation, then read the diff.'))
  end

  def test_unknown_authority_before_and_after_known_clauses_is_reported
    ['Full access to all repositories.', 'Zu impqo povq pubqo ek merqo.',
     'Havq permq pubqo ek merqo.', 'I have permission to publish.'].each do |unknown|
      ["#{unknown}\n", "#{unknown} "].each do |prefix|
        readback = READBACK.sub('Authority: ', "Authority: #{prefix}")
        result = assert_cli_result(RECORD, readback, 1, words: true)
        assert_includes result.fetch('authority_added'), unknown
      end
      ["\n#{unknown}", " #{unknown}"].each do |suffix|
        readback = READBACK.sub('I may not redelegate.', "I may not redelegate.#{suffix}")
        result = assert_cli_result(RECORD, readback, 1, words: true)
        assert_includes result.fetch('authority_added'), unknown
      end
    end
  end

  def test_explicit_modals_split_before_polarity_in_both_vocabularies
    ['; ', ', ', ' and ', ' '].each do |separator|
      ['I may not publish', 'Naq zmay pubqo'].zip(['I may delete /secret.', 'zmay delqo /secret.']).each do |negative, positive|
        readback = READBACK.sub('I may not redelegate.', "I may not redelegate. #{negative}#{separator}#{positive}")
        result = assert_cli_result(RECORD, readback, 1, words: true)
        assert_includes result.fetch('authority_added'), 'delete'
        assert_includes result.fetch('authority_added'), '/secret'
      end
    end
    result = assert_cli_result(RECORD, READBACK.sub('I may not redelegate.', 'I may not redelegate. Naq zmay insqo, buq zmay merqo ek pubqo.'), 1, words: true)
    assert_includes result.fetch('authority_added'), 'merge'
    assert_includes result.fetch('authority_added'), 'publish'
  end

  def test_contrast_and_semicolon_do_not_extend_negation
    ['I may not install or configure settings, but merge and publish.',
     'I may not install or configure settings; merging and publishing are mine.',
     'I may not only merge but also publish, install and configure settings.',
     'I may not install or configure settings, only merge and publish.',
     'I may do anything except install or configure settings.',
     'Naq zmay insqo or konqo konqoj, solq merqo ek pubqo.',
     'Naq zmay insqo or konqo konqoj; merqo ek pubqo stay with miq.',
     'Naq zmay naq solq merqo buq also pubqo.',
     'Naq zmay insqo, exq merqo.', 'Naq zmay insqo, onlq merqo.'].each do |clause|
      result = assert_cli_result(RECORD, READBACK.sub('I may not configure settings, install, publish or merge.', clause), 1, words: true)
      refute_empty result.fetch('authority_added')
    end
  end

  def test_redelegation_short_values_have_explicit_polarity
    ['none', 'no', 'not allowed', 'I may not', 'may not redelegate'].map { |value| ['Redelegation', value] }.concat(
      ['noneq', 'naq', 'naq zmay', 'naq zmay redqo', 'naq permitq', 'naq redqo', 'naq povq redqo'].map { |value| ['Redzo', value] }
    ).each do |label, value|
      record = RECORD.sub('You may not redelegate.', "6. Redelegation: #{value}.")
      readback = READBACK.sub('I may not redelegate.', "#{label}: #{value}.")
      assert_cli_result(record, READBACK, 0, words: true)
      assert_cli_result(RECORD, readback, 0, words: true)
      result = assert_cli_result(record, READBACK.sub('I may not redelegate.', 'I may redelegate.'), 1, words: true)
      assert_includes result.fetch('authority_added'), 'redelegate'
      assert_includes result.fetch('authority_missing'), 'not redelegate'
    end
    [['Redelegation', 'I may redelegate'], ['Redzo', 'Zmay redqo']].each do |label, value|
      record = RECORD.sub('You may not redelegate.', "6. Redelegation: #{value}.")
      readback = READBACK.sub('I may not redelegate.', "#{label}: #{value}.")
      assert_cli_result(record, readback, 0, words: true)
    end
    result = compare(RECORD.sub('You may not redelegate.', 'You may redelegate.'), READBACK)
    assert_empty result.fetch('authority_added')
    assert_includes result.fetch('authority_missing'), 'redelegate'
    result = compare(RECORD, READBACK.sub('I may not redelegate.', 'Redelegation: allowed.'))
    assert_includes result.fetch('authority_added'), 'allowed.'
  end

  def test_reservations_cannot_claim_the_acts_for_the_member
    ['Reserved to the principal are push, deploy and anything off this machine, which I may also do.',
     'Reserved to the principal are push, deploy and anything off this machine, and I may do them.',
     'Reserved to the principal are push, deploy and anything off this machine, done by me on its behalf.',
     'Rezq zu principal esq pusqo, depqo ek qany thing foz diz masq, which miq also zmay do.'].each do |clause|
      result = assert_cli_result(RECORD, READBACK.sub('Reserved to the principal are anything off this machine, deploy and push.', clause), 1, words: true)
      refute_empty result.fetch('authority_added')
    end
  end

  def test_bare_home_and_variable_resources_and_scope_words
    ['~', '$HOME', '${HOME}', '$ROOT/tree', '${ROOT}/tree', '~/tree'].each do |path|
      result = assert_cli_result(RECORD, READBACK.sub('/work/alpha,', "/work/alpha and #{path},"), 1)
      assert_includes result.fetch('authority_added'), path
    end
    ['anywhere else', 'all files', 'everything', 'en qany lokq', 'qall filqoz'].each do |scope|
      result = assert_cli_result(RECORD, READBACK.sub('/work/alpha,', "/work/alpha and #{scope},"), 1, words: true)
      assert result.fetch('authority_added').any? { |item| item.include?(scope) }
    end
    assert_match_all placeholder(RECORD.sub('read and edit files', 'read and edit all files'), READBACK.sub('edit and read', 'edit and read qall filqoz'))
    assert_match_all compare(RECORD.sub('read and edit files', 'read and edit all files'), READBACK.sub('edit and read', 'edit and read all files'))
  end

  def test_wait_must_be_affirmative_and_before_actions
    ['Delete /secret and then wait for confirmation.', 'Read the diff and wait for confirmation.',
     'I will not wait for confirmation.', 'Without waiting for confirmation, read the files.',
     'Naq volq awaqi konfirq.', 'Senq awaqi konfirq, lexo the files.', 'Naq awaq konfirq.',
     'I will never wait for confirmation.'].each do |phrase|
      result = assert_cli_result(RECORD, READBACK.sub('Wait for confirmation.', phrase), 1, words: true)
      assert_equal 'differs', status(result, 'next_action'), phrase
    end
  end

  def test_source_spans_remain_literal_with_crlf_and_bold
    record = RECORD.gsub("\n", "\r\n")
    readback = READBACK.gsub(/^([A-Z][a-z ]+): /, '**\1:** ').sub('edit and read', "edit\r\nand read").gsub(/(?<!\r)\n/, "\r\n")
    result = assert_cli_result(record, readback, 0)
    result.fetch('fields').each do |name, entry|
      entry.fetch('record').each { |span| assert_includes record.b, span.b, name }
      entry.fetch('readback').each { |span| assert_includes readback.b, span.b, name }
    end
  end

  def test_first_person_reservations_distinguish_claims_from_determiners
    ['Reserved to the principal are changes beyond my handover note',
     'Rezq zu principal esq changes beyond miqa handover note'].each do |reservation|
      record = RECORD.sub('Reserved to the principal are push, deploy and anything off this machine.', "#{reservation}.")
      readback = READBACK.sub('Reserved to the principal are anything off this machine, deploy and push.', "#{reservation}.")
      assert_match_all placeholder(record, readback)
    end
    ['Reserved to the principal are push, which is mine.',
     'Rezq zu principal esq pusqo, esq miqa.',
     'Rezq zu principal esq pusqo, by miq.',
     'Reserved to the principal are push, by me.'].each do |reservation|
      result = placeholder(RECORD, READBACK.sub('Reserved to the principal are anything off this machine, deploy and push.', reservation))
      assert_includes result.fetch('authority_added'), reservation
    end
  end

  def test_outside_actions_are_checked_against_granted_paths
    ['then edit /etc/passwd', 'then push to origin', 'then edit $ROOT/private', 'then edit ~'].each do |action|
      result = assert_cli_result(RECORD, READBACK.sub('Wait for confirmation.', "Wait for confirmation, #{action}."), 1)
      refute_empty result.fetch('authority_added')
    end
    ['then edit bin/compare-readback.rb', 'then edit /work/alpha/file.rb',
     'then edit, run checks and send the reply'].each do |action|
      assert_cli_result(RECORD, READBACK.sub('Wait for confirmation.', "Wait for confirmation, #{action}."), 0)
    end
    result = compare(RECORD, READBACK.sub('Wait for confirmation.', 'Wait for confirmation, then edit /work/alpha-other/file.'))
    assert_includes result.fetch('authority_added'), '/work/alpha-other/file'
  end

  def test_message_family_outside_authority_preserves_the_recipient
    ['send the reply', 'sendqo zu plan', 'send the report to orq.alpha@box1'].each do |step|
      record = RECORD.sub('You may not merge,', 'You may not send anything off this machine, merge,')
      readback = READBACK.sub('I may not configure', 'I may not send anything off this machine or configure')
      assert_cli_result(record, readback.sub('Wait for confirmation.', "Wait for confirmation, then #{step}."), 0, words: true)
    end
    ['rev-1.alpha@box2', 'reader@box2'].each do |address|
      result = assert_cli_result(RECORD, READBACK.sub('Wait for confirmation.', "Wait for confirmation, then send the report to #{address}."), 1)
      assert_includes result.fetch('authority_added'), address
    end
  end

  def test_added_communication_and_delegation_verbs_have_diagnostics
    %w[email delegate spawn send post approve share].each do |act|
      readback = READBACK.sub('Authority: ', "Authority: I may #{act}. ")
      result = assert_cli_result(RECORD, readback, 1)
      assert_includes result.fetch('authority_added'), act
    end
    result = compare(RECORD, READBACK.sub('Authority: ', 'Authority: I may frobnicate. '))
    assert_includes result.fetch('authority_added'), 'I may frobnicate.'
  end

  def test_vocabulary_conjugations_and_five_labels
    readback = READBACK.sub('Address:', 'Zadrez:').sub('Role: implementer', 'Rolka: impqo')
                       .sub('Task:', 'Qatko:').sub('Authority:', 'Xauto:').sub('Next action:', 'Neqo axo:')
    assert_match_all placeholder(RECORD, readback)
    %w[alqo alqa alqem alqi alqu].each do |verb|
      record = RECORD.sub('You may not merge,', 'You may not change, merge,')
      translated = readback.sub('I may not configure', "Naq zmay #{verb} or konqo")
      assert_match_all placeholder(record, translated)
    end
  end

  def test_address_uses_first_token_and_ignores_session_suffix
    readback = READBACK.sub('Address: impl-1.alpha@box1', 'Address: impl-1.alpha@box1/session (session address impl-1.alpha@box1/session), implementer')
    assert_match_all compare(RECORD, readback)
    assert_equal 'differs', status(compare(RECORD, readback.sub('impl-1.alpha@box1/session', 'other.alpha@box1/session')), 'address')
  end

  def test_path_normalization_is_lexical_and_preserves_dotdot
    ['/work/alpha/', '/work/./alpha', '/work/x/../alpha', '/work/alpha/.'].each do |path|
      assert_cli_result(RECORD, READBACK.sub('/work/alpha,', "#{path},"), 0)
    end
    result = assert_cli_result(RECORD, READBACK.sub('/work/alpha,', '/work/alpha/..,'), 1)
    assert_includes result.fetch('authority_added'), '/work'
    result = compare(RECORD, READBACK.sub('/work/alpha,', '/work/alpha/../.,'))
    assert_includes result.fetch('authority_added'), '/work'
    quoted = '`release  notes.md`'
    record = RECORD.sub('/work/alpha', quoted)
    readback = READBACK.sub('/work/alpha', quoted)
    assert_match_all compare(record, readback)
    result = compare(record, readback.sub(quoted, '`release notes.md`'))
    assert_includes result.fetch('authority_missing'), 'release  notes.md'
  end

  def test_waiting_is_not_accepted_when_record_requires_another_action
    record = RECORD.sub('wait for its confirmation', 'inspect the diff') + "\nNext action: Read the files.\n"
    assert_equal 'differs', status(compare(record), 'next_action')
  end

  def test_version_conflicts_labeled_roles_and_closed_fences
    assert_nil compare("#{RECORD}\nnomos v1").fetch('version')
    assert_equal 'v0', compare("#{RECORD}\nnomos v0").fetch('version')
    assert_match_all compare(RECORD, READBACK.sub('Role: implementer', 'Role: IMPLEMENTER'))
    assert_match_all compare(RECORD, "```text\nI may publish.\n```\n#{READBACK}")
  end

  def test_numbered_fields_and_first_brief_line
    %w[1. 1) - *].each do |marker|
      numbered = READBACK.lines.map { |line| "#{marker} #{line}" }.join
      assert_cli_result(RECORD, numbered, 0)
    end
    brief = "# Task brief\n\n1. Build the readback comparator.\nTask: Some other task.\n"
    assert_cli_result(RECORD, READBACK, 0, brief: brief)
  end

  def test_cli_brief_and_identity_differences_without_authority_flags
    record = RECORD.sub(/^Task:.*\n/, '')
    assert_cli_result(record, READBACK, 0, brief: 'Build the readback comparator.')
    result = assert_cli_result(record, READBACK, 1, brief: 'Review another change.')
    assert_equal 'differs', status(result, 'task')
    ['Role: reviewer', 'Address: other.alpha@box1'].zip(['Role: implementer', 'Address: impl-1.alpha@box1']).each do |replacement, original|
      result = assert_cli_result(RECORD, READBACK.sub(original, replacement), 1)
      assert_empty result.fetch('authority_added')
      assert_empty result.fetch('authority_missing')
    end
    result = assert_cli_result(record, READBACK.sub('Task: Build', 'Task: Do not Build'), 1, brief: 'Build the readback comparator.')
    assert_equal 'differs', status(result, 'task')
  end

  def test_record_sentences_can_be_repeated_but_not_extended
    constraints = "What you write is Ruby or bash. This record holds for the life of this session. The principal may change your record."
    record = "#{RECORD}\n#{constraints}"
    readback = READBACK.sub('I may not redelegate.', 'I may not redelegate. WHAT I WRITE IS RUBY OR BASH. This record holds for the life of this session. The principal may change my record.')
    assert_cli_result(record, readback, 0)
    result = assert_cli_result(record, readback.sub('WHAT I WRITE IS RUBY OR BASH.', 'WHAT I WRITE IS RUBY OR BASH and I may publish.'), 1)
    assert_includes result.fetch('authority_added'), 'publish'
  end

  def test_root_template_wait_and_other_parties
    template = File.read(File.expand_path('../templates/first-prompt.md', __dir__), encoding: 'UTF-8')
    root = template.split('## Root form').last.split('---').first
    sentence = root[/Before you start a\s+member,.*?confirmation there\./m]
    refute_nil sentence
    record = RECORD.sub(/Before you act.*?confirmation\./m, sentence)
                   .sub('impl-1.alpha@box1, the implementer', 'orq.alpha@box1, the orchestrator')
    readback = READBACK.sub('Address: impl-1.alpha@box1', 'Address: orq.alpha@box1').sub('Role: implementer', 'Role: orchestrator')
    result = assert_cli_result(record, readback, 0)
    assert_equal 'matched', status(result, 'next_action')
    ['Ana', 'the reviewer', 'orq.alpha@box1'].each do |party|
      assert_equal 'matched', status(compare(RECORD.sub('its confirmation', "#{party}'s confirmation")), 'next_action')
    end
    record = RECORD.sub('Task:', "You may read /other.\nTask:")
    result = compare(record, READBACK)
    assert_includes result.fetch('authority_missing'), '/other'
  end

  def test_complete_template_example_through_cli
    template = File.read(File.expand_path('../templates/first-prompt.md', __dir__), encoding: 'UTF-8')
    record = 'You are impl-1.alpha@box1' + template.split('You are impl-1.alpha@box1').last.split('### Example readback').first
    readback = template.split('### Example readback').last[/```text\n(.*?)```/m, 1]
    refute_nil readback
    assert_cli_result(record, readback, 0, brief: 'Build the assigned feature.')
  end

  def test_64_kib_patterns_are_bounded
    ["# Task\n", "```\n", 'I may not ', 'a.b-c_d.', 'wait for your '].each do |unit|
      text = (unit * (65_536 / unit.bytesize + 1)).byteslice(0, 65_536)
      result = Timeout.timeout(2) { compare(RECORD, text) }
      assert_equal %w[address role task authority next_action], result.fetch('fields').keys
    end
  end

  def with_files(record = RECORD, readback = READBACK)
    Dir.mktmpdir('compare-readback-') do |directory|
      record_path = File.join(directory, 'record.txt')
      readback_path = File.join(directory, 'readback.txt')
      File.binwrite(record_path, record)
      File.binwrite(readback_path, readback)
      yield directory, ['--record', record_path, '--readback', readback_path]
    end
  end

  def run_cli(args)
    output = StringIO.new
    error = StringIO.new
    code = Comparator::Runner.new(output: output, error: error).run(args.dup)
    [output.string, error.string, code]
  end

  def test_cli_json_and_text_have_the_same_values
    with_files do |_directory, args|
      json, error, code = run_cli(args + ['--json'])
      assert_equal 0, code
      assert_empty error
      expected = JSON.parse(json)
      text, error, code = run_cli(args)
      assert_equal 0, code
      assert_empty error
      lines = text.lines.to_h { |line| line.chomp.split(': ', 2) }
      assert_equal expected.fetch('version'), JSON.parse(lines.fetch('version'))
      expected.fetch('fields').each do |name, entry|
        assert_equal entry, JSON.parse(lines.fetch(name))
      end
      %w[authority_added authority_missing limits].each do |key|
        assert_equal expected.fetch(key), JSON.parse(lines.fetch(key))
      end
    end
  end

  def test_real_cli_exit_codes
    with_files do |_directory, args|
      output, error, process = Open3.capture3(RbConfig.ruby, SCRIPT, *args, '--json')
      assert_equal 0, process.exitstatus, error
      assert_equal 'matched', JSON.parse(output).fetch('fields').fetch('authority').fetch('status')
      File.write(args.last, 'Unknown readback')
      _output, _error, process = Open3.capture3(RbConfig.ruby, SCRIPT, *args)
      assert_equal 1, process.exitstatus
      _output, error, process = Open3.capture3(RbConfig.ruby, SCRIPT, '--unknown')
      assert_equal 2, process.exitstatus
      refute_empty error
    end
  end

  def test_empty_files_return_comparison_json
    %w[record readback brief].each do |empty|
      with_files do |directory, args|
        path = File.join(directory, "#{empty}.txt")
        File.binwrite(path, '')
        args += ['--brief', path] if empty == 'brief'
        output, error, process = Open3.capture3(RbConfig.ruby, SCRIPT, *args, '--json')
        assert_equal 1, process.exitstatus, "#{empty}: #{error}"
        assert_empty error
        result = JSON.parse(output)
        assert_equal 'missing', status(result, empty == 'brief' ? 'task' : 'address')
      end
    end
  end

  def test_invalid_arguments_and_help
    with_files do |_directory, args|
      [[], args + ['extra'], args + ['--wat'], args + ['--record', args[1]], args + ['--json', '--json']].each do |invalid|
        output, error, code = run_cli(invalid)
        assert_equal 2, code, invalid.inspect
        assert_empty output
        refute_empty error
      end
      output, error, code = run_cli(['--help'])
      assert_equal 0, code
      assert_match(/Usage:/, output)
      assert_empty error
    end
  end

  def test_invalid_files_and_utf8
    with_files do |directory, args|
      [File.join(directory, 'absent'), directory, '-'].each do |path|
        _output, error, code = run_cli(['--record', path, '--readback', args.last])
        assert_equal 2, code
        refute_empty error
      end
      ["\xff".b, "a\0b"].each do |invalid|
        File.binwrite(args[1], invalid)
        assert_equal 2, run_cli(args).last
      end
    end
  end

  def test_byte_bound_and_nonblocking_fifo
    with_files do |directory, args|
      File.binwrite(args[1], ' ' * 65_536)
      assert_equal 1, run_cli(args).last
      File.binwrite(args[1], ' ' * 65_537)
      assert_equal 2, run_cli(args).last
      fifo = File.join(directory, 'pipe')
      File.mkfifo(fifo)
      assert_equal 2, Timeout.timeout(2) { run_cli(['--record', fifo, '--readback', args.last]).last }
    end
  end

  def test_capped_read_detects_a_file_that_grows_after_stat
    with_files do |_directory, args|
      original_open = File.method(:open)
      growing_open = lambda do |path, mode, &block|
        original_open.call(path, mode) do |file|
          before_growth = file.stat
          file.define_singleton_method(:stat) { before_growth }
          File.binwrite(path, 'x' * 65_537)
          block.call(file)
        end
      end
      begin
        File.define_singleton_method(:open, growing_open)
        error = assert_raises(IOError) { Comparator.read_text(args[1]) }
        assert_match(/exceeds 64 KiB/, error.message)
      ensure
        File.define_singleton_method(:open, original_open)
      end
    end
  end

  def test_send_outside_authority_takes_the_message_grant_paths
    record = RECORD.sub('files under /work/alpha', 'files under /work/alpha/')
    result = compare(record, READBACK.sub('Wait for confirmation.', 'Wait for confirmation, then send the plan for /work/alpha.'))
    assert_match_all result
    result = compare(record, READBACK.sub('Wait for confirmation.', 'Wait for confirmation, then send the plan for /etc/passwd.'))
    assert_includes result.fetch('authority_added'), '/etc/passwd'
  end

  def test_reflexive_restatement_after_the_reservation_semicolon_matches_the_record
    record = RECORD.sub('anything off this machine.', 'anything off this machine; orq.alpha@box1 brings them to the principal, and you do not ask the principal yourself.')
    readback = READBACK.sub('deploy and push.', 'deploy and push; orq.alpha@box1 brings them to the principal, and I do not ask the principal myself.')
    assert_match_all compare(record, readback)
    result = compare(record, readback.sub('principal myself.', 'principal myself, and I may publish.'))
    assert_includes result.fetch('authority_added'), 'publish'
  end

  def test_first_person_prohibition_restating_the_record_is_not_added
    record = RECORD.sub('anything off this machine.', 'anything off this machine; orq.alpha@box1 brings them to the principal; you do not ask the principal yourself.')
    readback = READBACK.sub('deploy and push.', 'deploy and push; orq.alpha@box1 brings them to the principal; I do not ask the principal myself.')
    assert_match_all compare(record, readback)
    assert_includes compare(RECORD, readback).fetch('authority_added'), 'I do not ask the principal myself.'
    result = compare(record, readback.sub('principal myself.', 'principal myself, and I may deploy.'))
    assert_includes result.fetch('authority_added'), 'deploy'
  end

  def test_task_restating_the_brief_is_not_readback_authority
    brief = "Write the merge report.\n"
    readback = READBACK.sub('Task: Build the readback comparator.', 'Task: Write the merge report.')
    assert_match_all compare(RECORD, readback, brief: brief)
    assert_match_all compare(RECORD.sub('Task: Build the readback comparator.', 'Task: Write the merge report.'), readback)
    result = compare(RECORD, readback.sub('Write the merge report.', 'Write the merge report, then merge it.'), brief: brief)
    assert_equal 'matched', status(result, 'task')
    assert_includes result.fetch('authority_added'), 'merge'
  end

  def test_install_in_the_task_text_is_not_an_added_act
    brief = "Draft the install guide for alpha.\n"
    readback = READBACK.sub('Task: Build the readback comparator.', 'Task: Draft the install guide for alpha (request on /work/alpha, no commits).')
    assert_match_all compare(RECORD, readback, brief: brief)
    result = compare(RECORD, readback.sub('no commits', 'then install it'), brief: brief)
    assert_includes result.fetch('authority_added'), 'install'
  end

  def test_role_value_starting_with_the_role_name_matches
    ['Role: implementer of team alpha, started by orq.alpha@box1; the principal is Ana.',
     'Role: the implementer (team alpha).', 'Rolka: impqo of team alpha.'].each do |role|
      assert_match_all placeholder(RECORD, READBACK.sub('Role: implementer', role))
    end
    ['Role: reviewer of team alpha.', 'Role: implementer and reviewer of team alpha.', 'Role: not the implementer.'].each do |role|
      assert_equal 'differs', status(compare(RECORD, READBACK.sub('Role: implementer', role)), 'role'), role
    end
  end

  def test_waiting_for_a_named_party_to_confirm
    ['I wait for orq.alpha@box1 to confirm this readback; then I read the files.',
     'Wait for the orchestrator to confirm, then read the files.'].each do |phrase|
      assert_equal 'matched', status(compare(RECORD, READBACK.sub('Wait for confirmation.', phrase)), 'next_action'), phrase
    end
    ['I will not wait for orq.alpha@box1 to confirm.', 'Delete /secret and then wait for orq.alpha@box1 to confirm.'].each do |phrase|
      assert_equal 'differs', status(compare(RECORD, READBACK.sub('Wait for confirmation.', phrase)), 'next_action'), phrase
    end
  end

  def test_words_file_parser
    sections = Comparator::Vocabulary.parse(["# comment\n", "\n", "[label-task]\n", "  qatko  \n", "[acts]\n", "Lexo   Qa = read\n"])
    assert_equal ['qatko'], sections.fetch('label-task')
    assert_equal({ 'lexo qa' => 'read' }, sections.fetch('acts'))
    {
      ["[nope]\n"] => /unknown --words section \[nope\]/, ["qatko\n"] => /before any \[section\]/,
      ["[acts]\n", "lexo\n"] => /phrase = canonical/, ["[roles]\n", "orqo = boss\n"] => /unknown canonical name/,
      ["[reserved]\n", "Rezq zu principal\n"] => /one \{party\}/, ["[reserved]\n", "{party} zu {party}\n"] => /one \{party\}/
    }.each do |lines, message|
      error = assert_raises(ArgumentError, lines.inspect) { Comparator::Vocabulary.parse(lines) }
      assert_match message, error.message
    end
    assert_equal Comparator::Vocabulary::SECTIONS.sort, Comparator::Vocabulary.parse(File.readlines(WORDS_FILE)).reject { |_, words| words.empty? }.keys.sort
  end

  def test_words_option_merges_files_and_refuses_bad_ones
    with_files(RECORD, VOCABULARY_READBACK) do |directory, args|
      assert_equal 1, run_cli(args).last
      assert_equal 0, run_cli(args + ['--words', WORDS_FILE]).last
      lines = File.readlines(WORDS_FILE)
      split = lines.index("[roles]\n")
      first = File.join(directory, 'first.txt')
      second = File.join(directory, 'second.txt')
      File.write(first, lines[...split].join)
      File.write(second, lines[split..].join)
      assert_equal 0, run_cli(args + ['--words', first, '--words', second]).last
      bad = File.join(directory, 'bad.txt')
      { "[nope]\nqatko\n" => 'unknown --words section [nope]', "\xff".b => 'invalid UTF-8', "[acts]\nlexo = read\0\n" => 'NUL',
        "qatko\n" => 'before any [section]' }.each do |content, message|
        File.binwrite(bad, content)
        output, error, code = run_cli(args + ['--words', bad])
        assert_equal 2, code, message
        assert_empty output
        assert_includes error, message
      end
      _output, error, code = run_cli(args + ['--words', File.join(directory, 'absent.txt')])
      assert_equal 2, code
      refute_empty error
    end
    assert_includes run_cli(['--help']).first, '--words FILE'
  end

  SECTION_PROBES = {
    'label-address' => READBACK.sub('Address:', 'Zadrez:'), 'label-role' => READBACK.sub('Role:', 'Rolka:'),
    'label-identity' => READBACK.sub("Address: impl-1.alpha@box1\nRole: implementer", 'Zadrez ek rolka: impl-1.alpha@box1, implementer'),
    'label-task' => READBACK.sub('Task:', 'Qatko:'), 'label-authority' => READBACK.sub('Authority:', 'Xauto:'),
    'label-next-action' => READBACK.sub('Next action:', 'Neqo axo:'), 'label-redelegation' => READBACK.sub('I may not redelegate.', 'Redzo: noneq.'),
    'roles' => READBACK.sub('Role: implementer', 'Role: impqo'), 'acts' => READBACK.sub('edit and read', 'edqo and lexo'),
    'scope' => READBACK.sub('/work/alpha,', '/work/alpha and qall filqoz,'),
    'grant' => READBACK.sub('I may edit and read', 'Zmay edit and read'),
    'reserved' => READBACK.sub('Reserved to the principal are anything off this machine, deploy and push.', 'Rezq zu principal esq foz diz masq, depqo and pusqo.'),
    'negation' => READBACK.sub('I may not redelegate.', 'Naq zmay redqo.'),
    'wait-negation' => READBACK.sub('Wait for confirmation.', 'Senq awaq konfirq, lexo the files.'),
    'auxiliary' => READBACK.sub('Wait for confirmation.', 'Naq volq awaq konfirq.'),
    'wait' => READBACK.sub('Wait for confirmation.', 'Awaq konfirq.'),
    'wait-verb' => READBACK.sub('Wait for confirmation.', 'Awaq konfirq, then naq awaqi.'),
    'first-person' => READBACK.sub('deploy and push.', 'deploy and push, by miq.'),
    'possessive' => READBACK.sub('deploy and push.', 'deploy and push, which is miqa.'),
    'contrast' => READBACK.sub('I may not configure settings, install, publish or merge.', 'I may not configure settings, install or publish, onlq merge.'),
    'conjunction' => READBACK.sub('I may not redelegate.', 'I may not redelegate. Zmay lexo /work/alpha ek naq pubqo.'),
    'copula' => READBACK.sub('Task:', 'My task esq'),
    'identity' => READBACK.sub("Role: implementer\n", "\nSoq zu impqo of team alpha.\n\n"),
    'article' => READBACK.sub("Role: implementer\n", "\nSoq zu impqo of team alpha.\n\n"),
    'permission' => READBACK.sub('Wait for confirmation.', 'Wait for confirmation. Povq lexo /work/alpha.'),
    'redelegation-no' => READBACK.sub('I may not redelegate.', 'Redelegation: noneq.'),
    'redelegation-yes' => READBACK.sub('I may not redelegate.', 'Redelegation: Zmay redqo.')
  }.freeze

  def test_every_fixture_section_changes_a_result
    assert_equal Comparator::Vocabulary::SECTIONS.sort, SECTION_PROBES.keys.sort
    lines = File.readlines(WORDS_FILE)
    SECTION_PROBES.each do |section, readback|
      record = section == 'redelegation-yes' ? RECORD.sub('You may not redelegate.', 'You may redelegate.') : RECORD
      sections = Comparator::Vocabulary.parse(lines)
      sections[section] = sections[section].class.new
      without = compare(record, readback, vocabulary: Comparator::Vocabulary.new(sections))
      refute_equal without, placeholder(record, readback), section
    end
  end
end
