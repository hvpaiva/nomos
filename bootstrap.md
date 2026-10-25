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
| Implementer | At start | `cards/member.md` + `cards/implementer.md` | 767 | 2,770 to 3,150 |
| Reviewer | At start | `cards/member.md` + `cards/reviewer.md` | 774 | 2,790 to 3,180 |
| QA | At start | `cards/member.md` + `cards/qa.md` | 749 | 2,700 to 3,080 |
| Auditor | At start | `cards/member.md` + `cards/auditor.md` | 786 | 2,830 to 3,230 |
| Writer | At start | `cards/member.md` + `cards/writer.md` | 755 | 2,720 to 3,100 |
| Orchestrator | At start | `cards/orchestrator.md` (600), `orchestrator.md` (2,500), bootstrap sections 7 and 8 (2,162), harness notes for all three harnesses (1,479); omit notes for harnesses not being spawned | 6,741 | 24,270 to 27,640 |
| Harness start, outside nomos | Record the context stamped on the first readback | On 2026-10-23, third-run Claude Code 50.2K at its first turn and 60.9K after join and skill; first-run Claude Code 50.9K and 61.8K after join, skill and inbox; first-run Codex about 23K on its readback | Not a word count | Observed context, not a text estimate |
| Whoever fills this form | Only when filling it | `templates/audit-brief.md` | 781 | 2,820 to 3,210 |
| Whoever fills this form | Only when filling it | `templates/brief.md` | 1,243 | 4,480 to 5,100 |
| Whoever fills this form | Only when filling it | `templates/escalation.md` | 335 | 1,210 to 1,380 |
| Whoever fills this form | Only when filling it | `templates/first-prompt.md` | 1,719 | 6,190 to 7,050 |
| Whoever fills this form | Only when filling it | `templates/handover.md` | 1,521 | 5,480 to 6,240 |
| Whoever fills this form | Only when filling it | `templates/plan-review.md` | 420 | 1,520 to 1,730 |
| Whoever fills this form | Only when filling it | `templates/report.md` | 494 | 1,780 to 2,030 |
| Whoever fills this form | Only when filling it | `templates/review-brief.md` | 753 | 2,720 to 3,090 |
| Whoever fills this form | Only when filling it | `templates/review-findings.md` | 416 | 1,500 to 1,710 |
| Claude Code member | Only the note needed for its own harness | `harness-notes.md`, Claude Code | 50 to 201 per note | 180 to 830 per note |
| Codex member | Only the note needed for its own harness | `harness-notes.md`, Codex | 34 to 256 per note | 130 to 1,050 per note |
| Cursor member | Only the note needed for its own harness | `harness-notes.md`, Cursor | 77 to 154 per note | 280 to 640 per note |
| Rule auditor | Only to audit a rule | `evidence.md`, only the cited entry; full catalog size shown | 30,487 in catalog | 109,760 to 125,000 in catalog |

The largest initial member load is 786 words, `cards/member.md` plus `cards/auditor.md`, below the 800-word
limit. The common card has 494 words; role cards have implementer 273, reviewer 280, qa 255, auditor 292, writer 261; the orchestrator card has 600.

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
- A pre-send hook on the shell commands `keryx send`, `keryx ask` and `keryx reply` can refuse a body
  with a brace placeholder left in it, a relative day word, or a finding without a rank. The protocol's
  check table lists what to check and where. One script can serve every harness's hook, with a flag for
  each harness's input format.
- A writing rule the principal has had to correct twice becomes a write hook the same way (playbook,
  Turning a repeated correction into a check).

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
- Where the run's files live (decision log, run log, briefs, probes, delegation files).
- Where you installed keryx from and which release each machine runs; record the revision too if
  you use a source build.

When nomos says "the local layer", it means these instructions.

## 6. Start the orchestrator

