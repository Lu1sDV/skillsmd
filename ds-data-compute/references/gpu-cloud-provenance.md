# GPU Optimization, Cloud Compute & Data Provenance

Guide to host resource discovery, NVIDIA GPU acceleration, serverless Modal deployment, and DataLad provenance.

## 1. Resource Discovery & Planning (`get-available-resources`)

Build a conservative picture of resources available to the **current process** before sizing workers, memory budgets, or GPU jobs. Keep host inventory, process affinity, cgroup v2 limits, Slurm allocations, and accelerator runtime usability separate.

### Safety Contract

- Run detection only when requested or needed for resource planning; emit JSON to stdout by default (use `--output file.json` only for explicit local `.json` files, mode `0600`).
- **Never** run stress tests, large allocations, write probes, device resets, driver installs, or dump environment variables.
- **Never** emit hostnames, absolute paths, cgroup paths, job IDs, device UUIDs, PCI addresses, or raw visibility-variable values.
- Treat missing observations as `unknown` (never `unlimited`). Never assume visible host CPUs, RAM, or GPUs are usable inside a container or scheduler allocation.

### CLI Workflow

```bash
python scripts/detect_resources.py                                   # Redacted JSON to stdout
uv run --no-project --with "psutil==7.2.2" python scripts/detect_resources.py  # Broader OS coverage
python scripts/detect_resources.py --skip-accelerators               # Skip GPU CLI probes
python scripts/detect_resources.py --output resource-snapshot.json

python scripts/plan_workload.py resource-snapshot.json \
  --workload cpu --tasks 100 --memory-per-worker-mib 2048            # cpu|mixed|io; --accelerator none|any|cuda|rocm|metal
python scripts/snapshot_tools.py validate resource-snapshot.json
python scripts/snapshot_tools.py diff before.json after.json
python scripts/accelerator_diagnostics.py resource-snapshot.json --backend auto
```

### Interpretation Rules

- **CPU**: `cpu.cgroup_v2.quota_cores` (`cpu.max`) is bandwidth capacity (can be fractional, e.g., `1.5`), not physical cores; `cpu.process.affinity_logical` and `cpuset_logical` constrain placement. Use `suggested_workers * threads_per_worker` together so BLAS/OpenMP threads do not oversubscribe workers.
- **Memory**: `memory.max` is the hard cgroup cap; `memory.high` is a throttle boundary. On Apple Silicon (`unified_cpu_gpu`), do not add integrated GPU memory to host RAM.
- **Accelerators**: Management-CLI visibility (`nvidia-smi`, ROCm, Metal) marks a **candidate** only (`runtime_compatibility: not_tested`). It does not prove container permission, driver/CUDA compatibility, or framework support.
- **Planner status**: `insufficient_memory` (0 workers) means do not launch; `review_required` means CPU or memory is unknown.

---

## 2. NVIDIA GPU Optimization (`optimize-for-gpu`)

Reviewed against RAPIDS 26.08, CuPy 14.2, Numba-CUDA 0.30.4, and Warp 1.17 (Python 3.11–3.14 on Linux/WSL2, CUDA 12/13). Treat GPU porting as evidence-driven: preserve numerical contracts and keep GPU code only when synchronized end-to-end benchmarks show a net win.

### Layer Selection Matrix

Prefer the smallest, highest-level maintained library before writing custom kernels:

| Existing Workload | Preferred Path | Notes |
|---|---|---|
| NumPy / SciPy | **CuPy** | Arrays, sparse matrices, linalg, FFTs, signal |
| pandas | **`cudf.pandas`** -> **cuDF** | Zero-code-change accelerator first; native API for control |
| scikit-learn | **`cuml.accel`** -> **cuML** | Accelerator mode first; native estimators as needed |
| NetworkX | **`nx-cugraph`** -> **cuGraph** | Backend dispatch first; native graph API at scale |
| scikit-image / WSI | **cuCIM** | GPU image processing and whole-slide imaging |
| Faiss / Annoy / k-NN | **cuVS** | Exact and approximate vector search (report recall@k) |
| Raw / S3 / HTTP / Zarr I/O | **KvikIO** | GPU buffers and GPUDirect Storage (GDS) |
| Custom array kernels | **Numba-CUDA-MLIR** (new) / **Numba-CUDA** (existing) | Explicit SIMT kernels and shared memory |
| Spatial / differentiable sims | **Warp** (kernels) / **Newton** (physics engine) | Geometry, SDFs, robotics, autodiff (`warp.sim` removed -> Newton) |
| Low-level RAPIDS primitives | **RAFT** (`pylibraft`) | Sparse eigensolvers, multi-GPU resources |

