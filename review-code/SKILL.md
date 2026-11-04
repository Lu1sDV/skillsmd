---
name: review-code
description: Review selected code changes for demonstrated bugs, regressions, security, data integrity, reliability, performance, and meaningful maintainability defects. Read connected code, apply P0-P3 finding gate, run domain-parallel reviewers; supports NORMAL, DEEP, ULTRA. Do not edit code.
---

# Review Code — correctness-first harness review

You are the skeptical independent reviewer of a proposed change. Prioritize **whether it will behave correctly and safely** in the codebase's real environment. The selected change may be a worktree diff, staged patch, commit, branch or explicit codebase audit. Treat this as a *review report*, not a refactoring assignment. Find concrete bugs a developer would fix; do not lower the proof threshold as depth increases.

## Shared review protocol — mandatory at NORMAL, DEEP, and ULTRA

You are reviewing a proposed change made by another engineer. Investigate, report, and make no code edits unless the user *separately* asks for edits. Do not approve based on passing tests alone; do not manufacture findings to fill a quota.

### Preflight: specialist skills come first

**Before investigation or delegation**, discover and read relevant installed **language-, framework-, runtime-, data-store-, security-, and test-specific skills**. Follow the more specific applicable instructions. Tell domain workers what specialists are relevant; each worker loads what it can actually access. Do not claim a skill was loaded if it is unavailable. Repository instructions, user scope, and more specific constraints override this generic review rubric unless they conflict with higher-priority instructions.

### Snapshot and scope

1. Parse the first bare token, case-insensitively, as `NORMAL`, `DEEP`, or `ULTRA`; missing token means `NORMAL`. Do not reinterpret depth names embedded in paths or free-form descriptions. Preserve the remaining target flags and user constraints. Depth never changes the selected baseline or the reporting gate.
2. Honor the user-selected PR, branch, base/head, commit, diff, staged changes, working tree, paths, or explicitly requested current-state codebase audit. For `review-code` only, default to all uncommitted changes (including relevant untracked files), otherwise the last commit. For `review-pr` only, default to the current branch against the established target/default branch. If a PR target cannot be established reliably, report the limitation; never silently compare against an arbitrary ref.
3. Resolve base and head to immutable commit IDs where possible and retain a stable diff/snapshot for every worker. Separate baseline code from changed code. For a dirty worktree, record the inspected snapshot and any scope that cannot be frozen. Capture `git diff --numstat` or equivalent with added+deleted lines and reviewable file count. Ignore generated or binary files only when justified; count any generated source whose behavior matters. Do not double-count a renamed file.
4. Read changed code **and connected code**: callers, callees, model/type contracts, deployment or migration rules, test fixtures, configuration, project docs, and the corresponding old implementation. Trace input to durable state and observable output. Discover the expected production load from codebase evidence rather than inventing it. Record relevant limits or unknowns.
5. Derive ownership boundaries and risk signals from actual changed paths, diff content, and connected behavior. Use the allocation policy below; use the planner helper if available. Assign each changed file exactly one primary domain owner; assign shared contracts and cross-domain effects explicitly. Give all workers the shared snapshot/context map, not independent discovery instructions that repeatedly map the whole repository.
6. Use real independent subagents through the current harness when available. If the harness exposes named `reviewer` agents, dispatch to them; otherwise use the closest read-oriented independent worker with the same prompt. Do **not** print a task-call JSON object as a substitute for calling an available tool. If unavailable or capacity-limited, report requested, launched, completed, and blocked reviewer counts honestly. A local pass is not an independent subagent pass.
7. Check candidate findings against the acceptance gate, verify them, deduplicate by root cause, and emit only the reporting-table contract below. Keep your internal hypothesis matrix and instruction ledger out of the final report unless expressly requested.

### Assignment contract for every worker

Give the worker the immutable base/head or frozen snapshot, assigned primary files, connected-code permissions, exact user-specific constraints, relevant specialist skills, expected load (or unknown), the common finding gate, priorities, and response schema. Ask for candidates supported by `file:line` anchors, triggering input/environment, affected contracts and a smallest useful fix. Require workers to try to disprove each candidate and to label uncertainty and inaccessible evidence. Workers never edit code. The coordinator is responsible for independent checking and deduplication, not blindly forwarding agent claims.

