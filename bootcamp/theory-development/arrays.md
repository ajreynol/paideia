# Developing the array theory

[Bootcamp](../README.md) / [How to develop a theory](README.md)

Source baseline: [2026-09-18](../source-baseline.md). Begin with
[TheoryArrays][theory], its [class definition][header],
[array rewriting][rewriter] and [options][options].

## Representation and invariants

### Reads, writes and several equality relations

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

## Preprocessing and registration

### Preprocessing

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

### Registration establishes the local vocabulary

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

## Fact processing and checking

The base `preCheck` behavior is sufficient here.

`preNotifyFact` ensures appropriate non-preregistered equality operands exist
in the official engine. `notifyFact` handles asserted array disequality by
obtaining a cached extensionality index, constructing the two reads and
sending the guarded disequality consequence through the inference manager.
When the required read terms already exist, a local inference can accompany
the lemma. Non-array disequalities also feed model constraints.

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

## Equality and combination

New-class and merge notifications update array information, consequences and
the relationships used for stores. Disequality notification itself does not
implement a second extensionality algorithm; that work is in `notifyFact`.

`notifySharedTerm` records shared arrays and whether non-array shared terms
are present. `computeCareGraph` can first request an equality split between
compatible shared arrays. It then examines reads whose indices participate
in sharing, using candidate index values where available to reduce comparisons.
Unknown index values require a more conservative search. Equality status uses
the base implementation; an absent override is not an absent service.

## Model construction

`computeRelevantTerms` closes the model's needed reads over stores, including
the read at each store's own index and existing reads required by the
read-over-write rules. `collectModelValues` chooses an array representative,
selects a default value compatible with its may-equal group, creates a constant
array, and overlays stores for relevant reads. The resulting store chain is
registered as a model skeleton so other theories can resolve index and element
values.

## Developing and validating a change

Use the [shared development workflow](README.md#development-workflow)
with these entry points for this theory.

### Where to make a change

| Change | Start here |
| --- | --- |
| Read-over-write consequences | `preRegisterTermInternal`, store/read indices and the selected `postCheck` route |
| Array disequality | `notifyFact`, the cached extensionality witness and its guarded inference |
| Default values or missing model reads | `computeRelevantTerms`, the may-equal groups and `collectModelValues` |

### Worked example: a read at a different index

Save as `arrays.smt2`; run `build-dev/bin/cvc5 arrays.smt2`. The expected
result is `unsat`.

```smt2
(set-logic QF_AX)
(declare-sort I 0)
(declare-sort E 0)
(declare-const a (Array I E))
(declare-const i I)
(declare-const j I)
(declare-const v E)
(assert (distinct i j))
(assert (distinct (select (store a i v) j) (select a j)))
(check-sat)
```

The write changes only index `i`. Since `j` is different, both reads at `j`
must agree. In a lemma-based explanation, the relevant read-over-write
constraint has the shape:

```text
i = j  or  select(store(a,i,v),j) = select(a,j)
```

Both disjuncts contradict the input. Inspect [queueRowLemma][queue] and
[dischargeLemmas][discharge] for the search route. Array preprocessing can
already use `i != j` to remove the store; inspect `-o post-asserts` to see
whether this particular run needs a search lemma. A semantic example is not
by itself evidence that a particular lemma counter increased.

Remove `i != j` and the problem becomes satisfiable: take `i = j` and choose
`v` different from the old value of `a` there. This checks the guard on the
rule. A rewrite that discarded every store would incorrectly reject this
variant.

For a separate extensionality exercise, declare two arrays `a,b` and assert
only `a != b`. Read [notifyFact][extensionality] and identify the new index
`k` and the lemma `a = b or select(a,k) != select(b,k)`. Even though the
input contains no reads, the model must distinguish these two generated
reads. The upstream [arrays and bit-vectors example][example] shows a
larger problem with concrete index and element sorts.

### Further validation

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
[queue]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arrays/theory_arrays.cpp#L2043
[discharge]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arrays/theory_arrays.cpp#L2198
[extensionality]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arrays/theory_arrays.cpp#L1473
[example]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/examples/api/smtlib/bitvectors_and_arrays.smt2
