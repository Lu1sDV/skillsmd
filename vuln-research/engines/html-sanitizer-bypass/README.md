# HTML Sanitizer Bypass — harness engine

Target-agnostic engine for the vuln-research SAST swarm's "HTML Sanitizer
Bypass" lane. It builds a fixed XSS corpus, replays it through a target's REAL
sanitizer, and reports — as compact stdout rows — every payload that survives
sanitization and still reaches a live DOM sink.

**100% target-agnostic.** No Zabbix/Parsedown/etc. specifics are baked in. The
one per-sanitizer artifact (the *isolate*) is generated at runtime by the lane
agent and supplied via `--isolate`. The engine never opens a database and never
returns corpus payloads into an LLM context — it is a standalone subprocess that
emits compact row-shaped JSON to stdout.

## Files

| File | Role |
|------|------|
| `build_corpus.js` | Builds `corpus.json` (+ `corpus.manifest.json`) from `corpus_data/`. Run ONCE; output is pinned/committed. |
| `corpus_data/` | 21 agnostic payload-family files. `corpus_category` = family filename. |
| `sanitizer_runner.php` | Runs the REAL target `sanitize()` (via isolate) over the corpus → `out.json` `[{id, html}]`. One PHP process per isolate. |
| `oracle.js` | Reparses each sanitized output in jsdom, selects live sinks per `injection_context`, emits compact bypass rows + a trailing aggregate to stdout. |
| `corpus.json` | Pinned corpus (committed). Carries `corpus_version`. |
| `corpus.manifest.json` | Corpus metadata (version, families, counts). |

## Invocation sequence

```sh
# 0. one-time deps
npm install                       # jsdom

# 1. build the pinned corpus ONCE (already committed; only re-run if corpus_data changes)
node build_corpus.js              # -> corpus.json + corpus.manifest.json

# 2. PER reachable sanitizer:
#    a. lane agent generates an isolate shim into a scratch tmpdir
#    b. run the real sanitizer over the corpus
php sanitizer_runner.php --isolate /tmp/scratch/isolate.php \
                         --corpus corpus.json \
                         --out /tmp/scratch/out.json
#    c. classify -> compact stdout rows
node oracle.js --corpus corpus.json \
               --out /tmp/scratch/out.json \
               --defense <defense_symbol> > /tmp/scratch/rows.json
#    d. delete the scratch tmpdir (isolate + out.json) when done
```

The lane agent reads oracle stdout into an in-memory queue; the orchestrator
(sole DuckDB writer) flushes per-payload rows to `defense_bypasses` and the
aggregate to `sanitizer_bypass_runs`.

## The isolate contract

The **isolate** is the single per-sanitizer artifact, generated at runtime by
the lane agent (NOT shipped with this engine, NOT a swarm result artifact). It:

- lives in a scratch tmpdir and is deleted after the run;
- `require`s the target's REAL sanitizer source;
- defines exactly: `function sanitize(string $input): string { ... }` that
  invokes the real target sanitizer and returns its output;
- runs REAL target code — it MUST NOT mock, stub, or reimplement the sanitizer.

Minimal example (illustrative — generated per target, not committed):

```php
<?php
require '/abs/path/to/target/RealSanitizer.php';
function sanitize(string $input): string {
    return (new \Target\RealSanitizer())->clean($input);
}
```

## stdout row contract

`oracle.js` writes a single JSON array: per-bypass rows followed by one trailing
aggregate row.

Per-bypass row:
```json
{ "defense_symbol": "...", "payload_id": 123, "corpus_category": "protocols",
  "payload_technique": "...", "injection_context": "url_attr",
  "input_vector": "markdown_link", "sink_reached": "url_scheme",
  "capability": "xss_exec", "payload": "..." }
```

Trailing aggregate row:
```json
{ "verdict": "bypassed", "payloads_total": 30000, "payloads_bypassed": 5,
  "runtime_ms": 4210, "corpus_version": "cv1-..." }
```

Closed vocabularies (must match the DB schema):
- `sink_reached` ∈ `{script_exec, event_handler, url_scheme, css_expression, dom_clobbering}`
- `capability` ∈ `{xss_exec, open_redirect, html_injection}`
- `injection_context` ∈ `{html_text, attribute_value, url_attr, css, js_context}`
- `input_vector` ∈ `{markdown_link, img_src, autolink, raw_html, url_param}`
- `verdict` ∈ `{bypassed, clean, inconclusive}`

`payload_technique` and `corpus_category` are open-vocab TEXT.
