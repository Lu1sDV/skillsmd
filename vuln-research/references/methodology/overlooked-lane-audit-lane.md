# Overlooked-Lane Audit Lane (`overlooked_lane_audit_lane`)

> **Load when:** the orchestrator is closing out a DEEP run and needs to understand how the
> skill audits itself for high-yield lanes that were overlooked or erroneously skipped, and
> how it decides which to spawn in-run versus feed forward.
>
> **Strategy:** `overlooked_lane_audit_lane` (id 26, seeded in `db/seed/strategies.yml`)
> **Phase:** 1.7 — Self-Audit (phase token `phase1_7_self_audit`; `phase_seq` 6.5, between
> Phase 1.6 `methodology_blind_spots` and Phase 2 Confirm)
> **Tiers:** **DEEP-only mandatory** meta-lane (blocking via `v_required_deep_lanes`); not
> present at MEDIUM or LOW

---

## Purpose

The lane asks two adversarial self-questions at the close of every DEEP run, after all hunt
lanes and the Phase 1.6 blind-spot sweep have flushed:

> **(a) Generative** — "Are there **more** high-yield lanes we never considered?"
>
> **(b) Audit** — "Did we **erroneously ignore** a lane that should have spawned?" — a
> skipped or unpromoted lane whose documented skip reason no longer holds.

Detection is **DB-grounded**, not free-form LLM assertion. The lane diffs three reference
sets that already exist in the DB; the union of what those diffs surface defines the
actionable overlooked/ignored set. Because it runs *after* Phase 1.6, it can also read open
`methodology_blind_spots` rows as an optional fourth signal.

---

## Placement

The lane runs **last among the hunt-phase lanes** — after `methodology_blind_spots` (Phase
1.6, ids 17/18) has flushed — so that its detection can incorporate everything the blind-spot
sweep and all hunt agents produced. It appears in `v_phase_status` under phase token
`phase1_7_self_audit` at `phase_seq` 6.5.

`v_required_deep_lanes` enforces it: a round that reaches phase_seq 6.5 without a completed
or skipped `agent_step` for this lane surfaces as `MISSING` (HARD-RED).

---

## Detection — DB-Grounded Triple Reference

"Overlooked" and "erroneously ignored" are defined as **SQL diffs against three existing
sets**, never as free-form LLM intuition. This keeps the audit deterministic, verifiable, and
distinct from the Phase 1.6 blind-spot sweep (which writes `methodology_blind_spots`, not
`promising_lanes`).

### Reference 1 — Roster vs. coverage

```sql
-- Required lanes with no covering executed agent_step in the current round
SELECT s.name, s.id
FROM   v_required_deep_lanes r
JOIN   strategies s ON s.name = r.lane_name
WHERE  NOT EXISTS (
    SELECT 1 FROM agent_steps a
    WHERE  a.strategy_id = s.id
    AND    a.round_id    = :current_round_id
    AND    a.status      IN ('success', 'exhausted')   -- "ran" — the same definition v_lane_coverage / v_phase_status use
)
```

A row here is a **lane gap** — required by the roster, absent from the round's executed
steps. Combine with the lane's `termination_reason` (if any) to decide whether the skip was
legitimate at the time it was recorded.

### Reference 2 — Emitted-but-unpromoted `promising_lanes`

```sql
-- High-promise directions surfaced but never acted on
SELECT *
FROM   v_promising_lanes_ranked
WHERE  promoted_to_round_id IS NULL
ORDER  BY promise DESC
```

`open_direction = true` (i.e. `promoted_to_round_id IS NULL`) at high `promise` is the
primary signal for question (a). Each such row is a candidate the pipeline surfaced but did
not yet pursue.

### Reference 3 — `v_coverage` + enumeration signals

```sql
-- Enumeration uncovered signals from the completeness view (columns: metric, value, note).
-- v_coverage carries NO threshold/status columns — a metric is "hot" when value > 0; read
-- `note` to tell a HARD-RED gate (e.g. regexes_unmapped, slices_without_codebase_coverage)
-- from an inspect-SIGNAL (e.g. promising_lanes_unpromoted, methodology_blindspots_unpromoted).
SELECT metric, value, note
FROM   v_coverage
WHERE  value > 0
ORDER  BY metric
```

Uncovered modules, non-zero completeness-contradiction metrics, and (if present) a non-zero
`regexes_unmapped` gate value each represent attack surface the hunt may not have reached.
These drive new generative lane candidates for question (a).

### Optional 4th signal — open `methodology_blind_spots`

Because the lane runs after Phase 1.6, it may read `v_methodology_blindspots_ranked` rows
where no covering `agent_step` exists as additional generative prompts. These are optional
(the blind-spot sweep already owns that surface); the triple reference above is the required
baseline.

### Definitions

| Term | Definition |
|---|---|
| **Overlooked** | A high-`promise` direction in `v_promising_lanes_ranked` with no covering `agent_step` in the current round |
| **Erroneously ignored** | A skipped or unpromoted lane whose `termination_reason` no longer holds given the current round's findings |

---

## Action Model — Cap-Gated Hybrid

The lane follows an **always-emit, then cap-gated spawn** pattern:

1. **Always emit** a `promising_lanes` row for every confirmed overlooked or erroneously
   ignored lane. This preserves change-visibility and the `promoted_to_round_id` audit trail
   regardless of whether the lane is spawned in-run or fed forward.

2. **Spawn the top-N-by-`promise` in the current run**, up to a deterministic cap:

   ```
   cap = fetch-budgets.yml[phase1_7_self_audit].promising_lanes.row_cap × tier_multiplier
   tier_multiplier: low → 0.4 | medium → 0.7 | deep → 1.0
   ```

   The `row_cap` knob is the **existing** per-phase `promising_lanes` budget already in
   `db/seed/fetch-budgets.yml` — no new magic constant is introduced. At DEEP the multiplier
   is 1.0 so the full knob value applies.

