export const meta = {
  name: 'bypass-elucubrate',
  description: 'For each mapped GitLab guard, enumerate every possible bypass ("there always is a bypass"), then adversarially confirm which hold at HEAD (Fable)',
  phases: [
    { title: 'Bypass', detail: 'one Fable attacker per guard: locate code, enumerate all bypass vectors, rate each', model: 'fable' },
    { title: 'Confirm', detail: 'adversarial validation of the best vector against real code', model: 'fable' },
  ],
}

const N = 76
const CO = '/home/x/Personal_Projects/find-ctfs/gitlab'
const WL = 'oracle/validation/bypass/worklist.json'
const OUT = 'oracle/validation/bypass'

const TECHNIQUES = `
GENERAL (any guard): parser/normalization differential (the guard parses input differently than the downstream sink — Go net/http vs Ruby vs the proxy vs the browser), TOCTOU (state changes between check and use), fail-open on error/exception/timeout, alternate route that skips the guard entirely (direct API vs UI, internal endpoint, deprecated route, GraphQL vs REST), case sensitivity, Unicode normalization / homoglyph / overlong UTF-8, percent/double/triple URL-encoding, null byte / control char injection, trailing dot / whitespace / CRLF, type coercion (truthy non-boolean, array-vs-scalar param), missing-vs-present param defaulting to allow.
regex_filter: unanchored pattern (^/$ match line not string -> inject before/after via newline; substring match -> wrap the needle in benign text), missing \\A..\\z, alternation gaps, greedy .* swallowing a delimiter, character-class holes (ANSI/CSI sequences ending in letters not 'm', e.g. [2J [H [K), Unicode equivalents of ASCII delimiters, ReDoS to fail-open via timeout, encoding so the dangerous token no longer matches the denylist regex but is decoded later.
validator: header case-insensitivity (HTTP headers are case-insensitive but a map lookup is case-sensitive), scheme-only validation with no host check (-> SSRF), prefix-strip leaving ../ traversal, canonicalization done after the check, extension/suffix-based type detection (rename file to evade), content-type sniffing differential, duplicate headers / header smuggling, IP-string vs resolved-IP differential (DNS rebinding).
denylist: list incompleteness (add a NEW route/slug/IP-range/file not yet listed), fail-open when backing store (Redis/YAML config) is down/absent/empty/malformed, obscure IPv6 ranges (IPv4-mapped ::ffff:, 6to4 2002::/16, teredo 2001::/32, NAT64 64:ff9b::), decimal/octal/hex IP encodings, DNS rebinding past an IP denylist, case/encoding evasion of string entries, TOCTOU between setting-read and decision.
`

const BYPASS_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['index', 'symbol', 'located', 'guard_summary', 'vectors', 'best_likelihood'],
  properties: {
    index: { type: 'integer' },
    symbol: { type: 'string' },
    located: { type: 'boolean', description: 'did you find the real code for this guard' },
    real_file: { type: 'string', description: 'actual file:line you read, or "not found"' },
    guard_summary: { type: 'string', description: 'what the guard actually checks/blocks, from the real code (<=2 sentences)' },
    vectors: {
      type: 'array',
      description: 'every plausible bypass you can conceive; empty only if the guard is genuinely airtight',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['technique', 'how', 'impact', 'likelihood'],
        properties: {
          technique: { type: 'string', description: 'short name, e.g. "unanchored-regex newline inject", "case-sensitive header map", "fail-open on Redis down"' },
          how: { type: 'string', description: 'concrete input/step that defeats this specific guard' },
          impact: { type: 'string', description: 'what the attacker gains if it works' },
          likelihood: { type: 'string', enum: ['high', 'medium', 'low'] },
          test_idea: { type: 'string', description: 'how to empirically check it' },
        },
      },
    },
    best_likelihood: { type: 'string', enum: ['high', 'medium', 'low', 'none'] },
    notes: { type: 'string' },
  },
}

const CONFIRM_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['index', 'holds', 'confidence', 'reason'],
  properties: {
    index: { type: 'integer' },
    holds: { type: 'boolean', description: 'true if the bypass genuinely works against the real code at HEAD' },
    confidence: { type: 'number' },
    reason: { type: 'string', description: '<=3 sentences: why it holds, or what defeats it (downstream re-check, anchoring, auth, etc.)' },
    poc: { type: 'string', description: 'only if holds: concrete request/input that demonstrates the bypass' },
  },
}

