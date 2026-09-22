export const meta = {
  name: 'html-sanitizer-bypass',
  description: 'Opus "there is always a bypass" elucubration over 10 GitLab HTML/markdown/SVG sanitizers (Banzai sanitization filters, SVG scrubber, Slack/HtmlSafety validators), then adversarial confirm against real HEAD code + the actual render/reparse sink. Hunts stored-XSS, mXSS, SVG/namespace-confusion, CSS-injection, reverse-tabnabbing.',
  phases: [
    { title: 'Bypass', detail: 'one Opus agent per sanitizer: locate impl, quote allow/deny/regex, trace render sink, enumerate every bypass', model: 'opus' },
    { title: 'Confirm', detail: 'adversarially validate the strongest vector end-to-end against real code + browser/reparse semantics', model: 'opus' },
  ],
}

const CO = '/home/x/Personal_Projects/find-ctfs/gitlab'
const OUT = '/home/x/Personal_Projects/skillsmd/vuln-research/rules/ruby/oracle/validation/html-sanitizer-bypass'

const TECHNIQUES = `
HTML/MARKDOWN/SVG SANITIZER BYPASS TECHNIQUES — apply aggressively, ground every claim in code you actually read:
- mutation XSS (mXSS): sanitized HTML is re-parsed/re-serialized later (Nokogiri reserialize, copy-paste sanitizer,
  notification-email re-render, RSS/Atom/ICS feed, GraphQL note body re-render) and mutates into an executing form.
  Classic vectors: <noscript>, <template>, <style>, <textarea>, <xmp> content reparse; comment/CDATA confusion;
  unbalanced tags that re-balance into script; entity double-decoding.
- namespace confusion: SVG/MathML foreignObject lets HTML re-enter inside an SVG/MathML island where the allowlist
  thinks it is in foreign-content mode. <svg><foreignObject><... >, <math><annotation-xml encoding="text/html">.
  SVG <use xlink:href="#..."> / <use href> + <animate>/<set attributeName="href"> SMIL XSS; <svg><script>.
- attribute injection / DOM clobbering: surviving id/name attrs clobber globals; surviving data-*/aria-* feeding a
  client framework (Vue/JS) that re-interprets them as bindings; surviving style enabling CSS injection
  (the text-align table-style filter: does it allow url(), expression(), behaviour, or attribute breakout via ; }).
- href/src scheme tricks already partly mapped: javascript:/data:/vbscript: case/whitespace/entity/control-char
  obfuscation; non-canonical schemes; protocol-relative; the safe_protocol? '+' denylist gap.
- rel-strip weaknesses: remove_rel stripping rel="noopener noreferrer" -> reverse tabnabbing / referrer leak; or a
  rel value that survives and is security-relevant.
- denylist incompleteness: SlackMarkdownSanitizer deletes only <>[]| — what dangerous constructs survive (backticks,
  parens, mrkdwn link syntax <url|text>, @here/@channel, unicode lookalikes) and where does the output land (Slack
  message vs stored HTML)? HtmlSafetyValidator rejects "input containing HTML tags" via regex — what tag-like or
  tagless payload (e.g. on* without <, entity-encoded <, mXSS, CSS) slips the regex yet executes downstream?
- allowlist extension holes: customize_allowlist adds tables/tasklists/footnotes — does an added element/attribute
  (colspan, footnote ids, task checkbox) open an injection or id-clobbering hole?
- transform filters: SyntaxHighlightFilter replaces code-node children — can crafted language/lexer or node content
  re-inject markup that a later filter trusts?
- Sanitize gem / Loofah / Nokogiri version-specific parser quirks at the pinned versions in Gemfile.lock.
ALWAYS end at the real render sink and the real browser/parser behavior. A guard bypass with an inert sink = DEFEATED.`

