---
name: rust-tdd
description: >
  Use when implementing Rust features test-first, reproducing Rust bugs with
  regression tests, characterizing legacy Rust, or applying red-green-refactor
  with cargo test. Covers boundary and equivalence cases, proptest shrinking,
  mockall expectations, rstest fixtures, async/concurrent/CLI tests, and coverage
  interpretation. Not a substitute for system-wide test strategy or benchmarking.
---

# Rust TDD

Drive a small behavior change with an observed failure, a complete working fix,
and a behavior-preserving refactor. The compiler checks types and ownership;
it does not establish business rules, deadlock freedom, or correct error handling.

## Quick Reference

| Need | Action / reference |
|---|---|
| New feature | Acceptance example → one failing behavior → smallest complete implementation |
| Reported bug | Add regression at the shared failing path; preserve the reported evidence |
| Legacy change | Characterize behavior first; distinguish compatibility from approved bug fixes |
| Boundary inventory, testability | [Workflows and testability](references/workflows-and-testability.md) |
| Broad input space, shrinking | [Properties, doubles, and fixtures](references/properties-doubles-fixtures.md) |
| External interaction | Real value/function first; stub/fake/mock only at an actual dependency boundary |
| Async, concurrency, CLI, CI, coverage | [Scenarios and tooling](references/scenarios-and-tooling.md) |
| Attribution and technical corrections | [Sources](references/sources.md) |

## Establish the contract before the first test

1. Read the function, callers, nearby tests, `Cargo.toml`, feature gates, and CI.
   Reuse the project's test layout and dependencies; do not add a framework for
   assertions the standard harness already handles.
2. State observable inputs, output, errors, side effects, and forbidden changes.
   For a bug, identify the shared root cause rather than a special case in one caller.
3. Choose the cheapest level that observes the contract: a unit test for a rule,
   integration test for a boundary, subprocess test for exit status or CLI output.
4. Enumerate equivalence classes and their boundaries. Include valid cases so a
   function that rejects everything cannot pass. Specify integer overflow and
   string length units rather than letting implementation accidents define them.
5. Select the project's edition and MSRV; do not raise them just for test syntax.
   These standalone examples use edition 2024 (Rust 1.85+). That is not a claim
   that every optional test crate supports 1.85; check the locked crate versions.

## Red → green → refactor

**Red:** Write a named, focused test against the real behavior. Run that test
before changing production behavior and inspect its failure. A wrong expected
value, missing fixture, syntax error, or unavailable service is not useful red.
A missing new API can establish the first compile-time red; subsequently establish
an assertion failure whenever the behavior can be exercised. Check that a filter
actually selected the test: zero tests passing is not evidence.

Respect an existing failure report: do not rerun a user's known failure merely
to confirm it. Use its concrete evidence, adding a targeted regression if needed.
If execution is unavailable or prohibited, record the expected failure and the
unperformed command; never claim an observed red-green cycle.

**Green:** Implement the smallest complete behavior that satisfies the contract,
not an input-specific answer or a permanent stub. Run the focused test, then the
relevant existing suite. Keep expected assertions stable unless the requirement
was wrong and the correction is explained.

**Refactor:** With green evidence, simplify production and test code without
changing behavior. Rerun affected tests. A new case, error variant, or rejection
rule is another red-green cycle, not a refactor. Avoid speculative traits,
builders, or dependencies solely to make a tiny function appear testable.

## Complete green example: reservation is atomic on failure

Contract: reserve any amount up to available inventory, including zero; reject
an excessive request without changing inventory. Inventory is a count, not money.

Concrete red step for a boundary bug: suppose existing code rejects
`requested >= available`. Add `reserves_exact_remaining_inventory` containing
`let mut available = 3; assert_eq!(reserve(&mut available, 3), Ok(()));`.
Run `cargo test reserves_exact_remaining_inventory` in that project. Before the
fix the assertion compares `Err(Insufficient)` to `Ok(())`; inspect that failure,
not merely the command's exit code. Separately add the failure-state assertion
before fixing any implementation that mutates inventory before rejecting a request.
These are expected diagnostics, not a claim that this guide executed them.

