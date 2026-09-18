# Developing UF and higher-order reasoning

[Bootcamp](../README.md) / [How to develop a theory](README.md)

Source baseline: [2026-09-18](../source-baseline.md). Main entry:
[TheoryUF][theory]. Helpers include [HoExtension][ho],
[CardinalityExtension][card], [ConversionsSolver][conv] and
[DistinctExtension][distinct].

## Representation and invariants

### What the solver represents

For ordinary ground UF, the main invariant is congruence: if `a = b`, then
`f(a) = f(b)`. The equality engine stores this relationship, detects collisions
between incompatible facts and explains them. UF also participates in shared
equalities for terms whose primary syntax comes from other theories.

The directory contains more than first-order congruence closure. Finite model
finding needs bounds on uninterpreted-sort domains; higher-order logic needs
function-valued terms and extensionality; arithmetic/bit-vector conversions
need a bridge between two value theories. Current UF also has dedicated
reasoning for `DISTINCT` terms that survive preprocessing.

## Preprocessing and registration

`ppRewrite` checks the use of higher-order terms against the logic. `HO_APPLY`
and first-class function terms require a higher-order logic, as do ordinary
applications whose operator has a higher-order type. Higher-order preprocessing
delegates to `HoExtension`, which cooperates with lambda lifting. Fully applied
higher-order applications can be related to ordinary `APPLY_UF`; partially
applied functions cannot simply be treated as first-order applications.

With eager arithmetic/BV conversion enabled, the `BITVECTOR_UBV_TO_INT` and
`INT_TO_BITVECTOR` operators are eliminated here. Otherwise they are retained
for the conversion solver. `ppAssert` uses the base behavior.

`preRegisterTerm` registers with the cardinality extension when enabled, sets
equality triggers, records function applications, and lazily constructs the
conversion solver when a conversion first appears. A lifted lambda in
higher-order mode is added as a shared term. Some internal kinds, including
uninterpreted-sort model values, are not legal input facts to this solver.

During initialization, `APPLY_UF` is registered as a congruence function kind;
higher-order mode additionally registers `HO_APPLY` and accounts for equality
between function operators. This is the part to inspect if a new application
representation fails to propagate equalities even though all arguments are
registered.

## Fact processing and checking

The normal base fact loop asserts predicates and equalities into the official
equality engine. `notifyFact` forwards facts to the cardinality extension,
including whether the SAT literal was a decision. It dispatches `DISTINCT`
facts and handles higher-order function disequalities.

For **negative** equality `f != g`, extensionality requires an argument at
which the functions differ. The higher-order extension introduces and manages
that witness. The bootcamp's description of this trigger as a positive
function equality is incorrect at this baseline. Positive function equality
instead participates in congruence.

`postCheck` runs the cardinality extension where enabled, runs conversions at
last call, checks the distinct extension, and invokes higher-order checking at
full effort. `needsCheckLastEffort` reflects which of these extensions needs
the final candidate stage. A no-op `postCheck` in a minimal UF example says
little about a problem using finite domains or conversions.

