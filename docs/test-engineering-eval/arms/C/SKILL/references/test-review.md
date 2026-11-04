# Test review reference

Detail for the gate in [SKILL.md](../SKILL.md). Read the section that matches the question.

## Judging generated tests against a known defect

Use only when a defective and a fixed version both exist (a bug-fix commit or a benchmark); never invent a fixed version. Run the tests on both; the two must implement the same contract through a compatible interface. Keep all four outcomes apart.

| Defective | Fixed | Meaning |
|---|---|---|
| Fail | Pass | Candidate detection. Confirm it fails for the intended reason |
| Pass | Fail | Test encodes the bug: its expectation came from the defective behavior |
| Pass | Pass | Does not distinguish this defect; may still check useful common behavior |
| Fail | Fail | Diagnose first: wrong expectation, shared defect, or incompatible setup |

Track build failures, setup failures, timeouts, skips and tests that never ran separately; do not fold them into any row. "Passes on the defective version" lumps rows 2 and 3 and punishes tests aimed at a different defect.

Why it matters: in the original Mathews and Nagappan study of 287 buggy student programs, the generated suite passed the buggy code and failed the correct reference (row 2) for 171 of 287 programs with CodiumAI (59.6%), 62 of the 91 suites CoverUp produced (68.1%; it produced none for the other 196), and 12 of 287 with Copilot (4.2%). CodiumAI and CoverUp generate tests from the existing implementation and filter or repair failing ones, so a test that passes on the code under test survives. Copilot only generates.

## Oracle sources

Acceptable: the requirement or spec, a worked example from documentation, an independent calculation, a simpler or older reference implementation, a metamorphic relation, a round trip. Each has limits: an older implementation may share the bug, and a round trip passes for a symmetric defect.

Not acceptable: output copied from the code under test; the production helper or formula used to compute the expectation; a value you derived by reading the implementation, unless the test is labelled a characterization test.

When no spec exists, say so, derive preconditions, postconditions and error cases from docs, comments, callers and existing tests, and state which are assumptions. Do not present an assumption as a requirement.

## Assertion strength

Signs a test is weak:
- No assertion, or an unawaited async assertion (it passes without checking). A test that expects an exception does assert; a bare no-throw smoke test only shows the code ran.
- Only presence or truthiness checks on a value whose content matters.
- Asserts a mock was called, or called with specific arguments, where the caller-visible result is the contract.
- A `toMatchObject`-style partial match presented as an identity or full-equality check.
- A suite with no test for the failure path, empty input, or boundary values is thin even when each test is sound.

Calibrate before reporting a weakness:
- Name the wrong result the assertion would still accept. No candidate, no finding.
- Boolean assertions on a real property are not trivial. Exception tests legitimately have few assertions.
- Diversity is not volume: a longer chain of equality checks adds nothing.
- Recommend only assertion types that would catch a bug in this code. For a create, update or delete with no assertion, name the returned value or observable post-condition to check.

A suite can pass while checking nothing; high coverage with assertion-free tests is the typical case.

## Test doubles

Default: use the real object or value for code you own. Default to not mocking a data model, DTO, entity or state object; if constructing it is painful, add a builder (that is design feedback).

Exceptions, each with its purpose:
- **Stub** to inject a fault or rare state, such as a timeout.
- **Mock** when the effect is the contract ("sent at most once").
- **Fake** when the real dependency is slow, costly or has uncontrollable state. A reused fake should pass the same contract tests as the real component, and those tests establish only what they check, not transactions, timing or consistency.
- **Network boundary:** stub at the network layer and make unmocked requests fail, rather than mocking your own data modules.

When many tests mock the same dependency, a hand-written stub is usually cheaper to maintain. Assert the end result, not the sequence of interactions that produced it.

A response that echoes submitted fields does not prove persistence. A provider can return the expected body and drop the write. When persistence is the claim, observe the stored effect independently (a follow-up read, a query). When a database is the subject, run against a real one with the real migrations; a mocked session proves nothing about SQL.

A test that is mostly mock wiring means the unit is too small: widen it to something with real behavior, or say that the seam needs an integration test and name which.

## Properties

Use a property when an independent one exists: round trip, invariant (output sorted, length preserved), agreement with a simpler or older implementation, or a metamorphic relation. Skip it when only the implementation's own formula is available; a property that restates the code proves nothing.

- Check that generators do not filter out nearly every input, and that constraints are not contradictory. A passing property over zero cases is silent.
- Constrain generators to the intended domain, using production limits and validation ranges.
- Keep every shrunk counterexample as a fixed regression case after the fix.

## Mutation and fault injection

Use when the question is whether tests notice a defect in specific code. Scope to the changed lines or module; whole-suite runs are slow and their scores depend on the operator set, so compare only within one tool and configuration. Treat a timed-out mutant as inconclusive. Inspect survivors for equivalent mutants before writing a test for them. A survivor in code with an assertion-free test points to a missing assertion, not missing coverage.