The complete green implementation below covers exact exhaustion, zero,
insufficient inventory, sequential reservations, and the integer maximum.
Its assertions execute directly under rustdoc; in a crate, move each behavior
into a named `#[test]` in the existing test module.

```rust
#[derive(Debug, PartialEq, Eq)]
struct Insufficient;

fn reserve(available: &mut u32, requested: u32) -> Result<(), Insufficient> {
    let remaining = available.checked_sub(requested).ok_or(Insufficient)?;
    *available = remaining;
    Ok(())
}

let mut available = 3;
assert_eq!(reserve(&mut available, 3), Ok(()));
assert_eq!(available, 0);
assert_eq!(reserve(&mut available, 0), Ok(()));
assert_eq!(reserve(&mut available, 1), Err(Insufficient));
assert_eq!(available, 0);

let mut available = 5;
assert_eq!(reserve(&mut available, 6), Err(Insufficient));
assert_eq!(available, 5); // Failure must not consume inventory.
assert_eq!(reserve(&mut available, 2), Ok(()));
assert_eq!(reserve(&mut available, 3), Ok(()));
assert_eq!(available, 0);

let mut available = u32::MAX;
assert_eq!(reserve(&mut available, u32::MAX), Ok(()));
assert_eq!(available, 0);
```

A useful refactor preserves those assertions while simplifying a duplicated
validation branch. Rejecting zero requests would instead change the contract.

## QA questions before adding more tests

- **Zero, one, many:** empty collections, absent values, singleton inputs,
  duplicates, and repeated state transitions.
- **Boundary:** immediately below/at/above a threshold where representable;
  exact capacity, numeric extremes, partial reads, EOF, and Unicode boundaries.
- **Interface:** output values plus relevant state changes, error identity,
  ownership, and public API accessibility.
- **Exceptions:** failure at each side-effect boundary; state must remain valid.
  Assert the promised error variant, not only `is_err()` when variants matter.
- **Scenarios:** one realistic end-to-end path to catch adapter/wiring mistakes;
  keep most rule combinations close to the functional core.

Prefer one behavior per test, not a dogmatic one assertion per test. Check both
result and state when they jointly define the behavior. A test that only executes
code, asserts a constant, or compares two copies of the same algorithm is weak.

## When not to force TDD

Use a bounded discovery spike when the API or feasibility is unknown; discard
it or add a characterization safety net before evolving it into production.
Visual appearance needs visual/exploratory checks as well as tests of underlying
logic. Legacy code often needs characterization before test-first changes.
A genuinely disposable, low-risk script may warrant a small executable check
rather than a suite. None of these exceptions waive security, data-loss, or
other critical checks because code is called a prototype.

## Completion criteria and handoffs

- Every requested behavior has an observable assertion, including the relevant
  failure path and boundary; no skipped test hides an unfinished requirement.
- Record the focused command and red/green evidence actually observed; report
  blocked or unperformed checks explicitly.
- Tests isolate state, await/join owned work, and do not depend on execution order,
  real-time sleeps, live public services, or one lucky thread schedule.
- Relevant unit, integration, and documentation tests cover the changed contract;
  optional properties/doubles earn their maintenance cost.
- Coverage informs investigation, never proves correctness or imposes an
  arbitrary percentage. Benchmark results are a different kind of evidence.

Optional installed skills: **test-engineering** for system-wide risk and test
strategy; **rust-idiomatic** for compiler/error/tooling issues; **rust-api-design**
for a boundary redesign; **rust-concurrency** for synchronization/cancellation
correctness; **rust-performance** for measured performance and benchmark design;
**rust-macros** for compile-fail macro/API diagnostics. This bundle works alone.
