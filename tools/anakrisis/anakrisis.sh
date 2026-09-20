#!/usr/bin/env bash
# anakrisis.sh -- review a cvc5 pull request, from inside a cvc5 checkout.
# Run it as `run_anakrisis`: the public command is scripts/run_anakrisis at the
# root of this repository, which execs this file. The implementation lives here
# because a child project keeps its own -- kanon's docs/policy.md.
#
#   cd ~/cvc5 && gh pr checkout 12893 && run_anakrisis 12893
#
# The job is one question: what does this change do to the inventory of ways
# cvc5 can produce no proof? That half is computed rather than judged --
# dokimasia's analyzer is run at the merge base and at the head, and the two
# dumps are subtracted over observation ids -- and an assistant reads a delta it
# did not produce. See docs/review.md.
#
# dokimasia is another repository. Set DOKIMASIA_ROOT, or keep a checkout of it
# beside this one; this refuses to run rather than guessing further.
#
#   run_anakrisis 12893 --delta         the inventory delta alone; no assistant
#   run_anakrisis 12893                 the delta, then a review by an assistant
#   run_anakrisis 12893 --baseline      the same review with no delta -- the control
#   run_anakrisis 12893 --show-prompt   print the prompt, run no assistant
#   run_anakrisis --record 12893        afterwards: what the maintainers did
#   run_anakrisis --list                what has been reviewed, and what came back
#
# The baseline for this task already exists. Prompt-based tooling that hands an
# assistant a prompt and a checkout gets useful work out of the arrangement with
# no instrument at all, and that is what this has to beat -- not "no review".
# README.md says where that is established.
# So --baseline runs the same review with the delta withheld: the two prompts
# differ by the delta and by nothing else, which is what makes the comparison a
# measurement rather than an impression.
#
# It makes no network calls: it reviews whatever is checked out, and prints the
# fetch command rather than running it. Nothing is pushed, nothing is posted, no
# review is submitted and no pull request is approved -- ever. The governing
# document is the bar in dokimasia's dokimasia_analyzer/README.md, kept here by this
# project's own choice now that dokimasia is not its parent, and unchanged.

set -euo pipefail

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
LEDGER="$HERE/ledger"

# Where dokimasia is. The delta is two runs of *its* analyzer and the review is
# scoped to *its* documents, and neither is in this repository, so this cannot be
# derived from the script's own location: DOKIMASIA_ROOT answers it if it is set,
# and otherwise a checkout beside this repository, which is how these trees are
# usually laid out. Nothing here guesses further and nothing here fetches.
DOKI="${DOKIMASIA_ROOT:-}"
if [ -z "$DOKI" ] && [ -d "$HERE/../../../dokimasia" ]; then
  DOKI=$(CDPATH= cd -- "$HERE/../../../dokimasia" && pwd)
fi

# Fail closed, before anything runs and before a prompt is built. Empty output
# is how this script spells "nothing changed", so a dokimasia that is absent or
# is not the one this expects has to stop the run rather than shorten it -- and
# the prompt hands an assistant three of these paths by name, so a path that
# does not exist is a review scoped to nothing.
require_doki() {
  if [ -z "$DOKI" ] || [ ! -d "$DOKI" ]; then
    echo "run_anakrisis: no dokimasia checkout found, so there is no delta to" >&2
    echo "               compute. That repository is not this one:" >&2
    echo >&2
    echo "                   DOKIMASIA_ROOT=/path/to/dokimasia run_anakrisis $PR" >&2
    echo >&2
    echo "               or keep a 'dokimasia' checkout beside this repository." >&2
    exit 2
  fi
  missing=""
  for rel in scripts/dokimasia_analyzer docs/README.md dokimasia_analyzer/README.md; do
    [ -e "$DOKI/$rel" ] || missing="$missing $rel"
  done
  if [ -n "$missing" ]; then
    echo "run_anakrisis: $DOKI does not look like a dokimasia checkout." >&2
    echo "               missing:$missing" >&2
    echo "               The first is the command the delta runs; the others are" >&2
    echo "               the documents the read half is scoped to, and the prompt" >&2
    echo "               names every one of them by path." >&2
    exit 2
  fi
}

