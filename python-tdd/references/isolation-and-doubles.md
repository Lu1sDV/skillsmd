# Isolation, fixtures, and test doubles

- [Real behavior versus doubles](#pick-real-behavior-before-a-double)
- [Patch lookup](#patch-where-lookup-happens)
- [Deterministic clock example](#deterministic-clock-boundary-without-mocking-time-globally)
- [Fixture lifecycle](#fixture-lifecycle-and-leaked-state)
- [Flake diagnosis](#diagnose-a-flake-with-comparable-runs)

## Pick real behavior before a double

| Need | Prefer | Evidence limit |
|---|---|---|
| Collections, pure validation, serialization | Real value/function | Do not mock away the rule under test |
| File behavior | Temporary directory and real files | Does not reproduce every filesystem/permission behavior |
| Database behavior | Disposable instance of the supported database | SQLite is not evidence for PostgreSQL locking, SQL, or isolation |
| Deterministic dependency input | Stub / explicit callable or value | Controls one dependency, not its implementation |
| Small working replacement | Fake, only for needed behavior | Keep contract tests against real implementation; fake can drift |
| Required external side effect | Spy/mock at that boundary | Verifies attempted calls, not successful remote delivery |
| Live integration | Controlled endpoint/service and explicit credentials | Separate environment evidence, not a deterministic unit test |

A dummy is an unused argument; a stub supplies values; a fake implements a small
working contract; a spy records calls; a mock supports interaction expectations.
Use these names to explain intent, not to mandate a framework or interface.
Pass a clock callable or existing dependency when needed; do not introduce a
DI container, repository hierarchy, or abstract factory just to test a function.

Never patch the function under test and assert its configured return value.
Use real local boundaries where cheap. A replayed response can test parsing,
validation, and error mapping; it cannot establish that an actual API currently
accepts the request or returns that schema. A call assertion is useful when the
call itself is the contract (e.g. no charge on validation failure), but it does
not establish a completed transaction or delivered email.

## Patch where lookup happens

Recipe using two conceptual production modules:

```python
# In shop/reports.py:
from shop.transport import fetch_orders


def total_cents(account_id):
    rows = fetch_orders(account_id)
    return sum(row["amount_cents"] for row in rows)
```

In a test for that existing package, patch
`patch("shop.reports.fetch_orders", autospec=True)`, configure rows containing
`amount_cents`, call the real `total_cents`, and assert the computed total plus
the account argument. Patching `shop.transport.fetch_orders` after the import
does not replace the consumer's bound name. Conversely, if production uses
`import shop.transport` then `shop.transport.fetch_orders(...)`, patch that
looked-up attribute. Trace the import and expression; do not apply a slogan
without reading them.

`autospec=True` / `create_autospec` constrain signatures; `spec_set` also rejects
unknown attribute assignment. They catch some mock drift, not return schemas,
remote behavior, dynamic attributes, or every descriptor pattern. Avoid
`create=True` when it would hide a misspelled patch target. If patching a class,
configure its `.return_value` instance. For async callables use `AsyncMock` and
assert **awaits**, not just calls. Async context managers may have synchronous
factory calls with async `__aenter__`; mirror the real API rather than making
everything an `AsyncMock`. `pytest-mock`'s `mocker` fixture is optional, requires
its plugin, and is not needed to use stdlib `unittest.mock`.

Default expressions such as `clock=time.monotonic` capture the callable at
function definition; patching `time.monotonic` later will not replace it.
Captured closures and existing instances have similar lookup consequences.
Prefer passing the clock explicitly for the test when that seam already fits.
Use context-managed patching, or register a patcher's `.stop` immediately after
`.start`; never leave global patches active after failures.

## Deterministic clock boundary, without mocking time globally

This complete cache tests the actual lookup decision. Its clock is monotonic
seconds, not wall-clock dates; a caller controls time explicitly in the example.
The cache contract expires **at** the deadline. Only string keys/values are used.

```pycon
>>> class ExpiringCache:
...     def __init__(self, clock):
...         self._clock = clock
...         self._entries = {}
...     def put(self, key, value, ttl):
...         if ttl < 0:
...             raise ValueError("ttl must be nonnegative")
...         self._entries[key] = (value, self._clock() + ttl)
...     def get(self, key):
...         entry = self._entries.get(key)
...         if entry is None:
...             return None
...         value, deadline = entry
...         if self._clock() >= deadline:
...             del self._entries[key]
...             return None
...         return value
>>> now = [100]
>>> cache = ExpiringCache(lambda: now[0])
>>> cache.put("token", "payload", ttl=60)
>>> now[0] = 159
>>> assert cache.get("token") == "payload"
>>> now[0] = 160
>>> assert cache.get("token") is None
>>> assert cache.get("missing") is None
>>> cache.put("instant", "payload", ttl=0)
>>> assert cache.get("instant") is None
>>> from unittest import TestCase
>>> cache.put("stable", "old", ttl=10)
>>> with TestCase().assertRaisesRegex(ValueError, "nonnegative"):
...     cache.put("stable", "new", ttl=-1)
>>> assert cache.get("stable") == "old"

```

`now` is local test state, not a global clock patch. This establishes boundary
semantics and failure-state preservation, not thread safety or a complete cache
product. In production, choose the existing cache's clock source; this example's
injected clock must return finite numeric seconds and not move backwards.

## Fixture lifecycle and leaked state

Default to function scope for mutable fixtures. Broader `class`, `module`,
`package`, or `session` scope trades setup cost against shared state. A session
fixture is per pytest process/worker, not a distributed singleton. Reset state
explicitly or create independent data; do not depend on test order. A factory
fixture is useful for several distinct entities in one case, but keep defaults
visible and domain-relevant rather than hide an entire application graph.

For pytest `yield` fixtures, acquire resources under a context manager or
`try/finally` before setup that can fail. Code after `yield` is not reached if
setup raises before yielding. Split independently acquired resources into small
fixtures, or use `ExitStack` for conditional acquisitions; register finalizers
only after acquisition succeeded. Completed dependency fixtures are still torn
down when a dependent setup fails. A DB connection context may manage
transactions without closing the connection: verify its documented lifecycle.

Avoid autouse resets of private singleton attributes as the default convention.
They can conceal global-state design bugs and make a test's dependencies opaque.
Use autouse only when an explicit suite-wide invariant warrants it. Restore
monkeypatched environment/cwd/path state with the runner's scoped tools. For
randomness, use local `random.Random(seed)` and retain failing inputs; a seed is
not cross-version proof of every random distribution's exact output.

For concurrency, await/join work in cleanup, coordinate with events/queues, and
bound waits so failures terminate. Increasing sleeps/timeouts or serializing
all tests to hide an ordering bug is not a root-cause fix. A test that passes in
one schedule cannot prove race freedom.

With pytest-xdist, partition external names/resources by worker and test run;
`worker_id` alone repeats across runs. `--dist=loadscope` can keep related tests
on one worker and `worksteal` can balance uneven durations, but neither supplies
global fixture isolation or repairs ordering dependencies. Use the project's
compatible xdist version and measure any scheduling change.

## Diagnose a flake with comparable runs

Preserve the failing node/input, seed, versions, worker count, order, OS and logs.
Run a bounded set of identical attempts and record failures/attempts, not only
the last pass. Change one suspected cause, then compare under the same conditions;
zero failures in a small sample does not establish elimination. Check clock/timezone,
cwd/environment, leaked globals, unjoined work, shared external resources and
assertions tighter than the promised precision. A pass in isolation can implicate
pollution from other tests; a serial pass can implicate resource/schedule coupling.
Neither alone proves the cause.

Retries are a temporary mitigation, not evidence of a fix. Use quarantine only
under an explicit repository policy with a tracked owner/reason, not as the
default response to any flaky baseline. Keep a useful deterministic regression
once the cause is understood and report any residual nondeterminism honestly.

For output/snapshot checks, start capture before the emitting operation, let the
operation and promised background work finish, then inspect the intended capture
segment. `capsys.readouterr()` snapshots and clears captured output so far. A
snapshot update is a proposed behavioral change to inspect, not an automatic
way to resolve failure; framework-specific visual capture belongs to that framework.

Sources: [unittest.mock lookup](https://docs.python.org/3.15/library/unittest.mock.html#where-to-patch),
[pytest fixture cleanup](https://docs.pytest.org/en/stable/how-to/fixtures.html#safe-teardowns),
[pytest flaky tests](https://docs.pytest.org/en/stable/explanation/flaky.html),
[pytest output capture](https://docs.pytest.org/en/stable/how-to/capture-stdout-stderr.html),
[xdist scheduling](https://pytest-xdist.readthedocs.io/en/stable/distribution.html),
[xdist worker identity](https://pytest-xdist.readthedocs.io/en/stable/how-to.html#identifying-the-worker-process-during-a-test).
