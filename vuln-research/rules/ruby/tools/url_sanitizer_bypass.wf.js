export const meta = {
  name: 'url-sanitizer-bypass',
  description: 'Opus "there is always a bypass" elucubration on 3 GitLab URL/protocol sanitizers, then adversarial confirm against real HEAD code + downstream sink',
  phases: [
    { title: 'Bypass', detail: 'one Opus attacker per sanitizer: locate code, enumerate EVERY bypass, trace to a real sink, rate each', model: 'opus' },
    { title: 'Confirm', detail: 'adversarial Opus validation of the best vector(s) end-to-end against the real sink', model: 'opus' },
  ],
}

const CO = '/home/x/Personal_Projects/find-ctfs/gitlab'
const OUT = 'oracle/validation/url-sanitizer-bypass'

// The 3 guards the user flagged, with the suspected-weakness hint for each.
const GUARDS = [
  {
    key: 'urlsanitizer-sanitize',
    symbol: 'Gitlab::UrlSanitizer.sanitize',
    score: 0.25,
    hint: 'URI regex may not match all valid userinfo formats — credentials/userinfo that the regex fails to recognise survive into the "sanitized" output.',
    mechanism: 'regex_filter/validator',
    sink_hint: 'Output is stored/logged/displayed for mirror URLs, import URLs, repository remotes, webhook URLs. A miss = credential disclosure (user:pass leaked into logs/UI/DB). Also feeds URLs that are later FETCHED (import/mirror/webhook) — a parser differential here can also enable SSRF / credential exfiltration to an attacker host.',
  },
  {
    key: 'urlsanitizer-strip-userinfo',
    symbol: 'Gitlab::UrlSanitizer.strip_userinfo',
    score: 0.25,
    hint: 'Only matches scheme-based URLs, misses schemeless — a schemeless or non-standard URL keeps its user:password userinfo because the strip logic only fires when a scheme is present.',
    mechanism: 'regex_filter/validator',
    sink_hint: 'Used to remove credentials before showing/logging a URL (error messages, import/mirror status, audit). A miss = the password is shown to users / written to logs that lower-privileged users or attackers can read.',
  },
  {
    key: 'sanitizenodelink-safe-protocol',
    symbol: 'Gitlab::Utils::SanitizeNodeLink#safe_protocol?',
    score: 0.15,
    hint: '"+" is preserved in the scheme, so "javascript+foo:" (or data+x:, vbscript+y:) style schemes may slip past the allowlist while still being treated as javascript: by a browser — classic protocol-allowlist bypass leading to stored XSS in rendered markdown/HTML links.',
    mechanism: 'denylist/allowlist',
    sink_hint: 'This gates href/src/xlink:href protocols in sanitized user markdown/HTML (notes, issues, MR descriptions, wiki). A bypass = STORED XSS executing in the gitlab.com origin for any viewer — high impact.',
  },
]

const TECHNIQUES = `
URL / userinfo parsing differentials (sanitize, strip_userinfo):
- Ruby URI.parse / Addressable vs the regex vs what the eventual HTTP client (Net::HTTP, Gitlab::HTTP, git, workhorse/Go) actually connects to. The "sanitizer" and the "fetcher" disagreeing is the whole game.
- userinfo edge cases: empty user (":pass@host"), empty pass ("user:@host"), no pass ("user@host"), multiple @ ("a@b@host" — which @ wins?), userinfo containing encoded "@" (%40), "/", "?", "#", ":", backslash, whitespace, control chars, unicode.
- schemeless URLs ("//host/path", "host:port", "user:pass@host"), scheme-relative, protocol-relative, leading-whitespace/control before scheme ("\\tjavascript:", "\\njava\\tscript:"), uppercase/mixed-case scheme, scheme with "+"/"-"/"." (RFC 3986 scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )).
- credentials hidden behind fragment/query, IDN/punycode host, IPv6 literal "[::1]" userinfo confusion, trailing-dot host, port confusion.
- anchoring of the regex: ^/$ vs \\A..\\z, line-vs-string, substring match, unanchored alternation, greedy capture swallowing a delimiter.

Protocol-allowlist bypass (safe_protocol?):
- scheme grammar abuse: "javascript+x:", "java\\tscript:", "JaVaScRiPt:", "java script:" (space/tab/newline/null inside or before), "&#x6a;avascript:", "\\u0001javascript:", leading/trailing whitespace, BOM, control chars (the HTML/URL parser strips them, the allowlist check does not).
- relative resolution: the link is judged safe but resolves to a dangerous absolute scheme after base-href / redirect.
- the allowlist vs the actual browser: how does Chrome/Firefox interpret the scheme that the check waved through? "javascript+foo:" — does the browser execute it? "data:text/html", "vbscript:", "filesystem:", "blob:".
- where the scheme is extracted: does safe_protocol? split on ":" the same way the browser does? differential between Ruby's URI scheme extraction and the DOM URL parser.
- mutation XSS: sanitized output re-parsed differently by the browser (mXSS), entity decoding after the check, double-decoding.
- node attributes beyond href: src, xlink:href, srcset, formaction, style url(), etc.
`

