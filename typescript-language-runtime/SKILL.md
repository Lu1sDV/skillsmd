---
name: typescript-language-runtime
description: >
  Use when implementing or debugging TypeScript language features, typed JavaScript
  migrations, nullish handling, functions and classes, imports and module boundaries,
  runtime input validation, or compatibility with Node type stripping and other execution
  paths. Keep static contracts and JavaScript behavior aligned; use typescript-type-modeling
  for advanced generic or type-level API design.
---

# TypeScript Language and Runtime

Make the code's static contract, emitted or stripped JavaScript, and actual execution agree.

## Establish the execution contract

1. Inspect the relevant source, package manifest, lockfile, tsconfig chain, and existing run/build commands.
2. Record the actual compiler and runtime versions when behavior depends on them. Do not treat a guide's version label as the project's version.
3. Identify the execution path: compiled JavaScript, a bundler, a TypeScript runner, or native Node stripping.
4. Identify ESM/CommonJS boundaries, package exports, import extensions, and target environments before editing imports.
5. State valid inputs, absent values, mutation ownership, and error behavior. Use the surrounding API's conventions unless they cause the reported issue.

Read [runtime-compatibility.md](references/runtime-compatibility.md) for module, decorator, feature-support, or Node stripping issues. Route broad toolchain changes to `typescript-tooling-tdd`.

## Implement the smallest coherent change

1. Preserve local inference; annotate public boundaries and ambiguous empty/nullable state. Route complex generic relationships to `typescript-type-modeling`.
2. Preserve valid `0`, `false`, and empty strings when defaulting absent values: use `??` for nullish fallback and `||` only when all falsy values should trigger it.
3. Choose functions, classes, and modules by state ownership and lifecycle. Preserve the intended `this` receiver when detaching methods or passing callbacks.
4. Match the existing module system. Use `import type` for erased dependencies and the import extensions required by the actual execution path.
5. Accept external JSON, environment variables, storage, and user input as `unknown`; validate field values and domain constraints before promising a type. Successful parsing alone does not establish validity.

Read [runtime-boundaries.md](references/runtime-boundaries.md) when adding a parser, a type guard, an API client, or configuration loading.

## Protect important invariants

- Use an assertion only when an invariant is established elsewhere and cannot be expressed directly. Explain that invariant next to the assertion.
- Guard each nullable access. Do not use optional chaining or a non-null assertion to hide a required value or an undeclared property.
- Distinguish TypeScript `private` from JavaScript `#private` when runtime encapsulation matters.
- Separate binding constancy, readonly types, runtime freezing, and aliasing. `as const`, `satisfies`, and utility types do not sanitize values or enforce deep immutability.
- For numeric or string operations, establish safe-integer limits, division rounding, number/bigint separation, and the intended Unicode unit. Use `typescript-collections` for detailed collection/API decisions.
- Verify transforms for enums, parameter properties, and decorators. Adding `lib` declarations does not install runtime APIs or polyfills.
- Avoid claiming all code examples in a tutorial are standalone compilable modules. Isolate only the relevant example and supply its dependencies.
- Preserve the project's compiler/runtime unless an upgrade is required by the requested change.

## Verify the behavior that could fail

1. Run the existing project type-check command against its real configuration. Use the pinned local compiler, not an unrequested download of a newer compiler.
2. Run the relevant module or focused existing test through the actual execution path.
3. For a module change, exercise the real import boundary; a passing type check alone cannot prove loader compatibility.
4. For a runtime validator, check valid data, missing fields, wrong field types, null, and the important domain boundaries.
5. For a nullish or numeric fix, include legitimate falsy values and one out-of-range value where relevant.
6. If a command cannot run, report the missing dependency or environment requirement and distinguish inspection from execution.

Avoid creating a new test framework for a small language correction. Add a focused regression test only when it protects meaningful behavior.

## Return a reviewable result

Provide:

- The implementation or patch with the affected entry points.
- The input, mutation, and error contracts that influenced the implementation.
- The execution path and version-sensitive assumptions.
- The type-check/runtime checks performed and their results.
- Any remaining environment limitation that affects confidence.

## Source basis

Use these pinned chapters to locate the original subject coverage; apply the corrections in the bundled references before adapting examples.

- [Syntax quick reference, chapter 01](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/01-syntax-quick-reference.md)
- [Modern TypeScript, chapter 07](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/07-modern-typescript.md)
