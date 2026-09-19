# Advanced topics: understanding results and stalled runs

Once you can [follow an inference](observing.md), choose a diagnostic based on
the question you are trying to answer. A solver can find a result whose origin
is unclear, return `unknown`, or keep searching past your time budget. Those
cases call for different evidence.

This chapter draws its topic coverage from Andrew Reynolds's
[Interfaces for Understanding cvc5](https://cvc5.github.io/blog/2024/04/15/interfaces-for-understanding-cvc5.html).
The recipes below are checked against this guide's
[source baseline](source-baseline.md), including its [API contracts][api],
[SMT options][smt-options], [output tags][output] and [command parser][parser].
Use the blog for the broader diagnostic perspective and the pinned definitions
for exact spellings and requirements. The [validation record](source-baseline.md#readability-and-diagnostic-pass)
distinguishes source checks from runs on the available executable.

## Choose the evidence you need

| Situation | Start here | What you can learn |
| --- | --- | --- |
| `unsat`, but which assertions matter? | [Unsat cores](#unsat-cores) | A sufficient subset of the input |
| Which internal deductions supported `unsat`? | [Lemma and instantiation cores](#lemma-and-instantiation-cores) | Deductions retained in the refutation |
| What were the actual derivation steps? | [Proofs and components](#proofs-and-components) | A proof or a selected part of it |
| `sat`, but the values are surprising | [Models and model cores](#models-and-model-cores) | A satisfying interpretation and sufficient assignments |
| `unknown` or a limit was reached | [Incompleteness and limits](#incompleteness-and-limits) | The reported reason and next investigation |
| Which constraints make this input difficult? | [Timeout cores](#timeout-cores), [difficulty](#difficulty-is-an-attribution-heuristic) | A reproducing subset or heuristic attribution |
| What changed before search? | [Preprocessing and learned literals](#preprocessing-and-learned-literals) | Prepared assertions, substitutions and unconditional deductions |
| Why are quantifiers not progressing? | [Triggers and instantiations](#quantifier-triggers-and-instantiations) | Patterns, substitutions, strategy activity and remaining obligations |
| What candidate is the solver considering? | [Candidate models](#candidate-models-after-unknown), [synthesis](#synthesis-diagnostics) | A proposed interpretation or candidate program |
| Why is this run different? | [Configuration and statistics](#configuration-and-statistics) | Effective settings and where work accumulated |

Options such as model, proof and difficulty production must be enabled before
the check they instrument. Ask result-dependent questions immediately after
that check, before changing assertions or popping a scope. Diagnostic output
tags observe events; production and checking options can enable additional
bookkeeping or change the selected solver path. Record the full command.

## Unsat cores

An **unsat core** is a subset of the asserted formulas that is already
inconsistent. It narrows a debugging input while preserving a refutation.
It need not explain the internal reasoning, and the first core need not be
the smallest possible one.

Save as `cores.smt2`:

```smt2
(set-logic QF_LRA)
(set-option :produce-unsat-cores true)
(declare-const x Real)
(declare-const y Real)
(declare-const spare Real)
(assert (! (>= x 4) :named x_lower))
(assert (! (>= y 3) :named y_lower))
(assert (! (<= (+ x y) 6) :named sum_upper))
(assert (! (= spare 42) :named unrelated))
(check-sat)
(get-unsat-core)
```

```sh
build-dev/bin/cvc5 --minimal-unsat-cores --check-unsat-cores cores.smt2
```

The result is `unsat`. The three bounds form the minimal core: together they
require a sum of at least 7 and at most 6; removing any one permits a model.
The assignment to `spare` is irrelevant. Check the names, allowing their order
to vary. This gives you a reason to expect the core, rather than a transcript
to copy blindly.

`--minimal-unsat-cores` tries to remove unnecessary members using more solver
calls. Minimal means no member can be dropped while retaining the established
refutation, not minimum cardinality among all possible cores. In incomplete
fragments, an unsuccessful removal check can also reflect inability to settle
the smaller query. `--check-unsat-cores` reruns a check of the returned core.
Both cost extra work. See [UnsatCoreManager][cores].

Other useful views are `--print-cores-full` for formulas instead of relying on
names, `--dump-unsat-cores` for automatic output after unsatisfiable checks,
and `-o unsat-core-benchmark` for a standalone core benchmark. An unnamed
assertion is still part of the problem; names control how you refer to it in
the text interface.

## Lemma and instantiation cores

`-o lemmas` lets you watch output during search. After `unsat`,
`(get-unsat-core-lemmas)` asks for theory lemmas used in the refutation.
This helps separate a deduction that was produced from one the final proof
actually needed. At this pin the API requires **SAT-proof core mode**.

Copy `cores.smt2` to `lemma-cores.smt2` and replace its last command with
`(get-unsat-core-lemmas)`. Run:

```sh
build-dev/bin/cvc5 --produce-proofs --unsat-cores-mode=sat-proof lemma-cores.smt2
build-dev/bin/cvc5 --produce-proofs --unsat-cores-mode=sat-proof -o unsat-core-lemmas-benchmark lemma-cores.smt2
```

Relate each returned formula to the preprocessed bounds. It can use normalized
atoms or auxiliary symbols. The second command also emits the input core and
its relevant lemmas as a benchmark. Preprocessing may settle a small input,
leaving little theory reasoning to report; an empty list is not automatically
a diagnostic failure. The [unsat-core manager][cores] connects proof leaves
to these two kinds of core.

For quantified inputs, `--dump-instantiations` lists substitutions made for
quantified variables. With proof production enabled, the final unsat dump is
filtered to instantiations used in the refutation. Add
`--dump-instantiations-debug` to obtain inference identifiers:

```sh
build-dev/bin/cvc5 --produce-proofs --dump-instantiations-debug quantifiers.smt2
```

Use the [quantifier example](theory-development/quantifiers.md#worked-example-one-useful-ground-instance).
Identify the substitution for `x` and then the ground arithmetic contradiction.
The dump is not the complete history of attempted matches: candidates can be
discarded, and proof filtering can remove accepted but unused instances.

## Proofs and components

A proof exposes the derivation behind an unsatisfiable result. Enable
`--produce-proofs` and put `(get-proof)` immediately after an `unsat` check,
or use `--dump-proofs` to request output automatically. Try it on the
[singleton rewrite](development.md#worked-change-investigation-membership-in-a-singleton):

```sh
build-dev/bin/cvc5 --produce-proofs --check-proofs --dump-proofs --proof-format-mode=cpc singleton-member.smt2
```

Look for how the membership assertion becomes an equality and how the input
disequality closes the refutation. `--check-proofs` invokes internal checking;
`--proof-granularity=MODE` controls reconstruction detail. Inspect the available
modes before requesting more detail: changing the export format and expanding
rewrite steps are different operations.

The extended command `(get-proof :theory_lemmas)` requests a component instead
of the entire proof. Other component names include `:preprocess`, `:sat` and
`:full`. Components can be especially useful when comparing preprocessing
with theory reasoning; a tiny rewrite example may have little in the theory
component. Component output uses internal proof representation rather than
promising every full-proof export format.

The [proof options][proof-options] at this pin use `--proof-format-mode`, with
CPC as the default and Alethe, LFSC and DOT among the choices. Use the pinned
[proof documentation][proof-docs] for the external checker associated with
each format and its setup. Exporting a proof, internally checking it and
checking it externally are separate steps. Paideia describes these interfaces;
proof assurance is outside this guide's scope.

## Models and model cores

A model supplies values and function interpretations satisfying the input.
For development, request the expressions whose semantics you changed with
`get-value` before inspecting a large `get-model` response. Enable
`:produce-models` before solving. `--dump-models` requests model output after
satisfiable checks; `--check-models` checks returned models internally where
supported. The [model availability code][solver] enforces query state and
production requirements.

A **model core** keeps assignments sufficient to satisfy the input, omitting
symbols whose values can vary without spoiling satisfaction. Save as
`model-core.smt2`:

```smt2
(set-logic QF_LIA)
(set-option :produce-models true)
(declare-const left Int)
(declare-const right Int)
(declare-const unused Int)
(assert (or (>= left 4) (>= right 9)))
(check-sat)
(get-model)
```

```sh
build-dev/bin/cvc5 model-core.smt2
build-dev/bin/cvc5 --model-cores=simple model-core.smt2
```

Both runs should return `sat`. A sufficient core can fix `left` to a value
at least 4, or `right` to one at least 9. All extensions of that sufficient
assignment still satisfy the disjunction. Do not require one particular
branch or numeral in the output. An omitted symbol has not been removed from
the language or proved irrelevant to every other query. Follow
[ModelCoreBuilder][model-core] for how the sufficient assignments are selected.

## Incompleteness and limits

`unknown` says the run established neither satisfiability nor unsatisfiability.
It can result from a time/resource limit, an incomplete reasoning strategy,
an unsupported combination, or a mode deliberately stopping before search.
Start with `-o incomplete`; after an `unknown` result,
`(get-info :reason-unknown)` provides the high-level reason through SMT-LIB.

For an input named `problem.smt2` containing assertions and `check-sat`, try:

```sh
build-dev/bin/cvc5 --tlimit-per=1000 -o incomplete problem.smt2
```

This sets a millisecond limit for each check. It does not promise the example
will time out. `--tlimit` instead limits the run cumulatively, and
`--rlimit-per` limits counted resources rather than elapsed milliseconds.
Resource counts depend on the implementation and options, so keep the revision
with the result.

Read both the high-level explanation and any finer theory reason. A timeout
motivates examining progress and work distribution. A quantifier completeness
reason motivates examining strategies and remaining quantified obligations.
An option-related reason motivates checking configuration first. The internal
identifiers are described in [IncompleteId][incomplete]; their spelling is
not an API stability promise.

Do not diagnose an unsound result merely from seeing `setModelUnsound` in
this route. It tells the solver that its candidate is insufficient to justify
`sat`. The [query chapter](query.md#a-complete-assignment-is-still-a-candidate)
explains how that signal affects the result.

## Candidate models after unknown

With model production enabled, `get-model` and `get-value` can also be useful
after `unknown`. They expose an available candidate interpretation. This is a
proposal for investigation, not a satisfying model of all assertions.

For example, remove the ground comparison from
[quantifiers.smt2](theory-development/quantifiers.md#worked-example-one-useful-ground-instance).
The remaining universal assertion has the mathematical model `f(x) = x + 1`.
If a selected strategy returns `unknown`, inspect the interpretation it tried
and look for an argument at which `f(x) > x` fails. Checking finitely many
values is useful diagnosis but does not prove the universal assertion.

An interrupted run may have no available model, in which case the query can
report that unavailability. At this pin [getAvailableModel][solver] uses the
latest candidate after `unknown` and checks for its existence. Avoid assuming
that every timeout leaves a complete candidate or that a candidate satisfies
every ground constraint in an arbitrary interrupted run.

## Timeout cores

A **timeout core** is an input subset that reproduces a timeout under a
specified per-check budget. It is a way to isolate difficult constraints.
Unlike an unsat core, its significance depends on the solver version,
configuration, budget and machine.

In a copy of the problematic input, enable `:produce-unsat-cores` before
solving and replace the satisfiability query with `(get-timeout-core)`.
Remove subsequent result-dependent commands. Then run:

```sh
build-dev/bin/cvc5 --timeout-core-timeout=100 -o timeout-core-benchmark timeout-input.smt2
```

This performs its own sequence of checks; it does not extract a core from a
previous `check-sat`. The 100 milliseconds applies to those internal checks,
not to the total core computation. It can try many subsets. Interpret its
result as follows:

| Result | Interpretation |
| --- | --- |
| `unknown` with timeout reason and a core | A subset timed out under that budget |
| `unsat` and a core | A tested subset was proved inconsistent |
| `sat` and an empty core | The procedure found the assertions satisfiable |

As a small interface exercise, copy `cores.smt2`, replace its last two commands
with `(get-timeout-core)`, and run the same option on it. This easy problem
can return `unsat`; it is not a reliable timeout benchmark. Replay any reported
timeout subset separately before treating it as a useful reduction.

`(get-timeout-core-assuming (a1 ... an))` searches among the supplied Boolean
assumptions while keeping the ordinary assertions fixed. It lets you select
which portion of the input is eligible for removal. Use a nonempty assumption
list and retain all background assertions when replaying the result. Use
`--print-cores-full` to inspect formulas when assumptions have no `:named`
labels. The [validation record](source-baseline.md#readability-and-diagnostic-pass)
includes an all-`true` assumption edge case that did not behave as expected
on the older test executable; this experimental interface needs replay checks. See
[TimeoutCoreManager][timeout] and the [parser][parser] for the implementation.

The option at this pin is `--timeout-core-timeout`; the blog's
`timeout-core-limit` spelling is not the option declared here.

## Difficulty is an attribution heuristic

Enable `:produce-difficulty` before solving and put `(get-difficulty)` after
the check to obtain scores attributed to input assertions. For a complete
exercise, copy `cores.smt2`, add that production option and replace its final
command with `(get-difficulty)`. Run:

```sh
build-dev/bin/cvc5 -o lemmas difficulty.smt2
```

Compare the scores with the bounds used by the conflict. Scores can be zero
or absent, especially when preprocessing settles the problem. The API treats
unmentioned assertions as zero. A score is neither runtime in milliseconds
nor a mathematical measure of an assertion's inherent difficulty.

The default `--difficulty-mode=lemma-literal-all` attributes lemma activity
to assertions. `lemma-literal` restricts the relevant effort, while
`model-check` uses candidate-model failures. The [difficulty manager][difficulty]
and [preprocessing attribution][difficulty-pp] explain how activity maps back
to original assertions. Use the map after `sat`, `unsat` or `unknown` to choose
what to inspect or vary, then check the proposed explanation with a separate
experiment. Removing a high-scoring assertion can radically change search.

## Preprocessing and learned literals

The [preprocessing chapter](preprocessing.md) uses `-o pre-asserts`,
`-o post-asserts` and `-o subs` to connect surface terms with the prepared
problem. Lemmas typically mention that prepared representation. A missing
surface operator can therefore be a successful elimination, not a failure
to run its theory solver.

A **learned literal** is a unit consequence established from the active
assertions, independent of a tentative SAT branch. To observe such deductions,
save as `learned.smt2`:

```smt2
(set-logic QF_LIA)
(set-option :produce-learned-literals true)
(declare-const x Int)
(declare-const y Int)
(assert (>= x 8))
(assert (or (<= x 2) (>= y 3)))
(check-sat)
(get-learned-literals)
```

```sh
build-dev/bin/cvc5 -o post-asserts -o learned-lits learned.smt2
```

The input is satisfiable, but its first disjunct is impossible, so it entails
`y >= 3`. Look for that consequence or an equivalent normalized form and
identify when it was learned. The final query defaults to input literals
learned outside preprocessing; a consequence already settled in preprocessing
need not appear there. This is why an empty final list does not show failure
to discover the consequence.

The extended query accepts a classification, for example
`(get-learned-literals :preprocess)`. Other classes include `:preprocess_solved`,
`:input`, `:solvable`, `:constant_prop` and `:internal`. Consult the
[learned-literal type definitions][types] and [parser spellings][parser-state]
when comparing the streamed events with the final list. These literals are
consequences of assertions; they are not necessarily valid without those
assertions and are different from arbitrary current-trail assignments.

## Quantifier triggers and instantiations

Use the [quantifier example](theory-development/quantifiers.md#worked-example-one-useful-ground-instance)
and add `:qid grows` to its quantified body's attributes. The name makes
different diagnostics easier to correlate.

```sh
build-dev/bin/cvc5 -o trigger -o inst -o inst-strategy -o lemmas quantifiers.smt2
build-dev/bin/cvc5 --dump-instantiations-debug quantifiers.smt2
```

Find four things: the quantified formula, the pattern `f(x)`, a ground term
`f(a)` that can match it, and the submitted instance at `a`. `-o trigger`
reports selected patterns and can report formulas for which no trigger was
found. `-o inst` reports instantiation activity/counts; `-o inst-strategy`
helps identify participating techniques. The final dump supplies concrete
substitutions and, in debug mode, their inference identifiers.

If there is no useful instance, follow the chain in order: did preprocessing
retain the universal formula, is it active, does a trigger exist, are matching
ground terms indexed, and did the common instantiation utility reject the
candidate as redundant or already entailed? Missing triggers can explain
E-matching inactivity, but other instantiation strategies may still apply.
Many instances with no progress call for inspecting their shapes and whether
they generate ever more matching terms.

For `unknown`, also inspect `-o incomplete` and the responsible module's
completeness claim. A quiet instantiation round is insufficient to establish
a universal statement. The [quantifier chapter](theory-development/quantifiers.md)
connects these observations to `TermDb`, `Instantiate` and module scheduling.

## Synthesis diagnostics

Synthesis searches for a program satisfying a specification within an allowed
grammar. It has candidate generation, candidate checking and a final solution,
so one printed candidate does not establish success.

Save as `successor.sy`:

```sygus
(set-logic LIA)
(synth-fun next ((x Int)) Int
  ((Start Int))
  ((Start Int (x 0 1 (+ Start Start)))))
(declare-var x Int)
(constraint (> (next x) x))
(check-synth)
```

```sh
build-dev/bin/cvc5 --lang=sygus2 -o sygus -o sygus-enumerator -o sygus-sol-gterm successor.sy
```

`x + 1` is an allowed solution. Inspect candidate output, the enumeration
summary and the grammar annotations on the solution. The returned syntax
can differ; verify that it comes from the grammar and satisfies the
specification. In a separate copy, remove the grammar from `synth-fun` and
use `-o sygus-grammar` to inspect the automatically generated grammar.
That tag need not print an automatic grammar when you supplied one explicitly.
See the [synthesis route](theory-development/quantifiers.md#synthesis) for the
connection to datatype enumeration and verification queries.

## Configuration and statistics

A TOML default is the starting value of an option. Initialization can adjust
it for the logic, requested features and option dependencies. Inspect those
changes before comparing implementations:

```sh
build-dev/bin/cvc5 -o options-auto query.smt2
build-dev/bin/cvc5 --stats --stats-internal query.smt2
```

In the first output, identify the effective SAT backend for the incremental
query and the reported reason for any automatic change. Compare it with a
single-check copy run with `--no-incremental` (remove the input
setting that enables incrementality and the push/pop commands). Another useful comparison changes a precise
logic to `ALL` while keeping the formula the same: the broader declaration
can change configuration, even though the formula's mathematical answer is
unchanged. Follow [SetDefaults][defaults] from a reported option name.
`options-auto` lists changes, not a complete dump of all settings.

Statistics summarize work. Internal statistics expose additional timers,
counters and inference histograms; `--stats-all` also includes unchanged
statistics. `--stats-every-query` helps separate checks in an incremental run.
The [statistics documentation][stats] explains these filters. Read a counter's
update site before using it: attempted matches, accepted instances, sent
lemmas and final proof steps are different quantities.

Measure performance with an optimized build and the same input, configuration
and resource budget. A diagnostic run can locate the work; a trace-heavy debug
run is a poor basis for ranking solver strategies. For a reproducible finding,
retain the revision, build features, full input, command, result, relevant
diagnostic excerpt and the small variation that supports your interpretation.

[api]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/include/cvc5/cvc5.h
[smt-options]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/smt_options.toml
[output]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/base_options.toml
[parser]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/parser/smt2/smt2_cmd_parser.cpp
[parser-state]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/parser/smt2/smt2_state.cpp
[cores]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/unsat_core_manager.cpp
[proof-options]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/proof_options.toml
[proof-docs]: https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/docs/proofs
[solver]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/solver_engine.cpp
[model-core]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/model_core_builder.cpp
[incomplete]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/incomplete_id.h
[timeout]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/timeout_core_manager.cpp
[difficulty]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/difficulty_manager.cpp
[difficulty-pp]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/difficulty_post_processor.cpp
[types]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/include/cvc5/cvc5_types.h
[defaults]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/set_defaults.cpp
[stats]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/docs/statistics.rst
