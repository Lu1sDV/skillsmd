# Isolation and real boundaries

## Contents

- [Cleanup and parallel ownership](#cleanup-and-parallel-ownership)
- [Choose doubles deliberately](#choose-doubles-deliberately)
- [HTTP contracts](#http-contracts)
- [Files, databases, and processes](#files-databases-and-processes)
- [Deterministic concurrency and time](#deterministic-concurrency-and-time)

## Cleanup and parallel ownership

Keep mutable state owned by one test/subtest. Use real cheap domain values and
pure functions before introducing interfaces. Pass only the dependency actually
needed (`io.Reader`, `io.Writer`, a time value/function, or a narrow consumer
interface) when controlling an external boundary. Functional options can help an
existing configurable API; they are not a prerequisite for testability.

- Register `t.Cleanup` **immediately after successful acquisition**, before later
  setup can fail. Cleanups are LIFO and run after the test and all its subtests.
  Check cleanup errors when they affect the contract; don't discard database or
  file setup errors. `t.TempDir()` cleans itself up, but close opened files too.
- A parallel child pauses at `t.Parallel` until the parent function returns.
  Parent `defer resource.Close()` can therefore close the resource too soon.
  Parent `t.Cleanup(resource.Close)` (wrapped to handle errors when needed)
  runs after its children. Better still, acquire mutable resources per child.
- Go 1.22+ language semantics create a per-iteration variable for loop variables
  declared with `:=`. That does **not** deep-copy maps, slices, pointers, or
  captured service instances. Modules using older semantics need explicit
  rebinding (`tc := tc`) when closures outlive the iteration.
- `t.Setenv` and `t.Chdir` affect the whole process and are forbidden in parallel
  tests or tests with parallel ancestors. Raw `os.Setenv`/`os.Chdir` bypass the
  guard, not the hazard. Prefer an explicit configuration/path argument or a
  subprocess with its own `Cmd.Env`/`Cmd.Dir` for process-global behavior.
- No fixed `/tmp/config.json`, shared database tables, fixed ports, global seed,
  mutable package caches, or dependence on test order. Parallelize only after
  isolation is established. `-parallel` limits parallel tests, not package
  processes (`-p`) or arbitrary goroutines started by tests.
- `t.Context()` is Go 1.24+: it is canceled just before cleanup functions run,
  so cleanup can wait for a context-aware worker. Cancellation is cooperative;
  join workers and close resources. A canceled context is not proof of exit.

Use `TestMain` only for truly package-wide setup that cannot be scoped to a test.
It runs before ordinary test flag parsing, so call `flag.Parse()` if setup uses
flags. Run `m.Run()`, clean up, then `os.Exit(code)`; defers do not run when
`os.Exit` is called. Alternatively return from TestMain after cleanup and let the
test wrapper exit with m.Run's result. Do not use TestMain to make mutable shared
fixtures or order-dependent tests appear convenient.

## Choose doubles deliberately

| Choice | Use | Limitation |
|---|---|---|
| Real object | Domain rules, byte buffers, cheap in-process values | Must still isolate state |
| Dummy | Irrelevant required parameter | No behavior evidence |
| Stub | Deterministic value/error/timeout | Does not certify real API behavior |
| Fake | Small working model, such as in-memory storage | May miss uniqueness, aliasing, locking, transaction and query semantics |
| Mock | Required interaction is the contract, such as no charge after failure | Exact call-order assertions can encode implementation accidents |
| Spy | Observe an important effect while delegating to the real component | Needs its own concurrency/ownership discipline |

Prefer stdlib values and a small handwritten function/type over a mocking
framework for one fault. For example, an `io.Reader` that returns a sentinel
error can exercise your decoder's error propagation. Assert the application's
error and unchanged state, not merely that the reader was invoked.

Fakes should not quietly share pointers to mutable stored records if the real
store returns isolated values. A mutex protecting a map does not protect values
that escape it. Establish only semantics needed for the test; don't turn a fake
into a second database. Share relevant contract cases with the real adapter when
practical, and retain real integration tests for backend-specific guarantees.

## HTTP contracts

Choose the boundary explicitly:

| Tool | What it exercises | What it does not establish |
|---|---|---|
| `httptest.NewRequest` + `NewRecorder` + actual `ServeHTTP` | Handler/router, validation, status/headers/body | Socket I/O, deployment, live vendor |
| `httptest.NewServer` + real client | Loopback HTTP client/server behavior, serialization and transport errors | Production TLS/proxies, vendor schema/auth/availability |
| `httptest.NewTLSServer` + its trusted `Client()` | Local TLS path | Production trust chain/cert lifecycle |
| Explicit sandbox/live integration | Selected real external contract in a controlled environment | General correctness, availability, or production performance |

For Go 1.22+ method/path patterns, send the request through the **actual ServeMux**
if routing is under test. Manually `req.SetPathValue("id", "123")` is appropriate
only for a direct-handler test and does not verify route extraction.

Application recipe fragment (the `handler` must be your actual assembled app):

```go
req := httptest.NewRequest(http.MethodGet, "/users/123", nil)
rec := httptest.NewRecorder()
handler.ServeHTTP(rec, req)
res := rec.Result()
defer res.Body.Close()
if res.StatusCode != http.StatusOK {
    t.Fatalf("status = %d; want 200", res.StatusCode)
}
var got struct { ID string `json:"id"` }
if err := json.NewDecoder(res.Body).Decode(&got); err != nil {
    t.Fatal(err)
}
if got.ID != "123" {
    t.Errorf("ID = %q; want 123", got.ID)
}
```

Also exercise missing/invalid IDs, not-found, dependency failure mapping,
unsupported methods, and malformed JSON as relevant. Check content type and
other promised headers without asserting irrelevant header ordering. A status
alone often misses a corrupt body. Never ignore decoder errors then inspect a
zero-value object as though decoding succeeded.

Client recipe fragment (use the production client with the server URL/client):

```go
server := httptest.NewServer(actualHandler)
t.Cleanup(server.Close)
client := server.Client()
client.Timeout = 2 * time.Second // watchdog, not a completion signal
resp, err := client.Get(server.URL + "/users/123")
if err != nil {
    t.Fatal(err)
}
t.Cleanup(func() { resp.Body.Close() })
```

The final fragment only acquires resources: add assertions on decoded production
results, non-2xx handling and cancellation. A stub returning fixed JSON does not
establish that a vendor currently accepts your requests. Keep side-effecting or
credentialed integration tests explicit and separate from deterministic checks.
Never call `t.Fatal` from an HTTP server handler goroutine: record errors through
a channel, or return an HTTP failure and assert it on the test goroutine.

## Files, databases, and processes

**Filesystem:** for read-only `fs.FS` consumers, `fstest.MapFS` avoids external
state; `fstest.TestFS` checks filesystem implementation contracts. Check every
returned error. Use a fresh map per test and do not mutate it while readers run.
It does not prove permissions, symlink resolution, disk writes, or crash safety.
For OS behavior use `t.TempDir`, `filepath.Join`, `os.WriteFile`/`Open`, and the
real production adapter. Assert resulting bytes or parse the output; cover
missing/malformed/truncated input and non-creation/non-truncation on rejection
where promised. Do not rely on platform-specific permission failures when tests
might run as root; inject an I/O error at an appropriate seam instead. A mode
passed to creation is subject to umask and isn't a portable exact-mode assertion.

Filesystem recipe fragment (replace `LoadConfig` with the actual adapter):

```go
path := filepath.Join(t.TempDir(), "config.json")
if err := os.WriteFile(path, []byte(`{"limit":10}`), 0600); err != nil {
    t.Fatal(err)
}
got, err := LoadConfig(path)
if err != nil {
    t.Fatal(err)
}
if got.Limit != 10 {
    t.Errorf("limit = %d; want 10", got.Limit)
}
```

**Database:** real engine/driver tests are needed for SQL, uniqueness, isolation,
rollback and locking. `database/sql` has no built-in driver; do not present a
Postgres recipe as dependency-free. Use a test-owned database/schema or
transaction only when every operation truly shares it. Cleanup must never
`DROP` a common user table. Rollback cannot undo commits on other connections.
Verify stored rows and rejected-operation non-effects; a fake's returned struct
is not persistence evidence. Check that failures leave state consistent when a
save precedes an external payment; mocks cannot make the sequence atomic.

**CLI:** build the intended binary and execute it with `exec.CommandContext` in
a test-owned directory/environment. Assert exit status, stdout data, stderr
diagnostics, and generated files. Use a real subprocess when testing os.Exit or
process globals; do not change the testing process's directory/environment in
parallel. A watchdog limits the command, but child-process-tree cleanup needs
platform-aware handling. Record missing services/tooling as unperformed or
skipped integration checks, not a successful test of the requested boundary.

## Deterministic concurrency and time

For pure expiry decisions, pass explicit `now` and deadline values; an interface
hierarchy is unnecessary for one time comparison. Choose the equality contract
explicitly and test deadline-1ns, deadline, deadline+1ns. For actual timer/channel
behavior use joins/channels, or stable Go 1.25 `testing/synctest`.

[The complete runnable deadline recipe](../examples/synctest_test.go) checks
`context.WithTimeout` immediately before and exactly at its deadline. This tests
the standard API and illustrates the technique; it is **not** application
coverage for Budget. Its essential shape is:

```go
package budget_test

import (
    "context"
    "testing"
    "testing/synctest"
    "time"
)

func TestTimeoutBoundary(t *testing.T) {
    synctest.Test(t, func(t *testing.T) {
        ctx, cancel := context.WithTimeout(t.Context(), 5*time.Second)
        defer cancel()
        time.Sleep(5*time.Second - time.Nanosecond)
        synctest.Wait()
        if err := ctx.Err(); err != nil {
            t.Fatalf("before deadline: %v", err)
        }
        time.Sleep(time.Nanosecond)
        synctest.Wait()
        if err := ctx.Err(); err != context.DeadlineExceeded {
            t.Fatalf("at deadline: %v; want deadline exceeded", err)
        }
    })
}
```

This is a complete additional `_test.go` recipe for a disposable examples copy.
No `GOEXPERIMENT` flag is needed on Go 1.25+. The upstream `synctest.Run`
examples describe the older experimental Go 1.24 interface, not the stable API.

A bubble includes its root and goroutines it starts. Fake time advances when
all are durably blocked and no `Wait` call can return; `Wait` itself waits for
other bubble goroutines to be durably blocked **without advancing time**.
It is not “run every timer now.” The sleeps above advance virtual time;
`Wait` ensures the deadline callback settles before the assertions.

Only supported operations are durably blocking (not every mutex or syscall).
Real sockets, filesystem I/O, and external goroutines are not controlled by the
bubble's fake time. Do not put an `httptest.NewServer` loopback test in a bubble
and assume virtual time makes the network deterministic. Keep bubble channels,
timers, and participating synchronization local to the bubble. Synctest waits
for child goroutines to exit and detects bubble deadlocks; it does not exhaust
possible schedules or replace `-race`, correct synchronization, cancellation,
and explicit worker lifetime assertions.
