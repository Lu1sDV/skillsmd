# Sources and scope

Research reviewed **2026-10-23**. Match claims and commands to installed versions;
rolling documentation can change after review.

## Provenance

Starting point: sickn33's [python-performance-optimization](https://www.skills.sh/sickn33/agentic-awesome-skills/python-performance-optimization),
its [SKILL.md](https://github.com/sickn33/agentic-awesome-skills/blob/main/skills/python-performance-optimization/SKILL.md)
and delegated [implementation playbook](https://github.com/sickn33/agentic-awesome-skills/blob/main/skills/python-performance-optimization/resources/implementation-playbook.md).
Both were reviewed; this bundle rewrites the guidance from primary documentation.
Popularity does not establish applicability.

Reviewed SHA-256 fingerprints:

- SKILL.md: `674f8695f32b129e8f314980974c5954620be787e6b44cf91b9da30dd7155fc6`
- Playbook: `fe8d13f436730cc6140d8c81b14d3a5ea7276675fe5b60696e4ccb3b7d284bb7`

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
| Profilers, clocks, modes and compatibility | [CPython](https://docs.python.org/3.14/library/profile.html), [sampling](https://docs.python.org/3.15/library/profiling.sampling.html), [time](https://docs.python.org/3.14/library/time.html) |
| Calibration, warm-up, workers and comparisons | [pyperf](https://pyperf.readthedocs.io/en/latest/), [timeit](https://docs.python.org/3.14/library/timeit.html), [ASV](https://asv.readthedocs.io/en/stable/) |
| Tool commands, support and visibility | [py-spy](https://github.com/benfred/py-spy), [line_profiler](https://kernprof.readthedocs.io/en/latest/), [Scalene](https://github.com/plasma-umass/scalene), [Memray](https://bloomberg.github.io/memray/) |
| Memory, retention, caches and collectors | [tracemalloc](https://docs.python.org/3.14/library/tracemalloc.html), [sys](https://docs.python.org/3.14/library/sys.html), [functools](https://docs.python.org/3.14/library/functools.html), [gc](https://docs.python.org/3.14/library/gc.html) |
| Container costs and buffering | [collections](https://docs.python.org/3.14/library/collections.html), [bisect](https://docs.python.org/3.14/library/bisect.html), [heapq](https://docs.python.org/3.14/library/heapq.html), [itertools](https://docs.python.org/3.14/library/itertools.html) |
| Tasks, failures, isolation, starts and GIL | [asyncio](https://docs.python.org/3.14/library/asyncio-task.html), [executors](https://docs.python.org/3.14/library/concurrent.futures.html), [multiprocessing](https://docs.python.org/3.14/library/multiprocessing.html), [free threading](https://docs.python.org/3.15/howto/free-threading-python.html) |
| Quotas, saturation and offered load | [Linux cgroups](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html), [Google SRE](https://sre.google/sre-book/monitoring-distributed-systems/), [k6](https://grafana.com/docs/k6/latest/using-k6/scenarios/concepts/open-vs-closed/) |
| Queries, plans, transactions, pools and timeouts | [Django](https://docs.djangoproject.com/en/6.0/topics/db/optimization/), [SQLAlchemy](https://docs.sqlalchemy.org/en/20/faq/performance.html), [PostgreSQL](https://www.postgresql.org/docs/18/sql-explain.html), [HTTPX](https://www.python-httpx.org/advanced/clients/) |
| Copies, dtypes, native operations and compilation | [NumPy](https://numpy.org/doc/stable/), [pandas](https://pandas.pydata.org/docs/), [Numba](https://numba.readthedocs.io/en/stable/user/performance-tips.html), [Cython](https://docs.cython.org/en/stable/src/userguide/numpy_tutorial.html) |
| Device timing and allocator metrics | [PyTorch CUDA](https://docs.pytorch.org/docs/2.14/notes/cuda.html) |

## Version gates

| Feature | Gate/check | Source |
|---|---|---|
| Slotted dataclasses | `slots=True` 3.10+; `weakref_slot=True` 3.11+ | [dataclasses](https://docs.python.org/3.14/library/dataclasses.html) |
| Structured tasks | TaskGroup 3.11+; preserve failures/cancellation | [asyncio](https://docs.python.org/3.14/library/asyncio-task.html) |
| Iterator batching | `itertools.batched` 3.12+ | [itertools](https://docs.python.org/3.14/library/itertools.html) |
| Free threading | Optional 3.13+; supported 3.14+; check live GIL after imports | [PEP 779](https://peps.python.org/pep-0779/), [how-to](https://docs.python.org/3.15/howto/free-threading-python.html) |
| Executor buffering/interpreters | `buffersize`, InterpreterPoolExecutor 3.14+ | [executors](https://docs.python.org/3.14/library/concurrent.futures.html) |
| Process starts | Defaults changed in 3.14; inspect platform/context | [multiprocessing](https://docs.python.org/3.14/library/multiprocessing.html) |
| Standard-library sampling | `profiling.sampling` 3.15+; match minor version/build on attach | [sampling](https://docs.python.org/3.15/library/profiling.sampling.html) |
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
