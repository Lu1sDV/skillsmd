# Algorithms and Python

## Reduce work

Measure scaling with input size, distribution, skew and output cardinality. Count
operations and bytes moved: repeated scans, nested joins, aggregates, sorting and
serialization can dominate expression costs; even an efficient join can produce a
large legitimate output. Filter/project early and hoist invariants only when values,
errors and side-effect timing remain equivalent. Check mathematical shortcuts against
the numerical domain.

For a fixed sequential workload, bound a candidate with Amdahl's law:
`speedup = 1 / ((1 - f) + f / s)` for affected fraction `f` and local speedup `s`.
Reassess the model for queueing, saturation or changed workload sizes.

## Match structure to access

| Need | Candidate | Check |
|---|---|---|
| Repeated membership/key lookup | `set`/`dict` | Hashability, equality/hash cost, construction amortization, memory, duplicates, invalidation; expected lookup cost is not a worst-case constant-time guarantee |
| FIFO | `deque.popleft()` | List front removal shifts elements; bounded deque drops old entries rather than applying backpressure |
| Stack/indexed access | `list.append/pop`, indexing | Avoid long-list `pop(0)` and repeated deque middle indexing |
| Sorted range lookup | `bisect`, precomputed keys | Preserve sorted order; `insort` insertion remains linear |
| Small top-k | `heapq.nsmallest/nlargest` | Compare full sorting as k grows; use `min/max` for one extremum |
| Expensive ordering keys | `sorted(..., key=...)` | One key evaluation per item; preserve stability and mutation rules |
| Homogeneous numbers | `array.array` or existing numerical arrays | Range, precision, byte width, conversion and downstream work |

Sources: [CPython dictionaries](https://docs.python.org/3.14/faq/design.html#how-are-dictionaries-implemented-in-cpython),
[deque](https://docs.python.org/3.14/library/collections.html#collections.deque),
[heapq](https://docs.python.org/3.14/library/heapq.html),
[bisect](https://docs.python.org/3.14/library/bisect.html#performance-notes),
[sorting](https://docs.python.org/3.14/howto/sorting.html).

## Preserve index semantics

A dict comprehension keeps the last duplicate; a scan may return the first:

```python
def index_first(records):
    by_id = {}
    for record in records:
        by_id.setdefault(record["id"], record)
    return by_id
```

Preserve equality/hash contracts and mutable record identity; copying changes
aliasing and cost. Maintain/rebuild indexes after mutation. Test duplicates, missing
keys, empty inputs, ordering and realistic distributions. Include construction unless
application reuse justifies a separate measurement. Eager indexing can expose errors
in records a short-circuiting scan never reads; preserve required error timing.
[Dictionary behavior](https://docs.python.org/3.14/library/stdtypes.html#mapping-types-dict).

## Control construction and iteration

- Use comprehensions for materialization and generators for incremental consumption;
  neither guarantees faster execution. Consume the work when timing. Generators are
  normally single-use; count producer/consumer retention, buffers and largest record.
- Consider `chain.from_iterable` for incremental flattening; avoid
  `sum(list_of_lists, [])` and repeated growing concatenation. Use `itertools.batched`
  (3.12+) with measured, bounded batches. `tee` buffers consumer lag; `product` pools
  inputs. Iterator APIs do not guarantee bounded memory. [itertools](https://docs.python.org/3.14/library/itertools.html)
- For text, evaluate `str.join`/`io.StringIO`; for bytes, `bytes.join`, `bytearray`
  or a buffered sink. Stream when consumer semantics permit. Final joins still
  allocate the result; interpreter concatenation optimizations are not portable
  guarantees. [Sequences](https://docs.python.org/3.14/library/stdtypes.html#common-sequence-operations)
- Prefer suitable reductions/library algorithms that remove Python work. A built-in
  need not be implemented in C or beat a better algorithm.

## Avoid repeated parsing and logging

Inspect encode/decode cycles, repeated validation, object/dict/JSON round trips and
per-item configuration. Improve boundary representation; retain required validation.
Cache only stable results with ownership/invalidation rules.

Use equivalent literal operations for literal matching. Account for `re`'s recent
pattern cache before claiming explicit compilation helps. Test long inputs and near
misses for backtracking; atomic groups/possessive quantifiers (3.11+) can change
matches. [re](https://docs.python.org/3.14/library/re.html)

Defer log formatting; guard expensive argument construction:

```python
if logger.isEnabledFor(logging.DEBUG):
    logger.debug("batch summary: %s", build_expensive_summary(batch))
```

F-strings and argument expressions execute before level filtering. For slow handlers,
evaluate queueing with capacity/shutdown policies; preserve required operational
records. [Logging optimization](https://docs.python.org/3.14/howto/logging.html#optimization),
[blocking handlers](https://docs.python.org/3.14/howto/logging-cookbook.html#dealing-with-handlers-that-block).

## Keep micro-optimizations conditional

Measure `map(lambda ...)`, local aliases, inlining, list preallocation and
exceptions-versus-checks on the actual hot path. Specialization, callable type,
distribution and warm-up affect results; require material benefit over readable code.
`python -O` removes assertions and changes `__debug__`; do not change correctness
through a benchmark-only mode. [CLI](https://docs.python.org/3.14/using/cmdline.html#cmdoption-O)
