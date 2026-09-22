# Joern Forward-Slicing — CPGQL Cookbook (C2 / Joern layer)

> Concrete, copy-paste CPGQL for the forward-slicing lanes. Companion to `references/methodology/forward-slicing-lanes.md` (lane lifecycle, slice tuple, coverage contract), `references/methodology/llmxcpg.md` (execution-path-first slicing integration), and `references/phases/tool-integration-matrix.md` (why Joern sits above CodeQL/Semgrep).
>
> Joern is **tier-1 tooling** for DEEP runs. Its CPG carries inter-procedural data-dependence, so it is the only layer that can answer "does this attacker input *reach* this critical function" mechanically. Tool hits are **hypotheses to verify**, never findings — every slice this file produces lands in `input_slices` and is re-traced in Phase 1/2.

This file exists because "do a forward slice in Joern" was previously prose. The lanes need the *exact* queries, the *exact* coverage measurement, and the *exact* serialization into the DuckDB slice tuple. All three are below.

---

## 0. Language support and CPG fallback

Joern's frontend coverage is uneven across languages. Consult this before committing to a Joern-only workflow:

| Language | Joern frontend | Notes |
|---|---|---|
| C / C++ | First-class | Full CPG, ossdataflow, PDG |
| Java | First-class | Full CPG |
| JavaScript / TypeScript | First-class | Full CPG |
| Python | First-class | Full CPG |
| Go | Partial | CFG/AST available; data-dependence edges incomplete — treat slices as heuristic |
| Rust, Swift, Kotlin, C#, Solidity | Absent | No Joern frontend; use CodeQL slicing fallback or emit a `blind_spot` observation |

**When the CPG cannot be built:** if `joern-parse` fails (missing frontend, build error, platform mismatch), the lane MUST emit a `blind_spot` observation (`obs_kind='blind_spot'`, `body` includes the frontend error and target language) and fall back to the CodeQL slicing path: CodeQL path-queries from standard library sources to sinks produce the same `input_slices` row shape (`slice_kind`, `source_id`/`critical_fn_id`, `callee_set_hash`, `callee_count`, `representative_callees`, `coverage_json`) and are treated identically by downstream gates. For languages with no CodeQL support either, emit the `blind_spot` observation and record `termination_reason='no_slicing_frontend'` in the `agent_steps` row.

---

## 0.1 Configurable budgets (externalized knobs)

**Do not hardcode slice-depth or query-retry counts.** Both are loaded from `db/seed/scoring.yml` at run time so they can be adjusted without touching query code and are recorded in `coverage_json` so downstream rounds know the bound they inherited.

| Config key | Default | What it controls |
|---|---|---|
| `slice.max_depth` | `20` | `--slice-depth` / `maxDepth` budget passed to `joern-slice` and `repeat(_.ddgOut)(_.maxDepth(N))` |
| `query.max_attempts` | `3` | Maximum CPGQL query-generation attempts before recording a `dead_end` (§ 8) |

Read them at lane start:

```sql
SELECT key, value::INTEGER FROM scoring_config
WHERE key IN ('slice.max_depth', 'query.max_attempts');
```

If a row is absent, apply the defaults above and log a warning. Record the resolved depth in every `coverage_json` you emit:

```jsonc
"coverage_json": { "callees_visited": 9, "max_depth_reached": 6,
                   "slice_max_depth_config": 20,   // ← inherited budget
                   "deferred_edges": [] }
```

---

## 0. Build the CPG once per `(repo_url, commit_sha)`

```bash
# One CPG per target/commit. Reuse it across every lane in the run.
joern-parse "$TARGET_SRC" --output "$AUDIT_DIR/cpg.bin"
```

```scala
// Interactive / scripted: load the prebuilt CPG (do NOT re-parse per lane).
importCpg("$AUDIT_DIR/cpg.bin")
run.ossdataflow   // materialize the data-dependence layer if not already present
```

The CPG is an audit input, not a DuckDB artifact — it lives under the audit scratch dir, never in `db/`. Lanes share it read-only, preserving the single-writer rule for DuckDB.

---

## 1. Define the three node sets

Every forward-slice query is `<sinkSet>.reachableByFlows(<sourceSet>)`. Joern's engine is sink-anchored, so "forward from X" is expressed by putting X in the **source** position and a candidate target set in the **sink** position.

