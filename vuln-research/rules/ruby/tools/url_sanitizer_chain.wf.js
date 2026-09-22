export const meta = {
  name: 'url-sanitizer-chain',
  description: 'Opus deep re-audit of the 3 "defeated" GitLab URL/protocol sanitizers: exhaustively enumerate ALL callers (direct + transitive, CE+EE), then trace each CHAINED forward path to a second/broader sink, then adversarially confirm the strongest chained vectors against real HEAD code.',
  phases: [
    { title: 'Enumerate', detail: 'one Opus agent per guard: grep every caller + transitive caller, map chained sinks & audiences', model: 'opus' },
    { title: 'Trace', detail: 'per candidate chained path: follow the value forward to a 2nd sink / broader audience', model: 'opus' },
    { title: 'Confirm', detail: 'adversarially validate the strongest chained vectors end-to-end against real code', model: 'opus' },
  ],
}

const CO = '/home/x/Personal_Projects/find-ctfs/gitlab'
const OUT = '/home/x/Personal_Projects/skillsmd/vuln-research/rules/ruby/oracle/validation/url-sanitizer-bypass'

// What the FIRST pass already established (so agents do not re-derive, and focus only on NEW chained paths)
const PRIOR = `
PRIOR PASS RESULT (immediate-sink only — do NOT repeat, find what it MISSED):
- Gitlab::UrlSanitizer.sanitize (lib/gitlab/url_sanitizer.rb:36, URI_REGEXP :21, sanitize_unencoded :47):
  GUARD IS BYPASSABLE — URI_REGEXP uses URI::REGEXP::PATTERN::USERINFO = [\\-_.!~*'()a-zA-Z\\d;:&=+$,]|%hh.
  gsub rewrites only the matched substring, so any credential char OUTSIDE that charset (space, backslash,
  | " [ ] { } < > # / ? bare %, control, non-ASCII) terminates the match leftward and the credential PREFIX
  leaks UNMASKED. Verified empirically. Immediate sinks checked & DEFEATED:
    * remote_mirror.rb:170 + EE project_import_state.rb:246 pass user:/password: kwargs -> sanitize_unencoded
      literal-masks first -> fully masked.
    * source_user.rb:213 + importer paths chain Projects::ImportErrorFilter (/[^\\s]*\\/[^\\s]*/) -> whole URL token -> [FILTERED].
    * Only un-defeated: CE project_import_state.rb:190 via ImportFailureService, but needs non-token password
      with a non-allowlist char, leaks short prefix, surfaces only to project admin viewing own credential (self-disclosure).
- Gitlab::UrlSanitizer.strip_userinfo (lib/gitlab/url_sanitizer.rb:60-65): private, used ONLY by valid?/valid_web?
  to extract uri.scheme for a positive allowlist. Output is a BOOLEAN only — never rendered/logged/stored/fetched.
  Schemeless-miss is fail-CLOSED. (DEFEATED — no sink for the stripped string.)
- Gitlab::Utils::SanitizeNodeLink#safe_protocol? (gems/gitlab-utils/.../sanitize_node_link.rb:36-45): 3-item DENYLIST
  (data/javascript/vbscript). 'javascript+foo:' passes the denylist (gsub preserves '+'), and the <a> protocol
  backstop is deleted (base_sanitization_filter.rb:62) so this is the SOLE href gate — BUT a browser does not
  execute non-exact 'javascript:' so the surviving href is inert. Control-char schemes raise Addressable
  InvalidURIError -> link removed (remove_invalid_links:true). (DEFEATED — guard bypassed, no executable sink.)
`

