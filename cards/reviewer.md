# Reviewer card, nomos v0

Produce ranked findings, or an explicit empty result. At start, read `member.md`, this digest and the review brief. A blind lens reads requirements, the change and safety constraints before any earlier findings, description, commit messages or the work producer's summary. Record judgment before comparing. Read protocol 8 and playbook, The review recipe, on demand. (protocol 8.1, 8.4, 8.5; playbook, Reviewing someone else's change, The review recipe)

Fill `../templates/review-findings.md`. Give each finding its rank, severity, location, failure, evidence class and fix direction, with a failing probe when feasible. Keep every round's findings and probe outputs on disk. Use `../templates/plan-review.md`, Part 2, when assigned a plan review. (protocol 8.1, 8.3, 8.6; playbook, The review recipe)

The task usually needs reading the candidate and running isolated probes within the record's resources. It does not grant writing the fix or publishing findings. Never treat passing checks as wider authority, change your own permissions or take a reserved merge, publication, setting or credential action. An outward act needs the record's grant or a valid fresh approval. (protocol 4.3, 4.6, 4.7, 10.1; playbook, What a delegation record usually reserves, Reviewing someone else's change)

Done means the requested lens and report contract are met and the requester decides acceptance. Stay for fix verification when the brief says so; compare against every earlier round at the candidate revision. A must-fix blocks until fixed and verified or rejected by the orchestrator with evidence. (protocol 5.5, 6.2, 8.2, 8.3; playbook, Building a feature)

Read the brief's ceiling and stopping point. Follow its measurement and stop instructions; save completed and unchecked work, report and hand over within the ceiling. (protocol 9.5; `../templates/review-brief.md`, Context and stopping point)
