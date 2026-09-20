# empeiria

**The feature request.** *Hand a cvc5 issue to a front end and get back a
reproduction, a located cause, a patch and a regression test — and have it get
better at that as the maintainers answer.*

Every bug report costs a maintainer the same expensive hour before any judgement
is possible: build it, reproduce it, find the subsystem, decide whether it is a
bug at all. A front end that arrived with those four already done — and a patch
worth editing rather than rewriting — would be worth having even when it is
wrong, because a wrong reproduction is still a reproduction.

`run_empeiria 12905` is that attempt, in a working tree a person is driving.
**What makes it more than a prompt is that the loop closes**: the maintainer
answers, the answer is recorded beside what this project produced, and the
difference is evidence about what the next attempt should do differently. Nobody
knows yet whether that difference shrinks. That is the question.

**Fix first, learn second, and the order is fixed.** The ecosystem's charter is
*be useful fast*, and a project that made somebody wait for a fix while it took
notes would have inverted its own reason for existing. The ledger is written
afterwards, by a separate command, and nothing about it gates the work.

## Two projects, one question

paideia runs two research projects at opposite ends of cvc5's tracker. Each is
a feature request nobody has built, and each asks whether a front end can
produce something a maintainer actually wants.

| | works on | the feature request |
| --- | --- | --- |
| **empeiria** — here | open **issues** | reproduce it, locate it, fix it — and get better at it from how the maintainers answered the last one |
| [**anakrisis**](../anakrisis/README.md) | incoming **pull requests** | say what a change moved before it lands, and whether that was worth reading |

Each writes a ledger, each records what the maintainers actually did, and
**neither sends anything anywhere**. Neither imports the other. What they differ
in is the instrument: anakrisis computes a delta by running
[dokimasia's analyzer][dok] at two commits, and this project carries nothing of
the kind — which is why anakrisis's control arm is exactly this arrangement, an
assistant with a checkout and nothing else.

## The charter

**The question.** Can a front end work cvc5's issues — triage *and* fix — and
get measurably better at it by learning from how the maintainers answered the
last ones?

**Why it might work.** The signal is free and nobody is collecting it: every
issue worked here ends with a maintainer doing something public, so each case
scores itself. A fix also carries its own refutation — [built, and the
reproducer run before and after][bar] — so a wrong attempt is cheap to detect
rather than cheap to believe.

**Why it might not.** A patch that reads well can be a hypothesis wearing a
diff; the corrections may turn out to be one-offs with no shape to learn; and
the honest failure mode is a project that produces plausible work nobody wants
to review.

**The goals, in order.**

0. **Keep an index of every open issue** — [`triage.md`](docs/triage.md), refreshed
   by `run_empeiria --triage`. Numbered zero because it is a standing obligation
   rather than a result: it aims goal 1 and produces nothing on its own. **It is
   the first place to look and the last place to trust** — written from issue
   text by something that reproduced nothing, and no row in it may be cited as
   evidence anywhere.
1. **Work an issue end to end.** Reproduce it, locate it, produce a fix as a
   patch and a regression test, in a working tree a person is driving. A triage
   nobody tried to act on is an opinion.
2. **Record what the response taught.** What this project produced, what the
   maintainer actually did, and the **delta** between them. That delta is the
   asset; everything else is bookkeeping.
3. **Find the recurring shapes.** Across enough deltas, whether the corrections
   fall into a few kinds — wrong subsystem, wrong severity, already known, not a
   bug, a fix that treats the symptom.
4. **Make the next attempt better**, and say by how much against a held-out set
   of issues fixed before the measurement was designed. An improvement nobody
   measured did not happen.

**The wishue** — the goal if this went unusually well, and not a commitment. A
front end that reads a fresh cvc5 issue and produces a fix a maintainer applies
with edits they would call minor, measured against what they actually did rather
than against whether the patch reads well.

**Out of scope.**

- **Sending anything upstream.** Producing a fix is in scope; delivering it is
  not, ever — no push, no `gh pr create`, no tracker call. The artifact is a
  patch in a tree a person is driving.
- **Reviewing pull requests.** That is [anakrisis](../anakrisis/README.md)'s
  queue, and it has an instrument this project does not.
- **Proof-completeness bugs.** Those are dokimasia's and belong in [its
  register][register], held to [its bar][bar]. A person carries them there.
- **Deciding cvc5's design.** It fixes reported defects. A patch that changes
  what cvc5 chose to do is a proposal, and proposals go through a person.
- **A general bug-triage product.** The subject is cvc5's tracker and what one
  project's answers teach, not triage in the abstract.

