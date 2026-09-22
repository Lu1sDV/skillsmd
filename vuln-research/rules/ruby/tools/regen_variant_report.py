#!/usr/bin/env python3
"""Regenerate VARIANT-CORPUS-REPORT.md from variant-corpus.json (the source of truth).
Run from rules/ruby:  python3 tools/regen_variant_report.py
Do NOT hand-edit the .md — edit the .json and re-run this."""
import json, os
from collections import defaultdict

ROOT = os.path.join(os.path.dirname(__file__), "..")
CORPUS = os.path.join(ROOT, "oracle/validation/variant-corpus.json")
OUT = os.path.join(ROOT, "oracle/validation/VARIANT-CORPUS-REPORT.md")

c = json.load(open(CORPUS))
vs = c["variants"]; s = c["summary"]
def grp(st): return [v for v in vs if v.get("final_status") == st]

L = []
L.append("# GitLab HEAD Variant Corpus — Report")
L.append("")
L.append(f"_Checkout: {s.get('checkout')}. Generated from `variant-corpus.json` (source of truth) via `tools/regen_variant_report.py`._")
L.append("")
L.append("## Summary")
L.append("")
fs = s["final_status"]
L.append(f"- **{fs.get('VARIANT',0)} CONFIRMED variants** (adversarially verified, real & reachable)")
L.append(f"- **{fs.get('CANDIDATE_VARIANT',0)} candidate variants** (detector-flagged, not yet individually verified)")
L.append(f"- **{fs.get('REVIEW',0)} need manual review** (ambiguous / off-rule-axis)")
L.append(f"- **{fs.get('DEMOTED_FP',0)} demoted to false-positive** (verified non-issues)")
L.append(f"- Site-class of the {s.get('total_true_dedup')} dedup TRUEs: {s.get('site_class')}")
L.append("")
av = s.get("adversarial_verification", {})
if av:
    L.append(f"**Adversarial verification ({av.get('date')}):** {av.get('result')}")
    L.append("")

L.append("## TIER 1 — CONFIRMED variants")
L.append("")
byrule = defaultdict(list)
for v in grp("VARIANT"): byrule[v.get("rule")].append(v)
for rule in sorted(byrule):
    L.append(f"### `{rule}`  ({len(byrule[rule])})")
    for v in sorted(byrule[rule], key=lambda x: str(x.get("file"))):
        L.append(f"- **{v.get('file')}:{v.get('line')}** [{v.get('sev_raw')}/{v.get('sev')}, conf={v.get('conf','')}]")
        L.append(f"  - {str(v.get('disambig_note') or v.get('reason') or '')[:320]}")
    L.append("")

rev = grp("REVIEW")
if rev:
    L.append("## NEEDS MANUAL REVIEW")
    L.append("")
    for v in rev:
        L.append(f"- **{v.get('file')}:{v.get('line')}** `{v.get('rule')}` — {str(v.get('disambig_note') or v.get('reason'))[:320]}")
    L.append("")

L.append("## TIER 2 — candidate variants (by rule)")
L.append("")
cby = defaultdict(list)
for v in grp("CANDIDATE_VARIANT"): cby[v.get("rule")].append(v)
for rule in sorted(cby, key=lambda r: -len(cby[r])):
    L.append(f"- `{rule}` — {len(cby[rule])} sites")
L.append("")

L.append("## DEMOTED — verified false positives")
L.append("")
for v in sorted(grp("DEMOTED_FP"), key=lambda x: str(x.get("rule"))):
    L.append(f"- **{v.get('file')}:{v.get('line')}** `{v.get('rule')}` — {str(v.get('disambig_note') or '')[:260]}")
L.append("")

ifh = c.get("incomplete_fix_hunt", {})
if ifh:
    L.append("## Strategy-6 incomplete-fix confirmation lane")
    L.append("")
    L.append(f"- Fixes processed: {ifh.get('fixes_processed')} | residual_at_fix: {ifh.get('residual_at_fix')} | tp={ifh.get('tp')} fn={ifh.get('fn')} tn={ifh.get('tn')}")
    L.append(f"- {ifh.get('note')}")
    L.append(f"- Verification: {ifh.get('verification')}")
    L.append("")

bl = c.get("rule_precision_backlog", {})
if bl:
    L.append("## Rule-precision backlog")
    L.append("")
    for k in ["flood_ubiquitous_positive", "flawed_threat_model", "blind_to_external_guard", "arm_specific_fp", "note"]:
        if bl.get(k):
            L.append(f"**{k}:**")
            val = bl[k]
            for r in (val if isinstance(val, list) else [val]):
                L.append(f"- {r}")
            L.append("")

open(OUT, "w").write("\n".join(L) + "\n")
print(f"wrote {OUT} ({len(chr(10).join(L))} chars)")
print("CONFIRMED:", {r: len(byrule[r]) for r in byrule})
