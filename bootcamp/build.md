# Building and navigating

Building cvc5 turns its C++ source into a solver executable and libraries.
The executable reads inputs such as the tutorial's SMT-LIB files; a program
can instead call the library through its API. This chapter gets you a local
build for experiments and a map for finding the code behind an observation.

There are three steps. **Configuration** chooses features, dependencies and
compiler settings and writes build instructions. **Compilation and linking**
produce the executable and libraries. **Testing** runs those built programs
on selected cases. The source checkout and the build directory are separate:
`build-dev` below holds generated files and compiled output for one chosen
configuration. A debug build keeps checks and debugging information useful
when following the solver's execution.

For a first session, finish the checkout and build steps, then go directly to
the [three-check query](query.md#a-small-query-to-trace). The source directory
map and build-design sections below are reference material for later changes.

Source baseline: [2026-09-18](source-baseline.md). Start in the root of a cvc5
checkout, rather than this repository, for the commands below.

## Start from the source used by this guide

For a fresh checkout that reproduces the source links:

```sh
git clone https://github.com/cvc5/cvc5.git
cd cvc5
git switch --detach 3dcc1ef5421ab62cc1ee9af52d70042ce6861af0
git rev-parse HEAD
```

The detached checkout is useful for following the tutorial. Create a working
branch with `git switch -c my-change` when ready to edit. If you already have
a checkout with work in progress, use a separate checkout for this exercise.
To investigate newer `main`, record its commit and compare the affected code
with the [baseline](source-baseline.md) before applying the guide's line links.

The path `build-dev/bin/cvc5` below always means the executable produced by
this checkout. A bare `cvc5` can resolve to an older system installation.
After building, run `build-dev/bin/cvc5 --version` and retain its output with
your experiment. Archive builds may have no Git identifier in that output;
the independently recorded source revision still matters.

## Build a version you can investigate

`configure.sh` is a front end to CMake. Build types now include `unrestricted`,
`stable`, `safe`, `debug`, `testing` and `competition`. Older instructions using
other build-type names should be compared with `./configure.sh --help`.
`debug` enables assertions, tracing and debug symbols without optimization;
`testing` is an optimized debug configuration. `stable` and `safe` restrict
features; selecting one can change whether an experimental example is accepted.
These are developer-visible behavioral choices, not just compiler flags.

A useful starting configuration is:

```sh
./configure.sh debug --name=build-dev --auto-download --unit-testing
cmake --build build-dev -j 4
cmake --build build-dev --target build-tests -j 4
build-dev/bin/cvc5 --show-config
ctest --test-dir build-dev -N
ctest --test-dir build-dev --output-on-failure -L unit
```

`--auto-download` permits the build to obtain missing dependencies. Adapt the
parallelism to available memory. `ctest` runs built tests; it is not a substitute
for building their executables. For a first change, list tests with `-N`, select
the relevant unit/API/regression tests, and run the broader checks required by
the change. The upstream [installation instructions][install] and
[test targets][tests] give the supported combinations.

Confirm that `--show-config` reports tracing enabled. The tutorial uses output
tags such as `-o lemmas` and debug traces such as `-t im`; the latter require
that build feature. `--show-trace-tags` lists available trace tags.

Use `--ninja` if Ninja is installed and `--ccache` if ccache is installed.
`--asan` and `--ubsan` are useful for lifetime and undefined-behavior bugs.
Record the build type and options with any experiment: disabling assertions,
changing a SAT backend, or omitting an optional algebra package can change the
observed path. The configuration vocabulary is in [configure.sh][configure]
and the dependency/build logic is in [CMakeLists.txt][cmake].

For the finite-field exercise, enable CoCoA explicitly with `--cocoa` when
configuring, for example:

```sh
./configure.sh debug --name=build-ff --auto-download --cocoa
cmake --build build-ff -j 4
build-ff/bin/cvc5 --version
```

Use `build-ff/bin/cvc5` for that exercise. CoCoA's dependency and licensing
configuration is described in the upstream [installation instructions][install].
The availability of syntax at the parser does not establish that the build
contains the corresponding solver backend.

## Find the implementation layer

| Path in cvc5 | What to look for |
| --- | --- |
| [include/cvc5/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/include/cvc5), [src/api/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/api) | Public types, API checks and conversion to internal objects; bindings |
| [src/main/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/main), [src/parser/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/parser) | Executable entry, input parsing, commands and symbol management |
| [src/expr/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/expr) | Nodes, types, attributes, skolems, datatype declarations and kind generation |
| [src/context/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/context) | Backtracking storage and memory management |
| [src/smt/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/smt) | Solver lifecycle, assertions, environments, preprocessing orchestration and results |
| [src/preprocessing/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/preprocessing) | Assertion pipeline and named preprocessing passes |
| [src/prop/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/prop), [src/decision/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/decision) | CNF, SAT integrations, SAT/theory callbacks and decision strategies |
| [src/theory/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory) | Common theory protocol and individual theories |
| [src/rewriter/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/rewriter), [src/proof/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/proof) | Rewrite-rule infrastructure, proof objects, reconstruction and output |
| [src/options/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/options), [src/util/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/util), [src/base/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/base) | Options, numeric/string utilities, statistics, tracing and assertions |
| [proofs/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/proofs), [test/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/test), [examples/](https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/examples) | Proof-format definitions, regression/unit/API coverage and public examples |

The [library source list][sources] is useful when a class seems to be missing:
some headers and translation units are generated. For example,
`expr/node_manager.h` comes from `node_manager_template.h`. A source-only search
for the generated filename will not find its definition.

### Navigate from a symbol to the implementation

These searches run from the cvc5 source root:

```sh
rg -n 'TheoryArrays::notifyFact' src/theory/arrays
rg -n 'ARRAYS_EXT' src/theory src/proof include proofs
rg -n 'arraysWeakEquivalence|arrays-weak-equiv' src/options src/theory/arrays
rg --files test/regress/cli | rg 'arrays|array'
```

The first search locates an override. The second follows the inference and
proof identifiers it uses. The third connects a C++ option accessor to its
command-line spelling. The fourth finds candidate regressions; read their
`COMMAND-LINE` and `REQUIRES` metadata before treating them as comparable runs.
Start from [TheoryArrays::notifyFact][arrays-notify] to try this sequence.

When a method is absent from a theory's `.cpp`, inspect its header, the
[base Theory implementation][base-theory] and delegated helpers. When a header
is absent from `src/`, inspect the [generated source list][sources] and search
the build tree. These are different reasons for a search returning no match.

### Upstream reading companions

| Need | Source to keep beside this guide |
| --- | --- |
| Compiler, dependency and platform setup | [INSTALL.rst][install] |
| API construction and complete client programs | [C++ quickstart][cpp-quickstart] and [API examples][api-examples] |
| Executable invocation and SMT-LIB input | [Binary quickstart][binary-quickstart] |
| Changes to supported features | [NEWS.md][news] |
| Contribution and review conventions | [CONTRIBUTING.md][contributing] |

These links use the same source revision as the tutorial, including the
documentation sources. The [published cvc5 documentation](https://cvc5.github.io/docs/)
is easier to browse, but select its version deliberately when comparing an
API or option with this prerelease source.

## Kinds connect a theory to the rest of the solver

A **kind** identifies an expression's operation, such as addition or array
read. Its **arity** says how many arguments it accepts, and its **type rule**
says which argument types are legal and what result type follows. Many parts
of the solver need this same information. cvc5 generates some of their shared
declarations and dispatch code from metadata so the definitions stay connected.

[CVC5-2022](references.md#cvc5-2022) gives a system-level map of the theory
components. Use it to orient the source search below, then read the pinned
kind and option definitions for the interface exposed by this build.

Each theory's `kinds.toml` describes its kinds, metakinds, arities, type rules,
rewriter and related traits. `src/expr/mkexpr.py` and the theory generators
consume this metadata. `KINDS_TOML_FILES` in `src/CMakeLists.txt` assembles the
inputs. [Expression generation][expr-cmake] and [theory generation][theory-cmake]
produce dispatch code and declarations that couple otherwise separate modules.

Adding a new operator therefore touches more than the theory solver. Check its
public kind mapping, internal kind and payload, type checker, printer, parser
if needed, rewriting, model evaluation and proof handling. Generated files
belong in the build tree; change the template or metadata that produced them.

## Can a theory be disabled at build time?

Reducing binary size or dependency exposure can motivate removing a theory.
The current configuration does **not** expose a general switch such as
`--disable-theory=strings`. It has optional packages and feature/build modes.
Disabling CoCoA, for example, disables the available finite-field solving
backend; it does not delete finite-field kinds, values, type checking and all
references to that theory. Setting a narrow SMT logic is also a runtime
selection, not removal of code from the binary.

The source list still includes theory implementations and collects kinds
across theories. Generated type-checking, rewriting and enumeration dispatch
can refer to a theory even when a proposed build omits its main solver class.
Skipping construction of a `Theory` object cannot implement modular compilation.

A design for actual theory removal would need to define what survives at the
API and parser boundary, how disabled kinds fail, which utility types remain,
and how generated tables avoid unresolved references. It would also need to
account for dependencies such as floating-point word blasting into bit-vectors,
string lengths into arithmetic and sets of datatype tuples. This is an
engineering direction, not a supported recipe in this draft.

## Reduce build time by measuring the right thing

Separate a clean build, an incremental `.cpp` edit, a widely included header
edit and a metadata edit. They exercise different dependency paths. Record wall
time, peak memory, compiler, build type, generator and dependency-download time
separately. A cache hit is a different experiment from recompilation.

For Ninja, its build log and `-d stats` expose work and dependency overhead.
Compiler timing reports can identify expensive translation units; use the
timing facilities supported by the compiler you actually run. A generated
central header can invalidate many files even when the generator itself is
cheap. Link-time optimization can move much of the cost to linking.

Start with the slow rebuild observed by a developer, follow its dependency
chain, and test a concrete change such as moving an implementation out of a
header. Do not infer a compile-time hotspot from runtime statistics. This guide
has not benchmarked build times and makes no ranking of expensive files.

[configure]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/configure.sh
[cmake]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/CMakeLists.txt
[install]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/INSTALL.rst
[tests]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/test/CMakeLists.txt
[sources]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/CMakeLists.txt
[expr-cmake]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/expr/CMakeLists.txt
[theory-cmake]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/CMakeLists.txt
[arrays-notify]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/arrays/theory_arrays.cpp#L1473
[base-theory]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/src/theory/theory.cpp
[cpp-quickstart]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/docs/api/cpp/quickstart.rst
[api-examples]: https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/examples/api
[binary-quickstart]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/docs/binary/quickstart.rst
[news]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/NEWS.md
[contributing]: https://github.com/cvc5/cvc5/blob/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0/CONTRIBUTING.md
