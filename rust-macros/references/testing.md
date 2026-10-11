# Expansion, diagnostics, and compile-time traps

## Debug from the caller inward

1. Reduce to one invocation in the failing crate, preserving its edition,
   feature flags, dependency alias and module/import context.
2. Classify the error: matcher parse, expansion structure, name resolution,
   generated trait bounds, or actual runtime behavior. A parser rewrite will
   not fix a missing downstream public helper.
3. Read the first relevant diagnostic and expansion backtrace. Check which arm
   matched and whether the expression was evaluated repeatedly.
4. Inspect generated syntax with `cargo expand` if installed. Select the same
   package, target and features as the failing build. Expansion is lossy text:
   hygiene and spans can disappear, so recompiling the printout is not a proof.
5. Preserve a minimal passing caller and a targeted failing caller. Regression
   tests should exercise the contract, not just assert a pretty-printed string.

Optional expansion commands, from the actual Rust project:

```sh
cargo expand --lib
cargo expand --test macro_ui
```

`macro_ui` is the name of an existing integration-test target, not a magic
built-in target. Installation (`cargo install cargo-expand`) changes the local
tool environment; follow project policy and check its toolchain requirements.
Nightly-only aids include `trace_macros!`, `log_syntax!`, and
`cargo +nightly rustc --lib -- -Zmacro-backtrace`; do not place their feature gates
in ordinary stable builds. The `+nightly` selector requires a rustup-managed
installed nightly, which may be absent.

## Minimum test matrix

| Contract | Passing coverage | Failing coverage |
|---|---|---|
| Grammar | Empty if supported; singleton; many; trailing separator | Missing required token, duplicate separator, unsupported form |
| Evaluation | Side-effect count/order, move-only values, borrowing | Invalid generated borrow only when part of the intended contract |
| Hygiene | Shadowed local/helper/type names; module nesting | Private downstream helper where public reachability is required |
| Export | Separate crate using `use` and path invocation; Cargo dependency alias | Accidental reliance on imports in the definition's module |
| Derive | Named/tuple/unit structs, lifetimes, const/type generics, where clause | Unsupported enum/union; malformed/unknown helper attribute |
| Attribute | Existing attributes, visibility, signature, return behavior | Rejected arguments or unsupported function forms |
| Editions | Definition crate and supported consumer editions | Old matcher assumptions that changed in 2021/2024 |

For the procedural recipe, assert zero fields and generic two-field structs;
check the `FieldCount supports structs only` diagnostic on an enum, unexpected
`checked_result` arguments, and `uppercase!(123)` parsing. To test its lint
behavior, compile a caller with `#![deny(unused_must_use)]` that discards a
`#[checked_result]` function's non-unit result. Confirm that the rejection is for
the intended diagnostic, not an unrelated import or dependency failure.

Use standard integration tests for runtime behavior. Unit-test parsers and
internal `proc_macro2` expansion helpers when useful. Parsing emitted tokens
back into `syn` catches malformed syntax, not name resolution/type errors.
Token-string snapshots are optional aids, not substitutes for compiling callers.

