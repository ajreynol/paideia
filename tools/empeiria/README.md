# empeiria

**Footing:** `unadvertised-child` — the parent's front page does not name this
project, and nothing a reader of paideia sees points inward to it. The argument
is the one this work started with: paideia publishes a developer's guide to
cvc5's source that a reader is meant to rely on, and an unapplied fix for
somebody's bug has earned none of that credibility. `tools/` is how this is
discovered, and that is enough.

*Can a front end fix cvc5's public bugs, and get better at it by learning from
how the maintainers answered the last ones?*

**Internal.** A research project held to
[kanon's research-project rules](https://github.com/ajreynol/kanon/blob/main/docs/policy.md)
— paideia is a **member** of the Eunoia ecosystem, so those rules bind this
directory as they bind the rest of the tree — and not a project announcement. It is not linked
from the root [`README`](../../README.md), which is paideia's only front page,
and it has no row in the [documentation index](../../docs/README.md) either:
that index names what this repository publishes, and a research project is not
among it. `ajreynol/paideia` is a **public** remote: unadvertised means *not
pointed at*, not *not visible*. Nothing here makes a claim about cvc5 or should be quoted as
though it did.

**An island.** empeiria reads cvc5's tree and its own ledger, and nothing else.
What the parent publishes is a written guide, so there is no import path for
this to be off and the rule's interesting half is inapplicable here. The
operative half holds in full: nothing imports this, no test covers it, no
baseline ratchets it, no CI job runs it, its one script is invoked by hand from
somebody else's checkout, and deleting the directory leaves the repository
exactly as functional. The link that would break the rule is a pointer inward
from the guide, and there is none.

**It reaches outside this tree for nothing but the cvc5 checkout.**
`run_empeiria` resolves its ledger and [`triage.md`](triage.md) relative to its
own location, which is why the sibling project's cross-repository dependency has
no counterpart here. What it does lack is proximity: everything under *What it
inherits* below is in another repository, and a practice you have to go and
fetch is one you can quietly stop reading.

**Where "read-only" stops, stated rather than assumed.** A project that writes
fixes cannot be read-only everywhere, so the boundary is drawn precisely:
*inside this repository* it writes only within `tools/empeiria/`, and that is
the island property in full. *Outside* it, it may edit a cvc5 working tree a
person is driving — which is not a new licence but the one dokimasia already
takes in [the bar in
`findings.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/findings.md#the-bar),
where running an assistant in somebody's checkout is permitted and pushing from
it is not. If that distinction ever blurs, this note is the thing that was
wrong.

## On the name

**ἐμπειρία** — *experience*: the knowledge that comes from many particular
cases rather than from being taught. Aristotle puts it exactly this way in
*Metaphysics* A.1 — memory of many instances of the same thing produces a single
experience — and he makes it specifically the **practitioner's** knowledge: the
person with *empeiria* and no theory often succeeds where the person with theory
and no cases fails, because acting happens on particulars. That is both halves
of this project. It learns from cases, and what it learns is how to *do* the
next one.

*mathesis* (learning by instruction) was the other candidate and is the wrong
one twice over: nobody is teaching this project a rule, and *mathesis* is
knowing rather than doing. If it turns out that a written rule would have worked
all along, the name is wrong and that is itself the finding.

**It sits easily under παιδεία**, which is worth a sentence and not more:
ἐμπειρία is what a practitioner has from cases, παιδεία is the forming of
somebody who does not have it yet, and a project whose output is a record of how
cvc5's maintainers actually answered is closer to material for a guide than to
proof analysis. That is an observation about two Greek words, and it is not an
argument for where this project lives — that is a person's decision and stands
on their reasons rather than on this paragraph.

## The charter

**The question.** cvc5's issue tracker receives bug reports that a maintainer
triages, reproduces, fixes or closes. Almost none of them are
proof-completeness bugs, so almost none are dokimasia's. **Can a front end work
them — triage *and* fix — and get better at it by learning from how the
maintainers answered the last ones?**

**It is both halves, and the order between them is fixed.** Fixing the bug
comes first and the learning is a by-product — the ecosystem's charter is *be
useful fast*, and a project that made somebody wait for a fix while it took
notes would have inverted its own reason for existing. So the ledger is written
after the work, by a separate command, and nothing about it gates the fix.

The two are still one loop: attempt the work, compare against what the
maintainer did, let the difference change the next attempt. A learner that never
attempts a fix has no signal beyond whether its triage read well; an executor
that never learns repeats its mistakes at machine speed.

## Using it

```bash
run_empeiria --triage               # refresh the open-issue index
cd ~/cvc5
run_empeiria --issue 12905          # reproduce, locate, fix, test
run_empeiria 12905                  # the same; a bare N means --issue N
run_empeiria 12905 --show-prompt    # print the prompt, run nothing
run_empeiria --record 12905         # afterwards: what the maintainer did
run_empeiria --list                 # what has been worked, and what came back
```

`--triage` is the standing obligation and needs no cvc5 checkout — it reads the
tracker, not the tree. The rest refuse to run outside a cvc5 checkout and refuse
a dirty tree; work on an issue creates the branch itself rather than asking the
assistant to, because a branch the assistant forgot is a diff on somebody's
main. **`--show-prompt` is exempt from both refusals** — it runs nothing and
writes nothing, so the prompt is auditable anywhere, and it says on stderr which
tree the prompt it printed names. It makes no network calls, and it never
pushes, posts or opens anything.

**The goals, in order.**

0. **Keep an index of every open issue** — [`triage.md`](triage.md), refreshed
   by `run_empeiria --triage`. It is numbered zero because it is a standing
   obligation rather than a result: it makes goal 1 well aimed and produces
   nothing on its own. **It is the first place to look and the last place to
   trust** — an index written from issue text by something that reproduced
   nothing, and it says so about itself on every screen. No row in it may be
   cited as evidence anywhere.
1. **Work an issue end to end.** Reproduce it, locate it, and produce a fix as
   a patch and a regression test — in a working tree a person is driving. A
   triage nobody tried to act on is an opinion.
2. **Record what the response taught.** For each issue worked, capture what the
   project produced, what the maintainer actually did, and the **delta**. The
   delta is the whole asset; everything else is bookkeeping.
3. **Find the recurring shapes.** Across enough deltas, whether the corrections
   fall into a small number of kinds — wrong subsystem, wrong severity, already
   known, not a bug, a fix that treats the symptom.
4. **Make the next attempt better,** and say by how much against a held-out set
   of issues fixed before the measurement was designed. An improvement nobody
   measured did not happen.

**The wishue** — the goal if this went unusually well, and not a commitment.
A front end that reads a fresh cvc5 issue and produces a
fix a maintainer applies with edits they would call minor — measured against
what they actually did, not against whether the patch reads well.

**Out of scope**, explicitly, because a research project with no boundary
becomes a second tool:

- **Proof-completeness bugs.** Those are dokimasia's, and they belong in
  [its register](https://github.com/ajreynol/dokimasia/blob/main/docs/issues.md). If an issue turns out to be one it leaves
  this repository altogether — a carry between repositories, and a person does
  it.
- **Sending anything upstream.** Producing a fix is in scope; delivering it is
  not, ever. See the next section — dokimasia's policy is kept here by choice,
  and keeping it means keeping it whole.
- **Deciding cvc5's design.** It fixes reported defects. A patch that changes
  what cvc5 chose to do is a proposal, and proposals go through a person.
- **Speaking for dokimasia, or for paideia.** Nothing here is either one's
  position on anything.
- **Building a general bug-triage product.** The subject is cvc5's tracker and
  what one maintainer's answers teach, not triage in the abstract.

**Is there a paper in it?** Not yet, and probably not for a while. There is a
paper only if goal 3 produces a measured improvement against a held-out set of
issues; a project that has learned nothing measurable has nothing to write up,
and saying so now is cheaper than discovering it later.

## The PR policy is borrowed, and unchanged

**empeiria does not open pull requests against cvc5.** The rule comes from [the
bar in dokimasia's
`findings.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/findings.md#the-bar),
which does not govern this project by being its parent's — dokimasia is not its
parent, and paideia has no reporting policy of its own to impose. It governs
because this project keeps it, and keeping it is worth nothing unless the
standard stays where it was, so: **no separate channel, and no lighter standard
than dokimasia's own.**
This section only says how its three parts land on a project that writes
fixes.

- **The act stays with a person.** No `git push`, no `gh pr create`, no tracker
  call. *Executor* means the patch exists in a working tree a person is driving,
  not that anything is delivered. Approval to make a change is not approval to
  send it, and that is most tempting exactly here, where the artifact looks
  ready to go.
- **The verdict is this project's.** Applying
  [the bar](https://github.com/ajreynol/dokimasia/blob/main/docs/findings.md#the-bar) to a fix rather than to a finding,
  the demanding rule is **run-it**: a patch that has not been built, and whose
  reproducer has not been run against it before and after, is a hypothesis
  wearing a diff. `cheap-to-refute` means the regression test comes with it.
- **The guidance stays with the maintainer**, including this charter. A
  research project is started and ended by a person, and its scope is changed
  the same way — never by the project deciding it has outgrown its boundary.

**On reading the tracker.** dokimasia's standing position is that no analysis
path makes a network call, because an analysis whose answer depends on when it
ran is not a measurement. `--triage` does not break it: like every other command
here the script itself calls nothing, and hands a prompt to an assistant in a
session a person started. The index it produces is explicitly a dated snapshot
and explicitly not a measurement, which is the same arrangement dokimasia uses
for anything imported rather than computed.

The [research-project rules](https://github.com/ajreynol/kanon/blob/main/docs/policy.md)
say the same thing from the other direction: nothing leaves the island by
machine, a research project has no separate channel and no lighter standard than
its host, and what it may do on its own is accumulate a ledger inside its own
directory. A person decides when any of it is carried.

## What it inherits from dokimasia, and where

This project has no evidence of its own. dokimasia has it — cases it ran,
behaviours it verified — and the rule is to cite what is taken, so a reader can
tell what was checked from what was reasoned. None of the following is in this
repository, and every link in the table leaves it.

| inherited | where it was established |
| --- | --- |
| the workflow that runs an assistant against a cvc5 issue and writes a `TRIAGE:` / `HUMAN RESPONSE:` block | [`docs/cases/out-of-scope-bug-report.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/cases/out-of-scope-bug-report.md). The launcher and the document that defined it were retired from that tree; read on 2026-09-19, the case study is what still records the frame and says this repository now owns it |
| that a reply is triage and only an artifact settles anything | [`docs/findings.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/findings.md) |
| that a claim about behaviour is worthless until it has been run | [`docs/goals.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/goals.md) — three static arguments that read correctly and were false, every one caught by running something |
| the reporting policy in full — the bar, the three verdicts, and that we never open a PR | [`docs/findings.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/findings.md#the-bar), shared rather than restated |
| the postmortem shape — one block per round, about the workflow rather than the subject | [`docs/experience.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/experience.md#what-a-run-learned-about-itself), which is where dokimasia salvaged it when `postmortem.md` was retired |

**What holds the two practices together is a citation, and a citation is weak.**
dokimasia ran this loop first, wrote the block first, and learned things about it
that would otherwise be re-learned here; all of that is true and none of it is in
this repository. Nothing breaks when dokimasia's practice and this project's
drift apart, which is the cost of the arrangement and is worth knowing before
the drift rather than after.

## Status

**Started 2026-09-01**, by an explicit human instruction, which is the only way
one of these may begin, on the occasion of cvc5
[#12905](https://github.com/cvc5/cvc5/issues/12905) — a fatal failure in
`theory_engine.cpp` on a strings-and-quantifiers benchmark, which is a theory
explanation defect and **not** a proof bug. It is the kind of issue that fits
here and would be an awkward guest in a repository about proofs: paideia's
subject is cvc5's code. The routing question it raised is written up in
[dokimasia's `docs/cases/`](https://github.com/ajreynol/dokimasia/blob/main/docs/cases/out-of-scope-bug-report.md).

**Moved out of dokimasia into paideia on 2026-09-18**, by the same kind of
instruction.

**What exists is the interface and nothing it was built to produce.**
`run_empeiria` works — it guards the tree, makes the branch and hands over the
prompt — and `--show-prompt` prints what it would say. [`triage.md`](triage.md)
exists and says of itself that it has never been refreshed against the tracker:
it holds one row, written by hand. **No issue has been worked in either half,
the ledger is empty, and there is no result.** The ledger format is a first
guess made before a single case, which is exactly the condition under which a
format is wrong.

There are three endings and a person picks: it graduates into its own
repository, it is folded into the parent, or it is retired in place with a note
saying what was learned. Going quiet is not one of them. **What *folded into the
parent* would mean here is undecided**: the parent publishes a written guide to
cvc5's source, so folding in would mean this project's output becoming material
for that guide rather than a command anybody runs — which is a reading, not a
decision, and the decision is a person's.

**The register has this right.** The ecosystem's authoritative name register is
[kanon's glossary](https://github.com/ajreynol/kanon/blob/main/docs/glossary.md),
kept by the president of eo, and editing somebody else's register is a person's
edit. Read on 2026-09-19, its entry for empeiria names paideia as the parent and
its **Charter** link resolves to this file; *paideia* has an entry of its own.
Both were wrong when this project moved and both were corrected in that tree, so
nothing is owed here. What the register says about empeiria is the register's, and
this page is not a second copy of it.
