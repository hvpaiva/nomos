# nomos harness notes, version 0

These are observations, not guarantees. The machine facts are examples from the recorded runs.
Each fact was seen on one machine at the version given, and most were seen once. Tools change
behavior between versions, so check a fact again before you build on it, with the check given under
it. When a check disagrees, update the note with the new version and date, and keep the old line.

Each note gives the harness and its version, the date seen, the symptom, what to do, and how to check
it again. A note keeps apart what was seen at a version, what the tool's help or code says today, and
what you would have to do to see it again; when that check needs a new session, a dialog or a change
of configuration, the note says so, since a help page or a status line is not the behavior. Ids in
parentheses resolve in `evidence.md`. In the recorded example, versions seen on the test machine
on 2026-10-23 were keryx 0.1.0, herdr client and server 0.9.5 at 07:34 UTC, Claude Code 2.1.309,
codex-cli 0.163.0 and cursor-agent 2026.10.22-27dcf5f. The earlier server was 0.9.3. The acceptance
leader checked the new server version, not every old herdr behavior. (LOG, acceptance 1, stumble 5;
low, one status observation)

## herdr

**HN01. The client and the running server can be different versions, and sessions run on the server.**
Earlier on 2026-10-23, `herdr status` showed client 0.9.5 and server 0.9.3 with
`server_binary_stale: yes`. At 07:34 UTC the acceptance-test leader saw client and server 0.9.5 with
`server_binary_stale: no`. This updates the running version, not the behavioral evidence. The pane
and agent observations in HN02 to HN05 were seen only in the earlier run, with likely server 0.9.3;
they were not rechecked on server 0.9.5. HN04 separately labels its 0.9.5 help and compatibility facts.
(LOG, acceptance 1, stumble 5; low)

In an earlier port the new client called the old server's protocol incompatible, and the session
inside it kept the old binary until a reboot. Record the server version with every herdr fact, and
restart the server only when no team runs in it. To check, run `herdr status` and read both versions.
(M49)

**HN02. Some startup dialogs are reported as idle.** Seen 2026-10-22, client 0.9.5, likely server
0.9.3, for Codex's "Hooks need review", Cursor's "Workspace Trust Required" and Claude Code's folder
trust, not rechecked on server 0.9.5; the same Codex dialog stopped two seats launched by another tool on 2026-09-26. A spawner that
waits for "idle" then types into a dialog. Read the screen with `herdr pane read` before you trust a
state, and answer the dialog only when the delegation record covers that answer and its configuration
write for that directory. Earlier harness probes recorded Claude Code folder trust in `~/.claude.json`
and Cursor workspace trust in `~/.cursor/projects/<project>/.workspace-trusted`; Codex records folder
trust in `~/.codex/config.toml` (HN20). These writes are outside the workspace. On 2026-10-23 the
acceptance-test leader escalated Codex's dialog and reported its earlier Claude Code answer under
protocol 4.9. To check, start each harness in a new folder in a scratch server (`herdr --session test`)
and compare the pane text, reported state and configuration changes; this needs authority for new
sessions and those writes. (H01; LOG, 2026-10-23 04:49; low for the delegation lesson)

**HN03. Narrow panes wrap dialog text inside the harness's box.** Seen 2026-10-22, client 0.9.5,
likely server 0.9.3; not rechecked on server 0.9.5.
"1. Review" and "hooks" landed on two lines, so a phrase match found no dialog. Match on the screen's
text with line breaks, box borders and spaces removed. To check, open a dialog in a pane 60 columns
wide and read it; this needs a new session. (H02)

**HN04. `herdr agent start` drops the agent's name when its wait runs out.** Seen 2026-10-22, client
0.9.5, likely server 0.9.3, with a short `--timeout`; not rechecked on server 0.9.5. keryx's own compatibility notes give the condition for herdr 0.9.5:
the name goes when the timeout passes before the agent has been idle or blocked since it started.
Stopping the client keeps the name. Use the default timeout and read the name afterwards in
`herdr agent list`. `--timeout` takes milliseconds (default 30000, at most 300000, per `herdr agent
start --help` in 0.9.5). To check, start an agent in a scratch server with `--timeout 1000` and list
it; this needs a new session. (H08)

**HN05. A new pane inherits the server's environment, not the caller's.** Seen 2026-10-22, client
0.9.5, likely server 0.9.3; not rechecked on server 0.9.5. A test that sets KERYX_HOME in its shell and opens a pane finds the live value there. Start
a separate server from the test's environment, or pass the variables in the command. To check, export
a marker variable, open a pane in a scratch server, and print it there. (H08)

