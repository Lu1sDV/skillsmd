---
name: test-engineering
description: >
  Use when designing a test strategy, deciding what to automate or which tests a
  change needs, reviewing or generating tests (especially AI-written ones) for weak
  or self-confirming assertions, triaging flaky tests, diagnosing slow suites or
  coverage gaps, or interpreting coverage and mutation results. Framework-agnostic;
  language-specific test writing hands off to go-tdd, python-tdd, rust-tdd or
  typescript-tooling-tdd.
---

# Test Engineering

Decide which evidence a change needs and whether the tests provide it. Discover the project's runner, existing tests, CI and conventions before recommending anything. In a language covered by go-tdd, python-tdd, rust-tdd or typescript-tooling-tdd, load that skill for red-green, runners and fixtures; use this one for the task stage, oracle, detection and flaky policy, and strategy.

## Quick Reference

| Situation | Do | Detail |
|---|---|---|
| Plan tests for a feature or system | Strategy workflow below | — |
| Write or review tests, especially AI-generated | Name the task stage, then apply the quality gate | [test-review.md](references/test-review.md) |
| Fails intermittently, order-dependent, "passes on rerun" | Flaky procedure | [flaky-tests.md](references/flaky-tests.md) |
| Coverage is high but bugs ship; mutation scores | Coverage section | [test-review.md](references/test-review.md) |
| Mocks, stubs, fakes; property tests | Doubles and properties sections | [test-review.md](references/test-review.md) |
| Suite too slow | Slow suites section | — |
| Browser E2E tooling, load testing, security scanning | Out of scope | Playwright/Cypress docs, k6/Artillery, SAST/DAST |

## Name the task stage

Do this when judging a new or failing test. A failing new test means different things by stage.

| Stage | A new failing test means |
|---|---|
| New behavior (code absent) | Expected red; write it first (see the language TDD skill) |
| Regression augmentation (code believed correct) | Test is wrong or a real bug: check the spec before changing either |
| Bug discovery | Possible finding: confirm against the contract and report it. Do not commit a red test unless CI expects it; mark it expected-fail with a reason or report it uncommitted |
| Bug repair | Reproducer must fail before the fix for the reported reason, pass after |
| Characterization (legacy code) | Records current behavior; name it or comment it "characterization". A pass says nothing about correctness |

Dropping every test that fails on first run is valid only for regression augmentation, where a tool cannot tell a bug from a wrong assertion. Applied to bug discovery it discards the findings.

## Test-quality gate

Apply to every test you write or review.

1. **Independent oracle.** Expected values come from the spec, a worked example, an independent calculation, or a simpler reference model. Except in a labelled characterization test, never run the code and paste its output, and never reuse the production formula or helper. LLM-written assertions mostly capture actual behavior, so a test written from buggy code usually passes on the bug. Changing an expected value needs a stated cause (the requirement changed, or the test asserted the old wrong behavior), not "it now returns X". Assert caller-visible behavior, not internals or call sequences, unless the interaction is the contract.
2. **Real run.** Confirm the intended tests were selected (more than zero), ran against the changed source rather than an installed copy or stale build, and the exit status is not masked. List skips and xfails. Say which checks you did not run, and mark predicted results as predictions.
3. **Detection evidence.** When you claim a test catches or reproduces a defect, show it failing on the defective version for the intended reason and passing on the fixed one, or revert or mutate the behavior under test and confirm red. A compile or setup failure is not red. When you call an existing assertion weak, name a realistic wrong result it would still accept; with no such result, leave it alone. A test with no assertion, or an unawaited async assertion, is assertion-free.
4. **No change just to get green.** Skipping, retrying, raising a timeout, weakening or deleting an assertion, or regenerating a snapshot or golden file each needs a stated cause. Legitimate causes: a wrong fixture, a moved selector, a changed requirement. A passing retry is not a root cause.
5. **Cheapest faithful check.** Pick the cheapest test that keeps the failure mechanism intact and can observe it. SQL, serialization, config, wiring, transactions and cascading deletes cannot fail inside a test that stubs that layer; use the real boundary. Reuse existing coverage you can point to: name the test that already covers the behavior. Adding no test is valid when none adds evidence and the user did not ask for one.
6. **New tests earn their place.** Keep one that adds a distinct input partition, state, failure mechanism, or materially faster diagnosis. Drop an exact duplicate of another test's partition and observation. A test that still passes after the project's own code is deleted checks the framework, not the project. A test that only asserts a default value can still be a contract (default-deny permissions); keep it then.

