# Plan and plan review, nomos v0

> A plan review happens before the code (protocol 8.6). Part 1 is the plan, which the implementer
> sends as a request to the plan reviewer (a QA partner, the reviewer or the orchestrator). It says
> how long the implementer waits and what it does on timeout. Part 2 is the reviewer's answer, a
> recorded judgment. A timeout is never recorded as approval, and an implementer that proceeds on
> timeout says so in its report.
>
> In the [first keryx round](../evidence.md#lessons-of-the-first-keryx-round), a plan review caught a
> design gap in a race fix before any code, while
> reviews of finished code by the same seat added little. The model for Part 1 is the implementer's
> plan for fixing a review of a locking change.
>
> Fill every {placeholder} and delete these guidance lines.

---

## Part 1, the plan

Plan for {the task or the findings}, {what it changes in a few words}

{What triggers the plan, with the path of the brief or the review, and who reproduced what.} I wait up
to {a duration} for your answer, then I {start and say so in my report | stop and tell {the
director}}. I will send you each commit as I make it; tell me anything you would change.

### 1. {The item}, {must-fix | accepted suggestion | task step}

{The problem in two or three lines, with its evidence.}

- {A design decision, with the names it touches and why.}
- {What the change does not do, and why.}
- The tests. {(a) The scenario, and what must happen, within what time.} {What each test does before
  the fix, so it is known to fail first.}

### Commits

1. `{type}: {subject}`, {what it holds and why it is separate}.

{What else changes because of these, such as docs or the change's description.}

---

## Part 2, the plan review

> The reviewer replies to the plan request. Rank findings as in `review-findings.md`, each naming the
> plan item, the gap, how you know, and what would close it.

{Agreed | {n} findings}, plan for {the task}, read at {an absolute time with its zone}

1. {Must-fix | Suggestion}, item {n}. {The gap.} {How you know, with its evidence class.} {What would
   close it.}

{What you checked, such as precedence, failure modes, whether the tests prove the scenario rather than
the implementation, and whether they stay isolated from shared resources.}

nomos v0 plan review
