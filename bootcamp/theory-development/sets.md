# Developing sets and relations

[Bootcamp](../README.md) / [How to develop a theory](README.md)

This theory reasons about **finite sets**: unordered collections of distinct
values. Membership says whether a value belongs to a set; union, intersection
and difference construct sets from other sets. **Cardinality** is the number
of distinct elements, so `{1,1,2}` denotes the same set as `{1,2}` and has
cardinality 2. With unknown elements, their equality matters: `{x,y}` can
have cardinality 1 if a model makes `x = y`.

A **relation** is represented as a set of tuples. A binary relation, for
example, contains pairs `(a,b)`; relational operations reason about how such
pairs can be combined. The set solver connects membership structure to the
theories of its elements and to arithmetic for sizes. This chapter follows
those connections from simple membership consequences to witnesses that
distinguish sets and values that satisfy their required cardinalities.

**Why must a set solver count distinct values rather than member expressions?**

Work through the example first; the six implementation sections that follow
are a reference for tracing or changing that behavior.
See [Following an inference](../observing.md) for how to read the diagnostics.

## Worked example: cardinality counts values

Save as `sets.smt2`; run `build-dev/bin/cvc5 sets.smt2`. The expected result
is `unsat`. `ALL` enables the combination of sets and arithmetic used here.

```smt2
(set-logic ALL)
(declare-const A (Set Int))
(declare-const x Int)
(declare-const y Int)
(assert (set.member x A))
(assert (set.member y A))
(assert (distinct x y))
(assert (= (set.card A) 1))
(check-sat)
```

Membership gives two required elements, and the disequality makes their
values distinct. Hence `card(A) >= 2`, contradicting the asserted size. If
the disequality is removed, a model may equate `x` and `y`, leaving a
singleton set. Counting two syntax nodes as two elements would reject that
satisfiable variant.

### Observe the solver

```sh
build-dev/bin/cvc5 -o post-asserts -o lemmas sets.smt2
build-dev/bin/cvc5 -t im sets.smt2
```

Look for the connection between membership information and an arithmetic
cardinality bound. The final conflict may be reported by arithmetic even
though a set inference supplied the decisive constraint. Follow a `SETS_`
identifier into the cardinality extension and distinguish it from any
arithmetic split on the element values.

For the size-three variant, enable model production and request
`(get-value (A x y (set.card A) (set.member x A) (set.member y A)))`.
Check size 3 and both memberships; the extra element can vary. This tests
completion of a partially specified set rather than just conflict detection.

### Follow into the implementation

Read the membership collection in [TheorySetsPrivate][private], then the
[cardinality extension][card] for how membership classes, size constraints
and model construction interact. Arithmetic owns the size values; the set
solver supplies the constraints that make those integers actual cardinalities.
For a model exercise, require `card(A) = 3` while keeping the two distinct
members. The model must supply a third element even though the input never
names it. Query membership and cardinality rather than expecting one specific
choice of that extra integer.

For disequality, the needed witness has a different shape: `A != B` requires
some `k` with different truth values for `k in A` and `k in B`. It does not
require `k` to belong specifically to `A`. This symmetric-difference condition
explains why an inference that always chooses one direction would be too
strong. Continue with the upstream [set example][example] and
[relation example][rel-example] to see finite-set and tuple syntax.

## Representation and invariants

Source baseline: [2026-09-18](../source-baseline.md). The public theory wrapper is
[TheorySets][theory]; most work is in [TheorySetsPrivate][private], with a
separate [Strategy][strategy], [cardinality extension][card] and
[relational solver][rels].

### Membership connects set structure to elements

The solver reasons about set equality and membership, and reduces set
operations to relationships between memberships. For instance,
`x in union(A,B)` means `x in A or x in B`, while membership in an
intersection requires both. Equality of elements is supplied by the
appropriate element theory. Relations are sets of tuples, so relational
reasoning additionally depends on datatype tuple structure.

Cardinality adds an arithmetic obligation: the number of distinct elements
must agree with `set.card`. A list of syntactically different member terms
is not a cardinality calculation, because those terms may become equal.
The cardinality extension maintains a structured account of sets and regions
needed to constrain and construct their sizes.

## Preprocessing and registration

The extended-sets option is **`sets-exp`**. `ppRewrite` checks it for universe,
complement, join-image and comprehension terms. Comprehensions require a
quantified logic. Aggregate, project, map and fold operations have
higher-order requirements; fold, aggregate and project use reduction helpers.
Private preprocessing also expands choose and singleton tests.

Set algebra normalization lives in the [set rewriter][rewriter] and its rule
files, separately from the private preprocessing hook.

`ppAssert` attempts legal variable elimination, but restricts elimination of
set variables in extended mode. `preRegisterTerm` checks first-class element
types, registers equality and membership predicates as triggers, and validates
join-image's constant nonnegative bound. Other terms enter the equality engine.

## Fact processing and checking

