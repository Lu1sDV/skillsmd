# Numerical and data workloads

Read for measured numerical kernels, dataframe operations, conversions or accelerator work. Check deployed versions before applying version-sensitive guidance.

## Establish the numerical contract

Record shapes, dtypes, layout/strides, missing values, input ranges, output shape and tolerance. Include production conversion/allocation costs; benchmark realistic sizes to expose setup amortization. Treat overflow behavior, NaNs/infinities, signed zero, reduction order, mutation, aliasing and index alignment as correctness constraints. Verify domain requirements before changing representation.

Account for unbounded Python integers versus fixed-range NumPy integer dtypes; check intermediate products/accumulations as well as input ranges before replacing arithmetic. [NumPy data types](https://numpy.org/doc/stable/user/basics.types.html)

## Replace Python callbacks with native operations

Prefer suitable NumPy ufuncs/reductions and pandas built-in aggregations. Verify where expensive work executes: a batch-looking API need not be native. Do not prescribe `numpy.vectorize` for speed; it is essentially a loop/interface convenience. [NumPy vectorize](https://numpy.org/doc/stable/reference/generated/numpy.vectorize.html)

Prefer equivalent column operations to row iteration. When iteration is necessary, assess `itertuples()` over `iterrows()`, which constructs Series and may coerce row dtypes. Do not rely on mutating iterated objects to update the original frame. [pandas iteration](https://pandas.pydata.org/docs/user_guide/basics.html#iteration)

## Budget temporaries, views and copies

Compute intermediate shapes before broadcasting: input repetition is avoided, but outputs/chained intermediates can be enormous. For pairwise `(N, M, D)` temporaries, compare blocked evaluation or mathematical reformulation; check numerical stability. [NumPy broadcasting](https://numpy.org/doc/stable/user/basics.broadcasting.html)

Check view aliasing/lifetime: basic slicing usually shares storage; advanced indexing copies; reshape may copy if strides forbid a view. Copy a small slice when needed to release its large parent. Do not infer ownership/independence from small `nbytes`. [NumPy copies and views](https://numpy.org/doc/stable/user/basics.copies.html)

Use ufunc `out=`/safe in-place operations for measured temporary-allocation costs. Specify ownership, dtype, shape and aliasing; preserve inputs callers still need. Prepare independent `float64` arrays `a`, `b`, `c` with identical shapes for this example:

```python
import numpy as np

result = np.empty_like(a)
np.multiply(a, b, out=result)
np.add(result, c, out=result)
```

Reuse this single output buffer without promising zero internal temporaries for every layout/overlap. Recheck expressions with different broadcasting/dtype rules. [NumPy ufuncs](https://numpy.org/doc/stable/reference/ufuncs.html)

Read only required pandas columns; choose representations; inspect `memory_usage(deep=True)`. Chunk only independently computable or mergeable partial results; plan separately for global sorts, large joins and non-composable operations. Migrate engines only when size/measured bottlenecks justify the cost. [pandas scaling](https://pandas.pydata.org/docs/user_guide/scale.html)

## Apply version-specific pandas mutation rules

For pandas 3.0+, apply Copy-on-Write: indexing/assignment treats derived objects as independent; chained assignment cannot update originals. Do not assume recursive copies of Python objects in object-dtype cells. Use one explicit assignment, e.g. `df.loc[mask, "value"] = replacement`. Drop unnecessary aliases that would trigger later copies. Prioritize ownership/API semantics over blanket `inplace=True`, removing `.copy()`, or forcing returned NumPy arrays writable. Recheck older configurations separately. [CoW migration](https://pandas.pydata.org/docs/user_guide/migration.html#copy-on-write-cow), [pandas 3.0](https://pandas.pydata.org/docs/whatsnew/v3.0.0.html), [DataFrame.copy](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.copy.html)

## Compile measured kernels safely

Use Numba for narrow numerical hot paths with supported types/operations, not whole dataframe/service pipelines. Compile explicit loops instead of manufacturing giant broadcast temporaries. Use `@njit` for clear intent; `@jit` defaults to nopython since 0.59, so do not assume automatic object-mode fallback. Keep `fastmath=False` unless relaxed floating-point semantics are acceptable. Validate changed parallel-reduction order; verify `parallel=True` transformations succeeded and iterations cannot race. [Numba performance tips](https://numba.readthedocs.io/en/stable/user/performance-tips.html), [parallelization](https://numba.readthedocs.io/en/stable/user/parallel.html)

Separate compilation/first-call latency from repeated runs of already-compiled relevant signatures. Include startup for short-lived deployments; check Python/NumPy/Numba compatibility before runtime upgrades. [Numba five-minute guide](https://numba.readthedocs.io/en/stable/user/5minguide.html)

Use Cython when measured kernels benefit from typed loops/native-library integration and the project supports compilation/distribution. Use annotation to find remaining Python operations. Disable bounds/negative-index checks only with proven valid indices and maintained coverage: invalid accesses can corrupt memory/crash instead of raising Python exceptions. [Cython NumPy tutorial](https://docs.cython.org/en/stable/src/userguide/numpy_tutorial.html)

Benchmark pandas `eval`/NumExpr on representative complex expressions at meaningful scale; parsing/compilation can outweigh gains for small/simple expressions. Prefer ordinary operations without demonstrated benefit. [pandas enhancing performance](https://pandas.pydata.org/docs/user_guide/enhancingperf.html)

## Control every parallelism layer

Try threads for suitable NumPy kernels that release the GIL; object-dtype operations are an exception on ordinary GIL-enabled CPython. Use independent worker-owned arrays/read-only sharing. Shared writes/resizing can race/crash; free-threading removes additional protections. [NumPy thread safety](https://numpy.org/doc/stable/reference/thread_safety.html)

Inspect BLAS/OpenMP backends/thread settings. Outer process/thread pools plus internally threaded BLAS/Numba can oversubscribe. Test one deliberate layer or cap each; record actual settings in benchmark metadata. Check backend-specific controls and environment settings read at initialization. [NumPy global configuration](https://numpy.org/doc/stable/reference/global_state.html)

## Measure existing accelerator workloads

Separate device execution from host enqueue time. Time asynchronous PyTorch CUDA operations with properly placed CUDA events or interval synchronization. Warm the intended workload; report initialization separately; include deployment-paid host/device transfers end to end. Record shapes, batch size, precision and device. Separate live tensor from allocator-reserved memory; measure host memory independently. Do not infer a leak from allocator caches in `nvidia-smi`, or synchronize every operation if it changes the concurrency being measured. [PyTorch CUDA semantics](https://docs.pytorch.org/docs/2.14/notes/cuda.html)
