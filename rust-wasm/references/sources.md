# Sources and adaptation decisions

## Upstream attribution

Adapted from StructWeave Algorithms, Rust chapter 16,
[“Rust and WebAssembly”](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust/16-webassembly.md),
pinned to Rust-content revision `49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168`.
The upstream MIT notice is preserved in [LICENSE.upstream](../LICENSE.upstream).
This bundle is an original task-oriented synthesis, not a verbatim chapter copy.

Coverage retained: target/toolchain choice, JS and DOM integration, wasm-pack
packaging, async boundaries, WASI, Component Model/WIT, browser versus server
hosts, deployment, debugging/testing, workload selection, and boundary costs.
Image transformation supplies a real validated boundary example. Edge providers
and embedded plugin hosts are treated by their required interfaces/capabilities,
not a vendor support table that becomes stale independently of this skill.

## First-party references consulted

Documentation was consulted on 2026-10-11. These pages track their projects and
may change; reproduce behavior with a recorded compiler, dependency lockfile,
binding tools, and host version. Current wasm-pack book pages explicitly label
themselves unpublished; installed CLI help and a project's locked release govern
available flags. Recipes avoid depending on its newly documented experimental flags.

| Reference | Used for |
|---|---|
| [rustc: wasm32-unknown-unknown](https://doc.rust-lang.org/rustc/platform-support/wasm32-unknown-unknown.html) | Partial std behavior, host assumptions, changing instruction features, panic strategy |
| [rustc: wasm32-wasip1](https://doc.rust-lang.org/rustc/platform-support/wasm32-wasip1.html) | Preview 1 imports, target naming, compatibility, thread/process limits, sysroot versus wasi-sdk |
| [rustc: wasm32-wasip2](https://doc.rust-lang.org/rustc/platform-support/wasm32-wasip2.html) | Component output and component-aware host requirement |
| [wasm-pack build](https://wasm-bindgen.github.io/wasm-pack/book/commands/build.html) | Generated package, JS output modes, build profiles |
| [wasm-bindgen deployment](https://wasm-bindgen.github.io/wasm-bindgen/reference/deployment.html) | Loader distinctions, bundler requirements, Node CommonJS |
| [wasm-bindgen supported types](https://wasm-bindgen.github.io/wasm-bindgen/reference/types.html) | ABI-specific type mappings |
| [Numeric conversions](https://wasm-bindgen.github.io/wasm-bindgen/reference/types/numbers.html) | Truncation/wrapping/coercion and BigInt versus Number |
| [Numeric slices](https://wasm-bindgen.github.io/wasm-bindgen/reference/types/number-slices.html) | Typed arrays rather than arbitrary generic JS arrays |
| [DOM example](https://wasm-bindgen.github.io/wasm-bindgen/examples/dom.html) | Feature-gated web-sys and text-content methods |
| [Promises and futures](https://wasm-bindgen.github.io/wasm-bindgen/reference/js-promises-and-rust-futures.html) | Promise resolution/rejection, explicit JsFuture, version-sensitive direct-await APIs |
| [Uint8Array view API](https://docs.rs/js-sys/latest/js_sys/struct.Uint8Array.html#method.view) | Explicit view versus copying operations; unsafe memory boundary |
| [Threaded raytracing example](https://wasm-bindgen.github.io/wasm-bindgen/examples/raytrace.html) | Toolchain/runtime/worker/SharedArrayBuffer constraints, not universal thread support |
| [Browser test runner](https://wasm-bindgen.github.io/wasm-bindgen/wasm-bindgen-test/browsers.html) | Node versus browser selection, wasm-pack and WebDriver prerequisites |
| [Bytecode Alliance: Rust components](https://component-model.bytecodealliance.org/language-support/building-a-simple-component/rust.html) | Direct Cargo/wasip2 builds, generated bindings, exported Guest interfaces, WIT inspection |
| [Bytecode Alliance: WIT](https://component-model.bytecodealliance.org/design/wit.html) | Interfaces/worlds, results/resources, later-version future/stream distinctions |
| [Wasmtime CLI](https://docs.wasmtime.dev/cli-options.html) | Guest arguments, host flags, command versus custom-export versus HTTP invocation |
| [Wasmtime security](https://docs.wasmtime.dev/security.html) | Imports as authority and capability-scoped filesystem |

## Corrections made during adaptation

- **Output kinds:** `wasm32-wasip2` already emits a component. Removed the upstream
  mandatory second wrapping step and any implication that JS modules are components.
- **Edition/ABI:** crate kind depends on command versus library, not “Wasm requires
  a library.” Project MSRV is distinct from edition selection and tool MSRV.
- **WASI maturity and async:** use explicit Preview 1/0.2/component distinctions,
  not “Preview 2 means all async works” or speculative universal WASI 0.3 support.
- **Error integrity:** filesystem failures propagate; no `.ok()` hiding write
  failures, unconditional DOM unwrap, or success-shaped placeholder implementation.
- **Memory safety:** removed the leaked `Vec::with_capacity` pointer example; it
  did not establish initialized bytes, caller bounds, or reclamation. Sandbox
  bounds do not make unsafe Rust valid.
- **Input semantics:** numeric binding coercions need explicit validation; the RGBA
  example checks exact byte shape and dimensions before mutation. No wrapping
  Fibonacci or tiny-dimension blur is presented as a robust public API.
- **Security examples:** omitted the upstream SHA-256 password comparison. Fast
  unsalted hashing plus ordinary equality is not password storage/verification
  guidance. Use an appropriate vetted password-hashing design when actually needed.
- **Performance and GC:** removed language rankings, fixed-size claims, automatic
  Wasm-over-JS wins, and “Wasm has no GC.” Rust's allocation model, host JS GC,
  WasmGC, and end-to-end workload costs are separate questions.
- **Tooling/deployment:** retained web/bundler/Node distinctions without claiming
  every bundler, runtime, browser, or edge platform supports the same imports or
  threads. Optimizer/allocator changes require measurement, not blanket defaults.
- **Executable status:** one dependency-free native assertion example is separate
  from complete external-dependency browser and WASI command recipes. Native
  rustdoc cannot validate DOM access, host permissions, or component execution.