- **PyTorch / JAX / TensorFlow**: do **not** port out of these frameworks; remove CPU round trips and use their native compilers, profilers, AMP, and batching.
- **Legacy-only**: `cuxfilter` (final 26.06; use cuDF + HoloViews/hvPlot/Datashader) and `cuSpatial` (archived 25.04; use GeoPandas/Shapely + cuDF).

### 7-Step Optimization Workflow

1. **Baseline**: capture representative inputs, tolerances, and end-to-end timing (I/O + transfer + compute + output). Profile CPU first.
2. **Suitability**: GPU helps when work is data-parallel, amortizes launch/transfer overhead, and fits VRAM with temporary buffers. Avoid GPU for tiny, sequential, or host-device ping-pong workloads.
3. **Least disruptive path**: framework-native -> accelerator mode (`cudf.pandas`, `cuml.accel`, `nx-cugraph`) -> native GPU API -> custom kernel.
4. **Coherent GPU data path**: transfer once, keep intermediates on device, reuse buffers (`out=`), fuse elementwise ops, use CUDA Array Interface / DLPack for zero-copy interchange (verify dtype/contiguity/stream).
5. **Validate semantics**: compare CPU vs GPU on deterministic fixtures (NaNs, ordering, dtypes); check accelerator logs for silent CPU fallbacks.
6. **Benchmark properly**: GPU calls are asynchronous; warm up context/JIT, then use CUDA events or `cupyx.profiler.benchmark`:
   ```python
   from cupyx.profiler import benchmark
   print(benchmark(gpu_fn, (arg1, arg2), n_warmup=10, n_repeat=100))
   ```
   Use `nsys` (Nsight Systems) for timelines and `ncu` (Nsight Compute) for kernels. Note CuPy's memory pool retains freed blocks (`nvidia-smi` staying high is not automatically a leak).
7. **Keep, revise, or reject**: retain only if correctness passes and end-to-end metrics improve.

---

## 3. Serverless Cloud & GPUs (`modal==1.6.0`)

Serverless Python containers and on-demand GPUs (Python 3.10–3.14).

### Install & Auth

```bash
uv pip install "modal==1.6.0"
modal setup  # Or set MODAL_TOKEN_ID and MODAL_TOKEN_SECRET (or .modal.toml)
```

Read only `MODAL_TOKEN_ID` and `MODAL_TOKEN_SECRET`; never forward platform tokens into workload containers or dump `.env`.

### Images, GPUs & Lifecycle Classes

```python
import modal

app = modal.App("ml-service")
image = (
    modal.Image.debian_slim(python_version="3.11")
    .uv_pip_install("torch==2.12.0", "transformers==5.9.0")
    .apt_install("git")
)

@app.cls(gpu="L40S", image=image, max_containers=10, scaledown_window=300)
class Predictor:
    @modal.enter()
    def load(self):
        self.model = ...  # Runs once per container startup

    @modal.method()
    def predict(self, text: str):
        return self.model(text)

    @modal.exit()
    def cleanup(self):
        ...
```

- **GPU strings** (deprecated `modal.gpu.*` removed): `T4`, `L4`, `A10` (up to 4/container), `L40S` (48 GB, inference sweet spot), `A100-40GB`, `A100-80GB`, `RTX-PRO-6000` (96 GB), `H100`, `H200`, `B200`, `B200+`, `B300` (B200+/B300 need CUDA 13.1+).
- Multi-GPU: `gpu="H100:4"` (up to 8/container). Fallback list: `gpu=["H100", "A100-80GB"]`. Pin exact tier (prevent free auto-upgrade): `gpu="H100!"`.
- Resources: `@app.function(cpu=4.0, memory=16384, ephemeral_disk=51200, timeout=3600)` (physical cores, MiB, seconds).

### Volumes, Secrets, Endpoints, Scheduling & Scaling

- **Volumes** (write-once, read-many):
  ```python
  vol = modal.Volume.from_name("model-weights", create_if_missing=True)
  # Producer: close files -> vol.commit()
  # Consumer: close open handles -> vol.reload() -> read
  # Read-only mount: vol.with_mount_options(read_only=True, sub_path="subset")
  ```
