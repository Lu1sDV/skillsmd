---
name: typescript-interview-review
description: >
  Use when explaining TypeScript interview traps, predicting compile-time and runtime
  behavior, diagnosing small language examples, or coaching technical interviews about type
  versus interface, any/unknown/never, narrowing, equality, nullish operators, generics,
  enums, this binding, satisfies, infer, readonly, augmentation, variance, or overloads.
  Route production implementation and algorithm solving to the relevant specialist skill.
---

# TypeScript Interview Review

Explain the rule, demonstrate its boundary, and separate compiler behavior from JavaScript execution.

## Identify the requested mode

- For a direct question, answer it directly with a minimal example and the decisive caveat.
- For code-output prediction, analyze the supplied code before rewriting it.
- For a mock interview, ask one focused question at a time and wait for the user's reasoning before giving the solution.
- For answer evaluation, assess the supplied answer against the actual contract; distinguish a false claim from a missing qualification.
- For a requested quiz, follow the host's quiz format if available; do not turn ordinary debugging into a quiz.

Route substantial implementation to `typescript-language-runtime`, generic API design to `typescript-type-modeling`, algorithm solutions to `typescript-algorithm-patterns`, and compiler/test setup to `typescript-tooling-tdd`.

## Establish the conditions

1. Identify the TypeScript version and relevant compiler flags when known. State assumptions when they are not supplied.
2. Identify the runtime, module mode, and execution path if the question concerns emitted code, imports, enums, decorators, or `this`.
3. Distinguish isolated examples from a complete module. Supply missing declarations only when necessary to make the question meaningful.
4. Determine whether the example is intended to type-check, intentionally demonstrate an error, or execute JavaScript despite an error.
5. Avoid inferring a runtime result from a static annotation alone.

Read [diagnostic-cases.md](references/diagnostic-cases.md) to choose a useful example or counterexample. Read [verified-corrections.md](references/verified-corrections.md) when the source explanation conflicts with current compiler behavior.

## Analyze in three layers

1. **Static contract:** Identify the inferred or declared types, narrowing, assignability rule, and expected diagnostic. Name the relevant flag if it changes the result.
2. **Execution representation:** Identify what is erased, emitted, or rejected by the runner. State whether the compiler's emit settings allow JavaScript output after diagnostics.
3. **Runtime behavior:** Evaluate JavaScript values, identity, coercion, mutation, binding, and errors independently of static intent.

For a claim that depends on compiler inference or has competing interpretations, make the smallest reproducible example and check it with an available matching compiler. For pure language explanations, use a concise example without creating a project or installing tools unnecessarily.

## Explain with a counterexample

1. State the correct result or rule first.
2. Show the minimum code necessary to establish it.
3. Explain why the tempting interpretation fails.
4. Add one changed input, annotation, or call site that changes the result.
5. Offer a practical correction when the example represents a real bug.
6. Name unresolved version or environment assumptions instead of presenting a guessed diagnostic as observed output.

## Apply the core distinctions

| Topic | Preserve this distinction |
| --- | --- |
| `type` and `interface` | Structural overlap versus declaration merging, unions, mapped types, and conflicting intersections. |
| `any`, `unknown`, `never` | Opting out, requiring narrowing, and representing impossible values. |
| Equality and defaults | JavaScript coercion/reference identity versus static compatibility; nullish versus falsy. |
| Generics | Compile-time relationships and inference versus runtime construction or validation. |
| Enums and literal unions | Generated/inlined runtime representation versus erased type alternatives. |
| `this` | Call-site binding versus lexical capture; static receiver annotations do not bind a function. |
| `satisfies` and assertions | Checking compatibility versus claiming a type; neither validates external runtime data. |
| `infer` | Capturing a type within an `extends` pattern versus ordinary value inference. |
| Readonly and immutability | Static view, shallow runtime freeze, and mutation through aliases. |
| Augmentation | Extending declarations versus implementing runtime behavior. |
| Variance | Safe callback substitution direction versus method bivariance and mutable array hazards. |
| Excess properties and keys | Fresh-literal checking versus structural compatibility and possible extra runtime keys. |

## Coach without rewarding slogans

- Judge the reasoning and example, not whether the answer repeats the source's wording.
- Accept a qualified correct answer even when a tutorial labels a simpler answer as categorically wrong.
- In a mock interview, increase difficulty by changing one condition after the user answers.
- For a mistaken answer, show the smallest counterexample and let the user revise their explanation.
- Avoid blanket claims such as all callbacks lose narrowing, filters require explicit predicates, or interfaces always outperform aliases.
- Keep algorithm interview practice in `typescript-algorithm-patterns`; use this skill for language and type-system behavior.

## Return the appropriate result

For an explanation, provide the result, the decisive rule, a short example or counterexample, and the practical implication. Include configuration only when it matters.

For a diagnostic, distinguish observed compiler/runtime output from predictions and report the smallest verified correction.

For an interview review, provide a concise assessment, the missing or incorrect point, a stronger answer, and one targeted follow-up if coaching is requested.

## Source basis

Use [Interview trap questions, chapter 14](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/14-interview-trap-questions.md) for the topic inventory. Apply the bundled corrections to variance, narrowing, and runtime claims before using its examples.
