# nomos on keryx

How each element of `protocol.md` maps onto keryx main 92ab75d (version 0.1.0), checked on
2026-10-25, and which requirements in `evidence.md` remain open. All present-tense capabilities
and code references below use this baseline, except the reserved-scope behavior explicitly
rechecked at 7debfde (#38) on 2026-10-26; other commits identify when a feature shipped. The
capability review compared the baseline README and installed skill and help with the source,
traced commits and inspected test definitions. The installed gem's lib/ and exe/ files matched
this checkout byte for byte. It ran no keryx tests or live withdrawal, retirement, dialog or
context-threshold probes. Test references below identify coverage in the source, not passing runs.
The benchmark found an earlier baseline stale. (LOG, benchmark run; low) Addresses below use
illustrative names, spelled MEMBER.TEAM@HOST, as in `rev-1.alpha@box1`. A session address appends
/SESSION, as in `rev-1.alpha@box1/7f2abc` (`keryx help join`).

## Requirements triage

R01, R02, R07, R08, R09, R10, R11 and R13 are delivered. R07 and the filtered list view arrived in
0186dcd (#27); R11's last-activity column and R13's taken requests arrived in da068ef (#28).
R01 and R08 arrived in 143fbb8 (#30); 92ab75d (#31) keeps older addresses working during a move.
R03, R04, R05 and R06 remain open; R12 stays in the director's routine.

The historical triage recorded under R06 and R13, approved on 2026-10-23 at 04:17 UTC-3, put
R07, R13, the view hiding empty addresses, R01 with R08, and R05 after the audit fixes and spawn
task and before the 0.1.0 release. R11 followed the spawn task. That ordering does not mark the
now-delivered items as gaps. R03, R04 and R06 items 1 and 3 wait until after 0.1.0; R06 item 2
waits for a safe first-prompt delivery design, so cards travel by path instead of a long,
locally readable argv. R06 item 4, a check on each message, was declined then as a new trust
boundary, to be reconsidered only with field evidence of a mechanical error it would catch. That
evidence came on 2026-10-26 (LOG, 2026-10-26, raw human messages), and R30 takes the
check: keryx runs the command named in a root-owned `/etc/keryx/check` before it writes any message,
fail closed, and nomos supplies that command, `nomos check` (bootstrap section 4).
`evidence.md`, keryx requirements, records that order and its limits.

## Identity and addresses

| Protocol | keryx today | Requirement or remaining gap |
|---|---|---|
| 3.1 An identity outlives its sessions | An address has a mailbox under `addresses/MEMBER.TEAM/`; `occupant.json` names its holder. `keryx join MEMBER.TEAM --role ROLE` claims it and `keryx leave` releases it; mail keeps arriving with no holder unless it is retired (`keryx help join`, `keryx help retire`) | None |
| 3.2 The identity is (team, member), unique across the team's hosts | MEMBER and TEAM each take a lowercase letter then up to 31 lowercase letters, digits or hyphens. A second live holder on this host is refused unless `join --force` is given (`keryx help join`; `lib/keryx/commands/join.rb:79`) | R01 delivered in 143fbb8 (#30); uniqueness across hosts stays with the director |
| 3.3 Incarnations and session addresses | `whoami` shows the session address. `join --force` leaves the displaced live session bound there until it leaves; its inbox lists its session mail, and it opens and answers earlier stable-address requests by ID. Mail to a departed session is refused (`keryx help join`, `keryx help read`, `keryx help reply`; `lib/keryx/postman.rb:40`) | R08 delivered in 143fbb8 (#30) |
| 3.4 Spelling MEMBER.TEAM@HOST/SESSION | Team and session addresses are accepted. SESSION is six lowercase Crockford base32 characters, drawn by join; it is not the harness thread id (`keryx help join`; `lib/keryx/address.rb:17-20`, `lib/keryx/commands/join.rb:136`) | R01 and R08 delivered in 143fbb8 (#30) |
| 3.5 Role names within project-named teams | Use `orq.TEAM --role orchestrator`, `impl-N.TEAM --role implementer`, `qa-N.TEAM --role 'quality assurance'`, `rev-N.TEAM --role reviewer`, `aud-N.TEAM --role auditor` and `writer-N.TEAM --role writer` on join or spawn. Other seats use a short role word with an instance number. The short member name and full role field are separate (`keryx help join`, `keryx help spawn`) | Naming and the choice of full role word are conventions under 3.5, not transport validation |
| 3.6 Short names resolved by the sender | MEMBER means the sender's own team on this host, without fallback; MEMBER.TEAM is local. A sender without a team uses the one matching team or gets an ambiguity error listing candidates, subject to the compatibility case below. Unknown destinations are refused except the local terminal person's address, created on first mail (`lib/keryx/resolver.rb:15`, `lib/keryx/postman.rb:151`, `lib/keryx/identity.rb:40`) | R01 delivered in 143fbb8 (#30); the compatibility case is in 92ab75d (#31) |
| 3.7 Reserved scopes `local` and `system` | A terminal acts as NAME.local and notices come from keryx.system; full routes include @HOST. `whoami` gives the terminal's exact spelling. Join and spawn refuse every reserved address to an agent session, including the terminal person's own local address; a relay uses a team address (`lib/keryx/commands/join.rb`, `lib/keryx/commands/spawn.rb` at 7debfde) | R01 delivered in 143fbb8 (#30); the relay exception was removed in 7debfde (#38), merged 2026-10-26 12:44 UTC, with f1a9063 and 515b178; code and test definitions checked, no live impersonation probe |
| 3.8 Retire, never rename; no change with open requests | `keryx retire ADDRESS` runs on the address's host, refuses a live holder including a displaced session, and refuses open requests in either direction. It preserves files, refuses new mail and hides the retired address even with `--all`; `keryx join MEMBER.TEAM --revive` restores it. It rejects a session selector and this terminal person's own local address. `withdraw ID [TEXT]` still withdraws a sender's request under its former host name (`keryx help retire`, `keryx help withdraw`; `lib/keryx/commands/retire.rb:46`) | R07 delivered in 0186dcd (#27); R02 in a5157e6. Retirement is not rename or migration; identity-change checks remain conventions |

The compatibility form during a move is NAME@HOST. As the baseline README's "Ask and answer"
section says, join `MEMBER.TEAM`, finish what is open at the old address with `--as OLD_ADDRESS`,
then run `keryx retire OLD_ADDRESS`. A sender without a team reaches an existing, unretired old
address before trying teams; once it is retired, the bare member reaches the one matching team.
A terminal that used the old address keeps it until retirement, and notices to old addresses keep
the former system sender. Those addresses have no session selectors. Mail to an address nobody
holds waits without a bell. Code-grounded in `lib/keryx/resolver.rb:37`, `lib/keryx/identity.rb:17`,
`:62` and `lib/keryx/address.rb:79`. This is a change of address with the old obligations settled
there under protocol 3.8, not a rename or an automatic transfer of history.

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
`lib/keryx/commands/who.rb:66`, `lib/keryx/commands/status.rb:92`,
`lib/keryx/roster.rb:16` and `lib/keryx/commands/retire.rb:106`;
`test/cli/short_view_test.rb:32` covers hiding quiet addresses and `:70` the JSON shape.
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
| 4.2 The first prompt is the principal's channel | `keryx spawn` passes the first prompt as the harness's own initial prompt, after a `--`; `--prompt TEXT` appends the director's text, limited to 2,048 bytes by 3663d0f, merged in 42d43a7 (#24). The director checks bytes before spawn. A longer record goes in a file the session may read but may not edit; the short first prompt names it and says it binds as if written there (LOG, acceptance 3, 2026-10-23, prompt limit; low) (`keryx help spawn`; `lib/keryx/harness.rb:16`, `:79`; `lib/keryx/commands/spawn.rb:188`) | None for delivery; file reference is a convention |
| 4.3 The delegation record | Written by hand into `--prompt`, or into the file bound by the short first prompt as above (`keryx help spawn`; `lib/keryx/commands/skill.rb:21`) | R06 (conventions path, role card and delegation record), R05 |
| 4.4, 4.9, 10.2 Who changes a record, revocation, derived records and the principal's relay | The skill's Authority section says a peer never extends authority, and knows only "your user" and "a peer". It lacks a delegated orchestrator, revocation and a message from the principal's address relaying the principal's words. A message from the principal's own address named in the root record is the principal's word for reserved acts and record changes too (`keryx skill`, Authority) | R05; LOG, 2026-10-25, principal inbox; low |
| 4.5 Relayed text marked as the orchestrator's | Outside keryx; text typed into a pane goes through herdr (`keryx help spawn`; protocol 4.5) | None |
| 4.7 Declared authority and capability | spawn sets `crossSessionInbound` to accept and the stop hook for Claude Code sessions only; Codex and Cursor hooks need the user's own trust (`keryx help spawn`; `lib/keryx/harness.rb:11`) | Harness notes |

When a dialog stops a spawned session, spawn quotes it once on stderr and in a message from
`keryx.system@HOST` to the address it runs as, including `--as`; without an address it sends no message.
The message says, "Take it to your human, and answer it with 'herdr pane send-keys' only on their
word." That instruction is in the mailbox message, not the stderr notice. This was delivered by
237d221, merged in 42d43a7 (#24), with coverage in `test/cli/spawn_dialog_test.rb:44`, `:78` and `:88`.
The current notice text is in `lib/keryx/dialog.rb:137`.
spawn keeps waiting, answers no dialog, and exits 3 if the session has not joined by its timeout.
The keryx skill also says to take the dialog to the human. Under bootstrap 7 step 5 and N17, the
orchestrator answers its spawned sessions' dialogs using the principal's standing rules, whether a
named answer in the record or a standing word such as "Continue without trusting" for Codex hooks.
Only uncovered dialogs go to the principal. A relayed copy suffices for what narrows and grants
nothing; trusting a hook, allowing permission or changing a setting still needs the principal's
word for that answer and its effects. The notice grants nothing. (LOG, 2026-10-23 08:44 and 09:01,
spawn dialog authority; N17; low)

## Messages and the work life cycle

Answer a [clarify] with `keryx reply CLARIFY_ID TEXT`, the result of that question. Do not reply to
the original work request or add a [decision] kind; delivered-item decisions remain in the
requester's checkpoint under 5.5. (protocol 5.2; LOG, field PR 26, clarify answer; low)

keryx stores each message as one JSON file with `keryx` (format 2 for team or session addresses, format 1 between two old addresses), `id`, `kind`, `from`, `to`,
`thread`, `in_reply_to`, `created_at`, `due_at` and `body`, plus `context` when stamped. The transport
kinds are `message`, `request`, `reply` and `withdrawal` (`lib/keryx/message.rb:17`, `:82`). Withdrawal
arrived in a5157e6 (#19); `send --re` uses `message`, with no new kind. The nomos kinds ride on top
as the tag at the start of the first line (protocol 5.2).

Command forms in the following table are from `keryx help ask`, `send`, `reply`, `withdraw`
and `spawn`; the tags and their meanings are nomos conventions under protocol 5.2.

| nomos kind | Command | Note |
|---|---|---|
| request | `keryx ask ADDRESS --file BRIEF --within 2h` | Opens the obligation; `status` lists it until a reply or withdrawal |
| accept | `keryx send --re ID "[accept] ID, ..."` when taking a result request; `keryx reply ID --file COMMITMENT` for a commitment under 5.3; otherwise `keryx send ADDRESS "[accept] ID, ..."` | A commitment names what will be done and by when, with an absolute time and zone. For an agent requester it starts with `[accept]`; for a human it is a `notice` under 10.5 to 10.7, with a plain title on line 1, optional block on line 2 and no tag. Result acceptance and handover confirmation remain messages |
| refuse | `keryx reply ID --file BODY` | Closes the request; `[refuse]` for an agent requester, a `notice` without a tag for a human (10.5, 10.9) |
| clarify | `keryx ask ADDRESS "[clarify] ID, ..."` | A new request in a new thread, naming the original id |
| progress | `keryx send --re ID "[progress] ID, ..."` while the request is open; `keryx send ADDRESS "[progress] ID, ..."` after its reply | Names the request whose work continues |
| amend | `keryx send ADDRESS "[amend] ID, change, absolute time"` | The requester changes its open request. The worker acknowledges in its next progress or result, or asks [clarify] when it cannot (protocol 5.2; LOG, 2026-10-23 04:15; low, designed) |
| result | `keryx reply ID --file REPORT` for a result request; `keryx send ADDRESS --file REPORT` after a commitment reply | The report names the request. Delivery waits for the requester's decision in either case |
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
nothing. After a commitment reply under 5.3, send the result with `keryx send ADDRESS`, naming
the original request in the body; `send --re` is no longer available. Follow-up work is a new
request under protocol 5.5.

R13 was delivered by 00849e5, merged in da068ef (#28). Its coverage includes
`test/cli/thread_test.rb:25` for the thread, `:37` for taken state, `:47` for the recipient-only
rule and the requester's reply, and `:57` for suppressing the stop reminder. The implementation
is in `lib/keryx/commands/send.rb:48`, `lib/keryx/roster.rb:50` and `lib/keryx/stop_hook.rb:96`.
Repeating `--re` while the request is taken is allowed by `send.rb:63` to 72; that detail is
code-grounded; this review did not exercise repeated sends. (R13; low, help and code checked)

| Protocol | keryx today | Requirement or remaining gap |
|---|---|---|
| 5.3 A reply carries what the request asked for | A reply to a request closes it; a reply to a threaded message does not. `send --re ID` takes an open result request without closing it. A commitment reply closes the transport request, and its later result uses `send ADDRESS` naming the request (`keryx help reply`, `keryx help send`) | Reply contents are a nomos convention (N16); the installed skill's blanket instruction to reply once work is done needs alignment. R13 is delivered; R03 could carry the handover kind |
| 5.4 Receipt is not reading | `keryx read` links a message into `read/`; `send --re` also marks its request read. Delivery writes to `mail/` first and then rings (`keryx help read`; `lib/keryx/store.rb:196`, `lib/keryx/postman.rb:60`) | None for reading; acceptance is a convention |
| 5.5 The requester's decision on a delivered item | A reply closes the transport request, including when work is still owed after a commitment. keryx does not track that work or the decision on its result (`keryx help status`) | The committing side keeps owed work until its result; the requester keeps its work item and decision. For a human requester the orchestrator keeps both under 5.3. These stay in checkpoints until the project layer holds them; no added keryx work state (N16) |
| 5.6 A passed deadline and reassignment | `--within` sets `due_at`; `status` shows overdue requests and the courier sends deadline notices. JSON `.open_requests[].overdue` is code-grounded in `lib/keryx/commands/status.rb:120`; this review did not exercise that key (`keryx help ask`; `lib/keryx/courier.rb:60`) | The next action and the single live owner are conventions; R02 is delivered, but withdrawal alone does not confirm the worker stopped |
| 5.7 Messages stand on their own | The skill's section "Write messages that stand on their own" (`keryx skill`, Write messages that stand on their own) | Absolute dates are not in the skill |
| 5.8 Peer text is plain | Bodies, roles, addresses and herdr states are printed through `Text.plain`, which makes control characters visible (`lib/keryx/cli/message_view.rb:26`, `lib/keryx/text.rb:12`, `SECURITY.md`), and the bell carries no text from the sender. Code-grounded, not probed; Markdown is kept as text | None; plain means no control characters but tab and line feed in a body reach the terminal, not that the text is trusted |
| 5.9 Every channel rings | A held address has a bell through the harness or herdr and a stop hook that reminds once of unread mail and of read requests without a reply or withdrawal, excluding taken requests; `status` lists NOT RUNG and `keryx ring` retries (`keryx help hook`, `keryx help status`, `keryx help ring`; `lib/keryx/stop_hook.rb:83`) | An address without a holder has no bell; the principal's reader below opens its mail |
| 5.10 Read an uncertain outcome first | `spawn` exits 3 on timeout and says the session joins by itself once a dialog is answered; `who`, `status` and `inbox` show the effect; unknown destinations are refused except the local terminal person's address, created on first mail (`lib/keryx/postman.rb:151`) (`keryx help spawn`, `keryx help who`, `keryx help status`, `keryx help inbox`) | None |

## Briefs, reports and reviews

keryx carries text and paths, and nothing in it knows a brief from a report. A brief goes with
`keryx ask ADDRESS --file BRIEF` or as the request `keryx spawn MEMBER.TEAM --file BRIEF` posts before the session
exists. A report goes with `keryx reply ID --file REPORT`. Probes, findings and notes live in files
the messages point to, which is how the traces stay on disk (7.6). One writer per shared resource
(6.5) is kept outside keryx, by worktrees or by the director. keryx reads the context figure (7.1),
shows it in the CONTEXT column of `who` and `status`, and stamps it on a message sent by a session
holding its own address when the figure can be measured (R09, delivered in 60b1abb, #20). Messages
sent with `--as`, from a plain terminal or by the courier carry no context stamp. This includes the
predecessor's `--as` messages during handover; use an observed `who` figure or report unknown.
`test/cli/context_figures_test.rb:90` covers a session's stamp and `:115` the unstamped terminal
and `--as` cases. Context stamping is in `lib/keryx/app.rb:95`. An unavailable figure remains unknown; CONTEXT is `-` when no session runs.

## The session life cycle and handover

| Protocol | keryx today | Requirement or remaining gap |
|---|---|---|
| 2 The director | The spawner, else the sender of the session's oldest open request; with neither, the courier tells the session alone (`keryx help join`; `lib/keryx/courier.rb:93`) | R10 delivered in fde5548 (#21) (`keryx help join`) |
| 9.1 Spawn | `keryx spawn MEMBER.TEAM --harness claude\|codex\|cursor --role ROLE --file BRIEF --within D --ceiling TOKENS --prompt TEXT`, from inside a herdr pane (`keryx help spawn`) | None |
| 9.2 Readiness by readback | spawn waits for the join only; the readback is asked for in the first prompt and arrives as mail (`keryx help spawn`; `lib/keryx/spawner.rb:64`) | R04 (spawn waiting for a readback) |
| 9.1 Join | `keryx join MEMBER.TEAM --role ROLE --ceiling TOKENS`; `--force` takes the address from a live session (`keryx help join`) | None |
| 9.3 Settle obligations before leaving | `status` lists open requests, including taken ones. `send --re ID` suppresses the stop reminder for that request (`keryx help status`, `keryx help send`) | A turn ending is not leaving the session. Use a message for ongoing work and settle obligations before leaving (R13; protocol 9.3) |
| 9.1 Leave before close | `keryx leave`, then the harness's own exit (`keryx help leave`) | None |
| 9.4 Handover note and readback | The note is a file; its path reaches the incoming session in a request, as the first nomos handover round did (`keryx help ask`, `keryx help spawn`; `lib/keryx/message.rb:17`) | R03 (a kind that `inbox` shows first and `join` mentions), R04 (`spawn --takeover`) |
| 9.4 Predecessor reachable during the overlap | After `join --force`, the predecessor remains reachable at its session address, opens earlier work by ID and can finish it until it leaves (`keryx help join`, `keryx help read`, `keryx help reply`) | R08 delivered in 143fbb8 (#30); R04 remains open for `spawn --takeover` |
| 9.5 Checkpoint, renewal criterion and notices | Checkpoints remain files. `who` and `status` show CONTEXT; measurable messages sent under a session's own address carry its figure. `join` and `spawn` take `--ceiling TOKENS`; the courier notifies at 80% and at the ceiling, to the session and its director (`keryx help join`, `keryx help spawn`, `keryx help who`; `lib/keryx/app.rb:95`) | R09 delivered in 60b1abb; R10 in fde5548. The director still chooses the ceiling, checks progress and arranges handover. A change names the new figure, absolute time and reason; the session re-runs `keryx join MEMBER.TEAM --ceiling NEW`, keeping the stable address and setting the figure but drawing a new session selector. This drops the recorded director, so notices then go to the oldest open request's sender or only to the session. Rejoining without `--ceiling` drops both ceiling and director. This is code-grounded in `lib/keryx/commands/join.rb:109`, `:136`, `:158` and `lib/keryx/courier.rb:93`, not exercised in the capability review. Check notice routing after rejoining. A message alone leaves notices at the old point (LOG, field audits of fde5548; low) |
| 9.6 Announce disruptive actions, including upgrades | `keryx who` lists the addresses on a machine, and a `send` to each team's orchestrator announces. After an upgrade, a session joined under the old version may need its next keryx command before its bell works again; `keryx ring` and `status` show a refused bell (`keryx help who`, `keryx help ring`, `keryx help status`; README, Install and set up the agents) | None |

### Handover today, until R03 and R04

Session overlap is available when an already started successor runs `keryx join MEMBER.TEAM --force`.
The outgoing session keeps its session address until it leaves; the director records both routes
and the obligations each finishes (`keryx help join`, `keryx help reply`). `keryx spawn` still refuses
a live holder (`lib/keryx/commands/spawn.rb:201`), so the spawn recipe below retains the leave-first
arrangement. R08 is delivered; R04's `spawn --takeover` remains open. Binding a successor does not
confirm its readback or transfer nomos ownership before protocol 9.4's confirmation.

1. The director asks the outgoing session for the note with `keryx ask`, giving the path to write.
2. The outgoing session writes the note, with its table of obligations by id, replies with its path,
   runs `keryx leave`, and stays open in its pane without an address until the readback is confirmed.
3. If herdr still assigns the outgoing pane the member's agent name, the director frees that
   herdr name within its record before spawning from another pane. This does not rename the keryx
   address (`lib/keryx/spawner.rb:54`). The director starts the incoming session with `keryx spawn MEMBER.TEAM ... --file HANDOVER-REQUEST`,
   whose first prompt asks for a readback before any action.
4. The incoming session replies to the handover request with `[handover-ack]` and its readback. The
   director checks it against the note and confirms with `keryx send MEMBER.TEAM "[accept] ID, ..."`, which
   carries the time, and records the cutover in its checkpoint.
5. A question for the predecessor goes through the director, which types it into the predecessor's
   pane marked as its own (4.5). No renamed address is created.
6. The director tells the peers with open work, then closes the predecessor's pane once the
   obligations the note left with it are done.

For an orchestrator renewing itself under protocol 9.5, the outgoing session performs the director's
steps for the transfer. After saving the checkpoint and note and running `keryx leave`, it uses
`keryx spawn orq.alpha --as orq.alpha ... --file HANDOVER-REQUEST` for the same address, carrying the current
record and principal channel unchanged in the first prompt. It remains open without an address and
reads the handover request's reply using `--as orq.alpha`; the successor checks for the confirmation by
mail before acting. Messages to the same address do not ring it, so both sessions poll for these
specific handover messages until confirmation. Protocol 9.5 supplies the trigger, complete note,
health checks, two-successor failure limit and cutover duties. The outgoing session checks the
successor with `keryx who -o json | jq '.addresses[]'` and compares `keryx status -o json` with the note's requests.
For the bell check, send a `[clarify]` ping request naming the handover id and a fresh token with
`keryx ask orq.alpha --as orq.alpha --within 2m TEXT`, then run `keryx ring orq.alpha --as orq.alpha` while it is unread.
The successor reports whether the bell arrived and replies with the token; the outgoing session
reads that reply with `--as orq.alpha`. Reading the ping by polling is not evidence of a bell. Do not let
the predecessor mark the ping read before the ring. The two-minute wait is a default.

The outgoing session sends the timed confirmation only after all health checks pass, stops or hands
over its watchers and exits. Only the successor then directs the team, records cutover, tells peers
and the principal, and closes the old pane after checking the old process is gone. Self-message
suppression and the explicit `ring` path are code-grounded in `lib/keryx/postman.rb:73` and
`lib/keryx/commands/ring.rb:46`; this review did not exercise them. (LOG, acceptance 1, stumble 13; LOG, 2026-10-23 about 08:45,
orchestrator swap; low)

## The human

`nomos check` reads a recipient as a person by its address alone: the reserved `local` team
segment, or a full address with no team segment. The optional pre-send hook reads the same form
first and calls `keryx who --all -o json`, bounded at 2 seconds, only to resolve a bare member's
team; a recipient still unresolved is checked as a reply to an unknown recipient (bootstrap
section 4). (protocol 10.5 to 10.9 and 11.2; LOG, 2026-10-26, bare block; low, one message)

The orchestrator's first prompt uses the root form of `templates/first-prompt.md` to declare the
team's one channel to the principal (10.2). The principal may talk live in the orchestrator's own harness session. A
terminal uses NAME.local in keryx (`keryx help whoami`); it is a principal's channel only when the
record names it. When the principal's channel is a pane a relay reads, the root record may name
that relay by full address. The orchestrator puts each escalation in the declared channel and
sends its text or accessible file to the relay through keryx, so it rings a reader. Naming the
relay grants no decision authority and creates no second channel beyond the one 10.2 declares.
(protocol 10.2; LOG, acceptance 1, N2; low)

When the principal has an inbox, the root record names its full address, host included, together
with the orchestrator's own session as that one channel. At keryx 7debfde (#38), the principal's
NAME.local inbox has no agent holder. A relay holds a team address named in the record, carries
the principal's words verbatim under 4.5, decides nothing and answers no request itself. The
principal reads the inbox through a tool of their own. With no holder there is no bell; delivery
still puts the message in the mailbox. The tool marks it read when the principal opens it using
`keryx read ID --as PRINCIPAL.local@HOST` only from a plain terminal or a program started by one,
not an agent session. This is code-grounded in `lib/keryx/identity.rb` and
[keryx docs/troubleshooting.md at 7debfde](https://github.com/hvpaiva/keryx/blob/7debfdefbfd7d21de052aa8876b336b1becd810c/docs/troubleshooting.md),
with f1a9063's distinction between the terminal's own local address and another person's. This
review did not test a principal's reader.

Use `templates/human-message.md` and the address the record names. `decision`, `choice`,
`question` and `action` each go with `keryx ask PRINCIPAL.local@HOST --within D --file BODY`.
`suggestion` and `notice` go with `keryx send PRINCIPAL.local@HOST --file BODY`. A commitment to
the human's work request is a `notice` sent with `keryx reply ID --file COMMITMENT`, saying what
will be done and by when. The later `result` goes with
`keryx send PRINCIPAL.local@HOST --file REPORT` and names that request with `follows`. A result
requested as the reply under 5.3 uses `keryx reply ID --file REPORT`. A refusal or cancel
acknowledgment to a human is a `notice` sent as a reply. Human messages have a plain title and no
bracketed tag (10.5 to 10.9).

A question answered in the live session before the turn ends needs no inbox request; anything
still open goes there. Protocol 10.2 sets the deadline plan, the notices to send and the traffic
to omit. The same inbox serves every team. A team on another host first proves the route by
sending a notice, reading its arrival at the destination and checking `keryx status` on the
sending host for nothing waiting to be forwarded. Until that passes, or when the host is
unreachable, its record keeps its own orchestrator's session as the channel. (protocol 10.2; LOG,
2026-10-23 10:25 to 10:38, principal inbox; low, one arrangement, partly run)

A message from the principal's own address named in the root record is the principal's word,
including for field 5 reservations and record changes under field 8 and 4.4. The inbox answer
suffices on its own; the principal never has to repeat it in the orchestrator's session. In
7debfde, an agent's `--as` cannot act as a reserved address, including `send --on` as a person's
local address. `lib/keryx/identity.rb` checks the caller; f1a9063 supplies the refusal's
terminal-specific hint, and 515b178's test definition covers `send --on` succeeding from a plain
terminal and being refused to an agent. This is a caller check, not sender authentication; the
source and test definitions were read, not executed here. A human address on another host is a
third party under 4.6 unless a record names it. R05 must add to the skill's Authority section that
a message from the principal's named address is the principal's word, beside "your user" and "a
peer". (protocol 10.2; LOG, 2026-10-25, principal inbox; low, one counterexample)

## Checks and packaging

| Rule | Check | keryx today | Requirement or remaining gap |
|---|---|---|---|
| 3.3, 3.6, 3.8 | Refuse a left session's address, an ambiguous or unknown short name, a rename or move with open requests | Departed session addresses, ambiguous names, unknown destinations except the terminal person, and retired addresses are refused. Retirement waits for live holders and open requests (`lib/keryx/postman.rb:40`, `lib/keryx/postman.rb:151`, `lib/keryx/resolver.rb:37`; `keryx help retire`) | R01, R08, R07 and R02 delivered; identity-change checks remain conventions |
| 4.3, 9.2 | Compose the first prompt from a role card and delegation record; wait for the readback, not only the join | `--prompt` text by hand; spawn waits for the join (`keryx help spawn`) | R06, R04 |
| 5.2, 5.3 | Reply with what the request asks for, and tag kinds other than request and result | Four transport kinds, including withdrawal; reply contents are conventions (N16) | R03 remains open for handover |
| 5.5, 5.6 | Track work and decisions in the project layer and list overdue transport requests | `keryx status`, with `-o json`, lists overdue requests (`keryx help status`) | Until the project layer holds work items, keep them and their decisions in the requester's checkpoint (N16) |
| 5.7, 6.4, 7.2, 8.1 | Flag relative dates, missing headings, leftover placeholders, findings without rank or evidence class, per form and outside code and quotes | None in keryx (`lib/keryx/commands/send.rb:35`, `lib/keryx/commands/ask.rb:58`, `lib/keryx/commands/reply.rb:22`) | Advice, never refused: `nomos compose` prints it and the optional `hooks/pre-send.rb` flags it, as bootstrap section 4 describes; `nomos check` under R30 does not judge it |
| 9.1, 9.3 | Remind of unread mail and unanswered requests before a turn ends | `keryx hook stop` in all three harnesses; `send --re ID` marks an open received request taken (`keryx help hook`, `keryx help send`) | R13 delivered in da068ef (#28); taken requests keep their obligation until reply or withdrawal |
| 5.3, 10.5 to 10.8 | Refuse every message that breaks a MUST judged from the message alone, such as a block, title, footer or deadline missing from an agent's message to a human, or a progress note sent as a reply | R30: before it writes any message, on send and again on receive, keryx runs the command named in the root-owned `/etc/keryx/check`, `nomos check`, and refuses the message on any exit but 0; the inbox page still checks the block after delivery | R30, interface confirmed on 2026-10-26; installing `nomos check` and writing `/etc/keryx/check` is the principal's step on each machine (bootstrap section 4) |
| 9.4 | Show the handover note first to the next holder | Nothing (`lib/keryx/message.rb:17`; `keryx help inbox`) | R03 |
| 9.5 | Notify the session and its director near and past the criterion | CONTEXT and message figures (R09); `--ceiling` and courier notices at 80% and at the ceiling (R10) (`keryx help join`) | Delivered in 60b1abb and fde5548; checkpoint and handover stay with the team |
| How keryx knows nomos | Load conventions only when configured | Nothing yet (`lib/keryx/config.rb:10`, `lib/keryx/commands/skill.rb:21`; `keryx help spawn`) | R06 items 1 to 3 deferred in the triage recorded under R06; opt-in send/ask/reply checks (item 4) declined for now |
| Director heartbeat | Notice a stalled session | `who` and `status` show ACTIVE; JSON `.addresses[].last_activity` gives the last harness-record write time (`keryx help who`, `keryx help status`) | R11 delivered by d7b5502, merged in da068ef (#28), as narrowed to last activity; the routine still determines stalls |
| Pool awareness | Know each session's pool and that it can run out | The director records it in the routine (`keryx help who`; playbook, The director's heartbeat) | R12, not requested of keryx by the decision of 2026-10-23 |

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
| R01 | Delivered in 143fbb8 (#30), with compatibility in 92ab75d (#31). Team segment, sender-team resolution, ambiguity errors and reserved scopes (`keryx help join`; `lib/keryx/resolver.rb:15`). Cross-host uniqueness remains the director's responsibility | 3.2, 3.4, 3.6, 3.7 |
| R02 | Withdrawing a request, delivered in a5157e6 (#19) (`keryx help withdraw`) | 3.8, 5.2, 5.6 |
| R03 | Open, after 0.1.0. A handover kind that `inbox` shows first and `join` mentions (`lib/keryx/message.rb:17`; `keryx help inbox`, `keryx help join`) | 5.2, 9.4 |
| R04 | Open, after 0.1.0. `spawn --takeover`, and spawn waiting for a readback (`keryx help spawn`; `lib/keryx/commands/spawn.rb:201`) | 9.2, 9.4 |
| R05 | Open (`keryx skill`, Authority), planned before 0.1.0. A delegated orchestrator, record changes and revocation in the skill's Authority section, plus the principal's address relaying the principal's words beside "your user" and "a peer". A message from the principal's own address named in the root record is the principal's word for reserved acts and record changes too | 4.3, 4.4, 4.9, 10.2 |
| R06 | Open (`lib/keryx/config.rb:10`, `lib/keryx/commands/skill.rb:21`; `keryx help spawn`). Conventions-directory config path, first prompt from member and role cards and delegation record, and `keryx skill` printing the member-card path; items 1 and 3 after 0.1.0, item 2 awaiting safe first-prompt delivery, opt-in message checks (item 4) declined for now in the triage recorded under R06 | 4.3, 11.2 |
| R07 | Retiring an address, delivered in 0186dcd (#27); `retire ADDRESS` and `join MEMBER.TEAM --revive` (`keryx help retire`) | 3.8 |
| R08 | Delivered in 143fbb8 (#30). Session selectors, displaced-session reachability and refusal after departure (`keryx help join`, `keryx help read`, `keryx help reply`; `lib/keryx/postman.rb:40`) | 3.3, 3.4, 9.4 |
| R09 | Reading each session's context, shown in `who` and `status` and stamped on measurable sends under its own address; terminal, `--as` and courier sends are unstamped; delivered in 60b1abb (#20) (`lib/keryx/app.rb:95`; `keryx help who`) | 7.1, 9.5 |
| R10 | A ceiling per session that notifies the session and its director; delivered in fde5548 (#21) (`keryx help join`) | 9.5 |
| R11 | Delivered by d7b5502, merged in da068ef (#28), as narrowed to a last-activity column in `who` and `status`; `keryx help who` documents the column; the routine, built on `who -o json \| jq '.addresses[]'`, notices stalls | Playbook, The director's heartbeat |
| R12 | Not requested of keryx as of 2026-10-23; the director keeps pool awareness in the routine | Playbook, The director's heartbeat |
| R13 | `keryx send --re ID` (`keryx help send`), taken state in status after the recipient's threaded message, and no stop-hook reminder; delivered by 00849e5, merged in da068ef (#28). Only open received requests qualify; after reply use a message or new request naming the original id | 5.3, 5.5, 9.3 |
| R30 | Interface confirmed on 2026-10-26, merge and install planned for 2026-10-27. Before it writes any message, keryx runs the command named in the root-owned `/etc/keryx/check`, `nomos check`, on send and on receive, fail closed | 5.3, 10.5 to 10.8, 11.2 |

nomos v0 on keryx
