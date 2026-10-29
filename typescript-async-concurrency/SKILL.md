---
name: typescript-async-concurrency
description: >
  Use when designing, implementing, debugging, or reviewing asynchronous TypeScript
  workflows: promises, async/await, typed HTTP boundaries, bounded concurrency, queues,
  retries, cancellation, timeouts, mutexes, debouncing, async iterators, or race conditions
  where lifecycle, result ordering, failures, and cleanup must be explicit.
---

# TypeScript Async and Concurrency

## Define the lifecycle

1. Inspect the project's runtime, module mode, HTTP/client abstractions, lint rules, and test tooling.
2. Identify dependent versus independent operations and when each operation actually starts.
3. Define maximum in-flight work, output ordering, fail-fast versus settle-all results, retry policy, and cancellation behavior.
4. Identify owners of timers, listeners, locks, streams, and pending caller promises.
5. Separate a concurrency limit from a requests-per-time rate limit; specify both when required.
6. Define whether returning to a caller requires started work to finish, or whether background cleanup continues.

## Choose coordination semantics

| Requirement | Starting mechanism | Remember |
| --- | --- | --- |
| Later operation needs an earlier result | Sequential `await` | Preserve dependency and error propagation |
| All independent results required | `Promise.all` | Rejection does not cancel siblings |
| Every success/failure must be reported | `Promise.allSettled` | Inspect each discriminated outcome |
| First settlement decides outcome | `Promise.race` | Losers keep running unless separately cancelled |
| First success wins | `Promise.any` | All rejections produce AggregateError |
| Limit in-flight work | Lazy tasks plus a worker pool | Already-started promises cannot be retroactively limited |
| Serialize a critical section | Queue or scoped mutex | Release in `finally`; define ownership |
| Consume a stream incrementally | Async iterator | Respect backpressure and cleanup |

For ordinary arrays of promises, define empty input deliberately: all/allSettled fulfill with an empty result, race remains pending, and any rejects. Do not use a “never rejects” slogan for arbitrary iterables that can themselves throw.

## Implement reliable scheduling

- Start independent work together and attach outcome handling promptly; avoid separately awaiting already-started promises whose earlier rejections may be unobserved.
- Validate concurrency limits as positive integers; preserve input order by storing results at input indices if the API promises that order.
- Prefer a clear worker pool or correctly maintained active set; remove the exact completed promise, not the most recently started one.
- Keep every started task's rejection observed, including cleanup chains; define whether one failure stops future scheduling.
- Do not treat batched `Promise.all` as a continuously occupied pool or a time-based rate limiter.
- Avoid `forEach(async ...)` when completion matters; use sequential iteration or an appropriate awaited coordination mechanism.
- Expose queue completion and errors; reset processing state in `finally` so one rejection cannot leave the queue stuck.
- Choose an explicit debounce contract: reject superseded calls, share the final result, or return another documented outcome. Settle every affected caller.

Read [concurrency lifecycle](references/concurrency-lifecycle.md) for worker pools, queues, locks, retries, and debouncing.

## Handle cancellation, timeouts, and stale results

1. Accept and propagate an AbortSignal where underlying operations support it; handle an already-aborted signal before starting work.
2. Define whether timeout means stop waiting, request cancellation, or both.
3. Clear owned timers and remove listeners in `finally`; release locks and stream resources on both success and failure.
4. Do not claim that a race or abort call forcibly stops arbitrary work.
5. Preserve the chosen abort reason and distinguish cancellation from retryable failure.
6. Protect “latest request wins” state with a request/version identity check as well as cancellation where appropriate.
7. Prevent an older operation's cleanup from resetting newer operation state.

## Preserve typed boundaries

- Treat HTTP status failure separately from network failure; check the response status before interpreting success data.
- Parse external JSON as `unknown` and validate with a supplied decoder or schema before returning a domain type.
- Do not imply that `fetchJson<T>`, a type assertion, or an interface validates a remote response.
- Narrow caught unknown values and retain meaningful causes; do not blindly cast every thrown value to `Error`.
- Use the built-in settled-result discriminated union; narrow by `status` before reading `value` or `reason`.
- Use `Awaited` when deriving a fulfilled value type; avoid accidental nested-promise signatures.
- Match timer types to the runtime, using `ReturnType<typeof setTimeout>` when writing portable code.
- Use existing project abstractions before adding a new async utility or dependency.

Read [promise and boundary checks](references/promise-boundaries.md) for outcome, HTTP, error, and stream details.

## Verify adverse paths

- Measure actual simultaneous task count with tasks completing in different orders; assert the configured limit and result ordering.
- Exercise synchronous task throws, asynchronous rejection, empty input, and invalid concurrency values.
- Test pre-abort, mid-flight abort, timeout, and an operation that ignores cancellation; assert only the guarantees implemented.
- Verify timers/listeners are removed and queues/locks recover after failure.
- Verify every superseded debounce caller reaches its documented outcome.
- Test retry exhaustion, cancellation during backoff, and the policy for permanent failures.
- Use the project's fake timers or controlled deferred promises where available; advance microtasks deliberately.
- Run the typecheck and focused existing tests; report any lifecycle behavior left unverified.

## Deliver

Return the implementation or review findings, the scheduling and ordering contract, failure/cancellation behavior, resource cleanup strategy, and validation results. Explain whether throughput is bounded by concurrency, rate, batching, or a dependency.

## Sources

- [StructWeave: async patterns](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/06-async-patterns.md)
- [StructWeave: standard library async primitives](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/15-std-library-essentials.md#async-primitives)
- [ECMAScript promise combinators](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-promise.all)
- [DOM: aborting ongoing activities](https://dom.spec.whatwg.org/#aborting-ongoing-activities)
