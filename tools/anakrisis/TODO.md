# anakrisis — the plan

One thing is built and the move broke it. This is the order the rest would go
in, so that a reader can tell what is intended from what exists.

**Before any of it.** `--delta` shells out to `python3 -m dokimasia report` and
looks for that module two directories above itself, which is now paideia rather
than dokimasia. Nothing below this line can be attempted until a person decides
how this project finds dokimasia from its new home. It is not listed as a task
because it is not this project's decision to take.

## First

- [x] **`run_anakrisis --delta`** — the computed half. Two runs of dokimasia's
  analyses, at the merge base and at the head, subtracted. About 2.5s on a cvc5
  checkout, no build, one detached worktree that is removed on any exit.
  **Built and run in dokimasia; it does not run from here.**
- [x] **Make the subtraction mean something.** The first version compared the
  two reports with `diff` and returned mostly line numbers moving and lists in
  an unstable order. It is now a set difference over lines with `:NNN`
  normalised away, which is the only reason the output is readable.
- [x] **[`review.md`](review.md)** — what a review may claim, the four labels,
  the block, and the sealed jar.
- [x] **`--baseline`** — the control arm: the same review with the delta
  withheld. The baseline for this task is
  [`check_cvc5_issue`](https://github.com/ajreynol/dokimasia/blob/main/prompts/check_cvc5_issue),
  which is prompt-based tooling with no instrument and already produces useful
  work, so what has to be shown is that the delta adds something rather than
  that an assistant can review a diff.
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

## Not yet

- **A machine format out of dokimasia.** The delta is a diff of prose because
  that is what dokimasia prints, and both of the limits in the
  [charter](README.md#the-two-limits-named-before-the-first-use) come from it.
  A structured output would fix them — and building one is dokimasia's
  decision, not this project's, taken when somebody asks for the thing the
  charter names as its wishue rather than because some other repository would
  like it. This entry used to be written down where dokimasia's maintainer
  would come across it. Since the move it is not, so asking is now a person's
  carry rather than something a reader stumbles on.
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
  and
  [`pr-policy.md`](https://github.com/ajreynol/dokimasia/blob/main/docs/pr-policy.md).
  The artifact is a file here.
