# Verification, limits, and reasoning traps

## Review first, then exercise the proof

A clean test run establishes behavior for the tested executions, not soundness
for every safe client. Review constructors, mutators, returned borrows, generic
callbacks, ownership transfers, and destructors as one invariant boundary.
[Reference definition of soundness](https://doc.rust-lang.org/reference/behavior-considered-undefined.html#r-undefined.soundness).

| Area | Positive/boundary checks | What not to do |
|---|---|---|
| Pointer/length wrappers | Empty input, one element, maximum supported count, length conversion overflow | Pass a dangling pointer and expect an ordinary error |
| Initialization | Success initializes the claimed prefix; errors leave the specified state; cleanup drops exactly that prefix | Read uninitialized output just to see what C wrote on failure |
| Ownership | Repeated create/use/release cycles; exactly-once destructor counters; valid Rust/foreign round trips | Deliberately double-free to make a regression test fail |
| C strings | Empty string, missing terminator in a valid bounded slice, interior NUL, non-UTF-8 bytes | Scan beyond an allocation looking for NUL |
| Callbacks | Registration failure, allowed reentrancy/concurrency, unregister with an in-flight callback, no calls after quiescence | Free context and then call it to demonstrate a race |
| ABI/layout | Real foreign compilation, sizes/alignments/offsets, actual header, native errors | Assume Rust-to-Rust calls prove C compiler compatibility |
| Unwinding | Expected errors as statuses; any promised panic containment; subprocess checks for intended abort behavior | Let foreign exceptions cross non-unwinding Rust frames |

Test **safe rejection before unsafe access** where inputs are checkable. Unsafe
preconditions such as allocation ownership cannot be validated by inspecting a
pointer's numerical address. For unsafe internals, exercise valid boundary states
and use compile-fail tests for lifetime/type restrictions rather than UB demos.

## Stable Rust checks

For this installed bundle, the dependency-free runnable examples are in
`safety-and-initialization.md` and `c-boundaries.md`. From the repository root:

```sh
rustdoc --test --edition=2024 rust-unsafe-ffi/references/safety-and-initialization.md
rustdoc --test --edition=2024 rust-unsafe-ffi/references/c-boundaries.md
```

Inside a consuming Rust crate, use its supported features/targets and normal test
commands. `cargo test` and doctests do not check all raw-pointer rules at runtime.
Run the [complete C caller recipe](c-boundaries.md#real-c-caller-for-this-example)
when checking the example's native ABI; it requires a C toolchain and Linux loader
conventions. These commands are instructions, not recorded results.

## Miri: useful evidence with explicit boundaries

[Miri's own documentation](https://github.com/rust-lang/miri) describes its checks
and limitations. It interprets Rust executions and can detect out-of-bounds
accesses, use-after-free, invalid/uninitialized values, alignment violations,
invalid intrinsic preconditions, data races, and violations of its experimental
aliasing models. Leak detection is enabled by default; leaks are reported issues
but are not in themselves Rust UB.

For a Rust project, with `rustup` and a nightly toolchain containing Miri available:

```sh
rustup +nightly component add miri
cargo +nightly miri test
MIRIFLAGS="-Zmiri-strict-provenance" cargo +nightly miri test
MIRIFLAGS="-Zmiri-tree-borrows" cargo +nightly miri test
MIRIFLAGS="-Zmiri-seed=1" cargo +nightly miri test
```

Pin the actual nightly in CI and consult its Miri documentation: flags and models
change. Tree Borrows is an alternate experimental check, not a compatibility
switch to dismiss a Stacked Borrows finding. Investigate the operation and its
public contract when models differ. The strict-provenance mode rejects ambiguous
integer-to-pointer operations; prefer explicit pointer-provenance APIs.
[Source: Miri flags](https://github.com/rust-lang/miri#miri--z-flags-and-environment-variables).

Limits to report:

- A test covers only its paths, inputs, schedules, target, and active memory model.
  Varying seeds helps but cannot exhaust concurrency or weak-memory behavior.
- Most platform APIs and arbitrary foreign functions are not interpreted. An
  unsupported-operation diagnostic is not itself evidence of UB or of safety.
  Keep Rust-only contract tests **and** real native integration tests. Isolate an
  unsupported test only with a documented reason; do not replace the foreign
  operation with a no-op and claim the boundary passed.
- Experimental native-library support can execute some foreign calls but loses
  checks, including initialization/provenance tracking for shared native memory,
  and has target/thread restrictions. It does not validate the foreign library.
- A program can pass Miri while relying on unspecified layout or missing a
  different execution's bug. Miri is neither a full language specification nor a
  soundness certificate.

[Source: Miri limitations and native-library flags](https://github.com/rust-lang/miri).

Do not copy stale switches: current Miri does not need an upstream-style
`-Zmiri-leak-check` to enable leak checking. `-Zmiri-preemption-rate=0` **disables**
preemption; it is not a switch that enables race detection.
[Source: current Miri options](https://github.com/rust-lang/miri).

## Sanitizers and the foreign side

Rust's `-Zsanitizer` facilities are nightly, target-dependent instrumentation.
Choose the sanitizer for the property: AddressSanitizer for many memory access/
free errors, ThreadSanitizer for races, MemorySanitizer for uninitialized reads,
and LeakSanitizer for leaks. They do not establish Rust reference aliasing or
provenance soundness merely because native execution passes.
[Rust Unstable Book](https://doc.rust-lang.org/unstable-book/compiler-flags/sanitizer.html).

Example for an existing crate on the supported `x86_64-unknown-linux-gnu` target,
with nightly, `rust-src`, and a native toolchain installed:

```sh
rustup +nightly component add rust-src
RUSTFLAGS="-Zsanitizer=address" RUSTDOCFLAGS="-Zsanitizer=address" cargo +nightly test -Zbuild-std --target x86_64-unknown-linux-gnu
```

This is not a universal cross-platform command. Set `--target` so sanitizer
Rust flags do not instrument host build scripts/procedural macros inadvertently.
Use separate sanitizer jobs/configurations rather than piling every sanitizer
into one command. For mixed Rust/C/C++:

1. Rebuild the native library and C integration caller with the selected
   sanitizer's compatible compiler settings; Rust flags do not instrument C.
2. Match sanitizer runtime/linker choices across languages; incompatible runtimes
   can require explicit configuration such as `-Zexternal-clangrt`.
3. Account for instrumentation gaps: ASan can miss bugs in uninstrumented code;
   MSan needs the whole relevant program instrumented to avoid false positives.
4. Symbolize reports, record Rust/native compiler versions, and run supported
   target/build matrices. Platform layout differences need native tests even if
   a host run succeeds.

[Source: instrumentation and mixed-language caveats](https://doc.rust-lang.org/unstable-book/compiler-flags/sanitizer.html#instrumentation-of-external-dependencies-and-std).

## Reasoning traps retained and corrected

These questions consolidate relevant material from chapters 13 and 15 without
copying their UB demonstrations. Answer with the violated contract, not a slogan.

| Question | Correct reasoning / action |
|---|---|
| Does dereferencing `&mut T` require unsafe? | No. Raw-pointer access has additional unchecked obligations; wrapping ordinary reference use in unsafe proves nothing. |
| Does non-null mean a foreign pointer is usable? | No: alignment, extent, initialization, permission, lifetime, and ownership remain unproven. |
| Does matching size make `transmute` sound? | No: validity, layout, lifetime, and ownership still matter. Use byte conversions or `f32::from_bits` for their intended conversions. |
| Does a lifetime cast extend allocation lifetime? | No. An arbitrary lifetime-extending safe API is unsound; it is inaccurate to say every possible invocation is immediate UB. |
| Is capacity initialized length? | No. Reserve storage, initialize the prefix, then publish length; ordinary indexing beyond length panics rather than becoming an allocation proof. |
| Does `ptr::read` clone a resource? | No. It bit-copies even non-`Copy` values. Prevent a second owner/drop or use a safe move/clone operation. |
| Is `T: 'static` equivalent to immortality? | No. It constrains borrowed lifetimes, not drop time. Owned callback context still needs retention/teardown. Raw pointers do not track pointee lifetimes. |
| Does moving a `String` necessarily relocate its characters? | Moving the handle differs from reallocation of its buffer. Pinning an outer value does not freeze a contained growable allocation. Prefer offsets or restrict all invalidating operations. |
| Do `unsafe impl Send` and `Sync` mean the same thing? | No: transfer versus shared access. Prove pointee bounds, thread-affinity, synchronization, callback behavior, and destruction separately. |
| Is safe recursion/reentrancy intrinsically UB? | No. Reentering while creating conflicting references, accessing temporarily invalid state, or violating a foreign contract is the problem. |
| Is all panic across FFI UB? | No: a Rust panic hitting a non-unwinding Rust C boundary aborts; `C-unwind` can permit deliberate unwinding. Foreign exceptions entering through non-unwinding declarations are UB. |
| Does Miri define the final Rust aliasing model? | No. Follow std/Reference contracts; explain model-specific findings and never mistake a passing run for proof. |
| Is volatile enough for MMIO/thread safety? | Follow the target's volatile/register contract for MMIO. Volatile is not atomic synchronization, and a fixed address does not justify an ordinary mutable reference. |

Authoritative reasoning: [pointer contract](https://doc.rust-lang.org/std/ptr/index.html),
[MaybeUninit](https://doc.rust-lang.org/std/mem/union.MaybeUninit.html),
[raw read](https://doc.rust-lang.org/std/ptr/fn.read.html),
[pinning](https://doc.rust-lang.org/std/pin/index.html),
[Send/Sync](https://doc.rust-lang.org/nomicon/send-and-sync.html),
[unwinding](https://doc.rust-lang.org/reference/panic.html#unwinding-across-ffi-boundaries),
[volatile](https://doc.rust-lang.org/std/ptr/fn.read_volatile.html),
and [Miri](https://github.com/rust-lang/miri).

## Sources and adaptation

Adapted from StructWeave-Algorithms at Rust-content revision
`49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168`:

- [15 — Unsafe Rust and FFI](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/15-unsafe-ffi.md): unsafe contracts, pointers, UB, safe abstractions, C ABI/tools, ownership, strings, callbacks, Miri, hardware, and reasoning traps.
- [13 — Interview trap questions](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/13-interview-trap-questions.md): self-reference/pinning, lifetimes/`'static`, `Send`/`Sync`, initialized length versus capacity, and ownership copies.
- [Upstream MIT notice](../LICENSE.upstream).

This bundle replaces unsafe demonstrations and incomplete `SafeVec`/lock-free
examples with complete valid contract examples and explicit handoffs. It adds
`MaybeUninit`/drop-state reasoning, callback quiescence and forgotten-guard safety,
current Rust 2024 syntax, provenance qualifications, sanitizer limits, and a real
C caller. Reference/std rules take precedence over older teaching shorthand;
notably, the current Reference's foreign-exception catch semantics are more
specific than the Nomicon's older blanket wording. First-party sources are linked
next to the corresponding claims throughout the three references.
