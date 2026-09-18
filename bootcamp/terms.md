# Terms, types and ownership

A **term** is an expression that denotes a value. In `x + 1 > 0`, the
subexpression `x + 1` is an integer term and the whole comparison is a Boolean
term, also called a **formula**. A **sort**, or type, describes the values a
term may denote. Declaring `x` as an integer does not assign it a particular
integer: finding a suitable value is the solver's job.

cvc5 represents expressions as immutable nodes connected to their arguments.
Constructing `x + 1` builds that representation; it does not choose `x` or run
a satisfiability check. Algorithms inspect nodes, build replacement nodes and
attach bookkeeping to them. This chapter explains how those objects are
shared, what their types and values mean, and who keeps them alive. These
distinctions matter whenever code traverses or caches an expression.

Source baseline: [2026-09-18](source-baseline.md).

## Public handles and their managers

At the C++ API boundary, `Term` wraps an internal `Node`, `Sort` wraps a
`TypeNode`, and `Op` exposes operators, including indexed operators. A
`TermManager` constructs sorts and terms; a `Solver` uses a term manager and
owns its internal `SolverEngine`. Read the public declarations in
[cvc5.h][api] with their implementation in [cvc5.cpp][api-cpp].

```cpp
cvc5::TermManager tm;
cvc5::Solver solver(tm);
auto integer = tm.getIntegerSort();
auto x = tm.mkConst(integer, "x");
auto zero = tm.mkInteger(0);
auto nonnegative = tm.mkTerm(cvc5::Kind::GEQ, {x, zero});
solver.assertFormula(nonnegative);
```

This fragment illustrates API construction; it is not a standalone program.
`mkConst` creates a free symbol, while `mkInteger` creates a value and `mkVar`
creates a bound variable. The word “constant” in an API name is not a reliable
guide to internal `isConst()` behavior.

The bootcamp calls `NodeManager` a singleton. That is obsolete: `TermManager`
owns a node manager, multiple managers are supported, and solvers using the same
term manager share its term universe. The deprecated no-argument `Solver`
constructor uses a thread-local default term manager. Do not mistake that
compatibility route for the ownership model of all terms. Keep the manager
alive for its objects' use and destruction, and do not mix terms from different
managers in an API operation.

## A node is a shared DAG vertex

A **directed acyclic graph (DAG)** is an expression tree with sharing: several
parents can point to the same subexpression, and following child edges never
leads back to an ancestor. For `(x + 1) * (x + 1)`, both arguments can point to
one node for `x + 1`. **Interning** is the mechanism that reuses an existing
node when the same structure is constructed again. A **handle** is the small
C++ object through which code refers to that shared node.

`Node` is a reference-counted handle to a `NodeValue`. Structural interning in
the [node manager][nm] makes repeated construction of the same compound term
reuse the same vertex in that manager. Comparing nodes is consequently cheap;
it does not run a theorem prover. Free and bound symbols have identity: two
fresh symbols printed as `x` need not be the same node.

Nodes also represent structural objects such as bound-variable lists and
S-expressions. They are more general than user-level mathematical terms.
`getKind()` identifies the internal operation, `getNumChildren()` and `[]`
traverse arguments, `getType()` obtains a cached type, and `getOperator()`
accesses an operator where the kind supports one. The [NodeTemplate class][node]
is the authoritative contract for these operations.

Consider an internal `APPLY_UF` for `f(a,b)`. Its operator is the function
symbol `f`, and its ordinary children are `a,b`. When constructing a
parameterized node using `NodeManager::mkNode`, the supplied vector starts
with the operator. Once built, that operator is not counted as an ordinary
child. A traversal that rebuilds from children must explicitly preserve it.

At the API boundary, application kinds such as `APPLY_UF` expose the function
as child zero. Porting a visitor from public `Term` to internal `Node` by
renaming types can therefore silently change what it visits. For an indexed
operation such as bit-vector extract, the indices are carried by an operator
payload; internal code retrieves that payload from `getOperator().getConst<T>()`.
Other operator kinds have a built-in operator rather than a user function.

`MetaKind` groups kinds by representation: variable-like, constant-payload,
ordinary operator, parameterized operator, and so on. It answers storage and
construction questions. Ordinary theory algorithms should usually dispatch on
`Kind`, not duplicate low-level metakind logic.

### Walk one application at both interfaces

Consider a function `f : Int -> Int` and the expression `f(x + 1)`. The
mathematical argument list has one entry, but the traversal interfaces expose
it differently:

| Observation | Public `Term` for `f(x + 1)` | Internal `Node` for `f(x + 1)` |
| --- | --- | --- |
| Kind | `cvc5::Kind::APPLY_UF` | Internal `Kind::APPLY_UF` |
| Number of children | 2 | 1 |
| Child zero | Function symbol `f` | Sum `x + 1` |
| Child one | Sum `x + 1` | No such child |
| Function symbol | `term[0]` | `node.getOperator()` |

