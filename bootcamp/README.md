# Walking through cvc5

How does a solver turn a collection of logical constraints into an answer?
This bootcamp introduces that question through cvc5, then follows it into the
code. It is written for programmers who want to understand or change the
solver. Familiarity with C++ helps in the implementation chapters; no previous
experience building an SMT solver is needed.

## What does an SMT solver do?

An SMT solver asks: **can all of these constraints be true at once?** You
describe the unknowns and the conditions they must satisfy, and the solver
looks for a solution or establishes that there is none.

For example, suppose `x` is an integer and we require `x > 3` and `x < 5`.
There is a solution: `x = 4`. Add the requirement `x != 4`, and there is no
integer left that works. The solver's answers have three names:

- **`sat` (satisfiable):** the constraints have a solution. A **model** describes
  one such solution; here, it assigns `4` to `x`.
- **`unsat` (unsatisfiable):** no solution satisfies all the constraints.
- **`unknown`:** the solver has not established either answer.

This also gives us a way to check claims. To ask whether `x = 4` follows from
the two bounds, add its opposite, `x != 4`. The `unsat` answer rules out a
counterexample. The same pattern lets a verification tool ask whether an
encoded program execution can violate a property. The
[SMT beginner's tutorial](https://cvc5.github.io/tutorials/beginners/overview.html)
develops this connection with worked examples.

## Why “modulo theories”?

**SAT** is the satisfiability problem for Boolean logic: finding true/false
choices that satisfy a formula built with operations such as `and`, `or` and
`not`. **SMT** means *satisfiability modulo theories*. It adds expressions with
mathematical meaning, such as integer inequalities or reads from an array.
A **theory** supplies the rules for those expressions.

The choice of theory matters. Our constraints `x > 3`, `x < 5` and `x != 4`
are impossible over integers, but have a solution over real numbers: `x = 3.5`.
Likewise, arithmetic on fixed-width machine words has overflow rules that
ordinary integer arithmetic does not. The solver needs to know which meaning
your problem uses.

## Where cvc5 fits

[cvc5](https://cvc5.github.io/) is an open-source SMT solver, and the successor
to CVC4. You can run it as a command-line program or call it as a library from
another program. It supports combinations of theories, including arithmetic,
arrays, bit-vectors and strings. The bootcamp uses **SMT-LIB**, a text language
for writing constraints and solver commands, with syntax explained as it
appears in the examples.

Inside cvc5, Boolean search works with specialized theory solvers. Search
explores logical choices; theory reasoning checks whether those choices make
sense together. For instance, a choice that makes both `x > 3` and `x < 0`
true must be rejected by arithmetic. Simplifying expressions before search
and sharing deductions during search help the solver reach an answer. The
[query walkthrough](query.md) follows this cooperation into the implementation.

## How the bootcamp unfolds

The path goes from running a small example to understanding enough of the
implementation to make a small change:

1. **Run a query.** [Build cvc5](build.md), then try the
   [first query](query.md#a-small-query-to-trace). See how adding and removing
   a constraint changes the answer.
2. **Follow the reasoning.** [Observe an inference](observing.md), then learn
   how cvc5 represents [terms](terms.md) and
   [simplifies assertions](preprocessing.md) before search.
3. **Explore a theory.** [How to develop a theory](theory-development/README.md)
   introduces the shared interface and twelve theory sub-guides. Choose a
   topic that interests you; each opens with a small worked problem before
   moving into implementation details.
4. **Make a change.** The [development walkthrough](development.md) connects
   a mathematical rule to its code and a regression test. Return to
   [advanced topics](advanced.md) when you want to investigate results or
   stalled runs more deeply.

Read the opening examples first, predict their answers, and try the suggested
variations. The detailed implementation sections can serve as reference when
you need them.

The [overall architecture and full chapter index](overall-architecture.md)
collect the pipeline diagram, glossary, reading routes and research references.
The implementation chapters use a pinned cvc5 revision; the
[source baseline](source-baseline.md) records that version and how the guide
was checked.