```scala
// (a) Attacker-controllable sources — the untrusted-input frontier.
//     Mirror these into `sources` rows; keep the CPGQL beside source_kind.
def attackerSources = cpg.method
  .name("(?i)(get|read|recv|param|query|header|cookie|body|form|deserialize|unmarshal).*")
  .parameter ++
  cpg.call.name("(?i)(getParameter|getHeader|getInputStream|readLine|os\\.getenv|request\\..*)").inout

// (b) Critical functions — produced by the critical-function hunt, stored in
//     `critical_functions`. Anchor each by fullName for stability across runs.
def criticalFns = cpg.method.fullNameExact(
  "pkg.auth.CheckToken:bool(string)",
  "pkg.crypto.Verify:bool(byte[],byte[])"
)   // ← fill from `SELECT symbol_path FROM critical_functions WHERE target_id = ?`

// (c) Dangerous sinks — the existing `sinks` rows (sink-catalog driven).
def dangerousSinks = cpg.call.name("(?i)(exec|system|eval|query|writeFile|sendRedirect|newInstance).*")
```

### 1.1 Framework entry-point modeling

Joern does not automatically link HTTP route registrations (annotations, decorators, router tables) to their handler methods, so a framework-registered handler whose parameters are attacker-controlled will NOT appear in `attackerSources` via the regex above. **Supplement the source set with framework-discovered entry points** as a pre-step:

1. **Enumerate route registrations** — scan for framework-specific patterns before building the CPG source set:

   | Framework | Route pattern |
   |---|---|
   | Spring / JAX-RS (Java) | `@GetMapping`, `@PostMapping`, `@RequestMapping`, `@Path` annotations |
   | Express / Fastify (JS) | `app.get(`, `router.post(`, `fastify.route(` |
   | Flask / FastAPI (Python) | `@app.route(`, `@router.get(` decorators |
   | Gin / Echo (Go) | `r.GET(`, `e.POST(` calls |
   | Django (Python) | `urlpatterns` list entries |

2. **Resolve each handler's parameters** — for each registered handler method, treat its request-bound parameters (body, query, path, header) as additional attacker sources:

   ```scala
   // Example: add Spring @RequestMapping handler parameters to attackerSources.
   // Replace the annotation name with the framework-appropriate pattern.
   def frameworkHandlers = cpg.method
     .where(_.annotation.name("(?i)(GetMapping|PostMapping|RequestMapping|PutMapping|DeleteMapping|PatchMapping)"))
   
   def frameworkSources = frameworkHandlers.parameter
     .whereNot(_.name("this"))   // exclude 'this' receiver
   
   // Merge with the regex-based sources:
   def allAttackerSources = attackerSources ++ frameworkSources
   ```

3. **Synthesize a route-entry annotation observation** — emit one `agent_observations` row per discovered handler with `obs_kind='tool_output'`, `symbol_path=<handler.fullName>`, so the handler appears in feed-forward even if no flow is found this round.

Use `allAttackerSources` in place of `attackerSources` throughout §§ 2–3 and § 10.

---

## 2. Forward slice **FROM attacker inputs TO critical functions** (`critical_fn_reach`)

This answers Ask-4 direction (a): *which attacker inputs reach each ranked critical function.* One row per `(critical_fn, source)` reachability verdict lands in `critical_fn_reach`.

```scala
// CF callsites become the "sink" position; attacker inputs the "source".
def cfCalls = cpg.call.filter(c => criticalFns.fullName.toSet.contains(c.methodFullName))

val reachFlows = cfCalls.reachableByFlows(attackerSources)

// Serialize each flow → one critical_fn_reach row.
reachFlows.map { flow =>
  Map(
    "source_symbol" -> flow.elements.head.method.fullName,
    "cf_symbol"     -> flow.elements.last.method.fullName,
    "hop_count"     -> flow.elements.method.dedup.size,
    "guard_path"    -> flow.elements.isControlStructure.code.l,   // → guard_path_json
    "reach_status"  -> "reaches"
  )
}.l
```

| CPGQL outcome | `critical_fn_reach.reach_status` |
|---|---|
| `reachableByFlows` returns ≥ 1 flow | `reaches` |
| A guard/sanitizer dominates every flow (see `flow.elements.isControlStructure`) | `blocked` |
| CF callsite exists but no flow found within `--slice-depth` | `unproven` |

