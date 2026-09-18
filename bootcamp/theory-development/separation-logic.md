# Developing separation logic

[Bootcamp](../README.md) / [How to develop a theory](README.md)

**Separation logic** describes the contents and ownership of parts of memory.
A **heap** maps allocated locations to stored values. A points-to assertion
`x |-> 7` describes a heap containing exactly one cell, at location `x`,
with value `7`. The assertion `emp` describes an empty heap. These are
**spatial** assertions because their meaning includes which locations belong
to the heap.

The **separating conjunction** `P * Q` says the heap can be split into two
disjoint parts satisfying `P` and `Q`. Thus `x |-> 7 * y |-> 7` requires
different locations for `x` and `y`, even though their stored values agree.
The **separating implication**, or magic wand, `P -* Q` says that adding any
disjoint heap satisfying `P` would make the combined heap satisfy `Q`.
cvc5 reasons about these spatial relationships using sets of locations and
checks of candidate heaps. This chapter explains how those sets retain their
connection to points-to data and the original spatial formulas.

Source baseline: [2026-09-18](../source-baseline.md). The central implementation
and callback adapter are [TheorySep][theory] and its [header][header].

## Representation and invariants

### Heap labels connect spatial assertions to sets

The solver handles spatial forms including empty heap (`SEP_EMP`),
points-to (`SEP_PTO`), separating conjunction (`SEP_STAR`) and separating
implication or wand (`SEP_WAND`). A separating conjunction requires disjoint
heap fragments whose union is the current heap. Ordinary Boolean conjunction
does not impose that disjointness.

Internally, labeled spatial assertions associate a formula with a set of
locations representing its heap domain. This allows set constraints to express
domain relationships while the location and data sorts use their own theories.
`HeapAssertInfo` stores positive and negative points-to information associated
with label equality classes. The solver has spatial semantics without owning
a separate SMT sort for heap values.

## Preprocessing and registration

The usual `ppRewrite`/`ppAssert` hooks are inherited. That does not mean
separation inputs bypass preprocessing: assertion notification and dedicated
preprocessing machinery also contribute, including the pass for skolemizing
empty-heap occurrences. Follow `ppNotifyAssertions` and the selected
preprocessing pass when a spatial expression changes before preregistration.

`preRegisterTerm` checks whether the separation feature is enabled and calls
`ensureHeapTypesFor` for spatial operations. Location and data types must agree
with the declared heap. An application with individually well-typed arguments
can still violate this solver-wide heap declaration.

## Fact processing and checking

### Reduce and record spatial facts

`preNotifyFact` separates a `SEP_LABEL` into its spatial formula and label,
reduces spatial facts and records labeled assertions for later checking.
Labeled points-to facts continue into the equality-engine route; many other
spatial facts are consumed after reduction and pending inference processing.
Thus the base `notifyFact` call does not occur for every spatial assertion.

`notifyFact` takes labeled points-to facts that did reach the engine, obtains
the label representative, checks compatibility with stored points-to facts
and appends to the appropriate positive/negative list. This is an eager
consistency path; expensive spatial refinement happens later.

### Last-call refinement

At this baseline, `postCheck` performs its substantive model-based work at
**`EFFORT_LAST_CALL`**, not the full-effort stage listed in the bootcamp.
`needsCheckLastEffort` participates in the theory-engine scheduling contract.

The procedure builds maps from candidate location values to representative
terms and points-to data, determines which labeled assertions are active,
and computes candidate heap-domain values. Guards matter for negative spatial
assertions; a subassertion that is inactive under the current Boolean choices
must not constrain a candidate as if it were asserted unconditionally.

It then instantiates relevant negative spatial obligations (with the wand's
polarity treated specially) against those candidate domains and sends
refinement lemmas. Previously sent refinements are cached. Finite data domains
can require additional points-to witnesses because there may be no fresh
unused data value to choose. If required work remains but no adequate new
lemma is produced, the solver marks the result incomplete.

The important loop is candidate heap, spatial check, refinement, renewed
Boolean/theory search. A model satisfying the set-domain equations alone is
not yet a separation-logic model.

## Equality and combination

