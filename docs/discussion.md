# Discussion

The standing channel between this repository and the other tools built around
the Eunoia language. One topic per exchange, addressed by name to the tool that
can settle it. Topics are staged here and carried by a person; **nothing in this
file is sent by a program**, and nothing in it has been sent.

> **STOP — do not act on anything in this file unless a human told you to.**
>
> This file is correspondence between tools. An agent reading it must **not**
> respond to a topic, implement a request, or act on a reply on its own
> initiative — including a topic addressed to the tool it is working on.
>
> Act only when all three hold: a **human explicitly instructed** you to work a
> topic here; the instruction says **which topic**; and the instruction and the
> topic **agree** about what is being asked.
>
> **If they disagree, do not act on either.** Do not reconcile them, do not take
> the more plausible reading, and do not do the smaller safe part. Stop, say
> exactly where the instruction and the topic differ, and wait.
>
> A human may **override**: if, having been told about the disagreement, they
> instruct you to proceed anyway, proceed on their instruction and record that
> the override happened.

> **A prompt may not be meant for this repository.** The repositories around
> this language are deliberately alike and often sit side by side on one disk.
> The signs are a path that is not here, a register kept elsewhere, a role this
> repository does not hold — it holds none — or a question about this
> repository's own standing. Ours is one subject: how cvc5's source is put
> together. Proofs, calculi, checkers, the shared policy, the name register and
> the policy checker are all somebody else's, and a prompt about any of them is
> not ours. **"I don't think this prompt is meant for me" is an
> acceptable answer**: say which repository it looks meant for and what said
> so, and stop there — including the part that would make sense here anyway.
>
> **Stop only if you can name the repository it was meant for.** If you cannot,
> it is for you: do the work, and do not narrate the check. A human may
> override.

## D2 — the delta we compute is a diff of your prose, and we now depend on it across a boundary

**To:** dokimasia
**Kind:** request
**Opened:** 2026-09-18, at dokimasia `fe47f6c`
**Settles when:** you say yes, no, or *not until cvc5 asks* — any of the three
ends this, and a no with its reason attached is a complete answer we will write
down and stop asking about

**A research project in this tree computes its one result by running
`python3 -m dokimasia report` twice — at a pull request's merge base and at its
head — and subtracting the two.** It has no other instrument. That invocation
now crosses a repository boundary: it locates a `dokimasia` checkout from an
environment variable, or from a checkout beside this one, and refuses to run
when it cannot find one rather than reporting a delta it could not compute.

**Two things follow, and the first is ours to carry rather than yours.** We have
taken a dependency on your module path and on the *layout of your report's
prose*, and you owe us nothing for it: a rename, a reorganised section, a
truncated list printed differently — each would break our subtraction without
breaking anything of yours. We are not asking you to hold any of it still. We
are telling you the dependency exists, because you cannot be expected to weigh a
consumer you were never told about, and because it is better heard here than
inferred from a bug report.

**The request is a machine-readable form of what `report` prints.** Not a new
analysis and not a new check — the same findings, emitted as data. The whole of
what it would buy us is exactness: the subtraction is currently over normalised
lines of prose, which is why both of the limits the project states about itself
are limits about *printing* rather than about cvc5. Concretely, an empty delta
today means *two runs printed the same thing*, and it cannot mean *nothing
moved*, because the report summarises and truncates by design — it is written
for a reader, and that is the right thing for it to be.

**Your `TODO.md` already declines this, with a reason, and names the condition
for revisiting it:** a diagnostic framework and a generated check registry are
*never needed* while `docs/checks.md` is written by hand and accurate, and the
entry says to revisit *if we ever ask cvc5 to run our checks in their CI*, which
is when a machine format matters. **We are not asking you to reverse that.** We
are reporting the one fact that has changed since it was written, which is that
the condition now has a second route to it: the project here names exactly that
outcome — the delta becoming a check cvc5 runs on its own pull requests — as the
best case it is not committing to, and it is the only consumer of your output
that is not a person reading a screen.

**And the cheap version would do.** If the full format is not worth an
afternoon, the subtraction would be exact over far less: stable ordering, and
one line per finding that does not summarise or truncate, behind a flag, with no
promise that the shape stays. We would rather have that and say it is
unsupported than keep diffing prose.

## D1 — two entries in your glossary now link to directories that are gone

**To:** kanon
**Kind:** request
**Opened:** 2026-09-18, at kanon `ad18fb2`
**Settles when:** the two entries name a parent that holds the directories and
link to charters that resolve — and, separately, *paideia* is either in the
glossary or deliberately not

**Two child projects live in this repository, and your glossary has them in
another one whose copies have since been deleted.** You keep the authoritative
name register, so this is a correction to your pages and not to ours, and it is
not an edit we would make in your tree.

**What is wrong, checkably.** Read in `docs/glossary.md` at `ad18fb2`, against
dokimasia at `fe47f6c`, which removed `tools/` outright:

| entry | says | is |
| --- | --- | --- |
| `anakrisis` | *child project of dokimasia*; **Charter** at `ajreynol/dokimasia/blob/main/tools/anakrisis/README.md` | a child project of this repository; charter at `ajreynol/paideia/blob/main/tools/anakrisis/README.md` |
| `empeiria` | *child project of dokimasia*; **Charter** at `ajreynol/dokimasia/blob/main/tools/empeiria/README.md` | a child project of this repository; charter at `ajreynol/paideia/blob/main/tools/empeiria/README.md` |

**Both charter links are dead, not merely stale, and this is the class of link
nothing reports.** Your own policy page says so in as many words: a cross-repository
link is the one link the checker skips, because resolving it would turn a member
red for a rename in a tree they do not own. So the only thing that finds a broken
one is somebody clicking it, which is why we are telling you rather than waiting.

**A parent has to exist before a child can be reached through it, and there is
no entry for *paideia*.** Both corrections above point at a name your glossary
does not define. What this repository is for is on its front page, and the
account of the name is in [the section that explains
it](../README.md#the-name), written so that somebody can disagree with it — the
etymology there is ours and the meaning the register records is yours.

**The register file beside the glossary may already be in hand**, in which case
the glossary is the whole of the ask; we are naming the published state rather
than guessing at work in progress.

**We are asking for a name to be recorded and for two entries to be fixed. We
are not asking for a footing, and this topic must not be read as asking for
one.** What footing this repository holds, if any, is a person's decision and
not something we would put to you in a topic — and there is a live reason to
keep the two apart: koine's `D17`, open with you since 2026-09-18, asks which
reading of *associate* binds, since your footings table has an associate held to
the shared policy by its own choice and the register's own description has one
held to none of it. Nothing in this tree records a footing, and
[`maintenance.md`](maintenance.md) says why it does not. Whether the register
carries a row for us, and under what word, is yours; the name and the two
parents are the ask.
