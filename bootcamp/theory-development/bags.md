# Developing bags and tables

[Bootcamp](../README.md) / [How to develop a theory](README.md)

A **bag**, also called a multiset, is a collection in which values can occur
more than once. Its essential observation is an element's **multiplicity**,
or number of copies. For distinct values `a,b`, a bag containing two copies of
`a` and one of `b` has three elements counting repetitions, whereas the
corresponding set contains only two values. **Support** means the set of
elements with nonzero counts; a finite bag has finite support.

A **table** is a bag of tuples, so duplicate rows retain their multiplicity.
This matters when modeling database operations: combining rows can change
counts even when the distinct row values stay the same. cvc5 connects bag
operations to equations on integer counts. The bag solver supplies those
equations, arithmetic checks the numbers, and the element theories determine
which apparent elements are equal. This chapter follows that cooperation and
the construction of concrete bags from the resulting counts.

**How do operations on bags become equations about numbers of copies?**

Work through the example first; the six implementation sections that follow
are a reference for tracing or changing that behavior.
See [Following an inference](../observing.md) for how to read the diagnostics.

## Worked example: disjoint union adds multiplicities

Save as `bags.smt2`; use a build with bags enabled and run
`build-dev/bin/cvc5 bags.smt2`. The expected result is `unsat`.

```smt2
(set-logic ALL)
(declare-const A (Bag Int))
(declare-const B (Bag Int))
(declare-const x Int)
(assert (= (bag.count x A) 2))
(assert (= (bag.count x B) 3))
(assert (distinct (bag.count x (bag.union_disjoint A B)) 5))
(check-sat)
```

The required equation is `count(x, A union_disjoint B) = count(x,A) +
count(x,B)`, so the result count must be 5. Here “disjoint union” means
addition of multiplicities; it does not assert that `A` and `B` have
disjoint supports. Both bags deliberately contain `x`.

### Observe the solver

```sh
build-dev/bin/cvc5 -o post-asserts -o lemmas bags.smt2
build-dev/bin/cvc5 -t im bags.smt2
```

Look for `BAGS_UNION_DISJOINT` and find the three counts in its equation.
Purification can make those counts appear under auxiliary names in `im`;
`-o lemmas` can recover original terms when printing. Follow the defining
equalities rather than matching symbol names alone. The arithmetic conflict
should use the resulting sum and the two input counts.

On the maximum-union variant, request the compound bag's count with model
production enabled. It must be 3. A result of 5 would expose precisely the
operator confusion this pair of examples is designed to catch.

### Follow into the implementation

Follow `BagSolver::checkUnionDisjoint` in [BagSolver][solver] to
[InferenceGenerator::unionDisjoint][union-inference]. The latter obtains
multiplicity terms, purifies the compound bag and emits the count equation.
This makes the division of work concrete: bags establishes the equation,
arithmetic reasons about the integers, and subsequent rounds consume the
result. A generated count term is not necessarily the original surface term
printed in the input; use the purification equalities when comparing them.

Replace `bag.union_disjoint` with `bag.union_max`. The count becomes 3 and
the disequality with 5 is satisfiable. This is a small regression pair that
distinguishes two easily confused operators. For element sharing, introduce
`y = x` and query counts using `y`; equal elements must have equal counts.
The upstream [bag example][example] extends these ideas to several concrete
elements and model queries. For tables, remember that tuple identity and
multiplicity are separate: a join that finds the correct rows can still
compute the wrong number of copies.

## Representation and invariants

Source baseline: [2026-09-18](../source-baseline.md). Start with
[TheoryBags][theory], [BagSolver][solver], [SolverState][state],
[Strategy][strategy] and [BagReduction][reduction].

### Multiplicity is the central interface

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

The solver contribution in [TABLES-2024](../references.md#tables-2024) develops
theories of tables and relations. Read its bag semantics beside the count
equations here and the table rules in `InferenceGenerator`; the paper's SQL
translation is outside this implementation mapping. The system overview
[CVC5-2022](../references.md#cvc5-2022) documents the earlier bag support;
the current code includes operations beyond that snapshot.

## Preprocessing and registration

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
stage. Use [kinds.toml][kinds], the API and the actual preregistration checks together.
`ppAssert` and the ordinary fact callbacks inherit the base behavior.

## Fact processing and checking

`postCheck` drains pending facts, initializes the current round's state and
runs the strategy. `initialize` clears rebuilt indices, collects disequal
bags, and collects bags and count terms from the equality engine. Term
registration and count purification can themselves produce pending lemmas.

The strategy separates `CHECK_BAG_MAKE`, `CHECK_BASIC_OPERATIONS` and
`CHECK_QUANTIFIED_OPERATIONS`, keeping the quantified operations in a separate
part of the loop.

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
Here a **map** applies a function to every element. If it sends both `a` and
`b` to `c`, a bag with two copies of `a` and three of `b` produces five copies
of `c`. An **injective** function never identifies distinct inputs, which
makes the count relationship simpler.

Filters need the truth of the predicate on each relevant element; table
products and joins combine multiplicities as well as values. Follow the
corresponding `BagSolver::check*` method and inference constructors for the
exact schema. The existence of a quantified stage does not mean every
higher-order operator runs there.

After a round, local facts may enable another round. A sent lemma or conflict
returns control to the outer search. The strategy and pending queues are what
prevent a later phase from assuming that SAT or arithmetic has already
processed a freshly emitted count constraint.

## Equality and combination

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

## Model construction

`collectModelValues` processes relevant bag leaves once per equality class.
It gets the collected element/count pairs, filters them by relevance, maps
elements to representatives and obtains count-skolem values from the model.
`BagsUtils::constructBagFromElements` builds the bag, which is rewritten and
asserted as a skeleton equal to the original leaf.

Cardinality's reduction and constraints must already expose the structure
needed for larger cardinalities. Copying the sets model
algorithm into bags would miss that distinction.

## Developing and validating a change

Use the [shared development workflow](README.md#development-workflow)
with these entry points for this theory.

### Where to make a change

| Change | Start here |
| --- | --- |
| Operator reductions | `BagReduction`, preprocessing and any introduced quantified structure |
| Count equations, maps or table operations | The selected strategy stage and `BagSolver::check*` inference constructors |
| Sharing or reconstructed multiplicity | Element/count indices, typed care pairs and `collectModelValues` |

### Relate the example to the papers

[TABLES-2024](../references.md#tables-2024) gives a concrete reason to care
about the example's addition of multiplicities: duplicate rows matter under
bag semantics. Contrast `bag.union_disjoint`, which adds counts, with a
maximum-multiplicity union and with the set union in
[RELATIONS-2017](../references.md#relations-2017). Reusing the same inference
for those operators would change the mathematical operation. Follow a count
lemma through `InferenceGenerator` and arithmetic before studying table joins;
the simple count example does not exercise the whole SQL encoding.

### Further validation

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
[union-inference]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bags/inference_generator.cpp#L177
[example]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/examples/api/smtlib/bags.smt2
