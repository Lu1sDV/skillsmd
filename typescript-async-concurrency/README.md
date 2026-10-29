# typescript-async-concurrency

Design and review asynchronous TypeScript with explicit scheduling, ordering, cancellation, failure, and resource ownership. The [skill workflow](SKILL.md) targets worker pools, queues, retries, debouncing, streams, and stale-result races.

## Use

`Use $typescript-async-concurrency to review this worker pool's concurrency limit, cancellation, and rejection cleanup.`

Copy this complete folder, including references and `LICENSE.upstream`, into the skill location supported by your agent.

## References

- [Concurrency lifecycle](references/concurrency-lifecycle.md): bounded workers, rate limits, queues, locks, retries, and debouncing.
- [Promise and boundary checks](references/promise-boundaries.md): settlement, HTTP decoding, timeouts, cooperative abort, and streaming.

## Source and license

Adapted from [StructWeave TypeScript](https://github.com/nirajkvinit/StructWeave-Algorithms/tree/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript), chapter 06 and the async portions of chapter 15, at the pinned source snapshot. Retain the bundled [MIT notice](LICENSE.upstream) when copying or redistributing this skill.
