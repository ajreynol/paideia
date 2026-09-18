# Developing the datatype theory

[Bootcamp](../README.md) / [How to develop a theory](README.md)

An **algebraic datatype** describes values built from named constructors.
A list of integers, for example, is either `nil` or `cons(h,t)`, where `h`
is an integer and `t` is another list. A **selector** reads a field, such as
`head(cons(7,nil)) = 7`; a **tester** asks which constructor a value uses,
such as whether a list is `nil`. These give the solver explicit structure
to reason about even when a variable's full value is unknown.

Constructors of different forms cannot produce the same value, and equal
applications of the same constructor have equal fields. An **inductive**
datatype contains finite constructor values, so `x = cons(0,x)` has no list
solution. **Codatatypes** allow potentially infinite structures, including
values represented by cycles, and need different reasoning. **Parametric**
datatypes take type parameters, as a list can contain integers or strings.
The implementation below keeps these structural rules consistent with the
equalities learned during search.

Source baseline: [2026-09-18](../source-baseline.md). The main implementation is
[TheoryDatatypes][theory], with [rewriting][rewriter],
[inference management][im] and a [SyGuS extension][sygus].

## Representation and invariants

### Constructor structure on equality classes

For a datatype such as `List = nil | cons(head,tail)`, equal constructors of
the same kind imply equal fields, different constructors cannot be equal,
and an inductive value cannot contain itself along a constructor cycle.
Testers record which constructor a term has, while selectors expose fields.
The solver stores constructor/tester/selector information with equality
classes so these consequences can be recognized as classes merge.

Selectors applied to the wrong constructor require the datatype's specified
total-function behavior; they cannot simply inherit the intended constructor's
field equations. Parametric datatypes also require instantiated constructor
and selector types. Much of the utility and rewriter code exists to preserve
these distinctions while sharing representations.

## Preprocessing and registration

`ppRewrite` expands definitions through the datatype rewriter. It also handles
`DT_SIZE` by purification with a nonnegative-size constraint. Ordinary
constructor equalities and constructor clashes belong to rewriting; the
bootcamp's placement of every such simplification in `ppRewrite` does not
match the current split. `ppAssert` inherits the base substitution behavior.

`preRegisterTerm` checks datatype support, including well-foundedness,
nested-recursion settings and codatatype restrictions. It registers equality
and tester triggers, installs initial lemmas for other terms and sends terms
to the equality engine. If synthesis support is active, the SyGuS extension
also receives registration. Initial lemmas are processed here, so registration
can have visible inference effects.

