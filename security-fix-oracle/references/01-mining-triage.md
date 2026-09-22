# Phase 1 + 2: Mine & Triage — Git History → Labeled Security Dataset

Two Workflow harnesses turn a bare git clone into a labeled JSONL dataset:
- **Phase 1** (`gitlab_haiku_analysis.wf.js`): two-pass Haiku triage over all commits
- **Phase 2** (`haiku_regate.wf.js`): default-deny re-gate on the suspect subset

---

## Two-Pass Triage Design

| Pass | Mode | Input | Scale | Batch size | What it produces |
|------|------|-------|-------|-----------|-----------------|
| 1a — coarse | `message` | title + body only, NO diff, no network | ALL commits | 80/agent | `is_security_fix`, `confidence`, `category`, `needs_diff` per commit |
| 1b — precise | `diff` | title + body + Ruby diff (`*.rb *.rake *.erb`) via `git show` | Security-relevant subset only | 25/agent | Full root-cause fields: `sink`, `tainted_input`, `exploit_scenario`, `rule_idea` |

**Why two passes, not one:**
- Haiku message pass is near-free at scale (~$0.25 per 10k commits). Running it over 189k commits to filter down to 18k candidates is cheaper than running diff-fetch on all 189k.
- `git show` on large repos is I/O-heavy; fetching diffs for 171k irrelevant commits wastes both time and tokens.
- Message pass is intentionally coarse — `needs_diff:true` signals where diff-pass precision is worth the cost.

**Efficiency note — message pass sub-chunking:** agents work in sub-chunks of ~30 commits per reasoning step, classifying all 30 in one step and appending them in a single write (python heredoc). This avoids one reasoning turn per commit across 80-commit batches.

---

## The 26-Term Taxonomy

Used as the `category` field in both passes. Agents must pick exactly one.

```
command-injection, code-injection, sql-injection, deserialization, ssrf,
path-traversal, zip-slip, xss, ssti, open-redirect, mass-assignment,
redos, auth-session, crypto-tls, xxe, mail-header-injection, job-injection,
cache-poisoning, render-injection, http-parsing, hardcoded-secrets,
insecure-randomness, ldap-injection, secure-config, rails-misc, other
```

`rails-misc` catches Rails-specific patterns that don't map cleanly to a CWE bucket (e.g., `protect_from_forgery` gaps, `skip_before_action` misuse). `other` is a last resort — a high `other` rate signals taxonomy gaps.

---

## Per-Row JSONL Schema

### Message pass (`msg-NNNN.jsonl`)

```jsonc
{
  "sha":          "abc123",          // full or abbreviated commit SHA
  "date":         "2023-04-01",
  "subject":      "Fix XSS in widget renderer",  // commit title
  "is_security_fix": true,           // bool — primary label
  "confidence":   "high",            // "high" | "medium" | "low"
  "category":     "xss",             // one of the 26 taxonomy terms
  "cwe":          ["CWE-79"],        // [] if unknown
  "vuln_summary": "Unescaped user input rendered in ERB template",
  "rule_idea":    "Flag raw ERB interpolation of request params in view files",
  "needs_diff":   false              // true → include in diff-pass input
}
```

### Diff pass (`diff-NNNN.jsonl`)

All message-pass fields plus:

```jsonc
{
  // ... all message-pass fields ...,
  "signals":          "body mentions 'sanitize', branch 'security-patch-2023'",
  "fix_summary":      "Replaced raw interpolation with html_escape(); added CSP header",
  "tainted_input":    "params[:widget_name] via GET /widgets",
  "sink":             "ERB::Util.html_escape (was missing)",
  "exploit_scenario": "Attacker sets widget_name=<script>...; rendered to all viewers",
  "ruby_files":       ["app/views/widgets/show.html.erb", "app/helpers/widget_helper.rb"],
  "diff_available":   true           // false if git show timed out / empty Ruby hunks
}
```

**Sink field note:** `sink` is the dangerous API/operation patched by the fix (e.g. `Kernel#system`, `ActiveRecord::Base.connection.execute`, `render inline:`). Empty string when not determinable from diff alone.

---

## Phase 2: Re-Gate (Suspect Pool)

**Harness:** `haiku_regate.wf.js` — batch size 60, all in a single `parallel()` wave.

### What "suspect" means

Commits where the message pass set `is_security_fix:true` but the subject matches noise patterns: flaky-test quarantine, rubocop/lint todo regeneration, translations/i18n, docs-only, dependency version bumps without security notes, automatic master merges, screenshot/fixture/changelog updates.

These are extracted into `regate-input.json` (array of `{sha, subject, body, orig_category, orig_confidence}`) before the re-gate run.