# A response lives on the lines *after* the marker, not on it -- the same bug
# the sibling project here hit, and the same fix.
has_response() {
  awk '/^HUMAN RESPONSE:/ { seen = 1; next }
       seen && NF { found = 1 }
       END { exit(found ? 0 : 1) }' "$1"
}

AGENT=claude
PR=""
MODE=review
PRINT=0
SHOW=0
FORCE=0
BASELINE=0
BASEREF=""

usage() {
  cat >&2 <<'USAGE'
usage: run_anakrisis [--pr] N [--delta] [--baseline] [--codex] [--base REF]
                            [--print] [--show-prompt] [--force]
       run_anakrisis --record N
       run_anakrisis --list

  --pr N          the cvc5 pull request checked out here; a bare N is shorthand
  --delta         print the inventory delta and stop; runs no assistant
  --baseline      review with the delta withheld -- the control arm, and what
                  the prompt-based tooling here already gives you
  --base REF      what to take the merge base against (default: origin/main)
  --record N      record what the maintainers did, after the fact
  --list          what has been reviewed, and what came back
  --codex         run codex instead of claude
  --print         run non-interactively and print the result
  --show-prompt   print the prompt and exit; computes the delta, because the
                  delta is in the prompt, and runs no assistant
  --force         proceed even though the working tree is dirty

Run it in the root of a cvc5 checkout, with the pull request already checked
out. Fetching it is a network call and is yours: `gh pr checkout N`.
USAGE
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --pr) [ -z "$PR" ] || { echo "run_anakrisis: one pull request at a time" >&2; usage; }
          PR="${2:-}"; [ -n "$PR" ] || usage; shift 2 ;;
    --delta) MODE=delta; shift ;;
    --baseline) BASELINE=1; shift ;;
    --record) MODE=record; PR="${2:-}"; [ -n "$PR" ] || usage; shift 2 ;;
    --list) MODE=list; shift ;;
    --base) BASEREF="${2:-}"; [ -n "$BASEREF" ] || usage; shift 2 ;;
    --codex) AGENT=codex; shift ;;
    --claude) AGENT=claude; shift ;;
    --print) PRINT=1; shift ;;
    --show-prompt) SHOW=1; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage ;;
    -*) echo "run_anakrisis: unexpected option $1" >&2; usage ;;
    *) [ -z "$PR" ] || { echo "run_anakrisis: one pull request at a time" >&2; usage; }
       PR="$1"; shift ;;
  esac
done

# --- list needs nothing else -------------------------------------------------
if [ "$MODE" = list ]; then
  found=0
  for f in "$LEDGER"/*.md; do
    [ -e "$f" ] || continue
    n=$(basename "$f" .md)
    # ledger/README.md is not a PR; <N>-baseline.md is the control arm
    case "$n" in ''|*[!0-9]*) case "$n" in *-baseline) ;; *) continue ;; esac ;; esac
    if [ "$found" = 0 ]; then
      printf '%-10s %-24s %s\n' "pr" "triage" "reviewed"
      found=1
    fi
    state=$(sed -n 's/^TRIAGE:[[:space:]]*\([a-z ]*\).*/\1/p' "$f" | head -1)
    when=$(sed -n 's/^reviewed: *//p' "$f" | head -1)
    if has_response "$f"; then state="${state:-?} +response"; fi
    printf '%-10s %-24s %s\n' "#$n" "${state:-?}" "${when:-?}"
  done
  [ "$found" = 1 ] || echo "nothing reviewed yet; the ledger at $LEDGER is empty"
  exit 0
fi

case "$PR" in ''|*[!0-9]*)
  echo "run_anakrisis: give a pull request number, e.g. run_anakrisis 12893" >&2
  usage ;;
esac

# --- must be cvc5 ------------------------------------------------------------
if ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo "run_anakrisis: not in a git repository." >&2
  echo "               Run this in the root of a cvc5 checkout." >&2
  exit 2
