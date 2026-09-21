# Unreferenced papers

[Bootcamp](README.md) / Unreferenced papers

A paper can describe a modified solver used for an experiment while the
ordinary cvc5 checkout contains a different implementation. **Upstream** means
the main cvc5 project; a research **fork** is a separately maintained version.
This appendix helps explain why a feature encountered in a paper may not be
available in the source used by the tutorial. Consult it when following a
paper-to-code connection; it is background for that comparison, and the
theory chapters can be read independently.

This review list records papers describing CVC4/cvc5 implementation features
that are **not present in the pinned `main` implementation and therefore are
not taught as available features in this guide**. It accompanies the footnote
on the [overall architecture guide](overall-architecture.md). The comparison
is against
[`3dcc1ef5421ab62cc1ee9af52d70042ce6861af0`](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0),
observed on **2026-09-18**, not every historical release or research fork.
See the [source baseline and verification limits](source-baseline.md).

“Unreferenced” means omitted from the tutorials' implementation bibliography;
the papers are cited here so their claims can be reviewed. This is a focused
list of identified gaps, not a list of every excluded publication. Ordinary
applications and external clients are omitted unless the paper also claims
a solver modification missing from this snapshot.

An absent feature can indicate a research implementation, an unmerged change,
or a removed feature. It does **not** by itself show that the paper is wrong.
Calling a feature *deprecated* requires an upstream deprecation record;
calling it *removed* requires evidence that it was once upstream. Calling a claim *incorrect* requires a
contradiction with the version the paper actually describes. Neither finding
has been established for the entries below. The source comparisons establish
the narrower conclusion: these features should not be attributed to this
`main` snapshot.

## Learned quantifier selection

