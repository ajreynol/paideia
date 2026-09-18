# paideia

A developer's guide to cvc5: a written account of how the codebase is put
together, for the people who have to work on it.

cvc5 is an SMT solver — a program that decides whether a logical formula can be
satisfied, used inside verification tools, compilers, and program analyzers. It
is large and old, and most of what a newcomer needs to know about it is
currently learned by asking someone who already knows. paideia is where those
answers get written down.

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
the source is right. **And it is not a user manual** — it will not teach you to
use an SMT solver or to write SMT-LIB.

## What it would take to run it

Nothing runs. There is no guide yet. This repository contains this README and
nothing else: no prose, no build, no tooling, no tests, nothing to install and
nothing to check out and try. There is no date by which that changes.

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
is kanon's `docs/glossary.md`, and it has no entry for *paideia* — nor does any
other project in the trees use the name. An entry is owed to the president of
eo, who is the one who records what a name means and where the meaning came
from. Until that entry exists, the two paragraphs above are this repository's
working account and not the register's.

## Where it sits

paideia is an **associate** of the Eunoia ecosystem, chosen as such because a
guide to cvc5's source is not specifically about proofs. In that ecosystem's
terms an associate is a repository that carries no membership declaration and
**owes the ecosystem nothing**; it may later record for itself what it holds
itself to. It has not joined, and it is not set up to: `eo_join` has not been
run here.
