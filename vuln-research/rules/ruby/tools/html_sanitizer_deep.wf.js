export const meta = {
  name: 'html-sanitizer-deep',
  description: 'Round 2: maximally-deep multi-lens Opus elucubration on the LIVE (non-inert) sinks round 1 flagged — mXSS via the AS_XHTML Atom feed, data-* -> client Vue v-html/DOM-clobbering, Slack/chat mention+link injection, SVG.clean alternate inline sink, SyntaxHighlight escape-mode. Each lead attacked from multiple distinct angles, then adversarially confirmed end-to-end against real HEAD code + dynamic gem/JS checks.',
  phases: [
    { title: 'Deep', detail: 'multiple distinct-lens Opus agents per live lead, each enumerating concrete vectors to the real sink', model: 'opus' },
    { title: 'Confirm', detail: 'adversarial end-to-end validation (dynamic ruby/JS) of every high/medium vector', model: 'opus' },
    { title: 'Critic', detail: 'per-lead completeness critic: what path/lens did we miss?', model: 'opus' },
  ],
}

const CO = '/home/x/Personal_Projects/find-ctfs/gitlab'
const OUT = '/home/x/Personal_Projects/skillsmd/vuln-research/rules/ruby/oracle/validation/html-sanitizer-bypass'

const GROUND = `
PINNED GEMS (Gemfile.lock, verified round 1): sanitize 6.0.2, html-pipeline 2.14.3, nokogiri 1.19.3 (HTML5/Gumbo),
loofah 2.25.1, rails-html-sanitizer 1.7.0, rouge 4.7.0. GitLab source HEAD: ${CO} (CE app/ lib/ gems/; also ee/).
The system gems round 1 used matched these pins; isolated ruby harnesses against the real gems WORKED (bundler
could not materialize the full bundle, so test parser/filter/serializer logic in isolation). For frontend leads,
grep app/assets/javascripts + node_modules/@gitlab/ui for the real consumer; cite file:line.
DISCIPLINE: "there is always a bypass" — enumerate EVERY path, not the first. Ground every claim in code you read.
End at the REAL sink and REAL browser/feed-reader/parser semantics. A guard bypass with an inert sink = DEFEATED,
but say precisely what makes it inert. Findings are defensive items for GitLab's security team, not exploits.`

