# nomos playbook, version 0

Version 0, dated 2026-10-23. The protocol says what sessions owe each other. This playbook says
how a team does it well, with the defaults the first teams used and the incidents behind them. It is
opinionated and expected to change. Where a practice here disagrees with the protocol, the protocol
wins and the playbook is wrong.

## How to read the traces

Each practice tells its incident in place, so the playbook reads without any other file. It ends with
its trace and confidence, such as (P02, M35; medium). L, P and H are the lessons of the first keryx
round, M the candidates mined from other agent work, S public sources from the research, and LOG the
log of the run that wrote nomos. Each id resolves in `evidence.md`, which holds the sanitized rule,
incident and reason of every entry cited here. Field pull requests are in the public keryx
repository, `github.com/hvpaiva/keryx`.
Protocol rules are named by their section title, such as "the protocol's Reviews", since their numbers
may move. Facts about a tool at a version are in `harness-notes.md`. Machines, accounts, quotas and the
principal's own writing rules are the local layer, which every team writes for itself (see
`bootstrap.md`).

Confidence uses the protocol's terms, high, medium and low, for how often the incident held and in how
many settings. Two more labels keep a claim from borrowing that confidence. A default is a number or a
choice the first teams set and nobody measured against another, such as a ceiling or a wait; it is a
provisional convention. A hypothesis is a reading of why something happened that the evidence does
not isolate.

Where a count came from a private setting, it is replaced by one of these words, and only these:
once, a few (two to four), most (more than half), fewer than half, every time. Counts from the first
keryx round and from the run that wrote nomos are kept as they were.

## The stance behind the defaults

- Quality comes before cost. A seat moves to a cheaper model only with evidence that its quality
  holds, and cost is cut first by cutting context and empty wake-ups. A cheaper orchestrator was
  declined once; the measurement the same day showed the spending was context, not the model.
  (M19; medium for the incident, and untested whether a cheaper model would have held)
- Seats exist per task. A session starts when a task needs it and leaves when the task is accepted,
  unless its context is what the next task needs (see "Seats per task").
- Parallelism comes from independent tasks, never from cutting one task finer to keep seats busy.
- The orchestrator directs, verifies and keeps the record. It does not build.
- State lives in files, so a compaction, a crash or a handover loses nothing.

## What a delegation record usually reserves

The protocol asks every record to name the decisions reserved to the principal (protocol, Roles,
principals and the delegation record). The first teams reserved publishing and releases, tags,
repository, account and personal settings, choices others will maintain (the language, the runtime,
where the code lives), anything outside the approved plan, disruptive actions on shared machines, and
logins and credentials, which the team asks the principal to renew and never renews itself. Use it as
a starting list and adjust it in the local layer. Name merging in every record, reserved or granted,
since the merge rules need to know which. (L12, M12; medium, low for choices
others will maintain)

Name whether the orchestrator may remove the team's merged branches and worktrees. A grant to merge
alone does not grant cleanup. Without a cleanup grant, leave them in place and propose their removal
to the principal, naming the resources. (LOG, acceptance 1, stumble 12; low)

A delegation record names whether the delegate may answer harness trust and approval dialogs, and
for which directories. A folder trust answer writes the harness's configuration outside the workspace;
permission to work in that folder alone does not cover the write. Name the configuration effect in
the grant or reservation. The acceptance-test leader escalated Codex's dialog and reported an earlier
Claude Code answer outside its record under protocol 4.9. (LOG, 2026-10-23 04:49 UTC-3; low; protocol 4.3,
4.7, 4.8; harness notes HN02, HN20)

The root record names the mode members start in for each harness, including sandbox and approval
policy where separate, and who may apply it. The spawner carries that choice into the launch;
technical access never widens the record. A sandboxed Codex seat needs write access to the resolved
keryx store, outside its worktree, to join, read and reply. Include that directory in the approved
writable roots before launch and check a reply from the seat. If it is denied, report the denial
under protocol 4.7; the member does not change its own mode. (LOG, acceptance 1, stumble 3; low;
harness notes HN12, HN20, HN26)

## Team recipes

Every recipe has one orchestrator, which holds the team's delegation and its one channel to the
principal (protocol, The human). Members are spawned for a task with a brief and leave when the
orchestrator accepts the result. A role is chosen by what it needs, then a harness and model that
provide it. In the first round the implementer and the writer ran a Claude model at extra-high effort
in Claude Code, the reviewer and the auditor an OpenAI model at maximum effort in Codex, and QA and
the miner a model in Cursor on a separate quota pool. This is a recorded example; choose from your
models and pools by the role's needs. "The strongest model" in the tables below is a default nobody
compared against a cheaper one. (P01, charter; default)

### Building a feature

| Role | Needs | Joins | Leaves |
|---|---|---|---|
| Orchestrator | Long context, judgment, cheap reading of reports | Before the team | After the merge and the record |
| Implementer | The strongest coding model you have, high effort, its own worktree | With the brief | When the change is merged |
| Plan reviewer | A reader of designs, any vendor; QA partner or a separate reviewer, never the blind code reviewer | With the implementer | After its plan review |
| Reviewer | A strong adversarial model, a fresh session, another vendor as one option | When the change is open and green | After it has verified the fixes |

1. The orchestrator writes the brief from `templates/brief.md`, with the hazards of the machine and
   the isolation of live tests (see "Live tests and shared trees").
2. The implementer sends its plan to the plan reviewer and waits (see "Plan review before code").
   Keep that session separate from the blind code reviewer; it has read the implementer's framing. The
   orchestrator may skip plan review for a small mechanical change with no new design, interface or
   failure-path decision, only when the record and brief permit it. Put the skip, its scope and
   reason, and the record that allows it in the implementer's brief before implementation, so the
   implementer does not reopen the plan review procedure, and report the decision. This never skips
   the independent code review or merge gates. (protocol 4.8, 8.4, 8.5; LOG, acceptance 1, stumble 2;
   low for the skip criterion) The skip did not reach an implementer's brief in one run.
   (LOG, benchmark run; low)
3. The implementer opens the change and replies with the report.
4. A fresh reviewer reviews it blind (see "The review recipe"). Its brief says it stays to verify the
   fixes, since a reviewer told only to leave at the end of its task leaves before the fixes exist.
   (M02; medium)
5. The orchestrator reproduces each must-fix, sends a fix request, verifies, and then merges or asks
   for the merge by the merge rules.

Done means the change is merged under an authorization that covers the merge, every must-fix probe
passes on the merged revision, the probes are saved in the run's files, and every member has left. In
the first round the reviewer found two to four real defects in each change. (P01, P03, L08; high for
the reviewer, medium for the rest)

### Reviewing someone else's change

