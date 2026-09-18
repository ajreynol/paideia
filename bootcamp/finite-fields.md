# Finite fields

Source baseline: [2026-09-18](source-baseline.md). Follow
[TheoryFiniteFields][theory] to the field-specific [SubTheory][sub],
[CocoaEncoder][encoder], [GB procedure][gb] and [root search][roots].

## One algebraic problem per field

The supported fields here have prime order. A field sort fixes a prime `p`,
and its subtheory reasons over polynomials in `F_p[X]`. Theory leaves become
polynomial variables: a leaf is a term whose internal semantics this
algebraic procedure does not expand, not necessarily a user-declared symbol.

An equality `s = t` becomes the polynomial `s - t = 0`. A disequality can be
encoded using a fresh auxiliary variable `w` and
`w * (s - t) - 1 = 0`. Such a `w` exists exactly when the difference is
nonzero in the field. The encoder must distinguish auxiliary polynomial
variables from input leaves whose values will be exported to the SMT model.

The CoCoA-backed implementation is guarded by `CVC5_USE_COCOA`. A build without
that backend can still contain field syntax and values, but the solving
entry points reject unsupported use. Enabling a field logic at runtime does
not install the dependency. The `ff` feature option and build modes impose
additional configuration checks.

## Preprocessing and registration

The theory supplies a field rewriter and otherwise uses common preprocessing
hooks. There are also assertion-level finite-field passes, including
disjunctive-bit elimination: over a field, `x = 0 or x = 1` can be expressed
as `x*x = x`. This preserves field semantics rather than importing integer
arithmetic on the same numeral spelling.

`preRegisterTerm` first registers equality predicates/terms with the official
equality engine and ensures a subtheory for the appropriate field exists.
The bootcamp describes maintaining the polynomial variable list during
registration. In the current GB route, the encoder scans the accumulated
facts when solving, calls `endScan` to establish its ring/variables, then
encodes those facts. Ring construction therefore belongs to the solver call,
not a promise that preregistration has already assigned every polynomial
variable.

## Facts, Gröbner bases and search

The normal equality-engine fact path remains active. `notifyFact` appends the
signed fact to its field subtheory's SAT-context list. `postCheck` asks each
subtheory to check: nonempty problems require full effort. A conflict is
returned as a conjunction of originating facts; an incomplete full check
marks the candidate model insufficient.

The default `gb` procedure collects polynomial generators and computes a
Gröbner basis. A nonzero constant basis exposes inconsistency: the generated
ideal contains 1. With tracing enabled, the implementation traces the
derivation back to input generators to obtain a conflict core, omitting
auxiliary generators without input facts. Without that tracing it can return
the whole fact set.

A nontrivial ideal is not yet a model over the required finite field. Root
construction proceeds by assignments: use roots of a univariate polynomial
when one is available; for a zero-dimensional ideal, derive a minimal
polynomial for an unset variable; otherwise try values for variables in a
round-robin enumeration. Choices refine the ideal, and failed choices require
backtracking. In particular, possible roots in an algebraic extension are
not automatically values of `F_p`.

`ff-field-polys` can add field equations, but is not the default and should
not be presented as a necessary unconditional preprocessing step. Current
`ff-solver=split` selects a [partitioned Gröbner-basis procedure][split]
instead of the default one-basis route. Read the selected algorithm before
trying to reproduce a trace. Timeout/incomplete results propagate through
the subtheory instead of becoming a guessed model.

## Equality, combination and models

The standard equality-notification adapter handles generic propagation and
constant conflicts. There are no custom per-class field polynomial merges
in `TheoryFiniteFields`: facts are passed to the algebraic subtheory instead.
Sharing, equality status and care-graph work use the common theory behavior.

When the algebraic solver finds an assignment, the subtheory maps input leaf
nodes to `FiniteFieldValue` constants of the correct modulus.
`collectModelValues` exports entries that are in the global relevant-term
set using model equalities. It does not export the artificial inverse
witnesses as if they were user terms. Distinct field sorts must never share
coefficient rings or cached values merely because some numerals coincide.

For a change, test equality and disequality over a small prime where expected
solutions are easy to enumerate, then a problem with two field sorts and an
incremental pop. Include a nontrivial ideal with no root in the base field;
checking only the “basis contains 1” conflict route leaves model search
untested. Configuration details are in [ff_options.toml][options].

[theory]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/ff/theory_ff.cpp
[sub]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/ff/sub_theory.cpp
[encoder]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/ff/cocoa_encoder.cpp
[gb]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/ff/gb.cpp
[roots]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/ff/multi_roots.cpp
[split]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/ff/split_gb.cpp
[options]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/ff_options.toml
