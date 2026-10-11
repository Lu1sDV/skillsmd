# Declarative macros: grammar, hygiene, editions

## Pick the fragment that expresses the grammar

| Fragment | Input and important boundary |
|---|---|
| `expr` | Parsed expression, not arbitrary tokens; 2024 includes top-level `_` and `const { ... }` |
| `expr_2021` | Expression excluding those two top-level forms, for compatibility |
| `pat` | Pattern; definition edition 2021+ includes top-level or-patterns |
| `pat_param` | Pattern without top-level alternatives; useful before a literal `|` |
| `ident`, `lifetime` | Identifier (including keywords/raw identifiers as applicable), lifetime token |
| `ty`, `path` | Type or type-style path; not an evaluated value |
| `item`, `block` | Whole item or brace-delimited block |
| `stmt` | Statement without trailing semicolon, except item statements requiring one |
| `literal` | Literal, optionally preceded by `-`; not an arbitrary const expression |
| `meta` | Attribute contents, such as `cfg(unix)` |
| `vis` | Possibly empty visibility; do not assume it consumes a token |
| `tt` | One token tree: a token or one balanced delimited group |

Use `$($tokens:tt)*` to forward an arbitrary sequence. A single `$token:tt`
does not capture an undelimited multi-token expression. Prefer typed fragments
when they give callers earlier, more precise parse errors.

Rules are tried in order, with no retry after a matched rule's expansion fails.
The matcher does not look ahead to resolve local ambiguity. For example,
`$($prefix:ident)* $last:ident` cannot decide whether one identifier belongs to
`prefix` or `last`; separate them with a delimiter/tag instead.