Use one blind reviewer and, when the change has history worth knowing, one informed reviewer. The
blind one gets the requirement, the change and the safety constraints only. The informed one also gets
context the orchestrator has verified, marked as such ("already verified, use it, do not rediscover
it"), such as existing reviews, bots whose approval does not count, and the order of a stack. Neither
sees the other's verdict until both are in. Nothing is posted outside the team unless the record
grants it, by category or by name, or the principal approves that act by name (protocol, Roles,
principals and the delegation record). Done means the findings are measured by the orchestrator and
either published under that grant or approval or handed to the principal.

A coordinated review round of this shape ran once, with one coordinator and several reviewer
sessions. Once the coordinator relayed every question, the principal got fewer than half as many as in
an earlier round where each reviewer asked directly. A literal confirmation token required before
every publication held each time and stopped one near miss, including a wrong correction by the
coordinator. No team has yet run a blind and an informed lens on the same change, so whether the
coordinator's own verification replaces the blind lens is open. (M13, M14, M36, M37; medium for the
token and the single channel, low for the pair of lenses)

### An audit

One auditor, fresh, of a different vendor from the implementers when you have one, blind to the
changes it audits. It audits a revision nobody writes to, in a temporary clone, and names it. It
writes its findings first, records their hash and the time, and only then opens the earlier audit to
check each earlier finding for regression. A response to the audit is audited too, since one fix in an
earlier cycle made a proof citation more precise and more false. `templates/audit-brief.md` has the
form. Done means every finding is reproduced or labeled a suspicion, and the orchestrator has a
triage list. The first blind audit found fifteen findings. (P09, M04, M32; high for blind first,
medium for the rest)

Split an audit of more than about three heavy areas by area across auditors from the start, each
with its own progress file and coverage map. Keep both current after each finding from the start;
they are the condition of the read-heavy ceiling for its window in "The ceiling". (LOG, field audits
of fde5548; LOG, 2026-10-23 about 08:12 UTC-3, 1M ceiling; low)

### Research

One researcher per independent question, in a harness with web search, started in parallel with any
miner. Each source is cited at the place that says it, and the report says what it could not reach.
Prior art that the team's lessons contradict is reported, not hidden; the first survey found a
published recommendation against the orchestrator reading summaries only, and the protocol reconciled
the two instead of choosing one (S08, protocol, Reports and evidence). Done means a ranked list of
findings and a mapping from the team's lessons to the sources. (S07, S08; medium)

### Writing documents

The run that wrote nomos supplies this example.

| Role | Needs | Joins | Leaves |
|---|---|---|---|
| Evidence miner | A reader of large private material, any vendor, a hard context ceiling | First | At its handover or its report |
| Researcher | Web search, careful citation | First, in parallel with the miner | At its report |
| Writer | The strongest writing model you have | When mining and research are in | At its report or its ceiling |
| Adversarial reviewer | Another vendor, maximum effort, one lens per session | After the first draft | At its findings |
| Fixing writer | A fresh writer | After the review | At its report |
| Fresh user | A clean session with no memory of the work | Last | After the acceptance test |

The miner copies a rule, an incident and a reason, never the private source, and the orchestrator
gives the writer the sanitizing shapes for anything from another context. A second miner took over
from a handover note at the ceiling and finished the mining. A reviewer at maximum effort can read to
its ceiling before it writes, so the orchestrator sizes each review session to its window and splits
the review by lens, a blind pass in one session and a pass against the brief's choices in another
(see "Context policy"). Done means the documents exist, a trace accounts for every input, the review's
must-fix findings are resolved, and a fresh user has run the acceptance test (see `bootstrap.md`).
(LOG, N01; low, seen once)

## Routing across vendors and quota pools

Route a role first by what it needs, then by the pool it draws from. Keep in the local layer which
pool each of your accounts draws from, how full it is, and which harness shows it.

- A reviewer from another vendor is worth trying. The first round's reviewer ran on another vendor
  from the implementer and found real defects in every change, each with a failing test, and in
  another setting two reviewers from different vendors each caught defects the other did not, while
  a review of a whole piece by a reviewer of another vendor caught a defect between parts that every
  per-part review had passed. Research backs independent review through self-preference bias in
  judges, but not a rule that the vendor must differ. (P01, M35, M36, S18, S19; medium)
- A QA seat beside the implementer caught little in two settings. In the first round a QA partner on
  another pool found none of the eight code defects the reviewer reproduced across two changes, and
  was useful once on a plan and once on two wrong facts in an architecture paragraph. In a second
  setting a QA seat of a different vendor issued no reject in about nineteen runs and raised one test
  gap, while the two reviewers rejected five of thirteen parts each. The model changed between the
  two settings and the result did not, which points at the role or its timing more than at the model.
  That is a hypothesis, since the task, the seat's access to evidence and its moment changed as well.
  Use QA where it has paid, on a plan, on the facts of a document and on a missing test, read an empty
  QA review as weak evidence of no defects, and do not keep a seat because a pool has room. A later
  comparison should record each role's goal and access before it counts rejects. (P02; medium for
  the record, hypothesis for the cause) When QA probes extreme inputs, record each probe's run time
  alongside its result and report a correct but slow result as a suggestion, so a costly path is
  visible. One benchmark found such a path despite correct output. (LOG, benchmark run; low)
- Send bulk reading (transcripts, logs, large notes) to a pool you can spare, and decide on the
  reader's summary with the strongest model. A summary that lacks its context arrives looking like
  an answer, so the summary carries its sources. (P04, S07; low)
- Route one class of work to another harness by account boundary when a pool runs short. One
  principal drew the line by how a task ends. A task that ends in a command run and its output read
  went to a harness on another account, and a task that ends in code someone will maintain stayed
  with the strongest coding model. It is a rule by the shape of the work, not by model strength. (P06; low, seen once as a decision)
- A pool is drawn by every session on the account at once, so a parallel batch spends it in a burst,
  and a tool's rate limit is a pool too. Check how full each pool is before a batch. (P06; low)
- A usage limit that cuts a session mid-task can kill a background subtask with it, and the harness's
  own notes about the limit can tell the model to finish early or not to repeat finished work (HN33).
  After the reset, check what each subtask finished and rerun what died before you accept the report,
  and read a report written near a limit as possibly shorter than the work. (P06, M49;
  low)
- Some harnesses do not show which account a session draws from (HN22), so record the account in the
  spawn command and the run log. (P06; low)

## Plan review before code

Use Building a feature's recorded skip criterion when it applies; otherwise the plan reviewer starts
with the implementer. That session never supplies the blind code lens, even if it reads later commits.
(protocol 8.4, 8.5; LOG, acceptance 1, stumble 2; low for the clarification)

