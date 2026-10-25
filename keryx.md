# nomos on keryx

How each element of `protocol.md` maps onto keryx main 2f599dc (version 0.1.0), checked on
2026-10-25 at 12:10 UTC, and which requirements in `evidence.md` remain open. All present-tense
capabilities and code references below use this baseline; other commits identify when a feature
shipped. The read-only capability review compared installed help with the source, traced commits
and inspected test definitions. It ran no keryx tests or live withdrawal, retirement, dialog or
context-threshold probes. Test references below identify coverage in the source, not passing runs.
The benchmark found the previous baseline stale, which is why this one exists.
(LOG, benchmark run; low) Addresses use illustrative names. Their spelling is NAME@HOST, as in `rev-1@box1`; R01 with R08
would add `rev-1.alpha@box1` and its session selector.

## Requirements triage

R02, R07, R09, R10, R11 and R13 are delivered. R07 and the filtered list view arrived in
0186dcd (#27); R11's last-activity column and R13's taken requests arrived in da068ef (#28).
R01 with R08 remain open. Their implementation on `feat/team-addresses`, including 6edfdf0 and
3e22511, is not in main. R03, R04, R05 and R06 also remain open; R12 stays in the director's routine.

The historical triage recorded under R06 and R13, approved on 2026-10-23 at 04:17 UTC-3, put
R07, R13, the view hiding empty addresses, R01 with R08, and R05 after the audit fixes and spawn
task and before the 0.1.0 release. R11 followed the spawn task. That ordering does not mark the
now-delivered items as gaps. R03, R04 and R06 items 1 and 3 wait until after 0.1.0; R06 item 2
waits for a safe first-prompt delivery design, so cards travel by path instead of a long,
locally readable argv. R06 item 4, a check on each message, is declined for now as a new trust
boundary, to be reconsidered only with field evidence of a mechanical error it would catch.
`evidence.md`, keryx requirements, records that order and its limits.

## Identity and addresses

| Protocol | keryx today | Requirement or remaining gap |
|---|---|---|
| 3.1 An identity outlives its sessions | An address is a directory in the store (`addresses/NAME/`) with its mailbox; `occupant.json` names the session holding it. `keryx join NAME --role ROLE` claims it, `keryx leave` releases it, and mail keeps arriving while nobody holds it unless the address is retired | None |
| 3.2 The identity is (team, member), unique across the team's hosts | One flat name per host, a lowercase letter then up to 31 letters, digits or hyphens; keryx refuses a second holder on its own host and sees no other host | R01; uniqueness across hosts stays with the director |
| 3.3 Incarnations and session addresses | `occupant.json` records the session (Claude Code session, Codex thread, Cursor conversation, herdr pane), but nothing can address it. `join --force` moves the address and leaves the old session with none. Messages already carry full addresses with the host | R08 |
| 3.4 Spelling MEMBER.TEAM@HOST/SESSION | NAME@HOST; a dot, a second segment or a slash is refused by `lib/keryx/address.rb:10`. Code-grounded; the capability review found no test specifically for dotted or slashed names | R01, R08 |
| 3.5 Role vocabulary | `--role` on join and spawn, shown by `keryx who` and `keryx status`; the member names are a convention | None |
| 3.6 Short names resolved by the sender | A bare NAME means NAME on this host; unknown addresses are refused, except the terminal's `$USER` address, created on first mail. Nothing else is resolved | R01 |
| 3.7 Reserved scopes `local` and `system` | A terminal acts as `$USER@HOST`, and the courier's notices come from `keryx@HOST` | R01 |
| 3.8 Retire, never rename; no change with open requests | `keryx retire ADDRESS` runs on the address's host and refuses a live holder or a request awaiting a reply in either direction. It preserves files, refuses mail and hides the retired address even with `--all`. `keryx join NAME --revive` restores it with its mailbox. `keryx withdraw ID [TEXT]` still withdraws the sender's request, including one sent under the sender's former host name | R07 delivered in 0186dcd (#27); R02 in a5157e6. Retirement is not rename or migration |

`keryx who -o json` returns an object with `view`, `hidden` and `addresses`. Iterate
`.addresses[]`; `view` is `short` or `all` and `hidden` counts omitted addresses.
Both `who` and `status` hide an address by default only when its session is `none` or `gone`,
it has no unread mail and no open request involves it as recipient or local sender. Taken requests
keep addresses visible, as do sessions whose state is unknown. Use `--all` for a run inventory,
cleanup or checking an inactive address; the short view suffices for active-session heartbeats. Retired addresses never
appear, including with `--all`, so absence alone does not prove retirement. Keep the successful
`retire` output with the inventory. `status -o json` keeps its other request and delivery fields;
`.addresses[]` selects only its address records. Delivered by 8262ea4, merged in 0186dcd (#27).
Code-grounded in
`lib/keryx/commands/who.rb:65`, `lib/keryx/commands/status.rb:91`,
`lib/keryx/roster.rb:16` and `lib/keryx/commands/retire.rb:53`;
`test/cli/short_view_test.rb:32` covers hiding quiet addresses and `:69` the JSON shape.
(LOG, 2026-10-23 09:43, address retirement and list shape)

In field observations recorded for keryx 0.1.0, a bell reported `agent_not_ready` while the recipient
was blocked in `keryx wait` on its readback; the message was nevertheless read within seconds.
Check the message's read state before treating that bell error as failed delivery or resending.
A worker waiting for a peer also left its director's decision unread for fifteen minutes on PR 26.
These observations add no transport guarantee; distinguish a bell result from delivery and reading.
(LOG, field PR 25, bell and wait; LOG, field PR 26, delivery and conventions; low)

## Delegation

| Protocol | keryx today | Requirement or remaining gap |
|---|---|---|
| 4.2 The first prompt is the principal's channel | `keryx spawn` passes the first prompt as the harness's own initial prompt, after a `--`; `--prompt TEXT` appends the director's text, limited to 2,048 bytes by 3663d0f, merged in 42d43a7 (#24). The director checks bytes before spawn. A longer record goes in a file the session may read but may not edit; the short first prompt names it and says it binds as if written there (LOG, acceptance 3, 2026-10-23, prompt limit; low) | None for delivery; file reference is a convention |
| 4.3 The delegation record | Written by hand into `--prompt`, or into the file bound by the short first prompt as above | R06 (conventions path, role card and delegation record), R05 |
| 4.4, 4.9, 10.2 Who changes a record, revocation, derived records and the principal's relay | The skill's Authority section says a peer never extends authority, and knows only "your user" and "a peer". It lacks a delegated orchestrator, revocation and a message from the principal's address relaying the principal's words. A message from the principal's own address named in the root record is the principal's word for reserved acts and record changes too | R05; LOG, 2026-10-25, principal inbox; low |
| 4.5 Relayed text marked as the orchestrator's | Outside keryx; text typed into a pane goes through herdr | None |
| 4.7 Declared authority and capability | spawn sets `crossSessionInbound` to accept and the stop hook for Claude Code sessions only; Codex and Cursor hooks need the user's own trust | Harness notes |

When a dialog stops a spawned session, spawn quotes it once on stderr and in a message from
`keryx@HOST` to the address it runs as, including `--as`; without an address it sends no message.
The message says, "Take it to your human, and answer it with 'herdr pane send-keys' only on their
word." That instruction is in the mailbox message, not the stderr notice. This was delivered by
237d221, merged in 42d43a7 (#24), with coverage in `test/cli/spawn_dialog_test.rb:43`, `:58` and `:67`.
spawn keeps waiting, answers no dialog, and exits 3 if the session has not joined by its timeout.
This agrees with bootstrap 7 step 5: a record granting a named answer, such as "Continue without trusting" for Codex's hooks dialog,
carries the principal's word for that answer and its covered effects. Without that grant the
director escalates; the notice grants nothing. (LOG, 2026-10-23 08:44 and 09:01, spawn dialog
authority; low)

## Messages and the work life cycle

Answer a [clarify] with `keryx reply CLARIFY_ID TEXT`, the result of that question. Do not reply to
the original work request or add a [decision] kind; delivered-item decisions remain in the
requester's checkpoint under 5.5. (protocol 5.2; LOG, field PR 26, clarify answer; low)

keryx stores each message as one JSON file with `keryx` (format 1), `id`, `kind`, `from`, `to`,
`thread`, `in_reply_to`, `created_at`, `due_at` and `body`, plus `context` when stamped. The transport
kinds are `message`, `request`, `reply` and `withdrawal` (`lib/keryx/message.rb:16`). Withdrawal
arrived in a5157e6 (#19); `send --re` uses `message`, with no new kind. The nomos kinds ride on top
as the tag at the start of the first line (protocol 5.2).

| nomos kind | Command | Note |
|---|---|---|
| request | `keryx ask ADDRESS --file BRIEF --within 2h` | Opens the obligation; `status` lists it until a reply or withdrawal |
| accept | `keryx send --re ID "[accept] ID, ..."` when taking work; otherwise `keryx send ADDRESS "[accept] ID, ..."` | The worker takes an open request in its thread. Result acceptance and handover confirmation use a message naming the original id |
| refuse | `keryx reply ID "[refuse] ..."` | Closes the request |
| clarify | `keryx ask ADDRESS "[clarify] ID, ..."` | A new request in a new thread, naming the original id |
| progress | `keryx send --re ID "[progress] ID, ..."` | A message in the received, still-open request's thread |
| amend | `keryx send ADDRESS "[amend] ID, change, absolute time"` | The requester changes its open request. The worker acknowledges in its next progress or result, or asks [clarify] when it cannot (protocol 5.2; LOG, 2026-10-23 04:15; low, designed) |
| result | `keryx reply ID --file REPORT` | Closes the request; the item waits for the requester's decision |
| close | `keryx send ADDRESS "[close] ID, ..."` | A message from the requester, with the reason |
| cancel | `keryx withdraw ID "[cancel] ID, reason"` | R02 delivered in a5157e6 (#19). Withdraws the obligation and rings the recipient; a later reply is still delivered. Confirm the worker has stopped or cannot act before reassignment (5.6) |
| handover | `keryx ask ADDRESS --file NOTE-REQUEST`, or the request `keryx spawn` posts | R03 for a kind of its own |
| handover-ack | `keryx reply ID "[handover-ack] ..."` with the readback | R03 |

Only the recipient of an open request can use `keryx send --re ID TEXT`, with the ID from its
own mailbox. It sends to the requester in that request's thread, without an ADDRESS argument.
The requester cannot use `--re` on the request it sent. The recipient's send marks the request
read and taken; `status` keeps it open, and the stop hook no longer reminds of it. Use it for [accept] and [progress], naming the
id in the body so the message stands alone. It works only while the request is open; an answered
or withdrawn request is refused. After the reply, send a message or a new request naming the
original id under protocol 5.5. A requester sends amendments and delivered-item decisions with
`keryx send ADDRESS`; a [clarify] uses `keryx ask` and names the original id. Tags are not parsed.
A requester can reply to the worker's threaded message to stay in the thread; that reply settles
nothing. Follow-ups after a terminal reply remain governed by protocol 5.5.

R13 was delivered by 00849e5, merged in da068ef (#28). Its coverage includes
`test/cli/thread_test.rb:25` for the thread, `:37` for taken state, `:47` for the recipient-only
rule and the requester's reply, and `:57` for suppressing the stop reminder. The implementation
is in `lib/keryx/commands/send.rb:48`, `lib/keryx/roster.rb:49` and `lib/keryx/stop_hook.rb:96`.
Repeating `--re` while the request is taken is allowed by `send.rb:63` to 72; that detail is
code-grounded only, with no test found by the capability review. (R13; low, help and code checked)

| Protocol | keryx today | Requirement or remaining gap |
|---|---|---|
| 5.3 A reply is a terminal outcome | A reply to a request closes it; a reply to a threaded message does not. `send --re ID` marks an open received request taken and suppresses its stop reminder without closing it | R13 delivered in da068ef (#28); R03 could carry the handover kind |
| 5.4 Receipt is not reading | `keryx read` links a message into `read/`; `send --re` also marks its request read. Delivery writes to `mail/` first and then rings | None for reading; acceptance is a convention |
| 5.5 The requester's decision on a delivered item | A reply to the request closes it, and nothing in keryx tracks the item after it | The decision lives in the requester's checkpoint; listing undecided items in `status` would need a new requirement |
| 5.6 A passed deadline and reassignment | `--within` sets `due_at`; `status` shows overdue requests and the courier sends deadline notices. JSON `.open_requests[].overdue` is code-grounded in `lib/keryx/commands/status.rb:120`; no test for that key was found by the capability review | The next action and the single live owner are conventions; R02 is delivered, but withdrawal alone does not confirm the worker stopped |
| 5.7 Messages stand on their own | The skill's section "Write messages that stand on their own" | Absolute dates are not in the skill |
| 5.8 Peer text is plain | Bodies, roles, addresses and herdr states are printed through `Text.plain`, which makes control characters visible (`lib/keryx/cli/message_view.rb:26`, `lib/keryx/text.rb:12`, `SECURITY.md`), and the bell carries no text from the sender. Code-grounded, not probed; Markdown is kept as text | None; plain means no control characters but tab and line feed in a body reach the terminal, not that the text is trusted |
| 5.9 Every channel rings | The bell (the harness's channel, or typing into a herdr pane) and the stop hook, which reminds once of unread mail and of read requests without a reply or withdrawal, excluding taken requests; `status` lists NOT RUNG and `keryx ring` retries | None |
| 5.10 Read an uncertain outcome first | `spawn` exits 3 on timeout and says the session joins by itself once a dialog is answered; `who`, `status` and `inbox` show the effect; unknown addresses are refused, except the terminal's `$USER` address, created on first mail | None |

## Briefs, reports and reviews

keryx carries text and paths, and nothing in it knows a brief from a report. A brief goes with
`keryx ask ADDRESS --file BRIEF` or as the request `keryx spawn --file BRIEF` posts before the session
exists. A report goes with `keryx reply ID --file REPORT`. Probes, findings and notes live in files
the messages point to, which is how the traces stay on disk (7.6). One writer per shared resource
(6.5) is kept outside keryx, by worktrees or by the director. keryx reads the context figure (7.1),
shows it in the CONTEXT column of `who` and `status`, and stamps it on a message sent by a session
holding its own address when the figure can be measured (R09, delivered in 60b1abb, #20). Messages
sent with `--as`, from a plain terminal or by the courier carry no context stamp. This includes the
predecessor's `--as` messages during handover; use an observed `who` figure or report unknown.
`test/cli/context_figures_test.rb:89` covers a session's stamp and `:114` the unstamped terminal
and `--as` cases. An unavailable figure remains unknown; CONTEXT is `-` when no session runs.

## The session life cycle and handover

| Protocol | keryx today | Requirement or remaining gap |
|---|---|---|
| 2 The director | The spawner, else the sender of the session's oldest open request; with neither, the courier tells the session alone | R10 delivered in fde5548 (#21) |
| 9.1 Spawn | `keryx spawn NAME --harness claude\|codex\|cursor --role ROLE --file BRIEF --within D --ceiling TOKENS --prompt TEXT`, from inside a herdr pane | None |
| 9.2 Readiness by readback | spawn waits for the join only; the readback is asked for in the first prompt and arrives as mail | R04 (spawn waiting for a readback) |
| 9.1 Join | `keryx join NAME --role ROLE --ceiling TOKENS`; `--force` takes the address from a live session | None |
| 9.3 Settle obligations before leaving | `status` lists open requests, including taken ones. `send --re ID` suppresses the stop reminder for that request | A turn ending is not leaving the session. Use a message for ongoing work and settle obligations before leaving (R13; protocol 9.3) |
| 9.1 Leave before close | `keryx leave`, then the harness's own exit | None |
| 9.4 Handover note and readback | The note is a file; its path reaches the incoming session in a request, as the first nomos handover round did | R03 (a kind that `inbox` shows first and `join` mentions), R04 (`spawn --takeover`) |
| 9.4 Predecessor reachable during the overlap | Not possible; the first nomos handover round used renamed addresses instead | R08 |
| 9.5 Checkpoint, renewal criterion and notices | Checkpoints remain files. `who` and `status` show CONTEXT; measurable messages sent under a session's own address carry its figure. `join` and `spawn` take `--ceiling TOKENS`; the courier notifies at 80% and at the ceiling, to the session and its director | R09 delivered in 60b1abb; R10 in fde5548. The director still chooses the ceiling, checks progress and arranges handover. A change names the new figure, absolute time and reason; the session re-runs `keryx join NAME --ceiling NEW`, keeping the address and setting the figure. This drops the recorded director, so notices then go to the oldest open request's sender or only to the session. Rejoining without `--ceiling` drops both ceiling and director. This is code-grounded in `lib/keryx/commands/join.rb:89` to 103, not exercised in the capability review. Check notice routing after rejoining. A message alone leaves notices at the old point (LOG, field audits of fde5548; low) |
| 9.6 Announce disruptive actions, including upgrades | `keryx who` lists the addresses on a machine, and a `send` to each team's orchestrator announces. After an upgrade, a session joined under the old version may need its next keryx command before its bell works again; `keryx ring` and `status` show a refused bell | None |

### Handover today, until R03, R04 and R08

1. The director asks the outgoing session for the note with `keryx ask`, giving the path to write.
2. The outgoing session writes the note, with its table of obligations by id, replies with its path,
   runs `keryx leave`, and stays open in its pane without an address until the readback is confirmed.
3. The director starts the incoming session with `keryx spawn MEMBER ... --file HANDOVER-REQUEST`,
   whose first prompt asks for a readback before any action.
4. The incoming session replies to the handover request with `[handover-ack]` and its readback. The
   director checks it against the note and confirms with `keryx send MEMBER "[accept] ID, ..."`, which
   carries the time, and records the cutover in its checkpoint.
5. A question for the predecessor goes through the director, which types it into the predecessor's
   pane marked as its own (4.5). No renamed address is created.
6. The director tells the peers with open work, then closes the predecessor's pane once the
   obligations the note left with it are done.

For an orchestrator renewing itself under protocol 9.5, the outgoing session performs the director's
steps for the transfer. After saving the checkpoint and note and running `keryx leave`, it uses
`keryx spawn ORQ --as ORQ ... --file HANDOVER-REQUEST` for the same address, carrying the current
record and principal channel unchanged in the first prompt. It remains open without an address and
reads the handover request's reply using `--as ORQ`; the successor checks for the confirmation by
mail before acting. Messages to the same address do not ring it, so both sessions poll for these
specific handover messages until confirmation. Protocol 9.5 supplies the trigger, complete note,
health checks, two-successor failure limit and cutover duties. The outgoing session checks the
successor with `keryx who -o json | jq '.addresses[]'` and compares `keryx status -o json` with the note's requests.
For the bell check, send a `[clarify]` ping request naming the handover id and a fresh token with
`keryx ask ORQ --as ORQ --within 2m TEXT`, then run `keryx ring ORQ --as ORQ` while it is unread.
The successor reports whether the bell arrived and replies with the token; the outgoing session
reads that reply with `--as ORQ`. Reading the ping by polling is not evidence of a bell. Do not let
the predecessor mark the ping read before the ring. The two-minute wait is a default.

The outgoing session sends the timed confirmation only after all health checks pass, stops or hands
over its watchers and exits. Only the successor then directs the team, records cutover, tells peers
and the principal, and closes the old pane after checking the old process is gone. Self-message
suppression and the explicit `ring` path were checked in local Postman and Ring code on 2026-10-23;
they were not exercised by the writer. (LOG, acceptance 1, stumble 13; LOG, 2026-10-23 about 08:45,
orchestrator swap; low)

## The human

The orchestrator's first prompt uses the root form of `templates/first-prompt.md` to declare the
team's one channel to the principal (10.2). The principal may talk live in the orchestrator's own
harness session. A terminal uses `$USER@HOST` in keryx; it is a principal's channel only when the
record names it. When the principal's channel is a pane a relay reads, the root record may name
that relay by full address. The orchestrator puts each escalation in the declared channel and sends
its text or accessible file to the relay through keryx, so it rings a reader. Naming the relay grants
no decision authority and creates no second channel beyond the one 10.2 declares. (protocol 10.2; LOG,
acceptance 1, N2; low)

When the principal has an inbox, the root record names its full address, host included, together
with the orchestrator's own session as that one channel. In keryx the inbox is an address held by
a relay session. Decisions go with `keryx ask PRINCIPAL@HOST --within D --file ESCALATION` and
notices with `keryx send PRINCIPAL@HOST TEXT`, using the address the record names. A question
answered in the live session before the turn ends needs no inbox request; anything still open
goes there. Protocol 10.2 sets the deadline plan, the notices to send and the traffic to omit.
The same inbox serves every team. A team on another host first proves the route by sending a
notice, reading its arrival at the destination and checking `keryx status` on the sending host
for nothing waiting to be forwarded. Until that passes, or when the host is unreachable, its
record keeps its own orchestrator's session as the channel. (protocol 10.2; LOG, 2026-10-23
10:25 to 10:38, principal inbox; low, one arrangement, partly run)

The session holding the principal's address carries the principal's words verbatim under 4.5,
decides nothing and answers no request itself. A message from the principal's own address named
in the root record is the principal's word, including for field 5 reservations and record changes
under field 8 and 4.4. The inbox answer suffices on its own; the principal never has to repeat it
in the orchestrator's session. keryx does not authenticate a sender; any local session can write as
an address with `--as`. A human address on another
host is a third party under 4.6 unless a record names it. R05 must add to the skill's Authority
section that a message from the principal's named address is the principal's word, beside "your
user" and "a peer". (protocol 10.2; LOG, 2026-10-25, principal inbox; low, one counterexample)

## Checks and packaging

| Rule | Check | keryx today | Requirement or remaining gap |
|---|---|---|---|
| 3.3, 3.6, 3.8 | Refuse a left session's address, an ambiguous or unknown short name, a rename or move with open requests | Unknown addresses (except the terminal's `$USER`) and retired addresses are refused; R07 retires only without a live holder or open requests, and requests can be withdrawn under R02 | R01, R08; address-change checks remain conventions |
| 4.3, 9.2 | Compose the first prompt from a role card and delegation record; wait for the readback, not only the join | `--prompt` text by hand; spawn waits for the join | R06, R04 |
| 5.2, 5.3 | Reply only with a terminal outcome, and tag the other kinds | Four transport kinds, including withdrawal | R03 remains open for handover |
| 5.5, 5.6 | List undecided delivered items and overdue requests with their next action | `keryx status`, with `-o json`, lists overdue requests | Undecided items need a requirement |
| 5.7, 6.4, 7.2, 8.1 | Flag relative dates, missing headings, leftover placeholders, findings without rank or evidence class, per form and outside code and quotes | None in keryx | R06 item 4 declined for now in the triage recorded under R06 as a new trust boundary; nomos ships the optional `hooks/pre-send.rb` outside the transport, wired as bootstrap section 4 describes |
| 9.1, 9.3 | Remind of unread mail and unanswered requests before a turn ends | `keryx hook stop` in all three harnesses; `send --re ID` marks an open received request taken | R13 delivered in da068ef (#28); taken requests keep their obligation until reply or withdrawal |
| 9.4 | Show the handover note first to the next holder | Nothing | R03 |
| 9.5 | Notify the session and its director near and past the criterion | CONTEXT and message figures (R09); `--ceiling` and courier notices at 80% and at the ceiling (R10) | Delivered in 60b1abb and fde5548; checkpoint and handover stay with the team |
| How keryx knows nomos | Load conventions only when configured | Nothing yet | R06 items 1 to 3 deferred in the triage recorded under R06; opt-in send/ask/reply checks (item 4) declined for now |
| Director heartbeat | Notice a stalled session | `who` and `status` show ACTIVE; JSON `.addresses[].last_activity` gives the last harness-record write time | R11 delivered by d7b5502, merged in da068ef (#28), as narrowed to last activity; the routine still determines stalls |
| Pool awareness | Know each session's pool and that it can run out | The director records it in the routine | R12, not requested of keryx by the decision of 2026-10-23 |

ACTIVE is the age of the last write to the Claude Code transcript, Codex rollout or Cursor
conversation store. It is `unknown` when unreadable and `-` when no session runs; JSON gives an
ISO 8601 UTC time or null for either case. ACTIVE precedes CONTEXT in both tables, so scripts
should read JSON keys instead of old column positions. `test/cli/activity_test.rb:36`, `:48` and
`:53` cover the value, column order and JSON. A long tool call can look quiet; last activity does
not establish liveness or progress. The director still checks output or transcript growth, pane
errors and request deadlines and sends the stall notice from its routine.

## Requirements this document relies on

| Requirement | Current state and what nomos needs | Protocol rules |
|---|---|---|
| R01 | Open with R08; `feat/team-addresses` is not in main. The team segment, short-name resolution in the sender's team, errors for ambiguous and remote short names, the reserved scopes | 3.2, 3.4, 3.6, 3.7 |
| R02 | Withdrawing a request, delivered in a5157e6 (#19) | 3.8, 5.2, 5.6 |
| R03 | Open, after 0.1.0. A handover kind that `inbox` shows first and `join` mentions | 5.2, 9.4 |
| R04 | Open, after 0.1.0. `spawn --takeover`, and spawn waiting for a readback | 9.2, 9.4 |
| R05 | Open, planned before 0.1.0. A delegated orchestrator, record changes and revocation in the skill's Authority section, plus the principal's address relaying the principal's words beside "your user" and "a peer". A message from the principal's own address named in the root record is the principal's word for reserved acts and record changes too | 4.3, 4.4, 4.9, 10.2 |
| R06 | Open. Conventions-directory config path, first prompt from member and role cards and delegation record, and `keryx skill` printing the member-card path; items 1 and 3 after 0.1.0, item 2 awaiting safe first-prompt delivery, opt-in message checks (item 4) declined for now in the triage recorded under R06 | 4.3, 11.2 |
| R07 | Retiring an address, delivered in 0186dcd (#27); `retire ADDRESS` and `join NAME --revive` | 3.8 |
| R08 | Open with R01; `feat/team-addresses` is not in main. Addressing an incarnation, with the session selector designed with R01 | 3.3, 3.4, 9.4 |
| R09 | Reading each session's context, shown in `who` and `status` and stamped on measurable sends under its own address; terminal, `--as` and courier sends are unstamped; delivered in 60b1abb (#20) | 7.1, 9.5 |
| R10 | A ceiling per session that notifies the session and its director; delivered in fde5548 (#21) | 9.5 |
| R11 | Delivered by d7b5502, merged in da068ef (#28), as narrowed to a last-activity column in `who` and `status`; the routine, built on `who -o json \| jq '.addresses[]'`, notices stalls | Playbook, The director's heartbeat |
| R12 | Not requested of keryx as of 2026-10-23; the director keeps pool awareness in the routine | Playbook, The director's heartbeat |
| R13 | `keryx send --re ID`, taken state in status after the recipient's threaded message, and no stop-hook reminder; delivered by 00849e5, merged in da068ef (#28). Only open received requests qualify; after reply use a message or new request naming the original id | 5.3, 5.5, 9.3 |

nomos v0 on keryx
