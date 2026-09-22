# LLMxCPG — CPG + LLM Vulnerability Detection (integration map)

> What the **LLMxCPG** paper (`arXiv:2507.16585`; repo: https://github.com/qcri/llmxcpg) contributes to this skill, and where each of its ideas already lives or newly lands. This is a **delta integration**: the skill already does Joern/CPGQL slicing, forward/backward slices, focused SecuritySlice packing, and source→sink taint. Only the genuine deltas (execution-path-first slicing, the query-gen feedback loop, the anti-brittleness doctrine, and CWE-reliability calibration) are new.
>
> Companion docs: `references/methodology/joern-forward-slicing.md` (the copy-paste CPGQL recipe), `references/methodology/forward-slicing-lanes.md` (lane wiring + the `execution_path` discriminator).

LLMxCPG is **methodology, not a model we ship.** The paper fine-tunes two models; this skill realizes the same behavior as agent scaffolding — no Qwen/QwQ fine-tuning, no vLLM/Unsloth inference.

---

## 1. What LLMxCPG is

LLMxCPG (Lekssays, Mouhcine, Tran, Yu, Khalil; QCRI/NJIT/MBZUAI; July 2025) couples **Code Property Graphs** with **LLMs** for robust, function-level-and-beyond vulnerability detection. Two fine-tuned models in the paper:

- **LLMxCPG-Q** (Qwen2.5-Coder-32B) — generates **CPGQL** queries that locate vulnerable **execution paths** in a Joern CPG.
- **LLMxCPG-D** (QwQ-32B) — classifies the resulting focused slice **Vulnerable / Safe**.

The reusable core is **execution-path-first slice construction**: instead of feeding a whole function to the classifier, find the `source → sink` path first (`sink.reachableByFlows(source)`), enrich it with **interacters** (identifiers sharing a line with path nodes), then take a PDG-backed **path-union backward slice** (`(path ∪ interacters).reachableByFlows(cpg.all)`). The output is a *focused snippet* the paper reports as **68–91% smaller** than the enclosing function(s), which is both cheaper to reason over and more robust to semantic-preserving syntactic transforms.

Supporting ideas the skill adopts: a **bounded query-generation feedback loop** (generate → run → feed Joern's error back → retry ≤ 3), a per-dataset **confidence-threshold (γ)** calibrated on a small labeled set, a **memory-safety / taint CWE scope** (excludes runtime-dependent classes like races), and a **contamination-free evaluation set** (the paper's PKCO-25).

## 2. Concept map — LLMxCPG concept → vuln-research artifact

| LLMxCPG concept | vuln-research artifact |
|---|---|
| Joern + CPGQL slicing | `references/methodology/joern-forward-slicing.md` |
| forward / backward slices | `references/methodology/forward-slicing-lanes.md` (`forward_taint` / `backward_sink` / `critical_fn_forward`) |
| focused packed snippet | **SecuritySlice** (`input_slices` row + SecuritySlice input packet) |
| execution-path-first + interacters | **this integration** → `slice_kind = 'execution_path'`, produced within `forward_slice_lane` |
| CPGQL query-gen feedback loop | **`query_attempts`** table (status / `joern_error` / `attempt_no`) — see joern-forward-slicing.md § 8 |
| source → sink taint | Phase L4 `references/phases/taint-analysis.md` + `forward_slice_lane` |
| γ confidence-threshold calibration | **externalized scoring config** (`db/seed/scoring.yml` key `eval.gamma_threshold`), never a magic constant |
| PKCO contamination-aware eval | the **`vreval`** corpus (sample-provenance / knowledge-cutoff metadata) |

## 3. Execution-path-first slicing (the C1 delta, in brief)

Three steps, in full detail in `references/methodology/joern-forward-slicing.md` § 7:

1. **Path extraction** — `val execution_paths = sink.reachableByFlows(source)`.
2. **Interacters** — identifiers whose line number matches an execution-path line (`cpg.identifier.filter(id => execution_path_nodes.lineNumber.toSet.intersect(id.lineNumber.l.toSet).size.equals(1))`).
3. **Path-union backward slice** — `(execution_path_nodes ++ interacters).reachableByFlows(cpg.all)` → the focused snippet.

The snippet is serialized as an `input_slices` row with `slice_kind = 'execution_path'`, **source-anchored** (`source_id` set, `critical_fn_id` NULL). It is emitted by the **existing** `forward_slice_lane` — no new mandatory lane, `v_required_deep_lanes` unchanged.

**Codebase slice-coverage (vuln-research delta, built on top).** The paper measures each slice's *size reduction* (68–91% smaller than the enclosing function). The complementary question — *how much of the codebase did the UNION of all slices touch* — is answered when the slicing lanes end by the non-mandatory `cpg_coverage` step: a **raw** ratio (first-party methods) and a **frontier** ratio (attacker-reachable ∪ sink-bearing ∪ critical-function methods, the bug-finding signal). It persists one `cpg_slice_coverage` row (counts only; `v_cpg_slice_coverage` computes the %), emits each uncovered frontier method as a reusable `blind_spot` observation that the next round slices first, and is enforced by the count-free gate `v_coverage.slices_without_codebase_coverage` (no percentage floor). Recipe: `references/methodology/joern-forward-slicing.md` § 10; schema: `db/migrations/0017-cpg-slice-coverage.sql`.

## 4. Query-generation feedback loop (the C2 delta, in brief)

An agent generates a CPGQL query, runs it on the Joern server, and on a syntax error or empty result feeds the Joern error back and regenerates — up to **3** attempts; otherwise the attempt is recorded as a `dead_end`. Every attempt is persisted to the **`query_attempts`** table (`status ∈ {valid, syntax_error, empty}`, `joern_error`, `attempt_no`) so the dead queries are visible to later rounds. Full sub-procedure: joern-forward-slicing.md § 8.

## 5. Anti-brittleness doctrine (the C3 delta, in brief)

Sink catalogs / predefined dangerous-function lists are **necessary but not sufficient**: custom wrappers around a dangerous function defeat name-based matching, and selecting criterion points from patch-diffs is unreliable (refactoring noise). Prefer **graph-discovered execution paths** (`reachableByFlows`) as the primary criterion, with the sink catalog as one seed among several. Full doctrine: joern-forward-slicing.md § 9; cross-refs in `references/sinks-catalog.md` and `references/phases/tool-integration-matrix.md`.

## 6. CWE-reliability calibration note (C4, doc-only)

CPG-static slicing is **not equally reliable for every CWE**. It is a strong signal where the bug is a property of the data/control graph, and a weak signal where the bug only exists at runtime.

| CWE class | Examples | CPG-slice reliability | Trust instead |
|---|---|---|---|
| **Taint / injection** | CWE-89 (SQLi), CWE-78 (CMDi), CWE-79 (XSS), CWE-918 (SSRF), CWE-22 (path traversal), CWE-502 (deserialization), CWE-94 (code injection), CWE-611 (XXE) | **Reliable** — source→sink dataflow IS the path property; this is the canonical `reachableByFlows` case | CPG `execution_path` or `forward_taint` slice |
| Memory-safety / buffer | CWE-119, CWE-120, CWE-121, CWE-122, CWE-125, CWE-787 | **Reliable** — bounds/length flow is on the graph | CPG `execution_path` slice |
| Integer overflow | CWE-190 | **Reliable** — arithmetic on tainted size is a path property | CPG `execution_path` slice |
| Lifetime / aliasing | CWE-415 (double-free), CWE-416 (use-after-free) | **Reliable** — alloc/free ordering is on the PDG | CPG `execution_path` slice |
| **Logic / business-flow / authz** | CWE-285 (improper authz), CWE-639 (IDOR / BOLA), CWE-863 (incorrect authz), CWE-841 (improper enforcement of behavioral workflow) | **NOT reliable** — the bug is the *absence* of a guard on a path, not taint flow; `reachableByFlows` is a positive-flow engine and cannot model "guard not called" (see joern-forward-slicing.md § 3b) | the **negative-space query** (§ 3b in joern-forward-slicing.md) + manual auth-check-slice review |
| Race / runtime-dependent | CWE-362 (and other concurrency / TOCTOU timing classes) | **NOT reliable** — the bug is a scheduling/interleaving property the static graph does not encode | the **dynamic lanes** (`boundary_fuzz_lane` with `-race`/TSan, concolic), not CPG slices |

Practical rule: for taint-style and memory-safety CWEs, an `execution_path` slice closing is strong evidence. For authz/logic bugs, a clean CPG slice is **inconclusive** — the bug may be the missing guard, not a tainted value. For race / runtime-dependent classes, a clean slice is also **inconclusive**; defer to dynamic evidence. This note is **doc-only** — it is not a schema table.

## 7. Citation

LLMxCPG: *Robust Vulnerability Detection by Coupling Code Property Graphs and Large Language Models.* Ahmed Lekssays, Hamza Mouhcine, Khang Tran, Ting Yu, Issa Khalil. QCRI / NJIT / MBZUAI, July 2025. `arXiv:2507.16585`. Code: https://github.com/qcri/llmxcpg.
