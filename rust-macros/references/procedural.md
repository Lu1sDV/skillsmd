# Procedural macros: parse, validate, generate

## Choose the transformation

| Kind | Entry point | Input/output contract |
|---|---|---|
| Derive | `#[proc_macro_derive(Name, attributes(helper))]` | One struct/enum/union; output appends items, usually impls. Do not re-emit the type. |
| Attribute | `#[proc_macro_attribute]` | Attribute arguments plus the annotated item including other attributes; output replaces that item. |
| Function-like | `#[proc_macro]` | Tokens inside `name!(...)`; output replaces invocation in its syntactic position. |

Entry points are public crate-root functions in a crate with `[lib]
proc-macro = true`, using compiler-provided `proc_macro::TokenStream`. A macro
cannot be invoked within the same crate that defines it; integration tests are
separate crates and can invoke it. Runtime traits/helpers belong in a normal
library, not exported ordinary items in the proc-macro crate.

Use `syn` for parsing, `quote` for tokens, and `proc_macro2` for internal token
processing that can be tested outside compiler macro execution. Neither token
strings nor `syn` provide inferred type information. Do not parse Rust by
splitting `TokenStream::to_string()` or check types by spelling alone.

## Complete external-dependency recipe

The following is a **multi-file Cargo recipe**, not standalone rustdoc snippets.
The `text` fences contain full Rust source requiring the named crates. Create
these files in a separate experiment, not the skills installation. It implements
all three entry-point kinds without a new runtime dependency. The derive emits
an inherent associated constant rather than assuming a caller's trait import.

`macro_lab/Cargo.toml`:

```toml
[package]
name = "macro_lab"
version = "0.1.0"
edition = "2024"
rust-version = "1.85"

[lib]
proc-macro = true

[dependencies]
syn = { version = "2", features = ["full"] }
quote = "1"
proc-macro2 = "1"
```

Here `full` is needed for `ItemFn`; a derive-only crate should request only the
features it actually needs. Resolve versions compatible with the project's
MSRV and retain the consumer's dependency policy/lockfile.

`macro_lab/src/lib.rs`:

```text
use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, Data, DeriveInput, ItemFn, LitStr};

#[proc_macro_derive(FieldCount)]
pub fn field_count(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    expand_field_count(input)
        .unwrap_or_else(syn::Error::into_compile_error)
        .into()
}

fn expand_field_count(input: DeriveInput) -> syn::Result<proc_macro2::TokenStream> {
    let count = match &input.data {
        Data::Struct(data) => data.fields.len(),
        _ => return Err(syn::Error::new_spanned(
            &input.ident, "FieldCount supports structs only",
        )),
    };
    let name = &input.ident;
    let (impl_generics, type_generics, where_clause) = input.generics.split_for_impl();
    Ok(quote! {
        impl #impl_generics #name #type_generics #where_clause {
            pub const FIELD_COUNT: ::core::primitive::usize = #count;
        }
    })
}

#[proc_macro_attribute]
pub fn checked_result(args: TokenStream, item: TokenStream) -> TokenStream {
    if !args.is_empty() {
        return syn::Error::new_spanned(
            proc_macro2::TokenStream::from(args),
            "checked_result takes no arguments",
        ).into_compile_error().into();
    }
    let mut function = parse_macro_input!(item as ItemFn);
    function.attrs.push(syn::parse_quote!(
        #[must_use = "use the result of this function"]
    ));
    quote!(#function).into()
}

#[proc_macro]
pub fn uppercase(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as LitStr);
    let result = LitStr::new(&input.value().to_uppercase(), input.span());
    quote!(#result).into()
}
```

`consumer/Cargo.toml` (a sibling directory of `macro_lab`):

```toml
[package]
name = "macro_consumer"
version = "0.1.0"
edition = "2024"
rust-version = "1.85"

[dependencies]
macro_lab = { path = "../macro_lab" }
```

`consumer/src/main.rs`:

```text
use macro_lab::{checked_result, uppercase, FieldCount};

#[derive(FieldCount)]
struct Packet<'a, T, const N: usize>
where
    T: 'a,
{
    label: &'a str,
    values: [T; N],
}

#[derive(FieldCount)]
struct Empty;

#[checked_result]
fn next(value: u8) -> u8 { value + 1 }

fn main() {
    // A caller may shadow even primitive type names.
    #[allow(non_camel_case_types)]
    #[derive(FieldCount)]
    struct usize;
    assert_eq!(usize::FIELD_COUNT, 0);

    let packet = Packet { label: "data", values: [7u8; 2] };
    assert_eq!(Packet::<'static, u8, 2>::FIELD_COUNT, 2);
    assert_eq!(Empty::FIELD_COUNT, 0);
    assert_eq!((packet.label, packet.values), ("data", [7, 7]));
    assert_eq!(next(3), 4);
    assert_eq!(uppercase!("straße"), "STRASSE");
}
```

