# Fuzzing Lane (Phase 1.5, DEEP-only) — C8

> A **dynamic sanitizer-finding and coverage-deepening modality** that runs between Phase 1 Hunt and Phase 2 Confirm on **DEEP** runs. Its job: find memory-safety / logic crashes, C/C++ leaks, expose deep uncovered functions, and exercise stateful traces with applicable fuzzing/symbolic tools, then feed each crash, deterministic leak, or divergence into the five-gate Confirm as a candidate `gr_findings` row. Source of truth: `db/schema.sql` (`fuzz_runs` + `fuzz_artifacts` tables) + `gr_findings` (`finding_kind='fuzz_crash'` / `fuzz_divergence`) + this doc.
>
> This is **methodology, not a bundled fuzzer.** The orchestrator drives the host's installed engines (AFL++, libFuzzer, honggfuzz, cargo-fuzz, `go test -fuzz`, Jazzer, KLEE/SymCC, Miri, and protocol/stateful fuzzers such as AFLNet/StateAFL/boofuzz when available); the skill ships no runtime. Like every other lane, agents emit row events to the queue and the orchestrator is the single DuckDB writer.

---

## 0. Lane identity — `boundary_fuzz_lane`, **not** `isolation_fuzz_lane`

The pipeline has **two** fuzzing lanes with different jobs, different phases, and different tables. Keeping them distinct is deliberate — conflating them hides whether the mandatory boundary sweep actually ran.

| | **`boundary_fuzz_lane`** (this doc) | **`isolation_fuzz_lane`** |
|---|---|---|
| Strategy seed | id 10 | id 5 |
| Phase | **1.5** (between Hunt and Confirm) | **0.75** Defense Pre-Break (+ thin **3** recheck), Stage C escalation |
| Tier | DEEP only | MEDIUM + DEEP |
| Goal | Discover **memory-corruption / crash / C/C++ leak** bugs at untrusted boundaries | Prove a **specific isolated defense** can be bypassed |
| Surface | Parsers, decoders, FFI/JNI/cgo shims, tier-1 `critical_functions` | One defense wrapped as a callable + its bypass corpus |
| Oracle | Sanitizer abort (ASan/UBSan/MSan/…), invariant break | Defense returns "allow" on a payload it should reject |
| Records to | **`fuzz_runs`** + **`fuzz_artifacts`** (+ `gr_findings` `fuzz_crash` / `fuzz_divergence`) | **`defense_bypasses`** (+ cascade emits) |
| Mandatory? | **Yes** — run or skip-with-reason (§ 1) | No — cost-gated, only on a defense that survived Stages A/B |

`fuzz_runs` is **exclusively** the Phase 1.5 lane's table; an isolation-fuzz attempt (defense pre-break / recheck) records its outcome as `defense_bypasses` evidence, never a `fuzz_runs` row. So a query over `fuzz_runs` is always boundary-fuzz accounting, and a join through `agent_steps.strategy_id` to `strategies.name = 'boundary_fuzz_lane'` never returns an isolation-fuzz step. The schema enforces the strategy split (`db/schema.sql` strategies seed), and migration `0008` inserts/updates `boundary_fuzz_lane` to version 2 for current free-TEXT strategy schemas. Obsolete audit DBs that still have a pre-v0.14 `strategies.name` CHECK cannot be widened in place by DuckDB; recreate those ephemeral DBs before using this lane.

`fuzz_artifacts` is the resumability ledger for this lane: seeds, retained corpus inputs, generated symbolic testcases, queue checkpoints, dictionaries, state traces, coverage frontiers, and reproducers are content-addressed there (inline if small, sidecar if large). It is intentionally separate from `fuzz_runs`: `fuzz_runs` says *what ran*; `fuzz_artifacts` says *what to resume or replay*.

---

## 1. Mandatory-attempt discipline

DEEP **MUST** run this lane. It is not optional and not "best effort." Two legitimate end states only:

