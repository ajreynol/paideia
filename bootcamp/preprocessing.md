# Rewriting and preprocessing

Before studying the code, separate two kinds of transformation.
**Ordinary rewriting** replaces a term with another having the same value in
every interpretation allowed by its theory. For a Boolean formula, this means
preserving its truth value. Thus `x + 0` can become `x` regardless of the input
assertions. The equality between the old and new terms is valid. Rewriting is
**context-independent**: it does not rely on assertions or temporary search
choices. The rewriter is used throughout solving, including during
preprocessing and when theories construct new terms.

Rewriting both simplifies expressions and puts them into consistent forms.
A **normal form** is the result on which the selected rewrite rules have no
further work to do. This helps later algorithms recognize shared structure;
it does not mean that every pair of mathematically equivalent expressions
will have the same normal form.

**Preprocessing** prepares the asserted problem for search. Its usual contract
is **equisatisfiability**: the transformed problem has a model exactly when the
original does. It may use relationships between assertions, eliminate variables
or introduce fresh symbols with defining constraints. For example, from
`x = 3` and `x + y > 5`, it can eliminate `x` and solve `3 + y > 5`, remembering
`x = 3` for model reconstruction. Replacing `x` by `3` is justified by this
problem's assertion, so it is not an unconditional rewrite of the term `x`.

The useful scheduling picture is a preprocessing stage before search, with
rewriting available throughout. In an ordinary non-incremental run, the input
goes through that preparation stage before the main search. In incremental
use, new assertions need preparation for later checks; a preprocessing pipeline
can itself repeat passes. Theory-generated lemmas also undergo theory
preprocessing. Consequently, “once” describes the initial preparation stage,
not a promise that every preprocessing routine runs only once per solver.

Source baseline: [2026-09-18](source-baseline.md).

## Three places that can change a term

The [ordinary rewriter][rewriter] recursively normalizes nodes using theory
rewriters. Its pre-rewrite step can simplify before visiting children; its
post-rewrite step uses rewritten children. A rewrite response can request
another pass, so changing a kind or introducing new structure may trigger
further rewriting. Termination and stable normal forms are engineering
requirements: two rules that keep exchanging representations can loop.

`Theory::ppRewrite` performs theory preprocessing, which can introduce
auxiliary skolems and associated lemmas. For example, eliminating an extended
arithmetic operator or making an underspecified floating-point operation
explicit requires more machinery than simplifying `x + 0`. It returns a
`TrustNode` describing a rewrite, with a separate vector of `SkolemLemma`s
where needed. It is also applied to theory-generated lemmas, so these
operators must remain eliminable after the initial input preprocessing.

An assertion-level [preprocessing pass][passes] sees an `AssertionPipeline`.
It can transform several formulas, learn substitutions, introduce assertions
or exploit a property of the whole input. The ordering and option-dependent
selection of passes live in [ProcessAssertions][process]. A transformation
that is safe only after a particular pass must not silently move into the
ordinary rewriter.

Special solving modes can change the usual preservation contract. For example,
restricting unbounded integers to a bounded search space can lose solutions.
Such modes must account for that loss of completeness when reporting results.
They have additional obligations beyond the ordinary preprocessing contract
described here.

There is also a `ppStaticRewrite` hook. Several transformations described as
`ppRewrite` in the bootcamp now live in this separate hook, including some
arithmetic and bit-vector equality transformations. Check the current override
and its caller rather than treating every preprocessing rewrite as one phase.

