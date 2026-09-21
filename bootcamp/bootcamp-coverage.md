# Bootcamp coverage and corrections

This page is a map from the original bootcamp notes to the expanded tutorial.
It helps returning readers find a familiar topic and helps maintainers keep
track of corrections. To learn the solver concepts for the first time, start
with [Walking through cvc5](README.md) and use the linked chapters below as
needed. The tutorial explains its own terminology and examples; the original
notes are not required reading.

The original notes mix explanations, questions, TODOs and suggested changes.
The following table accounts for their sections without treating an old
suggestion as a current implementation.
All current-code statements use the [source baseline](source-baseline.md).

## Coverage

| Bootcamp topic | Where it is developed |
| --- | --- |
| Disabling theories at build time; binary/dependency footprint; kind/type-checker references | [Building](build.md#can-a-theory-be-disabled-at-build-time) |
| Reducing build times; measure hotspots first | [Build performance](build.md#reduce-build-time-by-measuring-the-right-thing) |
| API Term/Sort/Solver and internal Node/TypeNode | [Terms](terms.md#public-handles-and-their-managers) |
| Children, operators, APPLY kinds, indexed payloads and metakinds | [Node representation](terms.md#a-node-is-a-shared-dag-vertex) |
| Values versus symbols/bound variables/nullary operators; canonicality; sets, sequences, arrays/functions | [Value representation](terms.md#symbols-values-and-nullary-operations) |
| TNode, attributes, Boolean attribute default, node lifetime and rewrite-cache scope | [Lifetimes and attributes](terms.md#references-and-attributes-have-different-lifetimes) |
| Purification, named/dummy skolems, extensionality and definition recovery | [Skolems](terms.md#skolems-record-why-a-new-symbol-exists) |
| NodeManager, SolverEngine, Env/EnvObj, subsolvers, options, contexts and statistics | [Query architecture](query.md#solverengine-and-env) |
| Assertions/definitions, SmtDriver, preprocessing and finishInit | [Query lifecycle](query.md#assertions-enter-a-pipeline), [preprocessing](preprocessing.md) |
| ppRewrite/expandDefinitions, term ITEs, Boolean terms, quantified-body caveat and output tags | [Preprocessing](preprocessing.md#remove-term-level-formulas-without-losing-semantics) |
| PropEngine, CNF, SAT callbacks, decisions, preregistration, TheoryProxy and skolem definitions | [SAT and proxy](query.md#propengine-turns-formulas-into-a-boolean-search) |
| Theory rewriter/state/inference manager; output reentrancy | [Theory components](theory-development/interface.md#the-common-pieces-of-a-theory) |
| Type-/term-based routing and Boolean-term routing | [Ownership](theory-development/interface.md#which-theory-receives-a-literal) |
| Distributed/central equality engines and their manager | [Equality](theory-development/interface.md#equality-engines-and-their-notifications) |
| STANDARD/FULL/LAST_CALL; preCheck/preNotifyFact/notifyFact/postCheck | [Fact loop](theory-development/interface.md#the-fact-processing-skeleton) |
| Equality callbacks, care graphs, sharing and model construction | [Combination and models](theory-development/interface.md#combination-asks-the-equalities-that-matter) |
| Finite fields: polynomial encoding, GB conflicts, core extraction and root search | [Finite fields](theory-development/finite-fields.md) |
| Bags: reductions, count constraints, operation lemmas, care graph and models | [Bags and tables](theory-development/bags.md) |
| Sets: closure, cardinality, relations, singleton merging, disequality and models | [Sets and relations](theory-development/sets.md) |
| Arithmetic: variable elimination, extended operators and unfinished check/model outline | [Arithmetic](theory-development/arithmetic.md) |
| Bit-vectors: two bit-blasting backends, preprocessing, facts, equality and models | [Bit-vectors](theory-development/bit-vectors.md) |
| Datatypes: constructors/testers/selectors, cycles/splitting, SyGuS and skeletons | [Datatypes](theory-development/datatypes.md) |
| Floating point: totalization, registration, word blasting, real conversions and models | [Floating point](theory-development/floating-point.md) |
| Strings: registration, eager callbacks, strategy, typed care graphs and length-based models | [Strings and sequences](theory-development/strings.md) |
| Separation logic: spatial reduction, points-to merges, checking and models | [Separation logic](theory-development/separation-logic.md) |
| Arrays: preprocessing, reads/writes, weak equivalence, extensionality and models | [Arrays](theory-development/arrays.md) |
| UF: higher-order terms, cardinality, arithmetic/BV conversions and care graph | [UF](theory-development/uf.md) |
| Quantifiers: macros, modules, nested efforts, completeness and model truth values | [Quantifiers](theory-development/quantifiers.md) |

The theory chapters form the [How to develop a theory](theory-development/README.md)
category. Each instantiates its six development stages and addresses the
bootcamp's callback topics within those stages. Where a stage is inherited
or delegated, the sub-guide names the implementation path instead of filling
the slot with “not implemented.”

## Material corrections

| Old note or implication | Current account and evidence chapter |
| --- | --- |
| NodeManager is a singleton; Solver is the main term-construction handle | Explicit TermManager ownership and multiple managers: [terms](terms.md) |
| Proposed `isValue`, `getValue`, `isSymbol`, `Type`, `node/`, replacement of TNode | These proposals are not the present names; `UNINTERPRETED_CONSTANT` did become `UNINTERPRETED_SORT_VALUE`: [terms](terms.md) |
| Boolean attribute `hasAttribute` behavior is a question | Boolean flags default false and count as present: [terms](terms.md) |
| RAII local rewrite attributes proposed | Core caches still use node attributes; no claim that the proposal landed: [terms](terms.md) |
| SkolemFunId and a single SkolemManager skolemization entry | SkolemId plus quantifier-specific skolemization machinery: [terms](terms.md) |
| BOOLEAN_TERM_VARIABLE identifies Boolean terms | PURIFY skolems registered in Env: [preprocessing](preprocessing.md) |
| Initialization-before-construction proposal | finishInit remains: [query](query.md) |
| Central policy means one shared equality engine without qualification | Arithmetic and arrays are excluded from that central use policy; auxiliary engines remain: [interface](theory-development/interface.md) |
| Higher-order UF extensionality on positive equality | Trigger is function disequality: [UF](theory-development/uf.md) |
| Arrays always follows weak equivalence and has two engines | Weak equivalence is optional/default off; preprocessing has another engine: [arrays](theory-development/arrays.md) |
| All arithmetic equalities become two inequalities | Option-dependent, default off; ordinary equality normalization also changed: [arithmetic](theory-development/arithmetic.md) |
| Equality preprocessing grouped into ppRewrite | Separate ppStaticRewrite in arithmetic, BV and strings: corresponding chapters |
| Field leaves/ring fully established at preregistration | Current GB encoder scans facts at solve time; split backend also exists: [finite fields](theory-development/finite-fields.md) |
| sets-ext; blanket rejection of relations plus cardinality | sets-exp; specific incompleteness handling and an explicit strategy: [sets](theory-development/sets.md) |
| Bag higher-order separation proposed; cardinality/filler model sketch | Distinct quantified strategy stage, cardinality reduction and current count-based model collector: [bags](theory-development/bags.md) |
| Every FP expansion creates a fresh UF | Some are syntax reductions; totalization is operation-specific: [floating point](theory-development/floating-point.md) |
| Separation checks at FULL and has no model work | Last-call refinement plus explicit heap-model postprocessing: [separation logic](theory-development/separation-logic.md) |
| Quantified formula's model Boolean value demonstrates satisfaction | Completeness is separately established by modules: [quantifiers](theory-development/quantifiers.md) |
| Datatype constructor normalization all belongs in ppRewrite | Constructor equality/clash simplification also belongs in ordinary rewriting: [datatypes](theory-development/datatypes.md) |
| Nested set difference and old bag unsupported-operator lists describe current preprocessing | Follow the current rewriter, kind declarations and preregistration checks: [sets](theory-development/sets.md), [bags](theory-development/bags.md) |

Historical comparisons are collected here so the teaching chapters can explain
the implementation directly. The current behavior and its source evidence
remain in the linked chapters.

## Interfaces blog coverage

The [advanced topics](advanced.md) and the introductory
[observation exercise](observing.md) cover the diagnostic problems raised by
[Interfaces for Understanding cvc5](https://cvc5.github.io/blog/2024/04/15/interfaces-for-understanding-cvc5.html).
Commands follow the pinned source rather than assuming the blog's option
spellings or defaults still apply.

| Topic | Tutorial destination |
| --- | --- |
| Assertion cores; minimization, checking, names and benchmark output | [Unsat cores](advanced.md#unsat-cores) |
| Cores of theory lemmas and instantiations; inference identifiers and skolems | [Lemma and instantiation cores](advanced.md#lemma-and-instantiation-cores), [reading events](observing.md#read-the-event-before-the-formula) |
| Proof production, checking, granularity, formats, components and external checking | [Proofs and components](advanced.md#proofs-and-components) |
| Models, model checking and sufficient model cores | [Models and model cores](advanced.md#models-and-model-cores) |
| Timeouts, timeout cores, assumptions and per-check budgets | [Timeout cores](advanced.md#timeout-cores) |
| Difficulty attribution and its modes | [Difficulty](advanced.md#difficulty-is-an-attribution-heuristic) |
| Unknown explanations and finer incompleteness reasons | [Incompleteness and limits](advanced.md#incompleteness-and-limits) |
| Statistics, internal counters, timing and inference histograms | [Configuration and statistics](advanced.md#configuration-and-statistics) |
| Preprocessed assertions and substitutions | [Preprocessing exercise](preprocessing.md#worked-example-a-conditional-inside-a-function-application) |
| Learned literals, streaming and classification | [Learned literals](advanced.md#preprocessing-and-learned-literals) |
| Candidate interpretations after unknown | [Candidate models](advanced.md#candidate-models-after-unknown) |
| Triggers, missing triggers, quantifier names, substitutions and strategy activity | [Quantifier diagnostics](advanced.md#quantifier-triggers-and-instantiations) |
| Lemma streams and their source identifiers | [Following an inference](observing.md), then each theory's observation exercise |
| Synthesis candidates, grammars, enumerators and solution annotations | [Synthesis diagnostics](advanced.md#synthesis-diagnostics) |
| Logic-dependent automatic option configuration | [Configuration](advanced.md#configuration-and-statistics) |

The guide also connects developer traces (`-t im`, `-t theory-check` and
theory-specific tags) to these output interfaces. It documents their build
requirements, limited coverage and the conflict-polarity printing detail at
this source pin. The pinned spellings are `--timeout-core-timeout` and
`--proof-format-mode`; lemma-core extraction explicitly selects SAT-proof
core mode.

## Additions beyond the notes

The introductory reading pass adds basic explanations before implementation
details throughout the architecture and theory chapters. These cover what each
theory's objects mean, why its solving problem needs the described machinery,
and shared concepts such as terms, contexts, congruence, models and refinement.
The [rewriting and preprocessing introduction](preprocessing.md) distinguishes
term equivalence from preservation of satisfiability and explains when each
transformation is used. The guide index supplies an SMT-LIB reading primer;
the reference pages explain how to use their records.

The refactored reading route begins with a query and observation session.
Worked examples now precede the six theory-development reference sections.
These include [complete theory examples](theory-development/README.md#choose-a-concrete-starting-problem),
an [incremental query](query.md#a-small-query-to-trace), a
[term traversal comparison](terms.md#walk-one-application-at-both-interfaces),
an [ITE purification walkthrough](preprocessing.md#worked-example-a-conditional-inside-a-function-application),
and a [rewrite-to-regression exercise](development.md#worked-change-investigation-membership-in-a-singleton).
Each connects a semantic obligation with code to inspect and variations to
try. The [runtime evidence](source-baseline.md#validation-of-the-expanded-examples)
identifies the executable actually used and the finite-field limitation.

The draft adds the current SAT default and incremental exception, MPFR constant
evaluation, bit-vector abstraction/refinement, instantiation evaluation and
current CEGQI defaults, a synthesis route, source-generation boundaries,
proof-object plumbing, and a change/testing workflow. These additions are
documented as implementation at the baseline, not as claims about the exact
historical date each feature first appeared.

The bootcamp's remarks about possible external interest in smaller builds are
historical motivation. This draft makes no current claim about another
organization's plans. Its measurement-first build-performance discussion also
does not invent benchmark results that were absent from the notes.