fi
is_cvc5=0
case "$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)" in
  *cvc5/cvc5*|*cvc5.git*|*/cvc5) is_cvc5=1 ;;
esac
if [ "$is_cvc5" = 0 ] && [ -f "$ROOT/configure.sh" ] && [ -d "$ROOT/src/theory" ]; then
  is_cvc5=1
fi
if [ "$is_cvc5" = 0 ]; then
  echo "run_anakrisis: $ROOT does not look like a cvc5 checkout." >&2
  echo "               Expected a cvc5 origin remote, or configure.sh and src/theory/." >&2
  exit 2
fi

# --- record: after the fact --------------------------------------------------
ARM=delta; ENTRY="$PR"
if [ "$BASELINE" = 1 ]; then ARM=baseline; ENTRY="$PR-baseline"; fi

if [ "$MODE" = record ]; then
  f="$LEDGER/$ENTRY.md"
  if [ ! -f "$f" ]; then
    echo "run_anakrisis: no ledger entry for #$PR; review it first" >&2
    exit 2
  fi
  if has_response "$f"; then
    echo "run_anakrisis: #$PR already has a response recorded." >&2
    echo "               Edit $f by hand if it needs correcting." >&2
    exit 2
  fi
  echo "-- run_anakrisis: recording what the maintainers did with #$PR" >&2
  echo "   Paste what they actually did, then Ctrl-D." >&2
  echo "   Their words, not a summary: the delta between our review and the" >&2
  echo "   outcome is the only thing in the ledger that is an asset." >&2
  resp=$(cat)
  [ -n "$resp" ] || { echo "run_anakrisis: nothing read; leaving $f alone" >&2; exit 2; }
  tmp=$(mktemp)
  awk -v r="$resp" '
    /^HUMAN RESPONSE:/ { print; print ""; print r; next } { print }' "$f" > "$tmp"
  mv "$tmp" "$f"
  echo "   recorded in $f" >&2
  exit 0
fi

# Everything past here either computes the delta or builds the prompt, and both
# need dokimasia. --list and --record above do not, and still work without it.
require_doki

# --- what are we comparing against? -----------------------------------------
if [ -z "$BASEREF" ]; then
  if git -C "$ROOT" rev-parse --verify --quiet origin/main >/dev/null; then
    BASEREF=origin/main
  elif git -C "$ROOT" rev-parse --verify --quiet main >/dev/null; then
    BASEREF=main
  else
    echo "run_anakrisis: no origin/main or main here; pass --base REF" >&2
    exit 2
  fi
fi
if ! BASE=$(git -C "$ROOT" merge-base HEAD "$BASEREF" 2>/dev/null); then
  echo "run_anakrisis: no merge base between HEAD and $BASEREF" >&2
  exit 2
fi
HEADSHA=$(git -C "$ROOT" rev-parse HEAD)
if [ "$BASE" = "$HEADSHA" ]; then
  echo "run_anakrisis: HEAD is $BASEREF, so there is no change to examine." >&2
  echo "               Check the pull request out first -- that is a network" >&2
  echo "               call and it is yours to make:" >&2
  echo >&2
  echo "                   gh pr checkout $PR" >&2
  exit 2
fi
if [ "$FORCE" = 0 ] && [ -n "$(git -C "$ROOT" status --porcelain)" ]; then
  echo "run_anakrisis: $ROOT has uncommitted changes." >&2
  echo "               The block records a head sha, so the tree it names has" >&2
  echo "               to be the tree that was read. --force proceeds anyway." >&2
  exit 2
fi

# --- the delta ---------------------------------------------------------------
BASESUB=$(git -C "$ROOT" log -1 --format='%h %s' "$BASE")
HEADSUB=$(git -C "$ROOT" log -1 --format='%h %s' "$HEADSHA")
PROV=""                          # the control arm computes none, on purpose

