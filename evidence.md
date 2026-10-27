# Evidence for nomos v0

These cases explain the incidents behind nomos's rules, the reasons for those rules and the limits
of the evidence. A case is a sanitized summary of a real agent run. It keeps what happened and what
it taught, with dates and counts where the record supplies them. Roles replace session and person
names. Cases omit private paths, machine names, message identifiers, personal habits and reactions,
private tools, employer and customer facts, and account or quota details. The mapping to the raw
records stays private.

This collection was compiled on 2026-10-23 from the first keryx round, other agent work, the
research register and the run that wrote nomos. It also includes public sources and decisions,
which are identified separately below. Use a rule's citation to find its entry here; reading a case
does not require access to the private notes.

## How to read this file

| ID family | What it records |
|---|---|
| L | Protocol lessons from the first keryx round |
| P | Playbook lessons from that round |
| H | Harness behavior seen in that round |
| M | Candidate rules mined from other agent work and the keryx round |
| S | Public sources used to assess or qualify a rule |
| S-N | Public references on naming |
| E | Editorial recommendations that reconcile the inputs |
| N | Charter decisions that set the project's scope |
| R | Requirements proposed to the keryx team |
| Ruling | Decisions where the inputs disagreed |
| LOG | Dated incidents from the nomos run and later keryx field cases |

A lesson or candidate gives the rule, incident, reason, frequency and confidence. Later cases group
observations under a date or public pull request. A dated LOG citation refers to that incident, not
to a separate file. LOG times are UTC-3 unless an entry states another zone. Pull request numbers in
keryx cases refer to the public [keryx repository](https://github.com/hvpaiva/keryx).

The principal is the human role that grants authority. The orchestrator directs a team within that
grant. The long-running team mentioned in some cases is a separate group of agent sessions. These
roles describe actions and authority; the cases omit personal characteristics and private work
context. Public repository ownership remains visible through the repository links.

Evidence and confidence answer different questions. Observed evidence pairs an action with its
output; code-grounded evidence names a code path and its reasoning; sourced evidence attributes a
report or reference; a hypothesis remains unchecked. These summaries preserve those distinctions.
A report of a test is sourced evidence here unless the entry says the writer reran it. An unchecked
claim in the original notes is called a suspicion.

Some early entries use frequency qualifiers instead of exact counts. These keep the meanings in
the original records; later cases retain exact counts with their scope where available.

| Qualifier | Meaning |
|---|---|
| once | one time |
| a few | two to four times |
| many | five or more times |
| most | more than half of the cases |
| fewer than half | less than half of the cases |
| every time | in every recorded case |

Confidence follows `protocol.md` section 1. High means the rule held three or more times, or in two
independent settings, with no counterexample. Medium means it held twice, or once with supporting
prior art. Low means it held once or was only reasoned out. Since "a few" covers two to four, the
confidence says which side of three a count fell on. Where a problem recurred but the remedy is
new, the entry distinguishes the two. Confidence describes the support for a rule; the protocol
determines whether the rule is required.

## Lessons of the first keryx round

### Protocol lessons

**L01. A task states what done means, including what the reply must contain.**
- Incident. Every brief of the round ended with a section on what done means, asking for the change's
  URL, the commands run and their output, what was not done and where the reviewer should look first.
  Replies came back dense and checkable, and the orchestrator never had to open the work to know its
  state.
- Reason. A reply whose shape is fixed in advance can be checked in minutes, and a gap in it shows.
- Seen many times in one round. Confidence high.

**L02. Reports state facts checked by a command, with the command and its output, and label anything
else a suspicion.**
- Incidents. The audit brief said a finding without a reproduction is a suspicion, and the auditor and
  the reviewers kept to it. In other recorded runs, many claims
  needed correction because they lacked the command that would settle them. Reading a status
  alone had been treated as verification.
- Reason. A claim that carries its command is cheap to verify, and one that does not costs the reader
  an investigation.
- Seen every time in the round's reviews and audit, and many times elsewhere. Confidence high. The
  research added that a precise code path is evidence too (S28).

**L03. Review findings are ranked must-fix or suggestion, each with file and line, what goes wrong and
how the reviewer knows, with a failing test when possible.**
- Incident. The reviewer of the round did this in every review round, and the orchestrator ran the
  failing tests itself. Every must-fix reproduced. The ranking let the orchestrator accept or defer
  suggestions without a debate. A review procedure sends every draft finding to a validator
  that reads the file at the head commit and answers confirmed, wrong line, false positive or unclear.
- Reason. A ranked finding with a test settles itself, and an unranked list invites argument.
- Seen many times in one round. Confidence high.

**L04. The first prompt is the principal's channel, and it names the session's role, its principal,
any delegation and the authority of the role for the life of the session.**
- Incidents. A takeover prompt that authorized pushing one branch made the new implementer refuse a
  later task's branch on the orchestrator's word. Sessions of an unrelated project, whose principal was
  the principal directly, needed a different first prompt from the keryx team, whose principal spoke
  through the orchestrator. Later a mining session read material that a standing rule of its harness
  forbade, because its first prompt named that material as its sources, and it read it as data and
  followed none of it as instructions. The first prompt worked as a scoped exception.
- Reason. A session can trust only what comes through its user's channel, so authority has to be
  stated there or it does not exist.
- Seen a few times in the round and once in the mining. Confidence high.

**L05. A peer's message never extends a session's authority.**
- Incident. The transport's skill says so, and the implementer applied it when it refused to push a
  branch its first prompt did not cover. The gap it exposed is a delegated orchestrator, whose word
  inside its delegation should count, so the protocol has to say how a delegation is declared and how
  far it reaches.
- Reason. Any session can write to any address, so a peer's word cannot be a grant.
- Seen once, plus the principal's decision to delegate. Confidence medium, since prior art agrees (S11,
  S43) and one harness builds the same rule into its own transport (M49).

**L06. The life of a session is spawn, join, work, leave and close, and leave comes before close.**
- Incident. A Codex thread closed with `/quit` was later rung by a bell and resumed headless by Codex's
  shared app-server daemon, and it joined a new address on its own (H03). After that every session ran
  `keryx leave` before closing, and no closed session woke again.
- Reason. A session closed without leaving still holds an address, and a bell can wake it to act under
  an identity nobody directs.
- Seen once as a failure, then held every time a session closed. Confidence high.

