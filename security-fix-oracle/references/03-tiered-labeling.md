# ML Dataset Design — Tiering, Leakage, and Splits

Packager: `../harness/build_parquet.py` → `oracle/security-commits.parquet`
Siblings: [01-mining-triage.md](./01-mining-triage.md) · [02-diff-fetching.md](./02-diff-fetching.md) · [04-cross-language.md](./04-cross-language.md) · [05-cvss-enrichment.md](./05-cvss-enrichment.md) · [06-szz-attribution.md](./06-szz-attribution.md)

---

> **Read before modeling**
>
> 1. **Train only on `quality_tier = 'gold'`** (1,018 rows, diff-verified). Weak rows disagree with gold on 65 % of their overlap (431 / 657 category mismatches). They are weak-supervision / eval-only. Loader default must filter `quality_tier='gold'`.
> 2. **Never use `vuln_summary`, `rule_idea`, `fix_summary`, `exploit_scenario` as features.** These were generated *from* the text that set the label; 31 %+ embed the category token verbatim. Target leakage. Keep for audit only.
> 3. **Filter `is_security_fix_regate = true`** before any modeling. The upstream binary filter mislabeled ~720 chore/CI/docs commits as security; the regate column corrects them.
> 4. **Never random-split.** Backport families repeat across a random boundary. See the split recipe below.

---

## 1. Quality Tiers

| Tier | Rows | How labeled | `provenance` values | Trainable? |
|------|------|-------------|---------------------|------------|
| `gold` | 1,018 | LLM saw the **actual fix diff** and filled the full schema | `diff-verified` (814) · `diff-verified-nonruby` (204) | **Yes — primary training set** |
| `weak` | 17,545 | LLM saw commit **title + message only** | `message-only` | No — weak supervision / separate eval slice only |

**Why gold wins on SHA collision:** the packager loads weak first, then overwrites with gold on any shared SHA. Gold labels are authoritative.

**Provenance detail for gold:**
- `diff-verified` — Ruby patch read by the diff pass; LLM analyzed `.rb`/`.rake`/`.erb` hunks.
- `diff-verified-nonruby` — 204 rows: Sonnet read a JS/Vue/HAML/Go/GraphQL diff and confirmed a real security fix; fields (`language`, `category`, `cwe`, `sink`, `tainted_input`) overwritten with diff-derived values.

---

## 2. Target-Leakage Discipline

### Never use as features (synthetic leakage)

| Column | Why it leaks |
|--------|--------------|
| `vuln_summary` | LLM wrote this *after* reading the diff and assigning `category`; 31 %+ contain the category token |
| `rule_idea` | Same generation pass — category directly influenced output |
| `fix_summary` | Gold only; generated from the fix context that set the label |
| `exploit_scenario` | Gold only; same origin |

The packager's leakage assertion (`FEATURES = ["subject", "body", "sink", "tainted_input", "diff"]`) confirms these four are excluded from any feature check.

### Safe to use as features (genuine signal)

| Column | Signal quality | Caveat |
|--------|---------------|--------|
| `subject` | High | Raw commit title. A commit titled "fix xss in..." legitimately says "xss" — that is honest signal, not synthetic leakage. |
| `body` | Medium | Full commit message. Same reasoning applies. |
| `diff` | Highest for gold | The fix patch contains the vulnerable code by construction. Usable as a feature precisely because it is honest — you are reading the actual vulnerability. Null for frontend-only and message-only rows. |
| `sink` | High (gold only) | Dangerous API extracted from the diff — not generated from the label, generated from the code. |
| `tainted_input` | High (gold only) | Where untrusted data enters — same origin as `sink`. |
| `diff_chars` / `diff_truncated` | Auxiliary | Useful for length-aware sampling or truncation-aware training. |

---

## 3. Parquet Schema

Output: `oracle/security-commits.parquet` (zstd, ~2.6 MB for the gitlab build). Built by `pa.schema` in `build_parquet.py`.

### Identity / tier

| Column | Type | Notes |
|--------|------|-------|
| `sha` | str | Commit SHA — primary key |
| `date` | str | YYYY-MM-DD authored date |
| `quality_tier` | str | `gold` \| `weak` |
| `provenance` | str | `diff-verified` \| `diff-verified-nonruby` \| `message-only` |
| `source_pass` | str | `diff` \| `message` — which pipeline pass created this row |

### Features

| Column | Type | Notes |
|--------|------|-------|
| `subject` | str | Commit title (all rows) |
| `body` | str | Full commit message; null for 13 rows |
| `diff` | str | Fix patch (`+/-` hunks); capped at 24 KB; null when no code-file changed |
| `diff_chars` | int | Length before cap |
| `diff_truncated` | bool | True if clipped at 24 KB |
| `diff_status` | str | `ok` (Ruby patch) \| `ok-nonruby` \| `empty` (no code files) \| `timeout` \| `not-fetched` |
| `language` | str | `ruby` \| `vue` \| `js` \| `go` \| `haml` \| `graphql` \| null |
| `ruby_files` | list\<str\> | Changed `.rb`/`.rake`/`.erb` paths — **gold only**, null for weak |
| `signals` | list\<str\> | Fix-signal tags (Changelog/security-branch/CVE) — **gold only** |
| `sink` | str | Dangerous API in the diff — **gold only** |
| `tainted_input` | str | Entry point for untrusted data — **gold only** |

### Labels

| Column | Type | Notes |
|--------|------|-------|
| `category` | str | Primary label; one of 25 taxonomy terms ∪ `other`; deterministically normalized |
| `cwe` | list\<str\> | Multi-label `CWE-NNN` |
| `cwe_source` | str | Provenance of `cwe` — see §4 |
| `category_normalized_from` | str | Pre-normalization value if changed; null otherwise |

