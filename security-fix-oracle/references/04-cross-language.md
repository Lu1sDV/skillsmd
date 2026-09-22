# Phase 4 — Cross-Language Security Fixes (Non-Ruby)

Sibling phases: [01-mining-triage](./01-mining-triage.md) · [02-diff-fetching](./02-diff-fetching.md) · [03-tiered-labeling](./03-tiered-labeling.md) · [07-orchestration-harness](./07-orchestration-harness.md)  
Harness: [`../harness/prep_nonruby.py`](../harness/prep_nonruby.py) · [`../harness/nonruby_analyze.wf.js`](../harness/nonruby_analyze.wf.js)

---

## Why This Phase Exists

A large Rails monorepo's security fixes frequently never touch `.rb` files. The patch lives in:

- Vue/JS/TS frontend components (`v-html` bindings, `innerHTML` writes, URL redirect logic)
- HAML templates (raw output, unsafe interpolation)
- GraphQL resolvers (missing `authorize` calls, field exposure)
- Go services (SSRF, path traversal, input validation)
- SCSS/Less (less common but present for UI-level content injection)

Phase 3 (diff fetching) sets `diff_status='empty'` when `git diff <sha>^1 <sha>` returns nothing for `*.rb` globs. Without phase 4, these commits silently fall out of the corpus. **3,217 candidates** had empty Ruby diffs but were still flagged `is_security_fix_regate=true` by the title-only Haiku pass — 204 of them turned out to be real security fixes. Discarding them would be a systematic blind spot.

Phase 4 also runs a **stronger re-gate** on this population: 3,012 of the 3,217 were frontend churn (styling, test refactors, copy changes) that matched a security keyword in the commit subject. Sonnet diff-level judgement removes them from the security set.

---

## `prep_nonruby.py` — Pure Git I/O, No Model

**Input**: parquet rows where `diff_status IN ('empty', 'timeout') AND is_security_fix_regate`  
**Output**: `oracle/nonruby-analysis-input.json` + appends to `oracle/commit-diffs.jsonl`

### Filter Logic

```
candidates()  →  DuckDB SELECT sha, subject FROM parquet WHERE condition
                 (≈3,217 rows on the GitLab build)

probe(sha, subject):
  1. git diff --name-only sha^1 sha          # list all changed files
  2. keep = [f for f if ext(f) in CODE_EXT]  # code-language filter
  3. if not keep: return None                 # DROP — no code files
  4. git diff sha^1 sha -- <CODE_GLOBS>       # code-restricted diff
  5. truncate diff to 18,000 chars
  6. return {sha, subject, langs, files[:25], diff, truncated}
```

### CODE_EXT Set

| Extension | Language |
|-----------|----------|
| `.js` `.mjs` `.jsx` | JavaScript |
| `.ts` `.tsx` | TypeScript |
| `.vue` | Vue SFC |
| `.coffee` | CoffeeScript |
| `.haml` `.slim` | Template |
| `.go` | Go |
| `.graphql` | GraphQL SDL |
| `.scss` `.less` | CSS preprocessor |

Files **not** matched (dropped as noise): `.md` `.txt` `.yml` `.yaml` `.lock` `.png` `.svg` `.rb` `.json` (config), `.po` `.pot` (translations), `Gemfile*`, `*.gemspec`, CI configs.

### Outputs

| File | Content |
|------|---------|
| `oracle/nonruby-analysis-input.json` | `[{sha, subject, langs, files, diff, truncated}]` — Sonnet input |
| `oracle/commit-diffs.jsonl` (append) | `{sha, tier:"weak", diff, diff_chars, truncated, diff_status:"ok-nonruby"}` — populates parquet diff column |

**Concurrency**: `ThreadPoolExecutor(max_workers=14)` — each `probe()` is two `git` subprocesses; I/O-bound, safe to parallelize aggressively.

### Run

```bash
python3 harness/prep_nonruby.py
# candidate security non-ruby commits: 3217
# KEPT (code-language fixes): N
# language histogram: {'vue': ..., 'js': ..., ...}
# wrote oracle/nonruby-analysis-input.json (N rows) + appended code diffs to commit-diffs.jsonl
```

---

## `nonruby_analyze.wf.js` — Sonnet Subagents

