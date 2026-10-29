# Transactions and startup configuration

## Contents

- [Configuration is a startup boundary](#configuration-is-a-startup-boundary)
- [Pool, transaction and context identity](#pool-transaction-and-context-identity)
- [Complete transfer function for an existing PostgreSQL application](#complete-transfer-function-for-an-existing-postgresql-application)
- [Concurrency, external effects and evidence](#concurrency-external-effects-and-evidence)

## Configuration is a startup boundary

Parse once into a concrete struct, validate it, then pass the values to components.
Do not scatter `os.Getenv` calls throughout handlers or perform network/database
I/O in package initialization. Document defaults, precedence, units, empty-value
semantics and required fields. A sensible policy is defaults < file < environment
< explicit flags; that is a policy to implement, not something Go applies for you.
Use `os.LookupEnv` if unset and explicitly empty have different meanings.

The [complete config implementation](../examples/count.go) accepts defaults plus
nonempty environment overrides; it has **no** file or flag override layer:

| Setting | Default | Validation and interpretation |
|---|---|---|
| `LINECOUNT_MAX_BYTES` | `1048576` | Decimal integer, inclusive range 1..67108864 |
| `LINECOUNT_TIMEOUT` | `3s` | `time.ParseDuration`, strictly positive; server/client/shutdown timeout |
| Empty/missing setting | Default | Intentional identical meaning in this demo |

Malformed or out-of-range input fails startup rather than silently falling back.
`Config.Validate` also protects programmatic constructor callers. The operation
validates its own byte limit because it is callable without a `Config` object.
A timeout setting is not an implicit context deadline: pass or derive deadlines
where the actual operation supports cancellation.

Secrets need a source/rotation/permission policy, not a mandatory configuration
framework. Avoid logging DSNs, passwords, raw tokens, entire settings structs or
unredacted remote errors. Config templates should contain names/placeholders, not
real credentials. Parse booleans with `strconv.ParseBool`, never `value != ""`.
For reloadable configuration, validate a complete replacement and define resource
replacement/drain behavior; do not mutate shared fields piecemeal during requests.

## Pool, transaction and context identity

`*sql.DB` is a concurrency-safe pool handle, not one connection and not one
transaction. `sql.Open` can succeed without reaching the server: call
`PingContext` with a startup deadline if readiness requires a live database.
Select a real driver explicitly; the standard library does **not** bundle a
PostgreSQL or SQLite driver. Close the pool at its composition root after its
consumers stop, not after each query. Size pools against replicas/workers and the
server's connection budget; each process has its own pools.

One application operation owns `BeginTx`, `Commit` and rollback policy. Every
statement that must be atomic must use that exact `*sql.Tx`. Calling
`db.ExecContext` in the middle of an operation that has begun a transaction uses
the pool, **not** that transaction. Two repository objects holding the same `*sql.DB`
do not automatically share a transaction. If helpers are necessary, pass `*sql.Tx`
explicitly or bind them to it; a narrow query/exec capability can serve both pool
and transaction only when the caller deliberately selects the right one.

A context is cancellation/deadline/request metadata, not a transaction or dependency
registry. Do not hide transactions in context values or store a request context
inside a process-lived repository. Forward the operation context to `BeginTx`,
`ExecContext`, `QueryContext`, and `QueryRowContext`. The context passed to `BeginTx`
is used until commit/rollback; cancellation causes `database/sql` to roll it back,
and `Commit` will fail. Driver behavior still matters for timely interruption and
error classification. Check errors with `errors.Is` when wrapping may occur; do
not reinterpret every error as not-found.

Always release query rows, check `rows.Err()` after iteration, and remember that
`QueryRowContext` reports query/not-found errors on `Scan`. `Close` is cleanup,
not commit. A deferred rollback is normal after successful commit and returns
`sql.ErrTxDone`; unexpected rollback errors need to remain visible. A failed
commit is a failed operation result, but some connection failures leave the
server-side outcome uncertain: reporting failure does not prove rollback.

Sources: [sql.DB](https://pkg.go.dev/database/sql#DB),
[BeginTx](https://pkg.go.dev/database/sql#DB.BeginTx),
[transaction operations](https://go.dev/doc/database/execute-transactions),
[querying](https://go.dev/doc/database/querying).

## Complete transfer function for an existing PostgreSQL application

This is a complete Go source file for integration into an application that already
uses a PostgreSQL driver and migrations. It is **not** the stdlib-only runnable
demo and has not been executed here. Preconditions: authorized caller; all accounts
use the same currency/scale; table `accounts(id text PRIMARY KEY, balance bigint
NOT NULL CHECK (balance >= 0))`; supported read-committed transactions. No global
store, fake implementation, retry loop or transaction-in-context is involved.

```go
package bank

import (
    "context"
    "database/sql"
    "errors"
    "fmt"
)

var ErrInsufficient = errors.New("source missing or insufficient funds")
var ErrDestinationMissing = errors.New("destination missing")

func Transfer(ctx context.Context, db *sql.DB, from, to string, cents int64) (err error) {
    if from == "" || to == "" || from == to || cents <= 0 {
        return errors.New("distinct account IDs and positive cents are required")
    }
    tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
    if err != nil {
        return fmt.Errorf("begin transfer: %w", err)
    }
    defer func() {
        rollbackErr := tx.Rollback()
        if rollbackErr != nil && !errors.Is(rollbackErr, sql.ErrTxDone) {
            err = errors.Join(err, fmt.Errorf("rollback transfer: %w", rollbackErr))
        }
    }()

    debit, err := tx.ExecContext(ctx,
        `UPDATE accounts SET balance = balance - $1 WHERE id = $2 AND balance >= $1`,
        cents, from)
    if err != nil {
        return fmt.Errorf("debit: %w", err)
    }
    affected, err := debit.RowsAffected()
    if err != nil {
        return fmt.Errorf("debit row count: %w", err)
    }
    if affected != 1 {
        return ErrInsufficient
    }

    credit, err := tx.ExecContext(ctx,
        `UPDATE accounts SET balance = balance + $1 WHERE id = $2`, cents, to)
    if err != nil {
        return fmt.Errorf("credit: %w", err)
    }
    affected, err = credit.RowsAffected()
    if err != nil {
        return fmt.Errorf("credit row count: %w", err)
    }
    if affected != 1 {
        return ErrDestinationMissing
    }
    if err := tx.Commit(); err != nil {
        return fmt.Errorf("commit transfer: %w", err)
    }
    return nil
}
```

The primary key makes each affected-row expectation meaningful. The conditional
SQL debit, not a separate balance read, enforces sufficient funds under concurrent
PostgreSQL read-committed updates. PostgreSQL's checked `bigint` arithmetic rejects
credit overflow, causing the debit to roll back too. Opposite-direction transfers
can deadlock; the database aborts one, and this function returns the error. For a
real workload choose a consistent lock order or an explicitly bounded retry
policy after classifying safe-to-retry database failures. Do not blindly retry
unknown commit outcomes: this function has no persisted transfer ID or duplicate
suppression contract.

## Concurrency, external effects and evidence

A check-then-insert does not enforce uniqueness under races. Use a database unique
constraint and translate its driver-specific error. Aggregate validation likewise
needs constraints, row locks or a version predicate and affected-row check to
prevent concurrent invariant violations. Transactions and their isolation levels
do not automatically include another connection, cache, process or broker.

Do not ignore event/cache errors after saving data. Decide whether failure is
best-effort, a returned partial/unknown outcome, or part of a durable workflow.
Publishing only after commit avoids rolled-back notifications but leaves a crash
gap. Where loss is unacceptable, record an outbox event in the **same** database
transaction as the mutation and deliver it separately with stable identity and
consumer duplicate handling. Outbox delivery is not magical exactly-once remote
effects; remote timeouts can leave an unknown result.

For the transfer integration, use the actual driver and production database engine
in a disposable schema. Check successful debit/credit from another connection;
missing destination rolling back an already-performed debit; insufficient funds;
credit overflow; concurrent debits; canceled transaction; and commit/connection
failure semantics. Reset fixtures without changing production state. In-memory
stores or SQL mocks can check call expectations, not engine isolation or rollback.

The bundled tests instead cover the real boundaries they own: line/byte limits,
wrapped reader errors, cancellation before/during reads, config validation, and
HTTP status/body translation. Its self-stopping HTTP invocation exercises a real
local socket. None provides database, broker, deployment, durability, authentication
or load evidence. Exact commands and expected behavior are in [README](../README.md).
