export const meta = {
  name: 'injection-variant-hunt',
  description: 'Forward sink-discovery at GitLab HEAD across injection classes (Fable), with adversarial refute',
  phases: [
    { title: 'Hunt', detail: 'one Fable agent per injection class: grep sinks -> trace taint', model: 'fable' },
    { title: 'Refute', detail: 'adversarial refute of each candidate', model: 'fable' },
  ],
}

const CO = '/home/x/Personal_Projects/find-ctfs/gitlab'
const OUT = 'oracle/validation/inj'

const CATS = [
  { key: 'sql-injection', sinks: 'raw string interpolation in where/order/group/having/select/pluck, find_by_sql, execute(, exec_query, Arel.sql(, sanitize_sql misuse' },
  { key: 'command-injection', sinks: 'backticks, system(, exec(, IO.popen, Open3.*, %x(, spawn(, Kernel.system' },
  { key: 'ssrf', sinks: 'Gitlab::HTTP.*, Net::HTTP, HTTParty, Faraday, RestClient, URI.open/open( on a user URL, webhook/import/proxy url params' },
  { key: 'path-traversal', sinks: 'File.read/open/join with params, send_file, IO.read, Dir[, Pathname, FileUtils.* on user-derived paths' },
  { key: 'deserialization', sinks: 'Marshal.load/restore, YAML.load (not safe_load), Oj.load (not :strict), JSON.load, Psych.load on user data' },
  { key: 'code-injection', sinks: 'eval/instance_eval/class_eval/module_eval, send(/public_send( with params, constantize, const_get, define_method on user input' },
  { key: 'open-redirect', sinks: 'redirect_to with params/[:url]/[:redirect]/[:return_to], redirect_back fallback to user value' },
  { key: 'mass-assignment', sinks: 'params.permit!, update(params)/assign_attributes(params) without permit, params.merge into model attrs' },
]

const HUNT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['category', 'candidates', 'note'],
  properties: {
    category: { type: 'string' },
    candidates: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['file', 'line', 'sink', 'source', 'severity', 'reason'],
        properties: {
          file: { type: 'string' },
          line: { type: 'integer' },
          sink: { type: 'string' },
          source: { type: 'string', description: 'the attacker-controlled source reaching the sink' },
          severity: { type: 'string', enum: ['high', 'medium', 'low'] },
          reason: { type: 'string' },
        },
      },
    },
    note: { type: 'string', description: 'what was scanned / why no/few candidates' },
  },
}

const REFUTE_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['refuted', 'confidence', 'reason'],
  properties: {
    refuted: { type: 'boolean' }, confidence: { type: 'number' }, reason: { type: 'string' },
  },
}

function huntPrompt(cat) {
  return `You are hunting for ${cat.key.toUpperCase()} variants in GitLab at HEAD. Default to NO candidate; only raise one with a concrete attacker-controlled source reaching the sink UNSANITIZED. GitLab source: ${CO}

Sink patterns for this class: ${cat.sinks}

METHOD:
1. From ${CO}, grep app/ lib/ ee/app/ ee/lib/ for these sink patterns (use ripgrep/grep -rn with focused regexes; iterate a few patterns). Prioritize request-reachable code: controllers, lib/api (Grape), graphql resolvers/mutations, and services/finders that take params.
2. Rank hits by attacker-reachability. IGNORE: constants, allow-lists, internal/non-attacker values, test/spec/vendor dirs, already-sanitized (parameterized query/placeholder, safe_load, permit-listed, escaped, validated path).
3. Deep-trace your top 5-10 suspects: confirm a concrete source (params/request/body/header/external) reaches the sink with NO neutralization. For SQLi require raw interpolation (not bind params); for SSRF require a user-controlled host not allow-listed/validated by Gitlab::UrlBlocker; for path-traversal require an un-expanded/unchecked user path; for deserialization require user bytes into an unsafe loader; for code-injection require user input into eval/send/constantize without an allow-list; for open-redirect require redirect target from user input without host validation; for mass-assignment require a model write of unfiltered params including a sensitive attribute.
4. Return only concrete candidates (file, line, sink, source, severity, reason). If the class is clean/all-guarded, return [] and explain in note what you checked.

Persist your result JSON to ${OUT}/${cat.key}.json, then return via StructuredOutput. category="${cat.key}".`
}

function refutePrompt(c, category) {
  return `A scanner flagged a ${category} vulnerability in GitLab at HEAD. REFUTE it. Default refuted=true unless the exploit clearly holds end-to-end. Source: ${CO}

Claim:
  file: ${c.file}:${c.line}
  sink: ${c.sink}
  source: ${c.source}
  severity: ${c.severity}
  reason: ${c.reason}

Read ${CO}/${c.file} around the sink and trace the source. Break it if you can: is the value really attacker-controlled, or constant/allow-listed/internal? Is it sanitized (bind params/placeholders, Gitlab::UrlBlocker, expand_path+prefix check, safe_load, strong params/permit, host validation, escaping)? Is the code dead/test/vendor? Is there an upstream guard/authz? Set refuted=true if any defeats it; refuted=false only if a concrete exploit holds. Return via StructuredOutput.`
}

phase('Hunt')
const results = await pipeline(
  CATS,
  (cat) => agent(huntPrompt(cat), { label: `hunt:${cat.key}`, phase: 'Hunt', model: 'fable', schema: HUNT_SCHEMA }),
  (r, cat) => {
    if (!r || !r.candidates || !r.candidates.length) return r
    return parallel(
      r.candidates.map((c) => () =>
        agent(refutePrompt(c, cat.key), { label: `refute:${cat.key}`, phase: 'Refute', model: 'fable', schema: REFUTE_SCHEMA })
          .then((v) => ({ ...c, category: cat.key, refuted: v ? v.refuted : null, refute_reason: v ? v.reason : 'null', survives: v ? !v.refuted : false }))
      )
    ).then((judged) => ({ ...r, candidates: judged }))
  }
)

const clean = results.filter(Boolean)
const allCand = clean.flatMap((r) => (r.candidates || []).map((c) => ({ category: r.category, ...c })))
const survivors = allCand.filter((c) => c.survives)
log(`injection hunt: ${clean.length} classes, ${allCand.length} candidates, ${survivors.length} survive refute`)

return {
  classes: clean.length,
  total_candidates: allCand.length,
  survivors,
  by_class: clean.map((r) => ({ category: r.category, n: (r.candidates || []).length, survivors: (r.candidates || []).filter((c) => c.survives).length, note: r.note })),
  all_candidates: allCand,
}