Fragment followers are restricted even if a custom grammar looks unambiguous:
`expr`/`stmt` allow `=>`, `,`, `;`; `pat` allows `=>`, `,`, `=`, `if`, `in`;
`pat_param` additionally allows `|`. Use delimiters rather than trying to put an
arbitrary token after a fragment. See the complete [follow-set rules](https://doc.rust-lang.org/reference/macros-by-example.html#follow-set-ambiguity-restrictions)
for `ty`, `path`, `vis`, and interactions with optional repetitions.

## Repetition and forwarding

`*` means zero or more, `+` one or more, `?` zero or one. A separator may precede
`*`/`+`, but not `?`. `$(,)?` accepts one optional trailing comma. Combining
`$($x:expr),* $(,)?` also accepts a lone comma; use a distinct empty arm and a
non-empty `+` arm if that input should be rejected.

Transcribe a captured variable with the same repetition nesting and kind that
captured it. Repetition needs a captured variable to determine its length.
Variables zipped in one output repetition must have equal lengths; nested rows
may have different lengths unless the generated type or validation prohibits it.

This nested grammar permits ragged rows and returns nested arrays, so the caller
must choose rows of equal length for a single homogeneous outer array:

```rust
macro_rules! rows {
    ($( [ $($x:expr),* $(,)? ] ),+ $(,)?) => {
        [$( [ $($x),* ] ),+]
    };
}
assert_eq!(rows!([1, 2], [3, 4],), [[1, 2], [3, 4]]);
let empty_rows: [[u8; 0]; 2] = rows!([], []);
assert_eq!(empty_rows.len(), 2);
```

Captured `expr`, `ty`, and most other fragments become opaque syntax when
forwarded to another macro. `ident`, `lifetime`, and `tt` are exceptions that can
still be matched as literal tokens. Intentional failure: the inner macro cannot
recognize the literal `3` inside an opaque expression fragment.

```rust,compile_fail
macro_rules! literal_three { (3) => { 3 }; }
macro_rules! forward { ($x:expr) => { literal_three!($x) }; }
let _ = forward!(3);
```

Use `tt` forwarding only when the downstream grammar needs token inspection:

```rust
macro_rules! literal_three { (3) => { 3 }; }
macro_rules! forward { ($x:tt) => { literal_three!($x) }; }
assert_eq!(forward!(3), 3);
macro_rules! twice { ($x:expr) => { $x * 2 }; }
assert_eq!(twice!(5 + 3), 16); // expr grouping is preserved, unlike C text macros.
```

## Hygiene and exported paths

`macro_rules!` uses **mixed-site hygiene**: local variables and labels resolve
at the definition site; other names generally resolve at the invocation site.
An introduced local does not become accessible merely because its spelling
matches a caller's name. Accept a caller-provided identifier to introduce a
binding intentionally, or return a value instead.

```rust
macro_rules! bind {
    ($name:ident = $value:expr) => { let $name = $value; };
}
let x = 9;
macro_rules! definition_x { () => { x }; }
let x = 10;
bind!(answer = definition_x!() + x);
assert_eq!(answer, 19);
```

This intentionally fails: the caller did not supply the binding identifier.

```rust,compile_fail
macro_rules! hidden_local { () => { let generated = 42; }; }
hidden_local!();
assert_eq!(generated, 42);
```

- Unqualified names search textual macro scope before path-based scope. A local
  `macro_rules!` definition normally becomes available after its definition.
- `#[macro_export]` makes the macro public at the **crate root**, even when its
  source is nested in a module. Prefer modern path imports (`use library::name`)
  over broad legacy `#[macro_use]` imports.
- `$crate::support::helper(...)` names the **defining** crate, including when a
  consumer renames its dependency. Plain `crate::...` in expansion refers to the
  caller's crate. Use `$crate::other_macro!` for exported helper macros too.
- `$crate` does not bypass privacy. Helpers reached downstream must be public
  through a public path. `#[doc(hidden)]` hides documentation, not API exposure
  or compatibility obligations. Avoid helpers when inline simple code suffices.
- Use `::core::...` for core types/traits. `::std::...` requires a std consumer;
  an alloc-based macro needs an explicit alloc path/re-export strategy.
- `local_inner_macros` is a migration mechanism, not the default for new code.

A complete defining-crate example (also test from another crate before release):

```rust
pub mod support {
    pub fn increment(value: u32) -> u32 { value + 1 }
}
mod macros {
    #[macro_export]
    macro_rules! increment {
        ($value:expr) => { $crate::support::increment($value) };
    }
}
fn main() {
    assert_eq!(increment!(4), 5);
}
```

## Definition-edition changes

2021 changed `pat` to accept top-level `A | B`. A grammar that supplies its own
`|` separators should use `pat_param`, or accept a complete or-pattern with
`pat`. 2024 changed `expr` to include top-level const blocks and `_`. That can
change **which arm wins**, even when all old invocations still parse.

```rust
macro_rules! edition_sensitive {
    ($value:expr) => { "expression" };
    (const $value:expr) => { "tagged const" };
}
macro_rules! preserved {
    ($value:expr_2021) => { "expression" };
    (const $value:expr) => { "tagged const" };
}
assert_eq!(edition_sensitive!(const { 2 }), "expression");
assert_eq!(preserved!(const { 2 }), "tagged const");
macro_rules! any_pattern {
    ($value:expr, $($pattern:pat_param)|+) => {
        matches!($value, $($pattern)|+)
    };
}
assert!(any_pattern!(Some(3), None | Some(3)));
assert!(!any_pattern!(Some(4), None | Some(3)));
```

These assertions specifically target a **2024 macro definition**. Test supported
consumer editions using separate crates; changing the caller's edition alone
does not change a dependency's matchers. During migration review Cargo's edition
fixes, including `edition_2024_expr_fragment_specifier`, rather than blindly
keeping every `expr` or blindly replacing all with `expr_2021`.

## Patterns worth keeping small

For a builder generator, accept both builder and result type names instead of
emitting a globally fixed `Built`; explicitly decide missing-field errors,
defaults, visibility and duplicate setter behavior. For enum delegation,
generate the repetitive match but keep the trait contract ordinary Rust. For a
DSL, define delimiters and escaping rules first. `concat!` cannot combine runtime
`String`s produced by `format!`, and an HTML DSL must escape untrusted content.
Do not turn a miniature syntax example into a production templating system.

Recursive token-tree munchers need a terminating rule and input progress. Large
inputs may incur costly repeated parsing; prefer direct repetition. Raising
`recursion_limit` is only reasonable after proving termination and checking the
expected input size, not as a fix for accidental infinite recursion.

## Sources

- [Rust Reference: macros by example](https://doc.rust-lang.org/reference/macros-by-example.html) — matching, fragments, repetition, hygiene, export and editions.
- [StructWeave chapter 14, pinned](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/14-macros.md) — adapted macro patterns and interview prompts.
- [StructWeave chapter 13, pinned](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/13-interview-trap-questions.md) — hygiene trap, corrected to mixed-site resolution.
