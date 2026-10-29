# Tooling Decisions

## Inspect before choosing

Read the owning package manifest and lockfile; determine whether the code is a published library, browser application, Node service, command-line tool, or a mixed workspace. Check inherited compiler configuration and the scripts run in CI. Do not infer a tool's installed version from a tutorial.

| Concern | Inspect | Decide |
| --- | --- | --- |
| Type checking | `typecheck`, compiler binary, project references, include/exclude | Check the complete intended project, including tests when appropriate |
| Runtime execution | Start/dev scripts, runtime version, loader or bundler | Keep the supported execution path; validate syntax restrictions |
| Node ESM/CJS | Package `type`, file extensions, exports, Node-aware module options | Align emitted imports and runtime lookup |
| Bundled code | Bundler config, aliases, environment, module resolution | Let the bundler own transformations and resolution |
| Library output | Entry points, exports, declarations, supported consumers | Verify declaration output and a representative consumer import |
| Static quality | ESLint/Biome/Prettier config and scripts | Preserve one coherent project convention |
| Tests | Runner version, environments, setup, discovery patterns | Run the test in the same environment as the affected code |

## Keep responsibilities explicit

Use `tsc` or the project's configured compiler for type checking. Treat transpilers, direct runtime stripping, and bundlers as execution/build mechanisms unless their documented configuration includes a separate checker. For Node type stripping, verify supported syntax and runtime version; do not assume `tsconfig` aliases, JSX, or constructs requiring JavaScript generation work.

For command selection, prefer existing scripts such as `npm run typecheck` and the repository's one-shot test script. Substitute the actual package manager and script names found in the project. Use watch mode during interactive development, and a terminating one-shot command in CI. When no script exists, locate the installed executable and check its documented flags before introducing a new script.

Before adding a compiler option, explain which constraint it enforces. `strict` is a useful baseline; indexed-access and optional-property settings may require additional handling. Avoid suppressing a failing dependency or source contract simply to report success.

## Resolve common toolchain failures

| Symptom | Investigate |
| --- | --- |
| Types pass but Node cannot import an alias | `paths` does not rewrite output; inspect host alias support and package imports |
| API compiles but is undefined at runtime | Check runtime availability and polyfills separately from `lib` |
| Tests pass while source has type errors | Confirm a compiler/type-test command actually ran |
| ESM/CJS import error | Inspect the containing package, emitted extension, loader, and dependency export conditions |
| A test is silently absent | Inspect discovery globs, workspace/project selection, file suffixes, and skip filters |
| Test works locally but fails in CI | Compare lockfile install, runtime, environment variables, timezone, locale, filesystem case, and one-shot command |
| Stack points to the wrong line | Rebuild stale output and verify source maps and loader alignment |

## Use reproducible CI

Install from the committed lockfile with the package manager's frozen/reproducible mode. Match the supported runtime and run the same type, lint, test, and build scripts used locally. Scope caches to the runtime and lockfile. Preserve project gates and avoid blindly copying an upstream action version, tool schema, or dependency range.

Inspect script bodies before executing a command whose name suggests a check: some scripts also rewrite files, generate assets, publish packages, or deploy. Confirm the actual effect fits the task.

## Official references

- [TypeScript module reference, including paths and emit](https://www.typescriptlang.org/docs/handbook/modules/reference.html#paths-does-not-affect-emit)
- [TypeScript compiler configuration](https://www.typescriptlang.org/tsconfig/)
- [Node TypeScript execution](https://nodejs.org/api/typescript.html)
- [Vitest type tests](https://vitest.dev/guide/testing-types.html)
