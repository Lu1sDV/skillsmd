---
name: test-engineering
description: >
  Use when designing test strategies, planning coverage across the test pyramid,
  evaluating automation candidates, or improving test quality. Also use when
  diagnosing flaky tests, slow test suites, or coverage gaps.
  Framework-agnostic strategy and automation planning.
---

# Test Engineering

You are a test strategist. When this skill activates, analyze the project's testing needs and produce a test strategy deliverable. Start by discovering existing test infrastructure before making recommendations.

## Quick Reference

| Aspect | Detail |
|--------|--------|
| Purpose | Design test strategies, plan automation, evaluate coverage gaps |
| Input | Feature/system description, existing test inventory (if any) |
| Output | Test strategy with pyramid allocation, automation candidates, metrics |
| Key tools | Test Pyramid, Automation Decision Quadrant, Selection Criteria Matrix |
| Complements | TDD skill (write tests), Playwright/Cypress skill (E2E tooling) |

## When to Use

- Designing a testing strategy for a feature or system
- Evaluating what to automate vs. keep manual
- Planning test coverage across the pyramid
- Reviewing test quality and identifying gaps
- Calculating automation ROI

## When NOT to Use

- Writing specific test code (hand off to TDD skill)
- E2E browser automation setup (hand off to Playwright/Cypress skill)
- Performance/load testing (use k6, Artillery, or dedicated tools)
- Security testing (use SAST/DAST tools)

## Workflow

Copy this checklist and track progress:

```
Test Strategy Progress:
- [ ] Step 1: Discover existing test infrastructure
- [ ] Step 2: Inventory testable surfaces with user
- [ ] Step 3: Classify each into pyramid layers
- [ ] Step 4: Score automation candidates (selection matrix)
- [ ] Step 5: Design test scenarios (BDD naming)
- [ ] Step 6: Present strategy deliverable for approval
```

**Step 1: Discover**
Examine project structure for: test runner config, existing test files, CI pipeline, coverage reports. Note the language, framework, and current test count.

**Step 2: Inventory**
Ask the user: "Which features are business-critical? Which change frequently?" List all endpoints, user flows, and data pipelines.

**Step 3: Classify**
Assign each item a pyramid layer using the Test Pyramid below. Default to unit unless crossing service boundaries (integration) or testing full user flows (E2E).

**Step 4: Score**
Apply the Selection Criteria Matrix. Present results as a table. Automate the highest-scoring items first, defer middling ones, keep low-scoring ones manual.

**Step 5: Design**
For automation candidates, write test scenario names:
`test_[unit]_[scenario]_[expectedResult]`

**Step 6: Deliver**
Present the test strategy using the Output Template below. Wait for user approval before handing off to implementation.

## Test Pyramid

```
         E2E Tests
        /              \
   Integration Tests
      /                \
   Unit Tests
```

| Layer | Speed | Confidence | Cost | Examples |
|-------|-------|------------|------|----------|
| Unit | Fast | Low (isolated) | Low | Pure functions, validators, transforms |
| Integration | Medium | Medium | Medium | API routes, DB queries, service calls |
| E2E | Slow | High (realistic) | High | User workflows, checkout, auth flows |

## Automation Decision Quadrant

```
                    High Business Value
                           |
        +------------------+------------------+
        |   AUTOMATE       |   AUTOMATE       |
        |   FIRST          |   (careful ROI)  |
        |   (High ROI)     |                  |
  Low   +------------------+------------------+  High
Effort  |   AUTOMATE       |   CONSIDER       |  Effort
        |   (Low effort)   |   MANUAL         |
        |                  |   (Low ROI)      |
        +------------------+------------------+
                    Low Business Value
```

| Automate | Keep Manual |
|----------|-------------|
| Smoke/sanity tests | Exploratory testing |
| Regression suites | Usability/UX testing |
| Data-driven tests | One-time verifications |
| API contract tests | Rapidly changing features |
| Performance baselines | Visual design judgment |
| Security scans | Edge cases rarely executed |

## Selection Criteria Matrix

