# Runtime compatibility decisions

## Establish three independent capabilities

Check what the compiler accepts, what the build or runner transforms, and what the target runtime implements. A declaration in `lib` only describes an API. Type stripping only removes supported syntax. Neither supplies arbitrary runtime APIs.

| Execution path | Inspect | Verify |
| --- | --- | --- |
| Compiled JavaScript | tsconfig emit, package module mode, output directory, source import specifiers | Execute the emitted entry point and relevant import boundary. |
| Bundled application | Bundler configuration, platform target, transpiler, alias resolution, polyfills | Build for the actual deployment target and exercise the affected feature. |
| TypeScript runner | Runner version, project configuration support, transform limitations | Run through the repository's existing runner command. |
| Native Node stripping | Exact Node version, supported syntax, module mode, explicit import extensions | Execute the `.ts` entry point and type-check separately. |

## Native Node stripping

- Use erasable annotations, interfaces, type aliases, and type-only imports where the installed Node version supports them.
- Do not assume an enum works because it is declared `const`. Strip-only mode rejects enum syntax that requires transformation.
- Check parameter properties, runtime namespaces, import aliases, and decorators before choosing native execution.
- Do not expect Node's type stripping to read `tsconfig.json`, implement path aliases, downlevel JavaScript, or report type errors.
- Use `import type` for erased imports. Match extension and ESM/CommonJS rules to the running program.
- Run the project's type checker separately. Consider `erasableSyntaxOnly` when supported by the installed compiler and relevant to the project.

See the [official Node TypeScript documentation](https://nodejs.org/api/typescript.html) for the behavior of the installed release. Recheck it when changing Node versions.

## Module changes

1. Determine whether the source file is ESM or CommonJS from its extension, package context, and build configuration.
2. Follow how the specifier is resolved at build time and runtime. Avoid changing `moduleResolution` merely to suppress an import error.
3. Separate type-only dependencies from value dependencies. Check cycles if new value imports cross a module boundary.
4. Preserve existing public export paths unless the requested change includes an API migration.
5. For an alias or extension change, validate both type checking and actual module loading.

Consult the [TypeScript module reference](https://www.typescriptlang.org/docs/handbook/modules/reference.html) when the project's combination is unfamiliar.

## Decorators and newer features

Distinguish standard decorator semantics from legacy `experimentalDecorators` semantics. Confirm framework expectations and emitted metadata requirements before changing either. Do not copy a decorator that references undeclared classes, erases method signatures to `Function`, or measures only synchronous setup for an async method.

Use the installed compiler's release notes for syntax availability. Examples relevant to the source collection:

| Feature | Version context |
| --- | --- |
| `satisfies` | Introduced in [TypeScript 4.9](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html), not 5.0. |
| Const type parameters and standard decorator support | Introduced in [TypeScript 5.0](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-0.html). |
| `noUncheckedIndexedAccess` | Introduced in [TypeScript 4.1](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-1.html); not automatically enabled by `strict`. |
| Preserved closure narrowing after last assignment | Improved in [TypeScript 5.4](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-4.html), subject to control-flow conditions. |
| Inferred type predicates | Added in [TypeScript 5.5](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-5.html), subject to inference conditions. |

## Corrections to the upstream chapter

Treat the source's future-release forecasts, compiler benchmarks, and library speed comparisons as historical claims. Do not turn them into fixed migration instructions.

The source's 5.6 truthiness example is inaccurate: `if (value)` is valid for a variable of type `string`, because an empty string is falsy. The [5.6 diagnostics](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-6.html) identify syntactically predictable cases such as a regex or arrow function used directly as a condition.

Select compiler settings for the project rather than installing a dated universal tsconfig. Use the existing lockfile and package manager; perform upgrades only within the requested scope.
