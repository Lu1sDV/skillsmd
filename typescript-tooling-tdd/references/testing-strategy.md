# Testing Strategy

## Derive tests from a contract

Write down observable results, failure semantics, mutation/ownership, ordering, and environment assumptions before choosing test cases. For a bug, retain the smallest failing example. For a refactor, characterize supported existing behavior and record intentional changes separately.

| Layer | Establish | Do not substitute |
| --- | --- | --- |
| Compile-time contract | Accepted and rejected calls, narrowing, generic relationships | Runtime assertions for static assignability |
| Pure function | Independent examples and invariants | A mock of the function being tested |
| Boundary adapter | Data shape, error mapping, cancellation, protocol | A happy-path fake for all integration evidence |
| Component/user flow | Observable interaction and state transitions | Private implementation fields |
| Deployment/build wiring | Actual emitted entry point or representative consumer | A compiler-only success |

For compile-time regressions, use the existing type-test system or small compiler-checked fixtures with descriptive `@ts-expect-error` cases. Verify the intended diagnostic, since a misspelled name can accidentally satisfy a negative type test. Ensure those fixtures are actually included in a compiler invocation.

## Choose independent properties

| Behavior | Useful property | Common false confidence |
| --- | --- | --- |
| Sort | Nondecreasing output and unchanged element frequencies | Comparing two calls to the same sort implementation |
| Binary search | Returned boundary partitions all elements correctly | Checking only a found value, ignoring duplicates and absence |
| Merge intervals | Same covered domain; ordered, nonoverlapping output | Matching a few output lengths |
| Serializer | Round trip for a documented supported domain | Assuming every JavaScript object survives JSON |
| Collection transform | Defined ordering, cardinality, and ownership | Testing only successful construction |
| Concurrency limiter | Peak active count within limit and correct task settlement | Timing the total duration with real sleeps |

Use bounded generators when exact arithmetic or domain restrictions matter. Constrain generated inputs directly where possible, rather than discarding most cases. For async properties, use an async property runner and await its assertion. Save failing seeds and minimized inputs. Shrinking searches for a smaller counterexample; do not promise a unique global minimum.

Do not use arbitrary objects for a JSON identity property: unsupported values, omitted fields, prototype differences, and numeric representation can change the result. Choose an explicitly JSON-safe domain and a comparator consistent with that domain, including a policy for negative zero.

## Make asynchronous tests deterministic

1. Control task start and settlement with deferred operations or injected dependencies; track active count and completion order explicitly.
2. Attach error observation before triggering a rejection. Await the final result rather than relying on a console message or an arbitrary delay.
3. For timers, use the runner's timer API matching the installed version, including async timer advancement when promise callbacks must flush.
4. Check timeout and cancellation separately. A rejected timeout wrapper does not prove the underlying operation stopped.
5. Restore timers and global state in teardown, including failure paths. Close servers, release resources, and unsubscribe listeners.
6. For a limiter or queue, exercise out-of-order completion, rejection, empty input, and the smallest allowed capacity; verify the stated drain/fail-fast policy.

## Select test doubles deliberately

Use a stub for fixed data, a fake for a small working boundary, and a spy/mock for a contractually meaningful interaction. Keep deterministic domain logic real. Share conformance cases between a fake and its real adapter when divergent behavior would hide defects. Give each test fresh mutable fixtures; make identifiers and timestamps explicit when assertions depend on them.

Avoid universal rules such as one assertion per test, 100% coverage, fixed pyramid ratios, or arbitrary duration limits. Group assertions around one behavior and choose scope from the risk and execution environment. Use coverage to discover missing exercised branches; use assertion review or targeted mutation checks only when they resolve a real confidence gap.

## Assertion semantics

Use identity assertions when identity matters and deep comparison when structure matters. In Vitest, `toBe` follows `Object.is`, which treats `NaN` and signed zero differently from `===`. Choose approximate numeric comparisons only when the domain permits tolerance; integer counts and exact currency models should retain exact contracts.

## Official references

- [Vitest assertions](https://vitest.dev/api/expect.html)
- [Vitest type tests](https://vitest.dev/guide/testing-types.html)
- [fast-check properties](https://fast-check.dev/docs/core-blocks/properties/)
- [fast-check runners](https://fast-check.dev/docs/core-blocks/runners/)
- [fast-check configuration and replay](https://fast-check.dev/docs/configuration/)
