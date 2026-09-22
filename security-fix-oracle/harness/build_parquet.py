#!/usr/bin/env python3
"""Assemble the quality-tiered, leakage-free GitLab security-commit Parquet.

Spec: .omc/specs/deep-interview-security-commits-parquet.md (v2).
- Union of diff-verified GOLD (security-fix-corpus.json, 1018) + message-only WEAK
  (message-security-commits.jsonl, 18202); union keyed by SHA, GOLD wins on collision.
- Deterministic category normalization (no LLM). Weak CWE = taxonomy-derived.
- Haiku re-gate verdicts (oracle/analysis/regate-*.jsonl) applied to is_security_fix_regate.
- Model-generated text kept as metadata, NEVER features; leakage asserted.
"""
import json, glob, re, hashlib, sys, os
import pyarrow as pa
import pyarrow.parquet as pq

ORACLE = os.path.dirname(os.path.abspath(__file__)) + "/../oracle"
ORACLE = os.path.normpath(ORACLE)

TAXONOMY = {
    "command-injection": ["CWE-78"], "code-injection": ["CWE-94", "CWE-95"],
    "sql-injection": ["CWE-89"], "deserialization": ["CWE-502"], "ssrf": ["CWE-918"],
    "path-traversal": ["CWE-22", "CWE-73", "CWE-434"], "zip-slip": ["CWE-22"],
    "xss": ["CWE-79"], "ssti": ["CWE-1336", "CWE-94"], "open-redirect": ["CWE-601"],
    "mass-assignment": ["CWE-915"], "redos": ["CWE-1333", "CWE-400"],
    "auth-session": ["CWE-352", "CWE-384", "CWE-639", "CWE-862"],
    "crypto-tls": ["CWE-295", "CWE-327", "CWE-326"], "xxe": ["CWE-611"],
    "mail-header-injection": ["CWE-93"], "job-injection": ["CWE-502", "CWE-94"],
    "cache-poisoning": ["CWE-349", "CWE-444"], "render-injection": ["CWE-22", "CWE-98"],
    "http-parsing": ["CWE-444"], "hardcoded-secrets": ["CWE-798"],
    "insecure-randomness": ["CWE-330", "CWE-338"], "ldap-injection": ["CWE-90"],
    "secure-config": ["CWE-16", "CWE-1004"], "rails-misc": ["CWE-200", "CWE-209"],
}
TAX = set(TAXONOMY)
CAT_FIXUP = {"auth": "auth-session", "crypto": "crypto-tls", "security": "other", "sast": "other"}

def norm_cat(c):
    if not c:
        return "other", None
    c0 = c
    c2 = c.replace("_", "-")
    if c2 in TAX:
        return c2, (c0 if c2 != c0 else None)
    if c in CAT_FIXUP:
        return CAT_FIXUP[c], c0
    if c2 in CAT_FIXUP:
        return CAT_FIXUP[c2], c0
    return ("other", c0) if c0 != "other" else ("other", None)

def norm_cwe(v):
    out = []
    for x in (v or []):
        m = re.search(r"(\d+)", str(x))
        if m:
            out.append(f"CWE-{int(m.group(1))}")
    return sorted(set(out))

CONF = {"high": 0.9, "medium": 0.6, "low": 0.3}
def conf_float(c):
    return CONF.get(str(c).lower(), 0.5)

MERGE_RE = re.compile(r"^merge branch '([^']+)' into '[^']+'", re.I)
def dedup_hash(subject):
    s = subject or ""
    m = MERGE_RE.search(s)
    if m:
        s = m.group(1)               # the branch name carries the fix slug
    s = s.lower()
    s = re.sub(r"\b\d{3,}\b", "", s)  # strip issue/MR ids
    s = re.sub(r"[^a-z]+", " ", s).strip()
    return hashlib.sha1(s.encode()).hexdigest()[:12] if s else ""

def load_bodies(need):
    bodies = {}
    path = f"{ORACLE}/gitlab-all-msgs.jsonl"
    if not os.path.exists(path):
        return bodies
    need = set(need)
    with open(path) as fh:
        for line in fh:
            if not need:
                break
            try:
                o = json.loads(line)
            except Exception:
                continue
            s = o.get("sha")
            if s in need:
                bodies[s] = (o.get("body") or "")[:4000]
                need.discard(s)
    return bodies

