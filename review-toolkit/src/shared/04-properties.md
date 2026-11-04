## Required review properties and depth-specific hypothesis work

Inspect **each applicable** property in the selected changed code and its connected contracts; mark irrelevant properties not applicable in ULTRA rather than skipping silently:

| Property | Ask about the actual code |
|---|---|
| Correctness & contracts | Empty, zero, bounds, rounding, timezone, Unicode, ordering, changed return values, consumers and invariants. |
| Security & privacy | Trust boundaries, authorization, injections, secrets, tenant ownership and data leaks. |
| Data integrity & atomicity | Partial writes, retries, migrations, rollback, duplicate operations and interrupted transitions. |
| Concurrency & distribution | Races, stale reads, idempotency, multiprocess state, timing and ordering. |
| Reliability & recovery | Timeouts, cancellation, dependency outages, resource cleanup and restarts. |
| Performance & resource use | Realistic traffic, algorithmic cost, query fan-out, unbounded growth, hot loops and serial work. |
| Tests & observability | Regressions, assertions that actually fail, fixture realism, integration, diagnostics and alerts where material. |
| Architecture & ownership | Module boundaries, canonical helpers, types, contracts and duplicated policy. |
| Readability & maintenance | Cognitive load, branching, opaque optionality, comments that explain real invariants and documented style. |
| Simplicity & dependencies | Dead code, accidental modes, speculative abstractions, nonessential wrappers, avoidable dependencies. |
| Configuration & deployment | Feature flags, environment differences, version compatibility, releases, rollbacks and migrations. |

At NORMAL, inspect these within each assigned domain and validate candidate findings.

At DEEP and ULTRA, additionally perform a **mind-squeezing hypothesis matrix** for each applicable property, progressing from everyday inputs through boundaries, failures, cross-boundary interactions, and plausible compound/complex cases:

`Property | Actual invariant/contract | Trigger/compound scenario | Failure hypothesis | Evidence/check | Outcome`

The hypothesis work is adversarial: try to falsify the design *and* to falsify each alleged defect. Seek increasingly complex but **reachable** edge cases, grounded in code, configuration, inputs, consumers, and real constraints. Do not invent unverified capabilities, users, or execution paths. Stop when each applicable property has an evidence-backed result or a disclosed blocker and further cases repeat the same mechanism or require unsupported premises. An unchecked hypothesis is never a reportable finding.

In DEEP and ULTRA, spawn exactly one **additional independent holistic** reviewer with this directive, plus the common gate and snapshot:

> Review the selected PR, branch, or CODEBASE thoroughly and holistically, even for readability and bad practices. Inspect cross-domain interactions and opportunities for meaningful simplification; keep the same trigger/evidence gate, baseline, and output schema. Do not return style-only feedback or unproven concerns.

Holistic review is additive; it does not replace domain owners or the targeted high-risk reviewer.