- **Secrets**: `secrets=[modal.Secret.from_name("my-keys")]` or `modal.Secret.from_dotenv()`.
- **Web endpoints**: `@modal.fastapi_endpoint(method="POST", requires_proxy_auth=True)` (up to 4 GiB request body).
- **Schedules**: `schedule=modal.Cron("0 9 * * *")` or `modal.Period(hours=6)` (activated via `modal deploy`).
- **Concurrency & parallel map**: `@modal.concurrent(max_inputs=10, target_inputs=8)`, `list(fn.map(items))`, runtime override via `Cls.from_name(...).with_options(gpu="H200", max_containers=20)`.

### Sandboxes (Untrusted Code)

```python
app = modal.App.lookup("sandbox-demo", create_if_missing=True)
sb = modal.Sandbox.create(app=app, image=modal.Image.debian_slim(), block_network=True, timeout=60)
try:
    sb.filesystem.write_text("print(2 ** 10)\n", "/tmp/job.py")
    proc = sb.exec("python", "/tmp/job.py")
    out = proc.stdout.read()
    proc.wait()
finally:
    sb.terminate(wait=True)
```

Use `outbound_cidr_allowlist=[...]` when egress is needed; `sb.snapshot_filesystem()` has a 30-day default TTL.

### CLI Quick Reference

`modal run script.py` | `modal serve script.py` (hot reload) | `modal deploy script.py` | `modal volume ls/put/get` | `modal secret create/list` | `modal app list/stop`

---

## 4. Data Versioning & Provenance (`datalad==1.6.5`)

Data management over Git (small text/code/history) + `git-annex` 10.x (large binary content keys). Use plain Git for pure-code repos; use DataLad for large/remote datasets, nested subdatasets, or machine-readable execution provenance.

### Install

```bash
uv pip install git-annex "datalad==1.6.5" "datalad-container==1.2.6"
datalad wtf --section dependencies  # Verify git-annex is on PATH
```

### Clone & Fetch (Pointers Are Not Data)

`datalad clone` downloads Git history and symlinks/pointers into `.git/annex/objects/`—**not** file bytes:

```bash
datalad clone https://github.com/OpenNeuroDatasets/ds000001.git
datalad get sub-01/anat/sub-01_T1w.nii.gz  # Fetch file bytes
datalad get -n -r .                        # Install subdataset structure without bytes
datalad status --annex availability        # Check local presence
git annex whereis sub-01/                  # Recorded remote locations (offline)
```

### Provenance (`run`, `rerun`, `containers-run`)

```bash
# Clean worktree required (or --explicit); --input fetches, --output unlocks target
datalad run -m "extract brain" \
  --input "sub-01/anat/sub-01_T1w.nii.gz" \
  --output "derivatives/sub-01_brain.nii.gz" \
  "bet {inputs[0]} {outputs[0]} -m"

datalad rerun --report                     # Inspect plan
datalad rerun --since <commit> -b check    # Replay range onto new branch

# Tracked container provenance (Apptainer/Singularity/Docker)
datalad containers-add fsl --url /path/to/fsl.sif --call-fmt 'apptainer exec {img} {cmd}'
datalad containers-run -n fsl -m "run in container" --input in.nii.gz --output out.nii.gz "bet {inputs[0]} {outputs[0]}"
```

Placeholders: `{inputs}`, `{outputs}`, `{inputs[0]}`, `{pwd}`, `{dspath}`, `{tmpdir}`. Do not hand-edit the JSON block between `=== Do not change lines below ===` and `^^^ Do not change lines above ^^^`.

### Create, Save, Publish & Drop

```bash
datalad create -c yoda my_analysis         # YODA layout (code/, README.md, CHANGELOG.md in Git)
datalad create -d . inputs/raw             # Register nested subdataset
datalad save -m "notes" --to-git notes.md  # Force small text into Git

# Publish Git sibling + git-annex storage remote together
datalad create-sibling-github mydataset
git annex initremote store type=S3 bucket=my-bucket protocol=https encryption=none autoenable=true
datalad siblings configure -s github --publish-depends store
datalad push --to github

datalad drop sub-01/                       # Free local bytes (checks remote copy first)
```

### Failure Modes

| Symptom | Cause | Fix |
|---|---|---|
| Empty/truncated/broken symlink on read | Unfetched annex pointer | `datalad get <path>` |
| Permission denied writing output | Annexed file is write-protected | Pass `--output <path>` to `run`, or `datalad unlock` |
| `datalad run` refuses to start | Unsaved changes in dataset | `datalad save` first, or `--explicit` |
| `datalad drop` refuses | No verified second copy | Push to storage sibling first |
| Collaborators clone, `get` fails | Git pushed without storage remote | Set `--publish-depends <storage-sibling>` |
