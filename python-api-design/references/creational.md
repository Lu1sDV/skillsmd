# Creation, copying, and resource ownership

- [Pattern decisions](#pattern-decisions)
- [Constructor and builder](#constructor-before-builder)
- [Factories and registries](#factory-registry-and-family-coherence)
- [Copying and immutability](#prototype-and-immutability-name-the-identity-graph)
- [Singletons, lazy values, pools](#singleton-lazy-values-and-object-pools)

## Pattern decisions

| Source pattern | Small Python recipe | Introduce more only when |
|---|---|---|
| Singleton | Construct once in the owning entry point and pass the value | A documented identity/lifetime constraint really requires global access |
| Factory Method | Function or `@classmethod` alternate constructor | A real inherited algorithm needs an overridable creation hook |
| Abstract Factory | Pass a coherent bundle of compatible constructors/operations | Multiple product families must vary together and mismatches are a real risk |
| Builder | Keyword-only constructor/dataclass with validated defaults | Incremental assembly or dependent options make one constructor awkward |
| Prototype | `dataclasses.replace`, `copy.copy`, or explicit copy of owned fields | The desired shared/copied identity graph is understood |
| Object Pool | Existing library pool and its context manager | Measured scarcity/cost justifies managing a reusable resource lifecycle |

## Constructor before builder

Keep required inputs required. Put local invariants in the constructor so an
alternate constructor or `replace` cannot accidentally skip them. Use keyword-only
options to avoid positional boolean soup. Defaults do not justify an elaborate
builder; a builder that accepts the same options is often just a second API.

```pycon
>>> from dataclasses import dataclass, replace
>>> @dataclass(frozen=True, kw_only=True)
... class ExportOptions:
...     columns: tuple[str, ...]
...     delimiter: str = ","
...     def __post_init__(self) -> None:
...         if not isinstance(self.columns, tuple) or not self.columns:
...             raise ValueError("columns must be a nonempty tuple")
...         if any(not isinstance(name, str) or not name for name in self.columns):
...             raise ValueError("column names must be nonempty text")
...         if len(set(self.columns)) != len(self.columns):
...             raise ValueError("duplicate columns")
...         if not isinstance(self.delimiter, str) or len(self.delimiter) != 1:
...             raise ValueError("delimiter must be one character")
>>> original = ExportOptions(columns=("name", "quota"))
>>> tabbed = replace(original, delimiter="\t")
>>> assert original.delimiter == "," and tabbed.columns == ("name", "quota")
>>> replace(original, columns=("name", "name"))
Traceback (most recent call last):
...
ValueError: duplicate columns

```

This options value is logically deeply immutable under ordinary use because its
accepted contents are immutable strings in a tuple, not merely because it is frozen.
It is not a security boundary against Python reflection or hostile subclasses.
For general CSV output, use `csv.writer`; this options recipe is not a CSV codec.

A real builder must validate final combinations, return a snapshot rather than
its mutable working lists/dicts, and document reuse/reset behavior. Otherwise a
second build can change the first result or leak recipients/options between calls.
A director can just be a named preset function taking fresh arguments. Use `Self`
only for fluent methods genuinely returning the same subtype. Many parameters alone
are not evidence that a builder is needed.

## Factory, registry, and family coherence

A factory chooses or parses a representation; it is not required for every class.
The following returns real encoders with the same input/output contract and exposes
unknown names and encoding failures instead of inventing a successful fallback.

```pycon
>>> from collections.abc import Callable
>>> def text_encoder(name: str) -> Callable[[str], bytes]:
...     encoding = {"utf8": "utf-8", "ascii": "ascii"}.get(name)
...     if encoding is None:
...         raise ValueError("unsupported encoding")
...     def encode(text: str) -> bytes:
...         return text.encode(encoding)
...     return encode
>>> assert text_encoder("utf8")("café") == b"caf\xc3\xa9"
>>> assert text_encoder("ascii")("ABC") == b"ABC"
>>> text_encoder("other")
Traceback (most recent call last):
...
ValueError: unsupported encoding
>>> try:
...     text_encoder("ascii")("café")
... except UnicodeEncodeError:
...     print("unrepresentable text rejected")
unrepresentable text rejected

```

Use `functools.partial` or a closure for captured constructor defaults. Use a
callable object (`__call__`) when it has meaningful state/lifecycle, not solely to
rename a function. An alternate constructor should return `cls(...)`, validate
external input before construction, and document whether subclassing is supported.
Do not hide file/network acquisition in an otherwise plain record's constructor.
It is legitimate for a resource constructor to acquire resources when documented;
clean up partial acquisition if subsequent setup fails.

For abstract factory needs, e.g. a matching encoder/decoder pair, select both from
one validated configuration and return a small record of callables. Test a roundtrip
and rejection of unsupported data. A registry or abstract factory adds no value if
stdlib `codecs.lookup` already supplies the required family. A DB cursor/transaction
must belong to its actual connection; unrelated objects with matching protocols
are not sufficient proof of compatibility. Do not manufacture a fake portable DB
API by printing SQL. Use parameter binding for values, not string interpolation;
transaction ownership belongs to the actual driver/application boundary.

For genuinely extensible registries, specify duplicate-key behavior, registration
order, and when registrations become fixed. Build the registry explicitly at the
entry point; import-side-effect discovery creates order/cycle surprises. A closed
selection can remain an `if` or small mapping. A plain dict is not a substitute for
an API requiring a `.set` method or TTL just because both are storage-shaped.

## Prototype and immutability: name the identity graph

Assignment aliases an object. A shallow copy duplicates the outer container but
retains its nested references. A deep copy recursively copies supported objects,
uses memoization to preserve sharing/cycles, may copy too much, and is not guaranteed
to create independent external resources. Functions/classes may be returned as-is;
files, sockets, and similar handles are not generically cloned.

```pycon
>>> from copy import copy, deepcopy
>>> from dataclasses import dataclass, replace
>>> @dataclass(frozen=True)
... class Draft:
...     title: str
...     tags: list[str]
>>> draft = Draft("Report", ["review"])
>>> renamed = replace(draft, title="Final")
>>> shallow = copy(draft)
>>> independent = deepcopy(draft)
>>> renamed.tags.append("approved")
>>> assert draft.tags == shallow.tags == ["review", "approved"]
>>> assert independent.tags == ["review"]
>>> assert renamed.tags is draft.tags

```

`frozen=True` blocks normal attribute rebinding; it does not freeze `tags`.
`dataclasses.replace` invokes initialization and is not a deep copy. A frozen value
with an unhashable list field is still not hashable via its generated hash. Avoid
`unsafe_hash=True` to silence this; dictionary keys need stable equality and hashes.
Use tuples/frozensets with immutable members for immutable data, or give callers a
documented copy when mutation is intended. Read-only mappings and `MappingProxyType`
are shallow views, not recursive immutable snapshots.

If implementing custom `__deepcopy__`, allocate and put the clone in `memo` **before**
recursing into a field that might point back to the original. Pass the same memo to
nested `deepcopy` calls. Define which resource handles remain shared; do not promise
blanket independence. Prefer explicit reconstruction if generic copying hides the
ownership rules. `copy.replace` exists only on 3.13+; use `dataclasses.replace` on the
3.11 baseline.

## Singleton, lazy values, and object pools

- A module is cached under an import identity within an interpreter. This is not
  one instance across workers, processes, interpreters, reloads, or alternate import
  names. Prefer entry-point-owned configuration over hidden mutable global state.
- `__new__` reuse can still run `__init__` on every construction. Locking allocation
  alone does not make initialization or later mutation safe. Avoid metaclass singleton
  machinery and double-checked publication; use explicit synchronized ownership when
  a shared resource really is required.
- `cached_property` requires an instance dictionary and allows overwriting/deleting
  its cached attribute. On 3.12+ its old internal lock is gone; concurrent access may
  run the getter more than once. It is unsuitable as an exactly-once acquisition or
  cleanup policy. `lru_cache` coherence likewise does not guarantee single-flight.
- A pool is bounded ownership, not just a queue: specify acquisition deadline,
  maximum resources including checked-out ones, reset/rollback, health checking,
  broken-resource disposal, and close/shutdown behavior. Use the driver/executor's
  existing pool rather than copying a generic recipe.
- If implementing a pool is unavoidable, reserve capacity atomically before creation,
  return capacity on creation failure, prevent double release/foreign-resource return,
  and close rejected resources. A default blocking `Queue.get()` can wait forever;
  `Queue(maxsize=0)` is unbounded, not a zero-capacity pool. Use monotonic deadlines.
  Concurrency/lifetime design can hand off to python-concurrency when installed.

First-party references: [dataclasses](https://docs.python.org/3.14/library/dataclasses.html),
[copy](https://docs.python.org/3.14/library/copy.html), and
[functools](https://docs.python.org/3.14/library/functools.html).
