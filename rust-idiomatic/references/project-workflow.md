# Project workflow

## Establish the build contract

Before changing code, inspect `Cargo.toml` (including workspace root), `Cargo.lock`,
`rust-toolchain.toml` if present, `.cargo/config.toml`, existing CI, target, feature
combinations and lint/format configuration. The repository's chosen compiler is
not necessarily the host's default. Record `rustc --version` and `cargo --version`
when running checks; `cargo metadata --no-deps --format-version 1` exposes package,
target and workspace structure without inferring it from directory names.

**Edition and MSRV are distinct.** Preserve the project's `rust-version`; do not
raise it silently. Edition 2024 requires Rust 1.85+. Let chains require both
edition 2024 and Rust 1.88+. A new API's stabilization version also matters. A
newer compiler successfully compiling code does not prove it supports the MSRV.
Do not copy forecasts about gen blocks, Polonius or other nightly features into
a stable project. Consult the project's versioned documentation and feature gates.

## Command card

These commands describe normal project work, not permission to execute checks
against an assignment that forbids verification. Substitute the actual package,
binary, target and supported feature set when narrowing a command.

| Need | Command | Scope / caveat |
|---|---|---|
| New binary / library | `cargo new name` / `cargo new name --lib` | Only when creating a project is requested |
| Fast feedback | `cargo check` | Checks selected code; does not prove runtime behavior |
| Whole workspace check | `cargo check --workspace` | Explicitly includes workspace members |
| Build executable artifacts | `cargo build` / `cargo build --release` | Profiles can change overflow/panic behavior |
| Pass runtime arguments | `cargo run -- arg1 arg2` | `--` separates Cargo arguments |
| Generate local docs | `cargo doc --no-deps` | `--open` opens a browser when appropriate |
| Dependency graph | `cargo tree` / `cargo tree -d` | Inspect duplicate versions before changing dependencies |
| Feature provenance | `cargo tree -e features` | Explain why a dependency feature is enabled |
| Lockfile consistency | Add `--locked` to supported Cargo commands | Reject required lockfile updates; does not mean offline |
| Formatting | `cargo fmt --all -- --check` | Non-mutating workspace format check |
| Lints | `cargo clippy --workspace --all-targets -- -D warnings` | Requires Clippy; use supported features/targets, not blind all-features |
| Compiler explanation | `rustc --explain E0502` | Read both the initial borrow and its later-use diagnostic |

`cargo check` avoids final code generation for checked targets, but can still
compile/run build scripts and proc macros. A check is not a safe way to execute
an untrusted dependency tree. `--all-targets` means package target kinds
(libraries/binaries/examples/tests/benches), not every cross-compilation platform.
`--target` selects a platform; cross-linker and native-library requirements remain.

Testing commands, feature/MSRV test matrices, coverage and CI recipes live in
optional **rust-tdd**. Do not replicate a testing pipeline in this skill.

## Dependencies and lockfiles

Modern Cargo includes `cargo add` and `cargo remove`; installing `cargo-edit` is
not required for those commands on the Rust 2024 toolchain baseline. `cargo upgrade`
and tools such as `cargo audit` are separate tools, not universal built-ins.
Add a dependency only for required functionality, using existing project versions
and feature conventions. Do not preinstall an async runtime, serialization,
logging, or error crate into every new project.

`cargo update` resolves allowed newer dependency versions and can change many
entries. It is not routine cleanup during unrelated implementation. Keep the
project's lockfile policy and inspect intended dependency changes. `--locked`
checks reproducible resolution against the lockfile; `--offline` forbids network
access but needs cached data and may affect resolution. `--frozen` combines both.
A vulnerability audit reports known advisories; it is not proof of absence of bugs.
Treat automated dependency fixes as changes requiring review, not a harmless lint.

## Workspaces without accidental inheritance

A package can contain several crates (library, binaries and other targets); a
workspace contains packages sharing a lockfile and target directory. In a virtual
workspace, set the resolver explicitly because there is no root package edition
from which to infer it. Resolver `3` fits an edition-2024 / Rust-1.85+ baseline;
retain an older resolver when the project's supported toolchain requires it.

The following is a **two-manifest configuration example**, not a complete project
creation script. It assumes `crates/domain` already has its source files. The MSRV
is illustrative and must be replaced with the project's documented choice.

Workspace-root `Cargo.toml`:

```toml
[workspace]
members = ["crates/domain"]
resolver = "3"

[workspace.package]
edition = "2024"
rust-version = "1.85"
```

Member `crates/domain/Cargo.toml`:

```toml
[package]
name = "domain"
version = "0.1.0"
edition.workspace = true
rust-version.workspace = true
```

`[workspace.dependencies]` centralizes version requirements but members must opt
in with `dependency.workspace = true`; it does not add a dependency to every
member. Likewise package metadata and lint inheritance are opt-in. Feature
unification can enable more than a single member's local declaration, so inspect
the actual resolved graph. Check the relevant Cargo version before relying on
workspace `default-features` overrides.

Only workspace-root profile sections apply. `cargo check` from a member and from
the root may select different packages; use `-p name` or `--workspace` for explicit
scope and inspect `default-members`. Workspaces are useful for related packages,
not a requirement for every small binary. Release LTO/codegen tuning belongs to
optional **rust-performance**, not a default starter template.

