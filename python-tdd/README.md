# python-tdd

Python **3.15** red-green-refactor (stable **3.15.2**, checked **2026-11-03**):
meaningful regression failures, pytest and
unittest mechanics, fixtures, lookup-aware patching, deterministic clocks and
real local I/O, optional bounded Hypothesis, and coverage/mutation interpretation.
It is a Python implementation workflow, not a second system-wide test-strategy
skill. No sibling bundle is needed at use time.

- [Installation](#install-from-this-checkout)
- [Example prompts](#example-prompts)
- [Reference index](#reference-index)
- [Reproduce examples](#reproduce-the-dependency-free-examples)
- [Pinned source map](#pinned-upstream-source-map)
- [Design decisions](#consolidation-and-correction-decisions)
- [Technical references](#first-party-technical-references)

## Install from this checkout

From the repository root:

```sh
mkdir -p ~/.claude/skills && cp -r python-tdd ~/.claude/skills/
```

Preserve local changes in an existing installed `python-tdd` before replacing or
merging it. This command copies a bundle; it does not install pytest or plugins.

## Example prompts

- “Use python-tdd to reproduce this exact-threshold shipping bug; preserve the
  report and add the regression before fixing the shared pricing function.”
- “Characterize this legacy Python adapter, then change only the approved error
  mapping; distinguish characterization from newly required behavior.”
- “Review these pytest fixtures and patches for shared state, wrong lookup
  targets, swallowed exceptions, and tests that only echo mock return values.”
- “Add bounded Hypothesis properties for this encoder, keep shrunk regressions,
  and explain what the coverage and mutation reports cannot establish.”
- “Test cancellation cleanup and the installed CLI boundary deterministically;
  do not depend on sleeps or a live public service.”

## Reference index

| File | Contents |
|---|---|
| [SKILL.md](SKILL.md) | Activation, routing, contract/red-green-refactor workflow, gotchas and completion guard |
| [Workflow and runners](references/workflow-and-runners.md) | Feature/bug/legacy workflows, runnable threshold example and one-line mutation, pytest recipe, unittest/subTest/cleanup example, selectors |
| [Isolation and doubles](references/isolation-and-doubles.md) | Fixture scope/lifecycle, patch lookup, spec/async doubles, runnable cache boundary |
| [Properties and boundaries](references/properties-and-boundaries.md) | Optional Hypothesis recipe, real SQLite rollback and async cleanup examples, HTTP/CLI checks, coverage/mutation/CI |

## Reproduce the dependency-free examples

From the bundle directory (checkout or copied installation):

```sh
python3 -m doctest SKILL.md references/*.md
```

Targets Python **3.15**; use the standard library and no optimization flags that
remove test assertions. Examples are deterministic and local: no external
network, sleeps, shared fixed paths, or persistent user files. Each `pycon` fence
includes its own imports/helpers; temporary resources are closed/cleaned up.
The one-line threshold mutation in
[Workflow and runners](references/workflow-and-runners.md#reproducible-boundary-exact-free-shipping-threshold)
is performed only on a disposable bundle copy. From that copy, run
`python3 -m doctest references/workflow-and-runners.md` with `>` substituted for
`>=`, then restore `>=` and rerun; only the exact-threshold assertion should fail
in the mutated version. Published doctests stay green. These are verification
instructions and expected outcomes, not claims that execution has occurred.

The `python` fences are clearly labelled project/framework recipes, not doctests.
For the complete pytest file recipe, save its fence as `test_limits.py` in a
disposable directory and run `python -m pytest -q test_limits.py`. For the
Hypothesis recipe, save its fence as `test_runs.py` and run
`python -m pytest -q test_runs.py` with compatible pytest/Hypothesis installed.
These checks do not need pytest-mock, pytest-asyncio, a database service, or an
HTTP framework. Optional API clients, async pytest suites, coverage, and mutation
tools require the target project's compatible dependencies and separate checks.
No optional package is an implicit requirement of the installed skill.

Python 3.15 is this bundle's default baseline, not a verified all-version matrix
or permission to silently raise an existing consumer's minimum version. Preserve the target
project's supported versions and pinned plugin/runtime compatibility. SQLite
examples establish SQLite behavior only; in-process HTTP clients do not verify
socket/TLS/deployment behavior, and mocks do not establish live API compatibility.

Verification on **2026-11-03** used CPython **3.15.2**, GIL-enabled Linux x86_64:
all **40 doctest checks** and both complete pytest/Hypothesis recipes passed
(**8 tests**, pytest **9.2.0**, Hypothesis **6.170.14**). A separate bounded control
confirmed contradictory assumptions raise `Unsatisfiable` (**1 additional test**).
The disposable `>=` to `>` threshold mutation failed only the exact-threshold
assertion; restoring `>=` passed all 17 checks in that reference. These checks
do not validate optional Django, async pytest plugins, xdist, mutation tools,
Windows or free-threaded behavior.

## Pinned upstream source map

Adapted from StructWeave-Algorithms, copyright (c) 2024-2025 StructWeave
Contributors, under the [exact upstream MIT license](LICENSE.upstream).
Python content is pinned at commit
`0b88a786ef09681717a805d9f7e0b195ab610f6c`:

| Source | Local coverage / intentional boundary |
|---|---|
| [17 — Test-Driven Development](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/17-test-driven-development.md) | Full chapter synthesized: cycle/QA boundaries/workflows in SKILL and runner reference; fixtures/unittest/doubles/testability/smells in isolation and runner references; properties, scenarios, coverage/mutation, CI in boundary reference. Interview answers and quick cards consolidated rather than duplicated. Generic pyramid/risk strategy hands off by name to optional test-engineering. |
| [08 — Tooling and Testing](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/08-tooling-testing.md) | pytest/unittest, test layout/configuration/selection, test dependency and CI gates. General formatting, debugging, environments, profiling, and non-test tooling hand off by name to optional python-idiomatic. |
| [13 — Anti-Patterns and Best Practices](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python/13-anti-patterns-best-practices.md) | Testing implementation details, flaky clocks/services, excessive mocking, missing meaningful assertions; deterministic cache and actual state checks replace weak demonstrations. Other language/class/concurrency traps are outside this skill. |

## Consolidation and correction decisions

| Decision | Rationale / correction |
|---|---|
| Keep the entrypoint a router | Move the exact-threshold example unchanged to workflow/runners, update its mutation command and links, and keep all executable examples and longer-reference contents lists in the standalone bundle. |
| Keep TDD standalone | Python-specific red-green work, runner behavior, fixtures and boundary tests form a coherent task; general strategy is an optional test-engineering handoff. |
| Preserve meaningful red | An already-passing new example is additional coverage, not an observed red step. Import/setup failures do not substitute for a behavioral assertion failure. The threshold mutant identifies an exact expected failure without shipping a permanently failing doctest. |
| Refactor must preserve behavior | Upstream's “refactor” adds stricter email validation and lowercases the address; those are contract changes, not refactoring. The bundle uses explicit integer-cent semantics instead of implying a small regex is a complete email validator. |
| Avoid unsupported universal claims | Omit uncited TDD defect-reduction percentages, fixed 70/20/10 pyramid ratios, blanket time/coverage targets, and claims that all killed mutants prove effectiveness. Branch coverage is not all-path coverage. |
| Prefer real boundaries and assert outcomes | Mock echo/call-only examples are not evidence for application rules or live integrations. Real files, stored SQLite rows, expiry decisions, and awaited cancellation cleanup exercise observable behavior. Never infer SQL-injection prevention from removing words in input. |
| Correct Python lifecycle pitfalls | Add cleanup immediately after acquisition; pytest post-yield teardown does not run when setup fails before yield. SQLite transaction contexts do not close connections; rollback cleanup cannot undo earlier commits. |
| Scope optional dependencies honestly | pytest does not itself provide `--cov`, `mocker`, or an async coroutine runner. Hypothesis max_examples is not a total-call cap; preserve shrunk failures. Removed `asyncio.coroutine` examples are replaced by current async/await and AsyncMock guidance. |
| Keep boundaries proportionate | Existing functions/callables and real local resources first; no required DI framework, factory hierarchy, fake repository, universal fixture graph, or duplicated generic strategy. |

## First-party technical references

These support sensitive API/lifecycle claims; the actionable guidance is bundled
locally and does not require opening them during use.

- [Python unittest: cleanup and async test cases](https://docs.python.org/3.15/library/unittest.html#unittest.TestCase.addCleanup)
- [Python unittest.mock: lookup and patching](https://docs.python.org/3.15/library/unittest.mock.html#where-to-patch)
- [pytest fixtures: errors before yield and safe teardown](https://docs.pytest.org/en/stable/how-to/fixtures.html#handling-errors-for-yield-fixture)
- [Hypothesis API: settings, explicit examples, replay](https://hypothesis.readthedocs.io/en/latest/reference/api.html#hypothesis.settings)
- [coverage.py: branch measurement and limits](https://coverage.readthedocs.io/en/latest/branch.html)


## Community curation, 2026-11-03

The community list supplies candidate ideas, not authority. These files were
read directly; retained ideas were rewritten and checked against current
pytest, Hypothesis and Python documentation. Links identify the reviewed
locations without claiming an unverified immutable revision.

| Reviewed source | Adopted / corrected |
|---|---|
| [Trail of Bits: property testing](https://github.com/trailofbits/skills/blob/main/plugins/property-based-testing/skills/property-based-testing/SKILL.md) | Adapt a small contract-to-property table and counterexample triage. Reject an unconditional strength ladder: oracles can share bugs, and round trips or idempotence alone can be weak. Correct the claim that contradictory `assume` calls pass with zero cases: Hypothesis raises a health-check error or `Unsatisfiable`. |
| [wdm0006: testing strategy](https://github.com/wdm0006/python-skills/blob/HEAD/skills/python/testing-strategy/SKILL.md) | Adapt distinguishable fixtures, actual-boundary assertions and scoped sensitivity checks. Preserve existing red evidence; do not require gratuitous repeated mutation, universal external-I/O mocking, autouse global resets, or an arbitrary coverage percentage. |
| [dmoka: mutation testing](https://github.com/dmoka/skills/blob/HEAD/skills/mutation-testing/SKILL.md) | Adapt baseline validity, scoped campaigns, the missing-code blind spot and honest survivor classification. Reject automatic quarantine, “two passes proves stable”, fixed universal gates, and mandatory approval/subagent steps unrelated to repository policy. |

Other candidate concepts are retained only where their conditions can be stated
briefly: `importlib` is the pytest recommendation for new layouts, not a risk-free
switch for every existing suite; asyncio auto/strict and xdist scheduling depend
on backend and resource ownership; Django after-commit checks require the relevant
transaction boundary. Keep PyVista-specific snapshot machinery, framework fixtures,
performance benchmarking and organization-wide mutation policy outside this bundle.

The property catalogue is deliberately small. Flake work uses comparable runs,
recorded failures/attempts and a root-cause hypothesis, without promising a fixed
number of successful retries establishes correctness. Coverage jobs remain an
explicit project decision; removing all coverage flags from `addopts` is not a
universal rule.
