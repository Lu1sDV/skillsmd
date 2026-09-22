#!/usr/bin/env python3
"""Stage 3 — before/after verdict for selective real-DB validation of a query.

Given a fix's manifest row + the SARIF from the query run on the BEFORE (parent)
DB and the AFTER (fix) DB, decide TP / TN / FN / residual per the harness spec:

  TP  : >=1 result at BEFORE whose primary location is in a changed (non-test) file
        and whose line overlaps the parent deleted range (addition-only: ±W window).
  TN  : query WAS a TP at parent AND no result at AFTER overlaps the fixed range.
  FN  : no result at BEFORE overlaps any parent changed range (gap-report row).
  residual_at_fix : a result STILL overlaps the fixed range at AFTER (incomplete fix
        or rule keys on something the fix didn't touch) — high-value to review.
  variant : result at BEFORE NOT overlapping any changed range (sibling candidate).

Usage:
  verdict.py --sha <sha> --manifest snapshots.jsonl \
             --before-sarif <f> --after-sarif <f> [--window 3] [--out -]
"""
import argparse, json, sys

TEST_MARKERS = ("/spec/", "spec/", "/test/", "test/", "/tests/", "_spec.rb", "_test.rb")

def is_test(p):
    p = (p or "").lower()
    return any(m in p for m in TEST_MARKERS)

def overlaps(a0, a1, b0, b1):
    return a0 <= b1 and b0 <= a1

def sarif_results(fp):
    if not fp:
        return []
    try:
        data = json.load(open(fp))
    except (OSError, json.JSONDecodeError):
        return []
    out = []
    for run in data.get("runs", []):
        for res in run.get("results", []):
            locs = res.get("locations") or []
            if not locs:
                continue
            ploc = locs[0].get("physicalLocation", {}) or {}
            uri = (ploc.get("artifactLocation", {}) or {}).get("uri", "")
            reg = ploc.get("region", {}) or {}
            sl = reg.get("startLine")
            if sl is None:
                continue
            out.append({"rule_id": res.get("ruleId"), "file": uri,
                        "start": sl, "end": reg.get("endLine", sl)})
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sha", required=True)
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--before-sarif")
    ap.add_argument("--after-sarif")
    ap.add_argument("--window", type=int, default=3)
    ap.add_argument("--out", default="-")
    args = ap.parse_args()

    row = None
    for line in open(args.manifest):
        r = json.loads(line)
        if r["sha"] == args.sha:
            row = r
            break
    if not row:
        print(f"sha {args.sha} not in manifest", file=sys.stderr)
        sys.exit(2)

    # build per-file parent + fix target ranges (non-test files only)
    parent_ranges, fix_ranges = {}, {}
    for rng in row.get("changed_line_ranges", []):
        f = rng["file"]
        if is_test(f):
            continue
        ps, pl = rng["parent_del_start"], rng["parent_del_len"]
        if pl == 0:
            parent_ranges.setdefault(f, []).append((ps - args.window, ps + args.window))
        else:
            parent_ranges.setdefault(f, []).append((ps, ps + pl - 1))
        fs, fl = rng["fix_add_start"], rng["fix_add_len"]
        if fl == 0:
            fix_ranges.setdefault(f, []).append((fs - args.window, fs + args.window))
        else:
            fix_ranges.setdefault(f, []).append((fs, fs + fl - 1))

    def hits(results, ranges):
        h = []
        for res in results:
            for (b0, b1) in ranges.get(res["file"], []):
                if overlaps(res["start"], res["end"], b0, b1):
                    h.append(res)
                    break
        return h

    before = sarif_results(args.before_sarif)
    after = sarif_results(args.after_sarif)
    before_on_parent = hits(before, parent_ranges)
    after_on_fix = hits(after, fix_ranges)
    variants = [r for r in before
                if not any(overlaps(r["start"], r["end"], b0, b1)
                           for (b0, b1) in parent_ranges.get(r["file"], []))
                and not is_test(r["file"])]

    tp = len(before_on_parent) > 0
    residual = len(after_on_fix) > 0
    verdict = {
        "sha": args.sha, "category": row["category"], "cvss_score": row.get("cvss_score"),
        "quality_tier": row.get("quality_tier"), "fix_shape": row.get("fix_shape"),
        "tp": tp,
        "fn": not tp,
        "tn": tp and not residual,
        "residual_at_fix": residual,
        "n_before_on_parent": len(before_on_parent),
        "n_after_on_fix": len(after_on_fix),
        "n_variants_at_parent": len(variants),
        "rules_fired_before": sorted({r["rule_id"] for r in before_on_parent}),
        "variants": variants[:20],
    }
    out = json.dumps(verdict)
    if args.out == "-":
        print(out)
    else:
        with open(args.out, "a") as f:
            f.write(out + "\n")
        print(out)

if __name__ == "__main__":
    main()
