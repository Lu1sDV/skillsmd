# Flaky tests reference

Detail for the flaky section of [SKILL.md](../SKILL.md).

## Policy

A flaky test is red. Fix it, or quarantine it visibly with a reason, an owner, an issue and an exit date. A required test is never skipped silently. Rerunning until green hides the signal, and a passing retry is not a root cause or a fix. Do not raise a timeout or add a sleep just to make failures rarer. A failure you observed may be rerun once to tell flaky from deterministic; do not rerun a failure the user already reported just to confirm it.

## When to check a test for flakiness

Check any new or changed test that touches:
- async work, threads or timers
- wall-clock time or time zones
- randomness or generated IDs
- test order or state shared with another test (static fields, globals, files, databases, environment)
- the network or the filesystem
- an unordered collection (set, map, hash order, unsorted query results)

In a study of 7,571 flaky Python tests, order dependence caused 59% and test infrastructure 28%.

## Procedure

1. **Read the failure and the test.** Match it to a cause below. Never assert the order of an unordered result: sort it or compare as a set.
2. **Random-order run,** where the runner supports it. Run the suite, or at least the file, in random order and in isolation. In the Python study, order-dependent flakiness needed a median of about 31 random-order runs for 95% confidence, versus about 170 reruns for other causes. Both figures are medians over tests already known to be flaky.
3. **Pin the suspect variable and rerun:** fix the seed, the clock or the order, or inject a delay. Ten reruns are not expected to find more than about a third of non-order-dependent and half of order-dependent flaky tests on average, so unpinned reruns are a weak detector.
4. **Reproduce before fixing.** A fix needs a forced reproduction (pinned order, seed, delay) that fails before the change and passes after. If you cannot reproduce, say the cause is unconfirmed instead of reporting it fixed.

## Causes and fixes

| Cause | Fix |
|---|---|
| Order dependence, shared mutable state | Fresh state per test; no reliance on another test having run; random order in CI |
| Async or missing wait | Wait on a condition or the observable outcome with a deadline, never a fixed duration; await or join every worker |
| Concurrency | Synchronize on events or channels; make the schedule controllable |
| Time | Inject a clock; never read the wall clock in the assertion |
| Randomness | Fix or log the seed; keep the shrunk or failing seed |
| Network, external service | Local fake or recorded boundary for unit and integration runs; live service only in a labelled job |
| Unordered collection | Sort, or compare as a set |
| Resource leak, infrastructure (ports, temp paths, timeouts) | Acquire cleanup immediately after acquisition; unique temp paths and ports |

## Generated tests

Existing tests placed in the model's context transfer their flakiness to new tests. In a study of generated database tests, 72 of 115 flaky ones (63%) depended on ordering that was not guaranteed. Before copying a pattern from existing tests, check that it is deterministic. When a generated test touches anything in the trigger list above, run it in random order before reporting it done.
