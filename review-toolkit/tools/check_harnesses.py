#!/usr/bin/env python3
"""Compare installed harnesses to pinned published-version baselines.

This checks the CLI executable and version only. It does not prove runtime API
compatibility, agent launching, skill discovery or authenticated operation.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PINS = ROOT / "harnesses" / "versions.json"
SEMVER = re.compile(r"(?<![\d.])v?(\d+\.\d+\.\d+(?:-[a-zA-Z0-9.-]+)?)")


def load_pins(path: Path = DEFAULT_PINS) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("schema_version") != 1:
        raise ValueError("Unsupported compatibility pin schema")
    for key, item in data["harnesses"].items():
        if not key or not isinstance(item.get("version"), str) or not item.get("binary"):
            raise ValueError(f"Invalid pin entry {key}")
        if not SEMVER.fullmatch(item["version"]):
            raise ValueError(f"Invalid version for {key}")
    return data


def parse_version(output: str) -> str | None:
    match = SEMVER.search(output)
    return match.group(1) if match else None


def check_one(name: str, spec: dict, timeout: float = 8) -> dict:
    executable = shutil.which(spec["binary"])
    result: dict = {"harness": name, "expected": spec["version"],
                    "binary": spec["binary"], "status": "missing", "actual": None,
                    "detail": "executable not found on PATH"}
    if not executable:
        return result
    try:
        process = subprocess.run([executable, *spec.get("version_args", ["--version"])],
                                 capture_output=True, text=True, timeout=timeout, check=False)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return {**result, "status": "error", "detail": type(exc).__name__ + ": " + str(exc)}
    output = (process.stdout + "\n" + process.stderr).strip()
    actual = parse_version(output)
    if process.returncode != 0 or actual is None:
        return {**result, "status": "error", "detail": f"exit={process.returncode}; output={output[:300]}"}
    return {**result, "actual": actual, "status": "match" if actual == spec["version"] else "mismatch",
            "detail": f"found at {executable}"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pins", type=Path, default=DEFAULT_PINS)
    parser.add_argument("--target", choices=("all", "pi", "omp", "codex", "claude-code"), default="all")
    parser.add_argument("--strict", action="store_true", help="Exit nonzero for missing or mismatched versions")
    parser.add_argument("--json", action="store_true", help="Machine-readable results")
    parser.add_argument("--ci-matrix", action="store_true", help="Print GitHub Actions matrix from the same pins")
    args = parser.parse_args()
    data = load_pins(args.pins)
    names = list(data["harnesses"]) if args.target == "all" else [args.target]
    if args.ci_matrix:
        matrix = {"include": [{"target": name, "package": data["harnesses"][name]["package"],
                               "version": data["harnesses"][name]["version"]} for name in names]}
        print(json.dumps(matrix, separators=(",", ":")))
        return 0
    results = [check_one(name, data["harnesses"][name]) for name in names]
    if args.json:
        print(json.dumps({"snapshot_date": data["snapshot_date"], "results": results}, indent=2))
    else:
        for item in results:
            print(f"{item['harness']}: {item['status'].upper()} expected={item['expected']} "
                  f"actual={item['actual'] or '-'} — {item['detail']}")
        print("Pins compare CLI versions only; real command/agent behavior still needs interactive verification.")
    return 1 if args.strict and any(r["status"] != "match" for r in results) else 0


if __name__ == "__main__":
    raise SystemExit(main())