**Model**: `sonnet` (not Haiku — see [Why Sonnet](#why-sonnet-not-haiku))  
**Input**: `nonruby-analysis-input.json` (3,217 rows)  
**Batch size**: 18 commits/agent → ~179 parallel agents on the GitLab build  
**Output dir**: `oracle/analysis/nonruby-NNN.jsonl`

### Workflow Structure

```
args: { input, outDir, batchSize, total }
  ↓
N = ceil(total / batchSize) batches
  ↓
parallel(N agents) — each reads slice [start, end) via:
  python3 -c "import json,sys; d=json.load(open(INPUT))[start:end]; print(json.dumps(d))"
  ↓
each agent writes one JSON line per commit to nonruby-NNN.jsonl
  ↓
return { batches, completed, processed, security_confirmed, dropped_nonsecurity, out_dir }
```

Resumable: if the output `.jsonl` already exists, the agent skips SHAs already present.

### Judgement Rules

**Default**: `is_security_fix=false`. Flip to `true` only with diff evidence of closing a vulnerability:

| Signal in diff | Maps to |
|----------------|---------|
| `v-html` binding added/removed, `innerHTML =`, `dompurify`, `sanitize`, `escape` | XSS fix |
| `authorize`, permission check, role guard added to resolver/component | auth-session |
| Secret/token removed or moved to env var | hardcoded-secrets |
| URL redirect without validation → validation added | open-redirect |
| `fetch`/`axios` target validated against allowlist | SSRF |
| Path join with user input → `realpath`/traversal check | path-traversal |
| GraphQL field gains `authorize` call | auth-session |
| Go `http.Get(userInput)` → validated | SSRF / open-redirect |
| CSRF token added to form/request | auth-session |

**Drop as non-security** (stay false): pure SCSS/Less with no security effect, test-only changes, refactors, copy/i18n, feature work where no vuln is being closed, `diff_status='empty'` that slipped through.

### Gold Schema (one JSON line per commit)

```jsonc
{
  "sha": "abc123",
  "is_security_fix": true,          // bool — false rows still emitted
  "language": "vue",                // vue|js|ts|haml|graphql|go|scss|coffee
  "category": "xss",               // EXACTLY ONE of 26-term taxonomy (below)
  "cwe": ["CWE-79"],               // array; null if is_security_fix=false
  "sink": "v-html binding",        // dangerous API; null if false
  "tainted_input": "user note body",
  "vuln_summary": "...",           // 1 sentence
  "fix_summary": "...",            // 1 sentence
  "rule_idea": "...",              // 1 sentence SAST pattern, or null
  "confidence": "high"             // high|medium|low
}
```

For `is_security_fix=false`: set `category="other"`, all descriptive fields `null`.

### 26-Term Category Taxonomy

`command-injection` · `code-injection` · `sql-injection` · `deserialization` · `ssrf` · `path-traversal` · `zip-slip` · `xss` · `ssti` · `open-redirect` · `mass-assignment` · `redos` · `auth-session` · `crypto-tls` · `xxe` · `mail-header-injection` · `job-injection` · `cache-poisoning` · `render-injection` · `http-parsing` · `hardcoded-secrets` · `insecure-randomness` · `ldap-injection` · `secure-config` · `rails-misc` · `other`

Frontend-dominant categories: `xss`, `open-redirect`, `auth-session`, `secure-config`, `hardcoded-secrets`.

---

## Diff-Level Re-Gate: Both Sides of the Cut

This is a **stronger gate than the title-only / Haiku pass** in phase 3. Because Sonnet reads the actual diff:

| Outcome | Provenance field | Effect |
|---------|-----------------|--------|
| Confirmed real fix | `provenance='diff-verified-nonruby'` | Row enters security corpus |
| Rejected as non-security | `is_security_fix_regate=false`, `regate_reason='sonnet-nonruby-diff'` | Row removed from security set |

Phase 4 therefore does two things simultaneously:
1. **Adds** real non-Ruby security fixes that phase 3 missed (empty Ruby diff)
2. **Removes** frontend false-positives that title-matching incorrectly promoted

72 of the 204 confirmed fixes were previously marked 'gold' via weak signals — they were frontend fixes all along and would have been miscategorized as Ruby fixes without this phase.

---

## Why Sonnet, Not Haiku

Diff-level security judgement is qualitatively harder than title triage:

> "Is this `v-html` removal actually closing an XSS, or is it just a Vue 3 migration refactor?"

That requires reading template context, tracing data flow in the diff, and distinguishing defensive encoding from cosmetic change. Haiku makes systematic errors on this class of question. Use Haiku for scale (thousands of title-only decisions); use Sonnet when the diff must be read and reasoned about.

See [07-orchestration-harness](./07-orchestration-harness.md) for the full model-routing principle and cost/quality tradeoffs across all phases.

---

## GitLab Build Numbers

| Metric | Count |
|--------|-------|
| Candidates probed (empty/timeout Ruby diff, regate=true) | 3,217 |
| **Confirmed real security fixes** | **204** |
| Rejected as non-security | 3,012 |
| Previously 'gold' rows that were frontend fixes all along | 72 |

**By language (confirmed 204)**:

| Language | Fixes |
|----------|-------|
| Vue | 110 |
| JS | 51 |
| Go | 22 |
| HAML | 16 |
| GraphQL | 5 |

**By category (top 5)**:

| Category | Count |
|----------|-------|
| xss | 73 |
| auth-session | 48 |
| secure-config | 21 |
| hardcoded-secrets | 14 |
| open-redirect | 12 |

**Deliverable**: `oracle/nonruby-security-fix-corpus.json` — gold schema rows + diff field, no PII, committable.
