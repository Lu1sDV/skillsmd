# Imports, tools, and version boundaries

## Contents

- [Inspect before changing the environment](#inspect-before-changing-the-environment)
- [Imports are executable code](#imports-are-executable-code)
- [Formatting and static analysis](#formatting-and-static-analysis)
- [Debug and measure the actual workload](#debug-and-measure-the-actual-workload)
- [Version gates: preserve the declared minimum](#version-gates-preserve-the-declared-minimum)

## Inspect before changing the environment

Read `pyproject.toml`, the lockfile/requirements, supported interpreter range,
existing formatter/linter/type-checker configuration, and CI before choosing
commands. Use the project's environment manager, not a second overlapping stack.
A virtual environment isolates Python packages; it is not an OS sandbox or a
portable deployment artifact. Prefer `python -m pip` to bind installation to the
selected interpreter; activation is optional when invoking that environment's
Python explicitly. `pip freeze` is an environment snapshot, not a complete
cross-platform dependency-resolution policy.

Recipe (POSIX shell, Python with `venv` and pip available; does not install any
new dependency by itself):

```sh
python3 -m venv .venv
.venv/bin/python -m pip --version
.venv/bin/python -c 'import sys; print(sys.executable); print(sys.version)'
```

Windows uses `.venv\Scripts\python.exe`; activation differs between PowerShell
and cmd. For an existing uv project, follow its lockfile and `uv sync`/`uv run`
workflow. For pip-tools, use the project's compiled requirements and documented
sync command. Don't run multiple synchronizers on the same environment casually.
Packaging, `src` layout, build backends, entry points, and deployment are optional
**python-system-design** handoffs; no specific backend is mandatory here.

## Imports are executable code

An import executes module top-level code on initial load and caches the module
in `sys.modules`. Avoid network calls, file writes, CLI parsing, and expensive
setup on import. Guard script execution with `if __name__ == '__main__':` and use
`python -m package.module` when package-relative imports matter. Do not name your
file `json.py`, `typing.py`, or another dependency's module name. Inspect
`module.__file__`/`module.__spec__` when a surprising module is loaded.

Prefer explicit imports (including explicit reexports), group standard/third-party/
local imports according to existing tooling, and avoid `sys.path` hacks.
`__all__` controls wildcard exports, not privacy. `from module import name`
binds the current object; later rebinding `module.name` doesn't update that local
binding. Imported mutable objects can still be shared.

For a cycle, inspect the dependency graph and move genuinely shared definitions
to an appropriate lower-level module, or move orchestration out of mutually
importing models. A function-local import can defer a genuinely optional/expensive
dependency; ordinary import caching already exists, so do not build a second
module-global cache. Defer only for a reason: failures otherwise move from startup
to an arbitrary later call. `TYPE_CHECKING` imports are absent at runtime;
quoted/deferred annotations can still fail when introspection resolves them.

## Formatting and static analysis

Reuse repository tools and pinned versions. Ruff covers many lint and import
sorting rules, not every Pylint/Flake8 plugin or type check. Choose one formatter
(Ruff format or Black) rather than alternating both. Ruff's `I` rules can replace
isort for supported configurations; retain isort where the project requires it.
Mypy/Pyright check static contracts, not runtime input validity. Set their Python
target to the minimum supported version rather than the newest local Python.

Recipes, requiring the named tools already installed in the selected environment:

```sh
python -m ruff check .
python -m ruff format --check .
python -m mypy src/
```

Use `--fix`/format-writing commands only when intended, and inspect semantic
changes rather than treating tool suggestions as authority. Never disable broad
rule sets merely to hide a specific bug. Testing frameworks, fixtures, coverage,
and test CI are optional **python-tdd** handoffs.

## Debug and measure the actual workload

1. Preserve the original traceback; start at the failing operation and trace
   values/types and callers. Use `breakpoint()` or `python -m pdb script.py`
   with `n` (next), `s` (step), `c` (continue), `p` (expression), `w` (stack),
   and `u`/`d` (frames). Debugger evaluation can execute code and mutate state.
2. Keep diagnostic output off a machine-readable stdout channel. Reuse logging
   configuration; library code should not call `basicConfig` unconditionally.
3. Profile before optimizing: `python -m cProfile -s cumulative script.py` for
   call costs; `timeit.repeat` for an isolated repeatable operation; `tracemalloc`
   for Python allocation sites. Start tracing before the allocations of interest.
4. Use `time.perf_counter()` for elapsed duration, not wall time. Record interpreter,
   build, inputs, warmup/cache conditions, and repeats. Profiling changes timing;
   Python allocations are not total RSS or all native-extension memory.
5. Optional `line_profiler`/`memory_profiler` require separate installation and
   compatible instrumentation; use only when stdlib tools don't answer the question.
   Never copy the upstream's fixed speed/memory numbers as expected results.

## Version gates: preserve the declared minimum

| Feature | Minimum / caveat |
|---|---|
| f-strings | 3.6; debug `f'{value=}'` is 3.8 |
| positional-only `/`, walrus `:=` | 3.8 |
| built-in generic annotations, dict `|`, `functools.cache` | 3.9 |
| `match`, union `X | Y` annotations, strict zip, dataclass slots | 3.10 |
| `ExceptionGroup`, `except*`, `contextlib.chdir` | 3.11 |
| quote reuse/backslashes/comments in f-string expressions; type parameter/`type` alias syntax | 3.12 |
| `copy.replace` | 3.13; named tuples, dataclasses, or `__replace__` protocol, not every object |
| t-strings, deferred annotations, bracketless multi-exception handlers | 3.14 |

The doctests in this bundle target Python 3.11+; newer features below are
prose, not executable examples. Plain `f"{'hello'}"` already works before 3.12;
it is reusing the enclosing quote style, backslashes, and related grammar
restrictions that changed. Avoid newer syntax in code that must parse on older
interpreters; a runtime `if` cannot protect unsupported syntax from parsing.

In 3.14, t-strings return `string.templatelib.Template`, not `str`. Interpolated
expressions still execute immediately; a template is not automatically SQL-safe
or HTML-safe. Use database parameter binding rather than a homegrown sanitizer.
Deferred annotation evaluation changes when names/code are evaluated; it does not
validate arguments. `annotationlib` and runtime type introspection can evaluate
code or fail on unresolved names. `from __future__ import annotations` retains
its distinct string-based behavior; detailed migration belongs to **python-api-design**.

Bracketless `except A, B:` is allowed in 3.14 when there is no `as` binding;
retain `except (A, B) as error:` for binding and portable clarity. Python 3.14
remote debugging (`python -m pdb -p PID`, `sys.remote_exec`) depends on platform,
permissions, target support, and safe points; it is not a universal zero-overhead
capability. The target can disable it with `-X disable_remote_debug` or
`PYTHON_DISABLE_REMOTE_DEBUG=1`. Never attach to an unapproved process.

Free-threaded builds and multiple interpreters require separate concurrency
reasoning; they do not make compound shared-state operations safe. Hand off to
**python-concurrency**. Compression APIs (including 3.14 Zstandard and build
availability) belong to **python-stdlib**.

Sources: [venv](https://docs.python.org/3.14/library/venv.html),
[imports](https://docs.python.org/3.14/reference/import.html),
[Python 3.12 changes](https://docs.python.org/3.14/whatsnew/3.12.html),
[Python 3.14 changes](https://docs.python.org/3.14/whatsnew/3.14.html),
[pdb](https://docs.python.org/3.14/library/pdb.html),
[profiling](https://docs.python.org/3.14/library/profile.html).
