#!/usr/bin/env node
// oracle.js — target-agnostic sanitizer-bypass oracle.
//
// Replays each sanitized output through a real DOM innerHTML reparse (jsdom) and
// flags any LIVE sink that is reachable for the row's injection_context. Emits
// COMPACT ROW-SHAPED JSON to STDOUT ONLY (no file output, no DB access).
//
// Usage:
//   node oracle.js --corpus <corpus.json> --out <out.json> [--defense <symbol>]
//
//   --corpus   the corpus.json produced by build_corpus.js (carries
//              injection_context / input_vector / corpus_category / payload_technique)
//   --out      ONE sanitized out.json ([{id, html, error?}]) from sanitizer_runner.php
//   --defense  optional defense_symbol stamped onto each emitted bypass row
//
// STDOUT contract (newline-delimited is NOT used; a single JSON array is written):
//   [ ...per-bypass rows..., <trailing aggregate row> ]
//   per-bypass row: { defense_symbol, payload_id, corpus_category, payload_technique,
//                     injection_context, input_vector, sink_reached, capability, payload }
//   aggregate row:  { verdict, payloads_total, payloads_bypassed, runtime_ms, corpus_version }
//
//   sink_reached ∈ {script_exec, event_handler, url_scheme, css_expression, dom_clobbering}
//   capability   ∈ {xss_exec, open_redirect, html_injection}
//   verdict      ∈ {bypassed, clean, inconclusive}

const fs = require('fs');
const { JSDOM } = require('jsdom');

const t0 = Date.now();

// ---- arg parse ----
const opts = { corpus: null, out: null, defense: null };
const a = process.argv.slice(2);
for (let i = 0; i < a.length; i++) {
  switch (a[i]) {
    case '--corpus':  opts.corpus  = a[++i]; break;
    case '--out':     opts.out     = a[++i]; break;
    case '--defense': opts.defense = a[++i]; break;
    default: process.stderr.write('unknown arg: ' + a[i] + '\n'); process.exit(2);
  }
}
if (!opts.corpus || !opts.out) {
  process.stderr.write('usage: oracle.js --corpus <corpus.json> --out <out.json> [--defense <symbol>]\n');
  process.exit(2);
}

// ---- danger taxonomies (ported from reference classify.js, kept identical) ----
const DANGER_TAGS = new Set(['script','iframe','object','embed','svg','math','form',
  'meta','base','link','frame','frameset','template','noscript','xmp','style',
  'audio','video','source','track','input','button','keygen','marquee','details',
  'foreignobject','animate','set','image','use','annotation-xml','title','textarea','select']);
const URL_ATTRS = ['href','src','srcdoc','action','formaction','data','poster','background','xlink:href','ping','cite','lowsrc','dynsrc'];
const DANGER_SCHEMES = [/^javascript:/i, /^data:text\/html/i, /^data:image\/svg\+xml/i, /^data:application\/xhtml/i, /^vbscript:/i];

// Tags that constitute script execution by survival.
//  - PRESENCE_EXEC_TAGS: dangerous even when empty (<script> runs its text/src content).
//  - EMBED_TAGS: execute only via srcdoc or a dangerous src/data URL — classified by their
//    attributes below, NOT by bare presence.
// NOTE: svg/math/foreignobject/use/animate/set/annotation-xml are deliberately NOT listed.
// DOMPurify and most sanitizers legitimately keep an inert <svg></svg>/<math> shell; flagging
// the bare container as script_exec produced massive false positives (a CLEAN DOMPurify run
// over the 53,872-payload corpus scored ~3,700 "bypasses", every one an inert <svg> shell).
// Their genuinely-dangerous instances carry an on* handler or a javascript: URL, which the
// handler/scheme scanners below already detect on the same element.
const PRESENCE_EXEC_TAGS = new Set(['script']);
const EMBED_TAGS = new Set(['iframe','object','embed','frame','frameset']);

