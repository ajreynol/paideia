# Developing strings and sequences

[Bootcamp](../README.md) / [How to develop a theory](README.md)

Source baseline: [2026-09-18](../source-baseline.md). Start at
[TheoryStrings][theory], [TermRegistry][registry] and [Strategy][strategy].

## Representation and invariants

### Several solvers share one state

The string theory also handles sequences. Its equality engine supplies
congruence and classes; `SolverState` records relationships such as lengths
and disequalities; its inference manager stages facts and lemmas. Several
specialized solvers then operate on that common state:

| Component | Main concern |
| --- | --- |
| [BaseSolver](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/base_solver.cpp) | Initial class information, constants and cardinality |
| [CoreSolver](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/core_solver.cpp) | Concatenation, cycles, flat forms, normal forms and lengths |
| [ExtfSolver](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/extf_solver.cpp) | Evaluation and reduction of extended string operations |
| [RegExpSolver](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/regexp_solver.cpp) | Regular-expression membership reasoning |
| [CodePointSolver](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/code_point_solver.cpp) | Connections between strings and character codes |
| [ArraySolver](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/array_solver.cpp) | Sequence indexing/update and related array-style reasoning |
| [EagerSolver](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/eager_solver.cpp) | Cheap consequences and conflicts on newly asserted/merged facts |

A *normal form* here decomposes a string into concatenated components modulo
known equalities. It is more informative than ordinary syntactic rewriting.
For example, equal concatenations with different constant prefixes can be
inconsistent immediately, while variable prefixes may require a length split.
Length terms cross to arithmetic, so local string consistency is not enough
to construct a global model.

## Preprocessing and registration

`ppRewrite` now includes purification of `STRING_FROM_CODE`, checks on
regular-expression ranges and string alphabet values, optional membership
elimination, and restrictions on extended operators. Some operators also have
eager reductions in the registry. `ppStaticRewrite` performs aggressive string
equality rewriting and eliminates regular-expression equality through its
dedicated rule. The bootcamp's single list under `ppRewrite` obscures this
current separation. `ppAssert` inherits the base behavior.

`preRegisterTerm` is small because it delegates to `TermRegistry` and the
extended-theory registry. The registry handles equality/predicate triggers,
term information, eager reductions and the function terms later used for
combination. Eager preregistration of a SAT atom and eager registration of all
string subterms are distinct policies.

The registered vocabulary is constrained: regular expressions are not general
first-class values that can freely be shared with arbitrary theories.
`notifySharedTerm` explicitly rejects unsupported regular-expression sharing.
The `strings-exp` setting, logic and specific operation together determine
which extended features are accepted; consult [strings_options.toml][options]
and effective defaults.

## Fact processing and checking

The inherited `preCheck` leaves ordinary fact processing to the base loop.
`preNotifyFact` records string-like disequalities and ensures terms introduced
by internal equalities are registered. Returning false allows the official
equality engine to receive the fact. `notifyFact` informs the eager solver,
processes an eager pending conflict, and, in lazy-registration mode, registers
the atom's subterms.

`postCheck` first drains pending facts. At an effort supported by the strategy,
it runs the configured steps, processes resulting inferences and repeats while
local pending work remains without a sent lemma or conflict. This repetition
lets a simple equality enable a stronger local deduction before returning to
SAT. Strategy ordering is defined separately; it is not determined by the
order of helper fields in the C++ class.

Follow `runInferStep` to the implementation of an individual step: initialization,
constant classes, extended-function evaluation, cycle detection, flat forms,
normal-form equality/disequality, code points, length equalities, sequence
array checks, reductions, membership and cardinality. Many steps can stop the
round by producing a lemma. When debugging a missing late inference, first
check whether an earlier step legitimately returned control to SAT.

## Equality and combination

`eqNotifyNewClass` records length and code-term information and informs the
eager solver. The eager solver tracks information such as constant prefixes
and suffixes and bounds relevant to quick conflicts. `eqNotifyMerge` combines
that information and carries over length, code, cardinality-lemma and
normalized-length metadata. A contradiction may be recorded as pending and
then emitted through the inference manager; do not inspect only the callback's
return path. The specialized disequality callback is otherwise unused; explicit
disequalities are handled in fact notification.

