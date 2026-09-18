# The path of a query

Source baseline: [2026-09-18](source-baseline.md). The starting point here is a
well-typed formula already constructed by the API or parser.

The system papers [CVC4-2011](references.md#cvc4-2011) and
[CVC5-2022](references.md#cvc5-2022) explain the architecture's evolution;
[SMT-TUTORIAL-2024](references.md#smt-tutorial-2024) supplies the logical
background. Use them with the current call chain below: a system paper's
architecture diagram does not specify today's ownership or callback order.

## SolverEngine and Env

The public `Solver` forwards operations to one [SolverEngine][se]. Its job
includes initializing a solver configuration, tracking legal command states,
maintaining assertions, driving checks and providing result-dependent services.
Subsolvers used by features such as abduction or checking are additional engine
instances; do not assume every engine in a process corresponds to a user's
top-level `Solver`.

`finishInit()` still matters. It finalizes defaults and logic-dependent
configuration, initializes the environment's proof support and internal
solver, chooses a driver, and arranges contexts. An option's declared default
in TOML is not always the effective default for a particular logic or mode.
The bootcamp's proposed “construct the engine only after all initialization”
refactor is not the current organization.

[Env][env] is the common access point for a solver's node manager, SAT and user
contexts, options, logic, statistics, resource management, rewriter,
top-level substitutions, and enabled proof services. `EnvObj` gives internal
objects convenient access to it. “Global” in an `Env` comment means available
throughout that solver; it does not mean a process-wide singleton. The node
manager can outlive and be shared by several environments.

Keep three lifetimes distinct:

| Lifetime | Typical state | What invalidates it |
| --- | --- | --- |
| Term-manager lifetime | Interned nodes, structural attributes, skolem identities | Manager/node reclamation |
| User context | Assertions, definitions and state associated with API scopes | User `pop`, reset or solver destruction |
| SAT context | Current facts, merges, bounds and branch-local deductions | SAT backtracking as well as higher-level teardown |

`CDO`, `CDList`, `CDHashMap` and related [context containers][context] restore
their contents when their context pops. Choosing a context is part of an
algorithm's contract. A permanent “already processed” set can accidentally
prevent a lemma needed after a user pop; a SAT-context set can instead repeat
expensive work on every branch. Explain which behavior a cache requires.

## Assertions enter a pipeline

[Assertions][assertions] keeps input formulas and definitions in scoped state.
Definitions and learned substitutions also participate in the environment's
top-level substitution machinery. Input bookkeeping and the preprocessed
assertion vector have different purposes: the former preserves the user's
problem and scope, while the latter is the problem about to reach SAT.

`SolverEngine::checkSatInternal` checks the request's state and delegates to an
[SmtDriver][driver]. For the ordinary `SmtDriverSingleCall` path, the key
sequence is:

1. Prepare the assertions and assumptions for this call, with the context
   manager handling the necessary scope transitions.
2. Call `SmtSolver::preprocess` on an `AssertionPipeline`.
3. Assert the resulting formulas and auxiliary definitions to the internal
   solver.
4. Call `SmtSolver::checkSatInternal`, which calls `PropEngine::checkSat`.
5. Handle result adjustments associated with the selected preprocessing/driver
   mode and return through the engine's result bookkeeping.

The [SmtSolver][smt] contains the central theory/propositional components and
preprocessing integration. A deep-restart driver exists as a separate path;
do not read the single-call sequence as a guarantee that every user check
performs exactly one internal search. Likewise, `checkSatAssuming` uses scoped
assumptions; it does not permanently append them to the user's assertions.

## PropEngine turns formulas into a Boolean search

[PropEngine][prop] owns the CNF/SAT-facing machinery. `CnfStream` maps Boolean
nodes to SAT literals and emits clauses. Theory atoms get Boolean variables
whose meanings are checked by their theories; Boolean connectives are encoded
as clauses. A SAT assignment to `x < y` is a proposed truth value, not an
arithmetic derivation.

At this baseline the main CDCL(T) SAT default is **CaDiCaL**.
`SetDefaults` selects **MiniSat** by default in incremental mode when the user
has not explicitly chosen the backend. Inspect both
[prop_options.toml][prop-options] and [set_defaults.cpp][defaults]. The SAT
solver used inside a bit-vector backend is a separate selection; the phrase
“the SAT solver” can refer to two different instances.

The [TheoryProxy][proxy] is the boundary for SAT/theory interaction. It receives
new theory literals from the Boolean trail, requests checks and propagations,
obtains explanations, and asks for theory or decision-engine decision requests.
It also manages theory preprocessing, preregistration and notifications to
other modules. Follow this interface before diving into the CaDiCaL external
propagator or MiniSat-specific callback implementation.

Preregistration tells a theory that a term exists and sets up indices and
triggers. Assertion tells it that a literal currently holds. These are
different events. Preregistration policy is configurable, and theories can
have their own additional eager/lazy registration policy. Do not conflate
either of those with when a SAT variable becomes assigned.

The SAT/theory boundary also has an interface-level account in
[IPASIR-UP-2023](references.md#ipasir-up-2023) and
[USER-PROPAGATORS-2024](references.md#user-propagators-2024). Compare their
propagation, explanation and backtracking requirements with the current
[CaDiCaL theory propagator](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/prop/cadical/cdclt_propagator.h).
In the push/pop example below, an explanation must remain valid in the
context in which it is used even though Boolean search may revisit a branch.

## Definitions must participate in decisions

Suppose preprocessing turns `Q or P(ite(c,a,b))` into `Q or P(k)` plus the
definition `ite(c,k=a,k=b)`. The definition exists to give `k` the required
meaning. The [SkolemDefManager][skdef] records dependencies between the use of
a skolem and its defining assertion, allowing the decision machinery to
account for that definition when its use becomes relevant.

This is why adding a raw auxiliary assertion is not always interchangeable
with using the existing skolem-lemma interface. Definitions, proofs,
preregistration and decision relevance all need the same correspondence.

## A complete assignment is still a candidate

The [TheoryEngine][te] orchestrates theory checks, propagation and combination.
At standard effort, theories process new information and inexpensive
deductions during Boolean search. At full effort they must address the
candidate assignment more thoroughly. New facts can require another theory
pass, while a new lemma can require a return to SAT.

When full effort has no pending work or conflict, the engine resets the
candidate model and asks for last-call work where necessary. Some theories
need a built candidate model before they can refine it. Quantifiers also get
a last-call check. A model builder can fail to complete, or a last-call module
can add a lemma; either event prevents treating the candidate as a finished
answer. Model construction is thus part of search, not just serialization
after `sat`.

`setModelUnsound` is an internal completeness signal: the candidate does not
justify returning `sat` under the current reasoning strategy. It is not a
report that a known wrong `sat` answer has already been returned. Resource
limits and incomplete procedures are additional reasons a check can return
`unknown`. Read the result and its explanation instead of inferring a result
from the absence of a theory conflict.

For the mathematical reason that independently plausible theory models may
not combine, read [SHARING-2011](references.md#sharing-2011) and
[CAREFUL-2013](references.md#careful-2013). For the extra obligation introduced
by quantified assertions, compare [FMF-2013](references.md#fmf-2013): assigning
a truth value to a universal formula does not check all its instances.

## A small query to trace

Save this as `query.smt2` and run `build-dev/bin/cvc5 query.smt2`:

```smt2
(set-logic QF_UFLIA)
(set-option :incremental true)
(declare-const x Int)
(declare-const y Int)
(declare-fun f (Int) Int)
(assert (<= x y))
(assert (distinct (f x) (f y)))
(check-sat)
(push 1)
(assert (<= y x))
(check-sat)
(pop 1)
(check-sat)
```

The expected results are `sat`, `unsat`, `sat`. For the first check, choose
`x = 0, y = 1` and different function results. Inside the pushed scope, the
two inequalities imply `x = y`; UF congruence then forces equal function
results, contradicting the disequality. After the pop, only `x <= y` remains,
so the first model is possible again. A cached conflict or branch equality
that incorrectly survives the pop would break the last result.

### Follow the input through the interfaces

| Stop | What to inspect on this problem |
| --- | --- |
| [SolverEngine][se] and [SmtDriverSingleCall][single-call] | Which assertions and scope belong to this check? |
| [ProcessAssertions][process] | Did a substitution, simplification or learned fact already settle it? |
| [CnfStream][cnf] | Which surviving theory atoms have SAT literals? How is a negative atom represented? |
| [TheoryProxy::theoryCheck][proxy-check] | Which assigned literals are delivered before checking theories? |
| [TheoryEngine::check][engine-check] | What effort is requested, and does combination or a lemma require another round? |
| [TheoryUF][uf] and the arithmetic solver | How is equality of the arguments reflected in the applications and their explanation? |

The logical conflict uses the two inequalities and the function disequality.
Its negation is a valid conflict clause. Actual clauses may use normalized
atoms, auxiliary terms and explanations split across theory boundaries.
The route can also end during preprocessing. Treat the table as places to
inspect, rather than an assertion that this tiny input hits every row.

Start with `-o post-asserts -o subs` and then choose traces at the first stage
where the observed formula diverges from the expected one. A breakpoint in
the theory checker is too late if preprocessing already removed the term.

For a debug build, one useful session is:

```sh
gdb --args build-dev/bin/cvc5 query.smt2
```

At the GDB prompt, `break cvc5::internal::TheoryEngine::check` and `run`
locate the central check loop; `bt` identifies the current caller. Inspect
`effort` and step into the active theory's call instead of assuming all
theories run on each visit. If this breakpoint is never reached, inspect the
preprocessed assertions first. See [theory efforts](theory-development/interface.md#effort-levels-are-a-scheduling-contract)
for what full effort promises.

### What a model query adds

Enable `:produce-models` before the first check and put
`(get-value (x y (f x) (f y)))` immediately after a `sat` result. The numeric
choices can vary; check `x <= y` and distinct function results, which also
force `x != y`. Do not request model values after the middle `unsat` result.
This separates a result's logical obligations from a particular printed model.
The upstream [combination example][combination-example] is a next exercise
for observing several theories in one model.

Next: [rewriting and preprocessing](preprocessing.md).

[se]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/solver_engine.cpp
[env]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/env.h
[context]: https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/context
[assertions]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/assertions.cpp
[driver]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/smt_driver.cpp
[smt]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/smt_solver.cpp
[prop]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/prop/prop_engine.cpp
[prop-options]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/prop_options.toml
[defaults]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/set_defaults.cpp
[proxy]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/prop/theory_proxy.cpp
[skdef]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/prop/skolem_def_manager.h
[te]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/theory_engine.cpp
[single-call]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/smt_driver.cpp#L158
[process]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/process_assertions.cpp
[cnf]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/prop/cnf_stream.cpp
[proxy-check]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/prop/theory_proxy.cpp#L205
[engine-check]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/theory_engine.cpp#L386
[uf]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/uf/theory_uf.cpp
[combination-example]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/examples/api/smtlib/combination.smt2
