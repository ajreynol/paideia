# Developing sets and relations

[Bootcamp](../README.md) / [How to develop a theory](README.md)

Source baseline: [2026-09-18](../source-baseline.md). The public theory wrapper is
[TheorySets][theory]; most work is in [TheorySetsPrivate][private], with a
separate [Strategy][strategy], [cardinality extension][card] and
[relational solver][rels].

## Representation and invariants

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

The current extended-sets option is **`sets-exp`**, replacing the spelling
`sets-ext` used in the bootcamp. `ppRewrite` checks it for universe,
complement, join-image and comprehension terms. Comprehensions require a
quantified logic. Aggregate, project, map and fold operations have
higher-order requirements; fold, aggregate and project use reduction helpers.
Private preprocessing also expands choose and singleton tests.

The bootcamp mentions a special nested-difference rewrite in `ppRewrite`.
The current private hook handles choose/singleton expansion; it should not be
described using that old implementation. Find set algebra normalization in
the [set rewriter][rewriter] and its rule files.

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
the relevant reason. This is materially different from the bootcamp's
unconditional rejection description. Support and defaults are in
[sets_options.toml][options] and the corresponding checks.

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

### Validation

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
