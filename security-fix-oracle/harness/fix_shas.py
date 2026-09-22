#!/usr/bin/env python3
"""Fix hallucinated SHAs in cvss-*.jsonl by aligning to batch slice order.

Why this exists
---------------
LLMs (deepseek-v4-flash included) sometimes generate plausible-looking but
incorrect 40-char hex SHAs — common with long opaque identifiers. The CVSS
scoring itself is usually correct, but the `sha` field drifts.

Workaround: the jsonl files preserve input order (the prompt requires it).
We re-anchor each line's `sha` to the corresponding line in the batch slice.

Usage
-----
    python3 fix_shas.py 21 25 28 31           # fix specific batches
    python3 fix_shas.py --all                 # fix all cvss-*.jsonl
    python3 fix_shas.py --report              # show mismatches without writing
"""
import argparse
import json
import sys
from pathlib import Path

ORACLE = Path(__file__).resolve().parent.parent / "oracle"
ANALYSIS = ORACLE / "analysis"


def diff_file(batch_idx: int, write: bool = True) -> tuple[int, int, int]:
    """Returns (total_lines, fixed, already_correct)."""
    idx_str = f"{batch_idx:03d}"
    slice_path = ANALYSIS / f"cvss-batch-{idx_str}.json"
    jsonl_path = ANALYSIS / f"cvss-{idx_str}.jsonl"

    with open(slice_path) as f:
        slice_shas = [r["sha"] for r in json.load(f)]

    with open(jsonl_path) as f:
        raw_lines = [l for l in f if l.strip()]

    if len(raw_lines) != len(slice_shas):
        print(f"  WARN cvss-{idx_str}: slice has {len(slice_shas)} rows, jsonl has {len(raw_lines)} rows")

    fixed = 0
    already = 0
    new_lines = []
    for i, line in enumerate(raw_lines):
        if i >= len(slice_shas):
            new_lines.append(line)
            continue
        obj = json.loads(line)
        expected = slice_shas[i]
        if obj.get("sha") != expected:
            obj["sha"] = expected
            fixed += 1
        else:
            already += 1
        new_lines.append(json.dumps(obj, ensure_ascii=False))

    if write and fixed:
        with open(jsonl_path, "w") as f:
            for line in new_lines:
                f.write(line + "\n")

    return len(raw_lines), fixed, already


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("batches", nargs="*", type=int, help="specific batch indices to fix (e.g. 21 25 28 31)")
    g.add_argument("--all", action="store_true", help="fix all cvss-*.jsonl files in order")
    g.add_argument("--report", action="store_true", help="report mismatches without writing")
    args = p.parse_args()

    if args.report:
        args.batches = args.batches or []
        write = False
    else:
        write = True

    if args.all:
        idxs = sorted(int(p.stem.split("-")[1]) for p in ANALYSIS.glob("cvss-*.jsonl"))
    else:
        idxs = args.batches

    total_lines = total_fixed = total_already = 0
    for idx in idxs:
        n, f, a = diff_file(idx, write=write)
        total_lines += n
        total_fixed += f
        total_already += a
        marker = "[REPORT]" if not write else ("[FIXED]" if f else "[OK]")
        print(f"  {marker} cvss-{idx:03d}.jsonl: {n} rows, {f} shas fixed, {a} already correct")

    print(f"\nTotal: {total_lines} rows across {len(idxs)} files")
    print(f"  {'would fix' if not write else 'fixed'}: {total_fixed}")
    print(f"  already correct: {total_already}")


if __name__ == "__main__":
    main()