`unproven` is **not** `blocked` — it records that the lane hit its depth/coverage budget, which the coverage block (§5) must then explain. Never silently drop a CF as "not reachable".

### Dataflow soundness caveats

`reachableByFlows` uses Joern's **ossdataflow** layer, which is a forward-reachability approximation. It under-approximates in the following cases — a `blocked` verdict in these situations may be a false negative, not a genuine block:

| Under-approximation case | Effect | Mitigation |
|---|---|---|
| **Field / container propagation** — taint through struct fields, map entries, array slots, or collection elements is not tracked by default | A value stored into a field and read back later appears as a new, untainted source | Inspect field-write/read pairs on suspected taint paths manually; emit a `blind_spot` observation if a field write is on the path but the read is not tracked |
| **Implicit / control-dependence flow** — a predicate that influences control flow without a direct data edge (e.g., an if-guard whose branch sanitizes) is not modeled as a data edge | `blocked` may over-claim when the "guard" sanitizes only some branches | Cross-check with a `control-dependence-slice` (swarm-pipeline.md § Slice Types) for auth/guard nodes |
| **External callees** — calls to methods with no Joern-resolved body are `deferred_edges` (§ 5); taint may propagate through them unseen | Flows that cross library boundaries to an unresolved callee stop at the call site | Record the callee in `deferred_edges`; treat the reach verdict as `unproven` rather than `blocked` when unresolved callees are on the path |
| **Implicit conversions and reflective calls** — Java reflection, Python `getattr`, JS `eval` | Taint through these paths is invisible to the static graph | Note the dynamic dispatch in `blind_spot` observations; route to dynamic lane (fuzz / concolic) |

**Practical rule:** treat `blocked` as "blocked along modeled data edges" — not as a sound proof of non-reachability. For security-critical CFs (tier 1) where a `blocked` verdict gates a finding, run a complementary `control-dependence-slice` and consider a dynamic confirmation step.

---

## 3. Forward slice **FROM a critical function TO downstream effects** (`critical_fn_forward` slice)

This answers Ask-4 direction (b): *once control is inside a ranked critical function, what dangerous effects does its output feed?* The CF's return value and mutated out-params become the source position.

```scala
def cf = cpg.method.fullNameExact("pkg.auth.CheckToken:bool(string)")

// The CF's own outputs are the taint origin for the downstream slice.
def cfOutputs = cf.methodReturn ++ cf.parameter.filter(_.isOutParam)

val forwardFlows = dangerousSinks.reachableByFlows(cfOutputs)
```

For **unbounded** forward exploration (enumerate downstream nodes even without a predeclared sink), step the data-dependence graph directly — this is what feeds the coverage counters:

```scala
// 1-hop, then transitively, forward along data-dependence edges.
def forwardFrontier = cf.methodReturn.ddgOut.l
// Use DEPTH from scoring_config key 'slice.max_depth' (§ 0.1); default 20.
def forwardClosure  = cf.methodReturn.repeat(_.ddgOut)(_.maxDepth(DEPTH).emit).dedup.l
```

Each `forwardFlows` path is packaged as **one `input_slices` row** with `slice_kind = 'critical_fn_forward'` and `critical_fn_id` set to the originating CF (see forward-slicing-lanes.md § Slice Tuple). The `forwardClosure` size feeds `callees_visited`.

---

## 3b. Negative-space query — guard-not-called on a path (authz/IDOR)

`reachableByFlows` is a **positive-flow** engine: it finds paths where taint *does* travel. It cannot model the negative-space question — "is there an entry→sink path on which an access-control guard is **never called**?" — because that requires enumerating paths that *lack* a node, not paths that contain one.

The following recipe answers that question using Joern's `controlledBy` / path enumeration and set subtraction. It produces findings of kind `auth-check-slice`, storable as `input_slices` rows with `slice_kind = 'defense_callsite'`.

