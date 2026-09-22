export const meta = {
  name: 'jobtoken-variant-hunt',
  description: 'Corrected job-token privesc hunt: job_token_allowed routes -> sensitive ability -> policy/scope reachability (Fable)',
  phases: [
    { title: 'Scan', detail: 'one Fable agent per job-token-enabled API file', model: 'fable' },
    { title: 'Refute', detail: 'adversarial refute of each candidate', model: 'fable' },
  ],
}

const N = 39
const CO = '/home/x/Personal_Projects/find-ctfs/gitlab'
const LIST = 'oracle/validation/jt/jt-route-files.txt'
const OUT = 'oracle/validation/jt'

const FILE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['index', 'file', 'verdict', 'candidates'],
  properties: {
    index: { type: 'integer' },
    file: { type: 'string' },
    verdict: { type: 'string', enum: ['CLEAN', 'CANDIDATE'] },
    candidates: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['route', 'method', 'ability', 'line', 'sensitivity', 'reason'],
        properties: {
          route: { type: 'string' },
          method: { type: 'string' },
          ability: { type: 'string', description: 'the ability the route authorizes, or auth/route note' },
          line: { type: 'integer' },
          sensitivity: { type: 'string', enum: ['write', 'admin', 'destroy', 'cross-project', 'other'] },
          reason: { type: 'string', description: 'why a job token could abuse this beyond intended CI scope' },
        },
      },
    },
    note: { type: 'string' },
  },
}

const REFUTE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['refuted', 'confidence', 'reason'],
  properties: {
    refuted: { type: 'boolean' },
    confidence: { type: 'number' },
    reason: { type: 'string' },
  },
}

function scanPrompt(i) {
  return `You are hunting for a CI job-token PRIVILEGE-ESCALATION variant in ONE GitLab API file. Default to CLEAN; only raise a CANDIDATE with a concrete over-privileged operation. GitLab source (HEAD): ${CO}

BACKGROUND (verified facts — use them):
- A CI job token authenticates as the pipeline-triggering user, but is meant to be CONFINED to limited CI operations.
- Job-token auth is OPT-IN PER ROUTE: a token only becomes current_user where the route sets \`route_setting :authentication, job_token_allowed: ...\` (or \`allow_access_with_scope\`). auth_finders.rb:97 returns nil otherwise.
- Cross-project reach is confined by \`ci_job_token_scope\` (an allowlist) and per-route \`job_token_policies\`. \`BasePolicy\`'s \`condition(:admin)\` returns false for job tokens.
- THE THREAT: a \`job_token_allowed\` route that authorizes a SENSITIVE ability (write/admin/manage/destroy/create, or cross-project data access) where a job token gains power BEYOND read-only CI scope or beyond the triggering job's own project — without job_token_policies/scope confinement.

STEP 1 - your target file (index ${i}):
  python3 -c "print(open('${LIST}').read().splitlines()[${i}])"
This prints a path relative to the GitLab checkout. Open ${CO}/<that path>.

STEP 2 - find every route in that file that opts into job tokens (grep the file for job_token_allowed / allow_access_with_scope / job_token_policies). For EACH such route determine:
  - HTTP method + path + line
  - what ability/authorization it enforces (route_setting :authorization, authorize!, Ability.allowed?, or the helper it calls) and whether job_token_policies/scope is set
  - whether the operation is a SENSITIVE write/admin/destroy/cross-project action or just scoped read/package-pull

STEP 3 - decide:
  CANDIDATE = at least one job_token_allowed route performs a sensitive/over-privileged operation that a job token should NOT be able to do, OR a sensitive route is missing job_token_policies/scope confinement. List each as a candidate.
  CLEAN = all job-token routes are read/package-scoped and properly confined by scope/policies.
Be concrete and skeptical: package upload/download within the job's project, scoped artifact access, and reads are EXPECTED and CLEAN. Look specifically for: writes/admin to OTHER projects/groups, token/secret creation, deletion of others' resources, or sensitive ability with no scope check.

STEP 4 - persist your result JSON to ${OUT}/file-${i}.json, then return via StructuredOutput. index=${i}, file=<the path>.`
}

function refutePrompt(c, filePath) {
  return `A scanner flagged a possible CI job-token privilege-escalation in GitLab. REFUTE it. Default refuted=true unless the over-privileged path clearly holds. Source (HEAD): ${CO}

Claim:
  file:  ${filePath}
  route: ${c.method} ${c.route} (line ${c.line})
  ability: ${c.ability}
  sensitivity: ${c.sensitivity}
  reason: ${c.reason}

Read ${CO}/${filePath} at that route AND the policy/scope it relies on. Break the claim if you can:
  - Is the route actually job_token_allowed, or did the scanner misread? Is job_token_policies/scope set to confine it?
  - Does ci_job_token_scope / the policy restrict the operation to the job's own project, or to read-only?
  - Is the "sensitive" ability actually scoped/expected for CI (e.g. package publish to own project, artifact read)?
  - Does the policy arm require power the token's user already holds for their own resource (self-power, not escalation)?
Set refuted=true if any of these confines it; refuted=false only if a job token genuinely gains over-privileged/cross-scope power. Return via StructuredOutput.`
}

phase('Scan')
const results = await pipeline(
  Array.from({ length: N }, (_, i) => i),
  (i) => agent(scanPrompt(i), { label: `scan#${i}`, phase: 'Scan', model: 'fable', schema: FILE_SCHEMA }),
  (r) => {
    if (!r || r.verdict !== 'CANDIDATE' || !r.candidates || !r.candidates.length) return r
    return parallel(
      r.candidates.map((c) => () =>
        agent(refutePrompt(c, r.file), { label: `refute:${r.file.split('/').pop()}`, phase: 'Refute', model: 'fable', schema: REFUTE_SCHEMA })
          .then((v) => ({ ...c, refuted: v ? v.refuted : null, refute_reason: v ? v.reason : 'null', survives: v ? !v.refuted : false }))
      )
    ).then((judged) => ({ ...r, candidates: judged }))
  }
)

const clean = results.filter(Boolean)
const allCand = clean.flatMap((r) => (r.candidates || []).map((c) => ({ file: r.file, ...c })))
const survivors = allCand.filter((c) => c.survives)
log(`scan done: ${clean.length} files, ${allCand.length} candidates, ${survivors.length} survive refute`)

return {
  files_scanned: clean.length,
  candidate_files: clean.filter((r) => r.verdict === 'CANDIDATE').length,
  total_candidates: allCand.length,
  survivors,
  all_candidates: allCand,
}
