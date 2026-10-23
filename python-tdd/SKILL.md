---
name: python-tdd
description: >
  Use when implementing Python behavior test-first, reproducing bugs,
  characterizing legacy code, or applying red-green-refactor with pytest/unittest,
  fixtures, patch lookup, deterministic I/O and clocks, or Hypothesis properties.
  Covers coverage/mutation limits, not system-wide strategy or benchmarking.
---

# Python TDD

## Route by decision

| Need | Default / reference |
|---|---|
| Feature, regression, legacy behavior; pytest/unittest | Existing runner; named behavioral failure — [Workflow and runners](references/workflow-and-runners.md), including the exact-threshold red/green mutation |
| Fixtures, patch targets, doubles, clocks | Fresh mutable state and real local resources — [Isolation and doubles](references/isolation-and-doubles.md) |
| Properties, async, HTTP, CLI, database, CI, coverage/mutation | Named examples plus checks at the real boundary — [Properties and boundary checks](references/properties-and-boundaries.md) |

## Workflow

1. **Establish the contract.** Read implementation/callers, neighboring tests,
   packaging, supported versions, runner/plugins, and CI. Specify inputs/units,
   outputs, exceptions, state changes, and forbidden effects. Ask the owner about
   unresolved compatibility or destructive/loss policy before encoding it as a test.
2. **Choose falsifiable cases.** Select the nearest real boundary: function,
   file/database adapter, framework client, or installed CLI subprocess. Include
   accepted/rejected inputs, zero/one/many, threshold neighbors, repeated transitions,
   and failure-state preservation as relevant. For multi-consumer changes, track
   each affected path as pending, checked, or blocked.
3. **Red.** Add a named test through production behavior. Run the focused selector
   and inspect the assertion/promised-exception failure. Setup/import errors and
   zero selected tests are not behavioral red; after creating a missing API,
   establish a behavioral failure. Respect supplied failure evidence rather than
   rerunning merely to confirm it.
4. **Green.** Implement the smallest complete behavior, not a constant, permanent
   fake, or exception suppression. Run the focused case and affected tests.
   Preserve the assertion unless the approved requirement changes.
5. **Refactor.** Simplify without changing behavior and rerun affected checks.
   Added validation, normalization, formats, or error types need another red/green
   cycle, not a “cleanup” label.

## High-risk gotchas

- **Patch lookup, not origin.** `from x import f` binds a consumer name; defaults
  and closures can capture dependencies earlier. Trace the actual expression.
- **Acquire cleanup immediately.** `tearDown` is skipped after failed `setUp`;
  `addCleanup` still runs. A pytest fixture failing before `yield` never reaches
  its post-yield teardown. Join/await workers even when assertions fail.
- **Control state, not schedules.** Use explicit clocks, local randomness, temporary
  paths, and events rather than sleeps, live services, test order, or shared mutable
  fixtures. Confirm imports resolve to the intended package, not another checkout.
- **Assert behavior, not the double.** Check results and promised state/errors;
  mock echoes, no-throw checks, and broad `raises(Exception)` can miss the defect.
  Doubles do not establish live API compatibility. Annotations do not validate
  runtime data, and production validation must not rely on removable `assert`s.

## Completion and evidence

Require nonempty test selection, boundary/failure assertions, resource cleanup,
and closure of every affected consumer. Skips/xfails cannot hide requested work.
Report interpreter/dependency versions, commands/counts, actual red/green outcomes,
and unperformed checks. If execution is unavailable/prohibited, label outcomes
expected, not observed. Already-passing examples are coverage, not observed red;
coverage/mutation scores are signals, not proof.

This bundle works alone. Optional handoffs: **test-engineering** for system-wide
strategy, **python-concurrency** for runtime synchronization/cancellation design,
and **python-api-design** for approved interface redesign. Dependency-free examples
target Python 3.11+; framework recipes require the project's compatible dependencies.
See [README](README.md) for commands/decisions and the [upstream license](LICENSE.upstream).
