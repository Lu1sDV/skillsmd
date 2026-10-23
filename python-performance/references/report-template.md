# Experiment report

Scale this template to the task. Record observations; mark unknowns/not-measured
explicitly. Keep raw artifacts and commands with the project when appropriate.

## Contract

- Objective/threshold: latency distribution, throughput at acceptable errors, batch
  or startup duration, peak/steady memory, or resource cost; choose one primary metric.
- Guardrails: correctness, memory, tail latency, errors and cost.
- Workload: input identity, sizes/distribution/skew, hit/miss mix, concurrency,
  cold/warm policy and warm-up.
- Semantics: values/types/order/duplicates, mutation/aliasing, exceptions, precision,
  transactions, cancellation, retries/idempotency.
- Boundary: included/excluded setup, parsing/conversion, transfers, serialization,
  queueing, consumption and teardown.

## Reproduction

- Baseline/candidate revisions; implementation/version/build, GIL/JIT state,
  dependency versions/lock, OS/architecture.
- CPU quota/affinity, memory limits, process/worker/native-thread settings.
- Exact setup, profiling and unprofiled benchmark commands; raw result/profile
  locations and collection limits.

## Evidence and change

- Bottleneck: supporting samples, call counts, allocation stacks, spans or plans.
- Hypothesis: mechanism, affected fraction, tradeoff, falsifying result and why the
  change is proportionate.
- Correctness: existing tests and focused semantic cases; numerical range/tolerance
  justification, concurrency failure/cleanup checks, and unavailable validation.

## Results

| Metric/workload | Baseline | Candidate | Units, variability, repetitions | Interpretation |
|---|---|---|---|---|
| Primary | Not measured | Not measured | Sample design | Unverified |
| Memory | Not measured | Not measured | RSS/peak/live scope | Unverified |
| Latency/errors | Not measured | Not measured | Load/denominator | Unverified |

For durations: speedup = `baseline/candidate`; reduction =
`100 × (1 - candidate/baseline)`. Calculate throughput increase separately. Compare
compatible metrics; distinguish uncertainty from practical significance.

## Decision

Accept, reject or gather evidence. State benefit, maintenance/resource costs,
remaining bottleneck, regression coverage and transfer limits. Include rollout/
rollback details when deployment is requested.
