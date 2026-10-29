# Type design decisions

## Choose a representation

| Design pressure | Decision rule |
| --- | --- |
| One known shape | Use an interface or type alias according to project conventions; both participate in structural typing. |
| Open extension across declarations | Use interface/module augmentation deliberately; verify it augments the intended declaration rather than replacing a module. |
| Alternatives with different required fields | Use a discriminated union; avoid unrelated optional fields that admit invalid combinations. |
| All capabilities must coexist | Use composition or an intersection; check conflicts that produce impossible properties such as `never`. |
| A fixed set of keys is exhaustive | Use a literal key union and `Record`; distinguish this from an open string index signature. |
| Existing value is the source of truth | Derive with `typeof`, then `keyof` or indexed access as needed. |

Do not claim every interface is faster than every type alias. If compiler performance matters, inspect the actual expensive relationship and simplify it using measured evidence.

## Preserve relationships in generics

Use each type parameter to express a relation the caller benefits from. A parameter appearing only once often adds no useful relation. Use `readonly T[]` when reading without mutation so callers can supply mutable arrays or readonly collections.

For keyed APIs, preserve the specific key:

```typescript
function readProperty<T, K extends keyof T>(value: T, key: K): T[K] {
  return value[key];
}
```

Do not widen `key` to `string` and then cast the result. Avoid unnecessary `Record<string, unknown>` constraints when an ordinary object interface should be accepted.

Distinguish a generic default from an argument default. A default type parameter supplies a type when inference or an explicit argument does not; it does not synthesize a runtime value.

## Choose utilities by operation

| Operation | Tools and limitations |
| --- | --- |
| Project object fields | `Pick`, `Omit`; no runtime removal. |
| Modify property requirements | `Partial`, `Required`; generally shallow. |
| Expose a readonly view | `Readonly`, readonly arrays/tuples; no runtime freezing. |
| Filter union members | `Exclude`, `Extract`, `NonNullable`; not a runtime filter. |
| Derive callable structure | `Parameters`, `ReturnType`, `ConstructorParameters`, `InstanceType`; inspect overload and generic behavior. |
| Resolve awaited value | `Awaited`; prefer its thenable-aware behavior to a Promise-only approximation. |
| Transform keys or literals | Mapped/template-literal types; watch large unions and dropped non-string keys. |

With `exactOptionalPropertyTypes`, an optional property and a property explicitly allowing `undefined` are different contracts. Keep the distinction in updates and serializers.

## Control conditional types

- Expect `T extends U ? X : Y` to distribute when `T` is a naked type parameter instantiated with a union.
- Use `[T] extends [U] ? X : Y` when checking the union as a whole is the intended operation.
- Test `never`, `unknown`, and `any` only when they are relevant supported inputs; they can invalidate intuitive reasoning about conditions.
- Declare an inferred variable within an `extends` pattern; use that captured variable where it is in scope in the true branch.
- Handle readonly arrays and tuples if the public contract accepts them.
- Define termination and unsupported types before adding recursive transformations. Do not recursively remap every `object` and assume methods or Date/Map/Set remain useful.

## Preserve useful specificity

Use `satisfies` to check compatibility while retaining useful expression-specific information. Do not describe it as a runtime validator, a freeze operation, or a universal guarantee that contextual typing cannot influence inference. Use `as const` only when literal and readonly semantics are wanted.

Const scalar literals and mutable object properties can infer differently. Check the resulting type instead of assuming `const` makes every nested field literal or immutable.

## Sources

- [Official generics handbook](https://www.typescriptlang.org/docs/handbook/2/generics.html)
- [Official utility types reference](https://www.typescriptlang.org/docs/handbook/utility-types.html)
- [Official conditional types handbook](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html)
- [TypeScript 4.9: satisfies](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html)
- [Upstream generic constraints and advanced types](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/05-utility-types-generics.md#generic-constraints)
