# Documentation and verification

## Public contract

Give the crate an overview and useful runnable examples; link shared examples
instead of duplicating them. Prefer `?` in fallible examples. Document applicable
`# Errors`, `# Panics`, and `# Safety` obligations, including trait methods.
Describe meaningful allocation, capacity, blocking, and mutation-on-error promises.
Hide irrelevant implementation details. Provide useful, nonempty `Debug` output
without exposing secrets.

Maintain package metadata, licensing information, and significant release notes.
Review public dependency stability and license compatibility against project policy;
do not turn the upstream preference for permissive licensing into a blanket rule.

## Checks

Use the repository's CI matrix first. Typical default-feature checks:

```sh
cargo fmt --all -- --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
cargo test --workspace --release
cargo test --workspace --doc
cargo doc --workspace --no-deps
```

Exercise supported targets and feature combinations separately, including promised
no-default-features builds. Do not blindly use `--all-features`; add `--locked`
when the repository maintains the needed lockfile. Include boundary/error tests;
use property, fuzz, differential, or concurrency checks when the risk warrants them.
An optimized assertion-enabled lane complements, not replaces, normal release tests.

For a release, inspect `cargo package --list` and run `cargo package` with
verification enabled for the intended package. Check required sources/assets and
registry-resolvable non-dev dependency versions: the normalized manifest and
extracted archive must build independently of the checkout. Workspace tests alone do not
establish this. See [Cargo packaging](https://doc.rust-lang.org/cargo/commands/cargo-package.html).

## Lint scope

Tune lints to the MSRV and project; keep exceptions narrow and explained.
Workspace lints require member opt-in through `[lints] workspace = true`.

Do not combine inherited `unsafe_code = "forbid"` with a test requiring an unsafe
allocator. One compatible policy is workspace `deny`, production `lib.rs` `forbid`,
and a narrow `allow` in the separate integration-test crate. `allow` cannot override
`forbid`; unit tests inside the library still inherit its restriction. No allocator
implementation is supplied by this skill.

Basis: API Guidelines [documentation](https://rust-lang.github.io/api-guidelines/documentation.html),
[debuggability](https://rust-lang.github.io/api-guidelines/debuggability.html), and
[necessities](https://rust-lang.github.io/api-guidelines/necessities.html);
[gist](https://gist.github.com/auser/c3161f55a8393faa8af5ddda68c6befa) §§12–14, with
corrected lint scoping and configuration-dependent verification.