The implementer sends its plan as a request in the form
of `templates/plan-review.md`, covering the classes or modules it changes, how each failure path works
and which tests cover what. It waits up to fifteen minutes, then proceeds and says so in its report;
a timeout is never approval (protocol, Reviews). The plan reviewer answers with agreement or ranked
findings, then leaves unless its brief asks it to read later commits. In the first round a plan review
caught a real design gap in a race fix before any code, while the same seat reviewing finished code
added almost nothing. (P02; LOG, field PR 27, plan before code; medium for the timing, low for
one more plan decided before code, default for the fifteen minutes)

## The review recipe

The protocol's Reviews sets the contract, which is ranking, blocking, independence, reproduction and
the history of rounds. These are the choices that carry it out.

- One fresh reviewer per change. Reusing a reviewer across changes carries its reading of the last
  one; fresh reviewers found new defects every round. A fresh context after a clear, with a new brief,
  worked once in place of a fresh process. The same reviewer stays for the rounds of one change, since
  it checks its own findings. (L08; high for fresh per change, low for the
  variants)
- The blind lens gets a brief that says "review against the documented contract, not against the
  summary of whoever produced the work", and no summary, description, commit messages or earlier
  findings. In one change, every agent review pass read its description and earlier findings, and
  none asked whether the fix addressed the cause; a human reading the raw code found the cause
  quickly. Code that looks intentional is where an anchored review stops looking. (M13; high)
- The unit is one change with one purpose, or a stack of dependent changes reviewed in order as one
  unit. A rig that reviewed every small part of a piece with a fresh reviewer paid for a fresh
  session per accepted part, and the first review of the whole piece rejected it for a defect
  between parts that every per-part review had accepted. (M35; low)
- Parallel reviewers record their verdicts before they see each other's. One reviewer turned an
  acceptance into a reject 77 seconds after the other's reject, which looks like anchoring and was not
  checked. (M36; low)
- The reviewer writes a failing test or probe for each must-fix when one is feasible, and lists their
  paths. Every must-fix that came with a test reproduced in the first round. In a coordinated round
  without tests, the reviewer was right against the coordinator once, and corrections were measured
  in both directions before anyone relayed them. (L03, M15; high for the tests, low for the round
  without them)
- The orchestrator reproduces each must-fix itself on the candidate revision, in a scratch worktree
  with the transport's variables unset and a temporary store and config. It copies the probes into
  the run's files, since they live in temporary directories. One review skill sends each draft finding
  to a validator that reads the file at the head commit and answers confirmed, wrong line, false
  positive or unclear. (P03, L03; high for reproduction, low for the validator)
- The brief says that an empty result is valid (protocol, Reports and evidence), since a reviewer that
  must return something invents a finding. (M46; low)
- A defect a review finds is the team's to fix whatever its origin. The origin decides which change
  takes it, never whether it is fixed. A race older than the change under review was taken into that
  change. (M24; medium)
- The findings of every round stay verbatim in the run's files, so each new version can be checked
  against all of them. Points from earlier reviews came back "in another guise" once when only the
  last round was checked. (M25; medium)
- A seat never judges the value of its own role. An analysis of a rig's seats written by one of the
  seats concluded no seat should go, and an outside verification at the primary sources reversed its
  main conclusions. (M32; low)

A partial review is not a pass. Give its unchecked list to a fresh reviewer before merge. On PR 25
the first case of the successor's list found a must-fix after a partial review had found none.
(LOG, field PR 25, partial review; low)

Review style depends on the setting. Code before a merge gets an exhaustive list of must-fix findings
with tests. A peer's document gets few, high-signal points in a suggesting tone. The team's own
normative documents, such as this one, get an adversarial pass that attacks evidence, generality and
contradictions, ranked like code findings. (E01; low)

A recheck brief states the corrected expectation for each probe written to assert a defect. Do not
ask to rerun it unchanged or expect exit 1 as proof of the fix; an assertion can stop the script
before later cases run. Preserve the original and identify any adapted copy and its changes, so
all original cases can be checked on the candidate. (LOG, field PR 25, defect probes; LOG, field
PR 26, recheck probes; low)

Send one fix request per pull request for the round, carrying all its must-fixes after all reviews
are in. Before review starts, the director decides each residual the implementer names, either
fixed in the pull request or accepted as a known limit with its reason in the decision log. Do
not pass that decision to reviewers. Repeated fixes on PR 24 paid for two fresh sessions; PR 26
combined the next findings and reviewed a residual with its fix. PR 27 passed a named residual
undecided to two reviewers; both found it as a must-fix. This batches a round, not future findings
that do not exist yet. (LOG, field PR 26, fix batches; LOG, field PR 27, residual before review;
low, two contrasting residual cases; LOG, field PR 27, handover at delivery; low, one more
fix sent to a fresh session from a delivery handover)

PR 24 supplied two review observations, one case each. A check-then-act race took three fix
rounds that repeated or moved reads before a lock over the final check and clear closed it.
A remaining lock-duration limit was named by the implementer, accepted for now by the director
and measured by the reviewer, with a concurrent join failing loudly and a later retry succeeding;
it caused no further fix round. These are observations for the review recipe, not new rules.
(LOG, field PR 24, review race and measured limit; low, one case each)

## Merge rules

A change merges when the quality gates hold and the delegation record covers the merge. The
orchestrator checks each one itself.

1. Every must-fix is reproduced, fixed, and its probe passes on the head, together with the probes of
   every earlier round. Each suggestion a reviewer reproduced and each departure from a recorded
   decision that a result names has its own recorded decision before merge, fixed, accepted with
   a reason, or queued with its row. Merging is not that decision; no disposition waives a
   must-fix. (LOG, field PR 27, undecided suggestion at merge; low, one case)
2. The continuous integration checks are green on that head. When there is no CI, the orchestrator
   runs the gate commands named in the brief on that head in a clean worktree and records the
   revision, commands, outputs and exit codes; all must pass. (LOG, acceptance 1, stumble 11; low)
3. The commits carry the signatures and trailers the repository requires and no attribution the
   principal forbids. Name the base in the brief, `origin/main` with an origin remote, otherwise
   local `main` (or the repository's actual branch).
   `git log --format='%h %G? [%(trailers:only,unfold)] %s' BASE..BRANCH` shows both after substituting
   that base; a local-only run needs no remote or pull request. (LOG, acceptance 1, stumble 1; low)
4. The change's text has no internal ids, addresses, run names or private notes.
5. The record covers the act. When the orchestrator's record grants merging, it merges once 1 to 4
   hold. When merging is reserved to the principal, it sends the principal, in the principal's
   channel, a proposal that names the change, its head commit and the evidence of 1 to 4, and merges
   only on the principal's own answer to that proposal (protocol, Roles, principals and the
   delegation record). A head that moves after the answer needs a new answer.

