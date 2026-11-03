# Sources and scope

Review baseline **CPython 3.15.2**, verified **2026-11-03** against the
[stable release page](https://www.python.org/downloads/release/python-3152/).
Match tools/dependencies to the actual build; rolling documentation can change
after review. This skill targets the latest stable release at maintenance time,
without silently changing an existing project's declared support policy.

## Contents

- [Provenance](#provenance)
- [Community curation](#community-curation)
- [Evidence policy](#evidence-policy)
- [Primary authorities](#primary-authorities)
- [Version gates](#version-gates)
- [Maintenance](#maintenance)

## Provenance

Starting point: sickn33's [python-performance-optimization](https://www.skills.sh/sickn33/agentic-awesome-skills/python-performance-optimization),
its [SKILL.md](https://github.com/sickn33/agentic-awesome-skills/blob/main/skills/python-performance-optimization/SKILL.md)
and delegated [implementation playbook](https://github.com/sickn33/agentic-awesome-skills/blob/main/skills/python-performance-optimization/resources/implementation-playbook.md).
Both were reviewed; this bundle rewrites the guidance from primary documentation.
Popularity does not establish applicability.

Retain these historical **2026-10-23** audit fingerprints; they were not revalidated
in the current review and are not repository commit pins:

- SKILL.md SHA-256: `674f8695f32b129e8f314980974c5954620be787e6b44cf91b9da30dd7155fc6`
- Playbook SHA-256: `fe8d13f436730cc6140d8c81b14d3a5ea7276675fe5b60696e4ccb3b7d284bb7`

The discovery URLs are mutable. A fingerprint without the reviewed content or a
resolvable repository revision does not establish what a later reader retrieves;
verify provenance before claiming a pinned revision.

## Community curation

Retrieved candidates below identify useful gaps; their prescriptions are not
authoritative. This is targeted review, not an assertion that all entries in the
supplied community catalogue were re-audited. Local prose is a new synthesis;
maintainer references beside technical claims establish behavior.

| Retrieved candidate | Adopt / adapt | Exclude or qualify |
|---|---|---|
| [basitalisandhu profile reader](https://github.com/basitalisandhu/claude-skills/blob/main/plugins/debugging/skills/perf-profile-reader/SKILL.md) | Read self/cumulative time, follow repeated fan-out, estimate affected fraction, inspect stack dumps | GC is not inherently waiting; a flat/incomplete CPU profile does not prove I/O; no fixed capture duration suits every workload |
| [opum perf-measure](https://github.com/opum-ai/profile-skills/blob/main/skills/perf-measure/SKILL.md) and [perf-optimize](https://github.com/opum-ai/profile-skills/blob/main/skills/perf-optimize/SKILL.md) | A/A noise check, matched blocks, held-back workloads, bounded experiment budget, memory on both arms | No mandatory repository-specific comparison engine, universal significance/effect thresholds, or transferred tracer-overhead percentage |
| [clemux pytest profiling](https://github.com/clemux/agent-skills/blob/main/pytest-profiling/SKILL.md) | Separate collection/fixtures/body/teardown; diagnose serially and report normal runner separately | Do not discard the first run unconditionally, weaken test semantics, prescribe global fixture/hash changes, or treat wall sampling as exact CPU time |
| [Maxritz Python performance](https://github.com/Maxritz/MySkills/blob/main/python-perf/SKILL.md) | Native buffer lifetime, shape/dtype/aliasing and deployment-CPU contracts | No copied AVX/GPU/matrix kernel; existing numerical libraries and measured need remain the starting point |
| [mejbaurbahar resource testing](https://github.com/mejbaurbahar/software-tester-skills/blob/main/skills/memory-leak-resource-testing/SKILL.md) | Track descriptors, threads, connections and lifecycle troughs | Sawtooth shape is not a health test; rising RSS alone is not proof; no mandatory long soak or production forced-GC ritual |

NumPy migration facts were checked directly against
[2.4 release notes](https://numpy.org/doc/stable/release/2.4.0-notes.html);
the community `numpy-2-4-6` name is not a runtime compatibility declaration.
Keep older import/GC/version details only when they affect a current decision.

## Evidence policy

- **Behavior:** cite version-matched official manuals/maintainer docs and platform
  limits. Use accepted PEPs for design context; verify shipped behavior in runtime docs.
- **Recommendation:** state workload assumptions and tradeoffs; distinguish synthesis
  from upstream promises. Use first-party operational sources for load/queueing methods.
- **Improvement:** require an actual experiment, environment, correctness checks and limits.

Include content that changes diagnosis, implementation, correctness or validation.
Exclude unsupported rankings, transferred benchmark percentages, blanket speed claims,
promotional lists and popularity-based advice. Add infrastructure/engines only for an
observed need.

## Primary authorities

Detailed guides link claims directly; use this map for maintenance.

| Evidence | Sources |
|---|---|
| Profilers, clocks, modes and compatibility | [Tracing](https://docs.python.org/3.15/library/profiling.tracing.html), [sampling](https://docs.python.org/3.15/library/profiling.sampling.html), [time](https://docs.python.org/3.15/library/time.html) |
| Calibration, warm-up, workers and comparisons | [pyperf](https://pyperf.readthedocs.io/en/latest/), [timeit](https://docs.python.org/3.15/library/timeit.html), [ASV](https://asv.readthedocs.io/en/stable/) |
| Tool commands, support and visibility | [py-spy](https://github.com/benfred/py-spy), [line_profiler](https://kernprof.readthedocs.io/en/latest/), [Scalene](https://github.com/plasma-umass/scalene), [Memray](https://bloomberg.github.io/memray/) |
| Memory, retention, caches and collectors | [tracemalloc](https://docs.python.org/3.15/library/tracemalloc.html), [sys](https://docs.python.org/3.15/library/sys.html), [functools](https://docs.python.org/3.15/library/functools.html), [gc](https://docs.python.org/3.15/library/gc.html) |
| Container costs and buffering | [collections](https://docs.python.org/3.15/library/collections.html), [bisect](https://docs.python.org/3.15/library/bisect.html), [heapq](https://docs.python.org/3.15/library/heapq.html), [itertools](https://docs.python.org/3.15/library/itertools.html) |
| Tasks, failures, isolation, starts and GIL | [asyncio](https://docs.python.org/3.15/library/asyncio-task.html), [executors](https://docs.python.org/3.15/library/concurrent.futures.html), [multiprocessing](https://docs.python.org/3.15/library/multiprocessing.html), [free threading](https://docs.python.org/3.15/howto/free-threading-python.html) |
| Quotas, saturation and offered load | [Linux cgroups](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html), [Google SRE](https://sre.google/sre-book/monitoring-distributed-systems/), [k6](https://grafana.com/docs/k6/latest/using-k6/scenarios/concepts/open-vs-closed/) |
| Queries, plans, transactions, pools and timeouts | [Django](https://docs.djangoproject.com/en/6.1/topics/db/optimization/), [SQLAlchemy](https://docs.sqlalchemy.org/en/20/faq/performance.html), [PostgreSQL](https://www.postgresql.org/docs/18/sql-explain.html), [HTTPX](https://www.python-httpx.org/advanced/clients/) |
| Copies, dtypes, native operations and compilation | [NumPy](https://numpy.org/doc/stable/), [pandas](https://pandas.pydata.org/docs/), [Numba](https://numba.readthedocs.io/en/stable/user/performance-tips.html), [Cython](https://docs.cython.org/en/stable/src/userguide/numpy_tutorial.html) |
| Device timing and allocator metrics | [PyTorch CUDA](https://docs.pytorch.org/docs/2.14/notes/cuda.html) |

## Version gates

| Feature | Gate/check | Source |
|---|---|---|
| Slotted dataclasses | `slots=True` 3.10+; `weakref_slot=True` 3.11+ | [dataclasses](https://docs.python.org/3.15/library/dataclasses.html) |
| Structured tasks | TaskGroup 3.11+; preserve failures/cancellation | [asyncio](https://docs.python.org/3.15/library/asyncio-task.html) |
| Iterator batching | `itertools.batched` 3.12+ | [itertools](https://docs.python.org/3.15/library/itertools.html) |
| Free threading | Optional 3.13+; supported 3.14+; check live GIL after imports | [PEP 779](https://peps.python.org/pep-0779/), [how-to](https://docs.python.org/3.15/howto/free-threading-python.html) |
| Executor buffering/interpreters | `buffersize`, InterpreterPoolExecutor 3.14+ | [executors](https://docs.python.org/3.15/library/concurrent.futures.html) |
| Process starts | Defaults changed in 3.14; inspect platform/context | [multiprocessing](https://docs.python.org/3.15/library/multiprocessing.html) |
| Standard-library sampling | `profiling.sampling` 3.15+; match minor version/build on attach | [sampling](https://docs.python.org/3.15/library/profiling.sampling.html) |
| Deterministic profiling | `profiling.tracing` in 3.15; `cProfile` compatible alias; pure-Python `profile` deprecated in 3.15 | [tracing](https://docs.python.org/3.15/library/profiling.tracing.html), [profile](https://docs.python.org/3.15/library/profile.html) |
| Explicit lazy imports | 3.15+; deferred errors/side effects | [PEP 810](https://peps.python.org/pep-0810/) |
| pandas Copy-on-Write | Mandatory 3.0+; inspect older settings | [migration](https://pandas.pydata.org/docs/user_guide/migration.html#copy-on-write-cow) |
| Numba compilation default | `jit` defaults to nopython from 0.59; check types/versions | [Numba](https://numba.readthedocs.io/en/stable/user/performance-tips.html) |

Preserve deployment compatibility; these gates do not require upgrades. Check
patch-level behavior, especially GC, before tuning implementation-specific controls.

## Maintenance

Check installed `--help`, interpreter/platform/build support, versioned documentation,
redirects, release notes and upstream maintenance notices. For example,
[memory_profiler](https://github.com/pythonprofilers/memory_profiler)'s maintenance
notice affects new-tool selection without establishing that an existing use is broken.

Keep recipes in their topic guide and the entrypoint compact. Add topics only for
concrete gaps; revalidate examples and task routing after substantive changes.