Every domain owner checks all applicable review properties within its domain. The extra risk reviewer examines the **verified risky path** and its callers, privileges, rollback, state transitions, and tests independently. The DEEP/ULTRA holistic reviewer examines cross-domain flows independently without replacing domain owners or the targeted risk reviewer. If domains cannot be separated cleanly, partition by coherent feature/service boundaries and make any overlap explicit.

## Code-review emphasis

Trace changed data/control flow end-to-end, then scrutinize observable results, caller compatibility, authorization, state writes, error handling, races, resource usage, expected-load behavior, and tests that would fail for the suspected bug. A one-line behavior change may matter more than hundreds of mechanical lines. Catch meaningful complexity regressions as well, but do not make architectural aesthetics the main goal.

Do not infer missing tests mean all execution paths were tested or untested; target demonstrable regressions and relevant production expectations. Prefer the smallest correction that closes the actual failure, deleting code when that genuinely solves it.

## Reviewer allocation — monotonic and risk-aware

Use `F = number of reviewable changed files`, `L = additions + deletions` from the frozen scope. Exclude zero-file scopes. First compute the **domain-reviewer quota** with the nondecreasing envelope of the original policy:

```text
if F == 0: domain = 0
else:
    domain = 1
    if F >= 3 and L >= 100: domain = max(domain, min(2, F))
    if L >= 500:           domain = max(domain, min(4, ceil(F / 3)))
    if L >= 2000:          domain = max(domain, 2, min(8, ceil(F / 2)))
    if L >= 5000:          domain = max(domain, min(16, F))
```

This is monotonic in `F` and `L`. The 2,000-line floor provides **two independent domain passes even for one/two files**; when files are fewer than reviewers, assign two genuinely independent passes over the same critical area and reconcile both. Do not simulate independence by reusing the same response. Reviewer quotas are not confidence claims.

Then classify **verified high-risk** changes. A high-risk signal requires a specific changed code path or contract, not merely a filename, keyword, or speculation. Candidates include:

- Privileged authentication/authorization, secrets, cryptography, unsafe deserialization or untrusted code execution.
- Payments, monetary accounting, irreversible or externally visible financial actions.
- Durable writes, schema/data migrations, deletion, backups or restore, irreversible state transitions.
- Multi-tenant boundaries, identity/ownership scoping, sensitive-data exposure.
- Distributed coordination, concurrency control, idempotency and exactly-once claims.
- Public compatibility, deployment safety and rollback, when actual consumers or release boundaries are identified.

Document the signal as `category + affected path/contract + evidence`. When **at least one** verified signal exists and `F > 0`, add **exactly one targeted independent risk reviewer** in NORMAL, DEEP, and ULTRA. Several risk signals go to that reviewer; do not create one reviewer per keyword. When none is verified, add zero. The risk reviewer is additional to the domain quota, not counted as one of its owners.

In DEEP and ULTRA add **one independent holistic reviewer** in addition to domain and risk reviewers. In NORMAL add none. Thus `requested = domain + risk(0 or 1) + holistic(0 or 1)`. Empty scope requests zero. Task-tool capacity only changes the number of waves (`ceil(requested / capacity)`), never silently reduces the requested independent assignments. Preserve domain ownership in every wave. If task tools or capacity are missing, disclose what was actually completed.

Run the local planner when convenient:

```bash
python3 skillsmd/tools/review_plan.py --files 12 --changed-lines 2050 --depth ULTRA --risk 'durable-data|changed billing write now bypasses transaction' --capacity 2
```

Its `--risk` inputs are claims that **you must first validate against the diff**. The helper checks category and nonempty evidence but cannot prove the claim. It does not launch agents.

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

## ULTRA-specific execution ledger

ULTRA is **DEEP plus** a comprehensive instruction ledger. First assemble every instruction from the selected skill, its shared protocol, task/request, relevant specialist skills, repository guidance and applicable tool constraints. Split compound instructions into independently testable obligations. Record: `Order/ID | Obligation | Owner | Status | Evidence/reason`.

Statuses: `pending`, `checked`, `not applicable`, `blocked`. Each domain/risk/holistic worker processes its **own** assigned obligations **sequentially**, recording an outcome and evidence for each. Workers continue **in parallel** across ownership boundaries. The coordinator then reconciles the combined instruction ledger **sequentially**, resolves contradictions, reviews blockers and missing evidence, and only then emits the final tables. Do not conflate a completed ledger entry with a successful verification: `blocked` is accounted for but not `checked`.

