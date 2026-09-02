# Bug Bounty Report Standard

Use this standard for the report, executable PoC, and evidence bundle. Optimize
for a triager who will not infer missing facts, adapt commands, or
cross-reference scattered material.

## Phase 0: Eligibility and Scope

Before drafting or live testing, verify the current program terms, in-scope
asset, eligible weakness, tester eligibility, safe-harbor conditions,
prohibited methods, data/rate limits, and disclosure rules. Record the source
and check date. Use `blocked` when terms cannot be confirmed and `ineligible`
when the finding or planned test falls outside them.

## Report Template

```markdown
# [Component/Endpoint] allows unauthorized [action] via [attack vector]

## Summary
[In 2-3 lines: what is vulnerable, where it occurs, required attacker access,
and the exact demonstrated consequence.]

## Prerequisites and setup
- Target version/build:
- Program/platform:
- Instance type/tier or deployment model:
- Required feature flags/configuration:
- Attacker role:
- Victim/security boundary:
- Controlled test data:
- PoC dependencies:

## Steps to reproduce
1. [Atomic setup or action]
   - Command/request:
   - Expected result:
2. [Next chronological action]
   - Command/request:
   - Expected result:
3. [Directly demonstrate the headline impact]
   - Decisive result:

## Expected versus actual
- Expected:
- Actual:
- Negative control:

## Root cause
[Version-pinned file and line link, vulnerable mechanism, and the missing
security condition. If the finding came from source-code analysis, include the
relevant source lines with concise annotations identifying the vulnerable flow
and missing check. State incomplete-fix lineage only when the cited prior
change touched the relevant class or sink.]

## Impact and severity
- Demonstrated business/security consequence:
- CVSS vector:
- Metric rationale:
- Required chain elements, if any:

## Recommended fix
[Short concrete remediation at the actual trust boundary.]

## Attachments
- Frozen PoC:
- Uncut transcript or recording:
- Evidence bundle:
- Run manifest:
- Snapshot hashes:
```

Omit `Expected versus actual` only when the primary steps already make both
states unmistakable. Do not add a manual fallback that duplicates a working
script.

## Claim-to-Evidence Gate

Maintain this matrix while drafting:

| Claim | Minimum evidence |
|---|---|
| Affected build and prerequisites | Version/config capture and preflight output |
| Attacker access and victim boundary | Setup transcript plus identity/role assertions |
| Vulnerable request or action | Timestamped command/request and relevant complete response |
| Headline impact | Uncut final-PoC transcript or recording showing the consequence |
| Root cause and patch lineage | Version-pinned source or diff references |
| Security-boundary contrast | Negative control that restores the missing condition or removes the bypass |
| Cleanup | Exact cleanup ledger and final-state assertions |

A marker, canary, parser hit, or callback proves only an intermediate primitive
unless that event is itself the claimed impact.

## Validation Vocabulary

- `syntax/static`: the artifact parses or source inspection supports the
  mechanism; it was not proven end to end.
- `previous-live`: an earlier or materially different variant ran.
- `full-live`: the exact frozen final artifact ran end to end and generated
  attachable evidence.

Editing executable steps, payloads, assertions, environment derivation,
material claims, or cleanup after a full-live run invalidates that run for the
new snapshot.

## Portable PoC Contract

- Put editable values in one environment or configuration block. Derive later
  URLs, IDs, paths, filenames, callback addresses, and commands from it.
- Preflight dependencies, versions, connectivity, tier/features, protocol,
  authentication, permissions, and clean state. Fail early with an actionable
  error.
- Refuse collisions with pre-existing users, groups, projects, files, ports, or
  other named state. Never overwrite or silently reuse non-run-owned objects.
- Assert every identity boundary, transition, denial, and final impact. A zero
  exit code is not evidence by itself.
- Capture timestamps, stdout/stderr, relevant requests/responses, versions,
  assumptions, assertions, cleanup, and a machine-readable run manifest.
- Attach artifacts rather than depending on external hosts.
- Log non-reversible secret fingerprints when correlation is enough. If the
  claim is usable-secret disclosure, prove controlled use with a safe
  authenticated action instead of treating metadata as a credential.

Narrate the frozen script's meaningful output in this form:

```text
[Stage 3] Unauthorized project data becomes readable
REQUEST -> GET /api/v4/projects/123/repository/files/controlled.txt
The low-privilege account requests a file it cannot read in the baseline.
RESULT -> HTTP 200 - controlled file contents returned
```

Keep setup IDs together near the start. Show baseline, exploit, negative
control, direct impact, cleanup, and final `PASS` or `FAIL` chronologically.
Suppress incidental tool noise, but preserve decisive requests, errors, status
codes, and asserted values. Copy the report excerpt from this exact output;
never hand-edit a cleaner transcript.

## Transactional Cleanup

Record every created object in a durable ledger immediately after creation.
Install cleanup handlers before mutation, unwind exact IDs/names in reverse
order, make cleanup idempotent, and assert final state. Use the same cleanup
path after success, assertion failure, and catchable `EXIT`, `INT`, or `TERM`.

Do not promise survival after `SIGKILL`, power loss, or equivalent abrupt
termination. Mitigate it with immediate journaling, next-run collision refusal,
and exact manifest-driven recovery.

## Root Cause, Severity, and Precedent

- Pin code links and quoted line numbers to the analyzed target version or
  commit, for example `lib/api/example.rb:128-134 @ <full commit>`.
- Explain the missing security check once. Do not repeat the same rationale in
  Summary, Root cause, and Impact.
- For an incomplete fix, name the CVE/MR/issue lineage and prove the earlier
  change touched the relevant class or sink while leaving this path open.
  Similarity alone is not lineage.
- Keep title, impact, and CVSS within the direct primary-PoC consequence. For a
  chain, list every required bug and justify the combined result.
- Attribute vendor advisories, prior reports, CVE records, and FIRST CVSS
  specifications precisely. An analogy is not program policy.
- Distinguish names, identifiers, fingerprints, topology, and secret-related
  headers from an actually reusable secret.

## Independent Frozen-Snapshot Review

One independent reviewer must verify the entire frozen package:

- Current scope and terms, caveats, precedent, lineage, terminology, and
  metadata-versus-usable-secret classification.
- One combined impact-and-severity case, its CVSS vector, direct impact, every
  claim-to-evidence row, and negative controls.
- Clean execution of the exact PoC, including config, preflight, collision
  refusal, assertions, uncut capture, secret handling, interruption cleanup,
  final state, and manifest hashes.

If the review cannot include clean independent execution, keep the package in
`draft` or `blocked`; do not substitute the writer's earlier run.
