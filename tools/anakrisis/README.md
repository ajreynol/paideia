# anakrisis

**Footing:** `unadvertised-child` — the parent's front page does not name this
project, and nothing a reader of paideia sees points inward to it. The
argument behind that changed with the move and is weaker now: in dokimasia this
was speculative work that would have borrowed a working tool's credibility the
moment it were pointed at. paideia is a new and empty repository with no
credibility to borrow, so what is left is the plain half: a review of
somebody's pull request has earned nothing yet, and `tools/` is how it is
discovered. That is enough.

*What does this pull request do to cvc5's proof-completeness inventory — and is
that worth a maintainer's time?*

**Internal.** A research project held to
[kanon's research-project rules](https://github.com/ajreynol/kanon/blob/main/docs/policy.md)
by choice rather than by obligation — paideia is an **associate** of the Eunoia
ecosystem and owes it nothing — and not a project announcement. It is not linked
from the root [`README`](../../README.md), which is paideia's only front page,
and it has no row in the [documentation index](../../docs/README.md) either:
that index names what this repository publishes, and a research project is not
among it. `ajreynol/paideia` is a **public** remote: unadvertised means *not
pointed at*, not *not visible*. **Nothing here is anybody's opinion of anybody's
pull request** — not paideia's and not dokimasia's — and no review written here
has been sent to anyone.

**An island, and a weak kind of one.** anakrisis runs dokimasia's analyses as a
subprocess against two trees and diffs the results; it reads cvc5's tree and its
own ledger. The island property says much less here than the research-project
rules intend, because there is no working tool in this repository to be
independent of — paideia is a front page, some documents and two research
projects. What it does still say is the operative half: nothing imports this, no
test covers it, no baseline ratchets it, no CI job runs it, its one script is
invoked by hand from somebody else's checkout, and deleting the directory leaves
the repository exactly as functional.

**The analysis it subtracts is in another repository, and it has to be told
where.** `run_anakrisis --delta` computes the delta by invoking `python3 -m
dokimasia report`, so it needs a dokimasia checkout. `DOKIMASIA_ROOT` names one;
failing that it tries a `dokimasia` checkout beside this repository, which is how
these trees are usually laid out. It guesses no further, it fetches nothing, and
**it refuses to run when it cannot find one** — naming what was missing, whether
that is the module the delta runs or any of the three documents the read half is
scoped to, every one of which the prompt hands an assistant by path. Failing
closed is affordable here and is not a precaution: empty output is how this
spells *nothing changed*, so a run that could not read the analyses has to stop
rather than report a clean result.

**Where "read-only" stops, stated rather than assumed.** Two places, both
narrow. *Inside this repository* it writes only within `tools/anakrisis/`, and
it never writes a baseline: the delta is computed by running the analyses at two
commits and comparing the two runs, so nothing it does can move a number
dokimasia ratchets. *Outside* it, in the cvc5 checkout it is run from, it adds a
detached `git worktree` at the merge base and removes it again — a read of an
old commit that git happens to spell as a directory. It does not check anything
out in the tree you are on, and it refuses to run at all if that tree is dirty.
If either of those ever stops being true, this paragraph is the thing that was
wrong.

## On the name

**ἀνάκρισις** — the preliminary examination in Athenian law. Before a case came
to trial the magistrate held an *anakrisis*: both parties were questioned, the
documents and depositions each meant to rely on were produced and sealed in the
ἐχῖνος, and **nothing that had not been put in at the anakrisis could be
produced at the trial**. It did not decide the case. It decided what the case
was, and what the court would be allowed to see.

Both halves are this project. It examines a change **before** it is admitted
and it **does not rule** — merging is a maintainer's, exactly as sending is
under
[`pr-policy.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/pr-policy.md).
And the sealed jar is the discipline this project most needs: a review may rely
only on what it recorded at review time, which is dokimasia's **run-it**
applied to a review rather than to a finding.

**It rhymes with δοκιμασία, and a rhyme is not an argument.** δοκιμασία is the
scrutiny of the officer **before office** and ἀνάκρισις is the examination of
the case **before trial**: one asks whether the code already in the tree is fit
to serve, and this asks the same question of the change wanting in. That reads
well and settles nothing about where either belongs, and nothing is invented
here in its place. The name fits for the reason the two paragraphs above give,
which is the part that depends on nothing outside this directory: an
examination, before the thing is admitted, that decides nothing.

*The alternative with a real argument behind it was* **κρίσις** *— the judgement
itself. It is the wrong word for the same reason it is the tempting one: this
project produces no judgement, and a name promising one would have to be
explained away on its first page. A name whose explanation needs a
qualification is a scope that has not been decided.* ἐπίκρισις *reads better
still and is taken elsewhere in the ecosystem.*

## The charter

**The question.** cvc5 takes pull requests against `main` continuously, and
reviewing them is one of the most expensive standing jobs its maintainers have.
Almost none of those changes are *about* proofs, and yet any of them can add a
path that produces no proof — a new inference with no reconstruction, a rule the
Eunoia seam cannot print, an option default that safe mode does not disable.
**Can a reviewer say what a change does to that inventory before it lands, and
would a maintainer rather have that than not?**

**The baseline is a tool that already exists, and it is what this has to
beat.**
[`prompts/check_cvc5_issue`](https://github.com/ajreynol/dokimasia/blob/main/prompts/check_cvc5_issue)
is prompt-based tooling with no instrument in it at all: it hands an assistant
a prompt and a cvc5 checkout, and it gets useful work out of the arrangement. A
review of a pull request can be had the same way, today, for one command. So
the question is **not** whether an assistant can review a change — that is
settled, and the answer is yes. It is whether **the computed delta adds
anything**, and the only honest way to find out is to run both arms on the same
change and compare. `run_anakrisis --baseline` is that control: the same prompt
with the delta withheld, differing from the real one by the delta and by
nothing else.

**What makes it answerable at all.** dokimasia already computes the inventory
from a checkout, with no build, in about a second. Running it twice — at the
merge base and at the head — and subtracting is the whole mechanism, and what it
needs is dokimasia *to hand* rather than dokimasia's repository around it. The
result is a claim about a change that few are in a position to make, and it is
**cheap-to-refute** by construction — two commands and a diff, and anybody with
both checkouts can run them.

**The goals, in order.**

0. **The delta.** Run dokimasia's analyses at the merge base and at the head,
   and report what the change did to the inventory. Numbered zero because it is
   mechanical: it is computed rather than judged, and an assistant reads it
   rather than producing it. **Most pull requests will have an empty delta**,
   and that is the expected result rather than a failed run.
1. **Review one pull request end to end.** The delta, plus a reading of the diff
   scoped to what dokimasia has evidence about, written into the ledger in
   a shape a maintainer could act on. A review nobody could act on is an
   opinion.
2. **Record what the maintainers actually did.** Merged as proposed, merged with
   changes, changed for a reason we did not see, closed. The delta between our
   review and the outcome is the whole asset; everything else is bookkeeping.
3. **Beat the baseline, or say that it was not beaten.** For each pull request
   worked, run both arms and compare: which review lines were acted on, which
   were noise, and whether any of the difference came from the delta. The
   honest expected answer is *the computed half was worth it and the read was
   not* — and *neither arm was worth it* is an equally publishable result and
   the one that would retire this project.
4. **Say whether the empty delta is trustworthy.** A tool whose commonest output
   is *nothing to say* is only useful if that output can be relied on, and
   today it cannot be: see the two limits below.

**The wishue** — the goal if this went unusually well, and not a commitment.
The delta stops being something a person carries and becomes a check cvc5 runs
itself, on every pull request, in its own CI. That is **R11** in dokimasia's
[register of
asks](https://github.com/ajreynol/dokimasia/blob/main/docs/issues.md#open--asks),
and dokimasia's
[`TODO.md`](https://github.com/ajreynol/dokimasia/blob/main/TODO.md) currently
declines to build a machine format for it until somebody asks for exactly this.
Asking crosses a repository boundary, so the ask is staged as `D2` in
[paideia's discussion file](../../docs/discussion.md) — written down for a
person to carry, and sent to nobody.

**Out of scope**, explicitly, because a research project with no boundary
becomes a second tool:

- **General code review.** Not style, not naming, not performance, not
  architecture. cvc5's own reviewers and CI do all of that better, and an
  unsolicited opinion on somebody's variable names spends credibility on work
  that has earned none — paideia's, which is a smaller thing to spend only
  because there is less of it. The
  read half is scoped to what dokimasia has measured: the [hygiene
  rules](https://github.com/ajreynol/dokimasia/blob/main/docs/hygiene.md), the
  [contract](https://github.com/ajreynol/dokimasia/blob/main/docs/contract.md),
  and whatever the delta pointed at.
- **Reviewing pull requests we have nothing to say about.** The instrument
  speaks when it has something to say. *Nothing to say* is a complete outcome
  and is not written up anywhere but the ledger.
- **Sending anything.** No comment, no review, no approval, no push, no tracker
  call — ever. The artifact is a file in this directory and a person decides
  what, if anything, becomes of it.
- **Deciding whether a pull request should be merged.** The examination is not
  the trial. Nothing here carries a verdict on somebody's change.
- **Proof-completeness *findings*.** If a review turns up a hole rather than a
  question about a change, it leaves this repository altogether and enters
  dokimasia's register at
  [`docs/issues.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/issues.md),
  where it is held to that project's bar like anything else. That is a carry
  between repositories, and a person does it.
- **Speaking for dokimasia, or for paideia.** Nothing here is either one's
  position.

**Is there a paper in it?** No, and probably not ever. The mechanism is a
subtraction between two runs of somebody else's tool, and the interesting part
would be goal 3 — what a review has to carry to be wanted — which is a fact
about one project's maintainers rather than a result. If that turns out to
generalise, the place for it is [dokimasia's
`postmortem.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/postmortem.md)
— somebody else's document, and so a person's to carry it to — and not a
`report/` here.

## The two limits, named before the first use

Both were found by running the thing, and both bound what an empty delta means.

**It sees only what dokimasia prints.** `dokimasia report` is prose written
for a reader: it summarises, it truncates lists, and it names a count where the
count is the point. Anything it does not print is invisible here, so **an empty
delta is not a clean bill of health** — it is a statement about what two runs of
one program printed. This is dokimasia's standing warning applied to a tool
that reads its output, and it is also the argument for the wishue: a machine
format would make the subtraction exact, and until there is one the delta is a
diff of prose.

**It is static, and it reads `src/` only.** No build, no run, no benchmark. A
change whose entire effect is at runtime shows nothing here, and dokimasia's
own record is that a static argument reading correctly is worth very little
until something has been run — three of them read correctly and were false, as
[`pr-policy.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/pr-policy.md#why-the-bar-names-execution)
records. A delta is evidence that something moved, never evidence about what it
does.

## The PR policy is borrowed, and unchanged

**anakrisis posts nothing to cvc5.** The rule comes from [dokimasia's
`pr-policy.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/pr-policy.md),
which does not govern this project by being its parent's: paideia is an
associate, owes the ecosystem nothing, and has no policy of its own to impose.
It governs because this project keeps it — and keeping it is worth nothing
unless the standard stays where it was, so: **no separate channel, and no
lighter standard than it had in dokimasia.** This section says only how that
lands on a project whose whole output looks like something you would paste into
a review box.

- **The act stays with a person**, and the temptation is at its worst here. A
  finished review is one copy-paste from being delivered, and delivering it
  would put an unrequested opinion under a maintainer's nose with this
  repository's name on it. Approval to *write* a review is not approval to
  *send* one.
- **The verdict is this project's.** Applying [the
  bar](https://github.com/ajreynol/dokimasia/blob/main/docs/pr-policy.md#the-bar)
  to a review rather than to a finding: **theirs-not-ours** means a delta
  caused by our own parser is fixed here and never mentioned to anybody;
  **worth-the-attention** is the rule that will fail most often, and failing it
  is the correct outcome for most pull requests.
- **The guidance stays with the maintainer**, including this charter. A
  research project is started and ended by a person, and its scope changes the
  same way.

The [research-project rules](https://github.com/ajreynol/kanon/blob/main/docs/policy.md)
say the same from the other side: nothing leaves the island by machine, a
research project has no separate channel and no lighter standard than its host,
and what it may do on its own is accumulate a ledger inside its own directory.

**On reading the tracker.** The script makes no network calls. It requires the
pull request to be checked out already, and prints the one command that does
that rather than running it — fetching is the person's, or an assistant's in a
session a person started, exactly as dokimasia arranges everything else that
touches the outside world.

## What it inherits from dokimasia, and where

This project has no evidence of its own. dokimasia has it — cases it ran,
behaviours it verified, places the documentation and the implementation
disagreed — and the rule is to cite what is taken, so a reader can tell what was
checked from what was reasoned. None of the following is in this repository, and
every link in the table leaves it.

| inherited | where it was established |
| --- | --- |
| the inventory the delta is a delta of — trust ids, unreconstructed inferences, seam refusals, the checker's surface | [`docs/checks.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/checks.md), and the baselines beside `tests/` |
| that a quiet run is a fact about the check and not about cvc5 | [dokimasia's `README.md`](https://github.com/ajreynol/dokimasia/blob/main/README.md), first blockquote |
| that a claim about behaviour is worthless until something has been run | [`docs/pr-policy.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/pr-policy.md#why-the-bar-names-execution) — three static arguments that read correctly and were false |
| what a proof-hygiene defect looks like, so the read half has a list rather than a hunch | [`docs/hygiene.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/hygiene.md) |
| what cvc5 actually promises, so a review can tell a violated promise from a disliked design | [`docs/contract.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/contract.md) |
| the `TRIAGE:` / `HUMAN RESPONSE:` frame, and that only an artifact settles anything | [`docs/workflows.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/workflows.md), [`docs/findings.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/findings.md) |
| running an assistant against a cvc5 checkout without touching anything outside it | [`prompts/check_cvc5_issue`](https://github.com/ajreynol/dokimasia/blob/main/prompts/check_cvc5_issue), [`../empeiria/README.md`](../empeiria/README.md) |
| **the baseline this project has to beat** — that prompt-based tooling with no instrument already produces useful work | [`prompts/check_cvc5_issue`](https://github.com/ajreynol/dokimasia/blob/main/prompts/check_cvc5_issue), which is the same job with the delta subtracted out |

**The instrument is borrowed, and that is the standing risk.** Without the
inventory there is no delta, and without the delta this is a general-purpose
reviewer with no instrument and nothing to distinguish it. The inventory is
something this project reaches across a repository boundary for rather than
something it sits inside, so every row above is a citation of an outside source
rather than an inheritance — and a borrowed instrument is easier to leave broken
than a local one. What stands against that is the refusal: the command stops and
says what it could not find, rather than reviewing a change without the one
thing it was built to bring.

## Using it

Everything but `--list` and `--record` needs a dokimasia checkout, because
everything else either computes the delta or names dokimasia's documents in a
prompt. Set `DOKIMASIA_ROOT` where one is not beside this repository.

```bash
cd ~/cvc5
gh pr checkout 12893                  # the person's, or an assistant's: a network call
run_anakrisis 12893 --delta           # the inventory delta alone; no assistant
run_anakrisis 12893                   # the delta, then a review by an assistant
run_anakrisis 12893 --baseline        # the same review, delta withheld: the control
run_anakrisis 12893 --show-prompt     # print the prompt, run no assistant
run_anakrisis --record 12893          # afterwards: what the maintainers did
run_anakrisis --list                  # what has been reviewed, and what came back
```

`--show-prompt` computes the delta, because the delta is *in* the prompt; what
it does not do is start an assistant.

The protocol the review follows — what a review must carry, the block it is
written in, and what *nothing to say* means — is [`review.md`](review.md). The
record is [`ledger/`](ledger/). The plan is [`TODO.md`](TODO.md).

## Status

**Started 2026-09-01**, by an explicit human instruction, which is the only way
one of these may begin. **Moved out of dokimasia into paideia on 2026-09-18**,
by the same kind of instruction.

**`run_anakrisis --delta` and `--baseline` run**, against a dokimasia checkout
they are pointed at. The two limits above were found by running the first: it
compared the two reports with `diff`, and most of what came back was line
numbers moving. Nothing past the interface exists — no pull request has been
reviewed in either arm, the ledger is empty, and the review protocol in
[`review.md`](review.md) is a first guess written before a single review, which
is exactly the condition under which a format is wrong.

There are three endings and a person picks: it graduates into its own
repository, it is folded into the parent, or it is retired in place with a note
saying what was learned. Going quiet is not one of them. **What *folded into
the parent* would mean here is undecided**: the parent is paideia, which has
nothing to fold anything into, and the instrument this project would fold back
toward is in dokimasia.

**Owed elsewhere, and not ours to make.** The ecosystem's authoritative name
register is
[kanon's glossary](https://github.com/ajreynol/kanon/blob/main/docs/glossary.md),
kept by the president of eo, and editing somebody else's register is a person's
edit. Read on 2026-09-18, its entry for anakrisis is wrong in two places — it
calls this a *child project of dokimasia*, and its **Charter** link points at a
path in `ajreynol/dokimasia` that no longer exists, since that repository
removed the directory — and there is no entry for paideia at all. Both
corrections are asked for as `D1` in [paideia's discussion
file](../../docs/discussion.md), staged there and carried by nobody but a
person.
