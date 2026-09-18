# How to develop a theory

[Bootcamp](../README.md) / How to develop a theory

Source baseline: [2026-09-18](../source-baseline.md).

This category explains how to change a cvc5 theory solver. Start with the
shared workflow below and the [common theory interface](interface.md), then
use the sub-guide for the theory you are changing. Each sub-guide instantiates
the same development stages with that theory's classes, invariants, callbacks,
model obligations and validation cases.

The prerequisites are [terms and ownership](../terms.md),
[the path of a query](../query.md) and [preprocessing](../preprocessing.md).
Use the general [development workflow](../development.md) for adding kinds,
options, proof support and tests, and [building](../build.md) for commands.

## Shared contract and theory sub-guides

The [common theory interface](interface.md) supplies the contract for routing,
fact processing, inference, equality engines, combination and models. Read
it alongside the selected theory's overrides and delegated helpers.

| Sub-guide | The development problem it specializes |
| --- | --- |
| [UF and higher-order reasoning](uf.md) | Congruence, function extensionality, finite domains and extensions |
| [Arrays](arrays.md) | Read/write indices, extensionality witnesses and array model skeletons |
| [Datatypes](datatypes.md) | Constructor-class metadata, testers, cycles, splitting and synthesis interaction |
| [Arithmetic](arithmetic.md) | Linear constraints, integer reasoning and nonlinear model refinement |
| [Bit-vectors](bit-vectors.md) | Backend selection, bit blasting, assumptions and abstraction/refinement |
| [Floating point](floating-point.md) | Totalization, symbolic word blasting and real-conversion refinement |
| [Finite fields](finite-fields.md) | Polynomial encoding, algebraic conflicts and base-field root construction |
| [Strings and sequences](strings.md) | Coordinated subsolvers, term registration, typed sharing and length-based models |
| [Sets and relations](sets.md) | Membership closure, class merges, cardinality and relational reasoning |
| [Bags and tables](bags.md) | Count equations, multiplicity, quantified reductions and table operations |
| [Separation logic](separation-logic.md) | Heap labels, spatial reduction, points-to compatibility and heap refinement |
| [Quantifiers and synthesis](quantifiers.md) | Module ownership, instantiation, nested efforts and completeness |

For a first tour, begin with UF, then arrays and datatypes. They show how
increasing amounts of theory-specific state build on equality reasoning.
The numeric and collection theories show other solver organizations.
Quantifiers provides a final example in which the shared ground-theory
protocol delegates to a larger module architecture.

## Development workflow

1. **State the invariant and locate its owner.** Write a small input and the
   expected change in behavior. Identify the theory wrapper, its state and
   inference manager, and any backend or extension that actually owns the
   algorithm. Follow delegation before deciding where to edit. The first
   section of each sub-guide establishes the representation you must preserve.
2. **Trace preprocessing and registration.** Decide whether the operation is
   eliminated, normalized or retained for search. Check the selected logic,
   options, generated kind/type metadata and any auxiliary definitions. Then
   follow preregistration and the equality triggers or indices it establishes.
   A test of a rewrite alone does not exercise a term that survives into search.
3. **Choose the fact and inference path.** Read the base fact loop before
   changing `preCheck`, `preNotifyFact`, `notifyFact` or `postCheck`. Determine
   the effort at which work runs, the meaning of an early return, and when
   pending facts or lemmas are consumed. Send a derived fact, propagation,
   conflict or lemma through the appropriate inference interface, with its
   assumptions and proof information accounted for.
4. **Preserve equality and scope.** Identify the class metadata and shared
   terms affected by the change. Check merge callbacks, typed care pairs and
   explanations. Choose SAT-context, user-context or persistent storage
   according to when the state must be invalidated. Trace a backtrack or user
   pop through both the equality engine and the theory's associated state.
5. **Complete the model path.** Follow relevant-term computation, values or
   skeletons contributed to the global model, and any candidate refinement.
   State what happens when the procedure cannot justify the candidate.
   Distinguish equality chosen in a model from equality established by facts;
   do not use a model choice as an explained propagation.
6. **Validate the changed boundary.** Use the sub-guide's final section to
   select cases for this theory. Check a refutation and a satisfiable model
   where applicable, the affected option/backend, relevant context changes
   and interactions with other theories. Exercise proof production for a
   changed inference. Record the input, revision, build, options and outcome
   using the [general testing workflow](../development.md#tests-that-cross-the-changed-boundary).

The interface details behind this workflow are in [Theory][theory] and
[TheoryInferenceManager][im], with their control flow explained in the
[shared contract](interface.md). A theory can inherit a stage or delegate it
to a helper; its sub-guide identifies that route. An absent override does not
mean the stage can be ignored when developing a change.

## The structure of every theory sub-guide

The same six sections make it possible to compare implementations and find
the next obligation for an edit. Specialized algorithms appear as subsections
inside the appropriate stage.

| Section | What to establish before changing it |
| --- | --- |
| Representation and invariants | Which terms, state and helper classes encode this theory's semantics? |
| Preprocessing and registration | What reaches search, and what must exist before a fact is processed? |
| Fact processing and checking | Who consumes the fact, when does reasoning run, and how does output return to search? |
| Equality and combination | What changes on a merge, what backtracks, and what must other theories know? |
| Model construction | How do relevant terms obtain compatible values, and can a candidate need more search? |
| Developing and validating a change | Where should a particular edit start, and which tests exercise its obligations? |

For example, a read-over-write change starts in the
[array sub-guide](arrays.md). Its registration section identifies the read
and store indices; checking identifies the selected inference route; equality
explains how merges expose new relationships; models explains why needed
reads and default values must still agree. The final section turns those
dependencies into edit locations and regression cases.

## Maintaining this category

Keep each theory sub-guide in this directory and list it in the table above.
Preserve the six section headings; the guide checker verifies them and the
parent index. Put the common protocol in [interface.md](interface.md), and put
the theory's concrete implementation and exceptions in its sub-guide. Describe
inherited or delegated behavior explicitly instead of leaving a stage blank.

When extending a sub-guide, retain its source links and follow the
[baseline update procedure](../source-baseline.md#a-maintenance-pass). Update
the [bootcamp coverage map](../bootcamp-coverage.md) when a topic moves. A
structural edit does not establish that the source baseline has advanced or
that the suggested validation cases have been executed.

[theory]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/theory.cpp
[im]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/theory_inference_manager.cpp
