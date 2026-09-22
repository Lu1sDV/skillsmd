#!/usr/bin/env python3
"""Parse CodeQL SARIF into deduplicated findings (variant candidates / verdict input).

At HEAD, every result is a variant candidate: HEAD is the patched tree, so any
remaining match is a spot the historical fixes did not cover.

Usage: sarif_to_findings.py SARIF [SARIF...] --out variants.jsonl [--md report.md]
                            [--exclude-tests] [--source-only]
"""
import argparse, json, hashlib, os, sys, collections

TEST_MARKERS = ("/spec/", "spec/", "/test/", "test/", "/tests/", "_spec.rb", "_test.rb",
                "/qa/", "/features/")

def is_test(path):
    p = path.lower()
    return any(m in p for m in TEST_MARKERS)

def load_sarif(fp):
    with open(fp) as f:
        data = json.load(f)
    out = []
    for run in data.get("runs", []):
        # map ruleId -> properties (precision, security-severity) if present
        rules = {}
        for r in run.get("tool", {}).get("driver", {}).get("rules", []):
            props = r.get("properties", {}) or {}
            rules[r.get("id")] = {
                "precision": props.get("precision"),
                "security_severity": props.get("security-severity"),
                "name": r.get("name"),
            }
        for res in run.get("results", []):
            rid = res.get("ruleId")
            msg = (res.get("message", {}) or {}).get("text", "")
            locs = res.get("locations", []) or []
            if not locs:
                continue
            ploc = (locs[0].get("physicalLocation", {}) or {})
            uri = (ploc.get("artifactLocation", {}) or {}).get("uri", "")
            region = ploc.get("region", {}) or {}
            sl = region.get("startLine")
            el = region.get("endLine", sl)
            cf = res.get("codeFlows", []) or []
            out.append({
                "rule_id": rid, "file": uri, "start_line": sl, "end_line": el,
                "message": msg, "has_flow": bool(cf),
                "precision": rules.get(rid, {}).get("precision"),
                "security_severity": rules.get(rid, {}).get("security_severity"),
            })
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sarif", nargs="+")
    ap.add_argument("--out", required=True)
    ap.add_argument("--md")
    ap.add_argument("--exclude-tests", action="store_true",
                    help="drop findings in spec/test files (recommended for variant hunt)")
    args = ap.parse_args()

    findings = []
    for fp in args.sarif:
        if os.path.exists(fp):
            findings.extend(load_sarif(fp))
    # dedup by (rule, file, start_line)
    seen = {}
    for f in findings:
        if args.exclude_tests and f["file"] and is_test(f["file"]):
            f["_test"] = True
        key = hashlib.sha1(f"{f['rule_id']}|{f['file']}|{f['start_line']}".encode()).hexdigest()[:12]
        if key not in seen:
            f["dedup_key"] = key
            f["is_test_file"] = bool(f["file"] and is_test(f["file"]))
            seen[key] = f
    rows = list(seen.values())
    if args.exclude_tests:
        rows = [r for r in rows if not r["is_test_file"]]

    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    with open(args.out, "w") as fo:
        for r in rows:
            r.pop("_test", None)
            fo.write(json.dumps(r) + "\n")

    by_rule = collections.Counter(r["rule_id"] for r in rows)
    src = sum(1 for r in rows if not r["is_test_file"])
    summary = {"total": len(rows), "source_findings": src,
               "test_findings": len(rows) - src, "by_rule": dict(by_rule.most_common())}
    print(json.dumps(summary, indent=2))
    if args.md:
        with open(args.md, "w") as m:
            m.write(f"# Variant-hunt findings ({len(rows)} candidates, {src} in source)\n\n")
            m.write("| count | rule | precision |\n|---|---|---|\n")
            prec = {r["rule_id"]: r.get("precision") for r in rows}
            for rid, n in by_rule.most_common():
                m.write(f"| {n} | `{rid}` | {prec.get(rid)} |\n")

if __name__ == "__main__":
    main()