// Each lens = one deep agent. Multiple lenses per lead so no single angle is the only one tried.
const LENSES = [
  // ---- LEAD A: mXSS via AS_XHTML Atom events feed ----
  { lead: 'A', key: 'A1-xhtml-serialize-diff', title: 'AS_XHTML serialization differential (mXSS)',
    prompt: `LEAD A (mXSS Atom feed), LENS 1 — HTML5-parse vs AS_XHTML-serialize differential.
Round 1 found: Banzai renders notes/events with xhtml:true; renderer.rb:155-156 re-serializes AS_XHTML; the result
is embedded RAW (unescaped) into the Atom events feed at app/views/events/_event.atom.builder:26-30 (summary <<),
and PostProcessPipeline does NOT re-sanitize. So the already-sanitized HTML5 DOM is re-serialized to XHTML and then
parsed by a feed reader as XML/XHTML. Hunt EVERY allowlisted construct whose HTML5 parse tree serializes to XHTML
such that an XML/XHTML parser (feed reader, or browser viewing the feed) interprets it differently and executes or
breaks out: raw-text elements (<style>/<title>/<textarea>/<noscript> are not allowlisted — verify), comment/CDATA
re-interpretation, self-closing vs explicit-close confusion (<a/> , <p/>), attribute value re-quoting, entity
double-decode, the xmlns="http://www.w3.org/1999/xhtml" div wrapper boundary. Identify which models feed events.atom
(Event#target note/issue/MR description), whether the feed is reachable with an RSS feed-token or public, and build
the concrete markdown input -> rendered XHTML -> reader-parsed result. Dynamically reproduce the HTML5->AS_XHTML
round-trip with the pinned nokogiri 1.19.3 to PROVE the differential.` },
  { lead: 'A', key: 'A2-feed-xml-injection', title: 'Atom feed XML-structure injection',
    prompt: `LEAD A (mXSS Atom feed), LENS 2 — break the Atom XML structure itself.
The builder does summary << <rendered xhtml> raw inside <summary type="xhtml"><div xmlns="...">...</div></summary>
(app/views/events/_event.atom.builder:26-30). If the rendered content is not perfectly well-formed XML, or contains
a sequence that closes the <div>/<summary>/<entry> early, an attacker could inject feed-level Atom elements
(<author>, <link href>, <content>) or CDATA-escape into the feed consumed by aggregators/email-to-feed/browsers.
Enumerate every way allowlisted-but-XHTML-serialized content can produce a string that an Atom/XML parser treats as
markup outside the intended div: stray ]]> if any CDATA, unescaped & in attribute (does AS_XHTML escape & in all
positions?), characters illegal in XML 1.0, or a construct nokogiri HTML5 keeps that AS_XHTML emits unescaped.
Reproduce with the real serializer; show the exact feed bytes and the parser divergence.` },
  { lead: 'A', key: 'A3-color-math-reparse', title: 'Post-sanitize filter reparse into the feed',
    prompt: `LEAD A (mXSS Atom feed), LENS 3 — filters that run AFTER SanitizationFilter and inject nodes that ride
into the AS_XHTML feed. ColorParser (anchored /\\A...\\z/), InlineDiffFilter, MathFilter (data-math-style),
MermaidFilter/KrokiFilter (data-diagram-src), ReferenceFilter, SyntaxHighlightFilter all run post-sanitize in
gfm_pipeline.rb. Any node/attribute they add is NOT re-sanitized and is serialized AS_XHTML into the feed. Enumerate
each post-sanitize filter, what attributes/elements it injects, whether any value is attacker-influenced, and whether
the AS_XHTML serialization of that injected node yields executing/structure-breaking content in the feed reader
context. Ground in the real filter source and the pinned gems.` },

  // ---- LEAD B: data-* -> client Vue v-html / DOM clobbering ----
  { lead: 'B', key: 'B1-gltable-vhtml', title: 'json-table data-table-fields -> GlTable v-html',
    prompt: `LEAD B (data-* client sink), LENS 1 — THE CROWN. customize_allowlist permits table data-* via
filter_json_table_fields (re-JSONed key-sliced label). Round 1 follow-up: does @gitlab/ui GlTable render field.label
as v-html, turning the json-table path into stored XSS that BYPASSES the markdown cell DOMPurify? Trace the full
chain: SanitizationFilter#filter_json_table_fields -> the data-* attribute on the rendered table -> the frontend
component that reads it (grep app/assets/javascripts for data-table-fields / json table / GlTableLite / GlTable /
markdown table render) -> whether label/any field is bound with v-html / innerHTML / domProps.innerHTML, and whether
that value is DOMPurified before binding. Read node_modules/@gitlab/ui GlTable source for fields[].label handling.
Build the concrete markdown json-table input and show whether label reaches an unsanitized v-html. If DOMPurified or
text-bound, say exactly where.` },
  { lead: 'B', key: 'B2-dom-clobber-ids', title: 'footnote/user-content id DOM clobbering',
    prompt: `LEAD B (data-* client sink), LENS 2 — DOM clobbering / named-property collision. Allowlisted ids are
prefix-gated (fnref-/fn-/user-content-) and classes are exact-gated, but VALUES are attacker-controlled
(remove_id_attributes, FootnoteFilter ref_num). Enumerate every client script that does document.getElementById,
getElementsByName, a named global (window.X / form.elements), or framework lookup that an attacker-chosen id/name on
a surviving element could clobber (auth forms, CSRF token nodes, config blobs, GraphQL CSRF, gon, Vue refs). Also
check whether two user-content- ids can collide to break an integrity assumption. Cite the frontend consumer
file:line and assess real impact (DOM clobbering -> XSS/CSRF-token overwrite/open redirect) vs inert.` },
  { lead: 'B', key: 'B3-math-diagram-lang-consumers', title: 'data-math-style/diagram-src/canonical-lang consumers',
    prompt: `LEAD B (data-* client sink), LENS 3 — the math/diagram/highlight data-* attributes. MathFilter emits
data-math-style; Mermaid/Kroki emit data-diagram-src / data-* ; SyntaxHighlight emits data-canonical-lang. Each is
read by client JS (KaTeX renderer, mermaid sandbox, kroki, copy-code). Trace each consumer in app/assets/javascripts:
does any pass the attribute value into innerHTML / dangerouslySetInnerHTML / KaTeX with trust:true / new Function /
eval / element.src / a URL fetched without allowlist? KaTeX in particular: is it called with trust or strict false,
and can data-math-style or the math content reach an HTML-injecting macro (\\htmlData, \\includegraphics, \\href)?
Build the concrete input and show the sink, or prove it inert (sandboxed iframe / text-only / DOMPurify).` },

  // ---- LEAD C: Slack/chat mention + link injection ----
  { lead: 'C', key: 'C1-pipeless-broadcast', title: 'pipeless mention/broadcast injection via sanitize_slack_link',
    prompt: `LEAD C (chat injection), LENS 1 — sanitize_slack_link (SlackMarkdownSanitizer l.12-18) only escapes the
pipe-bearing <...|...> form. Round 1 (bypass-26): pipeless <!channel>/<!here>/<!everyone>/<@U..>/<#C..> broadcasts
and bare <https://evil> autolinks survive into the issue Slack notification (issue_message.rb:32,71). Verify against
real source: which fields flow through sanitize_slack_link vs strip_markup vs nothing; build concrete attacker inputs
(issue/MR title or description containing <!channel>) and show the exact Slack mrkdwn POST body produced. Determine
the real impact: does Slack render <!channel> from an incoming-webhook/bot message as an actual broadcast ping? (Note
Slack only honors broadcast mentions in certain message contexts — establish whether GitLab's integration message
type triggers it.) Cover Slack AND the shared ChatMessage base used by Mattermost.` },
  { lead: 'C', key: 'C2-unsanitized-name-fields', title: 'unsanitized name/identity fields into chat POST',
    prompt: `LEAD C (chat injection), LENS 2 — fields reaching the chat POST with NO strip_markup. Round 1: user.name,
project.name, @additional_message reach the Slack message unsanitized (l.150-152). Enumerate EVERY field across ALL
chat integrations (lib/gitlab and app: chat_message/*.rb — push, issue, merge_request, note, pipeline, wiki, deploy,
alert) that interpolates user-controllable identity/text (display name, project/group name, branch/tag, commit msg,
label, milestone) into the outgoing message WITHOUT sanitize/strip_markup. For each, give the concrete injection
(display name = '<!channel>' or '<https://evil|click>') and the resulting message. Rank by audience (channel
broadcast vs single field cosmetic).` },
  { lead: 'C', key: 'C3-link-phishing-other-integrations', title: 'link/format injection across other chat integrations',
    prompt: `LEAD C (chat injection), LENS 3 — beyond Slack/Mattermost: Discord, Unify Circuit, Hangouts/Google Chat,
Microsoft Teams, Pumble, Telegram (any ChatNotification integration). Each has its own message formatting (Discord
markdown, Teams adaptive cards, Telegram HTML/markdown). Identify which apply NO markup sanitizer to user-controlled
fields and whether their format permits link injection (phishing), @everyone/@here (Discord) mention bombing, or
markup breakout. Build one concrete PoC per vulnerable integration and note the audience/impact.` },

  // ---- LEAD D: SVG.clean alternate inline sink ----
  { lead: 'D', key: 'D1-inline-svg-render-hunt', title: 'any inline-DOM render of SVG.clean output',
    prompt: `LEAD D (SVG.clean), LENS 1 — the whitelist PERMITS <script> and on* handlers; it is inert ONLY because
the known sink base64-embeds into <img src="data:image/svg+xml">. Find ANY OTHER consumer. grep every caller of
Gitlab::Sanitizers::SVG.clean and SVG.clean across app/ lib/ ee/. For each, determine the render: is cleaned SVG ever
emitted inline in the DOM via raw()/html_safe/inline_svg/sprite/<use>/ActionView, or assigned to innerHTML client-
side, or rasterized server-side by a script-capable engine? Any inline-DOM path instantly weaponizes the permitted
<script>/on*. Cite each call site and its template; classify inert (<img>/attachment) vs live (inline). If all inert,
prove it for every caller.` },
  { lead: 'D', key: 'D2-raw-blob-content-disposition', title: 'raw SVG blob served inline same-origin',
    prompt: `LEAD D (SVG.clean), LENS 2 — the classic GitLab SVG-XSS shape: a user-uploaded .svg served same-origin
with Content-Disposition: inline and Content-Type image/svg+xml NAVIGATED directly executes script regardless of
SVG.clean (which only guards the blob VIEWER, not raw delivery). Trace the raw blob / uploads / artifacts / LFS /
wiki-attachment delivery paths (app/controllers .../raw, Workhorse send-blob, uploaders, FileUploader content
disposition, AssetProxy / user-content host). Determine: are user .svg files ever served from the GitLab app origin
with inline disposition (not 'attachment', not a separate sandboxed gitlab-static/user-content domain)? Check the
content-disposition logic (Gitlab::Workhorse, BlobHelper, send_file/send_data, uploads_controller) and whether
SafeFileUploader / content-type allowlist / disposition=attachment closes it. This is the highest-value SVG path —
be exhaustive and cite the exact disposition decision.` },

  // ---- LEAD E: SyntaxHighlight escape-mode (fold) ----
  { lead: 'E', key: 'E1-rouge-escape-and-lexer', title: 'Rouge escape-mode / hostile lexer tag into inline sink',
    prompt: `LEAD E (SyntaxHighlight), LENS 1 — output is inline-DOM and NOT re-sanitized (gfm_pipeline.rb:50 end).
Round 1: safe only because Rouge is never in escape-enabled mode and add_class/lang only gets lexer.tag or fixed
constants. Verify exhaustively: grep for any enable_escape!/with_escape/Formatter escape usage; any path where the
language label / lexer tag / a vendored or plugin lexer could contain markup chars that reach add_class/set_attribute
unescaped; the math/suggestion/kroki constant paths; and whether to_html + Nokogiri replace can mutate code text.
Also check the AsciiDoc and snippet highlight paths separately. If a single path emits unescaped attacker markup to
the inline sink, it is stored XSS — prove it or prove every path escaped.` },
]

