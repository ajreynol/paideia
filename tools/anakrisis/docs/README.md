# anakrisis documentation

The [charter](../README.md) is this project's entry point and says what it is
for. These are the documents it routes to.

| document | what it is for |
| --- | --- |
| [review.md](review.md) | the review protocol — what a review may claim, the block it is written in, the four labels, and what *nothing to say* means |
| [TODO.md](TODO.md) | the plan — what is built, what comes next, and what is deliberately not being built |

The reviews themselves are in [`../ledger/`](../ledger/), which carries its own
note. The public command is `scripts/run_anakrisis` at the root of this
repository; it execs the implementation, [`../anakrisis.sh`](../anakrisis.sh),
which stays here because a child project keeps its own.
