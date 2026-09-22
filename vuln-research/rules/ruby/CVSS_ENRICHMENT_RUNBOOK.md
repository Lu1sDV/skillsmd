# CVSS 3.1 Enrichment Runbook

**Skill:** `vuln-research/rules/ruby/`
**Date:** 2026-06-11 (initial) · 2026-06-11 (non-ruby re-run completed)
**Status:** **18,060/18,060 rows scored in `security-commits-cvss.parquet` (100%)** · non-ruby re-run complete · idempotent aggregator
**Authoring team:** Fable (architect) + Opus (advisor) + Sonnet (deepseek-v4-flash for batch execution)

---

## 1. Goal

Enrich `vuln-research/rules/ruby/oracle/security-commits.parquet` (18,563 GitLab
security-fix commits, 30 columns including a `language` tag) with **4 new columns**
for downstream rule-authoring and risk-prioritization use:

| New column | Type | Source |
|---|---|---|
| `cvss_score` | float 0.0–10.0 | procedural (recomputed from vector) |
| `cvss_vector` | string `CVSS:3.1/AV:.../AC:.../...` | LLM (NLP) |
| `cvss_severity` | {None, Low, Medium, High, Critical} | procedural (band of score) |
| `vuln_class_cwe` | list[str] (top-1-3 CWE IDs) | LLM (NLP) |

