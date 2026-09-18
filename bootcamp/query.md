# The path of a query

Source baseline: [2026-09-18](source-baseline.md). The starting point here is a
well-typed formula already constructed by the API or parser.

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

## A small query to trace

Use a formula that survives preprocessing; a trivial equality can disappear
before the layer you are investigating. For example, a mixed UF/arithmetic
problem can have arithmetic establish `x = y` while UF must reconcile
`f(x) != f(y)`. The useful path is: input assertion, preprocessed formula,
SAT atom, theory owner, shared equality, congruence conflict, explanation,
SAT conflict clause. Depending on simplification, some of that work may occur
earlier than expected.

Start with `-o post-asserts -o subs` and then choose traces at the first stage
where the observed formula diverges from the expected one. A breakpoint in
the theory checker is too late if preprocessing already removed the term.

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
