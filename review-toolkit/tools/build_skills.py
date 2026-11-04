#!/usr/bin/env python3
"""Deterministic generation of installed skills from ONE canonical shared-policy tree.

Run from any directory: python3 skillsmd/tools/build_skills.py [--check]
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MARKER = re.compile(r"\{\{shared:([0-9a-z-]+)\}\}")
SKILLS = ("review-code", "review-pr")


def generated_skills(root: Path = ROOT) -> dict[str, bytes]:
    shared_root = root / "src" / "shared"
    files = {p.stem: p.read_text(encoding="utf-8").rstrip() for p in sorted(shared_root.glob("*.md"))}
    result: dict[str, bytes] = {}
    for skill in SKILLS:
        template = (root / "src" / f"{skill}.md").read_text(encoding="utf-8")
        def expand(match: re.Match[str]) -> str:
            name = match.group(1)
            if name not in files:
                raise ValueError(f"Unknown shared policy {{{{shared:{name}}}}} in {skill}")
            return files[name]
        compiled = MARKER.sub(expand, template).rstrip() + "\n"
        if MARKER.search(compiled):
            raise ValueError(f"Nested shared policies are not supported in {skill}")
        if not compiled.startswith(f"---\nname: {skill}\n"):
            raise ValueError(f"Missing valid Agent Skills frontmatter in {skill}")
        result[f"skills/{skill}/SKILL.md"] = compiled.encode("utf-8")
    return result


def write_or_check(root: Path = ROOT, check: bool = False) -> bool:
    correct = True
    for rel, content in generated_skills(root).items():
        # In this skills repository, generated skills live at the repository root.
        # Standalone/extracted distributions retain their own skills/ directory.
        path = (root.parent / rel.removeprefix("skills/")) if (root / "IN_REPO.md").exists() else root / rel
        if check:
            if not path.exists() or path.read_bytes() != content:
                print(f"STALE {rel}", file=sys.stderr)
                correct = False
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)
            print(f"GENERATED {rel}")
    return correct


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Verify committed generated outputs match canonical src policies")
    args = parser.parse_args()
    ok = write_or_check(check=args.check)
    if args.check:
        print("Shared-policy outputs match canonical sources" if ok else "Regenerate with: python3 tools/build_skills.py")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
