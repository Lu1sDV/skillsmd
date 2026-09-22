export const meta = {
  name: 'html-sanitizer-r3',
  description: 'Round 3: deep Opus dive on the XSS-class un-tried paths the round-2 completeness critic surfaced — the ones that cross into the FRONTEND (GLQL/json-table/lang-params client renders) and the RAW SVG serving path (workhorse detection-evasion + uploads/avatar/LFS/snippet disposition) + the Atom type:html builder sink. Each path traced end-to-end to the real JS/Go sink, then adversarially confirmed.',
  phases: [
    { title: 'Deep', detail: 'one Opus agent per critic-surfaced XSS-class path, tracing to the real JS/Go sink', model: 'opus' },
    { title: 'Confirm', detail: 'adversarial end-to-end validation of every high/medium vector', model: 'opus' },
  ],
}

const CO = '/home/x/Personal_Projects/find-ctfs/gitlab'
const OUT = '/home/x/Personal_Projects/skillsmd/vuln-research/rules/ruby/oracle/validation/html-sanitizer-bypass'

const GROUND = `
GitLab source HEAD: ${CO}. Backend gems pinned (verified rounds 1-2): sanitize 6.0.2, html-pipeline 2.14.3,
nokogiri 1.19.3 (HTML5/Gumbo), loofah 2.25.1, rouge 4.7.0. FRONTEND: read the REAL files under
${CO}/app/assets/javascripts and ${CO}/node_modules/@gitlab/ui (GlTable/GlTableLite), and any v-safe-html /
DOMPurify config (app/assets/javascripts/lib/dompurify.js, directives/safe_html). For Go: ${CO}/workhorse.
DISCIPLINE: "there is always a bypass" — enumerate every variant. The deciding question for each path is the REAL
sink: does attacker-controlled bytes reach innerHTML / v-html / dangerouslySetInnerHTML / element.src / an
inline-same-origin executable response, WITHOUT a DOMPurify/escape/disposition guard in between? A v-safe-html bind,
a text interpolation, an <img>/attachment disposition, or an opaque-origin sandboxed iframe = DEFEATED — but say
exactly which file:line makes it so. Findings are defensive items for GitLab's security team, not exploits.`