const VEC_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['lead', 'key', 'sink_is_live', 'vectors', 'best_likelihood', 'notes'],
  properties: {
    lead: { type: 'string' }, key: { type: 'string' },
    sink_is_live: { type: 'boolean', description: 'does this lens reach a genuinely non-inert sink?' },
    vectors: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['technique', 'input', 'sink', 'why_reaches', 'impact', 'likelihood', 'evidence'],
        properties: {
          technique: { type: 'string' }, input: { type: 'string' },
          sink: { type: 'string', description: 'exact file:line render/sink' },
          why_reaches: { type: 'string' }, impact: { type: 'string' },
          likelihood: { type: 'string', enum: ['high', 'medium', 'low'] },
          evidence: { type: 'string', description: 'file:line + any dynamic test result' },
        },
      },
    },
    best_likelihood: { type: 'string', enum: ['high', 'medium', 'low'] },
    notes: { type: 'string' },
  },
}

const CONFIRM_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['key', 'technique', 'holds', 'vuln_class', 'severity', 'confidence', 'reason', 'poc'],
  properties: {
    key: { type: 'string' }, technique: { type: 'string' },
    holds: { type: 'boolean' },
    vuln_class: { type: 'string', enum: ['stored-xss', 'mxss', 'svg-xss', 'css-injection', 'reverse-tabnabbing', 'dom-clobbering', 'feed-injection', 'mention-injection', 'phishing', 'info-disclosure', 'none'] },
    severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low', 'none'] },
    confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
    reason: { type: 'string' }, poc: { type: 'string' },
  },
}