const TARGETS = [
  { key: 'remove-rel', symbol: 'Banzai::Filter::BaseSanitizationFilter.remove_rel', mechanism: 'denylist',
    desc: 'Strips rel attributes from links',
    hint: 'If it strips rel="noopener noreferrer" from target=_blank links -> reverse tabnabbing / window.opener / referrer leak. Check whether it strips rel unconditionally and whether target=_blank survives, and what re-adds noopener (if anything). Also: does removing rel enable any rel-based security feature bypass?' },
  { key: 'remove-namespace', symbol: 'Banzai::Filter::BaseSanitizationFilter.remove_namespace', mechanism: 'denylist',
    desc: 'Removes namespaced XML attributes',
    hint: 'Namespace stripping is a classic mXSS / namespace-confusion vector. Does removing the namespace prefix turn a benign foreign-content attribute into an HTML-context event handler or href? Does it run before or after Sanitize.clean_node!? Can xlink:href -> href, or an xmlns juggle smuggle script through SVG/MathML foreignObject?' },
  { key: 'safe-protocol', symbol: 'Gitlab::Utils::SanitizeNodeLink#safe_protocol?', mechanism: 'denylist',
    desc: 'Blocks javascript:, data:, vbscript: URLs',
    hint: 'ALREADY studied twice (javascript+foo: passes denylist but inert in <a href>; autolink path inert). NEW angle ONLY: find a render sink where a denylist-passing scheme IS executable or server-fetched — SVG use/href, xlink:href, srcdoc, formaction, CSS url(), or a non-Addressable parser path. Do not re-report the inert <a href> result.' },
  { key: 'slack-sanitize', symbol: 'SlackMarkdownSanitizer.sanitize', mechanism: 'denylist',
    desc: 'Deletes <>[]| characters',
    hint: 'Char-delete denylist (<>[]|). Identify the EXACT sink (Slack/Mattermost message text built from GitLab data). What dangerous Slack mrkdwn survives without those 4 chars: <url|text> link is broken by | strip, but @channel/@here mentions, <!everyone>, backtick code, or unicode homoglyph <  ? Does stripping create a new injection (e.g. removing | from a legit value merges fields)? Is there a notification-content spoofing / mention-injection angle?' },
  { key: 'remove-unsafe-table-style', symbol: 'Banzai::Filter::SanitizationFilter.remove_unsafe_table_style', mechanism: 'regex_filter',
    desc: 'Only allows text-align: center|left|right on table cells',
    hint: 'Regex allowlist on the style attribute. Quote the EXACT regex. Can the style value smuggle more than text-align via: extra declarations after a semicolon, CSS comments /**/, url(), expression(), case/whitespace/unicode-escape tricks, or a value that passes the regex but the browser parses as a different property? Surviving style -> CSS injection / data exfil via background:url() / overlay clickjacking.' },
  { key: 'html-safety-validator', symbol: 'HtmlSafetyValidator#validate_each', mechanism: 'validator',
    desc: 'Rejects input containing HTML tags',
    hint: 'Quote the rejection regex (likely /<[^>]+>/ or HTML_TAGS). What executable/dangerous payload contains NO matching tag yet harms a downstream sink: tagless event injection, CSS, markdown that later renders to HTML, mXSS, attribute-context breakout, or a tag form the regex misses (e.g. < with newline, unclosed tag, mathml/svg). Identify the field(s) it guards and the render sink. Validator bypass only matters if the value reaches an HTML sink.' },
  { key: 'base-sanitization-call', symbol: 'Banzai::Filter::BaseSanitizationFilter#call', mechanism: 'allowlist',
    desc: 'Main HTML sanitizer — Sanitize.clean_node! with element/attribute allowlist',
    hint: 'The MAIN allowlist sanitizer. Quote the allowlist (elements, attributes, protocols) and the Sanitize gem version (Gemfile.lock). Hunt: allowlisted element + allowlisted attribute combination that executes (e.g. surviving style/srcset/SVG); the deleted protocol backstop (allowlist[:protocols].delete(a)); mXSS via the post-sanitize reserialize; foreignObject/namespace re-entry; any transformer that runs after clean_node! and re-introduces unsanitized markup. Version-specific Sanitize/Nokogiri bypasses at the pinned version.' },
  { key: 'customize-allowlist', symbol: 'Banzai::Filter::SanitizationFilter#customize_allowlist', mechanism: 'allowlist',
    desc: 'Extends allowlist for tables, tasklists, footnotes',
    hint: 'Each ADDED element/attribute is a potential hole. Quote every addition. Footnote ids/hrefs -> DOM clobbering or id collision; tasklist checkbox input attrs; table colspan/rowspan abuse; any added data-* consumed by client JS as a binding. Does an added attribute escape the parent allowlist context?' },
  { key: 'svg-clean', symbol: 'Gitlab::Sanitizers::SVG.clean', mechanism: 'allowlist',
    desc: 'SVG scrubber via Loofah',
    hint: 'SVG is the richest XSS surface. Quote the Loofah scrubber allowlist (elements/attributes). Hunt: <script> in SVG, on* handlers, <use href>/<use xlink:href> to external or fragment, <animate>/<set attributeName=href/onbegin> SMIL, <foreignObject> HTML re-entry, <a xlink:href=javascript:>, <image href=>, CSS in <style>, external entity/XInclude. Where is cleaned SVG rendered — inline in DOM (executes) or as <img src> (inert)? Loofah/Nokogiri version quirks. The render context decides everything.' },
  { key: 'syntax-highlight', symbol: 'Banzai::Filter::SyntaxHighlightFilter#call', mechanism: 'transform',
    desc: 'Replaces code node children to prevent XSS',
    hint: 'It rebuilds the code node to neutralize XSS. Can a crafted lang/lexer label (attribute injection on the <code>/<pre> wrapper), an unknown lexer fallback, or Rouge/lexer output re-introduce raw markup that a LATER filter trusts as safe? Does the replacement set any attribute from user-controlled lang unescaped? mXSS via the highlighted HTML being reserialized?' },
]