The relevant syntax is not limited to user-defined inductive datatypes:
tuples and synthesis grammars also use datatype infrastructure.
**Syntax-guided synthesis (SyGuS)** searches for an expression satisfying a
specification while using only the forms allowed by a grammar. Datatype
constructors can represent those permitted expression forms; the
[synthesis introduction](quantifiers.md#synthesis) gives an example. Before
changing a generic constructor rule, find its uses through the datatype
utilities and the SyGuS extension.

## Fact processing and checking

`preCheck` processes pending inferences and resets the manager for the new
round. The standard equality-engine path handles incoming facts.
`notifyFact` forwards to the SyGuS extension, recognizes testers and updates
the argument class's possible constructors. An asserted positive tester can
enable constructor-specific consequences. External facts cause pending
inferences to be processed after notification.

At full effort, `postCheck` repeatedly checks cycles, processes resulting
facts, and performs constructor splitting. Internal facts can make another
local pass necessary; a sent lemma hands control back toward SAT. If a lemma
is sent during splitting, pending local facts are handled according to the
manager's protocol rather than blindly carried into another round. At last
call, the active SyGuS extension has its own check.

**Constructor splitting** asks search to choose a possible constructor when
the current facts do not determine one: an unknown list must be either `nil`
or a `cons`. The choice can expose new field constraints or a constructor
clash. **Injectivity** names the reverse structural deduction: equality of
two `cons` values forces equality of their corresponding fields.

An inductive constraint `x = cons(a,x)` is the simplest cycle to understand,
but useful tests also contain cycles exposed only by equality merges. A
codatatype permits cyclic values, so the inductive cycle rule cannot be
applied indiscriminately to all datatype sorts.

The calculus is developed in [CODATATYPES-2015](../references.md#codatatypes-2015)
and the expanded [CODATATYPES-2017](../references.md#codatatypes-2017).
Read the constructor clash, injectivity and cycle rules beside the corresponding
class metadata. [SHARED-SELECTORS-2018](../references.md#shared-selectors-2018)
explains why internal selectors can be shared across constructors; this does
not make two unrelated surface selectors interchangeable.

## Equality and combination

`eqNotifyNewClass` creates class information for constructors and registers
selectors with the class of their argument. Constructor applications with
fields and relevant selector/height terms become function terms used by later
reasoning. `eqNotifyMerge` invokes the datatype merge logic: constructor
clashes cause conflict, matching constructors force field equalities, and
selector/tester information is combined. No specialized disequality callback
is needed to implement all of this behavior.

`computeCareGraph` considers compatible applications, accounting for parametric
constructors. It must distinguish instantiations, not just constructor names.
Shared-term notification inherits the base behavior. `getEqualityStatus`
returns the engine's known relation, or `EQUALITY_FALSE_IN_MODEL` when separate
classes may be interpreted differently.

[DATATYPE-POLITENESS-2020](../references.md#datatype-politeness-2020) and
[DATATYPE-POLITENESS-2022](../references.md#datatype-politeness-2022) supply
the combination perspective. A constructor skeleton can constrain both the
datatype domain and values from field theories, so locally consistent
constructor choices still need a compatible combined model.

## Model construction

`computeRelevantTerms` makes the recorded constructor consistent with model
relevance. If a relevant constructor already exists in the class, it can
become the recorded one; otherwise the recorded constructor and its fields
must be included. This prevents the model builder from seeing a relevant
datatype class without the structure that its solver already established.

`collectModelValues` gathers known constructors and chooses permitted
constructor shapes for remaining constrained classes. It asserts the needed
equalities and registers constructor skeletons. Fields can belong to other
theories, so model assembly is intentionally deferred across that boundary.
Codatatypes follow a separate construction path capable of representing
cyclic values.

## Developing and validating a change

Use the [shared development workflow](README.md#development-workflow)
with these entry points for this theory.

### Where to make a change

| Change | Start here |
| --- | --- |
| Constructor, tester or selector consequences | Class metadata, `notifyFact` and datatype merge logic |
| Cycles or constructor splitting | The full-effort `postCheck` loop and pending inference handling |
| Model structure or synthesis interaction | `computeRelevantTerms`, constructor skeletons and the SyGuS extension |

### Worked example: a cycle through two classes

Save as `datatypes.smt2`; run `build-dev/bin/cvc5 datatypes.smt2`. The
expected result is `unsat`.

```smt2
(set-logic QF_UFDTLIA)
(declare-datatype List ((nil) (cons (head Int) (tail List))))
(declare-const x List)
(declare-const y List)
(assert (= x (cons 0 y)))
(assert (= y (cons 1 x)))
(check-sat)
```

An inductive list must be finite. Here `x` contains `y` as a tail, and `y`
contains `x`, so neither can be a finite constructor value. Think of the
constructor metadata as edges between equality classes: `[x] -> [y]` and
`[y] -> [x]`. The cycle test follows constructor fields through class
representatives, rather than looking only for a syntactic term containing
itself. Preprocessing can shorten this example before that test runs.

Read [merge][merge] to see how a class acquires constructor information,
then [checkCycles][cycles] to see the inductive conflict route and the
different treatment of codatatypes. Keep two explanations separate:
constructor injectivity gives equal fields from equal constructors;
well-foundedness rules out this cycle. Congruence alone gives neither the
reverse constructor implication nor the well-foundedness argument.

Replace the second assertion with `y = nil`, enable `:produce-models`, and
request `(get-value (x y (head x) (tail x)))` after the check. The expected
values are `x = cons(0,nil)`, `y = nil`, head `0`, and tail `nil`, modulo
printing. Next try `(head nil)`: this is a wrong-constructor selector, so
the previous head equation no longer determines its value. The upstream
[datatype example][example] includes constructor, selector and tester syntax.

### Relate the example to the papers

The two-class list cycle is an inductive acyclicity obligation from
[CODATATYPES-2017](../references.md#codatatypes-2017). Follow the equality
representatives across the constructor edges rather than searching only for
a syntactic `x = cons(..., x)`. Compare the paper's codatatype treatment before
reusing that check for potentially infinite structures. For the grammar
use of datatypes, [CVC4SY-2019](../references.md#cvc4sy-2019) explains the
separate enumeration problem; [INDUCTION-2015](../references.md#induction-2015)
addresses another distinct task, proving quantified inductive properties.

### Further validation

For a change to tester handling, test positive and negative testers, a merge
with a constructor, and a class with only selectors. For a care-graph or model
change, include a parametric datatype whose fields are shared with arithmetic
or UF, plus a repeated check across a user pop. A ground constructor rewrite
test alone will not exercise these paths.

[theory]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/theory_datatypes.cpp
[rewriter]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/datatypes_rewriter.cpp
[im]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/inference_manager.cpp
[sygus]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/sygus_extension.cpp
[merge]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/theory_datatypes.cpp#L491
[cycles]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/theory_datatypes.cpp#L1446
[example]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/examples/api/smtlib/datatypes.smt2
