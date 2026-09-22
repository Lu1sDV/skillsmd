# REPORT Critic Phase (C4)

> Operational guidance for the Phase 5 / Phase L7 critic agent. Worked examples and severity rubric: `references/v2/critic-rubric.md`.

For each `gr_findings` row with `confirmation_status = 'confirmed'`, the critic runs **three checks**. Each check emits a `critic_findings` row keyed by `(finding_id, check_kind)`. CRITICAL severity on any row blocks the final report; WARNING severity is stored structurally and surfaced in the report.

## The Three Checks

### 1. Comprehension

> Is the finding statement coherent with the cited evidence?

The critic re-reads the finding's `payload` (or sidecar), the source row's `evidence_path:line`, the sink row's `evidence_path:line`, and the slice's `representative_callees`. The check fails if:
- The cited code does not contain the claimed sink call.
- The slice's callee set does not reach the claimed sink.
- The payload's structure is incompatible with the claimed source kind (e.g., payload assumes JSON body but `sources.source_kind = 'http_query_param'`).

**WARNING** when the finding statement is partially miscoded (typo in symbol path, off-by-one line number) but the underlying claim survives a re-read.
**CRITICAL** when the cited evidence does not support the claim at all.

### 2. Eligibility

> Does it meet the project's bug-bounty / disclosure criteria?

The critic reads `intended_feature_classification` for the sink and applies the rigor doctrine (see `references/v2/confirmation-rigor-doctrine.md` § Gate 3). The check additionally validates `gr_findings.config_state`:

| `config_state` | Eligibility behavior |
|---|---|
| `vanilla` | Proof was collected against an unmodified production-equivalent deployment. Pass. |
| `non_vanilla` | Proof requires a configuration change. **Critic MUST emit a WARNING** with `evidence_json.required_config_delta` describing the required change. The report MUST disclose the non-vanilla prerequisite. |
| `unknown` | Config state not recorded. **CRITICAL** — the finding has not met Phase 7 Q4 ("Where is the defense layer?"). |
| `NULL` | Same as `unknown`. **CRITICAL**. |

The check also fails CRITICAL if the finding maps to a known "Submission N/A" criterion (see `references/phases/audit-poc-report.md`) — e.g., self-XSS, missing-but-not-bypassable security headers, MITM-only attacks against TLS-protected channels without a separable bug.

### 3. Attack-Scenario

> Is the chain plausibly weaponizable end-to-end?

The critic constructs a DAG (per `references/methodology/dag-reasoning.md`) from the cited source → intermediate nodes → verified sink and answers Phase L7 Q1–Q3:

1. Can the input be controlled by an attacker in production?
2. Does the tainted data survive all transforms, sanitizers, and WAF rules?
3. Does the payload demonstrate real-world consequences?

A check that cannot close the DAG from an untrusted source to a `verified_sink` writes **CRITICAL** — the finding is not exploitable in the claimed form.

A check that closes the DAG but identifies a **practical** controllability constraint (e.g., requires victim interaction, requires admin role at registration time) writes **WARNING** with the constraint in `evidence_json.controllability_caveat`.

## Severity Storage Contract

```sql
INSERT INTO critic_findings (finding_id, check_kind, severity, message, evidence_json, created_at)
VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP);
```

- The `(finding_id, check_kind)` pair is UNIQUE — each check runs once per finding.
- **CRITICAL rows block report emission** at orchestrator flush time. The orchestrator inspects `critic_findings WHERE severity = 'CRITICAL'` before finalizing the report; any hit demotes the finding to `confirmation_status = 'refuted'` and emits a `refutations` row with `refutation_reason = 'other'` and `evidence_json` containing the CRITICAL critic_findings rows.
- **WARNING rows are surfaced in the report** but do not block. The report renderer pulls WARNING rows alongside the finding's payload and renders them as "Critic Notes" / "Eligibility Caveats" / "Controllability Caveats".

## Rubric

The full severity rubric — 17 worked examples spanning all three check kinds — lives in `references/v2/critic-rubric.md`. The critic agent MUST consult that rubric before emitting a verdict; agent prompts include the rubric as seeded context (via the autoloading layer, see `references/v2/autoloading-knowledge-layer.md`).

## Cross-References

## Phase-numbering crosswalk

| Doc label | v2 pipeline phase | L-lane |
|---|---|---|
| Phase 4 (re-prove) | Phase 3 Bypass-Recheck | Phase L7 |
| Phase 5 critic | Phase 2 Confirm (Gate check) | Phase L7 |
| Phase 7 Q1–Q4 | exploitability questions inside Phase 2 | Phase L7 (Exploitability Gate) |
| Phase 8 report | Phase 4 Proof + Phase 5 Report | Phase L8 |

When this doc uses bare "Phase N" numbers they follow the older critic-agent labelling. The L-prefixed scheme (`Phase L7`, `Phase L8`) is the SKILL.md canonical form; the two are equivalent per the crosswalk above.

## Cross-References

| Need to | Read |
|---|---|
| Decide WARNING vs CRITICAL on a borderline case | `references/v2/critic-rubric.md` |
| Verify the underlying confirmation gates were honored | `references/v2/confirmation-rigor-doctrine.md` |
| Build the DAG for the attack-scenario check | `references/methodology/dag-reasoning.md` |
| Check whether the finding hits a "Submission N/A" rule | `references/phases/audit-poc-report.md` |
