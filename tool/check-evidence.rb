# frozen_string_literal: true

require 'find'
require 'set'

class EvidenceChecker
  ID_PATTERN = /\b(?:S-N|[A-Z]{1,2})[0-9]{2}\b/
  LOG_HEADING = '## Incidents of the nomos run (LOG)'

  def initialize
    @evidence = read_text('evidence.md')
    harness = read_text('harness-notes.md')
    paths = []
    Find.find('.') do |path|
      next if path == '.'
      Find.prune if File.basename(path).start_with?('.')
      paths << path.delete_prefix('./') if path.end_with?('.md') && File.basename(path) != 'evidence.md'
    end
    @files = paths.sort.to_h { |path| [path, read_text(path)] }
    abort 'No citing documents found' if @files.empty?

    @definitions = @evidence.scan(/^\*\*((?:S-N|[A-Z]{1,2})[0-9]{2})\./).flatten.to_set
    @definitions.merge(harness.scan(/^\*\*(HN[0-9]{2})\./).flatten)
    @definitions.merge(@evidence.scan(/^\*\*(Ruling [0-9]+)\./).flatten)
    @families = @definitions.map { |item| item.sub(/[0-9]+\z/, '') }.to_set
    @log = @evidence.split(LOG_HEADING, 2).last.to_s.split('## Decisions, requirements and rulings', 2).first.to_s
    @entries = []
    @log.scan(/^(?:### (.+)|\*\*(.+?)\.\*\*)/) do |heading, bold|
      match = Regexp.last_match
      title = normalize(heading || bold).sub(/\Alog,\s*/, '')
      @entries << [title, match.begin(0), match.end(0)] if title.match?(/\A(?:\d|field |acceptance |benchmark )/)
    end
  end

  def run
    errors = Set.new
    citation_count = 0
    @files.each do |path, text|
      text.scan(/#{ID_PATTERN}|\bruling [0-9]+\b/i) do |item|
        match = Regexp.last_match
        if item.downcase.start_with?('ruling ')
          item = "Ruling #{item.split[1]}"
        elsif item != item.upcase
          next
        end
        citation_count += 1
        next if @definitions.include?(item)

        family = item.sub(/[0-9]+\z/, '')
        kind = @families.include?(family) ? 'Unresolved evidence citation' : 'Unknown evidence family'
        errors << "#{path}:#{line_number(text, match.begin(0))}: #{kind}: #{item}"
      end
      text.scan(/(#{ID_PATTERN}) to (#{ID_PATTERN})/) do |first, last|
        prefix = first[...-2]
        if prefix != last[...-2] || first[-2..].to_i > last[-2..].to_i
          errors << "#{path}: Invalid range #{first} to #{last}"
          next
        end
        (first[-2..].to_i..last[-2..].to_i).each do |number|
          item = format('%s%02d', prefix, number)
          errors << "#{path}: Unresolved evidence citation: #{item}" unless @definitions.include?(item)
        end
      end
      if text.match?(/\bLOG\b/)
        citation_count += 1
        errors << "#{path}: Unresolved evidence citation: LOG" unless @evidence.include?(LOG_HEADING)
      end
      text.scan(/\bLOG,\s*((?:(?!\n\s*\n)[^;)|.])+)/) do |label|
        match = Regexp.last_match
        label = label.first.gsub(/\n\s*>?\s*/, ' ').strip
        unless resolves?(label)
          errors << "#{path}:#{line_number(text, match.begin(0))}: Unresolved evidence citation: LOG, #{label}"
        end
      end
    end
    errors << 'No evidence citations found' if citation_count.zero?
    puts errors.sort
    errors.empty? ? 0 : 1
  end

  private

  def read_text(path)
    File.read(path, encoding: 'UTF-8').gsub(/\r\n?/, "\n")
  rescue SystemCallError => error
    abort "[Errno #{error.errno}] #{SystemCallError.new(error.errno).message}: '#{path}'"
  end

  def normalize(text)
    text.gsub(/\bUTC(?:[+-][0-9]+)?\b/i, '')
        .gsub(/\babout\s+/i, '')
        .gsub(/\s+,/, ',')
        .gsub('**', '').tr('>', ' ')
        .gsub(/\s+/, ' ').gsub(/\A[ .,]+|[ .,]+\z/, '').downcase
  end

  def line_number(text, offset)
    text[...offset].count("\n") + 1
  end

  def resolves?(label, dates = [])
    label = normalize(label).sub(/, (?:s-n|[a-z]{1,2})[0-9]{2}\z/, '')
    if label == "2026-10-23, 02:52 and 04:05, and 08:05, orchestrator digest, plus the first acceptance test's stumbles 4 and 6"
      return ['2026-10-23 02:52 and 04:05', '2026-10-23 08:05, orchestrator digest',
              'acceptance 1, stumble 4', 'acceptance 1, stumble 6'].all? { |item| resolves?(item) }
    end
    return @definitions.include?(label.upcase) if label.match?(/\AN[0-9]{2}\z/i)
    if label == 'field pr 22 and audits of fde5548'
      return resolves?('field pr 22') && resolves?('field audits of fde5548')
    end
    if label.start_with?('acceptance ')
      dates += label.scan(/, (\d{4}-\d{2}-\d{2})(?=,|\z)/).flatten
      label = label.gsub(/, \d{4}-\d{2}-\d{2}(?=,|\z)/, '')
      plural = /\A(acceptance \d+), stumbles (\d+) and (\d+)\z/.match(label)
      return plural.captures.drop(1).all? { |number| resolves?("#{plural[1]}, stumble #{number}", dates) } if plural
    end
    @entries.each_with_index do |(title, _start, finish), index|
      next unless dates.all? { |date| date == title[/\b\d{4}-\d{2}-\d{2}\b/] }

      key = title
      if label.start_with?('acceptance ')
        key = key.sub(/\A\d{4}-\d{2}-\d{2}, /, '').sub(/, \d{4}-\d{2}-\d{2}.*\z/, '')
      end
      return true if key == label || key.start_with?(label + ',', label + ' ')

      if label.start_with?('field ', 'acceptance ')
        base, _, detail = label.partition(', ')
        next unless key == base || key.start_with?(base + ',')

        stop = @entries[index + 1]&.[](1) || @log.length
        labels = @log[finish...stop].scan(/^(?:- ([^.]+)\.|\*\*([^*]+)\.\*\*)/)
                     .map { |a, b| normalize(a || b) }.to_set
        return true if labels.include?(detail)
        return true if detail.include?(' and ') && detail.split(' and ').all? { |part| labels.include?(part) }
      end
      dated = /\A(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2})(, .+)?\z/.match(label)
      if dated && key.start_with?(dated[1] + ' ') && key.match?(/(?<!\d)#{dated[2]}(?!\d)/)
        return true if !dated[3] || key.end_with?(dated[3])
      end
      return true if label.match?(/\A\d{2}:\d{2}/) && key.match?(/(?<!\d)#{Regexp.escape(label)}(?!\d)/)
    end
    false
  end
end

Dir.chdir(File.expand_path('..', __dir__)) do
  exit EvidenceChecker.new.run
end