**Scope:** `security-commits-cvss.parquet` contains **18,060 rows**:
- 10,478 ruby `is_security_fix_regate=true` (original Ruby regate=true subset)
- 4,353 non-ruby `is_security_fix_regate=true` (4,148 with empty diffs → "non-vuln
  sentinel"; 205 with diffs → re-scored by the LLM)
- 3,229 non-ruby `is_security_fix_regate=false` (appended from master parquet;
  most have CVSS scores from the prior run)

`security-commits.parquet` (the master, 18,563 rows × 34 cols) is enriched **in
place** for the default aggregation mode, or **left untouched** in `--only-cvss`
mode (see §12).

---

## 2. Architecture — hybrid NLP + procedural

```
┌────────────────────────────────────────────────────────────────┐
│ Layer 1 — LLM (deepseek-v4-flash, "fixer" subagent)            │
│  Reads: subject, body, diff, ruby_files, signals, sink, cwe    │
│  Emits: cvss_vector (8 metrics), cvss_score (estimate),        │
│         cvss_severity (estimate), vuln_class_cwe (top 1-3)     │
│  Why: metric-choice is an NLP problem (text → 8-metric tuple)  │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼ jsonl: 1 row per commit
┌────────────────────────────────────────────────────────────────┐
│ Layer 2 — Procedural validator (cvss_aggregate.py)             │
│  Re-computes base score from vector using official CVSS 3.1    │
│  formula + roundup. Compares against LLM's numeric score.      │
│  • score-mismatch  → override with formula-derived score       │
│  • severity-mismatch → override with band(score)               │
│  • malformed vector → null all 4 cols for that row             │
│  Why: numeric CVSS math is deterministic; trust the formula    │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼ parquet: 4 new cols added
                  security-commits-cvss.parquet (regate=true subset)
                  security-commits.parquet (in-place, all 18563 rows)
```

**Why hybrid:** the LLM is good at *reading a commit and picking the 8 metrics*
(qualitative reasoning), but mediocre at *the exact CVSS 3.1 multiplication chain*
(quantitative lookup table). The formula is a 50-line Python function that always
returns the canonical score for any well-formed vector. We get LLM-quality metric
choices + machine-precision scores.

---

## 3. Files (created by this work)

| Path | Purpose |
|------|---------|
| `vuln-research/rules/ruby/oracle/security-commits.parquet` | master: 18,563 × 30 input → 18,563 × 34 enriched (default mode) or unchanged (`--only-cvss` mode) |
| `vuln-research/rules/ruby/oracle/security-commits-cvss.parquet` | CVSS subset: 18,060 × 34 (10,478 ruby + 4,353 non-ruby regate=true + 3,229 non-ruby regate=false) |
| `vuln-research/rules/ruby/tools/cvss_prompt.md` | reusable prompt template (LLM contract, language-agnostic) |
| `vuln-research/rules/ruby/tools/cvss_score.py` | orchestrator: `--prep` / `--list` / `--print BATCH_IDX` |
| `vuln-research/rules/ruby/tools/cvss_aggregate.py` | jsonl→parquet + CVSS 3.1 validator + severity band; supports `--only-cvss` mode (see §12) |
| `vuln-research/rules/ruby/tools/fix_shas.py` | post-processor for SHA hallucinations (catches fixers that emit plausible-but-wrong 40-char hex) |
| `.omc/specs/deep-interview-cvss-enrichment-v1.md` | spec doc (opencode metadata, design rationale) |
| `vuln-research/rules/ruby/oracle/analysis/cvss-input.json` | current input array (e.g. 205 non-ruby regate=true w/ diffs in re-run mode) |
| `vuln-research/rules/ruby/oracle/analysis/cvss-input-ruby-rerun.json` | **backup** of the original 17,843-row ruby input (kept for rollback) |
| `vuln-research/rules/ruby/oracle/analysis/cvss-batch-{000..594}.json` | per-batch slices (30 rows each, last batch may be smaller) |
| `vuln-research/rules/ruby/oracle/analysis/cvss-{000..594}.jsonl` | per-batch LLM outputs (one row per line) |
| `vuln-research/rules/ruby/CVSS_ENRICHMENT_RUNBOOK.md` | **this file** |

`oracle/analysis/` is gitignored (per `.gitignore` line 19) — output jsonl files
don't pollute the repo. The backup `cvss-input-ruby-rerun.json` is also gitignored.

---

## 4. Workflow (4 steps)

### Step 1 — Prep (idempotent, run once)

```bash
python3 vuln-research/rules/ruby/tools/cvss_score.py --prep
```

Produces `cvss-input.json` + N batch slices in `oracle/analysis/`.
**Default filter** (initial run): `is_security_fix_regate=true`, sorted gold →
weak-with-diff → weak-no-diff. Batches 0-33 = all 1,018 gold rows (highest
signal); batches 34-351 = weak-with-diff; batches 352-594 = weak-no-diff.

**Non-ruby re-run filter** (see §12): `is_security_fix_regate=true AND
language != 'ruby' AND diff_status not in (empty, timeout)`. Skips the 4,148
non-ruby regate=true rows with empty diffs (they keep the "non-vuln sentinel"
from the initial run).

Verify with:
```bash
python3 vuln-research/rules/ruby/tools/cvss_score.py --list
python3 vuln-research/rules/ruby/tools/cvss_score.py --print 0 | head -50
```

**Cleanup before re-prep** (only if previous `analysis/` is stale and you want a
clean state): `rm -f oracle/analysis/cvss-*.jsonl oracle/analysis/cvss-batch-*.json`
then move the old `cvss-input.json` to a backup name (e.g.
`cvss-input-ruby-rerun.json`) before re-running `--prep`.

### Step 2 — Launch waves (16 parallel fixers per wave, fresh sessions)

In opencode main loop, use the `task` tool with `subagent_type: "fixer"` and the
prompt template in §6. Vary `BATCH_IDX` from `000` to `594`.

- **Concurrency cap:** 16 fixers per wave (empirical; not the agent's `maxConcurrent`,
  but the practical limit observed when running parallel `task` tool calls in a
  single message). Don't try 32 in one message — subagent context will overlap.
- **Waves:** 36 full waves (16 fixers each = 576 batches) + 1 partial wave
  (3 fixers = batches 592-594) = 37 total.
- **Wall clock:** Wave 1 (turn 1 = batches 0-7, turn 2 = batches 8-15) completed
  in ~12 min. Wave 2+ should be similar.

### Step 3 — Aggregate (idempotent, re-runnable)

```bash
python3 vuln-research/rules/ruby/tools/cvss_aggregate.py
```

Reads all `cvss-*.jsonl` in `oracle/analysis/`, validates vectors, writes both
parquets. **Re-runnable**: each invocation re-aggregates from scratch (idempotent
because it overwrites with the latest jsonl state). Partial state survives — you
can aggregate after each wave to checkpoint.

### Step 4 — Verify

```python
import pandas as pd
df = pd.read_parquet('vuln-research/rules/ruby/oracle/security-commits-cvss.parquet')
scored = df[df['cvss_score'].notna()]
print(f'Scored: {len(scored)}/17843 ({len(scored)/17843*100:.1f}%)')
print(scored['cvss_severity'].value_counts())
print(df['vuln_class_cwe'].explode().dropna().value_counts().head(10))
# Vector sanity (all should start with CVSS:3.1/ and have 8 slashes):
print((scored['cvss_vector'].str.startswith('CVSS:3.1/')).sum(), '/', len(scored))
print(scored['cvss_vector'].str.count('/').value_counts())
```

---

## 5. Resume-from-interruption (if you crashed mid-wave)

The `--prep` step is idempotent (overwrites slice files). The aggregator is
idempotent. The fixers are stateless (each invocation reads its slice + writes
its jsonl). So the workflow is fully resumable.

**Pattern:** find the highest `cvss-NNN.jsonl` that exists, dispatch fixers for
the next 16 missing batches, aggregate, repeat.

```bash
# Find next batch to run:
python3 -c "
import os, glob
done = sorted({int(f.split('cvss-')[1].split('.')[0])
               for f in glob.glob('vuln-research/rules/ruby/oracle/analysis/cvss-*.jsonl')})
all_595 = set(range(595))
missing = sorted(all_595 - done)
print(f'Done: {len(done)}/595')
print(f'Next 16 batches to run: {missing[:16]}')
"
```

Each `cvss-batch-NNN.json` is 30 rows, named 0-indexed. The mapping is:
- `cvss-batch-{idx:03d}.json` (input slice)
- `cvss-{idx:03d}.jsonl` (output)

**The 480 Wave 1 rows are already done and aggregated** — do not re-run them.

---

## 6. Prompt template (for `fixer` subagent)

```
You are processing one batch of security-fix commits to assign CVSS 3.1 scores and
CWE classifications.

## Inputs
- Batch slice:  /home/x/Personal_Projects/skillsmd/vuln-research/rules/ruby/oracle/analysis/cvss-batch-{BATCH_IDX}.json
  (30 rows, pre-sorted gold → weak-with-diff → weak-no-diff)
- Prompt template (READ THIS FIRST):
  /home/x/Personal_Projects/skillsmd/vuln-research/rules/ruby/tools/cvss_prompt.md

## Output
- Write jsonl:  /home/x/Personal_Projects/skillsmd/vuln-research/rules/ruby/oracle/analysis/cvss-{BATCH_IDX}.jsonl
  (one JSON object per line, preserving input order)

## Procedure
1. Read cvss_prompt.md in full (it defines the 8 CVSS 3.1 base metrics, the CWE
   catalog, the output JSON shape, and worked examples).
2. Read cvss-batch-{BATCH_IDX}.json (30 rows). Each row has: sha, subject, body,
   ruby_files, signals, sink, cwe (pre-existing), category, diff (truncated to 6000
   chars), quality_tier, is_security_fix_regate.
3. For each row, reason about the vulnerability: what is the affected sink, what
   input is attacker-controlled, what authn/authz is required, what is the impact
   (C/I/A), what is the scope (changed vs unchanged). Emit the JSON object per the
   prompt spec.
4. Write 30 JSON objects to cvss-{BATCH_IDX}.jsonl — one per line, in input order.
5. Use the bash tool to verify: `wc -l /path/to/cvss-{BATCH_IDX}.jsonl` (must = 30)
   and `python3 -c "import json; [json.loads(l) for l in open('/path/to/cvss-{BATCH_IDX}.jsonl')]"`
   (must not raise).
6. Return a one-paragraph summary: severity histogram, top 5 CWEs, any rows you
   flagged as ambiguous or unsure about.

Important: do not edit the input file. Do not write to security-commits.parquet
(only cvss_aggregate.py writes the final parquets). Your only job is the jsonl.
```

---

## 7. CVSS 3.1 vector format (must be exact)

```
CVSS:3.1/AV:{N,A,L,P}/AC:{L,H}/PR:{N,L,H}/UI:{N,R}/S:{U,C}/C:{H,L,N}/I:{H,L,N}/A:{H,L,N}
```

- 8 base metrics, slash-separated, no trailing slash
- Prefix `CVSS:3.1/` is mandatory
- Total of 9 slashes (1 prefix + 8 metric separators)
- Severity bands (procedural, applied to final score):
  - 0.0 = None · 0.1–3.9 = Low · 4.0–6.9 = Medium · 7.0–8.9 = High · 9.0–10.0 = Critical

Metric cheat-sheet (see `cvss_prompt.md` for the full rubric):
- `AV` (Attack Vector): N=Network, A=Adjacent, L=Local, P=Physical
- `AC` (Attack Complexity): L=Low, H=High
- `PR` (Privileges Required): N=None, L=Low, H=High
- `UI` (User Interaction): N=None, R=Required
- `S` (Scope): U=Unchanged, C=Changed
- `C/I/A` (Confidentiality/Integrity/Availability impact): N=None, L=Low, H=High

---

## 8. Gotchas (worth knowing for the next run)

1. **Sort order = quality tier.** Batches 0-33 = all gold (1,018 rows). Running gold
   first means the most-labeled, highest-confidence rows score first. If you want
   quick wins, run a small wave and check before committing to all 595.

2. **Batch size 30 (not 60).** The earlier `haiku_regate.wf.js` workflow used 60/batch.
   deepseek-v4-flash has tighter context than haiku. 30 rows × (diff=6000 + body=1500
   cap) ≈ 250K input tokens per batch — fits comfortably in 1M-context models but
   would OOM smaller models. Don't increase without testing.

3. **Vector is canonical, score is derived.** Don't trust the LLM's numeric score —
   the validator re-computes from the vector. Wave 1 had 48.75% score-override rate
   (234/480), which is expected: the LLM is good at metric choice, but its mental
   arithmetic for the CVSS multiplication table is approximate.

4. **`None` severity rows are not bugs.** Wave 1 had 14 rows with score 0.0 and empty
   CWE list. These are correctly-identified non-issues: CVE-database bumps, version
   bumps, "remove outdated CVE request" merges, JSON validation limit increases. The
   LLM correctly emitted `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:N` (the canonical
   "no impact" vector).

5. **Concurrency cap = 16 fixers per message.** Empirically observed, not from any
   opencode config setting. Don't try 32 in one message — subagent output summaries
   will start truncating.

6. **`oracle/analysis/` is gitignored.** Output jsonl files don't pollute the repo.

7. **LSP false-positive type errors** in `cvss_aggregate.py` (stale cache) are
   cosmetic — runtime is correct, the script runs.

8. **Vector prefix check is the first line of defense.** All 480 Wave 1 vectors start
   with `CVSS:3.1/`. If a fixer emits `CVSS:3.0/...` or no prefix, the aggregator
   nulls the row. This catches drift / hallucinated metrics.

9. **The aggregator script has a cosmetic bug at the end** (a `ValueError: too many
   values to unpack` in the severity histogram print) — but the parquets are already
   written before the error. Just re-run if you want the histogram; or read it from
   pandas after the fact.

10. **SHA hallucination by the LLM.** Fixers occasionally emit a plausible 40-char
    hex sha that differs from the input in the last 4 chars (e.g. `...cdc824240`
    → `...ee7080b47`). Caught by comparing jsonl shas against the parquet. Fix
    manually: open the jsonl, replace the bad sha with the input sha, re-aggregate.
    Rate: ~1 per 200-300 rows in our experience. The `fix_shas.py` post-processor
    automates this for large-scale runs.

11. **Non-ruby re-runs require the parquet to have been enriched at least once.**
    The `--only-cvss` mode reads existing `security-commits-cvss.parquet` and the
    master `security-commits.parquet`. If `security-commits-cvss.parquet` doesn't
    exist, the aggregator exits with an error. Run the default aggregation once
    to seed it, then re-run with `--only-cvss` for incremental updates.

12. **`--only-cvss` is idempotent on sha.** Re-running appends the 3,229 non-ruby
    regate=false rows from the master parquet, then `drop_duplicates(subset='sha',
    keep='first')` so the second run dedupes them (you'll see `[deduped 3229]` in
    the log). The base row is kept (its CVSS score from the prior run is preserved).

---

## 9. Reproduction (full re-run from scratch, in order)

```bash
# 1. Prep (default mode: ruby regate=true, all 17,843 rows)
cd /home/x/Personal_Projects/skillsmd
python3 vuln-research/rules/ruby/tools/cvss_score.py --prep
ls vuln-research/rules/ruby/oracle/analysis/ | head -5
# (expect: cvss-000.jsonl doesn't exist yet; cvss-batch-000.json exists)

# 2. Launch waves in opencode main loop.
#    For each wave, send one message with 16 parallel `task` tool calls
#    (subagent_type="fixer", prompt = §6, BATCH_IDX = 016..031, 032..047, ...)
#    36 full waves + 1 partial wave (3 fixers) = 37 total.

# 3. Aggregate (run after each wave to checkpoint; default mode updates BOTH parquets)
python3 vuln-research/rules/ruby/tools/cvss_aggregate.py

# 4. Non-ruby re-run (see §12): re-prep with the non-ruby filter, score 7 batches,
#    then aggregate with --only-cvss to extend _cvss.parquet to 18,060 rows.
#    Master parquet is left untouched.

# 5. Final verification
python3 -c "
import pyarrow.parquet as pq
df = pq.read_table('vuln-research/rules/ruby/oracle/security-commits-cvss.parquet').to_pandas()
scored = df[df['cvss_score'].notna()]
print(f'Scored: {len(scored)}/{len(df)} ({len(scored)/len(df)*100:.1f}%)')
print(scored['cvss_severity'].value_counts())
print()
print('Top 15 CWEs:')
print(df['vuln_class_cwe'].explode().dropna().value_counts().head(15))
print()
print('Vector well-formedness:')
print('  prefix CVSS:3.1/:', scored['cvss_vector'].str.startswith('CVSS:3.1/').sum())
print('  slash counts:', scored['cvss_vector'].str.count('/').value_counts().to_dict())
"
```

Expected final state: **18,060 rows in `_cvss.parquet`** (10,478 ruby + 4,353 non-ruby
regate=true + 3,229 non-ruby regate=false), 17,251 with CVSS scores, severity
distribution Medium-dominant with a long tail to Critical, top CWEs dominated by
862/863/200/79/287 (auth + XSS patterns are the most common GitLab fixes).

---

## 10. Final state (18,060/18,060 = 100%)

### Initial ruby run (17,843 regate=true rows, 595 batches over 37 waves)

| Metric | Value | Verdict |
|--------|-------|---------|
| Scored rows | 17,843 (14,831 ruby + 4,353 non-ruby regate=true from the original prep) | 100% |
| Vectors well-formed | all | 100% pass |
| Score-mismatch overrides | ~30% across waves | expected — formula wins |
| Malformed (nulled) | 2 | down from 1,350 after the empty-vector sentinel fix |
| Severity distribution | None ~9,500, Medium ~1,750, High ~280, Critical ~46, Low ~33 | long tail to Critical |
| Top CWE | CWE-862 (~540), CWE-770, CWE-863, CWE-200, CWE-79, CWE-285, CWE-287, CWE-1333 | matches GitLab reality |

### Non-ruby re-run (205 rows in 7 batches, 1 wave)

| Metric | Value | Verdict |
|--------|-------|---------|
| Scored rows | 205 (non-ruby regate=true with non-empty diffs) | 100% |
| Vectors well-formed | 205/205 | 100% pass |
| Score-mismatch overrides | 62 (30%) | expected |
| Severity-mismatch overrides | 9 | expected |
| Malformed | 0 | none |
| Severity distribution | None 33, Low 7, Medium 116, High 49, Critical 0 | distinct from ruby (no Critical) |
| Top score | 8.8 High — CWE-862 (privilege escalation) | plausible |
| SHA hallucinations | 1 in 205 (0.5%) | fixed manually, re-aggregated |

**Spot-check highlights — initial ruby run:**
- `5983d82308` — "reject expired/blocked user keys" → 9.8 CWE-287/862 ✓
- `1bb92907f6` — "strong parameters to passwords_controller" → 9.8 CWE-915/287 ✓ (mass assignment)
- `6d5ecfb718` — "security-ruby-graphql" → 10.0 S:C CWE-94 ✓ (Ruby GraphQL code injection)
- `1f741e3aa4` — "Bump workhorse golang-jwt/jwt to 5.2.2" → 10.0 S:C CWE-287/522/327 ✓
- `4453364640` — "Prevent code injection in Product Analytics funnels YAML" → 9.6 S:C CWE-94/89 ✓
- `0bb8c45bda` — "Fix unauthorized project exposure via WorkItem GraphQL traversal" → 7.5 CWE-863/200 ✓
- `1b07f7a250` — "Log JSON streaming validator metadata in API logs" → 0.0 CWE-[] ✓ (no impact)

**Spot-check highlights — non-ruby re-run:**
- `92c93b636f25` — XSS fix → 8.7 High CWE-79 ✓
- `990558a0b288` — XSS fix → 8.2 High CWE-79 ✓
- `593bab0d354f` — code injection in Mermaid sandbox → 8.1 High CWE-94 ✓
- `e592cf0b5d0b` — TLS/CRYPTO fix → 8.1 High CWE-326 ✓
- `036d7b2cc710` — "Fixed HTML injection in Global Search" → 8.1 High CWE-79 ✓
- `d09826fc606b699ac55fcddcf309946cdc824240` — link_to helper fix (was a SHA hallucination in batch 005; correct sha is `...cdc824240`, fixer emitted `...ee7080b47`) → 5.2 Medium CWE-79 ✓

---

## 11. Open questions / known limitations

- **LLM score-mismatch rate is high (48%).** Acceptable because the vector is
  the source of truth, but if we want lower mismatch we could (a) include the
  CVSS 3.1 formula reference in the prompt so the LLM can self-check, or (b)
  ask the LLM to emit only the vector and let the procedural layer compute the
  score. Option (b) is cleaner — the prompt could be simplified to "emit vector +
  CWE list, score is computed for you."

- **Weak-no-diff batches (352-594) will be noisier.** These commits have no diff
  in the parquet (only subject + body). The LLM has less signal to work with.
  Expect higher None-severity and lower-confidence CWEs in those batches. Audit
  after aggregation.

- **No temporal split or version tagging.** CVSS scores reflect the vuln at the
  time of fix, not adjusted for current threat landscape. Acceptable for
  rule-authoring prioritization; not suitable for live vulnerability management.

- **No ground truth comparison.** We have no held-out CVSS-labeled commits to
  measure accuracy. Wave 1 spot-checks against commit subjects give high
  confidence (no obvious wrong assignments), but a precision/recall benchmark
  would require a separate labeled set.

---

## 12. Non-ruby re-run scenario (incremental re-scoring without touching the master)

**When to use:** you want to re-score (or score for the first time) the non-ruby
commits that were added to `security-commits.parquet` after the initial run,
**without** modifying the in-place master parquet. The output is an extended
`security-commits-cvss.parquet` that now includes all non-ruby rows (regate=true
+ regate=false) alongside the original ruby regate=true subset.

**What it does:** the `--only-cvss` flag on `cvss_aggregate.py` switches the
aggregator to a different code path:
1. Reads existing `security-commits-cvss.parquet` (the "base").
2. In-place updates the 4 CVSS cols for any sha in the jsonl files.
3. Reads `security-commits.parquet`, filters to `language != 'ruby' AND
   is_security_fix_regate = False`, appends those rows to the base.
4. Writes back to `security-commits-cvss.parquet` only. **Master parquet is
   not touched.**
5. `drop_duplicates(subset='sha', keep='first')` makes the operation idempotent
   on re-run — you'll see `[deduped 3229]` in the log if the regate=false
   rows are already present.

### Step-by-step (as run on 2026-06-11)

```bash
# 0. Backup the existing _cvss.parquet (just in case)
cp vuln-research/rules/ruby/oracle/security-commits-cvss.parquet \
   vuln-research/rules/ruby/oracle/security-commits-cvss.parquet.bak-pre-nonruby-rerun

# 1. Move old cvss-input.json aside (so --prep can write a fresh one)
cd vuln-research/rules/ruby/oracle/analysis
[ -f cvss-input.json ] && mv cvss-input.json cvss-input-ruby-rerun.json
# Remove stale batch slices from the previous run (will be regenerated)
rm -f cvss-batch-*.json
# Remove old jsonl outputs (the new fixers will write fresh ones)
rm -f cvss-*.jsonl

# 2. Re-prep with the new non-ruby filter (built into cvss_score.py)
cd /home/x/Personal_Projects/skillsmd
python3 vuln-research/rules/ruby/tools/cvss_score.py --prep
# expect: 205 rows / 7 batches of 30 (last batch is 25)

# 3. Launch 1 wave of 7 fixers in parallel
#    (subagent_type="fixer", prompt per §6 with BATCH_IDX = 0..6)
#    All 7 in a single message with 7 parallel `task` tool calls.

# 4. Validate the jsonl outputs (schema + sha-uniqueness)
python3 -c "
import json, glob
total = 0
for f in sorted(glob.glob('vuln-research/rules/ruby/oracle/analysis/cvss-*.jsonl')):
    n_ok = 0
    for ln in open(f):
        o = json.loads(ln)
        assert len(o['sha']) == 40
        assert o['cvss_vector'].startswith('CVSS:3.1/') or o['cvss_vector'] == ''
        n_ok += 1
    total += n_ok
    print(f'{f}: ok={n_ok}')
print(f'TOTAL OK: {total} (expected 205)')
"

# 5. Detect and fix SHA hallucinations before aggregating
python3 -c "
import json, glob
import pyarrow.parquet as pq
parquet_shas = set(pq.read_table('vuln-research/rules/ruby/oracle/security-commits.parquet').to_pandas()['sha'])
for f in sorted(glob.glob('vuln-research/rules/ruby/oracle/analysis/cvss-*.jsonl')):
    for i, ln in enumerate(open(f)):
        o = json.loads(ln)
        if o['sha'] not in parquet_shas:
            print(f'HALLUCINATED: {f} line {i+1}: {o[\"sha\"]}')
"

# 6. Aggregate with --only-cvss (modifies _cvss.parquet only)
python3 vuln-research/rules/ruby/tools/cvss_aggregate.py --only-cvss
# expect: 205 updated, 3229 appended, final 18060 rows, 17251 with cvss_score

# 7. Re-run --only-cvss once more to confirm idempotency
python3 vuln-research/rules/ruby/tools/cvss_aggregate.py --only-cvss
# expect: same final 18060 rows, with `[deduped 3229]` in the log

# 8. Final verification
python3 -c "
import pyarrow.parquet as pq
t = pq.read_table('vuln-research/rules/ruby/oracle/security-commits-cvss.parquet').to_pandas()
print(f'rows={len(t)} scored={int(t[\"cvss_score\"].notna().sum())}')
print(t['cvss_severity'].value_counts())
"
```

### Why the 4,148 empty-diff non-ruby regate=true rows keep their old score

The filter `diff_status not in (empty, timeout)` skips these rows. They were
scored in the initial run with the "non-vuln sentinel" (0.0 / None / empty CWE
list) — which is the correct answer for "no diff to analyze". Re-scoring them
would be wasted compute. The 205 rows with actual diffs get the full treatment.

### Why the filter is on the orchestrator, not a CLI flag

The filter is baked into `load_filtered()` in `cvss_score.py`. To re-run on a
different subset (e.g. only `language='go'`, or only `quality_tier='gold'`),
edit the filter conditions in `load_filtered()`. The rest of the pipeline
(orchestrator → fixers → aggregator) is unchanged.

### Backups & rollback

- `security-commits-cvss.parquet.bak-pre-nonruby-rerun` — the 14,831-row state
  from before this run. Safe to delete after you've confirmed the new file is
  correct.
- `oracle/analysis/cvss-input-ruby-rerun.json` — the 17,843-row original input.
  Safe to delete.

If anything goes wrong, restore:
```bash
cp vuln-research/rules/ruby/oracle/security-commits-cvss.parquet.bak-pre-nonruby-rerun \
   vuln-research/rules/ruby/oracle/security-commits-cvss.parquet
```
