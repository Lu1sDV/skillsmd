# Tabular & Array Compute: Polars, Dask, Vaex & Zarr

Guide to high-performance DataFrames, out-of-core/distributed arrays, and chunked scientific storage.

## Tool Selection

| Tool | Best For | Execution Model | Scale / Memory | Key Gotcha |
|---|---|---|---|---|
| **Polars** | Fast single-node ETL, SQL-like analytics, pandas migration | Multi-threaded Rust + Arrow; lazy query optimizer + streaming | Fits RAM (or spills/sinks via `streaming`) | `with_columns` expressions see the same input schema; `null` != `NaN` |
| **Dask** | Scaling pandas/NumPy beyond RAM or across clusters; custom task graphs | Lazy DAGs (`DataFrame`, `Array`, `Bag`) + `Futures` | Multi-core to multi-node TB+ | `.compute()` / `client.gather()` pull full results into client RAM |
| **Vaex** | Repeated reductions, histograms, and virtual columns on static local HDF5/Arrow | Memory-mapped out-of-core expressions; immediate reductions | Single machine, larger-than-RAM | Sorting, joins, `.to_numpy()`, `.materialize()` allocate RAM; Python <=3.12 |
| **Zarr-Python** | Chunked N-D array storage, partial reads, cloud object stores (S3/GCS) | Persistent hierarchical array/group store (v2 & v3 formats) | TB+ on local disk or object storage | Unwritten chunks return `fill_value`; `z[:]` materializes full array |

---

## Polars (`polars==1.44.2`)

Columnar DataFrame library (Python 3.10+) with Arrow interoperability and automatic parallelization.

### Install

```bash
uv pip install "polars==1.44.2"
uv pip install "polars[excel,database,fsspec,pandas,numpy]==1.44.2"
```

### Lazy vs Eager & Streaming

Prefer `scan_*` (`LazyFrame`) over `read_*` (`DataFrame`) for large inputs to enable predicate/projection pushdown and parallel query optimization:

```python
import polars as pl

lf = pl.scan_parquet("data/*.parquet")  # or pl.scan_csv("file.csv")
q = (
    lf.filter(pl.col("age") > 25, pl.col("city") == "NY")
    .select("name", (pl.col("age") * 12).alias("age_months"))
)
df = q.collect()                       # Materializes result in RAM
df_stream = q.collect(engine="streaming")  # Lower peak intermediate RAM
q.sink_parquet("output.parquet")       # Direct out-of-core file output
```

Inspect query plans with `q.explain()` and lazy schemas with `lf.collect_schema()`.

### Expressions, Aggregations & Window Functions

```python
# Add/transform columns in parallel (all see the same input schema)
df = df.with_columns(
    age_plus_10=pl.col("age") + 10,
    tag=pl.when(pl.col("age") >= 30).then(pl.lit("senior")).otherwise(pl.lit("junior")),
    norm_val=pl.col("^.*_value$") * 2,  # Regex column selector
)

# Group by + conditional aggregation
summary = df.group_by("city").agg(
    avg_age=pl.col("age").mean(),
    n_rows=pl.len(),
    over_30=(pl.col("age") > 30).sum(),
)

# Window functions preserve row count
df = df.with_columns(
    city_avg=pl.col("age").mean().over("city"),
    city_rank=pl.col("salary").rank().over("city"),
)
```

`over(..., mapping_strategy=...)`: `group_to_rows` (default, broadcasts scalars), `explode` (changes row count; use in `select`), `join` (attaches lists; high memory).

### Joins, Concatenation & Reshaping

```python
df1.join(df2, on="id", how="inner", validate="m:1")
df1.join(df2, left_on="user_id", right_on="id", how="left")

pl.concat([df1, df2], how="vertical")           # Stack rows
pl.concat([df1, df2], how="horizontal_extend")  # Add columns
pl.concat([df1, df2], how="diagonal")           # Union differing schemas

df.pivot(on="product", values="sales", index="date")
df.unpivot(index="id", on=["col1", "col2"])
```

### Pandas Migration

| Operation | Pandas | Polars |
|---|---|---|
| Select | `df["col"]` | `df.select("col")` |
| Filter | `df[df["col"] > 10]` | `df.filter(pl.col("col") > 10)` |
| Add column | `df.assign(x=...)` | `df.with_columns(x=...)` |
| Group by | `df.groupby("col").agg(...)` | `df.group_by("col").agg(...)` |
| Window | `df.groupby("col").transform(...)` | `df.with_columns(pl.col("x").mean().over("col"))` |

