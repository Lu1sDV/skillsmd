# Packages, modules and earned boundaries

## Contents

- [Choose the unit of change](#choose-the-unit-of-change)
- [Directory semantics](#directory-semantics)
- [Grow without an architecture migration](#grow-without-an-architecture-migration)
- [Clean and hexagonal decisions](#clean-and-hexagonal-decisions)
- [DDD only where invariants need it](#ddd-only-where-invariants-need-it)

## Choose the unit of change

Start with one `go.mod` and one cohesive package. A command can have `main.go`,
`count.go` and `count_test.go` in the same directory/package without introducing
any abstraction. Files organize source; packages establish import/API boundaries;
modules establish version/dependency distribution boundaries. A repository may
contain several modules, but each needs a demonstrated independent compatibility
or release need. A workspace (`go.work`) helps develop multiple local modules;
it does not replace the `require` versions needed by downstream module users.

A package should answer a concrete question: counting lines, reserving inventory,
or translating HTTP. Prefer short, descriptive lowercase names. Singular nouns
are not a language rule: `bytes`, `strings` and `maps` are good counterexamples.
Avoid `common`, `util`, `impl` and a global `domain` dumping ground. The useful
question is whether `package.Name` explains its role, not whether it fits a naming
formula. Export only what another package actually consumes.

## Directory semantics

| Directory or declaration | Actual effect |
|---|---|
| `package main` with `func main()` | An executable, not an importable library package |
| `cmd/count/main.go` | Conventional command location; `cmd` itself has no privacy magic |
| `internal/count` | Go import restriction based on the tree rooted at `internal`'s parent |
| `pkg/count` | Ordinary importable package; `pkg` adds no access control or official endorsement |
| Exported `Count` | Accessible to legal importers; being exported does not bypass `internal` |
| Unexported `count` | Accessible within its package, regardless of files |
| `go.mod` | Module path, language/toolchain baseline and dependency requirements |

For example, `example.com/shop/internal/stock` can be imported from the `shop`
tree, including `shop/cmd/api`. For `shop/stock/internal/sqlstock`, the permitted
tree starts at `shop/stock`, not `shop`: `shop/cmd/api` cannot import it. This is
**not simply “same module only”**; nested modules and filesystem/import-path layout
do not turn it into a module-wide visibility switch. Choose the `internal`
location for the intended importer tree.

A public library can put `client.go` at the module root and be imported as
`example.com/shopclient`; it need not invent `example.com/shopclient/pkg/client`.
Either chosen non-internal path is part of the compatibility contract. Moving it
later breaks callers. For ordinary v2+ modules, major versions belong in module
and import paths, e.g. `example.com/shopclient/v2`.

Source: [Go module layout](https://go.dev/doc/modules/layout),
[internal directories](https://pkg.go.dev/cmd/go#hdr-Internal_Directories),
[module major versions](https://go.dev/doc/modules/major-version),
[package names](https://go.dev/blog/package-names).

## Grow without an architecture migration

| Observed pressure | Smallest useful response |
|---|---|
| A file mixes unrelated concerns | Split files in the same package first |
| Cohesive feature changes independently | Extract a feature package with a small API |
| CLI and HTTP need the same operation | Move the operation out of transport code; both call it |
| Multiple programs share implementation | Add `cmd/api`, `cmd/worker`, and shared internal packages if useful |
| External callers import unstable implementation | Put it under the appropriate `internal` tree |
| Core policy changes with every SQL/HTTP change | Separate policy from its adapters at that seam |
| Independent rollout or isolation is necessary | Consider another service after defining consistency and failure semantics |

These are choices, not a progression every application must complete. `internal`
can be appropriate on day one; `cmd` is also reasonable for one command. Neither
requires a particular team size, file length or total line count. A modular
monolith can remain the final design; adding a service adds distributed failure,
security, deployment and consistency work, not just another directory.

When imports cycle, first ask whether the two packages are actually one cohesive
unit. Otherwise let an orchestrating caller compose them, pass stable IDs/values,
or put a minimal interface at its consumer. Extract a shared value package only
when it owns a real shared concept. A third package full of mutual interfaces can
hide the cycle conceptually without improving the design.

Before moving a public package, account for every importer and generated import
path. For internal moves, change callers and tests together; keep behavior fixed
while relocating one cohesive slice. Package separation does not establish a
security boundary between code in the same process.

## Clean and hexagonal decisions

Both approaches aim to keep important policy independent of delivery/storage:

- **Clean:** source dependencies point toward policy. Application orchestration
  can depend on domain values; HTTP and SQL adapters depend on that application
  contract. Domain code can use the standard library; “no imports” is not a rule.
- **Hexagonal:** driving adapters (CLI, HTTP) invoke operations; driven adapters
  implement the I/O the operations need. Go's implicit interfaces fit this well,
  but an input interface and a `port/` package are not mandatory.
- **Practical default:** concrete operation, concrete transport adapter, explicit
  constructor arguments. Add a small consumer-owned interface when it enforces a
  useful policy boundary, not one interface per struct or only after counting
  implementations. A real boundary can justify one implementation.

Dependencies and runtime calls are different: an operation calls a SQL adapter
through a consumer-owned interface, while the adapter imports the consumer's
value types. The interface prevents policy from importing a driver. Place it
where its contract is owned, not automatically in `domain`, `interfaces` or `port`.
Returning concrete types is a useful default, not a prohibition on encapsulating
an implementation behind an interface when that is the intended API.

Do not require `Handler -> Controller -> Service -> Manager -> Repository -> DAO`
or even a universal three-layer maximum. Each boundary must own validation,
policy, translation, transaction coordination or another real responsibility.
A forwarding service adds no value. Small CRUD can call a concrete SQL component
from a handler; complex rules may deserve a pure function or aggregate plus an
application transaction owner.

The [working example](../examples/count.go) intentionally has no repository or
DI container: counting bytes requires neither. Its [CLI](../examples/cmd/demo/main.go)
and [HTTP adapter](../examples/http.go) call the same actual operation. See
[applications and lifecycle](applications-lifecycle.md) for exact wiring.

## DDD only where invariants need it

Use a bounded context when a word/model has a distinct business meaning, such as
an order in billing versus shipping. It may occupy one package or several related
packages; it is not automatically a separately deployed service or module.
Translate at that boundary instead of sharing a universal mutable `User` model.

An **entity** has stable identity; a **value object** is compared by value; an
**aggregate root** owns the invariants for a group of state changes. An order
might reject edits after submission, reject nonpositive quantities, and forbid
submitting an empty basket. Keep the fields or slices that would bypass those
rules private, expose intentional operations, and avoid returning mutable aliases.
Persistence hydration must also restore valid state; private fields alone do not
validate loaded data.

For money, choose currency/scale explicitly, use checked integer or suitable
exact arithmetic, reject incompatible currencies, and check multiplication and
addition overflow. Unexported fields do not magically provide deep immutability
or a valid zero value. Converting arbitrary `int64` amounts to `float64` to format
money loses precision. State the formatting/rounding policy instead of copying
the source's unchecked `Multiply` and floating-point formatter.

A repository, when earned, loads/saves aggregate roots with defined not-found,
conflict and transaction behavior. It is not a mandatory generic CRUD interface.
In-memory validation does not stop concurrent writers: use database constraints,
locking or an optimistic version condition with an affected-row check. A
multi-aggregate operation needs an explicit consistency decision; domain events
alone do not make it atomic. See [transactions and configuration](transactions-config.md).

Separate request/response/storage models when their trust, exposure or evolution
differs, especially for secrets and authorization. Do not create four mechanically
identical structs for every trivial record. JSON tags do not validate a value;
HTTP fields should not accidentally expose database credentials or password hashes.