In lazy mode, `notifySharedTerm` registers needed subterms. Equality status
uses the common behavior. `computeCareGraph` indexes function terms by a pair
of their owning string-like type and operator, using equality representatives
of arguments. This is essential for polymorphic sequences: `Seq Int` and
`Seq (Seq Int)` must not share an untyped congruence index.

## Model construction

The common relevant-term computation feeds `collectModelValues`, which asks
the selected model-construction helper for string representatives and needed
auxiliary equalities. It processes types in dependency order: a sequence of
sequences needs values for its element sequence type first.

Within a type, `collectModelInfoType` partitions classes by their length terms
and obtains candidate length values from the model/arithmetic side. Pure
classes can be assigned fresh values of that length, respecting distinctness
and the available alphabet/element domain. Composite classes are assembled
from component normal forms. Code-point constraints fix some length-one
values; sequence-array constraints impose additional element assignments.

This can require more search. If too many classes need distinct values at a
length, a length/cardinality split may be necessary. A very large candidate
length cannot simply be allocated as a host-language vector; current code
has special treatment for representability and abstract model pieces. The
invariant is compatibility of the resulting model constraints, not that every
candidate word is eagerly materialized in memory.

## Developing and validating a change

Use the [shared development workflow](README.md#development-workflow)
with these entry points for this theory.

### Where to make a change

| Change | Start here |
| --- | --- |
| New or changed operators | `TermRegistry`, preprocessing and the owning specialized solver |
| A missing inference or stale class information | `TheoryStrings::runInferStep`, pending queues and equality callbacks |
| Sequence sharing or model values | Typed care-graph indices and model construction by length and element dependency |

### Worked example: cancellation, lengths and a candidate word

Save as `strings.smt2`; run `build-dev/bin/cvc5 strings.smt2`. The expected
result is `unsat`.

```smt2
(set-logic QF_SLIA)
(declare-const x String)
(declare-const y String)
(assert (= (str.++ x "a") (str.++ "b" y)))
(assert (= (str.len x) 1))
(assert (= (str.len y) 1))
(assert (distinct x "b"))
(check-sat)
```

The two concatenations have length two. Their first characters must agree,
forcing `x = "b"`; their second characters must agree, forcing `y = "a"`.
The disequality conflicts. Equality of total lengths alone would only give
`len(x) = len(y)` and would miss the content constraint.

Follow [Strategy][strategy] to the dispatch in [TheoryStrings][theory], then
read [CoreSolver][core] for normal-form comparisons and length reasoning.
The length constraints are arithmetic facts; the word equation is string
structure. A relevant inference must explain the equalities and length
conditions it used, or introduce a split when the needed length relationship
is not known. Do not assume that a plausible alignment of components in one
candidate model is an unconditional word equality.

Delete the final disequality, enable model production and ask for `x,y`:
the only values are `"b"` and `"a"`. This exercises reconstruction as well
as refutation. Then remove the two length assertions: many solutions become
possible, and a normal-form procedure may need to split on component lengths.
Use [RegExpSolver][regexp] for a further exercise adding a membership
constraint; regex reasoning is a separate strategy participant, so success
on word equations does not validate it. The upstream [strings example][example]
combines operations, lengths and membership; the [sequence example][seq-example]
shows the corresponding syntax when elements are integers instead of characters.

### Further validation

For a concatenation change, test equalities exposed only after a merge and
both equal- and unequal-length branches. For sequences, include nested
element types and indexing constraints. For membership work, combine a
regular-expression constraint with concatenation and length constraints so
the test crosses the interfaces that standalone regexp simplification misses.

[theory]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/theory_strings.cpp
[registry]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/term_registry.cpp
[strategy]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/strategy.cpp
[options]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/strings_options.toml
[core]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/core_solver.cpp
[regexp]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/strings/regexp_solver.cpp
[example]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/examples/api/smtlib/strings.smt2
[seq-example]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/examples/api/smtlib/sequences.smt2
