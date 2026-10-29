---
name: typescript-type-modeling
description: >
  Use when designing or repairing TypeScript domain models, public API types, narrowing,
  generic relationships, mapped and conditional types, utility types, or inference;
  representing valid states, deriving types from values, fixing assignability errors, or
  checking positive and negative compile examples. Use typescript-language-runtime for
  runtime parsing and execution compatibility.
---

# TypeScript Type Modeling

Express the real contract with the smallest type model that makes misuse visible.

## Establish concrete requirements

1. Inspect the existing types, call sites, compiler version, and effective compiler options.
2. Write one valid use, one invalid use, and the value or state each should produce. Include missing, null, empty, or readonly cases when relevant.
3. Identify what is known at compile time and what must be checked at runtime.
4. Identify relationships between inputs and outputs before introducing type parameters.
5. Preserve public compatibility unless the requested change explicitly includes migration.

Read [type-design-decisions.md](references/type-design-decisions.md) when choosing a representation, utility, constraint, or recursive transformation.

## Build the model in layers

1. Model finite states or alternatives with a discriminant. Put variant-specific required fields on the corresponding variant.
2. Use an interface or object type for a coherent shape. Choose declaration merging only when open extension is intended.
3. Identify any schema or generator that owns the shape. Derive local views from its types, or from existing values, before declaring a parallel contract.
4. Add a generic parameter only to express a useful relationship. Constrain it to capabilities the implementation actually needs.
5. Preserve useful inference at call sites. Use `satisfies` for compatibility checking, readonly inputs for nonmutating APIs, and const type parameters when literal preservation is required and supported.
6. Narrow through checks the runtime performs. Treat an explicit predicate or assertion as a proof obligation, not compiler-verified validation.
7. Use mapped or conditional types only after plain composition becomes insufficient. Define union distribution and recursion behavior deliberately.
8. Verify public call sites and rejected cases before polishing aliases or adding abstraction.

## Choose an appropriate tool

| Requirement | Preferred starting point |
| --- | --- |
| Distinct success/error or lifecycle states | Discriminated union with exhaustive handling. |
| Same primitive, different domain identities or units | A brand when accidental interchange is a real risk; construct it through the owning boundary. |
| Select or omit known properties in a static view | `Pick` or `Omit`; separately construct runtime output if fields must be removed. |
| Optional update fields | `Partial`, with an explicit policy for absent versus present `undefined` values. |
| Finite complete lookup table | `Record<KeyUnion, Value>` and, where useful, `satisfies`. |
| Dynamic possibly missing key | `Map` or an appropriately optional/indexed object contract; account for lookup failure. |
| Preserve key/value correlation | `K extends keyof T` with return or parameter type `T[K]`. |
| Derive a function or promise result | `ReturnType`, `Parameters`, `ConstructorParameters`, or `Awaited` as appropriate. |
| Transform property names or modifiers | Mapped type with key remapping only where required. |
| Extract a structural component | Conditional type with `infer` in the `extends` pattern. |
| Control inference from one argument | Restructure the signature first; consider `NoInfer` when supported and justified. |

## Guard against false guarantees

- Do not replace a failing type relationship with broad `any`, double assertions, or non-null assertions.
- Do not promise that `Readonly`, `as const`, `satisfies`, or a utility type changes runtime values.
- Do not declare a JSON payload to be `T` solely because the caller supplied `T`. Route validation work to `typescript-language-runtime`.
- Do not accept a type predicate that only checks property existence when it promises property types or stronger invariants.
- Preserve arrays, tuples, functions, and built-in objects intentionally in recursive utilities. State the utility's supported domain.
- Avoid exponential template-literal unions and unbounded recursive paths. Prefer a simpler public contract if realistic inputs exhaust compiler limits.
- Treat `Object.keys` assertions cautiously: structural object types may hide extra runtime properties, and symbol keys are omitted.
- For callback assignment, check function-parameter variance in the correct direction and distinguish function properties from methods.
- For typestate or accumulating builders, ensure return types describe the values actually returned, including arrays and mutation ownership.

## Validate types and values separately

1. Run the project's existing type check with its pinned compiler and configuration.
2. Verify accepted examples retain the intended result types rather than merely compiling through `any`.
3. Verify rejected calls using the existing type-test tooling or focused `@ts-expect-error` examples that fail if the error disappears.
4. Cover only the meaningful cases: unions, optional members, readonly inputs, empty tuples, callbacks, or invalid keys as the design requires.
5. Run runtime tests when the change includes parsing, mutation, returned value shapes, or behavior. Type tests alone do not establish these.
6. Record any compiler-version sensitivity and any assertion whose invariant remains external to the type system.

Read [type-contract-checks.md](references/type-contract-checks.md) for a small validation pattern and common sources of misleading confidence. Use `typescript-tooling-tdd` for broader test setup.

## Deliver the contract and its evidence

Return the resulting declarations or implementation, a short explanation of the modeled invariants, accepted and rejected usage examples, validation results, and any compatibility or runtime-validation requirement.

For a type-error explanation, identify the incompatible relationship and the smallest correction. Avoid rewriting the surrounding architecture unless that relationship requires it.

## Source basis

Use the pinned chapters as subject references, with the corrections and constraints above.

- [Type system mastery, chapter 03](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/03-type-system-mastery.md)
- [Utility types and generics, chapter 05](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/05-utility-types-generics.md)