**L07. A session near its context limit hands over through a note and a fresh session at the same
address.**
- Incidents. The note covers the state, the decisions and why, what the machine taught the session, the
  exact commands to repeat its checks, and what is open. A QA session handed over at a task boundary,
  an implementer mid-task and the orchestrator itself, and the new implementer fixed a review round in
  ten minutes without reopening a decision. The long-running team reached the same rule a month earlier, from cost
  per call rather than from context loss. The orchestrator's handover also ran with an overlap at the
  principal's request, the old session staying reachable at a side address, but nothing shows the new one
  asking it anything (suspicion on the overlap's value).
- Reason. A compaction loses what the session knew, and a note written at a stopping point keeps it
  for the next session to act from.
- Seen a few times in the round and again in a second setting. Confidence high for the note, low for
  the overlap.

**L08. One session per task, and a fresh reviewer for each change.**
- Incidents. Reusing a reviewer across pull requests carries its reading of the last one, and fresh
  reviewers found new defects every round. The long-running team relaunched its reviewer fresh for each new cut of
  work. Two variants were seen once each, a reviewer whose context was cleared and reused for a second
  change, which came back clean and verified, and a reviewer that took a stack of dependent changes in
  order on purpose.
- Reason. A reviewer that has read the last version anchors on it.
- Seen many times in one round and again in a second setting. Confidence high for a fresh reviewer per
  change. The variants show neither a cost nor a gain yet.

**L09. A request is for work that needs an answer, and a message is for everything else.**
- Incident. An outside user sent its feedback as messages, so it never waited on the orchestrator, and
  asked for a support session with a request.
- Reason. A request holds an obligation open until it is answered, and feedback that needs no answer
  should not hold one.
- Seen every time, throughout the round. Confidence high, with speech-act prior art (S06, S40).

**L10. Identities do not change while requests are open.**
- Incident. Renaming a machine made replies to earlier requests come from a different full address,
  so they would no longer close those requests, and replies addressed to the old name would be
  refused. The orchestrator reissued the open requests under the new name. The old requests could not
  be withdrawn, and one of them made an implementer's stop hook remind it on every turn.
- Reason. Requests are matched by full address, so a rename strands them.
- Seen once. Confidence medium, since task correlation in prior art agrees (S42).

**L11. Roles have stable names, and addresses outlive sessions.**
- Incidents. The orchestrator, implementer, QA, reviewer and auditor addresses were reused across
  sessions, and mail and open requests stayed with each address through every swap. Unused addresses
  accumulated and needed retiring. Before the transport existed the principal routed between the principal's sessions
  by hand, asking one for a file to paste into another and searching for a session by its topic, and a
  session renamed mid-task had to be matched by its session id.
- Reason. Work outlives the session doing it, so its address has to as well.
- Seen every time, throughout the round, and a few times before it. Confidence high.

**L12. The points where the human is needed are explicit, and everything else is delegated.**
- Incidents. The record reserved publication, tags, repository and personal settings, anything outside
  the plan, and reboots of a shared machine. Within that grant, gates replaced human review, namely
  green CI, an independent reviewer and the orchestrator reproducing the reviewer's tests. Most
  operational questions in the round repeated decisions already granted. Other sessions repeatedly
  asked before each step of authorized batches. Logins and credential renewal remained reserved.
- Reason. A team that needs the human at every step is slower than one session, and a team that never
  asks takes decisions that are the principal's.
- Seen every time, throughout the round, and many times elsewhere. Confidence high. M11, M12 and M29
  are the opposite failure, agents acting on what was the principal's.

**L13. Disruptive actions on a shared machine are announced ahead to every team using it.**
- Incidents. A planned release upgrade would reboot the machine the keryx team ran on; the agreed
  procedure required fifteen minutes' notice. In the nomos run the transport was upgraded
  under running sessions, and a session joined under the old version had its bell refused until its
  next transport command (LOG, 22:53).
- Reason. A team that loses its machine or its transport mid-task loses the work in flight.
- Seen once as an agreement and once as an incident. Confidence medium for announcing.

**L14. An address says which team a session belongs to, not only its role.**
- Incident. Transport addresses were a name and a host, and every team named its sessions its own way.
  One team used bare roles, another used task names, a third had to invent a prefix because the role
  names it wanted already belonged to the first team on the same machine, predecessors kept reachable
  got a suffix, and one orchestrator took the project's name as its address. The principal asked for the
  project to be in the address as well as the role. A public tool already carries the team in its
  addresses (S46, S47).
- Reason. Teams on one machine collide on role names, and a name that does not say its team cannot be
  resolved inside it.
- Seen a few times on one machine. Confidence low for the remedy, which is designed rather than run.

### Playbook lessons

**P01. Compose the team by what each model does best, across vendors.**
- Incidents. The implementer ran the strongest coding model available, the reviewer the most
  adversarial model of another vendor, the auditor a fresh session of that vendor blind to the changes,
  and QA a third vendor's model in Cursor to spread demand. The reviewer found a few real
  defects in every change and the blind audit found many. The QA seat found none of the code defects
  the reviewer reproduced, and a QA seat in the long-running team on yet another vendor did as little, which points
  at the role or its timing more than at the model.
- Reason. Models differ by role, and a reviewer from another vendor does not share the implementer's
  habits.
- Seen a few times in one round. Confidence medium for composing by role. Research backs independent
  review through self-preference bias, but not a rule that the vendor must differ (S18, S19).

**P02. QA starts with the implementer and reviews the plan, and the implementer waits a short, fixed
time for that review.**
- Incidents. When QA arrived with the change done it added little, and in one change it found nothing
  where the reviewer found must-fix defects. Reviewing a plan, it caught a real design gap in a race fix
  before any code. Over the round its record was no code defect, one plan gap and a few wrong facts in
  a document. In the long-running team, a QA seat beside the implementer raised one test gap and no reject across
  many runs.
- Reason. A plan review is cheap and early, and a second code review after the reviewer's adds little.
- Seen a few times in one round, and in a second setting for QA after the code. Confidence medium that
  QA after the code adds little, low that the plan is where it pays. The wait, fifteen minutes in the
  round, is a default.

**P03. The orchestrator verifies the reviewer's failing tests itself before merging, merges when every
must-fix test passes and CI is green, and stops at the second review round for small fixes.**
- Incident. Review rounds converged, and the second round of one change found only edge cases. Before
  merging, the orchestrator reran the reviewer's probes from both rounds against the final head.
- Reason. A reproduced test shows the fix holds, and a third round for small fixes costs more than it
  finds.
- Seen a few times in one round. Confidence high for reproducing before a merge, medium for the cap,
  which public review practice does not supply (S26).

**P04. The orchestrator reads messages, not transcripts, and filters every command's output.**
- Incident. After about four hours coordinating many sessions the orchestrator was at 59% of its
  window, while the first implementer reached 48% building one feature. Earlier, when the same session
  wrote the code itself, it filled up to a compaction. The same filtering once hid the one line a
  design depended on (M01). The topology guides of the long-running team's tool reach the same split, with cheap
  models reading the bulk and the expensive one deciding on their summaries, and warn that a summary
  without its context arrives looking like an answer.
- Reason. Coordination fits in one window only if the coordinator reads summaries.
- Seen every time, throughout the round. Confidence medium, since filtering also produced a false
  absence and a public source argues for sharing full traces (S08).

**P05. Swap a session at about half of its window, at a stopping point.**
- Incidents. Windows differ per model and setting, 1M for one session and 256K for another, so the
  threshold is per session. The long-running team used a quarter of a 1M window, swapped one seat about every hour
  and lost the role text on most swaps (M34). In single-session work, repeated
  compactions or swaps followed manual context readings and requests to save state first. One swap
  addressed drifting answers rather than a full window.
- Reason. A session near its limit forgets and compacts, and a swap at a stopping point keeps the
  state.
- Seen a few times in the round and in a second setting with a different threshold. Confidence medium
  for swapping at a stopping point. The number is a default, and no source backs a universal one (S20,
  S21).

**P06. Spread load across vendors and accounts, and know which pool each role draws from.**
- Incidents. The orchestrator and the implementers shared one usage pool, while review and QA ran on
  other vendors. Elsewhere a parallel batch of sessions on one account hit its usage limit together,
  cutting the coordinator and a reviewer in the same minute, and a code host's API rate limit turned
  out to be a pool too. One harness gives no supported way to show which account a session draws from.
- Reason. Every session on an account draws from the same pool at the same time.
- Seen every time, throughout the round, and a few times elsewhere. Confidence medium.

**P07. Keep the state outside the sessions.**
- Incidents. A decision log with dates and the principal's own words, a run log, briefs and probes in
  files, and a triage queue made every handover of the round possible. Another procedure
  required saving decisions before answering, but a few sessions still needed manual reminders
  to persist them.
- Reason. A session can be compacted or die at any moment, and the disk cannot.
- Seen every time, throughout the round, and in more than one other setting. Confidence high.

**P08. Give an outside user a cheap channel.**
- Incident. A session from an unrelated project found a few real issues in its first ten minutes, the
  first prompt passed on the command line, a misleading note and an outdated skill.
- Reason. A user outside the team reads the tool the way a new adopter will.
- Seen once. Confidence low.

**P09. Audit blind first, then compare with the previous audit.**
- Incidents. The auditor wrote its findings and recorded their checksum and the time before opening the
  earlier audit, then checked each earlier finding for regression. Another
  project ran an audit, a response and a rejoinder that audited the response, and the rejoinder found a
  citation that the fix had made more precise and more false. A validation of a plan and an advisor
  reviewing a design each wrote their own answer before reading the plan, and in both the blind answer
  differed from the plan on a central point that changed the verdict.
- Reason. A reviewer that reads the earlier audit or the plan first inherits its frame.
- Seen a few times, in more than one setting. Confidence high.

**P10. Ask the principal once, about understanding, and then act inside the plan.**
- Incidents. Sessions sent delegated decisions back for approval through the orchestrator, adding
  unnecessary confirmation steps. A handover note that told the new orchestrator to wait for
  confirmation was read as approval per step. In other sessions, repeated questions reopened
  authorized steps. A plan in the long-running team separated settled decisions, open choices with
  recommendations, and proposed defaults.
- Reason. Each question inside an approved plan costs the human a context switch and the team a wait.
- Seen many times in the round and elsewhere. Confidence high. M11, M12 and M29 are the opposite
  failure.

**P11. When a session asks a design question with options, decide with the reason, and accept a good
deviation.**
- Incident. The implementer's question on startup dialogs led to a better design than the brief's.
- Reason. The session closest to the code often sees what the brief missed, and a decision with its
  reason lets it go on.
- Seen a few times in one round. Confidence high.

**P12. Verify what is cheap to verify.**
- Incident. Signatures and trailers with `git log`, CI with the code host's checks, the change's text
  for internal ids and addresses, and the mailbox with `keryx status`.
- Reason. A check that costs seconds catches what a reviewer would miss.
- Seen every time, throughout the round. Confidence high. M26 refines it, since most cheap checks read
  a status, which confirms less than an action does.

### Harness facts

**H01. herdr 0.9.5 reports some startup dialogs as idle, among them Codex's "Hooks need review",
Cursor's "Workspace Trust Required" and Claude Code's folder trust, so read the screen.**
- Incidents. Seen at spawn in the round with all three harnesses, and in another setting when Codex
  seats launched by a different tool stopped at the same hook trust dialog. The version is the
  client's, and the running server on that machine was an older 0.9.3 (M49).
- Reason. A launcher that trusts the reported state waits on a dialog forever or types into it.
- Seen a few times, in more than one setting. Confidence high.

**H02. Narrow herdr panes wrap dialog text inside the harness's own box, so a phrase match fails, and
the match runs on joined lines without box borders.**
- Incident. A dialog line split as "1. Review" over "hooks" in a narrow pane, the dialog check matched
  nothing, and a bell could have typed into the dialog (M42).
- Reason. A check that misses a dialog lets text plus Enter confirm an option.
- Seen once. Confidence low.

**H03. In Codex 0.163, `codex queue --thread T` writes to a queue every app-server polls, and the
shared daemon keeps a thread loaded thirty minutes after its last client, so a queued message can
resume a closed thread.**
- Incident. The closed thread of L06 woke headless from a bell and joined a new address. A TUI started
  with any `-c` runs its own app-server. The keryx team then set an interim rule, to leave before
  closing a Codex session and to send nothing to a closed one's address (LOG, 22:14).
- Reason. A closed session that wakes acts under an identity nobody directs.
- Seen once. Confidence low for the mechanism. The rule it led to held every time after.

**H04. Claude Code 2.1.308 shows its predicted next prompt as dim text in the input, which can read as
an authorization nobody gave.**
- Incident. A dim predicted prompt in a pane read like an authorization the principal never gave. Read
  panes with ANSI before concluding someone typed, and never send a bare Enter to a Claude Code pane.
- Reason. A bare Enter submits the prediction as if the user had typed it.
- Seen once. Confidence low.

**H05. Claude Code takes `-n NAME` and `--remote-control NAME` at launch, Codex's `/rename` opens a
dialog and ignores an argument, and Cursor's `/rename` takes the name as an argument.**
- Incident. Seen while naming sessions at spawn in the round.
- Reason. A launcher that names sessions has to use each harness's own form.
- Seen once per harness. Confidence low.

**H06. Codex with `shell_environment_policy.inherit = "core"` drops `KERYX_*` and `HERDR_*` from its
commands, and `-c shell_environment_policy.set.NAME=VALUE` gives them back for that session only.**
- Incident. A Codex session's commands lost the transport variables, so a test session could join the
  live store unless a wrapper came first on PATH (M03). A related case in the round's feedback queue
  broke a command typed into a pane's interactive shell, through the PATH a launcher passed.
- Reason. A session without its variables acts as the wrong identity or in the wrong store.
- Seen once, with a related case. Confidence low.

**H07. A harness's initial prompt argument survives startup dialogs and is acted on once they are
answered, while a prompt typed after the start can be lost.**
- Incidents. Every first prompt of the round went in as the harness's own argument, and the handover
  notes reached new sessions that way. In the long-running team's tool, text pasted after a readiness probe was lost
  in most relaunches with a transcript (M34). The argument is visible in `/proc` to local processes and
  capped at 128 KiB.
- Reason. A session that never got its first prompt runs on generic instructions.
- Seen every time in the round, and measured in a second tool. Confidence high.

**H08. herdr agent start with a short `--timeout` makes herdr drop the agent's name, and a new herdr
pane inherits the server's environment, not the caller's.**
- Incidents. An agent started with a short timeout came up unnamed, while stopping the client kept the
  name. An agent launched from a pane of a server started inside a Claude Code session was taken for
  that session (M09).
- Reason. A pane's identity variables come from the server, so a test started from an agent's shell
  looks like that agent.
- Seen once each, with M09 as the same mechanism. Confidence medium.

**H09. A systemd user service does not see the mise shims, so a unit that has to run herdr or a harness
CLI needs its PATH set.**
- Incident. A unit in the round's feedback queue failed before it reached the harness, because the
  binaries sat on a PATH the service did not have.
- Reason. A user service starts with a minimal environment.
- Seen once. Confidence low.

## Candidates mined from other agent work

**M01. When a search for a fact comes back empty, rerun it without truncation before concluding the
fact is absent.**
- Incidents. In the first keryx round a search through a harness binary for its session id variable
  was cut short by a pipe to `head`, and the team concluded the harness exposed no id. An acceptance
  run later found the variable, and the identity design had to move forward a stage. Elsewhere,
  installing a CLI through `curl | bash` failed because an output-compressing shell hook truncated the
  script. A nightly script in the long-running team read an empty list from a starved daemon as "nothing alive" and
  logged success without stopping anything. In the nomos run, compressed listings hid files (LOG,
  22:50).
- Reason. The filter that keeps an orchestrator light can hide the line a design depends on, and an
  empty answer from a failing source is not an absence.
- Seen a few times, in more than one setting. Confidence high for the problem, medium for the remedy.

**M02. A brief says when the task ends and whether the session stays for follow-up work.**
- Incidents. A reviewer whose brief ended with the standard line to run `keryx leave` when the task
  ends left right after replying, so it was gone when its findings had to be verified against the
  fixes. Outside keryx, an agent closed a temporary permission it had been given for a test as soon as
  the test ended, and the principal reopened it and said not to close it until the principal said so.
- Reason. Leave before close, applied to a vague end of task, closes the session too early. A task ends
  when the principal accepts the result, not when the session's own steps are done.
- Seen a few times, in more than one setting. Confidence medium, since the remedy has not been run yet.

**M03. Live tests and probes run in an isolated environment of their own, never in the team's live
store or the user's default session server, and every config file a test touches is backed up and
restored.**
- Incidents. The first acceptance run used real agents in a separate herdr server and a temporary
  store, deleted afterwards. A later run added entries to a harness's global config for a scratch
  folder and restored them from a backup, and the audits ran their checks in a temporary clone. One
  harness drops the store variable from its commands (H06) and a new pane inherits the server's
  identity (H08), so a test without isolation joins the live store as the wrong session. Just before
  the round, a test meant for a disposable worktree ran for a few seconds in the working checkout
  because a chained `cd` broke (M29). Other recorded guidance also required isolation from live destinations.
- Reason. The team's mail lives in the same store a test would write to, and a test that leaks into it
  rings or reads real sessions.
- Seen many times in one round, and broken once just before it. Confidence high.

**M04. Audit a fixed commit that nobody is writing to, and name it in the report.**
- Incident. The first audit ran while another session was still changing the repository. The auditor
  froze a copy, and one of its findings described a mid-work state that was already fixed when the
  report arrived. The second audit pinned a commit, ran in a temporary clone and confirmed at the end
  that the tree had not moved.
- Reason. A finding about a state that no longer exists costs a triage round and dilutes the others.
- Seen once as a cost and once done right. Confidence medium.

**M05. A message that reached a session is not a message the session processed, and read state comes
only from the session's own action.**
- Incident. In probes before keryx's first stage, a message delivered into a session while it had a
  question open to the user reached the model and was not acted on. The messaging documentation of a
  public multi-agent tool draws the same line, that delivery is not acceptance and that consequential
  delivery is confirmed by its effect (S37).
- Reason. A transport that marks delivery as reading reports work nobody started.
- Seen once, with prior art that agrees. Confidence medium.

**M06. Text that one session writes and another reads, such as names, roles, headers and reminders, is
plain and validated before it reaches the reader's context.**
- Incident. An automated security review found that a role string stored by one session could carry
  terminal escapes into another session's screen and context through the roster, a bell or a hook
  reminder. The fix made every cell and header plain and validated ids, threads and addresses.
- Reason. In a team one session's output is another's prompt. The authority rule covers what a peer
  may ask for, not what its bytes can do once they are in the context.
- Seen once. Confidence low.

**M07. When the principal names a reference project, open it before designing, and take from it the
level of care, not its conventions.**
- Incidents. The principal had to ask whether a named reference project had been looked at. It had not,
  and the documentation was reorganized after it was. The same day an agent carried another reference
  project's conventions over, and the command grammar modeled on it was rejected.
- Reason. A reference used too little wastes the principal's pointer, and one used too much imports
  decisions made for another domain.
- Seen a few times, in opposite directions. Confidence medium.

**M08. Examples in a skill or brief use quoted, obviously illustrative text, never a bare placeholder a
model can send as is.**
- Incident. An orchestrator on a small model at low effort sent the literal word TEXT, copied from the
  skill's usage line.
- Reason. Every model on the team reads the skill, the cheapest included.
- Seen once. Confidence low.

**M09. A harness started from another harness's shell inherits its identity variables, so identity
checks read the innermost harness first.**
- Incident. A Cursor or Codex agent launched from inside a Claude Code session, or in a herdr server
  started from one, was taken for that Claude Code session because the tool read the Claude variable
  first.
- Reason. Every orchestrator spawns from its own shell, so the inheritance is the normal case.
- Seen once as a defect, with H08 as the same mechanism. Confidence medium.

**M10. Turn a correction the principal has had to repeat into a mechanical check that runs before the
output is shown, since a rule kept in memory did not hold on its own.**
- Incidents. The principal repeatedly corrected output that broke rules already in the sessions'
  memory. A write hook that refuses such output held where memory alone had failed. Another repeated
  correction became an always-applied rule. In the long-running team, an approval policy kept in a
  seat's role text and applied by a model reading the screen failed in silence.
- Reason. Every new session starts with the rules as text and its model's habits. A gate costs the
  principal nothing, while a repeated correction costs another round, and a team multiplies the
  sessions that have to learn it.
- Seen many times, in more than one setting. Confidence high.

**M11. A question from the principal asks for an answer or a proposal, never for the action.**
- Incidents. Asked a clarifying question about a file, an agent answered and also edited the file.
  Asked to assess a proposed action and describe its result, another agent performed it, requiring
  an undo. Asked for an explanation, a session changed code instead.
- Reason. An action taken on a question is unrequested work that the principal then reviews or undoes, and
  outward actions cannot always be undone.
- Seen a few times. Confidence high.

**M12. Choices the team will live with, such as the language, the runtime and where the code lives,
belong to the principal, and the agent lists the options with what is already in use and waits.**
- Incident. An agent wrote a new tool in a language it picked without asking, and the principal noticed
  only after days of review. No comparison had been made before starting.
- Reason. Changing such a choice later costs the rewrite, the tests and the evidence again.
- Seen once. Confidence low.

**M13. Every review has at least one lens that sees only the requirement and the code, blind to the
principal's framing.**
- Incidents. A review of a change by many agent passes, each given the change's description, its
  commit messages and the earlier findings, checked the mechanism of every finding, and none asked
  whether the chosen fix addressed the cause. A human reading the raw code found the cause in minutes.
  The audit method of another project settled on reading code and running
  commands, never the project's documentation, because auditing by the documentation produced praise
  and no findings. The keryx round wrote the rule into its review briefs and ran its audit blind.
- Reason. Passes that share the principal's premise attack the details and inherit the premise.
- Seen a few times, in more than one setting. Confidence high.

**M14. An outward-facing action by a delegated session needs an explicit, literal authorization from
its coordinator, not an approving word.**
- Incident. A literal confirmation token required before every publication held each time and stopped
  one near miss, including a wrong correction by the coordinator.
- Reason. In a relay, "approved" can refer to the findings, the text or the publication, and a token
  names exactly one act.
- Seen every time in one setting. Confidence high.

**M15. A reviewer's factual claims are measured before they are relayed, at the exact ref, tag or
package they are about.**
- Incidents. The reviewer was right against the coordinator once, and corrections were measured in
  both directions. In the keryx round every must-fix came with a failing test and every one reproduced
  (L03, P03). In the nomos run, the orchestrator's own restatement of a search result changed a fact
  (LOG, 22:51).
- Reason. A claim without a test can be wrong whatever model makes it, and a correction is a claim too,
  so its receiver measures it before applying it.
- Seen a few times. Confidence medium.

**M16. Decide per session whether peer messages are accepted or held for human approval, since a held
message is a human interruption and may expire.**
- Incidents. A message to a task-management session was held for the principal's approval and expired.
  The principal pasted the text by hand. A relay to a session on a second machine ran in a different permission mode,
  and the target held the message until the principal approved it. In probes before keryx's first stage, a session
  in bypass held peer messages unless it accepted cross-session messages. Later the principal found
  another session's messages each waiting for the principal's confirmation because that session was not in bypass.
  The orchestrators of the keryx round and of the nomos run never held their own address, since every
  bell would have become a dialog.
- Reason. A team built to need the human only where necessary loses that if every message stops at a
  dialog.
- Seen many times. Confidence high.

**M17. A reply channel without a notification is not read, so every channel a team uses rings its
reader.**
- Incident. Before keryx existed, a session on a second machine answered by appending dated sections
  to a file there, and several replies, one of them asking to reset a clone, stayed unread until the
  principal asked. It is one of the incidents that led to building keryx.
- Reason. Polling depends on the reader remembering to poll, and a session near its limit does not.
- Seen once. Confidence low.

**M18. Give every writing session its own worktree, commit finished work at once, and verify every
claim against a named commit.**
- Incidents. While one session audited another project, another wrote in the
  same worktree all day. The status changed between two reads, a test suite failed because the other
  session was rewriting that code at that minute, and the other session's broad `git add` swept the
  auditor's uncommitted work into its own commits a few times, once minutes after a rule against it was
  written down. Two sessions on one porting project left scripts uncommitted in a shared tree, and one
  overwrote a file the other also wrote. In the keryx round every implementer had its own worktree and
  no such incident was recorded, and reviewers were given clones of their own. The human writes too,
  and a file the principal has taken is not the session's to edit.
- Reason. A reading taken from a tree someone else is writing is unstable, and an audit or review
  built on it concludes wrong.
- Seen a few times as a failure and held through one round. Confidence high for the problem, medium
  for the remedy.

**M19. Cut cost by cutting context and empty wake-ups, and move a seat to a cheaper model only with
evidence that its quality holds.**
- Incidents. In the long-running team an agent proposed moving the orchestrator seat to a cheaper model. The change
  was declined because equivalent quality had not been established. A
  measurement the same day showed the spending was context, with the lead seat at about 720K tokens
  per call on a 1M model that does not compact. The long-running team then got a ceiling of 250K tokens per seat, a
  planned handover at every boundary between pieces of work and a fresh reviewer per cut. A health
  watchdog woke a seat on the strongest model every 30 minutes to run a deterministic script. A
  separate design used a deterministic frequent tick and reserved the expensive model pass for
  twice a day.
- Reason. A cheaper model saves quota once and costs quality on every task, while context is the waste
  that grows by itself.
- Seen once as a decision, with measurements and prior art that agrees (S21). Confidence medium.

**M20. Before working around a tool a team runs on, decide whether the gap is its design or a defect,
follow the design, patch only a proven defect, and expect a local patch to vanish on upgrade.**
- Incident. Reviewing the long-running team, the principal found that much of its own layer of scripts, patches and
  operations seats worked around the tool's design rather than a defect. A local patch to the tool's
  launcher had to be reapplied after every upgrade until a release fixed the cause. The daemon ran
  with a core component off on another agent's vague advice, and with the tool's own activity hooks
  missing, so most seats showed an unknown state and the layer scraped the screen instead.
- Reason. Workarounds of a design break at every upgrade and hide the supported path.
- Seen once in depth. Confidence low.

**M21. When a launch or send times out with an unknown outcome, read the effect before trying again.**
- Incidents. The long-running team's tool printed UNKNOWN after a five-second client timeout on launch while the seat
  came up anyway. herdr's agent start with a short timeout dropped the agent's name (H08), and keryx
  spawn timed out on a trust dialog while the session joined by itself once the dialog was answered. A
  send that failed verification was retried and a later attempt went to another conversation (M55),
  and the principal once stopped a retry to check first where an unclear send had gone.
- Reason. Retrying an action that did happen duplicates a session, a message or a seat.
- Seen many times, in more than one tool. Confidence high.

**M22. Check that every seat runs the model and effort its spec says, after every relaunch.**
- Incident. A reviewer seat in the long-running team ran a different model from its spec, by drift. In that tool,
  setting a seat's model applies only on resume, and a launch restores from a snapshot that carries the
  old model.
- Reason. A team composed by model (P01) is broken silently by a seat on the wrong one.
- Seen once. Confidence low.

**M23. An orchestrator that relays the principal's delegation marks the text as its own, never as the
principal's.**
- Incident. When an implementer asked the principal in its pane for a decision, the orchestrator answered
  in that session's input, marked as the orchestrator relaying the delegation. The same night a dim
  predicted prompt in a pane read like an authorization nobody gave (H04).
- Reason. Text in a session's input reads as the user's voice, so an orchestrator writing as the principal
  forges the one channel the protocol trusts (L04).
- Seen once, with H04 in the same family. Confidence low.

**M24. A defect a review finds is the team's to fix whatever its origin, and the origin decides which
change takes it, never whether it is fixed.**
- Incidents. Treating a defect as pre-existing, so not the team's, let one pass in earlier work often
  enough to be written into that project's runbook. In the keryx round the reviewer of one change
  found a race that predated it, and the orchestrator took the fix as an extension of the same change.
- Reason. A reviewer that sorts findings by blame leaves the defect in place.
- Seen a few times, the earlier case only as the notes tell it. Confidence medium.

**M25. Keep every review round verbatim in a file, and check each new version against all earlier
rounds, saying for each item whether it was resolved, only masked or subverted.**
- Incidents. In a document, points from earlier reviews came back in a new version, some in another
  guise, requiring another correction. In the keryx round, before merging a change, the
  orchestrator reran the reviewer's probes from both rounds against the final head.
- Reason. A fix checked only against the last round lets earlier defects come back, and the reviewer
  pays for the same reading twice.
- Seen a few times, in more than one setting. Confidence high.

**M26. Confirm by exercising the smallest real action and reading its effect, since status,
configuration and hand-built cases are trust, not confirmation.**
- Incidents. Asked to confirm that a message channel was open, an agent cited the tool's status, and
  the principal said that was trusting, not confirming, and to send the message. A field test was run by
  writing state into a store by hand while the real flow was reachable, and presented as validated.
  The principal later added that forged state is legitimate when the report says how the state was reached
  and what the case does not prove. Command guards passed hand-built cases and had never fired in a real
  session of the harness they guard. A coordinator checked each publication through the code host's API
  rather than the reviewer's report, and stopped reading an aggregate review state that was already in
  the target state before the act.
- Reason. Status and configuration say what should happen, and only the action shows what happens.
- Seen many times, in more than one setting. Confidence high.

**M27. Write what the current state does as a scoped fact, and write a principle only when a decision
or a test imposes it.**
- Incident. An agent wrote in a tool's architecture document that the tool only reads, inferred from
  the commands it had then, though write commands were planned.
- Reason. A document becomes a contract, and a principle inferred from one moment is false at the first
  change.
- Seen once. Confidence low.

**M28. A rewrite changes only what was asked and keeps the rest, and says so when a change removes
content.**
- Incidents. Repeated passes of an iterated rewrite cut points already supplied. Other sessions
  widened their tasks a few more times and needed corrections to return to the requested scope.
- Reason. It is the loss a careless handover causes, done by hand, and a writer seat iterates on the
  same documents for several rounds.
- Seen many times. Confidence high.

**M29. Before an experiment whose output will look like breaking a standing instruction, say what it
is and why, or do not run it.**
- Incident. Minutes after the principal forbade a version bump, an agent tested the bump path of a release
  script in a disposable worktree. The output showed the next version without identifying it as a test, leaving publication
  unclear. A broken chained `cd` had run the test for a few seconds in the working checkout
  (reverted, nothing committed).
- Reason. The principal reads results, not intentions, and a team's results reach the principal without their
  context.
- Seen once. Confidence low.

**M30. When the human decides in a dialog, the reasoning goes inside what the dialog shows, not in the
output above it.**
- Incident. An explanation requested for a decision had been printed immediately before a question
  dialog, which covered it in the terminal. The explanation had to be requested again.
- Reason. The human decides looking at the dialog.
- Seen once. Confidence low.

**M31. When a skill already defines a flow, follow it and add no gates of your own.**
- Incident. An agent running a review procedure added a briefing step with a wait before each point.
  The added flow required correction because the procedure had not requested those waits.
- Reason. Two protocols over one task double the round trips and drift from what the skill documents.
- Seen once. Confidence low.

**M32. A seat never judges the value of its own role, and analyses of a team's seats come from a
verifier outside the seats being judged.**
- Incident. An analysis of the long-running team's seats, written by subagents of its operations seat, concluded that
  no seat needed to go, and its cost figures used the most favorable window and a denominator that mixed
  two vendors' separate quotas. An external verification that checked every line at the primary source
  reversed its main conclusions.
- Reason. It is the anchoring of M13 with an interest added.
- Seen once, in detail. Confidence low.

**M33. Measure what the team spends on itself against what it spends on the work, and cut process when
it dominates, since a review finding justifies a bounded repair, not more process.**
- Incidents. The long-running team grew from a few seats to many in under a day, and most of the new seats worked on
  the long-running team itself. Its operations seats took fewer than half of the tokens over two days but nearly all
  of them on one night. Most of the principal's messages in a sample were about the long-running team rather than the
  product, and none of the scripts written for the layer ran the product.
- Reason. A team that measures only the work cannot see its own weight.
- Seen once in depth. Confidence low.

**M34. After every handover or relaunch, check that the new occupant has its role, brief and authority
in context, since the tool reporting it ready is not evidence.**
- Incidents. In the long-running team, every session started by handover lost its role text, and most fresh
  relaunches with a transcript lost it too, while the daemon marked every one ready. A readiness probe
  passed too early and the pasted startup text was lost. In the keryx round the first prompt went in as
  the harness's own argument (H07) and the handovers worked. In the nomos run each successor restated
  its role, order of work, authority and ceiling in a readback before working (LOG, 22:16).
- Reason. A session without its role keeps working on generic instructions, and nothing in the team
  notices.
- Seen many times in one tool, and as H07 in another. Confidence high for the problem, low for the
  readback.

**M35. Review a unit big enough to hold the defects that cross its parts.**
- Incident. The long-running team reviewed every small cut of a piece of work with a fresh reviewer,
  paying for a fresh session for every accepted cut. The first review of a whole piece, by another
  vendor's reviewer, rejected it for a defect between cuts that every per-cut review had accepted.
- Reason. A fresh reviewer per unit (L08) is only as good as the unit.
- Seen once. Confidence low.

**M36. Parallel reviewers do not see each other's verdicts until both are in.**
- Incident. In the long-running team a second reviewer accepted a cut with no findings and, a minute after the first
  reviewer's reject, issued a corrected reject. Only the order of the timestamps was checked
  (suspicion). Each reviewer, from a different vendor, also had defects only it caught.
- Reason. A second opinion that reads the first is not a second opinion.
- Seen once, as a suspicion. Confidence low.

**M37. The team has one channel to the human, declared at the start, and everything that depends on the principal
goes there.**
- Incidents. In the long-running team the principal asked a few times in a few hours why what depended on the principal was not
  reaching the principal through the declared gateway. In the keryx round the principal told an implementer that asked the principal in
  its pane that the principal talks only to the orchestrator. In a coordinated review, reviewer sessions that each
  asked the principal directly sent the principal questions from many panes at once, and in a later round with one channel
  the reviewers asked the principal nothing while the coordinator grouped the questions per change with proposed
  options. A plan was held back because its default delivery left a decision for the human silent for
  hours.
- Reason. The human does not watch the panes, so a question in a pane waits until the principal happens to look.
- Seen many times, in more than one setting. Confidence high.

**M38. Every question to the human says whether it blocks the next step.**
- Incident. A set of open decisions omitted whether they blocked the next step, requiring a
  follow-up question before the principal could decide when to answer.
- Reason. A non-blocking question that stops the work costs the team time and the human a context
  switch the principal could have scheduled.
- Seen once. Confidence low.

**M39. Messages carry absolute dates and times, never "yesterday" or "today".**
- Incident. The principal corrected a session that placed something the principal had just done on the day before,
  and said the same misjudgment had happened before across sessions.
- Reason. A session has no reliable sense of elapsed time across compactions and handovers, and a
  reader cannot tell when "yesterday" was.
- Seen once as a quote, described by the principal as repeated. Confidence low.

**M40. A team on a shared machine leaves it usable for interactive work, watches its load and plans
for the machine being suspended.**
- Incidents. The principal's interactive use of the machine was disrupted, and the long-running
  team's operations seat reported stopping every working seat to free the CPU (the causal link is a
  suspicion). The principal also asked how the team would resume after the machine was suspended.
  Codex sessions in a terminal multiplexer kept pulling the principal to their screen from another workspace.
- Reason. The machine is shared with the human the team serves, and L13 covers announcing a disruptive
  action, not the team itself being the disruption.
- Seen a few times, partly checked. Confidence medium.

**M41. Count tokens from Claude Code transcripts after deduplicating by message id, and report cost per
quota pool and over more than one window.**
- Incident. The long-running team's cost note says the transcripts count double without deduplication by message id,
  and an independent recount with that rule reproduced the long-running team's own script to within 0.1M tokens per
  seat. The same verification showed a single favorable window and a pool mixing two vendors
  understating a seat's share (M32).
- Reason. Cost decisions are only as good as the count.
- Seen a few times. Confidence medium.

**M42. Nothing types into a pane that shows a selection dialog, since pasted text plus Enter confirms
the highlighted option.**
- Incidents. In the long-running team's tool, sending a message into a pane with a permission prompt pasted the text
  and pressed Enter, so it confirmed the first option whatever the text said, and the tool now refuses
  without a dangerous flag. In the keryx round a narrow pane wrapped the dialog text (H02), the dialog
  check matched nothing, and a bell could have typed into the dialog. The long-running team's nightly script answered
  a resume selector by itself, against an invariant the tool states.
- Reason. A message meant as information becomes an approval nobody gave.
- Seen a few times, in more than one tool. Confidence high.

**M43. Harness facts from the long-running team, each seen once.**
- Claude Code 2.1.280 let an ask rule in settings win over a hook's allow decision, and its auto mode
  did not grant more than accept-edits with a wide allow list.
