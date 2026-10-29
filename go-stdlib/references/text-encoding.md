# Text and encoding

## Contents

- [Text, bytes and Unicode](#text-bytes-and-unicode)
- [Numeric conversion and regex](#numeric-conversion-and-regex)
- [JSON boundaries](#json-boundaries)
- [Other encodings](#other-encodings)

## Text, bytes and Unicode

| Need | API | Gotcha |
|---|---|---|
| Literal prefix/suffix | `HasPrefix`, `TrimPrefix`, `CutPrefix`, corresponding suffix APIs | `Trim(s, cutset)` removes any listed rune, not a substring |
| Split once | `strings.Cut` | Check `found`; empty before/after is valid |
| Split all fields | `Split`, `SplitN`, `Fields`, `FieldsFunc` | `Fields` collapses whitespace; `Split` preserves empty fields |
| Find a substring/rune | `Index`, `LastIndex`, `IndexRune`, `Contains` | Positions are byte offsets, even when searching by rune |
| Build a string | `strings.Builder` / `Join` | Do not copy a non-zero builder; `Reset` does not promise capacity reuse |
| Read/write binary buffer | `bytes.Buffer` | `Bytes` aliases storage and is valid only until the next modification |
| Reader over existing data | `strings.NewReader`, `bytes.NewReader` | Reader ownership does not make a caller's mutable bytes immutable |
| Stream string tokens | `Lines`, `SplitSeq`, `FieldsSeq` (Go 1.24+) | Single-use iterators; `Lines` retains terminating `\n` |

Strings are arbitrary immutable bytes, not necessarily valid UTF-8. Indexing and
`len` operate on bytes. Range decodes runes, returning byte indices; invalid UTF-8
produces U+FFFD with width one. Use `unicode/utf8.ValidString` when validity is a
boundary requirement. Rune count is not grapheme/display width. `unicode` classifies
and maps runes; it does not normalize canonically equivalent text. `strings.Title`
is deprecated; language-aware casing/normalization may need a reviewed dependency.
`EqualFold` is Unicode simple case folding, not locale-specific text equivalence.

Complete executable program (Go 1.24+):

```go
package main

import (
    "fmt"
    "strings"
)

func main() {
    for line := range strings.Lines("a\nb\nc") {
        fmt.Printf("%q\n", line)
    }
}
```

Output: `"a\n"`, `"b\n"`, `"c"`, on separate lines. Unlike Scanner's `ScanLines`,
`Lines` preserves newlines. See [executable examples](../examples/boundaries_test.go).
`bytes` exposes analogous search/split/trim APIs, but their returned subslices may
share mutable storage; clone only when ownership requires it.

Use `Builder.Grow` or `Buffer.Grow` when a justified size estimate is available.
For a few fixed pieces, `+` is clear. Repeated growing concatenation can repeatedly
copy prefixes; measure representative input rather than promising a fixed speedup.
Avoid converting large byte streams to strings just to convert them back.

## Numeric conversion and regex

- `Atoi` parses decimal into architecture-sized `int`; `ParseInt`/`ParseUint` let
  the schema choose base and bit size. Check errors, including range errors.
  A returned numeric value with a range error is not validated input.
- `ParseFloat` accepts `NaN`/infinities; reject with `math.IsNaN`/`IsInf` if the
  domain requires finite values. Decimal floating point is not exact money.
- `ParseBool` accepts a specific set including `1`/`0`, not arbitrary truthy text.
  `FormatInt`/`FormatFloat` and `Itoa` produce text; `string(65)` produces a rune's
  UTF-8 encoding, not decimal digits. `Quote`/`Unquote` use Go literal rules, not
  arbitrary JSON or shell quoting rules.
- `strconv.AppendInt`/`AppendFloat`/`AppendQuote` reuse a supplied byte slice **if**
  capacity suffices; they are not unconditionally allocation-free. Retain the
  returned slice, as with `append`.
- `regexp.Compile` reports dynamic pattern errors. Use `MustCompile` only for
  fixed programmer-owned patterns. Go regex uses RE2-style syntax and linear-time
  matching in input size for a fixed pattern; it has no backreferences/lookaround.
  This does not make unlimited patterns, input or match-result allocation free.
- `Find*Index` reports byte offsets; nil means no match. An empty match can be
  real. Anchor a whole-field policy deliberately. `ReplaceAllString` expands
  `$name`/`${name}` captures; `ReplaceAllLiteralString` does not.
- Regexes for email, IP and phone syntax are not full validators or proof of
  reachability. Use `net/netip.ParseAddr` for addresses; validation rules depend
  on the protocol/domain rather than a convenient demo expression.

## JSON boundaries

Choose typed structs for a known schema; use `json.RawMessage` to defer a payload
until its discriminator is validated. Exported fields and tags define mapping.
Check every `Marshal`, `Unmarshal`, `Encode` and `Decode` error. A decoding error
can leave the destination partially changed: decode into a fresh value and
publish only after success and domain validation.

| Choice | Meaning / caveat |
|---|---|
| `json:"name"` | Sets field name; matching is also case-insensitive in encoding/json v1 |
| `json:"-"` | Excludes a field, but does not redact copies logged elsewhere |
| `omitempty` | Omits false, numeric zero, nil pointers/interfaces, and zero-length strings/arrays/slices/maps; not every struct zero value |
| `omitzero` (Go 1.24+) | Omits the type's zero value or an `IsZero`-defined value |
| `,string` | Extra string encoding for supported scalar fields; not a general conversion hook |
| `Decoder.UseNumber()` | Decode numbers into `json.Number` in interface values; subsequent conversion still needs range checks |
| `DisallowUnknownFields()` | Rejects unknown struct fields, not duplicates, casing variants or all schema violations |

With `any`, JSON objects become `map[string]any`, arrays `[]any`, numbers `float64`,
and null nil. Unchecked assertions panic; numbers above float64's exact-integer
range lose precision. Prefer the target integer type or `UseNumber`.

`null` into a non-pointer scalar has no effect and no error. Use explicit presence
representation when missing/null/zero differ; a pointer distinguishes a value
from missing-or-null, but not missing from null by itself. Nil slices encode as
`null`, non-nil empty slices as `[]` (unless omitted). Decide that wire contract.

**One document:** bound bytes, call `Decode`, then call `Decode` again and require
`io.EOF`. The second call rejects both valid extra values and malformed trailing
bytes; whitespace is permitted. **Stream of top-level values:** repeatedly decode
until EOF and propagate other errors. **Array/object iteration:** use `Token`
and `More` inside the opened container, then consume its closing token. `More`
is not the contract for top-level stream termination.

[ReadSettings](../examples/boundaries.go) implements one bounded typed object,
rejects unknown fields, trailing data, top-level null and invalid domain values.
It deliberately retains encoding/json v1's duplicate-key/case-folding/Unicode
behavior: later duplicate keys may replace/merge earlier values and malformed
UTF-8/surrogates are replaced, not rejected. It is not a canonical or duplicate-free
security parser. If multiple parsers or signed documents must agree, choose an
explicit consistent parsing/canonicalization policy; do not infer it from
`DisallowUnknownFields`. No experimental JSON implementation is assumed here.

For custom `MarshalJSON`/`UnmarshalJSON`, preserve valid JSON, errors and pointer
mutation semantics; using an alias type avoids accidental recursive calls.
`Encoder.Encode` appends a newline. Response encoding can fail after output starts;
when an endpoint requires all-or-nothing response generation, marshal a bounded
result before writing status/headers.

## Other encodings

| Package | Appropriate use | Failure and ownership rules |
|---|---|---|
| `encoding/xml` | XML names, attributes, nesting, token streams | Struct mapping is not schema validation; namespace identity includes URI, not prefix spelling; limit untrusted input |
| `encoding/csv` | Quoted fields, commas/newlines in records | Do not split by comma manually; check `Read` errors, field counts, and `Writer.Error` after `Flush` |
| `encoding/base64` | Standard/URL alphabet, padded/raw variants | Match alphabet/padding to protocol; malformed data may return partial output and an error; encoding is not encryption |
| `encoding/gob` | Trusted Go-to-Go values | Exported fields, concrete-type registration for interfaces; not hardened against adversarial input or resource expansion |
| `encoding/hex` | Binary identifiers/digests | Validate decoding errors and expected byte length before use |

XML `XMLName`, `,attr`, `a>b` tags express names and nesting; decoder tokens allow
streaming. The stdlib parser is not a full XML application validator. CSV readers
can enforce `FieldsPerRecord`; `ReuseRecord` allows returned slices to be reused,
so clone retained records. `ReadAll` is convenient only for bounded input. CSV
quoting does not prevent spreadsheet-formula interpretation in exported cells;
choose a target-specific export policy if spreadsheets are the consumer.

Complete function fragment (import `encoding/csv` and `io`; it does not close `w`):

```go
func writeNames(w io.Writer, names []string) error {
    out := csv.NewWriter(w)
    for _, name := range names {
        if err := out.Write([]string{name}); err != nil {
            return err
        }
    }
    out.Flush()
    return out.Error()
}
```

The [runnable CSV example](../examples/boundaries_test.go) exercises a flush-time
destination failure. `base64.NewEncoder` also requires `Close()` to
flush a final partial block; closing that encoder does not close its destination.
A gob input byte cap alone is not proof of bounded allocation: decoding declared
sizes can consume disproportionate resources. Use a format and decoder suitable
for the actual trust boundary.

## Primary references

[strings](https://pkg.go.dev/strings), [bytes](https://pkg.go.dev/bytes),
[strconv](https://pkg.go.dev/strconv), [regexp](https://pkg.go.dev/regexp),
[unicode](https://pkg.go.dev/unicode), [unicode/utf8](https://pkg.go.dev/unicode/utf8),
[encoding/json](https://pkg.go.dev/encoding/json),
[encoding/xml](https://pkg.go.dev/encoding/xml),
[encoding/csv](https://pkg.go.dev/encoding/csv),
[encoding/base64](https://pkg.go.dev/encoding/base64),
[encoding/gob](https://pkg.go.dev/encoding/gob).
