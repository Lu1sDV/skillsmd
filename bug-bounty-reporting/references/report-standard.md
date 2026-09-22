# Bug Bounty Report Standard

Artifact contract behind `SKILL.md`. Everything here serves three readers:

- **The triager** — already has the report open and a VM. They will not transfer
  files, reconstruct state, or adapt commands.
- **The vendor team** — hands the bug to devs who work without your proxy, then
  re-runs the PoC to confirm the fix.
- **You** — drop the script in a terminal, watch it narrate the bug, click
  report.

## Codify the Report, Then Unit-Test It

1. **Codify.** One script sets the scene and walks the logic: this app does XYZ,
   here is who we are, the attacker cannot reach the data this way, then reaches
   it that way. It shows the actual HTTP requests. Done right, the written
   report is a wrapper — the PoC already explains why this is a vulnerability.
2. **Unit-test.** Assertions plus a negative control that fail the run when a
   claim stops being true. A claim with no failing case behind it is a guess
   with formatting.

Label the principals `attacker` and `victim`, never `user1`/`user2`. That
removes all ambiguity about session ownership, in the output and in the report.

## Report Template

```markdown
# [Component/Endpoint] allows unauthorized [action] via [attack vector]

## Summary
[2-3 lines: what is vulnerable, where, attacker access required, exact
demonstrated consequence.]

## Setup
- Target version/build, program/platform, instance type or tier:
- Required feature flags or configuration:
- Attacker role and victim/security boundary:
- Controlled test data:
- PoC entry point and dependencies:

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
[Version-pinned file and line link, vulnerable mechanism, missing security
condition. If the finding came from source analysis, include the annotated
source lines showing the vulnerable flow. Claim incomplete-fix lineage only
when the cited prior change touched the relevant class or sink.]

## Impact and severity
- Demonstrated consequence:
- CVSS vector and metric rationale:
- Required chain elements, if any:

## Recommended fix
[Short, concrete, at the actual trust boundary.]

## Attachments
- Frozen PoC, uncut transcript, evidence bundle, run manifest, snapshot hashes:
```

The repro steps run against the same single config block the PoC uses. If the
triager has to edit commands for their environment, the report is not done.
Omit `Expected versus actual` only when the primary steps already make both
states unmistakable, and never add a manual fallback that duplicates a working
script.

## Portable PoC Contract

- Put editable values in one environment or configuration block; derive later
  URLs, IDs, paths, callbacks, and commands from it.
- Preflight dependencies, versions, connectivity, tier/features, auth, and
  permissions; fail early with an actionable error.
- Refuse collisions with pre-existing users, groups, projects, files, or ports.
  Never overwrite or silently reuse non-run-owned state.
- Assert every identity boundary, transition, denial, and final impact; a zero
  exit code is not evidence by itself.
- Capture timestamps, stdout/stderr, relevant requests/responses, versions,
  assumptions, assertions, cleanup, and a machine-readable run manifest.
- Attach artifacts instead of depending on external hosts.
- For secrets, log non-reversible fingerprints when correlation is enough. When
  the claim is usable-secret disclosure, prove controlled use with a safe
  authenticated action; metadata is not a credential.

Narrate meaningful output in this form:

```text
[Stage 3] attacker reads a file the victim never shared
REQUEST -> GET /api/v4/projects/123/repository/files/controlled.txt
attacker session; the same request as victim returned 403 in the baseline.
RESULT  -> HTTP 200 - controlled file contents returned
```

Keep setup IDs together near the start. Show baseline, exploit, negative
control, direct impact, cleanup, and final `PASS`/`FAIL` chronologically.
Suppress incidental tool noise but preserve decisive requests, status codes,
errors, and asserted values. Copy the report's excerpt from this exact output;
never hand-edit a cleaner transcript.

## Unit Tests Behind the Claims

Each row is something the PoC must actually check:

| Claim | Minimum evidence |
|---|---|
| Affected build and prerequisites | Version/config capture and preflight output |
| Attacker access and victim boundary | Setup transcript plus identity/role assertions |
| Vulnerable request or action | Timestamped request and relevant complete response |
| Headline impact | Uncut final-PoC transcript showing the consequence |
| Root cause and patch lineage | Version-pinned source or diff references |
| Security-boundary contrast | Negative control that restores the missing condition or removes the bypass |
| Cleanup | Exact cleanup ledger and final-state assertions |

A marker, canary, parser hit, or callback proves only an intermediate primitive
unless that event is itself the claimed impact.

## Evidence Vocabulary

- `syntax/static` — the artifact parses or source inspection supports the
  mechanism; not proven end to end.
- `previous-live` — an earlier or materially different variant ran.
- `full-live` — the exact frozen artifact ran end to end and produced
  attachable evidence.

Editing executable steps, payloads, assertions, environment derivation,
material claims, or cleanup after a full-live run invalidates that run for the
new snapshot.

## Transactional Cleanup

Record every created object in a durable ledger at creation time. Install
handlers before mutating, unwind exact IDs/names in reverse order, make cleanup
idempotent, and assert final state. Use one cleanup path for success, assertion
failure, and catchable `EXIT`, `INT`, or `TERM`. Do not claim survival after
`SIGKILL`, power loss, or equivalent; mitigate with immediate journaling,
next-run collision refusal, and manifest-driven recovery.

## Independent Frozen-Snapshot Review

One independent reviewer verifies the frozen package: current scope and terms,
caveats, lineage, terminology, metadata-versus-usable-secret classification;
the combined impact-and-severity case, its CVSS vector, and every claim row with
its negative control; and a clean execution of the exact PoC including config,
preflight, collision refusal, assertions, uncut capture, cleanup, final state,
and manifest hashes.

Without clean independent execution, the package stays `draft` or `blocked`.
The writer's own earlier run is not a substitute.
