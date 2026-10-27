#!/usr/bin/env ruby

require 'json'
require 'optparse'
require 'set'

module Nomos
  module CompareReadback
    MAX_BYTES = 65_536
    ADDRESS = /[A-Za-z0-9_-]+\.[A-Za-z0-9_.-]+@[A-Za-z0-9_.-]+(?:\/[A-Za-z0-9_-]+)?/
    TRANSPORT = /(?<![A-Za-z0-9_.@-])[A-Za-z0-9_.-]+@[A-Za-z0-9_.-]+(?:\/[A-Za-z0-9_-]+)?/
    ROLES = %w[orchestrator implementer reviewer writer qa auditor].to_h { |role| [role, role] }.freeze
    LABELS = {
      address: ['address'], role: ['role'], identity: ['address and role', 'delegate'], task: ['task', 'my task'],
      authority: ['authority', 'my authority'], next_action: ['next action', 'my next action'],
      other: ['principal', 'delegator', 'duration', 'change authority'], grant: ['actions and resources granted'],
      reserved: ['decisions reserved to the principal'], redelegation: ['redelegation']
    }.freeze
    ACTS = {
      'read' => %w[read reading], 'edit' => %w[edit editing], 'create' => %w[create creating],
      'remove' => %w[remove removing], 'write' => %w[write writing], 'run' => %w[run running],
      'message' => %w[message messaging], 'commit' => %w[commit commits committing], 'push' => %w[push pushes pushing],
      'publish' => %w[publish publishing publication], 'merge' => %w[merge merging], 'delete' => %w[delete deleting],
      'deploy' => %w[deploy deploying], 'install' => %w[install installs installing],
      'configure' => %w[configure configuring], 'settings' => %w[settings],
      'off this machine' => ['off this machine', 'leaves this machine'], 'redelegate' => %w[redelegate redelegating grant],
      'open' => %w[open], 'update' => %w[update], 'tag' => %w[tag tags], 'change' => %w[change],
      'delegate' => %w[delegate delegating], 'spawn' => %w[spawn spawning], 'send' => %w[send sending],
      'email' => %w[email emailing], 'post' => %w[post posting], 'approve' => %w[approve approving], 'share' => %w[share sharing]
    }.freeze
    WORDS = ACTS.flat_map { |name, words| words.map { |word| [word, name] } }.to_h.freeze
    SCOPES = %w[any all anywhere everything everywhere].to_h { |word| [word, word] }.freeze
    PATH = /(?<![\p{L}\p{N}_@.:\/$])(?:(?:\$\{[A-Za-z_][A-Za-z0-9_]*\}|\$[A-Za-z_][A-Za-z0-9_]*|~)(?:\/[^\s,;"'`<>\[\]{}()]*)?|(?:\/|\.\.?\/|[\p{L}\p{N}_.-]+\/)[^\s,;"'`<>\[\]{}()]*|[\p{L}\p{N}_-][\p{L}\p{N}_.-]*\.[\p{L}\p{N}_-]+)/
    AUTHORITY_LABELS = %i[authority grant reserved redelegation].freeze
    LINE_PREFIX = /^[ \t]*(?:(?:\#{1,6}|[-*]|\d+[.)])[ \t]+)?/
    FENCE_START = /^ {0,3}(`{3,}|~{3,})/
    HEADING = /^\s*\#{1,6}\s+/
    QUOTED_LINE = /^\s*>/
    VERSION_LINE = /\A\s*nomos v\d+\b/i
    UNKNOWN_LABEL = /\A[\p{L}][\p{L} ]{0,60}:/
    EN_CLAUSE = /\A(?:(?:As the [\w-]+ )?(?:you|I)\s+)?(may|can|cannot)\s+(.*)\z/i
    QUOTED_INLINE = /([`"])[^`"\r\n]*\1/
    PERSON = { 'you' => 'i', 'your' => 'my', 'yourself' => 'myself', 'yours' => 'mine' }.freeze
    LIMITS = 'Lexical atoms and fixed labels and phrases only, English built in plus any vocabulary given with --words. ' \
             'A match is not an authority decision. Languages without a vocabulary, paraphrases outside the vocabulary, conditions, ' \
             'resource-to-action bindings, expiry, external records and the validity of grants need human review.'
    Segment = Data.define(:label, :body, :span)
    Clause = Data.define(:category, :body, :span, :negative)
    Atom = Data.define(:category, :name, :negative, :resource) do
      def key = %i[reserved prohibited].include?(category) ? [:restricted, name] : [category, name, negative]
      def text = "#{negative ? 'not ' : category == :reserved ? 'reserved ' : ''}#{name}"
    end

    # The words the comparator reads, English built in plus the sections of --words files.
    class Vocabulary
      LABEL_SECTIONS = {
        'label-address' => :address, 'label-role' => :role, 'label-identity' => :identity, 'label-task' => :task,
        'label-authority' => :authority, 'label-next-action' => :next_action, 'label-redelegation' => :redelegation
      }.freeze
      MAPPED = { 'roles' => ROLES, 'acts' => WORDS, 'scope' => SCOPES }.freeze
      SECTIONS = [*LABEL_SECTIONS.keys, *MAPPED.keys, 'grant', 'reserved', 'negation', 'wait-negation', 'auxiliary',
                  'wait', 'wait-verb', 'first-person', 'possessive', 'contrast', 'conjunction', 'copula', 'identity',
                  'article', 'permission', 'redelegation-no', 'redelegation-yes'].freeze
      PARTY = '(?:[\p{L}\p{N}_.@-]+\s+){0,7}[\p{L}\p{N}_.@-]+'

      attr_reader :roles, :words, :scopes, :label_names, :role, :label, :label_start, :label_delimiter, :label_boundary,
                  :next_label_prefix, :act, :modal_anywhere, :modal_start, :wait, :negated_wait, :sentence_boundary,
                  :short_modal_boundary, :clause_connector, :trailing_connector, :clause_negation, :grant_clause,
                  :reservation, :first_person, :redelegation_no, :redelegation_yes, :contrast, :permission, :scope,
                  :opening, :role_after_address, :role_after_opening, :role_head

      def self.empty = SECTIONS.to_h { |name| [name, MAPPED.key?(name) ? {} : []] }

      # Adds the sections of one --words file's lines to sections; a phrase before any header is an error.
      def self.parse(lines, sections = empty)
        current = nil
        lines.each do |line|
          text = line.strip
          next if text.empty? || text.start_with?('#')

          if (header = text[/\A\[([a-z-]+)\]\z/, 1])
            raise ArgumentError, "unknown --words section [#{header}]" unless sections.key?(header)

            current = header
          elsif current.nil?
            raise ArgumentError, "--words phrase before any [section]: #{text}"
          elsif MAPPED.key?(current)
            phrase, canonical = text.split(/\s+=\s+/, 2)
            raise ArgumentError, "[#{current}] needs 'phrase = canonical': #{text}" unless canonical && !phrase.empty?
            raise ArgumentError, "unknown canonical name in [#{current}]: #{canonical}" unless MAPPED[current].value?(canonical)

            sections[current][key(phrase)] = canonical
          else
            raise ArgumentError, "[reserved] needs one {party}: #{text}" if current == 'reserved' && text.scan('{party}').length != 1

            sections[current] << text
          end
        end
        sections
      end

      def self.load(paths) = new(paths.each_with_object(empty) { |path, sections| parse(CompareReadback.read_text(path).lines, sections) })
      def self.key(phrase) = phrase.downcase.gsub(/\s+/, ' ')
      def self.alternation(phrases) = phrases.uniq.sort_by { |phrase| -phrase.length }.map { |phrase| Regexp.escape(phrase).gsub('\\ ', '\\s+') }.join('|')

      def initialize(sections = {})
        list = ->(name) { Array(sections[name]) }
        any = ->(english, name) { Vocabulary.alternation(english + list[name]) }
        @roles = ROLES.merge(sections.fetch('roles', {}))
        @words = WORDS.merge(sections.fetch('acts', {}))
        @scopes = SCOPES.merge(sections.fetch('scope', {}))
        @label_names = LABELS.flat_map { |label, names| names.map { |name| [name, label] } }.to_h
        LABEL_SECTIONS.each { |name, label| list[name].each { |phrase| @label_names[Vocabulary.key(phrase)] = label } }
        @label_names.freeze
        negation = any[['not'], 'negation']
        conjunction = any[%w[and but], 'conjunction']
        grants = list['grant']
        identity = any[['I am'], 'identity']
        @role = /(?:#{Vocabulary.alternation(@roles.keys)})(?![\p{L}\p{N}_-])/i
        @label = /(?:#{Vocabulary.alternation(@label_names.keys)})(?![\p{L}\p{N}_])/i
        @label_start = /\A(?:\*\*)?(#{@label})(?:\*\*)?/i
        @label_delimiter = /:|\.(?=\s|\z)|(?<!\p{L})(?:#{any[['is'], 'copula']})(?!\p{L})/i
        @label_boundary = /(?<=[.!?])\s+(?=(?:\*\*)?#{@label})/i
        next_labels = @label_names.select { |_, label| label == :next_action }.keys
        @next_label_prefix = /\A(?:\*\*)?(?:#{Vocabulary.alternation(next_labels)})\b[\s:*]*/i
        @act = /(?<![\p{L}\p{N}_])(?:#{Vocabulary.alternation(@words.keys)})(?![\p{L}\p{N}_])/i
        modals = ['(?:As the [\w-]+ )?(?:you|I)\s+(?:may|can|cannot)\b']
        modals << "(?:(?:#{negation})\\s+)?(?:#{Vocabulary.alternation(grants)})\\b" unless grants.empty?
        @modal_anywhere = /(?<![\p{L}\p{N}_])(?:#{modals.join('|')})/i
        @modal_start = /\A#{@modal_anywhere}/i
        waits = ["wait for (?:(?:(?:its|your)|#{PARTY}['’]s) )?confirmation", 'wait for your \[accept\]', 'after confirmation',
                 "wait for #{PARTY} to confirm"]
        waits << Vocabulary.alternation(list['wait']) unless list['wait'].empty?
        @wait = /\b(?:#{waits.join('|')})(?!\p{L})/i
        wait_negation = Vocabulary.alternation(%w[not never without] + list['negation'] + list['wait-negation'])
        @negated_wait = /\b(?:(?:#{wait_negation})\s+(?:(?:#{any[%w[will be], 'auxiliary']})\s+){0,3}(?:#{any[%w[wait waiting], 'wait-verb']})|(?:#{any[['do not'], 'negation']})\s+#{@wait})/i
        templates = list['reserved'].map { |template| template.split('{party}', 2).map(&:strip) }
        heads = templates.filter_map { |prefix, _| prefix.split.first }
        @sentence_boundary = /(?<=[.!?;])\s+(?=[\p{L}*#\[\d-]|\z)|(?<=;)\s*|\r?\n(?=[ \t]*(?:(?:[-*]|\d+[.)])\s+|#{@modal_anywhere}|(?:#{Vocabulary.alternation(['Reserved'] + heads)})\b))/i
        @short_modal_boundary = /\s+(?:#{conjunction})\s+(?=(?:#{Vocabulary.alternation(%w[may can cannot])}|#{negation})\b)/i
        @clause_connector = /(?:\A(?:#{conjunction})\s+|[,;]\s*\z)/i
        @trailing_connector = /(?:[,;]\s*)?\b(?:#{conjunction})\s*\z/i
        @clause_negation = /\A(?:#{negation})\s+/i
        @grant_clause = (/\A((?:#{negation})\s+)?(?:#{Vocabulary.alternation(grants)})\s+(.*)\z/i unless grants.empty?)
        reservations = ["Reserved to (?:[\\p{L}\\p{N}_.@-]+\\s+){1,8}are"] + templates.map do |prefix, suffix|
          [prefix.empty? ? nil : "#{Vocabulary.alternation([prefix])}\\s+", PARTY,
           suffix.empty? ? nil : "\\s+#{Vocabulary.alternation([suffix])}", '\s*:?'].join
        end
        @reservation = /\A(?:#{reservations.join('|')})\s+(.*)\z/i
        @first_person = /\b(?:#{any[%w[I me], 'first-person']})\b|\b(?:#{any[%w[mine my], 'possessive']})(?=\s*(?:[,;.!?]|\z))/i
        @redelegation_no = /\A(?:none|no|not allowed|(?:I )?may not(?: redelegate)?|not redelegate#{list['redelegation-no'].empty? ? '' : "|#{Vocabulary.alternation(list['redelegation-no'])}"})\z/i
        @redelegation_yes = /\A(?:#{any[['I may redelegate'], 'redelegation-yes']})\b/i
        @contrast = /\b(?:#{any[%w[but only except], 'contrast']})\b/i
        permissions = ['(?:I|you) (?:may|can|am allowed|have permission)', 'not\s+(?:publish|merge)', 'I am authorized']
        permissions << Vocabulary.alternation(list['permission']) unless list['permission'].empty?
        @permission = /\b(?:#{permissions.join('|')})\b/i
        @scope = /\b(?:#{Vocabulary.alternation(@scopes.keys)})\b/i
        @opening = /\A(?:You are|#{identity}) /i
        @role_after_address = /#{ADDRESS},?\s+(?:(?:#{any[%w[the role], 'article']})\s+)?(#{@role})/i
        @role_after_opening = /\A(?:#{identity})\s+(?:(?:#{any[['the'], 'article']})\s+)?(#{@role})/i
        @role_head = /\A(?:(?:#{any[['the'], 'article']})\s+)?(#{@role})/i
        freeze
      end

      def role_name(text) = roles.fetch(Vocabulary.key(text))
      def act_name(text) = words.fetch(Vocabulary.key(text))
      def label_name(text) = label_names.fetch(Vocabulary.key(text))
      def scope_name(text) = scopes.fetch(Vocabulary.key(text))

      ENGLISH = new
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

      def initialize(text, readback: false, vocabulary: Vocabulary::ENGLISH)
        @text = text
        @readback = readback
        @vocabulary = vocabulary
        @segments = split_segments
      end

      def values(label)
        segments.select { |segment| segment.label == label && !segment.body.strip.empty? }
      end

      def identities
        found = values(:identity) + segments.select { |segment| segment.label.nil? }.flat_map do |segment|
          sentence_spans(segment.body).filter_map do |sentence|
            Segment.new(nil, sentence, sentence) if clean(sentence).match?(@vocabulary.opening)
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
          value = role_value(value) if field == :role
          [value, segment.span] if value
        end
        identities.each do |segment|
          body = CompareReadback.normalize(clean(segment.body))
          if field == :address
            value = address(body)
          else
            role = body[@vocabulary.role_after_address, 1] || body[@vocabulary.role_after_opening, 1]
            value = @vocabulary.role_name(role) if role
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
            match = segment.body.match(@vocabulary.wait)
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
            match = examined.match(@vocabulary.wait)
            before = match ? examined[...match.begin(0)].sub(@vocabulary.next_label_prefix, '') : ''
            valid = match && !examined.match?(@vocabulary.negated_wait) && !CompareReadback.act_names(before, @vocabulary).any?
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
            next if !@readback && body.match?(/\ABefore you (?:act|start)\b/i) && body.match?(@vocabulary.wait)

            explicit_field = AUTHORITY_LABELS.include?(segment.label)
            recognized = explicit_field || segment.label.nil?
            if recognized && body.match?(@vocabulary.reservation) && body.match?(@vocabulary.first_person)
              unknown << sentence
              next
            end
            parts = clause_spans(sentence)
            parts.each do |part|
              clause_body = CompareReadback.normalize(clean(part)).sub(@vocabulary.clause_connector, '').sub(@vocabulary.trailing_connector, '')
              clause = authority_clause(clause_body, part, recognized ? segment.label : nil)
              if clause && (recognized || clause.negative || clause.category == :reserved)
                if clause.negative && clause.body.match?(@vocabulary.contrast) && CompareReadback.act_names(clause.body, @vocabulary).any?
                  unknown << part
                else
                  clauses << clause
                end
              elsif explicit_field || clause_body.gsub(QUOTED_INLINE, '').match?(@vocabulary.permission)
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

      def role_value(value)
        head = value[/\A[^,;(]*/]
        match = head.match(@vocabulary.role_head)
        return @vocabulary.roles.fetch(Vocabulary.key(value), value) unless match && head.scan(/(?<![\p{L}\p{N}_-])#{@vocabulary.role}/).length == 1

        @vocabulary.role_name(match[1])
      end

      def label_parts(body)
        match = body.match(@vocabulary.label_start)
        return unless match

        tail_start = match.end(0)
        tail = body[tail_start..]
        return [@vocabulary.label_name(match[1]), body.length] if tail.strip.empty?

        delimiter = tail.match(@vocabulary.label_delimiter)
        return unless delimiter && tail[...delimiter.begin(0)].split.length <= 8

        value_start = tail_start + delimiter.end(0)
        value_start += body[value_start..][/\A(?:\*\*)?\s*/].length
        [@vocabulary.label_name(match[1]), value_start]
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
             (label && !AUTHORITY_LABELS.include?(label) && line.lstrip.match?(@vocabulary.modal_start))
            flush.call
            label = nil
          end
          prefix = line[LINE_PREFIX].to_s.length
          content_start = line_start + prefix
          content = text[content_start...offset]
          boundaries = [0]
          content.to_enum(:scan, @vocabulary.label_boundary).each { boundaries << Regexp.last_match.end(0) }
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
        body.to_enum(:scan, @vocabulary.sentence_boundary).each do
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
        masked.to_enum(:scan, @vocabulary.modal_anywhere).each do
          position = Regexp.last_match.begin(0)
          boundaries << position unless position.zero?
        end
        sentence.to_enum(:scan, @vocabulary.short_modal_boundary).each { boundaries << Regexp.last_match.end(0) }
        boundaries << sentence.length
        boundaries.uniq.sort.each_cons(2).filter_map do |left, right|
          span = sentence[left...right].strip
          span unless clean(span).empty? || span.match?(/\A(?:\d+[.)]|[-*])\z/)
        end
      end

      def authority_clause(body, span, label)
        negation = @vocabulary.clause_negation
        return Clause.new(:prohibited, body.sub(negation, ''), span, true) if body.match?(negation) && label != :redelegation
        if label == :redelegation
          return Clause.new(:redelegation, 'redelegate', span, true) if body.match?(@vocabulary.redelegation_no)
          return nil unless body.match?(@vocabulary.redelegation_yes)
        end
        if (match = body.match(EN_CLAUSE))
          negative = match[1].downcase == 'cannot' || match[2].match?(/\Anot\b/i)
          value = match[2].sub(/\Anot\s+/i, '')
          return Clause.new(negative ? :prohibited : :grant, value, span, negative)
        end
        if @vocabulary.grant_clause && (match = body.match(@vocabulary.grant_clause))
          negative = !match[1].nil?
          return Clause.new(negative ? :prohibited : :grant, match[2], span, negative)
        end
        if (match = body.match(@vocabulary.reservation))
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

    def self.act_names(body, vocabulary = Vocabulary::ENGLISH)
      resources(body).first.scan(vocabulary.act).map { |value| vocabulary.act_name(value) }
    end

    def self.atoms(clause, vocabulary = Vocabulary::ENGLISH)
      text, paths = resources(clause.body)
      names = paths.map { |name| [name, true] } + text.scan(vocabulary.act).map { |value| [vocabulary.act_name(value), false] }
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
      normalize(span).downcase.gsub(/\b(?:you|your|yourself|yours)\b/, PERSON)
                     .gsub(/[,;:!?]/, ' ').gsub(/[\s\u00a0]+/, ' ').sub(/\.\z/, '').strip
    end

    def self.scope_words(clause, vocabulary = Vocabulary::ENGLISH)
      resources(clause.body).first.gsub(vocabulary.act, '').scan(vocabulary.scope).map { |word| vocabulary.scope_name(word) }.to_set
    end

    def self.task_remainder(span, sources)
      text = normalize(span.gsub(/\*\*/, ''))
      sources.each do |source|
        next if source.empty?
        return text[source.length..] if text.start_with?(source)
        return '' if source.start_with?(text)
      end
      span
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

    def self.authority(record, readback, vocabulary = Vocabulary::ENGLISH, task_sources: [])
      atoms_of = ->(clause) { atoms(clause, vocabulary) }
      scopes_of = ->(clause) { scope_words(clause, vocabulary) }
      sources = [record, readback].map(&:authority)
      expected_clauses, expected_unknown, = sources[0]
      actual_clauses, actual_unknown, outside = sources[1]
      record_sentences = record.sentences.map { |span| sentence_key(span) }.to_set
      readback_sentences = readback.sentences.map { |span| sentence_key(span) }.to_set
      actual_unknown = (actual_unknown + actual_clauses.select { |clause| atoms_of[clause].empty? }.map(&:span))
                       .reject { |span| record_sentences.include?(sentence_key(span)) }
      expected_unknown = (expected_unknown + expected_clauses.select { |clause| atoms_of[clause].empty? }.map(&:span))
                         .reject { |span| readback_sentences.include?(sentence_key(span)) }
      expected = expected_clauses.flat_map { |clause| atoms_of[clause] }.uniq(&:key)
      actual = actual_clauses.flat_map { |clause| atoms_of[clause] }.uniq(&:key)
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

        scopes = scopes_of[clause]
        next if scopes.empty?

        keys = atoms_of[clause].map(&:key).to_set
        related = grants.select { |candidate| atoms_of[candidate].any? { |atom| keys.include?(atom.key) } }
        actual_unknown << clause.span unless related.any? { |candidate| scopes.subset?(scopes_of[candidate]) }
      end
      granted_acts = expected.select { |atom| atom.category == :grant && !atom.resource }.map(&:name).to_set
      granted_acts << 'send' if granted_acts.include?('message')
      restricted = expected.select { |atom| atom.negative || atom.category == :reserved }.reject(&:resource).map(&:name).to_set - granted_acts
      grant_paths = Hash.new { |hash, key| hash[key] = [] }
      grants.each do |clause|
        clause_atoms = atoms_of[clause]
        paths = clause_atoms.select(&:resource).map(&:name).select { |name| absolute_resource?(name) }
        clause_atoms.reject(&:resource).each { |atom| grant_paths[atom.name].concat(paths) }
      end
      grant_paths['send'].concat(grant_paths['message'])
      message_addresses = grants.flat_map do |clause|
        items = atoms_of[clause]
        items.any? { |atom| %w[message send].include?(atom.name) && !atom.resource } ? items.select(&:resource).map(&:name).select { |name| name.match?(TRANSPORT) } : []
      end.to_set
      task_bodies = readback.values(:task).map(&:body)
      outside.each do |span|
        next if record_sentences.include?(sentence_key(span))

        scanned = task_bodies.any? { |body| body.include?(span) } ? task_remainder(span, task_sources) : span
        names = act_names(scanned, vocabulary)
        acts = names.select { |name| restricted.include?(name) }
        paths = resources(scanned).last.select { |name| absolute_resource?(name) }
        widened = names.select { |name| granted_acts.include?(name) }.flat_map do |name|
          paths.reject { |path| grant_paths[name].any? { |root| within_path?(path, root) } }
        end
        if (names & %w[message send]).any?
          widened.concat(scanned.scan(TRANSPORT).map { |name| path_name(name) }.reject { |name| message_addresses.include?(name) })
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

    def self.compare(record:, readback:, brief: nil, vocabulary: Vocabulary::ENGLISH)
      expected = Document.new(record, vocabulary: vocabulary)
      actual = Document.new(readback, readback: true, vocabulary: vocabulary)
      task = brief ? Document.new(brief, vocabulary: vocabulary).task(brief: true) : expected.task
      authority_field, added, missing = authority(expected, actual, vocabulary, task_sources: task.map(&:first))
      next_action = expected.next_action
      waiting = next_action.map(&:first).uniq == ['wait for confirmation']
      fields = {
        'address' => field(expected.identity(:address), actual.identity(:address)),
        'role' => field(expected.identity(:role), actual.identity(:role), fold: true),
        'task' => field(task, actual.task, contains: !brief.nil?),
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
        words = []
        parser = OptionParser.new do |options|
          options.banner = 'Usage: compare-readback.rb --record FILE --readback FILE [--brief FILE] [--words FILE]... [--json]'
          %w[record readback brief].each do |name|
            options.on("--#{name} FILE") { |value| assign(values, name, value) }
          end
          options.on('--words FILE') { |value| words << value }
          options.on('--json') { assign(values, 'json', true) }
          options.on('-h', '--help') { @output.puts options; return 0 }
        end
        parser.parse!(argv)
        raise ArgumentError, parser.banner unless argv.empty? && values['record'] && values['readback']

        vocabulary = words.empty? ? Vocabulary::ENGLISH : Vocabulary.load(words)
        result = CompareReadback.compare(record: CompareReadback.read_text(values['record']),
                                        readback: CompareReadback.read_text(values['readback']),
                                        brief: values['brief'] && CompareReadback.read_text(values['brief']),
                                        vocabulary: vocabulary)
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