### Decision rule — default-deny

```
is_security_fix_regate = false  ← DEFAULT for all suspects
```

Flip to `true` ONLY with positive evidence in title or body:

| Evidence type | Example |
|---------------|---------|
| CVE/CWE reference | `Fixes CVE-2023-12345` |
| Named vuln class | `xss`, `csrf`, `ssrf`, `injection`, `path traversal`, `IDOR`, `secret leak`, `redos` |
| Security branch/MR | `security-*` branch name |
| Sanitization/authz change | "add sanitization", "check permissions", "restrict access" |
| Security advisory on dep bump | `bump rack (CVE-2023-...)` |

A dependency bump with no CVE/advisory does NOT count.

### Re-gate output (`regate-NNN.jsonl`)

```jsonc
{
  "sha":                    "def456",
  "is_security_fix_regate": false,
  "regate_reason":          "rubocop todo regeneration commit, no security substance",
  "regate_confidence":      "high"
}
```

### Why default-deny on suspects only is cheaper and higher-precision

- Re-judging all 18k security-flagged rows would cost ~3× the original message pass.
- The suspect pool (~728 rows) is selected specifically because the signal is low; default-deny minimizes FP contamination in the gold set without re-paying the full triage cost.
- Non-suspect rows (strong titles, CVEs, security-branch merges) are left as-is — they already pass a high-confidence bar.

---

## Resumability

Both harnesses skip SHAs already present in the agent's output file before writing new rows:

```
if <outFile> exists → collect all "sha" values already written → skip them (count as skipped_existing)
```

Safe to kill and re-run at any point. Partial batches resume from where they stopped. Aggregate counts (`processed`, `security_fixes`) reflect only new work in that run.

---

## How to Run

Pass args as a JSON object (or JSON string). The harness normalizes both.

### Message pass — full corpus triage

```js
// Workflow tool invocation args
{
  mode:      "message",
  manifest:  "/path/to/commits.jsonl",   // JSONL: one {sha,date,subject,body} per line
  total:     189000,                      // total line count of manifest
  batchSize: 80,                          // optional, default 80
  repo:      "/path/to/gitlab",           // git clone root (not used in message pass)
  outDir:    "/path/to/oracle/analysis",
  tag:       "msg-run1"                   // label prefix for agent traces
}
```

### Diff pass — security-relevant subset

```js
{
  mode:      "diff",
  manifest:  "/path/to/security-candidates.json",  // JSON: {commits:[{sha,date,subject,body,signals}]}
  total:     18202,
  batchSize: 25,                                    // optional, default 25
  repo:      "/path/to/gitlab",                     // required: git show runs here
  outDir:    "/path/to/oracle/analysis",
  tag:       "diff-run1"
}
```

### Re-gate pass — suspect pool

```js
// haiku_regate.wf.js args
{
  input:     "/path/to/oracle/regate-input.json",   // array of suspect rows
  outDir:    "/path/to/oracle/analysis",
  batchSize: 60,                                     // optional, default 60
  total:     728                                     // length of input array
}
// Note: no mode/manifest/repo/tag — regate has its own args shape
```

---

## gitlab-org/gitlab Build Results

| Stage | Count | Notes |
|-------|-------|-------|
| Commits triaged (message pass) | ~189,000 | Full repo history |
| Security-relevant flagged | 18,202 | `is_security_fix:true` after message pass |
| High-confidence with `rule_idea` | 2,647 | Primary authoring feed for rule DB |
| Diff-verified gold fixes | 1,018 | `is_security_fix:true` + `diff_available:true` from diff pass |
| Suspects re-gated | 728 | Noise-subject rows re-judged |
| Flipped to non-security | 720 | 98.9% of suspects were false positives |
| Kept as security after re-gate | 8 | Had actual CVE/vuln substance despite noisy subject |

**Dominant vuln classes** (by category frequency in gold set):
1. `auth-session` / IDOR (CWE-639, CWE-287)
2. `xss`
3. `redos`
4. `path-traversal`
5. `ssrf`

---

## Related Docs

- [./02-diff-fetching.md](./02-diff-fetching.md) — how diff candidates are prepared and `git show` is run at scale
- [./03-tiered-labeling.md](./03-tiered-labeling.md) — gold / weak / leakage labeling tiers from triage output
- [./07-orchestration-harness.md](./07-orchestration-harness.md) — Workflow tool mechanics, `agent()` / `parallel()` / `phase()` API
- Harness source: [../harness/gitlab_haiku_analysis.wf.js](../harness/gitlab_haiku_analysis.wf.js), [../harness/haiku_regate.wf.js](../harness/haiku_regate.wf.js)
