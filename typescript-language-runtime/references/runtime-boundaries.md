# Runtime boundary validation

## Earn the type from the input

Accept untrusted input as `unknown`. Validate its container, fields, field types, and domain constraints before constructing a typed value. Use an existing project schema library when one is established; choose a handwritten parser for a small stable contract when that is sufficient.

This original example validates and projects a small payload without an assertion:

```typescript
type Metric = { label: string; value: number };

function parseMetric(input: unknown): Metric {
  if (
    typeof input !== "object" || input === null || Array.isArray(input) ||
    !("label" in input) || typeof input.label !== "string" ||
    !("value" in input) || typeof input.value !== "number" ||
    !Number.isFinite(input.value)
  ) {
    throw new TypeError("Expected a label and a finite numeric value");
  }
  return { label: input.label, value: input.value };
}
```

Choose whether to reject or discard unknown fields from the actual contract. The example discards them by constructing a new object. Checking only that `label` and `value` exist would not establish their types.

## Apply the boundary contract

| Boundary | Required decisions |
| --- | --- |
| HTTP response | Check status before treating the body as success; parse JSON; validate `unknown`; preserve useful error context. |
| Environment variable | Distinguish missing, empty, malformed, and out-of-range values; do not use partial numeric parsing accidentally. |
| Configuration file | Separate read errors, JSON syntax errors, and schema errors; apply defaults after defining their semantics. |
| Persisted data | Account for old schema versions; migrate explicitly or reject with an actionable error. |
| Date or numeric text | Reject invalid dates/non-finite numbers; define timezone, rounding, units, and accepted formats. |

Use a `Result` union or exceptions according to the surrounding API. The choice between a throwing parser and a result-returning parser concerns error handling, not how trustworthy the input is.

## Avoid static-only assurances

- `fetchData<User>()` does not prove that the server returned a User. Pass a parser or validate within the function.
- `as User` and a handwritten `value is User` predicate are claims; the compiler does not prove their runtime implementation.
- `Pick` and `Omit` change the visible type, not an existing object's properties. Construct a new object when redacting fields.
- `Readonly<T>` does not recursively freeze data. `Object.freeze` is shallow and does not make every built-in collection immutable.
- `satisfies` checks an expression's compatibility at compile time; it does not validate network or storage data at runtime.

## Minimal validation matrix

Check one valid payload plus each materially different invalid class: null/container mismatch, missing required field, wrong field type, invalid domain value, and unknown-field behavior if the contract defines it. Confirm that a malformed field cannot pass a predicate and later crash a typed consumer.

For `parseMetric`, include `{ label: "cpu", value: 12 }`, `null`, `{}`, `{ label: 1, value: 12 }`, `{ label: "cpu", value: "12" }`, and non-finite values. Add empty-label or negative-value cases only if the domain excludes them.

## Sources

- [Upstream runtime validation section](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/07-modern-typescript.md#runtime-validation--type-safety)
- [TypeScript narrowing handbook](https://www.typescriptlang.org/docs/handbook/2/narrowing.html)
- [TypeScript 5.5 notes on type-predicate semantics](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-5.html)
