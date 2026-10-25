# Review findings, nomos v0

> The reviewer's reply to a review brief (protocol 8.1). Rank each finding must-fix or suggestion, and
> give its location, the failure, how you know and the direction of a fix, without writing the fix.
> Prefer a failing test or a probe with its output (observed), then a precise code path or a
> specification it violates (code-grounded). A finding with neither is a hypothesis and says so. A
> defect that predates the change is still a finding; say that it predates it, and the orchestrator
> decides which change takes the fix.
>
> The model is the review of a locking change in the
> [first keryx round](../evidence.md#lessons-of-the-first-keryx-round), where each finding came with a
> probe run on the head and on the base revision.
>
> Fill every {placeholder} and delete these guidance lines. In the first round, delete the section on
> earlier rounds.

---

{The verdict in one sentence, such as "Change 16 at 252e636 has one must-fix and one suggestion", or
"Change 16 at 252e636 has nothing that must be fixed".}

{The change, its branch, the base revision and the full head revision reviewed, or, for a document,
the files and their fingerprints.}

1. Must-fix, {severity by what a user loses}. {The defect in one sentence.}

   {The location, as file and line.} {The failure, meaning what goes wrong, for whom, and under what
   input or timing.}

   How I know, {observed | code-grounded | sourced | hypothesis}. {The reproduction, with its setup,
   command and output, on the head revision, and on the base revision when that tells whether the
   change introduced it.}

   {The direction of a fix, and a test that would catch the defect.} {The probe's path, and the paths
   of its outputs.}

2. Suggestion, {severity}. {The same fields.}

## Checks run

{The gates and their results on the head revision, with numbers, and where the full output is.}

## What I did not check

{The platforms, paths and conditions not exercised, and why.}

## Earlier rounds

| Finding | Round | At {the head revision} |
|---|---|---|
| {the finding} | {n} | {fixed, only masked, or reintroduced, with the probe that shows it} |

## State left behind

{The review worktree (detached at the reviewed revision, no changes), processes, temporary files. That
nothing was committed, pushed or posted.}

## Repeating the probes

{The exact commands, and the argument that runs each one against the base revision.}

nomos v0 review findings