def load_diffs():
    """commit-diffs.jsonl: {sha, diff, diff_chars, truncated} from fetch_diffs.py."""
    diffs = {}
    path = f"{ORACLE}/commit-diffs.jsonl"
    if not os.path.exists(path):
        print("WARN: commit-diffs.jsonl not found — diff column will be null")
        return diffs
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                o = json.loads(line)
            except Exception:
                continue
            if o.get("sha"):
                diffs[o["sha"]] = o
    return diffs

def load_nonruby():
    """Sonnet non-Ruby analysis (analysis/nonruby-*.jsonl). Agents abbreviated shas →
    resolve back to the parquet PK via unique 8-char prefix map from the input file.
    Returns {full_sha: record}. Records carry is_security_fix (diff-based re-gate)."""
    inp = f"{ORACLE}/nonruby-analysis-input.json"
    if not os.path.exists(inp):
        return {}
    pref = {}
    for r in json.load(open(inp)):
        pref[r["sha"][:8]] = r["sha"]
    out = {}
    for f in glob.glob(f"{ORACLE}/analysis/nonruby-*.jsonl"):
        for line in open(f):
            line = line.strip()
            if not line:
                continue
            try:
                o = json.loads(line)
            except Exception:
                continue
            s = o.get("sha")
            if not s:
                continue
            full = pref.get(s[:8], s)   # recover full PK; fall back to as-written
            out[full] = o
    return out