| Criterion | Score Guide |
|-----------|-------------|
| Execution frequency | 5=Daily, 3=Weekly, 1=Quarterly |
| Business criticality | 5=Revenue-critical, 1=Rarely used |
| Stability (low change) | 5=Stable, 1=Changes weekly |
| Complexity to automate | 5=Trivial, 1=Very complex |
| Data availability | 5=Static/easy, 1=Unavailable |

**Decision:** Prioritize high scores, defer middling scores, keep low scores manual.

## Testing Types

| Type | Purpose | Best For |
|------|---------|----------|
| Unit | Isolate individual functions | Pure logic, validators, transforms |
| Integration | Verify component interactions | API routes, DB queries, service calls |
| E2E | Full user workflows | Critical paths: auth, checkout, onboarding |
| Property-Based | Random inputs, verify invariants | Pure functions with defined contracts |
| Contract | API compatibility (consumer+provider) | Microservices, multi-team APIs |

## Naming Convention

```
test_[unit]_[scenario]_[expectedResult]

Example:
test_calculatePricing_withVolumeDiscount_appliesTierRate
test_loginUser_withInvalidPassword_returns401
```

## Quality Metrics

**Coverage goals:** Branch coverage matters more than line coverage. Don't game metrics — meaningful tests over numbers.

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Sleep/wait hardcoding | Flaky, slow | Explicit waits / polling |
| XPath over data-testid | Brittle selectors | Stable test attributes |
| Test interdependence | Order-dependent failures | Isolated setup per test |
| Shared mutable state | Race conditions | Fresh state per test |
| Too many E2E tests | Slow pipeline | Push down the pyramid |
| Testing implementation details | Breaks on refactor | Test behavior, not internals |
| Ignoring error paths | False confidence | Test failures + edge cases |
| Ignoring flaky tests | Erodes trust in suite | Fix or quarantine immediately |
| Missing boundary values | Off-by-one, null bugs | Test empty, null, min, max |
| No concurrency tests | Race conditions in prod | Test parallel access paths |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Testing implementation details instead of behavior | Assert on outputs and side effects, not internal state |
| E2E tests for edge cases | Use unit tests for edge cases; E2E for happy paths |
| Flaky tests left in suite | Quarantine immediately, fix within sprint, or delete |
| Mocking everything in integration tests | Integration tests should use real dependencies where feasible |
| Skipping test pyramid review | Audit the distribution quarterly |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Cannot decide unit vs integration boundary | If test needs external service/DB, it is integration. If it can run with mocks only, it is unit |
| Test suite too slow for CI | Profile slowest tests. Push E2E down to integration where possible. Parallelize |
| Coverage high but bugs still ship | Check branch coverage, not just line. Verify tests assert behavior, not implementation |
| Flaky test rate climbing | Quarantine flaky tests immediately. Root-cause: shared state, timing, or external deps |
| Stakeholders question automation ROI | Use the Selection Criteria Matrix scores to justify priorities |

## Output Template

Present the test strategy in this format:

```markdown
# Test Strategy: [Project/Feature Name]

## Current State
- Language/Framework: [detected]
- Existing tests: [count by type]
- Current coverage: [if available]

## Pyramid Distribution
| Layer | Count |
|-------|-------|

## Automation Candidates
| Feature | Score | Decision | Layer |
|---------|-------|----------|-------|

## Test Scenarios
[List of test names in BDD naming convention]

## Coverage Goals
- Current coverage: [if available]
- Critical paths: [list]

## Next Steps
- [ ] Implement [N] unit tests
- [ ] Implement [N] integration tests
- [ ] Configure CI pipeline
```

## Handoffs

| When | Hand off to |
|------|-------------|
| Strategy approved, ready to write tests | **REQUIRED SUB-SKILL:** TDD skill with test scenario list |
| E2E browser tests needed | **REQUIRED SUB-SKILL:** Playwright/Cypress framework docs |
| Performance baselines needed | Load testing tools (k6, Artillery) |
| CI pipeline configuration | Project's CI config file |

<!-- Credits: Merged from testing-strategies by @1Mangesh1 and automation-strategy by @melodic-software -->