if [ "$BASELINE" = 1 ]; then
  if [ "$MODE" = delta ]; then
    echo "run_anakrisis: --baseline withholds the delta and --delta asks for" >&2
    echo "               nothing else, so the two together ask for nothing." >&2
    exit 2
  fi
  # The control arm computes nothing, on purpose.
  DELTA="withheld -- this is the control arm."
else

# One extra worktree, at the merge base. The tree you are on is read where it
# is: nothing is checked out over your work, and the worktree goes away on any
# exit, including a failure.
WT=$(mktemp -d)
cleanup() {
  git -C "$ROOT" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"
  git -C "$ROOT" worktree prune >/dev/null 2>&1 || true
}
trap cleanup EXIT

rmdir "$WT"                       # git wants to create it itself
git -C "$ROOT" worktree add --detach --quiet "$WT" "$BASE"

DUMPS=$(mktemp -d)
trap 'cleanup; rm -rf "$DUMPS"' EXIT

# Two runs of dokimasia's analyzer, writing dumps rather than prose. --no-update
# touches no database, so this needs no Koine checkout and mutates nothing of
# theirs. The banner each run prints is provenance, so it goes to stderr rather
# than into the delta.
"$DOKI/scripts/dokimasia_analyzer" --cvc5 "$WT"   --no-update --dump "$DUMPS/base.json" >&2
"$DOKI/scripts/dokimasia_analyzer" --cvc5 "$ROOT" --no-update --dump "$DUMPS/head.json" >&2

# The comparability check, before the subtraction and separately from it. Two
# runs are subtractable only if they selected the same analyses and each covered
# its whole scope; without that, a record present in one and absent from the
# other says nothing about cvc5. This refuses rather than qualifying, because a
# qualified delta is one somebody reads the first line of.
PROV=$(python3 - "$DUMPS/base.json.run.json" "$DUMPS/head.json.run.json" 2>&1 <<'PY'
import json
import sys

base, head = (json.load(open(p, encoding="utf-8")) for p in sys.argv[1:3])

if base.get("analyses") != head.get("analyses"):
    sys.exit("the two runs selected different analyses:\n"
             f"  base {base.get('analyses')}\n  head {head.get('analyses')}")
incomplete = [n for n, r in (("base", base), ("head", head)) if not r.get("complete")]
if incomplete:
    sys.exit(f"{' and '.join(incomplete)} did not cover the whole declared scope "
             "(`complete` is false), so the difference is over a partial catalogue")
if base.get("analyzer_sha256") != head.get("analyzer_sha256"):
    sys.exit("the two runs were produced by different analyzer implementations")


def digest(run):
    return [t.get("input_sha256") for t in run.get("targets", ())]


print("analyses  " + ", ".join(base.get("analyses", ())))
print("analyzer  " + (base.get("analyzer_commit") or "?")[:12]
      + (", dirty" if base.get("analyzer_dirty") else "")
      + f", implementation {(base.get('analyzer_sha256') or '?')[:12]}")
if digest(base) == digest(head):
    print("input     identical at both commits -- nothing this analyzer reads "
          "changed, so an empty delta below is the only possible result")
PY
) || {
  echo "run_anakrisis: the two runs are not subtractable." >&2
  printf '               %s\n' "$PROV" >&2
  exit 3
}

