# Developing quantifiers and synthesis

[Bootcamp](../README.md) / [How to develop a theory](README.md)

Source baseline: [2026-09-18](../source-baseline.md). Read
[TheoryQuantifiers][theory], [QuantifiersEngine][engine], the
[module interface][interface] and [module initialization][modules] in that
order.

## Representation and invariants

### Ground search proposes; quantifiers refine

SAT and the ground theories can assign a Boolean value to a quantified formula
without establishing that every instance holds. The quantifiers engine supplies
instances, witnesses and model checks needed to close that gap. For a universal
formula `q = forall x. P(x)`, instantiating at `t` supplies `q => P(t)`.
Generating this lemma is useful only if `t` has the right type, substitutions
respect binding and the lemma reaches the ground solver with its explanation.

The public theory wrapper is intentionally small. The larger engine owns
shared utilities, state, registries, model support, inference management and
a set of configurable `QuantifiersModule`s. Each module can request work at
particular efforts, claim ownership of formulas, and report whether its work
is complete for a formula.

## Preprocessing and registration

The quantifier rewriter and assertion-level quantifier passes normalize
quantified formulas before search. The theory itself has no special
`ppRewrite` override. If quantified macros are enabled, `ppAssert` can solve
a formula such as `forall x. f(x) = t(x)` for a function definition
`f = lambda x. t(x)`, subject to mode and elimination checks. Arbitrary
universals are not definitions, and recursive or ill-scoped substitutions
cannot be accepted on that pattern alone.

`preRegisterTerm` forwards universal quantifiers to
`QuantifiersEngine::preRegisterQuantifier`. The engine arranges module
registration/ownership and term information. Module methods are named
`registerQuantifier` and `preRegisterQuantifier`; they are not all copies
of the ground theory's `preRegisterTerm` API.

## Fact processing and checking

`preNotifyFact` sends the quantified atom and its polarity to
`assertQuantifier` and returns true. This skips the base equality assertion
and `notifyFact` call. Negative universals require counterexample witnesses,
handled through the quantifiers' skolemization machinery. Positive universals
become obligations for the active modules.

### The main strategies and their shared infrastructure

E-matching uses patterns and indexed ground terms modulo equality to propose
substitutions. For a pattern `f(x)`, a ground application `f(a)` suggests
`x := a`; multi-patterns join compatible matches. The
[InstantiationEngine][ematching] coordinates user patterns and generated
triggers. The [TermDb][termdb] and term registry determine which terms and
representatives are currently available.

Conflict-based instantiation tries to find instances immediately useful to
the current ground assignment. Counterexample-guided instantiation uses
theory-specific reasoning to obtain substitutions. Finite model finding and
model-based quantifier instantiation examine candidate interpretations and
seek missing cases. Enumeration, pools, bounded-integer handling and
higher-order support provide additional routes. The module initializer is
the source of truth for which ones are constructed under a given option set;
not all run on every input.

All these routes should use the common [Instantiate][instantiate] utility
rather than emit arbitrary copies of a quantified body. It handles the
substitution, eligibility and entailment checks, duplicate recording, proof
information and lemma submission. A requested instantiation can be discarded
because it is redundant or already entailed; counting candidates and counting
sent lemmas are different measurements.

Current code includes an instantiation-evaluation layer under `quantifiers/ieval`.
Its [manager][ieval] resets evaluators at instantiation-round boundaries so
cached evaluation remains consistent with the term database. A persistent
cache keyed only by the quantified formula would miss changes to relevant
ground terms and equalities.

### Match an instantiation strategy to its paper

The worked `f(a)` example below illustrates the common instance shape. The
following papers explain different ways of finding the substitution; they
should not be read as interchangeable descriptions of one algorithm.