### Gotchas & Validation

- **No row index**: integer positions only; preserve IDs as strings (`schema_overrides={"sample_id": pl.String}`) to keep leading zeros.
- **Null vs NaN**: `fill_null(0)` does not fix `NaN`; check `is_nan()` and `is_finite()` separately.
- **Counts**: `pl.len()` counts all rows; `.count()` excludes `null`; `.n_unique()` includes `null`.
- **Chained dependencies**: chain `.with_columns(...)` calls when one new column depends on another.
- **Default joins** do not match `null` keys; sort within subject before lags, rolling windows, or `join_asof` with explicit tolerance.
- **Testing**: compare eager vs streaming on bounded fixtures with `polars.testing.assert_frame_equal`.

---

## Dask (`dask==2026.8.0`)

Parallel and distributed computing (Python 3.10+, pandas 2+, PyArrow 16+). Since 2025.1.0, query-planned DataFrames are the only implementation (do not install `dask-expr` or disable `dataframe.query-planning`).

### Install

```bash
uv pip install "dask[array,dataframe]==2026.8.0"
uv pip install "dask[complete]==2026.8.0"  # Includes distributed scheduler & dashboard
uv pip install s3fs gcsfs                  # Optional cloud object storage
```

### Five Core Components

1. **DataFrames (`dask.dataframe`)** — Parallel pandas over partitioned CSV/Parquet:
   ```python
   import dask.dataframe as dd

   ddf = dd.read_parquet("data/2024-*.parquet")
   summary = (
       ddf[ddf["value"] > 100]
       .groupby("category")
       .agg(amount_sum=("value", "sum"), amount_mean=("value", "mean"))
   )
   summary.to_parquet("output/summary.parquet")
   ```
   Use `map_partitions` for custom per-partition transforms; never load locally with `pd.read_csv` then `dd.from_pandas`.

2. **Arrays (`dask.array`)** — Blocked NumPy (~100 MiB target chunk size):
   ```python
   import dask.array as da

   x = da.from_zarr("large_dataset.zarr")
   scale = x.std()
   normalized = (x - x.mean()) / da.where(scale > 0, scale, 1)
   da.to_zarr(normalized, "normalized.zarr", mode="w-")
   ```
   Use `map_blocks` for custom chunk-wise array kernels; rechunk before reductions along poorly aligned axes.

3. **Bags (`dask.bag`)** — Streaming functional ETL for logs/JSON, then convert to DataFrame:
   ```python
   import dask.bag as db, json

   bag = db.read_text("logs/*.json").map(json.loads).filter(lambda x: x["status"] == "valid")
   ddf = bag.map(lambda x: {"id": x["id"], "value": x["value"]}).to_dataframe(
       meta={"id": "int64", "value": "float64"}
   )
   ```
   Prefer `foldby` over `groupby` on Bags.

4. **Futures (`dask.distributed`)** — Eager task-based parallelism (~1 ms overhead per task):
   ```python
   from dask.distributed import Client

   if __name__ == "__main__":
       with Client() as client:
           [data] = client.scatter([large_obj])  # Broadcast once
           futures = [client.submit(process, data, p) for p in params]
           results = client.gather(futures)
   ```

5. **Schedulers**:
   - `threads` (default): GIL-releasing NumPy/pandas numeric work.
   - `processes`: GIL-bound pure Python / text parsing (incurs serialization cost).
   - `synchronous`: single-threaded debugging with `pdb`.
   - `distributed` (`Client()`): multi-core/multi-node + diagnostic dashboard (`client.dashboard_link`).

### Performance & Memory Rules

- Guard process/distributed scripts with `if __name__ == "__main__":` and close `Client()`/`Cluster` cleanly.
- Batch independent `.compute()` calls via `dask.compute(a, b, c)` instead of calling `.compute()` in a loop.
- Check graph size with `len(ddf.__dask_graph__())`; fuse ops with `map_partitions`/`map_blocks` or increase chunk size if graphs reach millions of tasks.
- `.compute()` and `client.gather()` materialize results in **client** memory; `persist()` keeps partitions in **worker** memory (release when done).

---

## Vaex (`vaex-core==4.19.0`)

Single-machine out-of-core columnar DataFrame (Python 3.9–3.12 only; `pandas<3`, `numpy<3`, `dask<2024.9`). Best for repeated reductions and 2D histograms over local HDF5/Arrow files.

### Install

