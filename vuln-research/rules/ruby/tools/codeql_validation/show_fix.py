#!/usr/bin/env python3
"""Print the security-fix evidence (subject, cwe, cvss, diff) for one or more SHAs.
Looks in dumped authoring packets first, falls back to the parquet. Read-only; no PII.

Usage: show_fix.py <sha12> [<sha12> ...]
"""
import sys, json, glob, os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def from_packets(sha):
    for f in glob.glob(os.path.join(ROOT, "oracle/validation/authoring/*/%s*.json" % sha)):
        try:
            return json.load(open(f))
        except Exception:
            pass
    return None

def from_parquet(sha):
    import pyarrow.parquet as pq
    pqf = os.path.join(ROOT, "oracle/security-commits-cvss.parquet")
    t = pq.read_table(pqf, columns=["sha","subject","cwe","cvss_score","category","quality_tier","diff"])
    d = t.to_pydict()
    for i, s in enumerate(d["sha"]):
        if s.startswith(sha):
            return {"sha": s, "subject": d["subject"][i], "cwe": d["cwe"][i],
                    "cvss_score": d["cvss_score"][i], "category": d["category"][i],
                    "quality_tier": d["quality_tier"][i], "diff": d["diff"][i] or ""}
    return None

def main():
    for sha in sys.argv[1:]:
        rec = from_packets(sha) or from_parquet(sha)
        if not rec:
            print("=== %s : NOT FOUND ===" % sha); continue
        print("=== %s  [%s, %s, cvss=%s, cwe=%s] ===" % (
            rec.get("sha","")[:12], rec.get("category"), rec.get("quality_tier"),
            rec.get("cvss_score"), rec.get("cwe")))
        print(rec.get("subject",""))
        print("--- diff ---")
        print(rec.get("diff",""))
        print()

if __name__ == "__main__":
    main()
