# Perpetual Loop Mode

A self-firing, target-agnostic vulnerability-discovery loop modeled on Menon's triple-network
brain model (Default-Mode → Salience → Central-Executive), added as a **thin orchestration
layer over vuln-research's existing engine** — not a parallel machine. It absorbs the
capability of the `triple-network` skill but is re-authored natively: zero new tables, the
Executive lane REUSES Phase 2 Confirm + L5 PoC, and the learning ledger IS `round_ledger` +
`recurrence_counter`.

Strategies: `perpetual_dmn_generate` (19), `perpetual_salience_promote` (20),
`perpetual_executive_pursue` (21), `perpetual_ledger_learn` (22). All four are
**non-mandatory** — deliberately absent from `v_required_deep_lanes` (the `cpg_coverage`
precedent), so normal DEEP audits never block on them.

## The three-register model

One round runs three cognitive registers in sequence — divergent at the top, sober below:

```
DMN generate (divergent)  →  Salience promote (top-K by promise)  →  Executive pursue
                          →  Confirm  →  Learn (round_ledger)  →  self-fire (ScheduleWakeup)
```

- **DMN / Core (divergent register).** The generation phase runs vuln-research's existing
  **Agent Sweep S2 / Phase 1 Hunt** agents in an explicit divergent register: mandatory
  divergence, cross-domain analogy, surfacing unproven hunches, **and free re-litigation of
  previously-refuted leads** when a new angle, analogy, or ledger signal justifies another
  look. This is the ONLY place the divergent flavor lives. **DMN agents MUST emit divergent
  candidates as `suspicious_points` rows** — the Salience gate ranks only `suspicious_points`
  (via `v_promise_ranked`). Any direct `gr_findings(candidate)` emission bypasses Salience
  and is out of contract; such rows reach the Executive lane unranked and unfiltered. If a
  DMN agent has a strong candidate it wants to emit directly as a `gr_findings` row, it MUST
  first emit a corresponding `suspicious_points` row anchored to the same `(file, line,
  symbol_path)` so Salience can rank it.
- **Salience Gate (sober).** Ranks the round's `suspicious_points` by `promise` and promotes
  the top-K to the Executive lane. A read-time view (`v_promise_ranked`) over existing
  columns — no new tables, no stored score (the `v_suspicious_points_ranked` /
  `v_critical_fn_ranked` never-store rule). **Top-K default is K = 5 per round** (overridable
  per invocation via the same mechanism as N; document as `k_per_round` in the invocation
  parameters). K should be scaled to the effort tier: K=3 for LOW, K=5 for MEDIUM, K=10
  for DEEP — these are defaults, not floors. Externalize K alongside N so both are
  inspectable and tunable without editing this doc.
- **Executive Lane (sober).** **Reuses** the existing Phase 2 five-gate **Confirm**
  (refute-by-default, `references/v2/confirmation-rigor-doctrine.md`) + **L5 PoC constraints**
  (zero-mocking, vanilla real PoC). No new confirm path is built. A HIGH/CRIT confirmation
  here counts toward the loop's N target.

Divergence is **Core-only**. Salience and Executive stay strictly convergent — refute-by-
default, vanilla real PoC, no poetry, no unproven claims. "Open at the top, closed at the
bottom" — vuln-research's existing Agent Sweep philosophy.

## DMN doctrine — full divergence + free re-litigation

The DMN register is deliberately psychedelic at the generation step:

- **Mandatory divergence.** A round that emits only safe, already-known candidates **has
  malfunctioned**. Cross-domain analogy and unproven hunches are required output, not noise.
- **Free re-litigation.** Previously-refuted leads may be re-opened whenever a new angle,
  analogy, or ledger signal justifies another look. Refute-by-default is NOT a permanent ban
  on a lead — it is a per-attempt verdict. Precision is restored downstream by the unchanged
  Salience gate + five-gate Confirm, never by suppressing re-examination upstream.

## The loop protocol + ScheduleWakeup self-firing

The loop **self-fires across turns via `ScheduleWakeup`**: after Learn writes the round's
ledger feedback, the orchestrator schedules its own next wakeup and ends the turn, so the
loop continues across turn boundaries without a human re-prompt.

- **Unbounded by design.** The loop runs until **N HIGH/CRITICAL findings are confirmed**
  (default **N = 20**, overridable per invocation) **or the user interrupts**. No budget cap,
  no dry-exit auto-stop.
