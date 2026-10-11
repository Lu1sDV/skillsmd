# Errors and ordinary idioms

## Choose the failure contract

| Situation | Representation / response |
|---|---|
| A legitimate missing value | `Option<T>` |
| Failed operation with useful cause | `Result<T, E>` |
| Invalid external input | Return validation/parse error; do not panic |
| Broken internal invariant | Fix root cause; `expect` only with a documented proof |
| Caller selects recovery by category | Concrete error enum implementing `Display` and `Error` |
| Application boundary prints a diagnostic | Preserve source chain and add operation context |

`?` on `Result` returns early on `Err`, using `From` conversion when needed; on
`Option` it returns `None`. It does not freely mix the two: use `ok_or_else` when
absence becomes an error, or an explicit match when an error is legitimately
optional. A closure using `?` needs its own compatible return type.

Manual `std::error::Error` implementations are enough for small error sets.
If already used by the project, `thiserror` can derive typed errors and `anyhow`
can add application context; neither is a mandatory dependency or a rigid
library/application law. Preserve concrete errors where callers act on them.
Implement `source()` for wrapped causes; flattening everything into `String`
loses the chain and structured inspection.

## Combinators without hidden policy

| Method | Semantics | Common mistake |
|---|---|---|
| `map` | Transform successful/present value | Using it only for side effects; use `if let` or a loop |
| `and_then` | Transform into another `Option`/`Result` | Using `map` and accidentally nesting containers |
| `as_ref`, `as_mut`, `as_deref` | Borrow the contents instead of consuming | Cloning just to keep the original |
| `unwrap_or`, `ok_or`, `or_insert` | Arguments evaluated eagerly | Constructing an unused expensive fallback |
| `unwrap_or_else`, `ok_or_else`, `or_insert_with` | Run fallback closure only when needed | Silently replacing genuine failures with a default |
| `transpose` | Swap `Option<Result<T,E>>` and `Result<Option<T>,E>` | Treating missing and invalid as the same condition |
| `collect::<Result<Vec<_>, _>>()` | Stop at first failure | Assuming it rolls back earlier side effects |
| `Result::ok`, `filter_map(Result::ok)`, `flatten` over results | Discard error cases | Losing file/read/parse failures without an explicit contract |

Use plain `match` when several cases need different policy. A longer combinator
chain is not automatically more idiomatic. Short-circuiting stops future work,
but already-performed writes, logging, mutations, or network requests remain.

## Complete parsing example: distinguish absence, shape, and value

This parser accepts exactly two comma-separated signed integers, with surrounding
whitespace permitted for each integer. It rejects missing/extra fields and retains
the underlying integer error. `split_once` avoids a temporary vector and unchecked
indexing. `Display` formats directly into the formatter rather than building a
second formatted string.

```rust
use std::{error::Error, fmt, num::ParseIntError, str::FromStr};

#[derive(Debug, PartialEq, Eq)]
struct Point { x: i32, y: i32 }

#[derive(Debug)]
enum PointError {
    Shape,
    Coordinate { axis: &'static str, source: ParseIntError },
}
impl fmt::Display for PointError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Shape => write!(f, "expected exactly two comma-separated coordinates"),
            Self::Coordinate { axis, source } => write!(f, "invalid {axis} coordinate: {source}"),
        }
    }
}
impl Error for PointError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::Shape => None,
            Self::Coordinate { source, .. } => Some(source),
        }
    }
}
impl FromStr for Point {
    type Err = PointError;
    fn from_str(input: &str) -> Result<Self, Self::Err> {
        let (x, y) = input.split_once(',').ok_or(PointError::Shape)?;
        if y.contains(',') { return Err(PointError::Shape); }
        let x = x.trim().parse().map_err(|source| PointError::Coordinate { axis: "x", source })?;
        let y = y.trim().parse().map_err(|source| PointError::Coordinate { axis: "y", source })?;
        Ok(Self { x, y })
    }
}
fn optional_point(input: Option<&str>) -> Result<Option<Point>, PointError> {
    input.map(str::parse).transpose()
}

assert_eq!(" 1, -2 ".parse::<Point>().unwrap(), Point { x: 1, y: -2 });
assert_eq!(optional_point(None).unwrap(), None);
assert!(matches!("1".parse::<Point>(), Err(PointError::Shape)));
assert!(matches!("1,2,3".parse::<Point>(), Err(PointError::Shape)));
let error = "1,".parse::<Point>().unwrap_err();
assert!(matches!(&error, PointError::Coordinate { axis: "y", .. }));
assert!(error.source().is_some());
assert!("2147483648,0".parse::<Point>().is_err());
```

If parsing yields views into its input, use a borrowing function with an explicit
lifetime instead of `FromStr`, whose output cannot borrow from the input through
that trait signature. Do not trim by habit: this example's grammar explicitly
allows whitespace; fixed-width fields, passwords, and protocol payloads may not.

## Conversions and numeric boundaries

- `From<T>` / `Into<U>` express infallible conversion. Implement `From` to get the
  blanket `Into` implementation. Infallible does not mean allocation-free:
  `String::from(&str)` copies nonempty input into owned storage.
- `TryFrom` / `TryInto` express rejected values, such as `u8::try_from(256)`.
  Avoid `as` for untrusted integer narrowing. Integer-to-float conversion may lose
  precision; float-to-integer `as` truncates toward zero with saturation for
  out-of-range values and maps NaN to zero, not a parse error.
- `AsRef` / `AsMut` expose cheap borrowed views. Prefer a concrete borrow when
  there is no caller benefit from another generic parameter.
- `FromStr` parses a textual representation. Validate shape before indexing.
- `checked_add`/`checked_mul`/`checked_div` expose overflow as `Option`; choose
  wrapping/saturating behavior only if the domain specifies it. Debug and release
  default overflow settings differ and can be overridden. Constant overflow can
  be diagnosed at compile time, so a constant example is not a runtime experiment.
- Floating-point equality is exact equality of represented values, not a tolerance
  policy. Use `is_nan` to detect NaN; choose domain-specific absolute/relative
  tolerances for approximate comparisons. `f64::total_cmp` gives a total sort order
  but does not make NaN ordinary numerical equality. Floats do not implement `Ord`,
  so a plain iterator `.max()` on `f64` does not compile.

## Document behavior, not signatures

Use `///` for public items and `//!` for modules. Record input grammar, errors,
observable side effects, and real panic conditions. Never document ordinary
integer arithmetic as unconditionally non-panicking without proving its bounds.
Document examples with enough imports and setup to run independently. Debug output
is for diagnostics, not a stable serialization format; `Display` is human-facing
and should not accidentally expose secrets.

Runnable examples and assertions here illustrate contracts. For an actual feature
or bug, hand off to optional **rust-tdd** for an observed red-green-refactor loop,
regression selection and CI; assertions alone are not evidence of TDD.

## Sources

Adapted from upstream 01, 05, 13, and 17; pinned links in the
[source map](../README.md#sources-and-adaptation).
- [Result and the question-mark operator](https://doc.rust-lang.org/std/result/)
- [Option](https://doc.rust-lang.org/std/option/enum.Option.html)
- [Error source chains](https://doc.rust-lang.org/std/error/trait.Error.html)
- [Conversions](https://doc.rust-lang.org/std/convert/)
- [Numeric casts](https://doc.rust-lang.org/reference/expressions/operator-expr.html#numeric-cast)
- [f64 total ordering](https://doc.rust-lang.org/std/primitive.f64.html#method.total_cmp)
