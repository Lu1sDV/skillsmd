# Collections, iteration and functional utilities

## Contents

- [Container selection](#selection-without-a-second-implementation)
- [Signed counts and layered views](#signed-counts-and-layered-views)
- [Iterator consumption](#a-pipeline-is-a-consumption-contract)
- [Caching and function adaptation](#caching-and-function-adaptation)
- [Copying, numeric and string helpers](#copying-numeric-and-string-helpers)

## Selection without a second implementation

| Need | API | Boundary / pitfall |
|---|---|---|
| FIFO or bounded recent history | `collections.deque` | `maxlen` append evicts from the opposite end; not a lossless work queue |
| Count occurrences | `Counter` | Missing reads return zero without inserting; zero entries can remain |
| Build groups | `defaultdict(list)` | Factory runs on missing `[]`, not `.get` or membership |
| Reorder keys explicitly | `OrderedDict.move_to_end` | Ordinary dict already preserves insertion order; two OrderedDicts compare order |
| Layer configuration | `ChainMap(overrides, defaults)` | Reads search layers; assignment/deletion act on the first mapping |
| Named tuple-shaped record | `namedtuple` / `typing.NamedTuple` | Define the type once; fields can still contain mutable objects |
| Priority / sorted lookup | `heapq` / `bisect` | Heap is not sorted; bisect requires stable sorted ordering |
| Flatten one level | `chain.from_iterable` | Avoid repeated list addition, which copies growing prefixes |
| Adjacent pairs / running values | `pairwise` / `accumulate` | Decide empty input and whether an initial value is included |
| Aggregate all keys | `defaultdict` or `Counter` | `groupby` only aggregates consecutive equal keys |

Detailed complexity, custom structures and algorithm invariants belong to optional
**python-algorithms**. Hash-table lookup is average O(1), not an adversarial bound.
`bisect_left(..., key=f)` applies `f` to stored items, not the search key; insertion
still moves list elements. Heap ties need a deterministic, comparable tie-breaker
before an otherwise incomparable payload.

## Signed counts and layered views

Counter subtraction as an operator and as an in-place method have different
semantics. Use the latter when negative stock/delta values must not disappear.
A ChainMap reflects later mutations in its backing dictionaries.

```pycon
>>> from collections import ChainMap, Counter, defaultdict
>>> stock = Counter(red=1)
>>> stock - Counter(red=2)
Counter()
>>> stock.subtract(red=2)
>>> assert stock["red"] == -1 and stock["missing"] == 0
>>> assert "missing" not in stock
>>> groups = defaultdict(list)
>>> assert groups.get("new") is None and "new" not in groups
>>> groups["new"].append(7)
>>> assert groups["new"] == [7]
>>> defaults = {"timeout": 10, "region": "local"}
>>> overrides = {"timeout": 2}
>>> settings = ChainMap(overrides, defaults)
>>> settings["region"] = "remote"
>>> assert defaults["region"] == "local" and overrides["region"] == "remote"
>>> defaults["retries"] = 0
>>> assert settings["retries"] == 0

```

## A pipeline is a consumption contract

- An iterator is one-shot. Materialize only if a second pass or random access is
  actually required and the size is bounded; otherwise accept an iterable factory.
- `groupby` groups runs; sort by the same key for global grouping only when
  reordering is permitted. Its group iterators share the source; consume each
  before advancing, or deliberately materialize the groups you need to retain.
- `islice` advances the underlying iterator, including skipped values. `takewhile`
  consumes the first failing element. Neither rewinds the source.
- `tee` is not a free copy: it retains elements until the slowest consumer reaches
  them. `cycle` stores elements from its input. Do not use either on unbounded
  input without a bound on retained data.
- `product`, `permutations`, and `combinations` retain finite input pools and can
  generate huge outputs. Elements are distinguished by position, not value; equal
  input values can produce equal result tuples. `repeat(x)` shares `x`.
- `compress` and ordinary `zip` stop at the shortest input. Use `zip(strict=True)`
  if length mismatch is an error; it checks only as iteration advances.
- `batched` requires 3.12+ and positive `n`; its final batch may be shorter.
  `strict=True` requires 3.13+ and raises on an incomplete final batch.

```pycon
>>> from itertools import groupby, takewhile
>>> rows = [("a", 1), ("b", 2), ("a", 3)]
>>> runs = [(key, [value for _, value in group])
...         for key, group in groupby(rows, key=lambda row: row[0])]
>>> assert runs == [("a", [1]), ("b", [2]), ("a", [3])]
>>> source = iter([1, 2, 0, 3])
>>> assert list(takewhile(bool, source)) == [1, 2]
>>> assert list(source) == [3]  # The failing 0 was consumed, not preserved.

```

## Caching and function adaptation

Use `cache` only for a finite problem or deliberately bounded lifetime. Use
`lru_cache(maxsize=...)` when entry eviction is enough. It is not a TTL cache,
byte budget, distributed cache, or request coalescer. Inputs must be hashable;
lists/dicts cannot be keys. For a memoized grid algorithm, capture one immutable
problem instance and cache coordinates rather than passing a mutable list grid.

Arguments and results remain referenced until eviction/clear. Mutating a cached
result contaminates later calls; prefer immutable results. Method caches retain
`self`. Concurrent misses can execute the underlying function more than once even
though cache bookkeeping is thread-safe. Do not cache side effects or raw
coroutines/generators. Expose a deliberate invalidation point for changing data.

```pycon
>>> from functools import lru_cache
>>> @lru_cache(maxsize=2)
... def fields(record: str) -> tuple[str, ...]:
...     return tuple(record.split(","))
>>> assert fields("a,,b") == ("a", "", "b")
>>> assert fields("") == ("",)  # Empty field is not an absent record.
>>> fields.cache_clear()

```

Other adapters:

- `partial` binds chosen arguments; it does not copy mutable bound values.
- `wraps` preserves metadata and exposes `__wrapped__`; it does not validate types
  or automatically turn a synchronous wrapper into a coroutine wrapper.
- Prefer a `key` to `cmp_to_key`. A comparator needs a coherent ordering; use the
  conversion only when an existing comparison API is the right contract.
- `total_ordering` fills comparison methods, not missing domain semantics. Return
  `NotImplemented` for unsupported operand types; preserve equality/hash agreement.
- `cached_property` stores an ordinary instance attribute. It needs an instance
  dictionary, and Python 3.12+ provides no getter-execution lock.
- `itemgetter`, `attrgetter`, and `methodcaller` clarify simple operations; they do
  not validate absent keys/attributes. Prefer a readable function for real logic.

## Copying, numeric and string helpers

A shallow copy duplicates the container, not its children. `deepcopy` follows the
copy protocol, preserves repeated-reference structure via a memo, and may leave
immutable objects shared; it cannot duplicate arbitrary files, locks or external
resources. Copy only the state whose ownership needs to change. `copy.replace`
(3.13+) supports named tuples, dataclasses, and types with `__replace__`; replacement
is not recursive. `dataclasses.replace` is available on the 3.11 example baseline.

Use `sum`, `min`/`max` with a defined empty policy, `math.prod`, `math.gcd`,
`math.lcm`, `math.comb`, and `math.perm` rather than home-grown reductions. `isqrt`
avoids rounding through a float for integer square roots. Integers do not overflow
at a fixed word width, but operations grow more expensive with bit length.
`math.isclose` needs a domain-appropriate tolerance (often an absolute tolerance
near zero); `math.fsum` improves floating summation, not decimal exactness.
Use `Decimal` constructed from strings when decimal semantics are required.

`string.ascii_letters` and `string.digits` are explicitly ASCII. `str.isalpha` and
`str.isdigit` accept a wider Unicode domain. `all(...)` is true on an empty input;
check nonemptiness when validating a required identifier.

```pycon
>>> from copy import copy, deepcopy
>>> from math import isqrt
>>> original = [[1], [2]]
>>> shallow, independent = copy(original), deepcopy(original)
>>> shallow[0].append(3)
>>> assert original == [[1, 3], [2]] and independent == [[1], [2]]
>>> n = 10**40 + 17
>>> root = isqrt(n)
>>> assert root * root <= n < (root + 1) * (root + 1)

```

## Authorities

[collections](https://docs.python.org/3.14/library/collections.html),
[itertools](https://docs.python.org/3.14/library/itertools.html),
[functools](https://docs.python.org/3.14/library/functools.html),
[copy](https://docs.python.org/3.14/library/copy.html),
[math](https://docs.python.org/3.14/library/math.html),
[operator](https://docs.python.org/3.14/library/operator.html),
[string](https://docs.python.org/3.14/library/string.html).
