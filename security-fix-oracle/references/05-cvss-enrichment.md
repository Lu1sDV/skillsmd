# PHASE 6 — CVSS 3.1 + CWE Enrichment

Adds 4 columns to `security-commits-cvss.parquet`:

| Column | Type | Source |
|---|---|---|
| `cvss_score` | float 0.0–10.0 | procedural (recomputed from vector) |
| `cvss_vector` | `CVSS:3.1/AV:_/…/A:_` | LLM (NLP) |
| `cvss_severity` | None/Low/Medium/High/Critical | procedural (band of score) |
| `vuln_class_cwe` | list[str] top 1–3 | LLM (NLP) |

Full as-built operational log: [../../vuln-research/rules/ruby/CVSS_ENRICHMENT_RUNBOOK.md](../../vuln-research/rules/ruby/CVSS_ENRICHMENT_RUNBOOK.md)

---

## 1. Hybrid Architecture

```
Layer 1 — LLM (fixer subagent)
  Input : subject, body, diff, diff_status, category_hint
  Output: cvss_vector (8 metrics) + cvss_score (estimate)
           + cvss_severity (estimate) + vuln_class_cwe (top 1–3)
  Why   : metric selection is qualitative NLP — LLMs are good at it

         │  jsonl: 1 row / commit
         ▼

Layer 2 — cvss_aggregate.py (procedural validator)
  Re-computes base score from the vector via official CVSS 3.1 formula.
  Overrides the LLM's numeric score with the formula result.
  Why   : the multiplication chain is deterministic; LLMs botch it
          (~48% of rows needed override in the GitLab build)
```

**The key insight:** trust the vector (qualitative), derive the score (deterministic). Never trust the LLM's emitted float.

---

## 2. CVSS 3.1 Formula Reference

```
ISS = 1 − (1−C)(1−I)(1−A)

Scope Unchanged : Impact = 6.42 × ISS
Scope Changed   : Impact = 7.52×(ISS−0.029) − 3.25×(ISS−0.02)^15
                  (clamp to 0.0 if negative)

Exploitability  = 8.22 × AV × AC × PR × UI

Base score (Scope U) = roundup( min(Impact + Exploit, 10.0) )
Base score (Scope C) = roundup( min(1.08 × (Impact + Exploit), 10.0) )
If Impact ≤ 0 → score = 0.0

roundup: raise to next 0.1 if not already a multiple; floor-then-bump pattern.
PR lookup is scope-dependent: PR_U = {N:0.85, L:0.62, H:0.27},
                               PR_C = {N:0.85, L:0.68, H:0.50}
```

---

## 3. Metric Cheat-Sheet

Canonical vector format (9 slashes, no spaces):
```
CVSS:3.1/AV:<x>/AC:<x>/PR:<x>/UI:<x>/S:<x>/C:<x>/I:<x>/A:<x>
```
Example: `CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N`

| Metric | Name | Values (numeric weight) |
|---|---|---|
| AV | Attack Vector | N=0.85 · A=0.62 · L=0.55 · P=0.20 |
| AC | Attack Complexity | L=0.77 · H=0.44 |
| PR | Privileges Required | N=0.85 · L=0.62/0.68 · H=0.27/0.50 (U/C) |
| UI | User Interaction | N=0.85 · R=0.62 |
| S | Scope | U (Unchanged) · C (Changed) |
| C | Confidentiality Impact | H=0.56 · L=0.22 · N=0.0 |
| I | Integrity Impact | H=0.56 · L=0.22 · N=0.0 |
| A | Availability Impact | H=0.56 · L=0.22 · N=0.0 |

### Severity Bands

| Score range | Severity |
|---|---|
| 0.0 | None |
| 0.1 – 3.9 | Low |
| 4.0 – 6.9 | Medium |
| 7.0 – 8.9 | High |
| 9.0 – 10.0 | Critical |

---

## 4. Non-Vulnerability Sentinel

When a commit has no exploitable vuln (CVE-DB bump, version pin, docs-only), the LLM contract and validator both recognise this special value:

```json
{
  "cvss_score": 0.0,
  "cvss_vector": "",
  "cvss_severity": "None",
  "vuln_class_cwe": []
}
```

`parse_vector("")` returns `None` (not an error). The validator treats it as a valid non-vuln marker, not a malformed row. Score and severity checks still run against the claimed values — a non-empty severity or non-zero score on an empty vector still logs a flag.

---

## 5. Validation Outcomes (cvss_aggregate.py)

| Condition | Action |
|---|---|
| `cvss_vector` missing `CVSS:3.1/` prefix | `vector_invalid` → null all 4 cols |
| Wrong metric count / unrecognised value | `vector_invalid` → null all 4 cols |
| `abs(claimed_score − formula_score) > 0.05` | `score_mismatch` → override with formula score |
| `claimed_severity != band(formula_score)` | `severity_mismatch` → override with band |
| Empty CWE list (real vuln row) | `cwe_empty` flag (row kept, not nulled) |
| Non-vuln sentinel (empty vector) | pass-through; score=0.0, severity="None" |

The `CVSS:3.1/` prefix check is the first line of defence — any hallucinated or truncated vector fails immediately, protecting downstream consumers from silent bad data.

