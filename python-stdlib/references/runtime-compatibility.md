# Runtime compatibility and removed APIs

Baseline: **CPython 3.15.2**, checked **2026-11-03** against the
[release page](https://www.python.org/downloads/release/python-3152/).
At a future refresh, verify the latest final release and use its versioned
documentation. A PEP's schedule or a development documentation page does not prove
that a feature ships in the deployed interpreter.

## Check the actual runtime

Inspect `python -VV`, implementation, OS, declared `requires-python`, deployment
image and lockfile. Gate a change on supported runtime APIs and dependency
compatibility, not syntax acceptance alone. Keep an existing project's supported
floor unless a migration is part of the task; use 3.15 for new examples here.

`sys.stdlib_module_names` identifies top-level stdlib names for this Python
version. It includes modules disabled at build time or unavailable on the current
platform. Membership does not establish importability, an available submodule or
an installed third-party distribution. An actual import can also fail because a
shared library or transitive dependency is missing; preserve that diagnosis.

## Focused migration checks

| Change | Action at this boundary |
|---|---|
| 3.15 enables UTF-8 mode by default | Keep explicit encodings when a format contract requires them. For deliberately locale-based content, request `encoding="locale"`; test legacy files rather than silently replacing decode errors. |
| 3.15 makes `sqlite3.connect` options keyword-only after `database` | Use named options. Check positional-only callback registration signatures when upgrading. |
| 3.15 rejects `strptime` day-of-month formats without a year | Parse a real year, or supply an explicit leap-year context for a month/day contract. Never silently assume the current year. |
| 3.15 removes loader `load_module` support | Use the documented `exec_module` import protocol; test plugin initialization and side effects. |
| 3.14 removes `sqlite3.version` / `version_info` | Inspect `sqlite3.sqlite_version` for the linked SQLite engine; it is distinct from the Python version. |
| 3.14 removes `pkgutil.get_loader` / `find_loader` | Use `importlib.util.find_spec`; finding a submodule may import its parent. |
| 3.13 removes legacy modules including `cgi` and `telnetlib`; 3.12 removes `distutils` and `imp` | Consult the removal notes and actual packaging/protocol needs. Do not install a similarly named package as an automatic substitute. |

This table selects relevant failure points; it is not a complete release catalogue.
For syntax, annotations, sentinels and lazy-import semantics, use **python-idiomatic**
or **python-api-design** when installed. For process-start, free-threaded build and
asyncio policy changes, use **python-concurrency**.

Check warnings in the narrow affected path before a cutover, then exercise the
real file, process or database boundary under the target interpreter. Do not
silence a deprecation to make the migration appear complete. If runtime evidence
and versioned documentation disagree, record the exact patch/build and reproduce
the smallest case before turning either into a universal rule.

## Authorities

- [Python 3.15 porting and removals](https://docs.python.org/3.15/whatsnew/3.15.html)
- [Python 3.14 removals](https://docs.python.org/3.15/whatsnew/3.14.html#removed)
- [Python 3.13 removed modules](https://docs.python.org/3.15/whatsnew/3.13.html#removed-modules-and-apis)
- [Python 3.12 removals](https://docs.python.org/3.15/whatsnew/3.12.html#removed)
- [UTF-8 mode contract](https://docs.python.org/3.15/library/os.html#python-utf-8-mode)
- [Stdlib name inventory](https://docs.python.org/3.15/library/sys.html#sys.stdlib_module_names)
- [Finding a module](https://docs.python.org/3.15/library/importlib.html#importlib.util.find_spec)
