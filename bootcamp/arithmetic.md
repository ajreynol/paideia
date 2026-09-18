# Arithmetic

Source baseline: [2026-09-18](source-baseline.md). Start with
[TheoryArith][theory], then follow its delegation into
[TheoryArithPrivate][linear], [EqualitySolver][equality] and
[NonlinearExtension][nonlinear]. The bootcamp left most of the checking and
model callbacks blank; this chapter supplies that missing route.

## The wrapper and the linear core

`TheoryArith` is the theory-engine-facing coordinator. It owns arithmetic
state and inference management, preprocessing/operator elimination, the
linear solver and, for a nonlinear logic, the nonlinear extension. Reading
only the wrapper can make a substantial algorithm look like an empty hook.

The linear core maps terms and atoms into arithmetic variables, normalized
polynomials and `Constraint` objects. A tableau records linear equations;
the partial model maintains candidate assignments and bounds. Bounds have
reasons, so a contradiction can be explained to SAT rather than merely
reported as “the current numbers do not work.” Strict real bounds use the
linear solver's infinitesimal/delta representation instead of rounding a
rational approximation.

Solving the real relaxation is only part of integer reasoning. A rational
assignment satisfying every linear constraint can assign `1/2` to an integer
variable. Integer checking, cuts, Diophantine reasoning and branching address
that gap. The relevant code is in `src/theory/arith/linear/`; nonlinear
procedures live under `src/theory/arith/nl/`.

## Preprocessing and registration

`ppAssert` delegates to the linear core. It normalizes a candidate equality
for analysis, tries to solve for a variable with legal type and occurrence
conditions, and limits substitution size with `ppAssertMaxSubSize` (declared
default 2). It also supplies bound information to static learning.

`ppRewrite` calls arithmetic preprocessing/operator elimination. See
[OperatorElim][elim] for integer tests and conversions, division and modulus,
absolute value, square root and inverse trigonometric operations. Different
operators need different treatments: `abs` can use an ITE; integer conversion
needs an integer witness and bounds; division needs a denominator-zero case;
inverse transcendental functions need range information as well as an
equation. The ordinary rewriter also eliminates syntactic trigonometric
variants. These cases are not one universal “replace by a skolem” rule.

Equality-to-two-inequalities preprocessing is controlled by
`arith-rewrite-equalities`, whose declared default is false. Current ordinary
arithmetic rewriting also preserves the rewritten operands of equality,
possibly swapping them or deciding `true`/`false`; it no longer always replaces
the whole equality with a normalized polynomial equation. The linear solver
can still normalize internally. This separation matters to theory combination.

`preRegisterTerm` checks nonlinear and transcendental requirements, forwards
nonlinear terms to the extension, and sends all relevant input to the linear
core. There, bound atoms become internal constraints and polynomial terms get
their arithmetic representation. A declared linear logic with surviving
nonlinear multiplication is rejected. Operator-specific and experimental
options can impose additional restrictions.

## Fact processing and effort

`preCheck` tells the linear core whether new facts are pending and prepares its
status/propagation state. `preNotifyFact` always forwards the fact to the
linear core. Its Boolean return also determines whether the base class should
assert the fact into the official equality engine. With the optional
arithmetic equality solver, the decision is delegated to `EqualitySolver`;
otherwise the wrapper takes responsibility for handling the fact itself.
Do not assume every arithmetic inequality is asserted as a generic predicate
to congruence closure.

The linear core's `postCheck` processes learned bounds and existing conflicts,
repairs the real relaxation using simplex, performs applicable integer work,
and sends conflicts, propagations or splits. At full effort it also handles
disequality splitting and remaining nonintegral assignments. Work is staged
so an already-sent conflict or split can hand control back to SAT.

The wrapper then handles nonlinear work at **full effort**. It builds a
candidate arithmetic model cache and calls `NonlinearExtension::checkFullEffort`.
This is a correction to a common older mental model: this wrapper's
`postCheck` explicitly excludes `EFFORT_LAST_CALL`; nonlinear refinement here
is integrated into full effort.

There is still work at the last-call boundary: `needsCheckLastEffort` flushes
buffered nonlinear facts, lemmas and phase requirements before returning
false. It is therefore not a side-effect-free capability query. Inspect this
hook when a full-effort refinement seems to appear later than its creation.

The nonlinear extension compares candidate values against nonlinear semantics.
An abstraction may assign an independent value to a product term, so satisfying
the linear constraints does not ensure that the value equals the product of
its factors. Refinement adds constraints ruling out inconsistent candidates.
The implementation includes strategies for incremental linearization,
transcendentals and coverings, selected by options and supported dependencies.
Some combinations remain incomplete and must signal that fact instead of
letting the linear relaxation justify `sat`.

## Equality and combination

Arithmetic connects its equality solver to the linear congruence manager.
This is where equality-engine notifications and arithmetic propagations
are coordinated; an inventory of `eqNotify*` methods on `TheoryArith` alone
misses the implementation. `notifySharedTerm` strips an outer `TO_REAL` where
appropriate and registers the underlying shared term with the linear core.

`getEqualityStatus` can use the candidate arithmetic model or fall back to
the linear core. Equal candidate values yield a model status, not necessarily
an entailed equality. The model must retain consistency with shared terms
while the nonlinear extension repairs values. The inherited care-graph route
is not a replacement for this arithmetic-specific equality/model integration.

## Model construction and debugging

At full effort, the wrapper checks integer-model consistency and finalizes
its arithmetic model cache. `collectModelInfo` declines construction if a
pending lemma must be processed first. `collectModelValues` adds values for
relevant arithmetic leaves, checking exact type agreement. If a nonlinear
model assignment cannot be reconciled with the global model, the code can
request a split and resume search rather than silently overwrite the other
theory's value.

To debug a bound conflict, trace the atom's conversion to `Constraint`, its
assertion case and the reason for the bound that contradicts it. To debug an
integer issue, inspect the real relaxation before integer repair. To debug a
nonlinear result, compare the abstract value of each nonlinear term with its
evaluation under the candidate leaf assignments. Test both a refutation and
a model case; a change can preserve conflict detection while breaking model
reconstruction.

Current options and their declared defaults are in [arith_options.toml][options].
The new `nl-ext-initial-sign-lemmas` option adds early monomial zero-sign
constraints when incremental linearization is active; it is disabled by
default. Such a strategy addition should be documented separately from the
core arithmetic representation.

[theory]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/theory_arith.cpp
[linear]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/linear/theory_arith_private.cpp
[equality]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/equality_solver.cpp
[nonlinear]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/nl/nonlinear_extension.cpp
[elim]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arith/operator_elim.cpp
[options]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/arith_options.toml