For small self-contained rejection examples, Rustdoc `compile_fail` is enough.
It establishes failure, not exact diagnostic text. For an established macro
library needing stable diagnostic placement, consider [trybuild](https://docs.rs/trybuild/1/trybuild/)
as an explicit dev dependency: `TestCases::pass` compiles/runs valid callers,
`compile_fail` compares failing callers to adjacent `.stderr` files. Generate
snapshots, inspect the highlighted tokens/reason, then accept them. Never blindly
bless `TRYBUILD=overwrite`; compiler changes can alter diagnostics legitimately.
Do not add a framework just to run these dependency-free Markdown examples.

## Standard macros are not interchangeable

| Macro family | Correct use and common trap |
|---|---|
| `vec![a, b]` / `vec![value; n]` | List evaluates its elements; repetition evaluates `value` once and clones it as needed. Repeating an `Rc` shares one allocation rather than creating independent objects. |
| `println!`, `format!` | Format string grammar is checked at compile time, but argument evaluation and formatting execute at runtime. `format!` creates a `String`. |
| `write!`, `writeln!` | Bring the intended `fmt::Write` or `io::Write` trait into scope and handle its result; both are not interchangeable imports with the same name. |
| `assert!` / `debug_assert!` | `debug_assert!` execution follows `debug_assertions`, not a universal “release strips it” rule. Its expansion is still type checked. Never put required side effects or safety validation there. |
| `cfg!` / `#[cfg]` | `cfg!` expands to a boolean; both branches must remain valid. Use the attribute to remove unavailable platform APIs before type checking. |
| `concat!` / `stringify!` | Literal concatenation / syntax stringification, not runtime formatting or a stable token serialization format. |
| `env!` / `option_env!` | Build-time environment, required / optional. Not runtime configuration; avoid embedding secrets. |
| `include_str!`, `include_bytes!` | Build-time contents, paths relative to the containing source file. Bundled input must exist on the build machine. |
| `file!`, `line!`, `column!` | Source-location diagnostics; avoid treating them as durable identifiers. |
| `panic!`, `unreachable!` | Runtime panic, not an optimizer promise like `unreachable_unchecked`; `todo!` and `unimplemented!` are also panics, not completed behavior. |

This compile failure demonstrates why `cfg!` does not protect invalid code:

```rust,compile_fail
if cfg!(any()) {
    missing_platform_function();
}
```

This succeeds because an empty `any()` is false and the attribute removes the
statement before resolving its nonexistent function:

```rust
#[cfg(any())]
missing_platform_function();
assert!(!cfg!(any()));
```

## Macro expansion versus const evaluation

A macro can emit a const expression, but macro expansion does not evaluate an
arbitrary Rust expression. Conversely a `const fn` can run at runtime unless
called in a const context. For ordinary compile-time arithmetic prefer a const
function/item rather than a token DSL. Supported operations depend on MSRV;
loops and a literal-message const assertion work on the 2024 baseline. Do not
repeat outdated claims that all const panics are forbidden, or that merely
accepting a trait-object reference is forbidden in a const function.

```rust
const fn triangular(n: u32) -> u32 {
    let mut sum = 0;
    let mut i = 0;
    while i < n {
        i += 1;
        sum += i;
    }
    sum
}
const TOTAL: u32 = triangular(4);
const _: () = assert!(TOTAL == 10, "unexpected triangular value");
assert_eq!(TOTAL, 10);
assert_eq!(triangular(0), 0);
```

An assertion in a const initializer is checked during compilation. This fails
intentionally rather than waiting until a program runs:

```rust,compile_fail
const _: () = assert!(2 + 2 == 5, "invalid invariant");
```

Large inputs to the arithmetic example can overflow `u32`; that is a compiler
error when evaluated in a const context, not a promise that arbitrary input is
valid. General arithmetic/API policy belongs in the optional rust-idiomatic or
rust-algorithms skill.

## Sources

- [cargo-expand documentation](https://github.com/dtolnay/cargo-expand) — commands and lossy-output warning.
- [trybuild documentation](https://docs.rs/trybuild/1/trybuild/) — pass/fail callers, snapshots and review workflow.
- [Rust `cfg!`](https://doc.rust-lang.org/std/macro.cfg.html), [Rust `debug_assert!`](https://doc.rust-lang.org/std/macro.debug_assert.html) — compile-time removal versus boolean selection, assertion configuration.
- [Rust Reference: const evaluation](https://doc.rust-lang.org/reference/const_eval.html) — compile-time contexts and restrictions.
- [StructWeave chapter 14](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/14-macros.md) and [chapter 13](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/13-interview-trap-questions.md), pinned — adapted debugging, standard macro and const traps.
