# Composition, wrapping, and access policies

## Task selection

| Need | Pattern and smallest Go shape | Cost / when NOT needed |
|---|---|---|
| An existing API has different names or representation | **Adapter**: function or explicit wrapper; `http.HandlerFunc` adapts a function | Mapping must preserve errors, counts, units and ownership. No wrapper when the existing type already satisfies the consumer's interface. |
| Two genuinely independent axes vary | **Bridge**: compose policy and backend functions/interfaces | Additional contracts for both axes. One varying algorithm is a strategy, not a reason for two hierarchies. |
| Leaves and groups share recursive operations | **Composite**: common operation plus children on groups | Traversal, cycle and depth policy. A slice suffices for flat collections. |
| Add a cross-cutting operation without changing the core | **Decorator**: wrap the same narrow interface | Wrapper order and optional capabilities become observable. Use `io.LimitReader`, `bufio.Reader`, `gzip.Reader` instead of rebuilding them. |
| Callers need one cohesive multi-step operation | **Facade**: ordinary function or small service | Hides sequencing, not partial failures. Skip a facade that merely renames every subsystem method. |
| Many instances repeat substantial immutable data | **Flyweight**: intern shared state, keep position/request data outside | Retention, synchronization and immutability discipline. Do not intern tiny values without evidence of benefit. |
| Delay, authorize, cache or remotely forward access | **Proxy**: same operation with explicit policy | Freshness, denial, initialization, context and failure semantics. Direct calls are preferable without an actual policy requirement. |

