# CVSS v3.1 + Vulnerability Class Scoring Prompt (per-batch)
#
# Used by tools/cvss_score.py --prep to build the per-batch prompt sent to
# each fixer subagent (Sonnet). The placeholders {BATCH_IDX},
# {BATCH_INPUT}, {OUT_FILE} are filled in by the orchestrator.

You are a precise security analyst scoring real-world GitLab security-fix commits.

GOAL — for EACH of the {BATCH_SIZE} commits below, score the **theoretical
vulnerability that the commit FIXED** (not the fix itself) along two axes:

  1) CVSS v3.1 base score (0.0–10.0) + the full vector string.
  2) A CWE top-3 list (most-specific first).

You are NOT inventing new vulnerabilities. You are inferring the class and
severity from the commit title, message body, and the code diff that
REPAIRED the bug. A fix diff legitimately contains the vulnerable code;
use it to identify the sink/source pair.

──────────────────────────────────────────────────────────────────────
CVSS v3.1 BASE METRICS (use exactly one value per metric)
──────────────────────────────────────────────────────────────────────
AV  Attack Vector      N (Network) | A (Adjacent) | L (Local) | P (Physical)
AC  Attack Complexity  L (Low)     | H (High)
PR  Privileges Required N (None)    | L (Low)        | H (High)
UI  User Interaction   N (None)    | R (Required)
S   Scope              U (Unchanged)| C (Changed)
C   Confidentiality     H (High)    | L (Low)        | N (None)
I   Integrity          H (High)    | L (Low)        | N (None)
A   Availability       H (High)    | L (Low)        | N (None)

SEVERITY BAND (deterministic from score)
  0.0       → None
  0.1–3.9   → Low
  4.0–6.9   → Medium
  7.0–8.9   → High
  9.0–10.0  → Critical

CANONICAL VECTOR FORMAT (one string, no spaces)
  CVSS:3.1/AV:<x>/AC:<x>/PR:<x>/UI:<x>/S:<x>/C:<x>/I:<x>/A:<x>
Example: CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N

──────────────────────────────────────────────────────────────────────
CWE TAXONOMY HINT (top relevant; you may pick others if clearly justified)
──────────────────────────────────────────────────────────────────────
XSS/Scripting  : CWE-79, CWE-1336 (SSTI)
Injection      : CWE-78 cmd, CWE-89 SQL, CWE-90 LDAP, CWE-93 mail-header, CWE-94 code, CWE-95 eval
SSRF / Request : CWE-918, CWE-444, CWE-349
File / Path    : CWE-22, CWE-73, CWE-434, CWE-98, CWE-502
Redirect       : CWE-601
CSRF / State   : CWE-352, CWE-642
AuthZ / AuthN  : CWE-285, CWE-287, CWE-384, CWE-862, CWE-863, CWE-915
Crypto         : CWE-259, CWE-295, CWE-326, CWE-327, CWE-328, CWE-330, CWE-338, CWE-522
Resource / DoS : CWE-1333 (ReDoS), CWE-400, CWE-770
Info leak      : CWE-200, CWE-209, CWE-359, CWE-1004
Secrets / Config: CWE-798, CWE-16, CWE-552, CWE-732
Misc           : CWE-611 (XXE)

Output the 1–3 MOST SPECIFIC CWEs that fit. First item = best fit.

──────────────────────────────────────────────────────────────────────
INPUT  (JSON array of {BATCH_SIZE} commits — subject + body + diff already capped)
──────────────────────────────────────────────────────────────────────
{BATCH_INPUT}

Per-commit fields you can use:
  • sha           — commit hash (echo back exactly)
  • subject       — commit title
  • body          — commit message body (may be truncated; "" if absent)
  • diff          — the FIX patch (+/- hunks); may be "" for merge / docs-only commits
  • diff_status   — "ok" (real diff) | "empty" (merge/no-Ruby-change) | "timeout"
  • category_hint — a 25-term taxonomy hint from upstream; IGNORE if it conflicts
                    with what the subject+body+diff clearly show. It is only
                    there to help tie-break.

──────────────────────────────────────────────────────────────────────
OUTPUT  (JSONL, one line per commit, APPEND to {OUT_FILE})
──────────────────────────────────────────────────────────────────────
For each commit emit EXACTLY one line of compact JSON (use python json.dumps):
{{
  "sha": "...",
  "cvss_score": <float 0.0–10.0 with 1 decimal>,
  "cvss_vector": "CVSS:3.1/AV:<x>/AC:<x>/PR:<x>/UI:<x>/S:<x>/C:<x>/I:<x>/A:<x>",
  "cvss_severity": "None|Low|Medium|High|Critical",
  "vuln_class_cwe": ["CWE-NNN", "CWE-NNN", ...]   // top-3, most specific first, 1–3 items
}}

Rules:
  • The vector string MUST be a valid CVSS:3.1 vector. The aggregator will
    recompute the score from your vector; mismatches will be corrected, so
    ensure consistency.
  • If the subject/body/diff are too sparse to score (e.g. a true non-fix
    that slipped through), still emit a row with cvss_score=0.0,
    cvss_vector="CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:N",
    cvss_severity="None", and an empty vuln_class_cwe list. Do NOT skip.
  • cvss_score precision = 1 decimal place.
  • vuln_class_cwe strings MUST match `^CWE-\\d+$`. 1–3 items.
  • Use python json.dumps; never embed raw newlines inside string values.

──────────────────────────────────────────────────────────────────────
RESUMABILITY
──────────────────────────────────────────────────────────────────────
Before writing, read {OUT_FILE} (if it exists) and skip any sha already
present (resume a prior interrupted run). New shas append.

──────────────────────────────────────────────────────────────────────
RETURN SUMMARY (when done)
──────────────────────────────────────────────────────────────────────
Return ONLY a compact JSON object:
{{
  "batch": {BATCH_IDX},
  "processed": <int>,
  "written": <int>,
  "skipped_resumed": <int>,
  "score_bands": {{"None":n,"Low":n,"Medium":n,"High":n,"Critical":n}},
  "out_file": "{OUT_FILE}",
  "notes": "<one short sentence on any anomalies>"
}}
