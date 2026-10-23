# Benchmarking and performance validation

## Contents

- [Define the measurement contract](#define-the-measurement-contract)
- [Use a stable harness](#use-a-stable-harness)
- [Use timeit for narrow questions](#use-timeit-for-narrow-questions)
- [Measure services under load](#measure-services-under-load)
- [Prevent regressions](#prevent-regressions)
- [Reject misleading measurements](#reject-misleading-measurements)

Benchmark the actual objective while preserving required behavior; use [profiling](profiling.md) for attribution. Reuse a suitable project harness before adding dependencies.

## Define the measurement contract

Before editing, record:

- Target: batch duration, throughput at a latency/error budget, startup, peak memory or retention after repeated work.
- Workload: representative sizes/distributions, cache state, concurrency and output semantics; small, normal and stress cases; cold start versus warmed steady state.
- Environment: commit, exact interpreter/version/build, dependency lock, OS/architecture, CPU/container quota, relevant thread pools, dataset identifier and command.

Hold conditions constant; label interpreter/dependency changes as experimental variables. Preserve raw results. Validate output equality or agreed numerical tolerance before accepting timing.

Measure elapsed durations with `time.perf_counter_ns()` differences; measure current-process CPU consumption with `time.process_time_ns()` differences, which exclude sleeping and cannot represent request latency. Nanosecond units do not imply nanosecond resolution; inspect `time.get_clock_info()` when needed. [Python clocks](https://docs.python.org/3.14/library/time.html)

Use profiles for bottleneck hypotheses and repeatable unprofiled benchmarks for improvement evidence.

## Use a stable harness

Run the same `pyperf` harness/environment in baseline and candidate checkouts, with identical benchmark names:

```bash
python bench_workload.py -o baseline.json
# In the candidate checkout:
python bench_workload.py -o candidate.json
# Put both files in the comparison directory:
python -m pyperf check baseline.json candidate.json
python -m pyperf compare_to baseline.json candidate.json --table
python -m pyperf metadata baseline.json
```

Adapt the project-specific module/fixture:

```python
# bench_workload.py: operation must not mutate the reused fixture.
import pyperf
from project_workload import load_fixture, operation

def main():
    fixture = load_fixture()
    runner = pyperf.Runner()
    runner.metadata["dataset"] = "representative-fixture-v1"
    runner.bench_func("operation", operation, fixture)

if __name__ == "__main__":
    main()
```

Keep each call equivalent: reset mutation, control caches and consume lazy results. For iterator/coroutine returns, benchmark a consuming/awaiting wrapper. State this scaffold's boundary: fixture loading excluded, call/return overhead included. Use a time-function benchmark for fixture resets or per-iteration orchestration needing explicit boundaries; prefer `Runner.timeit` or `bench_time_func` for tiny operations where `bench_func` overhead dominates. Create only one `Runner` per script. [Runner API](https://pyperf.readthedocs.io/en/latest/api.html)

Let pyperf calibrate loops, separate warmups and use multiple sequential worker processes. Avoid competing runs on constrained machines. Warm up sufficiently for JIT/runtime specialization and intended state; measure startup separately at process level. [Execution](https://pyperf.readthedocs.io/en/latest/run_benchmark.html) [Runner controls](https://pyperf.readthedocs.io/en/latest/runner.html)

Inspect warnings, raw samples, histogram and run order. Treat `compare_to`'s first file as reference; “not significant” does not establish equivalence. Report effect size, variability and practical relevance; statistical detectability alone may not justify complexity. [Analysis](https://pyperf.readthedocs.io/en/latest/analyze.html) [CLI](https://pyperf.readthedocs.io/en/latest/cli.html)

Prefer a dedicated stable runner; record controls for CPU affinity/isolation, power policy and other load. Inspect changes/scope before `pyperf system tune`, which changes host settings; never silently tune a shared host. [System tuning](https://pyperf.readthedocs.io/en/latest/system.html)

## Use timeit for narrow questions

Account for setup exclusion and cyclic GC disabled by default; re-enable GC in setup when workload-relevant. The CLI calibrates repetitions; the convenience Python API defaults to a fixed count unless configured. Inspect repeats: the minimum is a best-case snippet bound, not a service latency percentile. Test production sizes. [`timeit`](https://docs.python.org/3.14/library/timeit.html)

Prevent these traps:

- Exhausted iterators or timing generator construction alone.
- Mutation shrinking/sorting later iterations.
- Cache hits standing in for deployed misses.
- Moving production conversion/copying/compilation/serialization costs into setup.
- Different outputs, errors, numeric accuracy or durability guarantees.
- Baseline/candidate groups straddling thermal/load drift; repeat or alternate matched runs when plausible.

For durations, report speedup as `baseline / candidate` and reduction as `1 - candidate / baseline`; never label the ratio a latency-reduction percentage. Report throughput rate increases separately.

## Measure services under load

Record latency distributions (p50/p95/p99 as appropriate), counts, offered load, achieved throughput, errors/timeouts and saturation. Separate success/failure latencies so fast failures cannot imply improvement. Compare errors and tails at matched offered load; means hide tails. Measure queue waits/dependency spans alongside handlers. [SRE monitoring](https://sre.google/sre-book/monitoring-distributed-systems/)

Match the load model to the question: closed-loop clients await completion and can reduce offered load under slowdown; arrival-rate models schedule independently to test target demand. Describe the model when claiming capacity. Report dropped/unscheduled and completed work; rule out a generator bottleneck. [k6 workload models](https://grafana.com/docs/k6/latest/using-k6/scenarios/concepts/open-vs-closed/)

Sweep the expected operating range; watch queues, pools and downstream capacity. More workers/queue slots cannot create unlimited throughput. Measure overload/recovery, bound expensive queued work, and evaluate latency/error tradeoffs. [Overload handling](https://sre.google/sre-book/handling-overload/) [Queue management](https://sre.google/sre-book/addressing-cascading-failures/)

## Prevent regressions

Keep compact benchmarks for representative sizes/distributions tied to the accepted optimization. Compare an appropriate baseline on a stable runner; investigate changes exceeding both measured noise and practical budgets. Preserve timing artifacts/configuration; avoid unconditional millisecond assertions on arbitrary CI hosts.

Use ASV for recurring commit-history, environment and parameter-grid comparisons. Timing setup normally lies outside the measured method, but repeated invocations may reuse state. Peak-memory measurement includes setup, which can confound results. Use fresh processes for import/startup. [ASV usage](https://asv.readthedocs.io/en/stable/using.html) [Lifecycle](https://asv.readthedocs.io/en/stable/writing_benchmarks.html)

Report workload/environment, correctness checks, before/after values and units, variability/sample design, bottleneck evidence, tradeoffs and remaining limits. Label unmeasured changes as unverified hypotheses.

## Reject misleading measurements

Repeat equivalent work and inspect variability; never present one elapsed run as reliable speedup. Investigate instability/outliers and disclose exclusions. Require representative scaling and an uninstrumented end-to-end workload, with consumption/awaited completion inside the intended timing boundary.
