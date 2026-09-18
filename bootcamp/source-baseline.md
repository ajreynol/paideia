# Source baseline and updating the guide

Upstream commit: `3dcc1ef5421ab62cc1ee9af52d70042ce6861af0`

Observed branch: upstream `cvc5/cvc5` `main`, read on **2026-09-18** with
`git ls-remote`. The [pinned source tree][source] calls itself **1.4.0 prerelease**
in NEWS. This is the first draft's baseline, not a promise that the live branch
will remain at that revision or that the draft has received upstream review.

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

This draft has **source inspection**, not runtime validation of all described
paths. cvc5 was not built and its test suite was not run to prepare the draft.
The snippets and commands are source-checked recipes or explicitly marked
illustrations. Algorithm explanations summarize the inspected implementation;
they are not completeness or correctness proofs.

## Mechanical checks

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

All bootcamp sections have an initial walkthrough. Further depth would be
useful in concrete end-to-end traces, individual simplex/nonlinear algorithms,
regexp procedures, specialized quantifier strategies and proof reconstruction
examples. Those are expansions of the current account, not topics silently
omitted from the bootcamp coverage. Future runtime evidence should be attached
to a specific example and configuration rather than advertised as verification
of the entire guide.

[source]: https://github.com/cvc5/cvc5/tree/3dcc1ef5421ab62cc1ee9af52d70042ce6861af0