DELTA=$(python3 - "$DUMPS/base.json" "$DUMPS/head.json" <<'PY'
"""The subtraction, as a set difference over observation ids.

Every record in a dump carries `id`, which dokimasia computes from
`[owner, code, entity]` and from nothing else -- no revision, no line number
and no wording -- so the same finding at the merge base and at the head has the
same id. The difference of the two id sets is therefore exact: not a diff, not
normalised prose, and not sensitive to how anything is printed.

What it is *not* is a rename tracker. A renamed entity is a new id, so it reads
as one removal and one addition rather than as a move, and the pair is only
visible to somebody who looks at it.
"""
import json
import sys


def load(path):
    return {r["id"]: r for r in json.load(open(path, encoding="utf-8"))}


base, head = (load(p) for p in sys.argv[1:3])
gone = [base[i] for i in base if i not in head]
new = [head[i] for i in head if i not in base]
if not gone and not new:
    sys.exit(0)


def line(sign, r):
    text = f"  {sign} {r.get('entity') or r.get('bug') or r['id']}"
    description = (r.get("description") or "").strip()
    return f"{text} -- {description}" if description else text


codes = []
for r in gone + new:
    if r.get("code") not in codes:
        codes.append(r.get("code"))
for code in sorted(codes, key=str):
    print(f"== {code}")
    for r in sorted(gone, key=lambda r: str(r.get("entity"))):
        if r.get("code") == code:
            print(line("-", r))
    for r in sorted(new, key=lambda r: str(r.get("entity"))):
        if r.get("code") == code:
            print(line("+", r))
    print()
print(f"{len(gone)} observation(s) gone, {len(new)} new, "
      f"across {len(codes)} code(s).")
PY
) || {
  # Never `|| true` here. A crash in the subtraction exits with no output, and
  # empty output is how this script spells "nothing changed" -- so swallowing
  # the failure would report a broken run as a clean one, which is the exact
  # mistake this repository exists to object to.
  echo "run_anakrisis: the subtraction failed; no delta was computed." >&2
  exit 3
}

if [ -z "$DELTA" ]; then
  DELTA="none -- no observation appeared or disappeared at the declared scope."
fi

fi

print_delta() {
  echo "-- anakrisis: what #$PR does to the inventory  [arm: $ARM]"
  echo "   base   $BASESUB"
  echo "   head   $HEADSUB"
  if [ "$BASELINE" = 1 ]; then
    echo
    printf '%s\n' "$DELTA"
    echo
    return
  fi
  echo "   how    dokimasia_analyzer --no-update --dump, run at both;"
  echo "          set difference over observation ids"
  printf '%s\n' "$PROV" | sed 's/^/   /'
  echo
  printf '%s\n' "$DELTA"
  echo
  echo "   An empty delta is not a clean bill of health. It means no observation"
  echo "   appeared or disappeared at the declared scope -- and the scope is the"
  echo "   nine observation-producing analyses, not the measurements beside them."
  echo "   A renamed entity reads as one removal and one addition. It is also"
  echo "   static -- no build, no run. See $HERE/README.md, 'What an empty delta does not mean'."
}

if [ "$MODE" = delta ]; then
  print_delta
  exit 0
fi

if [ "$BASELINE" = 1 ]; then
  PREAMBLE="**No inventory delta was computed for this run, and that is deliberate.** This
is the control arm. It exists so that a review made *with* a delta can be
compared against one made without, on the same change -- so review on the
merits, and do not try to reconstruct what a delta would have said."
  STEP1="1. **Read the diff.** \`git diff $BASE...$HEADSHA\` is the change."
else
  PREAMBLE="**Half of the review is already done and you did not do it.** The inventory