The gates are quality and the record is authority, and a change needs both. In the one coordinated
round with a publication token, each authorization also pinned the commit it was given for. The
second review round is the budget for small fixes. A blocker left after it never merges; the
orchestrator narrows the scope, asks for another fix or escalates (protocol, Reviews). After the merge
the orchestrator updates the main checkout and reinstalls what the team runs on only under grants
that cover those acts, and closes the members whose task ended (leave first). In the first round the
second review rounds found only edge cases. (P03, P12; high for the gates; M14; medium for pinning the head)

Remove the team's merged worktrees and branches only when the record grants that cleanup and after
checking that no member or unmerged work still needs them. Otherwise leave them in place and propose
the named removals to the principal. Report what was removed or remains. (LOG, acceptance 1,
stumble 12; low)

## Cleanup

A team closes the panes it opened once their sessions end. When a harness's permission check
refuses the close, the team reports the panes and the refusal and leaves them to whoever may close
them, without working around the denial. (protocol 4.7, 9.3; LOG, 2026-10-26, pane cleanup
ownership; low, one refused close and a reported cleanup)

Keep an inventory of resources the run creates, with exact paths or ids, creation evidence, current
holder, removal grant, retention reason and the command that checks their state. Update it at each
task end and copy its unfinished rows into the orchestrator handover. Remove only resources covered
by the record; a merge grant does not grant deletion, and a workspace grant does not grant editing
harness trust settings. Propose reserved removals to the principal and retain the named resources
until answered. The closing report lists what was cleaned, what remains, why and who owns the next
action. (protocol 4.3, 4.7, 4.8, 9.3; LOG, acceptance 1, stumble 12; LOG, 2026-10-23 about 08:45 UTC-3,
cleanup; low)

At a swap, keep resources needed by live work, transfer the inventory and watchers explicitly, and
close the outgoing pane only after its process is gone. At each task end, settle its requests and
remove or retain its resources under the record. At run end, check every inventory row, including
the board, test directories and trust entries; leave no leftover without a reason and owner.
The acceptance run left cleanup to its director, which removed four worktrees and a merged branch,
while the later handover still listed test directories, a trust entry and inactive addresses.
Later, the director archived all three tests' evidence before removing their directories, removed
the first test's trust entry, and retained inactive addresses, measurement transcripts and inert
project entries with reasons. (protocol 9.4, 9.5; LOG, 2026-10-23 05:13 UTC-3 and about 08:45 UTC-3, cleanup;
LOG, acceptance 3, 2026-10-23, cleanup; low)

When closing a Codex member after leave, send `/quit` or `/exit` with `herdr pane send-text`, pause
about one second, then submit Enter with `herdr pane send-keys`. Verify process exit before closing
the pane; immediate Enter can leave the command in the composer. The field also proposes `ctrl+c`
to clear the composer first. (HN35; LOG, field PR 25, harness operation; LOG, 2026-10-23 09:00 UTC-3; low)

Use the commands below with your run's recorded ids and paths. Save the command, output, exit code
and time before and after the covered cleanup. A denied or failed query proves no absence. These
are verification commands, not a grant to remove anything. (protocol 7.3, 7.4; LOG, 2026-10-23 about
08:45 UTC-3, cleanup; low)

| Resource | At swap, task end and run end | Check |
|---|---|---|
| Member and outgoing panes | At swap retain working members and close only the outgoing pane after its harness exits. At task end have departing members run `keryx leave`, settle or transfer obligations, exit their harness and then close their panes; retain a specialist only for named next work. Recheck all run panes at run end. | `keryx who --all -o json \| jq '.addresses[]'` checks the address holder; `herdr pane process-info --pane PANE` and `ps -p PID -o pid=,lstart=,args=` check the recorded harness process; `herdr pane list` checks the pane is gone. An idle pane or released address alone does not prove process exit. |
| Addresses created by the run | Retain the stable address through swaps. At task or run end, under the record, run `keryx retire ADDRESS` on the address's host after its live holder and open requests in either direction are gone. Keep the mailbox files; `keryx join MEMBER.TEAM --revive` restores the address with them. Otherwise retain and record the reason and holder. | Before retirement compare `keryx who --all -o json \| jq '.addresses[]'` and `keryx status --all -o json` with the run's inventory. Keep the successful retirement output, then check the address is absent from both full lists. Absence alone is not proof. `keryx help retire` states the refusal conditions and restoration command; R07 is delivered in 0186dcd. |
| Merged worktrees and branches | At swap keep those used by live work. At task end remove only merged, unused resources with the cleanup grant; otherwise propose the exact removals. At run end account for every retained tree and branch. | `git -C REPO worktree list --porcelain`, `git -C TREE status --porcelain`, `git -C TREE stash list` and `git -C REPO branch --merged BASE` establish registration, saved or unsaved work and merge state. Recheck the list and `git -C REPO branch --list BRANCH` after removal. A stash needs review, not deletion. |
| Scratch directories and temporary files | Transfer required probes and handover evidence at swap. At task and run end remove the run's disposable paths when covered, keeping evidence until its report no longer depends on them. | `ls -ld -- PATH` and `test -L PATH` distinguish the recorded path and a symlink; `test ! -e PATH && test ! -L PATH` checks removal. Check the creation inventory before considering any existing path disposable. |
| Loops, heartbeats and watchers | At swap name one continuing holder and stop or transfer each old instance after the new heartbeat is armed. At task end stop watchers whose purpose ended. At run end stop every run-owned instance; leave shared services running. | `ps -p PID -o pid=,lstart=,args=` checks the recorded process and start time. For scheduled work use the scheduler's exact listing command recorded when it was armed, such as `systemctl --user list-timers --all` for a user timer or `crontab -l` for a cron entry. Record the successor's id and next check, and verify the old instance stopped. |
| Board pane | Transfer it at swap, keep it while team work remains, and stop its watch process and close the pane at run end. | `herdr pane process-info --pane BOARD` identifies its watch process; the recorded PID check above and `herdr pane list` verify both process and pane are gone. |
| Harness trust entries | Preserve entries needed by active sessions at swaps and task ends. At run end remove only entries your run added, only when the record grants the settings edit; otherwise propose them to the principal. Preserve pre-existing and concurrently added settings. | `rg -n -F -- 'RUN_PATH' 'CONFIG_FILE'` locates the recorded entry. Compare with the saved pre-run entry and inspect the exact block, then repeat the query after removal. Exit 1 means no matching text; exit 2 is a failed check. Never restore a whole old config over newer settings. |
| Test directories | At swap retain live test state. At task or run end preserve accepted reports and probes first, check no session or test process still needs the directory, then remove only under its grant; otherwise retain and propose it. | `keryx who --all -o json \| jq '.addresses[]'`, the recorded test PID check and `git -C REPO worktree list --porcelain` check known users and registered trees. Use `ls -ld -- TEST_PATH` before and `test ! -e TEST_PATH && test ! -L TEST_PATH` after cleanup. |

