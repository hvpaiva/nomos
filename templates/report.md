# Report, nomos v0

> A report is the result that answers a request (protocol 7). The orchestrator reads it instead of
> opening your work, so it must let a reader check every claim without asking you. Answer the brief's
> report contract first, in the brief's own terms. Give each claim its evidence class (7.2), which is
> observed (a command or action, its output, and the revision and environment it ran against),
> code-grounded (a file and line, and the reasoning), sourced (a citation), or hypothesis. Say when
> output was cut, and never conclude that something is absent from a cut search (7.4). An empty result
> is a valid outcome; say how you checked it. Give every count its unit, scope and denominator (7.7).
>
> The line after the outcome is the report's provenance and footprint (7.1). Give your context from
> the transport's who (`keryx who` with keryx) or the message's context stamp, naming the reading,
> or write unknown when neither is available. Never estimate it. (protocol 5.7; LOG, field PR 26, context and times; low)
>
> A refusal is also a reply, much shorter. Its first line starts with "[refuse]", and its body says
> why and what would change the answer. Progress and accept are messages, never replies (5.3).
>
> Fill every {placeholder} and delete these guidance lines and any section with nothing to say.

---

{The outcome in one sentence, with the revision, such as "The review of change 16 is fixed and pushed
at 1add34f, three commits on 252e636, CI green".}

Written by {member.team@host} for request {its id}, against {the revision or artifact}. {It changed
{what} | It only read}. Context {figure and reading from the transport's who, such as keryx who,
or the message stamp | unknown}.

{What the work produced, with revisions and paths. For commits, one line each, with the item each one
answers.}

    {revision} {commit subject}            (item {n})

## What was done

1. {Item}. {What changed and why, in the brief's terms.} {The evidence for it, with its class, such as
   "Observed. The new test failed 5 of 5 on {base revision} and passes on {head revision}."}

## Evidence

- Observed. `{command}` on {revision}, in {environment}, exited {status} with {the output, or its key
  lines}. {Whether the output was cut.}
- Code-grounded. {The file and line}, {the reasoning}.
- Sourced. {The citation, at the place that says it.}
- Hypothesis. {What you believe and did not check, and how it could be checked.}

## Not done

- {What the brief asked that you did not do, and why.}
- {What you noticed and did not act on, since nobody asked.}

## Where to look first

{The part of the work where a reviewer's attention pays most, and why.}

## State left behind

{The worktree (clean or not), processes or servers still running, temporary files and stores, and
settings changed and restored, each checked.}

nomos v0 report
