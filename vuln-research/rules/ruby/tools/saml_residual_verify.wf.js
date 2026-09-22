export const meta = {
  name: 'saml-residual-verify',
  description: 'Verify->refute the 2 new auth-session SAML/LDAP extern_uid residuals from incomplete-fix hunt (Fable)',
  phases: [
    { title: 'Verify', detail: 'independent Fable verifier per residual site', model: 'fable' },
    { title: 'Refute', detail: 'adversarial refute of each CONFIRM', model: 'fable' },
  ],
}

const N = 2
const CO = '/home/x/Personal_Projects/find-ctfs/gitlab'
const WL = 'oracle/validation/saml-residual-worklist.json'
const OUT = 'oracle/validation/saml-residual'

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
    source: { type: 'string', description: 'attacker-controlled extern_uid/identity source, or "none"' },
    sink: { type: 'string', description: 'the identity-link/account-bind operation' },
    guard: { type: 'string', description: 'confirmation/ownership/authz guard found, or "none"' },
    reason: { type: 'string', description: '<=3 sentences' },
    exploit_sketch: { type: 'string', description: 'only if CONFIRM: concrete takeover path' },
  },
}

const REFUTE_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['index', 'refuted', 'confidence', 'reason'],
  properties: {
    index: { type: 'integer' }, refuted: { type: 'boolean' }, confidence: { type: 'number' }, reason: { type: 'string' },
  },
}

function verifyPrompt(i) {
  return `You are an adversarial security verifier auditing ONE candidate GitLab account-takeover variant. Default to DISCARD; only CONFIRM with a concrete exploit. GitLab source (HEAD): ${CO}

CONTEXT: This site is a RESIDUAL flagged by an incomplete-fix hunt around commit a8a9e972 "Require confirmation before linking JWT identity". The fix added a confirmation/ownership step before linking an external identity to an account; the rule rb/auth-session-saml-extern-uid-account-takeover still fires at this SIBLING site, which the fix did not touch. The threat is: an attacker who controls/influences an extern_uid (SAML NameID / LDAP DN / provider uid) links it to a VICTIM's account (or links a victim's uid to the attacker's account), achieving takeover — UNLESS there is an ownership check, confirmation step, signature/assertion validation, or admin-only gating.

STEP 1 - load your finding (index ${i}):
  python3 -c "import json;print(json.dumps(json.load(open('${WL}'))[${i}]))"
Keys: rule, file, line, origin_fix, why.

STEP 2 - read the REAL code. Open ${CO}/<file> around <line> (~60 lines each side) and trace:
  (a) Where does the extern_uid / provider identity value come from at this site? Is it attacker-controlled (request param, SAML response, LDAP lookup of attacker input) or server/admin-derived (validated assertion, trusted provider, admin API only)?
  (b) Is the identity link guarded? Look for: confirmation requirement, current_user ownership check, the actor must already own BOTH sides, admin-only API (authorize!/admin), signed/validated SAML assertion, unique-constraint that prevents hijacking an existing uid. Open callers and the policy/auth around the endpoint.

STEP 3 - decide (FP-skeptic):
  CONFIRM = a concrete actor links an extern_uid to an account they do not own (or rebinds a victim's), no neutralizing guard => takeover. Give exploit_sketch.
  DISCARD = admin-only, self-ownership enforced, confirmation present, value is validated/trusted, or test/dead code.
  REVIEW = genuinely ambiguous after honest tracing.

STEP 4 - persist your verdict JSON to ${OUT}/verify-${i}.json, then return via StructuredOutput. index=${i}.`
}

function refutePrompt(i, v) {
  return `A verifier marked GitLab finding index ${i} as a REAL account-takeover. REFUTE it. Default refuted=true unless the takeover clearly holds end-to-end. Source (HEAD): ${CO}

Claim:
  rule:  ${v.rule}
  site:  ${v.file}:${v.line}
  source/actor: ${v.source}
  sink:  ${v.sink}
  reason: ${v.reason}
  exploit_sketch: ${v.exploit_sketch || '(none)'}

Read ${CO}/${v.file} at the site, its callers, and the auth/policy around the endpoint. Break it:
  - Is the extern_uid actually attacker-controlled, or from a validated SAML assertion / trusted provider / admin-only API?
  - Is the link self-ownership-only (actor binds their OWN uid = capability, not takeover)?
  - Is there a confirmation step, unique constraint, or admin gate that blocks rebinding a victim's identity?
  - Is the path dead/test/EE-config-gated unreachable?
Set refuted=true if any defeats it; refuted=false only if a concrete cross-account takeover holds. Persist to ${OUT}/refute-${i}.json, return via StructuredOutput. index=${i}.`
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
        refute_reason: r ? r.reason : 'null',
        verdict: (r && r.refuted) ? 'DISCARD_ON_REFUTE' : 'CONFIRM',
      }))
  }
)

const clean = results.filter(Boolean)
const tally = {}
for (const r of clean) tally[r.verdict] = (tally[r.verdict] || 0) + 1
const survived = clean.filter((r) => r.verdict === 'CONFIRM')
log(`saml-residual done: ${clean.length} -> ${JSON.stringify(tally)}`)

return {
  total: clean.length,
  tally,
  survived: survived.map((r) => ({ rule: r.rule, file: r.file, line: r.line, reason: r.reason, exploit: r.exploit_sketch })),
  all: clean,
}
