export const meta = {
  name: 'recheck-confirmed-variants',
  description: 'Re-test the 12 prior-confirmed GitLab auth/privesc VARIANTs through the Fable verify->refute gate',
  phases: [
    { title: 'Verify', detail: 'independent Fable re-assessment of each confirmed finding', model: 'fable' },
    { title: 'Refute', detail: 'independent Fable skeptic attacks every surviving CONFIRM', model: 'fable' },
  ],
}

const N = 12
const CO = '/home/x/Personal_Projects/find-ctfs/gitlab'
const WL = 'oracle/validation/recheck-confirmed-worklist.json'
const RD = 'oracle/validation/rule-desc-confirmed.json'
const OUT = 'oracle/validation/cd-confirmed'

const VERDICT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['index', 'rule', 'file', 'line', 'verdict', 'confidence', 'source', 'sink', 'guard', 'reason'],
  properties: {
    index: { type: 'integer' },
    rule: { type: 'string' },
    file: { type: 'string' },
    line: { type: 'integer' },
    verdict: { type: 'string', enum: ['CONFIRM', 'DISCARD', 'REVIEW'] },
    confidence: { type: 'number' },
    source: { type: 'string', description: 'the attacker-controlled source / escalation actor, or "none"' },
    sink: { type: 'string', description: 'the dangerous sink or escalated ability at this site' },
    guard: { type: 'string', description: 'escaping/sanitization/authz/job-token guard found, or "none"' },
    reason: { type: 'string', description: '<=3 sentences justifying the verdict' },
    exploit_sketch: { type: 'string', description: 'only if CONFIRM: concrete path from actor to escalated power' },
  },
}

const REFUTE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['index', 'refuted', 'confidence', 'reason'],
  properties: {
    index: { type: 'integer' },
    refuted: { type: 'boolean', description: 'true if the CONFIRM claim does NOT hold' },
    confidence: { type: 'number' },
    reason: { type: 'string', description: '<=3 sentences: why the claim fails, or why it survives' },
  },
}

function verifyPrompt(i) {
  return `You are an adversarial security verifier RE-TESTING a finding that a PRIOR session marked as a CONFIRMED real vulnerability. Do NOT trust that prior verdict. Independently re-assess and DEFAULT TO DISCARD unless you can prove a concrete exploit. Your goal is to catch any over-confirmation.

Working directory is the Ruby detection-rules repo. GitLab source checkout (current HEAD) is at: ${CO}

STEP 1 - load your finding (index ${i}):
  python3 -c "import json;print(json.dumps(json.load(open('${WL}'))[${i}]))"
Keys: rule, file, line, sev, prior_status, reason (the prior session's CONFIRM argument), guard, src.

STEP 2 - load the rule's meaning AND its threat model: read '${RD}' and find the entry keyed by your finding's "rule". For job-token findings the threat-model note is essential — read it carefully.

STEP 3 - read the REAL code. Open ${CO}/<file> around <line> (~50 lines each side) and follow whatever you must to settle the claim:
  - For job-token privilege-escalation: open the policy file AND its ancestor chain (delegations / included policies). Determine whether a CI job token actually reaches this ability WITHOUT hitting any \`~project_allowed_for_job_token\`/\`from_ci_job_token?\`-gated prevent. CRITICAL: an \`is_author\`/self-authored arm grants only what the actor already has => DISCARD (not escalation). A genuine escalation grants owner/admin-class power beyond the actor's own.
  - For timing-unsafe compare: confirm the compared value is a real secret/token/HMAC reached by attacker-supplied input, and that \`==\` (not secure_compare) is used at the live HEAD line. Judge real-world exploitability of the timing side-channel.

STEP 4 - decide (skeptical):
  CONFIRM = concrete actor reaches escalated power / exploitable side-channel, no neutralizing guard (give exploit_sketch).
  DISCARD = self-authored-only arm, guarded by a job-token prevent in the chain, constant/non-attacker input, secure_compare already used, unreachable, or test/vendored code.
  REVIEW = genuinely ambiguous after honest tracing.

STEP 5 - persist: write your structured verdict JSON to ${OUT}/verify-${i}.json, then return it via StructuredOutput. Set index=${i}.`
}

function refutePrompt(i, v) {
  return `A verifier upheld GitLab finding index ${i} as a REAL vulnerability on re-test. Your job is to REFUTE it. Default refuted=true unless the exploit clearly holds end-to-end.

Claim:
  rule:  ${v.rule}
  site:  ${v.file}:${v.line}
  source/actor: ${v.source}
  sink/power:   ${v.sink}
  reason: ${v.reason}
  exploit_sketch: ${v.exploit_sketch || '(none given)'}

GitLab source checkout (HEAD): ${CO}
Read the SAME code at ${CO}/${v.file} and its policy ancestor chain / callers. Try hard to break the claim:
  - job-token: is there a job-token prevent reachable in THIS policy's full rule chain? Is the ability actually self-authored-only (capability, not escalation)? Does the actor already hold this power?
  - timing: is the value really a secret reached by attacker input? Is secure_compare actually used? Is the side-channel realistically measurable over the network?
Set refuted=true if ANY of these defeats the exploit; refuted=false only if it genuinely holds.

Persist your result JSON to ${OUT}/refute-${i}.json, then return via StructuredOutput. Set index=${i}.`
}

phase('Verify')
const results = await pipeline(
  Array.from({ length: N }, (_, i) => i),
  (i) => agent(verifyPrompt(i), { label: `verify#${i}`, phase: 'Verify', model: 'fable', schema: VERDICT_SCHEMA }),
  (v, i) => {
    if (!v) return { index: i, verdict: 'ERROR', reason: 'verify agent returned null' }
    if (v.verdict !== 'CONFIRM') return v
    return agent(refutePrompt(i, v), { label: `refute#${i}`, phase: 'Refute', model: 'fable', schema: REFUTE_SCHEMA })
      .then((r) => ({
        ...v,
        refute_refuted: r ? r.refuted : null,
        refute_reason: r ? r.reason : 'refute agent returned null',
        verdict: (r && r.refuted) ? 'DISCARD_ON_REFUTE' : 'CONFIRM',
      }))
  }
)

const clean = results.filter(Boolean)
const tally = {}
for (const r of clean) tally[r.verdict] = (tally[r.verdict] || 0) + 1
const survived = clean.filter((r) => r.verdict === 'CONFIRM')
const demoted = clean.filter((r) => r.verdict !== 'CONFIRM')
log(`recheck done: ${clean.length} -> ${JSON.stringify(tally)}`)

return {
  total: clean.length,
  tally,
  survived: survived.map((r) => ({ rule: r.rule, file: r.file, line: r.line, reason: r.reason })),
  demoted: demoted.map((r) => ({ rule: r.rule, file: r.file, line: r.line, verdict: r.verdict, reason: r.reason, refute_reason: r.refute_reason })),
  all: clean,
}