const BYPASS_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['key', 'symbol', 'located', 'real_file', 'guard_summary', 'downstream_sink', 'vectors', 'best_likelihood', 'introduces_vuln'],
  properties: {
    key: { type: 'string' },
    symbol: { type: 'string' },
    located: { type: 'boolean' },
    real_file: { type: 'string', description: 'actual file:line of the guard definition you read' },
    guard_summary: { type: 'string', description: 'what the guard actually does, from the real code (regex/allowlist quoted), <=3 sentences' },
    downstream_sink: { type: 'string', description: 'the real sink the guard protects (where the sanitized value is fetched/rendered/logged), file:line if found' },
    vectors: {
      type: 'array',
      description: 'every plausible bypass; each must be concrete against the quoted code',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['technique', 'input', 'why_passes', 'impact', 'likelihood'],
        properties: {
          technique: { type: 'string' },
          input: { type: 'string', description: 'the exact crafted URL/string/markdown that defeats the guard' },
          why_passes: { type: 'string', description: 'why the guard waves it through (regex anchor gap, schemeless miss, "+"-scheme, etc.)' },
          impact: { type: 'string', description: 'what the attacker gains downstream (credential leak / SSRF / stored XSS / ...)' },
          likelihood: { type: 'string', enum: ['high', 'medium', 'low'] },
          test_idea: { type: 'string', description: 'how to empirically check (irb snippet, markdown payload, request)' },
        },
      },
    },
    best_likelihood: { type: 'string', enum: ['high', 'medium', 'low', 'none'] },
    introduces_vuln: { type: 'boolean', description: 'does any viable bypass reach a real sink with real security impact' },
    notes: { type: 'string' },
  },
}

const CONFIRM_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['key', 'holds', 'vuln_class', 'confidence', 'reason'],
  properties: {
    key: { type: 'string' },
    holds: { type: 'boolean', description: 'true only if the bypass reaches the sink end-to-end with real impact at HEAD' },
    vuln_class: { type: 'string', description: 'SSRF / credential-disclosure / stored-XSS / none' },
    confidence: { type: 'number' },
    reason: { type: 'string', description: '<=4 sentences: why it holds, or exactly what downstream defeats it (re-sanitization, browser does not execute, value never fetched, etc.)' },
    poc: { type: 'string', description: 'only if holds: concrete end-to-end PoC (input + where it lands + observed effect)' },
    severity_guess: { type: 'string', enum: ['critical', 'high', 'medium', 'low', 'info', 'none'] },
  },
}

function bypassPrompt(g) {
  return `You are an OFFENSIVE security researcher auditing ONE GitLab sanitizer. Operating philosophy: "THERE IS ALWAYS A BYPASS." Elucubrate EVERY plausible way this guard can be defeated, then keep the vectors that are concretely arguable against the REAL code. GitLab source (HEAD): ${CO}

GUARD: ${g.symbol}
Suspected weakness (hint): ${g.hint}
Mechanism class: ${g.mechanism}
Where its output is used (sink hint): ${g.sink_hint}

STEP 1 — LOCATE the real code. grep ${CO} for the method (lib/gitlab/url_sanitizer.rb, lib/gitlab/utils/sanitize_node_link.rb, or wherever it lives). Read the FULL method and any regex/constant/allowlist it uses. Quote the exact regex / allowlist / split logic in guard_summary. Set located + real_file.

STEP 2 — TRACE THE SINK. Find where the sanitized value actually goes: who calls this method and what do they do with the result? For sanitize/strip_userinfo: is the output logged, shown in the UI, stored, OR later fetched by an HTTP/git client (import/mirror/webhook)? For safe_protocol?: which renderer/pipeline calls it, and is its verdict the ONLY thing standing between attacker markdown and a rendered href? Record downstream_sink (file:line). The bypass only matters if it reaches a real sink.

STEP 3 — ENUMERATE BYPASSES. Apply this catalog and invent more. Default mindset: the guard IS defeatable.
${TECHNIQUES}
For EACH viable idea give: technique, input (the EXACT crafted string/URL/markdown), why_passes (tie it to the quoted regex/allowlist — e.g. "scheme regex allows '+', browser treats javascript+foo: as javascript:"), impact (credential leak / SSRF / stored XSS), likelihood, test_idea. Be concrete: a vector with no exact input is worthless.

STEP 4 — be honest. high = exact input + reachable sink + no second guard catches it; medium = depends on an unverified downstream/browser assumption; low = theoretical/needs special config. Set best_likelihood to the max and introduces_vuln=true iff some vector reaches a sink with real impact.

STEP 5 — persist your result JSON to ${OUT}/bypass-${g.key}.json, then return via StructuredOutput. key="${g.key}".`
}

