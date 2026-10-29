# Focused TypeScript review checklist

Select checks that explain the observed problem. Prioritize correctness and
contract clarity before style changes. Use the existing project toolchain.

## Contents

- [Runtime boundaries and types](#runtime-boundaries-and-types)
- [SOLID without unnecessary abstraction](#solid-without-unnecessary-abstraction)
- [Errors, asynchronous effects, and state](#errors-asynchronous-effects-and-state)
- [Modules and dependency direction](#modules-and-dependency-direction)
- [Performance changes](#performance-changes)
- [Interpret the source carefully](#interpret-the-source-carefully)
- [Sources](#sources)

## Runtime boundaries and types

| Inspect | Require | Avoid |
| --- | --- | --- |
| JSON, API responses, environment values, storage | Parse from `unknown`; validate shape and domain constraints | A generic return type or `as DomainType` pretending to validate |
| Type predicates | Check the full invariant promised by the predicate | Checking that a key exists while assuming its value has the right type |
| Optional fields | Distinguish missing, explicit `undefined`, `null`, and a valid falsey value | Replacing `??` with `||` without checking behavior |
| State models | Encode valid combinations as discriminated alternatives | Independent flags that permit impossible states |
| Public types | Describe the supported caller contract | Widening public outputs accidentally during a refactor |
| Assertions and `any` | Restrict escape hatches to justified, documented boundaries | Broad casts used to silence compiler evidence |
| Strict compiler options | Follow project policy and assess incremental migration scope | Enabling new flags across the project as an unrelated change |

Remember that `strict` does not enable every useful compiler option. Evaluate
`noUncheckedIndexedAccess` and `exactOptionalPropertyTypes` separately when the
task concerns index safety or optional-property semantics.

## SOLID without unnecessary abstraction

- **SRP:** group code by a coherent reason to change. Keep related small functions
  together; do not equate responsibility with one method or one file.
- **OCP:** identify a stable seam and a real extension requirement. Keep ordinary
  edits and exhaustive switches for finite closed models when they remain clearer.
- **LSP:** compare allowed inputs, output guarantees, errors, effects, invariants,
  and state history. Test the same observable contract across implementations.
- **ISP:** shape interfaces around actual consumers. Avoid stub methods that throw
  solely because an implementation does not support an overbroad interface.
- **DIP:** let domain policy name the capability it needs, then supply adapters
  from the composition boundary. Use typed functions when an object adds no value.

For function properties checked under `strictFunctionTypes`, a function accepting
an `Animal` can fulfill a contract that only passes `Dog`; the reverse may reject
valid animals. Remember that method syntax has a bivariance exception. Establish
behavioral safety independently of whether a particular assignment compiles.

## Errors, asynchronous effects, and state

- Preserve whether failure throws, rejects, returns a result variant, or produces
  partial output. Keep deliberate failure visible to the caller.
- Normalize caught `unknown` values before reading fields. Preserve original
  causes when translating an error into an application-specific error.
- Assign responsibility for awaiting and rejecting work. A logging-only catch
  needs an explicit continuation policy; otherwise it can silently change failure
  into success.
- Verify cancellation ownership and stale-result prevention. Abort underlying
  work when supported; retain request identity checks when late completion can
  still overwrite newer state.
- Distinguish shared configuration, mutable per-request state, and resource pools.
  Give caches and subscriptions a disposal or eviction policy appropriate to use.
- Preserve transaction and idempotency requirements when separating persistence
  from notification. A smaller function does not create atomicity across systems.

## Modules and dependency direction

1. Trace the actual runtime import graph around a cycle. Distinguish a type-only
   relation from an import whose initialization executes code.
2. Extract a shared type/value into a neutral module, invert a dependency through
   a port, or move orchestration outside the mutually dependent modules.
3. Keep package boundary exports intentional. Use direct internal imports where
   they prevent accidental self-import through a barrel.
4. Re-run the relevant entry point after the change. Two direct imports can still
   form a cycle; a clean-looking path is not evidence that the cycle disappeared.
5. Adopt project references or package-boundary changes only when the repository's
   build model benefits. Verify output paths, dependencies, and runtime resolution;
   do not assume a package count implies a particular build architecture.

When adding or repairing boundary enforcement:

1. Identify public entry points and forbidden dependency edges from the existing
   architecture. Reuse its enforcement tool and configuration where possible.
2. Establish a passing allowed import. In a temporary fixture or isolated edit,
   introduce one resolvable import that violates the intended boundary.
3. Run the relevant check and require failure from the expected boundary rule;
   a missing module or unrelated compiler error does not demonstrate enforcement.
4. Remove only the probe, preserving pre-existing edits, then require another pass.
   Clean up even if a check fails; report if the rule never rejected the probe.
5. Confirm the same check runs through the project's intended local/CI gate.
   Report the allowed edge, rejected edge, rule, and command outcomes.

## Performance changes

| Candidate change | Preserve | Measure when relevant |
| --- | --- | --- |
| Repeated array membership to a Set | Equality, duplicate output, iteration order | Construction cost plus repeated queries |
| Linear record lookup to a Map | Key semantics and replacement/duplicate policy | Real read/write/delete workload |
| Repeated spreading to one transformation | Overwrite order and aliasing | Allocation volume and elapsed time |
| Copying to in-place mutation | Caller ownership and snapshot expectations | Time/memory with equivalent semantics |
| Complex recursive types to simpler contracts | Accepted/rejected programs and API ergonomics | Compiler diagnostics on the affected project |
| Object-shape changes | Correctness and public data shape | The actual deployed engine and workload |

Avoid hard-coded rules about small data thresholds or engine inline-cache states.
Separate measured improvements from hypotheses; keep the clearer implementation
when there is no meaningful benefit.

## Interpret the source carefully

Use chapter 13's anti-pattern categories as inspection prompts. Correct these
limitations before borrowing an example:

- Replace the chapter's `processWithLimit` implementation; it removes the newest
  submitted promise after a race and can exceed the limit or return too early.
- Validate property types in guards; a `"breed" in value` check alone does not
  establish a `string` breed or other required members.
- Resolve dependency direction instead of assuming direct imports remove cycles.
- Treat fake hashing, authentication, payment, and storage implementations as
  teaching stubs; use the application's real adapters and their contracts.
- Verify current tool configuration against installed versions. Do not paste
  a historical ESLint/Biome/monorepo configuration into an unrelated setup.

## Sources

- [SOLID contracts and dependency injection](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/09-solid-principles.md)
- [Anti-pattern categories and examples](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/13-anti-patterns-best-practices.md)
