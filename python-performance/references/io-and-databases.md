# I/O and databases

Match documentation to deployed driver/database/framework versions. Hypothesize from measured waits, round trips, rows, and application work; validate with the same workload and semantics.

## Contents

- [Diagnose the boundary that consumes time](#diagnose-the-boundary-that-consumes-time)
- [Remove unnecessary work and round trips](#remove-unnecessary-work-and-round-trips)
- [Stream and batch through the whole pipeline](#stream-and-batch-through-the-whole-pipeline)
- [Measure file and serialization costs](#measure-file-and-serialization-costs)
- [Reuse network clients, then control demand](#reuse-network-clients-then-control-demand)

## Diagnose the boundary that consumes time

Attribute waits before rewriting CPU code. Use spans/timings to separate request latency, query count, rows/bytes, pool wait, database/DBAPI execution, fetching, type conversion, ORM construction, and application/response work. Python profiles alone cannot establish database inefficiency. Check Cartesian products: huge fetches can precede small Python results. After SQLAlchemy upgrades, inspect compilation-cache warnings before rewriting. [SQLAlchemy performance](https://docs.sqlalchemy.org/en/20/faq/performance.html)

For PostgreSQL, inspect `EXPLAIN`; use `EXPLAIN (ANALYZE, BUFFERS)` on representative, authorized queries for actual rows/buffers. Compare estimated/actual rows, join fan-out, repeated loops, scan selectivity, sorting/spilling. Sequential scans can be appropriate; cost units are not milliseconds. Measure end-to-end latency separately for omitted client/network work. `ANALYZE` executes statements, including writes/functions; avoid casual production mutations. [Using EXPLAIN](https://www.postgresql.org/docs/18/using-explain.html), [EXPLAIN command](https://www.postgresql.org/docs/18/sql-explain.html)

## Remove unnecessary work and round trips

Detect N+1 via query-count growth with result size; compare eager loading or equivalent set operations. In Django, use `select_related()` for known single-valued relationships, `prefetch_related()` deliberately for collections. Prefetch materializes data; later filtered relation queries may bypass its cache. Avoid unused rows/columns; push suitable filters/aggregations into SQL. Use `exists()`/`count()` only when that answer alone is required; reuse already-needed results instead of adding preliminary queries. Use bulk operations to reduce statements; verify changed per-object hooks/signals. Add indexes from plan evidence; account for write overhead. [Django optimization](https://docs.djangoproject.com/en/6.0/topics/db/optimization/), [QuerySets](https://docs.djangoproject.com/en/6.0/ref/models/querysets/)

For an existing `Order.customer` foreign key and `Order.lines` reverse relation:

```python
orders = (
    Order.objects.filter(status="open")
    .select_related("customer")
    .prefetch_related("lines")
)
```

Compare joins, prefetching, projection, and bounded batches using query count, fan-out/row volume, bytes, memory/RSS, and latency. Minimizing queries alone can produce prohibitively large joins/prefetches.

Compare `execute` loops with `executemany` under identical transaction boundaries/durability; parameter-bind both. Report batching separately from transaction consolidation: per-row versus final commit changes more than execution APIs. [sqlite3 transactions/executemany](https://docs.python.org/3/library/sqlite3.html)

## Stream and batch through the whole pipeline

For SQLAlchemy 2.x, try `select(Model).execution_options(yield_per=batch_size)` to bound row/object buffering, subject to driver support. Iterate results/partitions; `.all()` defeats streaming. Verify server-side cursors/eager-loading compatibility: collection joined/subquery eager loading and `Result.unique()` conflict with `yield_per`; select-in loading depends on driver cursor support. [Large-result fetching](https://docs.sqlalchemy.org/en/20/orm/queryguide/api.html#fetching-large-result-sets-with-yield-per)

Bound read buffers, queues, active operations, and retained output throughout the pipeline. Avoid accumulating all records, precreating all tasks, or serializing everything at the end. `asyncio.Queue(maxsize=N)`, `N > 0`, blocks `put()` when full; zero is unbounded. Pair it with fixed workers for backpressure; semaphores cannot bound already-created tasks. [Asyncio queues](https://docs.python.org/3/library/asyncio-queue.html)

Before streaming batch work, establish input snapshot stability and whether output may precede complete transformation success. Preserve ordering/failure barriers. Consider transactional output/external staging for bounded RAM; account for space, latency, cleanup. Specify ownership of reused mutable input buffers. Streaming alone does not preserve batch semantics.

Choose batch sizes by measuring throughput, tail latency, peak memory, cancellation responsiveness. Preserve transactions/consistency: smaller fetches do not authorize separate commits within atomic operations. Include deployed encoding, compression, parsing, serialization in end-to-end measurements; API choice guarantees no speedup.

## Measure file and serialization costs

Before changing storage, measure reading, decoding, parsing, transformation, encoding, writing separately. Use buffered I/O/bounded chunks where formats permit; `readinto()` reuses buffers only when consumers do not retain them. Preserve decoding/newline handling when switching to binary. Line iteration is bounded by the largest line. [Python streams](https://docs.python.org/3.14/library/io.html)

Evaluate `os.scandir()` for metadata-heavy traversal to reuse enumeration information; preserve symlink behavior and handle stale cached `DirEntry` data. Benchmark actual `mmap` access patterns: mapping retains I/O costs and slices are not universally zero-copy. Preserve read/write modes and lifetime rules. [scandir](https://docs.python.org/3.14/library/os.html#os.scandir), [mmap](https://docs.python.org/3.14/library/mmap.html)

Remove redundant serialize/parse cycles. Compare size, CPU, memory, downstream compatibility before changing encoders/compression/formats. Preserve JSON framing: repeated `json.dump()` calls alone do not form one valid document. Preserve Unicode, number, non-finite-value, and custom-type behavior when replacing serializers. [JSON](https://docs.python.org/3.14/library/json.html)

Report warm/cold filesystem-cache conditions. Avoid silently flushing shared host caches; use controlled environments and record measured conditions.

## Reuse network clients, then control demand

Reuse scoped HTTPX `Client`/`AsyncClient` pools across related requests; avoid hot-loop recreation. Verify handshake/connection counts. Close clients/streaming responses reliably; manual streaming requires explicit cleanup. [HTTPX clients](https://www.python-httpx.org/advanced/clients/), [async support](https://www.python-httpx.org/async/)

Set concurrency/connection limits from measured capacity; pools do not bound pending jobs. Distinguish connect/read/write/pool timeouts: read/write apply to inactivity while receiving/sending chunks, pool measures connection acquisition. Preserve separate application deadlines where required; these are not total request deadlines. When throughput plateaus, locate downstream saturation through throughput, errors, queue/pool waits; track queue depth, peak memory, p95/p99. [HTTPX limits](https://www.python-httpx.org/advanced/resource-limits/), [timeouts](https://www.python-httpx.org/advanced/timeouts/)

With HTTPX installed, bounded/lazy `urls`, and `consume(bytes)` processing without retaining responses, use this pattern. Choose production limits from measurements; these numbers only illustrate configuration:

```python
import httpx

timeout = httpx.Timeout(10.0, connect=3.0, pool=2.0)
limits = httpx.Limits(max_connections=20, max_keepalive_connections=10)

with httpx.Client(timeout=timeout, limits=limits) as client:
    for url in urls:
        with client.stream("GET", url) as response:
            response.raise_for_status()
            for chunk in response.iter_bytes():
                consume(chunk)  # Process without retaining the entire response.
```

Use async to overlap compatible I/O; `async def` leaves blocking bodies/CPU-heavy parsing capable of stalling the loop. Move demonstrated blocking work to an appropriate executor or redesign it; measure executor overhead/downstream load. Async cannot fix unnecessary queries or saturated dependencies. [Asyncio blocking code](https://docs.python.org/3/library/asyncio-dev.html#running-blocking-code)

Give each concurrent task its own SQLAlchemy `AsyncSession`/transaction context. Engine/pool reuse does not make mutable transactions safe to share. [Async sessions](https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html#using-asyncsession-with-concurrent-tasks)
