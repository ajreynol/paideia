# empeiria documentation

The [charter](../README.md) is this project's entry point and says what it is
for. These are the documents it routes to.

| document | what it is for |
| --- | --- |
| [triage.md](triage.md) | the open-issue index — every open cvc5 issue in one line, refreshed by `run_empeiria --triage`, and never citable as evidence |
| [TODO.md](TODO.md) | the plan — what is built, what comes next, and what is deliberately not being built |

The issues worked are in [`../ledger/`](../ledger/), which carries its own note.
The public command is `scripts/run_empeiria` at the root of this repository; it
execs the implementation, [`../empeiria.sh`](../empeiria.sh), which stays here
because a child project keeps its own.
