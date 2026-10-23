# Serialization and text boundaries

## Contents

- [Format selection and validation](#choose-a-format-then-validate-the-contract)
- [JSON defaults](#json-defaults-are-permissive-in-specific-ways)
- [CSV and TOML](#csv-and-toml)
- [Pickle trust](#pickle-is-a-trust-decision)
- [Regex and ordinary text](#regex-and-ordinary-text)

## Choose a format, then validate the contract

| Format | API | Important limit |
|---|---|---|
| Interchange records | `json` | No schema, resource cap, duplicate rejection or finite-number policy by default |
| Tabular text | `csv` | Fields are strings by default; dialect/header/type validation is yours |
| Human configuration | `tomllib` (3.11+) | Reads TOML only; parsed data still needs validation |
| Python-specific trusted persistence | `pickle` | Loading can execute code; never accept an untrusted producer |

Define input size and nesting/expansion limits before parsing untrusted data. An
input that parses can still violate required fields, ranges, uniqueness, encoding,
precision or consumer expectations. Catch parser errors without replacing invalid
configuration with silent defaults.

## JSON: defaults are permissive in specific ways

- `dump` writes text to a stream; `dumps` returns a string. Repeated `dump` calls do
  not frame a sequence of JSON documents. Use a documented framing format such as
  one complete document per line when streaming independent records.
- Encoding defaults to `allow_nan=True`. Use `False` for interoperable output;
  it raises for NaN and infinities instead of emitting non-JSON tokens.
- Decoding accepts `NaN` and infinities by default; use `parse_constant` to reject
  those spellings. This does not prevent overflow of a legal numeric literal such
  as `1e999` to a float infinity; choose `parse_float=Decimal` or validate finite
  numbers/ranges according to the schema.
- Duplicate object keys keep the last value. Reject duplicates with an
  `object_pairs_hook` when ambiguity is unacceptable. `strict=True` alone only
  controls unescaped control characters inside strings.
- JSON object keys are strings. Integers used as Python dictionary keys do not
  round-trip as integers; tuples round-trip as lists. Large integers may lose
  precision in a different consumer runtime even if Python preserves them.
- `ensure_ascii=False` controls escaping, not the eventual file/transport encoding.
  Write with an explicit encoding. Decode only schema-designated date fields;
  do not guess that every string resembling a date should become a datetime.
- Use a deliberately selected output schema. Generic `obj.__dict__` and
  `dataclasses.asdict` can expose secrets and unintended state.

```pycon
>>> import json
>>> from decimal import Decimal
>>> def reject_constant(token: str):
...     raise ValueError(f"non-JSON number: {token}")
>>> json.loads('{"value": NaN}', parse_constant=reject_constant)
Traceback (most recent call last):
    ...
ValueError: non-JSON number: NaN
>>> try:
...     json.dumps({"value": float("inf")}, allow_nan=False)
... except ValueError:
...     pass
... else:
...     raise AssertionError("nonfinite output was accepted")
>>> def unique_object(pairs):
...     result = {}
...     for key, value in pairs:
...         if key in result:
...             raise ValueError(f"duplicate key: {key}")
...         result[key] = value
...     return result
>>> json.loads('{"role":"reader","role":"admin"}', object_pairs_hook=unique_object)
Traceback (most recent call last):
    ...
ValueError: duplicate key: role
>>> value = json.loads('{"price": 0.1}', parse_float=Decimal)
>>> assert value["price"] == Decimal("0.1")

```

These hooks illustrate independent policies, not a complete trust-boundary parser.
A real caller combines the needed policies, input budget and domain validation.

## CSV and TOML

Use `open(..., encoding="utf-8", newline="")` for CSV input and output; the csv
module owns its newline handling. Never split a CSV record on commas or physical
newlines: quoted fields can contain both. Check headers, duplicate column names,
missing and surplus fields before assigning domain meaning. `DictReader` does not
make those decisions for you. Check input size and `csv.field_size_limit` as needed.

CSV quoting is not protection against spreadsheet formula execution. If the
consumer is a spreadsheet, define an explicit formula-cell policy; do not silently
rewrite values in a generic interchange file.

```pycon
>>> import csv
>>> from io import StringIO
>>> stream = StringIO(newline="")
>>> writer = csv.writer(stream, lineterminator="\n")
>>> _ = writer.writerow(["name", "note"])
>>> _ = writer.writerow(["Lee, Ada", "line one\nline two"])
>>> _ = stream.seek(0)
>>> rows = list(csv.DictReader(stream))
>>> assert rows == [{"name": "Lee, Ada", "note": "line one\nline two"}]

```

`tomllib.load` requires a binary file; `tomllib.loads` accepts a string. TOML has
types such as datetimes that may need a deliberate conversion at JSON boundaries.
There is no stdlib TOML writer: reuse the project's dependency if writes are
required rather than manually emitting an incomplete grammar.

```pycon
>>> import tomllib
>>> from io import BytesIO
>>> config = tomllib.load(BytesIO(b'[service]\nport = 8080\nenabled = false\n'))
>>> assert config["service"] == {"port": 8080, "enabled": False}

```

Never use `bool(os.getenv("FLAG"))` as boolean parsing: `"false"` is truthy.
Configuration precedence and typed validation belong to **python-system-design**
when installed; the parsing APIs above remain useful without it.

## Pickle is a trust decision

Only load pickles from producers permitted to execute code in the receiving
process, with integrity/authenticity protected as required. HMAC authentication
does not make hostile content safe if the producer/key is compromised. Standard
pickle does not normally serialize lambdas or nested functions by value; functions
are referenced by importable qualified names. Compatibility depends on available
classes/modules and protocol versions. Never replace a validation failure with
unpickling as a fallback.

## Regex and ordinary text

Prefer literal methods (`split`, `partition`, `removeprefix`, `removesuffix`) for
literal structure. `strip(chars)` removes any listed character at either end;
it does not remove an exact prefix or suffix. Use `re.escape` for a literal inside
a pattern, not for replacement strings. For an arbitrary literal replacement,
use a callable replacement to avoid interpreting backslashes as group references.

- `match` anchors only at the start; `search` finds a match anywhere; `fullmatch`
  requires the whole input. `$` can match before a final newline; validation often
  wants `fullmatch` instead of a hand-built anchor pair.
- With str patterns, `\d`, `\w`, and `\s` are Unicode-aware. Use explicit ASCII
  ranges or `re.ASCII` when the external protocol is ASCII.
- `findall` changes result shape with capturing groups; `finditer` gives match
  objects and spans. Use named groups when fields have meaning.
- The stdlib re engine can spend excessive time on ambiguous nested repetition.
  Bound untrusted input and simplify patterns; compilation is not a ReDoS defense
  and re has no per-match timeout parameter.
- A regex checks a textual shape, not date validity, an email delivery address,
  or a complete structured-language grammar. Parse and validate the actual type.

```pycon
>>> import re
>>> assert re.fullmatch(r"\d+", "١٢") is not None
>>> assert re.fullmatch(r"[0-9]+", "١٢") is None
>>> assert re.fullmatch(r"[0-9]+", "12\n") is None
>>> assert "report.csv".removesuffix(".csv") == "report"
>>> replacement = r"\1"
>>> assert re.sub("TOKEN", lambda match: replacement, "aTOKENb") == r"a\1b"

```

Use `textwrap.dedent` for shared indentation, not arbitrary whitespace stripping;
it preserves a leading newline. `wrap`/`fill`/`shorten` are presentation operations
that may alter whitespace and should not touch byte-exact data. `difflib.unified_diff`
produces a diff iterator; preserve input line endings or choose `lineterm`
explicitly. `SequenceMatcher` similarity and `get_close_matches` are heuristics,
not edit-distance guarantees, identity checks, or safe automatic identifier repair.

## Authorities

[JSON defaults and compliance](https://docs.python.org/3.14/library/json.html#standard-compliance-and-interoperability),
[pickle security and supported objects](https://docs.python.org/3.14/library/pickle.html),
[csv](https://docs.python.org/3.14/library/csv.html),
[tomllib](https://docs.python.org/3.14/library/tomllib.html),
[re](https://docs.python.org/3.14/library/re.html),
[textwrap](https://docs.python.org/3.14/library/textwrap.html),
[difflib](https://docs.python.org/3.14/library/difflib.html).