// Live-sink subset selected per injection_context. Each flag enables one
// detection family inside analyze():
//   tags     — dangerous live tags in the reparsed DOM
//   handlers — on* event-handler attributes
//   schemes  — dangerous URL schemes surviving in URL attributes
//   css      — expression()/url(javascript:) inside style
//   clobber  — id/name shadowing a window global (DOM clobbering)
function sinkSet(ctx) {
  switch (ctx) {
    case 'url_attr':        return { tags: false, handlers: false, schemes: true,  css: false, clobber: false };
    case 'css':             return { tags: false, handlers: false, schemes: false, css: true,  clobber: false };
    case 'attribute_value': return { tags: false, handlers: true,  schemes: true,  css: false, clobber: false };
    case 'js_context':      return { tags: true,  handlers: false, schemes: false, css: false, clobber: false };
    case 'html_text':       return { tags: true,  handlers: true,  schemes: true,  css: true,  clobber: true };
    default:                return { tags: true,  handlers: true,  schemes: true,  css: true,  clobber: true };
  }
}

// A reusable DOM. We set innerHTML on a fresh div each time to mimic the real
// element.innerHTML = sanitizedOutput sink.
const dom = new JSDOM('<!DOCTYPE html><body><div id="sink"></div></body>');
const { document, window } = dom.window;

function tryNS(el, ua) {
  if (ua === 'xlink:href') { try { return el.getAttributeNS('http://www.w3.org/1999/xlink', 'href'); } catch (e) {} }
  return null;
}

// Map a raw sink discovery to {sink_reached, capability}.
function classifySink(kind, ctx) {
  switch (kind) {
    case 'script_exec':   return { sink_reached: 'script_exec',   capability: 'xss_exec' };
    case 'event_handler': return { sink_reached: 'event_handler', capability: 'xss_exec' };
    case 'css_expression':return { sink_reached: 'css_expression',capability: 'xss_exec' };
    case 'dom_clobbering': return { sink_reached: 'dom_clobbering', capability: 'html_injection' };
    case 'url_scheme': {
      // javascript:/vbscript:/data:text/html => script exec; otherwise redirect.
      return { sink_reached: 'url_scheme', capability: 'xss_exec' };
    }
    case 'html_injection': return { sink_reached: 'event_handler', capability: 'html_injection' };
    default:               return { sink_reached: 'event_handler', capability: 'html_injection' };
  }
}

