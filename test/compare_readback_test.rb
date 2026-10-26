require 'minitest/autorun'
require 'open3'
require 'stringio'
require 'tmpdir'
require 'timeout'
require_relative '../bin/compare-readback'

class CompareReadbackTest < Minitest::Test
  Comparator = Nomos::CompareReadback
  SCRIPT = File.expand_path('../bin/compare-readback.rb', __dir__)
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

  def compare(record = RECORD, readback = READBACK, brief: nil)
    Comparator.compare(record: record, readback: readback, brief: brief)
  end

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

  def test_opening_identity_with_tag_and_portuguese_sentence_forms
    ['[readback] impl-1.alpha@box1, implementer, aguarda confirmação.',
     'Sou impl-1.alpha@box1, implementer da equipe alpha.',
     'Eu sou impl-1.alpha@box1, implementador do time alpha.',
     "[accept] Readback de impl-1.alpha@box1.\nSou impl-1.alpha@box1, implementer da equipe alpha."].each do |opening|
      readback = READBACK.sub("Address: impl-1.alpha@box1\nRole: implementer", opening)
      assert_match_all compare(RECORD, readback)
      result = compare(RECORD, readback.sub('impl-1.alpha@box1', 'impl-2.alpha@box1'))
      assert_equal 'differs', status(result, 'address')
    end
  end

  def test_opening_role_comes_from_the_fixed_list_next_to_the_address
    %w[orchestrator implementer reviewer writer qa auditor].zip(%w[orquestrador implementador revisor redator qa auditor]).each do |english, portuguese|
      record = RECORD.sub('the implementer of team', "the #{english} of team")
      readback = READBACK.sub("Address: impl-1.alpha@box1\nRole: implementer", "[readback] impl-1.alpha@box1, #{portuguese} da equipe alpha.")
      assert_match_all compare(record, readback)
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

  def test_portuguese_labels_and_vocabulary
    readback = <<~TEXT
      Endereço: impl-1.alpha@box1
      Papel: implementer
      Tarefa: Build the readback comparator.
      Autoridade: Posso ler e editar /work/alpha, executar verificações e enviar mensagem para orq.alpha@box1.
      Não posso mesclar, publicar, instalar ou configurar configurações.
      Reservado ao principal estão push, implantar e qualquer coisa fora desta máquina.
      Não posso redelegar.
      Próxima ação: Wait for confirmation.
    TEXT
    assert_match_all compare(RECORD, readback)
  end

  def test_each_vocabulary_translation
    pairs = {
      'read' => 'ler', 'edit' => 'editar', 'create' => 'criar', 'remove' => 'remover',
      'write' => 'escrever', 'run' => 'executar', 'message' => 'enviar mensagem',
      'commit' => 'commitar', 'push' => 'push', 'publish' => 'publicar', 'merge' => 'mesclar',
      'delete' => 'excluir', 'deploy' => 'implantar', 'install' => 'instalar',
      'configure' => 'configurar', 'settings' => 'configurações',
      'off this machine' => 'fora desta máquina', 'redelegate' => 'redelegar',
      'open' => 'abrir', 'update' => 'atualizar', 'tag' => 'etiquetar',
      'change' => 'alterar', 'grant' => 'conceder'
    }
    pairs.each do |english, portuguese|
      result = compare("#{RECORD}\nYou may #{english}.", "#{READBACK}\nPosso #{portuguese}.")
      assert_equal 'matched', status(result, 'authority'), "#{english}: #{result}"
    end
  end

  def test_foreign_unlabeled_prose_is_missing
    result = compare(RECORD, 'Je suis le responsable et attends la confirmation.')
    assert_equal ['missing'] * 5, result.fetch('fields').values.map { |entry| entry.fetch('status') }
  end

  def test_labels_accept_short_connectors_and_sentence_starts
    ['Task is', 'My task is', 'Minha tarefa é', 'Tarefa conforme o pedido é',
     'Task as assigned:', 'Tarefa conforme o pedido.'].each do |label|
      readback = READBACK.sub('Task:', label)
      assert_equal 'matched', status(compare(RECORD, readback), 'task'), label
    end
    readback = READBACK.sub('Task:', "\nReady. My task is")
    assert_equal 'matched', status(compare(RECORD, readback), 'task')
    ['Authority as my first prompt gives it.', 'My authority is', 'Minha autoridade é'].each do |label|
      assert_match_all compare(RECORD, READBACK.sub('Authority:', label))
    end
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
    line = 'Próxima ação após confirmação é ler os arquivos.'
    result = compare(RECORD, READBACK.sub('Next action: Wait for confirmation.', line))
    assert_includes field(result, 'next_action').fetch('readback'), line
  end

  def test_modal_grants_inside_task_need_review
    readback = READBACK.sub("Task: Build the readback comparator.\nAuthority: ", "Minha tarefa é Build the readback comparator. ")
    result = compare(RECORD, readback)
    assert_equal 'differs', status(result, 'authority')
    refute_empty result.fetch('authority_added')
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
    ['Wait for your [accept], checking the inbox.', 'After confirmation, read the files.',
     'Aguardo confirmação para ler os arquivos.', 'Aguardar sua confirmação e ler os arquivos.',
     'Aguarda a confirmação e lê os arquivos.', 'Após confirmação, ler os arquivos.',
     'Após a confirmação, ler os arquivos.', 'Depois da confirmação, ler os arquivos.'].each do |phrase|
      assert_equal 'matched', status(compare(RECORD, READBACK.sub('Wait for confirmation.', phrase)), 'next_action'), phrase
    end
    ['Próxima ação após confirmação é ler os arquivos.',
     'Minha próxima ação, após a confirmação, é ler os arquivos.'].each do |line|
      assert_equal 'matched', status(compare(RECORD, READBACK.sub('Next action: Wait for confirmation.', line)), 'next_action'), line
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
    ['I may not redelegate, install or configure settings.', 'Não posso redelegar, instalar ou configurar configurações.'].each do |clause|
      readback = READBACK.sub("I may not configure settings, install, publish or merge.\n", "I may not publish or merge.\n")
      readback = readback.sub('I may not redelegate.', clause)
      assert_match_all compare(RECORD, readback)
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
    ['fora da máquina', 'para fora da máquina', 'fora desta máquina'].each do |phrase|
      readback = READBACK.sub('anything off this machine', phrase)
      assert_match_all compare(record, readback)
    end
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

  def assert_cli_result(record, readback, expected_exit, brief: nil)
    with_files(record, readback) do |directory, args|
      if brief
        path = File.join(directory, 'brief.txt')
        File.binwrite(path, brief)
        args += ['--brief', path]
      end
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
      READBACK.sub('Next action: Wait for confirmation.', 'Próxima ação: aguardo confirmação e depois faço push, publico e implanto.')
    ]
    variants.each do |readback|
      result = assert_cli_result(RECORD, readback, 1)
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
    ['Full access to all repositories.', 'O implementador pode publicar e mesclar.',
     'Tenho permissão para publicar e mesclar.', 'I have permission to publish.'].each do |unknown|
      ["#{unknown}\n", "#{unknown} "].each do |prefix|
        readback = READBACK.sub('Authority: ', "Authority: #{prefix}")
        result = assert_cli_result(RECORD, readback, 1)
        assert_includes result.fetch('authority_added'), unknown
      end
      ["\n#{unknown}", " #{unknown}"].each do |suffix|
        readback = READBACK.sub('I may not redelegate.', "I may not redelegate.#{suffix}")
        result = assert_cli_result(RECORD, readback, 1)
        assert_includes result.fetch('authority_added'), unknown
      end
    end
  end

  def test_explicit_modals_split_before_polarity_in_both_languages
    ['; ', ', ', ' and ', ' '].each do |separator|
      ['I may not publish', 'Não posso publicar'].zip(['I may delete /secret.', 'posso excluir /secret.']).each do |negative, positive|
        readback = READBACK.sub('I may not redelegate.', "I may not redelegate. #{negative}#{separator}#{positive}")
        result = assert_cli_result(RECORD, readback, 1)
        assert_includes result.fetch('authority_added'), 'delete'
        assert_includes result.fetch('authority_added'), '/secret'
      end
    end
    result = assert_cli_result(RECORD, READBACK.sub('I may not redelegate.', 'I may not redelegate. Não posso instalar, mas posso mesclar e publicar.'), 1)
    assert_includes result.fetch('authority_added'), 'merge'
    assert_includes result.fetch('authority_added'), 'publish'
  end

  def test_contrast_and_semicolon_do_not_extend_negation
    ['I may not install or configure settings, but merge and publish.',
     'I may not install or configure settings; merging and publishing are mine.',
     'I may not only merge but also publish, install and configure settings.',
     'I may not install or configure settings, only merge and publish.',
     'I may do anything except install or configure settings.',
     'Não posso instalar nem configurar configurações, só mesclar e publicar.',
     'Não posso instalar nem configurar configurações; mesclar e publicar ficam comigo.',
     'Não posso não só mesclar mas também publicar.',
     'Não posso instalar, exceto mesclar.', 'Não posso instalar, somente mesclar.'].each do |clause|
      result = assert_cli_result(RECORD, READBACK.sub('I may not configure settings, install, publish or merge.', clause), 1)
      refute_empty result.fetch('authority_added')
    end
  end

  def test_redelegation_short_values_have_explicit_polarity
    ['none', 'no', 'not allowed', 'I may not', 'nenhuma', 'não', 'não posso', 'não permitida',
     'não redelegar', 'não pode redelegar', 'may not redelegate'].each do |value|
      record = RECORD.sub('You may not redelegate.', "6. Redelegation: #{value}.")
      readback = READBACK.sub('I may not redelegate.', "Redelegação: #{value}.")
      assert_cli_result(record, READBACK, 0)
      assert_cli_result(RECORD, readback, 0)
      result = assert_cli_result(record, READBACK.sub('I may not redelegate.', 'I may redelegate.'), 1)
      assert_includes result.fetch('authority_added'), 'redelegate'
      assert_includes result.fetch('authority_missing'), 'not redelegate'
    end
    ['I may redelegate', 'Posso redelegar'].each do |value|
      record = RECORD.sub('You may not redelegate.', "6. Redelegation: #{value}.")
      readback = READBACK.sub('I may not redelegate.', "Redelegação: #{value}.")
      assert_cli_result(record, readback, 0)
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
     'Reservado ao principal são push, implantar e qualquer coisa fora desta máquina, que eu também posso fazer.'].each do |clause|
      result = assert_cli_result(RECORD, READBACK.sub('Reserved to the principal are anything off this machine, deploy and push.', clause), 1)
      refute_empty result.fetch('authority_added')
    end
  end

  def test_bare_home_and_variable_resources_and_scope_words
    ['~', '$HOME', '${HOME}', '$ROOT/tree', '${ROOT}/tree', '~/tree'].each do |path|
      result = assert_cli_result(RECORD, READBACK.sub('/work/alpha,', "/work/alpha and #{path},"), 1)
      assert_includes result.fetch('authority_added'), path
    end
    ['anywhere else', 'all files', 'everything', 'em qualquer lugar', 'todos os arquivos'].each do |scope|
      result = assert_cli_result(RECORD, READBACK.sub('/work/alpha,', "/work/alpha and #{scope},"), 1)
      assert result.fetch('authority_added').any? { |item| item.include?(scope) }
    end
    assert_match_all compare(RECORD.sub('read and edit files', 'read and edit all files'), READBACK.sub('edit and read', 'edit and read all files'))
  end

  def test_wait_must_be_affirmative_and_before_actions
    ['Delete /secret and then wait for confirmation.', 'Read the diff and wait for confirmation.',
     'I will not wait for confirmation.', 'Without waiting for confirmation, read the files.',
     'Não vou aguardar confirmação.', 'Sem aguardar confirmação, ler os arquivos.',
     'I will never wait for confirmation.'].each do |phrase|
      result = assert_cli_result(RECORD, READBACK.sub('Wait for confirmation.', phrase), 1)
      assert_equal 'differs', status(result, 'next_action')
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
     'Reservado ao principal são alterações além da minha nota de handover'].each do |reservation|
      record = RECORD.sub('Reserved to the principal are push, deploy and anything off this machine.', "#{reservation}.")
      readback = READBACK.sub('Reserved to the principal are anything off this machine, deploy and push.', "#{reservation}.")
      assert_match_all compare(record, readback)
    end
    ['Reserved to the principal are push, which is mine.',
     'Reservado ao principal são push, são minhas.',
     'Reservado ao principal são push, por mim.',
     'Reserved to the principal are push, by me.'].each do |reservation|
      result = compare(RECORD, READBACK.sub('Reserved to the principal are anything off this machine, deploy and push.', reservation))
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
    ['send the reply', 'envio o plano técnico', 'send the report to orq.alpha@box1'].each do |step|
      record = RECORD.sub('You may not merge,', 'You may not send anything off this machine, merge,')
      readback = READBACK.sub('I may not configure', 'I may not send anything off this machine or configure')
      assert_cli_result(record, readback.sub('Wait for confirmation.', "Wait for confirmation, then #{step}."), 0)
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

  def test_portuguese_conjugations_and_five_labels
    readback = READBACK.sub('Address:', 'Endereço:').sub('Role: implementer', 'Papel: implementador')
                       .sub('Task:', 'Tarefa:').sub('Authority:', 'Autoridade:').sub('Next action:', 'Próxima ação:')
    assert_match_all compare(RECORD, readback)
    %w[alterar altere alterem altera alteram].each do |verb|
      record = RECORD.sub('You may not merge,', 'You may not change, merge,')
      translated = readback.sub('I may not configure', "Não posso #{verb} nem configurar")
      assert_match_all compare(record, translated)
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
end
