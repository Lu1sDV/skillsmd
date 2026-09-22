export const meta = {
  name: 'bac-variant-hunt',
  description: 'Exhaustive variant analysis of the validated Todos mark_as_done broken-access-control class across the entire GitLab REST API + GraphQL + serializers: ownership-only lookup + entity exposing a foreign target with no per-target read_* gate + granular-only authorization guard + list-hardened-but-item-unhardened asymmetry. Multi-modal discovery -> dedup -> forward-trace -> adversarial multi-vote confirm -> completeness critic.',
  phases: [
    { title: 'Discover', detail: '6 blind multi-modal lanes enumerate candidate endpoints/entities/resolvers', model: 'opus' },
    { title: 'Trace', detail: 'per candidate: prove the access-loss/never-had-access scenario reaches protected data', model: 'opus' },
    { title: 'Confirm', detail: '3 independent adversarial skeptics per surviving candidate (default refuted)', model: 'opus' },
    { title: 'Critic', detail: 'completeness critic: which endpoint families went un-swept', model: 'opus' },
  ],
}

const CO = '/home/x/Personal_Projects/find-ctfs/gitlab'
const OUT = '/home/x/Personal_Projects/skillsmd/vuln-research/rules/ruby/oracle/validation/bac-variants'

const PATTERN = `
THE VALIDATED BUG CLASS (Todos mark_as_done — E2E-proven, the variant template):
- lib/api/todos.rb: post ':id/mark_as_done' does current_user.todos.find(params[:id]) (OWNERSHIP ONLY) then
  present todo, with: Entities::Todo. No authorize!/can?(:read_todo, todo) in the route body.
- Entities::Todo exposes :target / :body / target_title with NO authorization proc (lib/api/entities/todo.rb).
- todo_policy.rb: rule { own_todo & can_read_target }.enable :read_todo; rule { can?(:read_todo) }.enable
  :update_todo. commit_policy.rb: rule { can?(:read_code) }.enable :read_commit. So the INTENDED gate exists but the
  route never evaluates it.
- The route_setting :authorization (permissions: :update_todo) fires ONLY via Authz::Tokens::
  AuthorizeGranularScopesService#execute, which returns success immediately for legacy (classic) tokens
  (should_check_authorization? == false), so classic PAT / session cookies are NEVER gated by it.
- INCOMPLETE-FIX ASYMMETRY: GET /todos (list) was hardened by AllowedTargetFilterService (can?(:read_todo, todo)
  per item) + EntityLeaveService sweep; the single-item mark_as_done mutation and the Commit target type were NOT.
- ATTACK: a user who LOSES direct access but RETAINS inherited lower access (e.g. Developer->Guest via parent group)
  keeps stale rows whose target they can no longer read; the ownership-only endpoint still serializes the protected
  target. Also covers "never had read access to the target but owns the row" shapes.

A VARIANT = any REST route / GraphQL mutation/resolver that matches the SHAPE:
(A) loads a record by id scoped only to ownership/membership (current_user.<assoc>.find / find_by, or
    <Model>.find scoped to "mine"), AND
(B) serializes/returns a FOREIGN or TARGET object (target, source, note/body, issuable, commit, project, MR,
    snippet, design, epic, etc.) whose visibility is governed by a SEPARATE read_* policy, AND
(C) the route body does NOT call authorize!/can?(:read_*, the_foreign_object) (or relies only on the granular-token
    guard / a list-only filter), AND
(D) there is a realistic path where the caller can hold the row but NOT read the foreign object now
    (access downgrade, membership change, visibility change, transfer, confidential toggle, project move).`