const PATHS = [
  { key: 'E-glql-frontend', title: 'GLQL fence -> render_glql.js -> Vue (pre.textContent raw)',
    prompt: `CRITIC PATH (LEAD E): The \`\`\`glql fence is NOT highlighted by Rouge — the <pre> is REPLACED and its
raw textContent (the ENTIRE attacker-controlled code block) is read client-side. Chain: code block lang glql ->
data-canonical-lang="glql" -> app/assets/javascripts/behaviors/markdown/render_gfm.js:47 glqlEls ->
render_glql.js -> app/assets/javascripts/glql/index.js renderGlqlNode reads pre.textContent (glql/index.js:18-26
queryYaml: pre.textContent). Trace the FULL frontend chain: how the GLQL query + its RESULTS are rendered — read
glql/index.js, the GLQL Facade.vue / presenter / field components, and any GraphQL/REST result rendering. Determine
whether (a) the attacker query text, or (b) any query-RESULT string (issue title, label, description, user name),
reaches v-html / innerHTML / dangerouslySetInnerHTML / a non-escaped template binding, or whether everything is
v-safe-html (DOMPurify) / text-interpolated / escaped. Enumerate every field rendered. If a result field is bound
unescaped, that is stored XSS (the GLQL author controls the query; result fields are other users' content). Build
the concrete \`\`\`glql payload and name the exact .vue file:line of the sink, or prove every binding safe.` },
  { key: 'E-jsontable-frontend', title: 'json-table markdown:true -> render_json_table.js -> GlTable field.label',
    prompt: `CRITIC PATH (LEAD E + B1): A \`\`\`json fence with data-lang-params~="table" and "markdown":true builds a
server-side <table data-table-fields ...>; the client RE-READS it and re-mounts with isHtmlSafe=true. Chain:
JsonTableFilter -> <table data-table-fields=JSON> (filter_json_table_fields key-slices+re-JSONs the label but does
NOT HTML-escape it) -> render_gfm.js:46 tableHTMLEls -> render_json_table.js:72-101 (lines 82,89,95,101) ->
app/assets/javascripts/behaviors/markdown/components/json_table.vue. READ json_table.vue and the GlTable usage:
does items[].<field>, the caption, or the column-header LABEL (from data-table-fields JSON) render via v-html /
v-safe-html / text? Read node_modules/@gitlab/ui GlTable/GlTableLite for how fields[].label and cell content are
rendered (scoped slot? v-html? text?). The attacker controls BOTH the cell markdown (rendered with markdown:true ->
HTML) and the field label JSON. Determine whether isHtmlSafe=true means the cell HTML is injected without
re-sanitization client-side, and whether the field label is HTML or text. Build the concrete json-table markdown
and name the exact sink, or prove DOMPurify/text-binding defeats it.` },
  { key: 'E-langparams-frontend', title: 'data-lang-params escape_once -> frontend consumer',
    prompt: `CRITIC PATH (LEAD E): data-lang-params is a SECOND fully attacker-controlled value (everything after the
first ':' in a fence info string), only escape_once'd server-side: code_language_filter.rb:108-109
set_attribute('data-lang-params', escape_once(lang_params)). Trace every frontend consumer: code_block_highlight.js
(extractLanguage / dataset reads), the ContentEditor TipTap serializer (serializer/code_block.js:12 reflects
langParams back into source), render_gfm.js, copy-code, diagram/suggestion handlers. Determine whether any consumer
puts the langParams value into innerHTML, an unescaped attribute on re-serialize, a new Function/eval, an element
attribute that executes, or reflects it into editable source that round-trips into an executing context. escape_once
escapes & < > " but NOT single-quote or backtick — check attribute-context and JS-context sinks. Name the exact
sink or prove inert.` },
  { key: 'D-workhorse-svg-evasion', title: 'workhorse svg.Is() detection-evasion -> inline same-origin SVG',
    prompt: `CRITIC PATH (LEAD D): The attachment-forcing that makes raw SVG serving inert is GATED on
svg.Is()==true. Read ${CO}/workhorse internal/utils/svg/svg.go (svgRegex = (?i)^\\s*(?:<\\?xml[^>]*>\\s*)?
(?:<!doctype svg[^>]*>\\s*)?<svg[^>]* applied AFTER stripping HTML comments, plus isBinary) and
internal/headers/content_headers.go (lines ~29,76,82-90: the disposition decision; SVG -> attachment). Hunt every
way a file that a BROWSER will render as executable SVG (inline, same-origin) can make svg.Is() return FALSE so the
attachment disposition is NOT forced and Content-Disposition: inline is served: leading junk before <svg> that the
browser tolerates but the anchored regex rejects (BOM, whitespace variants \\f \\v, an HTML comment that the
comment-stripper handles differently than the browser, a leading <html>/<!doctype html> wrapper, XML PI variants,
content-type sniffing differences), isBinary misclassification, or a polyglot. For each evasion, state what
disposition workhorse then serves and whether the browser executes script. Also identify the controllers/paths that
reach this code (raw blob, artifacts, send-blob) vs those that hardcode attachment. Dynamically test the regex in Go
or with the exact pattern if useful. This is the classic GitLab same-origin SVG-XSS pattern — be exhaustive.` },
  { key: 'D-uploads-avatar-lfs-snippet-svg', title: 'uploads/avatar/LFS/snippet SVG egress disposition',
    prompt: `CRITIC PATH (LEAD D): The repo-blob raw path forces SVG->attachment, but UPLOAD / avatar / LFS / snippet
egress was never traced. Audit EVERY user-uploaded-SVG delivery path for content-disposition + content-type:
- /uploads/ markdown attachments (FileUploader, app/controllers/.../uploads_controller.rb, send_upload,
  lib/gitlab/uploads, send_file_upload.rb default disposition).
- avatars (project/group/user avatar upload + serving, AvatarUploader, content disposition).
- LFS objects (SendsBlob#send_lfs_object -> send_upload; can a .svg LFS object be served inline same-origin?).
- snippet raw (does *.svg snippet raw serve inline, or reuse _svg.html.haml <img data:base64>?).
- artifacts browse/raw.
For each: is disposition forced to 'attachment', is it served from a SEPARATE sandboxed host (gitlab-static /
user-content domain / object-storage with its own origin), and is the content-type image/svg+xml served inline
same-origin? Any path serving attacker SVG inline from the GitLab app origin = stored XSS. Cite the exact disposition
decision file:line for each path; classify guarded vs gap.` },
  { key: 'A-postprocess-and-type-html-feed', title: 'PostProcessPipeline AS_XHTML + Atom type:html builder sink',
    prompt: `CRITIC PATH (LEAD A): Round 2 walked the GFM-phase filters, NOT (1) the PostProcessPipeline that performs
the feed's to_html(AS_XHTML) at lib/banzai/renderer.rb:148-160, nor (2) the Atom builders that use type:'html' with
the CACHED web render. Investigate both:
(1) PostProcessPipeline (lib/banzai/pipeline/post_process_pipeline.rb) filters run AFTER SanitizationFilter with
current_user/context, rewriting hrefs and truncating subtrees, then AS_XHTML-serialized into the feed with NO
re-sanitization. Audit each (ReferenceRedactorFilter, RepositoryLinkFilter, UploadLinkFilter, AbsoluteLinkFilter,
SuggestionFilter, TruncateVisibleFilter, etc.): does any set an attribute/text from attacker-influenced data that,
AS_XHTML-serialized, yields an executing or feed-structure-breaking construct? Pay attention to TruncateVisibleFilter
producing a half-open subtree that AS_XHTML re-balances differently than a feed reader.
(2) The type:'html' Atom builders (_commit.atom.builder, _release.atom.builder, _issuable.atom.builder use
markdown_field(...), type:'html') emit the CACHED redacted_<field>_html (markup_helper.rb:102-105) built by GfmPipeline
WITHOUT xhtml:true — i.e. HTML5 serialization embedded in an Atom type="html" element, parsed by feed readers as
escaped HTML. Determine whether Builder's XChar.encode (xmlbase.rb) fully escapes that HTML for the XML context, or
whether a construct survives that a feed reader renders as live markup (the type:html content is double-decoded:
XML-unescaped then HTML-parsed). Build concrete inputs; name the sink or prove inert. Note feeds are reachable via
the RSS feed_token; assess audience.` },
]

