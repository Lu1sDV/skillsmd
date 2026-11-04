#!/usr/bin/env python3
"""Monotonic, risk-aware reviewer-budget planner. Does not spawn agents or prove risk.

Examples:
  python3 tools/review_plan.py --files 3 --changed-lines 500 --depth NORMAL
  python3 tools/review_plan.py --files 2 --changed-lines 2100 --depth DEEP \\
    --risk 'payments|diff replaces decimal rounding with binary float' --capacity 2
"""
from __future__ import annotations

import argparse
import json
import math
from dataclasses import asdict, dataclass
from typing import Iterable

RISK_CATEGORIES = (
    "auth-authorization", "secrets-crypto", "payments", "durable-data",
    "schema-migration", "tenant-isolation", "distributed-concurrency",
    "public-compatibility", "deployment-rollback", "unsafe-execution",
)
DEPTHS = ("NORMAL", "DEEP", "ULTRA")


@dataclass(frozen=True)
class RiskSignal:
    category: str
    evidence: str

    def __post_init__(self) -> None:
        if self.category not in RISK_CATEGORIES:
            raise ValueError(f"Unsupported risk category: {self.category!r}. Choices: {', '.join(RISK_CATEGORIES)}")
        if len(self.evidence.strip()) < 8:
            raise ValueError("Risk evidence must identify a concrete affected path/contract; an empty label is insufficient")


def parse_risk(raw: str) -> RiskSignal:
    category, separator, evidence = raw.partition("|")
    if not separator:
        raise ValueError("Risk must use 'category|specific path/contract and evidence'")
    return RiskSignal(category.strip(), evidence.strip())


def domain_reviewers(files: int, changed_lines: int) -> int:
    """Nondecreasing in both axes (for nonnegative integers)."""
    if files < 0 or changed_lines < 0:
        raise ValueError("File and changed-line counts must be nonnegative")
    if files == 0:
        return 0
    quota = 1
    if files >= 3 and changed_lines >= 100:
        quota = max(quota, min(2, files))
    if changed_lines >= 500:
        quota = max(quota, min(4, math.ceil(files / 3)))
    if changed_lines >= 2000:
        quota = max(quota, 2, min(8, math.ceil(files / 2)))
    if changed_lines >= 5000:
        quota = max(quota, min(16, files))
    return quota


def build_plan(files: int, changed_lines: int, depth: str = "NORMAL",
               risks: Iterable[RiskSignal] = (), capacity: int | None = None) -> dict:
    depth = depth.upper()
    if depth not in DEPTHS:
        raise ValueError(f"Depth must be one of: {', '.join(DEPTHS)}")
    if capacity is not None and capacity < 1:
        raise ValueError("Capacity must be positive")
    domain = domain_reviewers(files, changed_lines)
    unique_risks = list(dict.fromkeys(risks))
    risk = 1 if files and unique_risks else 0
    holistic = 1 if files and depth in {"DEEP", "ULTRA"} else 0
    requested = domain + risk + holistic
    return {
        "files": files,
        "changed_lines": changed_lines,
        "depth": depth,
        "domain_reviewers": domain,
        "targeted_risk_reviewers": risk,
        "holistic_reviewers": holistic,
        "total_requested": requested,
        "capacity": capacity,
        "waves": math.ceil(requested / capacity) if capacity and requested else (0 if requested == 0 else None),
        "verified_risks_input": [asdict(item) for item in unique_risks],
        "note": ("Risk inputs are reviewer-asserted and must be verified against the selected code. "
                 "Subagent capacity affects waves, not requested count. "
                 "This helper never launches agents or tests code."),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--files", type=int, required=True)
    parser.add_argument("--changed-lines", type=int, required=True,
                        help="Count additions + deletions; do not use the net delta")
    parser.add_argument("--depth", type=str.upper, choices=DEPTHS, default="NORMAL")
    parser.add_argument("--risk", action="append", default=[], metavar="CATEGORY|EVIDENCE",
                        help="Repeat only for verified changed risky paths or contracts")
    parser.add_argument("--capacity", type=int, help="Available concurrent agents; affects waves only")
    parser.add_argument("--human", action="store_true", help="Readable summary instead of JSON")
    args = parser.parse_args()
    try:
        plan = build_plan(args.files, args.changed_lines, args.depth,
                          (parse_risk(raw) for raw in args.risk), args.capacity)
    except ValueError as exc:
        parser.error(str(exc))
    if args.human:
        print(f"{plan['depth']}: domain={plan['domain_reviewers']} risk={plan['targeted_risk_reviewers']} "
              f"holistic={plan['holistic_reviewers']} total={plan['total_requested']} "
              f"waves={plan['waves'] if plan['waves'] is not None else 'capacity unknown'}")
        print(plan["note"])
    else:
        print(json.dumps(plan, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