// Returns the FIRST {sink_reached, capability} hit (highest-signal first) or null.
function analyze(html, ctx) {
  const set = sinkSet(ctx);
  let div;
  try {
    div = document.getElementById('sink');
    div.innerHTML = html; // the real reparse
  } catch (e) {
    return { error: 'reparse-threw:' + e.message };
  }

  const all = div.querySelectorAll('*');
  let domInjection = false; // any surviving tag (html_injection floor)

  // DOM clobbering: an element id/name that shadows a window global.
  if (set.clobber) {
    for (const el of all) {
      for (const aName of ['id', 'name']) {
        const v = el.getAttribute && el.getAttribute(aName);
        if (v && Object.prototype.hasOwnProperty.call(window, v) === false) {
          // shadows a global only if the name maps to a known window property
          // OR a well-known clobberable target. Use `in` to catch inherited globals.
          if (v in window) {
            div.innerHTML = '';
            return { sink_reached: 'dom_clobbering', capability: 'html_injection', detail: aName + '=' + v.slice(0, 40) };
          }
        }
      }
    }
  }

  for (const el of all) {
    const tag = el.tagName ? el.tagName.toLowerCase() : '';
    const localName = tag.includes(':') ? tag.split(':').pop() : tag;
    if (tag) domInjection = true;

    // dangerous live tags
    if (set.tags && DANGER_TAGS.has(localName)) {
      if (PRESENCE_EXEC_TAGS.has(localName)) {
        // a surviving <script> is a real bypass (runs its text/src content).
        div.innerHTML = '';
        return { sink_reached: 'script_exec', capability: 'xss_exec', detail: '<' + tag + '>' };
      }
      if (EMBED_TAGS.has(localName)) {
        // executes only via srcdoc (inline HTML doc); a dangerous src/data scheme is caught
        // by the URL-scheme scanner below. A bare <iframe>/<object> is html_injection only.
        const sd = el.getAttribute && el.getAttribute('srcdoc');
        if (sd) {
          div.innerHTML = '';
          return { sink_reached: 'script_exec', capability: 'xss_exec', detail: 'srcdoc=' + sd.slice(0, 30) };
        }
      }
      // any surviving danger tag (svg/math/form/input/iframe-without-srcdoc/…) is at least
      // html_injection; genuine script-exec for these is decided by the on*-handler and
      // url-scheme scanners that run on this same element below.
      domInjection = true;
    }

    // event-handler attributes
    if (set.handlers || set.css || set.schemes) {
      for (const attr of el.attributes || []) {
        const an = attr.name.toLowerCase();
        if (set.handlers && an.startsWith('on')) {
          div.innerHTML = '';
          return { sink_reached: 'event_handler', capability: 'xss_exec', detail: an + '=' + attr.value.slice(0, 30) };
        }
        if (set.css && an === 'style' && /expression\s*\(|url\s*\(\s*["']?\s*javascript:/i.test(attr.value)) {
          div.innerHTML = '';
          return { sink_reached: 'css_expression', capability: 'xss_exec', detail: attr.value.slice(0, 40) };
        }
      }
    }

    // dangerous URL schemes surviving in URL attributes
    if (set.schemes) {
      for (const ua of URL_ATTRS) {
        let v = el.getAttribute && (el.getAttribute(ua) || (el.getAttributeNS && tryNS(el, ua)));
        if (!v) continue;
        const norm = v.replace(/[\t\n\r\x00]/g, '').trim();
        for (const re of DANGER_SCHEMES) {
          if (re.test(norm)) {
            div.innerHTML = '';
            // javascript:/vbscript:/data:text\/html => exec; data:image/svg can exec too.
            const isExec = /^javascript:|^vbscript:|^data:text\/html|^data:image\/svg|^data:application\/xhtml/i.test(norm);
            return {
              sink_reached: 'url_scheme',
              capability: isExec ? 'xss_exec' : 'open_redirect',
              detail: ua + '=' + norm.slice(0, 40),
            };
          }
        }
      }
    }
  }

  div.innerHTML = '';
  return null; // no live sink for this context (domInjection alone is not a bypass)
}

// ---- load inputs ----
let corpus, out;
try {
  corpus = JSON.parse(fs.readFileSync(opts.corpus, 'utf8'));
  out = JSON.parse(fs.readFileSync(opts.out, 'utf8'));
} catch (e) {
  // Can't even load — inconclusive aggregate, no bypass rows.
  process.stdout.write(JSON.stringify([{
    verdict: 'inconclusive', payloads_total: 0, payloads_bypassed: 0,
    runtime_ms: Date.now() - t0, corpus_version: null,
  }]));
  process.exit(0);
}

const byId = new Map(corpus.map(r => [r.id, r]));
const corpusVersion = (corpus[0] && corpus[0].corpus_version) || null;

const rows = [];
let total = 0;
let bypassed = 0;
let harnessErrors = 0;

for (const rec of out) {
  const meta = byId.get(rec.id);
  if (!meta) continue; // out id not in corpus — skip silently
  total++;

  // Harness error on this row (isolate threw) — counts toward inconclusive signal.
  if (rec.error || rec.html == null) { harnessErrors++; continue; }

  const ctx = meta.injection_context || 'html_text';
  const hit = analyze(rec.html, ctx);
  if (!hit || hit.error) {
    if (hit && hit.error) harnessErrors++;
    continue;
  }

  bypassed++;
  rows.push({
    defense_symbol: opts.defense || null,
    payload_id: meta.id,
    corpus_category: meta.corpus_category,
    payload_technique: meta.payload_technique,
    injection_context: meta.injection_context,
    input_vector: meta.input_vector,
    sink_reached: hit.sink_reached,
    capability: hit.capability,
    payload: meta.input,
  });
}

// ---- 3-valued verdict ----
//   bypassed     : >=1 live-sink hit
//   clean        : full corpus ran, 0 hits, no harness errors
//   inconclusive : the run could not be trusted (no rows tested, or all/most
//                  rows errored and zero bypasses found)
let verdict;
if (bypassed > 0) {
  verdict = 'bypassed';
} else if (total === 0 || (harnessErrors > 0 && harnessErrors === total)) {
  verdict = 'inconclusive';
} else {
  verdict = 'clean';
}

rows.push({
  verdict,
  payloads_total: total,
  payloads_bypassed: bypassed,
  runtime_ms: Date.now() - t0,
  corpus_version: corpusVersion,
});

process.stdout.write(JSON.stringify(rows));
