---
name: rust-wasm
description: >
  Use when compiling Rust to WebAssembly, integrating wasm-bindgen or web-sys
  with browser JavaScript and the DOM, packaging with wasm-pack, choosing
  wasm32-unknown-unknown versus wasm32-wasip1 or wasm32-wasip2, designing WIT
  component interfaces, or debugging Wasm loading, capabilities, and target tests.
---

# Rust WebAssembly

Choose the host and boundary before choosing the target. Browser bindings,
WASI core modules, and WASI components have different imports, initialization,
permissions, and test runners. A successful native test does not prove any of them.

## Quick reference: route by deliverable

| Deliverable or symptom | Decision | Reference |
|---|---|---|
| Browser JS or DOM integration | `wasm32-unknown-unknown` + `wasm-bindgen`; DOM via `web-sys` | [Browser boundaries](references/browser-boundaries.md) |
| Direct browser ES module | `wasm-pack build --target web`; await generated initialization | [Browser smoke](references/testing-deployment.md#browser-package-smoke) |
| Bundler or Node package | Select `bundler` or `nodejs` output for the actual loader | [Browser boundaries](references/browser-boundaries.md#packaging-is-not-target-selection) |
| Existing Preview 1 host | `wasm32-wasip1`, core module importing Preview 1 APIs | [WASI and components](references/wasi-components.md) |
| WASI 0.2 / Preview 2 host | `wasm32-wasip2`, component-aware host and matching interfaces | [WASI and components](references/wasi-components.md) |
| Typed plugin or language boundary | WIT world + generated bindings + component linker | [WIT design](references/wasi-components.md#wit-is-a-contract-not-an-implementation) |
| Wrong numbers, corrupt bytes, rejected promises | Check coercion, sizes, ownership, errors, cancellation | [Browser boundaries](references/browser-boundaries.md#boundary-contract) |
| Unknown import / unsupported instruction / no output | Inspect artifact, target, imports, feature set, runtime | [Testing and deployment](references/testing-deployment.md) |

## Workflow

### 1. Identify the execution contract

Record:

- Host: browser main thread, worker, Node, embedded runtime, or deployed WASI host.
- Artifact: JS package plus core module, WASI command, or custom component exports.
- Inputs/outputs: encoding, numeric range, byte limits, ownership, error schema.
- Required capabilities: DOM, fetch, files, environment, clocks, network, threads.
- Rust toolchain/edition/MSRV, dependency lock, runtime version, enabled Wasm features.

Choose the project's edition and MSRV deliberately. Edition 2024 requires Rust
1.85 or newer; individual dependencies or tools can require a newer compiler.
Do not infer browser availability from `target_arch = "wasm32"`: WASI shares it.
The rustc target guides distinguish [unknown](https://doc.rust-lang.org/rustc/platform-support/wasm32-unknown-unknown.html),
[Preview 1](https://doc.rust-lang.org/rustc/platform-support/wasm32-wasip1.html), and
[Preview 2](https://doc.rust-lang.org/rustc/platform-support/wasm32-wasip2.html).

### 2. Keep domain code independent of the host

Prefer ordinary Rust functions for validation and transformation. Put JS objects,
DOM access, Promise conversion, WASI handles, and WIT-generated types at the edge.
Keep native tests useful, but test adapters in their actual host too.

Start with safe copied bytes and owned values. Batch meaningful operations when
it improves the API; do not design a raw-pointer protocol to avoid an unmeasured
copy. Linear-memory bounds checks do not establish Rust initialization, aliasing,
or ownership invariants.

### 3. Implement an explicit boundary

- Validate before integer conversion: JS-to-integer bindings can truncate/wrap.
  Use `f64` validation or inspect a `JsValue` when invalid inputs must be rejected.
- Bound bytes, collection length, and dimensions; use checked arithmetic before
  allocation or indexing. Reject malformed input without partial mutation.
- Specify `Number` versus `BigInt`; do not pass arbitrary `u64` identifiers through
  a JS `Number`. Treat timestamps, binary encoding, and missing fields explicitly.
- Use `Result` for expected errors. Sync binding errors can throw; async binding
  errors reject a Promise. A panic/trap is not a domain error protocol.
- For DOM text, use text-content APIs rather than interpolated HTML. Check missing
  `window`, document, and elements instead of assuming a browser main thread.
- Own callbacks for as long as JS can call them; unregister before dropping.
  Do not routinely leak closures with `forget`.

The [host-executable boundary example](references/browser-boundaries.md#host-executable-boundary-example)
checks JS-style numbers, RGBA shape, and failure-before-mutation.

### 4. Respect async and host limits

An exported async binding returns a Promise; it does not create a worker thread.
Use the project's supported Promise/Future bridge, preserve rejection details,
and handle HTTP status separately from fetch transport failure. Define who aborts
in-flight work; dropping a Rust future does not automatically cancel host work.
Avoid holding mutable state borrows across JS calls or awaits that can reenter it.

CPU-bound work on the main thread still blocks UI responsiveness. Use a worker
when appropriate; workers do not expose the document DOM. Shared-memory threads
require compatible compiler/std configuration, runtime support, worker setup,
and browser isolation headers. `std::thread::spawn` is not a portable Wasm API.
See the [binding threading caveats](https://wasm-bindgen.github.io/wasm-bindgen/examples/raytrace.html).

### 5. Package for the actual consumer

`wasm-pack --target web|bundler|nodejs` chooses JS output, not a WASI target.
Publish/deploy the generated glue and its matching Wasm together. Do not feed
wasm-bindgen output to an empty-import runtime and expect JS imports to resolve.

`wasm32-wasip2` already emits a component; do not wrap it again as if it were a
Preview 1 core module. Use a component-aware runtime and the expected WIT world.
An HTTP component is not interchangeable with a CLI command or a JS package.

### 6. Verify in layers and report evidence

Follow [the concrete smoke recipes](references/testing-deployment.md):

1. Native assertions validate host-independent invariants.
2. Target compilation checks dependency and platform compatibility.
3. Artifact inspection checks module/component kind and imports/exports.
4. Actual browser or WASI execution checks glue, permissions, and behavior.
5. Deployment smoke checks headers, paths, initialization, and rejected access.

Record exact commands, tool versions, results, and unexercised hosts. Installing a
runner or producing a `.wasm` is not runtime verification. Only run checks when
authorized in the current task.

## Pitfalls to reject in review

| Tempting claim or pattern | Correct action |
|---|---|
| “Wasm is always smaller/faster/near-native” | Measure load, initialization, copies, boundary calls, and the actual workload |
| “Wasm has no GC” | Rust does not require tracing GC; host JS and WasmGC are separate concerns |
| “All `std` works on a Wasm target” | Check the target; on unknown, files fail, printing is ineffective, and spawning threads panics |
| “Any `Vec<T>` maps to JS Array” | Check supported binding types; numeric buffers and JS arrays differ |
| “A wasm pointer is safe because memory is sandboxed” | Prove initialized range, allocation ownership, lifetime, aliasing, and reclamation |
| “A component automatically has network/filesystem access” | Inspect imports and grant only required host capabilities |
| “Preview 2 automatically makes arbitrary Rust async/threading work” | Check selected APIs, executor, ABI version, and host support |
| “WASI imports are resolved by the browser” | Supply an explicit implementation or choose browser JS bindings |

## Completion criteria

- Target, artifact kind, host, toolchain, and interface versions are named.
- Input validation, error behavior, resource lifetime, and cancellation are defined.
- Generated JS/Wasm are paired; WIT imports match supplied host implementations.
- Least-privilege grants and resource bounds are documented and tested when feasible.
- Native checks and target/runtime checks are distinguished; missing tools are disclosed.
- No raw uninitialized allocation or fake component implementation is left behind.

## Optional installed-skill handoffs

- **rust-idiomatic**: shared Rust error and ownership design.
- **rust-api-design**: public API evolution and type boundaries.
- **rust-concurrency**: cancellation, backpressure, synchronization, worker coordination.
- **rust-unsafe-ffi**: unavoidable raw-memory ABI proof obligations.
- **rust-tdd**: boundary regression tests and observable red-green-refactor.
- **rust-performance**: measured allocation, binary-size, or throughput changes.

[Sources and adaptation decisions](references/sources.md) distinguish upstream
material from first-party corrections. Runtime recipes are instructions, not
claims of executed browser or WASI verification.