### Quality signals

| Column | Type | Notes |
|--------|------|-------|
| `label_confidence` | float | 0.3 / 0.6 / 0.9 from low/med/high; gold floored at 0.8 |
| `is_security_fix` | bool | Original upstream verdict — keep for audit, do not filter on this |
| `is_security_fix_regate` | bool | **Filter on this.** Corrected verdict after Haiku re-gate and Sonnet non-Ruby diff review |
| `regate_reason` | str | Why the row was kept or flipped; null if never re-gated |
| `label_disagreement` | bool | For the 657 gold∩weak overlap: did message label differ from diff label? (431 true = 65 %) |
| `near_dup_subject_hash` | str | Fix-family key: merge-branch slug or issue-id-stripped subject, SHA-1 prefixed to 12 chars |

### Metadata — NOT FEATURES

| Column | Type | Notes |
|--------|------|-------|
| `vuln_summary` | str | LLM-generated — audit only |
| `rule_idea` | str | LLM-generated — audit only |
| `fix_summary` | str | Gold only — audit only |
| `exploit_scenario` | str | Gold only — audit only |

---

## 4. `is_security_fix_regate` and `cwe_source`

**Always filter `is_security_fix_regate = true`.** Two passes can flip a row to false:

1. **Haiku regate** (`analysis/regate-*.jsonl`) — re-judged ~728 suspect commits (chore/CI/docs that the upstream message filter passed); 720 flipped to false.
2. **Sonnet non-Ruby diff review** (`regate_reason = 'sonnet-nonruby-diff'`) — 3,012 frontend/styling commits confirmed non-security from their actual diff; stronger than the message regate since it read the patch.

**`cwe_source` provenance (weakest → strongest):**

| Value | Count | Meaning |
|-------|-------|---------|
| `empty` | ~4,717 | `category = 'other'` — no CWE assignable |
| `taxonomy-derived` | ~13,170 | CWE inferred from `TAXONOMY` dict keyed on `category`; not diff-derived |
| `diff-evidence` | 676 | CWE extracted from the diff by the gold-pass LLM; strongest evidence |
| `diff-evidence-nonruby` | ~204 | Same, from the Sonnet non-Ruby analysis pass |

For CWE-sensitive experiments, filter `cwe_source IN ('diff-evidence', 'diff-evidence-nonruby')` to get the 74 % subset with at least taxonomy-derived coverage, or the ~676 with hard diff evidence.

---

## 5. Split Recipe

**Never use a random split.** GitLab applies security fixes as backport merge-trains; the same logical fix appears across multiple branches with nearly identical subjects. A random split puts both sides of a backport pair into train and test, leaking the label.

```python
import duckdb

df = duckdb.sql("""
    SELECT * FROM 'oracle/security-commits.parquet'
    WHERE quality_tier = 'gold'
      AND is_security_fix_regate = true
""").df()

# (a) Temporal holdout — most recent ~6 months as test, mimics deployment
test  = df[df.date >= '2025-12-01']
train = df[df.date <  '2025-12-01']

# (b) Guard near-dup leakage: drop test rows whose fix-family also appears in train
dup_hashes = set(train.near_dup_subject_hash) & set(test.near_dup_subject_hash)
test = test[~test.near_dup_subject_hash.isin(dup_hashes)]

# (c) Gold is small (1,018 rows after filter) — prefer k-fold temporal CV for stable metrics
#     e.g. sklearn.model_selection.TimeSeriesSplit(n_splits=5) on df sorted by date

# (d) Weak rows: use as a separate eval slice only, never in gold training folds
weak = duckdb.sql("""
    SELECT * FROM 'oracle/security-commits.parquet'
    WHERE quality_tier = 'weak'
      AND is_security_fix_regate = true
""").df()

# (e) Report macro-F1 EXCLUDING 'other' — it is a catch-all non-class, not a real vuln type
from sklearn.metrics import f1_score
labels = [c for c in df.category.unique() if c != 'other']
# f1_score(y_true, y_pred, labels=labels, average='macro')
```

---

## 6. Class Support Reality

Gold support (gitlab build, `is_security_fix_regate=true`):

| Category | Gold count | Trainable? |
|----------|-----------|------------|
| auth-session | 387 | Yes |
| other | 209 | Skip in metrics (non-class) |
| secure-config | 75 | Yes |
| rails-misc | 69 | Yes |
| xss | 68 | Yes |
| redos | 62 | Yes |
| path-traversal | ~30s | Marginal |
| deserialization | 2 | Near-untrainable on gold alone |
| cache-poisoning | 2 | Near-untrainable on gold alone |
| zip-slip | 3 | Near-untrainable on gold alone |

For rare classes (< 10 gold rows): consider merging into a parent CWE bucket, using weak rows as pretraining only, or flagging them as out-of-scope for the primary classifier and routing to a binary specialist.

---

## Canonical Build Numbers (gitlab build)

- **Union**: 18,563 rows = 1,018 gold + 17,545 weak
- **Provenance**: message-only 17,413 / diff-verified 946 / diff-verified-nonruby 204 (after Sonnet overlay; 72 gold rows reclassified to nonruby)
- **CWE coverage**: ~74 % (13,659 / 18,563); diff-evidence CWEs: 676
- **Gold∩weak overlap**: 657 rows; category disagreement: 431 (65 %)
- **Regate flips**: 720 weak + 3,012 nonruby = 3,732 rows set to `is_security_fix_regate=false`
