# CLI, HTTP and lifecycle boundaries

## Contents

- [One operation, two driving adapters](#one-operation-two-driving-adapters)
- [CLI decisions](#cli-decisions)
- [HTTP decisions](#http-decisions)
- [Startup, shutdown and ownership](#startup-shutdown-and-ownership)
- [Complete small invocation](#complete-small-invocation)

## One operation, two driving adapters

The bundled program performs a real operation: count newline-delimited lines,
including an unterminated final line, in bounded input. Empty input has zero lines.
It has no fake user store, required database, background daemon or external module.

| File | Responsibility |
|---|---|
| [count.go](../examples/count.go) | Validated configuration and transport-independent `Count(ctx, reader, maxBytes)` |
| [http.go](../examples/http.go) | HTTP-to-operation translation and self-stopping loopback demonstration |
| [main.go](../examples/cmd/demo/main.go) | Argument parsing, environment loading, input-file ownership, exit/output policy |
| [examples_test.go](../examples/examples_test.go) | Named line/size/error/configuration/HTTP regressions |

The operation accepts `io.Reader` because that is its actual input capability, not
because every dependency needs an interface. It does not close a caller's reader,
log a fatal error, choose an HTTP status or inspect the environment. Count results
are integers, not `http.ResponseWriter` values. Both adapters pass failures back
to the boundary that can interpret them.

The implementation buffers at most `MaxBytes+1` input bytes plus allocation
overhead and runtime growth; it is not constant-memory streaming. The extra byte
distinguishes exact-limit success from over-limit input. Defaults cap each input
at 1 MiB; configuration accepts at most 64 MiB to keep this demonstration bounded.
Memory still scales with concurrent requests. A production service may need
admission limits or a streaming implementation based on measured workload.

## CLI decisions

- Keep a small CLI in one package until another real caller needs its operation.
  The bundled module separates it only to demonstrate a CLI and HTTP sharing code.
- Use `flag.FlagSet` with `ContinueOnError` when options are needed; a short explicit
  command switch is sufficient for `count` and `demo`. A command framework is not
  necessary just because the program has two commands.
- Pass parsed values into operations. Avoid global flags read from deep helpers.
  Use startup configuration, not repeated environment lookups during work.
- Write machine-readable results to stdout, diagnostics to stderr, and return a
  nonzero exit status on failure. `go run` may add its own `exit status 1` diagnostic.
- Open an input file at the caller that owns its lifetime. Close it before returning
  from `run`; leave borrowed stdin open. Check read, output and consequential close
  errors. An output error can occur after partial output; do not label it success.
- Keep `os.Exit`/fatal logging at the outermost `main`, after cleanup inside `run`.
  `os.Exit` does **not** run deferred functions.

`count` accepts an optional filename; missing filename or `-` means stdin. It does
not rewrite files. It is a byte/newline operation, not Unicode line-separator
recognition, CSV parsing or a universal document-format converter.

## HTTP decisions

Use `net/http` directly when routing, middleware and protocol needs fit it. The
example uses `http.NewServeMux` with `POST /count`: method-aware patterns require
Go **1.22+**; the example module's declared baseline is **1.25.0**. Do not enable
legacy `GODEBUG=httpmuxgo121=1` routing for these examples. A router framework is an
application choice, not a consequence of service size.

The handler consumes raw request-body bytes. It does not require JSON input.
Success is `200` with `Content-Type: application/json` and `{"lines":N}`. Oversize
input maps to `413`, request cancellation/deadline to `408`, and other input-read
failure to a generic `400`, without exposing the underlying error text. Method
mismatch is `405`; unknown paths are `404`. A client that already disconnected
will generally not receive the cancellation response.

Pass `r.Context()` down to context-aware operations. The HTTP server owns the
incoming request body and closes it; a handler need not retain or close it after
return. Outgoing clients instead own `response.Body` and must close it, including
non-success status paths. Read to EOF when practical for connection reuse.

For APIs that do accept structured JSON, separately define the request schema,
cap body size, decode/validate, handle unknown/trailing values by policy, authorize
the operation, and map stable domain errors to public statuses. JSON tags or a
successful `Decode` do not enforce business rules. Encode predictable response
values before headers where encoding can fail; once a response has started, a
later write failure cannot reliably change its status. The example's integer-only
response cannot produce a JSON value-encoding error; transport write errors are
logged, not followed by a misleading second response.

This local demonstration has no authentication or TLS because it binds only an
ephemeral loopback address and makes its own request. Do not repurpose it as an
internet-facing deployment without transport/security/admission policies.

## Startup, shutdown and ownership

A composition root does ordinary constructor calls in dependency order:
configuration -> resources -> concrete operation/adapters -> listener/server.
Check every error; unwind already-acquired resources on partial failure. A DI
container or global service locator makes none of this safer.

| Resource | Owner and lifetime |
|---|---|
| Parsed config | Composition root; immutable values passed to components |
| Open CLI input file | CLI invocation; closed before `run` returns |
| Borrowed stdin/reader | Caller; `Count` consumes but does not close |
| `*sql.DB` pool | Process/component that opened it; close after dependent work drains |
| `*sql.Tx` | Single operation; commit or rollback, never store for unrelated requests |
| HTTP listener/server | Composition root; stop accepting then drain/force-close by policy |
| Outgoing response body/transport | Request/owning component; close body and owned idle connections |
| Worker goroutines | Explicit owner; cancel **and join** before their dependencies close |

The [demo](../examples/http.go) binds `127.0.0.1:0`, starts `Serve`, sends one real
HTTP request with a bounded client timeout, checks its status and decoded result,
closes the response, closes idle client connections, and calls `Shutdown` with a
**fresh bounded context**. On shutdown timeout it calls `Close`; it waits for the
`Serve` goroutine and treats only `http.ErrServerClosed` as normal. Serve/startup,
request, output and shutdown errors remain failures. No manual signal is needed.

`Shutdown` does not kill arbitrary goroutines or wait for hijacked connections.
`Serve` returns as shutdown starts, before all handlers necessarily finish, so a
long-running server must wait for `Shutdown` itself, not exit merely because
`Serve` returned. WebSockets/hijacks and application workers require their own
shutdown/join contract. Close pools only after their consumers stop. For a real
service, use a signal-derived run context (e.g. `signal.NotifyContext`), handle
bind failures, stop background producers, drain within a deadline and define the
forced-shutdown outcome. Do not call fatal logging from the serving goroutine.

The configured timeouts bound server header/read/write operations and the demo's
client/shutdown. They do not set a deadline on every application operation or
preempt CPU work. `Count` checks cancellation before and after its bounded read;
`context` cannot interrupt an arbitrary blocked `io.Reader`. HTTP read deadlines
help unblock socket I/O; a file/pipe reader needs its own supported interruption
mechanism if prompt cancellation is required. A timeout does not prove that a
remote effect did not happen.

Process-local goroutines are suitable for explicitly disposable work only. Durable
work needs persistent acceptance/status, restart behavior and duplicate handling.
Do not pass a request body, transaction or soon-canceled request context into an
unowned after-response goroutine.

## Complete small invocation

This complete Go program uses the bundled module API; its only non-stdlib import
is that **local** module. The exact implementation and runnable command are
[main.go](../examples/cmd/demo/main.go) and the [README](../README.md). This snippet
illustrates the operation without the full CLI adapter; it is not another required
file to install.

```go
package main

import (
    "context"
    "fmt"
    "os"
    "strings"

    linecount "example.com/go-system-design"
)

func main() {
    lines, err := linecount.Count(context.Background(), strings.NewReader("one\ntwo"), 7)
    if err != nil {
        fmt.Fprintln(os.Stderr, err)
        os.Exit(1)
    }
    fmt.Println(lines) // 2
}
```

Sources: [HTTP server and Shutdown](https://pkg.go.dev/net/http#Server.Shutdown),
[request context](https://pkg.go.dev/net/http#Request.Context),
[response body ownership](https://pkg.go.dev/net/http#Client.Do),
[context contract](https://pkg.go.dev/context),
[Go 1.22 routing changes](https://go.dev/doc/go1.22#net/http),
[os.Exit](https://pkg.go.dev/os#Exit).