const BYPASS_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['key', 'symbol', 'located', 'real_file', 'guard_summary', 'downstream_sink', 'render_context', 'vectors', 'best_likelihood', 'introduces_vuln', 'notes'],
  properties: {
    key: { type: 'string' }, symbol: { type: 'string' }, located: { type: 'boolean' },
    real_file: { type: 'string', description: 'file:line of the real implementation' },
    guard_summary: { type: 'string', description: 'quote the actual allowlist/denylist/regex + gem version' },
    downstream_sink: { type: 'string', description: 'where the sanitized value is rendered/reparsed, file:line' },
    render_context: { type: 'string', enum: ['inline-dom-executes', 'img-src-inert', 'attribute', 'text-only', 'server-fetch', 'email-feed-rerender', 'mixed', 'unknown'] },
    vectors: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['technique', 'input', 'why_passes', 'impact', 'likelihood', 'test_idea'],
        properties: {
          technique: { type: 'string' }, input: { type: 'string' }, why_passes: { type: 'string' },
          impact: { type: 'string' }, likelihood: { type: 'string', enum: ['high', 'medium', 'low'] }, test_idea: { type: 'string' },
        },
      },
    },
    best_likelihood: { type: 'string', enum: ['high', 'medium', 'low'] },
    introduces_vuln: { type: 'boolean' },
    notes: { type: 'string' },
  },
}

const CONFIRM_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['key', 'symbol', 'holds', 'vuln_class', 'severity', 'confidence', 'reason', 'poc'],
  properties: {
    key: { type: 'string' }, symbol: { type: 'string' },
    holds: { type: 'boolean', description: 'true only if a REAL exploitable/reportable issue against HEAD' },
    vuln_class: { type: 'string', enum: ['stored-xss', 'mxss', 'svg-xss', 'css-injection', 'reverse-tabnabbing', 'dom-clobbering', 'info-disclosure', 'ssrf', 'spoofing', 'none'] },
    severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low', 'none'] },
    confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
    reason: { type: 'string' }, poc: { type: 'string', description: 'concrete markdown/HTML input + observed executing output, or "" if defeated' },
  },
}

const writeFile = (rel) =>
  `\n\nAfter producing StructuredOutput, ALSO write the same JSON to the absolute path ${OUT}/${rel} via the Write tool (Bash mkdir -p the dir first if needed). Absolute paths only.`

