# anakrisis

**The feature request.** *Before a cvc5 pull request is merged, say in two
seconds what it did to something somebody measures — and let a maintainer decide
whether that was worth reading.*

Nothing answers that question today. cvc5's CI reports whether a change builds
and whether the tests still pass; nobody runs an instrument at the merge base
and at the head and reports the difference. [dokimasia][dok] takes an inventory
of cvc5's proof production straight from a source checkout — no build, about a
second — and records [what it found][obs] under ids that carry no revision, no
line number and no wording. Run it at both ends of a branch, subtract, and a
reviewer has *this branch adds two inferences that produce no proof* before
anyone has read the diff.

That subtraction is `run_anakrisis 12893 --delta`, and it runs today. **Whether
a maintainer wants it is the open question**, and answering that — including
with *no* — is what this project is for.

**Nothing in the mechanism is about proofs.** It asks one property of an
instrument: an inventory taken from a source checkout, under stable ids, so the
same finding at two commits compares equal. Proofs are what the inventory
happens to be of, because dokimasia is the analyzer in hand and the one the
script names.

## Two projects, one question

paideia runs two research projects at opposite ends of cvc5's tracker. Each is
a feature request nobody has built, and each asks whether a front end can
produce something a maintainer actually wants.

| | works on | the feature request |
| --- | --- | --- |
| **anakrisis** — here | incoming **pull requests** | say what a change moved before it lands, and whether that was worth reading |
| [**empeiria**](../empeiria/README.md) | open **issues** | reproduce it, locate it, fix it — and get better at it from how the maintainers answered the last one |

Each writes a ledger, each records what the maintainers actually did, and
**neither sends anything anywhere**. Neither imports the other. empeiria is also
this project's control condition — an assistant with a checkout and no
instrument — which is exactly what `run_anakrisis --baseline` reproduces on a
pull request.

## The charter

**The question.** Can a reviewer be told what a change did to a measured
inventory before it lands, and would a maintainer rather have that than not?
Almost no pull request is *about* the inventory, almost any of them can move it,
and nobody can see that by reading the diff — which is the whole opening.

**Why it might work.** The instrument already exists and costs two seconds, the
subtraction is exact rather than a diff of prose, and the result is
**cheap-to-refute**: two commands and a set difference, reproducible by anybody
with both checkouts.

