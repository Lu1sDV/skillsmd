# Workflow and runners

## Contents

- [Choose a falsifiable contract](#choose-a-falsifiable-contract)
- [Red, green, refactor](#red-green-refactor)
- [Budget boundary example](#budget-boundary-example)
- [Reproduce red then green safely](#reproduce-red-then-green-safely)
- [Tables, helpers, and selection](#tables-helpers-and-selection)
- [Legacy, golden files, and test shape](#legacy-golden-files-and-test-shape)

## Choose a falsifiable contract

Read the API, callers, error policy, module version, test conventions, and CI
before changing code. For a bug, retain the supplied counterexample and locate
the shared path; for a feature, write down the new behavior first. A compact
case list is enough:

| Dimension | Cases worth considering |
|---|---|
| Input partitions | Valid representative; nil/empty/zero; invalid domain; malformed encoding |
| Boundaries | Just below, exactly at, just above; integer limits and overflow where applicable |
| Transitions | Initial state; successful action; repeated action; rejection preserving state |
| I/O | Short reads/writes, missing file, malformed payload, status/error mapping, cancellation |
| Lifetime | Cleanup after setup failure; worker joined; no effect after cancellation if promised |

Do not mechanically test every Cartesian combination. Choose cases that
separate credible defects. Unicode length means bytes, runes, or grapheme
clusters according to the actual requirement; NaN/Inf and integer widths need
explicit policy when they matter. SQL injection prevention requires parameterized
queries at the database boundary, not a test rejecting a suspicious username.

## Red, green, refactor

1. Write a named test through real production behavior; independently specify its
   expected result or error and the relevant state change/non-change.
2. Run its exact selector. Read the assertion failure, not just the exit status.
   Missing symbols can be an early test-first step; after adding the API, obtain
   a behavioral red. An already-green test adds coverage but does not establish red.
3. Implement the full behavior with the simplest ordinary code. When uncertain,
   triangulate with distinguishing cases; when obvious, implement directly.
   A temporary constant can be a learning step, never the final implementation.
4. Run the focused case and affected suite; then simplify without changing the
   contract. Adding a validator, changing normalization, or changing rejection
   policy is another behavior cycle, not refactoring.

Inside-out/classical TDD is a useful default for domain logic. Outside-in can
start with a visible HTTP/CLI contract, then grow the core. Neither requires
mocking every collaborator. Prefer small transformations, not a prescribed
hierarchy of constants/recursion/loops or a claim that one is universally safer.

## Budget boundary example

The executable [Budget implementation](../examples/budget.go) tracks nonnegative
integer units. `Take(0)` is valid even when empty, an exact request succeeds,
and a rejection leaves the remaining amount unchanged. It is deliberately
**not concurrent**: callers must not share mutable instances across goroutines.
No money rounding, authentication, persistence, or distributed quota is implied.

The regression table in [examples_test.go](../examples/examples_test.go) starts
from 10 units and checks `-1`, `0`, `9`, `10`, `11`; separate tests exercise
`4 → reject 7 → take 6 → reject 1`, the zero value, negative capacity, and
`MinInt64`/`MaxInt64`. This complete test illustrates the crucial boundary:

```go
package budget_test

import (
    "testing"

    budget "example.com/go-tdd"
)

func TestExactBudgetRequest(t *testing.T) {
    b, err := budget.NewBudget(10)
    if err != nil {
        t.Fatal(err)
    }
    if err := b.Take(10); err != nil {
        t.Fatalf("exact request rejected: %v", err)
    }
    if got := b.Remaining(); got != 0 {
        t.Errorf("remaining = %d; want 0", got)
    }
}
```

Save as an additional `exact_test.go` in a disposable copy of `examples` to run
with `go test -count=1 -run '^TestExactBudgetRequest$' .`. The shipped table
already contains this contract, so no extra file is required normally.

## Reproduce red then green safely

From `go-tdd/`, the following optional Python 3 command mutates **only a
throwaway copy**. It changes the sole `amount > b.remaining` condition to `>=`,
runs the exact-boundary regression, demands the expected assertion failure,
restores the correct source in `finally`, and runs the same case green. The
published source never changes, even when a check fails.

```sh
python3 - <<'PY'
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

env = dict(os.environ, GOWORK="off", GOTOOLCHAIN="local")
command = ["go", "test", "-count=1", "-run",
           "^TestBudgetTakeBoundary$/^exact_emptying$", "."]
with tempfile.TemporaryDirectory(prefix="go-tdd-red-green-") as directory:
    target = Path(directory) / "examples"
    shutil.copytree("examples", target)
    source = target / "budget.go"
    original = source.read_text()
    old = "if amount > b.remaining {"
    assert original.count(old) == 1, "mutation target changed"
    try:
        source.write_text(original.replace(old, "if amount >= b.remaining {", 1))
        red = subprocess.run(command, cwd=target, env=env, text=True,
                             stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        print(red.stdout, end="")
        assert red.returncode != 0, "mutant unexpectedly survived"
        assert "TestBudgetTakeBoundary/exact_emptying" in red.stdout
        assert "Take(10) = insufficient budget; want <nil>" in red.stdout
    finally:
        source.write_text(original)
    subprocess.run(command, cwd=target, env=env, check=True)
PY
```

Expected: the mutant rejects the affordable exact request and the selected
assertion fails; after restoration the same selector passes. A toolchain error,
zero selected tests, or an unrelated panic is not successful red evidence.
This reproduces a test's ability to detect a defect; it does not establish that
the checked-in implementation was historically developed test-first. No check
execution is claimed by these instructions.

## Tables, helpers, and selection

Keep `_test.go` files alongside their package. An external `package x_test`
exercises the public contract; same-package tests can target genuine internal
algorithms when justified, but do not use reflection/export shims merely to
assert representation. Use `TestX(*testing.T)`, `BenchmarkX(*testing.B)`,
`FuzzX(*testing.F)`, and `ExampleX` with `// Output:` as appropriate.

- Table rows should have diagnostic names, inputs, expected outputs/errors.
  Use `errors.Is` for promised wrapped sentinels and `errors.As` for promised
  typed errors; exact text only when text is itself a public contract.
- `t.Run` scopes setup/failure and enables focused selectors. Use nested BDD
  names if they aid reading; avoid a forest of identical setup helpers.
- If the project already uses Testify, construct `assert.New(t)`/`require.New(t)`
  inside each `t.Run` with that subtest's `t`; reusing a parent-bound helper
  misattributes failures and can misuse `FailNow`.
- `t.Helper` attributes failures to the caller. Fatal on unusable setup, then
  compare independent outcomes with Errorf. Several assertions can prove one
  transition; the rule is not “one assertion per test.”
- Call `Fatal`, `Fatalf`, `FailNow`, or `SkipNow` only from the test goroutine.
  Worker goroutines should return errors/results over a channel or be joined;
  do not let them keep logging to a test that has finished.

Commands from `examples/` (use `GOWORK=off GOTOOLCHAIN=local` as in README):

```sh
go test -list . .
go test -count=1 -run '^TestBudgetTakeBoundary$/^exact_emptying$' .
go test -count=1 -v ./...
go test -count=1 -shuffle=on ./...
```

`-run` is a regexp per slash-separated component; `-list` lists top-level names,
not every nested case. Read verbose output to confirm selection. `-count=1`
disables result caching for the run. Record the reported shuffle seed when a
failure depends on ordering. `-short` has no magic skip behavior: tests decide
whether to call `testing.Short()` and skip.

## Legacy, golden files, and test shape

For legacy code, characterize real current behavior first, including awkward
cases; distinguish characterization from an approved new requirement. Add only
the seam needed to control time/I/O, not a parallel implementation or framework.
Exploration can precede tests when the contract is unknown; retain findings,
then add checks before relying on retained code. UI serialization and vendor
wrappers still have valuable escaping/error/timeout contracts; they are not
categorically exempt from testing.

Golden files belong in `testdata/`. Compare actual generated bytes/structures
against a reviewed expected artifact. Updates require an explicit opt-in flag
and a human diff review; CI must never auto-update expectations. Parallel tests
must not rewrite shared goldens. A golden proves selected output, not semantic
completeness; independently test important parsed fields or invariants.

Avoid no-assertion tests, `got == got`, no-panic-only checks for a richer
contract, unchecked setup errors, constant-return mutants surviving all cases,
state shared across tests, real public-service calls, and sleeps used as
completion guesses. Split unrelated behaviors, but retain coherent transition
scenarios instead of hiding the state progression behind fixtures.
