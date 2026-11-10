# Review coverage: 16 dimensions, 14 deep-module lenses

**Coverage is not execution order.** Screen every row; deepen only applicable questions that can change the outcome. For each active row capture its *answer, primary evidence, counterevidence/unknowns and exit decision*. NASA [S01], ISO 42010 [S05], ISO 25010 [S06], arc42 [S07] and V&V [S09] inform coverage; specialized references apply conditionally.

| ID | Dimension | Investigation → exit condition |
|---|---|---|
| 00 | Review mission and boundaries | Goal, stakeholders, decision, time/permission limits, exclusions → explicit review contract |
| 01 | Repository snapshot and source hierarchy | Commit/branch/dirty tree, repo instructions, code/config/tests/docs/history, conflicting source authority → reproducible evidence context |
| 02 | Product goals and critical assumptions | Requirement versus inference, expected change scenarios, qualities and assumptions → prioritized falsifiable goals |
| 03 | Architecture and dependency map | Module ownership, static/runtime/data dependencies, external contracts, deployment/release topology → grounded views, not imagined graph edges |
| 04 | Implementation inventory | Relevant modules, callers, entry points, side effects, tests; breadth-first then selective depth → sampled and unsampled scope explicit |
| 05 | Data models, identities and invariants | Domain concepts, ownership, identity, lifecycle, validation, persistence, consistency, migrations and provenance → states and guarantees |
| 06 | Execution and state transitions | Trace entry→calls/events→data mutations→effects→result; common, invalid, failure, retry and async paths → referenced traces |
| 07 | Security and authorization | Principals, authorization checks, trust transitions, secrets/privacy, failure defaults and threat surface → preserved or flagged security guarantees [S10,S11] |
| 08 | Scientific and evaluation contracts | **When relevant:** datasets, leakage, metrics, baselines, reproducibility, uncertainty and protocol drift; FAIR4RS concerns software reuse, not statistical validity [S12] → validated protocol or gaps |
| 09 | Reliability, concurrency and failure | Transactions, idempotency, retries, version skew, resource limits, recovery, telemetry, performance/scale/cost → consequential operational risks |
| 10 | Implementation and validation status | Distinguish spec, merged code, current tests, independently run tests, CI commit and observed runtime → precise status, no inferred passes |
| 11 | Risk hypotheses and falsification | For every high-impact claim ask what refutes it; run a safe check or record blocker → supported/qualified/rejected/unresolved |
| 12 | Architecture/product improvements | Unchanged vs local fix vs deepening, scenario-based locality/leverage, test/security/rollout cost, reversibility → justified choice or no change [S04] |
| 13 | Historical findings and open decisions | ADRs, rejected designs, incidents, prior reviews, issue history, premise changes → honor decisions or justify reopening |
| 14 | Evidence index and references | Claim→path/test/commit link, version, method, contradictions, source limits → traceable evidence ledger [S03] |
| 15 | Reviewer assignment and outputs | Bounded assignments, independence, permissions, shared schema, contradiction checking, HTML QA → no orphaned material claims |

**Timing:** inspect 10 and 13 early; collect 14 throughout; plan 15 before parallel work. The report may present rows 00–15 in numerical order without forcing investigation into that sequence. Add a project-specific dimension only when these do not cover a material risk.

## Deepening lenses (D1–D14)

Apply the relevant checks to each candidate; use evidence and a falsifier, not a scorecard that produces automatic winners.

| Lens | Decision question / anti-false-positive test |
|---|---|
| D1 Domain cohesion | Is repeated domain policy truly the same, or are similar words masking different concepts? (02,05,13) |
| D2 Interface obligations | What must callers know about ordering, state, errors, policy, config and performance, beyond types? (03,04,06) |
| D3 Depth and information hiding | Would consolidation actually remove caller obligations and changes, or only move code? (04,12) |
| D4 Locality of decisions | Does a real edit/test require coordinated changes, or are differences intentional? (04,06,12) |
| D5 Seam/adapter/deletion | What behavior, isolation or guarantee would disappear if the module vanished? Adapter count proves nothing. (03,09) |
| D6 Change-coupling hotspots | Do semantic commits repeatedly co-change responsibility, after excluding churn? (01,04,13) |
| D7 Testability and regression | Are edge/error paths and useful internal tests preserved; do fakes match production enough? (04,10,11) |
| D8 State/concurrency/consistency | What transaction, locking, invariant or duplicate-effect guarantee could move? (05,06,09) |
| D9 Failure/operations | Who owns timeouts, retries, errors, logs, metrics and recovery afterward? (06,09) |
| D10 Security/privacy | Could a seam shift authorization, identity context, sensitive data or least privilege? (07) |
| D11 Compatibility/rollout | Do consumers, schemas, providers or independent release cadences make migration unsafe? (03,09,12) |
| D12 Navigability | For a real future change, does responsibility become easier to find and verify? Don't infer from file count. (04,12) |
| D13 Economics/reversibility | Is benefit proportionate to tests, coordination, rollout risk; can a small probe answer it? (09,12) |
| D14 Project intent/history | Does an ADR protect a reason the proposal misses; did that reason genuinely change? (02,13) |

**Cross-trigger examples:** distributed authorization→05/06/07/09; retries→05/06/09/10; metric shift→02/08/10/11; data-contract change→03/05/06/09; inconsistent fake→09/10/11; deployment merger→03/09/12/13. Re-run the candidate comparison whenever a triggered check changes its assumptions.