The base `preCheck` and `preNotifyFact` behaviors are used. After the equality
engine receives a fact, `notifyFact` processes positive membership. Membership
in a known singleton forces equality with its element; membership in an empty
set conflicts. Membership information is retained in solver state for later
closure rules.

At full effort, `postCheck` gathers relevant asserted terms and runs the
strategy. Its order is reset, basic set reasoning, relations, transitive
closure down/up, filter, map, group, disequality, cardinality and comprehension.
The transitive-closure down/up steps share a graph and run together without
an intervening break. This is a concrete scheduling dependency worth keeping
when refactoring the strategy.

The basic step rebuilds class/term indices, registers cardinality and
relational terms, and applies downward and upward membership closure.
Downward reasoning decomposes a membership in a compound set; upward
reasoning derives membership in a compound from memberships of its operands.
Pending lemmas and eagerly asserted local facts determine when the strategy
restarts or returns to SAT.

Set disequality needs an element in the symmetric difference. The solver
introduces a witness when current membership information does not already
separate the sets. Cardinality then relates the resulting set structure to
integer sizes, including additional elements needed to fill otherwise
underspecified sets.

The current code does **not** simply throw whenever cardinality and relations
are both present. It records specific incomplete combinations, including
cardinality directly over relational terms, and related higher-order/cardinality
cases. If no further inference resolves the issue, `setModelUnsound` carries
the relevant reason. Support and defaults are in
[sets_options.toml][options] and the corresponding checks.

[SETS-2016](../references.md#sets-2016) and its extended account
[SETS-2018](../references.md#sets-2018) explain the cardinality procedure.
Read them beside the cardinality extension, distinguishing membership closure
from constraints on region sizes. [RELATIONS-2017](../references.md#relations-2017)
explains the relational extension. [SET-COMPREHENSIONS-2025](../references.md#set-comprehensions-2025)
connects specifically to `SET_FILTER` and the `set.all`/`set.some` rewrites:
bounded quantification becomes a constraint on a filtered set. Compare
`checkFilterUp`/`checkFilterDown` with `checkReduceComprehensions`, which reduces
general comprehension to quantified formulas. A completeness result for one
of these fragments does not automatically cover their combinations.

## Equality and combination

`eqNotifyNewClass` records empty-set and singleton structure. Merging singleton
classes implies equality of their elements; merging a singleton with empty
produces a conflict. Other merges combine member information, detect
incompatible memberships and propagate consequences. `eqNotifyDisequal`
buffers set disequalities for witness reasoning.

`computeCareGraph` concentrates on `SET_SINGLETON` and `SET_MEMBER`, indexing
by element type and compatible argument representatives. Shared-term
notification and equality status inherit the normal base behavior. A set
solver change involving element equality should therefore be exercised with
elements constrained in UF, arithmetic or datatypes, not only literal values.

## Model construction

Membership facts usually describe only part of a set. If the input says
`x in A` and `card(A) = 3`, a model must choose two additional distinct values
for `A`. Those choices must obey negative memberships and the element type's
available values. Constructing a set model therefore includes completing its
contents consistently with its size.

Without cardinality, a class's known members give a natural finite skeleton:
a union of singletons. With cardinality, the extension orders classes and
fills out or combines values according to the cardinality structure.
`collectModelValues` rewrites these skeletons, asserts their equality to the
set classes and registers both sets and singleton pieces with the global
model. For finite element types, exclusion groups keep added slack elements
from collapsing into already-accounted-for members.

## Developing and validating a change

Use the [shared development workflow](README.md#development-workflow)
with these entry points for this theory.

### Where to make a change

| Change | Start here |
| --- | --- |
| Membership closure or disequality | `TheorySetsPrivate`, strategy steps and witness inference |
| Element equality or class merges | Singleton/member metadata and the typed care graph |
| Cardinality or relational support | The cardinality extension, relational solver and explicit incompleteness cases |

### Relate the example to the papers

In [SETS-2018](../references.md#sets-2018), relate the cardinality constraints
to the example's two **distinct values**. Remove their disequality and the
same two member terms can denote one element. Compare this with
[TABLES-2024](../references.md#tables-2024): set-based relations eliminate
duplicates, while the [bag tutorial](bags.md) must preserve multiplicities.
For a relational rule, write its membership condition on tuples before
following it into the relational solver.

### Further validation

Test a model with fewer known members than its required cardinality and one
where two apparent members become equal. Add a disequality between two sets
with otherwise identical observed memberships to exercise witness creation.
For relational changes, include the operation and any cardinality interaction
explicitly, and check whether the expected outcome is complete solving or an
incompleteness result under the chosen configuration.

[theory]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sets/theory_sets.cpp
[private]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sets/theory_sets_private.cpp
[strategy]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sets/strategy.cpp
[card]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sets/cardinality_extension.cpp
[rels]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sets/theory_sets_rels.cpp
[rewriter]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sets/theory_sets_rewriter.cpp
[options]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/sets_options.toml
[example]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/examples/api/smtlib/sets.smt2
[rel-example]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/examples/api/smtlib/relations.smt2
