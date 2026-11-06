# Security Test-Driven Development (Security TDD)

Detail for [test-engineering](../SKILL.md). Load for security-relevant features,
modifications, vulnerability fixes, or security-test review. Security TDD checks
that security guarantees hold under malicious inputs, insufficient permissions
and intentional workflow abuse. Integrate it into ordinary TDD, not a final scan.

## Quick Reference

| Need | Action |
|---|---|
| Decide whether security tests apply | Assess changed boundaries and threats; record applicability (§1) |
| Define what a test must establish | State an independent invariant and forbidden effects (§2) |
| Implement or repair security behavior | Red–green–refactor with detection evidence (§3) |
| Select abuse cases and test level | Follow actual attack paths; preserve real enforcement (§4–5) |
| Complement behavioral tests | Choose risk-relevant analysis and specialist assessment (§6) |
| Execute, retain and gate checks | Isolate safely; preserve regressions; do not hide failures (§7–9) |
| Report assurance limits | Record traceability, observed results and residual risk (§10) |

## 1. Assess security relevance

For every feature, modification or vulnerability fix, identify security properties
that could be introduced, weakened or bypassed. Inspect:

- Trust boundaries, entry points, untrusted inputs and external dependencies.
- Authentication, authorization, roles, permissions, ownership and tenant isolation.
- Sensitive data, secrets, sessions, credentials and cryptographic operations.
- State-changing operations, resource consumption and business-critical workflows.
- Security assumptions the change could invalidate, including deployment assumptions.

Prioritize plausible attack paths using the application's threat model, exposure
and impact. State relevant risks and reasons considered categories do not apply;
security relevance is mandatory to assess, not a mandate to test every category.
If the security contract is missing or ambiguous, identify the assumption and
obtain the responsible owner's decision before treating it as an acceptance rule.

## 2. Define observable security invariants

Before implementation, derive invariants from the security contract and applicable
requirements, independently of current implementation output. State the actor,
resource, preconditions, threat, expected outcome and forbidden side effects.
Examples of properties to consider, not a universal checklist:

- Unauthorized actors cannot read or modify protected resources across user,
  privilege or tenant boundaries; permitted actors retain legitimate access.
- Security-control or dependency failure cannot silently grant access.
- Untrusted input cannot cross an execution or interpretation boundary unsafely.
- Missing, invalid, expired or revoked credentials cannot authorize an operation.
- Security failures do not expose confidential data or secrets in responses or logs.
- Repeated, reordered or concurrent operations preserve business constraints.
- Resource consumption stays within explicitly defined safety limits.

Assert observable responses **and resulting state**, including absence of forbidden
writes, disclosures or external effects. An error response alone does not establish
that an unauthorized action did not occur. A mocked policy decision does not
establish that the application enforces it.

## 3. Apply red–green–refactor

Use the existing task-stage and test-quality gates in [SKILL.md](../SKILL.md);
load the language TDD skill for runner, fixtures and implementation mechanics.

**RED — demonstrate the requirement.** Before introducing or changing security
behavior, write the relevant tests. For each significant invariant, consider a
permitted case, a prohibited case and an adversarial bypass attempt. These are
case-selection prompts, not a quota of three new tests: reuse named adequate
coverage and avoid duplicate observations. Run the tests; security-relevant red
must demonstrate the forbidden behavior or missing protection, not broken setup,
compilation or an unrelated error. Existing protections may already pass; do not
weaken them to manufacture red. If detection needs checking, use a controlled
negative control or mutation only in an isolated test environment.

For a vulnerability repair, first reproduce the original exploit condition with
a failing regression test, then observe it passing with the fix. If reproduction
is unsafe or not reasonably automatable, record why, the closest safe evidence
and the remaining verification needed; never claim observed red without it.

**GREEN — minimum correct protection.** Implement or repair the control until the
relevant tests pass. Do not relax assertions, accept insecure results or add
test-only security bypasses to get green.

**REFACTOR — preserve the guarantee.** Improve code and tests without changing
invariants, then rerun affected security and functional regressions. Record the
actual command, source revision/build, selected tests, result and skips; an empty
selection, stale build or masked exit status is not a successful run.

## 4. Derive negative and abuse cases from threats

