# Records, cleanup, logging and processes

## Contents

- [Dataclasses and enums](#records-are-not-validators)
- [Cleanup on failure](#cleanup-must-survive-failure)
- [Logging and process-global state](#logging-and-process-global-state)
- [Child-process lifecycle](#child-process-contract)

## Records are not validators

| Tool | Use | Pitfall |
|---|---|---|
| `dataclass` | Named application state/value fields | Annotations do not validate constructor arguments |
| `field(default_factory=list)` | Fresh mutable state per instance | A shared class attribute or mutable default leaks across instances |
| `frozen=True` | Block ordinary field reassignment | Contained objects can mutate; generated hashing still needs hashable fields |
| `slots=True` | Deliberate attribute-layout policy | Not universal memory advice; may affect inheritance/weakrefs/cached_property |
| `replace` | Copy with selected field changes | Reuses unchanged children; construction/post-init rules still apply |
| `Enum` | Separate named alternatives | Duplicate values alias unless uniqueness is enforced |
| `IntEnum` / `StrEnum` | Interoperate with numeric/string protocols | Compare equal to corresponding primitive values; weaker domain separation |
| `Flag` / `IntFlag` | Bitwise combinations | Define which unknown combinations the boundary accepts |

Required positional fields must precede defaulted fields, including inherited
fields; keyword-only fields can express a different constructor contract. Use
`repr=False` to avoid accidental display, not as a serialization/redaction system.
`asdict` recurses into records/containers and deep-copies other objects. Serialize
an explicit public schema, not every field.

```pycon
>>> from dataclasses import dataclass, field, replace
>>> @dataclass
... class Batch:
...     name: str
...     records: list[str] = field(default_factory=list)
>>> first, second = Batch("first"), Batch("second")
>>> first.records.append("row")
>>> assert second.records == []
>>> renamed = replace(first, name="renamed")
>>> renamed.records.append("shared")
>>> assert first.records == ["row", "shared"]
>>> @dataclass(frozen=True)
... class Snapshot:
...     records: tuple[str, ...]
>>> snapshot = Snapshot(tuple(first.records))
>>> first.records.clear()
>>> assert snapshot.records == ("row", "shared")

```

`Enum(value)` raises `ValueError` for an unknown value; `EnumClass[name]` raises
`KeyError` for an unknown name. Decide whether that is a rejected external value
or a forward-compatibility branch. For persistent formats, explicit enum values
are safer than accidentally changing auto-assigned numbers by reordering members.
Python-native API typing, descriptors and design patterns belong to optional
**python-api-design** rather than another class hierarchy here.

## Cleanup must survive failure

Use a resource's native context manager. `closing` adapts a resource with `close`
but no context-manager protocol; `aclosing` closes an async generator at a known
point. A generator context manager yields exactly once and cleans up in `finally`.
If it catches an exception merely to log it, re-raise it instead of suppressing it.
A class context manager suppresses the exception when `__exit__` returns truthy.

`ExitStack` owns a dynamic set of resources/callbacks and unwinds in reverse order,
including when later acquisition fails. Register each acquired resource before
acquiring the next. `AsyncExitStack` handles asynchronous cleanup. `nullcontext`
can represent a borrowed resource whose lifetime belongs to the caller; avoid
closing it just because you accepted it as an argument.

```pycon
>>> from contextlib import ExitStack
>>> from pathlib import Path
>>> from tempfile import TemporaryDirectory
>>> with TemporaryDirectory() as directory:
...     path = Path(directory) / "input.txt"
...     _ = path.write_text("payload", encoding="utf-8")
...     try:
...         with ExitStack() as stack:
...             opened = stack.enter_context(path.open(encoding="utf-8"))
...             assert opened.read() == "payload"
...             _ = stack.enter_context((path.parent / "missing").open())
...     except FileNotFoundError:
...         assert opened.closed
...     else:
...         raise AssertionError("missing second resource unexpectedly opened")

```

`suppress(FileNotFoundError)` is appropriate only when absence is explicitly
acceptable. `suppress(Exception)` is not resource handling. `redirect_stdout`
changes process-global state and is not an isolation mechanism for concurrent
code or a child process. Async lifetime/locking belongs to **python-concurrency**.

## Logging and process-global state

- Libraries use `logging.getLogger(__name__)`; application entry points configure
  handlers and levels. Repeated `basicConfig` normally has no effect once root
  handlers exist; `force=True` is a deliberate application-wide replacement.
- `logger.debug("count=%s", count)` defers formatting, not evaluation of its
  arguments. Guard expensive argument construction with `isEnabledFor` if it
  matters. F-strings remain eager, including on Python 3.12+.
- `logger.exception` includes the active traceback inside an exception handler.
  Log once at the boundary that owns recovery/reporting; do not log-and-raise at
  every layer. Avoid secrets and unbounded attacker-controlled payloads.
- `extra` adds fields to a LogRecord; it does not select a JSON formatter. Avoid
  reserved attribute collisions, provide fields expected by your formatter, and
  avoid duplicate records from attaching handlers at multiple hierarchy levels.
- Rotating file handlers do not by themselves coordinate multiple processes
  writing the same file. Follow the deployment's log collector/queue policy.
- Environment, current directory, `sys.path`, stdout and root logging are shared
  process state. Parse configuration at an application boundary; pass `cwd` and
  `env` to children rather than calling `os.chdir` during concurrent work.
- `sys.getsizeof` measures the object itself plus implementation overhead, not a
  complete retained object graph. Raising the recursion limit is not an algorithm
  fix. Prefer proper package installation to `sys.path` modification.
- Reserve stdout for program output and stderr for diagnostics where a CLI has a
  machine-readable interface. Use `argparse` rather than ad hoc `sys.argv` parsing
  when options/validation are required.

## Child-process contract

Prefer `subprocess.run` for a bounded command. Specify a sequence of arguments,
`check=True` when nonzero is failure, a deadline, and explicit text encoding or
bytes. An argument sequence does not need shell escaping; it also does not stop
target-option injection. Use `--` where the target supports it and reject
unauthorized executables/options. Windows batch files can involve a shell even
without `shell=True`; do not assume Unix guarantees for `.bat`/`.cmd` files.

This example launches the actual current interpreter and checks a JSON result
and a failed exit; no network or platform-specific executable is required.

```pycon
>>> import json
>>> import subprocess
>>> import sys
>>> child = subprocess.run(
...     [sys.executable, "-I", "-c",
...      "import json, sys; print(json.dumps(sys.argv[1:]))", "a b", "x;y"],
...     capture_output=True, text=True, encoding="utf-8", check=True, timeout=10,
... )
>>> assert json.loads(child.stdout) == ["a b", "x;y"] and child.stderr == ""
>>> try:
...     subprocess.run([sys.executable, "-I", "-c", "raise SystemExit(7)"],
...                    check=True, capture_output=True, timeout=10)
... except subprocess.CalledProcessError as error:
...     assert error.returncode == 7
... else:
...     raise AssertionError("child failure was ignored")

```

`capture_output`/`communicate` buffer output in memory; redirect to a bounded file
or implement an appropriate streaming limit for large/untrusted output. Draining
one pipe while ignoring a full second pipe can deadlock. `run(timeout=...)` kills
and waits for its child, then raises; process creation may itself be uninterruptible.
It does not promise to terminate an entire descendant tree. `Popen.communicate`
timeout does not kill the child for you: terminate/kill as the policy requires,
then drain and reap it. Merely breaking a stdout loop or calling `terminate`
without `wait`/`communicate` leaves lifecycle work unfinished.

An explicit `env` mapping replaces inheritance rather than merging automatically.
Preserve required system variables deliberately, omit secrets the child does not
need, and select the executable from a trusted path. A subprocess is not a sandbox.

## Authorities

[dataclasses](https://docs.python.org/3.14/library/dataclasses.html),
[enum](https://docs.python.org/3.14/library/enum.html),
[contextlib](https://docs.python.org/3.14/library/contextlib.html),
[logging](https://docs.python.org/3.14/library/logging.html),
[subprocess](https://docs.python.org/3.14/library/subprocess.html),
[os](https://docs.python.org/3.14/library/os.html),
[sys](https://docs.python.org/3.14/library/sys.html).