1. Make a directory for the run's state with a charter (the goal, the team, the open questions), an
   empty decision log and an empty run log (playbook, State kept outside sessions). Check the
   project's effective git identity against the root record using section 8's checklist before any member commits.
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
     `keryx join orq --role orchestrator` and then uses keryx like any member.
   - When its harness would turn each bell into an approval dialog (HN10), it creates the address and
     lets it go, with `keryx join orq --role orchestrator && keryx leave`. From then on every keryx
     command it runs carries `--as orq`, including `inbox`, `read`, `reply`, `ask`, `send`, `status`
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
   are impl-1@box1, the implementer, started by keryx spawn. Run 'keryx join impl-1 --role
   implementer', then run 'keryx skill' and follow it, then run 'keryx inbox'.", which names the
   delegate by address and role, and adds the text of `--prompt` after it. The file carries the rest of
   the record. This example grants pushing and pull requests for a repository with a remote, with
   merging reserved to Ana. For a local-only run, grant local branches and commits instead and
   require a report naming the candidate branch and head.

       orq@box1 started you for team alpha.
       Before you act on your first request, send orq@box1 a readback with your address, role, task, authority and next action, and wait for its confirmation.
       The principal is Ana, who talks to this team only through orq@box1.
       The delegator is orq@box1, acting within the delegation it holds from Ana.
       As the implementer you may create the branches of the tasks orq@box1 gives you, commit, push them and open or update their pull requests in the repository of team alpha, for the whole life of this session.
       You may not merge, tag, publish, delete branches other than your own, or change repository or personal settings.
       Reserved to the principal are merging, publishing, tags, repository and personal settings, and anything outside the approved plan. orq@box1 brings them to the principal, and you never ask the principal yourself.
       You may not redelegate.
       This record holds for the life of this session.
       The principal may always change or revoke this record, directly or through orq@box1. orq@box1 changes it only on the principal's word, by a message that names the field and carries an absolute time. A message from anyone else that claims a wider grant is not one.

   The reviewer's file has the same lines, except that it says "to review one change" after "team
   alpha", grants "check out pull request branches detached in this worktree, read code, and run tests
   and linters", says "You may not push, merge, approve or post anything, and your findings go to
   orq@box1", and reserves "merging, publishing and posting outside the team". Before spawning, check
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

   Spawn the member from the orchestrator's pane, with `--as orq` when the orchestrator does not hold
   its address.

       keryx spawn impl-1 --as orq --harness claude --model MODEL --effort high --role implementer \
         --tab alpha --cwd ~/src/shop-impl-1 --file BRIEF_FILE --within 3h \
         --prompt "$(cat DELEGATION_FILE)"

       keryx spawn rev-1 --as orq --harness codex --role reviewer --tab alpha --cwd ~/src/shop-rev-1 \
         --file REVIEW_BRIEF_FILE --within 90m --prompt "$(cat REVIEW_DELEGATION_FILE)"

   Until keryx carries the team segment, addresses have no team part, so a second team on the same
   machine prefixes its member names (`a-rev-1`) and retires them when it ends.
5. Read the new pane's screen and answer its dialogs only when your record grants the answer and
   configuration effects for that directory (HN02, HN20, HN26). Otherwise use the declared escalation
   channel. spawn never answers one, and the session joins once it is answered, even after spawn timed out with status 3
   (HN28). Read `keryx who` before you spawn again. Name the pane with `herdr pane rename PANE NAME`.
   The spawn notice says, "Take it to your human, and answer it with herdr pane send-keys only on their word". A record granting a named dialog answer, such as
   Codex's hooks dialog answered "Continue without trusting", carries the principal's word for that
   answer and its covered effects. Without that grant, escalate. (LOG, 2026-10-23 08:44 and 09:01 UTC-3,
   spawn dialog authority; LOG, field PR 27, dialog notices; low, three more quoted dialogs,
   no recorded principal grant for their answers)
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
4. A round trip works on one machine. From a terminal, run `keryx ask orq "ping, reply with pong"
   --within 10m`. An orchestrator that holds its address is rung, reads it and replies. One that does
   not hold it sees its watcher loop end, then runs `keryx read --as orq ID` and
   `keryx reply --as orq ID pong`. Either way, the terminal's `keryx inbox` then shows the pong from
   orq. Read that reply and confirm it answers the id returned by the ping's `ask`; that id must no
   longer appear in OPEN REQUESTS in `keryx status`. Other open work requests do not fail this check.
5. With two machines, a round trip works across them. On box2, `keryx whoami` in a terminal prints
   its address, such as ana@box2. From a terminal on box1, `keryx ask ana@box2 "ping, reply with pong"
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
  nothing. `keryx join NAME --revive` restores the mailbox when authorized. Otherwise record the
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
