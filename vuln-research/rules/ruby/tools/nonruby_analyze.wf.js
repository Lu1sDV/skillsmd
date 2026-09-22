export const meta = {
  name: 'gitlab-nonruby-security-analysis',
  description: 'Sonnet subagents analyze non-Ruby (JS/Vue/HAML/Go/GraphQL/SCSS) GitLab security-fix diffs into gold-style structured records.',
  phases: [{ title: 'Analyze' }],
  model: 'sonnet',
}

// args = { input, outDir, batchSize, total }
let A = args
if (typeof A === 'string') { try { A = JSON.parse(A) } catch (e) { A = {} } }
if (!A || typeof A !== 'object') A = {}
const BASE = '/home/x/Personal_Projects/skillsmd/vuln-research/rules/ruby/oracle'
const INPUT = A.input || `${BASE}/nonruby-analysis-input.json`
const OUTDIR = A.outDir || `${BASE}/analysis`
const TOTAL = A.total || 3217
const BATCH = A.batchSize || 18
const N = Math.ceil(TOTAL / BATCH)

const RESULT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    batch: { type: 'integer' }, processed: { type: 'integer' },
    security_confirmed: { type: 'integer' }, dropped_nonsecurity: { type: 'integer' },
    out_file: { type: 'string' }, notes: { type: 'string' },
  },
  required: ['batch', 'processed', 'out_file', 'notes'],
}

const TAX = 'command-injection, code-injection, sql-injection, deserialization, ssrf, ' +
  'path-traversal, zip-slip, xss, ssti, open-redirect, mass-assignment, redos, ' +
  'auth-session, crypto-tls, xxe, mail-header-injection, job-injection, cache-poisoning, ' +
  'render-injection, http-parsing, hardcoded-secrets, insecure-randomness, ldap-injection, ' +
  'secure-config, rails-misc, other'

function prompt(idx, start, end) {
  const outFile = `${OUTDIR}/nonruby-${String(idx).padStart(3, '0')}.jsonl`
  return `You are a senior application-security analyst triaging NON-Ruby security fixes from gitlab-org/gitlab (frontend JS/Vue/HAML, GraphQL, Go, SCSS). Each commit was flagged security-relevant by a weak title pass; you decide from the ACTUAL DIFF whether it is a real security fix and, if so, characterize it.

SETUP
- mkdir -p ${OUTDIR}
- Read ONLY your slice (indices [${start}, ${end})) of the JSON array ${INPUT}:
  python3 -c "import json,sys;d=json.load(open('${INPUT}'))[${start}:${end}];print(json.dumps(d))"
  Each item: {sha, subject, langs, files, diff}. The diff is restricted to code files (capped).
- Output (JSON Lines, append one object per commit): ${outFile}
- RESUMABILITY: if ${outFile} exists, skip sha values already present.

JUDGEMENT
- is_security_fix=false for: pure styling/SCSS with no security effect, test-only changes, refactors, copy/i18n, feature work with no vuln being closed. Default to false when the diff shows no security-relevant change.
- is_security_fix=true ONLY with diff evidence of closing a vuln: output encoding/sanitization (v-html, innerHTML, dompurify, sanitize, escape), authz/permission checks, removing secret/token exposure, SSRF/redirect/path validation, CSRF, safe-URL handling, GraphQL field authorization, Go input validation, etc.

For each REAL security fix, characterize from the diff:
- language: primary code language (vue|js|haml|graphql|go|scss|ts)
- category: EXACTLY ONE of: ${TAX}
  (frontend favorites: xss for v-html/innerHTML/template injection; open-redirect for unchecked URLs; auth-session for client authz/token; secure-config; hardcoded-secrets)
- cwe: array of "CWE-NNN" (e.g. ["CWE-79"] for XSS, ["CWE-601"] open-redirect)
- sink: the dangerous API/operation in the diff (e.g. "v-html binding", "el.innerHTML=", "dompurify bypass", "GraphQL resolver missing authorize")
- tainted_input: where untrusted data enters (e.g. "user-controlled note body", "URL param", "API response field")
- vuln_summary: 1 sentence — the weakness
- fix_summary: 1 sentence — what the patch changed
- rule_idea: 1 sentence — a detectable pattern for a SAST rule (or null if not generalizable)
- confidence: high|medium|low

Append ONE JSON line per commit with EXACTLY these keys:
{"sha","is_security_fix"(bool),"language","category","cwe"(array),"sink","tainted_input","vuln_summary","fix_summary","rule_idea","confidence"}
For is_security_fix=false rows, set category="other" and the descriptive fields to null but still emit the line.
Use python json.dumps; never embed raw newlines in a value; append as you go.
Return JSON: {batch:${idx}, processed, security_confirmed, dropped_nonsecurity, out_file:"${outFile}", notes}.`
}

phase('Analyze')
log(`Sonnet non-Ruby security analysis: ${TOTAL} code-lang commits / ${BATCH} per agent = ${N} batches -> ${OUTDIR}`)

const batches = []
for (let i = 0; i < N; i++) batches.push([i, i * BATCH, Math.min(TOTAL, (i + 1) * BATCH)])

const results = (await parallel(
  batches.map(([idx, start, end]) => () =>
    agent(prompt(idx, start, end), { label: `nonruby:b${idx}`, phase: 'Analyze', model: 'sonnet', schema: RESULT_SCHEMA })
  )
)).filter(Boolean)

return {
  batches: N,
  completed: results.length,
  processed: results.reduce((a, r) => a + (r?.processed || 0), 0),
  security_confirmed: results.reduce((a, r) => a + (r?.security_confirmed || 0), 0),
  dropped_nonsecurity: results.reduce((a, r) => a + (r?.dropped_nonsecurity || 0), 0),
  out_dir: OUTDIR,
}