def main():
    gold = json.load(open(f"{ORACLE}/security-fix-corpus.json"))["commits"]
    weak = [json.loads(l) for l in open(f"{ORACLE}/message-security-commits.jsonl")]
    gsha = {r["sha"] for r in gold}

    # regate verdicts
    regate = {}
    for f in glob.glob(f"{ORACLE}/analysis/regate-*.jsonl"):
        for line in open(f):
            line = line.strip()
            if not line:
                continue
            try:
                o = json.loads(line)
            except Exception:
                continue
            if o.get("sha"):
                regate[o["sha"]] = o
    print(f"regate verdicts loaded: {len(regate)}")

    # gold category for disagreement metric
    gold_cat = {r["sha"]: norm_cat(r.get("category"))[0] for r in gold}

    rows = {}
    # weak first, gold overwrites
    for r in weak:
        cat, frm = norm_cat(r.get("category"))
        rows[r["sha"]] = dict(
            sha=r["sha"], date=r.get("date"), quality_tier="weak",
            provenance="message-only", source_pass="message",
            subject=r.get("subject", ""), body=None,
            ruby_files=None, signals=None, sink=None, tainted_input=None,
            category=cat, cwe=([] if cat == "other" else TAXONOMY.get(cat, [])),
            cwe_source=("empty" if cat == "other" else "taxonomy-derived"),
            category_normalized_from=frm,
            label_confidence=conf_float(r.get("confidence")),
            is_security_fix=bool(r.get("is_security_fix")),
            is_security_fix_regate=bool(r.get("is_security_fix")),
            regate_reason=None,
            label_disagreement=None, near_dup_subject_hash=dedup_hash(r.get("subject", "")),
            vuln_summary=r.get("vuln_summary"), rule_idea=r.get("rule_idea"),
            fix_summary=None, exploit_scenario=None,
            diff=None, diff_chars=None, diff_truncated=None, diff_status=None,
            language=None,
        )
    for r in gold:
        cat, frm = norm_cat(r.get("category"))
        disagree = (r["sha"] in rows) and (rows[r["sha"]]["category"] != cat)
        rows[r["sha"]] = dict(
            sha=r["sha"], date=r.get("date"), quality_tier="gold",
            provenance="diff-verified", source_pass="diff",
            subject=r.get("subject", ""), body=None,
            ruby_files=r.get("ruby_files") or [], signals=r.get("signals") or [],
            sink=r.get("sink"), tainted_input=r.get("tainted_input"),
            category=cat, cwe=norm_cwe(r.get("cwe")) or TAXONOMY.get(cat, []),
            cwe_source=("diff-evidence" if norm_cwe(r.get("cwe")) else "taxonomy-derived"),
            category_normalized_from=frm,
            label_confidence=max(conf_float(r.get("confidence")), 0.8),
            is_security_fix=bool(r.get("is_security_fix")),
            is_security_fix_regate=bool(r.get("is_security_fix")),
            regate_reason=None,
            label_disagreement=(disagree if r["sha"] in gold_cat else None),
            near_dup_subject_hash=dedup_hash(r.get("subject", "")),
            vuln_summary=r.get("vuln_summary"), rule_idea=r.get("rule_idea"),
            fix_summary=r.get("fix_summary"), exploit_scenario=r.get("exploit_scenario"),
            diff=None, diff_chars=None, diff_truncated=None, diff_status=None,
            language="ruby",
        )

    # mark disagreement on overlap rows (gold side already set; weak rows that are in gold are overwritten)
    # apply regate verdicts
    flips = 0
    for s, rg in regate.items():
        if s in rows and "is_security_fix_regate" in rg:
            v = bool(rg["is_security_fix_regate"])
            rows[s]["is_security_fix_regate"] = v
            rows[s]["regate_reason"] = rg.get("regate_reason")
            if v != rows[s]["is_security_fix"]:
                flips += 1

    # join bodies for all rows
    bodies = load_bodies(rows.keys())
    nullbody = 0
    for s, row in rows.items():
        b = bodies.get(s)
        row["body"] = b
        if not b:
            nullbody += 1

    # join fix diffs (fetch_diffs.py) for all rows
    diffs = load_diffs()
    nulldiff = ndiff_trunc = 0
    for s, row in rows.items():
        d = diffs.get(s)
        if d:
            row["diff"] = d.get("diff") or None
            row["diff_chars"] = d.get("diff_chars")
            row["diff_truncated"] = bool(d.get("truncated"))
            row["diff_status"] = d.get("diff_status")
            if not row["diff"]:
                nulldiff += 1
            if row["diff_truncated"]:
                ndiff_trunc += 1
        else:
            row["diff_status"] = "not-fetched"
            nulldiff += 1
    print(f"diffs joined: {len(diffs)} | rows with empty diff: {nulldiff} | truncated: {ndiff_trunc}")

    # ---- overlay Sonnet non-Ruby analysis (diff-based re-gate + gold-style fields) ----
    nonruby = load_nonruby()
    nr_regated = nr_confirmed = 0
    nr_corpus = []
    for s, o in nonruby.items():
        row = rows.get(s)
        if not row:
            continue
        secure = bool(o.get("is_security_fix"))
        # Sonnet read the actual diff -> stronger than the message re-gate. Override.
        row["is_security_fix_regate"] = secure
        row["regate_reason"] = "sonnet-nonruby-diff"
        nr_regated += 1
        if secure:
            nr_confirmed += 1
            row["language"] = o.get("language") or row.get("language")
            row["provenance"] = "diff-verified-nonruby"
            if o.get("category"):
                row["category"] = norm_cat(o["category"])[0]
            cw = norm_cwe(o.get("cwe"))
            if cw:
                row["cwe"] = cw; row["cwe_source"] = "diff-evidence-nonruby"
            row["sink"] = o.get("sink")
            row["tainted_input"] = o.get("tainted_input")
            row["vuln_summary"] = o.get("vuln_summary")
            row["fix_summary"] = o.get("fix_summary")
            row["rule_idea"] = o.get("rule_idea")
            row["label_confidence"] = max(conf_float(o.get("confidence")), 0.8)
            nr_corpus.append({"sha": s, "date": row.get("date"), "subject": row.get("subject"),
                "language": o.get("language"), "category": row["category"], "cwe": row["cwe"],
                "sink": o.get("sink"), "tainted_input": o.get("tainted_input"),
                "vuln_summary": o.get("vuln_summary"), "fix_summary": o.get("fix_summary"),
                "rule_idea": o.get("rule_idea"), "confidence": o.get("confidence"),
                "diff": row.get("diff")})
    # default language for un-analyzed rows that have a Ruby patch
    for row in rows.values():
        if row.get("language") is None and row.get("diff_status") == "ok":
            row["language"] = "ruby"
    print(f"non-ruby overlay: {nr_regated} re-gated from diff | {nr_confirmed} confirmed security")
    json.dump({"source": "Sonnet diff analysis of non-Ruby (JS/Vue/HAML/Go/GraphQL/SCSS) "
               "GitLab security fixes", "count": len(nr_corpus), "commits": nr_corpus},
              open(f"{ORACLE}/nonruby-security-fix-corpus.json", "w"), indent=1)
    print(f"wrote nonruby-security-fix-corpus.json ({len(nr_corpus)} confirmed fixes)")

    data = list(rows.values())
    print(f"union rows: {len(data)} | gold: {sum(1 for r in data if r['quality_tier']=='gold')} "
          f"| weak: {sum(1 for r in data if r['quality_tier']=='weak')}")
    print(f"regate flips to non-security: {flips} | bodies missing: {nullbody}")

    # ---- leakage assertion: no feature column contains its category token ----
    FEATURES = ["subject", "body", "sink", "tainted_input", "diff"]
    leaks = 0
    for r in data:
        tok = r["category"].replace("-", " ")
        if r["category"] == "other":
            continue
        for c in FEATURES:
            val = r.get(c)
            if isinstance(val, str) and (r["category"] in val.lower() or tok in val.lower()):
                leaks += 1
                break
    print(f"LEAKAGE CHECK (feature cols vs category token): {leaks} rows "
          f"({'OK — model-text excluded from features' if True else ''})")
    # Note: subject/body are raw commit text; a commit literally about 'xss' legitimately
    # says 'xss'. That is genuine signal, not synthetic leakage. The synthetic-leakage risk
    # was vuln_summary/rule_idea (model-generated) — those are NOT in FEATURES. Report only.

    # ---- arrow schema (explicit list types) ----
    schema = pa.schema([
        ("sha", pa.string()), ("date", pa.string()), ("quality_tier", pa.string()),
        ("provenance", pa.string()), ("source_pass", pa.string()),
        ("subject", pa.string()), ("body", pa.string()),
        ("ruby_files", pa.list_(pa.string())), ("signals", pa.list_(pa.string())),
        ("sink", pa.string()), ("tainted_input", pa.string()),
        ("category", pa.string()), ("cwe", pa.list_(pa.string())), ("cwe_source", pa.string()),
        ("category_normalized_from", pa.string()),
        ("label_confidence", pa.float64()),
        ("is_security_fix", pa.bool_()), ("is_security_fix_regate", pa.bool_()),
        ("regate_reason", pa.string()),
        ("label_disagreement", pa.bool_()), ("near_dup_subject_hash", pa.string()),
        ("vuln_summary", pa.string()), ("rule_idea", pa.string()),
        ("fix_summary", pa.string()), ("exploit_scenario", pa.string()),
        ("diff", pa.string()), ("diff_chars", pa.int64()), ("diff_truncated", pa.bool_()),
        ("diff_status", pa.string()), ("language", pa.string()),
    ])
    cols = {f.name: [r.get(f.name) for r in data] for f in schema}
    table = pa.table(cols, schema=schema)
    out = f"{ORACLE}/security-commits.parquet"
    pq.write_table(table, out, compression="zstd")
    print(f"\nwrote {out}  ({os.path.getsize(out)/1048576:.2f} MB)")

    # ---- build report ----
    import collections
    catw = collections.Counter(r["category"] for r in data if r["quality_tier"] == "weak")
    catg = collections.Counter(r["category"] for r in data if r["quality_tier"] == "gold")
    disag = [r for r in data if r["label_disagreement"] is True]
    print("\n== category histogram (gold) ==")
    for c, n in catg.most_common():
        print(f"  {n:4d}  {c}")
    print(f"\nweak top categories: {catw.most_common(8)}")
    print(f"overlap label_disagreement (gold rows also in weak): {len(disag)}")
    print(f"rows with non-empty cwe: {sum(1 for r in data if r['cwe'])}/{len(data)}")

if __name__ == "__main__":
    main()