## Running it

```bash
run_empeiria --triage               # refresh the open-issue index
cd ~/cvc5
run_empeiria 12905                  # reproduce, locate, fix, test; bare N = --issue N
run_empeiria 12905 --show-prompt    # print the prompt, run nothing
run_empeiria --record 12905         # afterwards: what the maintainer did
run_empeiria --list                 # what has been worked, and what came back
```

`--triage` needs no cvc5 checkout; it reads the tracker rather than the tree.
The rest refuse to run outside a cvc5 checkout and refuse a dirty one, and they
create the working branch themselves — a branch the assistant forgot is a diff
on somebody's `main`. **`--show-prompt` is exempt from both refusals**, since it
runs and writes nothing, and it says on stderr which tree the prompt names.

**The script itself makes no network call**, including under `--triage`: it
hands a prompt to an assistant in a session a person started, and the index that
comes back is a dated snapshot rather than a measurement. Inside this repository
it writes only in `tools/empeiria/`; outside it, it may edit a cvc5 working tree
a person is driving, which is [the licence dokimasia already takes][bar] and not
a new one.

**The command is `scripts/run_empeiria`**, at the root of this repository —
put that directory on your `PATH` or call it by path. It execs
[`empeiria.sh`](empeiria.sh) here, which is where the implementation stays.

[`docs/`](docs/README.md) is the rest: [the open-issue index](docs/triage.md)
and [the plan](docs/TODO.md). [`ledger/`](ledger/) is the record.

## The name

**ἐμπειρία** — *experience*: the knowledge that comes from many particular cases
rather than from being taught. Aristotle puts it exactly this way in
*Metaphysics* A.1 — memory of many instances of one thing makes a single
experience — and makes it the **practitioner's** knowledge: the person with
*empeiria* and no theory often succeeds where the person with theory and no
cases fails, because acting happens on particulars. That is both halves here. It
learns from cases, and what it learns is how to *do* the next one.

*mathesis*, learning by instruction, was the other candidate and is wrong twice
over: nobody is teaching this project a rule, and *mathesis* is knowing rather
than doing. If a written rule would have worked all along, the name is wrong and
that is itself the finding. The authority on names is kanon's
[glossary][glossary].

## Status

**Started 2026-09-01** on cvc5
[#12905](https://github.com/cvc5/cvc5/issues/12905) — a fatal failure in
`theory_engine.cpp` on a strings-and-quantifiers benchmark: a theory explanation
defect and **not** a proof bug, which is what made paideia rather than dokimasia
its home. **Moved out of dokimasia into paideia on 2026-09-18**, alongside
[anakrisis](../anakrisis/README.md). Both by explicit human instruction, which
is the only way a [research project][policy] starts or ends.

**What runs:** the interface. `run_empeiria` guards the tree, makes the branch
and hands over the prompt, and `--show-prompt` prints what it would say.

**What does not exist:** anything it was built to produce. No issue has been
worked in either half, [`triage.md`](docs/triage.md) has never been refreshed against
the tracker and holds one hand-written row, the ledger is empty, and its format
is a first guess made before a single case.

**What it borrows, and from where.** This project has no evidence of its own:
[what a finding is and the bar a claim clears][bar], the `TRIAGE:` /
`HUMAN RESPONSE:` frame, that [a claim about behaviour is worthless until
something has been run][static], and [every recorded exchange with
cvc5][episodes] are dokimasia's. The document that first defined the frame was
retired there, so what keeps the practices together now is a citation — and
citations drift.

**Footing:** `unadvertised-child` — paideia's front page does not name this
project, because it has not yet produced a result anybody should rely on;
`tools/` is how it is found.

**How it ends:** a person picks one of three — it graduates into its own
repository, it is folded into paideia, or it is retired in place with a line
saying what was learned. Going quiet is not one of them.

[dok]: https://github.com/ajreynol/dokimasia
[register]: https://github.com/ajreynol/dokimasia/blob/main/docs/README.md#the-register
[static]: https://github.com/ajreynol/dokimasia/blob/main/docs/README.md#the-general-rule-this-session-suggests
[bar]: https://github.com/ajreynol/dokimasia/blob/main/dokimasia_analyzer/README.md#the-bar
[episodes]: https://github.com/ajreynol/dokimasia/blob/main/docs/experience.md
[policy]: https://github.com/ajreynol/kanon/blob/main/docs/policy.md
[glossary]: https://github.com/ajreynol/kanon/blob/main/docs/glossary.md