## Coverage

Coverage shows which code ran, not which behavior was checked. When coverage is high and bugs still ship, ask what behavior was not executed, not observed (no assertion), or observed against the wrong expectation. For "would these tests notice a defect here?", use mutation testing or fault injection scoped to the changed code. Scores compare only within one tool and operator set. A mutant timeout is inconclusive, and equivalent mutants exist. Do not add or raise a numeric coverage target or pyramid ratio, and leave an existing gate in place unless asked to change it. A coverage drop on changed lines is a prompt to look.

## Flaky tests

A flaky test is red: fix it, or quarantine it visibly with a reason, an owner and an exit date. Rerunning until green silences the detector. Check a new or changed test for flakiness when it touches async work, time, randomness, ordering, shared state, the network, or unordered collections. Sequence: scan for nondeterminism, run in random order where the runner supports it, pin the suspect variable and rerun, reproduce before fixing. Details and numbers: [flaky-tests.md](references/flaky-tests.md).

## Slow suites

Profile first; find the slowest tests and what each uniquely protects. Move an E2E check down a layer only if the lower test still observes the failure mechanism. Parallelize only isolated tests. A faster run that skips a case or weakens an assertion is not an improvement; compare equivalent completed work before claiming a speedup.

## Strategy workflow

```
Test Strategy Progress:
- [ ] 1 Discover   - [ ] 2 Inventory   - [ ] 3 Failure mechanisms
- [ ] 4 Automate or manual   - [ ] 5 Scenarios   - [ ] 6 Present for approval
```

1. **Discover.** Test runner config, existing tests, CI, coverage reports, language and framework, test count, and whether the suite currently passes.
2. **Inventory.** Ask the user which features are business-critical and which change often. List endpoints, user flows, data pipelines.
3. **Failure mechanisms.** For each item, name the failure that matters and the cheapest faithful check (gate rule 5). Include error paths, boundary values (empty, null, min, max) and concurrent access where they are part of the contract. Typical layers:

| Layer | Observes | Use for |
|---|---|---|
| Unit | A rule inside one function or type | Pure logic, validators, transforms, boundary values |
| Integration | Interaction with a database, serializer, framework or service | Queries, routes, config, wiring, cascades |
| E2E | A full user journey | A few critical journeys; edge cases belong lower |
| Property | An invariant over many inputs | Functions with an independent property; see [test-review.md](references/test-review.md) |
| Contract | Consumer and provider compatibility | Multi-team or multi-service APIs |

4. **Automate or manual.** Answer four questions per item, asking the user where the code cannot tell: how serious is the failure, how often will the check run or the failure recur, what adequate evidence already exists, and what does another check cost to build, run, diagnose and maintain. Candidates that usually pay off: smoke and regression checks, data-driven cases, API contracts. Keep manual: usability, visual judgment, one-off checks, fast-changing features. For unclear or UI behavior, write a bounded exploratory charter (expected result, risk, entrypoint, isolation, exit condition) before probing, and turn confirmed defects into regression checks.
5. **Scenarios.** Follow the project's naming convention; otherwise name behavior as unit, scenario, expected result. Never name by delivery order, ticket key or phase.
6. **Present** using the template below. Wait for approval before handing off to implementation.

## Output Template

```markdown
# Test Strategy: [Project/Feature]

## Current State
- Language/framework, runner, CI; existing tests by type; suite status; coverage (informational)

## Failure Mechanisms and Checks
| Behavior / risk | Failure that matters | Cheapest faithful check | Layer | Already covered? |

## Automate or Manual
| Item | Consequence | Recurrence | Existing evidence | Cost | Decision |

## Test Scenarios
[Behavior-named scenarios]

## Adequacy Checks (only where a check claims to detect a specific defect)
- How the check will be shown able to fail (reproducer, negative control, mutation on changed lines)

## Next Steps
- [ ] Implement [N] checks at [layer]
- [ ] Configure CI
```

## Handoffs

| When | Hand off to |
|---|---|
| Strategy approved, write tests | go-tdd, python-tdd, rust-tdd or typescript-tooling-tdd by language; otherwise the project's own conventions |
| Browser E2E tooling | Playwright/Cypress documentation |
| Performance baselines | k6, Artillery |
| History-driven LLM fuzzing of a target | fuzzgpt |
| CI pipeline changes | The project's CI config |

<!-- Credits: Merged from testing-strategies by @1Mangesh1 and automation-strategy by @melodic-software -->