## When changing build scripts

`build.rs` runs on the host: read `TARGET` / `CARGO_CFG_*` for target decisions;
`cfg!` describes the host. Write generated artifacts to `OUT_DIR` and account for
retained outputs. Declare relevant file/environment inputs with `rerun-if-changed`
and `rerun-if-env-changed`; verify a clean build and an incremental rebuild after
changing an input. With no rerun directives, Cargo watches package changes, not
every invocation. Declare custom cfg names and allowed values with
`rustc-check-cfg` even when inactive; `rustc-cfg` enables a cfg, not its declaration.
Use syntax supported by the project's Cargo/MSRV. See [Cargo build scripts](https://doc.rust-lang.org/cargo/reference/build-scripts.html).

## Formatting, linting and editor setup

- Follow existing rustfmt configuration. Start with stable options; upstream
  examples of `imports_granularity`, `group_imports`, or code-in-doc-comment
  formatting may require nightly. Check option stability for the pinned toolchain
  instead of adding a nightly toolchain just for aesthetic preferences.
- Keep Clippy's MSRV aligned with `package.rust-version` (or the inherited value).
  Do not hard-code an unrelated newer version in `clippy.toml`.
- Treat lint suggestions as proposals: a clone can be necessary for independent
  ownership; `unwrap` to `expect` changes diagnostics, not panic policy. Reject
  suggestions that change error or overflow semantics. Prefer a narrowly scoped,
  explained allowance over muting an entire category. Do not enable all of
  `clippy::restriction` indiscriminately.
- When the lint is intentionally present in the checked configurations, prefer
  a scoped `#[expect(lint, reason = "...")]` on supported toolchains (Rust 1.81+).
  An obsolete exception then warns; retain an explained `allow` when the lint's
  presence legitimately varies. See [lint expectations](https://doc.rust-lang.org/reference/attributes/diagnostics.html#the-expect-attribute).
- `cargo clippy --fix` and `cargo fmt` mutate source; use only when authorized and
  review resulting changes. `-D warnings` is a project gate, not universal policy;
  compiler updates can add warnings, so keep toolchain drift intentional.
- Configure rust-analyzer for the project's toolchain, features and target. Use
  navigation, rename, borrow/type hints and macro expansion before broad edits.
  The current setting for the check command is `rust-analyzer.check.command`;
  consult the installed extension's schema rather than copying stale
  `rust-analyzer.checkOnSave.command` examples. Do not enable `cargo.features =
  "all"` for a project with mutually exclusive features.
- Clippy, rustfmt, a debugger and rust-analyzer may require separate installation.
  `rustup component add clippy rustfmt` applies only to a rustup-managed toolchain;
  otherwise use the project's package manager/provisioning policy. Report missing
  tools accurately instead of claiming their checks passed.

## Debug the actual executable

1. Identify input, working directory, arguments, environment, target, features and
   build profile that trigger the bug. Keep user-reported failures as evidence.
2. Read the first relevant error and source chain. For Rust panics,
   `RUST_BACKTRACE=1 cargo run -- ...` can expose call frames; this does not add
   backtraces to every arbitrary error type.
3. `dbg!` writes file/line/value to stderr and returns its argument. It can move
   non-`Copy` input; use `dbg!(&value)` when retaining ownership. Never log secrets.
4. Use a symbol-bearing development build and GDB/LLDB (Rust wrappers when
   installed) or a configured editor debugger. Select the actual binary/package
   rather than assuming `target/debug/<name>` when target-dir/target is customized.
   Inspect live values and control flow; optimized frames/variables may be missing.
5. For macro expansion hand off to optional **rust-macros**; `cargo expand` is an
   external tool. For runtime cost hand off to **rust-performance** and profile the
   representative optimized executable, not a debug build by accident.
6. Remove temporary debug prints and instrumentation introduced for investigation;
   keep meaningful diagnostics consistent with the project's logging approach.

## Edition migration is an explicit task

Do not run migration on unrelated dirty/staged work. Start from a known recoverable
state, run `cargo fix --edition` under the migration guide, inspect the edits, then
update edition and supported MSRV as intended and verify the supported package /
feature / target combinations. Do not use `--allow-dirty --allow-staged` as a
supposed read-only preview: `cargo fix` changes files.

Review newly unsafe environment functions and changed lifetime/match behavior;
automatic edits can establish syntactic compatibility but cannot prove safety.
Never append an unexplained unsafe block just because migration suggested it.

## Sources

General workflow adapted from upstream 07; pinned source in the
[source map](../README.md#sources-and-adaptation).
- [Cargo workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html)
- [Cargo commands](https://doc.rust-lang.org/cargo/commands/)
- [Cargo rust-version](https://doc.rust-lang.org/cargo/reference/rust-version.html)
- [Edition migration](https://doc.rust-lang.org/edition-guide/editions/transitioning-an-existing-project-to-a-new-edition.html)
- [Rustfmt configuration](https://rust-lang.github.io/rustfmt/)
- [Clippy configuration](https://doc.rust-lang.org/clippy/configuration.html)
- [rust-analyzer configuration](https://rust-analyzer.github.io/book/configuration.html)