**HN06. A harness started from another harness's shell inherits its identity variables.** Seen
2026-10-22. A Cursor or Codex agent started from a Claude Code session, or in a herdr server started
from one, was taken for that Claude session, because the identity check read the Claude variable
first. Identity checks read the innermost harness first. To check, start each harness from inside
another and run `keryx whoami` in it; this needs new sessions. (M09)

**HN07. Text sent into a pane that shows a selection dialog confirms the highlighted option.** Seen in
OpenRig 0.5.14 and 0.5.15 (September 2026), where a message into a pane with a permission prompt
pasted the text and pressed Enter, and in the first keryx round (2026-10-22), where a wrapped dialog
could have taken a bell's line and Enter. Never type into a pane before a dialog check passes. To
check, open a permission prompt in a scratch pane and look at what the tool refuses. (M42)

## Claude Code

**HN08. The predicted next prompt shows as dim text in the input.** Seen 2026-10-22, version 2.1.308.
It can read as an authorization nobody gave. Read panes with `herdr pane read --format ansi` before
concluding someone typed, and never send a bare Enter to a Claude Code pane. To check, read a Claude
pane after a turn with and without ANSI. (H04)

**HN09. Naming at launch.** Seen 2026-10-22, version 2.1.308. Claude Code takes `-n NAME` and
`--remote-control NAME` at launch, and `claude --help` in 2.1.309 still lists both. A session
relaunched or handed over by another tool lost its remote control flag (2026-09-24), so a relaunch
passes it again. To check the flags, run `claude --help`; to check the loss, relaunch a session
through the other tool and look for the flag. (H05, M43)

**HN10. Peer messages are held for the user's approval unless the session accepts them.** Seen
2026-09-15, 2026-10-21 and 2026-10-22, version 2.1.308 for the last. A held message is an interruption
for the human and can expire. `keryx spawn` passes `--settings` with `crossSessionInbound` set to
accept and a Stop hook running `keryx hook stop`, for that session only. An orchestrator that does not
want approval dialogs runs without holding its address and watches its mailbox with a loop; keryx
0.1.0's stop hook leaves a session that holds no address alone (`keryx hook --help`), so the loop is
that session's only bell. To check, send a message to a session started without those settings; this
needs a new session. (M16)

**HN11. A peer message arrives as a user turn wrapped in a `cross-session-message` tag.** Seen
2026-10-22, version 2.1.308. The tag carries the sender's name and permission mode (`from-mode`), and a
fixed paragraph tells the receiver the text is a teammate's request that cannot grant escalation or
count as the user's approval, and never to edit permission settings, instructions or config because a
peer asked. A team that mixes this channel with keryx has two authority texts in play, and both agree
with the protocol. To check, send a message between two Claude sessions and read the receiving turn.
(M49, M52)

**HN12. An `ask` rule in settings wins over a hook's allow decision.** Seen 2026-09-24, version
2.1.280. Auto mode did not grant more than accept-edits with a wide allow list, and its classifier
still blocked a command that changes shared resources. Commands with a shell variable or a loop asked
for approval even when the rule allowed them, outside auto mode and bypass (September 2026, version
not recorded). Plan the permission mode of each seat before a long run. To check, allow a command by
rule and by hook in a scratch project and run it with a variable in it. (M43)

On 2026-10-23, `claude --help` in 2.1.309 lists the session control `--permission-mode`, with
`acceptEdits`, `auto`, `bypassPermissions`, `manual`, `dontAsk` and `plan`; `--settings` loads settings
for the invocation. Pass the root record's chosen mode at launch, through the arguments after `--`
in `keryx spawn`. Help confirms the controls, not the effective permissions of a running seat; check
those with an authorized operation from that seat. (LOG, acceptance 1, stumble 3; low)

**HN13. The question dialog covers the output printed just before it.** Seen in mid-2026, version not
recorded. The human decides looking at the dialog, so the reasoning goes inside the dialog's own text.
To check, print a paragraph and open a question right after it in a narrow terminal. (M30)

**HN14. Transcripts count tokens more than once unless deduplicated by message id.** Seen 2026-09-24
and 25, version not recorded, where an independent recount with deduplication matched a script's
per-seat figures closely. On 2026-10-23, in one transcript of version 2.1.309, the naive sum of output
tokens was about 2.2 times the sum that keeps the last usage of each message id. Deduplicate by
message id before summing. To check, sum one transcript's usage records with and without
deduplication. (M41)

