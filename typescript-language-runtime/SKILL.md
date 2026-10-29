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

1. Keep local inference where it expresses intent; annotate public boundaries and ambiguous empty/nullable state.
2. Model finite alternatives with literal unions or a small discriminated union. Route complex generic relationships to `typescript-type-modeling`.
3. Use `const` for stable bindings and `let` for reassignment. Treat mutation of referenced objects as a separate design decision.
4. Handle `null` and `undefined` explicitly. Preserve valid `0`, `false`, and empty strings when choosing defaults.
5. Use ordinary functions, closures, classes, or modules according to lifecycle and state ownership. Do not add classes solely to hold stateless functions.
6. Match the existing module system. Use `import type` for erased dependencies and the import extensions required by the actual execution path.
7. Treat external JSON, environment variables, storage, and user input as untrusted runtime values. Validate them before promising a domain type.
8. Keep parsing and domain validation distinct: a syntactically valid number, date, or JSON object may still violate the contract.

Read [runtime-boundaries.md](references/runtime-boundaries.md) when adding a parser, a type guard, an API client, or configuration loading.

## Apply language decision rules

| Situation | Action |
| --- | --- |
| Default only absent values | Use `??` or an explicit nullish check; use `||` only when all falsy values should trigger a fallback. |
| Optional property chain | Guard each nullable boundary; do not use `?.` to bypass an undeclared property or swallow a required invariant. |
| Detached method or callback | Check how `this` is supplied; use a closure, explicit receiver, or binding when necessary. |
| Constant collection or object | Separate a constant binding, a readonly type, and runtime freezing; document required depth and aliasing. |
| Integer arithmetic | Establish safe-integer limits, division rounding, and whether `bigint` is required; avoid implicit number/bigint mixing. |
| String indexing | Decide whether the unit is UTF-16 code units, Unicode code points, or grapheme clusters. |
| Array sorting or copying | Supply a numeric comparator when needed; choose mutating or copy-producing operations deliberately. |
| Enum, parameter property, or decorator | Check the transform/runtime path before using syntax that needs generated JavaScript. |
| Generic assertion over external data | Replace the assertion with validation; a type argument cannot verify a payload. |
| Compiler library update | Check runtime availability separately; adding `lib` declarations does not install a polyfill. |

## Protect important invariants

- Prefer `unknown` over `any` at untrusted boundaries; narrow through real checks.
- Use an assertion only when an invariant is established elsewhere and cannot be expressed directly. Explain that invariant next to the assertion.
- Do not use a non-null assertion to hide a missing-value case in an API contract.
- Distinguish TypeScript `private` from JavaScript `#private` when runtime encapsulation matters.
- Treat `readonly`, `as const`, `satisfies`, and utility types as static tools; they do not sanitize data or enforce runtime immutability.
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
