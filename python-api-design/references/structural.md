# Composition without wrapper hierarchies

- [Pattern decisions](#structural-pattern-decisions)
- [UTF-8 adapter](#a-narrow-adapter-with-an-honest-count-contract)
- [Function decorators](#function-decorators-preserve-static-and-runtime-shape-separately)
- [Bridge and facade](#bridge-and-facade-compose-operations-not-inheritance-axes)
- [Composite, flyweight, proxy](#composite-flyweight-and-proxy-guardrails)

## Structural pattern decisions

| Pattern | Practical recipe | Preserve/check |
|---|---|---|
| Adapter | Function or explicit wrapper converts names, units, representations | Accepted inputs, returned counts, error meanings, ownership |
| Bridge | Compose two independently varying policies, e.g. layout and output encoding | Both axes actually vary; no subclass for every combination |
| Composite | Recursive data or nodes exposing a common operation | Child ownership, tree versus graph, cycles, traversal/depth limits |
| Decorator | Wrap one operation; `wraps` + `ParamSpec` for functions | Signature, return/exception behavior, wrapper ordering, sync/async distinction |
| Facade | One function/module entry point for a cohesive workflow | Partial success, transaction/cleanup ownership, lower-level error visibility |
| Flyweight | Share immutable intrinsic state; keep location/request state separate | Complete key, cache bounds/lifetime, no accidental shared mutation |
| Proxy | Explicitly forward a capability after access/lazy/cache policy | Denial before effects, invalidation, resource close, special methods |

Adapter changes interface, decorator adds behavior, facade simplifies a workflow,
and proxy controls access/lifetime. They can overlap; do not build four layers to
satisfy four names. A bridge is useful for independent axes; a single injected
algorithm is already a strategy, not evidence for a separate hierarchy.

## A narrow adapter with an honest count contract

`BytesIO` writes bytes and reports byte counts. A text writer reports characters.
This adapter deliberately wraps the concrete full-write in-memory buffer; it does
not pretend all arbitrary binary streams guarantee full writes. It borrows the
buffer and does not close it. UTF-8 errors propagate; the buffer remains unchanged
if encoding fails before the write.

```pycon
>>> from io import BytesIO
>>> class Utf8Sink:
...     def __init__(self, buffer: BytesIO) -> None:
...         self._buffer = buffer
...     def write(self, text: str, /) -> int:
...         encoded = text.encode("utf-8")
...         self._buffer.write(encoded)
...         return len(text)
>>> raw = BytesIO()
>>> text = Utf8Sink(raw)
>>> assert text.write("café") == 4
>>> assert raw.getvalue() == b"caf\xc3\xa9"
>>> assert text.write("") == 0
>>> before = raw.getvalue()
>>> try:
...     text.write("\ud800")
... except UnicodeEncodeError:
...     print("invalid Unicode rejected")
invalid Unicode rejected
>>> assert raw.getvalue() == before and not raw.closed

```

For real file buffering/transcoding, prefer `io.TextIOWrapper`; review whether
closing that wrapper also closes its underlying stream. A general binary-writer
adapter must handle partial writes or explicitly narrow its promise. A payment
adapter must not use `int(float_amount * 100)` as an exact money conversion: use
integer minor units or explicit decimal rounding/currency policy, and validate
provider success before returning a transaction ID.

## Function decorators preserve static and runtime shape separately

`ParamSpec` preserves the callable's argument relationship for a checker;
`functools.wraps` preserves metadata and `__wrapped__` for introspection. Neither
makes a synchronous wrapper async-aware or validates the wrapped operation.
Here the added policy is simply stripping the returned text, so its changed
postcondition is explicit rather than claiming full behavioral transparency.

```pycon
>>> from collections.abc import Callable
>>> from functools import wraps
>>> from inspect import signature
>>> from typing import ParamSpec
>>> P = ParamSpec("P")
>>> def stripped(function: Callable[P, str]) -> Callable[P, str]:
...     @wraps(function)
...     def wrapper(*args: P.args, **kwargs: P.kwargs) -> str:
...         return function(*args, **kwargs).strip()
...     return wrapper
>>> @stripped
... def label(name: str, *, prefix: str = "") -> str:
...     """Build a label."""
...     if not name:
...         raise ValueError("name is required")
...     return f" {prefix}{name} "
>>> assert label("Ada", prefix="Dr ") == "Dr Ada"
>>> assert label.__name__ == "label" and label.__doc__ == "Build a label."
>>> assert signature(label) == signature(label.__wrapped__)
>>> label("")
Traceback (most recent call last):
...
ValueError: name is required

```

`outer(inner(f))` runs outer policy first on entry, inner policy first on return.
A logging wrapper outside authentication may log denied requests; a cache outside
authorization may expose another user's cached data. Decide order explicitly.
Do not log secrets or arguments/results indiscriminately. Do not retry every
`Exception`; retry only specified transient failures when effects are safe to
repeat, within a real deadline. Count failures too when timing in `finally`, but
ensure monitoring failures do not mask the primary exception.

An async wrapper must `await` the wrapped callable inside its error/timing scope;
a normal wrapper otherwise observes coroutine creation rather than execution.
Do not cache a coroutine object with `lru_cache`. Wrapping a method with a callable
instance also needs descriptor binding semantics; a closure returned as a normal
function usually avoids that complication.

## Bridge and facade: compose operations, not inheritance axes

A rendering pipeline can receive a `render(record) -> str` callable and an
`encode(text) -> bytes` callable independently. `encode(render(record))` is often
the complete bridge. Validate cross-policy constraints where needed. A facade
can own this sequence plus writing, but must say which outputs survive failure;
a facade is not automatically a transaction.

A concrete facade can be as small as a real deterministic compression operation:

```pycon
>>> import gzip
>>> import json
>>> from collections.abc import Mapping
>>> def pack_counts(counts: Mapping[str, int]) -> bytes:
...     if any(not isinstance(key, str) for key in counts):
...         raise ValueError("count names must be text")
...     if any(type(value) is not int or value < 0 for value in counts.values()):
...         raise ValueError("counts must be nonnegative integers")
...     payload = json.dumps(dict(counts), sort_keys=True).encode("utf-8")
...     return gzip.compress(payload, mtime=0)
>>> packed = pack_counts({"closed": 0, "open": 3})
>>> assert json.loads(gzip.decompress(packed)) == {"closed": 0, "open": 3}
>>> pack_counts({"open": -1})
Traceback (most recent call last):
...
ValueError: counts must be nonnegative integers

```

This is compression, not encryption or authentication. The example checks decoded
content, not gzip bytes that may differ across runtimes. Do not reuse toy XOR,
base64, dummy codecs, or printed operations as security or media implementations.

## Composite, flyweight, and proxy guardrails

**Composite:** A nested immutable dataclass tree can provide `total()` for both
leaves and groups; operations on groups reduce child results. Do not make leaves
implement meaningless `add_child` methods. For externally supplied graphs, define
whether a shared child counts per occurrence or once and detect cycles or prohibit
them during construction. Use explicit stacks for untrusted/deep structures rather
than assuming recursion depth is safe. The visitor in [Behavior](behavioral.md)
shows a concrete traversal operation over real stdlib AST nodes.

**Flyweight:** A frozen style record `(font, size, bold)` can be shared by character
positions instead of copying style data. Key **every** intrinsic field, not just a
style name that may collide. Use a bounded `lru_cache` for a small pure constructor
when identity is not a promise; eviction and concurrent misses can create equal but
distinct values. A mapping with explicit lifetime may be better when identity is
required. `__slots__` reduces some per-instance overhead; it neither interns data
nor recursively freezes fields. Memory savings need measurement over the whole
object graph; storing the same existing texture reference does not copy its bytes
in every object merely because a field appears on each instance.

**Proxy:** Virtual proxies defer acquisition but must expose initialization failure
and define who closes acquired resources. Protection proxies check before each
operation and before returning cached data; `_private` naming does not prevent
untrusted Python code accessing the wrapped object. Enforce actual security at the
trusted boundary, not by assuming in-process wrappers are tamper-proof. Remote
proxies expose latency, deadlines, serialization, and partial failure: they are not
transparent local calls. Caching proxies need sentinel/presence checks, not `if
cached`, because `0`, empty collections, and `False` may be valid cached results.

Explicit methods are preferable to unrestricted `__getattr__`: forwarding all
attributes can bypass checks, hide misspellings, and collapse types to `Any`.
Implicit special-method lookup for `len(proxy)`, iteration, arithmetic, and context
management normally goes through the proxy's **type**, not a forwarded instance
attribute. Implement only the intended special methods and their contracts.

First-party references: [functools](https://docs.python.org/3.14/library/functools.html),
[io](https://docs.python.org/3.14/library/io.html), and
[special method lookup](https://docs.python.org/3.14/reference/datamodel.html#special-method-lookup).
