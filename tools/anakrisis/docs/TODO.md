# anakrisis — the plan

One thing is built and nothing it was built to produce is. This is the order the
rest would go in, so that a reader can tell what is intended from what exists.

**What every task below needs.** `--delta` shells out to
`scripts/dokimasia_analyzer`, which is in another repository: `DOKIMASIA_ROOT`,
or a `dokimasia` checkout beside this one. The command refuses to run without it
rather than reporting a delta it could not compute, so nothing here silently
proceeds on a missing instrument.

## First

- [x] **`run_anakrisis --delta`** — the computed half. Two runs of dokimasia's
  analyzer, at the merge base and at the head, subtracted. About 2s on a cvc5
  checkout, no build, one detached worktree that is removed on any exit.
- [x] **Make the subtraction mean something.** The first version compared the
  two reports with `diff` and returned mostly line numbers moving and lists in
  an unstable order; the second was a set difference over lines with `:NNN`
  normalised away, which made the output readable and left it a diff of prose.
- [x] **Make the subtraction exact.** It is now a set difference over the
  observation ids in dokimasia's dump, which carry no revision, no line number
  and no wording, so the same finding at both commits compares equal. What the
  two runs are checked for before subtracting — same analyses, both complete,
  same analyzer — is in the script beside the subtraction. Run on 2026-09-19
  over two cvc5 commits two hundred apart: 6 gone, 17 new, 7 codes, about two
  seconds.
- [x] **[`review.md`](review.md)** — what a review may claim, the four labels,
  the block, and the sealed jar.
- [x] **`--baseline`** — the control arm: the same review with the delta
  withheld. The baseline for this task is prompt-based tooling with no
  instrument, which already produces useful work, so what has to be shown is
  that the delta adds something rather than that an assistant can review a diff.
  The [charter](../README.md#the-charter) says where that is established now that
  dokimasia has retired the launcher it was established with.
- [ ] **Review one real pull request end to end, in both arms.** Nothing about
  the format above has met a change somebody actually proposed, and a protocol
  designed before its first case is wrong in ways no amount of thinking finds.
  Run both arms on it: one review with no control is an anecdote about an
  assistant, not evidence about a delta.
- [ ] **Then throw the format away and write it again.** Not *revise* — the
  first one is a guess and should be treated as one.
- [ ] **Decide what an unattributable delta line costs.** Today the review
  keeps it and says so. If most lines turn out to be unattributable, the delta
  is noise with a good story and this project should say so rather than tune
  the presentation.

## Then

- [ ] Enough cases to answer the charter's third goal: which review lines were
      acted on, which were noise, and what distinguished them.
- [ ] A held-out set of merged pull requests, picked before any measurement, so
      that *is a review wanted* can be answered against changes nobody chose
      with the answer in mind.
- [ ] **Say whether the empty delta can be trusted.** It is the commonest output
      and the least examined one. The honest test is to run the delta over a set
      of merged changes that *did* touch proof production and count how many it
      was silent about.

## The stretch: a check cvc5 could run itself

**The [wishue](../README.md#the-charter), broken into work somebody could
finish.** None of it is proposed to cvc5, and none of it is gated on cvc5
answering anything — what is gated is the *asking*, which waits on the three
goals above and travels through [dokimasia's
`R11`](https://github.com/ajreynol/dokimasia/blob/main/docs/README.md#open--asks)
rather than a channel of ours. Building the artifact first is the cheap order:
an ask with a working workflow attached costs a maintainer a read instead of a
design conversation.

- [ ] **A machine format for the delta.** Today `--delta` prints prose for a
      person. A check needs SARIF, or GitHub annotations, and the ids are
      already structured — this is a formatter, not an analysis.
- [ ] **Attribution to a hunk.** An annotation has to land on a file and a line,
      and today attributing a delta line to the diff is [the reader's first
      job](review.md). Any line that cannot be attributed automatically is
      reported without a location or not at all; guessing a location is worse
      than having none.
- [ ] **Decide which codes are worth annotating**, and say why the rest are not.
      Additions only, to begin with: a `-` line is where [the rename
      shape](../README.md#what-an-empty-delta-does-not-mean) lives, and the
      first impression a check makes is the only one it gets.
- [ ] **A workflow file, kept here as a proposal.** It runs the analyzer at the
      merge base and at the head and posts nothing — advisory, non-blocking,
      and never a comment on somebody's pull request. **It is never run from
      this side against cvc5's queue**; it is written so that cvc5 could adopt
      it, in the shape cvc5 already uses for its own static analysis.
- [ ] **Say what it would have said.** Run it over pull requests that already
      merged and write up the output beside what the reviewers did. That is
      the evidence the ask needs, and it is the same evidence goal 3 needs, so
      it costs nothing extra to collect.

## Not yet

- **Teaching the subtraction about renames.** A renamed entity reads as one
  removal and one addition, which is the third limit in the
  [charter](../README.md#what-an-empty-delta-does-not-mean). Pairing them
  automatically means guessing that two ids are one thing, and a wrong guess is
  worse than the shape a reader can see: the review prompt names the reading
  and a person makes it. Revisit if a real pull request shows the shape often
  enough to be noise.
- **An index of open pull requests.** The sibling project here keeps one for
  issues and it earns its place, because picking which issue to work is the
  hard part. Picking which pull request to examine is not: run the delta on the
  one you were going to review anyway — it costs two seconds — and let it tell
  you whether there is anything to say. An index would be a second thing to
  keep true for no gain.
- **Sweeping every open pull request.** It needs each one fetched, which is a
  network call, and it would produce a queue of reviews nobody asked for. If
  the wishue ever lands, cvc5's own CI is where a sweep belongs.
- **Anything that posts.** No comment, no review, no approval — see the charter
  and [the
  bar](https://github.com/ajreynol/dokimasia/blob/main/dokimasia_analyzer/README.md#the-bar).
  The artifact is a file here.
