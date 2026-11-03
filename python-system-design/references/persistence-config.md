# Persistence, configuration and trust boundaries

## Contents

- [Assign transaction ownership](#assign-transaction-ownership-before-creating-classes)
- [A real SQLite rollback boundary](#a-real-sqlite-rollback-boundary)
- [Constraints, migrations and remote effects](#constraints-migrations-and-remote-effects)
- [Bound database waiting](#bound-database-waiting)
- [Configuration is parsed input](#configuration-is-parsed-input-not-a-module-full-of-globals)
- [Secrets and trust checklist](#secrets-and-trust-checklist)

## Assign transaction ownership before creating classes

A unit of work is the set of changes that must commit together, not necessarily
a `UnitOfWork` class. Name the owning application operation. Queries/helpers may
flush or return results; they must not independently commit if the caller needs
several changes to be atomic. A generic CRUD repository that commits every method
cannot later be made atomic merely by wrapping its caller in a unit-of-work class.

| Lifetime | Owner | Cleanup/commit policy |
|---|---|---|
| Engine/pool/session factory | Process startup/composition root | Dispose on shutdown; budget across all processes |
| Session/connection | Request/job operation | Close/return to pool after operation |
| Transaction | One use case | Commit on success; rollback on failure before reporting success |
| Deferred job | Worker operation | Create new session; never reuse the request session |

Optional SQLAlchemy 2.x recipe; requires SQLAlchemy, a supported driver and an
existing configured `sessionmaker` named `SessionFactory`. This illustrates
transaction framing, not an executable standalone application:

```python
from sqlalchemy import text


def rename_account(SessionFactory, account_id: int, name: str) -> None:
    if not name.strip():
        raise ValueError("name must not be blank")
    with SessionFactory.begin() as session:
        result = session.execute(
            text("UPDATE account SET name = :name WHERE id = :id"),
            {"name": name, "id": account_id},
        )
        if result.rowcount != 1:
            raise LookupError("account not found")
```

The factory's `begin()` context commits on normal exit, rolls back on exception,
and closes the session. Ordinary `with SessionFactory() as session` closes but
does **not** promise a commit. The async equivalent is
`async with AsyncSessionFactory.begin() as session`, with awaited database calls.
Pass the same session to collaborating helpers; do not open a new transaction
inside each helper. See [SQLAlchemy transaction framing](https://docs.sqlalchemy.org/en/20/orm/session_basics.html#framing-out-a-begin-commit-rollback-block).

A SQLAlchemy Session is mutable transaction state, not a global cache; use one
Session per thread and one AsyncSession per concurrent task. Reusing the engine
or session factory is different from sharing a live session. Failed flushes may
require rollback before reuse; context-managed transaction failure should escape
so rollback occurs. `flush()` sends pending SQL but is not a durable commit.
Do not return lazy ORM state that will require an already-closed session to
serialize; materialize the intended result within the owning lifetime.
See [session concurrency rules](https://docs.sqlalchemy.org/en/20/orm/session_basics.html#is-the-session-thread-safe-is-asyncsession-safe-to-share-in-concurrent-tasks).

For Django, prefer `transaction.atomic()` for the synchronous operation; catch a
database error **outside** the atomic block so the context sees failure. Its
`on_commit()` is useful for actions that must not happen after rollback, but is
not a durable outbox. Django 6.0 async transaction limitations are covered in
[web and jobs](web-jobs.md). See [Django transactions](https://docs.djangoproject.com/en/6.0/topics/db/transactions/).

Use a nested transaction/savepoint only when the use case explicitly permits
partial success. In Django, catch the failing inner `atomic()` block's exception
outside that inner block; earlier writes remain pending in the outer transaction
and become durable only when the outer block commits. Returning a value labelled
"failed" is a normal return and does not automatically roll anything back. In
SQLAlchemy, `Session.begin_nested()` establishes a savepoint and first flushes
pending state; it does not create an independent durable transaction. Keep this
distinction in tests. See [SQLAlchemy savepoints](https://docs.sqlalchemy.org/en/20/orm/session_transaction.html#using-savepoint).

## A real SQLite rollback boundary

This miniature operation reserves units and records a unique reservation in one
transaction. A duplicate reservation is **rejected**, not silently retried as
success. If the receipt insert fails after stock changed, the stock change rolls
back. A separate connection then verifies committed disk state. It is a local
transaction example, not a production inventory service or distributed job queue.

This Python 3.15 example uses `autocommit=False` (available since **3.12**) and the
interpreter's optional `sqlite3` module. Each operation owns its connection and
transaction. `with db` commits/rolls back but does **not** close the connection;
`closing()` owns that. With `autocommit=False`, a new transaction is opened after
commit/rollback, so `in_transaction` is not an ownership test. Do not reuse this
operation shape for helpers inside a caller-owned transaction: pass that caller's
connection instead and leave commit/rollback to the caller.

```pycon
>>> import sqlite3
>>> from contextlib import closing
>>> from pathlib import Path
>>> from tempfile import TemporaryDirectory
>>> def open_db(path):
...     return sqlite3.connect(path, autocommit=False)
>>> def reserve(path, reservation_id, units):
...     if not isinstance(reservation_id, str) or not reservation_id:
...         raise ValueError("reservation_id must be nonempty text")
...     if type(units) is not int or units <= 0:
...         raise ValueError("units must be a positive integer")
...     with closing(open_db(path)) as db:
...         with db:
...             result = db.execute("UPDATE stock SET units = units - ? WHERE id = 1", (units,))
...             if result.rowcount != 1:
...                 raise LookupError("stock item not found")
...             db.execute("INSERT INTO reservation VALUES (?, ?)", (reservation_id, units))
>>> with TemporaryDirectory() as directory:
...     path = Path(directory) / "stock.db"
...     with closing(open_db(path)) as db:
...         with db:
...             _ = db.execute("CREATE TABLE stock (id INTEGER PRIMARY KEY, units INTEGER NOT NULL CHECK(units >= 0))")
...             _ = db.execute("CREATE TABLE reservation (id TEXT PRIMARY KEY, units INTEGER NOT NULL)")
...             _ = db.execute("INSERT INTO stock VALUES (1, 10)")
...     reserve(path, "r1", 3)
...     try:
...         reserve(path, "r1", 2)
...     except sqlite3.IntegrityError:
...         pass
...     else:
...         raise AssertionError("duplicate reservation was accepted")
...     with closing(open_db(path)) as other:
...         assert other.execute("SELECT units FROM stock").fetchone() == (7,)
...     try:
...         reserve(path, "r2", 8)
...     except sqlite3.IntegrityError:
...         pass
...     else:
...         raise AssertionError("negative stock was accepted")
...     with closing(open_db(path)) as other:
...         assert other.execute("SELECT units FROM stock").fetchone() == (7,)
...         assert other.execute("SELECT id, units FROM reservation").fetchall() == [("r1", 3)]

```

The example's stock row `id=1` is seeded deliberately. A multi-item application
must accept and validate the actual item identifier and express its actual schema.
The database CHECK and unique key enforce failures; Python `assert` only checks
the observed outcome in the example. Bind values as parameters, never interpolate
untrusted values into SQL. Dynamic identifiers require a separate allowlist.

Primary contracts: [connection context manager](https://docs.python.org/3.15/library/sqlite3.html#how-to-use-the-connection-context-manager)
and [sqlite3 transaction controls](https://docs.python.org/3.15/library/sqlite3.html#transaction-control).
SQLite concurrency, typing and locking differ from PostgreSQL/MySQL; use the
production engine for those integration claims. Do not change transaction modes
blindly on a connection that is already doing work.

## Constraints, migrations and remote effects

- Encode uniqueness, foreign keys, valid ranges and required fields in the schema
  where they are invariants. An application-level existence check is insufficient
  under concurrency. SQLite foreign-key enforcement must be enabled per connection
  when relying on it; this example has no foreign keys.
- Use atomic conditional updates/appropriate isolation for contested state; a
  Python lock in one worker does not protect all processes. Keep transactions
  short; do not hold row locks while waiting on a remote API.
- Schema migrations belong to a controlled deployment step with compatible rollout
  and rollback/recovery plans. A model change or `create_all()` is not a migration
  strategy for existing data. Test a migration from the previous supported schema.
  For rolling deployments, expand the schema first, deploy code compatible with
  old/new shapes, backfill with bounds and restartability, then remove obsolete
  fields only after old processes and rollback requirements are retired. Coordinate
  migration ordering and lock budgets; per-module ownership does not require
  separate, conflicting migration histories.
- A transaction cannot make a remote effect atomic. Required publish-after-commit
  work needs the outbox/consumer duplicate policy in [web and jobs](web-jobs.md).
  Returning an error after a commit does not undo it; record a retryable operation
  identity when clients must recover an unknown outcome.
- Pools do not fix slow queries or unlimited demand. Bound pool capacity/waits,
  paginate with stable ordering, inspect actual queries and measure before caching.
  Reuse clients/pools rather than opening one for each outgoing request.

## Bound database waiting

Use separate budgets for pool acquisition, connecting, lock acquisition and query
execution. A client-side timeout/cancellation does not prove the server stopped
or that a commit failed; discard/recover the connection according to the driver
and reconcile unknown outcomes. Budget pool capacity across all processes, with
headroom for migrations and operations; a health check must not exhaust the pool.

For PostgreSQL, choose values per application role/session or transaction rather
than copying global `ALTER SYSTEM` settings:

| Setting | Boundary |
|---|---|
| `statement_timeout` | Time executing a statement, including waits |
| `lock_timeout` | Time waiting for each lock acquisition; normally shorter than the statement budget |
| `idle_in_transaction_session_timeout` | Idle time with an open transaction; termination releases resources but is not application cleanup |

Reset session settings when returning pooled connections, or use appropriate
transaction-local settings. A restart-only server parameter such as
`max_connections` is not applied by `pg_reload_conf()` alone. See [PostgreSQL
timeouts](https://www.postgresql.org/docs/current/runtime-config-client.html)
and [connection settings](https://www.postgresql.org/docs/current/runtime-config-connection.html).

A database-backed queue can claim rows with `FOR UPDATE SKIP LOCKED` inside a short
transaction, then commit the claim before external work. The query alone is not a
durable job protocol: specify lease expiry/reclaim, ownership checks on completion,
attempt limits, duplicates and terminal failure. `SKIP LOCKED` deliberately gives
an inconsistent view and skips row locks only; use it for queue consumers, not
general business reads or an assumed guarantee of global FIFO order. See
[PostgreSQL locking clauses](https://www.postgresql.org/docs/current/sql-select.html#SQL-FOR-UPDATE-SHARE).

## Configuration is parsed input, not a module full of globals

Choose and document precedence, e.g. defaults < TOML file < environment < explicit
CLI options. Parse at startup, validate ranges and combinations, then pass a
settings value. Do not read the environment afresh in each business function or
contact a secret manager from a property getter. Missing required credentials
must fail clearly rather than select a development default in production.

Stdlib example: real TOML parsing plus explicit environment override semantics.
It accepts only its documented server keys, distinguishes `"false"` from truthy
nonempty strings and rejects invalid ports. The input environment is supplied so
tests do not mutate process-global state; the entry point can pass `os.environ`.

```pycon
>>> import tomllib
>>> from dataclasses import dataclass
>>> @dataclass(frozen=True)
... class Settings:
...     port: int
...     debug: bool
>>> def load_settings(text, environ):
...     document = tomllib.loads(text)
...     if set(document) - {"server"}:
...         raise ValueError("unknown configuration section")
...     server = document.get("server", {})
...     if not isinstance(server, dict) or set(server) - {"port", "debug"}:
...         raise ValueError("invalid server configuration")
...     port = server.get("port", 8000)
...     debug = server.get("debug", False)
...     if "APP_PORT" in environ:
...         try:
...             port = int(environ["APP_PORT"])
...         except ValueError:
...             raise ValueError("APP_PORT must be an integer") from None
...     if "APP_DEBUG" in environ:
...         raw = environ["APP_DEBUG"].strip().lower()
...         if raw not in {"true", "false"}:
...             raise ValueError("APP_DEBUG must be true or false")
...         debug = raw == "true"
...     if type(port) is not int or not 1 <= port <= 65535:
...         raise ValueError("port must be in 1..65535")
...     if type(debug) is not bool:
...         raise ValueError("debug must be a boolean")
...     return Settings(port, debug)
>>> config = '[server]\nport = 9000\ndebug = true\n'
>>> assert load_settings(config, {"APP_DEBUG": "false"}) == Settings(9000, False)
>>> assert load_settings(config, {"APP_PORT": "8080"}) == Settings(8080, True)
>>> for text, environment in [(config, {"APP_PORT": "0"}), (config, {"APP_DEBUG": "yes"}), ('[server]\nport = true', {})]:
...     try:
...         load_settings(text, environment)
...     except ValueError:
...         pass
...     else:
...         raise AssertionError("invalid configuration was accepted")

```

This narrow parser is enough for two nonsecret settings; it is not a replacement
for an existing settings framework. TOML syntax errors propagate as
`tomllib.TOMLDecodeError`. `tomllib` is read-only and available since Python 3.11;
for files, use binary mode with `tomllib.load()`. Bound file/input size when it
comes from an untrusted source. Optional Pydantic Settings recipes require the
separate `pydantic-settings` package: use its version-matched configuration API,
not an unqualified mixture of Pydantic v1 and v2 examples. A cached settings
factory requires an explicit reload/secret-rotation policy; caching forever is
not a rotation mechanism.

With Pydantic Settings, mounted `secrets_dir` files and `env_nested_delimiter` are
optional input sources, not a substitute for precedence tests. Verify alias and
case-sensitivity behavior against the deployed settings version. Complex
environment values normally undergo JSON decoding before field validators;
custom CSV parsing may require `NoDecode` or a custom source. Construct settings
at the entry point and propagate a sanitized failure instead of `sys.exit()` on
module import. `SecretStr` reduces accidental display but does not encrypt data
or make extracted strings safe to log. See [settings sources and decoding](https://docs.pydantic.dev/latest/concepts/pydantic_settings/).

## Secrets and trust checklist

- Do not commit credentials or real `.env` files. Environment variables and
  mounted secret files are delivery mechanisms, not encryption. Use the platform's
  secret store and least-privilege workload identity where available; separate
  development and production credentials and define rotation/revocation.
- Do not log settings reprs, authorization headers, full connection URLs, tokens,
  raw request bodies or secret-bearing exception values. A wrapper's redacted
  repr is not protection after extracting its raw string. Prefer sanitized error
  categories and nonsecret correlation IDs.
- Validate/authorize the operation even after authenticating the caller. Restrict
  tenant/object access, writable fields, request/body sizes, URL destinations and
  file paths. An annotation or `User(**request_data)` is not an authorization or
  safe field-selection policy.
- Keep debug off in production, validate allowed hosts/trusted proxies, enforce
  HTTPS and secure cookies/CSRF protections for cookie-authenticated browser
  traffic. Reuse framework security middleware rather than building your own.
  See [Django's deployment checklist](https://docs.djangoproject.com/en/6.0/howto/deployment/checklist/)
  for concrete settings; other frameworks need equivalent explicit integration.
- Treat uploaded files and broker messages as untrusted data. Do not execute
  uploaded content or load pickle from an untrusted boundary. Keep database and
  broker access private/authenticated and grant only required privileges.

Test configuration precedence and missing/malformed values without real secrets.
Test transaction failure after an earlier write, duplicate requests and concurrent
constraint behavior against the intended database. Use disposable databases and
least-privileged credentials; a fixture must never drop arbitrary production
schemas. Rollback-based isolation does not undo commits made on other connections
or effects in an external service. Test doubles establish orchestration, not live
provider compatibility or operational recovery.
