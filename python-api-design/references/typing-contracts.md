# Typing contracts and runtime boundaries

- [Choose a contract](#choose-the-contract-consumers-actually-need)
- [Parse external data](#parse-external-shape-before-declaring-it-typed)
- [Validated value example](#a-validated-value-not-a-validating-annotation)
- [Structural contracts](#structural-contracts-not-structural-proof)
- [Generics and narrowing](#generics-preserve-relationships-not-wishful-types)
- [Validation-library contracts](#validation-library-contracts-when-pydantic-is-already-used)
- [Version and introspection gates](#version-and-introspection-gates)
- [Checker workflow](#checker-workflow-and-compatibility)

## Choose the contract consumers actually need

| Need | Use | Important limit |
|---|---|---|
| Same concrete runtime representation | Concrete class or builtin | An annotation still does not validate values |
| Consume once | `collections.abc.Iterable[T]` | May be infinite or single-use; do not iterate twice |
| Index/length/multiple passes | `Sequence[T]` | Read-only interface, not immutable storage |
| Read keyed values | `Mapping[K, V]` | Does not freeze the underlying mapping |
| Caller-visible mutation | `MutableSequence`/`MutableMapping` or concrete container | State aliasing and mutation-on-error explicitly |
| One injected operation | `Callable[[Input], Output]` | `Callable[..., R]` discards argument checking |
| Keyword-only callback or several cohesive methods | `Protocol` | Parameter kinds/names and writable attributes matter |
| Controlled inherited implementation with abstract hooks | `ABC` + `abstractmethod` | No signature/domain validation at runtime |
| Known dict keys | `TypedDict`, `Required`, `NotRequired` | Ordinary dict at runtime; missing keys can still raise |
| Closed choices | `Literal`, enum, tagged union | `Literal` does not restrict runtime input |
| Distinct IDs sharing an underlying type | `NewType` | Returns its argument unchanged; no runtime invariant |
| Unknown external value | `object` until narrowed | `Any` instead allows unchecked operations to spread |

Use `None` only when its meaning is unambiguous. `T | None` says the value may be
`None`; it does not make a parameter optional to supply. `NotRequired[T]` says a
key may be absent, not that its present value may be `None`. A separate sentinel
is useful when absent and explicitly-null mean different things.

## Parse external shape before declaring it typed

`json.loads` can produce scalars, lists, and mappings. Decoding JSON is not domain
validation. This parser deliberately rejects extra keys, bool-as-int, empty names,
and invalid quotas. The returned `TypedDict` is a fresh ordinary dict. This is a
small schema, not a general-purpose validation framework.

```pycon
>>> import json
>>> from typing import NotRequired, TypedDict
>>> class UserSpec(TypedDict):
...     name: str
...     quota: NotRequired[int]
>>> def parse_user(text: str) -> UserSpec:
...     value: object = json.loads(text)
...     if not isinstance(value, dict):
...         raise ValueError("expected an object")
...     if set(value) - {"name", "quota"}:
...         raise ValueError("unknown fields")
...     name = value.get("name")
...     if not isinstance(name, str) or not name.strip():
...         raise ValueError("name must be nonempty text")
...     result: UserSpec = {"name": name.strip()}
...     if "quota" in value:
...         quota = value["quota"]
...         if type(quota) is not int or quota < 0:
...             raise ValueError("quota must be a nonnegative integer")
...         result["quota"] = quota
...     return result
>>> assert parse_user('{"name": " Ada ", "quota": 0}') == {"name": "Ada", "quota": 0}
>>> assert "quota" not in parse_user('{"name": "Ada"}')
>>> parse_user('{"name": "Ada", "quota": true}')
Traceback (most recent call last):
...
ValueError: quota must be a nonnegative integer
>>> parse_user('[]')
Traceback (most recent call last):
...
ValueError: expected an object
>>> parse_user('{"name": "Ada", "admin": true}')
Traceback (most recent call last):
...
ValueError: unknown fields

```

Malformed JSON raises `json.JSONDecodeError`; schema errors raise `ValueError`.
A larger boundary can translate these to an application error using `raise ...
from error`, without catching arbitrary programming errors. Numeric limits, accepted
unknown fields, normalization, and schema evolution are policy, not typing syntax.
`cast(UserSpec, value)` would perform none of these checks. Avoid `isinstance(x,
UserSpec)` or `isinstance(x, list[int])`; neither is a supported shape-validation API.

On Python 3.15, `TypedDict(..., closed=True)` can forbid extra keys in the static
contract, while `extra_items=T` describes additional string keys of type `T`;
these options are mutually exclusive. They do not validate a decoded dictionary.
Keep the parser's unknown-field policy explicit and verify checker support before
replacing an established compatibility representation.

## A validated value, not a validating annotation

This API accepts a nonempty half-open byte interval. Construction rejects wrong
runtime types (including `bool`, an `int` subclass), reversed ranges, and negatives.
The operation checks the remaining bound instead of silently returning a short slice.

```pycon
>>> from dataclasses import dataclass
>>> @dataclass(frozen=True)
... class ByteRange:
...     start: int
...     stop: int
...     def __post_init__(self) -> None:
...         if type(self.start) is not int or type(self.stop) is not int:
...             raise TypeError("range bounds must be integers")
...         if not 0 <= self.start < self.stop:
...             raise ValueError("expected 0 <= start < stop")
...     def extract(self, data: bytes) -> bytes:
...         if not isinstance(data, bytes):
...             raise TypeError("expected bytes")
...         if self.stop > len(data):
...             raise ValueError("range exceeds data")
...         return data[self.start:self.stop]
>>> assert ByteRange(1, 3).extract(b"python") == b"yt"
>>> ByteRange(2, 2)
Traceback (most recent call last):
...
ValueError: expected 0 <= start < stop
>>> ByteRange(True, 3)
Traceback (most recent call last):
...
TypeError: range bounds must be integers
>>> ByteRange(1, 3).extract(b"py")
Traceback (most recent call last):
...
ValueError: range exceeds data

```

`assert` above checks examples; it is not production validation. Python assertions
can be disabled. Frozen dataclasses prevent ordinary field assignment, not hostile
in-process mutation. Here the fields themselves are immutable integers; a frozen
record containing a list would not provide the same logical immutability.

## Structural contracts, not structural proof

For one operation pass a function. For a capability use a protocol defined near
its consumer. Positional-only parameters avoid requiring an implementation to use
the same public keyword name; if callers need keywords, name them in the contract.
The in-memory `StringIO` below is the real stdlib implementation, not a mock service.

```pycon
>>> from io import StringIO
>>> from typing import Protocol, runtime_checkable
>>> @runtime_checkable
... class TextWriter(Protocol):
...     def write(self, text: str, /) -> int: ...
>>> def emit_heading(target: TextWriter, text: str) -> int:
...     return target.write(text + "\n")
>>> target = StringIO()
>>> assert emit_heading(target, "Report") == 7
>>> assert target.getvalue() == "Report\n"
>>> class WrongSignature:
...     def write(self) -> int:
...         return 0
>>> assert isinstance(WrongSignature(), TextWriter)

```

The final presence check succeeds but `emit_heading(WrongSignature(), "Report")`
is not a valid call: a static checker should reject it, and runtime invocation
would raise `TypeError`. Do not turn presence checks into a plugin safety gate.
`issubclass` is not supported for protocols with data members, and parameterized
protocols are not runtime checks. In Python 3.12+, runtime protocol lookup uses
`inspect.getattr_static` and the protocol's member set is frozen at class creation;
objects depending on dynamic `__getattr__` may differ from Python 3.11.

A protocol's writable `value: T` requires safe reading **and writing**, which often
makes it invariant. A read-only `@property` can allow covariant access. ABC virtual
registration changes `isinstance`/`issubclass`, not methods or MRO; abstract method
requirements do not apply to registered virtual subclasses. Real ABC subclasses
with unimplemented abstract members can be defined but cannot be instantiated.

## Generics preserve relationships, not wishful types

Use a type variable when two positions have a relationship; a union merely lists
alternatives. Mutable `list[T]` is invariant: treating `list[int]` as `list[object]`
would let the receiver append a string. Prefer covariant read-only `Sequence[T]`
when the caller only reads; callable inputs are contravariant and outputs covariant.
Do not widen an input annotation then mutate it as if it were still homogeneous.

```pycon
>>> from collections.abc import Sequence
>>> from typing import TypeVar
>>> T = TypeVar("T")
>>> def first(items: Sequence[T]) -> T:
...     if not items:
...         raise ValueError("expected at least one item")
...     return items[0]
>>> assert first(("a", "b")) == "a"
>>> first(())
Traceback (most recent call last):
...
ValueError: expected at least one item

```

A bound such as `T = TypeVar("T", bound=int)` does **not** justify `return x + 1`
from a function returning `T`: arbitrary `int` subclasses need not survive addition.
Return `int` for that operation. Constraints (`TypeVar("N", int, float)`) select
from specified types, unlike an upper bound. Use `Self` for methods that truly
return the receiver's subtype, often `return self` or an alternate constructor
using `cls`. Do not promise `Self` while always constructing a base-class instance;
subclasses can also require incompatible constructor arguments.

Use `@overload` when input cases determine different output types. Overload
signatures are checker-facing declarations; one real implementation must accept
all declared cases and enforce runtime rules. Broad fallback overloads must have
return types compatible with narrower cases. Prefer a single union-returning
signature if consumers do not gain useful precision. Use `ParamSpec` to preserve
a wrapped callable's parameters, as in [Composition](structural.md).

`TypeGuard[T]` (3.10+) narrows the positive branch; `TypeIs[T]` (3.13+) also narrows
the negative branch and requires a type consistent with the input. A `TypeIs[T]`
predicate must return `True` **if and only if** its input belongs to `T`: a
predicate returning `False` for an empty `str` cannot soundly claim `TypeIs[str]`.
Otherwise the negative branch may be incorrectly narrowed. Test both outcomes,
including values near the recognition boundary. Mutation through another alias
after narrowing can invalidate assumptions. `assert_type` is a checker assertion and a
runtime identity operation; `assert_never` (3.11+) also raises if reached at runtime.
`Never` and `NoReturn` represent the same bottom type, not different precision tiers.

```pycon
>>> from typing import TypeIs
>>> def is_text(value: object) -> TypeIs[str]:
...     return isinstance(value, str)
>>> assert is_text("") and is_text("hello") and not is_text(0)

```

A modernization of a runtime alias is **not** necessarily cosmetic. `Alias = str`
binds the class object, whereas `type Alias = str` (3.12+) creates a
`typing.TypeAliasType` object. The latter is not a valid classinfo for
`isinstance`/`issubclass` and may affect runtime registries and reflection.
Review consumers before applying Ruff's unsafe PEP 695 alias fix:

```pycon
>>> RuntimeText = str
>>> type StaticText = str
>>> assert isinstance("hello", RuntimeText)
>>> try:
...     isinstance("hello", StaticText)
... except TypeError:
...     pass
... else:
...     raise AssertionError("a type alias was treated as a class object")

```

## Validation-library contracts when Pydantic is already used

Use a validation library where parsing, coercion or serialization is a real
boundary requirement. Do not introduce it merely to annotate an internal record;
ordinary classes/dataclasses remain useful. Conversely, do not ban internal
validation when an actual invariant or untrusted producer requires it. A static
checker and a Pydantic model establish different guarantees.

For **Pydantic v2**, inspect the project's pinned version and model configuration:

| Concern | Contract to establish |
|---|---|
| Coercion and extra data | Decide which conversions and unknown keys are accepted; strictness and `extra` policies are deliberate API choices. |
| `Field` metadata | Put `default`, `default_factory` and constructor-facing `alias` in assignment form when the checker must synthesize the constructor. |
| Union metadata | Attach field-wide metadata to the whole field type: `Annotated[int \| None, Field(deprecated=True)]`, not only to the `int` branch. |
| Validation order | Prefer built-in constraints for ordinary bounds. After validators receive already parsed values; before validators must handle raw input, potentially any object. |
| Reuse versus class policy | `Annotated[..., AfterValidator(...)]` makes a reusable validated type; decorator/model validators also suit multiple fields or cross-field rules. Neither style is universally correct. |
| Validation bypass | `model_construct()` skips validation. Defaults and later assignment need their own validation policy; construction does not guarantee all future mutations are checked. |
| Serialization | Nested model fields normally serialize according to their declared type, omitting subclass-only fields. Explicit polymorphic/duck serialization changes that contract and can expose secrets. |

Test accepted and rejected raw inputs, normalized values, and the actual serialized
payload. If omission differs from explicit null in a patch request, preserve field
presence (for example, a suitable `exclude_unset=True` operation) rather than
equating every default/`None` with absence. See [Evolution](evolution.md) for
input/output schemas and generated-client compatibility.

Do not mechanically remove future annotations or add runtime `isinstance` failures
to satisfy a typing-only change. Pydantic supports forward annotations; names must
be available in the resolution context. Use explicit named recursive aliases
(`type` on 3.12+, or a permitted `TypeAliasType` backport) where its schema resolver
needs them, and test the project's framework/checker combination.

Configuration is external input too: parse it at the application boundary and
inject validated settings or narrower values into consumers. Importing a reusable
module should not load all environment-dependent settings or call `sys.exit`.
Detailed source precedence, secret-file handling and application startup ownership
belong to **python-system-design** when that optional skill is installed.

## Version and introspection gates

Use stable Python 3.15 for new projects; retain an existing project's supported
minimum and its matching checker/dependency support.

| Python | Stdlib/syntax additions relevant here |
|---|---|
| 3.9 | Builtin generics such as `list[int]`; `collections.abc` generics |
| 3.10 | `X | Y`, `TypeAlias`, `ParamSpec`, `Concatenate`, `TypeGuard` |
| 3.11 | `Self`, `Never`, `Required`, `NotRequired`, `assert_type`, `assert_never` |
| 3.12 | `type Alias = ...`, `class Box[T]`, `def first[T](...)`; `typing.override`; runtime protocol changes |
| 3.13 | `typing.ReadOnly` for TypedDict keys; `TypeIs`; type-parameter defaults; nesting `ClassVar`/`Final` |
| 3.14 | Default deferred annotations; `annotationlib` |
| 3.15 current baseline | Builtin `sentinel` and `frozendict`; `typing.TypeForm`; `TypedDict` `closed`/`extra_items` |

Before 3.14, ordinary function/class annotations are eager unless quoted or using
`from __future__ import annotations`. Quote the **whole** forward-reference
expression (`"Node | None"`) on older supported Python, not `"Node" | None`. The future
import stores strings, including in 3.14–3.15; it is not identical to the default
lazy evaluation. Local variable annotations have different evaluation/storage
rules; do not infer runtime schema presence from every source annotation.

For trusted objects, use `typing.get_type_hints(obj, include_extras=True)` when
resolved typing forms and metadata matter; it may raise on unavailable names.
`TYPE_CHECKING` imports are not made available at runtime by magic. On 3.14+ use
`annotationlib.get_annotations` with `Format.VALUE`, `FORWARDREF`, or `STRING`
according to whether resolution, unresolved references, or display is needed.
These formats are not a sandbox: even `STRING` and `FORWARDREF` do not promise
execution-free introspection of an arbitrary annotation provider. Annotation
functions may execute code, so inspect only trusted objects at runtime; source
scanners should prefer source parsing over importing unfamiliar targets. Deferred
evaluation is not zero-cost typing or input validation.

`Final` prevents rebinding only in static analysis; it does not freeze a container.
`ClassVar` marks class-level intent and affects dataclass field treatment, not
runtime sharing rules. `ReadOnly[list[T]]` prevents assigning that TypedDict key
in checked code but not mutating its list. `Annotated[T, metadata]` carries metadata;
only a framework explicitly consuming it can add validation behavior.

`TypeForm[T]` (3.15+) describes a type expression accepted by a runtime API, such
as a union or parameterized generic; `type[T]` describes a class object instead.
Neither `TypeForm` nor a cast validates a value against that expression. Do not
invent a generic `decode`/`isinstance` implementation without an actual validator.

## Checker workflow and compatibility

Keep `Any` at untyped integration edges; use typed adapters to limit propagation.
For a value of unknown type, `object` requires narrowing before use. Document the
evidence behind a necessary cast, which returns its argument unchanged. Preserve
real validation at trust boundaries, while keeping a typing-only refactor free of
new observable failures. Read [Checker operations](checker-operations.md) for
coverage, strictness migration, diagnostics and downstream `py.typed` verification.

Newer syntax cannot be backported by a future import. Use `typing_extensions`
only when the project permits it and the checker supports the feature. Keep
positive and intentionally rejected consumer cases separate from runtime examples.

First-party references: [typing](https://docs.python.org/3.15/library/typing.html),
[ABCs](https://docs.python.org/3.15/library/abc.html),
[annotationlib](https://docs.python.org/3.15/library/annotationlib.html),
[TypeIs soundness](https://typing.python.org/en/latest/guides/type_narrowing.html),
[Ruff PEP 695 alias fix safety](https://docs.astral.sh/ruff/rules/non-pep695-type-alias/),
[TypedDict specification](https://typing.python.org/en/latest/spec/typeddict.html),
[Pydantic fields](https://docs.pydantic.dev/latest/concepts/fields/),
[validators](https://docs.pydantic.dev/latest/concepts/validators/),
[models](https://docs.pydantic.dev/latest/concepts/models/),
[serialization](https://docs.pydantic.dev/latest/concepts/serialization/), and
[forward annotations](https://docs.pydantic.dev/latest/concepts/forward_annotations/).
