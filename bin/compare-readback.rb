#!/usr/bin/env ruby

require 'json'
require 'optparse'
require 'set'

module Nomos
  module CompareReadback
    MAX_BYTES = 65_536
    ADDRESS = /[A-Za-z0-9_-]+\.[A-Za-z0-9_.-]+@[A-Za-z0-9_.-]+(?:\/[A-Za-z0-9_-]+)?/
    TRANSPORT = /(?<![A-Za-z0-9_.@-])[A-Za-z0-9_.-]+@[A-Za-z0-9_.-]+(?:\/[A-Za-z0-9_-]+)?/
    ROLES = {
      'orchestrator' => 'orchestrator', 'orquestrador' => 'orchestrator',
      'implementer' => 'implementer', 'implementador' => 'implementer',
      'reviewer' => 'reviewer', 'revisor' => 'reviewer', 'writer' => 'writer', 'redator' => 'writer',
      'qa' => 'qa', 'auditor' => 'auditor'
    }.freeze
    ROLE = /(?:#{ROLES.keys.join('|')})(?![\p{L}\p{N}_-])/i
    LABELS = {
      address: { en: ['address'], pt: ['endereço'] },
      role: { en: ['role'], pt: ['papel'] },
      identity: { en: ['address and role', 'delegate'], pt: ['endereço e papel'] },
      task: { en: ['task', 'my task'], pt: ['tarefa', 'minha tarefa'] },
      authority: { en: ['authority', 'my authority'], pt: ['autoridade', 'minha autoridade'] },
      next_action: { en: ['next action', 'my next action'], pt: ['próxima ação', 'minha próxima ação'] },
      other: { en: ['principal', 'delegator', 'duration', 'change authority'], pt: [] },
      grant: { en: ['actions and resources granted'], pt: [] },
      reserved: { en: ['decisions reserved to the principal'], pt: [] },
      redelegation: { en: ['redelegation'], pt: ['redelegação'] }
    }.freeze
    LABEL_NAMES = LABELS.flat_map { |label, forms| forms.values.flatten.map { |name| [name, label] } }.to_h.freeze
    LABEL = /(?:#{LABEL_NAMES.keys.sort_by { |name| -name.length }.map { |name| Regexp.escape(name) }.join('|')})(?![\p{L}\p{N}_])/i
    VOCABULARY = {
      'read' => { en: %w[read reading], pt: %w[ler leitura] },
      'edit' => { en: %w[edit editing], pt: %w[editar edição] },
      'create' => { en: %w[create creating], pt: %w[criar criação] },
      'remove' => { en: %w[remove removing], pt: %w[remover remoção] },
      'write' => { en: %w[write writing], pt: %w[escrever escrita] },
      'run' => { en: %w[run running], pt: %w[executar execução] },
      'message' => { en: %w[message messaging], pt: ['enviar mensagem', 'enviar mensagens'] },
      'commit' => { en: %w[commit commits committing], pt: %w[commitar] },
      'push' => { en: %w[push pushes pushing], pt: %w[push] },
      'publish' => { en: %w[publish publishing publication], pt: %w[publicar publicação] },
      'merge' => { en: %w[merge merging], pt: %w[mesclar] },
      'delete' => { en: %w[delete deleting], pt: %w[excluir exclusão] },
      'deploy' => { en: %w[deploy deploying], pt: %w[implantar] },
      'install' => { en: %w[install installs installing], pt: %w[instalar instalação instalações] },
      'configure' => { en: %w[configure configuring], pt: %w[configurar] },
      'settings' => { en: %w[settings], pt: %w[configurações] },
      'off this machine' => { en: ['off this machine', 'leaves this machine'], pt: ['fora desta máquina', 'fora da máquina', 'para fora da máquina'] },
      'redelegate' => { en: %w[redelegate redelegating grant], pt: %w[redelegar redelegação conceder] },
      'open' => { en: %w[open], pt: %w[abrir] }, 'update' => { en: %w[update], pt: %w[atualizar] },
      'tag' => { en: %w[tag tags], pt: %w[etiquetar etiquetas] }, 'change' => { en: %w[change], pt: %w[alterar] }
    }.freeze
    PT_VERBS = {
      'read' => %w[ler leio lê leem leia leiam], 'edit' => %w[editar edito edita editam edite editem],
      'create' => %w[criar crio cria criam crie criem], 'remove' => %w[remover removo remove removem remova removam],
      'write' => %w[escrever escrevo escreve escrevem escreva escrevam],
      'run' => %w[executar executo executa executam execute executem],
      'message' => ['enviar mensagem', 'enviar mensagens', 'envio mensagem', 'envia mensagem', 'envie mensagem'],
      'commit' => %w[commitar commito commita commitam commite commitem],
      'publish' => %w[publicar publico publica publicam publique publiquem],
      'merge' => %w[mesclar mesclo mescla mesclam mescle mesclem],
      'delete' => %w[excluir excluo exclui excluem exclua excluam],
      'deploy' => %w[implantar implanto implanta implantam implante implantem],
      'install' => %w[instalar instalo instala instalam instale instalem],
      'configure' => %w[configurar configuro configura configuram configure configurem],
      'redelegate' => %w[redelegar redelego redelega redelegam redelegue redeleguem conceder concedo concede concedem conceda concedam],
      'open' => %w[abrir abro abre abrem abra abram], 'update' => %w[atualizar atualizo atualiza atualizam atualize atualizem],
      'tag' => %w[etiquetar etiqueto etiqueta etiquetam etiquete etiquetem],
      'change' => %w[alterar altero altera alteram altere alterem]
    }.freeze
    EXTRA_VERBS = {
      'delegate' => { en: %w[delegate delegating], pt: %w[delegar delego delega delegam delegue deleguem] },
      'spawn' => { en: %w[spawn spawning], pt: %w[iniciar inicio inicia iniciam inicie iniciem] },
      'send' => { en: %w[send sending], pt: %w[enviar envio envia enviam envie enviem transmitir transmito transmite transmitem transmita transmitam] },
      'email' => { en: %w[email emailing], pt: ['enviar email', 'enviar e-mail', 'envio email', 'envia email', 'envie email'] },
      'post' => { en: %w[post posting], pt: %w[postar posto posta postam poste postem] },
      'approve' => { en: %w[approve approving], pt: %w[aprovar aprovo aprova aprovam aprove aprovem] },
      'share' => { en: %w[share sharing], pt: %w[compartilhar compartilho compartilha compartilham compartilhe compartilhem] }
    }.freeze
    WORDS = VOCABULARY.merge(EXTRA_VERBS).flat_map do |name, forms|
      (forms.values.flatten + PT_VERBS.fetch(name, [])).uniq.map { |word| [word, name] }
    end.to_h.freeze
    ACT = /(?<![\p{L}\p{N}_])(?:#{WORDS.keys.sort_by { |word| -word.length }.map { |word| Regexp.escape(word) }.join('|')})(?![\p{L}\p{N}_])/i
    PATH = /(?<![\p{L}\p{N}_@.:\/$])(?:(?:\$\{[A-Za-z_][A-Za-z0-9_]*\}|\$[A-Za-z_][A-Za-z0-9_]*|~)(?:\/[^\s,;"'`<>\[\]{}()]*)?|(?:\/|\.\.?\/|[\p{L}\p{N}_.-]+\/)[^\s,;"'`<>\[\]{}()]*|[\p{L}\p{N}_-][\p{L}\p{N}_.-]*\.[\p{L}\p{N}_-]+)/
    MODAL_ANYWHERE = /(?<![\p{L}\p{N}_])(?:(?:As the [\w-]+ )?(?:you|I)\s+(?:may|can|cannot)\b|(?:não\s+)?posso\b)/i
    MODAL_START = /\A#{MODAL_ANYWHERE}/i
    WAIT = /\b(?:wait for (?:(?:(?:its|your)|(?:[\p{L}\p{N}_.@-]+\s+){0,4}[\p{L}\p{N}_.@-]+['’]s) )?confirmation|wait for your \[accept\]|after confirmation|(?:aguardo|aguardar|aguarda) (?:(?:a|sua|a sua) )?confirmação|após (?:(?:a|sua|a sua) )?confirmação|depois da confirmação)(?!\p{L})/i
    NEGATED_WAIT = /\b(?:(?:not|never|without|não|sem)\s+(?:(?:will|be|vou|vai|irei|iria|vamos)\s+){0,3}(?:wait(?:ing)?|aguard\p{L}*)|(?:do not|não)\s+#{WAIT})/i
    AUTHORITY_LABELS = %i[authority grant reserved redelegation].freeze
    LINE_PREFIX = /^[ \t]*(?:(?:\#{1,6}|[-*]|\d+[.)])[ \t]+)?/
    LABEL_START = /\A(?:\*\*)?(#{LABEL})(?:\*\*)?/i
    LABEL_DELIMITER = /:|\.(?=\s|\z)|(?<!\p{L})(?:is|é)(?!\p{L})/i
    LABEL_BOUNDARY = /(?<=[.!?])\s+(?=(?:\*\*)?#{LABEL})/i
    NEXT_LABEL_PREFIX = /\A(?:\*\*)?(?:next action|my next action|minha próxima ação|próxima ação)\b[\s:*]*/i
    FENCE_START = /^ {0,3}(`{3,}|~{3,})/
    HEADING = /^\s*\#{1,6}\s+/
    QUOTED_LINE = /^\s*>/
    VERSION_LINE = /\A\s*nomos v\d+\b/i
    UNKNOWN_LABEL = /\A[\p{L}][\p{L} ]{0,60}:/
    SENTENCE_BOUNDARY = /(?<=[.!?;])\s+(?=[\p{L}*#\[\d-]|\z)|(?<=;)\s*|\r?\n(?=[ \t]*(?:(?:[-*]|\d+[.)])\s+|#{MODAL_ANYWHERE}|Reserved\b|Reservad[oa]s?\b))/i
    SHORT_MODAL_BOUNDARY = /\s+(?:but|and|mas|e)\s+(?=(?:may\b|can\b|cannot\b|not\b|não\b))/i
    CLAUSE_CONNECTOR = /(?:\A(?:and|but|mas|e)\s+|[,;]\s*\z)/i
    EN_CLAUSE = /\A(?:(?:As the [\w-]+ )?(?:you|I)\s+)?(may|can|cannot)\s+(.*)\z/i
    PT_CLAUSE = /\A(não\s+)?posso\s+(.*)\z/i
    RESERVATION = /\A(?:Reserved to (?:[\p{L}\p{N}_.@-]+\s+){1,8}are|Reservad[oa]s? (?:ao?|à|para) (?:[\p{L}\p{N}_.@-]+\s+){0,7}[\p{L}\p{N}_.@-]+(?:\s+(?:estão|são))?\s*:?)\s+(.*)\z/i
    FIRST_PERSON = /\b(?:I|me|eu|mim|comigo|posso|podemos)\b|\b(?:mine|my|meu|minha|meus|minhas)(?=\s*(?:[,;.!?]|\z))/i
    REDELEGATION_NO = /\A(?:none|no|not allowed|(?:I )?may not(?: redelegate)?|not redelegate|nenhuma|não|não posso(?: redelegar)?|não permitida|não (?:pode )?redelegar)\z/i
    REDELEGATION_YES = /\A(?:I may redelegate|Posso redelegar)\b/i
    CONTRAST = /\b(?:but|only|except|mas|só|somente|exceto)\b/i
    QUOTED_INLINE = /([`"])[^`"\r\n]*\1/
    PERMISSION = /\b(?:(?:I|you) (?:may|can|am allowed|have permission)|(?:não )?posso|tenho permissão|pode(?:m)?|not\s+(?:publish|merge)|I am authorized)\b/i
    SCOPE = /\b(?:any|all|anywhere|everything|everywhere|qualquer|todo|toda|todos|todas|tudo)\b/i
    LIMITS = 'Lexical atoms and fixed English or Portuguese labels and phrases only. A match is not an authority decision. ' \
             'Other languages, paraphrases outside the vocabulary, conditions, resource-to-action bindings, expiry, external records and the validity of grants need human review.'
    Segment = Data.define(:label, :body, :span)
    Clause = Data.define(:category, :body, :span, :negative)
    Atom = Data.define(:category, :name, :negative, :resource) do
      def key = %i[reserved prohibited].include?(category) ? [:restricted, name] : [category, name, negative]
      def text = "#{negative ? 'not ' : category == :reserved ? 'reserved ' : ''}#{name}"
    end

    def self.normalize(text)
      text.gsub(/\r\n?/, "\n").split(/(`[^`]*`|"[^"]*"|'[^']*')/).each_with_index.map do |part, index|
        index.odd? ? part : part.gsub(/[\s\u00a0]+/, ' ')
      end.join.strip.sub(/[.;]\z/, '').sub(/\A([`*]+)(.*?)\1\z/m, '\\2').strip
    end

    def self.read_text(path)
      File.open(path, File::RDONLY | File::NONBLOCK) do |file|
        raise IOError, "not a regular file: #{path}" unless file.stat.file?
        raise IOError, "input exceeds 64 KiB: #{path}" if file.stat.size > MAX_BYTES

        text = (file.read(MAX_BYTES + 1) || +'').force_encoding(Encoding::UTF_8)
        raise IOError, "input exceeds 64 KiB: #{path}" if text.bytesize > MAX_BYTES
        raise IOError, "invalid UTF-8: #{path}" unless text.valid_encoding?
        raise IOError, "NUL in input: #{path}" if text.include?("\0")

        text
      end
    end

    class Document
      attr_reader :text, :segments

      def initialize(text, readback: false)
        @text = text
        @readback = readback
        @segments = split_segments
      end

      def values(label)
        segments.select { |segment| segment.label == label && !segment.body.strip.empty? }
      end

      def identities
        found = values(:identity) + segments.select { |segment| segment.label.nil? }.flat_map do |segment|
          sentence_spans(segment.body).filter_map do |sentence|
            Segment.new(nil, sentence, sentence) if clean(sentence).match?(/\A(?:You are|I am|Sou|Eu sou) /i)
          end
        end
        if @readback && (opening = segments.first) && opening.label.nil?
          sentence = sentence_spans(opening.body).first
          found << Segment.new(nil, sentence.sub(/\A\[[^\]\n]+\]\s*/, ''), sentence) if sentence
        end
        found
      end

      def identity(field)
        pairs = values(field).filter_map do |segment|
          value = CompareReadback.normalize(clean(segment.body))
          value = address(value) if field == :address
          value = ROLES.fetch(value.downcase, value) if field == :role
          [value, segment.span] if value
        end
        identities.each do |segment|
          body = CompareReadback.normalize(clean(segment.body))
          if field == :address
            value = address(body)
          else
            role = body[/#{ADDRESS},?\s+(?:(?:the|role|o|a)\s+)?(#{ROLE})/i, 1]
            role ||= body[/\A(?:Sou|Eu sou|I am)\s+(?:(?:the|o|a)\s+)?(#{ROLE})/i, 1]
            value = ROLES.fetch(role.downcase) if role
          end
          pairs << [value, segment.span] if value
        end
        pairs
      end

      def labeled(field)
        values(field).map { |segment| [CompareReadback.normalize(clean(segment.body)), segment.span] }
      end

      def task(brief: false)
        return labeled(:task) unless brief

        segment = segments.find { |item| !item.body.strip.empty? && item.label != :other }
        return [] unless segment

        line = segment.body.lines.find { |item| !item.strip.empty? }
        line ? [[CompareReadback.normalize(clean(line)), line.strip]] : []
      end

      def next_action(waiting: false)
        pairs = labeled(:next_action)
        if pairs.empty?
          segments.select { |segment| !@readback || segment.label.nil? }.each do |segment|
            match = segment.body.match(WAIT)
            next unless match

            pairs << if @readback && waiting
                       [CompareReadback.normalize(clean(segment.body)), segment.span]
                     else
                       ['wait for confirmation', match[0]]
                     end
          end
        end
        pairs.map do |value, span|
          if !@readback || waiting
            candidate = values(:next_action).find { |segment| segment.span == span }
            examined = candidate ? candidate.span : value
            match = examined.match(WAIT)
            before = match ? examined[...match.begin(0)].sub(NEXT_LABEL_PREFIX, '') : ''
            valid = match && !examined.match?(NEGATED_WAIT) && !CompareReadback.act_names(before).any?
            value = 'wait for confirmation' if valid
          end
          [value, span]
        end
      end

      def sentences
        segments.flat_map { |segment| sentence_spans(segment.body) }
      end

      def authority
        clauses = []
        unknown = []
        outside = []
        segments.each do |segment|
          sentence_spans(segment.body).each do |sentence|
            body = CompareReadback.normalize(clean(sentence))
            next if body.empty?
            next if !@readback && body.match?(/\ABefore you (?:act|start)\b/i) && body.match?(WAIT)

            explicit_field = AUTHORITY_LABELS.include?(segment.label)
            recognized = explicit_field || segment.label.nil?
            if recognized && body.match?(RESERVATION) && body.match?(FIRST_PERSON)
              unknown << sentence
              next
            end
            parts = clause_spans(sentence)
            parts.each do |part|
              clause_body = CompareReadback.normalize(clean(part)).sub(CLAUSE_CONNECTOR, '').sub(/(?:[,;]\s*)?\b(?:and|but|mas|e)\s*\z/i, '')
              clause = authority_clause(clause_body, part, recognized ? segment.label : nil)
              if clause && (recognized || clause.negative || clause.category == :reserved)
                if clause.negative && clause.body.match?(CONTRAST) && CompareReadback.act_names(clause.body).any?
                  unknown << part
                else
                  clauses << clause
                end
              elsif explicit_field || clause_body.gsub(QUOTED_INLINE, '').match?(PERMISSION)
                unknown << part
              end
              outside << part unless explicit_field || (clause && (recognized || clause.negative || clause.category == :reserved))
            end
          end
        end
        [clauses, unknown, outside]
      end

      private

      def address(body)
        body[ADDRESS]&.delete_suffix('.')&.split('/')&.first
      end

      def clean(body)
        body.gsub(LINE_PREFIX, '').gsub(/\*\*/, '').strip
      end

      def label_parts(body)
        match = body.match(LABEL_START)
        return unless match

        tail_start = match.end(0)
        tail = body[tail_start..]
        return [LABEL_NAMES.fetch(match[1].downcase), body.length] if tail.strip.empty?

        delimiter = tail.match(LABEL_DELIMITER)
        return unless delimiter && tail[...delimiter.begin(0)].split.length <= 8

        value_start = tail_start + delimiter.end(0)
        value_start += body[value_start..][/\A(?:\*\*)?\s*/].length
        [LABEL_NAMES.fetch(match[1].downcase), value_start]
      end

      def split_segments
        result = []
        label = nil
        span_start = body_start = finish = nil
        heading = false
        fence = nil
        flush = lambda do
          if body_start && finish && !text[body_start...finish].strip.empty?
            result << Segment.new(label, text[body_start...finish].strip, text[span_start...finish].strip)
          end
          span_start = body_start = finish = nil
        end
        offset = 0
        text.each_line do |line|
          line_start = offset
          offset += line.length
          if fence
            fence = nil if line.match?(fence)
            next
          end
          if (marker = line.match(FENCE_START))
            flush.call
            fence = /^ {0,3}#{Regexp.escape(marker[1][0])}{#{marker[1].length},}[ \t]*\r?\n?\z/
            label = nil
            next
          end
          if line.match?(QUOTED_LINE)
            flush.call
            next
          end
          if line.strip.empty?
            unless AUTHORITY_LABELS.include?(label) || heading
              flush.call
              label = nil
            end
            finish = offset if body_start
            next
          end
          if (label == :redelegation && !line.match?(/\A[ \t]+/)) ||
             (label && !AUTHORITY_LABELS.include?(label) && line.lstrip.match?(MODAL_START))
            flush.call
            label = nil
          end
          prefix = line[LINE_PREFIX].to_s.length
          content_start = line_start + prefix
          content = text[content_start...offset]
          boundaries = [0]
          content.to_enum(:scan, LABEL_BOUNDARY).each { boundaries << Regexp.last_match.end(0) }
          boundaries << content.length
          boundaries.each_cons(2) do |left, right|
            chunk_start = content_start + left
            chunk = text[chunk_start...(content_start + right)]
            found, value_offset = label_parts(chunk.lstrip)
            chunk_start += chunk.length - chunk.lstrip.length
            if found
              flush.call
              label = found
              heading = line.match?(HEADING)
              span_start = line_start + left
              body_start = chunk_start + value_offset
            elsif content.match?(VERSION_LINE) || (line.match?(HEADING) && left.zero?)
              flush.call
              label = nil
              heading = false
              next
            elsif chunk.match?(UNKNOWN_LABEL) && !AUTHORITY_LABELS.include?(label)
              flush.call
              label = :unknown
              heading = false
            end
            span_start ||= chunk_start
            body_start ||= chunk_start
            finish = content_start + right
          end
        end
        flush.call
        result
      end

      def sentence_spans(body)
        ranges = [0]
        markers = body.to_enum(:scan, /^[ \t]*\d+\.[ \t]+/).map { Regexp.last_match.end(0) }.to_set
        body.to_enum(:scan, SENTENCE_BOUNDARY).each do
          position = Regexp.last_match.end(0)
          ranges << position unless markers.include?(position)
        end
        ranges << body.length
        ranges.each_cons(2).filter_map do |left, right|
          span = body[left...right].strip
          span unless span.empty?
        end
      end

      def clause_spans(sentence)
        boundaries = [0]
        masked = sentence.gsub(QUOTED_INLINE) { |part| ' ' * part.length }
        masked.to_enum(:scan, MODAL_ANYWHERE).each do
          position = Regexp.last_match.begin(0)
          boundaries << position unless position.zero?
        end
        sentence.to_enum(:scan, SHORT_MODAL_BOUNDARY).each { boundaries << Regexp.last_match.end(0) }
        boundaries << sentence.length
        boundaries.uniq.sort.each_cons(2).filter_map do |left, right|
          span = sentence[left...right].strip
          span unless clean(span).empty? || span.match?(/\A(?:\d+[.)]|[-*])\z/)
        end
      end

      def authority_clause(body, span, label)
        return Clause.new(:prohibited, body.sub(/\A(?:not|não)\s+/i, ''), span, true) if body.match?(/\A(?:not|não)\s+/i) && label != :redelegation
        if label == :redelegation
          return Clause.new(:redelegation, 'redelegate', span, true) if body.match?(REDELEGATION_NO)
          return nil unless body.match?(REDELEGATION_YES)
        end
        if (match = body.match(EN_CLAUSE))
          negative = match[1].downcase == 'cannot' || match[2].match?(/\Anot\b/i)
          value = match[2].sub(/\Anot\s+/i, '')
          return Clause.new(negative ? :prohibited : :grant, value, span, negative)
        end
        if (match = body.match(PT_CLAUSE))
          negative = !match[1].nil?
          return Clause.new(negative ? :prohibited : :grant, match[2], span, negative)
        end
        if (match = body.match(RESERVATION))
          return Clause.new(:reserved, match[1], span, false)
        end
        return Clause.new(label, body, span, false) if %i[grant reserved].include?(label)

        nil
      end
    end

    def self.path_name(value, quoted: false)
      value = value.sub(/(?<![.\/])[.!?]\z/, '') unless quoted
      return value unless value.include?('/')

      parts = []
      value.split('/').each_with_index do |part, index|
        next if part == '.' || (part.empty? && !index.zero?)

        if part == '..' && !parts.empty? && !['', '..', '~'].include?(parts.last) && !parts.last.start_with?('$')
          parts.pop
        elsif part == '..' && parts == ['']
          next
        else
          parts << part
        end
      end
      result = parts.join('/')
      result = '/' if result.empty? && value.start_with?('/')
      result.empty? ? '.' : result
    end

    def self.resources(body)
      names = []
      text = body.gsub(/([`"'])([^`"'\r\n]+)\1/) do |quoted|
        name = Regexp.last_match(2)
        if name.include?('/') || name.match?(/\A(?:~|\$[\w{}]+|[\p{L}\p{N}_. -]+\.[\p{L}\p{N}_-]+)\z/)
          names << path_name(name, quoted: true)
          ' ' * quoted.length
        else
          quoted
        end
      end
      [TRANSPORT, PATH].each do |pattern|
        text = text.gsub(pattern) do |value|
          names << path_name(value)
          ' ' * value.length
        end
      end
      [text, names]
    end

    def self.act_names(body)
      resources(body).first.scan(ACT).map { |value| WORDS.fetch(value.downcase) }
    end

    def self.atoms(clause)
      text, paths = resources(clause.body)
      names = paths.map { |name| [name, true] } + text.scan(ACT).map { |value| [WORDS.fetch(value.downcase), false] }
      names << ['redelegate', false] if clause.category == :redelegation && names.none? { |name, _| name == 'redelegate' }
      names.map do |name, resource|
        category = if !resource && name == 'redelegate'
                     :redelegation
                   elsif clause.category == :reserved
                     :reserved
                   else
                     clause.negative ? :prohibited : :grant
                   end
        Atom.new(category, name, clause.negative, resource)
      end
    end

    def self.sentence_key(span)
      normalize(span).downcase.gsub(/\b(?:you|your)\b/) { |word| word == 'you' ? 'i' : 'my' }
                     .gsub(/[,;:!?]/, ' ').gsub(/[\s\u00a0]+/, ' ').sub(/\.\z/, '').strip
    end

    def self.scope_words(clause)
      resources(clause.body).first.gsub(ACT, '').scan(SCOPE).map do |word|
        case word.downcase
        when 'all', 'todo', 'toda', 'todos', 'todas' then 'all'
        when 'any', 'qualquer' then 'any'
        when 'everything', 'tudo' then 'everything'
        else word.downcase
        end
      end.to_set
    end

    def self.field(record, readback, fold: false, contains: false)
      values = [record, readback].map { |pairs| pairs.map { |value, _span| fold ? value.downcase : value }.uniq }
      status = if values.any?(&:empty?)
                 'missing'
               elsif values.all? { |items| items.length == 1 } && (contains ? values[1][0].start_with?(values[0][0]) : values[0] == values[1])
                 'matched'
               else
                 'differs'
               end
      { 'status' => status, 'record' => record.map(&:last).uniq, 'readback' => readback.map(&:last).uniq }
    end

    def self.absolute_resource?(name)
      name.start_with?('/', '~', '$')
    end

    def self.within_path?(path, root)
      path == root || path.start_with?(root == '/' ? root : "#{root}/")
    end

    def self.authority(record, readback)
      sources = [record, readback].map(&:authority)
      expected_clauses, expected_unknown, = sources[0]
      actual_clauses, actual_unknown, outside = sources[1]
      record_sentences = record.sentences.map { |span| sentence_key(span) }.to_set
      readback_sentences = readback.sentences.map { |span| sentence_key(span) }.to_set
      actual_unknown = (actual_unknown + actual_clauses.select { |clause| atoms(clause).empty? }.map(&:span))
                       .reject { |span| record_sentences.include?(sentence_key(span)) }
      expected_unknown = (expected_unknown + expected_clauses.select { |clause| atoms(clause).empty? }.map(&:span))
                         .reject { |span| readback_sentences.include?(sentence_key(span)) }
      expected = expected_clauses.flat_map { |clause| atoms(clause) }.uniq(&:key)
      actual = actual_clauses.flat_map { |clause| atoms(clause) }.uniq(&:key)
      expected_keys = expected.map(&:key).to_set
      actual_keys = actual.map(&:key).to_set
      missing = expected.reject { |atom| actual_keys.include?(atom.key) }
      extra = actual.reject { |atom| expected_keys.include?(atom.key) }
      added = extra.select { |atom| %i[grant redelegation].include?(atom.category) && !atom.negative }.map(&:text)
      denied = extra.select { |atom| %i[prohibited reserved].include?(atom.category) || atom.negative }
      missing.concat(expected.select do |atom|
        %i[grant redelegation].include?(atom.category) && !atom.negative &&
          denied.any? { |restriction| restriction.name == atom.name && restriction.resource == atom.resource }
      end)
      grants = expected_clauses.select { |clause| !clause.negative && clause.category != :reserved }
      actual_clauses.each do |clause|
        next if clause.negative || clause.category == :reserved

        scopes = scope_words(clause)
        next if scopes.empty?

        keys = atoms(clause).map(&:key).to_set
        related = grants.select { |candidate| atoms(candidate).any? { |atom| keys.include?(atom.key) } }
        actual_unknown << clause.span unless related.any? { |candidate| scopes.subset?(scope_words(candidate)) }
      end
      granted_acts = expected.select { |atom| atom.category == :grant && !atom.resource }.map(&:name).to_set
      granted_acts << 'send' if granted_acts.include?('message')
      restricted = expected.select { |atom| atom.negative || atom.category == :reserved }.reject(&:resource).map(&:name).to_set - granted_acts
      grant_paths = Hash.new { |hash, key| hash[key] = [] }
      grants.each do |clause|
        clause_atoms = atoms(clause)
        paths = clause_atoms.select(&:resource).map(&:name).select { |name| absolute_resource?(name) }
        clause_atoms.reject(&:resource).each { |atom| grant_paths[atom.name].concat(paths) }
      end
      message_addresses = grants.flat_map do |clause|
        items = atoms(clause)
        items.any? { |atom| %w[message send].include?(atom.name) && !atom.resource } ? items.select(&:resource).map(&:name).select { |name| name.match?(TRANSPORT) } : []
      end.to_set
      outside.each do |span|
        next if record_sentences.include?(sentence_key(span))

        names = act_names(span)
        acts = names.select { |name| restricted.include?(name) }
        paths = resources(span).last.select { |name| absolute_resource?(name) }
        widened = names.select { |name| granted_acts.include?(name) }.flat_map do |name|
          paths.reject { |path| grant_paths[name].any? { |root| within_path?(path, root) } }
        end
        if (names & %w[message send]).any?
          widened.concat(span.scan(TRANSPORT).map { |name| path_name(name) }.reject { |name| message_addresses.include?(name) })
        end
        next if acts.empty? && widened.empty?

        added.concat(acts + widened)
        actual_unknown << span
      end
      added.concat(actual_unknown)
      status = if sources.any? { |clauses, other, _| clauses.empty? && other.empty? }
                 'missing'
               elsif !expected_unknown.empty? || !actual_unknown.empty? || !missing.empty? || !added.empty?
                 'differs'
               else
                 'matched'
               end
      spans = sources.map { |clauses, other, _| (clauses.map(&:span) + other).uniq }
      spans[1] = (spans[1] + actual_unknown).uniq
      [{ 'status' => status, 'record' => spans[0], 'readback' => spans[1] }, added.uniq, missing.map(&:text).uniq]
    end

    def self.compare(record:, readback:, brief: nil)
      expected = Document.new(record)
      actual = Document.new(readback, readback: true)
      authority_field, added, missing = authority(expected, actual)
      next_action = expected.next_action
      waiting = next_action.map(&:first).uniq == ['wait for confirmation']
      fields = {
        'address' => field(expected.identity(:address), actual.identity(:address)),
        'role' => field(expected.identity(:role), actual.identity(:role), fold: true),
        'task' => field(brief ? Document.new(brief).task(brief: true) : expected.task, actual.task, contains: !brief.nil?),
        'authority' => authority_field,
        'next_action' => field(next_action, actual.next_action(waiting: waiting))
      }
      versions = record.scan(/\bnomos (v\d+(?:\.\d+)*)\b/i).flatten.uniq
      { 'fields' => fields, 'authority_added' => added, 'authority_missing' => missing,
        'version' => versions.length == 1 ? versions.first : nil, 'limits' => LIMITS }
    end

    class Runner
      def initialize(output: $stdout, error: $stderr)
        @output = output
        @error = error
      end

      def run(argv)
        values = {}
        parser = OptionParser.new do |options|
          options.banner = 'Usage: compare-readback.rb --record FILE --readback FILE [--brief FILE] [--json]'
          %w[record readback brief].each do |name|
            options.on("--#{name} FILE") { |value| assign(values, name, value) }
          end
          options.on('--json') { assign(values, 'json', true) }
          options.on('-h', '--help') { @output.puts options; return 0 }
        end
        parser.parse!(argv)
        raise ArgumentError, parser.banner unless argv.empty? && values['record'] && values['readback']

        result = CompareReadback.compare(record: CompareReadback.read_text(values['record']),
                                        readback: CompareReadback.read_text(values['readback']),
                                        brief: values['brief'] && CompareReadback.read_text(values['brief']))
        if values['json']
          @output.puts JSON.generate(result)
        else
          result.fetch('fields').each { |name, entry| @output.puts "#{name}: #{JSON.generate(entry)}" }
          result.reject { |name, _| name == 'fields' }.each { |name, entry| @output.puts "#{name}: #{JSON.generate(entry)}" }
        end
        result.fetch('fields').values.all? { |entry| entry.fetch('status') == 'matched' } &&
          result.fetch('authority_added').empty? && result.fetch('authority_missing').empty? ? 0 : 1
      rescue OptionParser::ParseError, ArgumentError, IOError, SystemCallError => error
        @error.puts "NOMOS readback comparison could not run: #{error.message}"
        2
      end

      private

      def assign(values, name, value)
        raise ArgumentError, "duplicate option --#{name}" if values.key?(name)

        values[name] = value
      end
    end
  end
end

exit Nomos::CompareReadback::Runner.new.run(ARGV) if $PROGRAM_NAME == __FILE__
