# Check a type contract

## Test the caller's guarantee

Begin with the project's pinned compiler and real options. A test that passes under weaker flags or a different compiler may establish a different contract.

Use a small standalone check or the existing type-test framework. This original example verifies key/value correlation and rejects an invalid key:

```typescript
function readProperty<T, K extends keyof T>(value: T, key: K): T[K] {
  return value[key];
}

const sample = { label: "queue", count: 3 };
const label: string = readProperty(sample, "label");
const count: number = readProperty(sample, "count");

// @ts-expect-error: label access must retain its string result.
const wrong: number = readProperty(sample, "label");

// @ts-expect-error: only keys present in the input are accepted.
readProperty(sample, "missing");

void label;
void count;
void wrong;
```

Compile negative examples without executing them. Keep expected-error directives directly on the intended failing line, with a reason. Remove unrelated errors that could make an example look correctly rejected for the wrong reason.

## Verify inference and exhaustiveness

For a new discriminated union, check that each handler sees its variant's required fields. Put an explicit `never` check at an exhaustive switch boundary when adding a new variant must cause a compile error.

For a generic wrapper, check the caller's result type as well as argument acceptance. A broad `any` implementation can make every call compile while losing the promised relation.

For a builder, test that the built value's runtime shape matches its declared arrays, tuples, keys, and state. The upstream accumulating-builder example uses assertions that hide mismatches; derive a fresh implementation from concrete requirements.

## Check callback assignability in the correct direction

Under strict function-parameter checking, a callback accepting any Animal can stand in for one called only with Dogs. A callback that requires Dog-specific fields cannot safely stand in for one called with arbitrary Animals.

Method declarations have a bivariance exception, so inspect whether the API exposes a method or a function-valued property. See the [TypeScript 2.6 strict function types explanation](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-6.html).

## Check runtime claims with runtime cases

| Static construction | Runtime claim requiring separate evidence |
| --- | --- |
| Type guard or assertion function | Malformed input is actually rejected; promised field types and invariants are checked. |
| `Readonly<T>` or `as const` | Aliases cannot mutate data if actual immutability is required. |
| `Pick` or `Omit` return type | Omitted sensitive fields are absent from serialized output. |
| `fetchData<T>` | HTTP and schema failures are handled; response values were validated to become T. |
| Module augmentation | The claimed property or method is actually provided by runtime code. |

## Account for compiler evolution

- Reproduce narrowing examples using the installed compiler. Suitable callback narrowing improved in [5.4](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-4.html).
- Suitable filters infer predicates starting in [5.5](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-5.html). An explicit predicate remains useful when inference is insufficient, but it is not automatically sound.
- Check indexed values under the project's `noUncheckedIndexedAccess` policy; bounds checks do not always remove `undefined` from indexed expressions.
- Report the exact relevant flags when explaining variance, optional properties, unchecked indexes, nullability, or implicit any.

## Source context

Use the [upstream type predicates section](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/03-type-system-mastery.md#type-predicates) for topic coverage, but strengthen guards that only check member existence. Use the [upstream generics examples](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/05-utility-types-generics.md#real-world-patterns) as design prompts rather than validated implementations.
