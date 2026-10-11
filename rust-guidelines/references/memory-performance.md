# Memory and performance

## Select the contract, not a slogan

| Profile | Meaning within the stated scope |
|---|---|
| Allocation-conscious | Allocations allowed and intentional; general-purpose default here. |
| Allocation-free steady state | Setup may allocate; the named operation and callees do not allocate or reallocate. Specify deallocation separately. |
| Strict heapless | No heap-backed storage anywhere within the declared subsystem. |

`no_std` alone proves neither heaplessness nor allocation freedom. Reusing a heap-backed
`Vec` does not make it heapless. Name covered paths (success and recoverable errors)
and exclusions such as invariant-panic diagnostics.

For stricter profiles, review bounded scratch, stack, recursion, retries, output,
queues, and concurrency; include callbacks, logging, error paths, and lazy setup.
Exhaustion needs a defined failure/backpressure policy, never silent heap spilling.
Prefer reusable storage or incremental results where appropriate. Preserve required
sorting stability and deterministic tie-breaking. Exercise exhaustion and repeated
warm operation, not just success.

## Evidence and exceptions

An allocator counter observes the tested build and execution; it is not a proof
for all inputs or builds. Optimizers may remove allocations; direct/foreign
allocators can bypass instrumentation; background threads can pollute counts.
Combine measurements with dependency and call-path review.

`dyn`, iterator, and async syntax do not establish allocation behavior. Even
`Box::new` has a zero-sized exception; a policy banning Box is stronger than a
claim that every Box construction allocates.

Compare representative before/after workloads under matching settings. Keep a
clear semantic oracle for non-obvious optimizations; require evidence before
trading away maintainability.

Basis: [gist](https://gist.github.com/auser/c3161f55a8393faa8af5ddda68c6befa) §§2, 6, 8,
11, 13, with opt-in strictness and corrected measurement/Box claims.
