# Properties, doubles, and fixtures

Use ordinary `#[test]` and real values first. Add a dev-dependency only when it
solves a demonstrated test need; select versions compatible with the project's
MSRV and lockfile. These techniques preserve the red-green-refactor discipline
from [chapter 18](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/18-test-driven-development.md),
but replace several weak or misleading upstream examples.

## proptest: test the operation, not the generator

[Proptest](https://docs.rs/proptest/latest/proptest/) combines generated inputs
with assertions and failure shrinking. A passing run samples the chosen domain;
it is not a proof over every possible input. Keep fixed regression and boundary
examples even when properties exist.

A concrete reservation property recipe, using the real `reserve` function from
the entry point in the project's unit-test module:

1. Add `proptest` as a project-compatible dev-dependency and import
   `proptest::prelude::*` in that test module.
2. Inside `proptest!`, define a `#[test]` function with
   `available in any::<u32>()` and `requested in any::<u32>()`.
3. Preserve `available` as `original`; call `reserve(&mut available, requested)`.
4. Assert success iff `requested <= original` using `prop_assert_eq!`.
5. On success, assert conservation with a wider oracle:
   `u64::from(available) + u64::from(requested) == u64::from(original)`.
   On failure, assert `available == original` and the specific insufficient
   inventory error. This is a deliberate branch over different postconditions,
   not a branch that lets a case escape all assertions.
6. Keep explicit zero/exact/max cases: uniform generation need not hit the rare
   equality boundary. Add a separate property with requested equal to stock,
   or bias generation toward boundaries with `prop_oneof!` and `Just`.

The wider arithmetic is intentional: copying production `checked_sub` into the
oracle would duplicate the implementation, while adding two `u32`s might
introduce an overflow bug in the test itself.

### Strategies that preserve the domain

| Need | Strategy and caveat |
|---|---|
| Arbitrary typed values | `any::<T>()`; domain restrictions may still be needed |
| Inclusive count range | `0u32..=100`; `0..100` excludes 100 |
| Bounded sequence | `prop::collection::vec(any::<i32>(), 0..=100)` includes length 100 |
| Valid structured text | Regex strategies such as `"[a-z]{1,16}"`; assert behavior of the parser, not that generated text matches its regex |
| Distinct input classes | `prop_oneof!` with explicit empty, boundary, normal, malformed strategies |
| Dependent valid values | Tuple strategies plus `prop_map` or `prop_flat_map`; construct valid cases rather than rejecting almost all candidates |
| Occasional exclusion | `prop_filter` / `prop_assume!`; frequent rejection can exhaust limits and hurts exploration/shrinking |

Avoid testing only a generator's guarantee, such as “a vector generated with
length below 100 has length below 100.” Drive production code with the generated
value. Do not test a sort by comparing it to a second call to the same sort.

### Choose properties strong enough to reject wrong implementations

- **Round-trip:** decode(encode(x)) preserves x, with normalization policy explicit.
  Both operations could share a bug; also use externally specified examples or
  an independent implementation where compatibility matters.
- **Idempotence:** applying normalization twice equals once. A function returning
  empty text also satisfies this, so add expected outputs and preservation rules.
- **Ordering + conservation:** sorting produces ordered output and preserves the
  multiset, not merely length. A reference frequency map is a useful independent
  oracle for small domains.
- **State machine:** apply generated actions to production and a simple model;
  compare externally visible state after each action, including failed actions.
- **Algebraic laws:** use only laws actually promised. Floating-point addition
  is not generally associative; integer addition needs an explicit overflow policy.

### Shrinking and replay are part of the workflow

When a property fails, retain the generated input, seed/replay data, and relevant
feature/runtime configuration. Let shrinking simplify the counterexample before
fixing the cause. Shrinking is a search constrained by the strategy and configured
limits, not a guarantee of the globally smallest counterexample.

[Runner configuration](https://docs.rs/proptest/latest/proptest/test_runner/struct.Config.html)
controls case counts, rejection/shrink limits, RNG seed, and persistence. Standard
configuration persists failures under `proptest-regressions`; preserve the files
in version control when appropriate and add a readable fixed regression for the
minimal case. Replay depends on the strategy and library version; a fixed example
protects against future generator changes. Increase `PROPTEST_CASES` for a larger
search only after the property and generator are sound. Do not discard a failure
by changing seeds or treating a later lucky pass as a fix.

## Test doubles: smallest boundary, explicit oracle

| Double | Appropriate use | What it does not establish |
|---|---|---|
| Stub | Return a chosen time, read error, or remote response | Correct real adapter behavior |
| Fake | Stateful in-memory repository exercising domain transitions | Actual database isolation or constraints |
| Spy | Record notifications and inspect after the operation | That the real remote service received them |
| Mock | Enforce a meaningful interaction contract | Overall correctness if output/state are not checked |

Do not mock the system under test, pure transformations, basic collections, or
all internal calls. For “save succeeds before notifying,” assert both persisted
state/output and the interaction rule. For “save fails,” assert the error and
no notification. Keep at least a focused real-adapter integration check where
schema, filesystem, serialization, or transport details can diverge from a fake.

## mockall: expectations are not a response playlist

Follow [Mockall's guide](https://docs.rs/mockall/latest/mockall/) for the installed
version. For unit tests with a dev-dependency, use
`#[cfg_attr(test, mockall::automock)]` on an appropriate existing trait;
`#[automock]` generates `MockTraitName`. This conditional mock type is not
available from an integration test importing the normally built library.

For a repository read method, configure `expect_get()` with an exact key predicate
such as `.with(mockall::predicate::eq("user:42"))`, the required `.times(1)`, and
an explicit return value/closure. Then run the **real** service and assert its
returned user or domain error. Use `.never()` for forbidden interactions.

Important semantics:

- Call counts are unrestricted unless constrained. An expectation without
  `.times(1)` does not prove the interaction occurred exactly once.
- `.returning(...)` configures the return behavior of one expectation. Chaining
  several `.returning(...)` calls does **not** build a sequence of responses.
  Create separate one-call expectations with `.in_sequence(&mut sequence)`
  when ordered responses are the actual contract, or use one explicit stateful
  closure. Don't assert internal ordering when only the final outcome matters.
- Matching expectations are examined in insertion order. Put narrow matchers
  before any catch-all so a fallback cannot mask the assertion you intended.
- `.checkpoint()` validates outstanding expectations and clears them; use it
  at an intentional phase boundary, not to hide missing calls.
- Closures returning borrowed fixture values must obey their actual lifetime
  requirements. Move owned values into closures or use owned return types
  rather than leaking data or assuming a local reference is `'static`.
- Async trait support depends on the trait form and macro integration. Read the
  installed version's async section; don't mechanically apply a synchronous
  mock to a method returning a future or suppress `Send`/lifetime errors.

## rstest: readable cases, isolated fixtures

[rstest](https://docs.rs/rstest/latest/rstest/) is useful when a case table or
shared arrangement improves diagnosis. A plain loop with input values in the
assertion message is sufficient for a small table; do not add a crate just to
remove three repetitive assertions.

- `#[rstest]` with `#[case(...)]` and `#[case]` parameters generates a test per
  row. Name cases by behavior, for example exact-stock success and excess-stock
  rejection, rather than only by an unexplained numeric index.
- `#[values(...)]` on multiple parameters produces their Cartesian product,
  not a zip. Use rows when only specific combinations are valid; an unnecessary
  Cartesian explosion makes tests slow without improving coverage.
- A `#[fixture]` function returns arranged data; argument names select fixtures,
  and fixtures can depend on other fixtures. Return owned state or a resource
  guard, with cleanup tied to its lifetime.
- Avoid global mutable fixtures. Every test should receive isolated state and
  own its temporary directory/server/task resources. Shared immutable expensive
  data may be reasonable; a shared database that tests mutate is a different risk.
- Keep case-specific facts visible at the call site. A fixture that silently
  creates an authenticated user, grants permissions, and populates stock can
  conceal the very precondition the test intends to exercise.

Mocks and fixtures should reduce incidental setup, not encode the production
algorithm in a second implementation or conceal missing assertions.
