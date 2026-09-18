# Developing the floating-point theory

[Bootcamp](../README.md) / [How to develop a theory](README.md)

Source baseline: [2026-09-18](../source-baseline.md). Start in
[TheoryFp][theory], [FpExpandDefs][expand] and the
[floating-point implementation directory][directory].

## Representation and invariants

### Concrete evaluation and symbolic word blasting

The symbolic solver reduces floating-point constraints to bit-vector
constraints through word blasting. It must represent signs, exponents,
significands, rounding modes and special values consistently. This reduction
is more structured than treating each floating-point term as an arbitrary
bit-vector: NaN, signed zero and the semantics of each comparison must be
preserved.

Constant evaluation is a separate path. Current main defaults to **MPFR** for
floating-point constant folding, while SymFPU remains part of the symbolic
word-blasting implementation. `--no-mpfr` selects the alternative constant
backend at build time. Do not describe the MPFR change as replacement of the
symbolic theory solver. See [floatingpoint_literal_mpfr.cpp][mpfr] and
the pinned [NEWS][news].

## Preprocessing and registration

### Make underspecified cases explicit

`ppRewrite` calls the rewriter's definition expansion and expects several
surface kinds to be gone afterward. Some are syntactic reductions, such as
subtraction or reversed comparisons. Other operations need explicit choices
for cases their public semantics leave underspecified.

`min`/`max` and conversions to signed or unsigned bit-vectors use internal
totalized forms with auxiliary functions where necessary. Conversion to real
also has a totalized form with a value for the non-real cases. It would be
incorrect to say every FP definition expansion introduces a fresh UF:
ordinary comparison and arithmetic syntax can be reduced without one.
`ppAssert` otherwise inherits the base implementation.

### Register terms and abstractions

`preRegisterTerm` checks whether floating point is enabled and whether the
format is allowed without `fp-exp`. `registerTerm` adds equality triggers or
ordinary engine terms, then guards its additional work by user-context
registration state.

For `isNaN`, `isZero` and `isInfinite`, registration creates aliases exposing
the relationship to equalities with the corresponding values. NaN has one
canonical SMT value, while zero and infinity each have positive and negative
cases. These aliases help equality reasoning participate in what would
otherwise be known only through bit-vector encodings. SMT equality on FP
values and the IEEE-style `fp.eq` predicate differ, especially on NaN and
signed zero, so they must not share a rewrite indiscriminately.

Real/FP conversions create purified abstractions and initial constraints.
For example, converting a real cannot produce NaN, and a real zero has a
specified result; totalized conversion of a NaN or infinity to real must use
its designated fallback value. The abstraction map retains the original
operation for later refinement.

## Fact processing and checking

With the default `fp-lazy-wb=false`, ordinary registered terms are word-blasted
during registration. In lazy mode, `preNotifyFact` word-blasts a newly used
atom and relates its encoding to the original term. `notifySharedTerm` also
ensures an encoding exists when combination needs it.

`preNotifyFact` still determines whether a fact should follow the base
equality-engine route. Equalities are registered; some predicates whose kinds
are not congruence function kinds are consumed without that base assertion.
`preCheck` and `notifyFact` do not supply a separate FP decision procedure.

At `EFFORT_LAST_CALL`, `postCheck` examines active real-conversion abstractions
against the candidate model and calls `refineAbstraction`. New lemmas force
another search. If the procedure cannot establish a valid candidate and cannot
make the required progress, incompleteness must be reported. A recent change
in this area makes that explicit; a conversion abstraction is not permission
to accept an arbitrary real/FP pair.

## Equality and combination

The standard equality notification adapter supplies propagation and conflicts;
there is no elaborate FP-specific equivalence-class merge algorithm like
the datatype or string solvers. Equality status and care-graph behavior mostly
use the common protocol, while lazy word blasting at sharing is a material
FP-specific hook.

## Model construction

`collectModelValues` iterates relevant floating-point and rounding-mode leaves,
asks the word blaster for their reconstructed values, and asserts those values
to the global model. Debug checks ensure the encoded special-value flags and
components agree. Model caches are invalidated as checking proceeds.

## Developing and validating a change

Use the [shared development workflow](README.md#development-workflow)
with these entry points for this theory.

### Where to make a change

| Change | Start here |
| --- | --- |
| Constant evaluation or symbolic encoding | The constant-folding backend or word blaster, according to the triggering input |
| Underspecified cases and totalization | `FpExpandDefs` and the internal forms that registration expects |
| Real conversions or candidate models | Abstraction registration, last-call `refineAbstraction` and model collection |

### Validation

For a change, separate tests for fully constant evaluation from tests with
symbolic operands; the former may never reach word blasting. Include NaN,
both zeros, infinities and rounding-mode-sensitive examples as applicable.
For conversion changes, exercise last-call refinement and its inability-to-
finish path, not only an exactly representable rational.

[theory]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/fp/theory_fp.cpp
[expand]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/fp/fp_expand_defs.cpp
[directory]: https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/fp
[mpfr]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/util/floatingpoint_literal_mpfr.cpp
[news]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/NEWS.md
