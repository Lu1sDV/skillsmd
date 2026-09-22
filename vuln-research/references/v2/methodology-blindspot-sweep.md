# Methodology Blind-Spot Sweep (Phase 1.6, DEEP)

> The post-Hunt meta pass. After **all discovery sweeps** finish for a `(target, round)`, two identical, independent agents critique *our own methodology* and the prior phases' coverage, merge their output, and hand the merged directions to the **next round**. Source of truth: `db/schema.sql` (`methodology_blind_spots` table + `v_methodology_blindspots_ranked`) + `db/migrations/0018-methodology-blindspot-sweep.sql` + this doc. Companion: [`round-feedforward.md`](round-feedforward.md) (fetch (8) — how the next round consumes these) and [`db-logging-and-context.md`](db-logging-and-context.md) (the companion `blind_spot` observation + every-phase flush rule).

## Why this phase exists

Every prior phase is **inside** the methodology — it hunts bugs the way the methodology says to. None of them step **outside** and ask: *what is this whole approach failing to look at?* Phase 1.6 is that step back. It runs once the run has done all the looking it knows how to do (Phase 1 Hunt + DEEP Phase 1.5 Fuzzing), so the critique is grounded in what *actually happened this run*, not a generic checklist.

It does **not** find bugs and does **not** spawn work this run. Its product is **candidate directions/lanes** for the next round — the cheapest, highest-leverage steering signal a round can carry, because it is the methodology improving itself.

## When it runs

- **Tier:** DEEP only. It is two mandatory DEEP roster lanes (`methodology_blindspot_lane_a`, `methodology_blindspot_lane_b`, strategy ids 17/18). LOW/MEDIUM do not run it.
- **Order:** after Phase 1 Hunt and Phase 1.5 Fuzzing have flushed for the `(target, round)` — i.e. after *all discovery sweeps*. It runs before/independent of Confirm; its output is for the next round, so its position relative to Confirm/Proof does not change what it consumes.
- **Skip:** like any roster lane, a documented skip (`agent_steps.status='skipped'` + non-empty `termination_reason`) is honest and waivable; a silent no-show is a `MISSING` gate failure (`v_lane_coverage`).

## The two lanes — identical and independent

The dual-seed-corpus precedent (ids 12/13): **one prompt, two instances.** Diversity comes purely from LLM stochasticity, not from different instructions. Both lanes receive the same context and the same single goal:

> **"Find any blind spot in our codebase-analysis methodology."**

Each lane returns blind spots in **two clearly-separated classes** (`gap_class`):

| `gap_class` | Question | Examples |
|---|---|---|
| `process` | *How* did we analyze — what does the methodology itself not look at? | A bug class never checked (e.g. no deserialization-gadget lane); a lane that should exist but doesn't; an assumption taken on faith and never tested; a source/sink/defense *type* not in the enumeration vocabulary; a tool we had but never pointed at the right surface. |
| `coverage` | *What* did this run never reach? | A module/parser/region no slice or fuzz target touched; a high-value entry point with zero agent steps; a sink with no backward trace; a language in the polyglot stack we under-served. |

The separation is load-bearing: it keeps the meta-pass output **distinct from** the frontier-coverage `agent_observations(obs_kind='blind_spot')` rows that `cpg_coverage` (strategy 16) already emits for uncovered slice frontier methods. Those stay where they are; Phase 1.6 is a *higher-altitude* critique that can also re-state a coverage hole as a strategic direction.

## The merge — content-hash union-dedup

The two lanes' outputs are **merged**, not concatenated:

1. Each candidate blind spot is normalized and hashed into `blindspot_hash` (over `target_id` + `gap_class` + normalized identity — title/anchor).
2. Insert is `… ON CONFLICT (blindspot_hash) DO NOTHING` (single-writer, idempotent — the harness `put` path).
3. When lane B produces a row whose hash already exists (lane A flagged the same gap), the orchestrator at flush **flips `agreement` → `'both'`** and **bumps `dedup_cluster_size`**. Agreement across two independent instances is a **confidence signal** — a both-lane gap is more likely real than a single-lane one.
4. `dedup_cluster_size` also accrues across *rounds*: a direction repeatedly surfaced round-over-round climbs the ranking.

The merge is DB-native — there is no separate "merge agent." The UNIQUE constraint + the orchestrator's conflict handling *is* the union-dedup.

## The ranked output — `v_methodology_blindspots_ranked`

Read-time ranking, **no stored score** (the `v_critical_fn_ranked` / `v_suspicious_points_ranked` precedent). Ordering is purely ordinal — no magic constant:

1. `open_direction` (= `promoted_to_round_id IS NULL`) first — unconsumed directions are the next-round worklist.
2. both-lane `agreement` above single-lane.
3. `dedup_cluster_size` DESC — recurrence across lanes/rounds.
4. `gap_class`, then `created_at`.

## Feed-forward — how the next round consumes it

The merged directions are **not acted on this run**. The next round's round-entry fetch picks them up (`round-feedforward.md` fetch (8)): `v_methodology_blindspots_ranked WHERE target_id = ? AND open_direction`. Each unconsumed direction becomes a candidate lane/priority for that round:

- a `process` gap → a new or widened lane, or an enumeration pass that fills the missing source/sink/defense type;
- a `coverage` gap → slice/fuzz the named region first.

When the orchestrator **acts** on a direction (schedules a lane, re-prioritizes a region from it), it stamps `promoted_to_round_id` = the consuming round's id. That is the **feed-forward closure** and the change-visibility record: a query of `methodology_blind_spots` shows exactly which prior-round gaps actually became work, and which are still open.

## Persistence contract

- One `methodology_blind_spots` row per merged direction (`gap_class`, `title`, `body`, optional `proposed_lane` / `symbol_path` anchor, `agreement`, `dedup_cluster_size`, `blindspot_hash` UNIQUE, `promoted_to_round_id`). Oversize `body` (> 16 KB) spills to a sidecar via `body_sidecar_path` (A1).
- Each merged row **also** emits one companion reusable `agent_observations(obs_kind='blind_spot')`. This satisfies the **every-phase observation-flush** rule (so `v_observation_coverage` does not flag `phase1_6_blindspot` as `NO_OBSERVATION`) and lets the existing round-entry fetch (3) see the gap through the standard observation path. `obs_kind` is **not** widened — the process/coverage separation lives in `methodology_blind_spots.gap_class`, not in a new enum value, so there is no CHECK rebuild.
- Subagents emit row-shaped JSON events only; the orchestrator is the sole writer. No file artifacts (the absolute no-disk-write rule).

## Gates

- **Roster (`v_lane_coverage`):** both lanes must execute ≥1 step or record a documented skip, else `MISSING` (HARD RED).
- **Observation (`v_observation_coverage`):** `phase1_6_blindspot` is derived from the roster, so an executed phase with zero observations is `NO_OBSERVATION` (HARD RED).
- **Signal (`v_coverage.methodology_blindspots_unpromoted`):** count of merged directions not yet carried into a later round. This is an **inspect-signal, NOT an auto-red** — the latest round always has unconsumed directions by construction (nothing has run after it to consume them). The orchestrator confirms each was *considered* as a next-round lane; it never auto-fails on a non-zero count.
- **Phase status (`v_phase_status`):** `phase1_6_blindspot` (`rows_populated` = `methodology_blind_spots` count) sits after `phase1_5_fuzz`.