**Why it might not.** Most deltas will be empty; an empty delta is [not a clean
bill of health](#what-an-empty-delta-does-not-mean); and a review that says
nothing a cvc5 reviewer could not produce faster is noise with a good story.

**The goals, in order.**

0. **The delta.** Run the analyses at the merge base and at the head, report
   what moved. Numbered zero because it is computed rather than judged.
   **Most pull requests will have an empty delta** — the expected result, not a
   failed run.
1. **Review one pull request end to end**, in both arms: the delta, plus a
   reading of the diff scoped to what the instrument has evidence about, in a
   shape a maintainer could act on.
2. **Record what the maintainers actually did.** Merged as proposed, merged with
   changes, changed for a reason we did not see, closed. That difference is the
   asset; everything else is bookkeeping.
3. **Beat the baseline, or say it was not beaten.** Which review lines were
   acted on, which were noise, and whether any of the difference came from the
   delta. *Neither arm was worth it* is a publishable result and would retire
   this project.
4. **Say whether the empty delta can be trusted.** A tool whose commonest output
   is *nothing to say* is useful only if that output can be relied on.

**The wishue** — the stretch goal if this went unusually well, and not a
commitment. **The delta stops being something a person runs and becomes an
advisory check cvc5 runs itself, on every pull request.** Seconds, no build, no
stored baseline, and silent on the great majority of changes because their delta
is empty. It would annotate new observations attributable to the diff, stay
quiet about disappearances — where [a rename looks exactly like a
fix](#what-an-empty-delta-does-not-mean) — and **never fail a build**: a check
that blocks a contributor on a partial static analysis has earned being muted.

**Cost is not what stands in the way.** cvc5 already runs a no-build
`check-format` job on every pull request, and already keeps custom static
analysis in its own tree — a clang-tidy plugin in `contrib/tidy-checks/` and a
CodeQL query in `contrib/codeql/`. But that same workflow is the shape of the
objection: read on 2026-09-20 at cvc5 `40a4bb7e`,
[`static_analysis.yml`][cvc5-sa] runs **nightly and on demand, never on a pull
request**. So the question is not whether a job can be added. It is whether a
second-long advisory delta earns a place on the path every contributor waits on,
and nothing but goals 1–3 can answer that.

**And the ask is not this project's to make.** dokimasia already has
[**R11**][asks] open — *run our checks in cvc5 CI* — and the pull-request delta
is the cheaper half of it: no baseline to store, nothing to ratchet, and no
SARIF infrastructure needed to be useful. If it is ever asked for, it goes
through that register and a person carries it. What can be built here before
then is the artifact that makes the ask concrete: a workflow file that runs, a
delta in a machine format, and a case file saying what it would have said on
pull requests that already landed. [`docs/TODO.md`](docs/TODO.md) has that as
the stretch work, with the gate on it.

**Out of scope.**

- **General code review.** Not style, naming, performance or architecture —
  cvc5's reviewers and CI do all of it better. The read half is scoped to what
  an instrument measured: the [hygiene rules][hygiene], the
  [contract][contract], and whatever the delta pointed at.
- **Measuring anything itself.** No inventory of its own, no new check, no
  ratchet. A check nobody runs is [an ask to the analyzer][register], carried by
  a person.
- **Sending anything.** No comment, review, approval, push or tracker call —
  ever. The artifact is a file here, and a person decides what becomes of it.
- **A verdict on merging.** The examination is not the trial.
- **Findings about the inventory.** A hole rather than a question about a change
  leaves for [dokimasia's register][register], held to [its bar][bar].
- **The issue tracker.** That is [empeiria](../empeiria/README.md)'s queue.

## Running it

```bash
cd ~/cvc5
gh pr checkout 12893                  # a person's network call, never the script's
run_anakrisis 12893 --delta           # the delta alone, ~2s, no assistant
run_anakrisis 12893                   # the delta, then a review by an assistant
run_anakrisis 12893 --baseline        # the control: same review, delta withheld
run_anakrisis 12893 --show-prompt     # print the prompt, start nothing
run_anakrisis --record 12893          # afterwards: what the maintainers did
run_anakrisis --list                  # what has been reviewed, and what came back
```

It needs a dokimasia checkout — `DOKIMASIA_ROOT`, or one beside this repository
— and **refuses to run without it**, naming what was missing, rather than
reporting a clean result it could not compute. It makes no network calls,
refuses a dirty tree, and reads the merge base through a detached `git worktree`
it removes again. Inside this repository it writes only in `tools/anakrisis/`,
and it never writes a baseline anybody ratchets.

**The command is `scripts/run_anakrisis`**, at the root of this repository —
put that directory on your `PATH` or call it by path. It execs
[`anakrisis.sh`](anakrisis.sh) here, which is where the implementation stays.

[`docs/`](docs/README.md) is the rest: [what a review must carry and what
*nothing to say* means](docs/review.md), and [the plan](docs/TODO.md).
[`ledger/`](ledger/) is the record.

## What an empty delta does not mean

Every one of these was found by running it. The first two belong to the
instrument; the third belongs to the subtraction and would survive a change of
instrument.

- **Nothing ran.** Static, `src/` only, no build and no benchmark — a change
  whose whole effect is at runtime is invisible here. dokimasia's own record is
  that [three static arguments that read correctly were false][static], each
  caught by running something.
- **Only the observations are subtracted.** Measurements beside them — `gates`,
  `fragment`, `tcb`, `latent` — are not in [the dump][obs], so a change visible
  only in a measurement is not in the delta. Two runs are subtractable only at
  the same declared scope, and the script refuses rather than comparing partial
  catalogues.
- **A rename reads as one removal and one addition.** An id is
  `[owner, code, entity]`, which is what makes the same finding compare equal at
  two commits and what makes a move look like two events. dokimasia hit this
  from the other side: [two of four apparent closures in one window were
  renames][learned]. Nothing here resolves it automatically — the review prompt
  names the reading, and a person makes it.

## The name

**ἀνάκρισις** — the preliminary examination before an Athenian trial. Both
parties were questioned, the evidence each meant to rely on was produced and
sealed in the ἐχῖνος, and nothing that had not been put in could be produced at
the trial. It examined **before** admission and it **decided nothing**, which is
this project twice over: merging stays a maintainer's, and a review may rely
only on what it recorded at review time — shas and delta in the block, sealed.

The rhyme with δοκιμασία, the scrutiny before office, is a rhyme and not an
argument, and it does not make this a project about proofs. **κρίσις** — the
judgement — was the alternative, and is wrong for the reason it is tempting:
nothing here produces one. The authority on names is kanon's
[glossary][glossary].

## Status

**Started 2026-09-01**; **moved out of dokimasia into paideia on 2026-09-18**,
alongside [empeiria](../empeiria/README.md). Both by explicit human instruction,
which is the only way a [research project][policy] starts or ends. paideia is
the home because the subject is cvc5's code rather than cvc5's proofs; the
instrument is borrowed, and every claim above that came from dokimasia links to
where it was established.

**What runs:** `--delta` and `--baseline`, given a dokimasia checkout. The
subtraction has been exercised twice, and both times on the instrument rather
than on the idea. Two cvc5 commits two hundred apart, on 2026-09-19: 6
observations gone, 17 new, 7 codes, about two seconds, three of those pairs
renames. A different pair the same distance apart, on 2026-09-21 against
dokimasia `9e42bda`: 1 gone, 9 new, 4 codes, about three seconds for both
analyzer runs and the subtraction together, no rename shape in it. The second
run was asking whether the borrowed interface still holds, and it does.

**What does not exist:** a single reviewed pull request, in either arm. The
ledger is empty, [`docs/review.md`](docs/review.md) is a first guess written
before any case, and one instrument is wired with no second one tried.

**Footing:** `unadvertised-child` — paideia's front page does not name this
project, because it has not yet produced a result anybody should rely on;
`tools/` is how it is found.

**How it ends:** a person picks one of three — it graduates into its own
repository, it is folded into paideia, or it is retired in place with a line
saying what was learned. Going quiet is not one of them.

[dok]: https://github.com/ajreynol/dokimasia
[obs]: https://github.com/ajreynol/dokimasia/blob/main/docs/README.md#structured-observations
[hygiene]: https://github.com/ajreynol/dokimasia/blob/main/docs/README.md#proof-hygiene
[contract]: https://github.com/ajreynol/dokimasia/blob/main/docs/README.md#the-contract
[register]: https://github.com/ajreynol/dokimasia/blob/main/docs/README.md#the-register
[asks]: https://github.com/ajreynol/dokimasia/blob/main/docs/README.md#open--asks
[static]: https://github.com/ajreynol/dokimasia/blob/main/docs/README.md#the-general-rule-this-session-suggests
[bar]: https://github.com/ajreynol/dokimasia/blob/main/dokimasia_analyzer/README.md#the-bar
[learned]: https://github.com/ajreynol/dokimasia/blob/main/dokimasia_analyzer/README.md#what-a-run-learned-about-itself
[cvc5-sa]: https://github.com/cvc5/cvc5/blob/main/.github/workflows/static_analysis.yml
[policy]: https://github.com/ajreynol/kanon/blob/main/docs/policy.md
[glossary]: https://github.com/ajreynol/kanon/blob/main/docs/glossary.md
