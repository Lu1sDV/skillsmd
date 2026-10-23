# Antipattern review

Use the relevant section after diagnosis. Treat alternatives as experiments;
linked guides supply applicability, commands and primary evidence.

## Measurement

Read [benchmarking](benchmarking.md) and [profiling](profiling.md).

| Avoid | Reason and check |
|---|---|
| Optimize visually complex code | It may contribute little; profile representative execution and quantify impact. |
| `time.time()` for short durations | Clock adjustments distort intervals; use a monotonic elapsed clock with explicit units/boundary. |
| One-call proof | Startup, caches and noise confound differences; repeat matched work and inspect variability. |
| Python/native comparisons under cProfile | Instrumentation differs by path; attribute with profiles, compare unprofiled. |
| Adding cumulative profile rows | Parent/child time overlaps; inspect call paths, self time and counts. |
| Flame graph as chronology | Width aggregates the selected sample metric; use a timeline for event order. |
| Timing generator/coroutine creation | Work is deferred; consume/await the required result within the boundary. |
| Reusing mutated/exhausted inputs | Later iterations do different work; reset or deliberately measure application reuse. |
| Benchmarking cache hits for miss-heavy deployment | Match hit/miss mix, cold costs and invalidation. |
| Omitting required conversion/setup/transfers | Kernel gains may vanish; measure kernel and complete operation separately. |
| Treating insignificant results as equivalence | Report effect, uncertainty and a practical threshold. |
| Lowering mean latency through fast failures | Compare tails, errors, offered load and achieved throughput together. |
| Concurrent benchmarks on a constrained host | Experiments interfere; run comparisons sequentially under controlled load. |
| Fixed timing assertions on arbitrary CI hosts | Noise becomes regressions; use stable runners, raw artifacts and noise-informed budgets/triage. |

## Algorithms and representation

Read [algorithms and Python](algorithms-and-python.md).

| Avoid | Reason and check |
|---|---|
| Expression tuning inside repeated quadratic scans | Reduce operation count; compare indexing, aggregation or algorithms across sizes. |
| Building a set for each membership test | Construction may outweigh lookup savings; include build cost and reuse. |
| Replacing first-match scans with dict comprehensions | Last duplicate wins; specify and test the duplicate policy. |
| Large FIFO via `list.pop(0)` | Front removal shifts elements; evaluate deque with equivalent order/capacity. |
| Calling `insort` logarithmic | Position search excludes linear insertion; measure the whole update and its frequency. |
| Full sorting for tiny top-k | Unneeded ordering costs work; compare heap selection or `min/max`. |
| Repeated growing concatenation | Copying harms scaling; evaluate join, extend, buffers or incremental output. |
| Universal map/local-alias/inlining speed claims | Callable and interpreter behavior vary; measure supported runtimes and the actual hot path. |
| Rewrites justified only by a toy benchmark | Require material end-to-end benefit after maintenance cost. |
| Expensive disabled log messages | Formatting/arguments run eagerly; defer formatting and guard expensive construction. |

## Memory and caching

Read [memory and caching](memory-and-caching.md).

| Avoid | Reason and check |
|---|---|
| Whole-object comparisons with `getsizeof` | Referents/separate dictionaries are missing; compare equivalent populations and retained/peak memory. |
| Calling temporary allocations leaks | Objects may be released; repeat lifecycles and identify retained ownership. |
| Treating high RSS after `del` as a leak | Allocators, sharing and native memory affect RSS; correlate traces and repeated growth. |
| Two snapshots for all transient peaks | Allocations can disappear between snapshots; add peak windows/allocation traces. |
| Calling any generator pipeline constant-memory | Bound all retained stages, buffers and largest records; measure end-to-end peak. |
| Free iterator copying via `tee` | Consumer lag causes buffering; measure lag or redesign consumption. |
| Unbounded caching over arbitrary inputs | Cardinality may grow indefinitely; set entry/byte limits, eviction and hit-rate criteria. |
| Thread-safe cache means one computation per miss | Concurrent misses can duplicate work; coordinate per key when needed. |
| Caching coroutine/generator objects | Reuse differs from immutable values; cache appropriate materialized results with lifetime rules. |
| Weak mappings as guaranteed reuse caches | Objects disappear when other ownership ends; use bounded strong caching when required. |
| Per-request collection or blind GC disabling | Collection cost, cycles and runtime vary; measure activity before a targeted change. |
| Removing every copy | Aliasing/backing-buffer retention can worsen; check ownership and total retained memory. |

## Concurrency and runtime

Read [concurrency and runtime](concurrency-and-runtime.md).

| Avoid | Reason and check |
|---|---|
| Assuming all Python threads have identical CPU limits | Native GIL release/free-threaded builds differ; inspect operation, build and live GIL. |
| Adding `async` to CPU loops | Synchronous work occupies the loop; remove work or evaluate suitable offloading. |
| Millions of semaphore-guarded tasks | Active work is bounded, allocated tasks are not; bound admission/queues with fixed workers. |
| More workers after throughput plateaus | Quotas, bandwidth, locks/dependencies may saturate; sweep capacity while tracking queues, errors and memory. |
| Workers multiplied by unlimited native threads | Budget concurrency across all layers. |
| Tiny jobs/huge payloads in fresh process pools | Startup/transfer may dominate; reuse workers, batch, compact payloads and measure total cost. |
| Forcing `fork` to recreate old results | Platform, start methods and threads interact; choose supported contexts and verify correctness. |
| Interpreter workers as shared-global threads | State is isolated and values serialized; design communication and measure transfer cost. |
| Assuming timeout means running work stopped | Cancellation may affect only pending work; verify cleanup and remaining resource use. |
| Deferring every import | Errors/side effects and latency move; measure startup/first use and test registration/initialization. |

## I/O and numerical work

Read [I/O and databases](io-and-databases.md) and [numerical and data](numerical-and-data.md).

| Avoid | Reason and check |
|---|---|
| Query per result row | Round trips scale with cardinality; measure query count and selective eager/set loading. |
| Indexing every queried column | Selectivity, storage and write costs differ; use plans and representative reads/writes. |
| Minimal query count through huge joins | Fan-out inflates transfer/construction; compare bytes, memory and latency. |
| Per-row versus bulk commits as an API comparison | Transactions also changed; hold semantics constant or report consolidation separately. |
| New network client per request | Setup may dominate; reuse scoped clients and measure pooling/connection behavior. |
| Per-operation timeout as total deadline | Chunk activity can extend duration; enforce an end-to-end deadline. |
| Shared AsyncSession across tasks | Mutable transaction state is not task-isolated; assign appropriate sessions/transactions. |
| `numpy.vectorize` as compiled execution | It remains a convenience loop; evaluate native operations or measured compiled kernels. |
| Huge broadcast pairwise intermediates | Input broadcasting does not bound output allocation; calculate shapes and consider blocks. |
| Unchecked Python-int to fixed-width conversion | Intermediates can overflow; establish range/precision before conversion. |
| Blanket `inplace=True` or `.copy()` removal | Version, aliasing and Copy-on-Write matter; inspect semantics and allocations. |
| Default `fastmath`/disabled bounds checks | Numerical/memory-safety contracts change; prove assumptions and validate the domain. |
| Confusing JIT compilation and steady state | Deployment pays different costs; report first-call and warm execution with correct boundaries. |
| GPU enqueue timing as completion | Device execution is asynchronous; use framework timing/synchronization and relevant transfers. |
