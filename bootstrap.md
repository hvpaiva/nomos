# nomos bootstrap, version 0

From the nomos repository root, print only the reading map with this command.

```bash
awk '/^## Reading map$/{found=1} found && /^## / && $0 != "## Reading map"{exit} found{print} END{if (!found) exit 1}' bootstrap.md
```

## Reading map

A member starts with the common card and its role card. The orchestrator starts with
`cards/orchestrator.md`, `orchestrator.md`, bootstrap sections 7 and 8, and only the harness notes
needed for the harnesses it will spawn. Read HN02 and HN28 for every harness; add HN12 and HN16 for
Claude Code, HN20, HN21 and HN34 for Codex, and HN23, HN25 and HN26 for Cursor. Read notes by id.
Protocol and playbook are read by section on demand, including that section's subsections. The cards
and orchestrator digest add no rules; they name the sources for detail. Templates are read for the
form being filled and evidence to audit a rule. The first prompt and brief supply authority and task.
(LOG, acceptance 1, stumble 6; LOG, acceptance 2, map command; LOG, 2026-10-23 about 08:05 UTC-3, orchestrator
digest; low)

Print one section with this command from the nomos repository root, changing the file and exact heading for
the section needed. It includes nested headings and stops before the next heading of the same or a
higher level. A missing heading exits with status 1.

```bash
awk -v title='## 7. Start the first team' '
  /^#+ / {
    match($0, /^#+/); level = RLENGTH
    if (found && level <= depth) exit
    if ($0 == title) { found = 1; depth = level }
  }
  found { print }
  END { if (!found) exit 1 }
' bootstrap.md
```

For a harness note, use its id rather than reading the whole harness section.

```bash
awk -v id='HN02' '
  /^\*\*HN[0-9]+\./ { if (found) exit; if (index($0, "**" id ".") == 1) found = 1 }
  found && /^## / { exit }
  found { print }
  END { if (!found) exit 1 }
' harness-notes.md
```

The map follows decisions from the run that developed nomos, recorded in `evidence.md`, LOG,
2026-10-23, 02:52 and 04:05 UTC-3, and about 08:05 UTC-3, orchestrator digest, plus the first
acceptance test's stumbles 4 and 6. The digest choice is recorded in the run log at 08:12 UTC-3;
about 08:05 UTC-3 is the writing brief's approximate time of the choice.
Word counts include headings and forms, measured with
`wc -w`. The second run measured about 2.1 tokens per word for sections printed by command
and about 2.5 for a file read with line numbers, including tool calls. Keep that earlier range as
its own observation. The third run used 6,565 enumerated words plus the map's 1,023, or 7,588 words,
and about 27K to 31K tokens reading nomos. Dividing gives about 3.56 to 4.09 tokens per enumerated
word. Estimates below use 3.6 to 4.1, rounded upward to tens. This is a planning ratio across that
run's reading and interleaved model output, not a tokenizer ratio or a measured cost for each row.
The upper measurement includes two templates, and the run also opened five playbook sections and
bootstrap in full, so those extra texts are not all in the denominator. On-demand rows are not added
to the initial card total. The evidence row gives catalog size, not required reading.

Measured separately from the estimates below, reading nomos cost about 27K to 31K tokens in the third
run, against about 46K in the second and 48K in the first. The third leader's context was 50.2K at its
first turn, 60.9K after join and skill, 103.2K before writing its readback and about 110K when sending
it. The transcript figures include input, cache read and cache creation, hence the model's own prior
output. About 11K between 60.9K and 103.2K covered the task, repository, transport help and machine
checks. These are reported measures of one reading-only Claude Code run, not a controlled comparison.

The orchestrator row totals the current enumerated texts, with all three harnesses as the upper
case. The map itself, first prompt, brief, tool calls, interleaved output and on-demand reading add
to it. Harness startup is separate from reading cost but remains inside the session's ceiling.
(LOG, acceptance 2, reading measures; LOG, acceptance 3, 2026-10-23, reading measures; low)

| Reader | When | Reading | Words | Estimated tokens |
|---|---|---|---|---|
| Implementer | At start | `cards/member.md` + `cards/implementer.md` | 773 | 2,790 to 3,170 |
| Reviewer | At start | `cards/member.md` + `cards/reviewer.md` | 780 | 2,810 to 3,200 |
| QA | At start | `cards/member.md` + `cards/qa.md` | 755 | 2,720 to 3,100 |
| Auditor | At start | `cards/member.md` + `cards/auditor.md` | 792 | 2,860 to 3,250 |
| Writer | At start | `cards/member.md` + `cards/writer.md` | 761 | 2,740 to 3,130 |
| Orchestrator | At start | `cards/orchestrator.md` (598), `orchestrator.md` (2,500), bootstrap sections 7 and 8 (2,387), harness notes for all three harnesses (1,565); omit notes for harnesses not being spawned | 7,050 | 25,380 to 28,910 |
| Harness start, outside nomos | Record the context stamped on the first readback | On 2026-10-23, third-run Claude Code 50.2K at its first turn and 60.9K after join and skill; first-run Claude Code 50.9K and 61.8K after join, skill and inbox; first-run Codex about 23K on its readback | Not a word count | Observed context, not a text estimate |
| Whoever fills this form | Only when filling it | `templates/audit-brief.md` | 781 | 2,820 to 3,210 |
| Whoever fills this form | Only when filling it | `templates/brief.md` | 1,257 | 4,530 to 5,160 |
| Whoever fills this form | Only when filling it | `templates/escalation.md` | 495 | 1,790 to 2,030 |
| Whoever fills this form | Only when filling it | `templates/first-prompt.md` | 2,140 | 7,710 to 8,780 |
| Whoever fills this form | Only when filling it | `templates/handover.md` | 1,616 | 5,820 to 6,630 |
| Whoever fills this form | Only when filling it | `templates/human-message.md` | 1,156 | 4,170 to 4,740 |
| Whoever fills this form | Only when filling it | `templates/plan-review.md` | 420 | 1,520 to 1,730 |
| Whoever fills this form | Only when filling it | `templates/report.md` | 512 | 1,850 to 2,100 |
| Whoever fills this form | Only when filling it | `templates/review-brief.md` | 766 | 2,760 to 3,150 |
| Whoever fills this form | Only when filling it | `templates/review-findings.md` | 416 | 1,500 to 1,710 |
| Whoever fills this form | Only when filling it | `templates/roster.md` | 215 | 780 to 890 |
| Whoever fills this form | Only when filling it | `templates/roadmap.md` | 178 | 650 to 730 |
| Whoever fills this form | Only when filling it | `templates/progress.md` | 215 | 780 to 890 |
| Claude Code member | Only the note needed for its own harness | `harness-notes.md`, Claude Code | 50 to 204 per note | 180 to 840 per note |
| Codex member | Only the note needed for its own harness | `harness-notes.md`, Codex | 34 to 256 per note | 130 to 1,050 per note |
| Cursor member | Only the note needed for its own harness | `harness-notes.md`, Cursor | 77 to 356 per note | 280 to 1,460 per note |
| Rule auditor | Only to audit a rule | `evidence.md`, only the cited entry; full catalog size shown | 34,618 in catalog | 124,630 to 141,940 in catalog |

The largest initial member load is 792 words, `cards/member.md` plus `cards/auditor.md`, below the 800-word
limit. The common card has 500 words; role cards have implementer 273, reviewer 280, qa 255, auditor 292, writer 261; the orchestrator card has 598.

## About this guide

Use this guide to set up your own team from a copy of the nomos repository. Start with the reading
map above. Once keryx is installed, run `keryx help COMMAND` for its command reference. Dated checks
of particular tool versions are in `harness-notes.md`; check your installed versions before relying
on them. Examples use a principal named Ana, team alpha, machines box1 and box2, and a repository at
`~/src/shop`. Replace those names and paths with yours. Measurements from the runs that developed
nomos are evidence from those runs, not measurements of your machine or accounts.

When a step fails, stop there. Do not run the next step, since the steps below assume the ones above
worked. Read what the failed step did before you try it again, because a repeat can duplicate a
message, a session or an install (protocol, Messages and the work life cycle). Fix the cause, run the
step again, and write down what failed, so the next version of this guide can say it.

## 0. What you need in hand

- A copy of the nomos repository, with this guide, `orchestrator.md`, `protocol.md`, `templates/`,
  `cards/`, `playbook.md`, `harness-notes.md`, `keryx.md` and `evidence.md`. Public evidence and traces
  are in `evidence.md`; no private working directory is needed.
