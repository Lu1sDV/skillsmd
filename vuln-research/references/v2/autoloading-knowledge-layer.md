# Autoloading Knowledge Layer (C3)

> Operational guidance for seeding and expanding the per-agent knowledge corpus. Source of truth: [`references/v2/pipeline-architecture.md`](pipeline-architecture.md) § Knowledge-Layer.

The autoloading layer feeds each swarm agent the minimum corpus required for its task without flooding context. It is **DuckDB-native** — no markdown corpus loaded into context wholesale.

## Read-Path Modes

### Seed (phase-entry, top-K = 10)

At phase entry, the orchestrator queries the top-10 most-accepted chunks from `knowledge_chunks` filtered by relevance signals (target language, active sink categories, active defense types) and writes them to `knowledge_seed_log` with `load_mode = 'seed'`. The agent receives these 10 chunks in its initial prompt.

Seed is **last-write-wins** on `(source, chunk_key)` — only the most recent version is loaded.

### Expand (lazy, cap 50)

During execution, an agent may request additional chunks via `knowledge_seed_log` with `load_mode = 'expand'`. Each expand call is **version-pinned** at first reference within the `agent_step` — subsequent re-reads within the same step return the same `version` even if the canonical chunk has since been updated.

Per-agent_step expand cap: 50 chunks. The orchestrator enforces this at flush time; lanes that request beyond cap are rewritten to `failed` with `termination_reason = 'knowledge_expand_overflow'`.

## Acceptance Criteria (Tri-Signal)

A chunk graduates to **"core"** (auto-seeded across sessions, included in top-10) when ALL of:

1. **Reference rate** — `ref_count / window ≥ 0.05`. The chunk is referenced in at least 5% of agent steps within the rolling acceptance window.
2. **Non-noise** — `repeat_suppressions ≥ 3`. The chunk has survived at least 3 redundancy suppression passes (an attempt to load it was de-duplicated against existing context).
3. **Still relevant** — `growth_rate ≥ 0` AND `staleness_days ≤ 30`. The reference rate is not decaying AND the chunk has been touched in the last 30 days.

All three computed by the orchestrator at flush time and persisted to `knowledge_acceptance`.

## Bootstrap Rule (R8)

On the **very first audit of a target** (no historical window in `knowledge_acceptance`), the tri-signal AND-gate is too strict — no chunk has yet accumulated `repeat_suppressions ≥ 3`. The bootstrap rule relaxes this:

> First audit: **any single signal** (reference rate ≥ 0.05 OR repeat_suppressions ≥ 1 OR growth_rate > 0) admits a chunk to core.

The tri-signal AND-gate engages from audit #2 onward. Audit count is derived from `COUNT(DISTINCT audit_run_id) FROM audit_outcomes WHERE target_id = ?`.

## Persistence Tables

| Table | Purpose |
|---|---|
| `knowledge_chunks` (source, chunk_key, version, body) | Content store, versioned, NK = `(source, chunk_key, version)` |
| `knowledge_seed_log` (agent_step_id, chunk_id, load_mode) | Per-step load record |
| `knowledge_acceptance` (chunk_id, ref_count, repeat_suppressions, growth_rate, staleness_days, accepted) | Graduation state |

The orchestrator is the only writer to all three (single-writer rule per § B3a).

## Suppression Semantics

Duplicate or overlapping chunks are suppressed at expand time: the orchestrator hashes the chunk body and skips loads whose hash already exists in the agent's loaded set. Each suppression increments `knowledge_acceptance.repeat_suppressions` for that chunk_id. Suppression is a positive signal — it means the chunk's content is already in the agent's context and the chunk's downstream value has been validated.

## Decay

A chunk whose `growth_rate < 0` AND `staleness_days > 30` is **demoted** from core: its row in `knowledge_acceptance.accepted` is flipped to `false`. Demoted chunks remain queryable via expand but are no longer auto-seeded. The orchestrator runs the decay sweep at end-of-audit flush.
