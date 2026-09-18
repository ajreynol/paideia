# The review protocol

What a review of a cvc5 pull request has to carry, the shape it is written in,
and what it may never contain. Read
[`README.md`](README.md) first — this document assumes the charter, and in
particular assumes that nothing written here is sent anywhere.

**This is a first guess.** It was written before a single pull request had been
reviewed, which is the condition under which a format is reliably wrong. It is
meant to be replaced after two or three real ones, and
[`TODO.md`](TODO.md) says so as a task rather than as a hope.

**And it currently describes something that does not run.** The delta half needs
dokimasia's analyses, which this repository no longer contains; see the charter.
Nothing in this protocol has been changed on that account, because what the
protocol should say is a question for after the delta works again.

## A review has two halves and they are not equally good

**The delta is computed. The read is judged.** Everything about how a review is
written follows from keeping those two apart, because they fail in opposite
ways: the delta is narrow and reliable, and the read is broad and is where this
project will embarrass itself.

| | the delta | the read |
| --- | --- | --- |
| produced by | `run_anakrisis --delta` — two runs of dokimasia's analyses, subtracted | an assistant, reading the diff |
| what it can say | *this change moved a number dokimasia tracks* | *this looks like it does something dokimasia has evidence about* |
| how it is wrong | dokimasia's analysis is wrong, or the change is invisible to it | any of the ordinary ways a confident reading is wrong |
| in the review | quoted verbatim, never paraphrased | at most a few lines, each citing what grounds it |

**A review with no delta and no cited ground is not written.** That is the whole
of the filter, and it is what keeps this from being a general-purpose reviewer
with an opinion about somebody's naming.

**And there is a third thing a review can be, which is a control.**
`run_anakrisis --baseline` runs the same review with the delta withheld,
because the baseline for this task is not *no review*: it is
[`check_cvc5_issue`](https://github.com/ajreynol/dokimasia/blob/main/prompts/check_cvc5_issue),
prompt-based tooling with no instrument in it, which already produces useful
work. A control review is written to the same protocol, is labelled `arm:
baseline` in its header, and is the only thing that can turn *the delta helped*
from an impression into a comparison. Where a pull request has both, neither is
read without the other.

## What the delta may claim, exactly

The delta is a diff of what `dokimasia report` printed at two commits, with line
numbers normalised away and reordering ignored. So a delta line means:

> at the head of this branch, dokimasia's analyses print this where they
> printed that at the merge base.

It does **not** mean the change caused it — a rebase, an unrelated file, or a
count that moved for a reason elsewhere in the diff all produce the same line.
Attributing a delta line to the change is the first thing the read has to do,
and it is done by finding the hunk in `git diff BASE...HEAD` that produced it.
**A delta line nobody could attribute stays in the review as unattributed**,
which is more useful than dropping it and much more useful than guessing.

Two limits bound every delta and belong in any review that quotes one; the
charter states them in full and they are not restated here beyond the sentence
that matters: **an empty delta is not a clean bill of health.**

## What the read is allowed to be about

Scoped to what dokimasia has measured, because that is the only thing this can
say that a cvc5 reviewer could not say faster. **Since the move every document
in that scope is in another repository** — all four links below leave paideia,
and a reviewer who cannot open them cannot write the read half:

- **A new hole.** An inference with no reconstruction, a rule the seam cannot
  print, a trust step with no stated reason, a proofless call on a path that
  had one. The ten [hygiene
  rules](https://github.com/ajreynol/dokimasia/blob/main/docs/hygiene.md) are
  the list, each with the measurement behind it.
- **A promise that stopped holding.** Something
  [`contract.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/contract.md)
  says cvc5 guarantees, that this change makes untrue — most sharply, an option
  that safe mode does not disable and that declares no proof support.
- **A coupling.** Something the change breaks that dokimasia parses, which is
  ours to fix here and is never mentioned to anybody: see
  [`coupling.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/coupling.md).
- **Whatever the delta pointed at**, and nothing else in the diff.

Everything else is out of scope, and the charter says why.

## The block

One file per pull request, `ledger/<N>.md`, in this shape. `run_anakrisis`
writes the header and the assistant fills the rest.

```
# PR #N -- <title>

reviewed: <date>
arm:      delta | baseline
base:     <merge-base sha>
head:     <sha>

DELTA:
<the output of --delta, verbatim, or "none">

TRIAGE: nothing to say | question | objection | cannot tell -- pending review

<For anything other than "nothing to say": what it is, where in the diff, and
 what would show it is wrong. One paragraph per point, and each point names
 either a delta line or one of dokimasia's documents that grounds it.>

OBSERVED, NOT ACTED ON:
<optional -- anything true and out of scope, in one line each>

HUMAN RESPONSE:
```

**The four labels.**

| label | means |
| --- | --- |
| **nothing to say** | the delta is empty, or is attributable to nothing dokimasia has evidence about. The commonest outcome, and a complete one |
| **question** | something a maintainer should answer before merging. Most real output lands here, because most of what this can see is a fact whose significance somebody else knows |
| **objection** | something looks wrong, and there is evidence. Rare, and held to dokimasia's bar in full — a claim about behaviour needs something to have been run |
| **cannot tell** | in scope, and we cannot decide. An honest answer and a useful one; it names what would settle it |

**`HUMAN RESPONSE:` stays empty.** It is a maintainer's, and the two labels
exist to keep what an assistant concluded apart from what a person decided.
`run_anakrisis --record N` fills it afterwards with what the maintainers
actually did, in their words rather than a summary — the difference between the
two is the only thing in the ledger that is an asset.

## The sealed jar

A review may rely only on what it recorded at review time. Concretely: the
commit shas go in the block, the delta goes in verbatim, and a command that was
run is quoted with its output. **Anything added afterwards is a new review of a
different thing**, not a correction of this one, and the block says so if it
happens.

This is dokimasia's **run-it** applied to a review, and it is here because a
review is the artifact most likely to be tidied up after the fact: the outcome
arrives, and the temptation is to remember having been less wrong. What makes
goal 3 in the charter answerable at all is that the record was sealed before the
answer was known.

## What a review may never contain

- **Anything to be sent.** No text addressed to a contributor, no wording drafted
  for a review box, no "you could reply with". A file here that reads as a
  message is a file somebody will paste. Write about the change, to a reader
  here.
- **A verdict on merging.** The examination is not the trial.
- **A judgement about a person.** The subject is a diff.
- **A number nobody has measured.** Every quantity comes from the delta or from
  a document that names the command behind it, and those documents are
  dokimasia's rather than this repository's.
- **A restatement of dokimasia's other results.** A check that reports nothing
  is not evidence that anything is complete, and quoting a quiet run beside a
  pull request is exactly how that mistake gets made.
