# Properties, real boundaries, and evidence

- [Bounded Hypothesis recipe](#optional-bounded-hypothesis-recipe)
- [Database rollback](#database-rollback-is-an-observable-boundary)
- [Async cancellation](#async-cancellation-coordinate-do-not-sleep)
- [HTTP and CLI boundaries](#http-apis-and-cli-assert-the-actual-consumer-contract)
- [Coverage and mutation](#coverage-and-mutation-useful-signals-limited-claims)
- [CI feedback](#ci-feedback-and-completion)

## Optional bounded Hypothesis recipe

Use properties when a meaningful invariant covers many inputs, not to replace
named examples. Generate the actual valid domain rather than reject nearly
every input with `assume`. Define NaN/infinity, Unicode, integer magnitude, and
collection limits deliberately. Keep a different oracle or reconstruction step;
idempotence alone allows a function that always returns a constant.

Requires compatible pytest and Hypothesis versions in the target environment.
Save this complete recipe as `test_runs.py` in a disposable directory and run
`python -m pytest -q test_runs.py`. The Python fence is not a Markdown doctest;
in an application, import the production `encode_runs` instead of duplicating
it. The named examples prevent an identity/no-compression implementation from
passing the round-trip property alone.

```python
from itertools import groupby

from hypothesis import example, given, settings, strategies as st


def encode_runs(values):
    return [(value, sum(1 for _ in group)) for value, group in groupby(values)]


def test_adjacent_equal_values_are_compressed():
    assert encode_runs([2, 2, 1, 2]) == [(2, 2), (1, 1), (2, 1)]
    assert encode_runs([]) == []


@settings(max_examples=100, derandomize=True, database=None, deadline=None)
@example(values=[])
@example(values=[0, 0])
@given(values=st.lists(st.integers(min_value=-10, max_value=10), max_size=40))
def test_run_encoding_preserves_values(values):
    runs = encode_runs(values)
    restored = [value for value, count in runs for _ in range(count)]
    assert restored == values
    assert all(count > 0 for _, count in runs)
    assert all(left[0] != right[0] for left, right in zip(runs, runs[1:]))
```

Input sizes and successful generated examples are bounded, but `max_examples`
is **not** a hard bound on all calls: explicit examples, replay, filtering, and
shrinking affect execution count. `deadline=None` disables timing checks for
these tiny deterministic cases, not permission to run unbounded production
work; use the CI job/process timeout for a hung test.

`derandomize=True` and `database=None` make this recipe independent of local
example-database state for fixed test/dependency versions, not identical across
Hypothesis releases or changed tests. In a real suite, a persisted database may
speed replay; neither a cache nor a random seed substitutes for a retained
regression. On failure, inspect the shrunk input, add a named example or
`@example`, reproduce through the real function, fix, and rerun the focused test.
Save versions and any failure reproduction blob if needed. Do not swallow the
failure or assume a specific exact shrink result.

A function-scoped pytest fixture is not recreated for every Hypothesis example.
Create/reset mutable state **inside the test body** for each generated case;
do not suppress the relevant health check while leaking state between inputs.
For state machines, bound operation sequences and use a simpler reference model
with independently stated transition rules.

## Database: rollback is an observable boundary

This stdlib example establishes SQLite transaction behavior only. The unique
constraint rejects an insert; the preceding insert in that same transaction
must not survive. It checks stored rows after rollback rather than mock calls.
`closing` owns the connection; its own transaction context does not close it.

```pycon
>>> import sqlite3
>>> from contextlib import closing
>>> from unittest import TestCase
>>> with closing(sqlite3.connect(":memory:")) as connection:
...     _ = connection.execute("CREATE TABLE users (name TEXT UNIQUE NOT NULL)")
...     with connection:
...         _ = connection.execute("INSERT INTO users VALUES (?)", ("alice",))
...     with TestCase().assertRaises(sqlite3.IntegrityError):
...         with connection:
...             _ = connection.execute("INSERT INTO users VALUES (?)", ("bob",))
...             _ = connection.execute("INSERT INTO users VALUES (?)", ("alice",))
...     rows = connection.execute("SELECT name FROM users ORDER BY name").fetchall()
...     assert rows == [("alice",)]

```

For an application repository, exercise the actual repository and transaction
owner against its supported database. Assert commit visibility, constraint/error
mapping, and rollback effects using a fresh connection where that is the
contract. A test that merely calls `session.rollback()` during cleanup does
not undo commits made earlier by production code. Choose a disposable database
or a correctly joined outer-transaction fixture supported by the ORM/version;
do not assume SQLite-in-memory reproduces PostgreSQL isolation or SQL behavior.

## Async cancellation: coordinate, do not sleep

Dependency-free example: cancellation must reach the waiting worker and finish
its cleanup. Events establish ordering; the timeout bounds a broken startup,
not a claim that “five seconds is always enough” for every environment.

```pycon
>>> import asyncio
>>> from unittest import TestCase
>>> async def cancellation_case():
...     ready = asyncio.Event()
...     blocker = asyncio.Event()
...     closed = []
...     async def worker():
...         try:
...             ready.set()
...             await blocker.wait()
...         finally:
...             closed.append("closed")
...     task = asyncio.create_task(worker())
...     try:
...         await asyncio.wait_for(ready.wait(), timeout=5)
...     finally:
...         task.cancel()
...         with TestCase().assertRaises(asyncio.CancelledError):
...             await task
...     assert closed == ["closed"]
>>> asyncio.run(cancellation_case())

```

In a stdlib suite use `unittest.IsolatedAsyncioTestCase` and `async def test_*`.
With pytest, ordinary coroutine test functions need an async-aware runner/plugin
such as pytest-asyncio and its compatible event-loop/fixture configuration.
`@pytest.mark.asyncio` does not provide that plugin by itself. Never use removed
`asyncio.coroutine` as a modern mock recipe. Await the application coroutine;
assert returned values, exceptions, and cleanup. Keep loops/resources in the
same intended scope and finish every task, including failure paths. For threads
and processes, use controlled rendezvous and joins, a main guard where spawn
requires it, and subprocess-level deadlines for deadlocks. Production
cancellation/backpressure design belongs to optional **python-concurrency**.

## HTTP APIs and CLI: assert the actual consumer contract

**HTTP recipe prerequisites:** the application's actual framework, its compatible
test client/transport, and a test-only configuration/database. Build or obtain
that real app; use its client as a context manager when required to run startup
and shutdown. Send a valid request and assert the specified status, parsed
response fields, and persisted effects; send invalid input and assert the
specified validation/error status and absence of side effects. Test auth and
error mapping at the real adapter, not an injected mock status code. FastAPI's
usual request-validation response is not a universal HTTP/framework contract;
use the application's documented status. An in-process client omits actual
socket/TLS/proxy behavior; keep separate deployed-boundary checks where required.

**CLI recipe:** invoke the installed command (or `[sys.executable, "-m", package]`)
with `subprocess.run(..., capture_output=True, text=True, timeout=...)` from a
temporary directory. Assert exit status, stdout content/schema, stderr diagnostics,
and output-file bytes. Include a malformed input/missing file and assert nonzero
status plus no partial output when promised. Supply a controlled environment
and absolute fixture paths; never use `shell=True` just to run argument lists.
Click's `CliRunner` can test Click dispatch with its runtime installed, but it
does not establish console-entry-point packaging or OS process behavior. Build
and install into an isolated environment, then test outside the checkout when
installation/import/package-resource behavior is the requirement.

For visual behavior, retain visual/exploratory evidence as well as automated
assertions; an HTTP response or CLI exit status cannot establish rendered appearance.

## Coverage and mutation: useful signals, limited claims

With compatible pytest-cov installed in the target project's test environment:

```sh
python -m pytest tests/ --cov=myapp --cov-branch --cov-report=term-missing
```

Or with coverage.py and a unittest suite:

```sh
python -m coverage run --branch --source=myapp -m unittest discover -s tests
python -m coverage report -m
```

These are target-project recipes. Inspect uncovered changed lines and branch
arcs, then ask which behavior is missing. Statement coverage reports execution;
branch coverage adds observed control-flow destinations, not all path
combinations or correct assertions. Neither proves security, correct outputs,
absence of races, or a real service's behavior. Explain exclusions; do not mark
reachable defects `no cover` or choose an arbitrary universal percentage.

Mutation tools such as mutmut/cosmic-ray require compatible pinned versions and
project-specific configuration; their current CLI/configuration is not assumed
here. Start with the [exact-threshold mutation](workflow-and-runners.md#reproducible-boundary-exact-free-shipping-threshold).
A meaningful mutant must cause the intended assertion to fail; an import error,
timeout, or fixture failure is not evidence that behavior was detected. Classify
survivors: missing test, equivalent change, unreachable code, or tool limitation.
Do not add a brittle assertion solely to kill an equivalent mutant or claim a
perfect mutation score proves correctness.

## CI feedback and completion

1. Use the project's pinned/locked environment and supported interpreter matrix,
   including oldest/newest supported versions and relevant OS boundaries. These
   docs target Python 3.11+, not a mandate to raise the application's minimum.
2. Install declared test dependencies explicitly. Upstream's `--cov` CI command
   needs pytest-cov; pytest alone does not provide it. Optional pytest-mock,
   pytest-asyncio, Hypothesis, and framework clients need their own dependencies.
3. Run focused feedback locally, then the affected suite and full required CI
   gates. Confirm nonzero selection and no newly skipped requested behaviors.
   Keep general lint/type/packaging policy in existing project tooling.
4. Report interpreter/dependency versions, selected command/count, and actual
   outcomes. Archive failure diagnostics without credentials or private payloads.
   A timeout/interrupted run has no pass verdict; a retry that happens to pass
   does not fix nondeterminism.

Do not impose a fixed unit/integration/E2E ratio. Choose tests that observe the
actual changed contract at a tolerable maintenance/runtime cost. Wider risk
prioritization, exploratory plans, and organizational test strategy hand off to
optional **test-engineering**, not a duplicated methodology here.
