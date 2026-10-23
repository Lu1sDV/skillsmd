# Exceptions and resource ownership

## Contents

- [Catch only failures you can handle](#catch-only-failures-you-can-handle)
- [Own resources at a visible lexical boundary](#own-resources-at-a-visible-lexical-boundary)
- [Groups and memory lifetime](#groups-and-memory-lifetime)

## Catch only failures you can handle

Keep `try` around the operation whose exception is expected, not an entire
pipeline with unrelated calls. `else` executes only after the `try` succeeds;
exceptions in `else` are not caught by the preceding handlers. `finally` runs on
normal language-level exits, but not after every process termination or crash.
Avoid `return`, `break`, `continue`, or fresh exceptions in cleanup that mask an
active failure. Python 3.14 warns about control flow exiting `finally`.

Use `TypeError` for an unsupported argument type and `ValueError` for an invalid
value of an acceptable type. `KeyError`, `IndexError`, and `AttributeError` express
different missing-data contracts; do not flatten all to `None`. `MemoryError`
is an `Exception` too: catching `Exception` is not equivalent to recovery.
Bare `except`/`BaseException` also catches interrupts and `GeneratorExit`.
Reserve broad catches for a real isolation/reporting boundary, and propagate or
return an explicitly modeled failure. Logging an exception is not recovery.

```pycon
>>> def positive_count(text):
...     try:
...         count = int(text)
...     except ValueError as error:
...         raise ValueError('count must be an integer') from error
...     if count <= 0:
...         raise ValueError('count must be positive')
...     return count
>>> positive_count('2')
2
>>> positive_count('0')
Traceback (most recent call last):
...
ValueError: count must be positive
>>> try:
...     positive_count('two')
... except ValueError as error:
...     print(str(error), type(error.__cause__).__name__)
count must be an integer ValueError

```

`raise` alone reraises the active exception. `raise NewError(...) from error`
records explicit causality when translating boundaries. `from None` suppresses
context display, not the new exception's traceback; use it only when hiding
irrelevant implementation detail intentionally. Add custom exception types when
callers actually need to distinguish them, not an obligatory hierarchy per function.
Do not put secrets in error messages or log the same failure at every layer.
Assertions may disappear with `python -O`; never use them to validate untrusted
input or enforce required runtime behavior.

EAFP is useful when a precheck races (e.g. existence then opening a file), but is
not a universal preference. Cheap pure validation can prevent harmful partial
side effects. `mapping.get(key, default)` is appropriate only if absence and a
stored default-like value need not be distinguished; its default expression is
evaluated eagerly. Catching `AttributeError` around a property call can mistake
an internal bug for an absent attribute.

## Own resources at a visible lexical boundary

Use an object's context manager rather than relying on refcounts, `__del__`, or
GC timing. A context manager promises its specific exit behavior, not necessarily
closure, transaction commit, rollback, or atomicity. Read that object's contract.
`__exit__` returning truthy suppresses an active exception; usually return
`False`/`None`. If `__enter__` fails, its own `__exit__` is not called, so acquisition
must clean up partial state itself. In multiple `with` items, successful entries
exit in reverse order, including when a later entry fails.

```pycon
>>> from contextlib import contextmanager
>>> from io import StringIO
>>> @contextmanager
... def text_source(text):
...     stream = StringIO(text)
...     try:
...         yield stream
...     finally:
...         stream.close()
>>> with text_source('payload') as source:
...     assert source.read() == 'payload'
>>> source.closed
True
>>> try:
...     with text_source('payload') as source:
...         raise ValueError('consumer failed')
... except ValueError as error:
...     print(str(error), source.closed)
consumer failed True

```

A `@contextmanager` generator yields exactly once. Exceptions in the `with` body
are thrown at `yield`; if caught merely for logging, reraise or they are suppressed.
Use an existing context manager directly when available; the wrapper above is
for teaching the cleanup protocol, not a replacement for `with StringIO(...)`.
`contextlib.closing` adapts a closeable object; `ExitStack` manages a dynamic number
of acquisitions. `suppress(SpecificError)` is only for deliberately ignorable
failures. `redirect_stdout` and `chdir` modify process-global state, so avoid them
in concurrent/library work. `chdir` requires 3.11+.

If a caller lends an open stream, do not close it unless the contract transfers
ownership. If a generator opens a file and yields lines, a consumer's `break`
does not itself close that generator. Prefer owning `with open(...)` outside the
iteration; otherwise use explicit `closing(generator)` and ensure its cleanup
runs. Never return a lazy iterator over a file already closed by the function's
`with`. File encodings/newlines, atomic writes, paths, and subprocess details are
optional **python-stdlib** handoffs; async cleanup is **python-concurrency**.

## Groups and memory lifetime

Python 3.11+ `ExceptionGroup` represents multiple failures; `except*` selects
matching subgroups rather than catching a single ordinary exception. Keep normal
`except` for ordinary single-operation errors; don't invent batch aggregation
unless callers need it. Detailed concurrent task-group failure handling belongs
to **python-concurrency**.

Cycles are not automatically leaks: CPython's cyclic collector handles many
cycles, including ordinary finalizers in modern Python. Objects can nevertheless
remain reachable through caches, tracebacks, globals, or callbacks. `del name`
removes a binding, not a guarantee of destruction. Weak references change
ownership and may return `None`; use only when the relationship is intentionally
non-owning. Reference counts, exact collection timing, and object sizes are
implementation/build dependent; measure rather than asserting fixed counts.

Sources: [errors tutorial](https://docs.python.org/3.14/tutorial/errors.html),
[with/try semantics](https://docs.python.org/3.14/reference/compound_stmts.html),
[contextlib](https://docs.python.org/3.14/library/contextlib.html),
[data model](https://docs.python.org/3.14/reference/datamodel.html).
