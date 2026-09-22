#!/usr/bin/env node
// build_corpus.js — target-agnostic XSS test-corpus builder.
//
// Reads the agnostic `corpus_data/` family files (generalized PortSwigger
// canonical data), extracts base payloads, applies markdown/HTML/attribute/url
// WRAPPERS each tagged with the matching `injection_context` + `input_vector`,
// and stamps a content-derived `corpus_version` into every record + a manifest.
//
// Output:
//   corpus.json  = [{ id, corpus_category, payload_technique, injection_context,
//                     input_vector, base, input, corpus_version }]
//   corpus.manifest.json = { corpus_version, builder_version, families,
//                            bases, entries, generated_at }
//
// `input` is what the sanitizer is fed. `injection_context` / `input_vector`
// describe WHERE the payload would land so the oracle can pick the right live
// sink set. `corpus_category` = source family filename. `payload_technique`
// carries the source record's technique description.
//
// Usage: node build_corpus.js   (writes corpus.json + corpus.manifest.json beside this file)

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const BUILDER_VERSION = '1.0.0';
const DATA = path.join(__dirname, 'corpus_data');
const OUT_CORPUS = path.join(__dirname, 'corpus.json');
const OUT_MANIFEST = path.join(__dirname, 'corpus.manifest.json');

// Representative tag set for wildcard (tag:"*") expansion — mirrors how the
// PortSwigger cheat sheet expands a wildcard event across many host tags.
const WILDCARD_TAGS = ['body','div','span','p','a','img','svg','math','style','form',
  'input','iframe','video','audio','source','x','xss','marquee','details','select',
  'textarea','table','td','th','object','embed','button','label','meta','base','link',
  'script','template','noscript','title','frameset','frame','keygen','menuitem'];

function expandWildcard(code) {
  if (!/<\*|<\/\*>|\*>/.test(code)) return [code];
  const out = [];
  for (const t of WILDCARD_TAGS) {
    out.push(code.replace(/<\*/g, '<' + t).replace(/<\/\*>/g, '</' + t + '>').replace(/\*>/g, t + '>'));
  }
  return out;
}

// An array-file entry's payload may pack multiple newline-separated payloads.
function splitCode(code) {
  return String(code).split(/\r?\n/).map(s => s.trim()).filter(Boolean);
}

// ---- collect base payloads + technique label from every family file ----
// bases: { category, base, technique }
const bases = [];
function addBase(category, base, technique) {
  if (base && base.length) bases.push({ category, base, technique: technique || '' });
}

// Hash inputs deterministically for corpus_version. We hash the raw bytes of
// every family file (sorted) + the builder source + builder version, so the
// version changes iff the data, wrappers, or builder logic change.
const hash = crypto.createHash('sha256');
hash.update('builder:' + BUILDER_VERSION + '\n');
hash.update('wildcard:' + WILDCARD_TAGS.join(',') + '\n');

const families = [];
const dataFiles = fs.readdirSync(DATA).filter(f => f.endsWith('.json')).sort();
for (const file of dataFiles) {
  const raw = fs.readFileSync(path.join(DATA, file), 'utf8');
  hash.update(file + '\n');
  hash.update(raw);
  families.push(file.replace(/\.json$/, ''));

  const category = file.replace(/\.json$/, '');
  let parsed;
  try { parsed = JSON.parse(raw); }
  catch (e) { console.error('skip (bad json):', file, e.message); continue; }

  // Pull a technique/description label off a record (best-effort, generic).
  const tech = (r) => r.description || r.title || r.type || r.library || r.versionRange || '';

  if (Array.isArray(parsed)) {
    for (const entry of parsed) {
      const code = entry.code || entry.payload || entry.vector;
      const technique = tech(entry);
      if (code) for (const line of splitCode(code)) for (const w of expandWildcard(line)) addBase(category, w, technique);
      // some families nest payloads under tags[]
      if (Array.isArray(entry.tags)) {
        for (const t of entry.tags) if (t.code) for (const w of expandWildcard(t.code)) addBase(category, w, technique);
      }
    }
  } else if (parsed && typeof parsed === 'object') {
    // object keyed by event/name (e.g. events.json) -> { key: {description, tags:[{tag,code}]} }
    for (const k of Object.keys(parsed)) {
      const ev = parsed[k];
      const technique = (ev && ev.description) ? ev.description : k;
      const tags = (ev && ev.tags) || [];
      for (const t of tags) if (t.code) for (const w of expandWildcard(t.code)) addBase(category, w, technique);
    }
  }
}

