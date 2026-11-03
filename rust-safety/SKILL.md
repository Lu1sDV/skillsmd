---
name: rust-safety
description: >
  Use when auditing Rust safety or security, writing unsafe abstractions or
  C FFI/C-ABI bridges to C++, or investigating panic- or recursion-driven denial
  of service, resource/raw-handle ownership, untrusted input, filesystem/process
  boundaries, or concurrency invariant failures. Covers soundness proofs, MaybeUninit, Drop,
  Send/Sync, ABI/layout, C strings, allocator ownership, callbacks, FFI unwinding,
  Rust 2024 unsafe syntax, cancellation, and Miri/sanitizer evidence.
  Not a general Rust tutorial, style review, cryptographic design, or secret-memory erasure guide.
---

# Rust Safety and Security

Review the invariant and its observable consequences, not the presence of
`unsafe`, `unwrap`, or a suspicious API. Safe Rust can have availability and
logic vulnerabilities; a soundness defect is not automatically a remote exploit.

## Quick reference: load only the relevant guide

| Task or symptom | Read | First question |
|---|---|---|
| Raw pointers, provenance, unions, packed fields | [Safety and initialization](references/safety-and-initialization.md) | Can a safe owner/slice express it; if not, what proves the raw operation? |
| `MaybeUninit`, manual allocation, panic during `Drop` | [Safety and initialization](references/safety-and-initialization.md#initialization-and-destruction) | What remains live and initialized on every exit? |
| Unsafe traits, hostile safe callbacks, pinning | [Safety and initialization](references/safety-and-initialization.md#unsafe-traits-and-pinning) | Can any safe client break the invariant? |
| C ABI/layout, strings, foreign ownership, callbacks | [C boundaries](references/c-boundaries.md) | Who owns the allocation, and when does foreign access end? |
| FFI panic/exception, Rust 2024 extern/unsafe-attribute warning | [Syntax and unwinding](references/c-boundaries.md#rust-2024-syntax-and-unwinding) | Which ABI and panic policy apply before the boundary is crossed? |
| Panic, recursive values, memory/work exhaustion | [Availability and resources](references/availability-and-resources.md) | Can untrusted input exhaust the deployed process or its shared capacity? |
| Deadlocks, atomic protocols, cancellation | [Availability and resources](references/availability-and-resources.md#concurrency-and-cancellation) | Which state or resource survives interruption? |
| Lengths, encodings, paths, process arguments | [Input and OS boundaries](references/input-and-os-boundaries.md) | Which authority or identity does this input select? |
| Raw descriptors, handoff errors, handle leaks | [Descriptor ownership](references/input-and-os-boundaries.md#raw-descriptors-are-resources-not-arbitrary-integers) | Who owns the resource on each success, failure, and interruption path? |
| Write/flush errors, partial output, durability | [Output and persistence](references/input-and-os-boundaries.md#output-and-persistence) | Was output delivered, and what persistence guarantee was actually promised? |
| Reproducer, Miri, sanitizers, fuzzing, dependency warnings | [Verification and traps](references/verification-and-traps.md) | What does this evidence establish, and what did not run? |

The bundle is self-contained. Source links support the local guidance; routine
use does not require fetching every source. [Sources and decisions](references/sources-and-decisions.md)
records research provenance and rejected claims, not an extra prerequisite.

## Workflow

1. **Scope the contract.** Establish library versus application, actors and trust
   boundaries, public safe API, MSRV/edition, targets, features, dependency/native
   versions, build flags, panic strategy, resource promises, and concurrent or
   reentrant calls. Ask only for consequential intent or authority the repository
   cannot establish. Track pending, reviewed, and blocked areas for multi-file work.
2. **Map the whole boundary.** Trace constructors, mutators, exposed fields,
   callbacks, returned borrows, ownership transfers, and destruction. Include
   generated/macro-expanded code and relevant dependencies: an empty `unsafe`
   search is not proof of a safe implementation.
3. **State the proof or failure condition.** For each unsafe operation identify
   allocation/extent, alignment, initialization/validity, lifetime, aliasing,
   provenance, destruction, and thread obligations. For safe-code hazards identify
   controllable input/state, the violated limit or invariant, and the harmed
   consumer. Separate documented facts, project assumptions, and unresolved claims.
4. **Try to refute it.** Follow actual validation, type/private invariants,
   wrappers, configuration, and containment. A safe API needs no redundant runtime
   check when its types or established invariants already prove the obligation.
   Keep unsafe blocks small. A `SAFETY:` comment must name where a fact is
   established and how long it holds, not merely say “pointer is valid.”
   Document the shared module invariant when several safe methods participate.
   Restore invariants before calling user code; use unwind guards where needed
   to preserve memory safety on interruption.
5. **Choose the smallest correction.** Prefer existing safe std/library APIs,
   typed ownership, checked arithmetic, bounded work, and explicit errors.
   If callers must prove memory validity, expose a precise unsafe contract rather
   than a safe raw-pointer API with a null check. New unsafe code needs a concrete
   capability requirement or measured motivation; unsafe is not inherently faster.
   Do not add a partial collection or framework just to wrap one foreign call.
6. **Exercise failure and interruption.** Cover malformed/maximum/empty inputs,
   errors, partial initialization, user `Clone`/`Drop`, panics, reentrancy,
   cancellation, and repeated ownership cycles as applicable. Verify actual
   native or deployed behavior; use isolated subprocesses for expected aborts.
   Never deliberately execute UB in an ordinary regression test.
7. **Report honestly.** Classify soundness defects, reachable vulnerabilities,
   correctness defects, and hardening observations separately. Provide location,
   violated contract, triggering path, impact, minimal correction, and exercised
   evidence. Missing context or an unrun check is **unverified**, not safe/cleared.
   Resolve confirmed defects or explicitly report the remaining blocker.

## Critical guards

- **Any safe caller:** a safe abstraction must prevent UB for arbitrary safe
  clients, including surprising callbacks and safe trait implementations.
  Soundness does not depend on finding a network exploit. Safe code can encounter
  UB through an unsound dependency; successful compilation is not a safety proof.
  `unsafe` does not disable the borrow checker or relax Rust's validity rules.
- **Pointer proofs are conjunctive:** nullness or `NonNull` alone does not prove
  extent, alignment, initialized valid values, lifetime, aliasing, or provenance.
  Raw slice constructors still need non-null aligned pointers for empty slices.
- **Initialization is a transition:** capacity is not initialized length; publish
  only successfully initialized elements. A post-call bound check cannot undo a
  foreign out-of-bounds write. Keep interruption from exposing invalid slots.
- **Lifetime and destruction:** keep `CString` and other borrowed owners alive;
  pair transfers with the matching allocator/release function exactly once.
  Safe `mem::forget` must not create dangling callbacks. Unregistering is not
  enough without callback quiescence.
- **ABI is not a wire format:** `repr(C)` does not make nested Rust containers
  C-compatible, initialize padding, or validate enums. Contain recoverable Rust
  panics inside a non-unwinding callback boundary, not outside it.
- **Build settings matter:** `debug_assert!` cannot be the sole safety enforcer
  when disabled; overflow and panic behavior depend on the effective build.
  Parser protection does not automatically cover formatting, serialization,
  composed values, or destruction.
- **Concurrency is more than data races:** `Send`/`Sync`, atomics, and `Arc` do not
  prove protocol atomicity, progress, fairness, cancellation safety, or shutdown.
- **Boundaries stay boundaries:** `Path::join` is not confinement; argument
  separation is not a guarantee about the invoked program; lossy text is not
  an identity-preserving conversion.
- **Verification is not a sandbox or certificate:** inspect untrusted build
  scripts/proc macros before execution and use an approved isolated environment.
  Passing tests, Miri, sanitizers, or an advisory scan does not prove soundness.
  Exact aliasing/provenance models remain partly unsettled; follow documented
  contracts and state model-specific uncertainty.

## Completion gate

- Safe interfaces preserve the shared invariants; remaining caller obligations
  are explicit on unsafe interfaces. Every unsafe operation, trait impl, extern
  declaration, and unsafe attribute has a specific justification.
- Relevant boundary and interruption cases are exercised, including initialization,
  cleanup, callback quiescence, allocator/thread policy, and unwinding where present.
- Rust-only, native, and deployed checks are distinguished. Findings carry the
  contract, trigger, consequence, correction, and actual evidence; skipped/blocked
  areas and unverified targets stay visible rather than becoming a clean verdict.

## Versions and boundaries

Runnable examples target edition 2024, Rust 1.85+, unless explicitly marked
Unix-only. Preserve the consuming project's MSRV and edition unless migration is
requested; newer documentation is not permission to use newer APIs or guarantees.
Nightly tooling is separate.
Rust 2024 extern blocks/unsafe attributes and explicit unsafe operations are
covered in [C boundaries](references/c-boundaries.md#rust-2024-syntax-and-unwinding).

Out of scope: business authorization, cryptographic protocol design, secret-memory
erasure, smart-contract semantics, kernel/device policy, and browser/Wasm security.
Rust unsafe/FFI inside such systems can still be reviewed here without certifying
their domain security. Platform-specific conclusions need the real platform and
contracts; a local probe cannot establish all targets.

Optional handoffs, if installed: **rust-concurrency** for synchronization/runtime
implementation; **rust-idiomatic** for ordinary ownership/errors/I/O;
**rust-api-design** for API ergonomics; **rust-type-diagnostics** for advanced
lifetime/variance/drop-check diagnostics; **rust-tdd** for test-first workflow;
**rust-performance** for measured optimization; **rust-wasm** for JS/WASI boundaries.
