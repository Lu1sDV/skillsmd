---
name: rust-idiomatic
description: >
  Use when writing or reviewing ordinary Rust, fixing move/borrow/lifetime errors,
  handling Option or Result, choosing standard-library string/iterator/I/O APIs,
  or configuring Cargo workspaces, rustfmt, Clippy, and rust-analyzer. Covers
  UTF-8, partial moves, allocation semantics, and production error propagation;
  use specialized skills for API architecture, concurrency, or test-driven work.
---

# Rust Idiomatic

Make ownership, failure, and boundary behavior explicit. Prefer a standard-library
operation and a clear loop over a new abstraction or a clone that hides the problem.

## Quick Reference: routing

| Task / symptom | Read |
|---|---|
| Syntax, trait bounds, moved value, overlapping borrows, lifetime error | [Language and ownership](references/language-ownership.md) |
| `Option`, `Result`, conversions, parsing, error context | [Errors and idioms](references/errors-idioms.md) |
| UTF-8, iterator consumption, capacity, lines, files, paths, time | [Standard-library boundaries](references/stdlib-boundaries.md) |
| Cargo, workspace selection, MSRV, editor, lint, debugger | [Project workflow](references/project-workflow.md) |

Load only the relevant reference; all four are independent of sibling skill installs.

## Quick Reference: decisions

| Need | Default | Watch for |
|---|---|---|
| Read text / sequence | `&str` / `&[T]` | Borrowed output cannot outlive its owner |
| Mutate elements | `&mut [T]` | Use `&mut Vec<T>` only for vector-specific changes |
| Retain or consume input | `T` | Move an existing owner rather than cloning |
| Optional value | `Option<T>` | Absence is not necessarily an error |
| Recoverable failure | `Result<T, E>` and `?` | Do not discard error details with `.ok()` |
| Checked conversion | `TryFrom`, `TryInto`, `parse` | `as` can truncate or lose precision |
| Missing map entry | `entry().or_insert_with(...)` | Key construction is still eager |
| Untrusted index | `get`, `get_mut` | String ranges also require UTF-8 boundaries |
| LF/CRLF records | `lines()` or precise suffix removal | `trim()` changes payload whitespace |
| Timing | `Instant` | `SystemTime` can move backward |

## Workflow

1. **Inspect the actual project.** Read package/workspace manifests, lockfile,
   toolchain configuration, MSRV, edition, enabled features, target, and callers.
   Do not upgrade an edition, add crates, or enable all features by habit.
2. **State the contract.** Identify owners, borrows, mutation, valid input,
   failure behavior, and whether processing may have partial side effects.
   At text boundaries decide bytes vs Unicode scalars vs grapheme clusters.
3. **Choose the smallest representation.** Borrow for inspection; own to retain.
   Use enums for alternatives, `Option` for absence, and `Result` for failure.
   Establish a reason before introducing shared ownership or interior mutability.
4. **Follow the data through callers.** A changed argument or error type must be
   migrated at every affected call site. Read the first compiler diagnostic,
   including its later-use location, before changing lifetime annotations.
5. **Implement the intended semantics.** Prefer shorter borrows, `iter_mut`,
   `split_at_mut`, `entry`, `take`, or `replace` to clone-based workarounds.
   Preserve parsing failures and I/O errors; never turn them into success defaults.
6. **Select checks deliberately.** Follow repository policy; when execution is
   authorized, use the same toolchain, target, features, and workspace selection
   as the changed code. A host check does not establish MSRV or other-target support.
7. **Report evidence.** Describe ownership/error changes, boundary coverage, and
   exact checks performed. Separate unrun checks from observed results.

## Ownership rules that matter in reviews

- Moving a `String` transfers the handle; it does not clone its bytes. Moving a
  large inline value can still have a cost. `Copy` is implicit duplication, not
  a synonym for cheap. `Clone` can share state (`Rc`/`Arc`) rather than deep-copy.
