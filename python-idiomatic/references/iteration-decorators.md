# Iteration, control flow, and decorators

## Contents

- [Choose the result's lifetime](#choose-the-results-lifetime)
- [Branches and structural matching](#branches-and-structural-matching)
- [Decorators without hidden behavior changes](#decorators-without-hidden-behavior-changes)

## Choose the result's lifetime

| Need | Use | Boundary |
|---|---|---|
| Transform/filter into retained values | list comprehension | Materializes all results |
| Unique values / keyed results | set/dict comprehension | Hashable keys; later duplicate keys overwrite |
| One-pass stream | generator expression/function | Deferred work/errors; consumed once |
| Index and value | `enumerate(values, start=1)` | Index is a counter, not necessarily a source key |
| Pair aligned streams | `zip(left, right, strict=True)` | Python 3.10+; mismatch detected while consuming |
| Intentionally pad unequal streams | `itertools.zip_longest` | Choose a nonambiguous fill value |
| First match / existence / universal condition | `next(..., default)` / `any` / `all` | Short-circuit consumes only a prefix |
| Reverse sequence / sort iterable | `reversed` / `sorted` | Reverse needs protocol support; sort materializes |

Comprehension clauses follow equivalent nested-loop order. Keep simple
transformations in comprehensions; use loops for side effects, multi-step error
handling, or unreadable nesting. `map(existing_function, iterable)` is also
reasonable. Don't replace an indexed algorithm with `enumerate` mechanically.
`range` is a reusable compact sequence, not a list or a single-use generator.

```pycon
>>> matrix = [[1, 2], [], [3]]
>>> [value * 2 for row in matrix for value in row if value % 2]
[2, 6]
>>> {word: len(word) for word in ['a', 'bee']}
{'a': 1, 'bee': 3}
>>> sorted({word[0] for word in ['apple', 'apricot', 'pear']})
['a', 'p']
>>> stream = (number * number for number in range(4))
>>> next(stream), list(stream), list(stream)
(0, [1, 4, 9], [])
>>> bool(stream)
True
>>> any([]), all([])
(False, True)
>>> list(enumerate(['a', 'b'], start=1))
[(1, 'a'), (2, 'b')]
>>> list(zip(['a', 'b'], [1, 2], strict=True))
[('a', 1), ('b', 2)]
>>> list(zip([1], [], strict=True))
Traceback (most recent call last):
...
ValueError: zip() argument 2 is shorter than argument 1

```

`zip(strict=True)` does not prevalidate sizes or roll back side effects from
pairs already processed. Validate/materialize first if all-or-nothing processing
is required. `zip(*pairs)` cannot unpack an empty collection into two outputs;
handle that case explicitly. Dict inversion loses entries for duplicate values.
`sorted` is stable; a key function avoids ordering unrelated object types.
`list.sort()` and `list.reverse()` mutate and return `None`.

An iterable can produce an iterator with `iter`; an iterator has `next` and
returns itself from `iter`. Generators are iterators, not empty-aware containers.
Create a fresh iterator from a repeatable source or retain a bounded list for
multiple passes. `itertools.tee` buffers the gap between consumers; it is not
bounded-memory replay. `groupby` groups consecutive equal keys, not all equal
keys; sort with the same key only if global grouping is intended. Consume each
group before advancing the outer iterator, or retain it as a list.

```pycon
>>> from itertools import groupby, islice
>>> [(key, list(group)) for key, group in groupby('aaba')]
[('a', ['a', 'a']), ('b', ['b']), ('a', ['a'])]
>>> def counting(start=0):
...     while True:
...         yield start
...         start += 1
>>> list(islice(counting(5), 3))
[5, 6, 7]
>>> def concatenate(*iterables):
...     for values in iterables:
...         yield from values
>>> list(concatenate([1], [], [2, 3]))
[1, 2, 3]

```

`yield` pauses execution; function-body failures may occur at `next`, not at
construction. `yield from` delegates iteration (and generator protocol operations).
Use `return` to finish a generator, not an explicit `raise StopIteration` (which
can become `RuntimeError`). Infinite generators need a bounded consumer.
Resource-owning generators require explicit lifetime handling; read
[Errors and resources](errors-resources.md) before returning lazy file streams.
Detailed grouping/cache utilities belong to optional **python-stdlib**; algorithm
selection, memoized DP, lookup complexity, and data structures to **python-algorithms**.

## Branches and structural matching

Use guard clauses for invalid cases and a conditional expression for a short
choice. `break` exits the innermost loop; `continue` skips its current iteration;
`pass` does nothing. Loop `else` runs on exhaustion/false condition, including zero
iterations, but not after `break`, `return`, or an exception. A walrus expression
is useful when it avoids duplicated computation; parenthesize it when combining
with comparisons. Do not use truthiness to discard valid zero-valued results.

Pattern matching requires Python 3.10+. Bare names capture rather than compare
with existing locals; use qualified constants or guards. Sequence patterns do
not match strings/bytes; mapping patterns allow extra keys. Guards execute after
binding. A matching shape is not full trust-boundary validation.

```pycon
>>> def command(tokens):
...     match tokens:
...         case ['move', direction] if direction in {'left', 'right'}:
...             return direction
...         case ['quit' | 'exit']:
...             return 'stop'
...         case _:
...             raise ValueError('unknown command')
>>> command(['move', 'left']), command(['exit'])
('left', 'stop')
>>> command(['move', 'up'])
Traceback (most recent call last):
...
ValueError: unknown command

```

## Decorators without hidden behavior changes

`@outer` above `@inner` means `function = outer(inner(function))`.
Decorator factories run at definition time; wrappers run at call time.
Use `functools.wraps` and forward arguments/results/exceptions. Preserve the
caller's execution model: a synchronous wrapper that times coroutine construction
does not time the awaited work. Avoid retries/repetition decorators unless
repeated side effects are explicitly safe and requested.

```pycon
>>> from functools import wraps
>>> def require_nonempty(function):
...     @wraps(function)
...     def wrapper(text, *args, **kwargs):
...         if not text:
...             raise ValueError('text must not be empty')
...         return function(text, *args, **kwargs)
...     return wrapper
>>> @require_nonempty
... def normalize(text, *, upper=False):
...     return text.upper() if upper else text.lower()
>>> normalize('Hello', upper=True), normalize.__name__
('HELLO', 'normalize')
>>> normalize('')
Traceback (most recent call last):
...
ValueError: text must not be empty

```

Use `cache` (3.9+) or bounded `lru_cache` for suitable pure computations rather
than mutable-default caches. Arguments must be hashable; cached values and
arguments remain referenced. A mutable result is shared by callers; cached
instance methods can retain `self`. Bound size or clear caches for unbounded input.
Do not cache time-sensitive, random, side-effecting, generator, or coroutine
results without a specific semantic design. Cache thread-safety is not a promise
of one invocation per key under concurrent misses.

Sources: [iteration tutorial](https://docs.python.org/3.14/tutorial/controlflow.html),
[built-ins](https://docs.python.org/3.14/library/functions.html),
[functools](https://docs.python.org/3.14/library/functools.html),
[itertools](https://docs.python.org/3.14/library/itertools.html).
