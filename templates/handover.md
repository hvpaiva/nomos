# Handover note, readback and confirmation, nomos v0

> A handover is a transfer between two parties (protocol 9.4). Part 1 is the note the outgoing
> incarnation writes when it is asked to, after it stops starting new work. Write it for a capable
> engineer who has never seen this work. Everything in it is checked with a command in this session
> unless it says otherwise. The model is an implementer's mid-task handover in the
> [first keryx round](../evidence.md#lessons-of-the-first-keryx-round), after which the new session fixed
> a review round in ten minutes without reopening a decision.
>
> Part 2 is the readback the incoming incarnation sends as its reply to the handover request, before
> it acts. Part 3 is the confirmation from the outgoing incarnation, or from the director when the
> outgoing one is gone. Ownership of the identity's open work moves at that confirmation.
>
> Fill every {placeholder} and delete these guidance lines.

---

## Part 1, the note

# Handover of {member.team@host}, {the task}

Written {an absolute date and time with its zone} by the outgoing session {its session address}, at
{its context figure} of its window, for the session that takes the identity over. Everything below was
checked with a command in this session unless it says otherwise.

### 1. State

- {The repository, worktree and branch. The head revision, whether it is pushed and equal to the
  remote, and what tracks what.}
- {Whether the worktree is clean, with nothing staged, uncommitted or stashed.}
- {The change, its status and CI on which revision. Who merges.}
- {The local gates on the head revision, with their numbers.}
- {The commits since the base, one line each, with the finding or item each one answers.}
- {Which request this note answers.}

| Obligation | Id | Holder after the cutover | Until |
|---|---|---|---|
| {A request this identity received, one it sent and still waits on, a delivered item awaiting a decision, a process or an effect in progress} | {its id or path} | {the incoming incarnation \| the outgoing incarnation} | {the point at which the outgoing one hands it on or finishes it} |

### 2. What exists and how it is built

{The work in a few lines per part, with the files that matter, so that the next session can find its
way without rereading everything.}

### 3. Decisions taken, and why

> These are not to be reopened without new evidence. Say who decided each one.

1. {The decision}. {Who took it, why, and the evidence that settled it.}

### 4. What the environment taught

> What is not in the repository, such as the tools at their versions, their dialogs, names,
> environment and quoting, and the shared resources and their state. Each fact with the version it was seen at.

- {Tool} {version}. {The fact, and how it was seen.}

### 5. Repeating the checks

{The scratch paths, which may vanish with this session, and how to recreate them. The scripts, in
full when short. The exact commands of every check, in the order run, and what to compare after each.}

### 6. Open, owed and next

- {What is open, owed or half done, and who is waiting on it.}
- {What you would do next.}
- {Contingencies. If {a condition}, then {the action}.}
- {Ideas not acted on, since nobody asked.}

---

## Part 2, the readback

> The incoming incarnation sends this as its reply to the handover request, before it acts, from its
> session address. List what you checked against the machine and what you could not.

[handover-ack] {the handover request's id}, readback from {the incoming session address}

- I am {member.team@host}, the {role}, in session {the session id}.
- My task is {the task}, and done means {the criteria}.
- My authority is {the record's actions and resources} for the life of this session. Reserved to the
  principal are {the decisions}.
- My next action is {the action}.
- I checked {the items of the note I verified, with how}. I could not verify {the items, and why}.

---

## Part 3, the confirmation

> Sent as a message by the outgoing incarnation or the director. A readback that does not match the
> note gets a clarify instead, naming what is wrong, and nothing moves until a readback is confirmed.
> The director records the cutover time in its checkpoint. If the incoming incarnation is gone before
> this point, the outgoing one or the director still owns everything (protocol 9.4).

[accept] {the handover request's id}, readback confirmed, {member.team@host} now routes to {the
incoming session address} as of {an absolute time with its zone}, with the obligations the note
assigns to it

{The outgoing session stays at {its session address} until {an absolute time with its zone or the
condition}, to answer questions and finish {the obligations the table leaves with it, by id}, then
leaves.}

nomos v0 handover

## Orchestrator variant

> Use all three parts above, adding the fields below to the note and readback. Protocol 9.4 and 9.5
> govern the transfer; this form adds no authority. Start at the 80% notice or a planned boundary near
> it, finish or park the current step, and save the checkpoint. With keryx today, leave, spawn the
> same address from the unchanged root record and this note, and stay open without an address for
> the checks in `../keryx.md`, Handover today. Delete these guidance lines after filling the form.

### Additional note fields

- The checkpoint is {path}, saved at {absolute time with its zone}; the current step is {finished or parked, and
  how to resume it}.
- The root record is {its complete text, word for word, including its principal channel}; the launch
  prompt and handover request are {paths}. The successor uses {harness, window, ceiling and mode}.
- The expected readback context is {range}, based on {same-harness measurements and the required
  reading}. The outgoing process and pane are {pid, session id and pane}.

| Live directed session | Pane | Request | Deadline | Heartbeat |
|---|---|---|---|---|
| {address and session id} | {pane} | {id and task} | {absolute time with its zone} | {holder, interval, next check and process or scheduler id} |

| Open request | Direction and peer | State | Deadline | Holder after cutover |
|---|---|---|---|---|
| {id} | {received from or sent to address} | {pending, in progress or delivered awaiting decision} | {absolute time with its zone} | {incoming or outgoing, until what point} |

| Background loop or watcher | Current process or scheduler id | Stop or hand over | Verification |
|---|---|---|---|
| {purpose, command and log path} | {id and owner} | {new holder and point, or stop} | {command, output and time} |

| Decision pending with the principal | Evidence and declared channel | Next action |
|---|---|---|
| {question or request id} | {file and channel, with any named relay} | {owner and when to check} |

| Resource awaiting cleanup | Created by this run | Grant or reservation | Disposition and holder | Verification |
|---|---|---|---|---|
| {pane, address, worktree, branch, scratch file, watcher, board, trust entry or test directory} | {creation record} | {record field} | {remove, retain or propose, with reason and when} | {check command and result} |

### Additional readback and outgoing checks

> The successor replies to the handover request with Part 2 and its observed inventories. The
> outgoing incarnation fills this table from those observations and its own checks before Part 3.

| Check | Observation, command and output | Pass or mismatch |
|---|---|---|
| Readback and unchanged root record | {compare task, authority, next action and full record with the note} | {result} |
| Address holder | {the transport's who output (keryx who with keryx) naming the expected session and pane} | {result} |
| Readback context | {stamped figure and comparison with the recorded range} | {result} |
| Ping round trip and bell | {ping id and token, bell observation, reply id; an explicit ring for same-address mail} | {result} |
| Live sessions and requests both ways | {who and status comparison, with changes since the note reconciled by id} | {result} |
| Armed heartbeat | {interval, next check, process or scheduler id, and check that it is armed} | {result} |

Correct a mismatch with `[clarify]`. If it remains wrong, have the successor leave, check it cannot
act, close it and start another from the same record and corrected note. A second failed successor
goes to the principal. All checks must pass before the outgoing incarnation sends Part 3's timed
`[accept]`, stops or hands over its watchers and exits. The successor records cutover, notifies peers
with open work, and closes the old pane after checking its process is gone. Keep renewals, handovers
and context figures in the run log; tell the principal only when the change needs them, such as a
question, decision or changed commitment. A changed record or two failed successors still require
their decision. (protocol 9.4, 9.5; N17; low; playbook, Cleanup)

nomos v0 orchestrator handover
