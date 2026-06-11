export const meta = {
  name: 'gitlab-security-haiku-analysis',
  description: 'Haiku mega-analysis of GitLab security commits. mode=message: title+body at full scale (no network). mode=diff: title+body+Ruby diff for the precise fix set.',
  phases: [{ title: 'Analyze' }],
}

// args = { mode:'message'|'diff', manifest:path, total:int, batchSize?:int, repo?:path, outDir?:path, tag?:str }
// args may arrive as a JSON string or an object — normalize.
let A = args
if (typeof A === 'string') { try { A = JSON.parse(A) } catch (e) { A = {} } }
if (!A || typeof A !== 'object') A = {}
const args2 = A
const MODE = args2.mode || 'message'
const MANIFEST = args2.manifest
const REPO = args2.repo || '/home/x/Personal_Projects/find-ctfs/gitlab'
const OUTDIR = args2.outDir || '/home/x/Personal_Projects/skillsmd/vuln-research/rules/ruby/oracle/analysis'
const TAG = args2.tag || MODE
const TOTAL = args2.total || 0
const BATCH = args2.batchSize || (MODE === 'message' ? 80 : 25)
const N = Math.ceil(TOTAL / BATCH)

const TAXONOMY = [
  'command-injection','code-injection','sql-injection','deserialization','ssrf','path-traversal',
  'zip-slip','xss','ssti','open-redirect','mass-assignment','redos','auth-session','crypto-tls',
  'xxe','mail-header-injection','job-injection','cache-poisoning','render-injection','http-parsing',
  'hardcoded-secrets','insecure-randomness','ldap-injection','secure-config','rails-misc','other',
].join(', ')

const RESULT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    batch: { type: 'integer' }, processed: { type: 'integer' },
    security_fixes: { type: 'integer' }, skipped_existing: { type: 'integer' },
    out_file: { type: 'string' }, notes: { type: 'string' },
  },
  required: ['batch', 'processed', 'security_fixes', 'out_file', 'notes'],
}

function commonHead(idx, start, end, outFile, sliceInstr) {
  return `You are a security triage analyst for GitLab (gitlab-org/gitlab, a large Rails app). Produce a structured natural-language security analysis for a slice of commits. Output feeds a Ruby vulnerability rule database.

SETUP
- mkdir -p ${OUTDIR}
- Your output file (JSON Lines, ONE object per line, appended as you go): ${outFile}
- ${sliceInstr}
- RESUMABILITY: if ${outFile} exists, collect the "sha" values already present and SKIP them (count as skipped_existing).`
}

function messagePrompt(idx, start, end) {
  const outFile = `${OUTDIR}/msg-${String(idx).padStart(4, '0')}.jsonl`
  // MANIFEST is JSONL (one commit/line). Slice by line range (1-indexed).
  const slice = `Your input is lines ${start + 1}-${end} of the JSONL manifest ${MANIFEST}. Read ONLY them: sed -n '${start + 1},${end}p' ${MANIFEST}  — each line is a JSON object {sha,date,subject(TITLE),body}.`
  return `${commonHead(idx, start, end, outFile, slice)}

ANALYZE EACH COMMIT from its TITLE + MESSAGE only (no diff this pass). GitLab scrubs public security commit messages, so many will be terse — judge security relevance from wording, branch/MR references, and CVE/Changelog hints.
EFFICIENCY: work in sub-chunks of ~30 commits — read 30, classify them all in one reasoning step, then append all 30 JSON lines at once (e.g. write to the file with a single python heredoc). Do NOT spend a separate reasoning turn per commit; this pass is coarse triage at scale.
For each commit append ONE JSON line to ${outFile} with EXACTLY:
{"sha","date","subject","is_security_fix"(bool),"confidence"("high"|"medium"|"low"),"category"(one of: ${TAXONOMY}),"cwe"([] or ["CWE-.."]),"vuln_summary"(NL — what the security issue likely is, or why not security),"rule_idea"(NL — a detection a rule DB could add, or ""),"needs_diff"(bool — true if a diff pass would clarify)}
Use python json.dumps; never embed raw newlines in a value; append after each commit so partial progress survives.
Return JSON: {batch:${idx}, processed (lines written this run), security_fixes (is_security_fix true), skipped_existing, out_file:"${outFile}", notes}.`
}

function diffPrompt(idx, start, end) {
  const outFile = `${OUTDIR}/diff-${String(idx).padStart(4, '0')}.jsonl`
  const slice = `Manifest ${MANIFEST} is a JSON object with a "commits" array; your slice is index [${start}, ${end}). Extract it: python3 -c "import json,sys;json.dump(json.load(open('${MANIFEST}'))['commits'][${start}:${end}],sys.stdout)" — each entry has {sha,date,subject(TITLE),body,signals}.`
  return `${commonHead(idx, start, end, outFile, slice)}

ANALYZE EACH COMMIT from TITLE + MESSAGE + the Ruby DIFF. Get the diff (blobs are pre-warmed; Ruby files only to stay focused):
    cd ${REPO} && git show ${"<sha>"} --format='%n===MSG===%n%s%n%b%n===DIFF===' --unified=3 -- '*.rb' '*.rake' '*.erb'
If a fetch is very slow or fails, retry once, else record what you can from the message and set "diff_available":false. If the diff is huge (>~500 lines), focus on the security-relevant hunks and note truncation.
Judge security relevance mainly from the DIFF: added sanitization/escaping, authorization/permission checks, strong-params allow-listing, input validation, safe-API swaps, SQL parameterization, SSRF allow-lists, etc.
For each commit append ONE JSON line to ${outFile} with EXACTLY:
{"sha","date","subject","signals","is_security_fix"(bool),"confidence","category"(one of: ${TAXONOMY}),"cwe","vuln_summary"(NL: root cause),"fix_summary"(NL: what the diff changed to fix it),"tainted_input"(where untrusted data enters, or ""),"sink"(the dangerous API/operation, or ""),"exploit_scenario"(NL or ""),"rule_idea"(NL: a concrete Semgrep/CodeQL detection this fix suggests),"ruby_files"([changed .rb paths]),"diff_available"(bool)}
Use python json.dumps; never embed raw newlines in a value; append after each commit.
Return JSON: {batch:${idx}, processed, security_fixes, skipped_existing, out_file:"${outFile}", notes}.`
}

phase('Analyze')
log(`GitLab ${MODE} analysis: ${TOTAL} commits / ${BATCH} per agent = ${N} Haiku batches -> ${OUTDIR}`)

const batches = []
for (let i = 0; i < N; i++) batches.push([i, i * BATCH, Math.min(TOTAL, (i + 1) * BATCH)])

const mk = MODE === 'diff' ? diffPrompt : messagePrompt
const results = (await parallel(
  batches.map(([idx, start, end]) => () =>
    agent(mk(idx, start, end), { label: `${TAG}:b${idx}`, phase: 'Analyze', model: 'haiku', schema: RESULT_SCHEMA })
  )
)).filter(Boolean)

return {
  mode: MODE, batches: N, batch_size: BATCH,
  completed_batches: results.length,
  processed: results.reduce((a, r) => a + (r?.processed || 0), 0),
  security_fixes: results.reduce((a, r) => a + (r?.security_fixes || 0), 0),
  out_dir: OUTDIR,
}