- A live `&mut T` is exclusive access to the borrowed place. Disjoint places can
  be borrowed separately. Reborrows temporarily restrict the original reference;
  it becomes usable again after the reborrow's last use.
- A partial move invalidates the whole-value use, not every remaining field.
  Moving a non-`Copy` field out of a type implementing `Drop` is restricted.
- Lifetime annotations describe relationships; they do not extend storage.
  `T: 'static` does not mean the value lives forever. Avoid `'static`, `Box::leak`,
  or unsafe code as fixes for ordinary lifetime errors.
- Borrowing and destructor scope are different: the last use of a reference is
  not a promise that an owning guard is dropped at that point.

## Errors and boundaries

Use `?` to propagate failure to a caller that can decide what to do. Library
callers may need structured variants; an application boundary may instead need
operation/path context and a source chain. Neither requires adding a new crate:
reuse project conventions. `expect` documents an invariant, not input validation.

Check arithmetic policy explicitly: `checked_*`, `saturating_*`, `wrapping_*`, or
`overflowing_*` when overflow has defined meaning. Default build-profile overflow
settings are not a business rule. Division needs more than a zero check for signed
integers: `MIN / -1` also overflows.

```rust
fn quotient(numerator: i32, denominator: i32) -> Option<i32> {
    numerator.checked_div(denominator)
}

assert_eq!(quotient(12, 3), Some(4));
assert_eq!(quotient(12, 0), None);
assert_eq!(quotient(i32::MIN, -1), None);
```

A `String` is UTF-8; `len()` measures bytes and `char` is a Unicode scalar, not a
user-perceived character. `str::get` checks byte range and character boundaries.
Do not convert to `Vec<char>` merely to slice or locate an ASCII delimiter.

Iterator adapters such as `map` are lazy; consumers such as `collect`, `sum`, and
`for` execute them. `filter_map(Result::ok)` silently loses failures. `zip` stops
at the shorter input. A successful type check proves neither domain correctness
nor absence of panics, deadlocks, leaks, or unwanted allocations.

## Project workflow boundaries

Keep the project's MSRV and edition; Rust 2024 requires Rust 1.85 or newer, while
let chains additionally require 1.88 or newer and edition 2024. Do not assume a
feature is stable just because an upstream guide predicts its stabilization.

Use `cargo check` for ordinary iteration, `cargo tree -e features` for feature
surprises, and targeted compiler explanations for borrow errors. Keep stable
rustfmt settings and review Clippy suggestions against semantics. Do not use
`--all-features` if features are mutually exclusive. General commands and
workspace examples are in [Project workflow](references/project-workflow.md).

## Completion criteria

- Ownership and lifetimes reflect retention needs, not compiler appeasement.
- Empty input, absent data, malformed input, UTF-8 boundaries, overflow, and I/O
  failures have deliberate behavior where applicable.
- New clones, collections, conversions, and shared pointers have a semantic reason.
- No silent error-dropping, accidental whitespace trimming, or platform-path loss.
- All affected callers and documentation match; verification evidence states the
  actual toolchain/feature/target scope and any gaps.

## Handoffs

If installed, use **rust-api-design** for public APIs, trait/dyn architecture,
newtypes/builders, SOLID/GoF tradeoffs; **rust-tdd** for red-green-refactor,
regression/property tests and test CI; **rust-algorithms** for data-structure and
algorithm selection; **rust-concurrency** for synchronization/async; and
**rust-performance** for measurement, allocation/layout tuning, or build costs.
Use **rust-macros**, **rust-unsafe-ffi**, or **rust-wasm** for those boundaries.
These are optional handoffs, not required files in this bundle.

## Sources

Original synthesis from StructWeave chapters 01, 02, 05, 07, 13, and 17 at a pinned
revision. The [README source map](README.md#sources-and-adaptation) records chapter
links and adaptation decisions; references cite first-party semantics. Upstream
attribution is retained in [LICENSE.upstream](LICENSE.upstream).
