# go-system-design

A self-contained skill for practical Go package/module boundaries, incremental
architecture, CLI and `net/http` composition, startup configuration, transaction
identity and resource lifecycle. It favors concrete operations and explicit
wiring over framework skeletons, mandatory repositories or DI containers. No
sibling skill, source checkout, database driver or remote service is required.

## Install from a checkout

From the repository root:

```sh
mkdir -p ~/.claude/skills
cp -r go-system-design ~/.claude/skills/
```

If an installed copy exists, preserve its local changes before using this command;
do not blindly merge stale references into an updated bundle. Keep `SKILL.md`,
`references/`, `examples/`, this README and `LICENSE.upstream` together.

## Example prompts

- “Decide whether this Go CLI needs another package or just another file.”
- “Explain which callers may import our nested internal package.”
- “Share this operation between a CLI and net/http without a service skeleton.”
- “Review SQL helpers for accidental pool calls inside a transaction.”
- “Replace this DI container with explicit wiring and correct shutdown ownership.”
- “Decide whether our aggregate and outbox need separate consistency boundaries.”

## Reference index

| File | Scope |
|---|---|
| [SKILL.md](SKILL.md) | Routing, workflow, essential guards and version/evidence policy |
| [Packages and boundaries](references/packages-boundaries.md) | Package/module semantics, `internal`/`pkg`/`cmd`, growth, cycles, clean/hexagonal/DDD choices, aggregates/value objects/models |
| [Applications and lifecycle](references/applications-lifecycle.md) | Real CLI/HTTP operation, adapters, explicit composition, reader/socket ownership, cancellation limits, bounded startup/shutdown and workers |
| [Transactions and configuration](references/transactions-config.md) | Config parsing/secrets, SQL pool/transaction/context identity, complete PostgreSQL transfer integration recipe, concurrency/outbox/evidence |
| [Runnable module](examples/go.mod) | Complete stdlib-only line-count operation, CLI, loopback HTTP demo and named regressions |

## Runnable commands and expected behavior

Requires Go **1.25.0 or later** and a shell. The samples declare `go 1.25.0` and
have no third-party dependencies. `GOTOOLCHAIN=local` below prevents automatic
compiler download; if your local Go is older, select/install a suitable toolchain
explicitly. Verified on 2026-10-29 with Go 1.26.10 linux/amd64 in an isolated copy:
race-enabled tests, vet, stdin CLI and the real loopback HTTP demo passed.
Go 1.25 and other platforms were not independently exercised.

From `go-system-design/`, use an isolated temporary copy, with cleanup on exit:

```sh
(
    work=$(mktemp -d) || exit 1
    trap 'rm -rf "$work"' EXIT
    cp -r examples "$work/examples" || exit 1
    cd "$work/examples" || exit 1
    export GOTOOLCHAIN=local GOPROXY=off GOSUMDB=off
    export LINECOUNT_MAX_BYTES=1048576 LINECOUNT_TIMEOUT=3s
    go test ./... &&
    printf 'one\ntwo' | go run ./cmd/demo count - &&
    go run ./cmd/demo demo
)
```

Expected: tests succeed; the stdin CLI prints `2`; the HTTP demonstration prints
`HTTP 200 lines=2` and exits by itself. It binds an ephemeral **loopback-only**
port, starts the server, posts `red\nblue\n`, checks status and JSON, closes its
client resources, shuts down within its configured deadline (force-closing on
failure), and joins its serving goroutine. No curl, fixed port, signals, background
shell job or manual kill is required. It requires permission to open a local TCP
listener. A bind/request/shutdown failure is an error, not a skipped success.

The same commands can run directly from `examples/` without the copy. File input
is supported as `go run ./cmd/demo count path/to/file`; no filename or `-` uses
stdin. The command prints only a line count to stdout and does not modify input.
An empty file counts as zero; a final unterminated line counts as one; only byte
`\n` separates lines. Limits are byte counts, not characters or lines.

Failure probes, from `examples/` with the environment above:

```sh
printf '12345' | LINECOUNT_MAX_BYTES=4 go run ./cmd/demo count -
LINECOUNT_MAX_BYTES=0 go run ./cmd/demo demo
```

Both must exit nonzero. The first reports `input exceeds byte limit` on stderr;
the second rejects the invalid startup byte limit before creating a listener.
`go run` may additionally print `exit status 1`. Do not chain intentional failure
probes as though they were successful commands.

Named tests cover empty/blank/final lines, exact and exceeded limits, wrapped read
errors, cancellation before and during input reading, config defaults/overrides/
rejections, and HTTP status/body/method/cancellation behavior. The `ExampleCount`
output is checked by `go test`. The demo adds a real loopback socket interaction.
The HTTP tests use recorders and do not replace this network invocation.

