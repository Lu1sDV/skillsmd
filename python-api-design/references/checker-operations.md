# Make type checking an observed contract

## Establish the actual scope

Read the project's checker, version/lock, configuration, Python minimum, import
layout and framework plugins before proposing changes. Reuse that setup. Prefer
one authoritative gate unless multiple checkers serve an explicit purpose; a
library may intentionally verify several consumer checkers. Do not select tools
by popularity, unsupported speed claims or an editor brand.

Pin the toolchain through the project's dependency/lock policy and upgrade it
deliberately. Checker presets and diagnostics change; record the exact version
and target used. Target the supported Python floor, not whichever interpreter
runs the checker. For a new 3.15 project, first verify checker and dependency
support for the 3.15 features it uses. A syntax backport and a checker supporting
that syntax are separate requirements.

## Ensure a green result covers the code

| Check | Why it matters |
|---|---|
| Config file, invocation and included modules | An editor may run different settings from CI; excluded or unimported code may not be checked. |
| Untyped function bodies | Mypy normally skips these; `check_untyped_defs` checks their bodies, while stricter annotation rules address `Any` parameters. |
| Imported types/stubs and module resolution | A missing dependency, broad missing-import suppression or incorrect search path can erase useful checking. |
| Expected valid and invalid consumer examples | Successful examples alone do not prove wrong signatures/types will be rejected. |
| Runtime boundary checks | Static acceptance cannot establish parsing, domain invariants, authorization or behavioral substitutability. |

Use the existing project command. Illustrative commands for a project with `src`
and `tests`, not installation steps or claims of a passing run:

```sh
python -m mypy --version
python -m mypy --config-file pyproject.toml src tests
# For an existing Pyright project, use its locked runner to run:
pyright --version
pyright --project pyproject.toml
```

Do not silently run both checkers, replace configuration or install a global tool
as a side effect of loading this skill. A named config path must exist and contain
the correct checker section; use the repository's real command when it differs.

## Increase coverage without hiding the delta

Annotate public boundaries and meaningful relationships first. Grow checked
modules or stricter rules in reviewable steps, and track remaining exemptions.
Mypy supports per-module overrides for many options; Pyright supports a `strict`
path list over a less strict base. Follow the pinned checker's documented option
precedence instead of assuming their strictness controls are interchangeable.

Avoid a blanket `ignore_errors` or global `ignore_missing_imports` as the normal
ratchet: both can conceal new defects. Where a temporary baseline is necessary,
make its scope, owner and removal criteria visible and verify that new errors
cannot disappear unnoticed. Prefer available stubs or a typed integration adapter.

Fix incorrect contracts before suppressing diagnostics. Keep an unavoidable
suppression local, name the checker error code and record the reason/evidence.
Enable unused-suppression diagnostics (`warn_unused_ignores` for mypy;
`reportUnnecessaryTypeIgnoreComment` for Pyright) where supported. Cast only when
independent evidence already establishes the type; a cast performs no check.
Do not introduce a new raising runtime guard merely to silence a typing-only
change, or remove a real boundary guard because typed callers happen to pass.

## Verify the distributed type surface

For an inline-typed installed package, include `py.typed` in the import package
and verify that it survives into the wheel. Put markers inside the owned portions
of namespace packages. Stub-only distributions have different marker rules.
Missing `py.typed` can make inline annotations unavailable to consumers; it does
not universally turn every checker/import into `Any`, because separate stubs and
checker-specific source analysis may apply.

Run a small downstream consumer against the installed artifact outside the
checkout, through the documented import path. Check a valid call, a deliberately
invalid call and an explicit re-export under the supported checker/configuration.
Inspect the invalid case's expected diagnostic so an unrelated import failure
cannot masquerade as successful rejection. Coordinate wheel-building mechanics
with **python-system-design** when installed; no sibling skill is required.

Report checker/runtime versions, config, inspected modules, exact commands,
observed diagnostics and unverified platforms/dependencies. Doctests establish
runtime examples only. Avoid declaring static compatibility from a lint result,
a wheel listing, or a single successful import.

Primary references: [mypy configuration](https://mypy.readthedocs.io/en/stable/config_file.html),
[mypy untyped code](https://mypy.readthedocs.io/en/stable/dynamic_typing.html),
[Pyright configuration](https://github.com/microsoft/pyright/blob/main/docs/configuration.md),
and [type-information distribution](https://typing.python.org/en/latest/spec/distributing.html).
