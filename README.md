# nomos

A protocol for AI coding sessions working as one team.

Several sessions can divide the work and still leave a human carrying every message, checking what
was actually done and explaining the same lessons to each replacement. nomos gives the team shared
rules for authority, requests, evidence, review and handover. Its documents travel with the team to
the next machine or project.

## Project goals

nomos is for people who run several AI coding sessions, including Claude Code, Codex and Cursor, as
one team. The package contains a short protocol, a playbook of team recipes, templates, role cards
and versioned harness notes. Each rule carries the incident that produced it, its reason and its
confidence. The project is maintained and versioned, and a rule enters only with its case, reason
and confidence.

nomos is transport-agnostic, with keryx as the reference binding. It is a set of documents with
tools, not a framework or runtime. Messages are the exception to following the protocol by text
alone. Under the principal's decision (N18), keryx runs `nomos check` before it writes any message
and refuses one that breaks a MUST it can judge from the envelope, every time; the other tools stay
optional.

The protocol is [version 0](protocol.md). The cards and templates identify themselves as nomos v0.
[CHANGELOG.md](CHANGELOG.md) records changes to the package.

## Start a team

Start with the [reading map](bootstrap.md#reading-map). Each member reads the
[common card](cards/member.md) and its role card; the orchestrator follows the map's own reading
list. Read the protocol and playbook by section when a task needs them.

The human principal fills the root form in [the first-prompt template](templates/first-prompt.md)
for the orchestrator. It names the principal, delegator and delegate, the granted actions and
resources, reserved decisions, redelegation, duration and who may change the record. The
orchestrator fills the member form within that grant and writes the task separately using the
[brief template](templates/brief.md). A card tells a session how to work; the delegation record
says what it may do.

### With keryx

[The setup guide](bootstrap.md) covers the machine, transport and harness setup.
[The keryx binding](keryx.md) records the supported commands and the gaps between the transport and
the protocol. Follow its address spelling for the version you run.

From an orchestrator already joined to keryx in a herdr pane, prepare a member first prompt and a
brief. The prompt names the absolute paths to this repository's common card and the chosen role
card, carries the delegation record, and requires a readback before work. Replace the capitalized
arguments below with the files, directory, deadline and context ceiling chosen for that task.
The address `impl-1.alpha` is illustrative; use the member and team from its record.

```sh
wc -c < FIRST_PROMPT_FILE
keryx spawn impl-1.alpha --harness codex --role implementer \
  --cwd WORKTREE --file BRIEF_FILE --within DEADLINE --ceiling CONTEXT_LIMIT \
  --prompt "$(cat FIRST_PROMPT_FILE)"
```

Pass the harness arguments selected in the root record after `--` when that mode needs them.
The binding documents the prompt byte limit and how to carry a longer record by a read-only file
reference. Keep secrets out of the first prompt. `spawn` carries the prompt through startup dialogs
and tells the member to join, follow `keryx skill` and open its inbox. The director confirms the
member's readback of its address, role, task, authority and next action before it acts. A successful
join alone does not confirm readiness.

### With another transport

Give any session the filled [first-prompt template](templates/first-prompt.md), the
[common card](cards/member.md) and its role card through the harness's initial prompt. Use the root
form for the orchestrator. Replace the transport commands with the chosen transport's equivalents
and deliver the task as a separate request.

The transport needs durable addresses and mailboxes, correlated requests and replies, and a way to
find open obligations. Map the [protocol's message kinds](protocol.md#5-messages-and-the-work-life-cycle)
to it, including result acceptance and the handover confirmation. The member sends its readback to
its director and waits for confirmation through that transport. nomos does not require keryx to
carry these rules.

## What is in the repository

| File | Use |
|---|---|
| [bin/nomos](bin/nomos) | `nomos check`, the message check keryx runs before it writes a message, and `nomos compose`, with their library in [lib/nomos](lib/nomos) |
| [hooks/pre-send.rb](hooks/pre-send.rb) | Optional message checks before keryx sends, with Claude Code, Codex and Cursor adapters; the entry loads its classes from [hooks/pre_send](hooks/pre_send) and the rules it shares with `nomos check` from [lib/nomos](lib/nomos) |
| [bin/compare-readback.rb](bin/compare-readback.rb) | Optional readback comparator for identity, task, authority and next action, English built in, with a local vocabulary through `--words` |
| [protocol.md](protocol.md) | Rules every team member can rely on, including delegation, messages, reports and session life cycles |
| [playbook.md](playbook.md) | Recipes for implementation, review, audits, research and document work |
| [harness-notes.md](harness-notes.md) | Observed behavior of Claude Code, Codex and Cursor, with versions and evidence |
| [bootstrap.md](bootstrap.md) | Getting started, the reading map and a first-team acceptance exercise |
| [orchestrator.md](orchestrator.md) | The orchestrator's reading digest, with commands that open its sources |
| [keryx.md](keryx.md) | The reference transport binding and its limits |
| [evidence.md](evidence.md) | Sanitized cases, reasons, confidence, public sources and decisions behind the rules |
| [CHANGELOG.md](CHANGELOG.md) | The package's change history |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to propose a rule, submit a case and run the checks |

The cards are [member](cards/member.md), [orchestrator](cards/orchestrator.md),
[implementer](cards/implementer.md), [reviewer](cards/reviewer.md), [QA](cards/qa.md),
[auditor](cards/auditor.md) and [writer](cards/writer.md).

The templates are [first prompt](templates/first-prompt.md), [brief](templates/brief.md),
[report](templates/report.md), [handover](templates/handover.md),
[review brief](templates/review-brief.md), [review findings](templates/review-findings.md),
[plan review](templates/plan-review.md), [audit brief](templates/audit-brief.md),
[escalation](templates/escalation.md) and [human message](templates/human-message.md), read with
protocol 10.5 to 10.9.

[tool/check](tool/check) runs [the pre-send tests](test/pre_send_test.rb),
[the comparator tests](test/compare_readback_test.rb), the `nomos check` and `nomos compose` tests,
[the style check](tool/check-style.sh), shellcheck on every shell script, `ruby -wc` on every Ruby file,
[the evidence check](tool/check-evidence.rb), [the reading recount](tool/recount.rb) and
[the package verifier](tool/verify.rb), on Ruby 3.3 or later. [CI](.github/workflows/ci.yml) runs the
same entry point.

## How a rule is written

A rule names the behavior, the case that produced it, the reason for the remedy and the confidence
in that remedy. Its trace resolves in [evidence.md](evidence.md), where the case preserves what
happened without copying private source material. A recurring problem and an untested remedy have
different confidence; record both. A counterexample belongs with the rule too.

[Protocol section 1](protocol.md#1-about-this-document) defines high, medium and low confidence.
The cards and digest point back to those rules and add none of their own. To change one, follow
[CONTRIBUTING.md](CONTRIBUTING.md) and run `tool/check` from the repository root.

## License

nomos is released under the [MIT License](LICENSE).