A useful literature distinction is between discovering a rewrite and
justifying its use. [REWRITE-ENUM-2019](references.md#rewrite-enum-2019)
searches for candidate rules; [REWRITE-DSL-2022](references.md#rewrite-dsl-2022)
describes how rules support fine-grained reconstruction. Neither makes a
context-dependent deduction a globally valid cached rewrite. For string-specific
examples, see [STRINGS-ABSTRACTION-2019](references.md#strings-abstraction-2019).

## Assertion substitution is a scoped operation

A **substitution** replaces occurrences of a symbol or term with another
expression. Eliminating `x` using `x = t` requires that the replacement be
well-typed and not depend circularly on `x`. It also requires a scope: a
replacement learned from an assertion that a user later removes cannot remain
an unconditional fact. The example `x = 3` above illustrates both why the
substitution helps search and why its definition still matters to the model.

`Theory::ppAssert` can solve an assertion for a variable and record a
substitution through `TrustSubstitutionMap`. The base implementation handles
legal variable equalities; individual theories can do more or decline the
operation. For `x = t`, legality includes type compatibility and preventing a
cyclic replacement. Arithmetic can solve a linear equation for a variable;
the number of terms introduced by the substitution is an additional heuristic.

The [assertion pipeline][pipeline] records more than a vector of nodes. It
preserves information needed for proofs, assertion provenance and auxiliary
definitions. A pass should use its replacement/insertion interfaces. Updating
only a parallel local vector can disconnect the transformed formula from
proof reconstruction or later model recovery.

User-level definitions and eliminated variables still matter to `getValue`
and model checking. That is why preprocessing, top-level substitutions and
[definition expansion][expand] must agree. “The term was removed from SAT”
does not mean “the public solver can forget what it meant.”

## Remove term-level formulas without losing semantics

An **if-then-else** expression, written `ite(c,y,z)`, denotes `y` when the
Boolean condition `c` is true and `z` otherwise. Inside `f(ite(c,y,z))`, it
puts a Boolean choice in the middle of a non-Boolean term. **Purification**
names that inner expression with an auxiliary symbol and supplies constraints
that preserve its meaning. This lets Boolean search handle the choice while
the function solver sees an ordinary argument.

SAT handles Boolean structure, while theory terms may contain conditionals or
Boolean-valued arguments. [RemoveTermFormulas][rtf] bridges that boundary.
For a non-Boolean `ite(c,y,z)`, it introduces a purification skolem `k` and a
Boolean assertion:

```text
ite(c, k = y, k = z)
```

The enclosing term uses `k`. This moves the branch choice into Boolean search
without asking every theory to implement term-level ITE reasoning.

For `g(and(a,b))`, it can instead use `g(k)` and `k = and(a,b)`. The fact that
`k` has Boolean type is not enough: UF must learn which Boolean value it has
when congruence depends on it. For example, if `k1` and `k2` are both true,
`g(k1) != g(k2)` must be inconsistent.

The current implementation uses `SkolemId::PURIFY` and
`Env::registerBooleanTermSkolem`. [Env::theoryOf][env] routes these registered
Boolean term skolems to UF. The old `BOOLEAN_TERM_VARIABLE` kind from the
bootcamp is not the current mechanism. Registration is scoped in the
environment, while the skolem's identity belongs to the node manager.

Term context matters. `RemoveTermFormulas` distinguishes a Boolean formula
position from a Boolean term used as an argument, and its cache includes that
context. Its traversal currently stops at closures rather than performing
this removal inside quantifier bodies. Replacing an expression depending on
bound variables with one global fresh constant would lose that dependency;
quantifier-aware transformations need their own justification.

## Rewriting must agree with caches and proofs

The core rewriter's pre/post caches are node attributes. The cache has no key
for the current SAT branch. Do not add a rewrite based on “the equality engine
currently knows `x = y`” to that mechanism. Theory-local extended rewriting
or scoped simplification is the appropriate place to consider contextual
facts, with explanations when those facts justify the result.

When proofs are enabled, rewriting also has to account for the path from the
original node to the result. A cached unproved result is not by itself a proof.
The rewriter has logic to obtain proof-producing rewrites even when a normal
rewrite result already exists. New rules should preserve the same normalized
result in both paths.

Current cvc5 includes a [rewrite-rule DSL infrastructure][dsl] in
`src/rewriter/` and rule files such as `src/theory/arith/rewrites` and
`src/theory/strings/rewrites`. These contribute named rules and proof
reconstruction; they do not imply that all runtime C++ rewriting has been
replaced by a single generated rewriting engine. When adding a C++ rewrite,
look for the corresponding rule/checker or reconstruction route as a separate
part of the change.

## Inspect the boundary before debugging search

[FLEXIBLE-PROOFS-2022](references.md#flexible-proofs-2022) explains how
preprocessing transformations retain proof dependencies, while
[REWRITE-DSL-2022](references.md#rewrite-dsl-2022) details reconstruction of
individual rewrites. In the conditional-term example below, identify both
the auxiliary definition and the rewritten assertion: the final assertion's
proof must still account for the transformation introducing that definition.

### Worked example: a conditional inside a function application

Save as `preprocessing.smt2` and use the command below. The expected
satisfiability result is `unsat`.

```smt2
(set-logic QF_UFLIA)
(declare-const c Bool)
(declare-const x Int)
(declare-const y Int)
(declare-fun f (Int) Int)
(assert (distinct (f (ite c x y)) (ite c (f x) (f y))))
(check-sat)
```

Whichever branch `c` selects, both sides are the same function application.
To understand term-formula removal, name the two non-Boolean ITE results
`k` and `h`. A possible intermediate representation is:

```text
f(k) != h
ite(c, k = x, k = y)
ite(c, h = f(x), h = f(y))
```

For `c = true`, the definitions give `k = x` and `h = f(x)`; congruence
contradicts `f(k) != h`. The false branch is analogous. As Boolean clauses,
the first definition can be written `(not c or k = x)` and
`(c or k = y)`. Both directions of the branch choice are accounted for.
Adding only `k = x` would strengthen the input incorrectly.

The original formula and the conjunction with definitions do not have the
same free-symbol vocabulary. The preservation argument is that a model of
the original can be extended with appropriate values for `k,h`, and a model
satisfying the transformed formula and definitions restricts to a model of
the original. This is the concrete meaning of *equisatisfiability* when
preprocessing introduces fresh symbols. Dropping the definitions loses
that argument.

This is a possible intermediate form, not expected literal diagnostic output:
earlier rewriting or ITE simplification may choose another representation
or solve the problem. Follow [RemoveTermFormulas][rtf] and the
[theory preprocessor][theory-preprocessor] when identifying the actual phase.
The [query chapter](query.md#definitions-must-participate-in-decisions)
explains why the defining assertions also participate in decision relevance.

```sh
build-dev/bin/cvc5 -o post-asserts -o subs preprocessing.smt2
```

The [output tags][output] are defined in `base_options.toml`. `post-asserts`
prints the preprocessed problem and `subs` reports learned top-level
substitutions. Use a small example where a target operator survives ordinary
rewriting to investigate theory preprocessing. To study a generated lemma,
follow the proxy/theory-preprocessor path as well as the initial pass list.

A useful review sequence is: state the equivalence or equisatisfiability
argument, identify introduced symbols and their scopes, check how the model
reconstructs eliminated terms, and check the proof path. Then test the boundary
cases where the transformation is disabled, repeated, or used after a pop.

Next: [How to develop a theory](theory-development/README.md), starting with
its [common interface](theory-development/interface.md).

[rewriter]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/rewriter.cpp
[theory-preprocessor]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/theory_preprocessor.cpp
[passes]: https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/preprocessing/passes
[process]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/process_assertions.cpp
[pipeline]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/preprocessing/assertion_pipeline.h
[expand]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/expand_definitions.cpp
[rtf]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/term_formula_removal.cpp
[env]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt/env.cpp
[dsl]: https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/rewriter
[output]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options/base_options.toml
