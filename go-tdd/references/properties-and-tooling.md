# Properties, benchmarks, and test tooling

## Contents

- [Properties and metamorphic checks](#properties-and-metamorphic-checks)
- [Native fuzzing](#native-fuzzing)
- [Mutation and coverage](#mutation-and-coverage)
- [Benchmarks with B.Loop](#benchmarks-with-bloop)
- [Race detection and CI](#race-detection-and-ci)

## Properties and metamorphic checks

Start with named examples, especially exact thresholds and historical bugs.
Then add independent invariants for a broad input domain:

| Contract | Useful properties | Missing evidence |
|---|---|---|
| Budget | Rejection preserves units; successful requests conserve units; splitting an affordable request equals taking its sum | Concurrency or persistence (neither is promised) |
| Sorting | Ordered result **and** preserved multiplicities/length; repeated sort unchanged | Stability unless separately specified/tested |
| Encoding | Decode(encode(x)) preserves supported values | Encoder/decoder can share the same defect; add canonical examples |
| Normalization | Idempotence plus canonical representative examples | Identity function also satisfies idempotence alone |
| Search | Result validity; agreement with an independent small-input oracle | Large-input performance |

State the domain before generating. `Reverse(Reverse(s)) == s` has different
meaning for bytes and runes; converting invalid UTF-8 to runes can replace bytes,
and byte length is not rune count. Integer addition/multiplication used by a
property must not overflow; bound generated values or use a wider/reference
representation. Do not reproduce the production algorithm as the oracle.

[The runnable metamorphic test](../examples/examples_test.go) uses two `uint16`
amounts, whose sum fits `int64`, and compares two public executions: take `a`,
then `b`, versus take `a+b`. Both must accept and finish empty. It uses
`testing/quick.Check` with **200** generated cases and a local fixed seed.
`quick.Config.Rand` requires the older `*math/rand.Rand` type; this compatibility
boundary is why the example uses a local legacy generator rather than
`math/rand/v2`. It never seeds package-global state and is not security code.

Always check `quick.Check`'s returned error; ignoring it makes failed properties
pass. `testing/quick` is a small frozen stdlib API, not a full shrinking/property
framework. Log/preserve concrete failures as named regressions. For most new
Go projects, native fuzzing plus a small deterministic property loop is enough;
reuse an existing property library only when its generation/shrinking features
are actually needed.

## Native fuzzing

Go fuzzing is available since Go 1.18. Put `FuzzX(*testing.F)` in `_test.go`,
seed with `f.Add`, then call `f.Fuzz(func(t *testing.T, supportedArgs...) { ... })`.
The argument types/count must match every seed; use supported scalar types,
strings, or `[]byte`, not arbitrary structs. A seed corpus is not a substitute
for semantic assertions.

The executable `FuzzBudgetTake` uses five seeds (negative, zero, exact, over,
and empty), a `uint16` capacity, and an arbitrary `int64` amount. It asserts
that affordable requests are not rejected, rejections preserve the old state,
and successes conserve nonnegative units. The named integer-limit test covers
`MinInt64` and `MaxInt64` capacities/requests directly; fuzz capacity is bounded
to keep this property simple. It does not claim all state sequences were explored.

From `examples/`:

```sh
go test -count=1 -run '^FuzzBudgetTake$' .
go test -run '^$' -fuzz '^FuzzBudgetTake$' -fuzztime=5s -parallel=2 .
```

The first runs corpus seeds, not a generated fuzz campaign. Ordinary `go test`
also runs seed cases. The second generates inputs for one package/one matched
fuzz target; choose one target at a time, not `./...`. `-fuzztime=5s` bounds
fuzzing work, not all startup/shrinking/shutdown time. `-parallel=2` limits fuzz
worker processes here; respect CI CPU/memory constraints.

Fuzz targets should be deterministic, bounded and input-local. Do not modify
process environment/cwd, leak goroutines, write a shared path, call live
services, or retain previous inputs in package globals. Input slices can be
reused: copy only if retaining them beyond the callback. Check error paths and
invariants, not just that `json.Unmarshal` from the standard library does not
panic. If invalid inputs are legitimate, a rejection may be expected, but
returning on *every* error can hide the accepted-input contract; include positive
seeds and explicit acceptance properties.

Failures are minimized and retained under `testdata/fuzz/<FuzzName>/`; inspect
and retain the meaningful reproducer. Generated non-failing corpus entries may
live in Go's cache. Report time, toolchain, worker count, seeds and actual
failures. A finite campaign does not establish input-space completeness.

## Mutation and coverage

The [temporary exact-budget mutation](workflow-and-runners.md#reproduce-red-then-green-safely)
is the smallest useful mutation check: replace `>` with `>=` and demand a
failure of the exact-capacity assertion, then restore and rerun. A surviving
mutation can indicate a missing distinguishing case, unreachable code, or an
equivalent mutation. Investigate; do not require a universal kill percentage.
Mutation tools are optional, not bundled dependencies, and never justify
shipping an intentionally broken production file.

From `examples/`:

```sh
go test -count=1 -coverprofile=coverage.out ./...
go tool cover -func=coverage.out
go tool cover -html=coverage.out -o coverage.html
```

Go's coverage reports instrumented **statements**. It does not establish branch,
path, assertion, requirement or security coverage. A test may execute a line
without checking its result. Cross-package coverage can require an explicit
`-coverpkg` selection; choose actual application packages, not arbitrary
percentages. The demo package may be uncovered by unit tests even though
`go run ./cmd/demo` exercises it separately; do not mislabel the demo run as
coverage instrumentation.

Use uncovered code to ask which important contract is missing; do not add
meaningless getter/wiring tests just to hit a target. Conversely, a promised
panic/error is worth testing even if the function is tiny. Read changed-code
coverage alongside named boundary/error tests. No coverage percentage, TDD
defect-reduction statistic, or fixed test-pyramid ratio is a publication mandate
for this bundle.

## Benchmarks with B.Loop

`testing.B.Loop` was added in Go **1.24**. Use the syntactic shape
`for b.Loop() { ... }`, not an adapter wrapping Loop and not a second `b.N` loop.
Setup before the first Loop call is excluded by its automatic timer reset;
cleanup after it returns false is excluded by its stop. The canonical shape
also protects benchmark work against certain compiler elimination; it does
not prove the workload is representative or every subexpression is measured.

[BenchmarkBudgetNewAndTake](../examples/examples_test.go) measures construction
plus one exact-capacity take per iteration, with `b.ReportAllocs()`. The
construction belongs inside this benchmark's measured contract. If benchmarking
only a mutable operation, reset the state deliberately and say whether reset
cost is timed; reusing an exhausted budget silently changes the workload.
Never compare a success-path implementation with a failure-path benchmark.

```sh
go test -run '^$' -bench '^BenchmarkBudgetNewAndTake$' -benchmem -count=5 .
```

For older supported Go versions use the conventional `for i := 0; i < b.N; i++`
with appropriate timer management, but preserve observable work and don't
silently raise their language baseline. `b.Run` creates named scenarios;
`b.RunParallel` uses `pb.Next()` for deliberately concurrent workloads, not
`b.Loop()` inside worker bodies. It must not share a non-thread-safe Budget.

Run correctness checks separately. Capture toolchain, CPU, OS, dataset,
GOMAXPROCS and workload shape; compare repeated samples under like conditions.
`-race` instrumentation changes timing and is not a performance baseline. A
nanosecond result alone does not justify optimization or a universal speedup
claim. CPU/heap profiles should explain an observed bottleneck; avoid profiling
tiny test setup and calling it application throughput.

### Before/after comparison

Choose the sample count and benchmark selector before measuring; this example
uses ten runs. Capture baseline and candidate under the same environment above,
with identical inputs and timing boundaries. Measure variants serially on shared
hardware. Save both outputs and compare with
[benchstat](https://pkg.go.dev/golang.org/x/perf/cmd/benchstat); do not extend
sampling until significance appears.

```sh
# Baseline checkout; repeat in the candidate checkout, writing after.txt.
go test -run '^$' -bench '^BenchmarkBudgetNewAndTake$' -benchmem -count=10 . > before.txt
benchstat /path/to/before.txt /path/to/after.txt
```

Report effect sizes, uncertainty and allocation changes, including `~` (no
statistically significant difference detected). Treat that as inconclusive, not
equivalence; never suppress it. Statistical significance does not establish
practical value.

## Race detection and CI

Representative commands from `examples/` (Go toolchain and C toolchain must
support the race build; no optional service is needed by these samples):

```sh
go version
go vet ./...
go test -count=1 ./...
go test -count=1 -race ./...
go test -count=1 -shuffle=on ./...
go test -count=1 -coverprofile=coverage.out ./...
go tool cover -func=coverage.out
```

`-race` detects races only on executed paths/schedules, not all races and not
logical order/cancellation defects. Some targets lack support; CI should run a
supported job and report the limitation rather than pretend an unsupported job
passed. Race builds often require `CGO_ENABLED=1` and a C compiler; preserve the
project's platform constraints. `go vet` is static analysis, not runtime proof.

For a real project's CI:

1. Run on its supported minimum Go version and a deliberately selected current
   toolchain. This bundle's runnable baseline is 1.25, not a consumer policy.
2. Check formatting (`gofmt -l` with a nonempty-output failure gate), `go vet`,
   named tests and a supported race job. Avoid launching heavy instrumented
   jobs simultaneously when resources are limited.
3. Keep integration prerequisites explicit (driver/service, sandbox credentials,
   build tag such as `//go:build integration`). Invoke that lane explicitly;
   `-short` is not an automatic exclusion. Do not hide requested work with skips.
4. Use deterministic seed tests on ordinary PRs; allocate a bounded scheduled
   fuzz lane if useful. Retain minimized failures as normal regressions. Archive
   coverage and relevant logs/seed artifacts without exposing credentials.
5. Benchmarks are evidence, not a noisy pass/fail timing threshold on shared
   runners. Review actual changes before adopting a performance gate.

For these stdlib-only examples `GOWORK=off` prevents an enclosing workspace from
changing resolution and `GOTOOLCHAIN=local` prevents automatic toolchain download.
A Go >=1.25 installation must already exist. Normal compilation/fuzzing writes
Go caches and failure corpora; use a writable disposable copy for mutation and
strictly hermetic CI. Dependencies in a consuming project require its own locked
module/cache strategy; mocks never substitute for real compatibility tests.