Run from the directory containing both folders: `cargo run --manifest-path
consumer/Cargo.toml`. This recipe is deliberately narrow: `FieldCount` rejects
enums/unions and reserves `FIELD_COUNT`; `checked_result` accepts a function and
adds a lint attribute, not runtime validation; `uppercase` accepts exactly one
string literal, not a variable or arbitrary expression. These restrictions are
part of the API, not silent fallback behavior.

## Generics, bounds, and names

Preserve lifetime, type, and const parameters, defaults where appropriate, and
existing where clauses. `split_for_impl()` produces the different declaration
and type-use forms needed by an impl; emitting `impl Trait for #name` alone
breaks generic callers. Add bounds through `make_where_clause()` **before**
splitting generics. Add only obligations generated operations require: cloning
`Arc<T>` does not require `T: Clone`, whereas cloning a field of type `T` does.
For complicated field types consider bounds on each relevant field type, not
blanket bounds on every generic parameter. Recursive fields need care to avoid
self-referential bounds that prevent trait resolution.

Use `quote!` interpolation `#value`, repetitions `#(#items),*`, and actual
`Ident` tokens for field/method names. Interpolating `"field"` emits a string
literal, not an identifier. Preserve raw identifiers and reject malformed
constructed names instead of panicking while building them.

Proc macros are not `$crate`-hygienic. Use `::core` paths where possible.
Generated primitive types also need qualified paths such as
`::core::primitive::usize`: a caller can legally define its own `struct usize`.
Runtime crate paths must handle dependency renaming. A documented helper attribute
accepting a parsed `syn::Path` is an explicit option; an existing crate-resolution
utility can automate lookup if the project already chooses that dependency.
Test normal, renamed, and in-runtime-crate use. Generated private names can still
collide: prefer small scopes, avoid unnecessary items, and document names that
are intentionally part of the public API.

## Diagnostics and attributes

- Parse the exact promised syntax using `parse_macro_input!`, `syn::Parse`, or
  a specific parser. Validate trailing tokens and all helper options.
- Register derive helpers with `attributes(...)`; parse their contents, reject
  unknown/duplicate/incompatible options, and use their spans in errors.
  Registration alone does not implement any option.
- Return `syn::Result<proc_macro2::TokenStream>` from an internal expansion
  function. Convert failures with `into_compile_error()`. Use `new_spanned`
  for validation and `combine` for independent errors worth reporting together.
- Preserve interpolated token spans; use `quote_spanned!` when generated trait
  obligations should highlight a particular field. Do not replace every span
  with `call_site` and lose the offending input location.
- Preserve the parsed item's attributes and signature when transforming it.
  The recipe edits `ItemFn` instead of rebuilding just visibility/signature/body.
- A logging wrapper of the form “body; log completion” misses early `return`,
  `?`, panic and cancellation. Closures alter control flow, and guards introduce
  drop semantics. Define entry/success/exit behavior before selecting a strategy;
  test async functions on poll, completion, and cancellation, not just creation.
  Reject unsupported const/ABI/unsafe/async forms rather than accidentally
  changing their contract.
- Treat procedural dependencies as executable build-time code with compiler
  file/environment access. Avoid hidden network/file inputs and nondeterministic
  output; keep builds reproducible and review dependencies like build scripts.

## Sources

- [Rust Reference: procedural macros](https://doc.rust-lang.org/reference/procedural-macros.html) — entry points, replacement rules, tokens, hygiene and security.
- [syn 2 Generics](https://docs.rs/syn/2.0.106/syn/struct.Generics.html), [syn 2 Error](https://docs.rs/syn/2.0.106/syn/struct.Error.html) — generation and diagnostics APIs used here.
- [core primitive paths](https://doc.rust-lang.org/core/primitive/index.html) — prevent caller-defined names from shadowing generated primitive types.
- [quote](https://docs.rs/quote/1/quote/) — interpolation and span-aware generation.
- [StructWeave chapter 14, pinned](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/14-macros.md) — adapted procedural macro coverage; examples rebuilt to preserve generics and attributes.