// The chained angles the first pass did NOT explore — feed these as the hunting map.
const GUARDS = [
  {
    key: 'sanitize',
    symbol: 'Gitlab::UrlSanitizer.sanitize',
    chain_hints: `
The guard bypass (credential prefix leak) is PROVEN. The question is purely: does the leaked prefix reach a
BROADER AUDIENCE than the first pass's "project admin viewing own credential"? Hunt these CHAINED forward paths:
  1. remote_mirror.last_error / import_state.last_error / jira_import_state — is the SAME field (or a sibling
     field that carries the raw URL) exposed via REST API (e.g. RemoteMirror entity, ProjectImportEntity,
     GET /projects/:id/mirror/pull, import_status, /remote_mirrors), GraphQL (MirrorType, ImportStatusType,
     last_error fields), or webhook/system-hook payloads? Even if last_error is masked, is the raw url/import_url
     emitted UNmasked in an adjacent field/event to a wider role (Reporter/Guest/Developer, or another project)?
  2. Notification emails / Slack/Discord/webhook integrations fired on mirror-update-failed or import-failed —
     do they embed last_error or the URL? What recipient set? (mirror failure notifications go to project maintainers/owner.)
  3. Audit events / abuse reports / Sentry/o11y (o11y_provisioning_client.rb:69) / structured logs ingested into
     a queryable store readable by a broader set than the credential owner.
  4. CHAINING the OTHER direction: does any caller sanitize() then RE-PARSE or RE-SANITIZE the masked string and
     reconstruct/expose the credential, or store both masked + raw? Look for masked_url vs full_url confusion.
  5. Cross-tenant: does last_error from a mirror configured by user A ever surface to user B on a fork / shared
     project / group mirror where B did not supply the credential? That would upgrade self-disclosure to real disclosure.`,
  },
  {
    key: 'strip-userinfo',
    symbol: 'Gitlab::UrlSanitizer.strip_userinfo',
    chain_hints: `
strip_userinfo only feeds valid?/valid_web? (a boolean). The chained question: what does that boolean GATE, and
can the gated FETCH leak — i.e. SSRF / credential exfil / response reflection? Hunt:
  1. valid? consumers that then FETCH: lib/gitlab/http_io.rb:20, lib/gitlab/ci/config/external/file/remote.rb:54,
     lib/gitlab/dependency_linker/base_linker.rb:67, app/models/project.rb:1830, remote_mirror.rb:197, webhook URL
     validation, Prometheus/integration URLs. If valid? is the ONLY guard (no separate Gitlab::HTTP_V2/UrlBlocker
     SSRF check), can a userinfo-bearing or DNS-rebinding/redirect URL reach the fetcher and exfil credentials or
     hit internal hosts? Does the fetched RESPONSE/error get reflected into a CI job log, artifact, import error,
     or dependency-link render (a second sink)?
  2. valid? vs the actual fetch URL differential: valid? strips userinfo to read scheme, but the ORIGINAL url
     (with userinfo) is what gets fetched. Is there any path where validation passes on a stripped/normalized
     form but the fetcher acts on a DIFFERENT (credential- or host-bearing) form -> SSRF allowlist bypass?
  3. valid_web? -> dependency_linker base_linker.rb:67 emits an href. The first pass said it's html_escape_once'd —
     verify there is no second render path (AsciiDoc, RST, changelog, package registry README) where valid_web?
     gates an href WITHOUT escaping, or where the scheme allowlist is looser.
  4. Case-sensitivity fail-closed (HTTP:// rejected) — confirm it cannot be flipped fail-OPEN anywhere (e.g. a
     caller that lowercases first then trusts valid?, admitting a scheme the allowlist would otherwise reject).`,
  },
  {
    key: 'safe-protocol',
    symbol: 'Gitlab::Utils::SanitizeNodeLink#safe_protocol?',
    chain_hints: `
The 'javascript+foo:' guard bypass is proven-but-inert in <a href> via SanitizeLinkFilter. The chained question:
is there ANOTHER consumer / render path where the SAME permitted scheme IS executable, or where the value is
re-rendered (mXSS) into an executing context? Hunt:
  1. ALL callers of safe_protocol? / permit_url? / sanitize_unsafe_links, and every Banzai filter that includes
     SanitizeNodeLink. Beyond <a href>: src/xlink:href/srcset/poster/formaction/data attributes, SVG <use xlink:href>,
     MathML, <image>, iframe srcdoc, CSS url(). Is the protocol backstop deleted (base_sanitization_filter.rb:62
     style allowlist[:protocols].delete) for any element OTHER than 'a' where the scheme IS executable
     (e.g. svg use href, or an element that triggers fetch/navigation)?
  2. Differential render paths that DON'T go through Addressable's strict parser: wiki_link_filter.rb (fail-open
     remove_invalid_links:false — already noted, but trace where its output goes), AsciiDoc pipeline, reStructuredText,
     Markdown reference-style links, autolink filter, the snippet/blob highlight path, mermaid, KaTeX, package READMEs.
     Does any of them apply safe_protocol? to a scheme that a browser DOES treat as the dangerous one
     (e.g. 'java\\nscript:' surviving via a parser that strips the control char AFTER the check, or a scheme that
     normalizes to data:/javascript: in a specific browser)?
  3. mXSS: does the sanitized HTML get re-parsed/re-serialized (e.g. nokogiri reserialize, copy-paste sanitizer,
     notification email HTML, RSS/Atom feed, ICS) where 'javascript+foo:' or a denylist-passing scheme mutates
     into an executable form?
  4. Server-side consumers of the permitted href: link unfurling / preview / OpenGraph / asset proxy — does the
     server FETCH a safe_protocol?-permitted URL (blob:/filesystem:/view-source:/jar: or a custom scheme) -> SSRF
     or local-file read? The first pass dismissed these as browser-inert but did NOT check server-side fetchers.`,
  },
]

