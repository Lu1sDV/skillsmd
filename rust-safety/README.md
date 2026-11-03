# rust-safety

A standalone skill for Rust-specific safety and security review: sound unsafe
abstractions and native FFI, safe-Rust availability/resource hazards, untrusted
input, filesystem/process boundaries, raw OS handles, and concurrency invariants.
It distinguishes library unsoundness from application vulnerabilities and
hardening observations. It is not an all-purpose Rust or security handbook.

## Install

From this checkout:

```sh
mkdir -p ~/.claude/skills
cp -r rust-safety ~/.claude/skills/
```

Or:

```sh
npx skills add Lu1sDV/skillsmd --skill rust-safety
```

Copy the whole bundle, including references and `LICENSE.upstream`. No other
skill is required; named sibling handoffs are optional, not file dependencies.

## Usage prompts

- “Use rust-safety to review this raw-pointer wrapper. Prove lifetime,
  alignment, initialization, aliasing, and destruction for every safe method.”
- “Wrap this C output-buffer API safely. Its error status leaves output
  uninitialized; show the ownership contract and boundary tests.”
- “Migrate these bindings to Rust 2024 without confusing unsafe syntax with a
  proof. Check signatures, symbols, and unwinding.”
- “Audit this parser beyond successful decoding: nesting, declared sizes,
  expansion, formatting, serialization, and destruction on errors.”
- “Review this service's path and process boundaries. Distinguish lexical
  validation from filesystem confinement and argument passing from shell parsing.”
- “Check raw-descriptor ownership and cancellation: who owns each resource
  after success, early return, panic, or task cancellation?”
- “Audit this callback registration for reentrancy, forgotten guards, concurrent
  callbacks, and unregister/free races; verify the actual native boundary.”
- “Interpret this Miri result without treating its model or a passing run as
  a language specification or complete soundness proof.”

## Reference index

| File | Contents |
|---|---|
| [SKILL.md](SKILL.md) | Task routing, evidence workflow, critical guards, scope/version limits, optional handoffs |
| [Safety and initialization](references/safety-and-initialization.md) | Pointer contracts, casts/unions, packed/MMIO caveats, initialization/destruction, unsafe traits, pinning |
| [C boundaries](references/c-boundaries.md) | ABI/layout, native output-wrapper/C caller, strings, allocator ownership, callbacks, Rust 2024 syntax/unwinding |
| [Availability and resources](references/availability-and-resources.md) | Recursive value lifecycles, quotas, panic containment, atomic admission, locks, cancellation, executor progress |
| [Input and OS boundaries](references/input-and-os-boundaries.md) | Checked representations, bounded reads, raw-descriptor ownership, path resolution, processes, output errors |
| [Verification and traps](references/verification-and-traps.md) | Finding classifications, untrusted-build precautions, native/Miri/sanitizer/fuzz/model evidence and limits |
| [Sources and decisions](references/sources-and-decisions.md) | Primary/expert sources, community-skill survey, rejected overclaims, scope and provenance decisions |

## Runnable documentation checks

Examples use stable Rust compatible with edition 2024 / Rust 1.85+, except for
the explicitly Unix-only descriptor example. Keep the consuming project's
actual MSRV/edition; nightly verification is a separate environment.
Run from the repository root:

```sh
rustdoc --test --edition=2024 rust-safety/references/safety-and-initialization.md
rustdoc --test --edition=2024 rust-safety/references/c-boundaries.md
rustdoc --test --edition=2024 rust-safety/references/availability-and-resources.md
rustdoc --test --edition=2024 rust-safety/references/input-and-os-boundaries.md
```

For an independently copied installation, run the same commands with paths rooted
at `$HOME/.claude/skills/rust-safety/`; no neighboring skill files are needed.
These are permanent runnable checks, not a claim that every environment passed.
They assert real boundary behavior, errors, and ownership transitions; no fence
intentionally executes UB. A non-Unix run skips the Unix example, not verifies it.

The [native C caller recipe](references/c-boundaries.md#real-c-caller-for-this-example)
requires Linux, a C11 compiler/linker, and saving the complete Rust/C fences in a
scratch directory. It exercises a separate translation unit, not just a Rust
call with C calling convention. Miri/sanitizer recipes require suitable nightly
tools and a consuming Cargo project; they are optional verification environments,
not prerequisites for reading or installing this skill.

## Research, adaptation, and scope

The preserved unsafe/FFI foundation is a task-oriented synthesis of StructWeave
[chapter 15](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/15-unsafe-ffi.md)
and applicable
[chapter 13 traps](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/13-interview-trap-questions.md),
pinned to `49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168`.
Its MIT notice remains in [LICENSE.upstream](LICENSE.upstream).

The expansion was researched using official Rust/library documentation, original
engineering writing, and GitHub/skill-directory discovery. Community prompts were
treated as leads, not authority. New guidance/examples were written against
verified contracts rather than importing another skill's prose or orchestration.
[Sources and decisions](references/sources-and-decisions.md) records admission,
rejection, version uncertainty, and the different upstream licenses.

Preserved guards include any-safe-caller soundness, explicit pointer/initialization
proofs, callback quiescence, leak-safe registration, allocator pairing, FFI unwind
distinctions, target/layout limits, and genuine native verification. New topics
remain progressively loaded rather than filling the entrypoint with a catalog.

General API architecture, ownership tutorials, concurrency implementation, TDD,
Wasm, and performance stay with optional sibling skills. Cryptographic design,
secret-memory erasure, business authorization, smart contracts, kernel policy,
and browser security need separate scopes. No runtime/framework dependency is
introduced, and the expansion does not modify `vuln-research`.
