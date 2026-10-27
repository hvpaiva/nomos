# Review brief, nomos v0

> A review brief asks a reviewer for ranked findings on one change (protocol 8). In the first round of
> a change, the reviewer is the independent lens (8.4, 8.5). It runs in a session that did not write
> the work, and it gets the requirement and the change, never the summary of whoever produced the
> work, earlier findings, the change's description or its commit messages as framing. It still gets the
> requirements and the safety constraints. A later round of the same change may go to the same
> reviewer, which then checks its own findings.
>
> The model is the review briefs of the [first keryx round](../evidence.md#lessons-of-the-first-keryx-round),
> whose reviewer found two to four defects per change, each with a failing test that reproduced.
>
> Fill every {placeholder}, delete these guidance lines, and delete the section for later rounds in
> the first round.

---

Review {the change, by link} ({its subject in a few words}) and report findings ranked

You are {member.team@host}, {in a fresh session for this task | the reviewer of this change, now in
round {n}}. Anything in this mailbox from before this request belongs to earlier reviews.

{The change} is on branch {the branch}, {n} commits on {the base revision}. {What it is meant to do, in
one or two sentences taken from the requirement.} Reply to this request with findings ranked as
must-fix or suggestion, each with the location, what goes wrong, how you know (its evidence class, and
a failing test when one is feasible), and the direction of a fix. If you find nothing that must be
fixed, say so plainly; an empty result is valid, and it will be checked like a finding. List the paths of every probe or test you wrote, so that whoever decides the
merge can run them. `review-findings.md` is the form.

## Why the change exists

{The problem and the requirement, with the path of the brief for whoever produced the work.} Review
against the documented contract, not that session's summary of its work. Quote the plan's ask for each
item and name any wording in this brief that exceeds it; do not rank that excess as a defect in
the implementation. (protocol 6.1; LOG, field PR 26, brief and contract; low)

## Where to look hardest

- {An area of risk, and the question to ask of it.}

## How

Check the branch out detached in {the review worktree} ({the commands}), run {the gates}, and write
throwaway tests or probes there if they help.

## Authority and safety

You may {read, check out detached, run the tests and linters}. You may not {commit, push, merge,
approve, or post anything outside the team}. {The shared resources you must not touch, and the
isolated ones a live check uses instead.} Your findings go to {the director} only.

## For a later round

{What the implementer says it changed, item by item, for you to verify rather than trust.} Check that
each earlier finding is fixed at its cause, run your earlier probes again on the new head, and look
hard at what the fixes introduced, in particular {the new code most likely to hide a defect}.
For each defect-asserting probe, state {the original case and corrected expectation on the fixed
head}, keeping the original and naming any adapted copy and diff. Do not ask to rerun unchanged
or expect exit 1 as proof of a fix. (playbook, The review recipe; LOG, field PR 25, defect probes;
LOG, field PR 26, recheck probes; low)

## Context and stopping point

Your stored ceiling is {tokens, within the actual window and role policy}, including the harness's
initial load. Its 80% notice falls at {N tokens}, the handover trigger; the director sets the ceiling
to match that trigger, with no separate lower token stop in this brief. Read the transport's who
(`keryx who` with keryx) after each work unit; {who also measures and how} watches for delay. At
the notice, finish or park {the bounded step}, save {checkpoint, completed and unchecked items},
write {report and handover paths}, reply
and stop by the ceiling. Silence does not extend it. (protocol 9.5; playbook, The ceiling;
LOG, field PR 23, brief ceiling; LOG, field PR 26, stop lines; low)

## When the task ends

{Leave after {the director}'s acceptance of your reply, never after the reply alone | Stay after your
reply until {the director} says the fixes are verified, and leave after that}.
Run '{the transport's leave command}' before your session closes.

nomos v0 review brief
