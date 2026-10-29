# Corrections and qualifications for the source question bank

Use the repository's questions as topic prompts, not an authoritative answer key. The pinned chapter contains several incorrect or overly broad explanations.

## Function variance

The source's contravariance example marks the safe direction as an error. Under strict checking of function-valued parameters, a handler accepting any Animal can be used for Dogs. A handler requiring Dog-only members cannot be used wherever arbitrary Animals will be passed.

Method and constructor declarations have an exception to the stricter parameter rule. Distinguish them from function-valued properties before predicting a diagnostic. See [TypeScript 2.6 strict function types](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-6.html).

## Closure and filter narrowing

Do not repeat the source's blanket statements that callbacks lose narrowing or filters without an explicit predicate retain the whole union.

- [TypeScript 5.4](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-4.html) preserves narrowing in suitable closures after the last assignment. Assignment inside another closure can invalidate this reasoning.
- [TypeScript 5.5](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-5.html) infers suitable type predicates, including ordinary `typeof` and non-nullish checks in filters.
- Truthiness can still be too broad: filtering numbers with `!!x` removes zero as well as absent values.
- Explicit predicates are claims whose implementation must be correct; the compiler does not prove that the predicate tests every promised property.

Use the installed compiler to confirm exact diagnostics when those versions or flags are central to the question.

## Satisfies and inference

`satisfies` was introduced in [TypeScript 4.9](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html). It checks an expression against a target type while retaining useful expression-specific information. It is not runtime validation, runtime freezing, or a guarantee that contextual typing has no influence.

Differentiate const scalar literal inference from mutable object-property widening. An annotation, assertion, const assertion, and `satisfies` solve different problems; demonstrate the exact property the user asks about.

## Enums and runtime objects

Const-enum emit depends on configuration and compilation strategy. Do not assume inlining when the runner only strips types. Node strip-only mode rejects enum syntax, including const enums; see [Node's TypeScript support](https://nodejs.org/api/typescript.html).

An `as const` object remains an ordinary JavaScript object at runtime. The assertion emits no additional transformation, but the object itself is still present. It does not freeze the object.

See the [TypeScript enum handbook](https://www.typescriptlang.org/docs/handbook/enums.html) for const-enum publication and configuration caveats.

## Runtime versus static examples

Several upstream examples illustrate JavaScript values using TypeScript snippets that also contain diagnostics, such as accessing undeclared properties through optional chaining. Optional chaining does not make an undeclared property valid in the type system.

Similarly, a variable initialized to a constant value may already be narrowed before a comparison. Diagnose the actual expression rather than assuming a declared union prevents all comparison warnings.

TypeScript's `this` parameter is erased and does not bind a receiver. Class methods execute with strict-mode semantics; a detached method that accesses `this` can throw. The receiver supplied by timers or event systems depends on that runtime's API.

## Immutability, keys, and augmentation

- `Readonly<T>` and `Object.freeze` are shallow in ordinary use. A recursive mapped type does not implement runtime deep freezing.
- `Object.keys` excludes symbol keys and may expose keys not represented by a narrowed structural type. A cast to `(keyof T)[]` needs a valid closed-shape assumption.
- Module augmentation changes declarations. It does not implement missing methods or properties.
- Avoid absolute performance claims about interfaces versus aliases. Complex intersections can be costly, but the actual program and relationship matter.

## Source context

These corrections apply to [chapter 14 at the reviewed commit](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/14-interview-trap-questions.md), with related version/runtime corrections from [chapter 07](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/07-modern-typescript.md). Reproduce version-sensitive behavior before applying these explanations to a different toolchain.
