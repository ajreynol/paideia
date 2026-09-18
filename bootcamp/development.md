# Making and investigating a change

For work inside a theory solver, pair this general workflow with
[How to develop a theory](theory-development/README.md) and its sub-guide
for the affected theory.

Source baseline: [2026-09-18](source-baseline.md). This chapter describes the
engineering interfaces surrounding the bootcamp's architecture. The upstream
[contribution instructions][contributing] remain the place to check submission
requirements.

## Start with an observable behavior

Before editing, write a small input that exercises the intended path. Record
the cvc5 revision, build type, command line, expected result and actual output.
For a model problem, record the relevant values; for a crash, retain the full
input and diagnostic. A reduced input that preprocessing solves without
entering the target theory cannot validate a change in that theory's search.

Locate the behavior using the guide's pipeline: API/parsing, typing,
rewriting, preprocessing, preregistration, fact assertion, theory strategy,
combination and model construction. Choose the first layer where an invariant
is lost, rather than adding a compensating check at the last layer where the
failure is visible.

## Adding an operator

An operator needs a representation and a route through every interface that
can encounter it. Define its public/internal kinds and mapping, arity and
indexed payload, type rule, construction restrictions, parser/printer support
where applicable, and rewriting. The theory's `kinds.toml` wires much of the
internal dispatch. API kinds and internal kinds are distinct enumerations;
similar names do not make their numeric values interchangeable.

Then decide what reaches the solver. Some operators disappear by rewriting;
some require `ppRewrite` and auxiliary definitions; some remain in the theory's
registered vocabulary. In the latter case, add equality-engine congruence
registration, term/state registration, inference schemas and model evaluation
as required. An API constructor succeeding is only the first stage.

Test wrong arity/types, indexed parameters, the ordinary case and the
boundary semantics. If the operator can contain bound variables or appears in
synthesis grammars, check those routes explicitly. Finally, account for proof
construction and serialization of any new rule or skolem representation.

## Adding a lemma or rewrite

For a lemma, write down the assumptions and conclusion before selecting an
inference-manager method. If current facts imply `C`, output must represent
that implication or have an explanation path for the propagation; emitting
`C` as an unconditional lemma is different. Use an `InferenceId` that makes
the new route identifiable in diagnostics and statistics.

For a rewrite, decide whether it is unconditional normalization, a static
preprocessing transformation, an auxiliary-definition transformation, or a
context-dependent deduction. The same mathematical equation can belong in
different places depending on which assumptions and introduced symbols it
needs. Check termination, idempotence of the normalized result, type
preservation and compatibility with node-attribute caches.

### Worked change investigation: membership in a singleton

Use an existing rule to practice following an implementation before adding
one. The equation `member(x, singleton(y)) = (x = y)` is unconditional:
it depends only on set semantics, so it can be an ordinary rewrite. A claim
`member(x,A) = true` because the current branch asserts `x in A` has a
different lifetime and belongs in contextual reasoning.

Read these files in order:

| Stage | Concrete source and question |
| --- | --- |
| Operator declaration | [Set kinds][set-kinds]: what are `SET_MEMBER`'s argument and result types? |
| Runtime normalization | [TheorySetsRewriter::postRewrite][set-rewrite]: where is membership over `SET_SINGLETON` replaced by equality? |
| Further rewriting | The response is `REWRITE_AGAIN_FULL`; what happens if that new equality itself simplifies? |
| Named proof rule | [Set rewrite rules][set-rules]: locate `sets-member-singleton` and compare both sides with the C++ result |
| Unit-test fixture | [Set rewriter tests][set-tests]: see how `TestSmt`, the node manager and rewriter are obtained |
| End-to-end input | Run the small SMT-LIB regression below, then a satisfiable variant |

Save the following as `singleton-member.smt2`:

```smt2
; EXPECT: unsat
(set-logic ALL)
(declare-const x Int)
(declare-const y Int)
(assert (set.member x (set.singleton y)))
(assert (distinct x y))
(check-sat)
```

Run it through the ordinary executable and, separately, the upstream runner:

```sh
build-dev/bin/cvc5 singleton-member.smt2
python3 test/regress/cli/run_regression.py --tester base build-dev/bin/cvc5 singleton-member.smt2
build-dev/bin/cvc5 --produce-proofs --check-proofs --proof-check=eager singleton-member.smt2
```

