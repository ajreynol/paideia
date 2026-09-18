# Building and navigating

Source baseline: [2026-09-18](source-baseline.md). Start in the root of a cvc5
checkout, rather than this repository, for the commands below.

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
ctest --test-dir build-dev -N
ctest --test-dir build-dev --output-on-failure -L unit
```

`--auto-download` permits the build to obtain missing dependencies. Adapt the
parallelism to available memory. `ctest` runs built tests; it is not a substitute
for building their executables. For a first change, list tests with `-N`, select
the relevant unit/API/regression tests, and run the broader checks required by
the change. The upstream [installation instructions][install] and
[test targets][tests] give the supported combinations.

Use `--ninja` if Ninja is installed and `--ccache` if ccache is installed.
`--asan` and `--ubsan` are useful for lifetime and undefined-behavior bugs.
Record the build type and options with any experiment: disabling assertions,
changing a SAT backend, or omitting an optional algebra package can change the
observed path. The configuration vocabulary is in [configure.sh][configure]
and the dependency/build logic is in [CMakeLists.txt][cmake].

## Find the implementation layer

| Path in cvc5 | What to look for |
| --- | --- |
| `include/cvc5/`, `src/api/` | Public types, API checks and conversion to internal objects; bindings |
| `src/main/`, `src/parser/` | Executable entry, input parsing, commands and symbol management |
| `src/expr/` | Nodes, types, attributes, skolems, datatype declarations and kind generation |
| `src/context/` | Backtracking storage and memory management |
| `src/smt/` | Solver lifecycle, assertions, environments, preprocessing orchestration and results |
| `src/preprocessing/` | Assertion pipeline and named preprocessing passes |
| `src/prop/`, `src/decision/` | CNF, SAT integrations, SAT/theory callbacks and decision strategies |
| `src/theory/` | Common theory protocol and individual theories |
| `src/rewriter/`, `src/proof/` | Rewrite-rule infrastructure, proof objects, reconstruction and output |
| `src/options/`, `src/util/`, `src/base/` | Options, numeric/string utilities, statistics, tracing and assertions |
| `proofs/`, `test/`, `examples/` | Proof-format definitions, regression/unit/API coverage and public examples |

The [library source list][sources] is useful when a class seems to be missing:
some headers and translation units are generated. For example,
`expr/node_manager.h` comes from `node_manager_template.h`. A source-only search
for the generated filename will not find its definition.

## Kinds connect a theory to the rest of the solver

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

The bootcamp proposes this to reduce binary size and dependency exposure. The
current configuration does **not** expose a general switch such as
`--disable-theory=strings`. It has optional packages and feature/build modes.
Disabling CoCoA, for example, disables the available finite-field solving
backend; it does not delete finite-field kinds, values, type checking and all
references to that theory. Setting a narrow SMT logic is also a runtime
selection, not removal of code from the binary.

The source list still includes theory implementations and collects kinds
across theories. Generated type-checking, rewriting and enumeration dispatch
can refer to a theory even when a proposed build omits its main solver class.
This answers the bootcamp's kinds-generation concern: merely skipping
construction of a `Theory` object cannot implement modular compilation.

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
