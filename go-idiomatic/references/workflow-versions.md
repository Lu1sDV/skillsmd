# Everyday workflow and version decisions

- [Naming, imports and initialization](#naming-imports-and-initialization)
- [Module and toolchain decisions](#module-and-toolchain-decisions)
- [Semantic navigation and refactoring](#semantic-navigation-and-refactoring)
- [Commands and their limits](#commands-and-their-limits)

## Naming, imports and initialization

Use lowercase, purpose-named packages, not a dumping-ground `util`/`common`.
Avoid stuttering (`user.New`, not automatically `user.NewUser`); keep local names
short when scope makes them obvious and use semantic names across larger scopes.
Use `HTTPClient`, `userID`, consistent short receiver names, and documentation on
exported declarations. Exporting is controlled by the first Unicode uppercase
letter, not by a separate access modifier. Keep implementation names unexported.
Use keyed struct literals at maintained boundaries instead of fragile field order.
Prefer explicit returns, guard clauses and ordinary loops over clever tricks.
`len` needs no nil guard for slices/maps; `_` is for intentionally unused values,
not silencing errors. Ordinary switch cases need no redundant final `break`.

Import paths identify packages inside modules; aliases resolve genuine name clashes.
A local variable can shadow an import or builtin (`fmt`, `len`, `error`): avoid it.
A blank import executes package initialization and should serve a deliberate
registration/side-effect contract, not hide an unused import. Import cycles are
illegal. Package restructuring and dependency direction route to **go-system-design**;
interface contracts and the extent of the exported API route to **go-api-design**.

Package variables initialize according to dependency rules, then `init` functions
run in source order as files are presented to the compiler. The go command normally
presents files lexically; do not encode essential behavior in filename order.
Imported packages initialize before importers, once per program, before `main`.
Multiple `init` functions are allowed, but `init` is not an ordinary callable/bindable
identifier (nor a reserved keyword). Keep it for simple deterministic registration.
Use explicit constructors/run functions for fallible configuration and resources,
with reverse-order cleanup on partial acquisition. Avoid mutable global state;
constants and immutable lookup data are not prohibited by a blanket slogan.

## Module and toolchain decisions

A module is the versioned dependency unit identified by `module`; a package is the
compilation unit in a directory. Use a module path appropriate for publication;
examples here use a deliberately local demonstration path and no external modules.
Keep `go.mod` and `go.sum` under review, run dependency-changing commands deliberately,
and do not add a dependency for a tiny stdlib operation. Do not create a root module
for a documentation repository. Use `go env GOMOD GOWORK GOVERSION GOTOOLCHAIN` to
establish the actual module/workspace/toolchain rather than trusting the shell cwd.

The `go` directive declares the minimum required Go version and language semantics;
modern toolchains enforce it. `toolchain` suggests a toolchain for the main module,
not a replacement for the language version. Auto toolchain selection may download
another compiler: offline reproducibility needs the required compiler preinstalled
and an explicit policy such as `GOTOOLCHAIN=local`. A newer compiler does not certify
support on the declared minimum. Check dependency requirements, build constraints,
platform-specific files and cgo before changing minimums.

| Feature | First supported version / caution |
|---|---|
| `%w`, `errors.Is` / `errors.As` | 1.13 |
| Generics, `any`, built-in fuzzing | 1.18; API/test design elsewhere |
| `errors.Join` | 1.20; nil arguments ignored, all nil yields nil |
| `clear`, `min`/`max`, `slices`/`maps`, `log/slog` | 1.21; inspect individual APIs for later additions |
| New declared-loop variables, integer range, `slices.Concat` | 1.22; language version matters for loop semantics |
| Function range, `iter`, `maps.Keys` iterators | 1.23; iterator stop propagation belongs to algorithms |
| Generic aliases, `tool` directive, JSON `omitzero`, `testing.B.Loop` | 1.24; no generic methods with their own type parameters |
| Runnable bundle minimum | 1.25.0, no third-party dependencies |

## Semantic navigation and refactoring

When `gopls` is available, use references/implementations and semantic rename for
symbol changes, then inspect diagnostics after each coherent edit. [References](https://go.dev/gopls/features/navigation#references)
cover only the analyzed build configuration; check relevant GOOS/build tags
separately. Call hierarchy omits dynamic calls. A [rename that compiles](https://go.dev/gopls/features/transformation#rename)
can still change runtime interface assertions, reflection and wire names derived
from exported fields. Check string-based lookups, templates and external consumers,
then run focused behavior tests; compilation alone does not validate those contracts.

## Commands and their limits

Run commands in the intended module, keeping dependency mutation separate from
checks. These are recipes, **not execution evidence**:

```sh
go version
go env GOMOD GOWORK GOVERSION GOTOOLCHAIN
gofmt -w path/to/changed.go
go vet ./...
go test ./...
go test -race ./...
go build ./...
```

Use goimports only if installed/pinned; it is not a standard toolchain command.
`go fmt ./...` formats package source; gofmt handles selected files. Vet is not a
proof of correctness and does not by default detect every shadowed error. Race
checking detects races only on exercised paths and requires supported platform/cgo
prerequisites. Test design, coverage, fuzzing and benchmark methodology route to
**go-tdd**, including avoiding misleading unused-result microbenchmarks.

`go mod init <path>` starts a real module; `go mod tidy` reconciles dependencies and
can edit files/download modules. `go get module@version` deliberately changes module
requirements; `go install command@version` installs a versioned standalone tool.
From Go 1.24, `go get -tool package@version` records a tool and `go tool <name>` runs
it; `go install tool` installs tools declared by the current module. Pin actual
versions, not `@latest`, for repeatable workflows. Validate third-party linter schema
and configuration against its pinned major release. Do not exempt test error handling
as a blanket rule.

`go generate ./...` executes declared commands; it is not part of `go build` and can
run arbitrary programs. Review generated diffs and pin generators. Linker `-X` can
set a suitable string variable (e.g. `main.version`) at build time; it cannot change
arbitrary constants. CI/release provenance belongs to **go-system-design**.

Use profiling only to investigate a measured concern. `go test -cpuprofile=cpu.out`
and `-memprofile=mem.out`, then `go tool pprof <file>`, are local investigation
recipes. A heap profile shows retention, not automatically a leak; process memory
need not fall immediately after dropping references. HTTP pprof exposes sensitive
runtime data: bind to a protected diagnostic listener and handle startup errors,
never expose the default mux publicly by copying an ignored `ListenAndServe` error.
Block/mutex profiles require enabling collection. Detailed operational profiling
and logging route to **go-system-design**/**go-stdlib**.

Choose clear invariants, documented complexity and small helpers in interviews;
validate empty/ragged matrices rather than copying a `matrix[0]` assumption.
Algorithms, two-sum/profit and neighbor implementations belong to **go-algorithms**.
Go proverbs are judgment aids, not mandates: channels do not always beat mutexes,
small interfaces are not a fixed five-method limit, and a zero value should be
useful when the type's invariants permit it.