- **Dry rounds reported, not halting.** A round that confirms nothing is honest progress, not
  a stop condition. The only damper is **ledger down-weighting** (below).
- **Target-agnostic.** No target paths hardcoded; the target is a parameter; run state lives
  under the existing `.vuln-research/` workspace convention.

Invocation triggers: "run perpetual loop on `<target>`", "keep hunting until N high/critical
confirmed", "continuous / perpetual / self-firing vuln discovery", "DMN / salience / executive
loop".

## The promise formula

The Salience gate ranks candidates by

```
promise = novelty × est_severity × reachability_prior × ledger_history_factor
```

computed read-time in `v_promise_ranked` (see `db/schema.sql`). Each factor is
percentile-ranked within `(target_id, round_id)` so the product is scale-free and top-K
promotion is deterministic; a degenerate population (n ≤ 1) or a missing factor row yields a
neutral 0.5 (never a silent 0). **Factor estimation** maps each factor onto a column that
already exists — no new table, no invented score:

| Factor | Source column | Estimation |
|--------|---------------|------------|
| `novelty` | `suspicious_points.graduated_finding_id`, `.dedup_cluster_size` | Under-explored regions score high (`1/dedup_cluster_size`); an already-graduated region scores 0 — the loop wants new ground. Note: `v_promise_ranked` reads `suspicious_points` and `suspicious_point_factor` — it touches **no** `gr_findings` columns. |
| `est_severity` | `suspicious_point_factor.raw_value` where `factor_name='dangerous_sink_class'` | The only pre-Confirm severity proxy stored on `suspicious_points`; true severity is set later by Confirm/Proof on `gr_findings`. Non-sink-class candidates (logic bugs, authz) have no `dangerous_sink_class` factor — the neutral 0.5 applies. |
| `reachability_prior` | `suspicious_point_factor.raw_value` where `factor_name='reachable_from_entry'` | The existing Source-1 reachability gate's raw value, reused as a prior. |
| `ledger_history_factor` | `suspicious_point_factor.raw_value` where `factor_name='factor_recurrence_prior'` | The cross-round feed-forward / `round_ledger` recurrence signal — the ledger-bias input. |

## N-progress termination query

The loop's stop condition ("until N HIGH/CRITICAL findings are confirmed") must be DB-queryable so termination is deterministic, not LLM-honor-system. Use this read-time query to check progress after each round's Learn step:

```sql
-- v_perpetual_progress: confirmed HIGH/CRIT count vs target N for a given target.
-- N is the invocation parameter (default 20).
SELECT
    target_id,
    COUNT(*) FILTER (
        WHERE confirmation_status = 'confirmed'
          AND severity IN ('high', 'critical')
    ) AS confirmed_high_crit_count,
    :N AS target_n,
    COUNT(*) FILTER (
        WHERE confirmation_status = 'confirmed'
          AND severity IN ('high', 'critical')
    ) >= :N AS stop_condition_met
FROM gr_findings
WHERE target_id = :target_id
GROUP BY target_id;
```

The loop fires `ScheduleWakeup` for the next round **only when `stop_condition_met = false`**. When `stop_condition_met = true`, the Learn step records this in `round_ledger` and does not schedule another wakeup — the loop terminates cleanly. The query is **read-only** and produces no stored score; it is the mechanical enforcement of the prose "until N" contract.

## The learning ledger — ledger-bias mapped to existing tables

The Learn phase **IS** the existing machinery — no new ledger table:

- **`round_ledger`** opens each round and carries prior-round priors forward.
- **`recurrence_counter`** accumulates per-region hit/miss counts across rounds.
- Per-attack-class / per-region hit-miss rates **bias the next Core round**: down-weight
  exhausted families, surface under-explored regions. This ledger down-weighting is the
  loop's only damper against churn on re-litigated leads — there is no budget or dryness
  auto-stop.

The `ledger_history_factor` input to `promise` is exactly this signal, surfaced through the
`factor_recurrence_prior` factor that round feed-forward already populates.

### Calibration register — subtractive feedback on the generator

Ledger down-weighting biases the Core round on a *per-region* basis (down-weight exhausted
families, surface under-explored ground). That is a novelty signal, not a precision signal:
it never tells the divergent generator to stop producing a *shape* that keeps refuting. The
**calibration register** is the missing subtractive edge. After each round's Confirm, the
Learn step accumulates a **`false_positive_signature`** keyed on `(bug_class, sink_class,
discoverer_strategy, refutation_reason)` — the refute-counting twin of `recurrence_counter`'s
confirm-counting. It feeds the loop two ways:

- **Into Salience.** A `suspicious_points` candidate whose signature has a high refute-rate is
  **down-ranked before it consumes an Executive Confirm slot** — it must clear a raised bar
  before spending scarce confirm budget. (A high-refute signature is not a permanent ban —
  DMN's free re-litigation still applies — but the shape loses the benefit of the doubt a
  fresh shape gets.)
- **Into the DMN brief.** The next Core round's divergent prompt carries an explicit *"these
  shapes were false here — raise your bar"* note listing the high-refute signatures, so the
  generator stops re-emitting the shape rather than Salience re-killing each instance.

**Key on the shape, not the region.** Down-weighting a region is what the ledger already does
and it is not enough: a generator wrong about "OOB-read-via-class-X" in one region is wrong
about it in the next. The signature follows the *generative pattern* across regions. Full
mechanism (shared with the swarm pipeline): `references/methodology/swarm-pipeline.md`
§ Calibration Register.

### Negative-result stopping rule — a dry channel closes, it does not escalate

A dry round is honest progress, not a stop condition — but a dry *channel* must close, not
spawn a heavier next attempt. After **N clean attempts on a channel** (a fuzzing-strategy
family, an RCE-geometry vein, a re-confirmed-safe codec, a re-litigated lead that keeps
refuting), the Learn step writes a **`closures`** row (`surface_hash`, `closure_kind ∈
dead_end/exhausted/refuted_class`, `closed_in_round`, `reopen_condition`) and the loop
**STOPS** that channel. A negative result MUST NOT spawn a more elaborate next attempt on the
same channel — *sunk-cost escalation* (each clean strategy spawning a heavier one) is a named
failure class, not thoroughness. This is the one hard limit on DMN's free re-litigation: a
closed channel re-opens only when its `reopen_condition` *fires* (code under the slice moved,
a new primitive landed), never on a fresh appetite to try once more. The `closures` rows
written here are exactly what Wave Init dedup (below) and Phase 0.5 roster materialization
(`references/v2/pipeline-architecture.md`) consult to refuse re-running the closed surface.

## Wave init — ledger-dedup is a HARD pre-spawn step

Before each Core round spawns its DMN/Hunt agents, the pre-spawn ledger query is a
**blocking step, not advice**:

- Query `agent_observations` for `dead_end` / `blind_spot` / `invariant` rows on each
  candidate region **and** the `closures` table for an open closure whose `surface_hash`
  matches and whose `reopen_condition` has not fired. A region that is closed or logged-dead
  is dropped (scheduled `skipped`), not re-spawned. DMN re-litigation is allowed *only* when
  the closure's `reopen_condition` fired — a checkable event, not a mood.
- Decide presence at the pinned commit with **`git merge-base --is-ancestor`**, never a
  `presentAtPinned`-style flag — those flags have been observed unreliable; merge-base
  ancestry is the source of truth for whether the code under a region exists at the audited
  commit.

This is the preventive form of the dedup the ledger only enforced *reactively* (writing a
`dead_end` after the re-tread already fired). Promoting closure-consultation to a hard barrier
— rather than a soft down-rank the loop forgets under compaction — is what stops the perpetual
loop's unbounded rounds from spending a growing fraction of each round re-closing what it
already closed. Shared mechanism: `references/methodology/swarm-pipeline.md` § Wave Init.

## Resume reconciliation — never blind-replay a failing config

The loop self-fires across turns (`ScheduleWakeup`) and resumes after compaction/OOM by
reading `agent_steps.status` + `round_ledger` to re-enter at the last completed lane. Resume
restores *intent* — but it must not blindly re-run the *config* that just failed. **On resume,
before re-launching any lane, diff the config to be re-run against the config that caused the
last failure** (e.g. the concurrency / `MemoryMax` cap that OOM-killed the box, the
output-size that hung the synthesizer). **Refuse a blind replay of the failing config:** the
offending cap or cause MUST have changed before the lane re-launches. Resume-as-replay-
without-reconciliation is a named failure class — a resumed run that re-executes the exact
killing config simply re-fails (observed: three consecutive OOM kills because each resume
re-ran the same uncapped concurrency). Record the reconciliation decision in `round_ledger`
(what config changed, or why a replay is safe) so the refusal is auditable and a genuinely-safe
replay is not blocked.