**GitLab build stats:** 18,060 rows scored (100%); ~48% score-override rate; 0 malformed vectors after SHA repair. (The 18,060 is the full as-built run; it is fewer than the 18,563-row dataset union because rows with `empty`/`timeout` diffs are excluded from scoring.)

---

## 6. Orchestration (cvss_score.py)

```bash
# 1. Filter, sort, slice
python3 harness/cvss_score.py --prep
# → oracle/analysis/cvss-input.json  (filtered rows — see filter below)
# → oracle/analysis/cvss-batch-NNN.json  (one file per batch of 30)
# → prints tier mix and wave count

# 2. Inspect manifest
python3 harness/cvss_score.py --list

# 3. Emit a filled prompt (for manual dispatch or orchestrator)
python3 harness/cvss_score.py --print 42
```

**`--prep` row filter** (`load_filtered`): keeps rows where `is_security_fix_regate == True` **AND `language != 'ruby'` AND `diff_status not in {empty, timeout}`** (a diff must be present). The harness here scores the **non-Ruby slice**; the Ruby-inclusive as-built run (18,060 rows total) is logged in the [CVSS_ENRICHMENT_RUNBOOK](../../vuln-research/rules/ruby/CVSS_ENRICHMENT_RUNBOOK.md). Re-point or drop the `language` filter to score all languages.

**Batch size = 30** (not 60). Context budget per row: diff capped at 6,000 chars, body at 1,500 chars. At 60 rows the combined input regularly exceeds subagent context windows.

**Sort order inside `--prep`:**

| Priority | Tier |
|---|---|
| 0 | gold commits |
| 1 | weak commits with a diff |
| 2 | weak commits without a diff |

Then by `sha` for stable ordering.

**Dispatch in waves of 16** parallel fixer subagents. Empirical cap — at 32 simultaneous subagents, summary truncation causes partial jsonl output. After each wave: run SHA repair, then aggregate to checkpoint.

---

## 7. SHA Hallucination Repair (fix_shas.py)

LLMs emit plausible-but-wrong 40-char hex strings at roughly 1 per 200–300 output rows. The root cause: long opaque identifiers are a common LLM failure mode.

**The fix:** because the prompt requires output in input order and the batch slice preserves that order, each jsonl line's position uniquely identifies the correct SHA.

```bash
# Detect mismatches without writing
python3 harness/fix_shas.py --report

# Fix all batches
python3 harness/fix_shas.py --all

# Fix specific batches
python3 harness/fix_shas.py 21 25 28 31
```

`fix_shas.py` re-reads `cvss-batch-NNN.json` (source of truth) and overwrites each jsonl line's `sha` field in-place. The scoring payload (vector, score, CWE) is preserved.

**Run fix_shas.py BEFORE aggregating.** A mismatched SHA lands the CVSS data on the wrong commit row; it is not recoverable after parquet write without re-running.

---

## 8. Incremental Mode (--only-cvss)

Use when adding new rows to the dataset without re-scoring the full corpus (e.g., a non-Ruby language batch scored separately).

```bash
python3 harness/cvss_aggregate.py --only-cvss
```

**What it does:**
1. Validates and cleans all `cvss-*.jsonl` (same pipeline as default).
2. In-place update of 4 CVSS cols for any SHA already in `security-commits-cvss.parquet`.
3. Appends non-ruby `regate=false` rows from the master parquet.
4. Deduplicates by `sha` (`keep='first'` — existing base row wins).
5. Writes back to `security-commits-cvss.parquet` only.

**Master parquet (`security-commits.parquet`) is never touched in `--only-cvss` mode.**

The `drop_duplicates(subset='sha', keep='first')` call makes this idempotent — re-running with the same jsonl files produces the same output.

**Non-Ruby re-run result (GitLab build):** 205 rows with diffs scored; severity distribution was Medium-dominant; no Critical rows; appended cleanly with zero duplicates.

---

## 9. Known Limits

- **Weak-no-diff batches are noisier.** Without a diff, the LLM has only the commit subject and body — metric choices for AV/PR/UI are less reliable. These rows sort last in `--prep` and should be treated as lower-confidence in downstream analysis.
- **No temporal or threat adjustment.** Scores are Base Score only (CVSS 3.1 §7.1). No Temporal or Environmental adjustments. Suitable for relative prioritization of fix urgency; not for live vulnerability management dashboards.
- **No ground-truth benchmark.** There is no NVD or CVE-advisory cross-validation for these scores. The validator enforces formula correctness, not real-world accuracy.
- **CWE top-1 dominance.** Top CWEs across the GitLab build: CWE-862, CWE-770, CWE-863, CWE-200, CWE-79, CWE-285, CWE-287, CWE-1333 — auth gaps and XSS dominate. Distribution reflects the GitLab codebase skew, not a universal vuln landscape.

---

## Related Docs

- Previous phase: [./03-tiered-labeling.md](./03-tiered-labeling.md)
- Downstream use: [./07-orchestration-harness.md](./07-orchestration-harness.md)
- Harness scripts: [../harness/](../harness/) (`cvss_score.py`, `cvss_aggregate.py`, `fix_shas.py`, `cvss_prompt.md`)
- Full operational runbook: [../../vuln-research/rules/ruby/CVSS_ENRICHMENT_RUNBOOK.md](../../vuln-research/rules/ruby/CVSS_ENRICHMENT_RUNBOOK.md)
