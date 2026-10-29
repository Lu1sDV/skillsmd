# Diagnostic and interview cases

## Select a task with an observable distinction

Use these as prompts or counterexample ideas. Match difficulty to the user's answer, and do not present the whole bank during a one-question interview.

| Topic | Ask or inspect | Change one condition |
| --- | --- | --- |
| Type versus interface | Can two declarations add fields to the same named shape? | Replace the interface declarations with aliases, or intersect conflicting fields. |
| Unknown versus any | Which operations are allowed on untrusted input before checking it? | Add a real `typeof` guard, then replace it with an assertion. |
| Never | What proves every variant was handled? | Add one discriminant and observe the exhaustive check. |
| Nullish defaults | What happens for `0`, `false`, empty string, null, and undefined? | Exchange `??` and `||`; define which behavior matches the contract. |
| Object equality | Are independently created equal-shaped objects equal? | Reuse the same reference, or compare fields explicitly. |
| Generic defaults | Does a default type argument replace a missing runtime argument? | Use an inferred argument, an explicit type argument, and no inference source. |
| Conditional distribution | Does a union become one array or a union of arrays? | Wrap the checked type parameter in a tuple. |
| Enum representation | What runtime object exists after compilation? | Compare a regular enum, a const enum under the actual config, and an `as const` object. |
| Method binding | What receiver does a detached method use? | Call through the object, use `.bind`, or use an arrow field. |
| Satisfies | What property type does the caller retain? | Compare an annotation, `satisfies`, and an assertion on the same literal. |
| Readonly | Which mutation is rejected statically and which succeeds at runtime? | Mutate a nested object or a separate mutable alias. |
| Callback variance | Can an Animal handler serve where a Dog handler is required? | Reverse the substitution and compare method versus function-property declarations. |
| Excess properties | Why is a fresh literal rejected but a wider variable accepted? | Examine the object's runtime keys after assignment to a narrower type. |
| Augmentation | Does declaring a method make it callable at runtime? | Add the actual runtime implementation or remove it. |
| Overloads | Which signature is selected for a given argument? | Reorder broad and specific overloads; inspect the inferred result. |

## A useful analysis format

For an example with disputed behavior, record:

1. Compiler version and the flags that matter.
2. The static type at the important expression and any diagnostic.
3. Whether the selected toolchain emits, strips, or rejects the syntax.
4. The JavaScript result if it executes.
5. The smallest change that establishes the desired contract.

Do not conflate "the compiler rejects this" with "the expression has no JavaScript runtime behavior." Whether execution proceeds depends on the chosen toolchain and emit/run settings.

## One original callback example

```typescript
interface Animal { name: string }
interface Dog extends Animal { breed: string }

const handleAnimal = (animal: Animal): string => animal.name;
const handleDog = (dog: Dog): string => dog.breed;

const forDogs: (dog: Dog) => string = handleAnimal;
// @ts-expect-error: a Dog-only callback cannot handle every Animal.
const forAnimals: (animal: Animal) => string = handleDog;

void forDogs;
void forAnimals;
```

Evaluate this as a compile-only example with `strictFunctionTypes` enabled. Then ask why changing an API from a function property to method syntax can affect assignability. Do not execute intentionally invalid negative type examples.

## Assessment criteria

Prefer a short answer that correctly names the rule and supplies a counterexample over a long list of syntax facts. Flag an answer as incomplete when it omits a condition that changes the result; flag it as incorrect when its predicted behavior or substitution direction is false.

For recurring mistakes, keep a compact practice note consisting of the mistaken rule, corrected rule, one example, and one future prompt. Do not build a broad study plan unless requested.

## Sources

- [Pinned upstream question inventory](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/14-interview-trap-questions.md)
- [Official type compatibility reference](https://www.typescriptlang.org/docs/handbook/type-compatibility.html)
- [Official function and overload guidance](https://www.typescriptlang.org/docs/handbook/2/functions.html)