The expected result is `unsat`; removing the disequality makes it `sat`.
The ordinary rewrite may settle the whole example, so it exercises
normalization without necessarily exercising set-theory search. Use the
[sets chapter's cardinality example](theory-development/sets.md#worked-example-cardinality-counts-values)
when the changed behavior instead concerns search or model construction.

If changing this rewrite, cover equal and unequal elements, symbolic elements,
and an element type other than integers. Check the normalized term, not just
that the rewrite callback was called. Then compare proof reconstruction with
the named rule. The existence of a similar DSL rule alone does not establish
that every new C++ result is reconstructible.

To contribute a regression, place it alongside the relevant inputs under
`test/regress/cli/`, follow their option/feature metadata, and inspect the
[regression CMake registration][regress-cmake]. `--tester base` above selects
the output/exit-status check for this one input; it does not run every proof,
model and alternate-mode tester. The direct proof command illustrates a
separate check. Record which checks actually ran in the change description.

## Proof objects are part of the implementation

The guide's scope includes how proof-producing code is connected. This section
does not assess the adequacy of any proof system or external checker.

A [ProofNode][proof-node] records a rule application with premises, arguments
and a result. `ProofNodeManager` constructs nodes, while [ProofChecker][checker]
dispatches to rule checkers. A [ProofGenerator][generator] can construct the
proof of a requested formula later, letting a theory avoid building unused
proofs during search. `CDProof` and lazy proof utilities maintain and connect
those steps with the necessary context.

[TrustNode][trust] carries an inference with an optional proof generator.
Its two important views are deliberately different:

| Kind | `getNode()` | `getProven()` |
| --- | --- | --- |
| Rewrite `a` to `b` | `b` | `a = b` |
| Lemma `L` | `L` | `L` |
| Conflict conjunction `C` | `C` | `not C` |
| Propagate `L` from explanation `E` | `E` | `E => L` |

Passing `getNode()` where a caller expects the proven formula is a concrete
source of mistakes, especially for conflicts and rewrites. A `TrustNode` can
have a null generator; its name is not evidence that an independently checked
proof already exists. If a generator is lazy, its remembered premises and
substitutions must still be valid when reconstruction requests them.

At the SMT layer, [PfManager][pfmanager] and proof postprocessing connect
preprocessing, SAT and theory proofs. Rewrite reconstruction also uses the
rule database under `src/rewriter/`. Output translation can impose additional
requirements on terms, skolems and rules. The current proof formats include
CPC, Alethe and LFSC; CPC's definitions are under `proofs/eo/cpc/`, with
printing/conversion code under `src/proof/eo/`.

For an unsatisfiable regression involving a new inference, a useful internal
debugging run is:

```sh
build-dev/bin/cvc5 --produce-proofs --check-proofs --proof-check=eager example.smt2
```

Proof mode, checking granularity, completeness checks and output format are
separate options. Inspect [proof_options.toml][proof-options] and
`smt_options.toml` when interpreting what a run checked. External proof
checking is a further workflow with its own format/version support; printing
a proof or passing an internal debug check is not the same operation.

## Options, traces and statistics

Options originate in TOML files and are processed by
[mkoptions.py][mkoptions]. Put a setting in the appropriate module with its
type, declared default, help and restrictions. Then inspect `SetDefaults` and
option handlers for logic-, build- and mode-dependent adjustments. A new
default can affect proof support, incrementality and subsolvers as well as
the motivating benchmark.

For diagnostics, these commands illustrate the current entry points:

```sh
build-dev/bin/cvc5 --show-trace-tags
build-dev/bin/cvc5 -t theory-check example.smt2
build-dev/bin/cvc5 -o post-asserts -o subs example.smt2
build-dev/bin/cvc5 -o inst -o inst-strategy example.smt2
build-dev/bin/cvc5 --stats --stats-all example.smt2
```

Trace tags need a tracing-enabled build. Search for `Trace("tag")` in the
current source rather than relying on a remembered spelling. Output tags are
a separate interface from debug traces. Statistics live in the solver's
registry; counters/timers added through that registry have consistent lifetime
and reporting. A statistic's name is not sufficient documentation: say whether
it counts candidate inferences, sent lemmas, full checks or repeated rounds.

The `theory-check` trace follows the base fact-processing sequence. More
specialized traces are useful once that establishes that the term reaches the
right callback. For performance, use an optimized build and record options,
input set, time/resource limits and repetitions. Do not rank solver strategies
by a single debug-build run.

## Tests that cross the changed boundary

`test/unit/` contains internal unit tests, `test/api/` API tests, and
`test/regress/cli/` solver inputs exercised by the
[regression runner][regress]. Input metadata such as `EXPECT` and
`COMMAND-LINE` specifies expected output and required options. Follow a nearby
test's conventions and register new tests through the current CMake layout.

After building tests as described in [the build chapter](build.md), first list
the relevant tests, then run a selected test or label:

```sh
ctest --test-dir build-dev -N -R theory_sets_rewriter
ctest --test-dir build-dev --output-on-failure -R theory_sets_rewriter
ctest --test-dir build-dev --output-on-failure -L regress0
```

A rewrite test should verify meaningful semantic edge cases, not only repeat
the new implementation's pattern matching. A theory inference test needs an
input that reaches the inference. A cache or equality-class change needs
backtracking/incrementality coverage; a model change needs satisfiable inputs
and model checking where supported; a proof change needs its proof route.
Run the required upstream checks for the change's scope after the focused
checks pass.

The main-branch build and suite commands are source-checked recipes.
[The baseline record](source-baseline.md#validation-of-the-expanded-examples)
separately records the example and runner checks performed with an older
local executable; those runs do not validate current `main`'s solver suite.

[contributing]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/CONTRIBUTING.md
[proof-node]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/proof/proof_node.h
[checker]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/proof/proof_checker.cpp
[generator]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/proof/proof_generator.h
[trust]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/proof/trust_node.h
[pfmanager]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/proof_manager.cpp
[proof-options]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/proof_options.toml
[mkoptions]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/mkoptions.py
[regress]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/test/regress/cli/run_regression.py
[set-kinds]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sets/kinds.toml
[set-rewrite]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sets/theory_sets_rewriter.cpp#L141
[set-rules]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sets/rewrites#L8
[set-tests]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/test/unit/theory/theory_sets_rewriter_white.cpp
[regress-cmake]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/test/regress/cli/CMakeLists.txt
