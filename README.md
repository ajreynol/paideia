# paideia

A developer's guide to cvc5: a written account of how the codebase is put
together, for the people who have to work on it.

cvc5 is an SMT solver — a program that decides whether a logical formula can be
satisfied, used inside verification tools, compilers, and program analyzers. It
is large and old, and most of what a newcomer needs to know about it is
currently learned by asking someone who already knows. paideia is where those
answers get written down.

**The [bootcamp artifact](bootcamp/README.md) is ready to read.** It expands
the cvc5 bootcamp into a walkthrough of the architecture and twelve theory
solvers, checked against upstream `main` on 2026-09-18. It is a living draft:
the chapters carry pinned source links, and the
[baseline record](bootcamp/source-baseline.md) explains how they were checked
and how to update them.

## The question it answers

*I have to change cvc5. Where does this live, what will it touch, and what were
the people who wrote it assuming?*

That is a question about the code as it stands: its layout, its moving parts,
the path a query actually takes through it, the conventions that were never
written anywhere. The reader is a competent programmer who is new to this
particular tree, and what they need is orientation.

## The question it does not answer

*Is cvc5 right?*

Nothing here tells you whether the solver is correct, whether an answer it gives
can be trusted, or whether a proof it emits is sound. Those are the questions
the Eunoia ecosystem exists for — Eunoia is a language for defining proof
calculi and checking the proofs cvc5 produces, and its tools do that work.
paideia describes the machine. It does not certify it. Anyone who arrives here
wanting assurance about cvc5's output should leave empty-handed and go find the
checkers.

Two narrower disclaimers ride along. **This is not cvc5's own documentation.**
cvc5 maintains its own docs, and has not asked for this one; nothing written
here binds cvc5 or speaks for it, and where this guide and the source disagree,
the source is right. **And it is not a comprehensive user manual** — it introduces
the SMT-LIB and diagnostic commands needed to investigate the implementation.

## The bootcamp artifact

Start with [Walking through cvc5](bootcamp/README.md). Architecture foundations
cover term ownership, the path of a query and preprocessing.
[How to develop a theory](bootcamp/theory-development/README.md) is a category
with a shared workflow, the common theory interface and twelve theory
sub-guides. Each opens with a worked SMT-LIB problem, expected results and a
diagnostic exercise, then follows the same six development stages as implementation
reference. [Following an inference](bootcamp/observing.md) introduces the
output tags and traces used throughout. [Advanced topics](bootcamp/advanced.md)
cover cores, models, proofs and investigations of stalled or incomplete runs.
The architecture chapters add query and preprocessing walkthroughs; general development
chapters cover building, options, debugging, tests and proof-producing
interfaces, including a concrete rewrite-to-regression exercise.

The [research bibliography](bootcamp/references.md) connects 92 publications
to specific components in the pinned cvc5 `main` source, with citations beside
the tutorial algorithms and examples they explain.

The developer guide is this repository's artifact and lives in `bootcamp/`.
It is Markdown; nothing needs to be installed to read it. The
[chapter index](bootcamp/README.md#chapters) lists its contents. Its source
baseline is
`3dcc1ef5421ab62cc1ee9af52d70042ce6861af0`, observed on upstream `main` on
2026-09-18. Claims were checked by reading source, not by running every solver
path. A small read-only checker validates the guide's links and source paths;
the baseline record gives its commands and limits.

## Repository documentation

| document | what it is for |
| --- | --- |
| [`docs/README.md`](docs/README.md) | the repository documentation index |
| [`docs/maintenance.md`](docs/maintenance.md) | **start here to maintain this tree** — where to start, what the person does, and what this repository is responsible for |
| [`docs/discussion.md`](docs/discussion.md) | what is being said to other tools, staged for a person to carry |

## Common questions

| question | answer |
| --- | --- |
| *Is this cvc5's documentation?* | No. cvc5 keeps its own, and has not asked for this one. Where the two disagree, cvc5's source is right |
| *Where is the guide?* | [Start here](bootcamp/README.md); the [coverage table](bootcamp/bootcamp-coverage.md) maps every bootcamp topic to a chapter |
| *Who decides whether a cvc5 proof can be trusted?* | Not this repository. That is the Eunoia ecosystem's subject, and its tools do it |
| *Where is the shared repository policy this tree is arranged by?* | [kanon's `docs/policy.md`](https://github.com/ajreynol/kanon/blob/main/docs/policy.md), and the name register beside it is [`docs/glossary.md`](https://github.com/ajreynol/kanon/blob/main/docs/glossary.md) |

## The name

*paideia* is Greek παιδεία — education; the rearing and training of a child
(LSJ, s.v. παιδεία). It follows the ecosystem's habit of taking a Greek noun and
a one-line gloss: *kanon*, "the measuring rod"; *eunoia*, "good thinking";
*eschaton*, "the last thing."

The fit is a stretch and it is worth saying so. παιδεία in classical use means
the formation of an entire person into a member of a culture — character
included, the whole education (the sense Werner Jaeger's *Paideia* made famous).
This is a guide to a C++ codebase. The word also names something done *to
children*, which the readers here are not. What survives the shrinkage is the
part that does apply: παιδεία is the word for how a newcomer is brought into a
practice by the people already inside it, and that is the transaction this
repository is trying to write down. The name stands.

**It is not in the register yet.** The ecosystem's authoritative name register
is kanon's [`docs/glossary.md`](https://github.com/ajreynol/kanon/blob/main/docs/glossary.md),
and as read on 2026-09-18 it has no entry for *paideia* — nor does any other
project in the trees use the name. An entry is owed to the president of eo, who
is the one who records what a name means and where the meaning came from; asking
for it is [`docs/discussion.md`](docs/discussion.md) `D1`. Until that entry
exists, the two paragraphs above are this repository's working account and not
the register's.

## Where it sits

paideia is a **member** of the Eunoia ecosystem: it declares membership at the
top of the maintenance note below, and that ecosystem's policy check runs here
on every push. Membership is a claim about the form of this tree and nothing
more — it says nothing about cvc5, which keeps its own documentation, and
nothing about whether a proof can be trusted. The ecosystem records one footing
per tool in
[`ecosystem.json`](https://github.com/ajreynol/kanon/blob/main/scripts/ecosystem/ecosystem.json),
which is kanon's file to write; as read on 2026-09-18 it carries no entry for
paideia.

## How this repository is maintained

This repository is part of the **Eunoia ecosystem** and follows its shared
repository policy, kept by [kanon](https://github.com/ajreynol/kanon) in
[`docs/policy.md`](https://github.com/ajreynol/kanon/blob/main/docs/policy.md).

**Written by AI agents, under light human supervision.** A human directs the
work, reads what is published and decides what is filed; nobody vets the
internal design, and nothing here is carried to another project's issue tracker,
pull request queue or repository by machine.
[`docs/maintenance.md`](docs/maintenance.md) says where the work starts and what
this repository is responsible for.

**What the supervision does not cover.** The maintainer has not re-derived every
claim this tree makes about a repository other than this one; each of those is
read from another tree on the date the claim carries, and is correctable by the
repository it is about. The supervision is of what is *written*, which is the
scope of that review, and the program that runs on every push checks the form of
this tree rather than any claim made in it.

**Which check runs, and what can move under it.**
[`.github/workflows/anoieu.yml`](.github/workflows/anoieu.yml) calls anoieu's
shared workflow at `main` and names the **policy contract** it is checked
against — version 1 — rather than pinning a checker commit. That contract fixes
the obligations and leaves the implementation free to change, so this build can
go red with nothing committed here; when it does, a violation already in the
tree has started being reported, and a new requirement has not arrived.