- Claude Code asked approval for commands with a shell variable or a loop even with the rule allowed,
  and only auto mode or bypass avoided it (September 2026, version not recorded).
- An identity check parsed a weekday from `ps` and failed under a locale other than the one it expected, and keryx hit locale
  defects as well, US-ASCII under ssh without LANG and the C locale. Test team tooling under the
  machine's real locale and under ssh's bare one.
- A session relaunched or handed over in the long-running team lost its remote control flag.
- Reason. Each is a trap a team meets at spawn or at a handover.
- Seen once each. Confidence low.

**M44. A grant of elevated authority states its scope and its expiry.**
- Incidents. The first prompt of a support session for a porting project said the principal had turned on
  passwordless sudo until a stated time, and listed what the session must not do with it, such as a
  release upgrade or a reboot without a separate grant. Earlier, a session of that project that
  needed root while the principal was away left the request pending and ran nothing as root.
- Reason. Some grants are narrower in time than the session, and a session cannot know that unless the
  grant says so.
- Seen a few times. Confidence medium.

**M45. A lesson enters the procedure the sessions actually load, such as a skill, a brief, a rule or a
hook, or it is not applied.**
- Incidents. A lesson on review anchoring was written to memory with a concrete method, and the
  review procedure, changed weeks later, still started by reading the change's description and had
  no blind lens. A coordinated review mode lived in briefs rather than in the skill, so every brief had
  to repeat its overrides. A reviewer still cited a precedent that did not exist despite a loaded rule
  against invented examples, and a measurement caught it. The rules that held are the ones moved into
  hooks and always-applied rules (M10), and one script serves the hooks of two harnesses.
- Reason. Memory is read by the session that wrote it, and a skill by every session that runs it.
  Entering the procedure is necessary and not enough, and a check that runs is what held.
- Seen a few times. Confidence high.

**M46. A brief says that an empty result is a valid outcome, and an empty result is verified like a
finding before anyone acts on it.**
- Incidents. A coordinating session told a reviewer of a small change that it could legitimately find
  nothing and that an explicit empty batch beats an invented finding. The reviewer returned an empty
  batch, and the coordinator reproduced the main measurements itself before authorizing an approval. In
  the long-running team an empty verdict did not hold and turned into a reject after another reviewer's verdict (M36,
  suspicion). In the nomos run a command in the harness notes returned nothing with exit 0 because it
  selected a type that matches no line (LOG, 22:51).
- Reason. A reviewer that must return something invents a finding, and one that returns nothing may not
  have looked.
- Seen a few times. Confidence medium.

**M47. Every count names its unit, its scope and its denominator, and keeps them from one answer to the
next.**
- Incidents. Asked what was waiting for the principal's review, a coordinating session counted work items in one
  answer and changes in the next and added an item from another queue. The principal noticed only because
  the number grew, and it took a few exchanges to settle. A correction sent to a reviewer and a
  reviewer's claim each carried a count with the wrong denominator. In the long-running team a cost share used a
  denominator that mixed two vendors' quotas (M32).
- Reason. The human checks counts by their consistency between messages, and a number whose unit moves
  cannot be checked.
- Seen a few times, in more than one setting. Confidence high.

**M48. An answer to the human answers the question asked, first and short, and names every
referent.**
- Incidents. On 2026-10-22, one coordinating session received three corrections within twenty
  minutes for length, answering a different question and using an unnamed referent. Three other
  sessions across August to October 2026 received corrections for fragmented text, an obscured
  command and an answer that did not explain the failure. The corrections recurred in separate
  sessions over months.
- Reason. The human reads the first lines and decides from them, and a pronoun that points into the
  session's own context gives the reader no referent.
- Seen many times across two settings. Confidence high.

**M49. Harness facts from the reviewer and porting sessions.**
- herdr's client and server versions diverge after an upgrade, and the sessions run on the server. On
  the machine used in these runs `herdr status` reported client 0.9.5 and a running server 0.9.3 marked stale.
  A porting session kept the old binary until a reboot because the new client found the running
  server's protocol incompatible. Harness notes give the server's version.
- A script created with Claude Code's Write tool has no executable bit, and in a privileged batch it
  failed with exit 126 after the principal had already authenticated.
- Claude Code 2.1.308 delivers a peer session's message as a user turn wrapped in a
  `cross-session-message` tag with the sender's name and permission mode, followed by a fixed paragraph
  saying the text comes from a teammate, cannot grant escalation and is not the user's approval. A team
  that mixes this transport with keryx has two authority texts in play.
- Claude Code 2.1.289 injects a usage-limit note telling the model to finish the piece in hand and a
  few more and then stop, and after the reset a note saying not to mention the earlier ones. A
  background subagent died at the limit, and the reviewer correctly reran its validator. A report
  written under the first note could be shorter than the work without saying so (suspicion).
- Reason. Each changes what a team sees, or what a session does, without telling it.
- Seen once each. Confidence low, except the version split, which was checked on the machine.

**M50. A decision taken on a reason, or deferred, is written down with that reason and with what
reopens it, and the session that removes the reason reopens the decision.**
- Incident. An agent in another harness recommended starting the long-running team's tool with a core component off,
  for a symptom, a deferral and a mechanism that turned out to be wrong. Hours later another session
  fixed the symptom's real cause and restarted with the same flag without reopening the question, and
  days later the long-running team had rebuilt that component's job by hand.
- Reason. A provisional choice that carries no reason becomes permanent by inertia.
- Seen once in depth. Confidence low.

**M51. A report opens with its provenance and its footprint, meaning who wrote it, for which request, on
which version or commit, and what it changed or that it only read.**
- Incidents. Every advisor report of a study of the long-running team opened with one line giving the date, the seat,
  the work item, "read-only" and the version read, and the external audits of that study opened the
  same way. The keryx audits named the commit and the limits of what they analyzed (M04). A
  coordinator, after reproducing a reviewer's check, told it that the check left a generated file
  behind, a footprint the reviewer had not reported.
- Reason. A reader decides how far to trust a report by what it touched and what it stood on.
- Seen many times as practice and once as an omission. Confidence high.

**M52. No session changes its own permissions; the record names who chooses and applies the policy,
and the result is checked in the target session.**
- Incidents. The long-running team's advisor split the setup of a new team so that the principal chooses the permission
  policy and runs every privileged command, the principal's own session applies the files, the advisor reviews, and
  no agent runs sudo. Among the long-running team's counted permission prompts, one was a seat asking to edit its own
  settings. Claude Code 2.1.308 puts the same rule in the text that wraps every peer message (M49). A
  separate report suspected an attempt to bypass a reserved permission gate; the attempt was not
  verified.
- Reason. A session that can widen its own permissions has none in practice, and a peer that asks for
  it is the easiest path to an escalation nobody chose.
- Seen a few times, in different forms. Confidence low.

**M53. Before asking the human to run or approve a privileged batch, run every check that does not need
the privilege.**
- Incidents. A porting project's root batch, which the principal authenticated each time, took a few
  rounds, each stopped by a defect that could be found without root, a package named differently in the
  configured repository, a path prefix doubled by string concatenation, and a script without its
  executable bit. The proposed batch also needed a check that its commands would run on a clean install.
- Reason. Every round of a privileged step costs the human an interruption, and the principal is the one resource
  of the team that cannot run in parallel.
- Seen a few times. Confidence medium.

**M54. When a session restates the principal's words, it quotes them or keeps their meaning exactly,
since a changed claim is a false claim in the principal's name.**
- Incidents. Across August and September 2026, four drafts changed the principal's claims. A fifth
  case, an instruction for an adversarial review, required the original words instead of a summary.
  In the nomos run, the orchestrator's restatement of a search result also changed a fact
  (LOG, 22:51).
- Reason. A relay that rewrites the principal's words changes the claim attributed to the principal.
- Seen five times in the earlier records, four as failures, plus the nomos search-result case.
  Confidence high.

**M55. An outward message is addressed by the exact id of its destination, and the sending tool refuses
anything else, and after a send that failed verification the sender reads where it went before trying
again.**
- Incident. An outward action used an ambiguous destination. A retry after failed verification
  repeated the routing failure. The sending tool was changed to refuse ambiguous destinations.
- Reason. An outward action cannot always be undone, and a destination inferred from an ambiguous reference
  is a guess.
- Seen a few times, then fixed in the tool. Confidence high.

## Sources

Public sources from the research register, all read on 2026-10-23 (UTC). Each entry gives the title,
the author or organization, the URL and what the source supports in v0. Vendor and project documents
establish reported practice, not comparative efficacy, and the research read the academic papers at
abstract depth unless it says otherwise.

**S01. A2A specification.** The A2A project, Linux Foundation.
<https://a2a-protocol.org/latest/specification/>. It separates messages, tasks, contexts and
artifacts, defines cancellation, and says in-task authorization does not by itself confer
permission. v0 uses it to keep a work item's state apart from whether a session is alive, and for
read state coming only from the reader's action.

**S03. ACP run lifecycle.** Agent Communication Protocol, BeeAI and IBM, now part of A2A.
<https://agentcommunicationprotocol.dev/core-concepts/agent-run-lifecycle>. Created, in progress,
awaiting, completed, cancelling, cancelled and failed are distinct states. v0 uses it to keep
accept, progress and clarify from closing a request, and to treat a cancel and its acknowledgment
as separate events.

**S04. ACP message structure.** Agent Communication Protocol, BeeAI and IBM.
<https://agentcommunicationprotocol.dev/core-concepts/message-structure>. Messages carry typed
parts and named artifacts referenced by URL. v0 uses it for a report that names its deliverables
apart from its narrative.

**S06. KQML.** Finin and others, AAAI workshop paper, 1994.
<https://cdn.aaai.org/Workshops/1994/WS-94-02/WS94-02-007.pdf>. It separates the message protocol
from content languages and treats query and reply apart from other interaction patterns. v0 uses it
as speech-act prior art for the split between a request and a message, and for a small vocabulary
of intent.

**S07. Multi-agent research system.** Anthropic, 2025-06-13.
<https://www.anthropic.com/research/multi-agent-research-system>. An orchestrator with workers in
independent contexts, condensed results and a persisted plan, with much higher token use than chat.
v0 uses it for what a brief carries, for keeping the orchestrator on summaries, and for summaries
that carry their sources.

**S08. Don't Build Multi-Agents.** Cognition, 2025-06-12.
<https://cognition.com/blog/dont-build-multi-agents>. It argues for sharing full traces, since
actions carry implicit decisions that conflict across parallel workers. v0 reconciles it with an
orchestrator that reads summaries, by keeping traces, probes and the decision log on disk.

**S09. Multi-Agents, What's Actually Working.** Cognition, 2026-04-22.
<https://cognition.com/blog/multi-agents-working>. Several agents can contribute while writes stay
single-threaded, and parallel writers risk incompatible choices. v0 uses it for one writer per tree
and for briefs that share sources and plans.

**S11. Claude Code agent teams.** Anthropic, living documentation.
<https://code.claude.com/docs/en/agent-teams>. Teammates use mailboxes on disk, a plan approval
mode can approve on arrival without review, and relayed approval claims are untrusted input. v0
uses it for a relayed "approved" not being a grant, for a plan review that a mode cannot replace,
and for leaving before close.

**S12. Claude Code subagents.** Anthropic, living documentation.
<https://code.claude.com/docs/en/sub-agents>. A subagent definition states its model, tools,
permissions and context. v0 cites it for the unit of review and for allowing continuity across
rounds of one change.

**S15. OpenAI Agents SDK, human in the loop.** OpenAI.
<https://openai.github.io/openai-agents-python/human_in_the_loop/>. Tool approvals interrupt and
resume from retained state, and some environments do not support them. v0 uses it to scope an
approval to one suspended action and to check that a harness enforces a gate it claims.

**S16. Claude Code permissions.** Anthropic, living documentation.
<https://code.claude.com/docs/en/permissions>. Permission modes, tool rules and working directories
are configured separately. v0 uses it for a delegation that has to be translated into the tool's
actual policy, which stays subordinate to enforced restrictions.

**S17. Cursor run modes.** Cursor, living documentation.
<https://cursor.com/docs/agent/security/run-modes>. Approval classification and shell sandboxing
are different layers, and the documentation says its automatic review is not a security boundary.
v0 uses it to keep permitted intent, automatic approval and operating system enforcement apart.

**S18. Self-Preference Bias in LLM-as-a-Judge.** Wataoka and others, arXiv 2410.21819 v2.
<https://arxiv.org/abs/2410.21819v2>. A judge model favored its own and more familiar outputs. v0
uses it to back independent review, while noting that different authorship is not enough
independence.

**S19. Self-Preference Bias in Rubric-Based Evaluation.** Pombal and others, arXiv 2604.06996 v3.
<https://arxiv.org/abs/2604.06996v3>. Self-preference appears even on objective criteria, including
code tasks, and ensembles reduce it without removing it. v0 uses it with S18, and not as a rule
that the reviewer's vendor must differ.

**S20. Lost in the Middle.** Liu and others, TACL 2024. <https://aclanthology.org/2024.tacl-1.9/>.
Retrieval accuracy depends on where the relevant text sits in a long context. v0 uses it for
managing context, and as no basis for a universal renewal threshold.

**S21. Effective context engineering for AI agents.** Anthropic, 2025-09-29.
<https://www.anthropic.com/research/effective-context-engineering-for-ai-agents>. Context is a
finite resource managed with external notes, selective retrieval and renewal. v0 uses it for
checkpoints, renewal per session and an orchestrator that keeps its own context light.

**S22. The Scrum Guide.** Ken Schwaber and Jeff Sutherland, November 2020.
<https://scrumguides.org/scrum-guide.html>. The Definition of Done is a standing quality bar shared
by teams. v0 uses it to split what done means into a quality bar, a task's acceptance criteria and
the report contract, and for follow-up work as a new request.

**S26. Google engineering practices, the standard of code review.** Google.
<https://google.github.io/eng-practices/review/reviewer/standard.html>. Approve changes that
improve code health without demanding perfection, and mark optional comments. v0 uses it for
must-fix against suggestion, and notes that it gives no round limit and no license to merge a known
blocker.

**S27. Google engineering practices, how to write code review comments.** Google.
<https://google.github.io/eng-practices/review/reviewer/comments.html>. Explain the reasoning
behind a comment. v0 uses it for findings that carry their mechanism and impact, not only a
severity.

**S28. Google engineering practices, what to look for in a code review.** Google.
<https://google.github.io/eng-practices/review/reviewer/looking-for.html>. Design, edge cases,
concurrency and the tests themselves, where static reading can reveal defects. v0 uses it to count a
precise code path as evidence and for the review round cap.

**S29. Google engineering practices, small CLs.** Google.
<https://google.github.io/eng-practices/review/developer/small-cls.html>. Small changes are easier
to review and waste less when the direction is rejected. v0 uses it for an early, bounded plan
review.

**S30. Handoffs.** AHRQ Patient Safety Network, US Agency for Healthcare Research and Quality.
<https://psnet.ahrq.gov/primer/handoffs>. The I-PASS handoff has severity, a summary, an action
list, contingencies and a synthesis by the receiver. v0 uses it as clinical prior art for the
readback in a handover, not as an effect size for agents.

**S31. SBAR, TeamSTEPPS.** US Agency for Healthcare Research and Quality.
<https://www.ahrq.gov/teamstepps-program/curriculum/communication/tools/sbar.html>. Situation,
background, assessment and recommendation in a short message. v0 uses it for the shape of an
escalation to the human.

**S32. ICS Training Reference Guide.** FEMA, March 2023.
<https://training.fema.gov/emiweb/is/icsresource/assets/ics_training_reference_guide.pdf>. A
transfer of command has a joint briefing, a set transfer time, notice to others and a release of
the outgoing commander. v0 uses it for a handover that ends at an acknowledged cutover, and for
announcing a disruptive action.

**S33. Mission command requires sharp commander's intent.** US Army, 2019-11-04.
<https://www.army.mil/article/215297/mission_command_requires_sharp_commanders_intent>. Delegated
initiative within stated parameters and a shared end state, with checks that intent is understood.
v0 uses it for deciding inside a confirmed plan and for gates that stand in for the principal's
review.

**S34. Codex agent approvals and security.** OpenAI, living documentation.
<https://learn.chatgpt.com/docs/agent-approvals-security>. The sandbox restricts capability and the
approval policy controls interruptions. v0 uses it to keep declared authority apart from technical
capability and to record the policy a harness actually runs.

**S36. MCP Agent Mail.** The `mcp_agent_mail` project by GitHub user Dicklesworthstone.
<https://github.com/Dicklesworthstone/mcp_agent_mail>. Identities across harnesses, inboxes, threads
and advisory file reservations. v0 uses it as a close public analogue for identities that outlive
sessions and for signaling who writes where.

**S37. OpenRig.** The OpenRig project by GitHub user mvschwarz.
<https://github.com/mvschwarz/openrig>. Persistent teams across harnesses, where a message is not a
queue item and setup checks trust and permission prompts before work. v0 uses it for identities that
outlive sessions, for readiness checked before work, and for leaving before close.

**S38. Refute-or-Promote.** arXiv preprint 2604.19049, 2026-04-21.
<https://arxiv.org/html/2604.19049v1>. Adversarial refutation, informed and cold-start reviewers and
validation gates, with one operator and no ablations by its own account. v0 uses it as practitioner
prior art for a blind lens and gated review, not as causal proof.

**S39. AgentReview.** Jin and others, EMNLP 2024.
<https://aclanthology.org/2024.emnlp-main.70.pdf>. A simulation of peer review that offers
anchoring as one explanation for small changes after rebuttals. v0 uses it as an indirect caution
about inherited judgments.

**S40. FIPA Communicative Act Library, experimental XC00037H.** Foundation for Intelligent Physical
Agents, 2001-08-10. <https://jmvidal.cse.sc.edu/library/XC00037H.pdf>. Inform, request, refuse and
failure are distinct acts. v0 uses it for the split between a request and a message and for keeping
reading, accepting and completing apart.

**S41. The Contract Net Protocol.** Reid G. Smith, IEEE, December 1980.
<https://www.reidgsmith.com/The_Contract_Net_Protocol_Dec-1980.pdf>. Announcements, bids, awards and
reasons for silence such as busy or ineligible. v0 uses it for explicit accept and refuse and for
acknowledging a cancel.

**S42. A2A, Life of a Task.** The A2A project, Linux Foundation.
<https://a2a-protocol.org/latest/topics/life-of-a-task/>. Terminal tasks do not restart, related
work is a new task linked by reference, and input required is an interruption, not an outcome. v0
uses it for terminal outcomes, follow-up work as a new request, and requests correlated by their
full address.

**S43. A2A, Enterprise Features.** The A2A project, Linux Foundation.
<https://a2a-protocol.org/latest/topics/enterprise-ready/>. Authentication, authorization with
least privilege and tracing are separate concerns. v0 uses it to keep identity, authority and the
approval of one act apart, and for a resolved name that grants nothing.

**S45. A2A, Multi-Tenancy.** The A2A project, Linux Foundation.
<https://a2a-protocol.org/latest/topics/multi-tenancy/>. A tenant is an opaque routing field, and a
host can serve many agents. v0 uses it for the host being a route, not an identity.

**S46. OpenRig, naming rigs, pods and seats.** The OpenRig project.
<https://github.com/mvschwarz/openrig/blob/main/docs/reference/topology-naming.md>. The logical id
is pod and member, the session address names the rig, and host routes and runtime are separate. v0
uses it for the team being part of the identity and the host being configuration.

**S47. OpenRig, RigSpec reference.** The OpenRig project.
<https://raw.githubusercontent.com/mvschwarz/openrig/main/docs/reference/rig-spec.md>. Pod ids are
unique within a rig and member ids within a pod, and edges express delegation separately from
names. v0 uses it to keep the address grammar apart from the authority graph.

**S48. AutoGen Core, agent identity and lifecycle.** Microsoft.
<https://microsoft.github.io/autogen/stable/user-guide/core-user-guide/core-concepts/agent-identity-and-lifecycle.html>.
An agent is addressed by type and key, with a new key for each instance. v0 uses it to separate the
role from the instance, and the identity from its incarnation.

### Naming references

These are the references that part 5 of the research added on naming and identity, read on
2026-10-23 (UTC).

**S-N01. Kubernetes, Namespaces.** The Kubernetes project, living documentation.
<https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/>. Names are unique
within a namespace, not across the cluster. v0 uses it to make the team an explicit scope, so the
same member name can exist in two teams.

**S-N02. Kubernetes, DNS for Services and Pods.** The Kubernetes project, living documentation.
<https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/>. A short name resolves
inside the client's own namespace, and another namespace needs the qualified name. v0 uses it for
short names resolved only in the sender's team, without trying other scopes.

**S-N03. RFC 7622, XMPP address format.** IETF, September 2015.
<https://www.rfc-editor.org/rfc/rfc7622.txt>. A bare address differs from one with a resource part
that names a connection. v0 uses it for an identity and its session as two parts of one address.

**S-N04. RFC 6120, XMPP core.** IETF, March 2011. <https://www.rfc-editor.org/rfc/rfc6120.txt>.
Resource binding lets simultaneous connections of one entity stay separately addressable. v0 uses it
for a predecessor and a successor reachable at once during a handover.

## Editorial recommendations

**E01. Match review style to the setting.** The mined notes ask for a few points with clear value in
a suggesting tone when reviewing a peer's document, while L03 records the value of a full list of
must-fix code findings with tests. The playbook distinguishes those settings and proposes an
adversarial pass for the team's own normative documents, checking evidence, generality and
contradictions. This is a reconciliation of the notes' open question, not a comparison tested across
the three settings. Confidence low; S26 and S27 give public prior art for ranking comments and
explaining their reasons.