The example buffers bounded input, not constant-memory streaming, and cancellation
cannot interrupt an arbitrary blocked reader. Defaults permit the demo payload;
setting `LINECOUNT_MAX_BYTES` below 9 intentionally makes its HTTP request fail.
The timeout setting bounds the demo's HTTP I/O/client/shutdown, not arbitrary CLI
stdin or application computation. There is no daemon mode, authentication, TLS,
production database, durable queue or load claim. Method-aware mux patterns need
Go 1.22+ and must not use legacy `GODEBUG=httpmuxgo121=1` semantics. The complete
PostgreSQL function in the transaction reference is an explicitly separate
integration recipe requiring an existing driver/schema; it is not tested by the
stdlib-only sample module.

## Consolidation and correction decisions

- **Three task-based references, not enterprise scaffolds.** Merge repeated flat,
  feature, clean and hexagonal layouts into decisions about real dependencies.
  Keep one concrete operation and two driving adapters; no no-op store/publisher.
- **Correct `internal` semantics.** Its parent directory tree governs allowed
  importers, not a blanket same-module rule. `pkg` is ordinary and unnecessary
  for public library code; `cmd` is convention, not a language requirement.
- **Reject numerical architecture thresholds.** Source line-count/team-size
  ladders are not causal rules. A modular monolith is a valid final architecture;
  growth need not end with clean architecture or microservices.
- **Correct naming and dependency absolutes.** Singular package names, interfaces
  in a central domain package, no domain imports, and fixed maximum layer counts
  are not Go requirements. Consumer-owned small interfaces and cohesive concrete
  code serve actual boundaries, even with one implementation where justified.
- **Make construction and cleanup real.** Do not ignore `sql.Open` errors or assume
  it establishes connectivity. Do not use fatal logging while expecting defers
  to close resources. The sample has actual bounded byte processing and HTTP,
  explicit errors, real file/socket ownership and self-stopping shutdown.
- **Correct consistency claims.** Uniqueness needs database enforcement, every
  atomic statement needs the same transaction, and ignored cache/event errors
  are not successful reliable delivery. Discuss dual-write/outbox identity and
  unknown commit outcomes without inventing automatic retries.
- **Correct DDD examples.** Private fields do not enforce all invariants or deep
  immutability; unchecked integer arithmetic and float-based money formatting
  are unsafe general recipes. Separate transport/storage models when their
  exposure or evolution differs, not because a tag-count threshold is crossed.
- **Keep format/config scope honest.** The source CLI advertises TOML but implements
  JSON/YAML only and needs an external YAML module. Replace it with a complete
  stdlib-only operation, explicit config syntax/ranges, and testable boundaries.

## Pinned chapter-to-reference and correction map

Adapted from StructWeave-Algorithms revision
`e2a796e212d431c906c85957ea3c203ce0e2218f`:

| Pinned source coverage | Local destination and corrections |
|---|---|
| [13 System design](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/13-system-design.md), lines 1–261: philosophy, layout fundamentals, project-layout controversy | Packages and boundaries: preserve simple defaults, correct `internal`, public-root libraries and naming; do not copy unofficial directory template or numerical thresholds |
| Same chapter, 262–506: minimal CLI/API layouts and gradual growth | Packages and boundaries + applications and lifecycle: files versus package seams, shared concrete operation, import moves, checked setup and ownership |
| Same chapter, 507–1057: clean/hexagonal, ports/adapters, wiring | Packages and boundaries + applications and lifecycle: actual dependency direction, optional consumer interfaces, no mandatory port/domain skeleton; transactions/config correct ignored SQL/publisher/cache errors |
| Same chapter, 1058–1202: bounded contexts, aggregates, entities, money values, repositories | Packages and boundaries + transactions/config: private invariants/aliases, checked money arithmetic, aggregate persistence/concurrency and transaction identity |
| Same chapter, 1203–1469: over-engineering, tag soup, Java-style names, layers, cycles | Packages and boundaries: targeted model separation, coherent names, merge/orchestrate cycles; no hard layer/tag-count rules |
| Same chapter, 1470–1784: CLI converter, REST API and enterprise example | Runnable module + applications and lifecycle + transactions/config: replace incomplete converter/no-op dependencies with real CLI/HTTP, validate settings, stop/join/close correctly; enterprise directories remain optional decisions |
| Same chapter, 1785–1986: interviews, quick reference, resources | Entrypoint and all three references: consolidate repeated decisions; retain pinned attribution and primary-document links without copying thresholds or an inevitable complexity ladder |
| [12 Anti-patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/12-anti-patterns.md), 542–657 and 881–986: focused interfaces/construction, package names, cycles and export surface | Packages and boundaries: abstract for a useful seam, not a rigid implementation count; minimize exports and avoid shared-interface dumping grounds |

All of chapter 13 was read; the listed chapter 12 supplements were selected for
architecture/package coverage. Other anti-pattern domains belong to optional
sibling skills, not hidden installation dependencies. Primary Go API links in the
references qualify sensitive runtime claims; they are citations, not execution
evidence. Retain the verbatim upstream [MIT notice](LICENSE.upstream).