const LANES = [
  { key: 'L1-ownership-find', title: 'ownership-only id lookups in REST API',
    prompt: `LANE 1 — grep the entire REST API (${CO}/lib/api/**/*.rb, and ee/lib/api) for OWNERSHIP-ONLY record
lookups by id: current_user.<assoc>.find(params[:id]) / .find_by / find_by!, <Model>.<mine-scope>.find, or any
"load my record then act/serialize" without a following authorize!/can? on the record's FOREIGN target. For each,
note the route (verb+path), the model, what entity it presents, and whether the entity exposes a foreign/target
object. Focus on mutations (post/put/delete to :id/<action> like mark_as_done, toggle, restore, mark_all,
resolve, dismiss, revert) AND single-item GETs. Return every candidate matching shape (A)+(B).` },
  { key: 'L2-entity-target-expose', title: 'entities exposing foreign target without authz proc',
    prompt: `LANE 2 — audit ${CO}/lib/api/entities/**/*.rb (+ ee) for entities that expose a FOREIGN or TARGET object
or its sensitive fields WITHOUT an authorization proc: expose :target, :source, :note/:body, :issuable, :commit,
:merge_request, :project, :snippet, :design, :epic, :noteable, target_title, etc., where there is no if:/
unless:/documentation-only guard and no per-field can? check. For each such entity, grep who presents it (which API
routes) and whether those routes authorize the foreign object. Return entity + exposing line + presenting routes,
matching shape (B)+(C).` },
  { key: 'L3-granular-only-guard', title: 'routes gated ONLY by the granular-token authorization guard',
    prompt: `LANE 3 — the Todos route relied on route_setting :authorization (permissions: :update_todo) which only
bites granular tokens. grep ${CO}/lib/api for route_setting :authorization / permissions: and map each to whether
the route body ALSO has an explicit authorize!/can? on the resource. Identify routes whose ONLY authorization on the
foreign/target object is the granular-token guard (AuthorizeGranularScopesService) — i.e. classic PAT/session is
ungated. Read lib/api/helpers.rb authorize_granular_token? / AuthorizeGranularScopesService#should_check_authorization?
to confirm the legacy-token bypass still holds at HEAD. Return routes matching shape (C) via the granular-only gap.` },
  { key: 'L4-list-vs-item-asymmetry', title: 'incomplete-fix: list hardened, item/mutation not',
    prompt: `LANE 4 — the Todos bug was an INCOMPLETE FIX: GET /todos got AllowedTargetFilterService but the
single-item mark_as_done did not. Hunt the same asymmetry elsewhere: find resources where the INDEX/LIST endpoint
applies a re-authorization filter / .visible_to / preloaded permission check / a *FilterService, but the
single-item GET or a mutation (:id/<action>) on the SAME resource does NOT re-check. Grep for filter services
(AllowedTargetFilterService and siblings), .visible_to_user, with_api_entity_associations, and compare list vs item
authorization per resource. Also scan git log / CHANGELOG security entries for fixes that mention "filter"/"redact"/
"access" on a LIST path. Return resources with a list/item authorization asymmetry, shape (C)+(D).` },
  { key: 'L5-graphql-resolver', title: 'GraphQL resolvers/mutations missing the read filter',
    prompt: `LANE 5 — GraphQL. Audit ${CO}/app/graphql (+ ee/app/graphql) resolvers and mutations that load a record
by id/iid scoped to the current user and return a foreign/target object. The Todos investigation noted the GraphQL
TodosResolver did/does not apply AllowedTargetFilterService. Find resolvers/mutations that: load "my" record then
expose its target/foreign object without an authorized_resource?/authorize :read_* on that foreign object, or that
rely on field-level authorization that is missing on the target type. Return candidates matching shape (A)+(B)+(C)
for GraphQL.` },
  { key: 'L6-membership-downgrade-targets', title: 'stale-row models surviving access downgrade',
    prompt: `LANE 6 — model/data angle. The exploit needs a user-owned row whose FOREIGN target becomes unreadable
after a membership/visibility change, with no sweep. Beyond Todos, enumerate per-user "stale row" models that
reference a foreign object and may NOT be purged on access loss: todos (other target types: Commit/Design/Epic/
AlertManagement/etc.), notifications, sent notifications, subscriptions, awards/emoji on confidential items,
todo-like reminders, saved replies referencing objects, user-callouts, review state, draft notes, todo snoozes.
For each, check whether a DestroyService/EntityLeaveService-style sweep covers ALL target types and ALL
partial-downgrade scenarios (direct->inherited, project transfer, group move, confidential toggle, visibility
reduction). Return models with a missing/partial sweep that an ownership-only read endpoint could exploit, shape (D).` },
]