Use actual boundaries and attack paths, not arbitrary bags of attack strings.
Select relevant combinations of:

- Missing, malformed, expired, revoked or insufficient credentials.
- A valid identity changing user, role, tenant or resource identifiers.
- Manipulated parameters, request structure, types, encodings, lengths and limits.
- Replayed, skipped, reordered or duplicated workflow steps.
- Concurrent operations violating consistency or business rules.
- Dependency failures, malformed responses and unsafe fallback behavior.

Each case must name the threatened invariant and assert the protected outcome
and state. Payload collections are inputs, not an oracle. OWASP Top 10 is useful
for risk awareness, not a complete test specification or a substitute for ASVS
requirements and application-specific threats.

## 5. Choose the cheapest faithful level

| Level | Security evidence it can provide |
|---|---|
| Unit | Isolated policies, validation, authorization decisions, security-state transitions and failure behavior |
| Integration | Real enforcement through API routes, authentication/authorization middleware, persistence and tenant boundaries |
| E2E | Full workflows, deployment configuration, browser behavior or multi-service interactions that cannot be observed faithfully below |
| Property-based / fuzz | Explicit invariants over large input spaces, parsers, validators, protocols and stateful workflows |

Use realistic synthetic identities, roles, permissions and resource ownership.
Do not mock away the control or boundary being verified. Use a real store and
transaction behavior for persistence or concurrency claims; a unit policy test
cannot establish route enforcement. Inject dependency faults at the appropriate
boundary without replacing the protection under test. Prefer cheaper deterministic
tests when they offer equivalent evidence; do not duplicate them in E2E by default.
Bound generated cases and resources, preserve failing inputs/seeds, and use the
language skill or `fuzzgpt` for execution details.

## 6. Complement TDD with other verification

Security TDD alone is insufficient assurance. Based on risk and project policy,
complement behavioral checks with SAST, software composition/dependency analysis
(SCA), secret scanning, infrastructure/configuration checks, DAST, focused fuzzing,
security review and authorized penetration testing. Scanner configuration belongs
to the relevant tooling documentation, not this framework-agnostic skill.

Keep scanner findings distinct from executable security acceptance tests. A clean
scan does not verify application-specific authorization or business logic. Triage
findings for false positives, exploitability, context and compensating controls.
Escalate complex, high-impact or difficult-to-automate threats for specialist review;
name the owner and verification needed rather than implying automation covers them.

## 7. Execute safely and reliably

- Use synthetic data and test-only credentials. Never put real secrets or user
  data in fixtures, generated cases, logs, diagnostics or reports.
- Isolate state and external effects. Control time, randomness and concurrency
  where practical; use explicit synchronization rather than sleeps for races.
- Preserve reproducible failing inputs/seeds in a safe location; redact sensitive
  artifacts without discarding the information needed to reproduce the failure.
- Run intrusive, destructive or resource-intensive checks only against explicitly
  authorized, isolated targets, with bounded resource use and cleanup. An available
  URL or credentials are not authorization to attack a system.
- Make failures actionable without revealing secrets. Distinguish an environment
  or setup failure from a verified security outcome.

Keep fast deterministic security tests in ordinary suites and CI. Schedule costly
or intrusive checks separately with a named owner and trigger; explicitly report
checks not run. Scheduling separately does not make required verification optional.

## 8. Preserve security regressions

Every confirmed security defect needs a permanent regression check when reasonably
automatable. Reproduce its original failure condition and demonstrate the restored
property, not just that a patch-specific helper was called. Examine similar
components, sibling callers and trust boundaries when the defect suggests a
systematic weakness. If automation is impractical, document the reason and the
alternative verification with an owner. Retain the check unless the protected
behavior is intentionally removed or replaced by equivalent coverage.

## 9. Apply risk-based gates

Confirmed failures of mandatory security invariants block delivery. Never silently
suppress, skip, retry or quarantine them to obtain green; a visible quarantine
tracks a flake but does not discharge a security requirement. Unresolved high-impact
findings require explicit review and documented risk acceptance by the responsible
authority, not unilateral acceptance by the test author. An exception must identify
its scope, owner, rationale, compensating controls and review or expiry condition.
Record an approved requirement exception explicitly; until then the gate remains
blocking, and an accepted risk must not be reported as a passed test.

