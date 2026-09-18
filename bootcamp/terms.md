# Terms, types and ownership

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

## Symbols, values and nullary operations

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

## References and attributes have different lifetimes

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

## Skolems record why a new symbol exists

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
