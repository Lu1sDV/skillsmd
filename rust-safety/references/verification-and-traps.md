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

## Classify evidence before assigning impact

| Result | Required distinction |
|---|---|
| Soundness defect | A permitted safe call sequence can violate an unsafe contract; no deployed network route is needed to establish unsoundness |
| Application vulnerability | Attacker influence, reachable operation, failed defense, and concrete consumer harm under the actual build/runtime |
| Correctness defect | A contract fails; security consequences have not been established |
| Hardening observation | Missing lint/comment/optional mitigation, without evidence of a violated execution contract |
| Unverified or blocked | Missing callers, target, tool, configuration, or reproduction; not a clean result |

For each finding report: **location; violated contract/source; trigger and call
path; defenses checked; impact; minimal correction; executed evidence and limits**.
Refute a defect when its required precondition cannot occur. Do not merely reduce
severity because the alleged unsafe operation is actually valid. Preserve unknowns
without presenting every suspicious API or failed proof as a vulnerability.

For DoS, distinguish request failure, a panicking task, worker starvation, and
process death. Observe the real serving process and recovery policy. For library
soundness, include downstream-safe misuse and hostile safe trait implementations;
do not require an artificial remote exploit. Check relevant feature/target/build
variants rather than automatically enabling mutually incompatible features.

## Do not execute untrusted projects as reconnaissance

Cargo build/check/test and procedural macros/build scripts can execute host code.
Miri isolation is explicitly **not** a security sandbox. Inspect first; obtain
execution authority and use an appropriate external sandbox with no production
credentials or writable unrelated data. Do not run discovered skill installers
or target helpers just to inspect their contents.
[Cargo build scripts](https://doc.rust-lang.org/cargo/reference/build-scripts.html),
[proc-macro security](https://doc.rust-lang.org/reference/procedural-macros.html),
[Miri's isolation caveat](https://github.com/rust-lang/miri).

Even `cargo audit` needs care on an untrusted checkout: generating a missing
lockfile invokes Cargo. Its maintainers recommend supplying the existing lockfile
with `--file` and running outside the project. Record advisory database freshness,
tool/configuration, ignored advisories, and warnings; exit status alone is not
“no unsound dependencies.” Advisory scans find known reports, not all source bugs.
[cargo-audit security caveat](https://github.com/rustsec/rustsec/tree/main/cargo-audit).

## Stable Rust checks

For this installed bundle, run the dependency-free examples from the repository
root (the descriptor example is Unix-only):

```sh
rustdoc --test --edition=2024 rust-safety/references/safety-and-initialization.md
rustdoc --test --edition=2024 rust-safety/references/c-boundaries.md
rustdoc --test --edition=2024 rust-safety/references/availability-and-resources.md
rustdoc --test --edition=2024 rust-safety/references/input-and-os-boundaries.md
```

Inside a consuming Rust crate, use its supported features/targets and normal test
commands. `cargo test` and doctests do not check all raw-pointer rules at runtime.
Run the [complete C caller recipe](c-boundaries.md#real-c-caller-for-this-example)
when checking the example's native ABI; it requires a C toolchain and Linux loader
conventions. These commands are instructions, not recorded results.

## Miri: useful evidence with explicit boundaries

Tool behavior below was checked against the documented options on 2026-11-03.
Before running a recipe, verify it against the chosen toolchain's own docs; stop
and report unsupported flags or targets rather than silently weakening checks.

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

Do not copy stale switches: the inspected Miri documentation enables leak
checking by default without `-Zmiri-leak-check`. Its `-Zmiri-preemption-rate=0`
**disables** preemption; it does not enable race detection. Recheck these options
for the selected nightly rather than treating this snapshot as a timeless default.
[Source: Miri options](https://github.com/rust-lang/miri).

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

## Fuzzing and concurrency models

Fuzz the real parser/FFI boundary with constrained input sizes and preserve a
minimized reproducer. Include composition, formatting, and error cleanup where
they consume the produced value, not just successful parsing. Fuzzing supplies
executed cases, not a proof of coverage or safety; sanitizer findings still need
source/contract triage. Use compile-fail tests for forbidden safe API use.
[Rust Fuzz Book](https://rust-fuzz.github.io/book/).

For concurrency, a scheduled regression should force the problematic ordering
without arbitrary sleeps. Loom can explore modeled schedules with its replacement
types, but ordinary synchronization outside that model is not automatically
covered; bounds and memory-model limitations remain. Retain native integration
checks. Do not equate relaxed logical races with Rust data races.
[Loom usage and limitations](https://docs.rs/loom/latest/loom/),
[Nomicon race distinctions](https://doc.rust-lang.org/nomicon/races.html).

Validate release behavior separately when the claim depends on overflow,
debug assertions, panic strategy, or stack use. Use resource-bounded subprocesses
for expected crashes and disable core dumps where they could contain sensitive
data. Do not claim Windows, alternate architectures, Miri, or foreign-library
coverage from a Linux stable-Rust doctest.

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
Rust 2024 syntax, provenance qualifications, sanitizer limits, and a real
C caller. Reference/std rules take precedence over older teaching shorthand;
the foreign-exception catch semantics in the inspected Reference are more specific
than the Nomicon's older blanket wording. First-party sources are linked
next to the corresponding claims. The broader research and admission decisions
are recorded in [Sources and decisions](sources-and-decisions.md).