const CAND_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['lane', 'candidates'],
  properties: {
    lane: { type: 'string' },
    candidates: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['id', 'surface', 'location', 'foreign_target', 'why_candidate', 'shape_match', 'prelim'],
        properties: {
          id: { type: 'string', description: 'short stable id e.g. rest-notes-mark / gql-todos-resolver' },
          surface: { type: 'string', enum: ['rest', 'graphql', 'model'] },
          location: { type: 'string', description: 'file:line of the load/expose' },
          foreign_target: { type: 'string', description: 'the foreign/target object + its read_* policy' },
          why_candidate: { type: 'string' },
          shape_match: { type: 'string', description: 'which of A/B/C/D it matches + evidence' },
          prelim: { type: 'string', enum: ['high', 'medium', 'low'] },
        },
      },
    },
  },
}

const TRACE_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['id', 'reaches_protected_data', 'access_loss_scenario', 'missing_check', 'leaked_fields', 'likelihood', 'evidence'],
  properties: {
    id: { type: 'string' },
    reaches_protected_data: { type: 'boolean' },
    access_loss_scenario: { type: 'string', description: 'concrete: role/visibility change that strips read but keeps the row' },
    missing_check: { type: 'string', description: 'the authorize!/can?(:read_*) that is absent, vs the policy that should apply' },
    leaked_fields: { type: 'string' },
    likelihood: { type: 'string', enum: ['high', 'medium', 'low'] },
    evidence: { type: 'string', description: 'file:line citations' },
  },
}

const VOTE_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['id', 'refuted', 'reason', 'severity_if_real'],
  properties: {
    id: { type: 'string' },
    refuted: { type: 'boolean', description: 'true if this is NOT a real exploitable BAC (default to refuted if uncertain)' },
    reason: { type: 'string', description: 'the exact downstream check that defeats it, or why it holds' },
    severity_if_real: { type: 'string', enum: ['high', 'medium', 'low', 'none'] },
  },
}

const CRITIC_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['missed_families', 'verdict'],
  properties: {
    missed_families: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['family', 'why'],
        properties: { family: { type: 'string' }, why: { type: 'string' } },
      },
    },
    verdict: { type: 'string' },
  },
}

const writeFile = (rel) =>
  `\n\nAfter StructuredOutput, ALSO write the same JSON to ${OUT}/${rel} via Write (Bash mkdir -p first). Absolute paths only.`

phase('Discover')
const discovered = await parallel(
  LANES.map((l) => () =>
    agent(
      `You are a GitLab access-control auditor running ONE blind discovery lane for variants of a validated
broken-access-control bug. Real source HEAD: ${CO}. Use ripgrep + Read aggressively; be exhaustive.
${PATTERN}

${l.prompt}

Return EVERY candidate you find (favor recall; later phases filter). Stable ids, file:line, the foreign target +
its policy, and which of shape A/B/C/D each matches.
Return via StructuredOutput.${writeFile(`discover-${l.key}.json`)}`,
      { label: `discover:${l.key}`, phase: 'Discover', schema: CAND_SCHEMA, model: 'opus' }
    )
  )
)

// Dedup candidates across lanes by id (cross-lane dedup genuinely needs all results -> barrier already happened).
const seen = new Map()
for (const d of discovered.filter(Boolean)) {
  for (const c of d.candidates || []) {
    const key = (c.id || c.location || JSON.stringify(c)).toLowerCase()
    if (!seen.has(key)) seen.set(key, { ...c, lanes: [d.lane] })
    else seen.get(key).lanes.push(d.lane)
  }
}
const candidates = [...seen.values()].filter((c) => c.prelim !== 'low' || (c.lanes && c.lanes.length > 1))
log(`Discover: ${[...seen.values()].length} unique candidates; ${candidates.length} carried forward (high/med or multi-lane)`)

