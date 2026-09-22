# Tool-Integration Matrix (CPG / SAST / AST Tooling)

> **Load when**: Load during Phase L3.5 when a DEEP-tier swarm or any audit with a mechanical pre-pass is available; skip for LOW-tier or pure-LLM audits.

For DEEP-tier Swarm Pipeline runs and any audit where a mechanical pre-pass is available, select in priority order:

| Priority | Tool | Representation | When to use |
|----------|------|----------------|-------------|
| 1 | **Joern** | Code Property Graph (AST + CFG + DFG + call graph) | Full inter-procedural taint, PDG cuts, call-chain slicing. Best when a queryable graph justifies indexing cost (large C/C++/Java/JS/Python targets). |
| 2 | **CodeQL** | Relational AST + dataflow library | Path queries from stdlib sources to sinks. SARIF output. Use when a pre-built query pack matches the stack. |
| 3 | **Semgrep + ast-grep** | Semantic patterns (Semgrep) + structural AST matching (ast-grep) | Cheapest rule-writing path. Semgrep for dataflow-aware rules; ast-grep for language-agnostic structural hunts. |
| 4 | **Fallback: `sinks/<lang>.md` grep** | Plain text | No CPG/SAST tooling available — the per-language sink files are ripgrep-ready. |

**Why CPG over AST-first:** Raw AST lacks the security-relevant edges — data dependencies, control dependencies, call targets, aliasing. A CPG merges all four, which means one query answers "does untrusted input reach this sink under these guards?" without re-implementing dataflow per rule. See `../methodology/swarm-pipeline.md` § Slice Types for the 11 slice cuts the tooling can emit.

**Prefer graph-discovered paths over name lists (anti-brittleness).** Sink catalogs are necessary but not sufficient — custom wrappers and refactoring-noisy patch-diffs defeat name-based criterion selection. Let the CPG's `execution_path` slice (`reachableByFlows`) be the primary criterion, with the sink catalog as one seed among several. Doctrine + the LLMxCPG (`arXiv:2507.16585`) execution-path-first construction: `../methodology/joern-forward-slicing.md` §§ 7–9 and `../methodology/llmxcpg.md`.

Outputs from layers 1–3 are packaged as SecuritySlice input packets (see `../methodology/dag-reasoning.md` § SecuritySlice Input Packet) for LLM consumption. LLM agents treat tool hits as **hypotheses to verify**, never as findings to rubber-stamp.

## Optional function-context retrieval strategy (LLM agent scaffold)

VulnLLM-R's useful lesson for the skill is not model training; it is the scaffold. Treat this as an **additional strategy** for selected targets, not the default posture for every audit: when a function/sink candidate is high-value or ambiguous, make the LLM judge that **target function** with minimal, tool-retrieved **project context** instead of dumping a repository or asking for pattern matching.

When the function-context strategy is selected for a target function or sink candidate:

1. **Select the target** — function touched by a patch seed, reachable from an untrusted source, listed in `critical_functions`, hit by CodeQL/Joern/Semgrep, or sitting on a high attention-deficit surface.
2. **Retrieve context** — use Joern/CodeQL/LSP to fetch direct callers/callees, 1–3 sampled call paths from entrypoints to the target, security helpers (auth checks, validators, canonicalizers), and adjacent tests/config gates. Mark every retrieved item as `target_function` or `context_function`.
3. **Gate sufficiency before judgment** — if the packet cannot answer controllability, data-flow reach, guard behavior, or deployment/config state, emit `context_insufficient` + exact missing symbols instead of guessing.
4. **Narrow the policy** — derive 2–5 plausible CWE candidates from the slice, then force final judgment to choose one of those or `benign`. This prevents broad CWE fishing while still allowing a clear no-bug result.
5. **Summarize reasoning** — final output keeps only source→transform→guard→sink facts, CWE decision, and missing context. Long free-form chain text is noise unless it names evidence.

Persist the context packet in DuckDB before delegating judgment: use `agent_observations(obs_kind='tool_output', symbol_path=<target_function>, reusable=true)` for the packet body (sidecar if >16 KB), and link any scheduled analysis through `agent_steps.coverage_json` / `input_slices` ids. Later agents fetch the packet by `target_id + symbol_path + obs_kind='tool_output'` rather than re-running CPG/CodeQL/LSP unless the packet is stale or marked `context_insufficient`.

## Dynamic companions: fuzzing and symbolic execution

The static priority table feeds Phase 1 Hunt. Phase 1.5 uses dynamic tools from `../v2/fuzzing-lane.md` and should hand DB rows back to this matrix as slices/priors:

- **Munch-style FS hybrid** — when seed inputs exist, fuzz first to cover easy functions, compute uncovered function/call-depth frontier nodes, then run directed symbolic execution (KLEE/SymCC/angr equivalent) against only those targets.
- **Munch-style SF hybrid** — when seed inputs are missing, run bounded symbolic execution over minimal symbolic argv/stdin/file inputs, then use generated test cases as seeds for AFL++/libFuzzer/honggfuzz.
- **Stateful systems** — treat inputs as messages and traces; use protocol-aware fuzzers or harnesses where available, and let response/state abstractions guide coverage even without instrumentation.

Record dynamic coverage in `fuzz_runs.coverage_json` (functions, call-depth buckets, frontier nodes, states/transitions when applicable), persist resumable corpus/checkpoint/frontier data in `fuzz_artifacts`, and feed new uncovered frontier nodes back into `critical_functions` / `input_slices` rather than continuing blind mutation indefinitely.

**Turning tool output into DuckDB rows.** This matrix is *which tool, in what priority*. For the **exact run command + output parse + serialization into `gr_findings` / `sinks` / `input_slices` candidate row events** — plus cross-tool dedup and the coverage-computed-from-tool-output contract — see `../methodology/tool-ingest-recipes.md` (the priority-2/3 recipe). The Joern layer (priority 1) has its own cookbook in `../methodology/joern-forward-slicing.md`. Every ingested hit lands at `confirmation_status='candidate'` and earns promotion only through the five-gate Confirm (`../v2/confirmation-rigor-doctrine.md`).