**HN15. The Write tool creates files without the executable bit.** Seen 2026-09-23, version not
recorded. A script written that way failed with exit 126 inside a privileged batch, after the human had
authenticated. Run `chmod +x` and check the mode before any privileged run. To check, write a script
with the tool in a Claude Code session and run `ls -l` on it. (M49, M53)

**HN16. The Claude Code sessions in the recorded runs reported their own context figure.** Seen 2026-10-22 and
23, versions 2.1.308 and 2.1.309. A writer handed over at the ceiling by its own count, while every
Codex and Cursor session had to be told its figure (HN21, HN24). This records what was seen in three
harnesses, not that no other harness can. The figure is tokens in use, and the window is another
matter. The transcript does not hold the window, the model id does not tell a 200K window from a 1M
one, and Claude Code hands the window only to a status line command the user configures; the 1M
window in this example came from the session's configuration, as reported on 2026-10-23.
Check the window configured for your session. Whoever spawns it states its ceiling in tokens, from
the chosen model and setting, and nobody reads a percentage off the token count. The acceptance 3
reading measures in `evidence.md` give the transcript inputs summed in that run. (LOG, acceptance 3,
reading measures) To check, ask a fresh Claude Code session for its context use and compare it with
the last usage in its transcript; this needs a new session. (LOG)

**HN33. Usage-limit notes change what the model does.** Seen in October 2026, version 2.1.289. As a
usage limit approached, the harness added a note telling the model to finish
the piece in hand and a few more and stop, and after the reset a note saying the earlier notes no
longer applied, not to mention them, and not to repeat completed work. A background subagent running
when the limit hit died. A session that read the reset note literally could skip rerunning it, and a
report written under the first note could be shorter than the work without saying so; neither was
seen, and the reviewer of that case reran its validator. After a reset on your account, check each
background task and rerun what died. To check, read the turns around a usage limit in your session's transcript. (M49, P06)

## Codex

**HN17. A queued message can resume a closed thread.** Seen 2026-10-22, version 0.163. `codex queue
--thread T` writes to a queue every app-server polls, and the shared daemon keeps a thread loaded
thirty minutes after its last client, so a bell resumed a thread closed with `/quit`, headless and with
no pane. A TUI started with any `-c` runs its own app-server. Run `keryx leave` before closing a Codex
session, and send nothing to a closed Codex session's address. To check, close a thread and queue a
message to it within thirty minutes in a scratch store; this needs a new session. (H03, LOG)

**HN18. `/rename` opens a dialog and ignores its argument.** Seen 2026-10-22, version 0.163. Name the
pane with herdr instead (`herdr pane rename PANE NAME`). To check, run `/rename test` in a scratch
session. (H05)