const CRITIC_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['lead', 'missed_paths', 'verdict'],
  properties: {
    lead: { type: 'string' },
    missed_paths: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['path', 'why_promising'],
        properties: { path: { type: 'string' }, why_promising: { type: 'string' } },
      },
    },
    verdict: { type: 'string', description: 'is this lead exhausted, or is there a concrete un-tried path worth another round?' },
  },
}

const writeFile = (rel) =>
  `\n\nAfter StructuredOutput, ALSO write the same JSON to ${OUT}/${rel} via Write (Bash mkdir -p first). Absolute paths only.`

phase('Deep')
const deep = await parallel(
  LENSES.map((l) => () =>
    agent(
      `You are a senior web-security researcher doing a MAXIMALLY DEEP, single-angle dive.
${GROUND}

${l.prompt}

Return EVERY concrete vector you can construct for this angle (with exact input, the precise sink file:line, why it
reaches, impact, likelihood, and dynamic-test evidence where you ran it). Set sink_is_live honestly.
Return via StructuredOutput.${writeFile(`deep-${l.key}.json`)}`,
      { label: `deep:${l.key}`, phase: 'Deep', schema: VEC_SCHEMA, model: 'opus' }
    ).then((r) => (r ? { ...r, _title: l.title } : null))
  )
)

