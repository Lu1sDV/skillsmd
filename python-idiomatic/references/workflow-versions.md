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

An eager import executes module top-level code on initial load and caches the
module in `sys.modules`. Importing a submodule also initializes its parent
packages; inspect their `__init__.py` reexports when an apparently small import
pulls in a large dependency graph. Avoid network calls, file writes, CLI parsing, and expensive
setup on import. Guard script execution with `if __name__ == '__main__':` and use
`python -m package.module` when package-relative imports matter. Do not name your
file `json.py`, `typing.py`, or another dependency's module name. Inspect
`module.__file__`/`module.__spec__` when a surprising module is loaded.

Prefer explicit imports (including explicit reexports), group standard/third-party/
local imports according to existing tooling, and avoid `sys.path` hacks.
`__all__` controls wildcard exports, not privacy. `from module import name`
binds the current object; later rebinding `module.name` doesn't update that local
binding. Imported mutable objects can still be shared.

Treat a cycle as an architectural investigation, not proof of a runtime bug.
Identify the partially initialized names or initialization effects before reporting
impact. Inspect the dependency graph and move genuinely shared definitions
to an appropriate lower-level module, or move orchestration out of mutually
importing models. A function-local import can defer a genuinely optional/expensive
dependency; ordinary import caching already exists, so do not build a second
module-global cache. Defer only for a reason: failures otherwise move from startup
to an arbitrary later call. `TYPE_CHECKING` imports are absent at runtime;
quoted/deferred annotations can still fail when introspection resolves them.
Ruff `TC004` detects some runtime uses hidden in `TYPE_CHECKING`; a clean lint
run does not establish that a framework can resolve annotations dynamically.

On 3.15, `lazy import` / `lazy from` defer module loading until first use. They
are module-scope constructs, disallowed inside functions/classes and
`try`/`except`/`finally` blocks. Failures move to first use and registration side
effects may not run at startup. Use laziness only after checking those contracts;
keep eager guarded imports for optional-dependency detection. Module `__getattr__`
(PEP 562) can serve deliberate lazy public exports, but is not a blanket cycle fix.

## Formatting and static analysis

Reuse repository tools and pinned versions. Ruff covers many lint and import
sorting rules, not every Pylint/Flake8 plugin or type check. Choose one formatter
(Ruff format or Black) rather than alternating both. Ruff's `I` rules can replace
isort for supported configurations; retain isort where the project requires it.
Mypy/Pyright check static contracts, not runtime input validity. Align interpreter,
`requires-python`, formatter/linter targets, type checker and CI. For new code
under this guide use 3.15; for an existing compatibility contract, target its
declared minimum and confirm the pinned tools support that target.

Recipes, requiring the named tools already installed in the selected environment:

```sh
python -m ruff check .
python -m ruff format --check .
python -m mypy src/
```

Use `--fix`/format-writing commands only when intended, and inspect semantic
changes rather than treating tool suggestions as authority. Review what the
configured tools cannot establish: ownership, error policy, input-domain intent,
side effects and lifetime. Prefer a code-specific suppression plus a reason that
holds for that line; do not disable broad rule sets to hide a specific bug.

When changing enforcement, inspect effective settings and probe the actual
command in a disposable checkout with one intentional violation in the relevant
path. Confirm it is detected, then restore it and rerun. Ruff `F811` ignores
names matching `lint.dummy-variable-rgx`, so a permissive pattern can hide unused
redefinitions; rule selection alone is insufficient evidence. Keep ordinary
review focused on consequences, not blanket bans on `staticmethod`, relative
imports, comprehensions, or other valid constructs. Testing frameworks, fixtures,
coverage, and test CI are optional **python-tdd** handoffs.

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

Baseline: **Python 3.15.2**, stable release verified on **2026-11-03**. Recheck
[Python releases](https://www.python.org/downloads/) when refreshing this bundle;
use versioned stable docs, not development docs or accepted PEPs as release proof.
The table explains relevant migration boundaries, not a requirement to use every
new feature or widen this bundle into a historical feature catalogue.

| Feature | Introduced / caveat |
|---|---|
| quote reuse/backslashes/comments in f-string expressions; type parameter/`type` alias syntax | 3.12 |
| `copy.replace`; `typing.TypeIs` | 3.13; replace supports named tuples, dataclasses, or `__replace__`, not every object; TypeIs requires a truthful predicate |
| t-strings, deferred annotations, bracketless multi-exception handlers | 3.14 |
| UTF-8 mode by default (PEP 686) | 3.15; can be disabled with `-X utf8=0` / `PYTHONUTF8=0` |
| Explicit lazy imports; unpacking in comprehensions | 3.15; new syntax needs parser/tool support |
| `sentinel`, `frozendict` built-ins | 3.15; distinct sentinel identity; frozen mappings are not deeply immutable |

The doctests and recipes target Python 3.15. Plain `f"{'hello'}"` already works before 3.12;
it is reusing the enclosing quote style, backslashes, and related grammar
restrictions that changed. Avoid newer syntax in code that must parse on older
interpreters; a runtime `if` cannot protect unsupported syntax from parsing.

Choose explicit file/protocol encodings even with 3.15's UTF-8 default: legacy
data may use another encoding and the process can opt out. `encoding="locale"`
is an explicit locale contract, not UTF-8. Normalization changes text semantics
independently of encoding; consult [Language semantics](language-semantics.md).

Use `frozendict` when immutable mapping structure is the contract; nested values
can remain mutable, and hashing requires hashable keys and values. It is not a
`dict` subclass. Accept `collections.abc.Mapping` when the consumer only needs
the mapping interface, without broadening a deliberately narrower public API.

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

Sources: [venv](https://docs.python.org/3.15/library/venv.html),
[imports](https://docs.python.org/3.15/reference/import.html),
[lazy imports](https://docs.python.org/3.15/reference/simple_stmts.html#lazy-imports),
[module attribute hooks](https://docs.python.org/3.15/reference/datamodel.html#customizing-module-attribute-access),
[Python 3.15 changes](https://docs.python.org/3.15/whatsnew/3.15.html),
[TypeIs](https://docs.python.org/3.15/library/typing.html#typing.TypeIs),
[frozendict](https://docs.python.org/3.15/builtins/stdtypes.html#frozendict),
[pdb](https://docs.python.org/3.15/library/pdb.html),
[profiling](https://docs.python.org/3.15/library/profiling.html),
[Ruff F811](https://docs.astral.sh/ruff/rules/redefined-while-unused/),
[Ruff TC004](https://docs.astral.sh/ruff/rules/runtime-import-in-type-checking-block/).