function confirmPrompt(g, b, best) {
  return `An offensive researcher claims a bypass of a GitLab sanitizer. VALIDATE it end-to-end against the real code at HEAD — does it actually reach the sink with real impact, or does something downstream defeat it? Be rigorous; reject hand-waving. Source (HEAD): ${CO}

Guard: ${b.symbol}  (code: ${b.real_file})
Guard does: ${b.guard_summary}
Downstream sink (claimed): ${b.downstream_sink}
Best claimed bypass:
  technique: ${best.technique}
  input: ${best.input}
  why_passes: ${best.why_passes}
  impact: ${best.impact}
  test_idea: ${best.test_idea || '(none)'}

Read the REAL guard code AND the full path from it to the sink. Determine:
  - Does the crafted input actually pass the guard as written? (Check the exact regex anchors, the allowlist membership test, scheme extraction, decode order, case handling.)
  - Does it actually reach the dangerous behaviour? For XSS: would a real browser execute the scheme that survived (e.g. does Chrome run "javascript+foo:"? — reason precisely; the "+" makes it a DISTINCT scheme to the browser, which generally does NOT execute it — say so if true), and is there a downstream HTML sanitizer (e.g. the GitLab sanitize pipeline / Banzai / rails-html-sanitizer) that strips it anyway? For SSRF/credential leak: is the value actually fetched or actually shown to someone who shouldn't see it, with no second sanitization?
  - Is the path reachable by an unprivileged attacker?
Set holds=true ONLY if it reaches the sink end-to-end with real impact; otherwise holds=false and name exactly what defeats it. Give vuln_class, severity_guess, and (if holds) a concrete poc.

Persist to ${OUT}/confirm-${g.key}.json, then return via StructuredOutput. key="${g.key}".`
}

phase('Bypass')
const results = await pipeline(
  GUARDS,
  (g) => agent(bypassPrompt(g), { label: `bypass:${g.key}`, phase: 'Bypass', model: 'opus', schema: BYPASS_SCHEMA }),
  (b, g) => {
    if (!b) return { key: g.key, symbol: g.symbol, best_likelihood: 'error', vectors: [], introduces_vuln: false }
    if (b.best_likelihood !== 'high' && b.best_likelihood !== 'medium') return b
    const ranked = (b.vectors || []).slice().sort((x, y) => {
      const o = { high: 0, medium: 1, low: 2 }
      return (o[x.likelihood] ?? 9) - (o[y.likelihood] ?? 9)
    })
    const best = ranked[0]
    if (!best) return b
    return agent(confirmPrompt(g, b, best), { label: `confirm:${g.key}`, phase: 'Confirm', model: 'opus', schema: CONFIRM_SCHEMA })
      .then((c) => ({
        ...b,
        best_vector: best,
        confirm_holds: c ? c.holds : null,
        confirm_vuln_class: c ? c.vuln_class : 'unknown',
        confirm_severity: c ? c.severity_guess : 'unknown',
        confirm_reason: c ? c.reason : 'null',
        confirm_poc: c ? c.poc : '',
        confirmed: !!(c && c.holds),
      }))
  }
)

const clean = results.filter(Boolean)
const confirmed = clean.filter((r) => r.confirmed)
const tally = {}
for (const r of clean) tally[r.best_likelihood || 'unknown'] = (tally[r.best_likelihood || 'unknown'] || 0) + 1
log(`url-sanitizer-bypass done: ${clean.length} guards, best_likelihood ${JSON.stringify(tally)}, CONFIRMED real vulns=${confirmed.length}`)

return {
  total: clean.length,
  best_likelihood_tally: tally,
  confirmed: confirmed.map((r) => ({ symbol: r.symbol, vuln_class: r.confirm_vuln_class, severity: r.confirm_severity, vector: r.best_vector, poc: r.confirm_poc, reason: r.confirm_reason })),
  defeated: clean.filter((r) => !r.confirmed).map((r) => ({ symbol: r.symbol, best_likelihood: r.best_likelihood, why_defeated: r.confirm_reason || '(no high/medium vector to confirm)' })),
  all: clean,
}