function bypassPrompt(i) {
  return `You are an OFFENSIVE security researcher. Operating philosophy: "THERE IS ALWAYS A BYPASS." For ONE GitLab guard, your job is to elucubrate EVERY plausible way it could be defeated — be creative and exhaustive, then keep only vectors that are concretely arguable against the real code. GitLab source (HEAD): ${CO}

STEP 1 — load your guard (index ${i}):
  python3 -c "import json;print(json.dumps(json.load(open('${WL}'))[${i}]))"
Keys: symbol, fileline (may be ''), mechanism (regex_filter|validator|denylist), mode, stage, score, reason (a truncated hint about a suspected weakness).

STEP 2 — LOCATE the real code. If fileline is given, open ${CO}/<that path> around the line. If only a symbol is given, grep ${CO} (app/ lib/ ee/ workhorse/ and *.rb/*.go/*.js) to find the definition. Read enough to understand exactly what the guard checks, what input it sees, and what happens downstream of it (the sink it is supposed to protect). If you truly cannot find it, set located=false and explain in notes — still brainstorm vectors from the symbol+reason.

STEP 3 — ENUMERATE BYPASSES. Apply this technique catalog and anything else you can invent. Default mindset: the guard IS defeatable; find how.
${TECHNIQUES}
For THIS guard's mechanism especially, walk the relevant techniques and decide which produce a concrete input that the guard would wave through but the downstream sink would treat as dangerous. For each viable idea record: technique, how (concrete input/step), impact, likelihood (high/medium/low based on how plausibly it reaches a real sink with no other guard catching it), test_idea.

STEP 4 — be honest about likelihood. high = you can name a concrete input and a reachable sink with no second guard; medium = plausible but depends on an unverified downstream assumption; low = theoretical/needs special config. Set best_likelihood to the max across vectors (or "none" if the guard is genuinely airtight — say why in notes).

STEP 5 — persist your result JSON to ${OUT}/bypass-${i}.json, then return via StructuredOutput. index=${i}, symbol=<the symbol>.`
}

function confirmPrompt(i, b, best) {
  return `An offensive researcher claims a bypass for a GitLab guard. Your job: VALIDATE it against the real code at HEAD — does it actually work, or does something defeat it? Be rigorous; do not accept hand-waving. Source (HEAD): ${CO}

Guard: ${b.symbol}  (real code: ${b.real_file || b.symbol})
Guard does: ${b.guard_summary}
Best claimed bypass:
  technique: ${best.technique}
  how: ${best.how}
  impact: ${best.impact}
  likelihood(claimed): ${best.likelihood}
  test_idea: ${best.test_idea || '(none)'}

Read the REAL code at ${b.real_file || 'the guard symbol (grep ' + CO + ')'} AND the downstream path the guard protects. Determine:
  - Does the crafted input actually pass the guard as written? (Check anchoring, case handling, decode order, types.)
  - Does it actually reach and trigger the dangerous sink, or is there a SECOND guard / re-validation / auth / canonicalization downstream that catches it?
  - Is the protected path even reachable by an unprivileged attacker (auth/route opt-in)?
Set holds=true ONLY if the bypass reaches the sink end-to-end with real attacker impact; otherwise holds=false and name what defeats it. If holds, give a concrete poc (request/input).

Persist to ${OUT}/confirm-${i}.json, then return via StructuredOutput. index=${i}.`
}

phase('Bypass')
const results = await pipeline(
  Array.from({ length: N }, (_, i) => i),
  (i) => agent(bypassPrompt(i), { label: `bypass#${i}`, phase: 'Bypass', model: 'fable', schema: BYPASS_SCHEMA }),
  (b, i) => {
    if (!b) return { index: i, best_likelihood: 'error', vectors: [] }
    if (b.best_likelihood !== 'high' && b.best_likelihood !== 'medium') return b
    const ranked = (b.vectors || []).slice().sort((x, y) => {
      const o = { high: 0, medium: 1, low: 2 }
      return (o[x.likelihood] ?? 9) - (o[y.likelihood] ?? 9)
    })
    const best = ranked[0]
    if (!best) return b
    return agent(confirmPrompt(i, b, best), { label: `confirm#${i}`, phase: 'Confirm', model: 'fable', schema: CONFIRM_SCHEMA })
      .then((c) => ({ ...b, best_vector: best, confirm_holds: c ? c.holds : null, confirm_reason: c ? c.reason : 'null', confirm_poc: c ? c.poc : '', confirmed: !!(c && c.holds) }))
  }
)

const clean = results.filter(Boolean)
const confirmed = clean.filter((r) => r.confirmed)
const highUnconf = clean.filter((r) => !r.confirmed && r.best_likelihood === 'high')
const tally = {}
for (const r of clean) tally[r.best_likelihood || 'unknown'] = (tally[r.best_likelihood || 'unknown'] || 0) + 1
log(`bypass done: ${clean.length} guards, best_likelihood ${JSON.stringify(tally)}, CONFIRMED bypasses=${confirmed.length}`)

return {
  total: clean.length,
  best_likelihood_tally: tally,
  confirmed_bypasses: confirmed.map((r) => ({ symbol: r.symbol, file: r.real_file, vector: r.best_vector, poc: r.confirm_poc, reason: r.confirm_reason })),
  high_unconfirmed: highUnconf.map((r) => ({ symbol: r.symbol, file: r.real_file, best: (r.vectors || []).find((v) => v.likelihood === 'high'), confirm_reason: r.confirm_reason })),
  all: clean,
}
