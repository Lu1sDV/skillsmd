# Regression obligations and skill evaluation

**Status:** Proposed test design. The native scanner, benchmark pipeline, and JEV model were not executed for this review. The revision's mechanical checks validate document/trace consistency and preservation of the original examples, not detection accuracy.

## Two independent kinds of expected result

For every case retain source/contract assumptions, claim identity, scope, responsible rule(s), expected candidate admission, expected claim assessment, and actual execution receipt independently. `ruleid` or `ok` supplies only a native matcher expectation. A deliberately admitted safe candidate is not a false vulnerability verdict; an unsafe omitted candidate is not a safe negative.

Do not use one universal truth label for every effect in a file. A shell claim may be refuted while another process-related claim remains open. Conditional factories require concrete caller binding or an explicit justified educational contract before receiving a definite security label.

## Required case shapes

| Dimension | Required contrasting situations | Prevented failure |
|---|---|---|
| API/call binding | Positional/keyword/default/known expansion/unknown expansion; direct/alias/callback/factory | Spelling-based FP/FN and assumed runtime identity |
| Operand | Same external value in dangerous versus inert argument, tuple slot, field or key | Whole-call/whole-object taint promotion |
| Reaching state | Trusted→untrusted and untrusted→trusted; relevant→unrelated and reverse; conditional mutation | Stale construction/assignment assumptions |
| Control | Effective, absent, unenforced, wrong subject, rejection swallowed, alternate valid control | Presence-based or patch-shaped safety |
| Representation/context | Safe original context, reinterpretation, later decoding/recomposition, accepted-domain change | Non-durable sanitizer summaries |
| Effect timing | Before/after control, eager/lazy, used/unused, constructed/delivered | Retroactive safety and false effect claims |
| Paths/consumers | One unsafe feasible witness; all protected; mixed protected/unprotected; incompatible branches | Invalid joint inference or partial refutation |
| Coverage | Responsible rule, companion, replacement pack, previously supported nonbenchmark form | Delegation gaps and scope loss |
| Evidence | Missing key, present-but-incomplete, contradictory, stale, irrelevant, malicious comment | Forced answers, leakage and fabricated completeness |
| Execution | Syntax failure, skip, timeout, budget exhaustion, duplicate candidate, transport failure | False clean results and hidden unassessed work |

Apply every relevant dimension, and record why a dimension is not applicable. Do not require a full Cartesian product for every rule; require intentional combinations where mechanisms interact. In particular, challenge **reassignment + sliced access**, **safe serialization + changed response context**, **container mutation + selected operand**, **control + post-check transformation**, and **rule-local exclusion + companion handoff**.

## Admission truth table

| Security claim / scope | Candidate admission | Correct interpretation |
|---|---|---|
| Unsafe and within required supported scope | Present | Discovery success only; later assessment still needs validation |
| Unsafe and within required supported scope | Absent after valid relevant execution | Required discovery failure |
| Safe but within declared candidate inventory | Present | Intentional candidate; do not count as a model-accepted FP unless actually accepted |
| Genuinely safe within a detector claim | Absent after valid relevant execution | Eligible negative contrast, not universal safety proof |
| Conditional because required caller/API/policy is absent | Either | Unresolved applicability; not a definite TP/FN/TN merely from annotation |
| Outside one rule but delegated to another selected rule | Present only in companion | Check exact-operation ownership in the pack; not a requirement that every individual rule match |
| Relevant analysis missing/failed | Absent | Execution limitation under the declared protocol, not a clean pass |

## How to test each trace

[Structured error traces](error-traces.json) supply T01–T42, linked to E01–E42 and gates G01–G12. Convert an obligation into an inert fixture or an actual integration test only after its API/runtime premises are supplied. Test both the responsible rule and selected pack where coverage composition is relevant. Keep tests designed to detect a vulnerability mechanism separate from native parser/admission probes.

For procedural paths, cover both justified positive and justified negative conclusions with a transport that fails if called. Zero requests plus the correct claim-specific result is the acceptance condition. An unsupported procedural shape does not automatically enter the model queue.

For model paths, test actual serialized input and answer-domain interpretation using labeled synthetic transport responses for orchestration only. Those responses do not establish model accuracy. Any live study requires separate source-upload authorization and a frozen protocol. Inspect source-derived evidence completeness independently of JSON shape.

## Gate ledger

Each gate records `required_for_declared_scope`, `status` (not_run, blocked, passed, failed), artifact and source identities, actual invocation/condition, observed results, and unresolved limitations. Model execution status and security assessment remain separate. These are proposed authoring-side fields, not invented OpenGrep/JEV syntax.

Promotion requires all required in-scope gates to pass. A conditional challenge cannot be converted into a guaranteed vulnerability solely to manufacture a failure, and an unsafe required failure cannot be moved out of sight to manufacture a pass. A documented scope change preserves the former obligation and its resulting coverage impact.

## Test whether the revised skill actually improves authoring

Use the same agent/tool setup on paired tasks under the original and revised skill, with fixed resource and permission budgets. Start each task with a clean context; randomize assignment/order where appropriate and keep groups of related templates/pairs together. Review outputs without revealing the instruction condition when practical.

Use independently reviewed hidden tests that target the mechanisms above, not exact phrases in the new skill. Include tasks where the correct outcome is a native repair, a procedural augmentation, a residual question, a request for missing evidence, or no defensible rule. Keep the original OWASP cases as development evidence, and use unrelated held-out cases for generalization.

Evaluate rule-level and whole-pipeline false positives/false negatives, preserved old coverage, invalid syntax/contracts, unjustified claims, unresolved/blocked handling, evidence integrity, unnecessary model requests, and analyst/model cost. Report partial outcomes, failures and instruction regressions; measure both task success and failure-severity profiles rather than ranking by rule count or prose compliance.

Predeclare criteria and meaningful non-regression bounds appropriate to the use case; none are measured or calibrated by this document. If the revised skill produces fewer unsafe exclusions but more unbounded candidates, report both rather than declaring unconditional improvement. Finite success does not establish zero error.

## Attribution

Adapted skill guidance is CC BY-SA 4.0, retaining Lu1sDV and Trail of Bits attribution from the original skill. Third-party code, datasets and documentation retain separate terms.