const ENUM_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['key', 'symbol', 'all_callers', 'candidate_paths'],
  properties: {
    key: { type: 'string' },
    symbol: { type: 'string' },
    all_callers: {
      type: 'array',
      description: 'Every direct + transitive caller found, CE and EE, with file:line.',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['file_line', 'note'],
        properties: { file_line: { type: 'string' }, note: { type: 'string' } },
      },
    },
    candidate_paths: {
      type: 'array',
      description: 'Chained forward paths worth tracing: value flows from the guard to a 2nd/broader sink.',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['path_id', 'entry', 'chain', 'second_sink', 'audience', 'why_candidate', 'prelim_likelihood'],
        properties: {
          path_id: { type: 'string', description: 'short unique id e.g. sanitize-mirror-graphql' },
          entry: { type: 'string', description: 'file:line where the guard is called' },
          chain: { type: 'string', description: 'value flow: A.field -> serializer/event/email -> ... -> sink' },
          second_sink: { type: 'string', description: 'the broader/second sink file:line' },
          audience: { type: 'string', description: 'who can observe the second sink (role / cross-tenant?)' },
          why_candidate: { type: 'string' },
          prelim_likelihood: { type: 'string', enum: ['high', 'medium', 'low'] },
        },
      },
    },
  },
}

const TRACE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['path_id', 'reaches_broader_sink', 'broader_than_prior', 'audience', 'leak_content', 'defeated_by', 'likelihood', 'evidence'],
  properties: {
    path_id: { type: 'string' },
    reaches_broader_sink: { type: 'boolean', description: 'does the guarded value actually reach the 2nd sink?' },
    broader_than_prior: { type: 'boolean', description: 'is the audience broader than the first pass concluded?' },
    audience: { type: 'string' },
    leak_content: { type: 'string', description: 'what exactly is exposed (full url? prefix? executable href?)' },
    defeated_by: { type: 'string', description: 'if defeated, the exact downstream protection; else "none"' },
    likelihood: { type: 'string', enum: ['high', 'medium', 'low'] },
    evidence: { type: 'string', description: 'file:line citations proving the trace' },
  },
}

const CONFIRM_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['path_id', 'holds', 'vuln_class', 'severity', 'confidence', 'reason', 'poc'],
  properties: {
    path_id: { type: 'string' },
    holds: { type: 'boolean', description: 'true only if the chained path is a REAL exploitable/reportable issue against HEAD' },
    vuln_class: { type: 'string', enum: ['credential-disclosure', 'ssrf', 'stored-xss', 'info-disclosure', 'none'] },
    severity: { type: 'string', enum: ['high', 'medium', 'low', 'none'] },
    confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
    reason: { type: 'string' },
    poc: { type: 'string', description: 'concrete input + observation, or "" if defeated' },
  },
}

const writeFile = (rel, obj) =>
  `\n\nWrite your StructuredOutput. ALSO write the same JSON to the absolute path ${OUT}/${rel} using the Write tool (mkdir -p the dir first via Bash if needed). Use absolute paths only.`

phase('Enumerate')
const enums = await parallel(
  GUARDS.map((g) => () =>
    agent(
      `You are a GitLab security auditor doing an EXHAUSTIVE caller enumeration for the sanitizer ${g.symbol}.
GitLab source (real HEAD) is at: ${CO}  (CE under app/ lib/ gems/; EE under ee/). Use ripgrep/grep + Read.

${PRIOR}

Your guard: ${g.symbol}
CHAINED HUNTING MAP (the paths the first pass did NOT explore):
${g.chain_hints}

TASK:
1. Find EVERY caller of ${g.symbol} (and of any wrapper like valid?/valid_web?/permit_url?/sanitize_unsafe_links/
   masked_url that fronts it) across CE and EE — direct and transitive. Record file:line for each.
2. For each, follow the value FORWARD. We already know the immediate sinks are defeated. Identify CHAINED paths
   where the guarded value (or a sibling raw field) reaches a SECOND or BROADER-AUDIENCE sink: REST entities,
   GraphQL types, notification emails, webhook/system-hook payloads, audit events, server-side fetchers (SSRF),
   alternate render pipelines (mXSS / non-Addressable parsers), feeds, logs queryable by a wider role, or cross-tenant.
3. Return ONLY genuinely plausible candidate paths (prelim_likelihood high/medium preferred; include low only if novel).
   Quote file:line evidence. Apply "there is always a bypass" — be aggressive and creative, but every path must be
   grounded in code you actually read, not speculation.
Return via StructuredOutput.${writeFile(`enum-${g.key}.json`, null)}`,
      { label: `enum:${g.key}`, phase: 'Enumerate', schema: ENUM_SCHEMA, model: 'opus' }
    )
  )
)

