# rust-macros

A task-oriented Claude Code skill for Rust declarative and procedural macros:
matching and repetition, hygiene/export, edition migration, `syn`/`quote`,
generics, diagnostics, expansion and caller-level testing. Prefer ordinary
functions and generics unless syntax generation is actually required.

## Install

From this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r rust-macros ~/.claude/skills/
```

The directory is self-contained. Optional handoffs to rust-tdd, rust-idiomatic,
rust-api-design and rust-performance do not require those skills to be installed.
No plugin marketplace manifest or plugin installation is assumed.

## Usage prompts

- “Fix this macro_rules matcher without evaluating any argument twice.”
- “Make my exported macro work from a downstream crate with a renamed dependency.”
- “Migrate this macro definition to edition 2024 without changing arm selection.”
- “Implement a derive with syn 2 and quote, preserving lifetimes and where clauses.”
- “Explain why this attribute loses documentation and misses early returns.”
- “Add passing callers and compile-fail tests for this macro's diagnostics.”

## Reference index

| File | Contents |
|---|---|
| [SKILL.md](SKILL.md) | Routing, workflow, dependency-free syntax/evaluation checks, completion criteria |
| [Declarative macros](references/declarative.md) | All fragment categories, matching/follow sets, nested repetitions, forwarding, hygiene, `$crate`, exports, edition changes |
| [Procedural macros](references/procedural.md) | Complete external-dependency Cargo recipe for derive/attribute/function-like macros; generics, paths, spans, error reporting |
| [Testing and traps](references/testing.md) | Expansion workflow, caller matrix, compile-fail/UI guidance, standard macros, const evaluation |

## Runnable documentation checks

From the repository root, with Rustdoc supporting edition 2024 (Rust 1.85+):

```sh
rustdoc --test --edition=2024 rust-macros/SKILL.md
rustdoc --test --edition=2024 rust-macros/references/declarative.md
rustdoc --test --edition=2024 rust-macros/references/testing.md
```

These commands execute dependency-free `rust` examples and check intentional
`rust,compile_fail` examples. They are permanent verification instructions, not
claims that checks have run. After copying the skill outside the checkout, run
the same commands with `rust-macros/` replaced by the installation directory.
The edition-sensitive assertions intentionally test a 2024 **definition**.
Select and separately test the actual project's supported editions and MSRV;
these examples do not authorize a toolchain upgrade.

The procedural reference is a complete **separate Cargo-project recipe** needing
`syn = "2"` (with `full`), `quote = "1"` and `proc-macro2 = "1"`. Its Rust source
is labeled `text` with explicit file paths because it cannot run as independent
Rustdoc snippets. Once its files are created in sibling `macro_lab/` and
`consumer/` directories, run:

```sh
cargo run --manifest-path consumer/Cargo.toml
```

This compiles the macros in one crate and asserts behavior in the consumer.
Additional downstream rename/edition/UI cases are described in the testing
reference; they are not claimed to be included in that small recipe. Optional
cargo-expand, nightly tooling and trybuild are not bundled dependencies.

## Consolidation and corrections

Adapted from StructWeave's [Rust macros chapter 14](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/14-macros.md)
and the macro/compile-time traps in [chapter 13](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/13-interview-trap-questions.md),
at Rust-content revision `49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168`.
See [LICENSE.upstream](LICENSE.upstream) for the upstream MIT notice.
First-party language and library citations appear in each reference.

This is a rewritten workflow, not a chapter dump or interview-question bank:

- Combined chapter 14's syntax, patterns and interviews into three practical
  references; folded chapter 13's hygiene/const traps into executable checks.
- Replaced blanket “hygienic” claims with mixed-site resolution and downstream
  `$crate`/privacy rules; added definition-edition migration behavior.
- Avoided duplicate-evaluation square macros, globally fixed generated `Built`
  names and the non-working `concat!` of runtime HTML strings. Pattern guidance
  explains their failure modes without copying a broken production recipe.
- Rebuilt procedural examples to preserve generics/where clauses and attributes,
  reject unsupported syntax, and emit spanned errors. Strings interpolated by
  quote are literals, not field identifiers.
- Qualified generated primitive types through `::core::primitive` and added a
  caller that shadows `usize`, covering a hygiene defect found during review.
- Distinguished const evaluation from macro expansion, `cfg!` from removal, and
  configurable debug assertions from an unconditional release-build claim.
- Removed unsupported zero-cost claims: expanded code has ordinary costs, and
  textual expansion is a lossy debugging view rather than correctness proof.

General Cargo setup, ownership, public trait design and testing strategy remain
optional handoffs instead of being duplicated here.
