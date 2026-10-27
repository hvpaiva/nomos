# Brief, nomos v0

> A brief is the text of a request that asks for a task (protocol 6). The worker has none of your
> context, so give it everything the task needs and point to the files behind it. Keep the sections
> in this order, and drop one only when it has nothing to say. The model is the brief for a new command
> in the [first keryx round](../evidence.md#lessons-of-the-first-keryx-round), whose replies gave enough
> detail that the orchestrator never had to open the
> work to know its state.
>
> Fill every {placeholder} and delete these guidance lines. A brief with a brace placeholder left in
> it is not ready to send (6.4). Write dates and times as absolute values with the zone (5.7).

---

{The outcome, in one imperative sentence.}

You are {member.team@host}, the {role}. {The director's full address} directs this task. Reply to this
request when {the point at which the work is delivered}, or earlier if you are blocked. Ask {the
director} with a request for anything this brief leaves open that you cannot decide yourself.
{Anything in your mailbox from before this request belongs to earlier tasks.}

## Where you work

- {The repository, and what it is in one line}. Your worktree is {its path}, on branch {the branch},
  cut from {the base revision}.
- Read {the files, in the order to read them} first.
- The gates before every commit are {the commands}, all clean. {Any standing bar, such as coverage.}

## What {the task} does

{The task and its purpose. The steps, when their order matters. For each item derived from a plan,
quote the plan's ask with its source, adding no stricter wording. For any sourced count or figure,
quote the source's words or name the source without a number.} (protocol 6.1; LOG, field PR 26,
brief and contract; LOG, 2026-10-23 04:56, 09:04 and 09:45 UTC-3, brief compression; low, three caught
compressions, two of counts)

{Out of scope for this task are {the items}.} If the design above has a flaw you can show, tell {the
director} before you build around it.

> List every default step this task skips or changes, with its reason and the record that allows it.
> Delete the slot when there is none. (LOG, benchmark run; low)

- {Default step skipped or changed}, {what this task does instead}, because {reason}, as allowed by
  {the record and its relevant clause}.

## Things in this environment that will bite you

> Name every shared resource the task must not touch (live stores, shared servers, other sessions'
> worktrees, settings files) and the isolated copy it uses instead. Say how tests stay away from the
> live ones, which files may change only with a backup and what to restore, and the cost limits for
> live tests.

- {The hazard, and the rule that avoids it.}
> Choose one of the two writing arrangements below and delete the other. Under integration, name the
> same integrator and integrated resource in every participating brief, and assign each recipient its
> own resource. Only the integrator writes the integrated resource (6.5).

- You are the only writer of {the files, branch or store this task writes}.
- {The integrator's full address} alone writes {the integrated resource} and merges contributions
  from {the contributors and their separate resources}. You are the only writer of {this recipient's
  resource, the integrated resource if the recipient is the integrator}.

If you find another writer on the resource assigned to you, stop and tell {the director} before you
overwrite anything. Other contributors named above write only their own resources (6.5).

## Conventions

- {Language, commit format, signatures, comments, changelog, and what the public artifacts never
  mention.}

## Authority

{The authority this task uses, within your record. What you may do, such as commit on {the branch},
push it and open a pull request. What stays with others, such as merging, tagging, publishing and
settings.}

## Done means

- {The acceptance criteria of this task.} {When the task can rightly find nothing, say that an empty
  result is a valid outcome, and that it will be checked like a finding (6.2).}
- {The standing quality bar, such as every gate and CI green on the final revision.}
- Your reply has {the links and revisions, the commands you ran and their output, what you did not do,
  and where the reviewer should look first}.

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
reply until {the director} accepts the result, to {verify the fixes, answer questions}, and leave after
that acceptance}. Run '{the transport's leave command}' before your session closes.

nomos v0 brief

---

> A fix request is a brief too, a new request that names the review it answers (5.5). It is short,
> because the original brief still holds, and it carries only the findings the orchestrator accepted
> after reproducing them. Send one request per pull request for the round, after all reviews are in,
> with all must-fixes. Before review starts, the director decides each residual the implementer
> names, fixed in the pull request or accepted as a known limit with its reason in the decision
> log. Do not pass that decision to reviewers. (playbook, The review recipe; LOG, field PR 26,
> fix batches; LOG, field PR 27, residual before review; low, two contrasting residual cases)

Fix the review of {the change} at {the revision}, {n} must-fix and {n} accepted suggestions

{The reviewer} reviewed {the change} at {the revision}. {What passed.} It found {what}, with failing
tests, and I ran them on {the revision} with the same results. They are in {the path}; run them from a
checkout with {the command}. Turn the failing ones into tests in the suite, then make them pass. Reply
to this request when the fixes are pushed and {the gates} are green.

1. Must-fix. {The defect, with the file and line, the failure, and the evidence.} {The direction of the
   fix, and any doc it makes wrong.}
2. Accepted suggestion. {The same fields.}

{Rejected or deferred findings, with the reason.} Same conventions as before, one commit per item with
its test, each passing the gates on its own. Update the change's description where these change it.

The stored ceiling is {tokens}, chosen so its 80% notice falls at {N tokens}, the handover trigger.
There is no separate lower token stop. Read the transport's who (`keryx who` with keryx) after each
work unit; {who also measures and how} watches it. At the notice, save completed and unchecked
items, report and hand over,
stopping by the ceiling. (protocol 9.5; playbook, The ceiling; LOG, field PR 26, stop lines; low)

nomos v0 fix request
