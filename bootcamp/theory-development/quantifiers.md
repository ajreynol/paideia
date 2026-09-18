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

### Synthesis

Syntax-guided synthesis is an additional consumer of this architecture.
`SynthEngine` and its helpers under `quantifiers/sygus/` coordinate candidate
programs, examples/counterexamples and verification. Grammars can be encoded
as datatypes, which is why the datatype theory has a SyGuS extension and
last-call behavior. The top-level API path is in `smt/sygus_solver.cpp`.
Changing datatype enumeration or rewriting can therefore affect synthesis
even when ordinary satisfiability tests look unchanged.

## Developing and validating a change

Use the [shared development workflow](README.md#development-workflow)
with these entry points for this theory.

### Where to make a change

| Change | Start here |
| --- | --- |
| A new or changed instantiation strategy | The owning `QuantifiersModule`, term utilities and the common `Instantiate` path |
| Missing work or an unexpected `unknown` | Registration/ownership, nested efforts and per-formula completeness claims |
| Candidate programs or synthesis interactions | `SynthEngine`, the SyGuS helpers and the datatype extension |

### Validation

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