3. **Overflow beyond the cap is not spawned in-run.** Those rows remain in `promising_lanes`
   with `promoted_to_round_id IS NULL` and are consumed by the next round's entry fetch (10)
   via the normal `v_promising_lanes_ranked` path.

Spawning a lane stamps `promoted_to_round_id = current_round_id` on its `promising_lanes`
row. This is the single closure record; the `promoted_to_round_id` column is the audit trail
for everything the self-audit acted on.

### Doctrine note — bounded exception

The in-run spawn is the **deliberate, bounded exception** to the otherwise feed-forward-only
`promising_lanes` doctrine. This exception is intentional: the self-audit's value is
precisely that it can recover a high-confidence missed lane before the round closes, subject
to a cap that prevents unbounded spawning. A future reader must **not** "fix" this by
removing the in-run spawn — feed-forward-only is the general rule; the self-audit is the
named exception. See `references/v2/round-feedforward.md` for the general doctrine.

---

## Ranking

The top-N selection reads `promise` from `v_promising_lanes_ranked` at query time:

```
promise = novelty × est_severity × reachability_prior × ledger_history_factor
```

This composite is **never stored** — it is a read-time computation in the view. The lane
selects the N rows with the highest read-time `promise` among the confirmed overlooked/ignored
set, breaking ties by `created_at ASC`.

---

## DB Footprint

The lane introduces **no DDL**. It reuses:

- `promising_lanes` — emits rows (including provenance via `derived_from_cve_id` /
  `derived_from_writeup_id` if a prior-art lead was the missed direction)
- `agent_steps` — the spawn target; each spawned lane creates an `agent_step`
- `strategies` — the roster reference for Reference 1 diff
- `v_coverage` / `v_required_deep_lanes` — Reference 1 and Reference 3 gate surfaces
- `v_promising_lanes_ranked` — Reference 2 + ranking

Its own DB footprint is exactly:

| Artifact | Detail |
|---|---|
| Strategy row | id 26, `name = 'overlooked_lane_audit_lane'` |
| Roster row | `v_required_deep_lanes` entry, phase `phase1_7_self_audit` |
| `v_phase_status` row | phase token `phase1_7_self_audit`, `phase_seq` 6.5; `rows_populated` = count of executed `overlooked_lane_audit_lane` agent_steps in the round |

Schema migration: `db/migrations/0028-overlooked-lane-audit.sql`.

---

## `coverage_json` Self-Attestation

The lane stamps `agent_steps.coverage_json` with:

| Key | Meaning |
|---|---|
| `roster_gaps` | count of required lanes with no covering executed step (Reference 1) |
| `unpromoted_high_promise` | count of `v_promising_lanes_ranked` rows with `promoted_to_round_id IS NULL` above a `promise` threshold (Reference 2) |
| `coverage_signals` | count of HARD-RED / SIGNAL rows from `v_coverage` (Reference 3) |
| `confirmed_overlooked` | count of confirmed overlooked/ignored lanes across all three references |
| `emitted_promising_lanes` | count of `promising_lanes` rows emitted this step |
| `spawned_in_run` | count of lanes actually spawned in the current round (≤ cap) |
| `fed_forward` | count of overflow rows left unpromoted for next round |
| `cap_source` | e.g. `"fetch-budgets.yml[phase1_7_self_audit].promising_lanes.row_cap=8 × tier=1.0"` |

---

## Lane-Done Gate

The lane is complete when:

1. All three reference diffs were executed and recorded in `coverage_json`, **and**
2. Every confirmed overlooked/ignored lane has a `promising_lanes` row (even if cap was
   zero — emit still happens), **and**
3. The top-N-by-`promise` within the cap have spawned `agent_step` rows with
   `promoted_to_round_id` set.

A run that reaches phase_seq 6.5 with no `agent_step` for this lane is a HARD-RED
`v_required_deep_lanes` failure at DEEP.

---

## Relationship to Adjacent Lanes

- **Phase 1.6 `methodology_blind_spots`** — must flush *before* this lane opens. The
  self-audit reads blind-spot rows as an optional 4th signal but does not write to
  `methodology_blind_spots`. The two lanes are distinct: blind-spots → `methodology_blind_spots`
  table; self-audit → `promising_lanes`.
- **Phase L-1 `prior_art_intake_lane`** — prior-art leads in `promising_lanes` that were not
  promoted by round-1 will appear in Reference 2 (emitted-but-unpromoted); the self-audit can
  re-surface and spawn them if they remain high-promise.
- **Round-entry fetch (10)** — overflow rows (beyond the cap) are consumed by the *next*
  round's fetch (10) via `v_promising_lanes_ranked` exactly as any other unpromoted lane.

---

## References

- Schema migration: `db/migrations/0028-overlooked-lane-audit.sql`
- Strategy seed: `db/seed/strategies.yml` — `overlooked_lane_audit_lane` (id 26)
- Gate view: `v_required_deep_lanes` in `db/schema.sql` (phase token `phase1_7_self_audit`)
- Feed-forward doctrine + fetch (10): `references/v2/round-feedforward.md`
- Promising-lanes mechanics + `v_promising_lanes_ranked`: `db/migrations/0025-promising-lanes.sql`
- Phase 1.6 blind-spot sweep (adjacent, not merged): `references/methodology/methodology-blindspot-sweep.md`
- Spawn budget knob: `db/seed/fetch-budgets.yml` — `phase1_7_self_audit.promising_lanes.row_cap`
- Spec: `.omc/specs/deep-interview-vuln-research-three-enhancements.md` — C2 (AC-2.x)
