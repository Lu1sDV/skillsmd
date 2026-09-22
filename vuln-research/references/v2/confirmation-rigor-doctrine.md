# Confirmation Rigor Doctrine (C1)

> Operational guidance for the swarm + orchestrator when promoting a `gr_findings` row from `candidate` to `confirmed`. Source of truth: `db/schema.sql` (gate tables + `refutations` + `impact_proofs`) + this doc.

A finding moves from `confirmation_status = 'candidate'` to `confirmation_status = 'confirmed'` **only when all five gates pass**. Each gate writes structured evidence into a typed table; gate failure writes a `refutations` row with the matching `refutation_reason`. The first four gates prove a *path to a sink*; **Gate 5 proves a *consumer is harmed*** — a sink reached is not a consumer harmed, and the DAG does not close until the harm is named (see § Gate 5).

**Default-deny:** every finding is non-confirmed until a harness demonstrates exploitation against the unmodified target — see `references/phases/poc-constraints.md` § Attacker Scenario Harness.

**Stricter refutation default — refute before you confirm.** No finding may be promoted to `confirmed` until an **adversarial refutation has actually RUN and FAILED to refute it**. The confirming agent does not get to skip the refutation pass on its own say-so. Default to skeptical; **over-claiming is the documented failure mode** (confirmations that no independent refutation ever challenged). A confirmation with no recorded refutation attempt against it is itself a gate failure, not a pass.

The refutation tier scales with audit depth:

| Tier | Refutation requirement |
|---|---|
| **DEEP** | A **DAG-independent** adversarial trace: a separate agent reasons from a fresh DAG (not the discovery DAG), actively trying to break reach/defense-gap/intended-feature claims. Must execute and return empty before promotion. |
| **MEDIUM** | A **two-check re-trace** from an **independent lane/strategy** (not the discoverer): the refuter re-runs the DAG closure from a different starting node (alternative source or alternate path), then writes a `refutations` row with `pass=true` or a failure reason. |
| **LOW** | The **DAG-mechanical bar is raised**: every DAG step must cite a concrete line of evidence; unsupported inferences are treated as refutation failures and block promotion. The re-check is still authored by a lane/strategy other than the discoverer. |

All tiers require a `refutations` row with the outcome before `confirmation_status` can be set to `confirmed`.

**Independence is required at EVERY tier, not just DEEP.** A `refutations` row is gate-satisfying only when the refuter's lane/strategy ≠ the finding's discoverer strategy (`refutations.agent_step_id` → `agent_steps.strategy_id` differs from the finding's `discoverer_strategy_id`). A finding refuted by its own discoverer shares that discoverer's blind spot by construction and does not clear the gate. The earlier MEDIUM "same agent re-runs" shortcut is retired: self-refutation is not refutation.

**Stamp the rigor tier on the confirmation.** When a finding is promoted, record the tier the refutation actually achieved in `gr_findings.confirmation_rigor_tier` (the enum above: `DEEP`/`MEDIUM`/`LOW`). Every downstream consumer — round priors, the recurrence counter, cross-audit memory, the calibration register — reads this stamp so a weakly-tested (`LOW`/`MEDIUM`) confirmation can be **discounted** rather than treated as equal truth to a `DEEP` one. *A registry that erases the tier launders weak evidence into strong priors.*

## The Five Gates

### Gate 1 — Taint reach proven

At least one slice trace must exist in `input_slices` with:
- `slice_kind ∈ {forward_taint, backward_sink}`,
- `source_id` = the finding's `gr_findings.source_id`,
- a callee path reaching the finding's `sink_id` (verified by the slice's `representative_callees` or a chained DAG step).

**Failure → refutation:** `refutation_reason = 'not_reachable'`.

### Gate 2 — Defense gap proven

