# Bags and tables

Source baseline: [2026-09-18](source-baseline.md). Start with
[TheoryBags][theory], [BagSolver][solver], [SolverState][state],
[Strategy][strategy] and [BagReduction][reduction].

## Multiplicity is the central interface

A bag maps elements to nonnegative integer counts, with finite support.
`bag.count(x,A)` is therefore both a bag-theory observation and an arithmetic
term. Different operators have different count equations: disjoint union
adds counts, maximum union takes their maximum, intersection takes their
minimum, subtracting difference truncates subtraction at zero, and removing
difference removes occurrences when the right-hand bag contains the element.

Tables are bags of tuples. Product, join and group operations inherit tuple
structure and multiplicities; replacing them by set operations loses duplicate
rows. A bag solver's relevant element/count inventory is consequently as
important as its inventory of bag terms.

## Preprocessing and supported terms

`ppRewrite` expands choose, cardinality, fold, table aggregate and table
projection. Cardinality is now explicitly reduced by `BagReduction`, with
supporting constraints emitted through the inference manager. It should not
be described as only the old unfinished final cardinality phase.

Reductions for folds and cardinality can introduce quantified structure and
auxiliary functions. Whether a bag input remains a ground solving problem
depends on the operators it uses. A transformation that introduces a
quantifier needs the corresponding logic and quantifier infrastructure; its
integer-looking result does not make the reduction pure arithmetic.

`preRegisterTerm` checks whether bags are enabled, registers equality triggers
and other terms with the engine, and analyzes injectivity for `BAG_MAP`.
`BAG_PARTITION` is explicitly rejected if it survives rewriting to reach this
stage. The bootcamp's old unsupported-operator list includes names no longer
present in the same kind vocabulary; do not copy it as a current API list.
Use [kinds.toml][kinds], the API and the actual preregistration checks together.
`ppAssert` and the ordinary fact callbacks inherit the base behavior.

## A full-effort round

`postCheck` drains pending facts, initializes the current round's state and
runs the strategy. `initialize` clears rebuilt indices, collects disequal
bags, and collects bags and count terms from the equality engine. Term
registration and count purification can themselves produce pending lemmas.

The strategy separates `CHECK_BAG_MAKE`, `CHECK_BASIC_OPERATIONS` and
`CHECK_QUANTIFIED_OPERATIONS`. The last stage is now a real separation in the
implementation, corresponding to the bootcamp's suggestion to avoid mixing
all higher-order work into the basic solver loop.

Basic reasoning produces constraints for empty and constructed bags, the
union/intersection/difference family, duplicate removal and relevant count
terms. Counts must be nonnegative. Disequal bags require an element with
different multiplicity. `bag.make(x,n)` must handle nonpositive `n` and the
possibility that another element term equals `x`; it cannot be modeled as an
unconditional nonempty singleton.

The basic stage also handles filters and table product, join and group.
The separate quantified stage currently dispatches `BAG_MAP`. A noninjective
map can send several source elements to the same
target, requiring aggregation of counts rather than copying a single count.
Filters need the truth of the predicate on each relevant element; table
products and joins combine multiplicities as well as values. Follow the
corresponding `BagSolver::check*` method and inference constructors for the
exact schema. The existence of a quantified stage does not mean every
higher-order operator runs there.

After a round, local facts may enable another round. A sent lemma or conflict
returns control to the outer search. The strategy and pending queues are what
prevent a later phase from assuming that SAT or arithmetic has already
processed a freshly emitted count constraint.

## Equality callbacks and combination

The notification class uses the standard equality/inference adapter; it does
not maintain the same specialized merge metadata as sets. Much of the bag
state is recollected during checking. That trades eager callback complexity
for explicit rebuilding, so caching an old operator map across a round needs
careful justification.

Shared-term notification and equality status use common behavior.
`computeCareGraph` focuses on `BAG_MAKE` and `BAG_COUNT`, grouped by bag element
type and argument representatives. Two counts can refer to the same semantic
element even if the input terms are syntactically different; that equality
must be coordinated with the element theory.

## Models

`collectModelValues` processes relevant bag leaves once per equality class.
It gets the collected element/count pairs, filters them by relevance, maps
elements to representatives and obtains count-skolem values from the model.
`BagsUtils::constructBagFromElements` builds the bag, which is rewritten and
asserted as a skeleton equal to the original leaf.

The current method does not contain the bootcamp's general “add fresh filler
elements here for a larger cardinality” step. Cardinality's reduction and
constraints must already expose the needed structure. Copying the sets model
algorithm into bags would miss that distinction.

For a change, test duplicate elements, zero/negative constructor counts, bag
disequality and two element terms made equal by another theory. For a map or
table change, include repeated outputs/rows so an implementation that preserves
only support, rather than multiplicity, cannot pass by accident.

[theory]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bags/theory_bags.cpp
[solver]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bags/bag_solver.cpp
[state]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bags/solver_state.cpp
[strategy]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bags/strategy.cpp
[reduction]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bags/bag_reduction.cpp
[kinds]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bags/kinds.toml