```scala
// Step 1 — collect all auth/access-control critical functions from the DB.
//   Replace the name regex with fullNames from:
//   SELECT symbol_path FROM critical_functions WHERE cf_category IN ('auth_check','access_control')
def authGuards = cpg.method.name(
  "(?i).*(authenticate|authoriz|check_?permission|has_?role|is_?admin|require_?(login|auth)|verify_?token).*"
)

// Step 2 — enumerate entry→dangerousSink paths (all reachable paths, not just tainted ones).
//   Use the call graph: callers of each sink, transitively up to entry points.
def sensitiveCallsites = dangerousSinks   // from §1(c)

// For each sensitive callsite, walk callers up to external entry points.
// 'depth' is read from scoring_config key 'slice.max_depth' (§ 0.1).
val DEPTH = 20  // replace with config-read value at runtime
def entryPoints = cpg.method.isExternal(false)
  .whereNot(_.callIn)   // methods with no internal callers = entry points

// Step 3 — for each (entry, sink) pair reachable in the call graph,
//   collect the set of method fullNames on that call path.
//   A path is UNGUARDED when no auth guard fullName appears in its node set.

val unguardedPaths = sensitiveCallsites.flatMap { sinkCall =>
  // callers of the sink, up to depth levels
  val callerChains = sinkCall.method
    .repeat(_.calledByIncludingExternal)(_.maxDepth(DEPTH).emit)
    .dedup.l

  // filter to chains that never touch an auth guard
  val guardFullNames = authGuards.fullName.toSet
  callerChains
    .filter(m => !guardFullNames.contains(m.fullName))  // this method is not a guard
    .filter(m => m.callOut.callee.fullName.toSet.intersect(guardFullNames).isEmpty) // doesn't call one
    .map(m => Map(
      "entry_method"  -> m.fullName,
      "sink_method"   -> sinkCall.method.fullName,
      "sink_callsite" -> sinkCall.code,
      "guard_missing" -> "no auth_check CF on call path"
    ))
}.l
```

**Interpreting results:** each entry in `unguardedPaths` is a **candidate** authz gap — a path from a reachable entry to a sensitive sink with no auth guard observed on the call graph. These are **not confirmed findings**: the guard may exist in a caller the call-graph walk did not reach (external, dynamic dispatch, framework middleware). Each candidate MUST be manually verified against the actual request lifecycle before emission as a `gr_findings` row.

**Emit each candidate** as an `input_slices` row with `slice_kind = 'defense_callsite'` and `source_id` set to the entry method's `sources.id`, annotating the `coverage_json` with `guard_missing: true` and the `symbol_path` of the absent guard set.

**Limitation:** this query operates on the *call graph*, not the *data-flow graph* — it checks whether any call to an auth guard method appears on the path, not whether the guard's *return value* governs the sink. A guard that is called but whose result is not checked (e.g., `checkAuth(); doSensitiveThing()` without a conditional) will **pass** this filter but remain a real vulnerability. Pair with a `control-dependence-slice` on the guard's return value for high-confidence verdicts.

---

## 4. Critical-function *identification* queries (feed `critical_functions`)

These are the mechanical candidate-generators the critical-function hunt triages and ranks. See `references/v2/critical-function-hunt.md` for the taxonomy and ranking; the queries below populate `cf_category` candidates. **Tool output is a hypothesis** — the hunt confirms category + evidence before a row is written.

```scala
// auth_check / access_control
cpg.method.name("(?i).*(authenticate|authoriz|check_?permission|has_?role|is_?admin|verify_?token|require_?(login|auth)).*").l
// crypto_op
cpg.call.name("(?i).*(encrypt|decrypt|sign|verify|hmac|pbkdf2|bcrypt|digest|cipher).*").l
// deserializer
cpg.call.name("(?i).*(readObject|unserialize|pickle\\.loads?|yaml\\.load|fromJson|ObjectInputStream|unmarshal).*").l
// validator_sanitizer
cpg.method.name("(?i).*(validate|sanitiz|escape|clean|whitelist|allowlist|filter).*").l
// parser_decoder
cpg.call.name("(?i).*(parse|decode|fromString|unquote|b64decode).*").l
// privileged_op / state_transition / trust_boundary_transfer — usually project-specific;
// seed from crown-jewel map (Phase L2) symbol_paths rather than name regex.
```

**Blast-radius factor by fan-in** (drives `critical_functions.factor_blast_radius`):

```scala
cpg.method.name("(?i).*(authenticate|authoriz|verify_?token).*")
  .map(m => (m.fullName, m.callIn.size))   // callIn.size = number of callers
  .sortBy(-_._2).l
```

