# Forward-Slicing Lanes (C2)

> Operational guidance for the swarm when spawning a slice lane and the orchestrator when scheduling them. Companion docs: `references/methodology/joern-forward-slicing.md` (CPGQL recipes, coverage, negative-space query), `references/methodology/llmxcpg.md` (execution-path-first slicing integration).

A **lane** is a swarm agent that traces taint or defense callsites across a precomputed slice. Each lane operates on one `input_slices` row and writes one `agent_steps` row.

## Slice Tuple

Every slice is materialized in `input_slices` as a tuple:

```
(target_id, source_id, critical_fn_id, callee_set_hash, slice_kind, callee_count, representative_callees)
```

`source_id` anchors source-driven slices and is NULL for a pure `critical_fn_forward` slice; `critical_fn_id` anchors a critical-function-driven slice (FK → `critical_functions.id`) and is NULL for source/sink/defense slices. Exactly one of the two is set per slice — the `slice_kind` discriminator says which.

The natural key `(target_id, callee_set_hash, slice_kind)` makes slice creation idempotent — re-running Phase 0.5 over the same `commit_sha` updates rather than duplicates.

### `slice_kind` discriminator

| Value | Direction | Anchor | Consumer strategies |
|---|---|---|---|
| `forward_taint` | source → sink | `sources.id` | `forward_slice_lane` |
| `backward_sink` | sink → source | `sinks.id` (anchor reused into `representative_callees`) | `backward_sink_lane` |
| `defense_callsite` | callers of catalogued defenses | `defenses.id` (anchor encoded in slice's callee set) | `defense_base_lane`, `defense_context_verification_lane`, cascade-on-bypass |
| `critical_fn_forward` | critical function → downstream effects/sinks | `critical_functions.id` (via `input_slices.critical_fn_id`) | `critical_function_dataflow_lane` |
| `execution_path` | source → sink, refined via interacters + path-union backward slice (LLMxCPG) | `sources.id` (source-anchored) | `forward_slice_lane` |

The discriminator is the load-bearing routing key — the same `(target_id, source_id)` pair can have multiple slices (one per kind) coexisting.

The `execution_path` kind is the LLMxCPG (`arXiv:2507.16585`; repo: https://github.com/qcri/llmxcpg) construction — `source → sink` flow, refined by **interacters** (identifiers sharing a line with path nodes) and a **path-union backward slice** (`reachableByFlows(cpg.all)`) into a focused snippet. It is produced **within the existing `forward_slice_lane`** — **not** a new lane, so `v_required_deep_lanes` and the completion gate are unchanged. Copy-paste recipe: `references/methodology/joern-forward-slicing.md` § 7; integration summary: `references/methodology/llmxcpg.md`.

## Critical-Function Data-Flow (two directions)

The `critical_function_dataflow_lane` traces taint in **both** directions around a ranked `critical_functions` row (see `references/v2/critical-function-hunt.md` for how the registry is built and ranked):

1. **Source → critical function** (reachability). For every attacker-controllable source, does taint reach the critical function? This is recorded **not** as a slice but as a `critical_fn_reach` row `(critical_fn_id, source_id, slice_id, reach_status ∈ {reaches, blocked, unproven}, hop_count, guard_path_json)`. The optional `slice_id` back-links the `forward_taint` slice that proved the reach. This feeds `critical_functions.factor_reachability` + `source_reachable`.
2. **Critical function → downstream** (blast radius). From the critical function's outputs, what dangerous effects/sinks does it feed? Each flow is one `input_slices` row with `slice_kind = 'critical_fn_forward'` and `critical_fn_id` set.

Copy-paste CPGQL for both directions, the reach-status verdict table, and the SecuritySlice serialization live in **`references/methodology/joern-forward-slicing.md`** §§ 2–3, 6. Tier gating (tier1 = both directions, tier2 = downstream only, tier3 = recorded-not-sliced) is in critical-function-hunt.md § 3.

## Lane Lifecycle

```
spawn ──► running ──► success
            │  │
            │  └────► exhausted
            │
            └───────► failed | timed_out
```

Status transitions are written to `agent_steps.status`. Allowed values: `running`, `success`, `exhausted`, `failed`, `timed_out`. The `termination_reason` column captures the human-readable cause; `coverage_json` carries the per-stage coverage report.

### Required spawn invariants

When the orchestrator spawns a lane, it writes:

```sql
INSERT INTO agent_steps (
  target_id, strategy_id, slice_id, defense_id, parent_step_id,
  started_at, status, step_hash
)
VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, 'running', ?);
```

- `strategy_id` references one of the allowed `strategies.name` enum values (see schema § 2.3 strategies CHECK + the seed at `db/seed/strategies.yml`).
- `slice_id` is mandatory for taint/defense lanes; `defense_id` is populated only when the lane targets a specific defense.
- `parent_step_id` is set when this lane was cascaded from another step (e.g., cascade-on-bypass from a `defense_bypasses` row).
- `step_hash` is computed over `(strategy_id, slice_id, defense_id, parent_step_id)` so re-spawn is idempotent.

## Coverage Report Shape

Every lane MUST emit a `coverage_json` before terminating. Shape varies by lane kind, but each MUST include:

- `callees_visited`: integer count of slice callees actually examined.
- `max_depth_reached`: integer hop count from anchor.
- `deferred_edges`: list of `{symbol_path, reason}` pairs for edges not traversed (e.g., dynamic dispatch, missing source).

S2 bypass lanes additionally include the three-stage corpus coverage block — see `references/v2/bypass-catalogue.md` § 3 (Coverage Contract). `critical_function_dataflow_lane` derives all three keys directly from the CPG (`callees_visited` = forward-closure size, `deferred_edges` = unresolved/external calls) — see `references/methodology/joern-forward-slicing.md` § 5.

That per-lane `coverage_json` is *local* — it measures one slice. It does **not** measure how much of the codebase the slices *together* touched (see Slice-end coverage, below).

## Slice-end coverage

Per-lane `coverage_json` is per-slice; `v_lane_coverage` is per-lane. Neither measures the union. When the Hunt's slicing lanes finish for a `(target, round)`, the orchestrator runs the **non-mandatory `cpg_coverage` strategy** (id 16 — deliberately **not** in `v_required_deep_lanes`) once, over the union of every slice's nodes, and writes one `cpg_slice_coverage` row:

- **raw** ratio = covered ÷ first-party methods (the literal "% on codebase"); **frontier** ratio = covered ÷ (attacker-reachable ∪ sink-bearing ∪ critical-function methods) — the bug-finding signal.
- Percentages are **computed read-time** by `v_cpg_slice_coverage`, never stored.
- Each **uncovered frontier** method is emitted as a reusable `agent_observations(obs_kind='blind_spot')` anchored on `symbol_path`, so the next round (round feed-forward) slices it first.
- Enforcement = the count-free gate `v_coverage.slices_without_codebase_coverage` (slices exist but no coverage row ⇒ RED). **No percentage floor** — a low % is inspected, not auto-failed (slicing is selective by design).

Because the union must come from the slices' full node sets and `input_slices.representative_callees` is truncated, this is measured in Joern (or a run-scoped accumulator), not derived from stored rows. Recipe: `references/methodology/joern-forward-slicing.md` § 10; schema: `db/migrations/0017-cpg-slice-coverage.sql`.

## Cascade Semantics

When a HIGH-severity `defense_bypasses` row lands, the orchestrator auto-schedules cascade lanes:

1. **Cascade-on-bypass** — for every callsite of the broken defense (enumerated via `slice_kind = 'defense_callsite'` slices), spawn a `forward_slice_lane` with `parent_step_id = <bypass step id>`.
2. **Cascade-on-reach** — when a forward-slicing lane closes `bypass → source → sink` (or a `critical_fn_forward` closure reaches a dangerous sink), the orchestrator promotes the chain to Phase 4 (proof collection) by inserting an `agent_steps` row pointing back at the originating bypass step.
3. **Cascade-on-critical-function** — when the broken defense maps to a `critical_functions` row (via `critical_functions.defense_id` or `symbol_path`), the orchestrator raises that CF's `factor_bypass_prior`, recomputes `rank_score`, and — if the CF crosses a tier boundary — re-plans its data-flow lanes **this round** (a tier2→tier1 promotion adds the source→CF `critical_fn_reach` direction it previously skipped). The `defense_bypasses` row records the emitted IDs in `cascade_emitted_finding_ids` / `cascade_emitted_source_ids`. See `references/v2/critical-function-hunt.md` § 5 and `references/v2/bypass-catalogue.md` § Cascade.

Both cascades fire at orchestrator flush time (post-phase) to preserve the single-writer invariant. Lanes never spawn lanes directly — they queue an intent that the orchestrator consumes. Cross-round propagation of `factor_bypass_prior` (so next round starts where this round's bypass landed) is in `references/v2/round-feedforward.md`.

## Promising-lane side-output

If a slice surfaces a **promising lane** — a concrete new investigation direction worth a dedicated lane next round (e.g. a custom template engine → SSTI-fuzz, a hand-rolled deserializer → object-injection) — emit a `promising_lanes` row event. It is **feed-forward only** (the next round picks it up via `v_promising_lanes_ranked`), non-mandatory, and never chased in this run. See `references/v2/pipeline-architecture.md` (Promising-Lane Feed-Forward).

## Termination Contract

A lane MAY NOT mark itself `success` without producing a downstream artifact (`gr_findings`, `refutations`, or `defense_bypasses` row). A lane MAY NOT mark itself `exhausted` without writing the full coverage report demonstrating that every applicable corpus family / callee was attempted.

The orchestrator verifies these contracts at flush time:
- `success` lanes whose flush yielded zero artifact rows are rewritten to `failed` with `termination_reason = 'success_without_artifact'`.
- `exhausted` lanes whose `coverage_json` is missing required keys are rewritten to `failed` with `termination_reason = 'incomplete_coverage'`.