// Pipeline: trace each candidate, then 3-vote adversarial confirm on those that reach protected data.
const results = await pipeline(
  candidates,
  (c) =>
    agent(
      `Forward-trace this candidate BAC variant against real GitLab HEAD at ${CO}. Read the actual route/resolver,
the entity/type, and the relevant policy. Decide whether attacker-owned-but-unreadable data is actually returned.
${PATTERN}

Candidate ${c.id} (${c.surface}) at ${c.location}
Foreign target: ${c.foreign_target}
Why candidate: ${c.why_candidate}
Shape match: ${c.shape_match}

Establish the CONCRETE access-loss (or never-had-access) scenario, the EXACT missing authorize!/can?(:read_*) vs the
policy that should govern the foreign object, and which fields leak. Be precise; if the route already authorizes the
foreign object (or a before-block / shared helper does), say so and set reaches_protected_data=false.
Return via StructuredOutput.${writeFile(`trace-${c.id}.json`)}`,
      { label: `trace:${c.id}`, phase: 'Trace', schema: TRACE_SCHEMA, model: 'opus' }
    ).then((t) => ({ ...t, _cand: c })),
  (t) => {
    if (!t || !t.reaches_protected_data) {
      return t ? { id: t.id, holds: false, votes: [], trace: t } : null
    }
    // 3 independent skeptics, each told to REFUTE; real only if <2 refute.
    return parallel(
      ['policy-evaluation', 'before-block-or-shared-helper', 'real-access-loss-reachability'].map((lens) => () =>
        agent(
          `Adversarially REFUTE this claimed BAC variant against real GitLab HEAD at ${CO}, through the lens of
"${lens}". DEFAULT refuted=true; only refuted=false if, after reading the real code, you cannot defeat it.
${PATTERN}

Candidate ${t.id} at ${t._cand.location}; foreign target ${t._cand.foreign_target}.
Trace claim: reaches_protected_data=true; access_loss="${t.access_loss_scenario}"; missing_check="${t.missing_check}";
leaked_fields="${t.leaked_fields}"; evidence="${t.evidence}".

Try to defeat it via your lens: is the foreign object actually authorized somewhere (before_action, shared helper,
the entity's own conditional expose, a policy rule that still denies, a strong_memoized finder that re-scopes)? Is
the access-loss scenario actually reachable (does losing direct access really leave the row + strip read)? Is the
serialized field actually sensitive/foreign? Give refuted (bool), the exact defeating check or why it holds, and
severity_if_real.
Return via StructuredOutput.${writeFile(`vote-${t.id}-${lens}.json`)}`,
          { label: `vote:${t.id}:${lens}`, phase: 'Confirm', schema: VOTE_SCHEMA, model: 'opus' }
        )
      )
    ).then((votes) => {
      const v = votes.filter(Boolean)
      const refutes = v.filter((x) => x.refuted).length
      const holds = v.length > 0 && refutes < 2
      const sevs = v.map((x) => x.severity_if_real).filter((s) => s && s !== 'none')
      return { id: t.id, holds, refutes, votes: v, trace: t, severity: sevs.sort()[0] || 'low', cand: t._cand }
    })
  }
)

const clean = results.filter(Boolean)
const confirmed = clean.filter((r) => r.holds)

phase('Critic')
const critic = await agent(
  `Completeness critic for a GitLab broken-access-control VARIANT hunt of the Todos mark_as_done class.
${PATTERN}
We swept these lanes: ownership-only REST lookups, entity foreign-target exposes, granular-only auth guards,
list-vs-item asymmetry, GraphQL resolvers, stale-row models. We confirmed ${confirmed.length} variants and examined
${candidates.length} candidates. What endpoint FAMILY, serializer group, GraphQL area, or stale-row model did we
likely UNDER-sweep — a concrete place the same shape (ownership-only load + foreign-target serialize + missing
read_* gate) probably also lives? Only list families grounded in how GitLab's API/policies are structured.
Return via StructuredOutput.${writeFile('critic.json')}`,
  { label: 'critic', phase: 'Critic', schema: CRITIC_SCHEMA, model: 'opus' }
)

return {
  unique_candidates: [...seen.values()].length,
  carried_forward: candidates.length,
  confirmed: confirmed
    .map((r) => ({
      id: r.id, severity: r.severity, refutes: `${r.refutes}/3`,
      location: r.cand && r.cand.location, foreign_target: r.cand && r.cand.foreign_target,
      access_loss: r.trace && r.trace.access_loss_scenario, missing_check: r.trace && r.trace.missing_check,
      leaked_fields: r.trace && r.trace.leaked_fields,
    }))
    .sort((a, b) => ('' + a.severity).localeCompare('' + b.severity)),
  rejected: clean.filter((r) => !r.holds).map((r) => ({ id: r.id, refutes: r.refutes ? `${r.refutes}/3` : 'trace-defeated', reason: r.trace && (r.trace.missing_check || 'did not reach protected data') })),
  critic_missed_families: critic ? critic.missed_families : [],
}
