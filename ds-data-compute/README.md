# ds-data-compute

Consolidated skill for high-performance tabular/array compute, host resource
planning, NVIDIA GPU acceleration, serverless Modal execution, and DataLad
provenance. [SKILL.md](SKILL.md) is a short orchestrator that routes to two
independently readable references, loaded only when the task needs them:

- [references/tabular-and-arrays.md](references/tabular-and-arrays.md) —
  decision matrix, APIs, chunking/streaming patterns, and gotchas for Polars,
  Dask, Vaex, and Zarr-Python.
- [references/gpu-cloud-provenance.md](references/gpu-cloud-provenance.md) —
  redacted host/cgroup resource discovery (`get-available-resources`),
  evidence-driven NVIDIA GPU optimization (CuPy, RAPIDS, KvikIO, Warp,
  Numba-CUDA), serverless Modal cloud GPUs, and DataLad + `git-annex`
  provenance.

## Install and use

Copy the complete `ds-data-compute/` directory into your agent's skills
directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ds-data-compute ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ds-data-compute@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ds-data-compute
```

Examples:
- "Migrate this slow pandas ETL pipeline to lazy streaming Polars and sink to Parquet."
- "Set up a Dask Array + Zarr v3 pipeline with Blosc/Zstd compression and ~100 MiB chunks."
- "Accelerate this scikit-learn and NumPy workflow with cuML/CuPy and benchmark with CUDA warmup."
- "Deploy a Qwen inference service on Modal L40S GPUs with a persistent Volume."
- "Clone an OpenNeuro dataset with DataLad, fetch subject 01, and record a `datalad run` step."

## Sources and adaptation

Condensed on 2026-11-16 from eight upstream skills in
[K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills)
(MIT, commit `ec59a29a03d5c40f73ab40878df04860bc00e876`, see
[LICENSE.upstream](LICENSE.upstream)):

- `skills/polars/SKILL.md`
- `skills/dask/SKILL.md`
- `skills/vaex/SKILL.md`
- `skills/zarr-python/SKILL.md`
- `skills/optimize-for-gpu/SKILL.md`
- `skills/modal/SKILL.md`
- `skills/get-available-resources/SKILL.md`
- `skills/datalad/SKILL.md`

These references are condensed derivatives, not vendored copies. Overlapping
workflows and upstream repository boilerplate were deduplicated into two
domain-grouped guides while preserving core CLI flags, APIs, decision matrices,
and gotchas.

Validation: YAML frontmatter, local reference links, and line-count/structure
checks against `ml-architecture-data/`. Commands and Python APIs target the
consumer's compute/cloud environment and were not executed live here.
