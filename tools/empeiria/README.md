# empeiria

**Footing:** `unadvertised-child` — the parent's front page does not name
this project, and nothing a user of dokimasia reads links inward to it. A
fix for somebody's bug is speculative work that would borrow the parent's
credibility the moment it were pointed at, and it has earned none yet.
`tools/` is how it is discovered, and that is enough.

*Can a front end fix cvc5's public bugs, and get better at it by learning from
how the maintainers answered the last ones?*

**Internal.** A research project under
[kanon's research-project rules](https://github.com/ajreynol/kanon/blob/main/docs/policy.md),
not a project announcement. It is not linked from the root
[`README`](../../README.md), from [`docs/README.md`](../../docs/README.md), or
from either register ([`TODO.md`](../../TODO.md),
[`docs/issues.md`](../../docs/issues.md)), and it should stay that way until
there is something to show. `ajreynol/dokimasia` is a **public** remote:
unadvertised means *not pointed at*, not *not visible*. Nothing here makes a
claim about cvc5 or should be quoted as though it did.

**An island in this repository.** empeiria reads dokimasia's analyses, cvc5's
tree, and its own ledger. Nothing in `dokimasia/` imports it, no test covers it,
no baseline ratchets it, no CI job runs it, and its one script is invoked by hand from
somebody else's checkout. Delete
this directory and the repository is exactly as functional — that is the
property that makes it safe to keep here.

**Where "read-only" stops, stated rather than assumed.** A project that writes
fixes cannot be read-only everywhere, so the boundary is drawn precisely:
*inside this repository* it writes only within `tools/empeiria/`, and that is
the island property in full. *Outside* it, it may edit a cvc5 working tree a
person is driving — which is not a new licence but the one the parent already
takes in [`pr-policy.md`](../../docs/pr-policy.md), where running an assistant
in somebody's checkout is permitted and pushing from it is not. If that
distinction ever blurs, this note is the thing that was wrong.

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

`--triage` is the standing obligation and the only command that does not need a
cvc5 checkout — it reads the tracker, not the tree. The rest refuse to run
outside a cvc5 checkout and refuse a dirty tree; it creates
the branch itself rather than asking the assistant to, because a branch the
assistant forgot is a diff on somebody's main. `--show-prompt` runs nothing and
works anywhere, so the prompt is auditable without a checkout to hand. It makes
no network calls, and it never pushes, posts or opens anything.

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

- **Proof-completeness bugs.** Those are dokimasia's, and they stay in
  [`docs/issues.md`](../../docs/issues.md). If an issue turns out to be one, it
  leaves here and enters the parent's register.
- **Sending anything upstream.** Producing a fix is in scope; delivering it is
  not, ever. See the next section — the parent's policy governs and there is no
  lighter standard here.
- **Deciding cvc5's design.** It fixes reported defects. A patch that changes
  what cvc5 chose to do is a proposal, and proposals go through a person.
- **Speaking for dokimasia.** Nothing here is the parent's position on anything.
- **Building a general bug-triage product.** The subject is cvc5's tracker and
  what one maintainer's answers teach, not triage in the abstract.

**Is there a paper in it?** Not yet, and probably not for a while. There is a
paper only if goal 3 produces a measured improvement against a held-out set of
issues; a project that has learned nothing measurable has nothing to write up,
and saying so now is cheaper than discovering it later.

## The PR policy is the parent's

**empeiria does not open pull requests against cvc5. It has no separate channel
and no lighter standard than dokimasia.** The policy is
[`docs/pr-policy.md`](../../docs/pr-policy.md) and it governs here unchanged;
this section only says how its three parts land on a project that writes fixes.

- **The act stays with a person.** No `git push`, no `gh pr create`, no tracker
  call. *Executor* means the patch exists in a working tree a person is driving,
  not that anything is delivered. Approval to make a change is not approval to
  send it, and that is most tempting exactly here, where the artifact looks
  ready to go.
- **The verdict is this project's.** Applying
  [the bar](../../docs/pr-policy.md#the-bar) to a fix rather than to a finding,
  the demanding rule is **run-it**: a patch that has not been built, and whose
  reproducer has not been run against it before and after, is a hypothesis
  wearing a diff. `cheap-to-refute` means the regression test comes with it.
- **The guidance stays with the maintainer**, including this charter. A
  research project is started and ended by a person, and its scope is changed
  the same way — never by the project deciding it has outgrown its boundary.

**On reading the tracker.** The parent's standing position is that no analysis
path makes a network call, because an analysis whose answer depends on when it
ran is not a measurement. `--triage` does not break it: like every other command
here the script itself calls nothing, and hands a prompt to an assistant in a
session a person started. The index it produces is explicitly a dated snapshot
and explicitly not a measurement, which is the same arrangement the parent uses
for anything imported rather than computed.

The [research-project rules](https://github.com/ajreynol/kanon/blob/main/docs/policy.md)
say the same thing from the other direction: nothing leaves the island by
machine, a research project has no separate channel and no lighter standard than
its host, and what it may do on its own is accumulate a ledger inside its own
directory. A person decides when any of it is carried.

## What it inherits from dokimasia, and where

A research project runs inside a working tool's repository because that tool has
evidence — cases it ran, behaviours it verified — and it is required to cite
what it takes, so a reader can tell what was checked from what was reasoned.

| inherited | where it was established |
| --- | --- |
| the workflow that runs an assistant against a cvc5 issue and writes a `TRIAGE:` / `HUMAN RESPONSE:` block | [`prompts/check_cvc5_issue`](../../prompts/check_cvc5_issue), [`docs/workflows.md`](../../docs/workflows.md) |
| that a reply is triage and only an artifact settles anything | [`docs/findings.md`](../../docs/findings.md) |
| that a claim about behaviour is worthless until it has been run | [`docs/pr-policy.md`](../../docs/pr-policy.md) — three static arguments that read correctly and were false |
| the reporting policy in full — the bar, the three verdicts, and that we never open a PR | [`docs/pr-policy.md`](../../docs/pr-policy.md), shared rather than restated |
| the postmortem shape — one block per round, about the workflow rather than the subject | [`docs/postmortem.md`](../../docs/postmortem.md) |

The reason this is a child of dokimasia rather than its own repository is that
last row: the parent already runs the loop, already writes the block, and has
already learned things about it that would otherwise be re-learned.

## Status

**Started 2026-09-01**, by an explicit human instruction, which is the only way
one of these may begin. On the occasion of cvc5
[#12905](https://github.com/cvc5/cvc5/issues/12905) — a fatal failure in
`theory_engine.cpp` on a strings-and-quantifiers benchmark, which is a theory
explanation defect and **not** a proof bug, and so is the first concrete case of
an issue this repository cannot take and should not ignore. The routing question
it raised is written up in
[`docs/cases/`](../../docs/cases/out-of-scope-bug-report.md).

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
saying what was learned. Going quiet is not one of them.