- keryx, installed from its
  [installation instructions](https://github.com/hvpaiva/keryx#install-and-set-up-the-agents).
- An account for each harness the team will use, and a git repository for the team's first task.

## 1. Check the machine

This guide supports Linux with a systemd user session. keryx also runs on macOS, but the courier
service below is a systemd unit, so on macOS you write the equivalent job for your service manager.
Run each check for the tools your team needs and resolve any failure before you go on.

In a shell without a session bus, set these before the `systemctl --user` checks and the courier
commands in section 3. They point to the existing user session's bus.

```bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
```

| Tool | Needed for | Check | Passes when |
|---|---|---|---|
| systemd user session | The courier service | `systemctl --user is-system-running` | It prints running or degraded |
| git | Task repositories and worktrees | `git --version` | It prints a version |
| Ruby 3.4 or later, with RubyGems | keryx | `ruby -e 'exit(Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4"))' && gem --version` | It exits 0 and prints a version |
| jq | Watchers, Codex's context figure | `jq --version` | It prints a version; the nomos v0 checks used 1.7 |
| ssh | Two machines only | `ssh -V` | It prints a version |
| herdr | Spawning sessions into panes, bells for Codex and Cursor | `herdr --version`, then `herdr status` | Both run; `herdr status` names the client and the running server |
| Claude Code 2.1.224 or later | Claude Code seats | `claude --version` | The version is at least 2.1.224 |
| Codex CLI 0.149 or later | Codex seats | `codex --version` | The version is at least 0.149 |
| Cursor Agent CLI | Cursor seats | `cursor-agent --version` | It prints a version |

herdr is the terminal multiplexer keryx spawns sessions into; its site has the
[installation instructions](https://herdr.dev/docs/install/). The nomos v0 checks ran herdr 0.9.5;
its server can lag its client after an upgrade (HN01). The minimum harness versions above come from
keryx's compatibility notes used in those checks. Compare them with the
[compatibility notes](https://github.com/hvpaiva/keryx/blob/main/docs/compatibility.md) for the release
you install.

Install each harness from its vendor, log it in with the account you chose, and run it once by hand in
a scratch folder to clear its first-run dialogs. You only need the harnesses the team will use.

## 2. Install keryx

Follow keryx's [installation instructions](https://github.com/hvpaiva/keryx#install-and-set-up-the-agents),
then check the installed version with `keryx version`.

If installation fails, read the error and fix its cause before retrying. When `keryx version` is not
found after a successful install, `ruby -e 'puts Gem.bindir'` prints the gem's bin directory. Check
that it is on PATH; a version manager may need its shims refreshed.

Install the same keryx release on every machine that exchanges mail and record each machine's
`keryx version` output. The [keryx binding](keryx.md) names the reference revision and dated checks
behind its capability descriptions; compare them with the release you install.

Sessions that `keryx spawn` starts are told to run `keryx skill`. For sessions you start by hand,
install the skill where each harness reads skills, as keryx's README shows. Use the entries for the
harnesses your team runs.

    mkdir -p ~/.claude/skills/keryx && keryx skill > ~/.claude/skills/keryx/SKILL.md
    mkdir -p ~/.codex/skills/keryx && keryx skill > ~/.codex/skills/keryx/SKILL.md
    mkdir -p ~/.cursor/skills/keryx && keryx skill > ~/.cursor/skills/keryx/SKILL.md

## 3. Configure keryx

1. Name the machine. For the box1 example, write `host = box1` in `~/.config/keryx/config` (under
   `$XDG_CONFIG_HOME` when it is set). Use the alias the other machines use to reach yours with ssh.
   `keryx whoami` from a terminal must print your terminal's address on that host.
2. With two machines, make each reach the other with `ssh box2 keryx version` and no prompt, and check
   that both print the same version. keryx forwards mail over ssh. `KERYX_SSH` replaces the ssh
   command when you need options, and `KERYX_REMOTE_COMMAND` says how to run keryx there when a
   non-interactive ssh does not find it. With one machine, skip this step.
3. Run the courier as a user service on each machine. It forwards mail to a machine that was asleep
   when it is back, rings again for bells that did not reach a session, and tells senders about missed
   deadlines. Check the service's PATH; in the recorded setup it missed a version manager's shims
   (HN30). Set it to reach keryx, herdr and every harness CLI, and put the absolute path returned by
   `command -v keryx` in `ExecStart`. The unit below is an example; replace both path placeholders
   with the paths on your machine.

       # ~/.config/systemd/user/keryx-courier.service
       [Unit]
       Description=keryx courier

       [Service]
       ExecStart=/ABSOLUTE/PATH/TO/keryx courier
       Environment=PATH=DIRS_OF_KERYX_HERDR_AND_HARNESSES:/usr/local/bin:/usr/bin:/bin
       Restart=on-failure

       [Install]
       WantedBy=default.target

       systemctl --user daemon-reload &&
         systemctl --user enable --now keryx-courier &&
         systemctl --user is-active keryx-courier

   It passes when the last command prints active. When it does not,
   `journalctl --user -u keryx-courier -n 50` shows why, most often a PATH that misses a tool.
4. Read `keryx skill` once. It is what every session follows.

## 4. Make every session load nomos

A rule that lives only in a document sessions may not read is not applied (protocol, Conformance,
checks and versioning). Keep the nomos documents in one directory, such as `~/nomos`, and give each
harness a short entry file that points there. Do not copy the documents into each harness; the entry
file names the directory and says when to read which file.

| Harness | Where the entry goes | What it says |
|---|---|---|
| Claude Code | A user skill, `~/.claude/skills/nomos/SKILL.md`, whose description says to use it when the session works in a team through a transport; or one line in `~/.claude/CLAUDE.md` | Members read `cards/member.md` and their role card at start; the orchestrator follows the exact list and section commands in the reading map above |
| Codex | `AGENTS.md` in the repository the team works in, or the global instructions file of your Codex version | The same pointer |
| Cursor | A rule in `.cursor/rules/` of the repository, or a user rule, applied always | The same pointer |

Until R06 composes the first prompt, include the two card paths through the member form of
`templates/first-prompt.md`; a configured entry file does not replace that sentence.

Checks that can be mechanical go in hooks, which every session runs whatever it remembers.

- The stop hook, `keryx hook stop`, reminds a session of unread mail and unanswered requests before
  its turn ends. `keryx spawn` sets it for the Claude Code sessions it starts. For Codex, add
  `{"hooks": {"Stop": [{"hooks": [{"type": "command", "command": "keryx hook stop"}]}]}}` to its
  `hooks.json` and trust that one hook in `/hooks`, never "Trust all" (HN20). For Cursor, add
  `{"version": 1, "hooks": {"stop": [{"command": "keryx hook stop"}]}}` to its `hooks.json`. These are
  the forms `keryx hook --help` gives in 0.1.0. That help and the harness CLI helps do not name the
  paths; see keryx's [agent setup instructions](https://github.com/hvpaiva/keryx/blob/main/docs/agents.md),
  under Codex and Cursor. That guide names `~/.codex/hooks.json` or the project's `.codex/hooks.json` for Codex, and
  `~/.cursor/hooks.json` or the project's `.cursor/hooks.json` for Cursor. Check the instructions
  shipped with your version before editing. Section 8 tests the hook only where you installed it.
- The optional [pre-send hook](hooks/pre-send.rb) checks bodies before `keryx send`, `keryx ask` and
  `keryx reply`. It needs Ruby 3.2 or later on the PATH the harness gives the hook, and only its
  standard library. Alternatively, prefix the hook command with the absolute path to a compatible
  Ruby interpreter, for example `/usr/bin/ruby "/absolute/nomos/hooks/pre-send.rb" --harness claude`.
  The Ruby 3.0 and 3.1 warning branch is simulated in tests, untested on those real interpreters;
  it is intended to pass with a warning and make `--check` exit 2. CI tests Ruby 3.3 and 4.0.
  Ruby older than 3.0 cannot parse the script, so it fails without that warning.
  The [binding's check
  table](keryx.md#checks-and-packaging) says which checks belong to nomos and which to keryx.
  Wire it as shown below only when the principal's delegation permits the settings change.
- A writing rule the principal has had to correct twice becomes a write hook the same way (playbook,
  Turning a repeated correction into a check).

The hook checks brace placeholders, relative dates and future timestamps outside fenced code, inline
code and lines quoted with `>`. It reads a filled form's last nonempty line, such as `nomos v0 brief`,
and loads headings from `templates/` beside the script. It checks fixed headings of brief, audit
brief, review brief, review findings, roster, roadmap and progress; headings containing placeholders
are skipped. Report
sections may be omitted under that template's guidance, multipart first prompt, plan review and
handover forms have no heading check, and neither has a footer that several templates share, such
as the human message footer that ends an escalation. Review findings also require a rank and evidence
class for each numbered finding in the template's opening findings list, or under a `## Findings`
heading. Numbered steps in other sections are excluded. Optional sections remain optional.
Within a finding, an unindented list that restarts its numbering is treated as steps until a
ranked item, or a blank-separated item above the previous finding's number, starts another finding.
Indent nested steps to distinguish them from findings separated by blank lines.

For a message to a human, the hook also checks the block of protocol 10.5 to 10.9, restating the
inbox page's rules at revision 6adc0dc (`lib/inbox/nomos.rb` and `nomos/fields.rb`) and its file
checks at de6b57b (`files.rb`).
The recipient of `keryx send ADDRESS` and `keryx ask ADDRESS` is read as `nomos check` reads it:
a person is the team segment `local`, or a full address with no team segment, and any other team
segment is an agent, whose block is inert; a review draft goes inside a longer fence. Only a bare
member is resolved as keryx resolves it: it takes the team of `--as`, a `KERYX_AS=` prefix or
`KERYX_AS` in the hook's environment, else of the address whose session id matches the hook
input's, else the one team holding that member, which the hook reads with one read-only call,
`keryx who --all -o json`, bounded at 2 seconds, stopping the call and any process holding its output
at the bound. A bare member still unresolved is checked as a reply to an unknown recipient, below.

`keryx reply ID` and `keryx send --re ID` do not show the recipient, so the hook runs the block checks
only when the body claims the form: line 2 opens a fence whose info string starts with `nomos`, a
`nomos` fence sits on line 1 or 3, the body ends with `nomos v0 human message`, or line 2 or 3 holds
a bare object whose first key is `"kind"`, on the same line as its `{` or on the next. Such a reply is not proven to go to a human, and a reply to a human that
claims nothing, with no block and no footer, is not checked for a missing block.

The flags are these. `ask without block` for an ask to a human with no block on line 2; `ask not a
request` and `ask without deadline` for a `decision`, `choice`, `question` or `action` block not sent
by `keryx ask` with `--within`. `block placement` when line 2 is not a fence with the info string
`nomos` though the body claims the form, including a bare JSON object on line 2 or 3, a `json` or
unlabeled fence holding `{"kind"`, an unknown info string such as `nomos-1`, a fence on line 1 or 3,
or a footer with no block, or when the block never closes. `block size` over 16 lines or 1,024 bytes
counted from the opening fence through the closing fence's line ending, naming the longest field;
`block json` when it does not hold one JSON object under RFC 8259 alone, which also refuses a
repeated key, a comment and an invalid escape, whichever json gem the Ruby carries. These three stop the field checks. `block title`
for a blank line 1, one over 80 characters, or one opening a heading, list, quote or fence. `block
field`, `block options`, `block default` and `block id` for the field, option, default and message id
rules of 10.7 and 10.8, including a known field on a kind that does not take it, every broken rule
listed rather than the first. `block time` for a time or date in a free-text field, or a `due` or
`deadline` key; it also flags a zoneless `8:00`, `08:00` or `08h00`, and a bare hour such as `8h`
only after `at` or a clock prefix from the words file, which the page still draws, so a duration such
as "I continue for 2h" passes. `block kind` for a block of kind `answer`, which only the page writes and draws nothing for in
an agent's message. `block html` for `<` before a letter or `/` in any string. `label not in text` for an option
label missing from the text after the block. `block file` for a `files` path that is not absolute or
`~/`, has a folder or name starting with a dot or matching the page's secret pattern in any part
after `~/`, lacks one of the page's text extensions (md, markdown, txt, rb, erb, yml, yaml, json,
toml, sh, bash, py, go, rs, tf, hcl, js, ts, css, html, sql, csv, log, conf, ini), or is not a readable
regular file of at most 1 MiB. The rules read the path as written and its real path, so a symlink
into a dot folder or to a secret-like name flags, as the page refuses it. A path under `~/.cache` therefore flags, as the page cannot open it
either. The hook knows no configured page root, so passing proves no file opens. A `decision` block
also needs Situation, Background, Assessment and Recommendation headings in the text, or the
translations in the words file's `[headings]` section, in any case (`missing heading`). Against
the page at de6b57b, the hook's block checks refuse every block the page refuses, as the tests and
the reviewers' parity corpus show; it cannot judge whether the text and the
block agree, whether an answer's ids match the original ask, or whether a `default` is reversible.

The hook runs the rules of `lib/nomos`, the same code as `nomos check` below, so every rule exists
once. Toward a person it also flags `block missing` for any message without a block on line 2,
`block footer` for one that does not end with `nomos v0 human message` as its last line, `title tag`
for any bracketed text opening line 1, `request without ask` for a request whose block is no ask, `id not in text` for an
option id missing as a whole word from the text, and `deadline not in text` for an ask whose text
states no time within five minutes of the send time plus `--within`, read as described for
`nomos check`. A reply opening with `[progress]` is flagged `progress reply` whatever its recipient,
as advice, since a brief may ask for that reply. A toward-a-person flag of a rule the protocol states
as a MUST refuses every attempt. The other flags, and every flag on a reply to an unknown recipient,
are advice.

A flag refuses that attempt and tells the sending agent its line and text. The sender corrects the
body, or for advice resends the same command prefixed with `NOMOS_PRESEND_CONFIRMED=1` to confirm the
flags; a confirmed segment is still read, and a MUST flag on it still refuses. This
confirms only the occurrences in that segment and grants no authority to send. A standalone
assignment or `export NOMOS_PRESEND_CONFIRMED=1` confirms subsequent segments in the same command.
Other segments still undergo accounting. Confirmation applies only where the body parser can
resolve the shell syntax. It never opens a human approval prompt. The hook stores no state and never executes the command itself. Without flags, Claude and
Codex receive no decision; Cursor receives `permission: allow`, subject to the version gate below.

Merge the following entry into the harness's existing configuration, preserving its other hooks.
Replace `/absolute/nomos` with this checkout's absolute path, keeping the path quoted even when it
contains spaces. Claude Code uses
`~/.claude/settings.json` or the project's `.claude/settings.json`. If the launcher already passes
`--settings`, wire the hook in a settings file, for example the project's
`.claude/settings.local.json` kept out of git: Claude Code 2.1.310 kept only the last `--settings`
argument in the recorded probes. keryx 92ab75d puts its own settings before the harness arguments
([harness.rb, lines 66 and 67](https://github.com/hvpaiva/keryx/blob/92ab75d178aa68c742a126185125672ec509c985/lib/keryx/harness.rb),
[spawn.rb, lines 188 to 191](https://github.com/hvpaiva/keryx/blob/92ab75d178aa68c742a126185125672ec509c985/lib/keryx/commands/spawn.rb)).
A later `--settings` replaces keryx's `crossSessionInbound: accept` and Stop hook, losing automatic
bell acceptance and the stop reminder even if the pre-send hook loads (HN36).

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash|PowerShell|Monitor",
      "hooks": [{"type": "command", "command": "\"/absolute/nomos/hooks/pre-send.rb\" --harness claude"}]
    }]
  }
}
```

Codex uses `~/.codex/hooks.json` or the project's `.codex/hooks.json`. In `/hooks`, inspect and trust
that one PreToolUse hook, never "Trust all" (HN20). Installing this repository does not trust a hook.

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{"type": "command", "command": "\"/absolute/nomos/hooks/pre-send.rb\" --harness codex"}]
    }]
  }
}
```

Cursor uses `~/.cursor/hooks.json` or the project's `.cursor/hooks.json`. Its matcher passes every
command containing `keryx` to the hook, including quoted and nested text. A matcher that requires
shell word boundaries would filter out substitutions and command strings before the hook sees
them. The script handles the distinction between sends and mentions. Before wiring this adapter,
prove on that Cursor version, in an authorized isolated session, that `allow` leaves an otherwise
required user approval in place (HN37). If it grants execution, stop wiring and revise the adapter.
The reference documents no response that explicitly defers to the user's settings, so the adapter
retains `allow` even for wrong events and unreadable input. An empty response is not a proven substitute.

```json
{
  "version": 1,
  "hooks": {
    "beforeShellExecution": [{
      "matcher": "keryx",
      "command": "\"/absolute/nomos/hooks/pre-send.rb\" --harness cursor"
    }]
  }
}
```

The contracts were checked on 2026-10-25 with installed Claude Code 2.1.310, Codex 0.164.0 and Cursor
agent 2026.10.22-27dcf5f, against the [Claude hooks reference](https://code.claude.com/docs/en/hooks),
[Codex hooks reference](https://learn.chatgpt.com/docs/hooks) and
[Cursor hooks reference](https://cursor.com/docs/hooks). These are current references, not version
snapshots. Cursor's permission behavior was also read in that installed version's `4097.index.js`
(line 1, the shell hook caller) and `index.js` (line 414, the hook requirement setter and shell
permission checks). The Cursor adapter relies on `allow` from beforeShellExecution being
non-authoritative, leaving the shell's own permission checks in place. That behavior was read in
this version's code, without an installed hook test, and must be re-checked for each Cursor version
before wiring this adapter. The public references were read again on 2026-10-26 for tool coverage
and the Cursor response contract; that reading did not repeat the installed bundle inspection or
a live harness test. Check the contract of another harness version before wiring it.

For a manual check, run the command below. Exit 0 means no flags, 1 means flags, and 2 means the
check could not finish. Add `--words FILE` to either mode for a UTF-8 file with another language's vocabulary. Only English
is built in. A file without section headers lists extra relative-time words or phrases, one per line.
With headers, each section adds to the English set of the same check: `[relative]` for relative
time words, `[deadline]` and `[stamp]` for the future-time rule below, `[clock-prefix]` for the words
before a bare hour such as `8h` in a block's free text, and `[headings]` for four lines translating
Situation, Background, Assessment and Recommendation, in that order. Three one-line sections serve
the deadline: `[deadline-sentence]` with `%{time}` once (English `Answer by %{time}.`), `[clock]` a
`strftime` format (English `%Y-%m-%d %H:%M %:z`) that writes the offset with `%z` or `%:z` and must
read back as the same time in the morning and the afternoon, and `[zone]` a fixed offset such as
`-03:00` (English `+00:00`), the zone the composer writes in. Blank lines and lines starting
with `#` are skipped; an unknown section, a `[headings]` section without four lines or an invalid
one-line section is a usage error. Explicit vocabulary lists in a body are still ignored. An example file follows.

```text
[relative]
the day after
[deadline]
no later than
[stamp]
logged
[clock-prefix]
around
[headings]
Situation
Context
Evaluation
Proposal
```

```sh
ruby hooks/pre-send.rb --check MESSAGE_FILE
ruby hooks/pre-send.rb --check MESSAGE_FILE --action ask --to ana.local --within 1h
```

For the human-message checks above, `--check` takes `--action send|ask|reply`, `--to ADDRESS`,
`--within DURATION` in keryx's form (such as `30m` or `1h30m`), `--now TIME` in ISO 8601 for the
clock, and `--who FILE`, a saved `keryx who --all -o json` document. Without `--who` it reads the
recipient by its team segment only; without `--action` and `--to` it checks as a reply to an unknown
recipient. Hook mode takes these from the command and refuses them as options.

The shell parser handles literal inline text or `--file` bodies, leading environment assignments,
`--as`, executable paths and compound commands separated by `&&`, `||`, `;` or `|`. It follows a
literal initial `cd DIR &&` for a later relative file path. Other directory changes leave inline,
stdin and absolute-file bodies checkable; a relative file then passes with a warning. The parser
invalidates the directory for `pushd`, `popd`, and `cd` reached through repeated `builtin` or
`command` prefixes, including their `--` and `-p` options. An `eval`, `time`, `source` or `.` segment
also invalidates it, including after those prefixes, without interpreting its command string or
reading its script. A leading `CDPATH=` assignment before `cd` invalidates the directory. `CDPATH`
set in a shell profile remains a limit; use an absolute body-file path in that case.

The warning rule starts with the original command text. Every raw occurrence of `keryx`, followed
by `send`, `ask` or `reply`, must be accounted for. Global options can intervene, including repeated
`--as VALUE`, `--as=VALUE`, `--color` and `--color=WHEN`; touching quoted pieces and variable pieces
in an option value count as one word. Blanks and backslash-newline continuations between these
words count too. A literal printf/echo escape before `keryx`, such as `\n`, `\t`, `\x41`
or four-digit octal `\0012`, also counts as a boundary; an identifier merely ending in `keryx` does not. A terminal `keryx` with
no visible action counts in command position, including
carriers such as `xargs`, `env` and `nohup`. A path or binary-name argument to `cd`, `ls`, `which`,
`type` or `command -v` does not count on its own. With no occurrence, a command within the size
bound passes without shell parsing.

The trigger does not reconstruct names or actions. An action split by quotes (`keryx se''nd`), an
action held in a variable (`keryx $A`), a variable command name, a wrapper function forwarding
`"$@"`, or a glob command name such as `ker?x` can pass silently. Escapes that hide the raw words
can also prevent a match. A script written in one tool call and run in another is not tracked.
Writing and running it in separate segments of one command is tracked. A function, alias or
environment variable set in an earlier tool call is outside this stateless lint.

The wiring reaches different tools in each harness, according to the references read on 2026-10-26.

- Claude Code matches `Bash|PowerShell|Monitor`. Bash and Monitor commands get POSIX shell accounting;
  PowerShell input uses the warn-only word trigger below, since its language is not parsed. Plugin monitors
  that start without a tool call are outside this wiring, per the
  [tools reference](https://code.claude.com/docs/en/tools-reference).
- Codex matches `Bash`, the canonical hook name for shell and unified `exec_command` calls, reading
  `tool_input.command`. `write_stdin` does not rerun PreToolUse, and specialized paths can opt out.
  Those paths are outside this wiring, per the [hook coverage](https://learn.chatgpt.com/docs/hooks).
- Cursor matches `beforeShellExecution` only. Coverage of every terminal or background execution
  path is unverified; the separate `preToolUse` hook is not wired here.

If a team widens the Claude or Codex matcher, other tool names receive no shell exemption. The
adapter walks tool_input objects and arrays, reading every string key and value unchanged, plus
each array's direct string elements joined by spaces. It warns on the word `keryx`, in any case,
followed by `send`, `ask` or `reply` among the next four words. Whitespace, quotes, backticks and
backslash line continuations separate words. Paths, `.exe` and a call operator do not hide the name;
`mykeryx` is not the word. A known Bash or Monitor tool without a string command uses this path too,
so a Monitor `ws` watch passes silently. Missing or null tool_input is a contract error.
The keryx word test precedes the combined 64 KiB string-size gate. Input without that word passes
silently regardless of size, within the 32-level nesting bound. Oversized input with the word warns;
smaller input without a nearby action passes. This path never runs the POSIX shell scanner.

An occurrence is accounted for by a direct invocation whose literal body was resolved and checked,
or by literal data in a recognized read command. A nil body never discharges an invocation. Each
exemption belongs to its position in the original text. A checked body or search pattern cannot
account for a second, identical phrase elsewhere. Any leftover occurrence warns, including in a
shell form the scanner does not know. Substitutions inside a read argument do not inherit its
exemption, and output fed to a command that might execute it is not exempted as read data.

A read exemption requires a bare executable name, or that name directly under `/bin` or `/usr/bin`,
no variable mutation anywhere in the command or `env` wrapper, and every option on that reader's
own allowlist. Any assignment, export, declaration, variable read or unset disables read exemptions
across all segments and nested consumers, whichever variable it names. This includes `export`,
`declare`, `typeset`, `local`, `readonly`, `read`, `mapfile`, `readarray`, `printf -v`, `getopts`
and `unset`; even `x=1; grep 'keryx send' f` warns. Long options
must be spelled out; short clusters and attached values are accepted only where explicitly listed
in `Command::Reader::OPTIONS`. An unknown or abbreviated option warns when an occurrence depends
on that exemption. A function definition, alias, hash, enable, builtin invocation or PATH assignment
anywhere in the same command disables its read exemptions, including nested consumers. `eval`,
`source` and dot commands also invalidate reader names because they can redefine them.

The tables cover `grep`, `rg`, `head`, `tail`, `sort`, `uniq`, `wc`, `cut`, `tr`, `diff`, `cat`,
`echo`, and `printf`. Git has separate tables for log, show and grep; gh has separate tables for
search code and issue list. Git accepts `--no-pager` before log, show or grep, including alongside
`-C`. Git reads assume the repository configuration names no pager, textconv, external diff or
fsmonitor program. The lint cannot see that configuration, including includes or a repository
selected with `-C`, just as it cannot see an environment set by an earlier tool call. `xargs grep`, `xargs wc` and `find -exec grep` validate the inner command
against the same table. Find predicates have their own exact list. Executing options such as
`rg --pre`, `sort --compress-program` and `git grep --open-files-in-pager`, including abbreviations,
receive no exemption. Neither do output options or uniq's second operand.

For `sed`, only literal print, quit and delete programs with supported addresses and options are
reads. For `awk`, only literal print programs, optionally with a pattern and field, are reads.
Options after the program are checked too. Interpreters and unknown consumers warn. Literal
message arguments of `git commit` (`-m`, `--message`, and clusters of no-argument flags from
`a s q v e` ending in `m`, such as `-am`, `-sm` and `-asm`) and `gh pr create`, `gh issue create` and
`gh pr comment` (`-t`, `--title`, `-b`, `--body`) are data; the command itself is not a reader.

Text stored by a redirection or `tee` is data only if no part of the same command may run
it. Those storage forms are not read-only segments for body-file freshness. A shell, interpreter,
`eval`, `source`, dot command, variable command or unknown executable prevents the storage exemption,
including through a pipeline or nested producer. The rule is conservative when a destination or
subsequent consumer is uncertain. Writing a script without running it in the same command remains
a data operation when no variable mutation disables its read exemption.

The scanner recognizes reads behind `command` (including `command -p`, which uses the default
PATH), `exec`, `nohup` and a literal `timeout` with its options and duration, since these resolve
the command through the same lookup, or within literal shell command strings, ssh commands and
watch operands. `mise exec` and `mise x` before a read make it unknown and the command warns, since
a `mise.toml` in the working directory can set PATH and the environment. Shell
stdin containing recognized reads can be accounted for too. Supported shell no-execution options
exempt literal input, while expansions evaluated by the calling shell remain exposed. These paths
only account for reads; a wrapper never makes an unresolved send silent. Comments and quoted
here-document data are separate from executable substitutions. An unquoted here-document containing
expansions is not exempted as a whole.

The 64 KiB command limit is applied before occurrence scanning. A `--file` body over 64 KiB is not
read or checked; the hook warns with exit 0. Manual `--check` uses the same file bound and exits 2
on oversize. Reads are capped to catch a growing file. Both modes list at most 50 flags and the
number omitted. Line-number and findings-list checks use forward passes. Accounting finishes
before the body checker runs, so checker time cannot consume the command budget. With an occurrence present, the
scanner also limits nesting to 32 levels, lexical tokens to 4096 and scan time to 200 ms. A limit or
unexpected parser exception, including a stack overflow, produces a warning and exit 0. The error
path does not run the scanner again. A failed warning write to either output stream leaves the
other available and still returns exit 0 in hook mode. The scan retains source offsets and shares
its budget across nested reads. It does not execute commands or evaluate variables or script files.

The body parser supports output redirections to `/dev/null` and descriptor duplications such as
`2>&1`. Literal here-documents with quoted delimiters supply `--file -` bodies or inline text in
`"$(cat <<'EOF' ... EOF)"`; `<<-` strips leading tabs. Unquoted brace, glob and tilde expansions are
unresolved. A body file is checked only when earlier segments cannot change it. Earlier writers
such as `tee`, `cp`, `mv`, `install`, `dd`, `sort -o`, `uniq IN OUT`, `find -fprint`, `sed -i` or an
unknown command prevent resolution;
this conservative rule can warn even when the written path differs. Directory-only changes retain
the directory rules above. Unsupported syntax leaves its send occurrence unaccounted and warns.
The optional confirmation prefix still applies to commands the body parser can read.

An unreadable file, unsupported shell input or hook failure passes with a warning on stderr and
in the adapter output when that invocation is present. Name-only mentions outside command position
and accounted read data pass silently within the size bound; malformed hook input and manual-check
errors still report their diagnostics.
Claude Code and Codex receive `hookSpecificOutput.additionalContext` with
`hookEventName: PreToolUse` and no permission decision, as documented in their hook references
above. Cursor receives `agent_message` and `user_message` beside `allow`; delivery of those warning
fields has not been tested in a live harness. A Cursor warning may reach neither the agent nor
the user; stderr may appear only in its Hooks output channel. Cursor teams check bodies by hand
with `--check` until an authorized live probe shows warning delivery. Unknown or missing
`--harness` produces only stderr and exit 0, without an adapter JSON response. Repair the wiring
and tell the human on argument or input-contract errors; no schema compatibility is claimed for
an invocation whose harness could not be identified. Cursor's handling of empty stdout is not
documented, so section 8's clean control catches a misspelled `--harness` that blocks execution.
Body files must be regular UTF-8 files. These checks are a reminder, not a shell interpreter or an
authority gate.

For Codex, relative `--file` paths resolve against the session's `cwd` from the hook input, unless
the command starts with the supported literal `cd DIR &&`. The Codex reference's common input
fields define `cwd` as the session directory; neither that reference nor the checked adapter
format establishes a separate shell-call workdir field. Use an absolute body-file path when the
shell call runs in a different directory.

Recognized times use two-digit `HH:MM`, optionally `:SS` and a decimal fraction after the seconds.
An optional `YYYY-MM-DD` date is joined directly by `T` or one space. The zone is required, with
optional whitespace before it. Zones are uppercase `Z`, `UTC` or `GMT`, optionally followed by an
offset, or an offset alone in `+HH`, `-HH`, `+HHMM`, `-HHMM`, `+HH:MM` or `-HH:MM` form. A time without
a date uses the current date in that zone. A bare `HH:MM-HH:MM` is a range, not a negative offset;
its endpoint is checked when followed by a zone. Attach a negative `HH:MM` offset only to a time
with a date or seconds, or separate it with whitespace.

Date-only values, dates joined by a comma or the word `at`, named zones such as `BRT`, one-digit
hours and 12-hour clocks are not recognized as complete timestamps. A separate time and zone in
that text can still match using the current date. Times more than five minutes ahead of the check
are flagged unless their date is a later calendar day than the clock's date in the timestamp's own
zone. A time without a date uses that zone's current day and gets no such exemption. A same-day
future time beyond the five-minute tolerance is flagged unless a deadline word (until, before, due,
deadline, by directly before the time, and the words file's `[deadline]` lines) stands among the six
words before it and no stamp word (at, sent, checked, ran, and the `[stamp]` lines) does. The words are read in the same clause, from
the last `.`, `;` or `,` followed by a space, the line start, or the previous time, within 200
characters. An `at`, or a `[clock-prefix]` word, directly before the time joins a deadline word directly
before it, as in "due at" or "Deadline: at". So a 5.3 commitment's "by when" passes and "sent at" is
flagged. An event phrased with a deadline word, such as "finished by" or "worked until", passes
too, and a deadline wrapped onto the line after its word is flagged. In a `keryx ask` with `--within`, the word rule gives way to the deadline itself: only a time
within five minutes of the send time plus the duration is exempt. Text between “ ” or « », opened
and closed on one line, is a mention and is skipped by the relative and future time checks, and so is
text between straight double quotes when the line holds an even number of them and the opening one
follows a space, `(` or the line start; single quotes and apostrophes are not. A timestamp dated on a later day is exempt even if its prose
claims a completed event. This calendar rule does not classify event wording. Section names and
vocabulary examples outside quotes can still need confirmation. A flag is not proof of
a mistake.

Hooks and documents had not kept agents' messages to the principal in form (LOG, 2026-10-26, raw
human messages), so keryx runs a check before it writes any message (R30), and nomos supplies the
check. [`bin/nomos`](bin/nomos) and everything it loads live in [`lib/nomos`](lib/nomos), Ruby's
standard library only, loaded by `require_relative`. `nomos check` reads one envelope on stdin, as
keryx passes it: `check` (1), `event` (`send` or `receive`), `host`, `command` (null on receive) and
`message`, the message as keryx would store it. It exits 0 to accept, 1 to refuse with one reason per
line on stderr, each starting with the protocol section and saying what is wrong, such as `10.7 title
over 80 characters (81); line 1 is a plain title of at most 80 characters, not a heading, list, quote
or fence (line 1)`, within 4 KiB, and 2 on an invalid envelope, an invalid words file or an internal error,
which keryx refuses too. It reads no environment variable, starts no process, opens no mailbox or
network, and runs under `env -i PATH=/usr/bin:/bin LANG=C.UTF-8` from `/` on `/usr/bin/ruby` with
`--disable-gems`, Ruby 3.3 and 4.0 tested.

It refuses only rules the protocol states as MUST or MUST NOT and that the message alone decides,
never reading the clock, the event, the host, the id or a setting of the words file. The words file
reaches a verdict only by failing to load, which is exit 2, so with the same nomos version on both
machines and a words file that loads on each, a message accepted where it is sent is accepted where it
arrives; every machine that checks the principal's mail installs the same file. A sender whose team segment is `local`, or that has no team segment, is a
person and gets no rule. Toward a person (the same address form), every agent message of kind
request, message or reply carries a plain title on line 1 that opens with no bracketed text, since a
person's title is not a tag line, a valid block on line 2 of one of the seven kinds (an `answer` block
is the person's reply, never an agent's), and the footer `nomos v0 human message` as its last line,
matched as the inbox page matches it (10.5, 10.7); the block keeps the field rules of 10.7
and 10.8 that the inbox page applies, and JSON with no comment or repeated key; a block of an ask kind
goes in a request with a deadline, and a request's block is an ask (10.5, 10.6); an ask's text names
each option's label and id and states the request's deadline within five minutes (10.7). A
withdrawal to a person gets advice only. Between agents nothing is refused in this version; a reply
opening with `[progress]` gets advice (5.3), since a brief may ask for that reply. Everything else the hook flags, from relative dates to a missing file or a zoneless
clock in a block, is advice that `nomos check` never refuses.

The deadline is read in the text after the block, as a date (`YYYY-MM-DD`, or `DD/MM` with an
optional `/YYYY`), an optional word between, and a clock (`HH:MM`, `HHhMM` or `HHh`), with an optional
zone (`Z`, `UTC`, `GMT`, `UTC-3`, or an offset, in parentheses or not) and an optional `AM` or `PM`.
Only a time written with its zone states the deadline, as 5.3 asks for an absolute time and zone; a
time without one never counts, whatever the words file says. A time without a date is read on the
deadline's date in its own zone or the day before or after, whichever is nearest. `[zone]` is a fixed
offset that only the composer and advice use, so a zone with daylight saving needs the file rewritten
at each change.

`nomos compose send|ask|reply --to ADDRESS` builds a body and prints it on stdout, with its advice on
stderr as `advice SECTION reason`, and exits 1 without a body and without advice when the rules of
`nomos check` refuse it, printing only their reasons, or 2 on a usage error or an empty text. It never sends. The text comes from `--text FILE` or stdin; `ask` takes
`--within DURATION` in keryx's form; `--from ADDRESS`, `--words FILE` and `--now TIME` are optional.
Toward an agent the body is the text. Toward a person it takes `--title TEXT` and the block, either
`--block FILE` with one JSON object of the fields or `--kind KIND` with `--option ID=LABEL` (split at
the first `=`), `--select one|many`, `--recommended ID`, `--default ID`, `--answer-text
optional|required`, `--blocks TEXT` or `--blocks-none`, `--meanwhile TEXT`, `--if-silent TEXT`,
`--outcome done|partial|failed`, `--follows ID`, `--replaces ID`, `--attach PATH=LABEL` and `--link
URL=LABEL` (both split at the last `=`). It writes the title, the block one key per line, the text,
a numbered list of the options (`N. LABEL (`ID`)`) when the text lacks a label or an id, the words
file's deadline sentence when the text states no time with its zone equal to the deadline, and the
footer.

```sh
bin/nomos compose ask --to ana.local@box --within 1h --title 'Where process decisions live' \
  --kind choice --option 'keep=Keep as it is' --option 'move=Move to the Project' --blocks-none \
  --meanwhile 'I continue with the file' --if-silent 'I keep it as it is' --default keep < text.md
bin/nomos check < envelope.json
```

The human's words come from one file at `/etc/nomos/words`, in the `--words` format above, read by
both commands; without it they use English, the only language built in. `nomos compose --words FILE`
and `nomos check --words FILE` read another file for tests. A sender that composes with
`nomos compose`, checks with `nomos check` and sends with `keryx send`, `ask` or `reply` installs the
check for keryx: a root-owned copy of `lib/nomos` under `/usr/local/lib/nomos`, holding only regular
files and directories, in a directory named by the digest of its files, a root-owned wrapper in a
regular file there whose first line is `#!/usr/bin/ruby --disable-gems` and that loads that one
copy, the words file with `/etc/nomos` root's, and last `/etc/keryx/check` with only `command` naming
the wrapper and `timeout = 5`, each directory above them root's and not group or other writable,
with no link on the path. That is the principal's step on each machine. A broken words file makes
every check exit 2, so the installer stages the new copy and wrapper beside the live ones, runs the
staged wrapper unprivileged on an accepted and a refused message with the words file it will install,
and only then replaces the live wrapper, last, by a rename; a refused upgrade leaves the live copy and
wrapper as they were. It prints the digest so the principal can compare it with the reviewed
revision.

`nomos check` cannot judge whether the text and the block agree beyond labels, ids and the deadline,
whether a `default` is reversible, whether `if_silent` waits, whether a file in the block opens on the
page, whether a reply carries what its request asked for beyond the `[progress]` tag, or anything
that needs the clock, a mailbox or another message.

The optional [readback comparator](bin/compare-readback.rb) compares the five items in protocol 9.2
against the first prompt's delegation record. It needs Ruby 3.3 or later and only its standard
library; CI tests Ruby 3.3 and 4.0. Run it after saving the record and the readback as text files.

```bash
ruby bin/compare-readback.rb --record first-prompt.txt --readback readback.txt --brief brief.txt --json
```

Pass `--brief` with records made from `templates/first-prompt.md`, which has no task value, and
omit it only when the record already supplies that value. Omit `--json` for the same values in lines.
The JSON object contains `fields`, keyed by `address`, `role`, `task`, `authority` and `next_action`.
Each has `status` (`matched`, `missing` or `differs`) and `record` and `readback` arrays of literal
source spans. The task's record spans come from the brief when supplied. `authority_added` and
`authority_missing` list added atoms or unknown readback spans, and omitted atoms, respectively, `version` is the record's named NOMOS version
(such as `v0`, or `null` when no single version is named), and `limits` explains what needs human
judgment. Exit 0 means all five fields matched, 1 means at least one flag, and 2 means a usage or
file error. A flag is a warning, and only the director decides whether the readback is acceptable.

The readback should use five lines labeled `Address`, `Role`, `Task`, `Authority` and `Next action`,
or their translation into the readback's language. Begin `Task` with the first request's first line. In `Authority`, repeat granted acts and paths, prohibitions and reservations in the record's
words or a faithful translation into the readback's language. In `Next action`, state that you wait for
confirmation and what follows. Protocol 9.2 recommends this form; path summaries such as "the four
repositories" still flag missing resources. The comparator reads clauses beginning "I may", "I may not"
and "Reserved to {party} are". English is built in. `--words FILE` adds a UTF-8 vocabulary in
another language, kept outside the repository, with blank lines and `#` lines skipped and `[section]`
headers, an unknown section being a usage error. The label sections are `[label-address]`,
`[label-role]`, `[label-identity]`, `[label-task]`, `[label-authority]`, `[label-next-action]` and
`[label-redelegation]`; `[roles]`, `[acts]` and `[scope]` take `phrase = canonical` lines naming a
built-in role, act or scope word; `[grant]` holds first-person permission openers, `[reserved]` holds
`PREFIX {party} SUFFIX` templates, and `[negation]`, `[wait-negation]`, `[auxiliary]`, `[wait]`,
`[wait-verb]`, `[first-person]`, `[possessive]`, `[contrast]`, `[conjunction]`, `[copula]`,
`[identity]`, `[article]`, `[permission]`, `[redelegation-no]` and `[redelegation-yes]` hold literal
words or phrases, with no stems or patterns. (LOG, 2026-10-26, local vocabulary; low) Unknown sentences
under `Authority` can match whole record sentences after case, spacing, punctuation and you/I, your/my, yourself/myself
and yours/mine normalization; matching a fragment never exempts an added claim.

The comparator also recognizes the template's sentences, numbered fields 3 to 6, and an opening
address and role after an optional tag, including fixed English and Portuguese role words.
Labels may start a line or sentence and use a colon, period, `is`, or its Portuguese counterpart,
with at most eight connecting words; Markdown headings also work. With `--brief`, the task value
must start with the brief's first content line after normalization, so added detail can match. Without a
task source it stays `missing`. An explicit `Next action` takes precedence over the template's
wait instruction. When the record calls for waiting, fixed confirmation phrases in `WAIT` may
precede every act in the value and be affirmative; they do not authorize that step. A record that is
not template-shaped, such as a free-prose root record, can give authority and next_action `missing`.

Authority comparison assigns grant, prohibition, reservation and redelegation per atom, with
negation, and extracts paths, addresses and a fixed vocabulary of acts. The English and Portuguese
forms and conjugations are in the script's vocabulary tables. A reservation and the same prohibition satisfy each other.
A summary can match while changing word order.
Missing granted acts, paths or addresses, prohibitions, reservations and redelegation terms are flagged.
Extra affirmative grant atoms are flagged as possible additions. Unknown authority wording also flags a
difference and its original span appears in `authority_added`. Authority continues until the next known
field. Modals split before polarity is assigned; semicolons and bare contrasts cannot extend a negation.
Outside recognized authority clauses, restricted acts that are never granted also flag. A granted act
with an absolute, home or variable path outside its clause's granted paths flags; relative paths there
are not checked. A message grant counts as send in this outside scan only, and an ungranted transport
recipient also flags. These checks do not resolve action-to-resource bindings inside a clause.
Paths are normalized lexically for trailing slash, dot and parent segments, without expanding home or
variables or resolving symlinks. An Address value uses its first address without a session suffix.
An extra restriction flags a missing grant only
if it names a granted act or resource; unrelated extra restrictions do not flag. The original clauses
remain in the spans. These are lexical comparisons, not proof that a grant is valid or wider.
Conditions, which action applies to which resource, expiry, external records, other languages and
semantic equivalence need human review. The comparator never reads a file mentioned in the text,
makes a transport call, stores state or grants permission. Each input must be a regular UTF-8 file
without NUL bytes, at most 64 KiB; capped reads reject growth beyond that bound. Quoted lines and
fenced examples do not supply fields. Text output JSON-encodes each value on its own line to preserve
spans and escape embedded newlines.

## 5. Write your local layer

Keep your machine names, accounts and local rules in your own instructions, separate from the nomos
repository. Put them where your harnesses load them, such as your CLAUDE.md, AGENTS.md, rules or
memory. Cover at least these.

- Machines, their keryx host names, and which harnesses run on each.
- Accounts and quota pools, which roles may draw from which pool, how to see how full each is, and
  any account you may not use for some kind of work.
- The principal's reserved decisions, starting from the playbook's list (What a delegation record
  usually reserves), and whether the orchestrator may merge.
- The principal's writing rules, language for each audience, and the checks that enforce them.
- Commit rules (signatures, trailers, what must never appear).
- Where the run's files live (decision log, run log, checkpoint, roster, roadmap, progress, briefs,
  probes, delegation files; protocol 9.5).
- Where you installed keryx from and which release each machine runs; record the revision too if
  you use a source build.

When nomos says "the local layer", it means these instructions.

## 6. Start the orchestrator

1. Make a directory for the run's state with a charter (the goal, the team, the open questions), an
   empty decision log (decisions.md), empty run log (run-log.md) and checkpoint.md. Use `templates/roster.md`,
   `templates/roadmap.md` and `templates/progress.md` for the three team files. The orchestrator keeps
   roster current on member or launch changes, roadmap on phase, ask or decision changes, and progress
   on each principal ask and changes to its state or dependencies, before reports and handovers.
   One state file that holds the six forms as headed sections is an allowed equivalent when each
   form keeps its fields and update points. (protocol 9.5; playbook, State kept outside sessions;
   LOG, 2026-10-26, team files; low, one instance; LOG, 2026-10-26, one state file; low)
   Check the project's effective git identity against the root record using section 8's checklist
   before any member commits.
2. Write the orchestrator's first prompt from `templates/first-prompt.md` into a file in that
   directory, naming your principal as the delegator and the channel they will use. In the example,
   Ana says, "Ana talks to you here, in this session." State what the orchestrator may grant the
   members it starts, whether it may merge, and the reserved decisions.
   If the principal uses a transport inbox, name its full address, host included, in the root form.
   Every team uses that same address. Follow [protocol 10.2](protocol.md#10-the-human) and
   [the keryx binding's human channel](keryx.md#the-human) for its relay and message rules. Keep this
   session as the channel until section 8 proves the route, and whenever the inbox host is
   unreachable. A message from the principal's own inbox named in the root record is the
   principal's word for reserved acts and record changes too.
   When the team commits, name the author and committer identity its commits carry and how it is
   applied, through repository-local configuration by a named authorized actor or exact per-commit
   flags granted to the committing members. The second and third reading-only runs correctly
   escalated the missing identity before any commit; their records granted commits but omitted it.
   (LOG, acceptance 3, 2026-10-23, commit identity; low)
   Name the repository's base branch and whether it has a remote and CI. The examples use
   `origin/main` with a remote named origin, otherwise local `main`; use the actual names when they
   differ. A local run needs neither a push nor a pull request. Without CI, name the gate commands
   the orchestrator will run on the candidate head in a clean worktree. (LOG, acceptance 1,
   stumbles 1 and 11; low)
   Before using `keryx spawn`, the director checks `wc -c < FIRST_PROMPT_FILE`. In keryx 0.1.0
   on 2026-10-23, `--prompt` refuses more than 2,048 bytes. If the record exceeds the limit, keep
   it in a file the session may read but may not edit. Pass a short first prompt naming its absolute
   path and saying, "Read {absolute record path} before acting. That record binds you as if written
   in this first prompt. You may not edit it." Check that prompt's byte count too. The third run used
   a read-only file for a 2,840-byte record and a 348-byte prompt. (LOG, acceptance 3, 2026-10-23,
   prompt limit; low)
   Keep the Reading map command from the root form in the first prompt itself, including the short
   file-reference prompt. A direction to the top of bootstrap.md led the third leader to read the
   whole file. (LOG, acceptance 3, 2026-10-23, map command; low)
3. Open a herdr tab for the team and start the orchestrator in it, in the harness and model you trust
   most for judgment, with the prompt as the harness's own initial argument, which survives startup
   dialogs (HN27), such as `claude -n orq "$(cat FIRST_PROMPT_FILE)"`. Codex and `cursor-agent` take
   the initial prompt the same way, as their last argument.
4. Decide whether the orchestrator holds its address.
   - Holding it gives native bells and the stop hook. The orchestrator runs
     `keryx join orq.alpha --role orchestrator` and then uses keryx like any member.
   - When its harness would turn each bell into an approval dialog (HN10), it creates the address and
     lets it go, with `keryx join orq.alpha --role orchestrator && keryx leave`. From then on every keryx
     command it runs carries `--as orq.alpha`, including `inbox`, `read`, `reply`, `ask`, `send`, `status`
     and `spawn`. The stop hook ignores a session that holds no address, so the orchestrator starts
     the watcher loop of the playbook (Keeping the orchestrator light) as a background command of its
     harness, and starts it again after every compaction or relaunch. Section 8 checks this mode
     separately.
5. The orchestrator tells the principal, in a few lines, what it understood and what it will do
   first, and records the principal's answer in the decision log in their own words.

## 7. Start the first team

1. Give each writing member its own worktree, and the reviewer a detached one. Use the base named
   in section 6. For a repository with origin, fetch it and use `origin/main`.

       git -C ~/src/shop fetch origin &&
         git -C ~/src/shop worktree add -b impl-1/retry-fix ~/src/shop-impl-1 origin/main &&
         git -C ~/src/shop worktree add --detach ~/src/shop-rev-1 origin/main

   With no remote, branch from local `main` without fetching.

       git -C ~/src/shop worktree add -b impl-1/retry-fix ~/src/shop-impl-1 main &&
         git -C ~/src/shop worktree add --detach ~/src/shop-rev-1 main

   The reviewer checks out the candidate head detached in its own worktree, whether it arrives in a
   pull request or as a local branch. Without CI, the orchestrator runs the gate commands on that
   head in a clean worktree before merging (playbook, Merge rules). (LOG, acceptance 1, stumbles 1
   and 11; low)

   After the merge, `git -C ~/src/shop worktree remove ~/src/shop-impl-1` removes a member's tree
   only when the record grants cleanup; otherwise propose it to the principal.
2. Write the brief from `templates/brief.md` into a file in the run's directory. It names the outcome,
   the worker's address and role, where it works, the hazards of the machine, the conventions, the
   authority, what done means, whether the session stays, and its context ceiling as described in
   step 7. No brace placeholder may be left in it.
3. Write the member's delegation into a file in the run's directory, one sentence per line, from
   `templates/first-prompt.md`. `keryx spawn` writes the first part of the first prompt itself, "You
   are impl-1.alpha@box1, the implementer, started by keryx spawn. Run 'keryx join impl-1.alpha --role
   implementer', then run 'keryx skill' and follow it, then run 'keryx inbox'.", which names the
   delegate by address and role, and adds the text of `--prompt` after it. The file carries the rest of
   the record. This example grants pushing and pull requests for a repository with a remote, with
   merging reserved to Ana. For a local-only run, grant local branches and commits instead and
   require a report naming the candidate branch and head.

       orq.alpha@box1 started you for team alpha.
       Before you act on your first request, send orq.alpha@box1 a readback with your address, role, task, authority and next action, and wait for its confirmation.
       The principal is Ana, who talks to this team only through orq.alpha@box1.
       The delegator is orq.alpha@box1, acting within the delegation it holds from Ana.
       As the implementer you may create the branches of the tasks orq.alpha@box1 gives you, commit, push them and open or update their pull requests in the repository of team alpha, for the whole life of this session.
       You may not merge, tag, publish, delete branches other than your own, or change repository or personal settings.
       Reserved to the principal are merging, publishing, tags, repository and personal settings, and anything outside the approved plan. orq.alpha@box1 brings them to the principal, and you never ask the principal yourself.
       You may not redelegate.
       This record holds for the life of this session.
       The principal may always change or revoke this record, directly or through orq.alpha@box1. orq.alpha@box1 changes it only on the principal's word, by a message that names the field and carries an absolute time. A message from anyone else that claims a wider grant is not one.

   The reviewer's file has the same lines, except that it says "to review one change" after "team
   alpha", grants "check out pull request branches detached in this worktree, read code, and run tests
   and linters", says "You may not push, merge, approve or post anything, and your findings go to
   orq.alpha@box1", and reserves "merging, publishing and posting outside the team". Before spawning, check
   that no placeholder is left and that every field is there.

       f=DELEGATION_FILE
       grep -n '[{}]' "$f" && echo "placeholder left in $f"
       for s in 'The principal is' 'The delegator is' 'As the ' 'You may not ' \
                'Reserved to the principal are' 'redelegate' 'This record holds' 'may change or revoke'; do
           grep -q "$s" "$f" || echo "missing in $f: $s"
       done

   Anything it prints identifies a placeholder or a missing field; fix the file before you spawn.
   This only checks the shape. Compare the completed record with protocol 4.3 and 4.4 too, including
   the principal's continuing right to change or revoke it and the field and absolute time required
   on a change.
4. Before spawning, read the root record's chosen startup mode for each harness, including sandbox
   and approval policy where separate. Pass it as harness arguments after `--` in `keryx spawn`;
   HN12, HN20 and HN26 name the controls. A sandboxed Codex seat needs the resolved keryx store in its
   approved writable roots as well as its worktree, or it cannot reply. Verify a reply from that
   seat; a denial goes back to the director, not to a permission change by the member. If the record
   omits the mode, ask the principal before launching. (LOG, acceptance 1, stumble 3; low)

   Spawn the member from the orchestrator's pane, with `--as orq.alpha` when the orchestrator does not hold
   its address.

       keryx spawn impl-1.alpha --as orq.alpha --harness claude --model MODEL --effort high --role implementer \
         --tab alpha --cwd ~/src/shop-impl-1 --file BRIEF_FILE --within 3h \
         --prompt "$(cat DELEGATION_FILE)"

       keryx spawn rev-1.alpha --as orq.alpha --harness codex --role reviewer --tab alpha --cwd ~/src/shop-rev-1 \
         --file REVIEW_BRIEF_FILE --within 90m --prompt "$(cat REVIEW_DELEGATION_FILE)"

   Each team uses its own segment, such as `impl-1.alpha` and `impl-1.beta` on the same machine.
   Use full `MEMBER.TEAM@HOST` addresses in delegation records and readbacks.
5. Read the new pane's screen and answer its dialogs at once under protocol 9.1, by the member's
   record and the principal's standing rules, such as "Continue without trusting" for Codex hooks.
   Allow once what the record grants, never the option that changes a setting or stops later prompts,
   and decline what the record does not grant or reserves. Hook trust, folder trust or a setting change
   is granted only where the record names it with its configuration effects and directory (HN02, HN20,
   HN26). Bring the principal, at once through the declared channel, only a dialog none of these
   covers or one your harness will not let you answer, and never leave one to time out or to an
   automatic deny. spawn answers no dialog; the session joins once it is answered, even after timeout
   status 3 (HN28). keryx also tells the director about a dialog that stops a session long after its
   join. Read `keryx who` before spawning again. Name the pane with `herdr pane rename PANE NAME`.
   Since keryx 37056f1 the dialog notice and the keryx skill say the same; the notice grants nothing.
   (LOG, 2026-10-23 08:44 and 09:01 UTC-3, spawn dialog authority; LOG, field PR 27, dialog notices;
   N17; LOG, 2026-10-26, unanswered dialogs; low, three earlier quoted dialogs without a recorded
   grant, the principal's standing instruction and one incident)
6. Wait for the member's readback by mail and compare it, line by line, with the delegation file and
   the brief. A join is not readiness (protocol, The session life cycle and handover). A readback that
   misses a field, or adds authority, gets a correction before the member acts.
7. Set the stored ceiling so its 80% notice falls at the intended handover trigger; the brief sets
   no separate lower token stop. The member reads `keryx who` after each work unit. (playbook,
   The ceiling; LOG, field PR 26, stop lines; low)
   Tell each member its ceiling in tokens in its brief, by the window it actually runs at, and note in
   the run log how you will read its figure (playbook, Context policy). Record the context keryx stamps
   on each seat's first message, its readback, including your own. It already includes join, skill and
   inbox, so do not call it a measurement before those commands. The ceiling counts the harness's
   initial load, nomos and the task; do not subtract that load or silently raise the ceiling.
   (LOG, acceptance 1, stumble 4; low) You know the window from the
   model and setting you chose; for Claude Code nothing on the session's side gives it (HN16).

   Use playbook, The ceiling. On 1M, state-in-files roles stop at the first readback's stamped
   context plus 250K; the orchestrator and read-heavy roles with current progress and coverage files
   use that figure plus 350K, never above 500K. The orchestrator's window must meet that section's
   join-cost condition. Other windows keep the table's figures, including 125K and 180K at 258,400.
   Read-heavy work needs a progress file and coverage map current after each finding. If keryx cannot
   measure the harness, read its footer each heartbeat or route elsewhere. (LOG, field audits of
   fde5548; LOG, 2026-10-23 about 08:12 UTC-3, 1M ceiling; low)

   Where the client has a status line that shows the window, read it after start, never infer it
   from a model list (HN23). For Codex read the rollout (HN21); for Claude Code use the window the
   spawner's setup supplies (HN16). At each check, also see whether the member's output file grows,
   and send a stop early enough for the harness to deliver it (HN25, HN34).
8. To close a member, ask it to run `keryx leave`, wait until `keryx who` shows the address free, then
   exit the harness and close the pane.

## 8. The first ten minutes

Run these in order and stop at the first that fails. A failure here means the team must not start
yet; fix it and run the checks again from the one that failed. List this team's full addresses from
section 7, including its orchestrator and the terminal addresses used for the probes below. Status
is machine-wide; inspect only rows whose sender or recipient is in that list. Open work requests from
section 7 are expected at this point; the ping checks require only their own request ids to close.

1. `keryx version` matches on every machine, and `keryx whoami` prints the right host.
2. `systemctl --user is-active keryx-courier` says active on every machine that runs the courier.
3. `herdr status` shows a server version you recorded in the run log.
4. A round trip works on one machine. From a terminal, run `keryx ask orq.alpha "ping, reply with pong"
   --within 10m`. An orchestrator that holds its address is rung, reads it and replies. One that does
   not hold it sees its watcher loop end, then runs `keryx read --as orq.alpha ID` and
   `keryx reply --as orq.alpha ID pong`. Either way, the terminal's `keryx inbox` then shows the pong from
   orq.alpha. Read that reply and confirm it answers the id returned by the ping's `ask`; that id must no
   longer appear in OPEN REQUESTS in `keryx status`. Other open work requests do not fail this check.
5. With two machines, a round trip works across them. On box2, `keryx whoami` in a terminal prints
   its address, such as ana.local@box2. From a terminal on box1, `keryx ask ana.local@box2 "ping, reply with pong"
   --within 10m`; on box2, `keryx read` and `keryx reply ID pong`; back on box1, `keryx inbox` shows
   the pong. Read it and confirm it answers the id returned by that ping's `ask`; that id must no
   longer appear in OPEN REQUESTS in `keryx status`. Other open work requests do not fail this check.
   A plain `keryx send` proves only one direction.
6. In `keryx status`, filter NOT FORWARDED and NOT RUNG by the team's address list above; no team
   message may remain in NOT FORWARDED. No team message may remain in NOT RUNG for an address that
   should receive native bells. For an orchestrator using the watcher mode of section 6, confirm that
   its watcher woke and it read the message instead; that mode intentionally has no native bell.
   If the record names the principal's inbox, also prove that route before relying on it. Send a
   notice to the exact full address, check its arrival in the destination mailbox, and check that
   the sending host has nothing waiting to be forwarded to it (protocol 10.2). Record the message
   id and both observations. The generic ping in step 5 does not prove this inbox's route.
7. The stop hook fires, in each harness where it is installed (section 4). In a member's session,
   leave a request unanswered and end a turn; the hook reminds it. Trusting the hook in Codex is the
   orchestrator's act under its own record, never a member's.
   Before wiring the optional pre-send adapter on each Cursor version, recheck that its `allow`
   response leaves Cursor's own approval checks in place, following HN37. Include a command outside
   the allowlist and one needing sandbox escalation. If it grants execution,
   stop wiring and revise the adapter. Run any live probe only with authority for its settings and
   dialogs in an isolated session. In each wired harness, run a flagged body through a fake keryx
   executable in that isolated session. Confirm that the hook denies it, exposes the flags and
   leaves the fake's log empty. Run a clean control and verify that the fake then logs it. On Cursor,
   that control also catches a misspelled --harness, whose empty answer has no documented meaning. Test
   each named tool path; PowerShell must warn, not claim a POSIX body check. Do not send a live
   message for this exercise. A successful manual --check alone does not prove the hook is wired.
8. Each member's readback names its full address, role, task, authority and next action, and matches
   the delegation file and the brief you sent.
9. You can read each member's context figure, by the method for its harness named in section 7.
   For Codex, the command of HN21 prints a time and two numbers; an error or an old time means you
   cannot measure that seat yet.
10. Your entry files load. Ask a new session of each harness what nomos says about must-fix findings,
    and see it answer from the protocol, not from guesswork.
11. Check the effective author and committer identity against the root record from section 6. Before
    members commit, run `git -C ~/src/shop var GIT_AUTHOR_IDENT` and
    `git -C ~/src/shop var GIT_COMMITTER_IDENT` in each writing worktree, with the configuration,
    per-commit flags and environment the record names for commits. An environment override can
    change either identity. If either differs or the record names no identity or application method,
    stop commits and ask the director; a setting change belongs to whoever the record authorizes.
    Escalation was correct under both reading-only runs' incomplete records. (LOG, acceptance 1,
    N3; LOG, acceptance 3, 2026-10-23, commit identity; low)

## 9. The acceptance exercise

Give the new team a small real task and run it to a merged result with the recipe in the playbook
(Building a feature). Run the merge step under both kinds of record. With a record that reserves
merging, the orchestrator sends the principal a proposal naming the change, its head commit and the
gates' evidence, and merges on the principal's own answer. With a record that grants it, the
orchestrator merges once the gates pass and reports the merge. Each case ends with a next step the record names (playbook,
Merge rules).

Then rehearse the failures a team will meet, one at a time, and check that ownership and authority
stay clear in each. Name the disposable resources in the brief before you start, a scratch repository
or branch, a scratch herdr server and a temporary keryx store, and run the rehearsals only there. Try
a refused request, a bell that does not reach its session, a member interrupted mid-task and replaced
from its handover note, a conflicting edit between two worktrees, and a result that does not meet its
criteria. Wherever the team stumbles, the documents miss something; write it down for the next
version. This scenario set is a proposed evaluation, not a measured result of the cited sources.
(S11, S37, N01; low)

## 10. End the run

Use the inventory and commands in `playbook.md`, Cleanup. Run the relevant rows at every task end
and swap too; this checklist closes the whole run. Check only resources this run created, and remove
only what its record grants. The principal decides reserved removals. (protocol 4, 9; LOG, acceptance
1, stumble 12; LOG, 2026-10-23 about 08:45 UTC-3, cleanup; low)

- [ ] Decide each delivered result and settle or transfer each open request; check the team's ids in
  `keryx status -o json` and name the holder of anything still pending.
- [ ] After a Codex member leaves, send `/quit` or `/exit` with `herdr pane send-text`, pause about
  one second, then send Enter with `herdr pane send-keys`. Check that the process exited; immediate
  Enter can leave the text in the composer. (HN35; LOG, field PR 25; LOG, 2026-10-23 09:00 UTC-3; low)
- [ ] Confirm departing members ran leave, exited and have no surviving harness process before
  closing their panes; compare `keryx who --all -o json | jq '.addresses[]'`, `herdr pane process-info --pane PANE`,
  `ps -p PID -o pid=,lstart=,args=` and `herdr pane list` with the inventory.
- [ ] Account for every run-created address with `keryx who --all -o json | jq '.addresses[]'` and
  `keryx status --all -o json`. In 0186dcd, who returns `{view, hidden, addresses}`; iterate
  `.addresses[]`, not the top level. `--all` includes inactive addresses hidden by the short view.
  Under the record run `keryx retire ADDRESS` on its host; it refuses a live holder or an open
  request in either direction. Save its success output and confirm absence from both full lists.
  Retirement keeps files, refuses mail and is hidden even with `--all`; absence alone proves
  nothing. `keryx join MEMBER.TEAM --revive` restores the mailbox when authorized. Otherwise record the
  retained address and reason. (LOG, 2026-10-23 09:43 UTC-3, address retirement and list shape)
- [ ] Check merged branches and worktrees for live users and unsaved or unmerged work with the
  Cleanup commands. Remove under the cleanup grant or propose the exact resources to the principal.
- [ ] Preserve report evidence and check all recorded scratch paths, temporary files and test
  directories. For each covered removal verify `test ! -e PATH && test ! -L PATH`; list retained paths
  with their reason and holder.
- [ ] Stop or hand over all recorded loops, heartbeats and watchers; use PID and scheduler checks to
  prove the old instances ended and any continuing instance has its new holder and next check.
- [ ] If the run created a status board, stop its watch process and close its pane; verify the
  recorded PID is gone and the pane is absent from `herdr pane list`.
- [ ] Check the exact harness trust entries this run added against the saved pre-run entries. Remove
  only with the settings grant and only at run end, preserving other changes; otherwise propose the
  entries to the principal and list them as retained. Repeat the scoped `rg` check from Cleanup.
- [ ] Save the closing inventory with each resource's disposition, reason, holder, command, output,
  exit code and time. Report cleaned and retained items through the declared principal channel, then
  leave and exit the final session, naming who will verify and close its pane.

nomos v0 bootstrap