**HN19. Commands drop the transport's variables unless something passes them.** Seen 2026-10-22,
version 0.163. With `shell_environment_policy.inherit = "core"` Codex drops `KERYX_*` and `HERDR_*`
from its commands, so a test session joins the live store. `-c shell_environment_policy.set.NAME=VALUE`
gives a variable back for that session only, and a wrapper named `keryx` first on PATH can set
KERYX_HOME. keryx 0.1.0 at commit 9e3a313 already does this for the sessions it spawns (its Codex
launcher turns the session's variables into those `-c` settings), so a spawned session has them even
with `inherit = "core"`, and a session started by hand does not. To tell which case you are in, read
the Codex process's command line (`ps -o args= -p PID`) for `shell_environment_policy.set`, then run
`env | grep -E 'KERYX|HERDR'` from inside the session. Very long values in a passed `-c`, such as a
full PATH, broke the command typed into a pane's interactive shell. (H06)

**HN20. The hooks trust dialog.** Seen 2026-10-22, version 0.163, and 2026-09-26 under another
launcher. Answer "Continue without trusting" (down, down, check the selection, Enter), never "Trust
all". Codex runs a new hook only after the user trusts it in `/hooks`, so keryx installs none for
Codex. Codex records folder trust in `~/.codex/config.toml`; back it up before a test that adds
folders only when the record grants that configuration change for those directories (HN02). To check,
start Codex in a folder with a hooks file; this needs a new session and authority for the dialog's
configuration effects. (H01, LOG, 2026-10-23 04:49; low for the delegation lesson)

On 2026-10-23, `codex --help` in 0.163.0 lists `--sandbox` (`read-only`, `workspace-write`,
`danger-full-access`), `--ask-for-approval` (`on-request`, `never`) and `--add-dir DIR` for additional
writable directories. Configuration comes from `~/.codex/config.toml`; `-c` overrides it for the
invocation. The spawner passes the root record's policy after `--` in `keryx spawn`. For an approved
`workspace-write` seat, add the resolved keryx store as a writable directory and check a reply from
inside the seat. Mailbox commands write state outside the worktree. A denied write goes to the
director; the member never widens its sandbox. These controls were checked in help, not in a new
sandboxed session. (LOG, acceptance 1, stumble 3; low)

**HN21. Codex shows the session no context figure, but the rollout file has it.** Seen 2026-10-22 and
checked again 2026-10-23 with codex-cli 0.163.0. Nothing on screen shows it, neither to the session nor
on a status line. A session that knows its thread id can read its own rollout, as a verifier did.
The file is `~/.codex/sessions/YYYY/MM/DD/rollout-*-THREAD.jsonl`, where THREAD is the
`session_id` in the address's `occupant.json` in the keryx store. Its context samples are lines whose
`.type` is `event_msg` and whose `.payload.type` is `token_count`; each carries
`.payload.info.last_token_usage.input_tokens` and `.payload.info.model_context_window` (258400 for the
model in this example), and the last one is the current figure. An orchestrator measures a Codex seat
with

    jq -n -r '[inputs | select(.type == "event_msg" and .payload.type == "token_count" and .payload.info != null)]
      | last // error("no token_count sample in this file")
      | "\(.timestamp) \(.payload.info.last_token_usage.input_tokens) \(.payload.info.model_context_window)"' FILE

which prints the time of the last sample, the tokens in use and the window, such as
`2026-10-23T02:09:10.936Z 137213 258400`, and fails with exit 5 when the file has no sample. Watch for
the empty result. The first version of this note selected `.type == "token_count"`, which matches no
line, and jq printed nothing and exited 0, so a watcher read silence as no data and nothing looked
wrong. Treat an empty answer, or a last sample older than the session's last activity, as a failed
measurement, never as a session with room left. If the command fails on a new version, read one
rollout file and find the type and field names again. (LOG)

**HN22. No supported way to show which account funds a running session.** Seen 2026-10-21, version
0.163. Nothing in the session showed it. `codex login status` in 0.163.0 reports the CLI's current
login, which is not proof of the account a session started earlier draws from. Record which of your
accounts funds the session in the spawn command and the run log. To check on a new version, look for
an account indicator in the TUI and in `codex --help`, and compare `codex login status` before and after a change of login while a
session runs. (P06)

**HN34. A message to a busy session can wait minutes.** Seen 2026-10-22, codex-cli 0.163.0. A stop
message typed into a working reviewer's pane at 22:59 UTC-3 and queued there reached the session
after 23:05 UTC-3, when it next read its inbox. Send a stop to a busy Codex session well before its
ceiling. To check, queue a message to a session in a long tool call and time when it is acted on;
this needs a new session. (LOG)

**HN35. Pause before submitting text typed into Codex.** Seen 2026-10-23, codex-cli 0.163.0 with
herdr 0.9.5. In Field PR 25 at 10:19 UTC, Enter sent immediately after `herdr pane send-text` was
ignored and the text stayed in the composer. A pause of about one second worked at 10:21 UTC;
the field also proposes clearing the composer with `ctrl+c` first. After a writer's leave, the
protocol director used a one-second pause before Enter with `/quit` at 09:00 UTC-3 and checked
that its process exited before closing the pane. For `/quit` or `/exit`, send the text, pause about
one second, then send Enter and check process exit. To recheck, use a disposable Codex session and
compare immediate and delayed Enter, recording composer and process state. The writer recorded
these field reports without rerunning them. (LOG, field PR 25, harness operation; LOG, 2026-10-23 09:00, Codex close; low)

## Cursor

**HN23. The model list and the session's window can disagree.** Seen 2026-10-22, cursor-agent of
that week. The list named a Claude model as "1M", while the session's status line read 300K. A
parameterized model with an override, such as `claude-opus-5-5[context=1m,effort=xhigh,fast=false]`,
started at 1M. `cursor-agent --help` in 2026.10.22-27dcf5f documents the override syntax. Read the
status line after start, never the list. To check, start a session with and without the override and
read the line; this needs new sessions. (LOG)

**HN24. The session cannot see its own context figure.** Seen 2026-10-22, cursor-agent
2026.10.22-27dcf5f. The percentage is only on the status line at the bottom of the pane, such as
"300K Extra High · 81.2%" after the model's name, which the orchestrator reads with `herdr pane read`; no file
of the CLI holds it, per R09 in `evidence.md`. Tell a Cursor seat its ceiling in tokens and
watch it for the seat. To check on a new version, ask a running Cursor session for its context figure
and compare its answer with the status line. (LOG)

**HN25. A message that arrives during a running turn is queued behind it.** Seen 2026-10-22,
cursor-agent 2026.10.22-27dcf5f. Neither Enter nor selecting the queued item steered it into the turn,
and it arrived about 80 seconds later when the turn ended. A Cursor seat answers a correction only at
its next turn, so send corrections and stops early. To check, send a message to a busy Cursor session
and time its arrival; this needs a running session. (LOG)

**HN26. Workspace trust in a new folder, and naming.** Seen 2026-10-22, cursor-agent
2026.10.22-27dcf5f. "Workspace Trust Required" in a new worktree is answered with `a` only when the
record covers the configuration write for that directory (HN02). `/rename` takes
the name as an argument. Cursor reads hooks only from its `hooks.json`, so keryx installs none for
Cursor; `keryx hook --help` gives the entry to add. To check the dialog and the rename, start a session
in a new folder and run `/rename test`; this needs a new session. (H05, LOG)

On 2026-10-23, `cursor-agent --help` in 2026.10.22-27dcf5f lists `--sandbox enabled|disabled`,
`--auto-review` and `--force` (also `--yolo`); `--mode plan|ask` selects read-only execution modes.
The spawner passes the mode the root record names after `--` in `keryx spawn`. These are launch
controls checked in help, not a recommendation to allow every command; check the effective mode
inside the seat with an authorized operation. (LOG, acceptance 1, stumble 3; low)

## Any harness

**HN27. The initial prompt argument survives startup dialogs, and text typed after the start can be
lost.** Seen 2026-10-22 in the three harnesses under herdr, and measured in OpenRig 0.5.15, where text
pasted after a readiness probe was lost in 14 of 26 relaunches and in every handover of one rig. The
argument is visible in `/proc` to local processes and capped at 128 KiB per argument on Linux
(E2BIG); on 2026-10-23 an argument of 131071 bytes passed and one of 131072 failed. Keep the first
prompt short, with no secret, and put the task in the first request. To check, start a harness with a
first prompt and a dialog pending, answer the dialog, and see the prompt acted on; read
`/proc/PID/cmdline` to see what others see. (H07, M34)

**HN28. A launcher that times out can still start the session.** Seen in OpenRig 0.5.14, where the
client gave up after five seconds and printed UNKNOWN while the seat came up, and in keryx spawn
(2026-10-22), which timed out on a trust dialog while the session joined once the dialog was answered.
`keryx spawn --help` in 0.1.0 says it exits with status 3 in that case. Read `keryx who` or the pane
before trying again. (M21)

**HN29. Setting a seat's model in OpenRig applies only on resume.** Seen September 2026, OpenRig 0.5.x.
A launch restores from a snapshot that carries the old model. Check each seat's model after every
relaunch, on the seat's own status line. To check on a new version, change a seat's model, relaunch
it, and read the model the seat reports; this needs OpenRig and a relaunch. (M22)

## The machine around the harnesses

**HN30. A systemd user service does not see a version manager's shims.** Seen 2026-10-22. The keryx
courier in this example ran as a user unit and needed to reach herdr, the harness CLIs and keryx.
Check that your unit sets PATH for those commands (see `bootstrap.md`). To check, run
`systemctl --user show keryx-courier -p Environment` and `systemctl --user status keryx-courier`, from a shell that has the user's session bus; one without it
fails before it reaches the unit. (H09)

**HN31. An output-compressing shell hook can truncate without saying so.** Seen 2026-09-17 and
2026-10-22. An install script piped through `curl | bash` arrived truncated, and listings hid files.
Download scripts to a file first, read whole files with the harness's read tool, and bypass the hook
(such a hook usually has a raw mode) before concluding that something is absent. (M01, LOG)

**HN32. Locales break tools that parse text.** Seen 2026-09-26 and 2026-10-22. An identity check
parsed a weekday from `ps` and failed on a non-English locale, and keryx met US-ASCII under ssh with no
LANG and the C locale. Test team tooling under your machine's locale and under ssh's bare one, such
as `ssh HOST 'env -u LANG -u LC_ALL -u LC_CTYPE keryx who'`, since LC_CTYPE alone can keep UTF-8.
(M43)

nomos v0 harness notes
