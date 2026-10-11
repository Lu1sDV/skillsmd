# Workflows and testability

This reference adapts the methodology, QA mindset, test organization, and
functional-core sections of [StructWeave chapter 18](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/18-test-driven-development.md).
Use it to choose the next test, not to demand a rewrite before testing.

## New feature: outside-in intent, small internal cycles

1. Write a concrete acceptance example at the public boundary. Include the
   observable error contract and side effects, not just the happy-path value.
2. Pick one rule needed to make that scenario work. Write its failing unit test
   and inspect red before implementing that rule. A not-yet-existing API may
   fail to compile first; unrelated compiler errors are setup failures.
3. Implement the rule completely, run its test, and keep existing behavior green.
   Add the nearest boundary or contrary case next. A constant return can be a
   temporary experiment, but is not a deliverable implementing a general rule.
4. Refactor only after green. Keep the acceptance test as a wiring check rather
   than repeating every rule permutation at the slowest layer.
5. Exercise the supported feature configurations relevant to this behavior.
   A default-feature pass says nothing about code omitted by `cfg`.

For inventory reservations, the acceptance story is “two successful requests
consume the exact stock, then an excessive request leaves stock unchanged.”
Internal cycles cover zero, ordinary success, exact exhaustion, insufficient
stock, and error atomicity. Do not silently add a maximum-per-order rule.

## Bug fix: reproduce the cause, not a convenient symptom

- Start from the reported input, failure evidence, and affected public entry
  point. Respect existing observed failures; don't rerun them merely for confirmation.
- Trace to the shared rule and all callers that depend on it. Place a regression
  where it fails for that cause. Add a boundary/integration regression only if
  wiring or interpretation across a boundary contributed to the bug.
- State the required behavior. “Doesn't panic” is insufficient if the result can
  be wrong or state can be corrupted. An insufficient-funds error must not also
  debit the account; a failed save must not produce a success notification.
- Inspect a newly added regression's failure before the fix when execution is
  permitted. After the fix, run it and affected existing tests; add adjacent
  boundaries that protect the same root cause.
- If the regression already passes, investigate whether it exercises the wrong
  entry point, ignores a returned `Result`, tests a double instead of production,
  or fails to reproduce the necessary state. Do not invent a red result.

## Legacy code: characterization is not endorsement

1. Capture observable current behavior through the nearest stable entry point.
   Select representative success, error, and stateful sequences; preserve actual
   outputs rather than inventing what the old code ought to do.
2. Mark which observations are compatibility requirements, unknowns, or known
   defects. A characterization asserting a defect is a temporary safety net,
   not a permanent decision that the defect is correct.
3. Introduce the smallest seam needed for determinism: a supplied timestamp,
   byte buffer, function argument, or existing trait is often sufficient.
4. Refactor with the characterization tests green. Then write a new failing
   specification for each approved behavior change and update the contradictory
   characterization deliberately.
5. Keep real adapter tests: an in-memory fake may not reproduce transaction,
   constraint, encoding, or protocol semantics of the actual dependency.

## Build an input partition table

The purpose of QA thinking is to try to falsify the contract. For each partition,
choose a representative and then test transitions between partitions.

| Domain | Partitions | Boundaries and ambiguity to resolve |
|---|---|---|
| Reservation count | zero; below stock; exact stock; above stock | stock 0/1/max; unchanged on failure |
| Signed arithmetic | negative; zero; positive | `MIN`, `MAX`, overflow, division by zero and `MIN / -1` |
| Optional input | absent; present-empty; valid; malformed | defaulting versus rejecting; whitespace normalization |
| Text | ASCII; non-ASCII; invalid bytes before decoding | bytes vs scalar values vs graphemes; empty and size limits |
| Collection | empty; singleton; many | duplicates, sorted/reversed, capacity, missing member |
| State machine | each state and legal/illegal event | repeated operation, partial completion, cancellation |
| I/O | success; not found; permission; partial failure | EOF, short reads/writes, invalid encoding, cleanup |

Use ZOMBIES as a reminder: Zero, One, Many, Boundary, Interface, Exception,
Simple scenarios. It is not a requirement to invent every case for every function.
Error guessing supplements partitions: try embedded NUL, line endings, duplicate
identifiers, expired credentials, out-of-order delivery, or hostile input where
those belong to the real domain. Expected acceptance/rejection must follow the
contract, not an arbitrary universal rule about unusual input.

Do not compute `MAX + 1` just to represent an impossible typed input. Test the
parse boundary that can receive it, or test the defined checked/wrapping/saturating
arithmetic policy. For floats specify tolerances appropriate to the quantity,
plus NaN/infinity policy; avoid blindly using exact equality or a universal epsilon.

## Functional core, imperative shell

Keep transformation and decision logic independent of file/network/clock access.
For a file transformation, the shell reads bytes, invokes a pure transformation,
then writes according to the required update/atomicity policy. Unit tests cover
the transformation; temporary-directory integration tests cover real reads,
writes, errors, and preservation of the original file when required.

Prefer inputs over indirection:

- Need a time boundary? Pass `now` to the decision function; test just before,
  exactly at, and after expiry. Use a clock trait only if repeated clock access
  is part of a real boundary.
- Need output assertions? Accept `impl Write` at the I/O boundary and use a
  byte buffer in tests. Still test real CLI stdout/stderr and exit status.
- Need randomness? Supply a seedable generator or chosen value through a seam;
  keep test replay deterministic and test domain invariants.
- Need a remote repository? Reuse its narrow existing trait; use a fake for
  stateful behavior, or a mock for meaningful interaction constraints. Do not
  turn every helper into a trait merely because mocking is available.

Test difficulty is design feedback, not proof that any particular abstraction
is needed. A large fixture may signal mixed responsibilities; hiding its setup
behind a builder does not fix those responsibilities.

## Rust harness and assertions

[Rust's testing chapter](https://doc.rust-lang.org/book/ch11-00-testing.html)
and [Cargo test](https://doc.rust-lang.org/cargo/commands/cargo-test.html) define
these distinct surfaces:

- Unit tests commonly live in `#[cfg(test)] mod tests` beside implementation;
  `use super::*` allows access to the parent module's private items. Prefer
  stable behavior assertions over fragile representation checks.
- Each top-level `tests/*.rs` is a separate integration-test crate accessing the
  library's public API. Put shared helpers in `tests/common/mod.rs`, not a
  top-level `tests/common.rs` accidentally treated as its own target.
- The library is built as a normal dependency for integration tests: its own
  `#[cfg(test)]` items are not available there. Keep test doubles inside the
  integration-test crate when necessary rather than leaking test APIs publicly.
- Documentation tests exercise public examples. Keep them self-contained and
  assert something important, rather than marking broken examples `ignore`.
- `assert_eq!`/`assert_ne!` show compared values and require suitable `Debug` and
  equality implementations. `assert!(matches!(...))` checks a specific enum
  variant; `is_ok()` alone discards the payload and can hide a wrong result.
- A test returning `Result<(), E>` can use `?` for setup and still assert its
  domain result. Don't combine a `Result`-returning test with `#[should_panic]`.
- Use `#[should_panic(expected = "...")]` only for a specified panic contract.
  Isolate the operation so an unrelated setup panic cannot satisfy the test.
  Expected ordinary failures belong in `Result` assertions.

Avoid tests containing a branch that skips the important assertion. Small
parameter tables and independent reference models can contain logic; the rule
is to keep the oracle simpler and independent of the implementation, not to
ban every loop. Prefer several diagnostic tests to one enormous user lifecycle.