[HIGHER-ORDER-2019](../references.md#higher-order-2019) explains the
higher-order extension; compare its function-extensionality obligation with
`HoExtension`'s witness for `f != g`. Finite-domain work follows a different
route: [FMF-2013](../references.md#fmf-2013) and
[FMF-CONSTRAINTS-2017](../references.md#fmf-constraints-2017) explain why
congruence alone does not settle domain cardinality.

## Equality and combination

The new-class, merge and disequality notifications maintain the cardinality
extension when it is active. Congruence and trigger propagation still occur
even when no specialized cardinality callback work is needed. The cardinality
extension must keep domain-size constraints compatible with the equalities
and disequalities currently held by the engine.

`computeCareGraph` indexes applications by operator and, where required, type.
It uses representatives of their arguments and checks pairs relevant to shared
terms. Higher-order applications need indices accounting for function types;
unsigned BV-to-integer conversions need the input bit-vector type. Mixing
different widths or different instantiated function types in one index would
create invalid comparisons.

`getEqualityStatus` returns proven equality or disequality when the engine has
it, and otherwise `EQUALITY_FALSE_IN_MODEL`. This supports constructing a model
with different values for unconstrained classes. It does not establish a new
logical disequality. `notifySharedTerm` needs no additional UF-specific
override beyond the base registration.

## Model construction

Ordinary UF function interpretations are assembled by the common model
machinery from applications and their argument/result values. The UF
`collectModelValues` override adds higher-order model information through
`collectModelInfoHo`. Function disequalities need extensional witnesses in
that model too; simply assigning the same lambda to unconstrained function
classes can violate the input.

## Developing and validating a change

Use the [shared development workflow](README.md#development-workflow)
with these entry points for this theory.

### Where to make a change

| Change | Start here |
| --- | --- |
| Application registration or congruence | `preRegisterTerm` and the registered `APPLY_UF`/`HO_APPLY` function kinds |
| Function disequality or its model witness | `notifyFact`, `HoExtension` and `collectModelInfoHo` |
| Finite domains, conversions or distinct constraints | The corresponding extension and its effort/context requirements |

### Worked example: explaining a congruence conflict

Save this as `uf.smt2` and run `build-dev/bin/cvc5 uf.smt2` from your cvc5
checkout. The expected result is `unsat`.

```smt2
(set-logic QF_UF)
(declare-sort U 0)
(declare-const a U)
(declare-const b U)
(declare-const c U)
(declare-fun f (U) U)
(assert (or (= a b) (= a c)))
(assert (distinct (f a) (f b)))
(assert (distinct (f a) (f c)))
(check-sat)
```

There are two possible equality branches. If SAT chooses `a = b`, congruence
forces `f(a) = f(b)`, contradicting the first disequality. If it chooses
`a = c`, the other disequality conflicts. The disjunction prevents simply
substituting one unconditional input equality for `a`.

Read [function-kind registration][register-functions], then
[term preregistration][register-terms], then the equality engine's
[explanation interface][explanations]. For the first branch, the relevant
conflicting assumptions are `a = b` and `f(a) != f(b)`. The corresponding
clause is `a != b or f(a) = f(b)`. The second branch has the analogous
clause with `c`. This is a logical explanation of the conflict; the exact
internal representatives and clause presentation can differ.

Notice the direction of the rule. Ordinary UF does **not** make `f` injective:
`f(a) = f(b)` does not imply `a = b`. As an exercise, replace the assertions
by `a != b` and `f(a) = f(b)`. The result should be `sat`, with a function
interpretation that maps two domain elements to the same result. Compare the
larger upstream [UF example][example] for function/model queries. Use
`-o post-asserts` before choosing a breakpoint; even a conditional example
can be simplified before a particular search callback runs.

### Relate the example to the papers

The clause `a != b or f(a) = f(b)` records the equality premise needed for
congruence. For terms owned by different theories, continue with
[SHARING-2011](../references.md#sharing-2011) and
[CAREFUL-2013](../references.md#careful-2013): find where the theories agree
on the argument equality before using it in their local reasoning.

### Validation

To trace congruence, use `a = b` together with `f(a) != f(b)` and watch where
simplification resolves it. To exercise search instead, keep the equality
conditional so it survives preprocessing. For an extension change, add a
separate case involving that extension, such as function disequality or a
conversion at a nontrivial width. Test a push/pop around the relevant fact so
equality-class and extension state must recover together.

[theory]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/uf/theory_uf.cpp
[ho]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/uf/ho_extension.cpp
[card]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/uf/cardinality_extension.cpp
[conv]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/uf/conversions_solver.cpp
[distinct]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/uf/distinct_extension.cpp
[register-functions]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/uf/theory_uf.cpp#L88
[register-terms]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/uf/theory_uf.cpp#L299
[explanations]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/uf/equality_engine.h#L207
[example]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/examples/api/smtlib/uf.smt2