const VEC_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['key', 'sink_is_live', 'vectors', 'best_likelihood', 'notes'],
  properties: {
    key: { type: 'string' },
    sink_is_live: { type: 'boolean' },
    vectors: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['technique', 'input', 'sink', 'why_reaches', 'impact', 'likelihood', 'evidence'],
        properties: {
          technique: { type: 'string' }, input: { type: 'string' }, sink: { type: 'string' },
          why_reaches: { type: 'string' }, impact: { type: 'string' },
          likelihood: { type: 'string', enum: ['high', 'medium', 'low'] }, evidence: { type: 'string' },
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
    key: { type: 'string' }, technique: { type: 'string' }, holds: { type: 'boolean' },
    vuln_class: { type: 'string', enum: ['stored-xss', 'dom-xss', 'svg-xss', 'mxss', 'feed-injection', 'info-disclosure', 'none'] },
    severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low', 'none'] },
    confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
    reason: { type: 'string' }, poc: { type: 'string' },
  },
}

const writeFile = (rel) =>
  `\n\nAfter StructuredOutput, ALSO write the same JSON to ${OUT}/${rel} via Write (Bash mkdir -p first). Absolute paths only.`

phase('Deep')
const deep = await parallel(
  PATHS.map((p) => () =>
    agent(
      `You are a senior web-security researcher doing a deep end-to-end trace of ONE candidate XSS path that an
earlier audit's completeness critic flagged as un-walked.
${GROUND}

${p.prompt}

Return every concrete vector with exact input, the precise sink file:line (JS/Vue/Go), why it reaches, impact,
likelihood, and any dynamic-test evidence. Set sink_is_live honestly.
Return via StructuredOutput.${writeFile(`r3-deep-${p.key}.json`)}`,
      { label: `deep:${p.key}`, phase: 'Deep', schema: VEC_SCHEMA, model: 'opus' }
    ).then((r) => (r ? { ...r, _title: p.title } : null))
  )
)

const deepOk = deep.filter(Boolean)
const vectors = deepOk.flatMap((d) =>
  (d.vectors || []).filter((v) => v.likelihood !== 'low').map((v) => ({ ...v, key: d.key }))
)
log(`R3 Deep: ${deepOk.length}/${PATHS.length} paths; live=${deepOk.filter((d) => d.sink_is_live).length}; ${vectors.length} high/med vectors to confirm`)

phase('Confirm')
const confirms = await parallel(
  vectors.map((v) => () =>
    agent(
      `Adversarially CONFIRM this candidate XSS path against real GitLab HEAD at ${CO}. DEFAULT = DEFEATED; holds:true
ONLY with concrete proof attacker bytes reach an executing sink (innerHTML/v-html/inline-same-origin SVG/etc.) past
every DOMPurify/escape/disposition/sandbox guard, with real browser/parser semantics. Read the actual JS/Vue/Go.
${GROUND}

Path ${v.key}
Technique: ${v.technique}
Input: ${v.input}
Claimed sink: ${v.sink}
Why it reaches: ${v.why_reaches}
Impact: ${v.impact}
Evidence so far: ${v.evidence}

REFUTE hard (v-safe-html/DOMPurify binding, text interpolation, attachment/inline disposition, separate sandbox
origin, escape, gem/lib version, value never reaches the sink). Give vuln_class, severity, confidence, a
one-paragraph reason, and a concrete PoC (input + observed executing output) — or poc:"" if defeated.
Return via StructuredOutput.${writeFile(`r3-confirm-${v.key}-${v.technique.replace(/[^a-z0-9]+/gi, '-').slice(0, 20)}.json`)}`,
      { label: `confirm:${v.key}`, phase: 'Confirm', schema: CONFIRM_SCHEMA, model: 'opus' }
    )
  )
)
const confirmed = confirms.filter(Boolean).filter((c) => c.holds)

return {
  paths: PATHS.length,
  deep_run: deepOk.length,
  live_paths: deepOk.filter((d) => d.sink_is_live).map((d) => ({ key: d.key, title: d._title, best: d.best_likelihood })),
  vectors_examined: vectors.length,
  confirmed: confirmed.map((c) => ({ key: c.key, vuln_class: c.vuln_class, severity: c.severity, confidence: c.confidence, reason: c.reason, poc: c.poc })),
  defeated: confirms.filter(Boolean).filter((c) => !c.holds).map((c) => ({ key: c.key, technique: c.technique, reason: c.reason })),
}
