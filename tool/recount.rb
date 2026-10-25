# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'open3'
require 'optparse'
require 'pathname'
require 'tmpdir'

Encoding.default_external = Encoding::UTF_8

ROOT = Pathname.new(__FILE__).realpath.parent.parent

def read_text(path)
  path.read.gsub(/\r\n?/, "\n")
rescue SystemCallError => error
  raise IOError, "[Errno #{error.errno}] #{SystemCallError.new(error.errno).message}: '#{path}'"
end

def words(text)
  text.split(/[[:space:]\u001c-\u001f]+/).reject(&:empty?).length
end

def section(text, title)
  lines = text.lines
  starts = lines.each_index.select { |index| lines[index].delete_suffix("\n") == title }
  raise ArgumentError, "Expected one section '#{title}', found #{starts.length}" unless starts.length == 1

  start = starts.first
  depth = title[/\A#+/].length
  stop = ((start + 1)...lines.length).find { |index| lines[index].match?(/^\#{1,#{depth}} /) } || lines.length
  lines[start...stop].join
end

def grouped(number)
  number.to_s.reverse.scan(/.{1,3}/).join(',').reverse
end

def token_count(count, factor)
  ((count * factor).fdiv(100).ceil * 10)
end

def estimate(count)
  "#{grouped(token_count(count, 36))} to #{grouped(token_count(count, 41))}"
end

def recount(root)
  notes = {}
  harness = read_text(root.join('harness-notes.md'))
  harness.to_enum(:scan, /^\*\*(HN\d+)\./).each do
    match = Regexp.last_match
    rest = harness[match.begin(0)..]
    ending = rest.match(/\n(?:\*\*HN\d+\.|## )/)
    notes[match[1]] = words(ending ? rest[...ending.begin(0)] : rest)
  end
  common = %w[HN02 HN28]
  groups = { 'Claude Code' => %w[HN12 HN16], 'Codex' => %w[HN20 HN21 HN34], 'Cursor' => %w[HN23 HN25 HN26] }
  all_notes = common + groups.values.flatten
  original = read_text(root.join('bootstrap.md'))
  updated = original.dup
  card_names = %w[member implementer reviewer qa auditor writer orchestrator]
  cards = card_names.to_h { |name| [name, words(read_text(root.join("cards/#{name}.md")))] }
  startup = words(section(original, '## 7. Start the first team') + section(original, '## 8. The first ten minutes'))
  digest = words(read_text(root.join('orchestrator.md')))
  base = cards.fetch('orchestrator') + digest + startup
  starts = groups.to_h { |label, ids| [label, base + (common + ids).sum { |id| notes.fetch(id) }] }
  starts['All three'] = base + all_notes.sum { |id| notes.fetch(id) }
  replace = lambda do |pattern, &replacement|
    count = 0
    updated = updated.gsub(pattern) do
      count += 1
      replacement.call(Regexp.last_match)
    end
    raise ArgumentError, "Expected one reading-map match, found #{count}: #{pattern.source}" unless count == 1
  end

  card_names[1...-1].each do |role|
    count = cards.fetch('member') + cards.fetch(role)
    replace.call(/^(\| (?:Implementer|Reviewer|QA|Auditor|Writer) \| At start \| `cards\/member.md` \+ `cards\/#{role}\.md` \| ).*$/) do |match|
      "#{match[1]}#{grouped(count)} | #{estimate(count)} |"
    end
  end
  count = starts.fetch('All three')
  row = "| Orchestrator | At start | `cards/orchestrator.md` (#{grouped(cards.fetch('orchestrator'))}), " \
        "`orchestrator.md` (#{grouped(digest)}), bootstrap sections 7 and 8 (#{grouped(startup)}), " \
        "harness notes for all three harnesses (#{grouped(all_notes.sum { |id| notes.fetch(id) })}); " \
        "omit notes for harnesses not being spawned | #{grouped(count)} | #{estimate(count)} |"
  replace.call(/^\| Orchestrator \| At start \|.*$/) { row }
  templates = {}
  root.join('templates').glob('*.md').sort.each do |path|
    count = words(read_text(path))
    templates[path.basename.to_s] = count
    replace.call(/^(\| Whoever fills this form \| Only when filling it \| `templates\/#{Regexp.escape(path.basename.to_s)}` \| ).*$/) do |match|
      "#{match[1]}#{grouped(count)} | #{estimate(count)} |"
    end
  end
  ranges = {}
  groups.each_key do |label|
    ids = section(harness, "## #{label}").scan(/^\*\*(HN\d+)\./).flatten
    lo, hi = ids.map { |id| notes.fetch(id) }.minmax
    ranges[label] = [lo, hi]
    tokens = "#{grouped(token_count(lo, 36))} to #{grouped(token_count(hi, 41))}"
    replace.call(/^(\| #{label} member \|.*? \| `harness-notes.md`, #{label} \| ).*$/) do |match|
      "#{match[1]}#{lo} to #{hi} per note | #{tokens} per note |"
    end
  end
  count = words(read_text(root.join('evidence.md')))
  replace.call(/^(\| Rule auditor \|.*? \| `evidence.md`, only the cited entry; full catalog size shown \| ).*$/) do |match|
    "#{match[1]}#{grouped(count)} in catalog | #{estimate(count)} in catalog |"
  end
  largest = card_names[1...-1].max_by { |role| cards.fetch(role) }
  load = cards.fetch('member') + cards.fetch(largest)
  relation = load < 800 ? 'below' : load == 800 ? 'at' : 'above'
  summary = "The largest initial member load is #{load} words, `cards/member.md` plus " \
            "`cards/#{largest}.md`, #{relation} the 800-word\nlimit. " \
            "The common card has #{cards.fetch('member')} words; role cards have " +
            card_names[1...-1].map { |role| "#{role} #{cards.fetch(role)}" }.join(', ') +
            "; the orchestrator card has #{cards.fetch('orchestrator')}."
  replace.call(/The largest initial member load is [\s\S]*?orchestrator card has \d+\./) { summary }
  data = { cards: cards, digest: digest, bootstrap_7_8: startup,
           notes: all_notes.to_h { |id| [id, notes.fetch(id)] },
           orchestrator_start: starts.transform_values { |value| { words: value, tokens: estimate(value) } },
           templates: templates, harness_note_ranges: ranges, evidence: count,
           reading_map: words(section(updated, '## Reading map')) }
  [original, updated, data]
end

def map_diff(before, after)
  return '' if before == after

  Dir.mktmpdir('nomos-map-diff-') do |directory|
    original = File.join(directory, 'before')
    updated = File.join(directory, 'after')
    File.write(original, before)
    File.write(updated, after)
    stdout, stderr, status = Open3.capture3('diff', '-u', '--label', 'bootstrap.md', '--label', 'bootstrap.md (recounted)', original, updated)
    raise IOError, "diff failed: #{stderr}" unless [0, 1].include?(status.exitstatus)

    stdout
  end
end

def main
  reports = nil
  mode = nil
  parser = OptionParser.new do |options|
    options.banner = 'Usage: recount.rb [--check | --write] [--report-dir REPORT_DIR]'
    options.on('--check', 'Fail when the saved map differs from its inputs.') do
      raise OptionParser::InvalidArgument, '--check cannot be combined with --write' if mode == :write

      mode = :check
    end
    options.on('--write', 'Explicitly update bootstrap.md with computed figures.') do
      raise OptionParser::InvalidArgument, '--write cannot be combined with --check' if mode == :check

      mode = :write
    end
    options.on('--report-dir REPORT_DIR', 'Directory for generated reports; default is temporary.') { |path| reports = Pathname.new(path) }
  end
  parser.parse!
  raise OptionParser::InvalidArgument, ARGV.join(' ') unless ARGV.empty?

  reports ||= Pathname.new(Dir.mktmpdir('nomos-recount-'))
  FileUtils.mkdir_p(reports)
  begin
    before, after, data = recount(ROOT)
  rescue SystemCallError, IOError, ArgumentError, KeyError => error
    message = error.is_a?(KeyError) ? "'#{error.key}'" : error.message
    puts "FAIL reading recount: #{message}"
    return 1
  end
  delta = map_diff(before, after)
  reports.join('reading-counts.json').write("#{JSON.pretty_generate(data, ascii_only: true)}\n")
  reports.join('reading-map.diff').write(delta)
  reports.join('bootstrap.recounted.md').write(after)
  puts "Reading counts and proposed map: #{reports}"
  if before == after
    puts 'PASS reading map matches its inputs'
    return 0
  end
  if mode == :write
    ROOT.join('bootstrap.md').write(after)
    puts 'Updated bootstrap.md; review the diff before committing'
    return 0
  end
  print delta
  puts 'FAIL reading map has drifted; inspect the diff and run ruby tool/recount.rb --write to update it'
  1
rescue OptionParser::ParseError => error
  warn "#{parser.banner}\n#{error.message}"
  2
end

exit main if $PROGRAM_NAME == __FILE__