Verify the public behavior in [Term::getNumChildren and operator[]][term-children]
and the internal representation in [NodeTemplate][node]. An API `Op` for
`APPLY_UF` is not the function symbol `f`; the symbol remains a term in the
public child sequence. For an indexed operator such as `((_ extract 7 4) b)`,
the indices instead belong to the `Op`/internal operator payload.

Repeated occurrences of `x + 1` can share a single DAG vertex. A recursive
visitor that needs to process every *occurrence* should not silently switch
to a visited-node set; a structural property that is independent of position
can often be memoized by node. A property depending on enclosing binders or
formula-versus-term position needs that context in its cache key. The
[term-formula removal example](preprocessing.md#remove-term-level-formulas-without-losing-semantics)
shows why this distinction changes semantics.

Three different questions often get called “equality”:

| Question | Appropriate mechanism |
| --- | --- |
| Did I reconstruct the same interned syntax? | Compare `Node` handles within one manager |
| Does unconditional normalization identify these expressions? | Rewrite them, then compare the results |
| Do the currently asserted facts imply equality? | Ask the relevant theory/equality state and retain an explanation when deriving an inference |

For example, `x + 0` and `x` can start as different nodes but normalize to
the same one. Two variables `x,y` can remain different nodes even after the
solver learns `x = y`. Rebuilding `x` with `mkConst(integer, "x")` produces
another symbol with the same printed name, not a lookup of the old symbol.
The API's [mkConst implementation][mkconst] makes that freshness explicit.

## Symbols, values and nullary operations

A symbol names a value that may still be unknown; a value such as the integer
`3` already denotes a particular object. A **bound variable** gets its meaning
from an enclosing binder: in `forall x. x = x`, the quantifier binds `x` in
its body. A lambda binds parameters of a function expression in the same way.
For example, `lambda x. x + 1` denotes the function that adds one to its argument.
The binder and its body together are called a **closure** in this code.
An operation is **nullary** when it has no arguments. That describes syntax,
so it does not by itself tell us whether the node is a symbol or a value.

These distinctions matter when adding a rewrite or model rule:

| Internal object | Example | Meaning |
| --- | --- | --- |
| Free symbol | `VARIABLE`, `SKOLEM` | An interpreted-by-the-model symbol; not a known value |
| Bound variable | `BOUND_VARIABLE` | A variable bound by a closure such as a quantifier or lambda |
| Value | `CONST_INTEGER`, `CONST_STRING`, `UNINTERPRETED_SORT_VALUE` | An internal value representation |
| Nullary interpreted operator | `PI`, `SET_UNIVERSE`, `SEP_NIL` | A theory operation with no children, not automatically a canonical value |

`Node::isConst()` remains the current method name. It means that the node is
recognized as a value by the kind-specific implementation, not simply that it
has zero children. Constructor values and finite-set normal forms can have
children. Strings and constant sequences have payload-based representations;
the API's sequence-value operations should not be implemented by assuming a
sequence value is always a `seq.++` syntax tree.

Value recognition is deliberately partial. A closed expression can denote a
value without being recognized as a value in its present syntax. The intended
canonicality contract is that distinct recognized values of the same type
represent distinct values. Rewriting often constructs the normal form needed
for that contract. Arrays and functions are especially subtle: store chains
or lambdas may denote equal objects without syntactic identity. Do not extend
`isConst()` merely because every child passes it; inspect the kind's
constant-computation rule and normal-form requirements.

`getConst<T>()` extracts a payload of the correct C++ type; it is also used
for indexed-operator payloads. It does not evaluate arbitrary terms. The
bootcamp's proposals to rename it to `getValue`, `isVar` to `isSymbol`,
`TypeNode` to `Type`, or `expr/` to `node/` are not the names in this snapshot.
The bootcamp's `UNINTERPRETED_CONSTANT` is now `UNINTERPRETED_SORT_VALUE`.

`TypeNode` uses related representation machinery but denotes a sort, not a
term. Type rules live beside the theories and are wired through kind metadata.
For a new polymorphic kind, test ill-typed and parametric cases as well as its
obvious ground use. Matching a `Kind` without checking the instantiated type
is a common mistake in congruence and care-graph indexing.

The distinction between `APPLY_UF`, an operator, and an ordinary child becomes
especially useful when reading [HIGHER-ORDER-2019](references.md#higher-order-2019).
Compare the application walk above with partial application and lambda terms
in the [UF chapter](theory-development/uf.md). Replacing all applications by
one untyped argument list would lose distinctions needed by that reasoning.

## References and attributes have different lifetimes

Expression sharing raises a memory-management question: when is it safe to
reclaim a node? An owning `Node` handle contributes to the node's reference
count; a borrowed handle relies on an owner elsewhere. Metadata has a second
lifetime question: even if a node is still alive, is a cached answer about it
still true after search changes its assumptions?

`TNode` is the non-owning, non-reference-counting node handle. Another owner
must keep its node alive. It is useful for short traversals; storing it in a
long-lived container requires an explicit lifetime argument. A `Node` stored
in the container is usually easier to reason about. `TNode` has not been
replaced by C++ references.

[Attributes][attribute] attach typed metadata to nodes. A tag type distinguishes
two attributes with the same value type:

```cpp
struct ExampleTag {};
using ExampleAttribute = expr::Attribute<ExampleTag, uint64_t>;
// n.setAttribute(ExampleAttribute(), value);
// n.hasAttribute(ExampleAttribute());
// n.getAttribute(ExampleAttribute());
```

This internal illustration assumes the appropriate namespace and header.
Attribute keys do not keep the owning node alive; attribute entries are
removed when that node is reclaimed. Attribute *values* can themselves be
owning `Node`s, so “attributes never ref-count anything” would be too broad.
Names and cached structural properties are natural attributes. A property
valid only on the current SAT branch is not.

Boolean attributes have a special default: `false`. `hasAttribute()` is true
even before an explicit assignment; use the value to test the flag. If you
need to distinguish “not computed” from “computed false”, represent that state
separately. See the [attribute specializations][attribute-internals].

The ordinary rewriter still caches results in node attributes, through
[rewriter_attributes.h][rw-attributes]. Different solvers sharing a manager
can therefore observe shared caches. The bootcamp's suggestion of an RAII
solver-local replacement should not be described as implemented. A rewrite
must respect the cache's lifetime and assumptions; context-sensitive or
option-sensitive simplification belongs in a suitably scoped mechanism.
This observation is a development constraint, not evidence of a particular
current cache bug.

Proof reconstruction makes term identity and binding observable outside the
rewriter. [FLEXIBLE-PROOFS-2022](references.md#flexible-proofs-2022) explains
why a transformation needs a recoverable justification, while
[CPC-2026](references.md#cpc-2026) supplies a calculus-level perspective.
Use those accounts when deciding what information an auxiliary term must retain.

## Skolems record why a new symbol exists

Solving often introduces symbols that the user did not write. They can name
a complicated expression or stand for a needed witness. For example, if two
arrays differ, there must be some index at which their reads differ; an
auxiliary symbol can name that index. cvc5 uses **skolems** for several such
roles. The introducing transformation must retain the symbol's meaning and
the constraints that justify its use.

The [SkolemManager][skolems] supplies reproducible identities for auxiliary
symbols. `mkPurifySkolem(t)` returns a symbol representing a term; requesting
the same purification reuses its identity. `mkSkolemFunction` uses a
`SkolemId` plus index/cache terms, whose combination determines the symbol and
its type. Array extensionality witnesses are one example. Current names use
`SkolemId`; the bootcamp's `SkolemFunId` is historical.

`mkDummySkolem` creates a fresh auxiliary symbol without such a semantic
definition. It is useful where a fresh symbol is what the algorithm actually
needs; using one to bypass a missing definition can make reconstruction and
proof work harder. `getUnpurifiedForm` exposes one purification step, while
`getOriginalForm` recursively recovers original terms through purification.
Skolemization of quantified formulas now also involves the quantifiers'
dedicated [Skolemize][skolemize] utility; do not look for the whole algorithm
in a historical `mkSkolemize` entry point.

For example, the string solver may need arithmetic to reason about the length
of `str.++(a,b)`. A direct equality between that length and `len(a)+len(b)`
can rewrite to `true` before arithmetic sees anything useful. Purifying the
concatenation to `k` allows a constraint about `len(k)` to cross the theory
boundary while retaining the connection to the original term. Creating `k`
does not automatically assert every defining constraint: the caller must use
the appropriate inference/preprocessing path.

Next: [the path of a query](query.md).

[api]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/include/cvc5/cvc5.h
[api-cpp]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/api/cpp/cvc5.cpp
[nm]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/expr/node_manager_template.h
[node]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/expr/node.h
[attribute]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/expr/attribute.h
[attribute-internals]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/expr/attribute_internals.h
[rw-attributes]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/rewriter_attributes.h
[skolems]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/expr/skolem_manager.h
[skolemize]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/quantifiers/skolemize.cpp
[term-children]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/api/cpp/cvc5.cpp#L2566
[mkconst]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/api/cpp/cvc5.cpp#L6640
