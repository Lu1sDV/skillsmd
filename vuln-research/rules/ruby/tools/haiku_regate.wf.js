export const meta = {
  name: 'gitlab-haiku-security-regate',
  description: 'Re-judge is_security_fix on chore/merge-noise suspect commits (title+body) to strip mislabeled non-security rows.',
  phases: [{ title: 'Regate' }],
}

// args = { input:path(regate-input.json), outDir:path, batchSize?:int }
let A = args
if (typeof A === 'string') { try { A = JSON.parse(A) } catch (e) { A = {} } }
if (!A || typeof A !== 'object') A = {}
const INPUT = A.input || '/home/x/Personal_Projects/skillsmd/vuln-research/rules/ruby/oracle/regate-input.json'
const OUTDIR = A.outDir || '/home/x/Personal_Projects/skillsmd/vuln-research/rules/ruby/oracle/analysis'
const TOTAL = A.total || 728
const BATCH = A.batchSize || 60
const N = Math.ceil(TOTAL / BATCH)

const RESULT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    batch: { type: 'integer' }, processed: { type: 'integer' },
    kept_security: { type: 'integer' }, flipped_to_nonsecurity: { type: 'integer' },
    out_file: { type: 'string' }, notes: { type: 'string' },
  },
  required: ['batch', 'processed', 'flipped_to_nonsecurity', 'out_file', 'notes'],
}

function prompt(idx, start, end) {
  const outFile = `${OUTDIR}/regate-${String(idx).padStart(3, '0')}.jsonl`
  return `You are a precise security-triage gatekeeper for gitlab-org/gitlab. These commits were AUTO-flagged as security fixes by a weak title-only pass, but their subjects look like chore / CI / merge-of-master / docs / i18n / dependency noise. Your job: decide for EACH whether it is ACTUALLY a security fix, judging from the TITLE + MESSAGE BODY.

SETUP
- mkdir -p ${OUTDIR}
- Read ONLY your slice (indices [${start}, ${end})) of the JSON array ${INPUT}:
  python3 -c "import json,sys;d=json.load(open('${INPUT}'))[${start}:${end}];json.dump(d,sys.stdout)"
  Each item: {sha, subject, body, orig_category, orig_confidence}.
- Output (JSON Lines, append one object per commit): ${outFile}
- RESUMABILITY: if ${outFile} exists, skip sha values already present.

DECISION RULE — default to NON-security for this suspect pool, flip to security ONLY with positive evidence:
- is_security_fix_regate = false for: flaky-test quarantine, rubocop/lint todo regeneration, translations/i18n, docs-only, dependency version bumps with no security note, automatic master merges, screenshot/fixture/changelog updates.
- is_security_fix_regate = true ONLY if title or body shows real security substance: a CVE/CWE, a vuln class (xss/csrf/ssrf/injection/path traversal/deserialization/authz/IDOR/secret leak/redos), a security MR/branch ('security-...'), sanitization/escaping/permission/authorization changes, or an explicit "fixes a security issue" note. A dependency bump counts as security ONLY if it cites a security advisory/CVE.

For each commit append ONE JSON line with EXACTLY:
{"sha","is_security_fix_regate"(bool),"regate_reason"(short NL: why kept or flipped),"regate_confidence"("high"|"medium"|"low")}
Use python json.dumps; never embed raw newlines in a value; append as you go.
Return JSON: {batch:${idx}, processed, kept_security, flipped_to_nonsecurity, out_file:"${outFile}", notes}.`
}

phase('Regate')
log(`Haiku is_security_fix re-gate: ${TOTAL} suspects / ${BATCH} per agent = ${N} batches -> ${OUTDIR}`)

const batches = []
for (let i = 0; i < N; i++) batches.push([i, i * BATCH, Math.min(TOTAL, (i + 1) * BATCH)])

const results = (await parallel(
  batches.map(([idx, start, end]) => () =>
    agent(prompt(idx, start, end), { label: `regate:b${idx}`, phase: 'Regate', model: 'haiku', schema: RESULT_SCHEMA })
  )
)).filter(Boolean)

return {
  batches: N,
  completed: results.length,
  processed: results.reduce((a, r) => a + (r?.processed || 0), 0),
  flipped_to_nonsecurity: results.reduce((a, r) => a + (r?.flipped_to_nonsecurity || 0), 0),
  out_dir: OUTDIR,
}
