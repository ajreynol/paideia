#!/usr/bin/env python3
"""Read-only checks for the bootcamp artifact and repository documentation.

Checks local Markdown links/fragments, reference definitions, separate artifact
and documentation indexes, and cvc5 source-link pins. With --cvc5-source, also
checks source path existence. Generates and rewrites no files.
It does not fetch anything, authenticate an archive, or verify prose semantics.
Only the Markdown forms used by this guide are supported; this is not a renderer.
"""

import argparse
import re
from pathlib import Path
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
BOOTCAMP = ROOT / "bootcamp"
FENCES = re.compile(r"^(```|~~~)[^\n]*\n.*?^\1[^\n]*$", re.M | re.S)
DEFINITIONS = re.compile(r"^\[([^\]]+)\]:\s*(\S+)", re.M)
INLINE = re.compile(r"\[[^\]]*\]\(([^\s)]+)\)")
REFERENCES = re.compile(r"\[([^\]]+)\]\[([^\]]*)\]")
SOURCE = re.compile(r"/(?:blob|tree)/([^/]+)(?:/(.+))?")


def written_text(path):
    return FENCES.sub("", path.read_text(encoding="utf-8"))


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
        return ["source-baseline.md: missing full upstream commit"], 0, 0
    commit = match[1]
    errors = []
    local_targets = set()
    source_paths = set()
    index_targets = {DOCS / "README.md": set(), BOOTCAMP / "README.md": set()}
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
    for page in pages:
        index = BOOTCAMP / "README.md" if page.is_relative_to(BOOTCAMP) else DOCS / "README.md"
        if page != index and page not in index_targets[index]:
            errors.append(f"{page.relative_to(ROOT)}: missing from {index.relative_to(ROOT)}")
    return errors, len(local_targets), len(source_paths)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cvc5-source", type=Path,
                        help="extracted source or checkout at the documented baseline")
    args = parser.parse_args()
    if args.cvc5_source and not (args.cvc5_source / "src/theory/theory.cpp").is_file():
        parser.error("--cvc5-source must point to a cvc5 source root")
    errors, local_count, source_count = check(args.cvc5_source)
    if errors:
        for error in errors:
            print(error)
        return 1
    print(f"Guide checks passed: {local_count} local targets, "
          f"{source_count} pinned cvc5 paths.")
    if not args.cvc5_source:
        print("Source path existence not checked; pass --cvc5-source to check it.")
    print("Prose accuracy and source revision identity require separate review.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
