# rust-wasm

A Rust WebAssembly skill for choosing browser bindings versus WASI targets,
designing validated data/error/async boundaries, packaging JS consumers, and
working with Preview 1 modules or Preview 2/WIT components. Includes least-privilege
host guidance and concrete browser/WASI smoke recipes with explicit prerequisites.
It does not promise universal runtime, threading, binary-size, or performance behavior.

## Install

From a checkout of this repository:

```sh
mkdir -p ~/.claude/skills
cp -r rust-wasm ~/.claude/skills/
```

Copy the whole directory; its references and attribution travel with the skill.
No plugin marketplace manifest or plugin installation command is assumed.

## Example prompts

- “Use rust-wasm to expose this RGBA transform safely to JavaScript; reject bad
  dimensions before mutation and explain typed-array ownership.”
- “Use rust-wasm to diagnose why the package builds but fails to initialize in
  our browser deployment.”
- “Choose wasm32-wasip1 or wasm32-wasip2 for this host and specify the artifact,
  required imports, capabilities, and runtime smoke test.”
- “Review this WIT plugin boundary and its cancellation/resource ownership policy.”

## Contents

| File | Scope |
|---|---|
| [SKILL.md](SKILL.md) | Quick routing, workflow, review pitfalls, completion criteria, optional skill handoffs |
| [Browser boundaries](references/browser-boundaries.md) | wasm-pack modes, JS/DOM/async bindings, ownership, validated host-executable RGBA example |
| [WASI and components](references/wasi-components.md) | Preview distinctions, WIT design, native component build workflow, host capabilities |
| [Testing and deployment](references/testing-deployment.md) | Complete browser package and WASI command smoke recipes, negative cases, troubleshooting |
| [Sources](references/sources.md) | Pinned upstream attribution, first-party references, specific corrections |

## Runnable checks

The dependency-free Rust fence validates a real data boundary on the native host.
From the repository root, run:

```sh
rustdoc --test --edition=2024 rust-wasm/references/browser-boundaries.md
```

After manual installation, the identical standalone check is:

```sh
rustdoc --test --edition=2024 ~/.claude/skills/rust-wasm/references/browser-boundaries.md
```

Edition 2024 needs Rust 1.85+; select the actual project's MSRV separately and
account for dependency/tool requirements. The [target smoke recipes](references/testing-deployment.md)
name each scratch file, dependency, command, prerequisite, expected result, and
expected failure. The browser recipe needs target libraries, wasm-pack, a browser,
and an HTTP server; the WASI recipe needs both WASI targets, Wasmtime, and wasm-tools.
External-dependency/browser and argument-driven WASI source files are explicitly
labeled and fenced as text, not disguised as host-executable doctests.

These commands document checks to run, not claimed results. Host assertions,
target compilation, artifact inspection, browser execution, and WASI execution
are separate evidence. This bundle does not claim browser/WASI runtime verification.

## Consolidation and attribution

Adapted from StructWeave's [Rust chapter 16](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/16-webassembly.md)
at revision `49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168`; see the
[upstream MIT notice](LICENSE.upstream) and [source/correction ledger](references/sources.md).

Browser interop and WASI share one entry point but separate references so their
incompatible loading, interfaces, and permission assumptions remain visible.
Unsafe pointer examples, placeholder component services, insecure password-hash
examples, broad performance rankings, and speculative runtime support claims
were replaced with validation, explicit host contracts, and first-party guidance.
Image processing retains a meaningful invariant-focused example; vendor-specific
edge deployments route through their actual SDK/world/host contract rather than
an unmaintained provider matrix. Profiling belongs to optional **rust-performance**,
raw-memory proofs to **rust-unsafe-ffi**, and test workflow to standalone **rust-tdd**;
none is required to read or install this bundle.
