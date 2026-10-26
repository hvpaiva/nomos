# Human message, nomos v0

> A message to a human starts with a plain title on line 1, at most 80 characters, not a heading,
> list, quote or fence. Its `nomos` block starts on line 2, and the text below stands alone (protocol
> 10.5 to 10.9). Pick the kind by what the human must do now. An ask (`decision`, `choice`,
> `question`, `action`) goes as a request with a deadline and carries one ask; its block is required.
> A `suggestion`, `notice` or `result` may omit the block. Write in the human's language, with no
> bracketed kind tag. Put the deadline in the request's deadline and once in the text, never in the
> block. When the block and the text disagree, the text governs; send a correction with `replaces`
> and withdraw a replaced request.
>
> Use your kind below in place of the form's block. Option ids have 1 to 24 lowercase ASCII letters,
> digits or hyphens, start with a letter and are unique. Labels are 1 to 60 characters in the human's
> language. `decision` and `choice` need 2 to 6 options.
>
> - A `decision` uses the form's block with `"kind": "decision"`, with no `default`. Its `if_silent`
>   waits or keeps things as they are. The text follows `escalation.md` for more than a short case.
> - A `choice` uses `"kind": "choice"`, adding `"default": "{id}"` only when that option is reversible
>   and inside the team's authority.
> - A `question` uses `{"kind": "question", "blocks": null, "meanwhile": "{what the team does}",
>   "if_silent": "{what the team does without an answer}"}`, with `options` for suggested answers.
> - An `action` uses that block with `"kind": "action"` and no `options`. Omit `text`; its requirement
>   is fixed. Answers are `done`, `failed` and `declined`; only `failed` requires words to report
>   the failure.
> - A `suggestion` uses `{"kind": "suggestion"}`, with `links` or `files`; nothing waits on it.
> - A `notice` uses `{"kind": "notice"}`, adding `"replaces": "{message id}"` for a correction.
>   A commitment reply to a human's work request is a notice saying what will be done and by when,
>   with an absolute time and zone (5.3), followed later by a result message naming that request.
> - A `result` uses `{"kind": "result", "outcome": "{done|partial|failed}", "follows": "{request id}"}`.
>
> Any kind may add `"files": [{"path": "{path}", "label": "{label}"}]`, `"links": [{"url":
> "{https url}", "label": "{label}"}]` and `replaces`. Each array has at most 3 entries. Files are
> openable regular text files with absolute or `~/` paths; folders go in the text. The page's
> configured roots still govern which files it can open. `blocks`, `meanwhile` and `if_silent` are
> non-blank strings of at most 80 characters; `blocks` may instead be `null` when nothing waits.
> With options, an ask may add `"select": "many"` and a `recommended` array. Omit `recommended` when
> there is no recommendation, it is conditional or teams disagree, and explain that in the text.
> Except for `action`, `text` is `optional` or `required`, defaulting to optional with options and
> required without. An option with no words is complete unless text is required. A question without
> options needs words.
>
> Keep the block within 16 lines including fences and 1,024 bytes even when individual fields fit,
> with no time, date or HTML. Unknown keys are ignored; invalid blocks fall back to text without
> buttons. Changed field meanings need a new info string, such as `nomos-1`, not a version key.
> Put a draft for agent review inside a longer fence; a block sent to an agent is inert.
>
> The page writes an answer's label on line 1 and its block on line 2, for example
> `{"kind": "answer", "answer": "keep"}`, then the human's words verbatim, possibly empty. The first
> line is the page's, not the human's words. Use the option's exact label, labels joined by "; " and
> cut at 80 characters for select many, or the action's outcome word in the human's language. The
> `answer` value is the chosen id, an array for many, an action outcome, or `take` or `skip` for a
> suggestion; omit it for words only. Read conditions in the words even when an option was chosen.
> Without a block, words naming exactly one option without doubt count as the choice, including
> "the recommended one" for a single recommendation. An undecided decision needs a new request
> naming the old one with `follows` (10.9).
>
> Fill every {placeholder}, drop the lines your kind does not use and delete these guidance lines.

---

{The title, the ask or the news in one line of plain words, at most 80 characters}
```nomos
{"kind": "{kind}",
 "options": [{"id": "{id}", "label": "{label}"},
             {"id": "{id}", "label": "{label}"}],
 "recommended": "{id}",
 "blocks": "{what waits for the answer}",
 "meanwhile": "{what the team does while it waits}",
 "if_silent": "{what the team does if no answer comes}"}
```

{What happened and why it reaches the human, in two or three sentences, naming every referent.}

1. {Label} (`{id}`). {What it costs, risks, and whether it can be undone.} {Recommended, if it is.}
2. {Label} (`{id}`). {The same.}

{What waits for the answer, and what the team does meanwhile.} {What the team does if no answer
comes by {the request's deadline, absolute, in the human's zone}.}

{How to answer, such as "Responda 1 ou 2, ou o id".}

nomos v0 human message
