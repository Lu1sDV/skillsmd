---
name: rust-unsafe-ffi
description: >
  Use when writing or reviewing Rust unsafe blocks, raw-pointer abstractions,
  MaybeUninit or manual Drop code, unsafe trait implementations, or C/C++ FFI
  bindings. Covers pointer validity, aliasing and provenance, C ABI/layout,
  callbacks, allocator ownership, C strings, unwinding, Rust 2024 unsafe syntax,
  and interpreting Miri or sanitizer findings.
---

# Rust Unsafe and FFI

## Quick reference: route the task

| Task or symptom | Read | First decision |
|---|---|---|
| Raw pointers, dangling references, provenance, packed fields | [Safety and initialization](references/safety-and-initialization.md) | Can a slice, reference, index, or existing owner express this safely? |
| `MaybeUninit`, `set_len`, manual allocation, double drop | [Safety and initialization](references/safety-and-initialization.md#initialization-and-destruction) | Which elements are initialized, and who drops them on every exit? |
| `unsafe impl`, `Send`/`Sync`, self-reference | [Safety and initialization](references/safety-and-initialization.md#unsafe-traits-and-pinning) | What can arbitrary safe clients do to this invariant? |
| C signature, layout, linking, bindings generation | [C boundaries](references/c-boundaries.md) | Which target ABI, header version, allocator, and compiler flags apply? |
| C string, callback, retained pointer, foreign handle | [C boundaries](references/c-boundaries.md#ownership-and-lifetimes) | Borrow, copy, or transfer ownership; when may foreign code stop using it? |
| Panic, exception, 2024 edition warning | [C boundaries](references/c-boundaries.md#rust-2024-syntax-and-unwinding) | Is unwinding prohibited, contained, or explicitly part of the ABI? |
| Miri failure, sanitizer configuration, proof review | [Verification and traps](references/verification-and-traps.md) | Which paths and which side of the boundary were actually exercised? |

## Non-negotiable contract

A safe API must not let **any safe caller** cause undefined behavior (UB), not
just the callers in today's test suite. `unsafe` does not disable the borrow
checker or relax Rust's validity rules. Safe code can encounter UB through an
unsound dependency; “it compiles” is not a safety proof.
[Source: Rust Reference](https://doc.rust-lang.org/reference/behavior-considered-undefined.html).

Prefer standard safe operations. An unchecked lookup, hand-written allocator,
or pointer cast needs a concrete capability requirement or measured motivation;
`unsafe` is not inherently faster. Do not add a partial collection implementation
just to wrap one foreign call.

## Workflow

1. **Identify the boundary.** Read the actual foreign header/API contract and
   existing wrapper, constructors, mutators, destructors, and callers. Establish
   project MSRV, edition, supported targets, panic strategy, dependency versions,
   native build flags, and whether calls can reenter or run concurrently.
2. **State the invariants before code.** Record allocation owner and extent,
   initialization state, alignment, aliasing permissions, borrow duration,
   permitted threads, callback lifetime, and release function. A raw address or
   `NonNull` alone establishes almost none of these.
3. **Choose the smallest safe surface.** Prefer `&[T]`, `&mut [T]`, `&CStr`, owned
   handles with private fields, and `Result`. If callers must prove memory
   validity, expose an `unsafe fn` with a precise `# Safety` section; do not hide
   that obligation behind a safe raw-pointer function and a null check.
4. **Implement the proof locally.** Minimize unsafe blocks and put a `SAFETY:`
   argument at each one: identify the fact, where it was established, and how
   long it remains true. Document the module invariant when multiple safe
   methods participate. Do not merely restate “pointer is valid.”
5. **Account for interruption.** Review error returns, panics, user callbacks,
   generic `Clone`/`Drop`, reentrancy, registration failure, and cancellation.
   Restore invariants before calling user code. Leaking an owner must not leave
   a foreign callback pointing at a subsequently freed borrowed stack value.
6. **Verify the contract, not an unsafe misuse.** Test valid boundary cases,
   safe rejection of invalid requests, exactly-once cleanup, and real native
   integration. Never deliberately execute UB as a normal regression test.
   Use Miri and appropriate sanitizers as additional evidence, not proof.
7. **Report the remaining trust.** Name unverified targets, foreign code paths,
   unsupported tools, and contracts provided by a native library rather than
   checked by Rust.

## Pointer proof checklist

Before a dereference, reference construction, or raw-memory operation, answer:

- **Extent:** Is the entire accessed range inside the required live allocation?
  Have byte-count arithmetic and conversions been checked for overflow?
- **Alignment:** Does this operation require `align_of::<T>()`? An unaligned
  load needs an unaligned operation, not a temporary unaligned reference.
- **Initialization and validity:** Are the required `T` values initialized and
  valid, including discriminants, references, and ownership invariants?
- **Lifetime:** What keeps the allocation alive and prevents reallocation?
  Returned borrows must be tied to an owner, not a freely chosen lifetime.
- **Aliasing:** May this operation read or write now? Is a foreign callback
  capable of accessing the same bytes while a Rust reference is live?
- **Provenance:** Was the pointer derived with permission to access these bytes?
  Equal addresses and integer casts do not prove permission.
- **Destruction:** Will ownership be moved or copied? Who is allowed to destroy
  the value and deallocate the storage, and on which thread?

Raw pointer validity is operation-specific; exact aliasing/provenance semantics
are not fully settled. Follow the documented API preconditions rather than
promoting a particular Miri model into a language specification.
[Sources: pointer safety](https://doc.rust-lang.org/std/ptr/index.html#safety),
[provenance](https://doc.rust-lang.org/std/ptr/index.html#provenance).

## Boundary mistakes to reject

| Mistake | Required replacement |
|---|---|
| “Not null, therefore safe to dereference” | Establish extent, alignment, initialization, lifetime, aliasing, and provenance |
| Form a Rust slice from `(NULL, 0)` | Handle the empty case before reference construction; raw-slice constructors still require non-null aligned pointers |
| Set `Vec` length to capacity before a foreign write | Publish only the initialized prefix after a successful, bounded write |
| Mark a raw-pointer wrapper `Send + Sync` to satisfy an error | Prove ownership, thread-affinity, access synchronization, and destruction separately |
| Let C free a `Box` or `CString` | Return it through the matching Rust release function, exactly once |
| Return `CString::new(...).unwrap().as_ptr()` | Keep the owner alive for the whole borrow or explicitly transfer ownership |
| Assume `repr(C)` makes `String`, `Vec`, or `&str` C-compatible | Use agreed scalar fields, pointer/length pairs, and opaque handles |
| Catch a panic outside an `extern "C"` callback | Contain recoverable Rust panics inside the callback before they cross its non-unwinding boundary |
| Free callback context immediately after unregistering | Establish that no callback is in flight and none can start afterward |
| Treat Miri/native tests as a soundness certificate | Keep the written proof and state execution, target, and foreign-code coverage limits |

The detailed preconditions and source links are in the routed references.

## Edition and toolchain policy

Examples use Rust 2024, which requires Rust 1.85 or newer. Keep the consuming
project's chosen MSRV and edition unless migration is requested; nightly tooling
is a separate verification environment, not an implied production requirement.
[Edition guidance](https://doc.rust-lang.org/edition-guide/rust-2024/index.html).

In Rust 2024, use `unsafe extern "C" { ... }` declarations and
`#[unsafe(no_mangle)]` / `#[unsafe(export_name = "...")]` /
`#[unsafe(link_section = "...")]` where applicable. Unsafe operations inside
an `unsafe fn` still belong in explicit unsafe blocks; the
`unsafe_op_in_unsafe_fn` lint warns by default. These annotations expose proof
obligations; they do not fulfill them.
[Details and authoritative links](references/c-boundaries.md#rust-2024-syntax-and-unwinding).

## Completion criteria

- Safe interfaces encode ownership/lifetimes or validate what they can; all
  remaining caller obligations are explicit on unsafe interfaces.
- Every raw operation, unsafe trait impl, extern declaration, and unsafe
  attribute has a specific justification; all methods preserve shared invariants.
- Initialization, failure cleanup, destructor behavior, callback quiescence,
  allocator pairing, thread policy, and unwinding are covered.
- Boundary tests include empty/zero values, maximum valid sizes, error statuses,
  partial initialization where supported, and repeated ownership cycles.
- Rust-only checks and real foreign integration checks are distinguished; report
  exactly what ran and what could not run.

## Optional handoffs

- **rust-tdd**, if installed: red-green-refactor, regression design, property
  testing, and CI; this skill supplies memory-safety and ABI proof obligations.
- **rust-concurrency**, if installed: synchronization, atomics, cancellation,
  callback scheduling, and shutdown; return here for unsafe ownership proofs.
- **rust-api-design**, if installed: public handle ergonomics and type contracts.
- **rust-performance**, if installed: measure before introducing unchecked access,
  custom allocation, SIMD, or a lock-free implementation.
- **rust-wasm**, if installed: JS/Wasm or WASI boundaries are not interchangeable
  with native C ABI recipes.
