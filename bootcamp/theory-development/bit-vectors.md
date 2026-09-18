# Developing the bit-vector theory

[Bootcamp](../README.md) / [How to develop a theory](README.md)

Source baseline: [2026-09-18](../source-baseline.md). Read
[TheoryBV][theory] with the backend it constructs:
[BVSolverBitblast][external] or [BVSolverBitblastInternal][internal].

## Representation and invariants

### The backend boundary

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

[BV-EAGER-LAZY-2014](../references.md#bv-eager-lazy-2014) explains the
translation tradeoffs in the historical CVC4 backends. Compare those choices
with the current classes above, keeping translation timing separate from
internal/external SAT routing.

## Preprocessing and registration

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

## Fact processing and checking

### How a fact reaches the bits

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

### Abstraction before bit blasting

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

The current [AbstractionModule header](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bv/abstract/abstraction_module.h)
explicitly cites [BV-ABSTRACTION-2024](../references.md#bv-abstraction-2024),
originally evaluated in Bitwuzla. Compare the paper's abstract operators and
refinement lemmas with this integration. The four-bit increment example below
does not exercise expensive multiplication or division; use a suitable wider
operator when investigating this module.

## Equality and combination

The theory delegates shared-term notifications and backend-specific equality
status. If the backend cannot establish a status, `TheoryBV` compares
candidate values and returns a model equality/disequality status when values
are available. Specialized eager equality-class callbacks are not the primary
reasoning algorithm; shared congruence still matters in mixed-theory problems.
The common care-graph behavior applies unless the active backend supplies
additional behavior through its own interface.

## Model construction

Model values come from bit assignments and are reconstructed as values of the
correct width. The separate backend's relevant-term handling includes the
eager encoding's needs, and eager model collection can also recover Boolean
symbols absorbed into that encoding. `TheoryBV` maintains value-cache
invalidation around search changes; a stale value can corrupt combination
even when the clauses are correct.

## Developing and validating a change

Use the [shared development workflow](README.md#development-workflow)
with these entry points for this theory.

### Where to make a change

| Change | Start here |
| --- | --- |
| An operator or equality transformation | The rewriter, static preprocessing and the selected bit-blast translation |
| Fact assertion, assumptions or conflicts | The active backend, especially the lifetime of permanent facts versus assumptions |
| Abstraction or model values | The separate backend's refinement path and value-cache invalidation |

### Worked example: overflow makes an inequality true

Save as `bit-vectors.smt2`; run `build-dev/bin/cvc5 bit-vectors.smt2`.
The expected result is `sat`, with `x = #b1111` (the printer may use hex).

```smt2
(set-logic QF_BV)
(set-option :produce-models true)
(declare-const x (_ BitVec 4))
(assert (bvult (bvadd x #b0001) x))
(check-sat)
(get-value (x (bvadd x #b0001)))
```

The addition is modulo 16. For unsigned values 0 through 14, adding one
increases the value; for 15 it produces 0. A conceptual adder uses carry
`c0 = 1`, bits `si = xi xor ci`, and `c(i+1) = xi and ci`. The final carry
is discarded. The unsigned comparison then relates the four result bits
to the four input bits. The implementation may rewrite this pattern before
building a circuit; inspect `ppRewrite`'s `UltAddOne` path as well as the
[bit-blasting strategies][circuits].

To investigate backend routing, run the same file with `--bv-solver=bitblast`
and with `--bv-solver=bitblast-internal`. In the first route, follow the
[separate backend][external] from the theory atom to its bit-level assumption;
in the second, inspect the [internal backend][internal] lemma connecting the
atom with its encoding. Compare satisfiability and returned values before
comparing traces: the two routes need not send identical lemmas.

Replace `bvult` with `bvslt`. Now the satisfying value is `#b0111`: signed
7 wraps to signed -8. This is a useful check that a change preserves both
width and signedness. For an incremental exercise, temporarily assert
`x != #b1111` in the original unsigned problem: it becomes `unsat` and must
be `sat` again after a pop. See the upstream [bit-vector example][example]
for more construction and query syntax.

### Relate the example to the papers

[INT-BLASTING-2022](../references.md#int-blasting-2022) connects the example
to `IntBlaster`: identify the range and modulo-16 constraints preserving the
overflow case. For symbolic-width work, [BV-PARAMETRIC-2025](../references.md#bv-parametric-2025)
has a narrower connection to this snapshot: the integer backend's `PIAndSolver`
and `Pow2Solver`. Those files implement lazy reasoning about parametric integer
AND and powers of two; they do not establish a parametric-bit-vector front end
in `main`. Changing the concrete width of this input exercises neither claim.

For quantified bit-vectors, read [BV-INVERT-2018](../references.md#bv-invert-2018)
and [BV-INVERT-2021](../references.md#bv-invert-2021) with
[BvInstantiator](https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/cegqi/ceg_bv_instantiator.h).
Its comments connect variable solving to the paper's invertibility conditions.
Trace the condition needed to construct an instantiation term; ground overflow
tests do not exercise that construction.

### Further validation

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
[circuits]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/bv/bitblast/bitblast_strategies_template.h
[example]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/examples/api/smtlib/bitvectors.smt2
