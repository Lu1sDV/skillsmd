# Runtime API Checks

## Iterators and generators

Define finite versus infinite input, laziness, consumption count, and ownership of iterator cleanup. Validate positive integer chunk/window sizes. Define zero-input zip as immediate completion or reject it explicitly. Specify whether zip stops at the shortest input.

Avoid consuming an extra item when taking exactly n results. On early termination, close owned underlying iterators where their contract requires it. Do not materialize an infinite iterator with spread. Check runtime support for iterator helpers; `Iterator.from` is not a polyfill for missing runtime APIs.

## Text and numbers

Choose code units, code points, or user-perceived graphemes before implementing indexing, length, reversal, or windows. Keep normalization and case-folding assumptions explicit. Do not mix `for...of` code-point iteration with code-unit index arithmetic unless that conversion is intentional.

Use `Intl` with an explicit locale/timezone when output must be reproducible. Distinguish validation from a convenient regex heuristic; a short email regex is not a comprehensive address validator.

Check integer bounds and finite values before arithmetic. Use bigint for exact integer results outside the safe number range, with an explicit serialization policy. Avoid number bitwise operations for unrestricted integer arithmetic. Avoid spreading unbounded arrays into function arguments.

## Binary data

Distinguish a buffer from its typed views. Check byte offset, element width, range, and endian convention; use DataView for mixed layouts. Treat multiple views of one buffer as shared mutable data.

Use TextEncoder/TextDecoder for the required character encoding and define invalid-byte handling. For base64, use the runtime's supported byte APIs or bounded chunks; avoid a huge `String.fromCharCode(...bytes)` call.

## Dates and durations

Separate a timestamp/elapsed duration from a calendar date and local-time arithmetic. Use explicit timezone rules for calendar operations. Do not infer calendar days from rounded elapsed milliseconds divided by 24 hours across arbitrary DST boundaries.

Define handling for invalid dates and ambiguous input strings. Test month/year boundaries and timezone transitions when the feature depends on them.

## JSON, cloning, and immutability

Treat parsed JSON as untrusted `unknown`; validate before declaring a domain type. Specify how missing fields, null, numbers, unknown properties, and versioned schemas are handled. Define representation for bigint, Date, Map, and Set rather than assuming ordinary JSON preserves them.

Use shallow copying for shallow independence and structured cloning for supported data graphs. Check clone limitations, class/prototype behavior, and transfer-list ownership. Treat structuredClone as a host API whose availability must be checked.

Do not claim deep immutability from `Object.freeze(structuredClone(value))`: only the outer clone is frozen. Deep immutability requires an explicit approach that understands nested containers and the domain; freezing a Map object does not prevent its entry-mutating methods.

## Reflection, errors, and lifetime

Preserve accessor receiver semantics with Proxy/Reflect when proxying objects. Do not invent a general cache key by JSON-stringifying arbitrary arguments: identity, cycles, unsupported values, and collisions can change behavior.

Preserve meaningful error causes and narrow caught unknown values. Avoid copying sensitive payloads into messages by default.

Treat finalization as optional cleanup, never the required mechanism for correctness or resource release. If a weak cache overwrites a key, ensure an old finalizer cannot delete the replacement; use registration identity checks and a deliberate unregister policy. Prefer explicit size/TTL limits when predictable cache behavior is needed.

## Source sections

- [Standard library: iterators and generators](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/15-std-library-essentials.md#iterators--generators)
- [Standard library: object and reflection](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/15-std-library-essentials.md#object--reflection)
- [ECMAScript Object.freeze](https://tc39.es/ecma262/multipage/fundamental-objects.html#sec-object.freeze)
- [HTML structured serialization](https://html.spec.whatwg.org/multipage/structured-data.html#structured-cloning)