---

## 5. Coverage measurement — the *explicit* part (Ask 2)

Every lane MUST emit `agent_steps.coverage_json` before terminating. Forward-slice lanes compute the three required keys directly from the CPG so coverage is **measured, not asserted**:

| Coverage key | CPGQL derivation |
|---|---|
| `callees_visited` | `forwardClosure.size` (§3) — distinct data-dependence nodes actually walked |
| `max_depth_reached` | `flows.map(_.elements.size).maxOption.getOrElse(0)` — longest flow length |
| `deferred_edges` | unresolved/dynamic calls in the slice — see query below |

```scala
// Edges Joern could not resolve become deferred_edges {symbol_path, reason}.
def deferred = cpg.call
  .filter(c => c.callee.isEmpty || c.callee.isExternal.nonEmpty)
  .map(c => Map("symbol_path" -> c.methodFullName,
                "reason" -> (if (c.callee.isEmpty) "unresolved_dynamic_dispatch" else "external_callee")))
  .dedup.l
```

A lane that returns `agent_steps.status = 'exhausted'` MUST show that `callees_visited` covers the reachable frontier and that every gap is enumerated in `deferred_edges` with a reason. An empty `deferred_edges` on a non-trivial slice is itself suspect — dynamic dispatch and external calls almost always exist; their absence usually means the query under-walked. The orchestrator rewrites `exhausted` lanes with missing coverage keys to `failed` / `termination_reason = 'incomplete_coverage'` (forward-slicing-lanes.md § Termination Contract).

---

## 6. SecuritySlice packaging (CPG flow → DuckDB slice tuple)

A Joern flow becomes an `input_slices` row the orchestrator can flush. The lane emits a row event; it never writes DuckDB itself.

```jsonc
{"kind": "input_slices", "row": {
  "target_id": 1,
  "source_id": null,               // CF-anchored: source_id is NULL on a critical_fn_forward slice
  "critical_fn_id": 7,             // the critical function this slice traces forward FROM
  "slice_kind": "critical_fn_forward",
  "callee_set_hash": "<sha256 of flow.elements.method.fullName joined>",
  "callee_count": 9,
  "representative_callees": ["pkg.auth.CheckToken", "pkg.db.RawQuery", "..."],
  "coverage_json": {"callees_visited": 9, "max_depth_reached": 6, "deferred_edges": []}
}}
```

The schema's `slice_anchor` CHECK enforces exactly one anchor: a `critical_fn_forward` row sets `critical_fn_id` with `source_id` NULL (above); a source-anchored row (`forward_taint` / `backward_sink` / `defense_callsite`) sets `source_id` with `critical_fn_id` NULL. Sending both — or neither — fails the CHECK at flush. The natural key `(target_id, callee_set_hash, slice_kind)` keeps slice creation idempotent across re-runs (forward-slicing-lanes.md § Slice Tuple). `callee_set_hash` is computed over the **ordered** `flow.elements.method.fullName` list so the same flow re-hashes identically next round.

### `joern-slice` CLI alternative (batch, no shell)

For non-interactive lanes the `joern-slice data-flow` extractor produces the same material as a JSON file the orchestrator parses into slice rows:

```bash
# Read slice.max_depth from scoring_config (default 20) before invoking.
SLICE_DEPTH=$(vrdb exec "SELECT value FROM scoring_config WHERE key='slice.max_depth'" | tail -1)
SLICE_DEPTH=${SLICE_DEPTH:-20}

joern-slice data-flow "$AUDIT_DIR/cpg.bin" \
  --slice-depth "$SLICE_DEPTH" \
  --sink-method-pattern '(?i)(exec|system|eval|query|writeFile).*' \
  --output "$AUDIT_DIR/slices.json"
# orchestrator reads slices.json → input_slices row events (single-writer preserved)
```

`--slice-depth` is the budget that, when hit, produces `unproven` reach verdicts (§2) — record the configured depth in `coverage_json` (key `slice_max_depth_config`) so a later round knows the bound it inherited (see § 0.1).

---

## 7. Execution-path-first slice construction (LLMxCPG)