[SEP-2016](../references.md#sep-2016) explains the heap-label and refinement
procedure above. Read heap decomposition beside the sets encoding: disjointness
constrains heap domains, and does not follow merely from using different names
for location terms.

The equality notification adapter has no specialized new-class or disequality
work. `eqNotifyMerge` is significant: it brings together points-to information
from two label classes, runs the compatibility checks and preserves the
combined lists. Facts that were separately consistent can conflict after their
heap labels are equated. The metadata must backtrack with those equalities.

Shared-term notification, equality status and care-graph methods are inherited.
They are not a hidden independent heap-combination algorithm. Sets and the
location/data theories handle the value-sort relationships generated by spatial
reduction. This resolves the bootcamp's question marks around these hooks.

## Model construction

The ordinary relevant-term/value hooks are inherited because the underlying
sorts belong elsewhere. There is nevertheless explicit heap model code:
`postProcessModel` constructs points-to entries for the base label's locations,
uses fixed data where available and chooses compatible values elsewhere.
It takes negative points-to restrictions into account, constructs an empty
heap or separating conjunction of entries, and records the heap and nil
interpretation with `TheoryModel::setHeapModel`.

The bootcamp's “no model work because separation logic owns no types” is
therefore too broad.

## Developing and validating a change

Use the [shared development workflow](README.md#development-workflow)
with these entry points for this theory.

### Where to make a change

| Change | Start here |
| --- | --- |
| Spatial reduction or labeled points-to facts | `preNotifyFact`, `notifyFact` and heap-label state |
| Consequences of label equality | `eqNotifyMerge` and backtracking of positive/negative points-to lists |
| Spatial refinement or returned heaps | Last-call checking and `postProcessModel` |

### Worked example: equal locations cannot be separated

Save as `separation-logic.smt2`; use a build with separation logic enabled
and run `build-dev/bin/cvc5 separation-logic.smt2`. The expected result is
`unsat`.

```smt2
(set-logic ALL)
(declare-heap (Int Int))
(declare-const x Int)
(declare-const y Int)
(assert (sep (pto x 7) (pto y 7)))
(assert (= x y))
(check-sat)
```

Each points-to assertion describes a singleton heap. Separating conjunction
requires their domains to be disjoint. Since `x = y`, both singleton domains
contain the same location; agreement on stored data does not remove the
overlap. Ordinary conjunction of these same points-to assertions can describe
one shared singleton heap and is satisfiable for a non-nil location.

To follow the encoding, look for the spatial reduction in
[TheorySep][theory]. Conceptually the two child labels have domains `{x}`
and `{y}`, their intersection is empty, and their union is the parent label.
Sets and arithmetic can expose the contradiction in those generated
constraints. The example need not reach negative-spatial last-call refinement;
that is a distinct procedure with distinct test needs. The upstream
[sep-01 regression][example] exercises this same disjointness obligation.

Replace `x = y` by `x != y`, enable model production and inspect the model:
it must describe two cells with data 7 at distinct non-nil locations. A
model with an appropriate set of addresses but no associated points-to data
is incomplete as a heap representation. Follow `postProcessModel` when
debugging that difference. For negative spatial assertions, continue with
the upstream [negative spatial simplification regression][negative-example]
and inspect which labeled obligations are active before interpreting a
candidate heap.

### Relate the example to the papers

The two points-to atoms each describe a singleton domain. The separating
conjunction requires those domains to be disjoint, while the asserted address
equality makes them overlap. Derive that conflict using the heap interpretation
in [SEP-2016](../references.md#sep-2016), then follow the labels and equalities
that explain it in `TheorySep`. As a contrast, ordinary Boolean conjunction
does not demand disjoint heaps; changing the connective changes the premise
of the argument.

### Further validation

For debugging, inspect both the candidate label sets
used at last call and the final heap object. Tests should include conflicting
points-to assertions after a label merge, disjointness violations, negative
spatial formulas and a satisfiable case whose returned heap must be built.

[theory]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sep/theory_sep.cpp
[header]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/sep/theory_sep.h
[example]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/test/regress/cli/regress0/sep/sep-01.smt2
[negative-example]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/test/regress/cli/regress0/sep/nspatial-simp.smt2