// ---- wrappers: each tagged with injection_context + input_vector ----
// injection_context ∈ {html_text, attribute_value, url_attr, css, js_context}
// input_vector      ∈ {markdown_link, img_src, autolink, raw_html, url_param}
//
// The wrappers describe how attacker text reaches the sanitizer in different
// real sinks. The context/vector tags let the oracle select the right live-sink
// subset per row (url_attr→scheme sinks, html_text→tags+handlers, etc).
function wrappers(base) {
  const oneLine = base.replace(/\r?\n/g, ' ');
  return [
    // raw HTML body — the classic innerHTML sink
    { variant: 'raw',          input: base,                              injection_context: 'html_text',       input_vector: 'raw_html' },
    // markdown link/image — payload lands in an href/src URL attribute
    { variant: 'link_href',    input: `[click](${oneLine})`,             injection_context: 'url_attr',        input_vector: 'markdown_link' },
    { variant: 'img_src',      input: `![x](${oneLine})`,                injection_context: 'url_attr',        input_vector: 'img_src' },
    { variant: 'autolink',     input: `<${oneLine}>`,                    injection_context: 'url_attr',        input_vector: 'autolink' },
    { variant: 'ref_link',     input: `[click][1]\n\n[1]: ${oneLine}`,   injection_context: 'url_attr',        input_vector: 'markdown_link' },
    // markdown link title — lands inside a title attribute value
    { variant: 'link_title',   input: `[click](http://a "${oneLine}")`,  injection_context: 'attribute_value', input_vector: 'markdown_link' },
    // raw url param style — payload is a bare URL fed as a parameter
    { variant: 'url_param',    input: oneLine,                           injection_context: 'url_attr',        input_vector: 'url_param' },
    // text-context wrappers — payload lands in HTML text flow
    { variant: 'inline_text',  input: `hello ${base} world`,             injection_context: 'html_text',       input_vector: 'raw_html' },
    { variant: 'heading',      input: `# ${oneLine}`,                    injection_context: 'html_text',       input_vector: 'raw_html' },
    { variant: 'blockquote',   input: `> ${base}`,                       injection_context: 'html_text',       input_vector: 'raw_html' },
    { variant: 'list_item',    input: `- ${base}`,                       injection_context: 'html_text',       input_vector: 'raw_html' },
    // style/css context — payload could land inside a style attribute/block
    { variant: 'style_attr',   input: `<div style="${oneLine}">x</div>`, injection_context: 'css',             input_vector: 'raw_html' },
    // js/script context
    { variant: 'js_context',   input: `<script>${oneLine}</script>`,     injection_context: 'js_context',      input_vector: 'raw_html' },
    // html_block — raw block passthrough
    { variant: 'html_block',   input: `${base}\n`,                       injection_context: 'html_text',       input_vector: 'raw_html' },
  ];
}

// Finalize corpus_version once all family bytes are folded in.
hash.update('wrappers:v1\n');
const corpus_version = 'cv1-' + hash.digest('hex').slice(0, 16);

const corpus = [];
let id = 0;
const seen = new Set();
for (const { category, base, technique } of bases) {
  for (const w of wrappers(base)) {
    const key = w.variant + ' ' + w.input;
    if (seen.has(key)) continue;
    seen.add(key);
    corpus.push({
      id: id++,
      corpus_category: category,
      payload_technique: technique,
      injection_context: w.injection_context,
      input_vector: w.input_vector,
      base,
      input: w.input,
      corpus_version,
    });
  }
}

fs.writeFileSync(OUT_CORPUS, JSON.stringify(corpus));
const manifest = {
  corpus_version,
  builder_version: BUILDER_VERSION,
  families,
  bases: bases.length,
  entries: corpus.length,
  generated_at: new Date().toISOString(),
};
fs.writeFileSync(OUT_MANIFEST, JSON.stringify(manifest, null, 2));
console.error(`bases=${bases.length} corpus=${corpus.length} corpus_version=${corpus_version}`);
