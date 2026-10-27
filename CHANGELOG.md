# Changelog

All notable changes to this project are documented in this file.
The format follows Keep a Changelog. Before the first release, all entries are under Added.

## [Unreleased]

### Added

- `nomos check`, the one message validator keryx runs before it writes any message, refusing only
  the MUSTs a message alone decides, and `nomos compose`, which builds a body without sending it,
  with a words file for the human's language and the pre-send hook moved onto the same rules. A
  request's deadline counts only when written with its zone, and a progress note sent as a reply is
  advice.
- Pre-send checks of the block in a message to a human, with its ask, deadline, title and files, by the
  recipient's directory role, with quoted mentions, deadline words and stricter wrapper reads.
- Handover notices only when the change needs the principal, member dialogs handled under standing
  rules, and an explicit no-footer rule for the page's human answers.
- Roster, roadmap and progress forms, with the orchestrator's update duties and their first case.
- An optional readback comparator for identity, task, authority and next action, with JSON output,
  bounded file input and tests on Ruby 3.3 and 4.0. It preserves literal evidence spans, checks authority
  claims across fields, reports omitted acts, and reads English built in, other languages from a local
  vocabulary file given with `--words`.
  Protocol 9.2 recommends the five-line form, with a complete example and human confirmation required.
- Protocol 10.5 to 10.9 and a human-message template, with seven kinds, one ask per request, a `nomos`
  block for the reader's page, answers that keep the human's words, and commitment and escalation forms.
- The keryx reserved-scope restrictions at 7debfde (#38) and pane cleanup ownership after session exit.
- Role-based member names within project-named teams, with short names and a full transport role.
- Request-specific replies, commitments for later or human-requested work, and their dated cases.
- An optional pre-send hook for keryx messages, with Claude Code, Codex and Cursor adapters and tests.
  It accounts for every raw send, ask or reply occurrence by its position, exempts only reads on
  per-reader option allowlists, walks other tools' input as strings, and bounds its parsing, input and
  output.
- Harness notes and wiring checks for Cursor's non-authoritative hook allow and Claude Code's
  last-settings-only command-line behavior, each with its dated case.
- nomos protocol v0 for team identity, delegation, requests, reports, review and handover.
- A checked closing order for members and outgoing orchestrators, the successor ending the outgoing
  session, a temporary address for the outgoing orchestrator, and leaving only after the acceptance.
- Mailbox purges only after the principal's confirmation and a verified full export.
- The `nomos` block and the human-message footer together on every agent message to a human.
- One state file with the six team forms as sections as an allowed equivalent of the six files.
- The director's duty to answer every dialog of a session it directs at once, under protocol 9.1.
- A ceiling change that keeps the director, through leave, expect and join.
- `nomos check` run by keryx before every message under the principal's decision, in protocol 11.2.
- Traces for ten rules, and an evidence check that requires a confidence on every protocol rule and
  playbook practice paragraph.
- shellcheck and `ruby -wc` in `tool/check`, Ruby 3.3 as the stated floor, the comparator in the
  README, the team's commit flow in CONTRIBUTING, and weekly Dependabot updates for GitHub Actions.
- A playbook of team recipes and versioned notes on Claude Code, Codex and Cursor.
- A getting-started guide with a reading map and a first-team acceptance exercise.
- Role cards, an orchestrator digest and templates for the team's work.
- A reference binding for keryx, with observed behavior and transport gaps.
- Sanitized cases with the incidents, reasons and confidence behind the rules.
- A public introduction, contribution guide and local package checks run by CI.
