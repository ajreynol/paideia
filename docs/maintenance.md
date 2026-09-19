# Maintaining paideia

**If you are a human maintaining this repository — possibly by directing an
agent — this is where to start.** It says what this tree is responsible for,
what is reserved to you, and what is currently owed elsewhere. It is addressed
to a person and is short on purpose; the depth is in the pages it points at.

## Where to start

1. Read [`../README.md`](../README.md). It is the only entry point, and every
   other page here assumes it.
2. Read the shared repository policy this tree is arranged by —
   [kanon's `docs/policy.md`](https://github.com/ajreynol/kanon/blob/main/docs/policy.md)
   — and the vision it is argued from,
   [`docs/vision.md`](https://github.com/ajreynol/kanon/blob/main/docs/vision.md).
   Neither is ours and neither is restated here.
3. Read [`discussion.md`](discussion.md) for what is currently being said to
   another tool and what it is waiting on.
4. For work on the bootcamp artifact, read the
   [source baseline and update procedure](../bootcamp/source-baseline.md) and
   [bootcamp coverage](../bootcamp/bootcamp-coverage.md). Check claims against
   the pinned cvc5 source, then update explanations and citations together.
   Theory sub-guides belong in the
   [How to develop a theory](../bootcamp/theory-development/README.md) category
   and open with a worked example followed by its six implementation sections.

## What this repository is responsible for

**One thing: a written account of how cvc5's source is put together.** The
[bootcamp artifact](../bootcamp/README.md) covers the architecture and every theory
in the supplied bootcamp. It lives in `bootcamp/`, with its own chapter index
and source baseline. `docs/` contains the repository's maintenance and standing
documentation. The artifact is authored Markdown with source citations,
intended to evolve through source-checked edits, initially mostly by AI agents.

**It does not assess the correctness of proofs.** The guide describes proof
objects and interfaces where they are part of cvc5's implementation. Answering
*is cvc5 right* belongs to the tools built around the Eunoia language, and a
page here that started answering it would be answering somebody else's
question badly.

## The child projects

**They are under [`../tools/`](../tools/), and listing that directory is how
they are discovered.** Each carries its own charter, its own plan, its own
ledger and its own record of what it is not advertised from — and each records
that it is not named on the front page, which is why nothing a reader of this
repository sees points inward to one.

**What you need to know to run one:** each has a single command at the root of
its own directory, invoked by hand from a cvc5 checkout, and its own `README.md`
says how. Nothing runs them on a schedule, nothing in CI runs them, and neither
one sends, posts, pushes or opens anything — ever. Their output is a file in
their own directory, and whether any of it goes anywhere is yours.

**One of them reaches across a repository boundary.** It computes its result by
running dokimasia's analyzer, which is in another repository, so it has to be
told where that checkout is: `DOKIMASIA_ROOT=/path/to/dokimasia`, or a
`dokimasia` checkout beside this one, which is the default it tries. It refuses
to run rather than guessing, and names what it could not find. **That dependency
is the standing risk in this arrangement**, and nothing removes it: dokimasia
owes us no stability and we have asked for none. What it does now rest on is a
command with a stated interface and a documented record shape rather than on the
layout of somebody's prose, which is what dokimasia recommended when asked. No
topic is open about it.

## What is reserved to you

Not an agent's, on any prompt:

- **Starting or ending a child project**, and changing the scope of one.
- **Carrying anything out of this tree** — to cvc5, to a tracker, to another
  repository's discussion file. Everything here is staged and nothing is sent.
- **What this repository says about its own standing.** See below.
- **Opening a repository, or a licence.** There is no licence file in this tree,
  so nothing here states an intention about use.

## What is owed elsewhere, and what is open

**This repository is a member, and one page of somebody else's says
otherwise.** The front page carries the membership declaration and
[`.github/workflows/anoieu.yml`](../.github/workflows/anoieu.yml) runs the
shared policy check on every push, so the mechanical half of the footing is
decided here on every commit. kanon's
[`ecosystem.json`](https://github.com/ajreynol/kanon/blob/main/scripts/ecosystem/ecosystem.json)
records one footing per tool and is kanon's file, not ours; read on 2026-09-19,
its row for paideia is `candidate` and explains itself by a reading of this tree
taken before the declaration was written. **Whether that row moves is theirs and
is not something this repository argues for** — a repository pressing its own
standing is the one shape the gate in [`discussion.md`](discussion.md) says must
stop. The notice that the reading is out of date is `D3` there, and it asks for
nothing.

**The register has the name and both child projects.** kanon's
[`docs/glossary.md`](https://github.com/ajreynol/kanon/blob/main/docs/glossary.md)
is the authoritative name register; read on 2026-09-19 it defines *paideia* and
names anakrisis and empeiria under it, with charter links into this tree.
Nothing is owed there. Correcting somebody else's register is their edit and
never ours.

**What no check settles, here or anywhere.** A member is checked for declaring
and for the form of its tree, and nothing more. The other half — that a member
shares the approach the shared vision argues for — is a judgement, and the
vision may never acquire a checker. Nobody's tick says this repository is
worth having.

## What is deliberately not here

- **No CI beyond the policy check.** `.github/workflows/anoieu.yml` is the whole
  of it: it calls anoieu's shared workflow at `main` against policy contract 1,
  so there is no checker commit pinned here and nothing to bump. Nothing builds,
  nothing is installed, and no child project runs there. Adding any further
  runner to this tree is outward-facing and yours.
- **No `tests/`, `deps/` or `prompts/`.** The one script,
  [`check_guide.py`](../scripts/check_guide.py), checks written-guide links,
  indexing and source paths on request. It generates nothing and does not
  validate the semantics of the prose. No runner invokes it automatically.
- **No second overview.** The front page is the only entry point, and
  [`README.md`](README.md) beside this file is the index and nothing else.