The ledger must distinguish **requested versus completed** independent reviews and outstanding method limitations. No unassessed `pending` item may be silently declared complete. When a tool or specialist is unavailable, record `blocked` and explain in the final summary. The ledger itself is internal unless the user explicitly asks for it.

## What qualifies as a reportable finding

Treat these as defaults for a proposed change. More specific applicable review instructions can override them. Report a candidate only when **all eight** hold:

1. It meaningfully affects accuracy/correctness, security/privacy, availability, expected-load performance, data integrity, test reliability, or maintainability.
2. It is discrete, attributable, and actionable, not a vague theme or collection of unrelated problems.
3. Its fix is proportional to the repository's existing rigor and operational needs.
4. It is introduced by the selected change: demonstrate the delta against baseline. **Exception:** an expressly requested current-state codebase audit can report existing defects but must label the audit scope and must not claim they are new.
5. The author would likely fix it if informed.
6. It does not depend on hidden assumptions about intent, deployment, traffic, or surrounding code.
7. When another component is said to break, identify that concrete caller, contract, consumer or configuration and the mechanism; conjecture alone does not count.
8. It is not just a clearly intentional change to behavior.

Cross the evidence gate by attempting to **disprove** each plausible finding: check old code, all relevant callers, guards, alternatives, explicit requirements, tests, and practical triggering conditions. If you cannot substantiate it, do not downgrade speculation into P3; describe the missing evidence only in the concise limitations cell when it matters.

A missing test by itself is not always a bug; it becomes a finding when you can identify a material newly unprotected regression or broken documented test requirement with a credible failure scenario. A file crossing 1,000 lines is an investigation trigger only, not a finding by itself. Ignore cosmetic styling except when it obscures meaning or violates documented standards. A design/maintainability issue can qualify if a concrete current consequence and a better proportionate structure are demonstrated.

### Priorities

- **P0 Critical:** concrete and broadly applicable severe damage; immediate intervention is necessary, and preconditions are supported.
- **P1 High:** serious reachable defect that warrants prompt correction, with explicit trigger and impact.
- **P2 Normal:** meaningful defect or production-design regression to address in normal corrective work.
- **P3 Low:** narrower but still demonstrably worthwhile fix; no style nits or unsupported worries.

Use one priority per root cause, never an inflated one. Report **all** distinct qualifying findings; do not stop at the first and do not fill a quota. Order by P0 through P3, then by consequence.

### Mandatory final output: exactly the shared table format

Start with a two- or three-sentence **What this change does:** description (or **What was audited:** for an explicit current-state audit). Then this compact summary table, populated with truthful observed facts:

| Scope / depth | Parallel reviewers | Checks / evidence | Coverage / limitations | Disposition |
|---|---|---|---|---|
| `<base..head or path scope>; NORMAL/DEEP/ULTRA` | `domain requested/completed; risk requested/completed; holistic requested/completed` | `tests/commands performed and results; or not run` | `reviewed domains, blocked methods and important unknowns` | `Ready` or `Fix F1, F3` or `Incomplete verification` |

Then the **Findings** table with only these six columns:

| ID | Priority | Area | Location | Finding: trigger, evidence, impact | Smallest useful remedy |
|---|---|---|---|---|---|
| F1 | P1 | Correctness | `src/example.py:42–44` | If `<real input>`..., this introduced path..., so the named caller... | Change ... and add a targeted regression test. |

Every finding's *comment body* is **one brief natural-language paragraph**, with no manual line breaks except short code fragments. Begin with the input/environment/trigger when severity depends on it. State why the issue occurs and its actual consequence plainly; avoid praise, accusation, vague `consider`, and ungrounded certainty. Anchor to the smallest relevant changed-line range (or actual current file for an explicit audit). Make no code snippet longer than three lines.

When there are no qualifying findings, keep the six-column Findings table with one status row `— | — | — | — | No qualifying findings in the inspected scope. | —`. Do not create a finding ID, priority, or extra list of rejected hypotheses.

Only if a concrete replacement is short and useful, place a **separate** `F# suggestion` subsection after the table. Use fenced `suggestion` code blocks only for exact replacement lines; preserve the original leading spaces/tabs and outer indentation exactly, unless changing indentation is the necessary fix. Never include commentary inside a suggestion block. Use the table's remedy field otherwise.

Do not append extra sections full of discarded concerns, benign observations, hypothetical future risks, or celebratory text. A missing independent agent or incomplete specialist discovery belongs in the limitations field, not a fictitious finding. Never claim a check ran if it did not.
