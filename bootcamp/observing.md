# Following an inference

You have a small input and an expected answer. How can you tell whether it
reaches the code you intend to change? Start by observing the transformations
and deductions between the input and the result. A correct final answer alone
does not tell you which algorithm produced it.

This chapter uses [query.smt2](query.md#a-small-query-to-trace), whose answers
are `sat`, `unsat`, `sat`. Keep that file in your cvc5 checkout and use the
[development build](build.md#build-a-version-you-can-investigate).
The commands and source links follow the [source baseline](source-baseline.md).

## Predict, observe, locate, vary

The middle query adds `y <= x` to `x <= y` and `f(x) != f(y)`. Arithmetic
forces `x = y`; congruence forces equal function results. Before opening the
code, write down those premises and the contradiction. They give you something
specific to recognize even if cvc5 prints different syntax.

First inspect the problem prepared for search:

```sh
build-dev/bin/cvc5 -o pre-asserts -o post-asserts -o subs query.smt2
```

Find the function disequality and the inequalities at each check. `pre-asserts`
and `post-asserts` show the two sides of preprocessing; `subs` shows learned
substitutions. Incremental output describes preparation for successive checks,
so interpret it together with the assertions retained from earlier scopes.
If a term disappeared here, a breakpoint in its search routine may never fire.

Next observe reasoning and scheduling in separate runs:

```sh
build-dev/bin/cvc5 -o lemmas query.smt2
build-dev/bin/cvc5 -t im -t theory-check query.smt2
```

`-o lemmas` reports formulas on the lemma assertion path with a `:source`
inference identifier. `-t im` reports lemmas, conflicts and internal facts
passing through the common inference manager. `-t theory-check` follows the
base theory check/fact loop. These are different views of the same run, with
different coverage. An internal fact can enable another local inference without
being sent to SAT as a standalone lemma. Specialized theory paths can bypass
the common manager.

An **inference identifier** names the producing rule or route. When you see one,
search for it in the source. For example, if the run reports
`COMBINATION_SPLIT`, use:

```sh
rg -n 'COMBINATION_SPLIT' src/theory
```

Read its description in [inference_id.h][ids] and the call site that sends it.
A combination split can ask search to decide an equality; it is not itself
the arithmetic argument proving that equality. Match the event to its role
before judging whether the expected deduction occurred.

Finally, remove the added inequality or pop its scope. The result must become
`sat` again. Check the values described in the [query exercise](query.md#what-a-model-query-adds).
This variation tests whether the implementation retained the right premises
and invalidated state when those premises disappeared.

## Read the event before the formula

The following shapes summarize the [inference-manager trace][im]; they are
schematic, not a transcript or SMT-LIB commands:

```text
(lemma ID L)
(fact ID C E)
(conflict ID (not E))
```

For the first, inspect the lemma `L`, including any guards. For the second,
`C` is an internal conclusion and `E` is its explanation: the obligation is
`E => C`. For the third, `E` describes an inconsistent conjunction of facts;
the manager prints its negation through `TrustNode::getProven()`.

There is a printing detail at this source revision: the `-o lemmas` path in
[PropEngine::assertTrustedLemmaInternal][prop] prints `getNode()` before
applying the conflict's negation flag. A conflict payload can therefore appear
as `(lemma E :source ID)`, even though SAT receives the negation of `E`.
For example, the [arithmetic exercise](theory-development/arithmetic.md)
can print the conjunction of three incompatible bounds. Do not read that
conjunction as a claim that the bounds are universally true. Inspect the
event kind, its producer and, when needed, the [TrustNode views](development.md#proof-objects-are-part-of-the-implementation).
These diagnostics are an investigation aid, not a standalone proof format.

The two views can also print different terms. `-o lemmas` recovers original
forms of purification skolems, while `im` can show their internal names.
A printed `let` merely names a repeated subexpression within that expression.
Follow definitions and premises rather than expecting text equality between
the input, an internal fact and the SAT-facing formula.

## Choose a diagnostic for a question

| Question | First observation | What it establishes |
| --- | --- | --- |
| Did my operator survive preparation? | `-o pre-asserts -o post-asserts -o subs` | The prepared representation and eliminated terms |
| Did a theory submit a relevant deduction? | `-o lemmas`, then `-t im` | Output events and their producing identifiers |
| Was the fact delivered? | `-t theory-check`, then the theory's own trace | Progress through the selected callbacks |
| Why did this configuration take another path? | `-o options-auto` | Automatic option changes and their reasons |
| Is a returned value consistent with the example? | `get-value` with model production | Values of the expressions whose semantics you know |
| Why did it return `unknown`? | `-o incomplete` | The reported incompleteness or limit reason |
| Which part is doing substantial work? | `--stats --stats-internal` | Counters, inference histograms and timers |

These [output tags][output] and options also lead into the
[advanced investigations](advanced.md), including cores, proof components,
learned literals, quantifier triggers and candidate models.

## When a trace is quiet or too large

Check tracing support before concluding that a callback was skipped:

```sh
build-dev/bin/cvc5 --show-config
build-dev/bin/cvc5 --show-trace-tags
rg -n 'Trace\("im"\)' src/theory/theory_inference_manager.cpp
```

The configuration must enable tracing, and the requested tag must exist in
that build. Output tags (`-o`) do not require a tracing build; debug traces
(`-t`) do. Search for the actual `Trace("tag")` calls in the relevant class
to learn which branches emit it. A supported tag may legitimately print
nothing for a particular input. The theory exercises supply more specific
tags where the common manager is insufficient.

Capture a small run before adding more tags:

```sh
build-dev/bin/cvc5 -t im query.smt2 > query-im.log 2>&1
```

Both streams are captured because trace/output routing can differ. This is a
diagnostic log, so it can contain results and trace text together. Keep the
input, revision and command beside it. Broad traces can overwhelm the useful
events and distort timing; use a separate run without them for measurements.

A useful checkpoint before editing is being able to name one surviving term,
one relevant event or simplification, and the source routine responsible.
After editing, repeat the observation and the semantic variation. Stable
results and valid explanations matter more than preserving an exact event
order or number of printed lemmas.

Next: [terms and ownership](terms.md), or the
[theory interface](theory-development/interface.md) if you already know the
term representation.

[ids]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/inference_id.h
[im]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/theory_inference_manager.cpp
[prop]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/prop/prop_engine.cpp
[output]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/base_options.toml