phase('Bypass')
const bypasses = await parallel(
  TARGETS.map((t) => () =>
    agent(
      `You are a senior web-security researcher auditing a GitLab HTML/markdown/SVG sanitizer for bypasses.
Real GitLab source (HEAD) is at: ${CO} (CE under app/ lib/ gems/; check ee/ too). Use ripgrep + Read, and verify
gem versions in Gemfile.lock (Sanitize, Loofah, Nokogiri, Rouge). Apply "there is ALWAYS a bypass".

TARGET: ${t.symbol}  (mechanism: ${t.mechanism}) — ${t.desc}
TARGET-SPECIFIC HINT: ${t.hint}

${TECHNIQUES}

TASK:
1. LOCATE the real implementation; quote the actual allowlist/denylist/regex/scrubber and the relevant gem version.
2. Trace to the REAL render sink and classify render_context (does the output land inline in the DOM where it
   executes, as <img src> where it is inert, in an attribute, server-fetched, or re-rendered in email/feed?).
3. Enumerate every plausible bypass with a CONCRETE crafted input, why it passes the guard, the impact, and a test idea.
   Be aggressive and creative but ground each in code you actually read. Mark the best_likelihood honestly.
4. Set introduces_vuln only if at least one vector plausibly reaches an executing/harmful sink.
Return via StructuredOutput.${writeFile(`bypass-${t.key}.json`)}`,
      { label: `bypass:${t.key}`, phase: 'Bypass', schema: BYPASS_SCHEMA, model: 'opus' }
    )
  )
)

const found = bypasses.filter(Boolean)
log(`Bypass phase: ${found.length}/${TARGETS.length} analyzed; introduces_vuln=${found.filter((b) => b.introduces_vuln).length}`)

// Confirm only the ones with a plausible (high/medium) vector reaching a non-inert sink.
const toConfirm = found.filter(
  (b) => b.introduces_vuln && (b.best_likelihood === 'high' || b.best_likelihood === 'medium')
)
const inert = found.filter((b) => !toConfirm.includes(b))

const confirmations = await parallel(
  toConfirm.map((b) => () =>
    agent(
      `Adversarially CONFIRM a claimed bypass of the GitLab sanitizer ${b.symbol} against real HEAD code at ${CO}.
Your DEFAULT verdict is DEFEATED; return holds:true ONLY with concrete proof the payload reaches an
executing/harmful sink against real browser/parser semantics and survives every downstream filter.

Implementation: ${b.real_file}
Guard: ${b.guard_summary}
Downstream sink: ${b.downstream_sink}  (render_context=${b.render_context})
Best vectors found:
${JSON.stringify(b.vectors.filter((v) => v.likelihood !== 'low').slice(0, 5), null, 2)}

${TECHNIQUES}

Validate end-to-end: build the concrete markdown/HTML input, follow it through the FULL Banzai pipeline (note the
filter ORDER and any later SanitizationFilter/PostProcess pass), the gem (Sanitize/Loofah/Nokogiri/Rouge at the
pinned version), and the actual render context. Try hard to REFUTE: later filter strips it? gem already blocks it?
browser does not execute it? sink is <img>/text not inline DOM? value never reaches an HTML context? Run a quick
local ruby/JS check if useful. Give vuln_class, severity, confidence, a one-paragraph reason, and a concrete PoC
(input + observed executing output) — or poc:"" if defeated.
Return via StructuredOutput.${writeFile(`confirm-${b.key}.json`)}`,
      { label: `confirm:${b.key}`, phase: 'Confirm', schema: CONFIRM_SCHEMA, model: 'opus' }
    )
  )
)

const confirmed = confirmations.filter(Boolean).filter((c) => c.holds)
const defeatedConfirm = confirmations.filter(Boolean).filter((c) => !c.holds)

log(`Confirm phase: ${toConfirm.length} validated, ${confirmed.length} HOLD, ${defeatedConfirm.length} defeated; ${inert.length} skipped as inert/low`)

return {
  total: TARGETS.length,
  confirmed: confirmed.map((c) => ({ symbol: c.symbol, vuln_class: c.vuln_class, severity: c.severity, confidence: c.confidence, reason: c.reason, poc: c.poc })),
  defeated_at_confirm: defeatedConfirm.map((c) => ({ symbol: c.symbol, vuln_class: c.vuln_class, reason: c.reason })),
  skipped_inert_or_low: inert.map((b) => ({ symbol: b.symbol, best_likelihood: b.best_likelihood, render_context: b.render_context, notes: b.notes })),
  bypass_overview: found.map((b) => ({ symbol: b.symbol, introduces_vuln: b.introduces_vuln, best_likelihood: b.best_likelihood, render_context: b.render_context, vectors: b.vectors.length })),
}
