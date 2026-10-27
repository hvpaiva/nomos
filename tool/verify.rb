# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'open3'
require 'optparse'
require 'pathname'
require 'set'
require 'timeout'
require 'tmpdir'
require 'uri'

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

def json(value)
  JSON.pretty_generate(value, ascii_only: true)
end

def prose(text)
  text.gsub(/^[[:space:]]*```[^\n]*\n.*?^[[:space:]]*```[^\n]*$/m, '')
end

def heading_ids(text)
  seen = Set.new
  prose(text).scan(/^\#{1,6}[[:space:]]+(.+?)[[:space:]]*#*$/).flatten.each do |title|
    slug = title.gsub(/<[^>]+>/, '').downcase.gsub(/[^\p{L}\p{N}_ -]/, '').tr(' ', '-')
    candidate = slug
    counter = 0
    while seen.include?(candidate)
      counter += 1
      candidate = "#{slug}-#{counter}"
    end
    seen.add(candidate)
  end
  seen.merge(text.scan(/<(?:a|h[1-6])\b[^>]*\b(?:id|name)=["']([^"']+)/).flatten)
end

def resolve(path)
  path = path.expand_path
  return resolve(path.parent.join(path.readlink)) if path.symlink?
  return path.realpath if path.exist?

  resolve(path.parent).join(path.basename)
end

def inside?(path, root)
  path == root || path.to_s.start_with?("#{root}/")
end

def capture(args, root: nil, env: {})
  options = root ? { chdir: root.to_s } : {}
  Open3.popen3(env, *args, **options) do |input, output, error, process|
    input.close
    stdout = Thread.new { output.read }
    stderr = Thread.new { error.read }
    begin
      status = Timeout.timeout(30) { process.value }
      [stdout.value.gsub(/\r\n?/, "\n"), stderr.value.gsub(/\r\n?/, "\n"), status.exitstatus || -status.termsig]
    rescue Timeout::Error
      Process.kill('KILL', process.pid)
      process.value
      raise Timeout::Error, "Command #{args.inspect} timed out after 30 seconds"
    end
  end
end

def verify(root, reports)
  checks = []
  check = lambda do |name, ok, details = nil|
    checks << { name: name, exit_code: ok ? 0 : 1, pass: !!ok, details: details }
  end
  command = lambda do |name, args, expected: 0, empty: false|
    stdout, stderr, code = capture(args, root: root)
    check.call(name, code == expected && (!empty || stdout.empty?),
               { exit_code: code, stdout: stdout, stderr: stderr })
    stdout
  end

  required = %w[
    README.md CHANGELOG.md CONTRIBUTING.md protocol.md playbook.md harness-notes.md bootstrap.md
    orchestrator.md keryx.md evidence.md cards/member.md cards/orchestrator.md cards/implementer.md
    cards/reviewer.md cards/qa.md cards/auditor.md cards/writer.md templates/first-prompt.md
    templates/brief.md templates/report.md templates/handover.md templates/review-brief.md
    templates/review-findings.md templates/plan-review.md templates/audit-brief.md templates/escalation.md
    hooks/pre-send.rb test/pre_send_test.rb
    test/fixtures/pre-send/claude.json test/fixtures/pre-send/codex.json test/fixtures/pre-send/cursor.json
    test/fixtures/pre-send/flagged.txt test/fixtures/pre-send/excluded.txt test/fixtures/pre-send/backtick.txt
    test/fixtures/pre-send/vocabulary.txt
    tool/check tool/recount.rb tool/verify.rb tool/check-style.sh tool/check-evidence.rb .github/workflows/ci.yml
  ]
  missing = required.reject { |name| root.join(name).file? }
  check.call('required package files', missing.empty?, missing)
  return checks unless missing.empty?

  paths = root.glob('**/*.md').sort.reject do |path|
    path.relative_path_from(root).each_filename.any? { |part| part.start_with?('.') }
  end
  texts = paths.to_h { |path| [path, read_text(path)] }
  digest = texts.fetch(root.join('orchestrator.md'))
  helper_match = digest.match(/```bash\n(.*?)\n```/m)
  check.call('digest section helper', !helper_match.nil?)
  source_commands = digest.scan(/`(section [^`]+)`/).flatten
  paragraphs = prose(digest).split("\n\n").reject { |paragraph| paragraph.strip.empty? || paragraph.lstrip.start_with?('#') }
  without_source = paragraphs.reject { |paragraph| paragraph.match?(/`section [^`]+`/) }
  check.call('digest paragraph sources', !paragraphs.empty? && without_source.empty?, without_source)
  if helper_match
    helper = helper_match[1]
    source_commands.each_with_index do |command_text, i|
      command_text.split('; ', -1).each_with_index do |single, j|
        name = "digest paragraph #{i + 1} source #{j + 1}"
        stdout = command.call(name, ['bash', '-c', "#{helper}\n#{single}"])
        check.call("#{name} output", !stdout.strip.empty?)
        checks[-2][:details][:stdout] = stdout.lines.first&.chomp || ''
      end
    end
    command.call('missing source heading', ['bash', '-c', "#{helper}\nsection protocol.md '## Missing heading for check'"],
                 expected: 1, empty: true)
  end
  check.call('digest word limit', words(digest) <= 2500, { words: words(digest), limit: 2500 })
  common_words = words(texts.fetch(root.join('cards/member.md')))
  root.join('cards').glob('*.md').sort.each do |path|
    role = path.basename('.md').to_s
    count = words(texts.fetch(path))
    limit = { 'member' => 500, 'orchestrator' => 600 }.fetch(role, 300)
    check.call("card #{role}", count <= limit, { words: count, limit: limit })
    next if %w[member orchestrator].include?(role)

    check.call("member load #{role}", common_words + count <= 800, { words: common_words + count, limit: 800 })
  end
  map_commands = []
  %w[bootstrap.md cards/orchestrator.md templates/first-prompt.md].each do |name|
    match = texts.fetch(root.join(name)).match(/awk '\/\^## Reading map\$.*?' bootstrap\.md/)
    check.call("reading map command present #{name}", !match.nil?)
    next unless match

    map_commands << match[0]
    stdout = command.call("reading map #{name}", ['bash', '-c', match[0]])
    check.call("reading map boundaries #{name}", stdout.start_with?("## Reading map\n") && !stdout.sub(/\n+\z/, '').match?(/\n## /))
    checks[-2][:details][:stdout] = "#{words(stdout)} words"
  end
  check.call('map commands identical', map_commands.length == 3 && map_commands.uniq.length == 1)
  links = []
  inline = []
  external_paths = %w[AGENTS.md CLAUDE.md SECURITY.md ARCHITECTURE.md docs/agents.md docs/compatibility.md]
  texts.each do |path, text|
    relative = path.relative_path_from(root).to_s
    body = prose(text)
    targets = body.scan(/\[[^\]]*\]\(([^)]+)\)/).flatten
    definitions = body.scan(/^\[([^\]]+)\]:[[:space:]]*(\S+)/).to_h
    targets.concat(definitions.values)
    body.scan(/\[([^\]]+)\]\[([^\]]*)\]/).each do |label, ref|
      ref = label if ref.empty?
      check.call("reference link #{relative} [#{ref}]", definitions.key?(ref))
    end
    targets.each do |raw|
      target = raw.split.first.sub(/\A[<>]+/, '').sub(/[<>]+\z/, '')
      next if target.match?(/\A[a-zA-Z][a-zA-Z0-9+.-]*:/) || target.start_with?('//')

      url_path, fragment = target.split('#', 2)
      url_path = url_path.split('?', 2).first.to_s
      destination = url_path.empty? ? path : resolve(path.parent.join(URI::DEFAULT_PARSER.unescape(url_path)))
      inside = inside?(destination, root)
      exists = inside && destination.exist?
      anchor = URI::DEFAULT_PARSER.unescape(fragment.to_s)
      anchor_ok = anchor.empty? || (exists && destination.extname == '.md' && heading_ids(read_text(destination)).include?(anchor))
      links << { file: relative, target: target, inside: inside, exists: exists, anchor: anchor_ok }
    end
    body.scan(/`([^`\n]+)`/).flatten.each do |raw|
      token = raw.split('#', 2).first.to_s
      next unless token.match?(%r{\A(?:\.\./)*(?:[\p{L}\p{N}_-]+/)*[\p{L}\p{N}_-]+\.md\z})

      candidates = [resolve(path.parent.join(token)), resolve(root.join(token))]
      matches = candidates.any? { |candidate| inside?(candidate, root) && candidate.exist? }
      inline << { file: relative, target: raw, package: matches, external_source_or_config: external_paths.include?(token) }
    end
    stdout, _stderr, code = capture(['wc', '-w', path.to_s], env: { 'LC_ALL' => 'C.UTF-8' })
    check.call("wc #{relative}", code.zero? && Integer(stdout.split.first) == words(text))
  end
  bad_links = links.reject { |link| %i[inside exists anchor].all? { |key| link[key] } }
  check.call('package Markdown links', bad_links.empty?, bad_links)
  bad_inline = inline.reject { |link| link[:package] || link[:external_source_or_config] }
  check.call('inline package paths', bad_inline.empty?, bad_inline)
  reports.join('link-inventory.json').write("#{json({ markdown: links, inline: inline })}\n")
  checks
end

def main
  reports = nil
  parser = OptionParser.new do |options|
    options.banner = 'Usage: verify.rb [--report-dir REPORT_DIR]'
    options.on('--report-dir REPORT_DIR', 'Directory for reports; default is temporary.') { |path| reports = Pathname.new(path) }
  end
  parser.parse!
  raise OptionParser::InvalidArgument, ARGV.join(' ') unless ARGV.empty?

  reports ||= Pathname.new(Dir.mktmpdir('nomos-verify-'))
  FileUtils.mkdir_p(reports)
  begin
    checks = verify(ROOT, reports)
  rescue SystemCallError, IOError, ArgumentError, KeyError, Timeout::Error => error
    message = error.is_a?(KeyError) ? "'#{error.key}'" : error.message
    puts "FAIL package verification: #{message}"
    return 1
  end
  reports.join('checks.json').write("#{json(checks)}\n")
  failed = checks.reject { |check| check[:pass] }
  puts json({ checks: checks.length, failed: failed })
  failed.empty? ? 0 : 1
rescue OptionParser::ParseError => error
  warn "#{parser.banner}\n#{error.message}"
  2
end

exit main if $PROGRAM_NAME == __FILE__
