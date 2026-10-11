# rust-idiomatic

An installable skill for ordinary Rust implementation and review: language syntax,
ownership and borrowing, lifetime diagnostics, error handling, standard-library
boundaries, and the everyday Cargo/editor/lint/debug workflow. It favors standard
operations, explicit failure behavior, and preserving data over clever abstractions.

## Install

From this repository checkout:

```sh
mkdir -p ~/.claude/skills && cp -r rust-idiomatic ~/.claude/skills/
```

The copied directory contains its own references and attribution. No sibling skill
or plugin marketplace manifest is required. If replacing a prior local copy,
preserve local changes before copying.

## Usage prompts

- “Use rust-idiomatic to fix this partial-move error without unnecessary clones.”
- “Review this line parser for CRLF, UTF-8, whitespace loss and dropped errors.”
- “Explain this lifetime bound and whether the result should borrow or own.”
- “Review our Cargo workspace/MSRV and stable rustfmt/Clippy configuration.”
- “Refactor this Option/Result chain while preserving absence versus failure.”

For public API architecture, use **rust-api-design** if installed. For test-driven
implementation and CI, use standalone **rust-tdd**. Algorithm selection,
concurrency, macros, unsafe/FFI, WebAssembly and performance measurement have their
own optional Rust skills; this bundle does not require them to load.

## Reference index

| File | Content |
|---|---|
| [SKILL.md](SKILL.md) | Trigger, quick routing, workflow, review gates and handoffs |
| [Language and ownership](references/language-ownership.md) | Syntax, traits, ownership choices, partial moves, reborrowing, lifetime bounds, closure capture |
| [Errors and idioms](references/errors-idioms.md) | Option/Result policy, fallible parsing, source chains, conversions, numeric boundaries and documentation |
| [Standard-library boundaries](references/stdlib-boundaries.md) | UTF-8, allocation semantics, collections/iterators, exact line endings, filesystem/paths/environment/time |
| [Project workflow](references/project-workflow.md) | Cargo commands, lockfiles, workspaces, MSRV/edition, stable tools, debugging and safe migration |
| [LICENSE.upstream](LICENSE.upstream) | Upstream MIT notice |

## Runnable examples

The ordinary `rust` fences are dependency-free, complete Rust programs or doctest
bodies with assertions. The one `rust,compile_fail` fence intentionally demonstrates
use of a partially moved whole value. From the repository root, these are the
permanent checks (not a claim that they have already run):

```sh
rustdoc --test --edition=2024 rust-idiomatic/SKILL.md
rustdoc --test --edition=2024 rust-idiomatic/references/language-ownership.md
rustdoc --test --edition=2024 rust-idiomatic/references/errors-idioms.md
rustdoc --test --edition=2024 rust-idiomatic/references/stdlib-boundaries.md
```

From inside an independently copied `rust-idiomatic` bundle, the equivalent checks
are:

```sh
rustdoc --test --edition=2024 SKILL.md
rustdoc --test --edition=2024 references/language-ownership.md
rustdoc --test --edition=2024 references/errors-idioms.md
rustdoc --test --edition=2024 references/stdlib-boundaries.md
```

These examples target edition 2024 without external crates. Project code must
still follow its own MSRV and edition; this example invocation does not authorize
upgrading a consumer project. Shell commands and workspace TOML are illustrative
recipes, not hidden executable Rust. `project-workflow.md` contains no Rust fence.
The line-normalization example covers trusted finite input; it documents the
additional size/deadline policy required for an untrusted stream.

## Sources and adaptation

Original consolidation/adaptation of the following StructWeave guides by
[nirajkvinit / StructWeave-Algorithms](https://github.com/nirajkvinit/StructWeave-Algorithms),
pinned at Rust-content commit `49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168`:

| Upstream chapter | Adapted coverage |
|---|---|
| [01 — Syntax quick reference](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/01-syntax-quick-reference.md) | Core syntax, patterns, traits/generics, closures, conversions and edition constraints |
| [02 — Ownership and borrowing](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/02-ownership-borrowing.md) | Ownership decisions, borrowing, lifetimes, pointers, interior mutability and compiler-error repairs |
| [05 — Idioms and best practices](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/05-idioms-best-practices.md) | Error/Option handling, iteration, conversion and documentation; API patterns and testing handed off |
| [07 — Tooling and workflow](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/07-tooling-workflow.md) | General Cargo, workspaces, tooling, editor and debugging; testing/CI belongs to rust-tdd |
| [13 — Interview trap questions](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/13-interview-trap-questions.md) | Partial moves, reborrows, lifetime/HRTB bounds, allocation, numeric and standard-library correctness traps |
| [17 — Standard-library essentials](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/17-std-library-essentials.md) | Production strings, iterators, collections, I/O, filesystem, paths, environment, time, formatting and conversion |

### Consolidation decisions

- One task-oriented entry point replaces overlapping syntax/ownership/interview
  chapters. Four cohesive references load on demand rather than reproducing full
  chapter catalogs. Sources are recorded here and first-party authorities are
  linked beside each reference's semantics.
- Keep trait syntax and ordinary errors here; public abstraction/API design,
  builders/newtypes and SOLID/GoF design belong to **rust-api-design**. Keep general
  Cargo/editor/lint/debugging here; testing methods and test CI belong to
  **rust-tdd**. Synchronization belongs to **rust-concurrency**; no copied lock or
  atomic recipes. Profiling and measured optimization stay in **rust-performance**.
- Replace interview-only shortcuts with production boundary contracts: no blind
  `unwrap`, no `filter_map(Result::ok)` for I/O, no unchecked coordinate indexing,
  no general-purpose whitespace trimming to remove line endings.
- Correct upstream ownership traps: reborrowing does not permanently disable the
  original reference; `Fn(&str) -> &str` already expresses the elided HRTB; lifetime
  annotations do not extend storage. Moving a `String` does not move its heap
  contents, and adding `Pin` is not by itself a self-reference safety proof.
- Correct allocation/capacity oversimplifications: `Clone` need not be deep;
  `String -> String` is a move; empty strings/vectors and zero-sized vector elements
  need not allocate; capacity is not initialized length or always an exact request.
  Avoid absolute “zero cost” and unmeasured performance claims.
- Correct standard-library traps: lazy adapters are distinct from consumers;
  `scan` remains lazy; float `.max()` lacks `Ord`; collection ordering/equality
  contracts must agree; `metadata` follows symlinks; environment mutation is unsafe
  in edition 2024. Preserve bare CR and payload spaces while handling LF/CRLF.
- Keep versions explicit rather than copying forecasts or all-purpose setups:
  2024 needs 1.85+, let chains need 1.88+ and 2024; Cargo add/remove are built in on
  that baseline; nightly rustfmt options are not stable defaults; `cargo fix` is
  mutating, not a dry-run check. Do not blindly install crates or enable all features.

The upstream MIT notice is retained in [LICENSE.upstream](LICENSE.upstream).
