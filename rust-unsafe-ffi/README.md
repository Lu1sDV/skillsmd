# rust-unsafe-ffi

A standalone Claude Code skill for reviewing and building sound Rust unsafe
abstractions and native C/C++ boundaries. It covers raw-pointer proof obligations,
initialization and destruction, unsafe traits, provenance, C layout/ABI,
callbacks, ownership, C strings, unwinding, Rust 2024 syntax, and the limits of
Miri/sanitizer evidence.

## Install from this checkout

Run from the repository root:

```sh
mkdir -p ~/.claude/skills
cp -r rust-unsafe-ffi ~/.claude/skills/
```

Copy the whole directory, including references and `LICENSE.upstream`.
No other skill is required. The named handoffs are optional installed skills,
not dependencies or links to neighboring bundles.

## Usage prompts

- “Use rust-unsafe-ffi to review this raw-pointer wrapper. Prove lifetime,
  alignment, initialization, aliasing, and destruction for every safe method.”
- “Wrap this C output-buffer API safely. Its error status leaves output
  uninitialized; show the ownership contract and boundary tests.”
- “Audit this callback registration API for concurrent callbacks, reentrancy,
  forgotten guards, and unregister/free races.”
- “Migrate these bindings to Rust 2024 without confusing unsafe syntax with a
  proof. Check signatures, symbols, and unwinding.”
- “Interpret this Miri failure and identify what still needs native C integration
  tests or sanitizers.”

## Reference index

| File | Contents |
|---|---|
| [SKILL.md](SKILL.md) | Task routing, proof workflow, boundary pitfalls, completion criteria, optional handoffs |
| [Safety and initialization](references/safety-and-initialization.md) | Pointer validity/alignment/lifetimes/aliasing/provenance, packed/MMIO caveats, `MaybeUninit`, `Drop`, unsafe traits, pinning |
| [C boundaries](references/c-boundaries.md) | ABI/layout, a complete safe output-wrapper example and real C caller, ownership, strings, callbacks, edition syntax, unwinding, binding tools |
| [Verification and traps](references/verification-and-traps.md) | Rust/native checks, Miri/sanitizer limits, corrected chapter 13/15 traps, source mapping |

## Runnable documentation checks

Examples use dependency-free stable Rust with edition 2024 (Rust 1.85+).
Select the consuming project's actual MSRV/edition rather than assuming this
example baseline requires a project migration. Run these commands from the
repository root; they execute all Rust fences in the two example-bearing files:

```sh
rustdoc --test --edition=2024 rust-unsafe-ffi/references/safety-and-initialization.md
rustdoc --test --edition=2024 rust-unsafe-ffi/references/c-boundaries.md
```

To exercise an independently copied installation from any working directory:

```sh
rustdoc --test --edition=2024 "$HOME/.claude/skills/rust-unsafe-ffi/references/safety-and-initialization.md"
rustdoc --test --edition=2024 "$HOME/.claude/skills/rust-unsafe-ffi/references/c-boundaries.md"
```

These are permanent runnable checks, not claims of already-passing results. The
examples assert successful and overflow output contracts, untouched error output,
exactly-once destruction after initialization, C-string validation, and a correct
ownership round trip. No fence intentionally executes undefined behavior.

The [separate native C recipe](references/c-boundaries.md#real-c-caller-for-this-example)
requires Linux, a C11 compiler/linker, and saving its complete Rust/C fences in a
scratch directory. The Miri and sanitizer recipes require a suitable nightly
installation and run against a consuming Cargo project; they are not prerequisites
for using the skill or running its Rust doctests. Neither Miri nor a Rust-only
ABI call proves the behavior of an external C library.

## Consolidation and adaptation

This is an original task-oriented synthesis of StructWeave-Algorithms
[chapter 15](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/15-unsafe-ffi.md)
and applicable
[chapter 13 traps](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/13-interview-trap-questions.md),
pinned to Rust-content revision `49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168`.
The upstream material is MIT-licensed; see [LICENSE.upstream](LICENSE.upstream).

- Consolidates the unsafe/FFI chapter into three on-demand references rather than
  loading a long tutorial or copying the entire interview chapter.
- Replaces intentional UB and incomplete custom collections/lock-free structures
  with valid, complete examples and explicit safety contracts.
- Corrects null-check-only safety claims, unconditional `Send`/`Sync` reasoning,
  lifetime-extension slogans, blanket FFI-unwind claims, and stale Miri switches.
- Adds initialization/destructor transitions, callback quiescence and leak-safe
  registration design, Rust 2024 declarations/attributes, explicit provenance,
  sanitizer/native-test limitations, and a genuine separate C translation unit.
- Keeps general synchronization, API design, TDD, Wasm, and measured optimization
  with the optional **rust-concurrency**, **rust-api-design**, **rust-tdd**,
  **rust-wasm**, and **rust-performance** skills. No binding framework or runtime
  dependency is introduced by this bundle.

Rust Reference, Nomicon, standard-library, Edition Guide, Miri, and sanitizer
sources are linked at the relevant claims. The source mapping and important
corrections are in [Verification and traps](references/verification-and-traps.md#sources-and-adaptation).
