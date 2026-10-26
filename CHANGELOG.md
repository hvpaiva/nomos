# Changelog

All notable changes to this project are documented in this file.
The format follows Keep a Changelog. Before the first release, all entries are under Added.

## [Unreleased]

### Added

- Handover notices only when the change needs the principal, member dialogs handled under standing
  rules, and an explicit no-footer rule for the page's human answers.
- Roster, roadmap and progress forms, with the orchestrator's update duties and their first case.
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
- A playbook of team recipes and versioned notes on Claude Code, Codex and Cursor.
- A getting-started guide with a reading map and a first-team acceptance exercise.
- Role cards, an orchestrator digest and templates for the team's work.
- A reference binding for keryx, with observed behavior and transport gaps.
- Sanitized cases with the incidents, reasons and confidence behind the rules.
- A public introduction, contribution guide and local package checks run by CI.
