# Contributing to nomos

A rule enters nomos with its case, reason and confidence. Propose the behavior you want sessions to
follow, explain the failure it addresses, and show what supports the remedy. For a change to an
existing rule, name its section and trace, describe the counterexample or new evidence, and say
which part of the rule changes.

## From a case to a rule

Write the case in [evidence.md](evidence.md), using its existing entry shapes and identifiers. Give
an absolute date with its zone when the event has one, what happened, the consequence, the reason
for the proposed rule and how often the remedy held. Keep the distinction between an observed
incident, a reading of code, a cited source and a hypothesis. A failure seen repeatedly does not
make its proposed fix tested.

Use the confidence definitions in [protocol section 1](protocol.md#1-about-this-document). High
means the rule held three or more times, or in two independent settings, with no counterexample.
Medium means twice, or once with agreeing prior art. Low means once or reasoned out. Say when the
problem and the remedy have different confidence.

Put the rule in the document that owns it. [protocol.md](protocol.md) holds what members must be
able to rely on; [playbook.md](playbook.md) holds recipes; [harness-notes.md](harness-notes.md)
holds tool behavior at a named version. Update affected templates and the [keryx binding](keryx.md).
Cards and [the orchestrator digest](orchestrator.md) summarize and point to those sources; they
must not introduce a rule. Link the change to its case, update the reading map if its inputs changed,
and add an entry in [CHANGELOG.md](CHANGELOG.md)'s Unreleased section. Follow Keep a Changelog's
categories, such as Added, Changed, Fixed and Removed. Before the first release, keep all entries
under Added, since the package is being introduced as a whole.

## Send a field case without private facts

Preserve the failure's shape and the reason for the remedy. Replace real people with their roles,
real machines with illustrative names, and paths with examples. Remove message identifiers, pane
identifiers, private repository and branch names, credentials, email addresses, employer and
customer facts, and account or quota details. Do not paste a private conversation or its raw log.
Keep any mapping back to the original record outside this repository.

A useful submission says what the session was allowed to do, what it did, what was observed and
what changed afterward. Include only the commands and output that can be shared, with their
revision and environment. Mark a redaction or a missing observation so a reviewer knows the limit
of the evidence. Check that the remaining combination of details does not identify the private
case. The package checks cannot decide that for you.

## Check a change

From the repository root, with Ruby 4.0 or later, Bash and the standard Unix tools `awk`, `sed`,
`grep`, `sort`, `find`, `wc` and `diff` available, run the same entry point as CI.

```sh
tool/check
```

The checks read the package and fail on a style violation, an unresolved evidence citation, a card
or digest over its word limit, a broken internal link, a source command that fails to read its
section, or a reading map whose counts have drifted. Generated reports go to a temporary directory;
the command prints its path. It leaves the repository unchanged and runs every check even if one
fails. Inspect the reported failures and run it again after fixing them.

For a count change, first inspect the recount and the proposed map diff.

```sh
ruby tool/recount.rb --check
```

To apply those computed figures deliberately, run the separate update command and review the diff.
CI never runs this command.

```sh
ruby tool/recount.rb --write
```

The common member card is limited to 500 words, each member role card to 300, and the orchestrator
card to 600. A common card plus a member role card stays within 800 words. The orchestrator digest
is limited to 2,500 words. Counts include headings and forms and are checked against `wc -w`.
Token ranges in the reading map are estimates, separate from measured context.

## House style and review

Write in plain English, with a specific subject and a checkable claim. Give dates and versions for
tool observations. Use sentences instead of label-and-colon openings, and commas, periods or
parentheses instead of em dashes, en dashes or a double-hyphen substitute. Keep code in fenced
blocks or inline code spans. The style check excludes those spans and rejects its listed filler
words and phrases in prose; the list is in [tool/check-style.sh](tool/check-style.sh).

A pull request explains the case, the rule and its reason, the confidence, the files affected and
the checks run with their exit codes. Name what remains unverified. The automated checks establish
mechanical consistency; a reviewer still checks the rule against its evidence, the privacy of the
case and the authority it implies. For a change to the startup or handover path, use the
[acceptance exercise](bootstrap.md#9-the-acceptance-exercise) with a fresh session and report its
result before asking for acceptance.