delta below was computed by running dokimasia's analyzer at the merge base and
at the head of this branch and subtracting the two dumps over observation ids.
Do not recompute it, do not second-guess the numbers, and quote it into the
block verbatim."
  STEP1="1. **Attribute each delta line to the diff.** \`git diff $BASE...$HEADSHA\` is
   the change. For each line above, find the hunk that produced it and say so.
   A delta line has four possible readings and they are not equally likely: the
   change caused it, it is one half of a rename whose other half is the opposite
   sign in the same block, something unrelated in the range caused it, or
   dokimasia is wrong. Check the rename reading first, because the subtraction
   cannot see one: a \`-\` and a \`+\` under the same code with entity names that
   differ only in spelling are one moved thing, not two. If you cannot attribute
   a line, say that -- an unattributed line stays in the review as unattributed,
   and guessing is worse than either."
fi

read -r -d '' PROMPT <<PROMPT_END || true
You are reviewing a pull request to cvc5, in a cvc5 checkout at $ROOT. You are
running out of a research project in the paideia repository, whose subject is
one question and not code review in general: can a path through the solver
produce no proof at all? The analyses the delta comes from, and the documents
named below, are dokimasia's, in a separate checkout at $DOKI.

The pull request:

  https://github.com/cvc5/cvc5/pull/$PR

**Read $HERE/docs/review.md before you start.** It says what a review may claim, what
it may not be about, the shape you write it in, and what the four triage labels
mean. It governs; this prompt only sets up the work.

$PREAMBLE

$(print_delta)

Your half, in this order:

$STEP1
2. **Read the diff for what this repository has evidence about**, and nothing
   else. The list is the proof-hygiene rules and the contract, both sections
   of $DOKI/docs/README.md. Style, naming, performance and
   architecture are out of scope and stay out even when you can see something.
   cvc5's own reviewers do that better and this project has no standing to.
3. **Decide the label.** "nothing to say" is the commonest correct answer and a
   complete one: most pull requests to this project do not touch proof
   production. Choose it when the delta is empty and the diff touches nothing on
   the list. Do not manufacture a point in order to have written a review.
4. **Hold anything about behaviour to having been run.** The project this
   instrument is borrowed from has been confidently wrong three times in one
   sitting with static arguments that read correctly -- $DOKI/docs/README.md
   records all three, and the bar is in $DOKI/dokimasia_analyzer/README.md.
   If you claim
   this change makes something happen, say what you ran. If you ran nothing, say
   that instead; it is a weaker claim honestly labelled rather than a stronger
   one you cannot support.

Constraints, none of them negotiable:

- **Post nothing.** No review, no comment, no approval, no request for changes,
  no reaction, no push, no tracker call of any kind. This is not a review that
  gets submitted -- it is a file a person reads and decides about. Approval to
  write one is not approval to send one.
- **Change no file in this cvc5 checkout.** You are reading it. If you build or
  run something, clean up after yourself.
- **Do not write anything addressed to the contributor.** Not a draft, not a
  suggested wording. A file that reads as a message is a file somebody will
  paste.
- Write only inside $LEDGER.

Write the review to:

  $LEDGER/$ENTRY.md

Use the shape review.md sets out, starting from the header that is already in
that file, and leave HUMAN RESPONSE empty -- it is the maintainer's, and keeping
the two apart is what makes the pair worth anything later.

**Finish by asking what to do next.** Say what you found, what you could not
attribute, and what you would want to run. The second turn is usually where the
work gets done.
PROMPT_END

if [ "$SHOW" = 1 ]; then printf '%s\n' "$PROMPT"; exit 0; fi

command -v "$AGENT" >/dev/null 2>&1 || {
  echo "run_anakrisis: $AGENT is not on PATH" >&2; exit 127; }

mkdir -p "$LEDGER"
if [ ! -f "$LEDGER/$ENTRY.md" ]; then
  cat > "$LEDGER/$ENTRY.md" <<HEADER
# PR #$PR -- <title>

reviewed: $(date +%Y-%m-%d)
arm:      $ARM
base:     $BASE
head:     $HEADSHA

DELTA:
$(printf '%s\n' "$DELTA" | sed 's/^/  /')

TRIAGE:

HUMAN RESPONSE:
HEADER
fi

echo "-- run_anakrisis: cvc5 pull request #$PR" >&2
echo "   tree    $ROOT" >&2
echo "   base    $BASESUB" >&2
echo "   head    $HEADSUB" >&2
echo "   ledger  $LEDGER/$ENTRY.md   (arm: $ARM)" >&2
echo "   agent   $AGENT -- nothing is posted, nothing is pushed, no review is submitted" >&2
echo >&2
echo "   Reviewing whatever is checked out here. That it is #$PR is your word:" >&2
echo "   this makes no network call and cannot check it." >&2

if [ "$AGENT" = codex ]; then
  if [ "$PRINT" = 1 ]; then exec codex exec "$PROMPT"; else exec codex "$PROMPT"; fi
else
  if [ "$PRINT" = 1 ]; then exec claude -p "$PROMPT"; else exec claude "$PROMPT"; fi
fi
