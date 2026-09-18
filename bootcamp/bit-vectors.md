# Bit-vectors

Source baseline: [2026-09-18](source-baseline.md). Read
[TheoryBV][theory] with the backend it constructs:
[BVSolverBitblast][external] or [BVSolverBitblastInternal][internal].

## The backend boundary

Bit-vector operations have fixed-width, modular semantics. Bit blasting
translates a term into Boolean expressions for its bits and an atom into a
Boolean condition over those bits. Arithmetic identities valid over integers
need not hold at a fixed width: wraparound, signedness and division edge cases
are part of the operation's definition.

`TheoryBV` owns shared state, rewriting, inference and model integration, but
delegates many callbacks through `d_internal`. The `bitblast` backend uses a
separate SAT solver for bit-level constraints. The `bitblast-internal` backend
sends bit-blasting lemmas to the main solver. These choices are separate from
eager versus lazy bit blasting and from the main CDCL(T) SAT backend.
Read [bv_options.toml][options] together with effective defaults before
describing a run.

## Preprocessing and preregistration

`ppAssert` first tries base variable elimination and then specialized
bit-vector substitution, including supported extract-equals-value cases.
For an equality fixing only bits `i..j`, the remaining bits must remain free;
the substitution cannot replace the entire vector with the narrow value.

`ppRewrite` includes `UltAddOne`, overflow-predicate elimination where
appropriate, and backend preprocessing. Several equality rewrites from the
bootcamp now live in `ppStaticRewrite`: solving equalities, optional bitwise
equality transformations, and sign-/zero-extension equalities against constants.
The runtime rewriter, static preprocessing and backend translation therefore
need separate tests if an operator's normalized representation changes.

`preRegisterTerm` forwards to the backend and, if an official equality engine
is in use, registers equalities as triggers and other terms normally. The
separate bit-blast backend requires that engine for sharing or when explicitly
requested. It is not safe to assume every BV configuration has the same
equality-engine setup.

## How a fact reaches the bits

For the separate backend, `preNotifyFact` queues facts. With input assertion
optimization enabled, fixed facts can be asserted permanently at the
appropriate user level; other facts become SAT assumptions. Keeping these
categories distinct permits reuse of translated clauses while retracting
branch choices. Resetting assertions has a corresponding backend-reset path.

`postCheck` translates queued atoms, records maps between theory facts and
bit-level SAT literals, then calls the bit-level solver with assumptions.
At non-full effort it only attempts propagation when supported. An unsat
assumption core maps back to a conjunction of theory facts; a conflict from
permanent assertions has a different explanation source. The inference
manager returns that conflict to the main search.

For the internal backend, `preNotifyFact` sends the relevant bit-blasting
lemma, relating the original atom to its bit-level encoding. The main SAT
solver searches the combined clauses. The return value controlling base
equality processing depends on the eager mode; it is not always “consume every
fact and skip the equality engine.” Most of the work consequently occurs at
lemma introduction rather than a separate `postCheck` SAT call.

## Abstraction before bit blasting

The current separate backend has an [abstraction module][abstraction] for
expensive multiplication, unsigned division and remainder. With
`--bv-abstraction`, selected arithmetic subterms become fresh abstract values
before their circuits are built. A satisfying abstract assignment is checked
at full effort; inconsistent values cause refinement, with fallback to exact
bit blasting after the configured budget. An abstract `sat` result is not a
finished bit-vector model.

The minimum width and value-refinement budget have dedicated options. This
feature is not supported by `bitblast-internal` at this baseline. It is a
substantial addition to the bootcamp's two-backend account, but it does not
change bit-vector semantics or justify using approximate results.

## Equality, sharing and models

The theory delegates shared-term notifications and backend-specific equality
status. If the backend cannot establish a status, `TheoryBV` compares
candidate values and returns a model equality/disequality status when values
are available. Specialized eager equality-class callbacks are not the primary
reasoning algorithm; shared congruence still matters in mixed-theory problems.
The common care-graph behavior applies unless the active backend supplies
additional behavior through its own interface.

Model values come from bit assignments and are reconstructed as values of the
correct width. The separate backend's relevant-term handling includes the
eager encoding's needs, and eager model collection can also recover Boolean
symbols absorbed into that encoding. `TheoryBV` maintains value-cache
invalidation around search changes; a stale value can corrupt combination
even when the clauses are correct.

For a change, cover width one, a larger width, signed/unsigned boundaries and
the operator's zero/overflow cases. A backend change should exercise its own
mode explicitly. An incremental test should make an assumption satisfiable
after a pop or reset, catching accidental permanent assertion of a branch
fact.

[theory]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bv/theory_bv.cpp
[external]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bv/bv_solver_bitblast.cpp
[internal]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bv/bv_solver_bitblast_internal.cpp
[options]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/bv_options.toml
[abstraction]: https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bv
