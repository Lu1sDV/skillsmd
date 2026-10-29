# Construction, configuration and ownership

## Contents

- [Choose ordinary construction first](#choose-ordinary-construction-first)
- [Singleton and initialization](#singleton-and-initialization)
- [Factories and related families](#factories-and-related-families)
- [Builder and functional options](#builder-and-functional-options)
- [Prototype and copy boundaries](#prototype-and-copy-boundaries)
- [Object pools and lifecycle](#object-pools-and-lifecycle)

## Choose ordinary construction first

A composite literal or `NewThing(required, config)` is the default. A constructor
is useful for invariants, validation, defaults or acquired resources; it need not
return a pointer or interface. Prefer useful zero values where compatible with
invariants. A type with unexported fields may intentionally require construction;
document whether its zero value is usable. Do not add a “Must” variant unless
panic on fixed programmer configuration is truly wanted.

| Source creation family | Smallest Go choice | Escalate only when |
|---|---|---|
| Singleton | One value owned in `main`, injected explicitly | A genuinely shared initialization lifetime is required |
| Factory method | Ordinary `NewX` or a small closed switch | Runtime implementation selection exists |
| Abstract factory | A concrete family owning compatible products | Multiple related product families need one consumer boundary |
| Builder | Config literal plus one validation step | Incremental staged assembly genuinely helps callers |
| Prototype | Explicit `Clone` with declared ownership | Reusing a template is meaningful |
| Object pool | Allocate normally; use existing resource pool | Measured reusable temporary allocation or scarce-resource lifecycle warrants it |
| Functional options | Required args plus config | Many independently optional settings need composable defaults |

## Singleton and initialization

`sync.Once.Do` invokes its function once per Once value, not once per process
across plugins, replicas or restarts. It synchronizes publication of completed
initialization; it does not make later mutations safe. Never copy a used Once or
reset one concurrently. Recursive `Do` on the same Once deadlocks. If `Do`'s
function panics, it still counts as done; subsequent calls do not rerun it.

Go 1.21's `sync.OnceValues` conveniently caches a value **and its error**. Complete
example, with declarations from [api.go](../examples/api.go):

```go
package main

import (
    "fmt"
    "sync"
)

func main() {
    load := sync.OnceValues(func() (string, error) {
        return "ready", nil
    })
    value, err := load()
    fmt.Println(value, err) // ready <nil>
}
```

OnceValue/OnceValues re-panic with the same panic value on subsequent calls if the
initializer panics, unlike repeated Once.Do behavior. A cached initialization
error is permanent for that closure's lifetime. The executable regression checks
failure is called once, not retried. If transient failure needs retry, use explicit
state under a mutex with all reads/writes synchronized and a defined retry policy;
never implement it by assigning a new `sync.Once` as in the source's retry example.
Do not install a race-prone global `SetForTesting`; inject isolated dependencies.

`init()` cannot return errors and is not directly callable. Reserve it for small,
deterministic package initialization or documented registration. Load files,
credentials and connections explicitly at the application boundary. If an initial
connection succeeds but readiness validation fails, close it before returning.
No external DB driver is bundled; source SQL/SMTP/SDK fragments are not executable
examples here. A real `sql.DB` owner sets its own connection limits and closes it.

## Factories and related families

A factory returning a concrete type remains an ordinary constructor. A factory
returning an interface can select actual interchangeable implementations; report
unknown selections as errors instead of returning nil success. Use typed config
rather than a loosely typed map when schemas differ. A small closed switch is
clearer than a registry with global state. If plugins require registration, define
duplicate-name policy and synchronize lookup, then release the registry lock
**before** invoking a factory that may block or reenter registration.

An abstract factory creates a related family, not arbitrary objects that happen
to share method names. Source database factories assert a generic Connection to a
specific driver pointer; mixing families can panic. Prefer an operation on the
owning connection (`BeginTx` creates its own transaction) or return a paired
family whose products cannot be accidentally mixed. Stdlib `database/sql` already
provides that ownership structure.

A compact real family can be function values. This complete declaration uses the
containing file's `encoding/json` import, with no fake transport or type assertion:

```go
type JSONFamily struct {
    Encode func(any) ([]byte, error)
    Decode func([]byte, any) error
}

func NewJSONFamily() JSONFamily {
    return JSONFamily{Encode: json.Marshal, Decode: json.Unmarshal}
}
```

This is a *single concrete* family, not a reason to introduce an abstract interface.
Its encode/decode functions are exercised in [examples_test.go](../examples/examples_test.go).
If multiple families are required, select the pair together and document their
wire representation; changing a factory does not guarantee protocol compatibility.
HTML-generating UI families must escape untrusted values (prefer `html/template`),
not interpolate a label directly into markup as in the source.

## Builder and functional options

Both organize construction; neither implies validation or safe ownership.

- Keep required dependencies explicit. Config/options apply before side effects;
  final validation checks cross-field invariants after all options.
- Define duplicate options (this bundle uses last valid scalar option wins), nil
  options (rejected), ordering, and invalid earlier options (return error even if a
  later value might repair them). Do not leak a partially configured product.
- Validate ranges, durations, URL host **and** scheme, TLS key/cert pairs and header
  rules if those settings are actually exposed. A parsed URL can still be relative.
  Never label arbitrary settings “production defaults” without deployment context.
- Validate a builder in `Build`; snapshot owned maps/slices each time, and define
  reuse. A director is usually an ordinary function calling the builder for a
  named recipe; do not invent a class solely for that name.
- Keep SQL values in bound arguments, not `fmt.Sprintf` interpolation into WHERE.
  Validate/allowlist identifiers separately; parameters cannot bind table names.
- A request builder is not an HTTP implementation. Prefer `http.NewRequestWithContext`
  and `http.Client` over scaffolding an undefined Execute method. If retries are
  offered, define replayability/idempotency, cancellation and attempt limits.

[api.go](../examples/api.go) implements a reusable `DocumentBuilder` whose Build
returns independent tags and rejects empty titles; `NewExporter(io.Writer, ...Option)`
validates prefix/positive byte limit, applies options before writing, and reports
short/error writes. Output is a real write to the supplied dependency; it is not
“sent successfully” text standing in for network I/O. Representative complete
option declaration from the example module (`strings` and `errors` imports):

```go
func WithPrefix(prefix string) Option {
    return func(config *exportConfig) error {
        if strings.ContainsAny(prefix, "\r\n") {
            return errors.New("prefix must not contain a newline")
        }
        config.prefix = prefix
        return nil
    }
}
```

`Option`/`exportConfig` are defined in the linked executable source; this is a
complete declaration, not a standalone program. Options receive private
configuration, not a running Exporter. Constructors reject a nil writer interface;
typed nil writers are outside the documented contract rather than reflectively
probed. A custom option is responsible for honoring its configuration contract.

## Prototype and copy boundaries

Assignment copies values, not ownership graphs. `slices.Clone` and `maps.Clone`
copy storage shallowly; maps containing slices need each slice copied too.
`Document.Clone` in [api.go](../examples/api.go) demonstrates that explicit policy:
copy tags, copy the map, copy each byte slice. Builder reuse and caller mutation
regressions assert the original remains unchanged. Public mutable fields still
allow caller edits; Clone provides independence, not immutability.

Define whether a clone preserves identity/timestamps or creates a new entity;
copying and creation are different domain operations. Source's “revised (Copy)”
output does not follow from assigning a new title afterward; examples here assert
actual resulting state. A prototype registry should store an owned snapshot or
explicitly borrowed immutable prototype, return independent clones, and synchronize
registration/lookup if concurrent.

`encoding/gob` is a wire serialization format, not an arbitrary deep-copy API.
It handles exported encodable state and may invoke custom codecs; functions,
channels, resources, unexported state, cyclic graphs and pointer identity do not
become faithful independent copies. Propagate codec errors and restrict such a
technique to a known encodable schema, not a promise for `T any`. Never clone live
locks, file descriptors, transactions or connection pools with assignment or gob.

## Object pools and lifecycle

`sync.Pool` is an optional cache of interchangeable temporary objects, **not** a
bounded resource pool. Get may ignore stored items and call New; items may disappear
at any time without notice. GC removal is not Close and does not release external
resources deterministically. Do not depend on goroutine/thread affinity, FIFO order,
retention, maximum size or guaranteed allocation reduction.

If pooling is measured to help, reset before reuse, avoid retaining huge backing
arrays, and stop using an object immediately after Put. Returning bytes aliasing a
pooled buffer permits another owner to overwrite them; copy before returning or
transfer ownership without Put. Reset is not secure erasure of the backing array.
Never put externally scarce connections/files in sync.Pool. Do not copy a used Pool.

For deterministic scarce-resource pooling, prefer an existing owner such as
`sql.DB`. A custom implementation must specify bounded total count (idle plus
leased plus initializing), constructor failure cleanup, acquire cancellation,
exclusive leases, double-release policy, shutdown admission, outstanding-return
cleanup and close errors. Source's channel-pool recipe has release/send versus
channel-close races and receives closed-channel zero values as successful leases;
it is not copied. A closed flag check followed by unlocking before send is not
atomic with Close. No incomplete custom pool is supplied as a replacement.

Worker pools are bounded work/lifetime coordination rather than object allocation
caches. Consume results while submitting when both jobs/results are bounded;
submitting all jobs before draining results can deadlock as in the source sample.
Define cancellation and wait for owned workers on shutdown. The optional
**go-concurrency** skill expands implementation, but these constraints are local.

Correction authorities: [sync.Once and helpers](https://pkg.go.dev/sync#Once),
[sync.Pool](https://pkg.go.dev/sync#Pool), [gob](https://pkg.go.dev/encoding/gob),
[sql.DB](https://pkg.go.dev/database/sql#DB),
[constructors](https://go.dev/doc/effective_go#composite_literals).
