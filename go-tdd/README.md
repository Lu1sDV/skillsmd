# go-tdd

Standalone Go red-green-refactor: observable boundaries and state transitions,
named table/subtests, cleanup and parallel isolation, real local HTTP/files,
doubles with honest limits, properties/fuzzing, benchmarks, synctest, and test CI.
Consult **test-engineering** only for an explicitly requested system-wide strategy;
no sibling skill, upstream checkout, external service, or Go dependency is
required to use this bundle's examples.

- [Install](#install-from-this-checkout)
- [Prompts](#example-prompts)
- [References](#reference-index)
- [Commands and expected behavior](#runnable-examples)
- [Source coverage](#pinned-source-coverage)
- [Decisions and corrections](#consolidation-and-correction-decisions)
- [API references](#first-party-api-references)

## Install from this checkout

From the repository root:

```sh
mkdir -p "$HOME/.claude/skills"
if [ -e "$HOME/.claude/skills/go-tdd" ] || [ -L "$HOME/.claude/skills/go-tdd" ]; then
    printf '%s\n' 'Existing go-tdd preserved; back up/reconcile it before installing.'
else
    cp -r go-tdd ~/.claude/skills/
fi
```

This preserves an existing installation instead of overwriting local edits.
The copy installs guidance and examples, not a toolchain or test framework.

## Example prompts

- “Use go-tdd to reproduce an exact-quota rejection; add a boundary regression
  before changing the shared Take path, and assert rejected requests preserve state.”
- “Characterize this legacy Go handler, then implement only the approved error
  mapping. Exercise its actual ServeMux, not manually populated path values.”
- “Find why these parallel subtests lose their database connection; fix ownership
  and cleanup without serializing unrelated cases or touching shared tables.”
- “Replace sleep-based timeout tests with stable Go 1.25 synctest; distinguish
  virtual-time progress from waiting for goroutines to settle.”
- “Add bounded metamorphic/fuzz checks for this parser and a B.Loop benchmark;
  report what seed tests, race detection and coverage do not prove.”

## Reference index

| File | Contents |
|---|---|
| [SKILL.md](SKILL.md) | Activation, routing, workflow, guardrails, version/evidence gate |
| [Workflow and runners](references/workflow-and-runners.md) | Contract/QA cases, red-green-refactor, safe exact-boundary mutation, table/subtest/helper mechanics, legacy and golden files |
| [Isolation and boundaries](references/isolation-and-boundaries.md) | Cleanup/parallel ownership, test doubles/testability, HTTP/files/DB/CLI, explicit time and stable synctest |
| [Properties and tooling](references/properties-and-tooling.md) | quick/metamorphic checks, fuzz corpus, coverage/mutation limits, B.Loop/parallel benchmark scope, race/vet/CI |
| [Budget source](examples/budget.go) | Complete nonconcurrent nonnegative-unit state machine |
| [Tests/example/benchmark](examples/examples_test.go) | Public-contract regressions, bounded metamorphic property, native fuzz target, Example with Output, B.Loop benchmark |
| [Synctest recipe](examples/synctest_test.go) | Complete standard-library deadline-boundary test, explicitly not Budget coverage |
| [Demo](examples/cmd/demo/main.go) | Actual rejected and exact-capacity requests using the production sample |

## Runnable examples

Requires **Go 1.25+**, a writable Go build cache, and only the standard library.
`examples/go.mod` declares `go 1.25.0`. Go 1.25 is the sample's minimum, not an
all-version certification or a requirement to raise a consuming project's
minimum. Core tests use older APIs; native fuzzing is 1.18+, loop-variable
semantics here are Go 1.22+, B.Loop and T.Context are 1.24+, and stable
synctest.Test is 1.25+. The old experimental synctest.Run is not used.

From the bundle directory (checkout or installed copy):

```sh
cd examples
export GOWORK=off GOTOOLCHAIN=local
go version
go run ./cmd/demo
go test -count=1 ./...
go test -count=1 -run '^TestBudgetTakeBoundary$/^exact_emptying$' .
go test -count=1 -run '^TestDeadlineBoundary$' .
go test -count=1 -shuffle=on ./...
go vet ./...
go test -count=1 -race ./...
go test -count=1 -coverprofile=coverage.out ./...
go tool cover -func=coverage.out
go tool cover -html=coverage.out -o coverage.html
go test -run '^$' -fuzz '^FuzzBudgetTake$' -fuzztime=5s -parallel=2 .
go test -run '^$' -bench '^BenchmarkBudgetNewAndTake$' -benchmem -count=5 .
```

`GOWORK=off` avoids an enclosing workspace; `GOTOOLCHAIN=local` refuses automatic
toolchain downloads, so an adequate Go version must already be installed.
Race builds need a supported platform and typically cgo/a C compiler. Keep
resource-intensive checks sequential. Fuzzing writes caches and may preserve a
failure corpus in `testdata/fuzz`; coverage commands create local report files.
Use a disposable bundle copy if the installation is read-only. Verified on
2026-10-29 with Go 1.26.10 linux/amd64: isolated race-enabled tests, vet, the demo,
the documented failing-mutant/restored-green recipe, and a five-second two-worker
fuzz campaign passed. Coverage reports, shuffle runs and benchmarks were not run.

Expected demo output:

```text
after rejected request: 10
after exact request: 0
```

### Test coverage inventory (not measured percentages)

| Named check | Observable contract |
|---|---|
| `TestBudgetTakeBoundary` | Five isolated parallel subcases: negative, zero, below, exact, above; errors and remaining units |
| `TestBudgetTransitions` | Successful decrement, rejection preserving state, exact emptying, rejection after emptying |
| `TestBudgetZeroValue` | Empty zero value accepts zero and rejects a positive request without changing state |
| `TestNewBudgetRejectsNegativeCapacity` | Negative capacity returns nil and the promised sentinel |
| `TestBudgetIntegerLimits` | MinInt64 rejection preserves MaxInt64; exact maximum request safely empties |
| `TestBudgetTakeSplit` | 200 locally seeded bounded quick cases; split and whole affordable requests have the same final effect |
| `TestDeadlineBoundary` | Standard API recipe: context active at deadline-1ns, canceled at deadline, without wall-clock waiting |
| `FuzzBudgetTake` | Five seeds in ordinary tests; generated campaign checks acceptance, conservation, and rejection non-effects |
| `ExampleBudget_Take` | Executable public example with checked Output |
| `BenchmarkBudgetNewAndTake` | Timed construction plus exact request, using B.Loop and ReportAllocs; no performance claim |

Seven top-level `Test` functions, five boundary subcases, one native fuzz target,
one executable Example, and one benchmark are authored. This inventory is not a
coverage percentage, benchmark result or proof over every schedule/input.
The small core sample intentionally
has no persistence, concurrent-use guarantee, or live HTTP integration; reference
recipes explain how to test those boundaries in a real application.

### Reproduce a behavioral red, then green

From `go-tdd/`, run the complete [temporary mutation command](references/workflow-and-runners.md#reproduce-red-then-green-safely).
It additionally needs Python 3 for safe disposable copying, mutation and
restoration. Exact mutation in the disposable `budget.go` only:

```diff
-if amount > b.remaining {
+if amount >= b.remaining {
```

Exact selector before and after restoration:

```sh
go test -count=1 -run '^TestBudgetTakeBoundary$/^exact_emptying$' .
```

Expected red: `Take(10) = insufficient budget; want <nil>` in
`TestBudgetTakeBoundary/exact_emptying`. Expected green: the same selector
passes after restoring `>`. The command verifies the named assertion rather than
accepting any failure and restores source in a `finally` block before the green
run. All modifications are inside an automatically deleted temporary copy;
the published source stays correct. These are the expected outcomes; the recorded
verification appears under [Runnable examples](#runnable-examples).

## Pinned source coverage

Adapted from StructWeave-Algorithms, copyright (c) 2024-2025 StructWeave
Contributors, under the [verbatim MIT notice](LICENSE.upstream). Sources are
pinned to commit `e2a796e212d431c906c85957ea3c203ce0e2218f`; local references
are the usable guidance, not a dependency on opening upstream pages.

| Pinned chapter / read scope | Local coverage |
|---|---|
| [15 — Test-Driven Development](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/15-test-driven-development.md), **entire chapter**, lines 1–3403 | All 15 source sections synthesized as below; repeated interview answers/cards are consolidated, not copied |
| [05 — Idioms and Best Practices](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/05-idioms-best-practices.md), testing lines 397–537 and workflow 750–769 | Basic/table tests, helpers, native fuzzing and round-trip caveats, B.Loop, test/vet/coverage command guidance; general tooling is outside this bundle |
| [12 — Anti-Patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/12-anti-patterns.md), testing 1234–1377 and race 1464–1473 | Public behavior, proper synchronization, table tests, race CI with supported-platform caveats |
| [14 — Standard Library Essentials](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/14-standard-library-essentials.md), testing 2372–2605 and card 3019–3030 | Testing API, TestMain, parallel ownership, benchmark/fuzz/fs.FS, corrected stable synctest API |
| [03 — Concurrency Patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/golang/03-concurrency-patterns.md), concurrent testing 971–1023 and card 1137–1141 | Go 1.25 API/version correction, durable blocking vs virtual-time advance, and lifecycle/race limits |

Chapter 15 section-to-reference map:

| Source topic | Consolidated destination |
|---|---|
| 1 Why TDD; 2 cycle; 3 schools | Workflow: contract-first feedback, red/green/refactor, inside-out vs outside-in; unsupported statistics removed |
| 4 QA mindset, boundaries, partitions, negatives, error guessing | Workflow case matrix and executable exact-budget/transition/limit checks |
| 5 Practical Go patterns | Workflow tables/subtests/helpers/goldens; isolation cleanup/time; actual tests and mutation command |
| 6 doubles; 7 testability | Isolation: roles/limits, small consumer seams, pure values, no globals, proportionate options |
| 8 strategies | Workflow: triangulation vs obvious implementation, temporary fake caution, small transformations and case planning |
| 9 ten test anti-patterns | Workflow/isolation/tooling: missing assertions, giant/unrelated tests, setup coupling, slow/flaky/shared state, private internals, metric obsession, copy-paste and environment dependency |
| 10 properties, fuzz, mutation, BDD | Properties/tooling and named/nested-test guidance, with meaningful assertions and checked quick results |
| 11 business, HTTP, database, concurrent scenarios | Core executable sample plus real HTTP/file/DB/CLI and deterministic concurrency recipes/limits |
| 12 when not TDD | Workflow: spikes and unknown contracts; retained code and wrappers/UI still need appropriate boundary evidence |
| 13 interviews; 14 cards; 15 resources | Consolidated throughout; local routing/commands and first-party technical references replace duplicated Q&A/cards |

## Consolidation and correction decisions

| Decision | Rationale / source correction |
|---|---|
| Keep a short router and three task guides | Preserve meaningful chapter topics without a second long entrypoint or duplicated interview cards |
| Use a nonnegative-unit state machine | Public boundaries and rejection non-effects are easy to falsify without pretending a toy identity validator is secure |
| Preserve a real behavioral red | Undefined symbols/setup failures are not the final regression evidence; an already-passing valid-email case does not prove red |
| Do not ship source email/password policy as validation | `Contains("@")`, length and character-class checks are pedagogical only; not complete email validation, secure password policy, hashing, or account security |
| Correct stable synctest and time claims | Go 1.25 uses Test, not Run; Wait synchronizes durable blocking, not automatic “advance five seconds” behavior |
| Fix cleanup before fallible setup | The source DB helper registers cleanup after table creation and drops a shared users table; use immediately registered cleanup and test-owned schema/resources |
| Fix parallel shared-fixture implications | Per-iteration loop variables do not isolate mutable maps/DBs; parent defers can close resources before parallel children resume |
| Make properties meaningful | Source sort properties ignore quick.Check errors; JSON examples sometimes only decode or discard errors. Inspect errors, assert preservation plus canonical outcomes, and avoid identity-pass properties alone |
| Avoid unsupported claims/mandates | Remove TDD defect percentages, blanket coverage targets and unconditional race support; statement coverage, finite fuzzing and executed race paths have explicit limits |
| Keep testability proportionate | No required DI/options framework, fake repository hierarchy, broad interfaces or third-party mocking dependency |
| Distinguish test scopes | Synctest recipe is standard API evidence only; fakes/loopback HTTP do not certify real DB semantics/live vendor API compatibility |
| Avoid blanket “do not test” categories | A tiny wrapper, renderer or panic contract can be important; choose meaningful boundary assertions rather than testing purely for metric increases |
| Handle numeric contracts explicitly | Source integer examples can overlook MinInt abs overflow or unchecked arithmetic; the sample bounds/property domain and subtract-only accepted transition avoid overflow |

## First-party API references

Sensitive claims can be checked against these references; their essential
instructions are included locally for offline use:

- [testing: T, cleanup, parallel, helpers, fuzz, TestMain](https://pkg.go.dev/testing)
- [testing.B.Loop](https://pkg.go.dev/testing#B.Loop) and [Go 1.24 release notes](https://go.dev/doc/go1.24)
- [testing/synctest](https://pkg.go.dev/testing/synctest) and [Go 1.25 release notes](https://go.dev/doc/go1.25)
- [Native Go fuzzing](https://go.dev/doc/security/fuzz/) and [testing/quick](https://pkg.go.dev/testing/quick)
- [net/http/httptest](https://pkg.go.dev/net/http/httptest), [testing/fstest](https://pkg.go.dev/testing/fstest)
- [Race detector requirements and limits](https://go.dev/doc/articles/race_detector)
- [Go test flags](https://pkg.go.dev/cmd/go#hdr-Testing_flags) and [coverage tooling](https://go.dev/blog/cover)
- [Go 1.22 loop-variable language change](https://go.dev/doc/go1.22#language)
