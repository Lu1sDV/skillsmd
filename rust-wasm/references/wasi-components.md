# WASI, components, and host capabilities

## Choose the artifact the host actually accepts

| Rust target | Artifact and imports | Appropriate consumer |
|---|---|---|
| `wasm32-unknown-unknown` | Core module; application-specific imports if added by bindings | JS bindings or a custom embedding supplying those imports |
| `wasm32-wasip1` | Core module; OS operations import `wasi_snapshot_preview1` | A Preview 1 host, or an explicit compatible adaptation path |
| `wasm32-wasip2` | WebAssembly component using WASI Preview 2 interfaces | A component-aware host implementing the required interfaces |

The [Preview 1 rustc guide](https://doc.rust-lang.org/rustc/platform-support/wasm32-wasip1.html)
and [Preview 2 rustc guide](https://doc.rust-lang.org/rustc/platform-support/wasm32-wasip2.html)
define these outputs. Preview 1 is the compatibility choice, not the name for all
WASI; use the current target name rather than historical `wasm32-wasi` commands.
Pin the host and WASI interface versions instead of saying “WASI supported.”

For ordinary Rust-only use, rustup-distributed WASI targets include the needed
standard-library support. Building rustc itself or integrating C/C++ can require
wasi-sdk/linker configuration; do not impose that requirement on every user.
Choose a binary crate for a command and `cdylib` for a reactor/library component.
[The Bytecode Alliance Rust tutorial](https://component-model.bytecodealliance.org/language-support/building-a-simple-component/rust.html)
uses native Cargo with `wasm32-wasip2`; it no longer recommends cargo-component as
the default new-project path.

### Standard library is not a portable OS

On `wasm32-unknown-unknown`, `println!` is ineffective, filesystem APIs fail,
and `std::thread::spawn` panics. On Preview 1, file APIs route through WASI but
are constrained by host grants; spawning threads/processes is unsupported by the
ordinary target. Preview 2's richer interfaces do not imply arbitrary process
spawning, threads, POSIX behavior, or host permission. Check the exact library
API, dependency feature, runtime implementation, and grant.

Use `target_os = "wasi"` with `target_env = "p1"` or `"p2"` to separate WASI
adapters on supported compilers; the `p1` environment discriminator requires
Rust 1.80+. `target_arch = "wasm32"` alone includes browser and nonbrowser hosts.
Even the unknown target does not prove that JavaScript or a DOM exists.

## WIT is a contract, not an implementation

[WIT](https://component-model.bytecodealliance.org/design/wit.html) describes a
package, interfaces, and a world of imports/exports. Rich types such as records,
variants, lists, options, and results are lifted/lowered by the Component Model's
canonical ABI. This is not Rust struct layout or a C ABI, and it does not promise
zero-copy transmission or application-level validation.

For example, this is a complete interface contract, **not a built component**:

```wit
package example:images@0.1.0;

interface transform {
    enum image-error {
        invalid-dimensions,
        invalid-length,
        too-large,
    }

    grayscale: func(width: u32, height: u32, rgba: list<u8>)
        -> result<list<u8>, image-error>;
}

world image-worker {
    export transform;
}
```

The integer fields are typed but still need the dimension/byte-limit checks in
[the host boundary example](browser-boundaries.md#host-executable-boundary-example).
The wire type says nothing about the maximum accepted list length or the amount
of memory required to lift it. Enforce memory limits in the host as well as
semantic validation in the guest. Changing names, types, or interface versions
can break linking; review the world and consumer together.

### Implementing a custom world

1. Put the WIT in the project and pin its package dependencies. Decide exported
   functions, imported authority, domain error variants, and resource lifetime.
2. Select a compatible `wit-bindgen` dependency and generate bindings for that
   exact world/path. Consult that version's generated trait/module names; an
   exported named interface is not necessarily a top-level `Guest` trait.
3. Implement every generated guest method with real domain code. Use the generated
   export macro for the implementation. The interface declaration alone implements
   nothing; a dummy returned user or empty list is not a working service.
4. Build with `cargo build --target wasm32-wasip2 --release` on the supported
   toolchain. This produces a component directly. Do **not** run `wasm-tools
   component new` on that output as a mandatory second step.
5. Inspect with `wasm-tools component wit` and `wasm-tools validate`. Supply all
   imported interfaces through the component linker or component composition.
6. Exercise custom exports with a host generated from the same WIT, or supported
   runtime CLI invocation. Test both success and returned domain errors; traps
   indicate a different failure class.

For an existing Preview 1 core module, conversion can instead require a compatible
Preview 1 adapter and componentization tooling. Determine command versus reactor
ABI and adapter version before wrapping. An arbitrary core module with JS imports
cannot be made into a valid WASI component merely by renaming or wrapping it.

### Commands, HTTP, and plugins are different worlds

- A command exports `wasi:cli/run` and is run to completion by a command host.
- An HTTP component targets the host's expected HTTP world, commonly
  `wasi:http/proxy`; a `main` printing text is not an HTTP handler.
- A custom plugin exports its own WIT interfaces; the embedding must invoke them
  and supply their imports. Wasmtime's core `Module` API is not its component API.
- Browser use of components requires suitable component-to-JS tooling and
  implementations of imports; browser `WebAssembly.instantiate` is not by itself
  a WASI component loader.

The [Wasmtime CLI guide](https://docs.wasmtime.dev/cli-options.html) distinguishes
command execution, custom export invocation, and `serve`. Its `serve` command is
for local development/testing, not a substitute for production limits, TLS,
authentication, and a hardened host/proxy.

### Async versions are not interchangeable

WASI Preview 2 is WASI 0.2. Do not describe its interfaces as automatically
providing the later native component async ABI. The WIT guide identifies
`future`/`stream` additions with WASI 0.3. A host offering 0.2 interfaces is not
therefore a 0.3 host; choose the interface set, bindings, compiler, and runtime
as a tested combination. Rust async adapters and pollable resources are also
not evidence of shared-memory thread support.

## Capability and resource review

WASI filesystem access is capability-based: the host explicitly grants accessible
directories, rather than exposing its whole filesystem. See
[Wasmtime security](https://docs.wasmtime.dev/security.html). Keep the runtime
patched; sandboxing is a security boundary, not a claim that host code has no bugs.

For each deployment, document:

| Authority / resource | Required policy and negative check |
|---|---|
| Files | Grant a narrow directory; deny traversal/outside access; distinguish host and guest paths; prefer read-only host configuration when sufficient |
| Environment / arguments | Pass only needed values; do not inherit secrets or entire host environment by default |
| Network / HTTP | Limit destinations and credentials at the host; an imported HTTP client can be an exfiltration capability |
| CPU | Set a runtime execution budget/deadline; a guest can loop without touching a forbidden syscall |
| Linear memory / tables | Bound allocations and instances; reject oversized inputs before unbounded host copies |
| Host calls / output | Bound request sizes, response sizes, handles, output, and call duration |
| Resource handles | Define ownership, drop/close behavior, cancellation, and cleanup after failure |

Fuel/epoch interruption and memory limits are host configuration, not protections
a guest can grant itself. Host calls need separate deadlines where applicable.
Test denied capabilities alongside permitted use; a passing “hello world” does
not exercise filesystem/network policy. The [target smoke recipe](testing-deployment.md#wasi-command-smoke)
includes an explicit no-grant failure and narrow-directory success.
