#!/usr/bin/env python3
"""Verify the installed layout and wrapper/skill content without launching models."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from install import layout_for, root_paths  # noqa: E402
from tools.build_skills import generated_skills  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", choices=("pi", "omp", "codex", "claude-code"), required=True)
    parser.add_argument("--scope", choices=("project", "user"), default="project")
    parser.add_argument("--project-root", type=Path)
    args = parser.parse_args()
    paths = root_paths(args.target, args.scope, project_root=args.project_root)
    expected = layout_for(args.target, with_reviewer=True, scope=args.scope)
    for key, content in expected.items():
        path = paths.resolve(key)
        if not path.is_file():
            print(f"MISSING {path}", file=sys.stderr)
            return 1
        if path.read_bytes() != content:
            print(f"STALE {path}", file=sys.stderr)
            return 1
    print(f"Layout OK for {args.target}: {len(expected)} installed resources")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