## Incidents of the nomos run (LOG)

The initial nomos writing run began on 2026-10-22, on a shared machine. Later entries follow the
work into 2026-10-23. Times are UTC-3 unless an entry gives another zone or date. Each entry says
what happened and what it is evidence for. The sessions are named by role.

**21:40.** The orchestrator of the keryx round compacted and started this run as the orchestrator
of nomos, with a loop in its own session watching its mailbox. It never held its own address for
approval and read only its own mail, with one slip at 23:24. Evidence for the waiting loop in the
playbook's "Keeping the orchestrator light" and for M16.

**21:50 and 21:55.** A miner spawned in Cursor stopped at "Workspace Trust Required", answered with
`a`, and a researcher spawned in Codex stopped at the hooks dialog, answered "Continue without
trusting". Each later Codex spawn met the same dialog and got the same answer. Evidence for
answering startup dialogs by reading the screen (H01, HN20, HN26).

**22:00.** Cursor's model list named the miner's model as 1M, while the session's status line read
300K at 23% before its first source. Evidence for reading the window from the status line, never
from the list (HN23, the playbook's "Context policy").

**22:12.** The Cursor miner asked the orchestrator for its context figure, since the CLI does not
show the session its own indicator. The orchestrator read 81.2% of a 300K window from the pane and
told it to stop and hand over. The Codex researcher had no exact meter either and reported an
estimate of its own. Evidence that sessions on these harnesses cannot see their figure, that the
director measures it, and that a report gives the figure as shown or unknown (HN24, the protocol's
"Reports and evidence" and "The session life cycle and handover", R09).

**22:14.** The miner's handover reply arrived. Cursor had queued the orchestrator's earlier reply
behind the miner's running turn, neither Enter nor selecting the queued item steered it in, and it
arrived about 80 seconds later at the end of the turn. Evidence for HN25 and for sending stops
early.

**22:14.** The keryx team's orchestrator set an interim rule for Codex sessions until a transport
fix merged, to run `keryx leave` before closing and to send nothing to a closed Codex session's
address. Evidence for HN17 and the playbook's rules on closing sessions (H03, L06).

**22:16 and 22:17.** A successor miner started on a model with a 1M context override, its status
line showing 1M and 5.1% at start, with a ceiling of about 250K tokens watched by the orchestrator.
Before working it sent a readback of its role, order of sources, authority and ceiling. Evidence
for HN23 and for the readback after a handover (M34).

**22:33.** The protocol writer, in Claude Code, handed over at about 290K tokens by its own count.
Evidence that the Claude Code sessions of the run reported their own figure (HN16).

**22:45.** A Codex reviewer could not see its context either. The orchestrator read 67K of a 258K
window from the last token count event in its rollout file, and lowered its ceiling to about half
the window, since a quarter of the window had been set with 1M windows in mind. Evidence for HN21
and for ceilings per window.

**22:50.** A writer found that an output-compressing shell hook hid files from directory listings,
and recorded it in its handover; the session that compiled this file saw a listing mark entries as
hidden shortly after 23:30. Evidence for HN31 and for never concluding absence from a filtered
output (M01).

**22:50 and 23:00.** Two Codex reviewers at maximum effort reached nearly half of their window with
almost nothing written, one with its first pass unwritten and one with a few lines. Each was told
to write what it had and leave the rest to a fresh reviewer. Evidence for watching the output file
as well as the figure, and for splitting a review by lens across sessions (the playbook's "Context
policy" and "Team recipes").

**22:51.** A reviewer contradicted a harness note by running it. The published `jq` filter selected
`.type == "token_count"` and returned nothing with exit 0, while the rollout has `.type ==
"event_msg"` with `.payload.type == "token_count"`. The error came from the orchestrator's own
message to the writer, which described a search match as a field's value. Its search was right and
its description was not. Evidence for checking an empty result like a finding and for relaying
evidence as it was (M46, M54, the protocol's "Reports and evidence").

**22:53 to 23:01.** The transport was upgraded on the shared machine at 22:53 while sessions ran. A
Codex reviewer that had joined at 22:46 under the old build had its bell refused at 23:00, since
the new build needs the process recorded at join. The message was delivered by hand, and the
reviewer's next transport command fixed the record. The refusal fails closed by design. Evidence
for announcing an upgrade of a shared tool and checking bells after it (L13, the protocol's "The
session life cycle and handover").

**22:59 to 23:05.** A stop message typed and queued into a busy Codex reviewer's pane at 22:59
reached the session only after 23:05, at its next inbox check. Evidence for HN34 and for sending a
stop well before the ceiling.

**23:04.** The second reviewer of the protocol found, among other things, that the orchestrator's
sanitizing shape for M14 had given it M15's shape and erased its mechanism, the literal token. The
orchestrator accepted the correction. Evidence that corrections run in both directions and are
measured by their receiver (M15).

**23:15.** The principal asked what keryx could do for context management. R09 and R10 were
written, and the keryx team agreed to the design, to follow its batch of small fixes. Evidence that
those two are proposals at that time; R09 and R10 below record their later implementation (the
playbook's "Context policy").

**23:16.** A Claude Code writer reached about 187K tokens before its first edit, spent on
instructions, memory and inputs, and its ceiling was raised for that round, since a successor would
pay the same start-up cost. Evidence that a renewal criterion accounts for the fixed start-up cost
of a session.

**23:17.** A writer pointed out that the orchestrator's own first prompts lacked the redelegation
and revocation fields. From then on they carried all eight fields of the delegation record.
Evidence for the protocol's delegation record.

**23:24.** A bell to a busy Cursor writer was deferred as a dialog because of Cursor's follow-ups
box. While sending, the orchestrator killed its own shell with `pkill -f` on a pattern that matched
its own command line, and then checked delivery by listing another address's mail directory, which
its own handover note forbade. `keryx status` shows outgoing mail without reading anyone else's.
Evidence for the playbook's rule never to read another address's mail.

**23:25.** The keryx team relayed the principal's correction that keryx cannot know a Claude Code
session's window, since the model id does not tell a 200K window from a 1M one and the window
reaches only a status line the user configures. Ceilings are set in tokens by the spawner, and
percentages are used only where the harness reports the window. Evidence for HN16.

**23:31.** A bell to a busy Cursor session arrived about 13 minutes late, when its long turn ended,
and the session had read the message through `keryx inbox` in the meantime. Evidence for notices at
more than one threshold and for HN25.

**2026-10-23 02:28 UTC-3.** The principal corrected the director after it waited two and a half
hours for a stalled session, relying on events the session would not emit. The session used a
shared usage pool. The corrected routine never waits without a deadline, gives each request a
`--within` suited to the task and wakes about every fifteen minutes while sessions work, even
without events, to inspect output or transcript growth, pane errors and request deadlines. The
director knows each session's pool and that it can run out. This does not prohibit sharing a pool.
Evidence for the playbook's "The director's heartbeat"; one incident, low confidence, with fifteen
minutes a chosen default.

**2026-10-23 02:52 and 04:05 UTC-3.** At 02:52 the principal asked whether the documents would grow
so large that loading them no longer paid. The package was reported at about 42,300 words,
estimated at 55K to 60K tokens, beside about 800 tokens for keryx's skill. These are a package
measurement and estimates, not observed context consumption by a member. At 04:05 the principal
chose role cards before the acceptance test. Members start with a common card and their role card;
templates, harness notes and evidence are read only for the work that needs them. The bootstrap
reading map gives current word counts and estimated tokens. Evidence for that map and the cards;
one decision, with no measured acceptance result or savings yet.

**2026-10-23 04:14 UTC-3.** The keryx team reported its first observation of a conflict with the
protocol's terminal-reply rule. The stop hook keeps a turn going once per message when a request
has been read but not answered, while its reminder asks for a reply before ending the turn. That
wording pushes a member to close a request whose work is still open. The code at fde5548 states the
once-per-message behavior in `lib/keryx/commands/hook.rb`, lines 18 to 20, and the reply
instruction in `lib/keryx/stop_hook.rb`, lines 100 to 103; pending-message marks are filtered in
that file's `pending` method. This is code-grounded, not a hook execution in this writing round.
Under protocol 5.3 and 9.3, a member that has sent [accept] ends its turn after the one reminder
without replying; it settles the request before leaving the session. Evidence for the mapping in
`keryx.md` and the member card; one field report, low confidence in the workaround until exercised.

**2026-10-23 04:15 UTC-3.** The requester added an item to an open writing request using
[progress], a kind assigned to the worker in 5.2. The vocabulary had no requester amendment. The
ruling adds amend as a message from the requester naming the request id, change and absolute time;
the worker acknowledges it in its next progress or result, or asks [clarify] when it cannot take
it. Authority still comes from the record. Evidence for protocol 5.2, the transport mapping and the
member card; low, designed from one observed gap, with no field test of amend yet.

**2026-10-23 04:25 UTC-3.** The director found estimated absolute times six to twenty minutes ahead
in three messages and the log. An acceptance at 04:17 said 04:30, the ceiling ruling at 04:22 said
04:40, and another acceptance at 04:24 said 04:45. It corrected the log from message timestamps and
the clock and sent a correction. An absolute time must be read from the clock or the message, never
estimated. The field audits report the same mistake by another director. Evidence for protocol 5.7;
low for the remedy, with no check yet of whether the new sentence prevents recurrence.

**2026-10-23 04:37 UTC-3.** The acceptance-test leader met the stop hook on an open request, sent
[accept] and kept it open under 5.3. Its orchestrator card lacked the member card's sentence about
ending the turn after the one reminder. The same workaround now appears in both cards, digesting
5.3 and 9.3 and the code-grounded transport mapping recorded at 04:14. One field report, low
confidence; this report does not establish what the hook does across later turns.

**2026-10-23 04:49 UTC-3.** The acceptance-test leader left Codex's folder trust dialog unanswered
because its record reserved configuration and edits outside the test workspace. The answer goes
into `~/.codex/config.toml`. It also reported under 4.9 that it had answered Claude Code's folder
trust dialog before noticing the same boundary. Earlier harness probes recorded Claude Code's
answer in `~/.claude.json` and Cursor's in `~/.cursor/projects/<project>/.workspace-trusted`. The
trust answer writes harness state outside the workspace, even when the trusted folder is inside it.
A record names whether the delegate may answer trust and approval dialogs, for which directories,
and covers the configuration effect. Evidence for the playbook's delegation guidance, the
first-prompt template and HN02, HN20 and HN26; low for the rule, one acceptance-test report; paths
are from the recorded probes, not new probes in this writing round.

**The run as a whole.** The run used a miner, a researcher, a protocol writer, a playbook writer,
adversarial reviewers split by lens, fixing writers and a verifier, each spawned with a brief and a
ceiling, and a second miner took over from a handover note at the first one's ceiling. Evidence,
seen once, for the playbook's recipe for writing documents.

**2026-10-23, acceptance 1, stumble 4.** The leader reported that the reading estimate omitted the
harness's own initial context. The acceptance report records 50.9K at the first Claude Code
assistant turn, 61.8K after join, skill and inbox, and about 23K stamped on Codex readbacks in two
writing sessions. These are observations on this machine, not portable budgets or measurements at
the same stage. The director clarified at 05:19 UTC-3 that the start to record is the context
stamped on the first readback, already after join, skill and inbox. The playbook counts the initial
load inside the ceiling and bootstrap requires that recorded figure. Confidence low, one acceptance
test and two writing-session starts.

**2026-10-23, acceptance 1, stumble 6.** The leader read bootstrap, playbook and harness notes in
full, plus its card and protocol, spending about 48K on nomos against the map's roughly 15K
estimate. The map omitted the harness notes bootstrap 7 requires. Bootstrap and the orchestrator
card now name every initial section and give commands to print one section or note. Counts describe
the text to read, not measured context or a demonstrated reduction. Confidence low, one acceptance
test.

**2026-10-23, acceptance 1, stumble 13.** The leader received the 81% notice on its 250K ceiling
while review was running and asked whether it could finish past the ceiling. No answer arrived
during the run. It reduced reading, reached a stable result at about 227K and stopped without
crossing the ceiling. The documents had not explained self-renewal or an explicit bounded
exception. Protocol 9.5 and the playbook now give the existing keryx handover sequence for the
orchestrator and require a yes naming the remaining work and a hard cap before crossing. The keryx
mapping spells out the same-address transfer and explicit mailbox checks because messages to
oneself do not ring. Its --as behavior and no-self-bell condition were checked in the local
Identity, Spawn and Postman code; no session was spawned. Confidence low, one acceptance test;
self-renewal was not exercised.

**2026-10-23, acceptance 1, stumble 10.** The first implementer's pane and process vanished
mid-edit without a leave or handover note. The acceptance report identifies an injected failure;
the leader's own report did not know its cause. The director checked the lost session, recovered
state from the worktree and mailbox, wrote the handover note, and passed the leftover edit to a
successor as an unverified draft. Protocol 9.4 now assigns the missing note to the director, using
checkpoint, mailbox and worktree, after checking that no process of the lost session can still act.
Confidence low, one recovery.

**2026-10-23, acceptance 1, N2.** The principal's channel for the acceptance leader was its pane,
read by a relay. The leader wrote its ceiling question there, but the relay received no bell and
missed the question for the rest of the run. Protocol 10.2, the root first-prompt form and the
keryx mapping now let the record name that relay and require a transport message for each
escalation as well as the declared channel. Confidence low, one missed escalation; the added
delivery rule has not been tested in another run.

**2026-10-23, acceptance 1, N1.** The leader asked the principal to choose the team's shape even
though the brief had already given that choice to it. Protocol 4.8 already requires granted
decisions to be made and reported. The playbook's orchestrator routine and its card now spell out
this case, with a recorded decision and reason instead of another escalation. Confidence low for
the incident, one acceptance test; protocol 4.8 keeps its earlier confidence.

**2026-10-23, acceptance 1, stumble 3.** The root record did not choose the members' permission
modes, and the leader had no documented way for a sandboxed Codex seat to write the keryx store
outside its worktree. It asked the principal. The playbook and bootstrap now require the record to
name the modes per harness and the Codex writable store, with a reply check from the seat. Local
help was checked on 2026-10-23 for Claude Code 2.1.309, codex-cli 0.163.0 and cursor-agent
2026.10.22-27dcf5f; HN12, HN20 and HN26 give their launch controls. Confidence low, one acceptance
test; help checks establish syntax, not a newly tested permission policy.

**2026-10-23, acceptance 1, stumble 1.** The bootstrap and commit gate assumed origin/main, but the
acceptance repository had no remote. The leader used local main for the worktrees and commit range.
Bootstrap sections 6 and 7 and the merge rules now name the base explicitly, origin/main with that
remote or main without one, adapting actual names to the repository. Confidence low, one local
acceptance test.

**2026-10-23, acceptance 1, stumble 11.** The acceptance repository had no CI. The leader ran
`cargo fmt --check`, `cargo test` and `cargo clippy --all-targets -- -D warnings` on the candidate
head in a scratch worktree, then again on main after merging. The acceptance report records five
passing tests and clean clippy. Bootstrap and merge gate 2 now accept the orchestrator's recorded
gate commands on the head in a clean worktree when CI does not exist. Confidence low, one local
acceptance test; these are the leader's reported checks, not a rerun by the document writer.

**2026-10-23, acceptance 1, stumble 2.** The recipe offered the reviewer as plan reviewer without
separating it from the blind code lens, and gave no rule for skipping a plan review on a small
change. The leader used a separate plan reviewer and a fresh blind reviewer; the test passed.
Building a feature and Plan review before code now keep those sessions separate. A proposed skip
criterion permits a recorded decision only for small mechanical changes without new design,
interface or failure-path decisions, within the record and brief. Code review and merge gates
remain required. Confidence low for this clarification and the untested skip criterion, one
acceptance test; protocol 8.4 and 8.5 keep their earlier confidence.

**2026-10-23, acceptance 1, stumble 12.** The merge rules told the leader to remove merged branches
and worktrees, while its record did not grant deletion and the local rules reserved it. It left the
resources in place and proposed cleanup to the principal. The playbook's record guidance and merge
rules now require an explicit cleanup grant for the team's merged resources; otherwise removal
stays with the principal. Bootstrap's removal example carries the same condition. Confidence low,
one acceptance test.

**2026-10-23, acceptance 1, N3.** The acceptance report noted that members' commits carried a git
identity different from the one intended for the task. Bootstrap now checks the effective author
and committer identities in the repository and writing worktrees before commits, and sends any
needed configuration change to whoever the record authorizes. Confidence low, one acceptance test;
no identity was changed by this writing task.

**2026-10-23, acceptance 1, stumble 5.** At 07:34 UTC the acceptance-test leader ran herdr status
and reported client and server 0.9.5 with server_binary_stale set to no. The published notes still
described the earlier server 0.9.3 as current. The preamble and HN01 now distinguish those
observations, and HN02 to HN05 keep the earlier likely server 0.9.3 attached to their behavior.
Confidence low, one reported status check; those behaviors were not rechecked on 0.9.5 in this
writing task or the acceptance run.

**2026-10-23, acceptance 2, map command.** In the second acceptance run, at 05:36 to 05:41 UTC-3,
the leader read all of bootstrap because the map had no command to print itself. Stumble 6 reports
31,850 bytes loaded; later playbook sections and harness notes were printed separately as intended.
Bootstrap now opens with a command that prints only the map; the orchestrator card carries it and
the root first prompt gives it before required reading. Confidence low, one reading run; the
revised entry command has no new acceptance run.

**2026-10-23, acceptance 2, reading measures.** The second reading run reported 51.0K context at
the first assistant turn, 60.8K after join, skill, inbox and the request, 76.7K after bootstrap in
full and the card, 90.0K after protocol, 103.5K after the named playbook sections, and 107.2K after
the ten harness notes. The readback was at 132.1K. Reading nomos cost about 46K, versus about 48K
in the first run. Protocol read with line numbers cost about 2.5 tokens per word; playbook sections
printed by command cost about 2.1, including tool calls. The map now uses those observed ratios for
planning; they do not measure the revised map command's savings or promise the same cost in another
harness. Required orchestrator text was about 16,000 words. Stumble 6 attributes the excess only as
a total; allocations to whole-file reading, line numbers, checks and reasoning remain hypotheses.
Confidence low, one reading run, as recorded in the acceptance report and the 05:42 UTC-3 log
entry.

**2026-10-23, acceptance 2, message times.** The leader wrote a send time of 05:43 UTC-3 for a
message sent at 05:39 UTC-3, despite protocol 5.7's instruction to read times from the clock. The
acceptance report records the error. Protocol 5.7 now says the transport supplies a message's send
time; a body needs absolute times only for other events, taken from the clock or a message.
Confidence low, one repeated failure; the changed wording has not been tested in another run.

**2026-10-23 about 08:05 UTC-3, orchestrator digest.** After two acceptance runs measured about 48K
and 46K tokens reading nomos before action, the principal chose an orchestrator digest in place of
reading the whole protocol and most of the playbook at startup. The writing brief places the choice
at about 08:05 UTC-3; the run log records the acceptance of option B in its 08:12 entry. The time
of the choice is approximate, not a separately verified timestamp. The required texts had been
about 16,000 words, and the second run measured about 2.1 to 2.5 tokens per word, depending on how
sections were printed, including tool calls.

The chosen route uses a digest of at most 2,500 words whose paragraphs name their source sections
and commands for reading them. It adds no rule or authority. The orchestrator starts with that
digest, its card, bootstrap sections 7 and 8 and only the selected harness notes; protocol and
playbook sections are read on demand. The writing target was about 6,000 words for the enumerated
texts, with the map and other startup material counted separately. The reading map cites this
choice and shows text estimates, not measured savings from the new route. Confidence low, one
principal decision after two measured runs; no acceptance run of the digest route had measured its
savings when the choice was written into v0.

**2026-10-23 about 08:12 UTC-3, 1M ceiling.** The keryx team's orchestrator reported nine swaps from
04:59 to 07:49 UTC-3 that night, each entering at about 70K and leaving at the 250K cap after about
fifteen to twenty minutes. The report attributes most of the join load to the harness; each swap
paid for another join, handover note, spawn and readback, costing about two minutes of the team's
attention. The run log's 11:03 UTC entry and the request sent at 11:12 UTC are the sources; these
are reported measurements, not a rerun by the writer. The principal asked for a ruling on the cost.

The protocol director ruled at about 08:12 UTC-3 that a 1M ceiling starts from the context keryx
stamps on the first readback, the join figure. State-in-files roles get that figure plus 250K; the
orchestrator and a read-heavy role with current progress and coverage files get it plus 350K, never
above half the window, 500K. An orchestrator uses a window where half leaves at least three times
its join figure; about 70K joins mean 1M here, never 200K. Windows of 258K and below keep their
figures. The earlier field-audit rule remains the trace for those figures and the progress-file
condition. The report of sessions past 340K without loss, including readings of 375K and 386K,
is limited evidence. The changed budget has no controlled comparison yet.

Lower the rule if errors past about 350K trace to long context, such as missed or misread messages,
wrong ids or repeated work, or if Claude quota per hour of work is clearly higher than with
frequent swaps. The ruling asks for swaps per hour, each orchestrator's join figure and the account
usage meter's Claude figure at each swap. Evidence for playbook, The ceiling, and its bootstrap and
card digests. Confidence low, one reported night and a reasoned change, retaining P05, M19, M34 and
the field audits as the earlier trace.

**2026-10-23 04:59 UTC-3, swap name collision.** The run log reports that the keryx team's
orchestrator swapped at about 04:58 and that spawn refused until the outgoing pane's herdr agent
name was renamed. A free transport address did not establish that the pane name was free. This
supports checking both `keryx who` and `herdr agent list` after a refused spawn, not assuming a new
session exists or creating another transport address. Confidence low, one reported refusal; the
writer did not reproduce it or establish whether the installed spawn still has that defect.

**2026-10-23 about 08:45 UTC-3, orchestrator swap.** The principal asked for orchestrators to
perform their own swaps, check that the successor is well and clean what the run leaves behind. The
run log records the principal's words at 08:44; the writing brief places them at about 08:45 UTC-3.
That brief reports that the protocol orchestrator had asked the principal how to swap at about
08:15 and 08:27. Those questions are the delegator's report, not separately recorded questions in
the log entries read by the writer. The earlier nine swaps in under three hours are recorded in
LOG, 2026-10-23 about 08:12, 1M ceiling.

The resulting model starts at the 80% notice or a nearby planned boundary, preserves the root record
word for word, and requires a checked readback, address holder, expected context, a ringing ping,
matching session and request inventories, and an armed heartbeat before timed acceptance. A mismatch
gets a clarification, a persistently failed successor is replaced, and two failed successors go to
the principal. Successful renewal needs only an after-the-fact location message; a record change
still needs the principal. Watchers, obligations and cleanup have named holders across cutover.

At 08:45 the log records the first attempt at this model. At 08:47 it records the predecessor
checking the note, address, ceiling and heartbeat plan and confirming without asking the principal.
Its entry reports an 86K stamped readback and about 90K in who; the successor's entry reports 73K
in who at its readback. These are different reported readings, not a reconciled context measure.
The successor reports arming its heartbeat and closing the old pane after reading that the
predecessor stopped acting. The successor's follow-up report confirms that neither the ringing ping
nor the comparison with an expected context range ran. It dates the acceptance message at 11:47:20
UTC and reports notifying the team's peer and the principal afterward. The recorded sequence does
not establish a process-exit check before pane closure. This is evidence of one transfer, not
validation of every new health and cleanup check.

On 2026-10-23 the writer checked local keryx 0.1.0 help and code. Postman's post method suppresses
the bell when sender and recipient names match; the Ring command reads unread mail and calls the
bell directly, without that condition. The mapping therefore uses a distinct ping request, explicit
`keryx ring`, the successor's bell observation and matching reply. This path is code-grounded, not
exercised in this writing task. Confidence low for the model and its new checks, with one recorded
swap and no controlled test of the full procedure. This extends acceptance 1, stumble 13, and
supports protocol 9.4 and 9.5, the playbook routine and their card, digest and handover form.

**2026-10-23 05:13 and about 08:45 UTC-3, cleanup.** In acceptance 1, stumble 12, the leader could
not remove merged resources because its record did not grant deletion. The run log at 05:13 records
its director removing four worktrees and the merged branch after checking that the saved probe copy
matched. The later orchestrator handover still lists two test directories and a Codex trust entry
awaiting the principal's decision, inactive team and test addresses pending R07, and a board pane
running watch that the successor must close at run end. These are reported leftovers with different
holders and permissions, not evidence that everything should be deleted at once. The writer made no
removals.

The principal's request, logged at 08:44 and placed at about 08:45 by the writing brief, asks for
cleanup that leaves nothing forgotten across orchestrator swaps. The playbook now keeps a resource
inventory through swaps, task ends and run end, including members' panes, addresses, merged
worktrees and branches, scratch and temporary files, loops, heartbeats, watchers, the board,
run-added trust entries and test directories. It supplies checks for each and requires a closing
inventory of cleaned and retained resources, with reason and owner. Removal still follows the
record; a merge or workspace grant does not grant deletion or settings changes. R07 remains
unavailable in the local keryx help read on 2026-10-23, so inactive addresses stay listed rather
than having their mailboxes erased. Confidence low, one acceptance run, a later handover and a
reasoned checklist. The writer checked command help for pane and address inspection but did not run
a cleanup exercise. Bootstrap section 10 and the orchestrator card and digest summarize this
practice.

### LOG, acceptance 3, 2026-10-23 09:20 to 09:27 UTC-3

The run log at 09:20 and 09:27 and the third-run acceptance report describe a reading-only test of
v0 after round 9, with a fresh Claude Code leader at xhigh reasoning effort, a copy of the package
without working files, a fixed local crate revision with no remote, and the second run's task and
root record with new test addresses. The leader read the record, map, card, orchestrator digest,
bootstrap 7 and 8, five playbook sections, named harness notes and two templates. It gave its
readback at about 09:24 and sent [accept]; the director withdrew the request at 09:25. The leader
acknowledged with no repository effect and left. The log reports that the process exited before the
pane closed. These are sourced observations, not actions rerun by this document writer. Confidence
low, one test.

**Prompt limit.** The log reports keryx 0.1.0 refusing a 2,840-byte root record as `--prompt`, with
a 2,048-byte limit, though the same text had passed at 05:36. The director put the record in a file
with mode 444 and sent a 348-byte first prompt naming it. The root form and bootstrap 6 now require
a byte-count check before spawn; a record over the limit goes to a file the session may read but
may not edit, named by a short prompt that says the record binds as if written there. The keryx
mapping records this limit and file convention. The earlier pass does not establish a different
version or explain when enforcement changed. Confidence low for the workaround.

**Commit identity.** Both the second reading-only run, logged at 05:42, and this run escalated
before any commit under bootstrap 8 step 11. Their records granted commits but named no identity;
the effective commit identity differed from the intended identity. Escalation was correct under
those records. The root form and bootstrap 6 now name the team's author and committer identity and
its application through repository-local configuration or per-commit flags; step 11 checks against
that record. This repairs the record's omission without granting settings changes to members.
Confidence low, two reading-only runs, no commit exercise in either.

**Map command.** The short prompt said "the reading map at the top of bootstrap.md" instead of
giving the map's command. The leader's first nomos read was `cat bootstrap.md` in full, and its
output was cut. The director clarified at 12:34:05 UTC on 2026-10-23 that it reused the second
run's round-5 record for comparability, omitting the command that the root form has carried since
round 6. That omission belonged to the test setup. The form now explicitly keeps the command in the
first prompt even when the record is in a file. The member form names the two cards directly.
Confidence low, one repeated whole-file read; the revised short prompt awaits a fresh run.

**Reading measures.** The transcript measure sums input, cache read and cache creation for each
assistant turn, so it also includes the model's earlier output. Context was 50.2K on the first
turn, 60.9K after join and skill, 103.2K before writing the readback and about 110K when sending
it. About 11K between 60.9K and 103.2K covered the task, repository, transport help and machine
checks. Reading nomos took about 27K to 31K, the upper figure including two templates, against 46K
in the second run and 48K in the first. Round 9 enumerated 6,565 words plus the map's 1,023, or
7,588. Dividing gives 3.56 to 4.09 tokens per enumerated word; the map now uses 3.6 to 4.1 for
planning and keeps the earlier 2.1 to 2.5 observation. The denominator excludes extra sections and
templates, and the numerator includes interleaved output, so this is no text-only ratio or per-row
measurement. The saved round-9 table shows 13,790 to 16,420, consistent with 2.1 to 2.5 times 6,565
rounded up to tens. At 12:34:05 UTC on 2026-10-23 the director clarified that it had copied round
8's 13.4K to 15.9K estimate into the acceptance narrative, then corrected the narrative to 13.8K to
16.4K from that saved table. The writer read that correction. The measured 27K to 31K is unchanged.
Confidence low, one uncontrolled reading run.

**Message times.** The leader wrote "since about 09:27 -03" in a message sent at 09:24:32 UTC-3,
despite protocol 5.7 in its digest. The second leader had written 05:43 for 05:39, the protocol
director had estimated future times at 04:25, and field PR 26 records the keryx team's same error.
A text rule alone has not held. Protocol 11.2 now proposes a pre-send comparison of each absolute
body time with send time, flagging one ahead for confirmation. Future events can be legitimate;
the check does not infer an error from order alone. Confidence low, repeated failure of the text
rule and an untested hook proposal, not an implemented transport feature.

**Cleanup.** The log at 09:22 reports archiving the first two tests' run records with clean `diff
-r` and `cmp` checks, bundling the first test's main branch and checking its clone, checking panes
and address holders, then removing both test directories. It reports removing that run's Codex
trust entry, saving a configuration copy, a no-match query and a successful TOML parse. Inactive
test addresses remain pending R07; Claude transcripts remain as primary measurement evidence; three
project entries remain because they are inert without their paths and live sessions rewrite the
shared file. At 09:27 the third run's records were archived with a clean `diff -r` before its test
directory was removed. This extends the earlier cleanup inventory with dispositions and retention
reasons for all three tests. Confidence low, sourced cleanup reported by the director; this writer
made no removals and did not independently repeat those checks.

### LOG, 2026-10-23 08:40 UTC-3, named decision relay

A session outside the team talked with the principal about the roadmap, recorded the principal's
decisions and sent plan changes to the orchestrator. The ruling treats each change as a third
party's relay under 4.6 unless the orchestrator's delegation record names that session as carrying
the principal's decisions and the change cites a dated entry of its decisions file. Otherwise the
orchestrator confirms each change with the principal. Naming a relay to carry messages grants no
decision authority. This preserves the source of a decision while allowing its named carrier to
convey it. Sourced from the run log of 2026-10-23 at 08:40 UTC-3; one case and a ruling, with no
later exercise of the amended record reported. Confidence low.

### LOG, 2026-10-23 08:44 and 09:01 UTC-3, spawn dialog authority

At 08:44 UTC-3 the run log recorded keryx's new spawn notice, "Take it to your human, and answer it
with herdr pane send-keys only on their word". The director answered the Codex hooks prompt
"Continue without trusting", the answer used earlier in the run. At 09:01 UTC-3 the ruling
reconciled that notice with bootstrap 7 step 5: a delegation record's grant of a named dialog
answer carries the principal's word; without it the director escalates. Such a grant must cover the
answer and its configuration effects and does not grant answers to other dialogs. This is a sourced
log observation and ruling, not a new permission or a test of every harness. Confidence low.

### LOG, 2026-10-23 09:00 UTC-3, Codex close

After the previous writer left its address, the director sent `/quit`, paused one second before
Enter and checked that the Codex process was gone before closing its pane at 09:00 UTC-3. The round
9 brief identifies codex-cli 0.163.0 and herdr 0.9.5 for HN35. Field PR 25 reports an immediate
Enter ignored at 10:19 UTC and delayed Enter working at 10:21 UTC. These are sourced observations,
not this writer's live test; confidence low for the pause remedy across sessions.

### LOG, 2026-10-23 04:56 UTC-3, 09:04 and 09:45 UTC-3, brief compression

At 04:56 UTC-3 a writer's [clarify] caught a brief stricter than
its ruling on unmeasurable harnesses. The director answered to follow the ruling, reading the
footer at each heartbeat. This was a compressed requirement, not a numerical field count.

At 09:04 UTC-3 another writer questioned a count. The brief said six PR 26
progress messages lacked both tag and id; the field said five lacked both and one tagged message
lacked the id. The director's answer kept the field's breakdown.
At 09:45 UTC-3 a third writer questioned another count. The brief said six more
estimated-time cases on PR 24; the field listed seven messages, six from directors and one from
a member, plus a separate log correction. The director answered to keep those source units.
Field PR 24 and Field PR 26 below preserve those corrected counts.

The 09:45 log entry and the round 12 ruling widen protocol 6.1 from the plan's ask to any sourced
count or figure in a brief, quoting the source's words or naming the source without a number.
Sourced from the three log entries, three caught compressions, two of counts. Confidence low for
the remedy; these corrections do not show it preventing a later error.

### LOG, 2026-10-23 09:48 UTC-3, premature progress

The writer's progress said two items were saved. Its citation script
had failed an assertion before writing, and the progress was sent in the same shell command.
Seconds later, the writer corrected the claim. The writer fixed the selector,
reran with exit 0 and checked the saved result. The log and the round 12 ruling require reading
a step's exit status and result before reporting it; a report sent in the same command as a
step that can fail states a fact before it exists. Sourced from the 09:48 UTC-3 log entry.
Confidence low, one premature report and correction.

### LOG, 2026-10-23 09:54 UTC-3, late notice

The round 11 result reported four items done and 107 checks with
exit 0. The director read the relevant diff, accepted it and
committed the change. The courier's notice for the 80% threshold
arrived afterward showing 82%. This is one more late notice under protocol 9.5 and the playbook's
member reading `keryx who` after each work unit; it does not change either rule. Sourced from the
09:54 UTC-3 log entry, not a repeated timing test. Confidence low for this case.

### LOG, 2026-10-23 10:25 to 10:38 UTC-3, principal inbox

At 10:25 UTC-3 the director ruled on an inbox held by a relay for the principal. The root record
names that full transport address, host included, beside the orchestrator's own session as the
team's one channel. The session holds the live conversation; the inbox keeps what needs the
principal available later. Decisions go as requests with deadlines, in the escalation shape,
saying whether they block and what the team does meanwhile and at the deadline. Silence is never
assent. Notices go as messages, one subject each, standalone and in the principal's language.
Heartbeats, swaps and their checks, member traffic and progress that needs nothing from the
principal stay out. A question answered in the session before the turn ends needs no inbox
request; anything still open goes there.

The ruling gives one principal one inbox across teams. A team on another host first proves a
round trip by sending a notice, reading its arrival in the destination mailbox and checking that
nothing waits to be forwarded from the sending host. Until that passes, or when that route is
unreachable, its record keeps its own orchestrator's session as the channel. A human address on
another host is a third party under 4.6 unless a record names it. The inbox's holder carries the
principal's words verbatim, decides nothing and answers no request itself. Messages from that
address were then limited to decisions within the receiver's existing delegation. What field 5
reserved to the principal and any record change under field 8 and 4.4 required the principal's word
in the orchestrator's own session. R05 was to name this relay case beside "your user" and "a peer".

At 10:27 the principal granted adoption through the inbox. The director asked for confirmation in
its own session because adoption changed the root record. At 10:33 the principal confirmed there
after the additional confirmation step. Pending questions then went to the inbox as requests. The
10:38 entry records answers received through the inbox that still required the principal's word
in the session for a reserved act or a record change. The director gathered them into the next
in-session confirmation instead of asking for another trip. That refinement was intended to keep
the authority boundary while avoiding a separate confirmation for each answer.

Sourced from the principal-inbox ruling and the run log entries of 2026-10-23 at 10:25, 10:27,
10:33 and 10:38 UTC-3. Confidence low, one arrangement, partly run. These entries establish the
extra confirmation and its cost; they do not establish a cross-host round trip or a completed
batched confirmation. The 2026-10-25 principal-inbox case withdrew this arrangement's in-session
step; protocol 10.2 and the keryx binding now carry that correction.

### LOG, 2026-10-25 UTC-3, principal inbox

At 10:24 UTC-3 the director asked the principal a publication question in its session and through
the principal's inbox. It recommended choices for the public history and push, the license, a
standing answer to a startup dialog, publication order and the timezone used in cases. Publication
was held for the principal's word in the director's session. At 11:34 the log recorded the
principal's instruction, through the inbox, that decisions needing the principal wait while other
work continued.

At 13:57 the principal answered through the inbox. The principal said they would never come to the
director's session, that a message from their inbox was their word, and that the director had
invented a limit they had not set. The principal approved the recommendations, said the publication
order was not the director's concern and left the cases' timezone free. The director dropped the
in-session step and pushed at 13:59. A later check failure was fixed and pushed, with checks green
at 14:04. Two days before, the principal had already said that they spoke only through the inbox
and that the inbox was them.

This is a counterexample to the 2026-10-23 arrangement. A message from the principal's own transport
address named in the root record is the principal's word for reserved acts and record changes too.
The principal never has to repeat it in the orchestrator's session.

Sourced from the charter decisions on the principal's inbox and its correction, and the run log
entries of 2026-10-25 at 10:24, 11:34 and 14:06 UTC-3. Confidence low, one counterexample with a
publication following the inbox answer. Protocol 4.4, 4.6 and 10.2 and the keryx binding carry the
correction.

### LOG, 2026-10-25, repeated Claude settings

While wiring the optional pre-send hook, an orchestrator found that Claude Code 2.1.310 kept only
the last `--settings` argument on its command line. Its reported probe ran
`claude -p --settings '{"env":{"MARK":"merged-b"}}' --settings '{"env":{"OTHER":"a"}}'`;
the Bash echo printed `MARK= OTHER=a`. A hook carried by the first of two settings arguments did
not load; the same hook carried by the last argument did. Those probes distinguish replacement
of the argument from merging its settings with the earlier one.

The initial account reversed the consequence for keryx. A later code check at keryx 92ab75d found
that [harness.rb, lines 66 and 67](https://github.com/hvpaiva/keryx/blob/92ab75d178aa68c742a126185125672ec509c985/lib/keryx/harness.rb)
adds keryx's settings before
[spawn.rb, lines 188 to 191](https://github.com/hvpaiva/keryx/blob/92ab75d178aa68c742a126185125672ec509c985/lib/keryx/commands/spawn.rb)
appends the harness arguments. A later `--settings` there replaces keryx's settings. The lost
values are `crossSessionInbound: accept` and the Stop hook that runs `keryx hook stop`
([harness.rb, lines 11 to 14](https://github.com/hvpaiva/keryx/blob/92ab75d178aa68c742a126185125672ec509c985/lib/keryx/harness.rb)).
The pre-send hook in that later argument can load, while bells are held for approval and the stop
reminder is absent. The orchestrator moved the hook into the project's local settings file, kept
out of git. HN36 and bootstrap section 4 record the consequence. This does not imply that settings
from separate files fail to merge.

Sourced from the orchestrator's run log of 2026-10-25 at 16:21 UTC-3 and its implementation brief,
which give the command and output above and the two hook placements. The writer did not rerun
the probes. The argument ordering is code-grounded at the revision and lines above, read by the
reviewer and checked again by the implementer. Confidence low, one version and one reported
experiment with both placements, combined with the launcher code reading.

### LOG, 2026-10-25, Cursor pre-send permission dependency

The pre-send implementer inspected Cursor agent 2026.10.22-27dcf5f while checking adapter formats.
The recorded reading of `4097.index.js`, line 1, found that the shell hook caller returned no
approval override for `allow`. In `index.js`, line 414, the requirement setter left the shell
permission checks in place. No hook was installed for that inspection. The adapter returns
`allow` both on clean commands and on unchecked commands, so a later version that treats that
response as an approval would invalidate its authority boundary. HN37 and bootstrap require a
version-specific recheck before wiring it.

A [Cursor IDE bug report](https://forum.cursor.com/t/beforeshellexecution-hook-permissions-allow-ask-ignored-allow-list-takes-precedence/144244)
describes allow and ask verdicts yielding to the allowlist and later inconsistent behavior. A
[feature request](https://forum.cursor.com/t/support-authoritative-allow-deny-and-ask-verdicts-from-hooks/161342)
asks for authoritative verdicts; a reply reports an open bug ticket for `preToolUse`. These are
reports about the IDE, not live evidence for this CLI version.

Sourced from the implementer's recorded code inspection, also cited in bootstrap section 4, and
the two public forum threads. The writer did not repeat the installed-code inspection or a live
hook test, including whether an empty object could be a neutral response. Confidence low, one
reported CLI code reading, with related IDE reports that do not establish CLI behavior.

### LOG, 2026-10-25 16:30 to 16:34 UTC-3, role names

At 16:30 UTC-3 the protocol team's orchestrator moved to an address whose member and team
segments both named the project. At 16:32, following the principal's preference for names by
role, it moved to orq.nomos. The principal asked the protocol team to define that convention.
At 16:34 the principal asked it to suggest role naming to the other teams' orchestrators, and
the orchestrator sent the suggestion to three teams on the same machine.

The rule is that the team segment names the project and the member segment the role, so an
orchestrator is orq.TEAM and a writer is writer-N.TEAM. The repeated project name had hidden the
role. On 2026-10-26, a writer's `keryx who -o json` reading found the five listed team
orchestrator addresses used orq as their member segment. That is adoption in one shared
environment, not two independent settings. The orchestrator closed the choice of short names
against full words in favour of short role names with instance numbers, with the full word in
the transport's role field. `keryx help join` exposes `--role ROLE` separately from the address.

Sourced from charter N14 and N15 and the run log entries of 2026-10-25 at 16:30, 16:32 and
16:34 UTC-3; the naming choice is the orchestrator's ruling in the writing brief of 2026-10-26.
The directory and help readings were observed by the writer on 2026-10-26. Confidence medium,
one shared setting with the role-based identity rationale in L11, L14 and S-N03. Evidence for
protocol 3.5 and the closure of the role-name question in section 12.

A review on 2026-10-26 found the protocol team's orchestrator still used `protocol` as its
transport role. The orchestrator retained that known divergence because the root record names the
role and changing that record needs the principal. Other seats follow the same short-role naming
pattern even when absent from the examples. Sourced from the review and the orchestrator's ruling,
not a new naming grant.

### LOG, 2026-10-26 06:50 to 06:59 UTC-3, request replies

The joint review of request semantics reported that several teams had answered work requests
with acknowledgments before completing the work. Requests disappeared from the transport's
open list while the work remained in the orchestrators' notes. At 06:50 UTC-3 on 2026-10-26,
the protocol team's orchestrator checked its own case against the message store. On 2026-10-25
at 16:27 UTC-3 it had answered the principal's address-migration request with an acknowledgment;
its completion notice followed at 16:29. The protocol's own orchestrator had broken the rule
that a reply had to be a terminal outcome.

On 2026-10-26 at 06:56 UTC-3 the principal decided that a request closes when answered, that keryx
gains no work-state layer and that following up work belongs to the project layer. The principal
left agents' use of requests to nomos. The 06:59 log entry records the orchestrator's ruling that
a reply carries what the request asked for. A result request gets its result, with an accept
message while it is underway. A request for later work, or work requested by a human, gets what
will be done and by when; its result follows as a message naming the request. The requester keeps
the work item in its checkpoint until the project layer holds it.

The 07:25 UTC-3 log entry records the proposal owed to the principal as an obligation in the
committing orchestrator's checkpoint. A later review found that 5.3 had named only the requester's
checkpoint, leaving no keeper for human-requested work. The correction names the committing side
as keeper of owed work until the result, the requester as keeper of its work item and decision,
and the orchestrator as keeper of both for a human requester.

Sourced from the joint request-semantics review, charter N16 and the run log entries of 2026-10-26
at 06:50, 06:59 and 07:25 UTC-3, and the later review ruling. The earlier acknowledgments are
reported observations; the protocol team's own case was checked by its orchestrator. Confidence
low for the remedy, a new rule following early closes, with no completed acceptance test of that
rule in this case. Evidence for protocol 5.1 to 5.3 and the keryx mapping of 5.3 and 5.5.

### LOG, benchmark run, 2026-10-24 00:00 to 00:13 UTC

A benchmark ran NOMOS 7fec01a with keryx da068ef. The later triage checked its saved checkpoint,
record and implementer's brief against the protocol and the keryx commit history. The checkpoint's
save time preceded an acceptance it already recorded. It still said code work had not started and
that the next action was to wait for the controller to start the run. Its request map retained the
second-round review and QA requests but omitted the first-round requests and their decisions.
Protocol 5.5 already required a decision under each delivered item's own request id. The run broke
that rule without making the contradiction visible. A checkpoint save must preserve those
decisions and make the phase, next action and save time agree with the work actually recorded.

The record waived a separate plan review before implementation. The implementer's brief omitted
the waiver, although the feature recipe allowed a skipped review only when both the record and
brief permitted it. A brief must carry each permitted skip, its reason and the record that allows
it. The formation also fixed the number of sessions and allowed no successor. At the 80% context
notice, renewal needed an additional session, so the orchestrator asked the controller. The first
prompt had not stated what to do at the notice when renewal was outside the grant. That action
must be settled in the record before the run.

The binding still used fde5548 as its baseline, with rechecks at 0186dcd. Its R13 rows said the
threaded progress message was not delivered, and its R11 rows still described last activity as a
gap. The triage checked that the run's keryx revision already included threaded messages and the
taken state, last activity, address retirement and a filtered directory view. The binding needed a
new baseline with the commits and tests behind each delivered capability. Last activity remains
evidence of activity, not proof of task progress. The benchmark also reported a correct but slow
result on an extreme input, supporting a QA report that includes probe duration and flags the cost.

Sourced from the benchmark reports and the later triage's checks of the saved artifacts and commit
history. These are reported observations, not a rerun by the writer. Confidence low, one benchmark
run; the proposed checkpoint and brief checks were not tested by this case.

### LOG, 2026-10-26 UTC-3, human messages

On 2026-10-26 a writer classified the messages agents had sent the principal's inbox over the
previous four days, 249 from agents and six from the transport, by what each asked the principal to
do now. The provisional labels were 86 status, 74 results, 41 reserved decisions, 27 notices, eight
suggestions, seven open questions and six choices among named alternatives. Of the 54 messages that
asked for something, 30 went as requests, 13 as plain messages and 11 as replies, so the transport
kind alone missed almost half of the asks. Three of the 30 requests had no deadline. Some asks
needed the principal to act rather than answer, such as running a command that needed root or
testing a page on a phone, and a yes alone would not have done them. Deadlines, what was blocked,
what the team did meanwhile and what it would do without an answer sat in prose, sometimes as local
times without a date, and one message said it would apply changes after an hour, which read like
authority taken from silence.

It taught that messages to a human need a kind chosen by what they ask, that every ask must be a
tracked request with a deadline, that a human action is its own kind, and that waiting, work
meanwhile and the no-answer plan are separate facts to state. Status was the largest class although
10.2 already keeps progress out of the inbox.

Sourced from the writer's inventory and its reproducible label ledger. Confidence low, one corpus,
labels without a second review pass. Protocol 10.5, 10.7 and 10.8 carry it.

### LOG, 2026-10-26 UTC-3, bundled asks

In the same corpus, a publication question carried five independent decisions in one request,
another message three and another two. The principal answered three of four items of one bundled
decision request and said the third was unclear, and the sender had to restate it in a new
message. Of the 30 requests, 26 had a direct first reply, and three of those were partial or bundled
answers. Since a reply closes its request, a bundled request answered in part closed in the
transport while one decision stayed open with nothing tracking it.

It taught that a request to a human carries one ask, so the reply closes exactly what was asked.

Sourced from the writer's inventory. Confidence low, three bundled cases and one partial answer.
Protocol 10.6 carries it.

### LOG, 2026-10-26 UTC-3, answers without a choice

In the same corpus, the principal answered choices with a bare letter, "option 1", the exact label,
"the recommended one" and free text. A one-word reaction to a demonstration of a cleanup was a reply
with no option in it, and the deletion stayed pending in a later report. An answer to a two-way
diagnostic question named neither alternative and said the symptom had stopped. A terse two-word
reply needed a follow-up question to understand. The sender of each case had to reconstruct the
answer from the conversation.

It taught that the answer should carry an option id the asker can parse, with the human's words
kept whole, and that a reply naming no option closes the request without deciding it, so a
decision is asked again when its answer is unclear. Words that name exactly one option without
doubt still count, including an id, number or label anywhere in the answer and "the recommended
one" when there is one recommendation. The principal had used that wording and had told the
team to do what it recommended; requiring an exact first-line match would reject those choices.

Sourced from the writer's inventory, the principal's replies and the orchestrator's ruling on
unambiguous choices in words. Confidence low, two replies without a choice; the structured answer
has not been tested with the principal. Protocol 10.9 carries it.

### LOG, 2026-10-26 UTC-3, inbox page

On 2026-10-26 the maintainer of the principal's inbox page described what it renders. It took the
title from the first line, made numbered lines in a request into answer buttons that wrote the label
into the reply, guessed the recommended option from a phrase in Portuguese, guessed file paths in
the prose and drew the deadline from the transport's deadline only. The maintainer asked for a
declared kind, options with ids and the recommended one, what blocks and the default, and files to
show, in a fenced block at the top rather than front matter, which a renderer that ignores it shows
as a rule and raw keys. The text had to stand alone, the title had to come from the text, the
block could hold no HTML, had to fit a phone screen when shown raw and had to fall back to plain
rendering when malformed, and the deadline had to stay in the transport only so the two could not
drift.

A later contribution from the page's team reported an observed probe against the page's message
class. With the fence on line 1, the title and notification body read "No text". Moving the title
to line 1 restored both before a block parser existed. The transport's summary also read line 1.
An answer with the fence first lost its title in the same way. The contribution proposed a
page-written label on line 1, a block on line 2 declaring the answer kind, and the principal's
words unchanged after it. An option alone would be enough unless words were required, and an
action would require words only on failure.

The contribution also found by code inspection that the page opens only regular text files of at
most 1 MiB inside its configured roots, with dot folders and secret-like names excluded. Folder
paths in the draft could not open. Its size probe showed that a block can exceed the total byte
cap even when each field fits its own cap. The accepted design kept labels at 60 characters,
shortened the waiting facts to 80, capped files and links at three each, kept 16 lines and 1,024
bytes binding, and used null for nothing waiting. These limits were not measured on a phone. The
team also proposed no buttons for a malformed or rule-breaking block, text taking precedence over
a conflicting block, an inert block for agent recipients, and a new info string for changed
meanings. Its directory probe reported the principal's address with role `human`, supporting that
as the human-recipient test with the local scope as fallback.

It taught that the title belongs before the block, that replies preserve the principal's words
separately from the page's label, and that fallback must preserve the text without inventing
answer buttons. The deadline stays out of the block, and file links must name openable files.

Sourced from the maintainer's code account and the page team's contribution, which separates
observed probes, code inspection and phone-layout hypotheses. The writer did not rerun those
probes. Confidence low, one page; title placement was probed, the block parser and answer path
were not built. Protocol 10.7 and 10.9 carry it.

### LOG, 2026-10-26 09:17 UTC-3, asks sent as notes

On 2026-10-26 at 07:22 UTC-3, the protocol team's orchestrator sent the human-message proposal
to the principal as a message asking for a reaction, after a threaded send was refused. It did
not open a new request. The principal answered anyway at 09:08 UTC-3, approved the proposal and
asked for the inbox page team's contributions before application. At 09:17 UTC-3, the principal
reminded every orchestrator that everything depending on the principal must arrive as a request,
since a note asking for something might go unseen.

It taught that asking in a message loses the tracked obligation even when the principal happens
to answer. Each ask needs its own request with a deadline; a reply to one ask then closes that
ask, while a note remains for information that needs no answer.

Sourced from the protocol run log's entries at 09:09 and 09:18 UTC-3 on 2026-10-26, which record
the answer and the reminder. Confidence low, one ask sent as a note and a direct correction;
the one-ask-per-request remedy was not tested by this incident. Protocol 10.5 and 10.6 carry it.

### LOG, 2026-10-26 UTC-3, pane cleanup ownership

On 2026-10-26 at 09:38 UTC-3, the principal said that a team that opened a pane must close it once
the session ends. The protocol team's orchestrator tried to close a finished pane, but its
harness's permission classifier refused. The orchestrator reported the refusal and the finished
panes it had opened, leaving them in place. The principal then assigned their closure to another
orchestrator, which reported closing them at 09:49 UTC-3.

It taught that each team owns cleanup of the panes it creates after the sessions end. A permission
refusal does not erase that ownership or permit a workaround; the team reports the retained panes
and leaves the close to whoever may perform it.

Sourced from the run log entries of 2026-10-26 at 09:39 and 09:55 UTC-3, which record the
principal's direction, the refusal and the other orchestrator's completion. Confidence low, one
refused close and a reported cleanup, not a rerun by the writer. The playbook's Cleanup section
carries the lesson under protocol 4.7 and 9.3.

### LOG, 2026-10-26 UTC-3, readback form

On 2026-10-26, trials on the comparator round's first revision flagged every field of three real
member readbacks.
Each readback used prose in the member's language without labels and summarized the granted paths;
the director had confirmed all three by reading. Passing synthetic tests had not shown whether the
tool could compare the readbacks members actually sent. After the first fix round, the three member
pairs flagged task without a brief and authority on summarized paths. The later review also required
omitted acts and unknown wording to remain visible; a labeled form alone does not guarantee a match.

The proposed remedy is five labeled lines. The task begins with the first request's first line, authority
repeats granted acts and paths, prohibitions and reservations in the record's words or a faithful
translation, and the next action
states the wait for confirmation and what follows. This gives both the director and the optional
tool identifiable values to compare, while summarized paths still need clarification.

Sourced from the director's trial report and correction request of 2026-10-26, in UTC-3, and the
three saved member readbacks. Confidence low, three comparisons and a proposed form, with no
new member launch testing that form. Protocol 9.2 carries the lesson.

## Field evidence from the keryx team (LOG)

These entries summarize reports about pull requests in the public [keryx
repository](https://github.com/hvpaiva/keryx), with private addresses, request ids and machine
names removed. The reports are field evidence, not reruns by the writer. Times in these entries are
UTC unless another zone is stated; the incident log above uses UTC-3. A single pilot or audit round
does not establish a general result.

### Field PR 22, neutral host name in address tests, 2026-10-23 07:12 to 07:23 UTC

One request opened. One readback was sent, none skipped or corrected. The member sent one [accept],
and the requester sent one [accept] as its decision; one [progress], no [clarify] and no [close].
There were no nonterminal replies on this PR's request. Its one delivered item had a recorded
decision, none lacked one. The brief pasted about 240 words of conventions, plus a 196-word
delegation record in the first prompt.

- The implementer sent its readback as a request at 07:13:35, about fifty seconds after joining. It
  restated the seven lines, authority, prohibitions and next action. The director compared it with the
  brief and record and confirmed at 07:14. It caught no error on this one-file task and cost about one
  minute of the director's attention.
- [accept] and [progress] were messages naming the request id. The former gave a result deadline,
  the latter the PR link. The progress message let the director check the PR while CI ran; the merge
  followed the result within two minutes. The terminal reply led with its outcome, classified claims
  as observed or code-grounded and stated omissions. The director's [accept] after the merge named
  the merge commit and checks. The reporter found this clearer than the first round's replies.
- Separately, the director was holding a requirements request while waiting for the principal's
  decision. The stop hook asked it to reply before ending its turn. It sent a conditional reply,
  closing work that was still open under protocol 5.3. This led to R13. On R13 itself it sent [accept],
  but approval arrived in the same turn and it replied; this did not test whether the reminder would
  recur in another turn. The PR member's count of zero nonterminal replies excludes this request.
- The director moved two auditors' stopping points from 125K to about 180K by message. The courier
  still sent 100% notices to the auditors and director at the old ceiling. The
  protocol director checked rejoining its own address at 04:22 UTC-3; rejoin kept the address and set
  the new figure. The ruling makes the stored ceiling the stopping point, changed by a timed message
  with the reason and `keryx join NAME --ceiling NEW` by the session.

Evidence for message conventions, R13 and the playbook's moving-ceiling rule. Confidence low, one
pilot, with the rejoin checked and the stop-hook recurrence not observed in that pilot.

### Field audits of fde5548, 2026-10-23 07:05 to 07:50 UTC

Four requests opened, three audits and a successor for one auditor's remaining areas. These
auditors were briefed before adoption of the v0 conventions, so readbacks, tags and the requester's
decision were not requested. The director sent each a plain acceptance and a request to leave. It
received six ceiling notices. This is evidence about audit operation, not a four-request test of
the conventions.

- The initial ceiling was 125K on windows of about 258K and 256K. A full audit used about 180K to
  216K. One auditor reached 109K at minute six and 183K at about minute forty, stopping partial;
  another finished at about 187K in twenty-two minutes; the third finished at 84.6%, about 216K.
  The 80% and 100% notices called for a stopping point as early as minute six. Reading about 5,200
  lines of code, 7,300 of tests, docs and probe output made a fresh session costly. The director moved
  two points to about 180K by message, but the old notices continued until both auditors rejoined
  with `--ceiling 180k`; notices then matched the director's point.
- The reporter saw no quality loss in the complete, evidenced reports written at about 70% and 85%.
  This is a reported observation, not a controlled comparison. A progress file holding findings and a
  coverage map, updated after each finding, let the partial auditor hand four areas to its successor
  without redoing work. Compaction near the window's end remained a risk.
- keryx could not read the Cursor auditor's figure. The footer gained a count of edited files,
  and spawn left a pane twenty-six columns wide. No context notices reached that auditor. It
  reported that the director's typed instruction arrived only after its report because Cursor queued
  it until the turn ended.
- One turn ended on a provider capacity message, another on a provider content restriction while
  reading its own probe log; the latter also waited at a menu that the principal noticed. `who`
  showed done or idle. Only the director's heartbeat or the principal's observation caught the
  unfinished work. A fifteen-minute heartbeat was too slow for the twenty-two-minute audit, the
  field case for R11's last-activity column.
- The resulting ruling keeps roles whose state lives in commits, notes and reports at half the
  window, at most 250K, and gives one-pass reading about 70%, at most 400K, only with a progress file
  and coverage map current from the start. Without the file the half-window rule applies. The 1M
  reading cap is not measured. More than about three heavy areas are split across auditors from the
  start. A figure keryx cannot read needs the director's footer reading at each heartbeat or a
  different harness. The heartbeat is about a quarter of the expected run, at most fifteen minutes.
- In a later message about the successor audit, the director wrote that a decision was made at
  07:56 UTC; the clock read 07:51:29 just after sending. Another director had made the same mistake
  earlier that day (LOG, 04:25). Absolute timestamps were being estimated instead of read.

Evidence for the playbook's An audit, The ceiling and The director's heartbeat, the audit brief,
auditor card and protocol 5.7. Confidence low, one round with three original auditors; the successor
shows a partial handover worked, not that the new policy has been tested across teams.

### Field PR 23, audit fix batch 1, 2026-10-23 07:54 to 09:07 UTC

Six work requests opened, the batch, QA, plan review, code review, a documentation fix and three
probes assigned together. Five readbacks were sent, none skipped or corrected. Members sent four
[accept] messages and the requester sent one as its decision; there were three [progress], no
[clarify] and no [close]. The requests carried 35 messages, eleven requests including five
readbacks, eleven replies and thirteen messages, eight tagged and five untagged instructions. Ten
courier ceiling notices included five copies to the director. No reply was nonterminal; five
confirmed readbacks and six delivered results. All six items had checkpoint decisions; one was sent
to its worker. Conventions pasted into the three initial briefs occupied 250, 132 and 253 words,
counted with their headings, and none in the two follow-up briefs. Their first prompts occupied
196, 199 and 206 words; the two fresh sessions' prompts were not traced to a file and were not
counted.

**Reading before code.** QA reached 82% of its 125K ceiling at 08:05:26 and 101% at 08:09:27 while
reviewing the plan, and finished at 137K. The director ended its task at the plan rather than
swapping it, to avoid paying for reading again. The batch implementer held 191K of 250K before code
at 08:06, used five subagents in isolated worktrees whose work it cherry-picked, received an 83%
notice at 08:13:28 and delivered at about 241K according to the run log at 08:38. A planned swap
was not used. Two other implementers passed 80% before writing code on their tasks. The field
reporter proposes planning a swap for an eleven-item batch or reducing its brief's reading.
Confidence low, one batch and two related task reports; this entry does not change the ceiling or
authorize crossing it.

**Deferred bells.** The stop for the plan reviewer was sent at 08:05:55, deferred because Cursor
reported a dialog, and read at 08:11:40, after the plan reply at 08:11:19. The reviewer then closed
as instructed. Notes to two QA seats on other pull requests met the same condition at 08:54:46; one
receipt was deferred and the other rang at 08:55:35. Both notes waited in mailboxes and were read
at 08:56:16 and 08:55:49, after their plan replies at 08:54:46 and 08:54:45. The messages crossed
the replies and none was lost. This is the reporter's live deferred-bell case, low confidence
beyond those seats.

**Readback cost.** The fresh implementer joined at 08:48:31 and sent its readback at 08:48:54. It
waited four minutes seven seconds for confirmation while the director brought up the fresh
reviewer. It committed the one-paragraph fix at 08:53:32 and replied at 08:54:56, one minute
fifty-five seconds after confirmation. The reviewer read its request at 08:53:08, sent its readback
at 08:53:32 and was confirmed at 08:54:11; its join time was no longer on disk after departure.
Both readbacks were confirmed without correction. The implementer's readback round took about twice
as long as its fix. Confidence low, one case; no change to the readback rule follows from it.

**Follow-up messages.** Neither follow-up brief nor its confirmation asked for [accept]. The fresh
reviewer nevertheless sent one with a result deadline of 09:30:00 UTC and delivered at 09:05:03.
The implementer sent none and delivered one minute fifty-five seconds after confirmation; the report
found nothing lost. Three open requests were changed without [amend], the QA scope, the reviewer's
stopping point and the implementer's instruction to merge main rather than rebase. The first two
named their request, but the stopping-point message had no absolute time. The third named neither
request nor time, followed a correction to a different implementer by one second, and its own brief
had never said rebase. QA and the reviewer acknowledged their changed instructions in their results.
These observations do not waive protocol 5.2.

**Review and verification.** The reviewer's suggestion identified documentation saying mail takes
no locks while the change added an outcomes lock. Because the change introduced the inconsistency,
the fix went into the same pull request, in one commit with all six CI checks green. Unchecked
serializer error paths stayed out because there was no finding on them. The batch result said it
had sixteen commits; the director's revision-count check found fifteen. These are reported checks,
not rerun by this writer.

**Departure and usage pool.** The director first closed a Codex reviewer with `/quit` without
asking it to leave the transport, against HN17. No harm was observed and `who` showed the address
without a session; the successor ran leave before `/quit`. To preserve capacity in one shared usage
pool, the director assigned the extra probes to another vendor and kept the documentation fix under
its existing model decision. Both Codex launches showed the expected hooks dialog; the director
chose Continue without trusting. These are one round's reported observations, not new grants or
harness checks.

**Requester decision.** All six delivered items had a decision in a checkpoint, five in the
director's run log and the plan reply in the implementer's handover. Only one decision was sent to
its worker, and its bell found no session because the worker had already left. The plan's
acceptance went to the director and the handover, not its reviewer. New requests to fresh sessions
followed the batch and partial review, but neither named its earlier request. The fix and probe
results had no decision message before their sessions closed. The protocol director ruled at 06:22
UTC-3 that the checkpoint entry under the request id is the decision; send it while the worker's
session is live or its identity holds other open work with the requester. A closing note before
departure may carry it. Fix requests and follow-up work still name the earlier request. Evidence
for protocol 5.5; low, designed from one field round, not a tested delivery exception.

**Brief ceiling.** The Codex reviewer had a 125K ceiling, but neither its brief nor its first
prompt stated a ceiling or stopping point. It read whole source files, reached 106K (84%) at
08:41:31 and 127K (101%) at 08:42:02. The director sent a stop at 08:41:59; the partial reply came
at 08:45:31, with no must-fix, one suggestion and five areas unchecked. A successor brief stated
125K and a report before about 110K. That reviewer covered three areas as probes at about 86K by
the director's reading, with no courier notice. The 06:22 UTC-3 ruling calls for the ceiling and
stopping point in briefs. The brief and review-brief forms now ask for the token ceiling, who
measures it, an earlier stopping trigger and saved completed and unchecked work for the report and
handover. Implementer and reviewer cards digest these fields. Confidence low, one review and its
successor, not a controlled test of the brief alone.

**Message times.** The director's handover recorded three estimated times in twenty minutes, 08:30
for 08:28, 08:31 for 08:30 and 08:38 for 08:36. Its field notes also said 08:38 for the reviewer's
start whose readback was at 08:36:50, 09:06 for the probes' result at 09:05:03, and 09:08 for the
merge at 09:05:25. These are the reporter's comparisons with message timestamps and the merge
record, not checks rerun by this writer. The protocol director ruled at 06:22 UTC-3 that a message
body need not restate its send time because the transport stamps it. Evidence for protocol 5.7; low
for the clarification, one field round repeating an earlier observed error.

### Field PR 24, spawn safety without an attended pane, 2026-10-23 08:23 to 11:42 UTC

Sourced from the field reporter's mailbox count from 08:23:37 to 11:44:00 UTC. Selection by request
thread, reply or body reference found 97 envelopes; eleven more were recovered by hand, including
six progress messages without request ids. Two messages to another host were in the outbox and
excluded from this count. Twenty-one work requests opened, task, QA, plan review, two successor
tasks, four reviews, three rechecks and nine further implementer requests. Fourteen readbacks were
sent, one per six implementer sessions, QA and seven reviewers; three had a [readback] tag. None
was skipped; the plan review and six implementer requests went to already confirmed sessions.
Two readbacks were corrected, merge rather than rebase and functions rather than whole files;
three confirmations added predecessor conditions or a retained worktree. Members sent six
[accept] messages, five from the first three implementer sessions and one from QA; the requester
sent none as its decision. Five progress messages were tagged, four from implementers and one
from the director; six reviewer progress messages had neither tag nor request id. One [clarify]
was answered in 25 seconds; two untagged questions were answered in 1 minute 47 seconds and
19 seconds. There was no [close], no [fix] tag on the nine further implementer requests and no
[amend]. Five changes were untagged, at 08:54, 10:23, 10:35, 10:56 and 11:34; one at 08:39 was
sent as [progress].

Of 108 transport envelopes, 38 were requests, including fourteen readbacks, one clarify and two
untagged questions, 40 replies and 30 messages. Eighteen courier ceiling notices included nine
copies to the director. No reply was nonterminal; fourteen confirmed readbacks, three answered
questions and 23 returned terminal results. One delivery answered three requests; QA posted its
plan review twice on the plan request and once on QA. The terminal replies also included a
"Not started" refusal and a task-closing reply at 11:43:26 to a task already answered at 10:03:26.
All seventeen delivered items had checkpoint decisions, fifteen in the director's log, the plan
in an implementer's handover and one fix in the next request. Eight decisions reached workers
in six untagged envelopes, two of them requests. None reached QA or the reviewers, whose sessions
had left, or one fix's departed implementer. Convention sections with headings occupied 250 and
132 words in the implementer and QA briefs. The seven review briefs had none and counted 768,
391, 439, 481, 545, 313 and 402 words overall; eight fix request texts counted 369, 234, 759, 494,
489, 539, 276 and 331 words. First prompts counted 196 words for the implementer by its spawn
recipe, 199 for QA and 206 for each reviewer.

- Side effect and successor conditions. At 08:29 a test stub used a name resolved through a shell
  startup shim, installing a real 381M package. The implementer reported it in [progress] at
  08:30:06. The director left removal to the principal 37 seconds later and required a stub name
  with no shim or configuration entry; two successor confirmations carried that condition. At
  09:14:37 the next implementer asked [clarify] before a required probe whose stubs had real
  harness names. The director allowed it 25 seconds later with shim and harness directories
  removed from PATH, resolution checked with `command -v -a`, and checks for stray processes and
  new installs afterward. The log at 09:19 reports those checks met. One incident supports the
  report-and-contain part of 4.9 and continuity in 9.4, not a new installation grant. Confidence low.
- Honest refusal. At 10:41:47 a fix went to an implementer then at 161K of 250K with a 212K stop.
  At 10:44:04 it answered "Not started" at 187K, explaining that the fix would not fit, and left a
  section for it in the handover. A replacement request went to a fresh session at 10:45:01.
  The work remained undone, but the original request closed with a reason. This cost about three
  minutes and two request texts, 489 and 539 words. One case supports refusal as a terminal
  outcome under 5.3. Confidence low.
- Untagged questions. Two questions used requests without [clarify]. At 11:22:18 the implementer
  questioned a fix brief whose assertions contradicted its chosen lock boundary and whose join
  reference named the wrong function. The director chose the corrected test 19 seconds later;
  the fix arrived at 11:30:58, without the unnecessary join change. The other question concerned
  a review finding. Both got answers, but neither followed 5.2's tag convention. Two lapses,
  not evidence that a tagging remedy has held. Confidence low.
- Review race. One check-then-act finding needed three fix requests, three implementer sessions
  and three recheck reviewers. On 237d221 the reviewer reported four interleavings at 10:30:09.
  The first fix, 83036dc, repeated address and pane-name reads before clearing; the recheck at
  11:03:05 found deadline and rejoin gaps. Reordering the reads in ffee0d1 left a join-after-check
  window, reported at 11:16:43. Holding the occupants lock over the last address check and clear
  in b2ab993 closed it; the final recheck at 11:42:13 had no must-fix. The reporter counts
  72 minutes from the first finding to the final recheck. One review-recipe observation,
  confidence low, with no new general locking rule.
- Measured limit. The last fix named a remaining limit, two slow external calls could hold the
  lock for about 22 seconds while join waits only 15. The director accepted the limit for now
  and asked the reviewer to measure it. At 11:42:13 the reviewer reported that two injected
  11-second delays gave a 22.009-second spawn, a concurrent join exiting 1 after 15.043 seconds
  with a lock-timeout error, and a join after release exiting 0. It triggered no further fix
  round; permanent tests remained a suggestion. One review-recipe observation, confidence low,
  not a rule to accept all named limits.
- Ceiling mid-change. A fifth implementer stopped at its 81% notice, 201K of 250K at 11:07:44,
  leaving a merge undone. The 1M ruling arrived at 11:12:20. Its successor used a 320K ceiling
  with a first readback stamped 67K, delivered a fix at 180K and the merge at 212K, and closed
  the task at 216K, past the old 200K notice line without a courier notice. The reporter attributes
  one avoided spawn and about 67K of rereading to completing both in that session; the earlier
  swap had already been paid. With PR 26 this is a second operational instance of the 1M rule
  holding, not a comparison of quality or quota use. Confidence medium for those two completions,
  low for the chosen ceiling figures and their wider effect.
- Checked commit facts. At 11:43:27 the director told another host that the first prompt no longer
  traveled in argv. After `git log -1 3663d0f`, it corrected the claim at 11:43:46. The prompt
  remained the harness's last argument, readable in `/proc` while running; the change capped it
  at 2,048 bytes and excluded secrets from `--prompt`. The wrong claim stood for 19 seconds.
  These two outbox messages are outside the envelope count above. One case supports checking
  a relayed commit claim against that commit under 7.1 and 7.5. Confidence low for this case.
- Message times. Six director messages gave estimated event times, 11:49 for a merge at 11:42:41
  in a message sent at 11:42:58, 11:51 and 11:53 in messages sent at 11:43:27 and 11:43:46,
  11:20 and 11:36 in confirmations sent at 11:18:49 and 11:32:43, and 10:25 in a request sent at
  10:21:24. A member wrote 09:20 for a check around 09:14 and corrected itself three seconds
  after sending at 09:14:40. These are seven messages, six from directors and one from a member.
  Separately, the director corrected log entries of 11:43 to 11:54 for events at 11:40 to 11:43,
  from message ids and the merge record. The reporter found no effect on the work and times up
  to nine minutes ahead in messages. This repeats 5.7's failure on both sides and supports the
  proposed pre-send comparison in 11.2; it does not validate that unimplemented check.

The writing director confirmed on 2026-10-23 at 09:45 UTC-3 that the brief's six time cases meant
seven messages in the source, plus the log correction as a separate case. Counts and observations
are sourced field evidence. This writer did not repeat the mailbox census or operational tests;
confidence remains low beyond the reported cases unless a narrower qualifier above says otherwise.

### Field PR 25, bell input targets, 2026-10-23 08:24 to 10:18 UTC

Sourced from the field reporter's mailbox count, selecting messages from 08:24:00 to 10:19:30 UTC
by request thread, reply or body reference, plus one progress message found by hand. Ten work
requests opened, task, QA, plan review, successor task, two reviews, two fixes and two rechecks.
Six readbacks were sent, none skipped or corrected; the continuing reviewer's recheck needed no
new readback. Members sent six [accept] messages and the requester sent one as its decision.
Five progress messages were tagged and one had neither tag nor request id. There was one [clarify],
answered within a minute, no [close], two [fix] request tags and no [amend]. Two changes to open
reviews, at 09:43 and 09:54, were untagged. Of 49 transport envelopes, 17 were requests, including
six readbacks and one clarify, 17 replies and 15 messages. Seventeen courier notices included eight
copies to the director. No reply was nonterminal; six confirmed readbacks, one answered the clarify
and ten delivered results, with one result posted to two requests. All seven delivered items had
checkpoint decisions, one sent to its worker. Convention sections with headings occupied 250, 132
and 253 words in the implementer, QA and first review briefs; the later review briefs had none and
were 824 and 299 words overall. First prompts counted 196, 199, 206 and 206 words; one reviewer's
prompt was not saved and was not counted.

- Partial review. The first reviewer reached 80% of 125K fourteen minutes after joining and returned
  no must-fix with an unchecked list. The director passed that list to a fresh reviewer, whose first
  of five cases found a must-fix in the change's core property. One round and two more sessions kept
  that defect out of main. The ruling of 2026-10-23 09:01 UTC-3 keeps unchecked coverage open until a
  fresh reviewer completes it; a partial review is not a pass. Confidence low, one case.
- Context and delivery. Reviewers reached 80% in fourteen to twenty-five minutes on this change,
  against five and seven minutes in related reviews of PR 24 and PR 26. A request to read only
  touched functions did not hold. A three-item recheck completed at 94K of 125K. Another reviewer
  reserved about 10K for recheck, but received an 85% notice while finishing the main result, refused
  the recheck with a reason and handed it to a fresh reviewer. Cursor QA sessions at 105% to 114%
  of 125K still returned complete plan reviews; instructions to stop queued during their long turns
  and were seen after the replies. These observations grant no exception to the ceiling.
- Bell and wait. At 09:41, 10:08 and 10:16, confirmations reported `agent_not_ready` while their
  recipients were in `keryx wait` on readbacks; each message was read within seconds and `who`
  showed zero unread. Bell failure did not mean failed delivery in these cases. The same field
  records a PR 26 implementer waiting on QA from 09:44 to 09:59, leaving its director's decision
  unread until the wait ended. Cursor follow-up input was also mistaken for a dialog at 09:55
  on the installed revision d6944ff, the deferred-bell case this change addressed.
- Readbacks. A reviewer caught a brief requesting a new worktree outside the path its first prompt
  granted, and chose the granted path. A handover at 09:22 wrongly said PR 23 was unmerged at
  09:20, though the merge record said 09:05:25. The successor's spawn request corrected it and its
  readback carried the correction; it delivered at 09:30:23, five minutes after joining.
- Defect probes. Audit probes ended in raises asserting defects, so a fixed tree stopped at its
  first fixed case. The batch brief asked for a copy without those raises and a recursive diff;
  a reviewer ran original blocks separately with a driver checking the probe hash before and after.
  This and PR 26 support the corrected-expectation ruling of 2026-10-23 09:01 UTC-3, at low confidence.
- Message shape. The untagged progress at 10:11:08 had no request id and escaped the thread query;
  it was recovered by hand. Alongside PR 26, this is evidence for R13 and consideration of a pre-send
  hook, not an implemented hook or a change to message kinds. The two untagged amendments remain
  failures of the existing convention, not exceptions to it.
- Harness operation. Codex hooks dialogs initially made spawn report an error; from 09:49 it waited
  with a notice instead, four times. The director answered after checking the selection. At 10:19,
  Enter immediately after `herdr pane send-text` left text in a Codex composer; a one-second pause
  worked on another seat at 10:21. HN35 records the reported versions and remedy.
- Orchestrator load. Four successive sessions went from 73K to 183K in 26 minutes, 72K to 162K in
  19 minutes, 71K to 154K in 17 minutes, and 74K to 177K in about 20 minutes. Work included results,
  reviews, fixes, merges, installs, swaps and spawns; heartbeats cost about 2K to 4K. The reporter
  described 20 to 30 minutes under this load before a 250K cap. These are observations supporting
  the 08:12 UTC-3 1M ruling, not a controlled comparison of quality or quota.

Confidence low for these field observations beyond the reported cases. Counts describe this window
and include related-task incidents only where named; the writer did not rerun the mailbox census,
probes, spawns or context measurements.

### Field PR 26, audit fix batch 2, 2026-10-23 09:37 to 11:34 UTC

Sourced from the field reporter's mailbox count from 09:37:03 to 11:35:00 UTC, selected by request
thread, reply or body reference, plus seven messages recovered by hand. Six of those were progress
without request ids; the seventh named a result instead of its request. Eleven work requests
opened, task, QA, plan review, review, three fixes and four rechecks. Eight readbacks were sent,
none skipped, one corrected to read functions rather than whole files; the initial implementer's
confirmation also changed its handover trigger to the 80% notice. Members sent three [accept]
messages and the requester none as a decision. Progress comprised two tagged messages, one without
a request id, and five untagged messages without request ids. Thus six lacked an id, five both id
and tag. One [clarify] was answered in 42 seconds with an undefined [decision] tag. There was no
[close], no [fix] tag on the three fix requests, and no [amend]. Four changes were untagged, at
09:52, 10:07, 10:50 and 11:16; with PR 25's two this makes six untagged changes to open requests
across the two fields. Of 56 transport envelopes, 20 were requests, including eight readbacks and
one clarify, 20 replies and 16 messages. Seven courier notices included three copies to the
director. No reply was nonterminal; eight confirmed readbacks, one answered clarify and eleven
delivered results, with QA's result posted twice. A task-closing reply at 11:35:07 falls outside
the count. All ten delivered items had checkpoint decisions, nine in the run log and QA's in the
agreed plan; four were sent to workers, none tagged. Reviewers left after their results. Convention
sections with headings occupied 250 and 132 words in the implementer and QA briefs, none in the
five review briefs (763, 554, 473, 448 and 390 words) or three fix requests (501, 179 and 231
words). First prompts counted 196 words for the implementer by its spawn recipe, 199 for QA and 206
for each reviewer.

- Clarify answer. The director's [decision] answered a clarify request. The ruling of 2026-10-23
  09:01 UTC-3 makes the answer the reply on that clarify request, adds no [decision] kind and leaves
  delivered-item decisions in the checkpoint under 5.5. Confidence low, one field answer.
- Stop lines. On PR 24, reviewers crossed brief stops of 90K, 90K and 95K, reaching 106K, 104K and
  108K; the first 80% notice on 125K was at 100K, already past those lines. On PR 26 a partial
  rechecker rose from 47K to 80K in three minutes of whole-file reading and returned at 87K without
  its own probe. Splitting the remainder into two and three items produced complete reports at 78K
  each; a related PR 24 reviewer reported 82K while writing. A final PR 26 reviewer read `who`
  after probes and held 68K before its writing gate, but a skill read brought it to 82K, above its
  80K stop. Its report was stamped 83K at 11:33:30, with 24 cases and no must-fix. The 09:01 UTC-3
  ruling extends the earlier stored-ceiling correction: no separate lower token stop in the brief; set the ceiling so its 80% notice
  falls at the intended handover trigger, and read `who` after each work unit. Confidence low;
  the setting is designed from overruns, not validated by the successful small reviews.
- Settled figures. A related PR 24 plan specified 8 lines of 160 from a 20-line capture. The
  implementation changed the figures to 24 and 60 and called this an unsettled decision. Acceptance
  missed the difference; a reviewer caught it at 10:36:15, and the director recorded its plan
  decision at 10:38. The 09:01 UTC-3 ruling requires comparing a result's decisions with the
  plan's settled figures before acceptance and deciding and recording any deviation as a plan change.
  Confidence low, one caught deviation.
- Context and times. A related implementer estimated 75K in a report stamped 158K at 10:40:56,
  then corrected it five seconds later to 161K, 64%, from `keryx who`, before the director acted.
  The director also wrote 10:40 UTC in a message sent at 10:38:02, and 11:29 UTC in one sent at
  11:25:48. The 09:01 UTC-3 ruling requires context from `who` or the message stamp, never estimates,
  beside the existing absolute-time rule. Confidence low for this added source requirement.
- Fix batches. On PR 24, two fixes within twenty minutes each needed a fresh implementer with a
  62K readback. The reporter puts reading per fix session at 60K to 90K. On PR 26, the next fix
  waited for the last review at 11:06, then went to one fresh implementer. That implementer reported
  a residual at 11:18:35; the director took it into scope at 11:19:19, it was fixed five minutes
  later, and one review covered both revisions. The 09:01 UTC-3 ruling calls for one fix request
  with all must-fixes after all reviews are in; an implementer's named residual may join before
  review. Confidence low, cases on two changes, not a measured general saving.
- Recheck probes. A defect-asserting probe stopped at a parser error before its first case on the
  fixed tree; another on PR 24 exited 1 at an assertion that cleanup had not run. Briefs asked to
  rerun unchanged or expect exit 1. The partial recheck did not exercise its original case, which
  a fresh reviewer took. The 09:01 UTC-3 ruling requires each probe's corrected expectation in
  the recheck brief. Evidence also comes from PR 25; confidence low for the remedy.
- Brief and contract. A reviewer ranked a silent drop as must-fix because the brief demanded a
  refusal be reported, while documenting that the code's contract specified a silent drop. The
  director rejected that ranking at 11:09; the stronger ceiling notice had already
  reached the recipient. This is a separate decision from the earlier plan-figure case. The
  09:01 UTC-3 ruling says to quote each plan ask without stricter wording and rank against the
  documented contract, naming any brief excess. The writing run's clarify at 04:56 UTC-3 also
  caught a brief stricter than its ruling. Confidence low for the remedy.
- Delivery and conventions. Six progress messages lacked request ids, five also lacking tags.
  Alongside PR 25, these are evidence for R13 and a pre-send hook, with no rule change here.
  The PR 25 field records this batch's implementer blocked on QA in `keryx wait` for fifteen minutes,
  from 09:44 to 09:59, while the director's decision waited unread. Hooks dialogs also serialized
  three nominally parallel Codex spawns at 10:55, each waiting for Continue without trusting.
- Join and ceiling. The orchestrator's join cost about 70K. One incarnation went from 70K to 166K
  in thirteen minutes; stamps showed 96K at 10:50:19 and 170K at 11:03:34, with a swap at about
  190K at 11:08, nineteen minutes after join. After the 1M ruling at 11:12:20 UTC, an implementer
  at 144K of 250K rejoined at 320K on the director's 11:16:37 message rather than swapping. It
  reported at 161K and 203K, passing the old 200K notice line with no courier notice. Its initial
  readback was 61K; the reporter estimated about 70K of rereading avoided. This is one instance
  where the 1M rule held operationally, not a quality or quota comparison.

The writing director confirmed at 2026-10-23 09:04 UTC-3 that its brief had compressed the progress
count incorrectly; the five-untagged plus one-tagged breakdown above preserves the field source.
Confidence low beyond the reported cases. Counts and observations are sourced field evidence;
the writer did not repeat the mailbox census or the operational checks.

### Field PR 27, address retirement and short lists, 2026-10-23 11:50 to 12:40 UTC

Sourced from the field reporter's mailbox count from 11:50:27 to 12:42:00 UTC. Selection by request
thread, reply or body reference found 25 envelopes; four were recovered by hand, a handover note,
a merge note and two progress messages without request ids. The director's output-change notice
to the protocol owner was outside the team and excluded. Six work requests opened, task, plan,
two reviews, fix and recheck. Five readbacks were sent, none tagged, skipped or corrected. Three
confirmations added conditions, two the 80K stop missing from the readbacks and one functions-only
reading. Members and requester sent no [accept]. Two progress messages had neither tag nor request
id. There was no [clarify] tag; one untagged question received an answer in twelve seconds. There
was no [close], [fix] or [amend] tag. The untagged fix request named no request id but pointed to
a handover and a fix document naming the reports. One change to the open fix request, a second
commit, traveled as the answer to the question.

Of 29 transport envelopes, twelve were requests, including five readbacks and one question,
twelve replies and five messages. Three separate courier notices quoted hooks dialogs; there was
no courier ceiling notice. No reply was nonterminal; five confirmed readbacks, one decided the
plan's nine points, one answered the question and five returned results. All six delivered items
had decisions in the director's log, the plan, initial change, two reviews, fix and recheck. Three
decisions reached workers, none tagged; none reached reviewers. No brief had a convention section.
The task brief counted 528 words; the review briefs 433, 478 and 417; the fix request message 22
and its document 280. First prompts counted 196 words for the implementer by its spawn recipe and
206 for each reviewer.

- Plan before code. The plan arrived at 11:55:32, four minutes 23 seconds after readback confirmation,
  with nine open points. The director decided all nine as proposed at 11:56:00, in one round of
  28 seconds. The first commit was at 12:05:45 and delivery at 12:13:55, with no question back
  during the build. Both review briefs cited the plan and the answer as the contract. One case
  supports the plan step; the 17 minutes 55 seconds after the decision do not prove a general
  time saving. Confidence low.
- Handover at delivery. The implementer delivered at 250K of 320K at 12:13:55. Its receipt asked
  for a handover and departure; it saved the note and left at 255K at 12:14:51 while the reviews
  started. The fix went to a fresh session at 12:22:06, twenty seconds after the second review
  result, with the note as its first input. Its readback came 36 seconds later at 65K and its
  result at 12:30:45 at 133K. The fix needed no intervening wait for a session swap. One case,
  confidence low; it does not set a new context threshold.
- Dialog notices. Each of three reviewer spawns quoted a Codex hooks dialog to the director,
  seven seconds after its request, at 12:14:54, 12:15:24 and 12:31:52. Readbacks followed the
  quotes by 50, 50 and 62 seconds. The director answered from the quotes. The courier required
  the human's word, while the team's standing procedure chose Continue without trusting and the
  log recorded no word from the principal for these answers. Three observed notices support the
  delivery mechanism in bootstrap 7 step 5, not authority to answer; that authority remains a
  named dialog answer in the delegation record. Confidence low beyond these notices.
- Residual before review. Two reviewers, assigned two and three items, independently reproduced
  one must-fix, retirement during spawn's pane creation could still start a harness and leave
  spawn waiting for its timeout. The implementer had named the window at delivery and omitted
  a race test as too narrow. The director passed it to review without deciding it. Both reviewers
  found it at 12:21:05 and 12:21:46, producing one fix round. PR 26's residual was decided and
  fixed before review. The round 12 ruling makes the director decide the named residual before
  review, fixed in the change or accepted as a known limit with a reason in the decision log,
  rather than pass that decision to reviewers. Confidence low, two contrasting cases.
- Probe across the stop. Both reviewers passed their 80K brief stop by one probe between readings
  of `keryx who`, from 76K to 82K and from 73K to 83K. They stopped and reported what they had;
  the first left the full remote-kind matrix unchecked for the recheck. The recheck brief set
  70K with the reason that one probe had taken a reviewer from 76K to 82K. Its readback and
  confirmation carried the stop. It stopped probing at 70K, reported progress at 12:38:19 stamped
  71K, ran the final suite of 709 runs and delivered at 76K at 12:40:20. One remote withdrawal
  case stayed open because the probe looked in the wrong directory; unit coverage did not
  replace that remote run. This is one held stop with a reason, against two crossed stops here
  and the earlier PR 24 and PR 26 cases. The round 12 ruling keeps the mechanical 80% notice
  and no separate brief stop, leaving one probe's cost between notice and required end of work.
  Confidence low; the held stop does not validate a separate brief threshold.
- Question during the fix. A probe showed that the director's premise about retirement during a
  spawn hold held only when spawn carried a request. Without one the reported exits were retire 0,
  join 1 and spawn 3 after timeout; with one they were retire 1, join 0 and spawn 0. At 12:25:12
  the implementer sent options A, B and C as an untagged request while continuing the asked fix.
  The director chose A twelve seconds later, stopping spawn's wait on the retirement marker in
  a second commit. Both windows closed in one fix round, a98cbd1 and 1310dc1, and the recheck
  found no must-fix. One more untagged question after PR 24's two; it supports asking while
  independent work proceeds, not an exception to 5.2's tag convention. Confidence low.
- Undecided suggestion at merge. The fix result at 12:30:45 named `spawned.json` beside
  `retired.json`, a departure from point 3 of the recorded plan decision. The rechecker reproduced it,
  found that revival on the same socket, pane and harness inherited the old director, and
  suggested documenting or removing it. The director's 12:42 log entry recorded the suggestion
  and the merge, with no decision, and the field reporter's queue search found no row. The merge
  was at 12:40:49. The round 12 ruling requires a recorded decision before merge for each
  reproduced suggestion and each named departure, fixed, accepted with a reason, or queued with
  its row. One case, confidence low; merging was not a decision on this known departure.
- Tool change notice. The delivery named the new `who -o json` object with `view`, `hidden` and
  `addresses`. A reviewer checked callers, docs and skill. At 12:41:27, 38 seconds after merge,
  the director notified the protocol owner and named the bootstrap consumer. The reporter found
  the new shape in the protocol's tool note and digest by file modification time 12:49:44 UTC.
  One observation of informing a dependent owner; it does not establish a notification rule
  under protocol 9.6, which requires announcing disruptive upgrades beforehand and checking bells. Confidence low.
- Missing tags. All five briefs lacked a convention section and all 29 counted messages lacked
  bracketed tags. Both implementer sessions sent neither [accept] nor [progress]; the two
  reviewer progress messages also lacked request ids and required hand recovery. This is an
  association observed in one change, not evidence that omitting the convention caused the
  omissions or that the tag rule should change. Confidence low.
- One director through merge. The director's message stamps rose from 242K at 11:51:09 to 300K
  at 12:41:27 under a 420K ceiling, about 58K in fifty minutes including other work. It swapped
  after merge at 308K; the successor joined at 12:43:50. This is a third operational instance
  of the 1M-window ceiling rule holding, with PR 24 and PR 26, and no swap within this change.
  Confidence medium for the three reported completions, low for wider effects; there is no
  quality or quota comparison. The 1M figure names the window rule, not this director's ceiling.

Counts and dated observations are sourced field evidence. This writer did not repeat the mailbox
census, probes, spawns or context measurements. Confidence is low beyond the reported cases unless
a narrower qualifier above says otherwise.

### 2026-10-23 09:43 UTC-3, address retirement and list shape

The director's log reports keryx 0186dcd (#27), installed at about 09:41 UTC-3, with `retire`
and a short view for `who` and `status`. The old heartbeat parser expected an array from
`who -o json`; it was changed to `.addresses[]` with `--all` and passed shellcheck. The log
records 28 addresses retired across the team and its three acceptance tests, every command
successful and the files retained. These are the director's observations, not retirement tests
repeated by this writer. Confidence low beyond this one cleanup batch.

The writer checked the local checkout at 0186dcd, command help for `retire`, `join`, `who` and
`status`, and read-only JSON output. The list object has `view`, `hidden` and `addresses`;
`.addresses[]` selects the records. The short view omits only addresses with no holder, no unread
mail and no open request in either direction; `--all` includes those inactive addresses.
`retire ADDRESS` refuses a live holder or an open request sent or received. Retired addresses
refuse mail, remain absent even with `--all` and retain their files; `join NAME --revive`
restores the mailbox. The refusal and restoration behavior is grounded in the local help and
code, not a mutation test by this writer. Retirement is a command under the delegation record,
not permission to clean up another team's addresses. Evidence for R07 and the list consumers in
`keryx.md`, bootstrap 10 and playbook, Cleanup.

**2026-10-26, team files.** One team's directory became the first instance of the agreed team layout
at 07:31 UTC-3. It added roster.md, roadmap.md and progress.md without moving existing files. The
roster held members, roles, harness and model, ceiling, pane and state, plus a launch profile; the
roadmap held phases, what was asked and their state; progress held one row per principal ask,
when it was asked, where it stood and what it waited on. The protocol team agreed to adopt those
file and field names unless one contradicted a protocol term; none did. Its forms keep them and
assign updates to the orchestrator when those facts change, before reporting or handover. Progress
points to work items and decisions kept under 5.5, since a transport reply closes a request without
necessarily finishing the work (N16). Confidence low, one instance; the new forms have no fresh-user
acceptance test yet.

**2026-10-26, bare block.** An orchestrator's result to the principal put its block's JSON object
bare on line 2, without the `nomos` fence, then text and the human-message footer. The principal's
page found no block on line 2, showed the JSON and the footer as text with its amber note, and the
principal called it an error. The contract and the page both held; only the page checked, after
delivery. It taught that a form a sender claims (a footer, a fence, a `{"kind"` line) must be checked
before sending, and that the hook should flag the page's note rather than guess the sender's
intent. The pre-send hook now flags that shape as `block placement`. Confidence low, one message.

**2026-10-26, a "by when" flagged.** An orchestrator's commitment, "I will deliver the plan by" a
same-day time in UTC, made the pre-send hook exit 1 with `future time`, although 5.3 asks for that
future deadline; later calendar days were already exempt. It taught that the clock comparison needs
the word that governs the time: a deadline word marks a future time as intended, while a stamp word
such as "at" or "sent" still marks an event that cannot lie ahead. The hook now exempts the first and
keeps the flag for the second. Confidence low, one case.

## Decisions, requirements and rulings

### Charter decisions

The principal's decisions on the nomos work and the orchestrator's rulings within them.
N01 to N05 are of 2026-10-22; later entries give their dates.

**N01.** The principal agreed to a separate layer of conventions and practices beside keryx, in
three layers, the protocol, the playbook and the harness notes.

**N02.** The principal asked the orchestrator of the keryx round to compact and become the
orchestrator of this work, to pick its own team and to choose every name, nomos included.

**N03.** The initial draft was to stay in private working notes pending the principal's
repository decision. This records the earlier decision, before nomos became a public project.

**N04.** The principal asked for a naming standard where the address carries the project as well as
the role, to be worked out with the keryx team (L14).

**N05.** The principal agreed with the orchestrator and the keryx team on R01, that the team is
part of the address's identity, that ambiguous or cross-host bare names are errors, that old
addresses are retired rather than renamed, and that the grammar lands before keryx 0.1.0 is
published, as its own pull request.

**N14.** On 2026-10-25 at 16:30 UTC-3, the protocol team moved to project-named team
addresses at the principal's word. Its orchestrator initially repeated the project in the member
segment. N15 replaced that choice two minutes later.

**N15.** On 2026-10-25 at 16:32 UTC-3, the principal preferred orq.nomos and asked the
protocol team to define names by role. The team segment names the project and the member segment
the role. The writing brief of 2026-10-26 records the orchestrator's ruling for short role names
with instance numbers, orq for the single orchestrator, and the full word in the transport's role
field. See the role-names LOG case.

**N16.** On 2026-10-26 at 06:56 UTC-3, the principal decided that a request closes when
answered and that work state belongs to the project layer, leaving agents' use of requests to
nomos. The orchestrator ruled that the request states what its reply must carry. A result request
gets a result; a request for later work, or work requested by a human, gets what will be done and
by when, with the result following as a message naming the request. The requester keeps work
items in its checkpoint until the project layer holds them. See the request-replies LOG case.

**N17.** On 2026-10-26 at 10:55 UTC-3, the principal sent every orchestrator the same words.
They did not want messages that only announced a handover unless the change needed them, and each
orchestrator was to handle its own sessions' dialogs. Earlier that day the principal had answered
Codex hooks dialogs for three sessions of this team. Renewals, handovers and context figures stay
in the run log; the principal hears only a question, decision, changed commitment or other matter
that needs them. The orchestrator answers dialogs under the principal's standing rules, such as
"Continue without trusting" for Codex hooks, and brings them only uncovered dialogs. The team's
ruling of 11:01 UTC-3 accepts a relayed copy for what narrows and grants nothing; trusting a hook,
allowing a permission or changing a setting still needs the principal's word. This keeps routine
session care with the orchestrator without widening its authority. Confidence low, one standing
instruction after three dialogs; no new field test of the remedy.

### keryx requirements

What nomos asked of keryx, the transport. At the first reading (0.1.0, commit 9e3a313), none was
implemented. By the 2026-10-23 reading at fde5548, R02, R09 and R10 had entered keryx at the
commits recorded below. That update checked
`keryx help withdraw`, `keryx help join`, `keryx help spawn`, `keryx who` and `keryx status`, and
read notice routing in `lib/keryx/courier.rb`. This establishes help, display and code behavior,
not an executed withdrawal or threshold-crossing test.

The capability check of 2026-10-25 at main 2f599dc also records R07, R11 as narrowed, R13 and the
filtered directory view as delivered. The version string remains 0.1.0, so the commit identifies
this baseline. The check compared installed help and source, traced the introducing and merge
commits and located tests; it ran no tests. The updates below are sourced from that check, not
live exercises by the writer. `keryx.md` maps this baseline to the protocol rules.

**R01.** A team segment in addresses, with short names resolved inside the sender's team, errors
for ambiguous and remote short names, and reserved scopes for parties with no team. The keryx team
answered that it is a wire change, so both machines upgrade together, that new names start fresh
while old addresses are retired, and that the grammar should land before 0.1.0. The principal
agreed (N05). On 2026-10-23 the keryx team accepted the exception for senders in `local` or
`system`, which have no team. Their bare MEMBER resolves only when exactly one MEMBER.TEAM exists
on the host; otherwise it is the same listing error. This is an accepted design for protocol 3.6,
still not implemented in main at 2f599dc. R01 and R08 were in progress on a separate branch at
that historical point. The reserved-scope behavior was rechecked in keryx 7debfde (#38), merged on
2026-10-26 at 09:44 UTC-3. Its join and spawn reject all reserved addresses, and its identity
check refuses an agent acting as one. f1a9063 names the terminal path for the caller's own or
another person's local address; 515b178 defines a test of send --on from a terminal and its
refusal to an agent. These are source and test-definition readings, not live probes. The keryx
binding records this revision separately from its general baseline.

**R02.** Withdrawing a request, already in the keryx team's next batch on 2026-10-22, since stale
requests made an implementer's stop hook block every turn (L10). Delivered in a5157e6 (#19), `keryx
withdraw ID [TEXT]` closes the obligation and rings the recipient; a late reply still arrives.
Withdrawal does not itself prove the worker stopped acting.

**R03.** A handover message kind that `keryx inbox` shows first and `keryx join` mentions, sent
with the protocol draft. Still open at 2f599dc; a handover travels as an ordinary request.

**R04.** `keryx spawn --takeover`, and spawn waiting for the new session's readback rather than
only its join, sent with the protocol draft. Still open at 2f599dc; spawn waits only for the join.

**R05.** A delegated orchestrator, changes to a delegation record and revocation, stated in the
skill's Authority section, sent with the protocol draft. Still open at 2f599dc; that section
still describes only the user and a peer.

**R06.** How keryx knows nomos without depending on it, through a config path, spawn composing the
first prompt from a role file, and the skill pointing to it, sent with the protocol draft. The
request of 2026-10-23 widens R06 to four items, (1) a config path naming the conventions directory,
(2) spawn composing the first prompt from the member card, role card and delegation record, (3)
`keryx skill` printing the member-card path when configured, and (4) an opt-in check on `send`,
`ask` and `reply`. The triage decision defers items 1 and 3 until after the release, item 2 to a
later design of safe first-prompt delivery, and declines item 4 for now as a new trust boundary.
None is a feature at 2f599dc.

**R07.** Retiring an address, raised by the keryx team's answer to R01, since unused addresses pile
up and a move to team names needs the old ones retired. Introduced in f3182c6 and merged in
0186dcd (#27), present at 2f599dc, with retirement
refusing a live holder or open request in either direction, files retained, mail refused and `join
NAME --revive` restoring the mailbox. See LOG, 2026-10-23 09:43, address retirement and list shape,
for the reported cleanup and the writer's read-only checks.

The filtered view was introduced in 8262ea4 and merged in the same 0186dcd (#27). At 2f599dc,
`who` and `status` hide addresses with no session, unread mail or open request in either direction;
`--all` includes those addresses but never retired ones. The capability check located the refusal
and revival tests in `test/cli/retire_test.rb` and the view tests in `test/cli/short_view_test.rb`.

**R08.** Addressing an incarnation, a selector such as MEMBER.TEAM@HOST/SESSION delivered only to
that session while it lives and refused after it leaves, designed with R01. A protocol writer
raised it on 2026-10-22, since `keryx join --force` moves the address and leaves the old session
with none. Still open in main at 2f599dc, in progress on the same branch as R01.

**R09.** Reading each session's context and showing it in `keryx who` and `keryx status`, with the
sender's figure stamped on each message, so that keryx measures and decides nothing. The principal
raised it after a night where a few nomos sessions ended by context and none of the Codex or Cursor
ones could see its own figure (LOG, 23:15). Delivered in 60b1abb (#20); `who` and `status` show a
CONTEXT column and messages a session sends from its own address carry the sender's figure; a send
with `--as`, from a terminal or from the courier carries none. An unavailable measurement is unknown.

**R10.** A context ceiling per session, set in tokens at spawn or join, with the courier telling
the session and its spawner when the figure nears and passes it. In a Cursor session the bell for
the notice can wait for the end of the turn, while the notice is already in the mailbox for
`keryx inbox` and `keryx read`. Delivered in fde5548 (#21); `join` and `spawn` take `--ceiling TOKENS`,
and the courier notifies at 80% and at the ceiling. The director is the spawner, else the sender of
the oldest open request; with neither, only the session is told. The director still arranges the
checkpoint and handover.

**R11.** The decision of 2026-10-23 narrows the request to a last-activity column in `who` and
`status`. Introduced in d7b5502 and merged in da068ef (#28), present at 2f599dc. The ACTIVE
column reports when the harness last wrote its session record; JSON gives `last_activity` as a
UTC time or null when unknown or ended. This is not a liveness check or proof of progress.
The capability check located the display and JSON tests in `test/cli/activity_test.rb` and
the harness readers' tests in `test/unit/meter_activity_test.rb`.
A notice that a session has stalled remains in the orchestrator's routine, built on
`keryx who -o json` and the checks in the playbook's "The director's heartbeat". The column is not
present at the historical fde5548 baseline.

**R12.** The decision of 2026-10-23 does not ask keryx to track each session's pool. Knowing the
pool and that it can run out stays in the director's routine, including when sessions share it
(LOG, 2026-10-23 02:28; playbook, The director's heartbeat).

**R13.** A message in a request's thread through `keryx send --re ID`. Introduced in 00849e5 and
merged in da068ef (#28), present at 2f599dc. Only the recipient of an open request can use it.
Once the recipient sends such a message, `status` shows the request as taken and the stop hook
does not remind of it; no tags are parsed. The request stays open until a reply or withdrawal.
An answered or withdrawn request refuses `send --re`. The keryx team took the proposal, and the
principal approved it in the triage decision on
2026-10-23 at 04:17 UTC-3, after R07. It addresses the premature terminal reply in field PR 22.
The capability check located the thread, taken-state, stop-hook and refusal tests in
`test/cli/thread_test.rb`, plus the cross-host taken-state test in `test/cli/machines_test.rb`.
Those tests were not rerun for this update. Confidence low for the proposed remedy to that field
case; the capability check establishes the implementation, not a new field test.

The keryx team's triage was approved unchanged on 2026-10-23 at 04:17 UTC-3. After the audit fixes
and the spawn task, the order is R07, R13, a `who` and `status` view hiding addresses with no
holder and no mail, R01 with R08 as one grammar and wire change, then R05 as skill text, before the
0.1.0 release. R11's last-activity column follows the spawn task. R03, R04 and R06 items 1 and 3
wait until after 0.1.0, decided by field evidence. R06 item 2 is later, designed around safe
first-prompt delivery, since a first prompt in argv is readable by local processes and limited in
size; cards travel by path. R06 item 4 is declined for now because a check on every message adds a
trust boundary. Reopen it only with field evidence of a mechanical error it would have caught. This
records the team's accepted order, not delivered features or a measured benefit.

### Rulings

The orchestrator's choices where the sources pulled against each other, given to the protocol
writer on 2026-10-22 and revised for 2, 7 and 10 after the first adversarial review.

**Ruling 1.** Authority is a declared delegation record carried by the first prompt, never extended
by a peer's message, and declared permission is kept apart from the harness's technical capability.

**Ruling 2.** An action the delegation record grants is done and reported without asking again, an
action inside the task but outside the record is decided by the delegate if it is reversible, and
an action outside the record, irreversible or reserved to the principal is proposed first, while a
message never makes its sender wait. This replaced an earlier two-case version. That wording is
historical. The corrected reading in force in protocol 4.8 lets the delegate decide a reversible
act only within both the categories of action and the resources already granted, with no reserved
decision, even when the act is not individually named. Merely naming a resource grants no new
category of action.

**Ruling 3.** Messages keep the transport's kinds and add a small vocabulary on top as conventions,
with work state kept apart from session state and silence never taken as assent.

**Ruling 4.** Evidence is a taxonomy of observed, code-grounded, sourced and hypothesis, and a
filtered or truncated search never supports a claim of absence.

**Ruling 5.** Findings stay ranked must-fix or suggestion, a must-fix blocks the merge, a round cap
never justifies merging a blocker, and at least one review lens is blind to the earlier findings
and the principal's framing.

**Ruling 6.** Fresh sessions are a means stated by their reasons, and continuity across review
rounds of one change is allowed.

**Ruling 7.** A handover is a two-party transfer in which ownership moves when the outgoing side,
or the director if it is gone, confirms the incoming session's readback, with each open obligation
listed with its holder after the cutover.

**Ruling 8.** Context renewal has no universal percentage, only an external checkpoint and a
criterion per session set by its director, who measures when the harness hides the figure.

**Ruling 9.** The orchestrator reads reports, not transcripts, and the traces stay on disk so a
decision's evidence can be retrieved later.

**Ruling 10.** The identity is the pair of team and member, unique across every host the team spans
and kept unique across hosts by the director, while the host is the route and every message carries
the full address.

**Ruling 11.** Normative force is kept apart from confidence, with BCP 14 keywords only where
interoperability needs them and a trace and confidence on every rule.

**Ruling 12.** A rule that can be checked mechanically says how, through a hook, a skill, a first
prompt or a template field.

## Checking that every cited id resolves

Run the maintained check from the repository root:

```bash
ruby tool/check-evidence.rb
```

It resolves cited ids and ranges against entries here and HN entries in `harness-notes.md`, rejects
unknown id families, and checks LOG labels against dated entries and field headings or their item
labels. A bare LOG refers to the incident collection. It prints each unresolved citation with its
file, exits 1 on failure and prints nothing on success. This checks references, not the truth of a
case or the absence of private facts.
