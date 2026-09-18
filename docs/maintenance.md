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
running dokimasia's analyses, which are in another repository, so it has to be
told where that checkout is: `DOKIMASIA_ROOT=/path/to/dokimasia`, or a
`dokimasia` checkout beside this one, which is the default it tries. It refuses
to run rather than guessing, and names what it could not find. That dependency
is the standing risk in this arrangement, and it is [`discussion.md`](discussion.md)
`D2`.

## What is reserved to you

Not an agent's, on any prompt:

- **Starting or ending a child project**, and changing the scope of one.
- **Carrying anything out of this tree** — to cvc5, to a tracker, to another
  repository's discussion file. Everything here is staged and nothing is sent.
- **What this repository says about its own standing.** See below.
- **Opening a repository, or a licence.** There is no licence file in this tree,
  so nothing here states an intention about use.

## What is owed elsewhere, and what is open

**The register does not yet know this repository exists.** kanon's
[`docs/glossary.md`](https://github.com/ajreynol/kanon/blob/main/docs/glossary.md)
and the register beside it, read on 2026-09-18, have no entry for *paideia*, and
both describe the two child projects here as belonging to another repository.
Correcting somebody else's register is their edit and not ours; the ask is
[`discussion.md`](discussion.md) `D1`.

**The footing is open, and is deliberately not recorded here.** The front page
says this repository is an *associate* of the Eunoia ecosystem and that it has
joined nothing. The shared policy would have that recorded as a marker on this
page, naming what the repository holds itself to — and this page carries no such
marker, for a reason worth knowing before you add one:

- **The word is in dispute.** koine's `D17`, open with kanon since 2026-09-18,
  asks the office to say which reading of *associate* binds: the policy's
  footings table has an associate held to the shared policy by its own choice,
  and the register's own description has one held to none of it. Those are
  opposite obligations under one word.
- **The command that used to write the marker refuses.** koine's `eo_join`
  dropped `--associate` on 2026-09-18, on its maintainer's instruction, and its
  remaining soft form says in as many words: do not write `associate` or any
  other footing into this tree.
- **And it is a claim about this repository's own standing**, which is the one
  question an agent here must not answer. Asked whether it should hold a
  footing, an agent finds the case for holding one, because finding it is what
  it was asked to do.

**So the state is: the claim is on the front page in prose, and no marker backs
it.** A policy check run against this tree from outside reports that the front
page declares no membership, which is true and is not a defect — it is the check
saying this repository has joined nothing. Resolving it is one of three
decisions, all yours: write the marker, join outright, or keep the note that
claims no footing at all.

## What is deliberately not here

- **No CI.** No `.github/`, no workflow, no ecosystem checker pinned or called. A
  repository that has joined nothing runs none of the ecosystem's checks, and
  adding a runner to a tree is outward-facing and yours.
- **No `tests/`, `deps/` or `prompts/`.** The one script,
  [`check_guide.py`](../scripts/check_guide.py), checks written-guide links,
  indexing and source paths on request. It generates nothing and does not
  validate the semantics of the prose. No runner invokes it automatically.
- **No second overview.** The front page is the only entry point, and
  [`README.md`](README.md) beside this file is the index and nothing else.