Contents: [adapters and Readers](#adapters-and-readers), [HTTP wrappers](#http-decorators-preserve-capabilities), [bridge](#bridge-independent-axes), [composite](#composite-trees-not-arbitrary-graphs), [facade](#facade-error-and-resource-ownership), [flyweight](#flyweight-shared-state-must-stay-immutable), [proxy](#proxy-cache-and-initialization-contracts), [API shape](#accept-small-contracts-return-useful-types).

The distinctions are intent, not a mandate for seven layers. An adapter changes
an interface; a decorator adds behavior; a proxy controls access; a facade
combines a workflow. The same concrete wrapper can serve more than one intent.
All examples here use the standard library; runnable bundle samples require Go
1.25. `sync.OnceValues` needs Go 1.21; `http.ResponseController` needs Go 1.20.

## Adapters and Readers

`http.HandlerFunc(f)` adapts an ordinary function to `http.Handler`. For a vendor
storage client, an explicit wrapper can bind the bucket and translate
`PutObject(bucket, key, body)` into the consumer's `Store(key, body)` method.
Do not embed a client merely to expose its entire API. Translate errors only when
the target contract requires it; retain causes with `%w` when adding context.
For XML, decode into real tagged fields or implement `UnmarshalXML`; a
`map[string]any` field is not an arbitrary-XML decoder. Changing serialization
also requires a specified schema, not just matching method names.

A reader decorator must count and return the actual `n`, even when `err != nil`.
The caller processes `p[:n]` **before** deciding what to do with the error. A
single read may return data and `io.EOF` together, or data and another error.
Do not turn those bytes into `(0, err)` or clear the error to make a wrapper look
successful. `Read` is not required to fill its buffer. For writers, a short write
must have a non-nil error; forward `(n, err)` and use `io.ErrShortWrite` if building
an adapter around a weaker full-write promise.

Complete standalone program; the function type is an adapter, the counter a
decorator. It prints `3 3 true` without discarding data returned with EOF:

```go
package main

import (
    "fmt"
    "io"
)

type readFunc func([]byte) (int, error)

func (f readFunc) Read(p []byte) (int, error) { return f(p) }

type CountingReader struct {
    source io.Reader
    Bytes  int64
}

func (r *CountingReader) Read(p []byte) (int, error) {
    n, err := r.source.Read(p)
    r.Bytes += int64(n)
    return n, err
}

func main() {
    remaining := "abc"
    source := readFunc(func(p []byte) (int, error) {
        n := copy(p, remaining)
        remaining = remaining[n:]
        if remaining == "" {
            return n, io.EOF
        }
        return n, nil
    })
    counted := &CountingReader{source: source}
    data, err := io.ReadAll(counted)
    fmt.Println(len(data), counted.Bytes, err == nil)
}
```

This counter is single-owner, like many readers; a mutex on the count alone
would not make an unsafe underlying reader concurrently usable. It borrows the
reader and does not claim to close it. Add `io.Closer` only when the wrapper owns
that responsibility. Embedding `io.Reader` does not automatically preserve
`io.Seeker`, `io.WriterTo`, `io.ReaderAt`, or other methods of its dynamic value.
`io.Copy` may choose optional fast paths: a forwarded `WriterTo` that bypasses
`Read` can also bypass accounting. Test the operations the wrapper advertises.

Decorator order matters: `LimitReader(CountingReader(file), n)` counts bytes
through the limit; counting outside a decompressor counts decompressed bytes,
inside counts compressed bytes. Close a successfully created `gzip.Reader` and
its owned file separately; closing the gzip reader does not close that file.
Handle open/decompression/read errors; never slice `data[:100]` without checking
its length. Limiting the output also does not prove gzip checksum validation:
that requires consuming the decompressor through EOF.

## HTTP decorators preserve capabilities

Prefer passing the original `http.ResponseWriter` through if a wrapper is not
needed. A timing middleware can log around `next.ServeHTTP(w, r)` without
replacing `w`. If capturing status/bytes, the contract is larger than adding a
`WriteHeader` method:

- The first final status wins; a first `Write` implies status 200. Forward 1xx
  informational responses without treating them as the final response (101 has
  protocol-upgrade semantics). Repeated final `WriteHeader` calls must not change
  the recorded final status. Also account for implicit commitment through
  supported streaming operations, not only ordinary `Write` calls.
- Embedding an `http.ResponseWriter` exposes only its declared methods, not the
  dynamic writer's `http.Flusher`, `http.Hijacker`, `http.Pusher` or `io.ReaderFrom`
  capabilities. Never add unconditional stub methods that falsely claim support.
  A wrapper advertised as transparent must preserve the actual supported set,
  and keep metrics correct on every forwarded fast path.
- A wrapper's `Unwrap() http.ResponseWriter` lets `http.NewResponseController`
  traverse to supported controls. It does **not** make a direct assertion such
  as `w.(http.Flusher)` succeed, and it does not preserve every optional method.
  Operations that unwrap may bypass the wrapper's accounting unless designed
  together. For a small closed application, document the narrower capability
  contract instead of claiming universal transparency.
- Use capability-specific wrappers or an established, audited wrapper when the
  application needs direct optional-interface compatibility. Test streaming,
  upgrade and `io.Copy` paths, not only `httptest.ResponseRecorder` basic writes.
- Authentication must stop the chain after denial; authorize before returning
  cached protected data. Recovery cannot retract a committed response or convert
  a partially streamed success into a clean 500. Do not write a second error body
  blindly after headers/body have been sent.

A metrics wrapper is not a reason to implement a home-grown HTTP framework.
See [chain ordering](behavior-patterns.md#chain-strategy-and-template-control-flow)
for the same ordering problem expressed as behavior.

## Bridge: independent axes

For a document, *what to render* and *where/how to encode* can vary separately.
Compose these functions instead of defining an HTMLUrgentEmailReport for every
combination. This is also ordinary dependency injection; no bridge base class
is required.

Complete package declarations; the caller supplies real rendering and output:

```go
package composition

import (
    "fmt"
    "io"
)

type Render func(string) ([]byte, error)

func Publish(w io.Writer, render Render, text string) error {
    body, err := render(text)
    if err != nil {
        return fmt.Errorf("render: %w", err)
    }
    n, err := w.Write(body)
    if err == nil && n != len(body) {
        err = io.ErrShortWrite
    }
    if err != nil {
        return fmt.Errorf("publish: %w", err)
    }
    return nil
}
```

Preconditions: non-nil writer and renderer. A write can partially succeed, so an
error does not imply no output. Use `encoding/json` for JSON, `html/template` for
HTML with contextual escaping, and validate link schemes where applicable;
`fmt.Sprintf` does not safely escape arbitrary JSON/HTML/Markdown. A scheduled
notification bridge should submit to a lifecycle-owned scheduler, not block a
request goroutine in `time.Sleep` until a future delivery time. Actual scheduling
belongs in `go-concurrency` when installed; this reference retains only the policy
versus transport boundary.

## Composite: trees, not arbitrary graphs

A directory and file can share `Size() int64`; only the directory needs `Add`.
A menu item and submenu can share rendering/activation without making a leaf
implement meaningless child-management operations. The type names are not the
pattern: recursive uniform behavior is.

Fragment (imports/package omitted), for a trusted, acyclic, non-nil tree whose
aggregate fits in `int64`:

```go
type Node interface { Size() int64 }
type File struct { Bytes int64 }
func (f File) Size() int64 { return f.Bytes }
type Directory struct { Children []Node }
func (d Directory) Size() int64 {
    var total int64
    for _, child := range d.Children {
        total += child.Size()
    }
    return total
}
```

For public construction, validate nonnegative sizes and define nil handling,
child ownership and whether a child may have multiple parents. For an externally
supplied graph, prohibit/detect cycles and choose whether a shared descendant is
counted per occurrence or once. A checked traversal needs an error-bearing
operation, not a `Size()` that silently ignores invalid input or overflow. Avoid
unbounded recursion for untrusted depth; use an explicit stack and limits. A
full size traversal is O(nodes + edges); repeatedly calling it for every printed
directory can become quadratic on a chain. Compute once per traversal when needed,
rather than introducing cache invalidation into every node speculatively.

## Facade: error and resource ownership

A facade owns orchestration, not fictitious success. For welcome email, validate
the address, render the template, connect/authenticate/send, and close resources
owned by this call. Report stage-specific errors without credentials or message
secrets. Do not replace SMTP with a print statement returning nil. A migration
facade must execute both schema change and version record through the **same**
transaction where the database permits transactional DDL; recording the version
on a separate pooled connection is not atomic. Check commit errors; define
rollback/partial-completion behavior explicitly.

A small real facade is enough. Complete package declarations; this marshals then
compresses without claiming encryption or authentication:

```go
package composition

import (
    "bytes"
    "compress/gzip"
    "encoding/json"
    "errors"
)

func PackJSON(value any) ([]byte, error) {
    payload, err := json.Marshal(value)
    if err != nil {
        return nil, err
    }
    var out bytes.Buffer
    zipped := gzip.NewWriter(&out)
    _, writeErr := zipped.Write(payload)
    closeErr := zipped.Close()
    if err := errors.Join(writeErr, closeErr); err != nil {
        return nil, err
    }
    return out.Bytes(), nil
}
```

`Close` finishes the gzip stream and may report an error. The buffer is owned by
this operation and only exposed after completion. For a borrowed file/network
writer, clarify who closes it and which partial bytes survive. Returning a
single error does not make a multi-service workflow transactional.

## Flyweight: shared state must stay immutable

Keep intrinsic data (font family, size, color; decoded icon pixels) in shared
objects, and extrinsic data (character value, coordinates, request selection)
per instance. A mutex protecting a map does **not** protect later mutation of
an object returned from that map. Use unexported immutable fields and read-only
methods or copy values when ownership transfers. `image.Image` is only a read
interface; its dynamic value might still be a mutable `*image.RGBA` held elsewhere.

Fragment (requires `import "sync"`); scoped to one document, with no mutation of
returned styles and no copying of the factory after use:

```go
type styleKey struct {
    family, color string
    size          int
    bold, italic  bool
}
type style struct { key styleKey }
type styleFactory struct {
    mu     sync.Mutex
    styles map[styleKey]*style
}
func (f *styleFactory) intern(key styleKey) *style {
    f.mu.Lock()
    defer f.mu.Unlock()
    if old := f.styles[key]; old != nil {
        return old
    }
    if f.styles == nil {
        f.styles = make(map[styleKey]*style)
    }
    value := &style{key: key}
    f.styles[key] = value
    return value
}
```

A typed comparable key avoids formatting/escaping collisions and omissions when
adding style fields. Validate font size/color at the construction boundary. A
per-document factory has the document's lifetime; an unbounded process-global
intern table retains every distinct style forever. Measure memory including map,
pointer, allocation and per-instance overhead instead of claiming savings from
`(instances - styles) * sizeof(style)` alone.

`sync.Map.LoadOrStore` atomically chooses the stored object, not the preceding
load: two concurrent misses can both decode an icon and discard one result.
That is safe only if duplicate work/effects are acceptable, discarded resources
are released, and the loader itself is concurrency-safe. Prefer an ordinary typed
map with a mutex until `sync.Map`'s workload fits. Single-flight loading needs an
explicit in-flight/result policy; it does not arise from choosing a concurrent map.

## Proxy: cache and initialization contracts

| Proxy intent | Contract to decide before wrapping |
|---|---|
| Virtual/lazy | First-load failure cached forever or retryable? Who initializes/closes? Can calls race? |
| Protection | Authenticate caller and authorize the requested object/action before effects; return typed errors, not denial text as valid content. Do not expose a bypass to untrusted callers. |
| Caching | Complete key, TTL/freshness, invalidation, memory bound, mutable ownership, error caching and concurrent misses |
| Logging | Preserve result/error; redact tokens, credentials and personal data; record failed calls too without masking the original failure |
| Remote | Context/deadline, transport versus application error, status validation, body ownership, and duplicate-side-effect policy |

For immutable one-time configuration, `sync.OnceValues(func() (T, error))` can be
a lazy proxy. It safely publishes one result **including a failure**; it is not
a retry mechanism. A plain `if p.value == nil { p.value = load() }` races across
goroutines and often loses load errors. If load failures are retryable, coordinate
in-flight calls explicitly and decide whether waiters can cancel independently.
Never run arbitrary callbacks under a global map mutex just to avoid duplicate
loads.

Complete package declarations for a lazy, immutable text-file snapshot. Constructing
the function performs no I/O; the first call reads once, and all later calls share
that same string/error, even if the file subsequently changes:

```go
package composition

import (
    "os"
    "sync"
)

func LazyText(path string) func() (string, error) {
    return sync.OnceValues(func() (string, error) {
        data, err := os.ReadFile(path)
        if err != nil {
            return "", err
        }
        return string(data), nil
    })
}
```

`os.ReadFile` closes its own file; returning a string prevents a caller from
mutating the shared byte buffer. This is not a bounded-size reader or a refreshable
configuration service: use it only for trusted, acceptably sized files and a
deliberate snapshot lifetime.

A cache miss implementation has the following important steps, even when the
policy is small:

1. Read/copy the entry under the map lock; check expiry against a clear clock
   policy. Do not read the map again after unlocking.
2. Release the lock before fetching. The source must support concurrent calls if
   callers can miss concurrently. Propagate failures; do not convert them to
   empty successes. Decide explicitly whether negative results are cacheable.
3. Publish a fully initialized, immutable/copy-owned value under the lock. A
   returned `[]byte` or `*Record` must not let callers mutate shared cache state;
   copy on ingress/egress or establish a genuinely immutable ownership contract.
4. Accept duplicate fetches only deliberately. With overlapping reads, an older
   slow response may overwrite a newer one. If invalidation races with a miss,
   deleting the entry alone permits that miss to repopulate stale data. Use a
   per-key generation checked before publication when invalidation must fence
   prior loads; deleting in-flight bookkeeping alone is insufficient.
5. Bound admission/eviction and remove expired entries as needed: TTL alone does
   not reclaim entries for keys never read again. Decide whether stale-on-error
   is allowed; never return stale data silently under a fresh-data contract.

For a cache of protected data, include all relevant tenant/principal/policy and
representation dimensions in the key, or authorize on every hit. Do not cache
permission denials across users. For external calls, retries are safe only under
specified idempotency and transient-failure rules, not because the operation is
hidden behind a proxy. See [resilience decisions](behavior-patterns.md#resilience-patterns-are-policy-not-automatic-safety).

## Accept small contracts, return useful types

Accept the smallest useful consumer-defined interface (`io.Reader`, not `*os.File`
when only reading), and usually return a concrete type when its extra methods
are meaningful. Neither slogan is absolute: take a concrete type when its
semantics are required, and return an interface when intentionally hiding an
implementation or selecting among implementations. The standard library does
both. Do not create a broad producer-owned repository interface merely to make
all wrappers implement it. Composition does not repair an oversized contract.

## Sources and correction decisions

Adapted from [StructWeave structural patterns, pinned chapter 10](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/10-design-patterns-structural.md).
All seven patterns and the interface/concrete-return guidance are retained;
repeated file/menu, email/migration, style/icon and proxy scaffolds are consolidated
into the decisions above. Deliberate corrections: no fake backend successes,
no arbitrary XML-map decoding, no unsafe formatted JSON/HTML, no dropped
Reader data/errors, no transparent-HTTP-wrapper claim from embedding, no
mutation-safe or single-load claim from concurrent maps, no stale-repopulation
assumption after invalidation, and no universal ban on interface return values.

Authoritative API contracts: [io.Reader](https://pkg.go.dev/io#Reader),
[http.ResponseWriter](https://pkg.go.dev/net/http#ResponseWriter),
[http.ResponseController](https://pkg.go.dev/net/http#ResponseController),
[sync.Map](https://pkg.go.dev/sync#Map),
[sync.OnceValues](https://pkg.go.dev/sync#OnceValues).