1. **Ran** — at least one selected entry point was harnessed and fuzzed under sanitizers/oracles; a `fuzz_runs` row records the config + coverage, `fuzz_artifacts` records resumable seeds/corpus/frontier/checkpoints, and any crashes, deterministic C/C++ leaks, or divergences are `fuzz_crash` / `fuzz_divergence` findings.
2. **Skipped-with-reason** — the target has no harnessable boundary for this lane, recorded as a `fuzz_runs` skip row (§ 6) whose `coverage_json` proves *why*. The orchestrator verifies the skip before accepting the lane as exhausted, exactly as it verifies bypass `exhaustion_log` (`bypass-catalogue.md` § 7).

The bar for skipping is **"there is no harnessable native/parser/FFI/protocol-session boundary with an oracle"**, never "fuzzing is hard here." A pure interpreted web app with no native extensions, no FFI, no in-process parser/decoder, and no feasible stateful protocol/workflow harness is a legitimate skip (`skip_reason='interpreted_only'` or `no_harnessable_state_oracle`); a Go service with a hand-rolled protocol decoder, or a WebSocket/protocol service with sample traces and response oracles, is **not**.

LOW and MEDIUM do not run this lane (LOW does no fan-out; MEDIUM's dynamic budget goes to PoC Proof). It is a DEEP escalation.

---

## 1a. Seed corpus feed-in from Phase 1.4

Before Phase 1.5 runs, **Phase 1.4 dual seed-corpus generation lanes**
(`llm_seed_corpus_lane_a`, `llm_seed_corpus_lane_b`) populate
`fuzz_artifacts(artifact_kind='seed_initial')` with LLM-synthesized seeds covering the
target's input-format families. The resume protocol (§ 6d) picks these up automatically:
fetch the newest `fuzz_artifacts` for `target_id + entry_point` before starting, and the
merged Phase 1.4 corpus is included. The **existing inline seed mechanism** (sample /
PCAP / OpenAPI sources, `seed_source='existing'`) still runs and is complementary — Phase
1.4 adds an LLM layer on top; it does not replace in-tree seeds.
See `references/v2/seed-corpus-generation-lane.md` for the Phase 1.4 lane spec.

A **third** Phase 1.4 lane also feeds this corpus: `fuzzgpt_history_lane` (history-driven
LLM fuzzing, FuzzGPT / arXiv:2304.02014 — `references/v2/fuzzgpt-history-lane.md` +
`references/methodology/fuzzgpt-history-driven-lane.md`) mines the target's *own bug
history* (gh issues/PRs/commits) into unusual edge-case programs and emits them as the same
`seed_initial` artifacts, so § 6d resumes them transparently alongside the dual seed-corpus
output. It also carries an in-lane **target-agnostic differential oracle** whose divergences
are quarantined as `gr_findings(finding_kind='differential_divergence', severity=NULL,
confirmation_status='unconfirmed')` and kept out of the severity rankings until triage shows
a security path — distinct from this lane's `fuzz_crash`/`fuzz_divergence` findings, which
are rated through Confirm here. The three Phase 1.4 lanes are complementary layers.

The FS/SF concolic hybrid in § 3a (coverage-stall escalation inside this lane) is a
distinct mechanism: it handles **coverage plateaus during the fuzz run itself**, whereas
`concolic_bypass_lane` (Phase 0.75, `references/methodology/cpp-java-concolic-bypass-lane.md`)
is a dedicated pre-break lane that uses constraint-solving to defeat a guard before any Hunt
agent spawns. The two are complementary, not duplicates.

---

## 2. Check for an existing pipeline FIRST

Before harnessing anything, recon what already exists — reusing a maintained corpus or OSS-Fuzz target is faster and higher-coverage than a cold harness. Record the result in `fuzz_runs.existing_pipeline` and set `reused_existing_pipeline = TRUE` when you build on it.

| Look for | Where |
|---|---|
| OSS-Fuzz integration | `oss-fuzz/projects/<name>/`, `.clusterfuzzlite/`, `Dockerfile` + `build.sh` with `$CFLAGS`/`$LIB_FUZZING_ENGINE` |
| In-tree fuzz targets | `fuzz/`, `test/fuzz/`, `*_fuzzer.cc` / `LLVMFuzzerTestOneInput`, Rust `fuzz/fuzz_targets/*.rs`, Go `func FuzzXxx(*testing.F)`, JVM `fuzzerTestOneInput` / `@FuzzTest` |
| Seed corpora & dictionaries | `corpus/`, `seeds/`, `testdata/`, `*.dict`, `*.options`, `go test` `testdata/fuzz/` |
| CI fuzz jobs | `.github/workflows/*fuzz*`, ClusterFuzzLite config, scheduled fuzz runs |

A reused corpus is a `seed_source='existing'` in `coverage_json`; a cold start is `seed_source='generated'`. If OSS-Fuzz already fuzzes this target continuously, the lane's value is targeting *the deltas* (patch-seed code, newly added parsers) rather than re-fuzzing covered ground.

---

## 3. Tooling matrix (engine + sanitizer per stack)

Pick the engine for the language and **always pair with sanitizers** — a fuzzer without a sanitizer only catches hard crashes, missing the silent corruption that ASan/UBSan/MSan turn into a clean abort.

For C/C++, **leak discovery is equal-priority with crash discovery** during fuzzing. Enable LSan wherever the target/toolchain supports it, keep leak detection on in reproducible runs, and do not discard leaks because they are non-crashing. A deterministic LSan report is a first-class fuzzing result: emit it as a `fuzz_crash` candidate, dedupe by leak stack/signature, store the reproducer and sanitizer report, and let Confirm decide reachability and promotion just as it does for crashes.

| Stack | Engine(s) | Sanitizers | Concolic / extra |
|---|---|---|---|
| **C / C++** | AFL++, libFuzzer, honggfuzz | ASan, UBSan, MSan (uninit reads), LSan (leaks); TSan for data races | KLEE, SymCC, SymQEMU for path-deep branches the fuzzer stalls on; use FS/SF handoff below |
| **Rust** | `cargo fuzz` (libFuzzer), AFL.rs | ASan on nightly; **Miri** for UB/aliasing in `unsafe` | — |
| **Go** | native `go test -fuzz`, go-fuzz/go-118-fuzz-build | `-race`; ASan/MSan via cgo when C is linked | — |
| **Java / JVM** | **Jazzer** (libFuzzer-backed) | Jazzer bug detectors (deserialization, SSRF, path traversal, OS-command, SQLi); **ASan/UBSan** on JNI/native via `--asan` | — |
| **Any with a grammar** | structure-aware fuzzing (libprotobuf-mutator, Jazzer `@FuzzTest` autofuzz), differential fuzzing against a reference impl | per stack | — |
| **Stateful protocol / workflow** | AFLNet/StateAFL-style greybox fuzzers, boofuzz/Peach/Sulley-style generators, custom harness over client/server library | per stack + protocol oracles | Active/passive state-machine learning, response-guided trace mutation |

Concolic execution (KLEE/SymCC) is the escalation when coverage plateaus: it solves path constraints the mutational fuzzer cannot reach. Use it on the stalled entry points, not as the primary engine.

### 3a. Munch-style hybrid coverage deepening (FS / SF)

Do not keep mutating blindly after a coverage plateau. Track **function coverage** and **call-graph depth coverage**, then hand off between fuzzing and symbolic execution:

- **FS hybrid (Fuzzing → Symbolic execution)** — use when seed inputs or sample traces exist. Fuzz first; compute functions not covered by the fuzzer; identify reachable **frontier nodes** at greater call-graph depth; run directed symbolic execution per target function with short per-function timeouts. A KLEE-style `sonar-search` terminates states that cannot reach the target and switches back to normal symbolic exploration after the target entry is reached.
- **SF hybrid (Symbolic execution → Fuzzing)** — use when seeds are missing or low-quality. Run bounded symbolic execution over the smallest viable symbolic argv/stdin/file inputs, then feed the generated tests to the fuzzer as a diverse seed corpus.
- **Budget gates** — record SMT solver query counts, per-target timeout, marginal function-coverage gain, and frontier nodes still uncovered. Escalate only where the fuzzer or symbolic executor is adding coverage; otherwise log the uncovered frontier as a reusable blind spot.
- **Harness gate** — normalize input style before starting: STDIN vs file vs argv, minimum symbolic buffer sizes, deterministic wrappers around `main`, and generated seed corpus paths. Combined argv+file formats often need a custom harness; skipping that work is a false skip.

The point is not KLEE/AFL specifically; it is the handoff discipline: cheap mutation covers easy functions, directed symbolic execution spends solver budget only on hard-to-reach function entry points, and symbolic test cases rescue seedless fuzzing.

---

## 4. What to fuzz — entry-point selection

The lane is **surface-driven**, not blind. Choose harness targets from what Hunt already mapped, preferring boundaries reachable from an untrusted `sources` row (so a crash maps to a real attack path for Confirm G1):

- Native/in-process **parsers, decoders, deserializers** (image/media/archive/protocol/format handlers).
- **Stateful protocol/session handlers** where an attacker controls a sequence of messages (network protocols, WebSockets, daemon control sockets, multi-step API workflows). Harness the library boundary when possible; avoid blind DAST-style probing.
- **FFI / JNI / cgo boundaries** — where memory-unsafe code is reachable from a managed runtime.
- The **`critical_functions` registry** — tier-1 parsers, canonicalizers, and validators are prime targets; a crash there is high-value and cascades (§ 7).
- **Patch-seed-adjacent code** (`sources.source_kind='patch_seed'`) — the variant-analysis surface; fuzz around the fix hunk for incomplete patches.

Anchor each harnessed entry point in `fuzz_runs.entry_point`. A crash whose entry point has no path from any real source still gets recorded, but Confirm will gate it at G1 (§ 7).

### 4a. Stateful systems: message + trace model

For stateful systems, the input is not one blob. Model it at two layers before mutation:

- **Message format** — the bytes/fields of one request, packet, event, or command.
- **Trace language** — the sequence of messages that drives protocol state.
- **State model / protocol state machine** — supplied by a spec, inferred from sample traces, or learned by active queries.
- **Abstraction functions** — map concrete messages to message types and responses to response classes/state labels (status code, error class, connection close, semantic response bucket).

Mutation must operate at both layers: bit/field mutations inside a message **and** trace mutations (`reorder`, `drop`, `repeat`, `insert`, `splice`, `replay`). Preserve dependencies that make the trace meaningful (session tokens, sequence numbers, length/checksum fields), but deliberately violate state transitions once the baseline valid trace is established.

Coverage for stateful targets includes:

- `states_covered` / `transitions_covered` / `response_classes_seen`
- deep authenticated and unauthenticated states reached
- spec/state-machine divergence (accepted invalid transition, rejected valid transition, client/server message confusion)
- response-guided feedback when instrumentation is unavailable

Responses can be useful as inputs: if client and server share message parsers, replaying a server-only response to the server can expose authentication/state-machine bugs (Libssh-style class confusion).

---

## 5. Sanitizer report → severity

The sanitizer's finding class sets the **preliminary** `gr_findings.severity`. Confirm still gates promotion — severity here is triage, not a verdict.

| Sanitizer signal | Preliminary severity |
|---|---|
| ASan heap-buffer-overflow (write), use-after-free, double-free | CRITICAL |
| ASan heap/global/stack-buffer-overflow (read), MSan uninit-read feeding a branch/addr | HIGH |
| UBSan: OOB index, type-confusion, invalid cast; integer overflow **feeding** an alloc/index | HIGH |
| UBSan: signed-overflow / alignment / misc with no memory-safety consequence | MEDIUM |
| LSan leak, pure assertion/`abort()` with no corruption | LOW |
| Jazzer logic detector (SSRF / path-traversal / command-injection / deserialization) | maps to the matching `sink_category`; severity per that bug class |

Dedup **before** counting: collapse crashing inputs by the sanitizer's dedup token (top-N frame signature / ASan dedup key) and LSan leak reports by leak stack/signature, so a corpus of 10k reports becomes the handful of distinct bugs. `fuzz_runs.crash_count` is **distinct bugs**, not raw crashing inputs; deterministic leak findings count here even when they do not hard-crash.

---

## 6. Recording: `gr_findings` (result) + `fuzz_runs` (run) + `fuzz_artifacts` (resume)

Both, every time. The crash/leak/divergence is a finding; the run is the accounting that proves the mandatory attempt.

Important: **do not store every attempted mutation by default**. For real fuzzers this can be millions of inputs and turns the audit DB into a slow packet capture. Store everything needed to resume and reproduce: initial seeds, generated symbolic seeds, retained coverage-increasing corpus entries, dictionaries, queue/checkpoint manifests, coverage frontiers, state traces, and distinct crash/divergence reproducers. Only store `attempted_input_sample` for short deterministic/isolation runs or when a debugging budget explicitly asks for full attempted-input capture.

### 6a. Each distinct crash or deterministic C/C++ leak → a `gr_findings` row event

```jsonc
{"kind": "gr_findings", "row": {
  "target_id": 1,
  "finding_kind": "fuzz_crash",
  "sink_id": null, "source_id": null,        // set when the crash maps to a known source/sink
  "agent_step_id": 88,
  "confirmation_status": "candidate",
  "config_state": "unknown",
  "severity": "CRITICAL",                     // from § 5
  "payload": {
    "evidence_path": "src/png/chunk.c", "evidence_line": 412,
    "crash_type": "heap-buffer-overflow-WRITE",
    "sanitizer": "asan",
    "dedup_token": "asan:png_read_chunk+0x1f/IDAT/__interceptor_memcpy",
    "stack_top": ["png_read_chunk", "png_handle_IDAT", "png_read_row"],
    "repro_input_b64": "…",                   // the crashing input (spills to sidecar if > 16 KB)
    "fuzz_run_id": 7,
    "trace_json": { /* sanitizer stack as a DAG, dag-reasoning.md shaped */ }
  }
}}
```

The crashing input is the **G4 reproduction artifact** — for a memory-safety crash, G4 is satisfied by construction (§ 7). Oversize inputs spill to `db/sidecars/<finding_hash>` per the schema's 16 KB rule (filename is the content hash only — never a caller-supplied path). `finding_hash` is derived by the orchestrator at flush; the agent never supplies it.

### 6b. The run → a `fuzz_runs` row event

```jsonc
{"kind": "fuzz_runs", "row": {
  "target_id": 1, "agent_step_id": 88,
  "entry_point": "png_read_chunk",
  "engine": "libfuzzer",
  "sanitizers": "[\"asan\",\"ubsan\"]",
  "reused_existing_pipeline": true,
  "existing_pipeline": "{\"oss_fuzz\":true,\"in_tree_targets\":[\"fuzz/png_fuzzer.cc\"],\"corpora_paths\":[\"corpus/png\"]}",
  "coverage_json": "{\"surface\":\"png parser\",\"attempted\":[\"IHDR\",\"IDAT\",\"tEXt\"],\"engine\":\"libfuzzer\",\"sanitizers\":[\"asan\",\"ubsan\"],\"edges\":18422,\"function_coverage_pct\":61.5,\"functions_covered\":120,\"uncovered_frontier\":[\"png_handle_iCCP\",\"png_handle_sPLT\"],\"runtime_s\":900,\"corpus_size\":1240,\"seed_source\":\"existing\",\"hybrid_mode\":\"FS\",\"artifact_ids\":[31,32]}",
  "crash_count": 2,
  "emitted_finding_ids": "[101,102]",
  "round_id": 3,
  "fuzz_run_hash": "<sha256 of target_id|entry_point|engine|sanitizers|round_id>"
}}
```

`emitted_finding_ids` links the run to the `gr_findings` it produced (parallels `defense_bypasses.cascade_emitted_finding_ids`), so a crash traces back to its run config and vice-versa.

### 6c. Skip-with-reason → a `fuzz_runs` skip row

```jsonc
{"kind": "fuzz_runs", "row": {
  "target_id": 1, "agent_step_id": 88,
  "entry_point": null,
  "engine": "none",
  "sanitizers": "[]",
  "skip_reason": "interpreted_only",
  "coverage_json": "{\"surface\":\"pure-PHP app, no native ext / FFI / in-process parser\",\"reason\":\"no native/parser/FFI boundary to harness\",\"checked\":[\"composer.json ext-*\",\"FFI usage grep\",\"bundled .so/.node\"]}",
  "fuzz_run_hash": "…"
}}
```

`skip_reason ∈ {no_native_code, no_parsers_or_ffi, interpreted_only, no_harnessable_entrypoint, no_stateful_protocol_surface, no_harnessable_state_oracle, env_unavailable, other}` (free TEXT — grows without a DuckDB CHECK rebuild). `coverage_json.checked` lists what recon ruled the surface out; the orchestrator verifies it before accepting the skip.

### 6d. Fuzz artifacts → resumable corpus/checkpoint rows

Every run that actually executes should persist at least one resumability artifact. Minimal rows:

```jsonc
{"kind": "fuzz_artifacts", "row": {
  "target_id": 1,
  "fuzz_run_id": 7,
  "agent_step_id": 88,
  "round_id": 3,
  "artifact_kind": "corpus_manifest",
  "label": "libfuzzer queue after 15m",
  "content_hash": "sha256:...",
  "payload": "{\"entries\":[{\"hash\":\"sha256:...\",\"kind\":\"seed_retained\"}],\"engine\":\"libfuzzer\",\"rng_seed\":1234}",
  "metadata_json": "{\"entry_point\":\"png_read_chunk\",\"coverage_edges\":18422,\"resume_priority\":0.91}",
  "parent_content_hash": null
}}
```

Canonical `artifact_kind` values:

| Kind | Store |
|---|---|
| `seed_initial` | user/sample/PCAP/OpenAPI-derived starting seeds |
| `seed_symbolic` | SF-mode symbolic testcases later fed to the fuzzer |
| `seed_retained` | coverage-increasing corpus entries kept by the engine |
| `seed_replay` | known-bad payloads replayed from bypasses/CVEs/prior rounds |
| `corpus_manifest` | list of retained seed hashes + engine/dictionary/RNG metadata |
| `queue_checkpoint` / `engine_state` | enough engine state to restart without cold-starting |
| `coverage_frontier` | uncovered functions, call-depth buckets, state/transition gaps |
| `state_trace` | stateful message trace with response/state abstraction labels |
| `dictionary` | fuzz dictionary or grammar fragments |
| `crash_reproducer` | minimized crashing/diverging input or trace |
| `attempted_input_sample` | optional sampled/full attempted inputs under an explicit budget |

Resume protocol: before fuzzing a boundary, fetch the newest `fuzz_artifacts` for the same `target_id + entry_point` (join through `fuzz_runs`) ordered by `round_id DESC, created_at DESC`, hydrate the retained corpus/checkpoint from inline payloads or sidecars, then continue from the stored frontier. A cold start is only acceptable when no relevant artifact exists or the prior artifact is incompatible with the current build/config.

---

## 7. Handoff into Confirm (Phase 2) — fuzz crashes are not auto-confirmed

A `fuzz_crash` is a **candidate**, not a confirmed vuln. It enters the five-gate doctrine like any other finding:

- **G1 taint reach** — is the crashing entry point reachable from a real untrusted `sources` row in the deployed app, or only from the synthetic fuzz harness? A crash reachable only through the harness's direct entry, with no path from any real source, is **refuted** (`refutation_reason='not_reachable'`). This is the gate that separates real bugs from harness artifacts.
- **G2 defense gap** — does a Tier-1/Tier-2 defense on the real path neutralize the malicious input before it reaches the crashing code? Consult the Phase 0.75 defeated-defense set (`bypass-catalogue.md`).
- **G3 intended-feature filter** — is the crash in test-only / debug / developer-tool code not shipped to production? Filter via `intended_feature_classification`.
- **G4 reproduction artifact** — **satisfied by construction** for memory-safety crashes: the crashing input + sanitizer report *is* the artifact. Phase 4 Proof packages it (`config_state` recorded) rather than re-deriving it; a memory-safety crash with a deterministic repro input needs no separate PoC build beyond running it against the production-equivalent target.

**Cascade-on-critical-function.** A crash inside a `critical_functions` row (matched by `symbol_path` / `evidence_path`) raises that function's `factor_bypass_prior`-equivalent attention and re-ranks it this round — the same cascade mechanism reproduced bypasses use (`critical-function-hunt.md` § 5). A tier-1 parser that crashes under fuzzing is a strong signal to deepen its data-flow lanes.

---

## 8. Coverage contract (orchestrator-verifiable, DB-gated)

`fuzz_runs.coverage_json` is the fuzzing analogue of the bypass exhaustion log. The contract is **maximize coverage and prove it** — so a ran row must record both *how much* it covered and *what it did not reach*.

Required keys on a **ran** row:
- `surface`, `attempted[]` (selected entry points / formats / chunk types), `engine`, `sanitizers[]`, `runtime_s`, `seed_source` (`existing`|`generated`|`resumed`|`replay`), and `artifact_ids[]` linking to the `fuzz_artifacts` rows that make the run resumable.
- **A coverage measurement** — at least one of `edges`, `blocks`, or `function_coverage_pct`. This is the *how much*. `edges`/`blocks` is the universal relative-progress signal every coverage-guided engine emits; `function_coverage_pct` (+ `functions_covered`) is the true code-coverage signal and is **strongly preferred** wherever the engine's instrumentation can produce it.
- **`uncovered_frontier[]`** — the reachable functions / call-graph-depth buckets / protocol states the run did **not** cover. This is the *what's left*, and it is load-bearing: it is the proof you measured the gap, and it is the worklist that feeds the next round (each entry is emitted as a reusable `agent_observations(obs_kind='blind_spot')` and resumed via `fuzz_artifacts(artifact_kind='coverage_frontier')`, § 6d). An empty `uncovered_frontier[]` is a positive claim (coverage saturated — see § 8a), not a default.

Strongly recommended keys when available: `call_depth_buckets`, `hybrid_mode` (`none`|`FS`|`SF`), `smt_queries`, `symbolic_targets[]`, `state_model_source`, `message_types[]`, `states_covered`, `transitions_covered`, `response_classes_seen`, `oracles[]` (§ 10). On a **skip** row: `surface`, `reason`, `checked[]`.

**Enforcement is no longer prose-only — two count-free DB gates back it** (the dynamic mirror of the static `slices_without_codebase_coverage` gate; both in `db/schema.sql` `v_coverage`):

| `v_coverage` metric | RED when |
|---|---|
| `fuzz_runs_without_coverage_measurement` | a `fuzz_runs` row that **ran** (`skip_reason IS NULL`) records **no** coverage measurement in `coverage_json` (none of `edges`/`blocks`/`function_coverage`) — a fuzz run executed but never measured coverage |
| `fuzz_skips_unrecorded` | a `boundary_fuzz_lane` `agent_step` that ran or was documented-skipped emitted **no** `fuzz_runs` row at all — the mandatory attempt left no accounting |

Beyond the gates, the orchestrator still rejects a lane claiming completion whose ran `coverage_json` lacks `uncovered_frontier[]` or `artifact_ids[]`, or whose skip `checked[]` doesn't substantiate `skip_reason`, rewriting the step to `failed` / `termination_reason='incomplete_fuzz_coverage'` — mirroring `bypass-catalogue.md` § 7.

**Read the coverage back with `v_fuzz_coverage`** — the read-time per-run rollup (the dynamic analogue of `v_cpg_slice_coverage`): it extracts `edges` / `function_coverage_pct` / `functions_covered` / `uncovered_frontier_n` from each ran row's `coverage_json` (never a stored column) and orders by `(target_id, round_id, entry_point)`, so the **round-over-round coverage trend** — *did coverage actually grow this round?* — is one query. As with the slice-coverage view there is **no percentage floor**: coverage is selective by design, so a low % is *inspected* here, never auto-failed. The gates enforce that coverage was *measured and accounted*, not how high it must be.

### 8a. Saturation / stopping criterion (no magic floor)

"Maximize coverage" needs a *stop* rule, but a hard `function_coverage_pct ≥ N` floor would be a magic constant and is wrong for selective, surface-driven fuzzing. The criterion is **behavioural, not numeric** — a ran row is coverage-complete only when:

1. **Plateau reached** — new edges/blocks and corpus growth have flat-lined for the configured budget (`run_config` per-entry-point exec/time budget). Record the plateau (`edges`/`runtime_s` at the knee) in `coverage_json`.
2. **Escalation exhausted** — the FS/SF concolic hybrid (§ 3a) has been *attempted* on the stalled frontier nodes, not just considered. If symbolic execution is unavailable for the stack, that is recorded, not silently skipped.
3. **Frontier logged + fed forward** — whatever remains uncovered after (1)+(2) is enumerated in `uncovered_frontier[]` and carried to the next round as `blind_spot` observations + a `coverage_frontier` artifact.

A run that stops before (1) without exhausting its budget is an incomplete run, not a saturated one; a run that claims `uncovered_frontier: []` asserts genuine saturation. The next round resumes from the stored frontier (§ 6d) and pushes coverage further — coverage maximization is **across rounds**, monotonic via the carried frontier, which is exactly what `v_fuzz_coverage` ordered by `round_id` makes auditable.

---

## 9. Why a distinct modality (and why it is not DAST)

- **Ground-truth artifacts SAST can't produce.** A sanitizer-backed crash is a reproduction, not an inference — it pre-satisfies G4 and resolves the "is this real?" question that static traces leave open.
- **Memory-safety coverage.** SAST under-finds heap/UAF/overflow bugs in native code; a fuzzer + ASan is the right tool for that bug class.
- **Not a black-box web scanner.** This lane is *targeted, in-process, coverage-guided* fuzzing of specific entry points under sanitizers — complementary to the SAST hunt, sharing its source/sink/critical-function map. It is categorically different from the DAST web scanners the pipeline excludes (`vuln-swarm.md` Handoff): those probe a running web app blindly; this drives known code boundaries with instrumentation.

---

## 10. Beyond raw crashes — replay, differential, property, state (Tier 3 oracles)

Coverage-guided mutation with a sanitizer only catches what the sanitizer flags. Four cheaper, higher-signal oracles run **inside the same harness** and record through the same `fuzz_runs` + `gr_findings` path — they widen the lane from "did it segfault" into logic-divergence and known-bad-input discovery. Record which ran in `coverage_json.oracles[]` (`sanitizer` | `replay` | `differential` | `property` | `state_model`).

- **Replay-the-payload.** Before (and alongside) blind mutation, seed the harness with *known-bad inputs* and replay them: the reproduced payloads from `defense_bypasses` (this run and prior rounds via `carried_from_bypass_id`), public CVE PoCs for the same component/version, and the format's classic malformed corpora. This is the cheapest variant analysis there is — it re-tests whether a documented attack still lands at *this* boundary. A replay that crashes/diverges is still a `fuzz_crash` finding; tag `coverage_json.seed_source='replay'` and reference the originating `bypass_id` / CVE in the finding payload so Confirm can short-circuit G1 (the source path is already known).
- **Differential testing.** Run the same input through **two implementations** and treat divergence as the oracle — patched vs. unpatched (the `sources.source_kind='patch_seed'` surface, § 4), the target vs. a reference parser, or two endpoints that must agree. Divergence finds logic bugs no sanitizer sees: parser-confusion / request-smuggling, canonicalization mismatches, incomplete-fix regressions. Record as `gr_findings.finding_kind='fuzz_divergence'` (free TEXT, no enum change) with both outputs in the payload; severity follows the resulting `sink_category`, not the crash table (§ 5).
- **Property / invariant testing.** Give the fuzzer an oracle beyond crashing by asserting invariants in-harness: round-trip identity (`decode(encode(x)) == x`), idempotent canonicalization, bounds the code claims to enforce, "validator output is always safe for the sink." A violated invariant is a `fuzz_crash` (assertion abort) whose payload names the broken property. Property fuzzing is what turns a tier-1 `validator_sanitizer` or `parser_decoder` (§ 4) crash into a *logic* finding rather than just a memory one.
- **State-model divergence.** For stateful targets, assert the expected protocol state machine: invalid transitions should fail consistently, valid transitions should not be rejected only after a weird prefix, and auth-only messages must not be accepted pre-auth. A divergence records as `finding_kind='fuzz_divergence'` with `trace[]`, `expected_state`, `observed_response`, and the abstraction function used.

All four still funnel through the five-gate Confirm (§ 7): a divergence or invariant break is a **candidate**, gated on a real source path (G1) and a real deployment (G3) like any other finding. They are oracles, not verdicts.
