# Behavior, transitions, and collaboration

- [Pattern decisions](#pattern-decisions)
- [Strategy, template, chain](#strategy-template-and-chain-are-different-control-flow)
- [State transitions](#state-illegal-transitions-preserve-the-value)
- [Command and memento](#command-plus-memento-record-only-a-successful-edit)
- [Observer and mediator](#observer-and-mediator-delivery-is-an-api)
- [Iterator and visitor](#iterator-and-visitor)
- [Context-manager restoration](#context-manager-restore-presence-not-truthiness)

## Pattern decisions

| Source pattern | Small Python recipe | Contract that matters |
|---|---|---|
| Chain of Responsibility | Ordered handlers returning a distinct unhandled marker | First match versus all validators, short-circuiting, order, errors |
| Command | Function/`partial` now; data record when queuing/history is needed | Completion, repeatability, undo preconditions, failure before recording |
| Iterator | Generator; custom `__next__` only for needed state/control | Progress, one-shot exhaustion, resource lifetime, mutation during iteration |
| Mediator | Explicit coordinator receiving collaborators | Who initiates work, ordering, partial failure; not automatically an event bus |
| Memento | Immutable snapshot of sufficient state | Alias independence, restore validity, bounded retention, sensitive data |
| Observer | Callback subscriptions with explicit unsubscribe | Delivery order, reentrancy, exception policy, lifetime |
| State | Enum + transition function/table for a small closed workflow | Illegal transitions leave state unchanged; effects are not assumed atomic |
| Strategy | Pass one callable; callable object for real policy state | Same input/output/error contract across choices |
| Template Method | Fixed orchestration with callable steps | Hook order/invariants; inheritance only when controlled extension needs it |
| Visitor | `ast.NodeVisitor`, `singledispatch`, or closed `match` | Dispatch axis, coverage of node kinds, recursive traversal policy |

Context managers and coroutine/queue collaboration are Python-specific source
patterns, covered below. A command need not support undo unless the use case
requires it. Not all effects can be reversed.

## Strategy, template, and chain are different control flow

A strategy picks **one** algorithm. A template fixes sequencing while allowing
specific steps to vary. A chain tries handlers until one accepts; a validation
pipeline may instead run **all** checks and collect errors. State which behavior
is intended, rather than inheriting a linked `Handler` hierarchy by habit.

The template below normalizes an iterable using the selected strategy, retaining
input order. It consumes its input once and returns a new tuple. No sorter class
or abstract processor is needed.

```pycon
>>> from collections.abc import Callable, Iterable
>>> def labels(items: Iterable[str], normalize: Callable[[str], str]) -> tuple[str, ...]:
...     return tuple(normalize(item) for item in items)
>>> assert labels((x for x in (" Ada ", "BOB")), str.strip) == ("Ada", "BOB")
>>> assert labels(("Ada", "BOB"), str.casefold) == ("ada", "bob")
>>> assert labels((), str.strip) == ()

```

A chain's unhandled marker must not collide with valid falsey results:

```pycon
>>> from collections.abc import Mapping, Sequence
>>> def first_setting(name: str, sources: Sequence[Mapping[str, int]]) -> int:
...     for source in sources:
...         if name in source:
...             return source[name]
...     raise KeyError(name)
>>> assert first_setting("limit", ({"limit": 0}, {"limit": 10})) == 0
>>> first_setting("limit", ({}, {}))
Traceback (most recent call last):
...
KeyError: 'limit'

```

A middleware chain can have pre/post hooks by wrapping callables, but document
whether a rejection still reaches logging/cleanup hooks. Do not confuse auth,
validation and rate limiting demonstration code with complete security policy.

## State: illegal transitions preserve the value

Compute and validate the transition before exposing a new state. Enum values name
a closed workflow; separate state classes are useful only if behavior becomes
substantial and genuinely state-specific.

```pycon
>>> from enum import Enum
>>> class Status(Enum):
...     DRAFT = "draft"
...     PUBLISHED = "published"
...     ARCHIVED = "archived"
>>> def transition(status: Status, action: str) -> Status:
...     match (status, action):
...         case (Status.DRAFT, "publish"):
...             return Status.PUBLISHED
...         case (Status.PUBLISHED, "archive"):
...             return Status.ARCHIVED
...         case _:
...             raise ValueError("invalid transition")
>>> current = Status.DRAFT
>>> try:
...     current = transition(current, "archive")
... except ValueError:
...     print("transition rejected")
transition rejected
>>> assert current is Status.DRAFT
>>> current = transition(current, "publish")
>>> assert transition(current, "archive") is Status.ARCHIVED

```

This proves local transition rules, not a DB commit or remote publication. For
side effects, decide whether state is updated before or after the effect and how
partial completion is reconciled. Retries need idempotency where duplicate effects
matter. The same caution applies to a mediator orchestrating save/notify/update:
a central coordinator can reduce peer coupling without guaranteeing atomicity.

## Command plus memento: record only a successful edit

A callable/`partial` suffices for an immediate action. Use a command dataclass for
explicit inputs, serialization or history. A durable command also needs a stable
schema, identity/idempotency and completion/error semantics; a closure or pickled
arbitrary object is not a durable message protocol.

This editor uses string mementos, so snapshots have no nested mutable aliases.
Undo/redo changes history only when an operation exists; a rejected command leaves
both content and history untouched. A new successful command invalidates redo.

```pycon
>>> from dataclasses import dataclass
>>> @dataclass(frozen=True)
... class Insert:
...     position: int
...     text: str
...     def apply(self, content: str) -> str:
...         if type(self.position) is not int or not 0 <= self.position <= len(content):
...             raise ValueError("insert position out of range")
...         if not isinstance(self.text, str):
...             raise TypeError("insert text must be str")
...         return content[:self.position] + self.text + content[self.position:]
>>> class Editor:
...     def __init__(self) -> None:
...         self._content = ""
...         self._undo: list[str] = []
...         self._redo: list[str] = []
...     @property
...     def content(self) -> str:
...         return self._content
...     def execute(self, command: Insert) -> None:
...         updated = command.apply(self._content)
...         self._undo.append(self._content)
...         self._content = updated
...         self._redo.clear()
...     def undo(self) -> bool:
...         if not self._undo:
...             return False
...         self._redo.append(self._content)
...         self._content = self._undo.pop()
...         return True
...     def redo(self) -> bool:
...         if not self._redo:
...             return False
...         self._undo.append(self._content)
...         self._content = self._redo.pop()
...         return True
>>> editor = Editor()
>>> assert not editor.undo() and not editor.redo()
>>> editor.execute(Insert(0, "café"))
>>> editor.execute(Insert(4, "!"))
>>> assert editor.content == "café!"
>>> assert editor.undo() and editor.content == "café"
>>> try:
...     editor.execute(Insert(99, "bad"))
... except ValueError:
...     print("invalid edit rejected")
invalid edit rejected
>>> assert editor.content == "café" and editor.redo() and editor.content == "café!"
>>> assert editor.undo()
>>> editor.execute(Insert(4, "?"))
>>> assert editor.content == "café?" and not editor.redo()

```

Indices are Python string code-point positions, not UTF-8 byte offsets or displayed
grapheme clusters. This is local single-owner history, not a concurrent editor;
restore can overwrite intervening changes in a shared system. It keeps all history
for this bounded example. An application must set a retention/size policy; large
snapshots or secrets should not accumulate indefinitely. If undo itself can fail,
move history entries only after successful reversal. Reversing an external payment
is a new fallible compensating operation, not guaranteed restoration.

## Observer and mediator: delivery is an API

A mediator coordinates collaborators; an observer broadcasts a change to subscribers.
Use a direct call when there is only one known recipient. For callbacks, choose
subscription ownership, ordering, same-cycle subscription changes, failure policy,
and reentrancy **before** adding threads or an event bus.

The policy here is synchronous, insertion-ordered snapshot delivery. Removing a
subscriber affects the next emission; the current snapshot still receives it.
An exception propagates immediately and stops later callbacks. Unsubscribe is
idempotent, and each registration has its own identity even for equal callbacks.

```pycon
>>> from collections.abc import Callable
>>> class Signal:
...     def __init__(self) -> None:
...         self._callbacks: dict[object, Callable[[str], None]] = {}
...     def subscribe(self, callback: Callable[[str], None]) -> Callable[[], None]:
...         token = object()
...         self._callbacks[token] = callback
...         def unsubscribe() -> None:
...             self._callbacks.pop(token, None)
...         return unsubscribe
...     def emit(self, message: str) -> None:
...         for callback in tuple(self._callbacks.values()):
...             callback(message)
>>> signal = Signal()
>>> seen = []
>>> stop = signal.subscribe(seen.append)
>>> signal.emit("one")
>>> stop(); stop()
>>> signal.emit("two")
>>> assert seen == ["one"]
>>> def reject(message: str) -> None:
...     raise ValueError("subscriber failed")
>>> cancel_reject = signal.subscribe(reject)
>>> cancel_later = signal.subscribe(seen.append)
>>> signal.emit("three")
Traceback (most recent call last):
...
ValueError: subscriber failed
>>> assert seen == ["one"]
>>> cancel_reject(); cancel_later()

```

This intentionally supports same-thread subscription changes via a snapshot, not
thread safety or unbounded recursive emission. Callbacks can reenter `emit`; choose
to allow, queue, or reject that behavior for real stateful consumers. Strong callback
references keep owners alive; unsubscribe when their lifetime ends, or deliberately
use weak references such as `WeakMethod` with well-defined collection behavior.
Do not catch exceptions and only print them while reporting successful broadcast.
An aggregate-error policy can continue and return/raise structured failures if
required, but is a different contract.

A single queue shared by consumers distributes work, not copies to every observer.
Async broadcast requires per-subscriber delivery/backpressure and owned tasks;
thread-per-callback fire-and-forget loses error and shutdown control. For actual
queues/tasks specify bounds, cancellation, completion acknowledgement, and shutdown;
python-concurrency can help if installed. This recipe needs no concurrent runtime.

## Iterator and visitor

Prefer a generator to an iterator class unless you need explicit resumable state or
control methods. An iterable may return a fresh iterator; an iterator returns itself
from `iter` and stays exhausted after `StopIteration`. Never restart the same
iterator silently. For resource-backed generators, delayed iteration delays I/O
and errors; early termination must still close the resource, typically using a
caller-owned `with` scope rather than relying on garbage collection.

Pagination must continue through an empty page when its next cursor is present;
`if not page.items: stop` is not a sufficient end condition. Require advancing
cursors or bounded/repeated-cursor detection, use `deque` rather than `pop(0)` for
a buffer, and preserve request/parse failures. Do not claim a single-use cursor
iterator provides repeatable snapshot iteration or coherent concurrent updates.

A visitor adds operations over an existing structure without adding methods to
every node. The following uses the real stdlib parser and visits names without
executing the input. `generic_visit` is necessary when overriding a node with
children that still need traversal.

```pycon
>>> import ast
>>> class LoadedNames(ast.NodeVisitor):
...     def __init__(self) -> None:
...         self.names: list[str] = []
...     def visit_Name(self, node: ast.Name) -> None:
...         if isinstance(node.ctx, ast.Load):
...             self.names.append(node.id)
>>> visitor = LoadedNames()
>>> visitor.visit(ast.parse("result = left + right(left)"))
>>> assert visitor.names == ["left", "right", "left"]

```

`singledispatch` is **single** dispatch on the first argument's runtime class, not
multiple dispatch or dispatch on `list[int]`'s element type. Registered functions
must accept compatible remaining parameters. `singledispatchmethod` skips `self`/
`cls` for dispatch. For a closed union, a clear `match` plus exhaustive checker
assertion may be simpler; for a compiler-owned AST, `NodeVisitor` already fits.
Parsing arbitrary large input can still consume resources; this is not a sandbox.

## Context manager: restore presence, not truthiness

A context manager should make cleanup run even on failure. Missing and present-with-
`None` are different states. `__exit__` returning truthy suppresses an exception;
do that only for the explicit exceptions the API promises to suppress.

```pycon
>>> from collections.abc import Iterator
>>> from contextlib import contextmanager
>>> @contextmanager
... def temporary_key(data: dict[str, object], key: str, value: object) -> Iterator[None]:
...     missing = object()
...     old = data.get(key, missing)
...     data[key] = value
...     try:
...         yield
...     finally:
...         if old is missing:
...             del data[key]
...         else:
...             data[key] = old
>>> settings = {"mode": None}
>>> try:
...     with temporary_key(settings, "mode", "preview"):
...         assert settings["mode"] == "preview"
...         raise ValueError("work failed")
... except ValueError:
...     pass
>>> assert settings == {"mode": None}
>>> with temporary_key(settings, "extra", 0):
...     assert settings["extra"] == 0
>>> assert "extra" not in settings

```

This is a single-owner temporary binding: the body must not delete the managed key
or arrange concurrent mutation. For production temporary state prefer an isolated
context/request value over shared globals. A transaction context manager must expose
commit/rollback failure, not treat `with` as proof that commit succeeded. Multi-resource
acquisition needs cleanup for earlier resources if later acquisition fails;
`contextlib.ExitStack` is the stdlib tool. No custom lifecycle framework is required.

First-party references: [AST visitors](https://docs.python.org/3.14/library/ast.html#ast.NodeVisitor),
[functools](https://docs.python.org/3.14/library/functools.html), and
[contextlib](https://docs.python.org/3.14/library/contextlib.html).
