# Audit brief, nomos v0

> An audit looks at a whole product at a fixed revision, not at one change (protocol 8.7). The
> auditor runs in a session blind to the changes and their reviews. It writes its findings before it
> opens any earlier audit, records a fingerprint of them, and only then checks the earlier findings
> for regression. An audit of a tree that another session is writing to reports states that no longer
> exist, so the revision is fixed, named, and checked again at the end.
>
> The model is the second audit of the [first keryx round](../evidence.md#lessons-of-the-first-keryx-round),
> which pinned a commit, ran its checks in a temporary
> clone, made its blindness checkable with a hash, and found fifteen issues.
>
> Fill every {placeholder} and delete these guidance lines.

---

Audit {the product} at {the full revision} for defects, broken promises and gaps, and report them with
their evidence

You are {member.team@host}, the auditor. {The director's full address} directs this task. Reply to
this request when the report is written, with its path and the findings ranked. Ask {the director}
with a request if something blocks you.

## What to audit

{The checkout, detached at {the revision}, and what it contains.} {Work in progress elsewhere that is
not part of this audit.} Nobody writes to this revision; confirm at the end that it has not moved.

Judge it against these.

- What the product promises, in {its README, docs, help pages and the instructions agents read}.
- {The requirements and decisions, with their path.}
- Correctness under the conditions it lives in, such as {concurrency, crashes between steps, damaged
  or hostile input, unreachable peers, slow or hung subprocesses, missing locales}.

## Progress from the start

Create {the progress file} before reading the audit target. Keep findings and a coverage map of
{the assigned areas}, including checked and unchecked scope, current after each finding. The brief
sets a ceiling of {tokens} for {the actual window}, using playbook, The ceiling. Its read-heavy
figure requires this file from the start; otherwise use the window's state-in-files figure. If scope exceeds about three
heavy areas, the director splits it across auditors before work starts, each with its own file.
Set the ceiling so its 80% notice falls at {N tokens}, the handover trigger, with no separate lower
token stop. Read the transport's who (`keryx who` with keryx) after each work unit and save completed
and unchecked areas at that notice, stopping by the ceiling. (LOG, field PR 26, stop lines; low)
(playbook, An audit, The ceiling; LOG, field audits of fde5548; LOG, 2026-10-23 about 08:12 UTC-3, 1M ceiling; low)

## Blind first

Do not open {the earlier audit's path} until your own findings are written. When they are, record
their SHA-256 and the time in the report, then read the earlier audit, and add a last section saying
whether each of its findings {its ids} still reproduces at {the revision}. Findings you add after
that point go in that last section only.

## How

- Run {the gates} and record the results.
- Give each finding the evidence its claim needs (protocol 7.2, 8.7). Reproduce a behavior that
  depends on execution with a probe and keep its output. Show a static defect, such as two
  requirements that contradict each other or a code path that cannot work, by file and line and the
  reasoning. Label as a suspicion only what you could not establish either way.
- Rank each finding must-fix or suggestion, and give it a severity (high, medium, low) by what a user
  of the product loses, as two separate fields; a low-severity defect can still be a must-fix. Give the
  file and line, the evidence, the impact, and the direction a fix should take, without writing the
  fix. `review-findings.md` is the form for each finding.
- Report gaps where the docs promise something the code does not do, or the code does something the
  docs never mention.

## Safety in this environment

- {The live resources the audit must not touch, and the isolated copies its probes use instead.}
- {What it may not run (real agent sessions, connections to other machines) and the stand-in for
  each.}
- Do not edit, commit or push in the repository, and do not change {the settings directories}.

## Report

Write it in {the language} to {the directory}, with a README, your probes and an evidence folder. Open
with the overall verdict in two or three sentences, then the check results, then the findings table
with rank and severity, then each finding, then the fingerprint, then the section on the earlier audit.

nomos v0 audit brief
