# Arrays

Source baseline: [2026-09-18](source-baseline.md). Begin with
[TheoryArrays][theory], its [class definition][header],
[array rewriting][rewriter] and [options][options].

## Reads, writes and several equality relations

The essential constraints are read-over-write and extensionality:

```text
select(store(a, i, v), i) = v
i != j  =>  select(store(a, i, v), j) = select(a, j)
a != b  =>  select(a, k) != select(b, k)  for an extensionality witness k
```

Array terms are connected to other theories through index and element sorts.
The solver must distinguish equality of arrays, possible compatibility for
model construction and syntactic store-chain relationships.

The official equality engine handles asserted equalities and congruence.
`d_mayEqualEqualityEngine` groups arrays used by the array algorithm and default
value construction. There is also `d_ppEqualityEngine` for preprocessing.
Thus the bootcamp's “two equality engines” describes only part of the current
class. A may-equal relation is not a reason to assert actual array equality.

## Preprocessing

`ppRewrite` first handles restrictions and definition expansion, including
`EQ_RANGE`. Range equality expands to a formula quantifying over indices in
the indicated range. Constant arrays and range equality are guarded by the
experimental-array option at this layer.

When array preprocessing is enabled, its private equality information can
justify removing a store under a read at a known distinct index, reordering
stores at known distinct indices, and solving suitable write equalities.
These steps have stronger contextual assumptions than ordinary syntactic
rewrites. `ppAssert` records equality/disequality facts in the preprocessing
engine and also attempts legal variable substitution.

## Registration establishes the local vocabulary

`preRegisterTerm` delegates to `preRegisterTermInternal` and adds predicate
triggers for Boolean-valued reads. The internal method registers array terms
with the may-equal engine and other terms with the official engine, records
read indices and stores, and checks which read-over-write consequences are
already applicable.

Registering `store(a,i,v)` introduces the read at its own index and derives
`select(store(a,i,v),i) = v`. It also records both “stores represented by this
class” and “stores whose base is this class”, needed when merges expose new
interactions. Constant arrays retain their default value. This implementation
rejects arrays indexed by arrays and checks restrictions on constant-array
defaults; do not assume every type accepted by term construction is supported
by the solving path.

Preregistration and new-class notification cooperate closely. Adding a term
can trigger equality-engine callbacks immediately. Read the registration guard
and callback definitions in the header before moving an insertion across an
inference: duplicate or half-finished registration can break the indices.

## Checking and equality callbacks

`preNotifyFact` ensures appropriate non-preregistered equality operands exist
in the official engine. `notifyFact` handles asserted array disequality by
obtaining a cached extensionality index, constructing the two reads and
sending the guarded disequality consequence through the inference manager.
When the required read terms already exist, a local inference can accompany
the lemma. Non-array disequalities also feed model constraints.

New-class and merge notifications update array information, consequences and
the relationships used for stores. Disequality notification itself does not
implement a second extensionality algorithm; that work is in `notifyFact`.
The base `preCheck` behavior is sufficient here.

`postCheck` has two distinct algorithmic routes. The ordinary route discharges
queued read-over-write lemmas at full effort when eager lemma output is off.
With `arraysWeakEquivalence`, it replays array merges into a weak-equivalence
structure, groups reads by may-equal array representative and index
representative, and finds reads connected without a relevant intervening
write. It explains those paths to produce lemmas.

The weak-equivalence option is **false by default** in this snapshot. Its
trigger also depends on full effort or eager lemma settings. The bootcamp's
unqualified weak-equivalence description should not be used as the default
execution trace. A change in one route needs tests explicitly selecting it.

## Combination and models

`notifySharedTerm` records shared arrays and whether non-array shared terms
are present. `computeCareGraph` can first request an equality split between
compatible shared arrays. It then examines reads whose indices participate
in sharing, using candidate index values where available to reduce comparisons.
Unknown index values require a more conservative search. Equality status uses
the base implementation; an absent override is not an absent service.

`computeRelevantTerms` closes the model's needed reads over stores, including
the read at each store's own index and existing reads required by the
read-over-write rules. `collectModelValues` chooses an array representative,
selects a default value compatible with its may-equal group, creates a constant
array, and overlays stores for relevant reads. The resulting store chain is
registered as a model skeleton so other theories can resolve index and element
values.

A minimal regression for read-over-write is a write at `i`, a read at `j`,
and a separate constraint making `i` and `j` equal or distinct. A model
regression should also contain array disequality with no explicit input read:
the extensionality witness must still get a distinguishing value. Check both
read values and default-value choices when debugging an apparently correct
set of observed reads but an invalid array model.

[theory]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arrays/theory_arrays.cpp
[header]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arrays/theory_arrays.h
[rewriter]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arrays/theory_arrays_rewriter.cpp
[options]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/arrays_options.toml