Bootstrap section 10 supplies the end-of-run checklist. A check can finish with a retained resource
when the report names its reservation or continued use; it cannot finish by silently dropping that
row. (LOG, 2026-10-23 about 08:45 UTC-3, cleanup; low)

For address records, use `keryx who --all -o json | jq '.addresses[]'`; the full JSON object also
has `view` and `hidden`. Use `--all` in cleanup because the short view hides addresses with no
holder, unread mail or open request. Retired addresses stay absent from both views and refuse
mail; do not send a probe to a real address just to check cleanup. The director reported 28
addresses retired across the team that wrote nomos and three acceptance tests, with files retained,
on 2026-10-23 at 09:43 UTC-3. This is sourced cleanup evidence; the writer did not repeat it.
(LOG, 2026-10-23 09:43 UTC-3, address retirement and list shape; low, one cleanup batch)

## Context policy

Every brief gives its session a renewal criterion and the orchestrator watches it (protocol, The
session life cycle and handover). The defaults below come from three settings.

| Setting | Criterion | What happened |
|---|---|---|
| The first keryx round | About 50% of the window, at a stopping point | Three handovers worked; a new implementer fixed a review round in ten minutes from the note |
| A long-running rig | 250K tokens on a 1M window, a planned handover at every boundary | Spending fell, but one seat was swapped about every hour and most swaps lost the role text |
| The nomos run, before the 1M ruling below | Half the window, at most 250K | A miner reached 81% of a 300K window it could not see; reviewers at maximum effort read to their ceiling with almost nothing written |

### The ceiling

A benchmark formation fixed its sessions with no successor allowed, and its orchestrator reached the
80% notice with no instruction for it, so it asked its controller. (LOG, benchmark run; low) A
proposal not yet tried follows from it: before starting a cycle, the director compares the room left
before the 80% notice with the last comparable cycle's context growth and renews first when that room
is too short.

The ceiling sits where stopping costs less than going on. The cost of stopping is what a successor
has to load again. Outside the 1M window, roles whose state lives in commits, notes and reports,
including implementers, reviewers, QA, writers and an orchestrator with a current checkpoint, stop at
half the window, at most 250K tokens. A one-pass, read-heavy role, such as an auditor or researcher,
stops at about 70%, at most 400K, only with a progress file holding its findings and coverage map,
kept current after each finding from the start. Without that file it stays at half, at most 250K.
The remaining 30% gives room for report, handover and the harness's compaction. Windows of 258K and
below keep their figures, including the 258,400-token row. (LOG, field audits of fde5548; low, one
round with three auditors; LOG, 2026-10-23 about 08:12 UTC-3, 1M ceiling; low)

On a 1M window, count from the context keryx stamps on the first readback, called the join figure.
State-in-files roles stop at that figure plus 250K. The orchestrator, and a read-heavy role with its
progress file and coverage map kept current after each finding, stop at that figure plus 350K.
Neither ceiling exceeds half the window, 500K. An orchestrator runs on a window where half of it
leaves at least three times its join figure; with joins of about 70K, the ruling chooses 1M, never
200K. These are absolute stopping figures in keryx, not amounts to subtract from measured context.
(LOG, 2026-10-23 about 08:12 UTC-3, 1M ceiling; LOG, field PR 24, ceiling mid-change; LOG, field PR 26,
join and ceiling; LOG, field PR 27, one director through merge; medium for three operational
completions, low for the figures and wider effect)

Every ceiling includes the harness's instructions, tools and skills loaded before nomos. Record the
context stamped on every seat's first readback, including the orchestrator's; it already includes
join, skill and inbox. On 1M that figure sets the budget above, while measured context still includes
it. The reading map estimates only the nomos texts. If the initial load leaves too little room,
reduce the task or seek a stated ceiling change before heavy reading. (LOG, acceptance 1, stumble 4;
LOG, 2026-10-23 about 08:12 UTC-3, 1M ceiling; low)

Whoever spawns the session states the ceiling in tokens for its actual window and role. Do not assume
a window for Claude Code. Its transcript gives the tokens in use but not the window, the model id
does not tell a 200K window from a 1M one, and the harness hands the window only to a status line
command the user configures (HN16). Give a percentage only where the harness reports the window, as
Codex's rollout file and Cursor's status line do.

| Window, in tokens | State in files | One-pass reading with the progress file | Where this window was seen |
|---|---|---|---|
| 200,000 | 100K | 140K | Claude Code without a long-context setting; not seen in these runs |
| 256,000 | 125K | 180K | A second harness in the field audits of fde5548 |
| 258,400 | 125K | 180K | Codex, with the model in the recorded example (HN21) |
| 300,000 | 150K | 210K | Cursor without an override (HN23); reading ceiling calculated, not measured |
| 500,000 | 250K | 350K | Not seen; calculated from the rule |
| 1,000,000 | Join + 250K, at most 500K; orchestrator uses the next column | Join + 350K, at most 500K, also for the orchestrator | Cursor with an override (HN23), and Claude Code with that configured window; low-confidence ruling, no comparison run yet |

A harness whose figure keryx cannot read takes read-heavy work only if its director reads the figure
from the pane's footer at each heartbeat; otherwise route the work to a harness keryx can measure.
Cursor's unreadable footer left one auditor without notices in the field audits. A typed stop
may arrive only after the turn ends, so it cannot replace the check. (LOG, field audits of fde5548;
low; HN25)

The half comes from the first keryx round, where handovers at about half the window worked. The
former 250K cap came from a long-running rig and the nomos writing run, where spending fell under
it. A low ceiling increases rereading and readback; the rig's quarter-window ceiling swapped one
seat about every hour and most swaps lost its role text. Read the actual window, never the model
list, since a list said 1M while the session ran at 300K. The field audits added room for reading
whose cost would otherwise be repeated. (P05, M19, M34, LOG; medium for the earlier incidents, low
for the role-based figures)

The 1M exception follows nine orchestrator swaps on 2026-10-23 from 04:59 to 07:49 UTC-3, each
entering at about 70K and leaving at 250K after about fifteen to twenty minutes. The join, note,
spawn and readback were paid each time. The report and ruling found that cost too high; a few
sessions past 340K without reported loss are limited evidence, not a controlled comparison. Lower
the rule again if errors beyond about 350K trace to long context, such as missed or misread
messages, wrong ids or repeated work, or if Claude quota use per hour of work is clearly higher
there than with frequent swaps. Record swaps per hour, each orchestrator's join figure, and the
vendor's Claude usage figure from your account meter at each swap for the next decision. (LOG,
2026-10-23 about 08:12 UTC-3, 1M ceiling; low)

