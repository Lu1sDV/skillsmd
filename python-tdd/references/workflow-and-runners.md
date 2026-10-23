# Workflow and Python test runners

- [Select a regression](#select-a-focused-regression)
- [Exact-threshold example and mutation](#reproducible-boundary-exact-free-shipping-threshold)
- [Runner commands](#runner-selection-and-commands)
- [pytest recipe](#pytest-recipe-real-files-isolated-fixtures-parametrized-validation)
- [unittest and cleanup](#unittest-assertions-subcases-cleanup)

## Select a focused regression

| Situation | Concrete sequence |
|---|---|
| New behavior | State an acceptance example → failing focused case → complete implementation → affected suite → behavior-preserving refactor |
| Bug | Preserve reported input/failure → trace shared failing path and callers → named regression → smallest root-cause fix → neighboring cases |
| Legacy code | Capture current public behavior → introduce only the seam needed for the change → separate compatibility tests from approved changed behavior |
| Unknown interface | Bounded exploration first; retain no production prototype without characterization and explicit contracts |

A test name describes behavior, e.g. `test_exact_threshold_ships_free`, not
`test_function_2`. Arrange the smallest relevant state, act through the public
interface, assert its result and relevant state. Several assertions describing
one transition are preferable to one assertion that misses half the contract.

For thresholds, include below/at/above; for combined predicates, use a small
decision table containing each meaningful combination. For example, if members
ship free regardless of total, cover member/nonmember below and at the threshold.
Do not derive expected values by copying the implementation formula. For error
paths, check the intended exception and whether a file, row, or in-memory state
was left unchanged. Do not assume strings should be ASCII-only, or SQL injection
is prevented by removing words: test the actual specified boundary instead.

## Reproducible boundary: exact free-shipping threshold

Contract: a nonnegative integer subtotal in cents ships free at **10,000 cents
or above**; lower subtotals cost 500 cents. The typed function's caller supplies
integers; a public JSON/HTTP adapter must separately validate input types.

Green example; assertions exercise the real pricing decision:

```pycon
>>> def shipping_cents(subtotal_cents: int) -> int:
...     if subtotal_cents < 0:
...         raise ValueError("subtotal must be nonnegative")
...     return 0 if subtotal_cents >= 10_000 else 500
>>> assert shipping_cents(9_999) == 500
>>> assert shipping_cents(10_000) == 0
>>> assert shipping_cents(10_001) == 0
>>> assert shipping_cents(0) == 500
>>> from unittest import TestCase
>>> with TestCase().assertRaisesRegex(ValueError, "nonnegative"):
...     shipping_cents(-1)

```

**One-line bug mutation:** in a disposable copy, replace
`return 0 if subtotal_cents >= 10_000 else 500` with
`return 0 if subtotal_cents > 10_000 else 500`.
The assertion `assert shipping_cents(10_000) == 0` must fail with
`AssertionError`: the mutated function returns `500`. The neighboring assertions
still pass, showing why the equality boundary matters. From the disposable bundle
copy, run `python3 -m doctest references/workflow-and-runners.md`; restore `>=`
and run it again.
These are expected outcomes, not recorded execution results. In a project, keep
this case as `test_exact_threshold_ships_free` and reproduce red before the fix;
the published example intentionally remains green, not a failing doctest.

## Runner selection and commands

Commands below are target-project recipes, not files shipped by this skill.
Use the same interpreter/environment as the application and its existing runner.

| Need | pytest (third-party) | unittest (stdlib) |
|---|---|---|
| Focused test | `python -m pytest tests/test_shipping.py::test_exact_threshold_ships_free -q` | `python -m unittest tests.test_shipping.ShippingTests.test_exact_threshold_ships_free -v` |
| File / module | `python -m pytest tests/test_shipping.py -q` | `python -m unittest tests.test_shipping -v` |
| Relevant suite | `python -m pytest tests/ -q` | `python -m unittest discover -s tests -p 'test_*.py' -v` |
| Inspect selection | `python -m pytest --collect-only -q tests/` | Inspect reported test count; successful exit with zero tests is not useful green |
| Debug | `python -m pytest -x --pdb tests/test_shipping.py` | `python -m pdb -m unittest tests.test_shipping` |

Use an exact node ID before `-k` substring filters; confirm the selected count.
`--lf` uses pytest's local failure cache and is convenient feedback, not a full
CI gate. Both runners need importable tests/application modules; preserve the
project's package layout. Avoid `sys.path` hacks that conceal a broken install.

## pytest recipe: real files, isolated fixtures, parametrized validation

Requires pytest in the target environment. Save the entire following `python`
fence as `test_limits.py` in a disposable directory and run
`python -m pytest -q test_limits.py`. This is an illustrative complete adapter and
test recipe; in an application, import the production adapter instead of keeping
a duplicate in the test file. It is **not** executed by Markdown doctest.

```python
import json

import pytest


def load_limit(path):
    value = json.loads(path.read_text(encoding="utf-8"))["limit"]
    if type(value) is not int or value <= 0:
        raise ValueError("limit must be a positive integer")
    return value


@pytest.fixture
def limit_file(tmp_path):
    path = tmp_path / "limits.json"
    path.write_text('{"limit": 12}', encoding="utf-8")
    return path


def test_loads_limit_from_disk(limit_file):
    assert load_limit(limit_file) == 12


@pytest.mark.parametrize("value", [0, -1, True, "12"],
                         ids=["zero", "negative", "bool", "text"])
def test_rejects_invalid_limit(limit_file, value):
    original = json.dumps({"limit": value})
    limit_file.write_text(original, encoding="utf-8")
    with pytest.raises(ValueError, match="positive integer"):
        load_limit(limit_file)
    assert limit_file.read_text(encoding="utf-8") == original


def test_reports_malformed_json(limit_file):
    limit_file.write_text("{", encoding="utf-8")
    with pytest.raises(json.JSONDecodeError):
        load_limit(limit_file)
```

Here `type(value) is int` deliberately rejects JSON booleans: Python `bool` is
an `int` subclass. The function-scope fixture runs afresh per case, including
parametrized cases. A malformed file test asserts the promised parser error,
not `Exception`, and rejection cases verify there was no write-back.

Built-in pytest tools: `tmp_path` for files, `capsys` for Python-level stdout and
stderr, `capfd` for file-descriptor capture, `caplog` for logging, `monkeypatch`
for scoped attributes/environment changes. Assert output content/status, not
only that capture succeeded. Use `pytest.approx` with domain-appropriate
absolute/relative tolerances for floating point; integer cents/`Decimal` are
often the actual monetary contract, not approximate binary floats.

Put genuinely shared fixtures in the nearest `conftest.py`; tests discover them
without importing it. Register custom markers in project configuration and use
`--strict-markers`. Use `skipif` for a real unavailable capability with a reason;
use `xfail(strict=True)` for a tracked known defect when appropriate, so an
unexpected pass is noticed. Neither is a substitute for delivering a fix.

## unittest: assertions, subcases, cleanup

Dependency-free runnable example. A temporary file is read through the real
parser; `addCleanup` owns its directory even if later setup fails. The runner is
captured so doctest asserts real test counts and failures, not unstable timings.

```pycon
>>> import io
>>> import json
>>> import tempfile
>>> import unittest
>>> from pathlib import Path
>>> class JsonFileTests(unittest.TestCase):
...     def setUp(self):
...         directory = tempfile.TemporaryDirectory()
...         self.addCleanup(directory.cleanup)
...         self.path = Path(directory.name) / "data.json"
...     def test_unicode_and_empty_values_round_trip(self):
...         for value in [{"city": "東京"}, {}, []]:
...             with self.subTest(value=value):
...                 self.path.write_text(json.dumps(value), encoding="utf-8")
...                 restored = json.loads(self.path.read_text(encoding="utf-8"))
...                 self.assertEqual(restored, value)
...     def test_truncated_document_has_specific_error(self):
...         self.path.write_text('{"city":', encoding="utf-8")
...         with self.assertRaises(json.JSONDecodeError):
...             json.loads(self.path.read_text(encoding="utf-8"))
>>> suite = unittest.defaultTestLoader.loadTestsFromTestCase(JsonFileTests)
>>> result = unittest.TextTestRunner(stream=io.StringIO()).run(suite)
>>> assert result.testsRun == 2
>>> assert result.wasSuccessful(), (result.failures, result.errors)

```

`subTest` reports each failing input while continuing other inputs. Use
`assertEqual`, `assertIsNone`, `assertRaisesRegex`, and `assertLogs` for precise
diagnostics; if log text is not a stable contract, assert level/name and relevant
record fields instead. Keep only the intended exception-raising operation inside
the exception context, not unrelated setup that could fail for the same reason.

`setUp`/`tearDown` run per test, `setUpClass`/`tearDownClass` share class state.
`tearDown` is skipped when `setUp` fails; register `addCleanup` immediately after
acquisition. Pytest can run many `unittest.TestCase` suites, but direct pytest
fixture argument injection/parametrization into TestCase methods is not supported
in the same way as plain pytest functions. Preserve existing runner conventions
rather than mixing lifecycle models accidentally.
