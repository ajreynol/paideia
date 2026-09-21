# ledger

One file per cvc5 pull request examined, *per arm*: `<number>.md` for the review
made with the inventory delta, and `<number>-baseline.md` for the control made
without it. Each carries an `arm:` field, so a pair cannot be mistaken for two
independent reviews. The shape is the one
[`../docs/review.md`](../docs/review.md) sets out; the header is written by
[`run_anakrisis`](../../../scripts/run_anakrisis) and the rest by whoever did the review.

Each holds the computed `DELTA:` for that change — or `withheld` in the control
arm — a `TRIAGE:` line carrying one of four labels, and `HUMAN RESPONSE:`,
filled afterwards by `run_anakrisis --record N` with what the maintainers
actually did.

**Two differences here are assets, and nothing else in these files is.** The
first is between `TRIAGE:` and `HUMAN RESPONSE:` — what was concluded against
what happened. The second is between the two arms on the same pull request,
which is the only evidence there will ever be that the computed delta adds
something to a review an assistant could have written without it. Both are only
legible because the review was sealed before the outcome was known, which is
what the sealed jar in `docs/review.md` is for.

**A review recorded here has been sent to nobody**, and nothing in this
directory is addressed to a contributor or to a maintainer of cvc5. A person
decides whether any of it goes anywhere; the rule is [dokimasia's
bar](https://github.com/ajreynol/dokimasia/blob/main/dokimasia_analyzer/README.md#the-bar),
which is in another repository, kept here by this project's own choice, and
unchanged.

*Empty. No pull request has been reviewed yet.*