```bash
uv venv --python 3.12 .venv-vaex
uv pip install --python .venv-vaex/bin/python "vaex-core==4.19.0" "vaex-hdf5==0.15.0" "vaex-viz==0.6.0" "vaex-ml==0.19.0"
```

### Delayed Expressions & Export Pattern

```python
import vaex

df = vaex.open("input.hdf5")       # Memory-mapped HDF5/Arrow; CSV/Parquet require indexing/decoding
df["energy"] = df.x ** 2 + df.y    # Virtual column (deferred)
selected = df[df.x >= 3]

# Batch independent reductions into a single pass
mean_task = selected.energy.mean(delay=True)
count_task = selected.count(delay=True)
selected.execute()
print(count_task.get(), mean_task.get())

# Grouped aggregation with explicit vaex.agg objects
summary = df.groupby("category", agg={"rows": vaex.agg.count(), "e_sum": vaex.agg.sum("energy")})

# Chunked export evaluates virtual columns without materialize()
df.export_hdf5("output.hdf5", chunk_size=1_000_000)
```

### Gotchas

- `df.x.mean()` executes immediately; pass `delay=True` + `df.execute()` to batch passes.
- `Expression.quantile` is not a core 4.19.0 API; use `df.percentile_approx("x", percentage=50)`.
- `join` defaults to `how="left"` and accepts one key expression per side; extract filtered inputs before joining if filter defines membership.
- **Memory traps**: sorting, joins, large group dicts, `.values`, `.to_numpy()`, unchunked `.to_pandas_df()`, `.materialize()`, and `sklearn` `.fit()` allocate full arrays in RAM.
- State files can contain serialized executable objects; load only trusted state files.

---

## Zarr-Python (`zarr==3.4.0`)

Chunked N-D array and hierarchical group store (Python 3.12+, NumPy 2+). Reads/writes Zarr format 2 and 3; new arrays default to format 3.

### Install

```bash
uv pip install "zarr==3.4.0" "numpy==2.5.3"
uv pip install "zarr[remote,cli]==3.4.0" "fsspec==2026.9.0" "s3fs==2026.9.0" "gcsfs==2026.8.1"
```

### Arrays, Codecs, Indexing & Resize

```python
import numpy as np, zarr
from zarr.codecs import BloscCodec

z = zarr.create_array(
    "array.zarr",
    shape=(12, 8),
    dtype="float32",
    chunks=(4, 4),
    zarr_format=3,
    compressors=BloscCodec(cname="zstd", clevel=5, shuffle="bitshuffle"),
    dimension_names=("sample", "feature"),
    attributes={"units": "arbitrary"},
)
z[0:4] = np.ones((4, 8), dtype="float32")

reopened = zarr.open_array("array.zarr", mode="r")
v = reopened.vindex[[0, 5], [2, 7]]  # Coordinate indexing -> shape (2,)
o = reopened.oindex[[0, 5], [2, 7]]  # Orthogonal product -> shape (2, 2)
b = reopened.blocks[0, 0]            # Exact chunk read -> shape (4, 4)
```

- Pass either `data=` or `shape=` + `dtype=` to `create_array` (never both).
- Format-3 default numeric codec is bytes + `ZstdCodec`; set `compressors=` explicitly for reproducibility.
- `append(arr, axis=0)` and `resize((new_shape))`: shrinking removes out-of-bounds chunks, but retained boundary chunk values can reappear on re-expansion (not secure erasure).

### Groups, Concurrency & Gotchas

```python
root = zarr.open_group("hierarchy.zarr", mode="w-", zarr_format=3)
temp = root.create_group("temperature")
temp.create_array("t2m", data=np.full((3, 4, 6), 280, dtype="f4"), chunks=(1, 4, 6))
root.require_array("count", shape=(3,), chunks=(3,), dtype="i4")
print(root.tree())
```

- Use `create_array` / `require_array` (`create_dataset` / `require_dataset` are removed in v3). `require_array` validates compatibility; it does not rechunk.
- Use `mode="w-"` (fail if exists) or `mode="r"` (read-only); `mode="w"` destroys existing stores.
- **Parallel writes**: assign one writer per chunk (or per **shard** when sharding is enabled, where shard dims are multiples of chunk dims). Serialize metadata, append, and resize operations.
- Unwritten/missing chunks read as `fill_value`; `np.asarray(z)` or `z[:]` materializes the entire array. Negative-step slices are unsupported.
- Format-3 metadata consolidation is experimental; refresh after metadata edits and verify downstream readers.