const deepOk = deep.filter(Boolean)
const allVectors = deepOk.flatMap((d) =>
  (d.vectors || []).filter((v) => v.likelihood !== 'low').map((v) => ({ ...v, lead: d.lead, key: d.key }))
)
log(`Deep phase: ${deepOk.length}/${LENSES.length} lenses; ${allVectors.length} high/medium vectors to confirm`)

phase('Confirm')
const confirms = await parallel(
  allVectors.map((v) => () =>
    agent(
      `Adversarially CONFIRM this vector against real GitLab HEAD at ${CO}. DEFAULT = DEFEATED; holds:true ONLY with
concrete proof the payload reaches an executing/harmful sink and survives every downstream filter + real
browser/feed-reader/chat-client/parser semantics. Run dynamic ruby/JS checks where they settle it.
${GROUND}

Lead ${v.lead} / lens ${v.key}
Technique: ${v.technique}
Input: ${v.input}
Claimed sink: ${v.sink}
Why it reaches: ${v.why_reaches}
Impact: ${v.impact}
Evidence so far: ${v.evidence}

Try hard to REFUTE (later filter, DOMPurify, gem version, sink actually inert/<img>/text, value never reaches HTML/
chat-broadcast context, browser/Slack won't honor it). Give vuln_class, severity, confidence, a one-paragraph reason,
and a concrete PoC (input + observed harmful output) — or poc:"" if defeated.
Return via StructuredOutput.${writeFile(`confirm2-${v.key}-${v.technique.replace(/[^a-z0-9]+/gi, '-').slice(0, 24)}.json`)}`,
      { label: `confirm:${v.key}`, phase: 'Confirm', schema: CONFIRM_SCHEMA, model: 'opus' }
    )
  )
)
const confirmed = confirms.filter(Boolean).filter((c) => c.holds)

phase('Critic')
const LEADS = ['A', 'B', 'C', 'D', 'E']
const critics = await parallel(
  LEADS.map((lead) => () => {
    const lensesForLead = LENSES.filter((l) => l.lead === lead).map((l) => l.title)
    const found = deepOk.filter((d) => d.lead === lead).flatMap((d) => (d.vectors || []).map((v) => `${v.technique} [${v.likelihood}]`))
    return agent(
      `Completeness critic for LEAD ${lead}. We already attacked it from these lenses: ${JSON.stringify(lensesForLead)}.
Vectors found: ${JSON.stringify(found)}.
${GROUND}
Ask: what concrete bypass PATH or LENS did we NOT try for this lead — a sink not enumerated, a filter-order assumption
unverified, a gem quirk unchecked, a frontend consumer ungrepped, a chat client untested? Only list paths grounded in
code that plausibly reach the live sink. If genuinely exhausted, say so.
Return via StructuredOutput.${writeFile(`critic-${lead}.json`)}`,
      { label: `critic:${lead}`, phase: 'Critic', schema: CRITIC_SCHEMA, model: 'opus' }
    )
  })
)

const openPaths = critics.filter(Boolean).flatMap((c) => (c.missed_paths || []).map((m) => ({ lead: c.lead, ...m })))

return {
  lenses_run: deepOk.length,
  vectors_examined: allVectors.length,
  confirmed: confirmed.map((c) => ({ key: c.key, vuln_class: c.vuln_class, severity: c.severity, confidence: c.confidence, reason: c.reason, poc: c.poc })),
  defeated: confirms.filter(Boolean).filter((c) => !c.holds).map((c) => ({ key: c.key, technique: c.technique, vuln_class: c.vuln_class, reason: c.reason })),
  live_leads: deepOk.filter((d) => d.sink_is_live).map((d) => ({ lead: d.lead, key: d.key, title: d._title, best: d.best_likelihood })),
  critic_open_paths: openPaths,
}