Jan Jakubův, Mikoláš Janota, Jelle Piepenbrock and Josef Urban,
*Machine Learning for Quantifier Selection in cvc5*:
[ECAI 2024](https://journals.sagepub.com/doi/abs/10.3233/FAIA241009) and
the [extended IJAR 2026 article](https://doi.org/10.1016/j.ijar.2025.109602).
The [author manuscript, Section 3](https://arxiv.org/html/2408.14338v1#S3)
describes LightGBM models that select quantified formulas during solving,
including model loading, feature extraction and prediction inside
instantiation modules.

**Missing feature:** this trained selection layer. The pinned
[module initialization](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/quantifiers_modules.cpp),
[enumerative check loop](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/inst_strategy_enumerative.cpp)
and [quantifier options](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/quantifiers_options.toml)
contain the usual strategy scheduling and eligibility checks, but no model
loading or LightGBM prediction path. The source and dependency definitions
contain no LightGBM integration. Decision-tree learning for SyGuS classification
is a different feature.

**Documentation gap and assessment:** the [quantifier tutorial](theory-development/quantifiers.md)
describes the implemented strategies without learned filtering. The papers
report an experimental solver extension; the current-source check establishes
its absence here, not a false experimental result or a removal history.

## Neural selection of quantifiers and instances

Jelle Piepenbrock, Mikolas Janota, Josef Urban and Jan Jakubův,
[*First Experiments with Neural cvc5*](https://easychair.org/publications/paper/Z6b2),
LPAR 2024. The paper adds a graph neural network to guide enumerative
instantiation. Its [research repository](https://github.com/JellePiepenbrock/mlcvc5-LPAR)
explicitly identifies the modified solver and includes model weights.

**Missing feature:** neural scoring of available quantified formulas and
instantiation choices. The pinned
[InstStrategyEnum](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/inst_strategy_enumerative.cpp)
uses relevant-domain and ground-term enumeration; the corresponding
[term-tuple enumerator](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/term_tuple_enumerator.cpp)
and options do not provide the paper's neural scoring/model-loading path.

**Documentation gap and assessment:** the [quantifier tutorial](theory-development/quantifiers.md)
does not describe neural guidance. A separate implementation is documented by
the authors, so this is evidence of a research-fork feature, not evidence that
the claimed prototype never existed.

## Specialized multimodular integer reasoning

Elizaveta Pertseva, Alex Ozdemir, Shankara Pailoor, Alp Bassa,
Sorawee Porncharoenwase, Işil Dillig and Clark Barrett,
[*Integer Reasoning Modulo Different Constants in SMT*](https://doi.org/10.1007/978-3-031-98668-0_17),
CAV 2025. Section 6 describes an alternative nonlinear integer solver using
Singular and GLPK, with constraints partitioned by modulus and lemmas lifted
and lowered between subsystems. The
[paper artifact](https://zenodo.org/records/15220343) records its experimental setup.

**Missing feature:** that specialized multimodular procedure. The pinned
[NonlinearExtension](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/nl/nonlinear_extension.cpp)
initializes the existing refinement, coverings, interval and integer-bitwise
subsolvers, without the described modulus-partitioned solver. There is no
Singular integration in the source/build definitions. The
[finite-field backend](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/ff/sub_theory.cpp)
uses CoCoA and does not supply the paper's cross-modulus lifting/lowering.

**Documentation gap and assessment:** the [arithmetic tutorial](theory-development/arithmetic.md)
covers the available nonlinear routes. Ordinary integer `mod` support and
finite-field reasoning do not implement this specialized algorithm. The
paper's experimental implementation is separate from the checked `main`;
whether it was ever upstream has not been established.

## Greedy congruence explanations retaining redundant equalities

Bruno Andreotti and Haniel Barbosa,
[*Producing Shorter Congruence Closure Proofs in a State-of-the-Art SMT Solver*](https://hanielbarbosa.com/papers/2026vmcai.pdf),
VMCAI 2026. Section 4 describes changing cvc5's equality engine to retain
redundant equalities and use a Greedy explanation algorithm, with constraints
on eligible explanation edges. The authors provide an
[experimental artifact](https://zenodo.org/records/17181344).

**Missing feature:** the described redundant-edge/Greedy explanation engine.
In the pinned [EqualityEngine](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/uf/equality_engine.cpp),
`assertEquality` returns immediately for terms already equal, and `propagate`
skips a merge candidate whose representatives coincide before adding a graph
edge. Those behaviors conflict with the feature's defining requirement to
retain redundant equality edges for later explanation choices. They do not
mean that cvc5 lacks congruence proofs generally.

**Documentation gap and assessment:** the [UF tutorial](theory-development/uf.md)
describes current congruence and explanation behavior without this optimization.
The paper distinguishes its modified engine from the baseline. The observed
gap supports excluding the optimization from the current guide; it does not
invalidate the artifact's results or establish deprecation.

## Alethe proof skeletons with external propositional checking

Joseph E. Reeves, Haniel Barbosa, Andrew Reynolds and Marijn Heule,
[*A General Approach for SMT Proof Skeletons*](https://hanielbarbosa.com/papers/2026ijcar-skeletons.pdf),
IJCAR 2026. Section 3 describes instrumenting cvc5 to emit an Alethe skeleton
with theory-lemma holes and a `prop_unsat` step, leaving propositional checking
and selected lemma justification to an external pipeline. The
[research repository](https://github.com/jreeves3/SMT-Skeleton-Check) provides
the solver and checking workflow.

**Missing feature:** this skeleton-emission protocol and its `prop_unsat`
handoff. The pinned [Alethe printer](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/proof/alethe/alethe_printer.cpp),
[postprocessor](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/proof/alethe/alethe_post_processor.cpp)
and [proof options](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/proof_options.toml)
do not implement that step or the described skeleton output path. Existing
proof granularity, trusted steps and lazy reconstruction do not establish this
specific external protocol.

**Documentation gap and assessment:** the [proof workflow](development.md#proof-objects-are-part-of-the-implementation)
explains the current producer/printer interfaces. The paper's instrumented
solver and external pipeline remain distinct from them. The separate artifact
supports a prototype interpretation; the audit does not establish removal
from upstream.

## Partial case: finite-field proof production

Pedro Saccomani, Abdalrhman Mohamed, Elizaveta Pertseva, Daniela Kaufmann,
Cesare Tinelli, Clark Barrett and Haniel Barbosa,
[*Proof Production for Satisfiability Modulo Finite Fields with Proof Checking in Pacheck and Lean*](https://repositum.tuwien.at/handle/20.500.12708/230471),
FMCAD 2026. This paper describes instrumented finite-field proof production
and external checking. It is **not wholly absent from the code** and therefore
does not belong among the unreferenced entries above.

The pinned [ProofRule declarations](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/include/cvc5/cvc5_proof_rule.h)
already include `FF_POLY_COMBINATION`, `FF_ROOT_BRANCH`, `FF_EXHAUST_BRANCH`
and `FF_ONE_UNSAT`, among other finite-field rules. However,
[TheoryFiniteFields::getProofChecker](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/ff/theory_ff.cpp)
returns `nullptr`, and `postCheck` reports its subtheory conflict through
`d_im.conflict(conflict, InferenceId::FF_LEMMA)` without a proof generator.
Uses of those rules in the implementation search are their API string
representations, not the producer/checker pipeline described in the paper.

**Assessment:** rule declarations are present, but the examined field-solving
path does not supply the paper's end-to-end proof production. The
[bibliography entry](references.md#finite-field-proofs-2026) and
[field tutorial](theory-development/finite-fields.md) now document this limited
connection. A rule name alone is insufficient evidence that the feature is
usable. No runtime or external-checker validation was performed for this claim.

## Reviewing and updating an entry

The check combined paper implementation sections, available author artifacts,
source inspection and searches through `src/`, `include/`, `cmake/`, `proofs/`,
options and tests as applicable. A missing keyword alone is not the finding:
the entries name the expected integration point and the behavior inspected.
These are source observations, not reproductions of the papers' experiments.

To reclassify an entry, identify an upstream implementation or removal commit,
its public option/API and an example that reaches the claimed algorithm.
If the code is present and the guide merely omitted it, update the tutorial
and move the paper into the implementation bibliography. If history proves a
removal, record the last supported revision and the reason separately. Reserve
an incorrect-claim finding for evidence about the paper's actual version and
claim, rather than a mismatch with a later snapshot.
