# Time and networking

## Contents

- [Time and clocks](#time-and-clocks)
- [Timers and cancellation](#timers-and-cancellation)
- [HTTP clients](#http-clients)
- [HTTP servers](#http-servers)
- [URLs and sockets](#urls-and-sockets)

## Time and clocks

Go layouts describe the reference instant `Mon Jan 2 15:04:05 MST 2006`, not
strftime directives. Prefer named constants (`time.RFC3339`, `time.DateOnly`) for
wire formats. `2006-01-02` is a date, `15:04:05` a 24-hour clock, and `Z07:00`
a UTC-or-numeric-offset zone. Preserve precision and zone requirements explicitly.

| Need | API | Important distinction |
|---|---|---|
| Parse a wire timestamp | `time.Parse(time.RFC3339, s)` | Check error; a timestamp offset is not a geographical zone |
| Parse a local civil time | `ParseInLocation(layout, s, loc)` | Load/check the location; DST gaps/ambiguities need a domain policy |
| Measure elapsed duration | `start := time.Now(); time.Since(start)` | Uses monotonic data when available |
| Advance an elapsed interval | `t.Add(d)` | 24 hours is not always one local calendar day |
| Advance calendar fields | `t.AddDate(y, m, d)` | Normalizes invalid dates; month arithmetic is not end-of-month clamping |
| Compare instants | `Before`, `After`, `Equal` | `==` also compares location/monotonic representation |
| Parse a duration | `time.ParseDuration(s)` | Units through hours; no calendar month/day unit |
| Numeric timestamp | `Unix`, `UnixMilli`, `UnixNano` | Units and representable ranges matter |

`time.Duration` is an `int64` nanosecond count; multiplications/conversions can
overflow. `time.Time` serialized through JSON/text loses monotonic data. Location
loading can fail on systems without zoneinfo; packaging `time/tzdata` is an explicit
binary-size/deployment decision. Truncation rounds relative to an absolute origin,
not necessarily a local civil-hour boundary. Do not silently replace a timezone
loading failure with UTC if it changes the requested meaning.

## Timers and cancellation

- `NewTimer` sends once; `NewTicker` repeats and may drop ticks for slow consumers.
  Ticker duration must be positive. Stop a ticker when its activity should end,
  but `Stop` does **not close its channel**: a `range ticker.C` will not exit merely
  because another goroutine stopped it. Select on a separate cancellation signal.
- Go 1.23's channel-timer semantics prevent stale values after `Stop`/`Reset` and
  permit collecting unreferenced timers/tickers. They depend on the main module's
  Go version and `GODEBUG=asynctimerchan`; do not blindly transplant a drain recipe
  from older code. A goroutine still retaining a timer/channel is another matter.
- `time.AfterFunc` invokes a callback in its own goroutine. `Stop` does not wait
  for an already-running callback; synchronize shared state and completion.
- Pass `context.Context` first, propagate the caller's value, and call each derived
  cancel function. Cancellation requests cooperation; it neither kills arbitrary
  computation nor joins spawned goroutines. Use context-aware APIs or explicit
  socket deadlines/closure for blocking operations.
- `WithCancelCause` (1.20) preserves a cancellation cause; `ctx.Err` still returns
  the standard canceled/deadline status. Keep application errors distinct.
- Context values are request-scoped metadata, not optional arguments or a service
  locator. Use private comparable key types and checked assertions to avoid key
  collisions/panics; copying a context does not make its mutable values safe.
- `WithoutCancel` (1.21) drops parent deadline and cancellation, and its `Done`
  channel is nil. Detached cleanup needs its own bounded context and owner.
  `context.AfterFunc` (1.21) runs on cancellation; its stop function does not join
  a callback that already started.

Complete function fragment (imports `context`, `fmt`, `time`; callback must cooperate):

```go
func every(ctx context.Context, period time.Duration, work func(context.Context) error) error {
    if period <= 0 {
        return fmt.Errorf("period must be positive")
    }
    ticker := time.NewTicker(period)
    defer ticker.Stop()
    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        case <-ticker.C:
            if err := ctx.Err(); err != nil {
                return err
            }
            if err := work(ctx); err != nil {
                return err
            }
        }
    }
}
```

This fragment also imports `fmt`. Cancellation can race with the callback start;
there is no guarantee that zero work starts after an arbitrary cancellation instant.
It serializes callbacks, coalescing/dropping ticks rather than creating unbounded
work. **go-concurrency** owns worker limits, joining and pipeline lifetime design;
**go-tdd** owns stable Go 1.25 `synctest.Test`, not the earlier experimental `Run`.

## HTTP clients

Reuse `*http.Client` and its transport; they are designed for concurrent reuse.
Configure timeout policy rather than relying on `http.Get`'s default client with
no overall timeout. `Client.Timeout` includes redirects and body reading; a
request context can impose a narrower operation deadline. Streaming protocols may
need separate connection/header/idle policies instead of a single short timeout.

Complete function fragment (imports `context`, `fmt`, `io`, `net/http`):

```go
func fetchSmall(ctx context.Context, client *http.Client, endpoint string) ([]byte, error) {
    req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
    if err != nil {
        return nil, err
    }
    resp, err := client.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    if resp.StatusCode != http.StatusOK {
        return nil, fmt.Errorf("unexpected HTTP status %d", resp.StatusCode)
    }
    const limit = 4096
    data, err := io.ReadAll(io.LimitReader(resp.Body, limit+1))
    if err != nil {
        return nil, err
    }
    if len(data) > limit {
        return nil, fmt.Errorf("response exceeds %d bytes", limit)
    }
    return data, nil
}
```

Assumptions: a non-nil configured client and an already-authorized endpoint. It
intentionally closes non-OK/oversized bodies without unbounded draining; HTTP/1
connection reuse may be lost. Closing is required on success too. Reading to EOF
and closing normally enables reuse, but do not spend unlimited resources merely
to preserve a connection. Non-2xx status is not a `Do` error. `Content-Length`
is not a trusted substitute for limiting actual bytes read.

Use typed request bodies and check encoding errors before sending. Never log auth
headers or whole response bodies by default. A tee logs only the bytes actually
read (possibly decoder read-ahead), not necessarily the complete response.
Redirects, DNS resolution and allowed schemes/hosts are part of an untrusted-URL
policy; successful `url.Parse` is not permission to send a request. Preserve TLS
verification and the chosen proxy policy.

## HTTP servers

ServeMux method/path patterns (`"GET /users/{id}"`, `r.PathValue("id")`) need Go
1.22+. A `GET` pattern also matches `HEAD`; patterns without a method accept all
methods. A trailing slash expresses a subtree; `{$}` anchors the end. Conflicting
patterns panic during registration. Path parameters are decoded strings: validate
their domain meaning and authorization before database/filesystem use.

- Use a dedicated mux and `http.Server` with justified `ReadHeaderTimeout`, body
  limits, idle and write policies. Whole-request read/write timeouts interact with
  uploads and streaming; do not copy an arbitrary blanket value.
- `r.Context()` carries disconnect/shutdown-related request lifetime information;
  derive operation deadlines from it rather than creating `Background` in handlers.
- For untrusted bodies, use `http.MaxBytesReader(w, r.Body, max)` and check decode
  errors. Do not rely on `Content-Length`. The server owns incoming-body closure.
- Set headers before `WriteHeader`/`Write`. First body write implies 200 if no
  status was sent. Do not try to emit a replacement JSON error after partial output.
  Return generic client errors; log internal causes without secrets.
- Middleware order changes authentication/logging/recovery behavior. Wrapping
  `ResponseWriter` may hide optional interfaces; preserve capabilities intentionally.
  Go 1.20+ `ResponseController` can unwrap wrappers exposing `Unwrap`, but this does
  not make direct assertions of `http.Flusher`/`http.Hijacker` succeed automatically.
- Check `ListenAndServe`/`Serve` results; `http.ErrServerClosed` is expected during
  shutdown. `Shutdown` stops accepting and waits for active ordinary HTTP requests
  within its context, not hijacked connections or arbitrary background tasks.
  Main must wait for shutdown to finish. **go-system-design** owns full lifecycle.

## URLs and sockets

`url.URL` separates scheme, authority, escaped path and query. Use `Hostname()` and
`Port()` rather than splitting host on `:`, especially for IPv6. `url.Values`
represents repeated keys; `Get` returns only the first. `Values.Encode()` sorts keys.
`URL.Query()` silently discards malformed query pairs: use `url.ParseQuery` and
check its error when malformed input must be rejected.

`QueryEscape` and `PathEscape` have different contracts (`+` means space in query
encoding). Do not decode twice or interchange them. Preserve escaped-segment
meaning when joining; a path-escaping operation is not an authorization check.

`net.Dialer.DialContext` covers dialing cancellation; later socket I/O needs its
own deadlines/ownership. `SetDeadline` affects reads and writes, with a zero time
clearing the deadline. TCP is a byte stream, not a message boundary: use explicit
framing and the Reader/Writer rules. `net.Conn` permits concurrent method calls,
not unsynchronized mutation of caller buffers.

Servers need a bound on active connections/work and a shutdown owner. When
`Accept` returns after a listener is closed, exit rather than spinning on errors;
classify other errors before deciding on a retry. UDP datagrams can be truncated
by a short receive buffer and do not gain TCP delivery/ordering guarantees.
Use `net.Resolver` context-aware methods where cancellation matters. Prefer
`net/netip` for comparable parsed addresses; DNS names/addresses still need policy.

## Primary references

[time](https://pkg.go.dev/time), [Go 1.23 timer semantics](https://go.dev/wiki/Go123Timer),
[context](https://pkg.go.dev/context), [net/http](https://pkg.go.dev/net/http),
[net/url](https://pkg.go.dev/net/url), [net](https://pkg.go.dev/net),
[net/netip](https://pkg.go.dev/net/netip).
