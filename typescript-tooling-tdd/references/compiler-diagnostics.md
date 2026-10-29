# Compiler Diagnostics

Use this procedure for missing checks, resolution failures, slow checking, or editor/CLI disagreement. Investigate the affected project before changing compiler policy.

## Establish what actually runs

1. Resolve the owning package, installed checker/version, exact script, configuration, and working directory. Read script bodies before running them; preserve the original diagnostic and exit status.
2. Inspect inherited settings with the local compiler's `--showConfig -p <config>`. Use the framework's supported equivalent when it owns the program. Do not pass arbitrary flags through a wrapper without checking how it forwards arguments.
3. Obtain actual program files with `--listFilesOnly -p <config>` or reasons with `--explainFiles`. The former stops after discovery; neither substitutes for a successful type check. Compare intended production, test, and tooling files with the programs CI executes.
4. Follow project references. A solution config with `files: []` can have no program to measure; inspect its referenced projects or the established build-mode command. Plain `tsc -p` does not build referenced dependencies.
5. Use the established framework checker for component files, such as Vue, Svelte, or Astro sources. A plain TypeScript file list does not establish component/template coverage. Respect generated configuration ownership.

`exclude` does not prevent a file from entering through an import. Treat glob-only inventories as estimates; report coverage as unavailable if the owning checker cannot enumerate it.

## Route the symptom

| Symptom | Next evidence | Check after the change |
| --- | --- | --- |
| Green check misses known errors | Actual program files, referenced projects, framework checker | Intended files participate in the real gate |
| Editor disagrees with CLI | Compiler versions, selected/inferred project, generated configs, plugins | Same file under the intended compiler and project |
| Import cannot resolve | `--traceResolution` for the owning project; isolate the failing specifier in the output | Type resolution and the real runtime/bundler entry point |
| Slow CLI check | Comparable `--extendedDiagnostics` baseline | Same workload and cache state after one change |
| Editor alone is slow | Language-service project/log or trace and relevant plugins | Repeated editor operation under the same conditions |

For imports, inspect the containing package, export conditions, extensions, and selected declaration. Do not change resolution mode merely to make a diagnostic disappear. For editor mismatch, align the intended workspace compiler/project before rewriting types.

## Measure before simplifying types

1. Record compiler/runtime versions, checked project, original command, diagnostic count, and cache state. Keep cold builds and incremental rebuilds as separate workloads.
2. Collect `--extendedDiagnostics` without tracing. Separate program construction/resolution, checking, and emit; a wrapper or framework may also contribute time outside the compiler.
3. If checking dominates, collect a separate `--generateTrace <output-directory>` run with the installed compiler's supported flags. Ensure the relevant work actually executes; an up-to-date incremental build may skip it. Record any cache or build-mode change.
4. Inspect expensive files and type relationships, using an existing compatible trace analyzer or viewer. Counts of types/instantiations are leads, not proof of a culprit; avoid universal thresholds and automatic generic rewrites.
5. Change one supported cause, such as unintended program inputs or an expensive public type relationship. Preserve intended file coverage and accepted/rejected type-contract examples.
6. Rerun the original untraced measurement under comparable conditions and the affected correctness gates. Trace overhead is uneven: do not compare traced timing with an untraced baseline as a speedup claim.

Treat `skipLibCheck`, dependency upgrades, extra memory, and project references as explicit tradeoffs supported by the diagnosis. Do not suppress a failing contract or exclude intended source files to report a faster green check.

## Completion evidence

Report the owning program and checker, coverage established or missing, the measured cause, the focused change, and comparable before/after results. Keep traces temporary and inspect their contents before sharing: they can contain source paths and code. If a CLI check does not reproduce an editor problem, state that limitation.

## Primary references

- [Compiler CLI options](https://www.typescriptlang.org/docs/handbook/compiler-options.html)
- [Why files enter a program](https://www.typescriptlang.org/tsconfig/explainFiles.html)
- [Project references and build mode](https://www.typescriptlang.org/docs/handbook/project-references.html)
- [Resolution tracing](https://www.typescriptlang.org/tsconfig/traceResolution.html)
- [Compiler performance investigation](https://github.com/microsoft/TypeScript/wiki/Performance)
- [Trace interpretation and overhead](https://github.com/microsoft/TypeScript/wiki/Performance-Tracing)
