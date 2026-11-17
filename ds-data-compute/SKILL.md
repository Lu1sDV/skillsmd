---
name: ds-data-compute
description: >
  Use when processing large tabular datasets or chunked N-D arrays (Polars,
  Dask, Vaex, Zarr), discovering host/container CPU/memory/GPU limits before
  launching workloads, accelerating scientific Python on NVIDIA GPUs (RAPIDS,
  CuPy, Numba-CUDA, Warp, KvikIO), deploying serverless GPU jobs on Modal, or
  versioning datasets and computational provenance with DataLad. Triggers on
  'polars', 'dask', 'vaex', 'zarr', 'cuDF', 'CuPy', 'RAPIDS', 'modal',
  'datalad', 'git-annex', 'get-available-resources', or 'out-of-core'.
---

# Data Science Compute, Storage & Provenance

Two capabilities, one reference each. Open only the reference the task needs;
do not preload all.

| Task / Tool | Read |
|---|---|
| Tabular & array compute: Polars (lazy/streaming), Dask (DataFrame/Array/Bag/Futures), Vaex (out-of-core HDF5/Arrow), Zarr-Python (chunked v3 arrays) | [Tabular & arrays reference](references/tabular-and-arrays.md) |
| Resource discovery (`get-available-resources`), NVIDIA GPU acceleration (CuPy, RAPIDS, Warp, KvikIO), Modal serverless GPUs, DataLad/git-annex provenance | [GPU, cloud & provenance reference](references/gpu-cloud-provenance.md) |

## What each covers

- **Tabular & arrays** — Selection matrix, lazy/streaming execution (`scan_*`, `sink_parquet`, `dask.compute`), chunking & sharding (`~100 MiB` Dask chunks, Zarr v3 codecs & `vindex`/`oindex`), out-of-core Vaex `delay=True` batching, and pandas-to-Polars migration.
- **GPU, cloud & provenance** — Redacted host/cgroup/Slurm resource snapshots and worker planning, evidence-driven NVIDIA GPU porting (`cudf.pandas`/`cuml.accel`/`nx-cugraph` -> native RAPIDS/CuPy -> Warp/Numba-CUDA) with synchronized benchmarking, Modal `App`/`Image`/`Volume`/`Sandbox` cloud GPUs, and DataLad `get`/`run`/`rerun`/`containers-run` + sibling publishing.

## Universal rules

- Check effective CPU, cgroup/Slurm memory, and disk limits before sizing workers or chunked arrays; never equate `unknown` with `unlimited` or visible host GPUs with container usability.
- Prefer lazy/streaming execution (`pl.scan_*`, `sink_parquet`, Dask graphs, Vaex `delay=True`) and bounded Zarr slices over materializing full datasets in driver/client RAM.
- Keep GPU porting evidence-driven: try framework-native or zero-code accelerators (`cudf.pandas`, `cuml.accel`, `nx-cugraph`) first, validate numerical parity, and benchmark with warmup + CUDA synchronization.
- On Modal, commit/reload Volumes explicitly across producer-consumer boundaries and run untrusted code inside `modal.Sandbox` with `block_network=True`.
- With DataLad, always `datalad get` before reading annexed pointers, declare `--input`/`--output` on `datalad run`, and configure `--publish-depends` so storage siblings push before Git history.