The ceiling stored in keryx is the stopping point. To move it, the director sends the session the
new figure, an absolute time and the reason; the session re-runs `keryx join MEMBER.TEAM --ceiling NEW`.
Rejoining keeps its address and sets the figure, but it drops the director spawn recorded, so the
notices then go to the sender of its oldest open request, or to the session alone; a rejoin without
`--ceiling` also removes the ceiling (keryx.md, 9.5). A message alone leaves the courier's notices at
the old ceiling, as the field audits showed when two auditors were told to continue past 125K. The
director's rejoin was checked at 2026-10-23 04:22 UTC-3. (LOG, field PR 22 and audits of fde5548; low)

A brief sets no separate token stop below the stored ceiling. If the director wants handover to
start at N tokens, it sets `--ceiling` so the 80% notice falls at N, retaining the ceiling as the
hard stopping point and leaving room to save and report. Leave the cost of one probe between
the 80% notice and the point where work must end. For example, an 80K trigger uses a 100K
ceiling. Keep that ceiling within the window and role policy; lower the trigger if necessary.
The member reads `keryx who` after each unit of work, including required skill reads, rather than
waiting for a delayed notice. Three PR 24 reviewers passed lower brief stops before the first
notice, and a PR 26 reviewer passed its stop during a skill read. Two PR 27 reviewers passed
their brief stops by one probe; its rechecker held a stop given with its reason. That one held
stop does not change the rule, since the notice is mechanical and brief stops were passed in
PR 24, PR 26 and PR 27. This extends the stored-ceiling correction in the field audits; the notice
is a handover trigger, not permission to ignore the ceiling. (LOG, field audits of fde5548;
LOG, field PR 26, stop lines; LOG, field PR 27, probe
across the stop; LOG, 2026-10-23 09:54 UTC-3, late notice; low, two more crossed stops, one held stop
and one more late notice)

### Who measures and when

- Codex and Cursor show the session no context figure in the runs recorded here, so the
  orchestrator measures for them, from Codex's rollout file (HN21) and from Cursor's status line in
  the pane (HN24). A Codex session that knows its thread id can also read its own rollout; a verifier
  did so. The Claude Code sessions reported their own figure in tokens (HN16), against a window
  their spawner had to know. (LOG; high for the absence of a figure shown to the session, medium for
  the methods)
- The brief gives the session its ceiling in tokens and says who will tell it when it gets close.
- A stop does not arrive at once. A message to a busy Cursor session waits until its turn ends, and
  one to a busy Codex session waited for its next tool call, which took minutes in the recorded
  nomos run (HN25, HN34). Send the stop with that margin before the ceiling, and expect the session
  to finish the step it is in. (LOG; low)
- Watch the output, not only the figure. A reviewer at maximum effort read until its ceiling with
  almost nothing written, twice in the recorded nomos run. At each check, look at whether the
  session's output file has grown, and when it has not, tell the session to write what it has. Size a
  review task to the window, and split a large review by lens into separate sessions. (LOG; low, seen twice in one run)
- Renew at a stopping point, never mid-edit, through the handover note and a readback. Check that the
  new session has its role, brief and authority before it acts. (M34, P05; medium)
- Renew early when answers drift, whatever the figure. One swap addressed drifting answers rather
  than a full window. (P05; low)

Before this practice, context monitoring and saving state before compaction needed manual checks
in single-session work. The practice above moves those checks to the director. (P05; medium)

