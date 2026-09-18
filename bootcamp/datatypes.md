# Datatypes

Source baseline: [2026-09-18](source-baseline.md). The main implementation is
[TheoryDatatypes][theory], with [rewriting][rewriter],
[inference management][im] and a [SyGuS extension][sygus].

## Constructor structure on equality classes

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
tuples and synthesis grammars also use datatype infrastructure. Before
changing a generic constructor rule, find its uses through the datatype
utilities and the SyGuS extension.

## Facts and the full-effort loop

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

An inductive constraint `x = cons(a,x)` is the simplest cycle to understand,
but useful tests also contain cycles exposed only by equality merges. A
codatatype permits cyclic values, so the inductive cycle rule cannot be
applied indiscriminately to all datatype sorts.

## Equality callbacks and combination

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

## Model skeletons

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

For a change to tester handling, test positive and negative testers, a merge
with a constructor, and a class with only selectors. For a care-graph or model
change, include a parametric datatype whose fields are shared with arithmetic
or UF, plus a repeated check across a user pop. A ground constructor rewrite
test alone will not exercise these paths.

[theory]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/theory_datatypes.cpp
[rewriter]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/datatypes_rewriter.cpp
[im]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/inference_manager.cpp
[sygus]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/datatypes/sygus_extension.cpp
