---
name: typescript-tooling-tdd
description: >
  Use when configuring, diagnosing, or validating TypeScript development workflows: tsconfig
  or module-resolution failures, missing or slow type checks, editor/CLI disagreement,
  package exports or declaration compatibility, Vitest/Jest/Node test setup, regression
  tests, red-green-refactor changes, flaky async tests, property-based testing, coverage,
  linting, debugging, CI, or testability refactors. Preserve the existing package manager
  and toolchain unless a migration is requested.
---

# TypeScript Tooling and TDD

## Establish the project contract

1. Read repository instructions, `package.json`, the lockfile, compiler configurations, test configuration, and CI before editing. Identify the package or workspace owning the change.
2. Record the installed compiler and runtime, execution path, module format, package manager, and existing scripts. Distinguish emitted JavaScript, bundler execution, and direct TypeScript execution.
3. State the desired observable behavior or the exact failing command. For a bug, capture a minimal reproducer; for a toolchain problem, capture the original diagnostic.
4. Separate runtime behavior, static type contracts, and environment wiring. Select checks that exercise the changed layer.
5. Follow the current project conventions. Add or migrate tooling only when needed for the requested outcome; retain lockfile and CI compatibility.

## Select the workflow

| Request | Start with | Completion evidence |
| --- | --- | --- |
| Compiler, import, coverage, or performance problem | [Compiler diagnostics](references/compiler-diagnostics.md) | Verified program coverage, identified cause, and relevant type/runtime checks |
| Package exports or declarations change | [Package consumer checks](references/package-consumers.md) | Packed artifact works for the promised consumers |
| Behavior change | A small failing acceptance or unit test | New behavior and affected regressions pass |
| Bug fix | A deterministic reproducer | It fails before the fix and passes afterward |
| Legacy refactor | Characterization at a public boundary | Supported behavior is preserved |
| Async flake | Control time, I/O, scheduling, and cleanup | Reproduction is deterministic; intended ordering holds |
| Generic/type API change | Positive and negative compile-time examples | Compiler or dedicated type-test command reports the contract |
| Missing test infrastructure | Smallest runner compatible with the runtime | One representative test plus independent type checking |

Read [tooling-recipes.md](references/tooling-recipes.md) for config, module, command, and CI decisions. Read [testing-strategy.md](references/testing-strategy.md) for test design, async scheduling, and properties. Read [sources-and-corrections.md](references/sources-and-corrections.md) when comparing the upstream examples or resolving a version-sensitive claim.

## Configure only the required tools

- Reuse repository scripts and locally installed binaries. Resolve a workspace command from that workspace; avoid accidental package downloads through an unqualified runner invocation.
- Keep type checking explicit. Successful execution or transpilation does not establish TypeScript correctness. Run the existing `typecheck` script or the configured compiler/type-test equivalent.
- Match `module` and `moduleResolution` to the host: Node-aware settings for direct Node package semantics; bundler-aware settings when a bundler owns resolution. Inspect package `type`, export maps, and import extensions together.
- Treat `paths` as compiler resolution metadata. Verify runtime or bundler alias support independently; do not assume TypeScript rewrites emitted imports.
- Distinguish `target`, available `lib` declarations, runtime APIs, and polyfills. Adding a library declaration does not install the corresponding API.
- Enable strictness appropriate to the project. When tightening settings in existing code, keep the migration scoped and expose unresolved errors instead of suppressing them broadly.
- Use the existing formatter/linter and test framework. Check the installed major version before writing configuration; omit copied version rankings and obsolete schemas.
- Keep debug logging temporary and scrub sensitive values. Confirm source-map and source-file alignment when a breakpoint or stack trace is misleading.

## Apply red, green, refactor

1. Write one behavior-focused test with explicit inputs and expected results derived from the requirement.
2. Run it and verify that its failure demonstrates the missing or incorrect behavior. Repair harness/import failures before treating a test as evidence of a behavior defect.
3. Make the smallest coherent implementation change. Do not implement additional rules merely to make the example look complete.
4. Run the focused test and relevant neighboring tests.
5. Refactor while preserving behavior. Introduce each new validation rule through another failing test, rather than adding it during cleanup.
6. Run the project type check, affected tests, and applicable lint/build gates. Broaden testing only to address a concrete risk or repository requirement.

Use proportionate verification for documentation, configuration-only, or reversible low-impact changes. Do not create a broad test suite solely to satisfy this workflow.

## Design useful tests

- Assert public behavior and contracts; avoid private fields, incidental call order, or a reimplementation of the production algorithm as the oracle.
- Select representative zero, one, many, boundary, invalid, and failure cases from the input domain. Include `NaN`, infinities, Unicode, sparse arrays, and mutation only when the contract makes them relevant.
- Await or return every async assertion. Attach rejection handling before advancing fake timers or releasing a controlled failing operation.
- Restore spies, global stubs, timers, subscriptions, servers, and fixtures even when an assertion fails. Use test teardown or `try/finally`.
- Inject clocks, randomness, transport, and storage where needed. Keep pure logic real; use small fakes or boundary mocks for slow or nondeterministic dependencies.
- Cover an important boundary with a real integration test when a fake cannot establish protocol, module, database, or browser compatibility.
- Use property tests for independent invariants and generators restricted to the intended domain. Preserve seeds and minimized counterexamples; finite sampling is not proof for every input.
- Interpret coverage as executed code, then inspect assertions and failure paths. Avoid universal percentage targets or fixed unit/integration/E2E ratios.

## Return the result

Report the behavior or tooling defect, changed files, why the chosen checks cover the risk, and exact commands with outcomes. Distinguish checks actually run from recommended checks. Identify blocked commands and residual limitations without claiming a green build.

For purely conceptual requests, provide the proposed test cases or configuration decisions and explain the relevant tradeoff; do not invent an executed validation result.

## Sources

Adapt the workflows from StructWeave chapters [08: Tooling and testing](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/08-tooling-testing.md) and [16: Test-driven development](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/16-test-driven-development.md), with the corrections in the linked reference. Retain the bundled MIT attribution when redistributing this skill.
