# Escalation, nomos v0

> An escalation brings the principal a decision the team may not take (protocol 10). It goes through
> the team's one channel to the principal (10.2), sent by the orchestrator. The text under its
> `decision` block follows Situation, Background, Assessment, Recommendation, so the principal
> can decide from it without transcripts. Put the whole escalation where the principal reads when
> deciding, not in output that a question dialog hides.
>
> A message from the principal's own inbox named in the root record is the principal's word for
> reserved acts and record changes too (10.2). Escalate what is reserved, outside the plan or a
> blocker the team cannot resolve within its authority. A design question inside the plan is the
> orchestrator's to decide.
>
> Send one ask as a request with a deadline. Use `human-message.md` (10.5 to 10.9) for the title,
> block and closing line, exactly once each, as shown below. The title is plain words on line 1,
> at most 80 characters; the block begins on line 2. Its option ids and labels match the numbered
> Assessment. Give the deadline once in the text, equal to the transport's; never put it in the
> block. Silence on this reserved decision only waits or keeps things as they are (10.8).
>
> Fill every {placeholder} and delete these guidance lines. If using this under an existing
> human-message title and block, take only Situation through Recommendation and keep that form's
> single footer. Apply the field and total-size limits in `human-message.md`.

---

{The decision needed, in plain words, at most 80 characters}
```nomos
{"kind": "decision",
 "options": [{"id": "{id}", "label": "{label}"},
             {"id": "{id}", "label": "{label}"}],
 "recommended": "{id}",
 "blocks": "{what waits for the answer, or replace this string with null}",
 "meanwhile": "{what the team does while it waits}",
 "if_silent": "{wait or keep things as they are}"}
```

## Situation

{What happened and what decision it needs, in two or three sentences. Name who is affected, what
waits for the answer and what the team does meanwhile, or say that nothing waits.}

## Background

- {A fact}, {its evidence class and where to see it, such as the command and its output, a file and
  line, or a citation}.

## Assessment

1. {Label} (`{id}`). {What it costs, what it risks, and whether it can be undone.}
2. {Label} (`{id}`). {The same.}

## Recommendation

{What the team would do and why, in two or three sentences. Omit recommended from the block if
there is no recommendation, it is conditional or teams disagree, and explain that here.}

{What waits or stays as it is if no answer comes by {the request's absolute deadline with zone}.
Silence never authorizes the reserved act.}

{How to answer, such as "reply 1 or 2, or the id", or the exact words that authorize an outward act.
The principal answers in the channel the escalation came through.}

nomos v0 human message