const guardByKey = Object.fromEntries(GUARDS.map((g) => [g.key, g]))
const paths = enums
  .filter(Boolean)
  .flatMap((e) => (e.candidate_paths || []).map((p) => ({ ...p, key: e.key, symbol: e.symbol })))

log(`Enumerate done: ${paths.length} candidate chained paths across ${enums.filter(Boolean).length} guards`)

// Pipeline each candidate path: Trace (does it reach the broader sink?) -> Confirm (is it real & reportable?)
const results = await pipeline(
  paths,
  (p) =>
    agent(
      `Trace this CHAINED forward path against real GitLab HEAD code at ${CO}. Read the actual files; do not assume.

Guard: ${p.symbol}
Path id: ${p.path_id}
Entry (guard call): ${p.entry}
Proposed chain: ${p.chain}
Proposed second sink: ${p.second_sink}
Proposed audience: ${p.audience}
Why candidate: ${p.why_candidate}

${PRIOR}

Determine: does the guarded value (the leaked credential prefix / the validated-but-credential-bearing URL / the
denylist-passing scheme) ACTUALLY flow to that second sink, and is the observing audience BROADER than the first
pass concluded (which was: sanitize=self-disclosure to project admin; strip_userinfo=boolean-only no sink;
safe_protocol?=inert href)? If it is defeated, name the EXACT downstream protection (escape, separate UrlBlocker/
SSRF guard, separate masking, role check, removal filter) with file:line. Be skeptical and precise.
Return via StructuredOutput.${writeFile(`trace-${p.path_id}.json`, null)}`,
      { label: `trace:${p.path_id}`, phase: 'Trace', schema: TRACE_SCHEMA, model: 'opus' }
    ).then((t) => ({ ...t, path: p })),
  (t) => {
    if (!t) return null
    // Only spend a confirm agent on paths the trace says reach a broader sink.
    if (!t.reaches_broader_sink) {
      return {
        path_id: t.path_id,
        holds: false,
        vuln_class: 'none',
        severity: 'none',
        confidence: t.likelihood || 'medium',
        reason: `Trace: does not reach broader sink. ${t.defeated_by || ''}`.trim(),
        poc: '',
        _trace: t,
      }
    }
    return agent(
      `Adversarially CONFIRM this chained path against real GitLab HEAD code at ${CO}. Your default is "defeated";
only return holds:true if you can prove an exploitable or genuinely reportable issue with concrete evidence.

Guard: ${t.path.symbol}
Path id: ${t.path_id}
Trace finding: reaches_broader_sink=${t.reaches_broader_sink}, broader_than_prior=${t.broader_than_prior},
audience="${t.audience}", leak_content="${t.leak_content}", evidence="${t.evidence}".

${PRIOR}

Validate end-to-end: craft the concrete input, follow it through every transform to the sink, and verify the
exact bytes/href that surface and to whom. Try to REFUTE it (separate SSRF guard? second masking? role gate?
html escaping? browser won't execute? value never actually populated?). Give vuln_class, severity, confidence,
a one-paragraph reason, and a concrete PoC (input + observation) — or poc:"" if defeated.
Return via StructuredOutput.${writeFile(`confirm-${t.path_id}.json`, null)}`,
      { label: `confirm:${t.path_id}`, phase: 'Confirm', schema: CONFIRM_SCHEMA, model: 'opus' }
    ).then((c) => ({ ...(c || { path_id: t.path_id, holds: false, vuln_class: 'none', severity: 'none', confidence: 'low', reason: 'confirm agent returned null', poc: '' }), _trace: t }))
  }
)

const clean = results.filter(Boolean)
const confirmed = clean.filter((r) => r.holds)
const broader = clean.filter((r) => r._trace && r._trace.broader_than_prior)

log(`Chain audit done: ${paths.length} paths traced, ${broader.length} reached a broader-than-prior sink, ${confirmed.length} CONFIRMED real`)

return {
  total_paths: paths.length,
  confirmed: confirmed.map((r) => ({ path_id: r.path_id, vuln_class: r.vuln_class, severity: r.severity, reason: r.reason, poc: r.poc })),
  broader_than_prior: broader.map((r) => ({ path_id: r.path_id, audience: r._trace.audience, leak_content: r._trace.leak_content, holds: r.holds })),
  defeated: clean
    .filter((r) => !r.holds)
    .map((r) => ({ path_id: r.path_id, reason: r.reason, defeated_by: r._trace ? r._trace.defeated_by : 'n/a' })),
  enum_summary: enums.filter(Boolean).map((e) => ({ key: e.key, callers: (e.all_callers || []).length, candidates: (e.candidate_paths || []).length })),
}