| Strategy and paper | Current implementation reading task |
| --- | --- |
| E-matching: [LOCAL-EXTENSIONS-2015](../references.md#local-extensions-2015), [CCFV-2017](../references.md#ccfv-2017) | Follow trigger terms and equality representatives; [trigger metadata](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/ematching/trigger_term_info.h) cites free-variable congruence closure |
| Conflict-based: [CONFLICT-INST-2014](../references.md#conflict-inst-2014) | [QuantConflictFind](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/quant_conflict_find.cpp): identify the candidate ground conflict used to guide substitution |
| Enumeration: [ENUM-INST-2018](../references.md#enum-inst-2018) | [InstStrategyEnum](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/inst_strategy_enumerative.h): separate tuple generation from entailment filtering |
| Theory-specific CEGQI: [ARITH-CEGQI-2017](../references.md#arith-cegqi-2017), [BV-INVERT-2018](../references.md#bv-invert-2018), [BV-INVERT-2021](../references.md#bv-invert-2021) | [CegInstantiator](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/cegqi/ceg_instantiator.h) and per-theory instantiators: find the arithmetic projection or invertibility condition |
| Syntax-guided: [SYQI-2021](../references.md#syqi-2021) | Ask which grammar supplies terms unavailable from ordinary ground matching |
| Model-based: [MBQI-2009](../references.md#mbqi-2009), [MBQI-ENUM-2025](../references.md#mbqi-enum-2025) | [InstStrategyMbqi](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/inst_strategy_mbqi.h) and [MbqiEnum](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/mbqi_enum.cpp): connect a counterexample in the candidate model to terms usable in an instance |
| Choice terms: [CHOICE-INST-2026](../references.md#choice-inst-2026) | In `MbqiEnum`, follow the choice grammar, witness elimination and the auxiliary lemmas constraining introduced symbols |

### Two dimensions of effort

`TheoryQuantifiers::postCheck` delegates to the engine, which has its own
efforts `CONFLICT`, `STANDARD`, `MODEL` and `LAST_CALL`. These are nested inside
the outer theory effort; `QEFFORT_MODEL` is not another spelling of
`Theory::EFFORT_FULL`.

The engine determines which modules need checking and when any of them needs
a model. It resets round state, builds a candidate model at the requested
point, calls modules and flushes pending inferences. A new lemma or conflict
stops the current sequence so ground reasoning can catch up.

At outer last call, a quiet round is insufficient to justify `sat`.
Utilities and modules must not report global incompleteness, and each asserted
quantified formula must have an applicable module that claims completeness
for it. An owning module has a special role in that decision. Limits on
instantiation rounds and unsupported cases can supply an incompleteness
reason. `setModelUnsound` then prevents accepting the candidate as a complete
model; it is not a diagnosis of an already-returned wrong answer.

As a current behavior change, `cegqi-midpoint` is enabled by default. It uses
midpoint-based substitutions for relevant arithmetic cases; the former virtual
term substitution route is restricted by safe/stable configurations. Defaults
and restrictions are defined in [quantifiers_options.toml][options] and
`SetDefaults`, not by which strategies existed when the bootcamp was written.

## Equality and combination

The theory does request an equality engine with `d_useMaster = true`.
Quantifier matching and indexing need ground equalities even though quantified
facts do not enter that engine through the ordinary base fact loop. “No
specialized equality callbacks” must not become “quantifiers does not use
equality information.”

The theory does not implement a specialized ground care graph or a family of
per-class equality callbacks; it instead consumes shared/master equality and
model information through its utilities.

## Model construction

`collectModelValues` records the asserted Boolean polarity of quantified
formulas in the model. This makes value queries agree with the asserted
literal; it does **not** independently evaluate a universal formula over all
values. Satisfaction is the engine's completeness obligation described above.

The finite-model line develops through
[FMF-INSTANTIATION-2013](../references.md#fmf-instantiation-2013),
[FMF-2013](../references.md#fmf-2013) and
[FMF-CONSTRAINTS-2017](../references.md#fmf-constraints-2017). Compare each
paper's domain/instance completeness argument with the owning module's
completeness check. [RECURSIVE-FUNCTIONS-2016](../references.md#recursive-functions-2016)
adds recursive definitions; [INDUCTION-2015](../references.md#induction-2015)
addresses induction; [HIGHER-ORDER-2019](../references.md#higher-order-2019)
adds function-valued terms. These features share infrastructure but introduce
different obligations.

### Synthesis

Syntax-guided synthesis is an additional consumer of this architecture.
`SynthEngine` and its helpers under `quantifiers/sygus/` coordinate candidate
programs, examples/counterexamples and verification. Grammars can be encoded
as datatypes, which is why the datatype theory has a SyGuS extension and
last-call behavior. The top-level API path is in `smt/sygus_solver.cpp`.
Changing datatype enumeration or rewriting can therefore affect synthesis
even when ordinary satisfiability tests look unchanged.

The paper-to-code route is especially explicit here:
[SYGUS-CEGQI-2015](../references.md#sygus-cegqi-2015) is cited by
`SynthEngine` and [EmbeddingConverter](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/sygus/embedding_converter.h).
[REFUTATION-SYNTHESIS-2019](../references.md#refutation-synthesis-2019)
gives the extended account, and [CVC4SY-2019](../references.md#cvc4sy-2019)
explains fast term enumeration. For a candidate that fits all current
examples, identify the verification query that can still reject it.

Several further procedures have identifiable components in this snapshot:

| Procedure and paper | Current code and reading task |
| --- | --- |
| Classification: [SYGUS-CLASSIFICATION-2019](../references.md#sygus-classification-2019) | [CegisUnif](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/sygus/cegis_unif.h) cites the paper; follow how classified pieces become a full candidate |
| Reuse inside SMT: [SYGUS-CORE-2017](../references.md#sygus-core-2017) | `ExampleEvalCache` and `SygusQePreproc`: identify the evaluation or elimination result that justifies pruning |
| Abduction: [ABDUCTION-2020](../references.md#abduction-2020) | `SygusAbduct` and `AbductionSolver`: find both the implication and consistency obligations |
| Constant repair: [SYNTHESIS-CONSTANTS-2023](../references.md#synthesis-constants-2023) | `SygusRepairConst`: follow the quantified query that fills symbolic constant positions in a candidate |
| Solution fitting: [SOLUTION-FITTING-2023](../references.md#solution-fitting-2023) | `SygusReconstruct`: match a solution to a target grammar using enumeration and discovered equalities |
| Oracle reasoning: [ORACLES-2022](../references.md#oracles-2022) | `OracleEngine` explicitly cites the paper; `OracleChecker` relates current interpretations to external responses |

## Developing and validating a change

Use the [shared development workflow](README.md#development-workflow)
with these entry points for this theory.

### Where to make a change

| Change | Start here |
| --- | --- |
| A new or changed instantiation strategy | The owning `QuantifiersModule`, term utilities and the common `Instantiate` path |
| Missing work or an unexpected `unknown` | Registration/ownership, nested efforts and per-formula completeness claims |
| Candidate programs or synthesis interactions | `SynthEngine`, the SyGuS helpers and the datatype extension |

### Worked example: one useful ground instance

Save as `quantifiers.smt2` and run
`build-dev/bin/cvc5 -o inst quantifiers.smt2`. The expected satisfiability
result is `unsat`; diagnostic output can vary with the selected strategy.

```smt2
(set-logic UFLIA)
(declare-fun f (Int) Int)
(declare-const a Int)
(assert (forall ((x Int)) (! (> (f x) x) :pattern ((f x)))))
(assert (<= (f a) a))
(check-sat)
```

Let `q` name the universal assertion. The ground term `f(a)` matches the
pattern `f(x)`, proposing `x := a`. An instance has the logical shape
`q => f(a) > a`. With `q` asserted, arithmetic receives a strict lower
comparison that conflicts with `f(a) <= a`. The instance is a lemma linking
the universal obligation to ground reasoning; matching does not itself
perform the arithmetic refutation.

Read [TermDb][termdb] for indexed applications, the
[instantiation engine][ematching] for trigger handling, and
[Instantiate][instantiate] for the shared submission path. Other enabled
modules or preprocessing may discover the contradiction first. A user pattern
makes the intended match explicit, but does not guarantee that E-matching
will be the module credited for the final answer.

For an equality-aware matching exercise, change the ground comparison to
`f(b) <= a` and assert `a = b`. The instance at `b`, together with that
equality, still refutes the input. When studying a failed match, inspect both
the stored ground term and its equality representative, then check whether
the proposed instance was discarded as already entailed or duplicated.

Removing the ground comparison leaves a satisfiable formula, for example
with `f(x) = x + 1`. That mathematical witness does not guarantee a particular
incomplete strategy returns `sat`. Read the engine's completeness checks when
the result is `unknown`; producing no new instance is insufficient evidence
that all integers were covered.

### A concrete synthesis entry point

The upstream [SyGuS function example][sygus-example] declares functions to
synthesize, their grammars and constraints, then calls `check-synth`.
Start there to distinguish grammar terms from the values a candidate program
computes. Follow [SygusSolver][sygus-solver] into
[SynthEngine][synth-engine], and return to the
[datatype sub-guide](datatypes.md#model-construction) for grammar constructor
enumeration. A candidate program satisfying the current examples still needs
the verification step against the synthesis conjecture; a counterexample
extends the next round's obligations.

### Further validation

When debugging a missing instance, follow formula registration, ownership,
active assertion, eligible term indexing, candidate match, `Instantiate`
filtering and lemma submission in that order. For an unexpected `unknown`,
inspect completeness reasons as well as the number of generated instances.
Useful tests include nested binders, repeated instantiations after context
changes, equal ground terms, and a satisfiable quantified problem in a
fragment the selected procedure claims to complete.

[theory]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/theory_quantifiers.cpp
[engine]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers_engine.cpp
[interface]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/quant_module.h
[modules]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/quantifiers_modules.cpp
[ematching]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/ematching/instantiation_engine.cpp
[termdb]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/term_database.cpp
[instantiate]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/instantiate.cpp
[ieval]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/ieval/inst_evaluator_manager.h
[options]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/quantifiers_options.toml
[sygus-example]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/examples/api/smtlib/sygus-fun.sy
[sygus-solver]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/sygus_solver.cpp
[synth-engine]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/sygus/synth_engine.cpp
