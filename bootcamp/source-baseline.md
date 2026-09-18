# Source baseline and updating the guide

Upstream commit: `3dcc1ef5421ab62cc1ee9af52d70042ce6861af0`

Observed branch: upstream `cvc5/cvc5` `main`, read on **2026-09-18** with
`git ls-remote`. The [pinned source tree][source] calls itself **1.4.0 prerelease**
in NEWS. The expansion pass rechecked `main` on the same date and found the
same revision. This pin is not a promise that the live branch will remain
there or that the guide has received upstream review.

## Inputs and evidence

The supplied `cvc5-Bootcamp.docx` supplied the topic outline. Its SHA-256 is
`d265a8040a59b36e6e005b84739ab60013d5fc3e56df287f5a71abbe4c372fab`.
It remains a local, untracked input; the guide is self-contained and does not
link readers to a document absent from a clone. The
[coverage table](bootcamp-coverage.md) preserves its subject map in Markdown.

The source inspection used GitHub's archive for the exact commit, extracted
in ignored working space. The downloaded archive's SHA-256 was
`5aa940d77b46207dbaccd166fb5ec64c2f9c85a3cc3f571d67928ad8151df02c`.
This records the particular download, not a guarantee about the byte layout
of future GitHub-generated archives. No cvc5 source is vendored into the guide.

Each chapter links the implementation files used to check its claims. The
inspection included the common theory fact loop, theory-specific overrides
and relevant helpers, generated-source templates, kind and option metadata,
effective defaults, and model/proof interfaces. Current behavior is described
from code; historical questions and suggestions were not treated as evidence
that a feature exists.

The implementation account has **source inspection**, not runtime validation
of all described paths. The pinned cvc5 revision was not built and its test
suite was not run to prepare this guide. The expanded examples also received
the limited runtime checks recorded below, using a different revision.
Algorithm explanations summarize the inspected implementation; they are not
completeness or correctness proofs.

## Validation of the expanded examples

On 2026-09-18, `git ls-remote https://github.com/cvc5/cvc5.git refs/heads/main`
again returned the baseline above. A fresh download of its GitHub archive
had the same SHA-256 recorded above, and all **7,222 regular files** compared
byte-for-byte with the local source used for this pass. New links were checked
against that source, including the API child traversal, inference explanations,
array lemmas, datatype cycles, bag count equation and set rewrite used in the
worked explanations.

The locally available executable reported
`cvc5 1.3.5.dev+main@97b00835f [git 97b00835f on branch main]`, compiled with
GCC 15.2.0 on 2026-05-23. Its SHA-256 was
`50bfb9538278b353c5b448051ba145530e98f8a6970f6f61edf2251823157a6c`.
`--show-config` reported tracing enabled, debug code and assertions disabled,
safe/stable modes disabled, and no CoCoA. **This is an older build, not a
runtime check of the pinned `main`.**

All 15 complete `smt2` blocks were copied unchanged from the chapters into
temporary files and invoked as `cvc5 --tlimit=10000 FILE`. Fourteen completed
with the expected results:

| Chapter examples | Observed result |
| --- | --- |
| [Query](query.md#a-small-query-to-trace) | `sat`, `unsat`, `sat` across push/pop |
| [Preprocessing](preprocessing.md#worked-example-a-conditional-inside-a-function-application), [development](development.md#worked-change-investigation-membership-in-a-singleton) | `unsat` each |
| UF, arrays, datatypes, arithmetic, strings, sets, bags, separation logic, quantifiers | `unsat` each; inputs indexed in the [theory exercise table](theory-development/README.md#choose-a-concrete-starting-problem) |
| [Bit-vectors](theory-development/bit-vectors.md#worked-example-overflow-makes-an-inequality-true) | `sat`, `x = #b1111`, increment result `#b0000` |
| [Floating point](theory-development/floating-point.md#worked-example-two-meanings-of-equality) | `sat`; both zero predicates true, SMT equality false, `fp.eq` true |
| [Finite fields](theory-development/finite-fields.md#worked-example-a-polynomial-without-a-base-field-root) | Rejected because the executable lacks CoCoA; **not runtime-validated** |

On that same older executable, both `--bv-solver=bitblast` and
`--bv-solver=bitblast-internal` produced the documented bit-vector values.
The singleton-membership input returned `unsat` with
`--produce-proofs --check-proofs --proof-check=eager`, and the pinned
regression runner's `--tester base` accepted it. The quantifier example with
`-o inst` reported one instantiation and `unsat`. The preprocessing example
with `-o post-asserts -o subs` displayed two purification definitions and
returned `unsat`.

These checks validate parsing and observed outputs on that build. They do
not establish the exact callbacks reached on current `main`, proof completeness,
or runtime behavior of the additional prose exercises. The C++ fragments,
build commands and GDB session remain source-checked recipes. To repeat the
main-branch experiments, build the [pinned checkout](build.md#start-from-the-source-used-by-this-guide),
use its executable for each chapter's command, and enable CoCoA for the field
example. Record that build's version, options and outputs separately.

## Mechanical checks

### Literature pass

The literature expansion on **2026-09-18** added the
[research bibliography](references.md), with **92 entries** and contextual
citations throughout the architecture and theory tutorials. Discovery used
the CVC4/cvc5 publication pages and author catalogs recorded there. Inclusion
required a connection to a specific component in the pinned source; entries
supported only by a research branch, application or project association were
excluded. Each retained entry has its own source links and connection note.

Paper-to-code connections were checked against the existing source pin,
including explicit references in the string helpers, CEGQI and enumerative
instantiation headers, SyGuS embedding, bit-vector abstraction, split Gröbner
bases, arithmetic refinement and rewrite proof reconstruction. Current class
names and paths come from that source; a paper's experimental implementation
is not assumed to be merged. Partial connections are scoped explicitly: for
example, the parametric-bit-vector paper is linked to the PIAND/power-of-two
integer backend, and the distributed-solving paper to partition generation.
Proof-format papers connect to the formats actually emitted by the printers.

The tutorial's [unreferenced-papers footnote](unreferenced-papers.md) separately
records six publications covering five missing implementation features.
It also records the partial finite-field proof integration: rule declarations
exist, while the examined field-solving path lacks the corresponding producer
and checker. The audit distinguishes absence at this pin from a demonstrated
removal or an incorrect claim about a paper's own experimental version.

An external-link pass found and replaced three stale author-hosted PDF URLs
for solution fitting, distributed partitioning and CPC. Publisher access
restrictions and redirects prevent treating automated HTTP responses as a
universal availability check. Primary publication links and bibliographic
metadata remain separately reviewable in the bibliography. This pass did not
reproduce paper experiments or add new runtime claims about cvc5.

### Guide structure and source links

The small [guide checker](../scripts/check_guide.py) reads the authored
Markdown. It checks local links and heading fragments, reference definitions,
the artifact's hierarchy of chapter indexes, the six shared theory sub-guide
sections, the repository documentation index and use of this source pin.
Each chapter is indexed by its directory's README; a category README is indexed
by its parent. Given a source tree, the checker also checks that each linked
cvc5 path exists. Run these commands from the repository root:

```sh
python3 scripts/check_guide.py
python3 scripts/check_guide.py --cvc5-source /path/to/cvc5
git diff --check
```

For the initial draft on 2026-09-18, the checker passed against the extracted
baseline source: **27 local targets and 119 distinct cvc5 paths**. The tracked
diff and all newly authored files also passed whitespace checks. Both embedded
bootcamp figures were reviewed alongside the extracted paragraph text.

After the expansion pass, the checker passed with **28 local targets and
178 distinct pinned cvc5 paths**. All 20 distinct source line targets added
by the tutorials were checked against the pinned files, and `git diff --check`
passed. The six-section structure of every theory sub-guide is unchanged.

After the literature pass and unreferenced-paper audit, the checker passed
with **30 local targets and 250 distinct pinned cvc5 paths**, including all
new citation anchors and implementation reading stops. `git diff --check`
also passed. The tutorial
inputs and the six-section structure are preserved.

It does not fetch dependencies, generate prose, authenticate a checkout or
confirm that a method still behaves as described. Supply an independently
verified checkout or archive at the baseline. It also does not check external
sites outside the pinned cvc5 source links. No CI or scheduled maintenance has
been installed.

## A maintenance pass

1. Resolve upstream `main` to a full commit and record the observation date.
   Inspect an isolated checkout or archive; do not let unrelated local changes
   become the guide's undocumented source.
2. Compare the old and new revisions. Start with the source links of affected
   chapters, then follow changed callers, helpers, options and generated
   interfaces. NEWS is a useful lead, not a substitute for these reads.
3. Recheck the behavior at the boundary: return values of callbacks, which
   phase consumes a fact, context lifetime, configuration guards, default
   changes and model/proof consequences. Read the base class when an override
   disappears. A symbol rename alone cannot justify retaining the old prose.
4. Update the explanation and the bootcamp correction table where relevant.
   Preserve reasoning and examples that explain why an invariant matters.
   Add new source links for new claims. Label proposed designs, measured
   results and unverified hypotheses distinctly.
   Update affected [literature connections](references.md) alongside the code
   account: preserve stable citation keys, correct publication metadata and
   explain when the current implementation has diverged from a cited paper.
   Remove entries whose implementation connection no longer holds.
5. Advance this baseline and source links together **after** reviewing the
   affected account. For a deliberately partial update, record a separate
   explicit section baseline and adjust the checker before using mixed pins;
   do not make an old chapter look freshly verified by changing only its date.
6. Run the mechanical checks. Run relevant cvc5 examples/tests when claiming
   observed behavior and record their exact revision, build, options and
   outcome. Keep “read the implementation” separate from “executed the path.”
7. Update the relevant category index if chapters moved or were added, and
   the artifact's [chapter index](README.md#chapters) if categories changed.
   For theory work, preserve the common structure in
   [How to develop a theory](theory-development/README.md#the-structure-of-every-theory-sub-guide).
   Keep repository documentation indexed separately in `docs/`. Leave a
   concise change description for human review, naming behavioral corrections
   and any uncertainty that remains.

For AI maintenance, the durable handoff is these documents, their source pins,
and reproducible evidence, rather than a conversation's memory. An agent
should change the prose when the source contradicts it and keep unresolved
implementation questions explicit. A successful link check does not approve
an architectural claim, and no external issue or message is sent as part of
updating this guide.

## Where to deepen the next edition

All bootcamp sections have a walkthrough, and each theory now includes a
concrete starting input with source-reading stops. Further depth would be
useful in recorded traces from a build of this exact revision, individual
simplex/nonlinear algorithms, regexp procedures, specialized quantifier
strategies and complete proof reconstruction examples. Attach future runtime
evidence to the specific example and configuration, as above, rather than
advertising it as verification of the entire guide.

[source]: https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0