EITHER:
- **(a) No defense on path** — a `defenses` rank-1 callsite check finds no `defenses` row whose `symbol_path` appears in the slice's callee set; OR
- **(b) Bypass reproduced** — a `defense_bypasses` row exists with `reproduced = true` linking the defense on the path (`defense_bypasses.defense_id` matches one of the slice's defenses, `defense_bypasses.sink_reach_finding_id = gr_findings.id`).

**Failure → refutation:** `refutation_reason = 'sanitized'`.

### Gate 3 — Intended-feature filter

Read `intended_feature_classification` for the finding's `sink_id`:

| `is_documented_behavior` | `precondition_strictness` | `observed_role_at_sink` | Verdict |
|---|---|---|---|
| `false` | (any) | (any) | **Pass** |
| `true` | `≤ user-supplied threshold` | `≤ user-supplied role gate` | **Pass** (documented but the observed precondition + role keep it in scope) |
| `true` | `> user-supplied threshold` OR `> user-supplied role gate` | — | **Fail** |

The `user-supplied threshold` and `user-supplied role gate` are audit-config inputs (default: `trivial` and `anonymous` respectively — anything stricter counts as out-of-scope).

**Failure → refutation:** `refutation_reason` ∈ `{'intended_feature', 'wrong_role', 'preconditions_unmet'}` depending on which sub-condition failed.

### Gate 4 — Reproduction artifact

EITHER:
- `gr_findings.payload IS NOT NULL` (inline payload, ≤ 16 KB), OR
- `gr_findings.payload_sidecar_path IS NOT NULL` (sidecar path under `db/sidecars/<hash>`).

**AND** `gr_findings.config_state` MUST be set to one of `{'vanilla', 'non_vanilla', 'unknown'}` describing the deployment configuration under which the payload was collected. A `non_vanilla` proof MUST disclose the required configuration in the eventual report — Phase 5 critic enforces this via its eligibility check (see `references/phases/report-phase.md`).

**Failure → refutation:** `refutation_reason = 'env_required'` (sidecar missing) or `'other'` with `evidence_json` describing the artifact deficiency.

### Gate 5 — Consumer harm

Reaching a sink is **not** the terminal of a finding. Gates 1–4 prove a *path to a sink*; Gate 5 proves the *harm that path causes*. The finding does not confirm until you can name **the default-config component that reads / dispatches / trusts the tainted value, and the harm it suffers**.

- Name the **`consumer_symbol`** — the concrete default-config code path that consumes the sink's tainted output (reads the corrupted bytes, dispatches the attacker-controlled request, trusts the forged value), together with the **`harm_class`** it incurs (memory disclosure, RCE, request forgery, auth bypass, availability loss, …) and a **`reachability_evidence_ref`** that the consumer is reachable under default config.
- **A sink reached is not a consumer harmed.** A write into separately-arena'd / never-read memory, a request never exfiltrated, a corrupted value no consumer trusts — all reach a sink and harm no one. These pass Gates 1–4 and **fail Gate 5**.
- **No nameable consumer → auto-demote.** If no default-config consumer can be named, the finding is **not** confirmed; it auto-demotes to an Observation (`agent_observations`), never to `confirmed`.
- **Sink-less classes (authz / IDOR / logic).** For findings with no data sink, the consumer *is the privileged operation reached past the broken guard* — the state-changing / data-returning operation an unauthorized actor now executes. Name that operation as the `consumer_symbol` and the authority it breaches as the `harm_class`.

Gate 5 evidence lands as a typed **impact-proof** row (`impact_proofs(finding_id, consumer_symbol, harm_class, reachability_evidence_ref, severity_basis)`); the `v_promotion_coverage` view red-flags any `confirmed` finding lacking one. Severity is a **contract, not an automatic function**: the Confirm agent MUST derive severity from the exploitability-gate rubric over `harm_class × proven_reachability × mechanism_cap` and record that derivation in `severity_basis` — the harness does not compute severity (it records the agent-derived rating + its basis, and refuses a rating above any `mechanism_cap`-implied ceiling). It is never typed free-hand at emit.

**Failure → refutation:** `refutation_reason = 'no_consumer_harm'` with `evidence_json` recording the sink reached and the absent/unreachable consumer.

## Refutation Row Shape

Every gate failure writes a `refutations` row:

```sql
INSERT INTO refutations (finding_id, agent_step_id, refutation_reason, evidence_json, created_at)
VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP);
```

The `(finding_id, agent_step_id, refutation_reason)` triple is UNIQUE — repeated rejection of the same finding by the same agent for the same reason is idempotent.

## Cross-DB Provenance

`refutations.agent_step_id` is a FOREIGN KEY into `agent_steps(id)`. This preserves which agent (via `agent_steps.strategy_id`) authored the refutation. When debugging false refutations, query:

```sql
SELECT r.refutation_reason, r.evidence_json, s.name AS strategy_name, a.started_at
FROM refutations r
JOIN agent_steps a ON r.agent_step_id = a.id
JOIN strategies s ON a.strategy_id = s.id
WHERE r.finding_id = ?;
```

## DAG Terminal Node

The taint DAG does **not** close at a `verified_sink`. `verified_sink` is **non-terminal**: a finding's DAG closes only when a sink node connects forward to a **`harmed_consumer`** node (the Gate 5 `consumer_symbol` — a default-config path that reads / dispatches / trusts the tainted value with a stated `harm_class`). A structurally complete, admissible DAG that terminates at a sink with no forward edge to a harmed consumer is **incomplete**, not closed — it fails Gate 5. For sink-less classes (authz/IDOR/logic) the `harmed_consumer` node is the privileged operation reached past the broken guard. Closure requires `source → sink → consumer`, never `source → sink`.

## Promotion Path

Once all five gates pass — including the Gate 5 consumer-harm / `harmed_consumer` DAG closure — the orchestrator (single writer per § B3a) flips `gr_findings.confirmation_status` from `candidate` to `confirmed` under the per-phase transaction, stamping `confirmation_rigor_tier` with the achieved refutation tier. The Phase 5 REPORT critic (see `references/report-phase.md`) then runs its three checks against the confirmed finding before final report emission.