Source: **LLMxCPG** (Lekssays et al., QCRI/NJIT/MBZUAI; `arXiv:2507.16585`; repo: https://github.com/qcri/llmxcpg). The paper's reusable core is a three-step recipe that turns a `source → sink` reachability into a *focused snippet* — the path, the identifiers that share its lines, and only the code that influences either. It reports a **68–91% reduction** versus the enclosing function(s). This lands as a new `slice_kind = 'execution_path'` produced **within** the existing `forward_slice_lane` (no new lane, no new gate). The queries below are **adapted from the paper's Listings, which are illustrative fragments — not turnkey**: substitute your own source/sink selectors and **validate the Joern API surface against your Joern version** before relying on them. Some idioms (`.lineNumber.l` on a single node, `reachableByFlows` over a `List`) depend on Joern's implicit traversal lifting and have shifted across releases; the C2 query-gen loop (§ 8) exists precisely to catch a query that does not parse or returns empty.

The paper's running example is a kernel `skb_put(skb, len + ring->frameoffset)` overflow; the generic recipe is the same shape with your own selectors substituted.

### Step 1 — path extraction

Identify the source and sink, then ask Joern for the source→sink flows. The flow set *is* the execution path(s).

```scala
// Paper example (CVE-style skb_put overflow):
val source = cpg.identifier.name("len")
val sink   = cpg.call.name("skb_put")
  .where(_.argument.order(2).codeExact("len + ring->frameoffset"))
val execution_paths = sink.reachableByFlows(source)

// Generic form — substitute your own source/sink selectors:
//   val source = cpg.identifier.name("<tainted_var>")            // or a parameter / call
//   val sink   = cpg.call.name("<dangerous_fn>").where(_.argument.order(<n>).codeExact("<expr>"))
//   val execution_paths = sink.reachableByFlows(source)
```

`execution_paths` is a list of flows; the path nodes are `execution_paths.flatMap(_.elements)`.

### Step 2 — interacters

An identifier is an **interacter** if its line number matches a line of at least one execution-path node. This pulls in contextual definitions the raw path misses — a constant, a bound, a struct field assigned on the same line — that the data-flow edges alone would not surface.

```scala
val execution_path_nodes = execution_paths.flatMap(_.elements).l

val interacters = cpg.identifier.filter(id =>
  execution_path_nodes.lineNumber.toSet
    .intersect(id.lineNumber.l.toSet)
    .size.equals(1)
)
```

Read the predicate as: *keep this identifier when its line number is one of the execution-path lines.* An identifier carries a **single** line number, so the path-line ∩ identifier-line intersection is always **0 or 1** — `.size.equals(1)` (the paper's idiom) therefore means a *non-empty* intersection, i.e. the identifier sits on a path line. (It is **not** an "exactly one" filter that could drop identifiers on shared lines — the right operand can never exceed one element.)

### Step 3 — path-union backward slice

Union the path nodes with the interacters, then run a PDG-backed backward slice over the whole CPG. Joern walks the program-dependence graph to gather every code element that *influences* the path ∪ interacters — producing the focused snippet.

```scala
val execution_path_and_interacters = (execution_path_nodes ++ interacters).l
val focused_slice = execution_path_and_interacters.reachableByFlows(cpg.all)
```

> **Performance caveat.** `reachableByFlows(cpg.all)` uses *every* CPG node as the source set — faithful to the paper's Listing 3, but expensive on a large CPG. The goal is the PDG-backed backward slice, not the literal `cpg.all` breadth: if it is too slow, scope the source set to the enclosing method(s) (e.g. the path nodes' `.method`) instead of `cpg.all`.

The result is serialized as a SecuritySlice `input_slices` row with `slice_kind = 'execution_path'` (see § 6 for the row event shape). The slice is **source-anchored**: set `source_id`, leave `critical_fn_id` NULL — it follows the same `slice_anchor` CHECK branch as `forward_taint` / `backward_sink`.

```jsonc
{"kind": "input_slices", "row": {
  "target_id": 1,
  "source_id": 4,                  // the source identifier/param this path starts FROM
  "critical_fn_id": null,
  "slice_kind": "execution_path",
  "callee_set_hash": "<sha256 of focused_slice.elements.method.fullName joined, ordered>",
  "callee_count": 6,
  "representative_callees": ["drv.ring_rx", "skb_put", "..."],
  "coverage_json": {"callees_visited": 6, "max_depth_reached": 4, "deferred_edges": []}
}}
```

Lane wiring + the discriminator row are in `references/methodology/forward-slicing-lanes.md` § `slice_kind` discriminator; the integration summary + concept map is in `references/methodology/llmxcpg.md`.

## 8. CPGQL query-generation feedback loop (C2)

LLMxCPG (`arXiv:2507.16585`) does not assume a query is correct on the first try. An agent **generates** a CPGQL query, **runs** it against the Joern server, and on failure **feeds the Joern error back** into the next generation — a bounded loop up to **`query.max_attempts`** attempts (default 3; read from `scoring_config` per § 0.1).

```
attempt 1 ──► run on Joern server ──► valid + non-empty? ──► done (emit slice)
   │                                        │
   │                                        └─ syntax_error OR empty result
   │                                                │
   └──◄── regenerate query with the Joern error ◄──┘   (≤ query.max_attempts total)

after max attempts failed ──► record the attempt as a dead_end
```

- On a **syntax error**, the raw Joern error message is the feedback signal — paste it into the regeneration prompt verbatim so the next query fixes the exact parse/type failure.
- On an **empty result**, the selector probably mis-anchored the source or sink — broaden/rename the selector and retry.
- After **`query.max_attempts`** failures, stop and record a `dead_end` (`agent_observations.obs_kind='dead_end'`); do not keep spinning.

Every attempt is logged to the **`query_attempts`** table for change-visibility (one row per attempt): `status IN ('valid','syntax_error','empty')`, `joern_error` (the raw server message on failure), `attempt_no` (1..`query.max_attempts`), plus the `query_text` (sidecar when large) and FK back-links to `targets` / `agent_steps` / `input_slices`. Because every generated query — including the failed ones — is persisted, a later round can see exactly which selectors Joern rejected and why, instead of rediscovering the same dead query.

## 9. Anti-brittleness doctrine (C3)

LLMxCPG (`arXiv:2507.16585`) is explicit that **name-based seeds are necessary but not sufficient**:

- **Sink catalogs / predefined dangerous-function lists** (`references/sinks-catalog.md`, the `sinks` rows) are a good *seed* — but **custom wrappers** around a dangerous function defeat name-based matching. A project that calls `safe_copy()` (which internally calls `memcpy`) will never match a `memcpy` name filter, yet carries the same overflow.
- **Selecting criterion points from patch-diffs is unreliable.** Refactoring noise (renames, reformatting, unrelated hunks in the same commit) makes the changed lines a poor proxy for the actual vulnerable nodes.

**Doctrine:** prefer **graph-discovered execution paths** (`reachableByFlows`, § 7) as the *primary* criterion-point selector, with the sink catalog as **one seed among several** (others: attacker-source frontier, `critical_functions`, fuzz frontier nodes). The CPG finds the wrapper's *callsite of the real sink* even when the name filter cannot — so let the graph, not the name list, decide what is on the path.

## 10. Codebase slice-coverage — measure it WHEN THE SLICES END

The per-lane `coverage_json` (§ 5) answers *"how thoroughly was THIS slice walked?"* and `v_lane_coverage` answers *"which lanes ran?"*. Neither answers the question that decides whether the Hunt actually looked at the attack surface: **"of the whole codebase, what fraction did the UNION of all slices touch?"** A swarm can slice five functions perfectly while 95% of the attack surface was never sliced — and nothing flags it. So when the Hunt's slicing lanes finish for a `(target, round)`, the **non-mandatory `cpg_coverage` step** measures the union and persists it.

> It is a **non-mandatory** strategy (id 16) — deliberately **absent** from `v_required_deep_lanes`, so the mandatory roster and the LLMxCPG "no new lane" precedent are unchanged. It is enforced instead by the count-free gate `v_coverage.slices_without_codebase_coverage` (slices exist but no `cpg_slice_coverage` row ⇒ RED). There is **no percentage floor** — slicing is selective by design, so a low % is *inspected* (via `v_cpg_slice_coverage`), never auto-failed.

### Two denominators (both stored as integer counts; the % is the view's job)

| Ratio | Denominator | What it tells you |
|---|---|---|
| **raw** (`methods_*`) | all first-party methods (`cpg.method.isExternal(false)`) | the literal "% on codebase" — an honest baseline |
| **frontier** (`frontier_*`) | **attacker-reachable ∪ sink-bearing ∪ critical-function** methods | the **bug-finding signal**: did the slices cover the *security-relevant* surface? This is what drives round feed-forward |

The frontier membership **reuses sets already computed** — only the raw method total is a fresh count:

```scala
// RAW denominator — the only fresh count needed.
val methodsTotal = cpg.method.isExternal(false).fullName.dedup.l

// FRONTIER denominator = union of three already-known sets:
val sinkBearing  = dangerousSinks.method.fullName.toSet          // §1(c): methods containing a catalogued sink call
val criticalFns  = criticalFnSet                                 // fullNames from the `critical_functions` registry
val reachable    = attackerSources                               // §1(a)
  .reachableByFlows(cpg.method.isExternal(false))
  .flatMap(_.elements.method.fullName).toSet                     // (or reuse critical_fn_reach 'reaches' + forward_taint flows from the DB)
val frontier     = sinkBearing ++ criticalFns ++ reachable       // distinct first-party method fullNames
```

> **Reuse note.** `reachable` is largely already in the DB: the `critical_fn_reach` rows with `reach_status='reaches'` and the `forward_taint` / `execution_path` slice flows already enumerate attacker-reachable methods. Prefer intersecting the **already-computed** sets over re-running `reachableByFlows` over every source — only `methodsTotal` genuinely needs Joern at slice-end.

### Numerators — the UNION across every slice produced this round

This is why it must be measured in Joern (or from a run-scoped accumulator) and **cannot** be reconstructed from the DB: `input_slices.representative_callees` is deliberately truncated, so the stored rows do not carry the full per-slice method set. As each slice lane emits its `input_slices` row event, it also contributes its `focused_slice.elements.method.fullName` to a run-scoped union; the `cpg_coverage` step closes it out:

```scala
// allSliceMethods = distinct first-party method fullNames across the union of every
// slice's nodes this round (forward_taint ∪ backward_sink ∪ critical_fn_forward ∪ execution_path).
val covered         = allSliceMethods.toSet.filter(fn => methodsTotal.toSet.contains(fn))
val methodsCovered  = covered.size
val frontierCovered = covered.intersect(frontier).size

// per_kind_json: covered-method count attributable to each slice_kind (change-visibility).
val perKind = sliceMethodsByKind.view.mapValues(_.toSet.size).toMap   // {"execution_path": n, ...}
```

### Emit: one coverage row + a blind-spot per uncovered frontier method

The `cpg_coverage` step emits **one** `cpg_slice_coverage` row (counts only — `v_cpg_slice_coverage` computes `frontier_covered_pct` / `methods_covered_pct`), and **one reusable `blind_spot` observation per uncovered frontier method** so the next round slices them *first*:

```jsonc
{"kind": "cpg_slice_coverage", "row": {
  "target_id": 1, "round_id": 4, "agent_step_id": 88,
  "methods_total": 200, "methods_covered": 40,        // raw: 20% of the codebase
  "frontier_total": 50, "frontier_covered": 35,       // frontier: 70% of the attack surface
  "files_total": 30, "files_covered": 12,
  "per_kind_json": "{\"execution_path\":28,\"forward_taint\":9,\"critical_fn_forward\":3}",
  "measured_at": "...", "coverage_hash": "<sha256 of target+round+basis>"
}}
```

```jsonc
// one per uncovered frontier method — fed forward, never silently dropped:
{"kind": "agent_observations", "row": {
  "target_id": 1, "agent_step_id": 88,
  "obs_kind": "blind_spot", "reusable": true,
  "symbol_path": "pkg.handler.RawExec",                 // anchor: the uncovered frontier method
  "body": "frontier method never covered by any slice this round (sink-bearing); slice it next round"
}}
```

**Reading the number.** `frontier_covered_pct` is the signal that matters: a high raw % with a low frontier % means effort went to inert code; a low raw % with a high frontier % is *healthy* (focused slicing). The round-over-round `frontier_covered_pct` trend (via `v_cpg_slice_coverage` keyed by `round_id`) shows whether each round is closing the blind spots the prior round's `blind_spot` observations flagged. Schema + gate: `db/migrations/0017-cpg-slice-coverage.sql`; integration summary: `references/methodology/llmxcpg.md`; lane lifecycle: `references/methodology/forward-slicing-lanes.md` § Slice-end coverage.