## 10. Report security evidence

Use within the parent strategy/output, not as a separate mandatory report for
unrelated work. For planned work, mark execution as not run; fill observed results
only after execution.

| Property / requirement + version and verified ID or source | Threat / abuse case | Test / level | Expected outcome + forbidden effects | Observed result / command / revision | Regression evidence |
|---|---|---|---|---|---|

Also state considered non-applicable risks and reasons, unrun checks, coverage gaps,
residual risks, approved exceptions (owner, rationale, review/expiry) and specialist
verification needed. Report scanner findings and their triage separately. Do not
claim comprehensive security, compliance certification or absence of vulnerabilities
from passing automated checks. Test coverage and security assurance are not synonyms.

## Conceptual examples

These describe assertions and observation points, not runnable test implementations.

| Scenario | Invariant | Cases and observations | Faithful level |
|---|---|---|---|
| Cross-tenant invoice access | Valid authentication never grants another tenant's protected invoice access | Owner read/update succeeds; another tenant's valid user substitutes the invoice ID for read/update; assert contract-defined denial, no invoice disclosure and unchanged stored invoice after the rejected write | Integration through real identity/authorization middleware and persistence |
| Password reset token | A token authorizes reset only while valid and at most once | Valid reset succeeds; replay and expiry at the contract-defined boundary are rejected; verify credential state is unchanged after rejection and responses/logs do not reveal the token; use a controlled clock | Integration across token verification, consumption and credential storage |
| Concurrent voucher redemption | A single-use voucher produces its benefit at most once | Verify ordinary redemption, then coordinate two competing requests for a fresh voucher; assert exactly one benefit in durable business state, not merely one error response; retain rejected/repeated-use coverage | Integration with real transactions; use a faithful concurrency harness, not sequential calls or sleeps |

## Reference policy

Use established guidance for distinct jobs rather than inventing a methodology.
The versions below are explicit baselines, not timeless claims about the latest
release. Verify official publication status before changing a baseline or claiming
one is current; do not silently substitute development or draft requirements.

| Reference | Role |
|---|---|
| [OWASP SAMM — Requirements-driven Testing](https://owaspsamm.org/model/verification/requirements-driven-testing/) | Lifecycle: positive/negative control verification, misuse/abuse and security regressions; this skill integrates those practices into TDD |
| [OWASP ASVS 5.0.0](https://github.com/OWASP/ASVS/tree/v5.0.0) | Verifiable web-application requirements: what must hold |
| [OWASP WSTG 4.2](https://wstg.owasp.org/v4.2/) | Applicable web testing techniques: how to investigate requirements |
| [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/) | Control-specific implementation guidance; [Authorization Testing Automation](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Testing_Automation_Cheat_Sheet.html) illustrates role/resource matrices |
| [NIST SP 800-218 SSDF 1.1](https://csrc.nist.gov/pubs/sp/800/218/final) | Secure development process, especially PW.8 executable-code testing |
| [NIST IR 8397](https://csrc.nist.gov/pubs/ir/8397/final) | Complementary developer verification: threat modeling, automated tests, analysis, fuzzing and included-code review |

For web applications, use ASVS Level 2 as the general reference target unless the
project defines another risk-appropriate level. L1 is the entry baseline; L3 is
for higher assurance. This is a skill default, not a claim that every application
must meet L2 or every feature must implement every control. ASVS itself calls for
risk-based level selection; see its [versioned scope and levels](https://github.com/OWASP/ASVS/blob/v5.0.0/5.0/en/0x03-What-is-the-ASVS.md).
Adapt to the software platform and organizational requirements, documenting
non-applicability rather than forcing web controls onto unrelated systems.

Verify requirement text and identifiers in the chosen version. Use version-qualified
ASVS IDs (`v<version>-<chapter>.<section>.<requirement>`) and versioned WSTG scenario
references when available. Never invent an ID: if it cannot be verified, cite the
source/section, label the mapping unverified and do not claim conformity. Some
requirements need design/documentation review rather than executable tests;
record that evidence separately instead of manufacturing boilerplate tests.