keryx now implements R09 and R10 in `evidence.md`. At 60b1abb (#20), it reads each session's
context from the harness's files, shows CONTEXT in `who` and `status`, and carries the sender's figure
on each message a session sends from its own address; a send with `--as`, from a terminal or from the
courier carries none. At fde5548 (#21), `join` and `spawn` accept `--ceiling TOKENS`; the courier notifies
at 80% and at the ceiling. It tells the session and its director, the spawner or else the sender of
its oldest open request, and only the session when neither exists. The director still chooses the
ceiling, checks output and stalls, keeps the checkpoint and arranges handover. A missing figure needs
the harness-specific check above; a delayed notice still needs margin. (R09, R10; help and display
checked at fde5548, notice routing code-grounded, threshold delivery not probed here)

### The director's heartbeat

While any session is working, the director never waits without a deadline. Give every request a
`--within` suited to its task. Set the heartbeat interval to about a quarter of the expected run,
never more than fifteen minutes, even when no message arrives; a 22-minute audit needs a check about
every five minutes. Check output-file or transcript growth, errors in the pane and each request's
deadline. Compare with
the previous check; silence is not progress. Use `keryx who -o json | jq '.addresses[]'` to list sessions for the routine,
then inspect those signals. The transport's context notice does not show whether useful work advances.

Know which pool each session uses and that it can run out, including when several sessions share
it. In the recorded nomos run the director waited two and a half hours for a stalled session
because it depended on events that the session could no longer emit; the session drew from a shared
pool. The correction is a bounded wait and a check independent of incoming events.
Shared pools remain a routing choice. (LOG, 2026-10-23 02:28 UTC-3; low for the incident)

A turn ended by a provider error, a capacity message or a menu can show as done or idle in `keryx
who` while the task remains unfinished. Since d7b5502 on keryx main, `who` and `status` show last
activity in the ACTIVE column, the time since the harness last wrote its session record. This is
not a liveness check; a session on a long tool call can look quiet. Keep the heartbeat because a
last-activity figure alone does not prove progress. Fifteen minutes proved too slow for a
22-minute audit. (LOG, field audits of fde5548; R11; low for the incidents and the task-based
interval) The benchmark found the binding still describing this delivered feature as future.
(LOG, benchmark run; low)

## Keeping the orchestrator light

- A choice the record or brief already gives, such as the team's shape, belongs to the orchestrator
  within its authority. Record the decision and its reason, act and report it; do not ask the
  principal to make it again. Escalate only what the record reserves or leaves outside its grant.
  (protocol 4.8; LOG, acceptance 1, N1; low for this incident)
- Read reports, not transcripts. Open a trace only when a report is ambiguous, contradicts another, or
  a decision is contested (protocol, Reports and evidence). After about four hours directing some ten
  sessions, the first orchestrator was at 59% of its window; when the same kind of session wrote code
  itself, it filled to a compaction. (P04; medium for the practice, low for the comparison, which is
  one round against one earlier session)
- Filter command output by default, and never conclude absence from a filtered search. A search for a
  harness's session variable cut by `head` led to the conclusion that the harness had none, and a
  stage had to be redone; an install script piped through an output-compressing hook arrived
  truncated. Rerun without the filter, or read the file whole, before writing that something does not
  exist. An empty answer from a starved or failing source is not an absence either; a nightly script
  read an empty status list as "nothing alive" and stopped nothing. (M01; medium)
- Give bulk reading to a member and ask for a file. The orchestrator reads the summary and the path.
- Renew yourself on the 80% notice, or at a planned step boundary near it, without waiting for the
  principal. Finish or park the step and save the checkpoint and orchestrator handover variant.
  Include every directed session's address, pane, request, deadline and heartbeat; requests both
  ways; watchers; pending principal decisions; and the Cleanup inventory. Leave, spawn at the same
  address with the root record word for word and the note as the handover request, and stay open
  without an address. Follow `keryx.md`, Handover today. (protocol 9.4, 9.5; LOG, 2026-10-23 about
  08:45 UTC-3, orchestrator swap; low)
- Before confirming your successor, compare the readback and record, the holder shown by `keryx who`,
  the stamped context against the expected harness and reading range, a ping that rings and gets a
  reply, the team and request inventory, and the armed heartbeat. Save each result. Correct a failed
  check with `[clarify]`; if it stays wrong, have that successor leave and close it after checking it
  cannot act, then try one replacement. Ask the principal after the second failure. A historical swap
  was refused while the outgoing pane still held the same herdr agent name; inspect `herdr agent list`
  and `keryx who` before retrying, distinguishing a pane name from an occupied address. (protocol 9.5;
  LOG, 2026-10-23 04:59 UTC-3, swap name collision; LOG, 2026-10-23 about 08:45 UTC-3, orchestrator swap; low)
- Send the timed `[accept]` only after all checks pass, stop or hand over your watchers and exit.
  The successor records cutover, tells affected peers, tells the principal in one line where it now
  lives and closes your pane once your process is gone. Successful renewal with the same record
  needs no principal decision. A changed record does. Finishing beyond the ceiling still needs an
  explicit yes for the remaining work and a hard cap with an absolute time, applied by rejoin as The
  ceiling specifies; no answer extends nothing. (protocol 9.5; LOG, acceptance 1, stumble 13;
  LOG, 2026-10-23 about 08:45 UTC-3, orchestrator swap; low)
- Decide whether the orchestrator holds its address. Holding it gives native bells and the stop hook.
  An orchestrator whose harness would turn every bell into an approval dialog (HN10) can run without
  holding it, and then every keryx command it runs names the address, as in `keryx inbox --as ORQ`,
  `keryx read --as ORQ ID` and `keryx reply --as ORQ ID TEXT`, since a reply must come from the
  request's recipient. The stop hook leaves a session that holds no address alone, so it reminds this
  orchestrator of nothing, and a watcher loop run as a background command of its harness is its only
  bell.

      for check in $(seq 1 15); do [ "$(keryx inbox --as ORQ -o json | jq length)" -gt 0 ] && break; sleep 20; done; keryx inbox --as ORQ

  The loop is how this mode meets the protocol's rule that every channel rings its reader (protocol,
  Messages and the work life cycle), so it runs whenever the orchestrator waits and is started again
  after every compaction or relaunch. This example returns after about five minutes even without mail.
  Choose the loop count for about a quarter of the expected task run, at most forty-five checks of
  twenty seconds each. Perform the heartbeat checks before waiting again while sessions work. Never
  read another address's mail. The orchestrator in the recorded nomos run worked this way throughout.
  (M16, LOG; medium for the watcher; LOG, field audits of fde5548; low for the interval)
- Do not wake a model for a deterministic check. A watchdog that woke the strongest model every 30
  minutes to judge a script's output made that seat the most swapped of its rig. Run the script on a
  timer with no model. Wake a model when the script finds something or the director's heartbeat
  deadline arrives while sessions are working. (M19; medium)

## State kept outside sessions

Keep these files from the first hour, in a directory the team can read and the principal owns.

- A decision log. Each decision has an id, an absolute date, what was decided, and the principal's own
  words in quotes when the decision is the principal's. A paraphrase changes the principal's claim; a
  draft that turned "I don't know who owns it" into "it has no owner" was a false claim in the
  principal's name. (P07, M54; high for the log, medium for the quotes)
- A run log with absolute times and their zone, one line per event (spawn, reply, handover, incident),
  with the message ids.
- Briefs, fix requests, handover notes, probes and reports as files, which the messages point to.
- A triage queue for findings from outside the team (see "A cheap channel for outside users").
- Deferred decisions with their reason and what reopens them. A core component was started switched
  off on another agent's vague advice, with "off on purpose" in memory and no reason; a later session
  fixed the real cause and restarted it with the same flag, and the rig then rebuilt that component's
  job by hand. Write "deferred because X; reopen when Y", and the session that removes X reopens it.
  (M50; low)

At each checkpoint save, check that every delivered request keeps its own decision entry under its
id, that each re-evaluation has a new request id naming the earlier one without overwriting it,
and that the next action and phase follow from what remains open; timestamp the checkpoint with
the save time. Do not write a handover note from a checkpoint that fails this check. One run's
checkpoint lost earlier request decisions, kept a stale next action and recorded a save time
before its acceptance entry. This check applies the existing obligations in protocol 5.5 and 9.5.
(LOG, benchmark run; low)

Persist before answering. Anything agreed in conversation goes to a file before the reply, because the
session can be compacted at any moment and the disk cannot. Twice a principal had to ask for
persistence by hand. (P07; high)

## A cheap channel for outside users

A session or person outside the team that uses its product sends findings as messages, not requests,
so it never waits on the orchestrator, and asks with a request only when it needs a session to help.
The orchestrator keeps a triage table (number, from, finding, triage, where it goes) and answers each
finding once. An outside session found three real issues in its first ten minutes, among them that the
first prompt traveled where any local process could read it. (P08, L09; low, seen once)

## Measuring what the team spends on itself

Count, at the end of every run and at a fixed interval on long runs, what the team spends on its own
process against what it spends on the work. Daily is the default interval, and nobody has measured a
better one. Count tokens per seat and per quota pool over more than one window, the principal's
messages about the team against those about the work, and the code written to run the team. A rig
grew from six to eleven seats in 23 hours with four of the five new seats working on the rig itself;
its operations seats took about a third of the Claude tokens over two days, and most of the principal's
messages were about the rig rather than the product. Cut process when it dominates. A review finding
justifies a bounded repair, not more process. The first keryx round did not measure its share, so
there is no baseline yet. Count Claude Code transcripts after deduplicating by message id (HN14), give
every count its unit and denominator, and never mix two vendors' pools in one denominator, since a
cost analysis in the same rig did. (M33, M41, M47; medium for the method, default for the interval, low
for any threshold)

## Seats per task

Parallelism comes from tasks that are independent (separate changes, separate questions, separate
documents), each with its own seat, and never from cutting one task finer to keep seats busy. A rig
that reviewed every small part of a piece with a fresh reviewer paid for a fresh session per part,
and the per-part reviews missed the defect between parts that the first whole-piece review found.
The rig tool's own guidance says a declared topology is an inventory of capabilities, not a
requirement to fill every lane. When the principal asks about an idle seat, answer with the list of
open tasks and their dependencies, and start a seat if one is independent. (M33, M35; low)

Closing an idle session is the default. Its evidence is the same rig, where the cost of process grew
with every seat kept busy, and the empty wake-ups of a model that bought nothing (see "Keeping the
orchestrator light"). Its cost is the reread when the closed session's context is needed again. The
exception is a session whose context is the value, such as a specialist kept between review rounds of
the same change, which checks its own findings faster than a fresh reader could relearn them (protocol,
Reviews). Keep such a session while the next task that needs its context is known, and close it when
that work ends. Closing a session does not retire its address, since the identity outlives the
session. This is nomos's operational choice and not a resolution of the evidence. The case against
inventing work for a seat is strong, the case for closing every specialist between tasks is narrower,
and nobody has measured the reread against the idle cost. (M02, M33, L08; default)

## Turning a repeated correction into a check

When the principal corrects the same thing a second time, write a check that runs before the output
is shown (a write hook, a pre-send hook, a lint rule), not a memory note. The second time is a
default; the evidence shows that memory did not hold, not that two is the right threshold. One writing
rule needed repeated corrections, every time with the rule already in memory, and held once
it moved into a write hook that refuses the text. A rule kept only in a skill also failed, since a review skill still lacked the blind lens
two months after the lesson was written down. One script can serve the hooks of several harnesses,
run with a flag for each. Loading a rule is necessary and not enough, because a reviewer still cited a
precedent that did not exist with a rule against invented examples loaded; the check that runs is what
held. Write each lesson at the grain of the trap, the wrong reflex and what to do instead. (M10, M45;
high for the mechanism, default for the threshold)

Do not add gates of your own over a skill that already defines its flow. A session that added a wait
for "continue" before each step of a review skill doubled the round trips. (M31; low)

## Unprivileged checks before a privileged request

Before asking the principal to run or approve a privileged batch, run every check that needs no
privilege, such as a dry run, a syntax check, a package lookup in the configured repository, and the
mode of every script. A root batch took four rounds of the principal's authentication for three
defects each findable without root, the last a script with no executable bit that failed only after
the authentication succeeded. The same holds for commands handed to anyone else. The principal is the
one resource the team cannot parallelize. (M53, M49; low)

## Live tests and shared trees

- Live tests run in their own environment, never in the team's live store or the user's default
  session server. Use a separate multiplexer server, a temporary store and config, a wrapper first on
  PATH for harnesses that drop environment variables, and the cheapest model at low effort. Back up
  every config file a test touches and remove only what the test added. No leak into the store was
  recorded in a round where every brief carried this section. (M03; high)
- Guard every `cd` before a write in a chained command. A test meant for a disposable worktree ran for
  a few seconds in the principal's own checkout when a chained `cd` broke. (M03, M29; low)
- Tests and probes never send to a live destination other people read, such as a shared chat channel
  or a real address, and keep their output inside the isolated test environment. (M03; low)
- Every writing session has its own worktree and commits finished work at once when its delegation
  record grants commits. Otherwise it keeps the work saved on disk and reports it. Verify claims
  against a named commit, identifying saved changes when the work is not committed. An auditor and a
  writer sharing a tree saw `git status` change between two reads and lost uncommitted work to the
  other's broad `git add`. A file someone else has taken, including the principal, is not the session's
  to edit. (M18; high for isolation; protocol 4.3, 4.7, 4.8 for authority)
- One directory is also one configuration. Seats that share a working directory share its instruction
  files, settings and skills, so role text cannot live there. (M18; low)

## Seats, tools and the shared machine

- After every relaunch, check that each seat runs the model and effort its brief says. A reviewer
  seat ran another model by drift, and one tool restores a seat from a snapshot that carries its old
  model. (M22; low)
- When the principal names a reference project, open it before designing and take its level of care,
  not its conventions. Both errors happened on one day. (M07; medium)
- Follow the design of a tool the team runs on, and patch only a proven defect, upstream when you can.
  A local patch to a tool's launcher had to be reapplied after every upgrade, and much of one rig's
  layer worked around what was the tool's design. nomos itself follows keryx's design and sends its
  needs to keryx as requirements. (M20; medium)
- A team on a shared machine leaves it usable for foreground work, watches its load, and plans
  for suspend. A rig stopped every working seat to free the processor during foreground work,
  and sessions kept changing the active workspace. (M40, L13; low)
- Announce a disruptive action on a shared machine to every team that uses it. Fifteen minutes'
  notice was the agreed default once. (L13; low)
- Answer a new session's startup dialogs yourself, by reading the screen. Never choose to trust all
  hooks in Codex. Never type into a pane that shows a selection dialog, since text plus Enter confirms
  the highlighted option. Close a session only after it ran `keryx leave`, and send nothing to the
  address of a closed Codex session until the transport refuses it. (H01, H03, M42, L06, LOG; high)

## Writing for the team

An agent writing to the principal picks the kind by what it asks now, sends each ask as its own
request with a deadline, and uses `templates/human-message.md` (protocol 10.5 to 10.9). An
escalation uses `templates/escalation.md` for the text below a `decision` block, with one title,
one block and one human-message footer; silence on that reserved decision only waits or keeps
things as they are.

- Write the current state as a scoped fact, and a principle only when a decision or a test imposes it.
  An architecture document said a tool only reads, from the commands it had that week. (M27; low)
- A rewrite changes only what was asked, keeps the rest, and says when it removes content. Iterated
  rewrites that cut points already made, and sessions that widened a task on their own, are the same
  failure. (M28; medium)
- Before an experiment whose output will look like breaking a standing instruction, say what it is
  and why. (M29; low)

## Open

- Whether an informed lens with the orchestrator's verification can replace the blind lens. No team
  has run both on one change.
- The fifteen-minute plan wait, the daily count of the team's own spending, the second correction
  as the trigger for a check, and the fifteen-minute notice are defaults nobody measured. The
  role-based ceilings have one field round behind them; the 1M rule has a reported swap cost but no
  controlled comparison of quality or quota use.
- Why the QA seat caught little, and whether it earns a place beyond plans, the facts of documents
  and missing tests.
- Whether keeping an idle specialist costs less than its reread, and for which roles.
- What share of a team's spending on itself should trigger a cut. Nobody has a baseline.

nomos v0 playbook
