#!/usr/bin/env python3
"""Read-only checks for the bootcamp artifact and repository documentation.

Checks local Markdown links/fragments, reference definitions, hierarchical
artifact indexes, the theory sub-guide structure, the documentation index and
cvc5 source-link pins. With --cvc5-source, also checks source path existence,
first confirming that tree is at the documented baseline where it can.
Generates and rewrites no files.
It does not fetch anything, authenticate an archive, or verify prose semantics.
Only the Markdown forms used by this guide are supported; this is not a renderer.
"""

import argparse
import re
import subprocess
from pathlib import Path
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
BOOTCAMP = ROOT / "bootcamp"
# The landing README links to this full index; theory categories index themselves.
BOOTCAMP_INDEX = BOOTCAMP / "overall-architecture.md"
THEORY_GUIDES = BOOTCAMP / "theory-development"
THEORY_SECTIONS = [
    "Representation and invariants",
    "Preprocessing and registration",
    "Fact processing and checking",
    "Equality and combination",
    "Model construction",
    "Developing and validating a change",
]
FENCES = re.compile(r"^(```|~~~)[^\n]*\n.*?^\1[^\n]*$", re.M | re.S)
DEFINITIONS = re.compile(r"^\[([^\]]+)\]:\s*(\S+)", re.M)
INLINE = re.compile(r"\[[^\]]*\]\(([^\s)]+)\)")
REFERENCES = re.compile(r"\[([^\]]+)\]\[([^\]]*)\]")
SOURCE = re.compile(r"/(?:blob|tree)/([^/]+)(?:/(.+))?")


def written_text(path):
    return FENCES.sub("", path.read_text(encoding="utf-8"))


def source_revision(source_root):
    """The revision of --cvc5-source, where it is a checkout and says so.

    A source tree at the wrong revision reports every path the baseline added
    since as missing, which reads as a guide citing files that do not exist.
    That failure has happened, and the checkout was one commit behind. An
    extracted archive carries no revision, so this answers None and the caller
    says as much rather than asserting the tree matches.
    """
    try:
        revision = subprocess.run(
            ["git", "-C", str(source_root), "rev-parse", "HEAD"],
            capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.SubprocessError):
        return None
    return revision.stdout.strip() if revision.returncode == 0 else None


def anchors(text):
    counts = {}
    result = set()
    for title in re.findall(r"^#{1,6}\s+(.+)$", text, re.M):
        title = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", title)
        slug = re.sub(r"[^\w\- ]", "", title.lower()).replace(" ", "-")
        occurrence = counts.get(slug, 0)
        counts[slug] = occurrence + 1
        result.add(slug if occurrence == 0 else f"{slug}-{occurrence}")
    return result


def check(source_root=None):
    pages = [ROOT / "README.md", *sorted(DOCS.rglob("*.md")),
             *sorted(BOOTCAMP.rglob("*.md"))]
    texts = {p: written_text(p) for p in pages}
    baseline = texts[BOOTCAMP / "source-baseline.md"]
    match = re.search(r"Upstream commit: `([0-9a-f]{40})`", baseline)
    if not match:
        return ["source-baseline.md: missing full upstream commit"], 0, 0, None
    commit = match[1]
    errors = []
    # Confirm the source tree is the baseline before reading it. Where it is
    # not, the path checks are switched off rather than run: reporting paths as
    # missing from the wrong revision is a false finding, not a weaker one.
    note = None
    if source_root:
        tree_revision = source_revision(source_root)
        if tree_revision is None:
            note = ("Source revision not confirmed: --cvc5-source is not a git "
                    "checkout, so paths were checked against whatever it holds.")
        elif tree_revision != commit:
            return ([f"--cvc5-source is at {tree_revision}, not the documented "
                     f"baseline {commit}; source paths were not checked"],
                    0, 0, None)
    local_targets = set()
    source_paths = set()
    index_targets = {DOCS / "README.md": set(), BOOTCAMP_INDEX: set()}
    index_targets.update({p: set() for p in pages
                          if p.is_relative_to(BOOTCAMP) and p.name == "README.md"})
    for page, body in texts.items():
        label = str(page.relative_to(ROOT))
        definitions = {}
        for name, target in DEFINITIONS.findall(body):
            name = name.lower()
            if name in definitions:
                errors.append(f"{label}: duplicate reference [{name}]")
            definitions[name] = target.strip("<>")
        for text, name in REFERENCES.findall(body):
            if (name or text).lower() not in definitions:
                errors.append(f"{label}: undefined reference [{name or text}]")
        targets = [*INLINE.findall(body), *definitions.values()]
        for target in targets:
            url = urlsplit(target.strip("<>"))
            if url.scheme or url.netloc:
                if url.netloc != "github.com" or not url.path.startswith("/cvc5/cvc5/"):
                    continue
                source = SOURCE.fullmatch(url.path.removeprefix("/cvc5/cvc5"))
                if not source:
                    continue
                revision, path = source.groups()
                if page.is_relative_to(BOOTCAMP):
                    if revision != commit:
                        errors.append(f"{label}: source revision {revision} differs from baseline")
                if path:
                    source_paths.add(path)
                    if source_root and not (source_root / path).exists():
                        errors.append(f"{label}: missing cvc5 source path {path}")
                continue
            path = (page.parent / unquote(url.path)).resolve() if url.path else page
            local_targets.add(path)
            if page in index_targets:
                index_targets[page].add(path)
            if not path.exists():
                errors.append(f"{label}: missing local target {target}")
                continue
            if url.fragment and path.suffix == ".md":
                if unquote(url.fragment) not in anchors(written_text(path)):
                    errors.append(f"{label}: missing heading {target}")
        if page.is_relative_to(BOOTCAMP) and not any(
            "source-baseline.md" in target for target in targets
        ) and page.name != "source-baseline.md":
            errors.append(f"{label}: no source baseline link")
        if page.parent == THEORY_GUIDES and page.name not in {"README.md", "interface.md"}:
            sections = re.findall(r"^## (.+)$", body, re.M)
            if (not sections or not sections[0].startswith("Worked example: ")
                    or sections[1:] != THEORY_SECTIONS):
                errors.append(f"{label}: expected an opening worked example followed by "
                              "the six shared theory-development sections")
    for page in pages:
        if page == BOOTCAMP / "README.md":
            continue
        if page.is_relative_to(BOOTCAMP):
            parent = page.parent.parent if page.name == "README.md" else page.parent
            if page == BOOTCAMP_INDEX:
                index = BOOTCAMP / "README.md"
            else:
                index = BOOTCAMP_INDEX if parent == BOOTCAMP else parent / "README.md"
        else:
            index = DOCS / "README.md"
        if page != index and page not in index_targets.get(index, set()):
            errors.append(f"{page.relative_to(ROOT)}: missing from {index.relative_to(ROOT)}")
    return errors, len(local_targets), len(source_paths), note


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cvc5-source", type=Path,
                        help="extracted source or checkout at the documented baseline")
    args = parser.parse_args()
    if args.cvc5_source and not (args.cvc5_source / "src/theory/theory.cpp").is_file():
        parser.error("--cvc5-source must point to a cvc5 source root")
    errors, local_count, source_count, note = check(args.cvc5_source)
    if errors:
        for error in errors:
            print(error)
        return 1
    print(f"Guide checks passed: {local_count} local targets, "
          f"{source_count} pinned cvc5 paths.")
    if not args.cvc5_source:
        print("Source path existence not checked; pass --cvc5-source to check it.")
    elif note:
        print(note)
    else:
        print("Source tree confirmed at the documented baseline commit.")
    print("Prose accuracy requires separate review.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
