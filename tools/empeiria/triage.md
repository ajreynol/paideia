# The open-issue triage

**Every open cvc5 issue, one line each.** The first place to look, and the last
place to trust.

*Refreshed by `run_empeiria --triage`. Snapshot of **not yet taken** — this file
has never been refreshed against the tracker, and the single row below was
written by hand.*

## What this is, and what it is not

**It is an index.** It exists so that somebody arriving at cvc5's tracker can
see the shape of what is open in one screen, and pick — rather than reading
forty issues to find the one worth an afternoon. Orientation is the whole
purpose, and orientation is worth a lot.

**It is not evidence, and nothing here may be cited as though it were.** Every
row is a guess made from an issue's text by something that did not reproduce it.
Concretely:

- **No row may be quoted in a finding, a case study, or anything carried to
  cvc5.** If a claim from this file matters, someone opens the issue and checks
  it, and *that* is what gets cited.
- **A row is superseded the moment the issue is worked.** The ledger entry
  ([`ledger/`](ledger/)) is written after reproducing, and it is the authority.
  Where the two disagree, the row is wrong.
- **A row goes stale silently.** Issues get comments, fixes and closures that
  nothing here notices between refreshes. An old snapshot looks exactly like a
  current one, which is the failure mode to keep in mind.
- **`class` is a guess about which repository cares**, not a diagnosis of the
  bug.

The name for this is *the triage for the triage*: a cheap first pass whose only
job is to make the second pass better aimed. It buys attention, and it settles
nothing.

## Classes

Where a row routes, using the three-way test from
[the routing case study](../../docs/cases/out-of-scope-bug-report.md):

| class | means | goes to |
| --- | --- | --- |
| `proof` | it concerns whether a step can produce a proof | **dokimasia's** register, [`docs/issues.md`](../../docs/issues.md) |
| `bug` | an ordinary defect — crash, wrong answer, assertion, regression | empeiria: `run_empeiria --issue N` |
| `perf` | it is about time or memory, not correctness | empeiria, lower priority |
| `design` | it asks what cvc5 should do, not whether it did what it meant to | neither of us decides; a person |
| `unclear` | the report does not say enough to route it | needs a question asked, not work |

A row's class is provisional by construction — see above.

## Open issues

| # | title | one line | class | worked |
| --- | --- | --- | --- | --- |
| [12905](https://github.com/cvc5/cvc5/issues/12905) | Fatal failure at `theory_engine.cpp:2030` | a fact reaches the explanation machinery that the engine does not think it sent, on a strings-and-quantifiers benchmark | `bug` | not yet |

*One row, written by hand on 2026-09-01 while setting this up. The table is not
a snapshot of the tracker until `--triage` has been run against it, and saying
so is more useful than an empty table that looks refreshed.*
