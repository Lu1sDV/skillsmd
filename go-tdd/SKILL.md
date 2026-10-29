---
name: go-tdd
description: >
  Use when implementing Go behavior test-first, reproducing a Go regression,
  characterizing legacy packages, writing table tests/subtests, httptest or
  filesystem boundary tests, fuzz/property tests, B.Loop benchmarks, or
  deterministic testing/synctest tests, and configuring race/coverage test CI.
---

# Go TDD

## Route by decision

| Need / symptom | Default / reference |
|---|---|
| New behavior, bug, legacy characterization, meaningful red | Contract first; [Workflow and runners](references/workflow-and-runners.md), including the exact-budget mutation |
| Table cases, subtests, selectors, helpers, golden output | Named cases and focused failures; [Workflow and runners](references/workflow-and-runners.md) |
| Cleanup, parallel isolation, HTTP/files/DB, doubles, time | Real local boundaries; [Isolation and boundaries](references/isolation-and-boundaries.md) |
| Sleeps/races in concurrent tests; Go 1.25 synctest | Synchronize observable progress; [Isolation and boundaries](references/isolation-and-boundaries.md#deterministic-concurrency-and-time) |
| Properties, fuzz corpus, mutation, benchmarks, coverage/CI | Bounded checks and honest evidence; [Properties and tooling](references/properties-and-tooling.md) |

## Workflow

1. **Contract.** Read implementation, callers, nearby tests, `go.mod`, build tags
   and CI; preserve versions/runners. Specify accepted/rejected inputs, units,
   errors, transitions and forbidden effects. Resolve ambiguous destructive or
   compatibility policy before encoding it.
2. **Cases.** Use the nearest real function/type/HTTP/file/database/CLI boundary.
   Cover relevant zero/one/many, threshold neighbors, nil/empty, overflow, repeated
   transitions and failure-state preservation. Assumptions are not requirements.
3. **Red.** Add a named regression; run its exact selector and inspect the behavioral
   assertion failure. Compile/setup failures can guide API creation but do not prove
   defect detection. Do not rerun supplied failures solely to confirm them.
4. **Green.** Implement the smallest complete contract, not an input-specific
   constant, production fake or swallowed error. Run focused and affected tests;
   never weaken assertions for green.
5. **Refactor.** Simplify without changing contracts; rerun affected checks.
   Normalization, stricter validation and changed errors need a new behavior cycle.

## High-risk guardrails

- Assert outputs, promised errors, and externally visible state, not private
  fields, mock echoes, or collaborator wiring. Multiple assertions are useful
  when they establish one transition, especially unchanged state on rejection.
- Call `t.Helper()` in helpers. Use `t.Fatal`/`FailNow` only from the test's
  goroutine; send worker errors/results back and join workers before returning.
- Register `t.Cleanup` immediately after acquisition, before fallible setup.
  Fresh `t.TempDir` paths and per-case objects avoid shared mutable fixtures.
  No `t.Setenv` or `t.Chdir` in parallel tests or under parallel ancestors.
- A parallel child waits until its parent returns; parent `defer` may close a
  resource before children use it. Use parent `t.Cleanup` or child-owned resources.
- Use channels, joins, or synctest rather than sleeps as completion signals.
  Deadlines bound hangs; they do not prove cleanup or stop goroutines by force.
- Doubles control failures, not reality. `httptest.NewServer` exercises local
  HTTP, not a live vendor API; a fake store does not certify SQL or transactions.
- Upstream email `Contains("@")` and password-class tests are teaching examples,
  not production identity validation or password-storage/security guidance.

## Version gate

Runnable samples require **Go 1.25+** (`go 1.25.0`), stdlib only. Fuzzing is
Go 1.18+, per-iteration variables for loops declared with `:=` follow the
module's Go 1.22+ language semantics, `B.Loop` is Go 1.24+, and stable
`testing/synctest.Test(t, func(*testing.T))` is Go 1.25+. Do not copy the old
experimental `synctest.Run` API. Older-core recipes do not raise a consumer's
minimum version automatically. See the [README](README.md) for exact commands.

## Completion and evidence

Require nonempty selection, boundary/failure assertions, resource cleanup, and
coverage of every affected caller. Report toolchain/platform, exact commands,
actual red/green failures and outcomes, race/fuzz/benchmark limits, and skips or
unperformed checks. Coverage is statement execution, not branch/path proof;
mutation results are signals, not correctness guarantees. Already-green tests
are coverage, not observed red. Never present expected results as execution.

This bundle works alone. Consult **test-engineering** only for an explicitly
requested system-wide test strategy. Preserve contract-based, risk-driven coverage;
do not import numeric coverage targets or fixed test-pyramid ratios. Concurrency
architecture is outside this testing workflow.
See [examples](examples/) and the [upstream license](LICENSE.upstream).
