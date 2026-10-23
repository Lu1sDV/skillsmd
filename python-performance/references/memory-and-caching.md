# Memory, ownership and caching

## Choose the metric

| Metric | Measures | Limits |
| --- | --- | --- |
| Live traced Python bytes | Retained traced allocations | Excludes some native allocations; not process total |
| Traced peak | Maximum traced bytes/interval | Neither RSS nor cumulative churn |
| Allocation volume/stacks | Allocation/free activity/sites | High churn need not imply retention |
| RSS | Resident physical memory | Shared pages/allocator retention; summed processes can double-count sharing |
| USS/PSS | Private/proportionally shared memory | Support, privileges and collection cost vary |
| Container/cgroup memory | Usage versus deployment limit | Includes children/other charged memory beyond one process |
| Shallow object size | Direct object storage | Excludes referents; cannot establish whole-graph savings |

Match metrics to objectives; correlate Python, process and deployment telemetry. Check installed [psutil](https://psutil.io/api/) RSS/USS/PSS APIs/platform collection methods. [`sys.getsizeof`](https://docs.python.org/3.14/library/sys.html#sys.getsizeof) excludes list elements and separate instance attribute dictionaries; extensions vary. Compare equivalent populations under matching ownership, never extrapolate one shallow size.

## Separate retention from peaks and allocator behavior

Trace before relevant allocations; compare steady-state snapshots at matching lifecycle boundaries for retention, peaks/allocation profiles for temporary bursts. More traceback frames improve attribution/increase overhead. Substitute this bounded example's workload placeholders. [tracemalloc](https://docs.python.org/3.14/library/tracemalloc.html)

```python
import tracemalloc

tracemalloc.start(10)
warm_up_application()
before = tracemalloc.take_snapshot()
tracemalloc.reset_peak()
run_representative_batch()
current_bytes, peak_bytes = tracemalloc.get_traced_memory()
after = tracemalloc.take_snapshot()
for entry in after.compare_to(before, "traceback")[:10]:
    print(entry)
print({"traced_current_bytes": current_bytes, "traced_peak_bytes": peak_bytes})
tracemalloc.stop()
```

Treat a list dropped between snapshots as temporary; inspect owners/eviction for buffers retained across batches. Freed objects need not lower RSS immediately: CPython/native pools, arenas and allocator policies retain memory; extensions can bypass Python's allocator. With stable traced bytes/rising RSS, inspect native allocations, mappings and process scope before alleging a Python reference leak. [CPython memory management](https://docs.python.org/3.14/c-api/memory.html)

## Find growing retention

1. Repeat equivalent warmed-up work; record input/request counts and memory after each completed batch.
2. Inspect cache cardinality, pools, queues, pending tasks/futures, accumulated results and telemetry buffers.
3. Compare traces; distinguish allocation sites from retaining owners. Investigate callbacks, closures, exception tracebacks and library-managed objects.
4. If Python traces cannot explain growth, correlate native allocation profiling with process/container usage. Verify platform, Python/build and native-stack support. [Memray](https://bloomberg.github.io/memray/)
5. Release suspected ownership in a controlled reproduction; repeat to check whether growth stops. One high watermark cannot establish a leak.

## Reduce representation and copy costs

Stream input, processing and output; bound queues, submissions, concurrency and retained results. Estimate baseline + active workers × per-worker footprint + queued payloads + temporary overlap; measure actual peak.

Use suitable homogeneous buffers: `array.array`, numerical arrays, bytes or memoryviews. Preserve width, signedness, precision, layout and ownership. Memoryviews avoid some copies but retain exporters; small views can retain large allocations. [array](https://docs.python.org/3.14/library/array.html), [memoryview](https://docs.python.org/3.14/library/stdtypes.html#memoryview)

Evaluate `__slots__` or `@dataclass(slots=True)` (3.10+) for many fixed-layout instances. Check inheritance, dynamic attributes, serialization, descriptors/weakrefs; base/subclass `__dict__` can defeat savings. Slotted dataclasses require 3.11 for `weakref_slot=True`. Measure population memory and creation/access time; promise no fixed saving. [Slots](https://docs.python.org/3.14/reference/datamodel.html#slots), [dataclasses](https://docs.python.org/3.14/library/dataclasses.html)

Remove unnecessary copies; keep those breaking unwanted aliasing or releasing larger backing buffers. Account for NumPy views, dataframe Copy-on-Write and temporaries.

## Budget caches

Confirm repeated keys/expensive reusable work. Define keys, validity, result ownership, eviction, failure policy and observability. Measure misses, hits, realistic mixtures, entries, retained bytes/invalidation; include user-paid initialization.

Use `lru_cache` for hashable arguments/stable results. Capacity bounds entries, not bytes; `cache`/`maxsize=None` are unbounded. The cache retains arguments/results, including method `self`. Thread-safe storage permits duplicate concurrent-miss computation. Do not cache coroutines/generators/side effects as reusable values. [functools](https://docs.python.org/3.14/library/functools.html)

Start bounded; verify reuse. Specify service invalidation/stampede control; account for duplicate per-process caches/inconsistent state and incorrect stale/shared mutable hits.

## Inspect GC and weak references precisely

Use `gc` statistics/targeted cycle inspection. Require evidence for per-request `gc.collect()`, global disabling or copied thresholds. `DEBUG_SAVEALL` retains unreachable objects; `gc.get_referrers` has incomplete extension visibility and may see objects under construction. Check the exact runtime before tuning: collector details can change in patch releases. [gc](https://docs.python.org/3.14/library/gc.html)

Use weak mappings when another component owns lifetime. They prevent mapping-only retention, neither guarantee reuse nor replace capacity/TTL policies. Allow for values disappearing before lookup; require weak-reference-capable types. [weakref](https://docs.python.org/3.15/library/weakref.html)
