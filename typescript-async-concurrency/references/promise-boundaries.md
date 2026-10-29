# Promise and Boundary Checks

## Outcomes and observation

Choose a result contract deliberately: throw, a discriminated Result, or per-item settled results. Preserve original causes when wrapping errors. Treat thrown values as unknown; normalize them only when the public contract requires an Error.

For an ordinary array of promises, `all` preserves input ordering, `allSettled` records each outcome, `race` follows the first settlement, and `any` follows the first fulfillment. None of those methods intrinsically cancels losing or sibling work.

Handle aggregate rejection reasons where useful. Do not redefine the built-in settled-result type as one object with unrelated optional value/reason properties; narrow the discriminated union by status.

## HTTP boundaries

Check `response.ok` or the project's explicit accepted status set. A resolved fetch promise is not proof of an HTTP success status. Decide which responses have a body before parsing.

Decode JSON into unknown, then validate the required shape. Make the decoder an input to a generic helper instead of treating a type parameter as proof of runtime data. Normalize dates, enums, and optional fields according to the domain.

Preserve cancellation and network failures separately from invalid payloads or application errors when the caller needs that distinction. Avoid exposing secrets or complete external payloads through error messages.

## Timeouts and cooperative abort

Define whether a timeout only rejects the caller-facing promise or also signals underlying work. A task that ignores AbortSignal can continue even after timeout; report that boundary accurately.

Check pre-aborted signals, propagate reasons, and remove abort listeners after settlement. Clear timeout handles when work completes first. When composing cancellation sources, use supported runtime APIs or a cleanup-aware implementation.

Do not make error recognition depend solely on a same-realm DOMException constructor when callers can supply arbitrary abort reasons or cross-realm errors. Honor the established signal and error contract.

## Async iterators and streams

Use `for await...of` when each item should be consumed before requesting more. For parallel processing, bound in-flight items rather than collecting the entire stream.

Define what early termination means for upstream work. Release reader locks and cancel/close owned streams as the API contract requires. Preserve backpressure, propagate errors, and stop pagination with an explicit termination condition.

Validate HTTP responses and page data before using cursor/items fields. Avoid unbounded loops when a service repeats a cursor or never produces an empty page; honor the documented pagination contract and task limits.

## Callback adaptation

Match the actual callback signature, optional arguments, and receiver binding. Reject on error and resolve only once. Prefer a runtime-supported adapter when it matches the API; do not assume a one-callback toy wrapper can adapt every overloaded I/O function.

Use async functions directly when they already return promises. Avoid an async Promise executor whose returned promise is ignored by the constructor.

## Verification cases

- Reject one task immediately while another remains pending; verify all started failures are observed.
- Resolve tasks in reverse order; verify promised output order.
- Return an HTTP error response with valid JSON; verify it is not mistaken for success.
- Return JSON with the wrong shape; verify the decoder rejects it.
- Abort before start and during a retry delay; verify no later attempt starts.
- Finish before the timeout; verify no retained timer or listener changes later state.
- Stop a stream consumer early; verify its owned resources are released.

## Primary references

- [ECMAScript promises](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-promise-objects)
- [DOM cooperative abort semantics](https://dom.spec.whatwg.org/#aborting-ongoing-activities)
- [StructWeave: typed async functions](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/06-async-patterns.md#typed-async-functions)
- [StructWeave: standard library async primitives](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/15-std-library-essentials.md#async-primitives)
