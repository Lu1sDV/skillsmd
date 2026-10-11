# Testing, deployment, and debugging

These are reproducible **recipes**, not records of execution. A host rustdoc test
checks the pure algorithm only. Browser and WASI recipes require the named tools
and an actual target host; no runtime verification is implied by this bundle.
Use fresh scratch directories for the examples, never overwrite an existing app.

## Host boundary check

From the repository checkout:

```sh
rustdoc --test --edition=2024 rust-wasm/references/browser-boundaries.md
```

Test the application's pure Rust library natively as well. Then compile the
selected target: dependencies can include unsupported native syscalls even when
all your own code appears portable. A target build proves neither initialization
nor host behavior.

## Browser package smoke

Prerequisites: Rust/Cargo with an edition-2024-capable toolchain (1.85+ and any
higher dependency MSRV), rustup or equivalent installed target libraries,
wasm-pack, a current browser, and a local static HTTP server. This example uses
Python 3 only to serve files. Install tools through trusted project-approved
channels, record versions, and retain the resolved Cargo.lock for reproduction.

Create a new library named `wasm_boundary_smoke`:

```sh
rustup target add wasm32-unknown-unknown
cargo new --lib --edition 2024 wasm_boundary_smoke
```

Inside that new directory, replace its `Cargo.toml` with:

```toml
[package]
name = "wasm_boundary_smoke"
version = "0.1.0"
edition = "2024"

[lib]
crate-type = ["cdylib", "rlib"]

[dependencies]
wasm-bindgen = "0.2"
web-sys = { version = "0.3", features = ["Window", "Document", "Element", "Node"] }
```

`src/lib.rs` below is a complete **external-dependency, browser-target** file,
not a host rustdoc example. The `f64` parameter preserves invalid numeric values
for validation; strict JS-type checking would instead take a `JsValue`.

```text
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn checked_count(value: f64) -> Result<u32, JsValue> {
    if !value.is_finite()
        || !(1.0..=4096.0).contains(&value)
        || value.fract() != 0.0
    {
        return Err(JsValue::from_str("count must be an integer from 1 to 4096"));
    }
    Ok(value as u32)
}

#[wasm_bindgen]
pub fn show_count(value: f64) -> Result<(), JsValue> {
    let count = checked_count(value)?;
    let window = web_sys::window().ok_or_else(|| JsValue::from_str("no window"))?;
    let document = window.document().ok_or_else(|| JsValue::from_str("no document"))?;
    let output = document.get_element_by_id("output")
        .ok_or_else(|| JsValue::from_str("missing output element"))?;
    output.set_text_content(Some(&format!("count={count}")));
    Ok(())
}
```

Save this complete `index.html` beside `Cargo.toml`:

```html
<!doctype html>
<html lang="en">
<meta charset="utf-8">
<title>Wasm boundary smoke</title>
<pre id="output">not initialized</pre>
<script type="module">
import init, { checked_count, show_count } from './pkg/wasm_boundary_smoke.js';
const output = document.getElementById('output');
try {
  await init();
  if (checked_count(4096) !== 4096) throw new Error('valid input failed');
  for (const invalid of [0, -1, 1.5, 4097, NaN, Infinity]) {
    let rejected = false;
    try { checked_count(invalid); } catch { rejected = true; }
    if (!rejected) throw new Error(`accepted invalid input: ${invalid}`);
  }
  show_count(12);
  if (output.textContent !== 'count=12') throw new Error('DOM update failed');
  output.textContent += '\nPASS';
} catch (error) {
  output.textContent = `FAIL: ${String(error)}`;
  console.error(error);
}
</script>
</html>
```

Run from that scratch crate:

```sh
wasm-pack build --target web --dev
python3 -m http.server --bind 127.0.0.1 8000
```

Open `http://127.0.0.1:8000/`. Expected result: `count=12` followed by `PASS`, with
no initialization failure. This tests generated JS, target numeric validation,
error-to-exception behavior, and actual `web-sys` DOM access. Stop the server
when finished. Do not use `file://` or claim that merely building exercised it.

For automated project tests, add compatible `wasm-bindgen-test` dev dependencies,
write `#[wasm_bindgen_test]` tests, and select browser execution with
`wasm_bindgen_test_configure!(run_in_browser)`. Then, with Chrome and matching
WebDriver available, run `wasm-pack test --headless --chrome`. The runner can
manage WebDriver installation when allowed; offline CI must provision it.
Default Node tests do **not** prove DOM behavior. See the
[first-party test runner guide](https://wasm-bindgen.github.io/wasm-bindgen/wasm-bindgen-test/browsers.html).

## WASI command smoke

Prerequisites: Rust/Cargo, installed `wasm32-wasip1` and `wasm32-wasip2` libraries,
Wasmtime with Preview 1 **and** Preview 2/component support, and `wasm-tools`.
Record the actual versions; other runtimes require their own compatibility check.
This is a command test, not a custom WIT plugin or HTTP component test.

```sh
rustup target add wasm32-wasip1 wasm32-wasip2
cargo new --bin --edition 2024 wasi_boundary_smoke
```

Replace `src/main.rs` in that new crate with this complete **WASI command** file.
It intentionally needs command arguments and is not a host rustdoc example:

```text
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut args = std::env::args().skip(1);
    let number: u32 = args.next().ok_or("missing unsigned integer")?.parse()?;
    let square = number.checked_mul(number).ok_or("square overflow")?;
    if let Some(path) = args.next() {
        let contents = std::fs::read_to_string(path)?;
        print!("{contents}");
    }
    println!("{square}");
    Ok(())
}
```

From the scratch crate, build and inspect both artifact kinds:

```sh
cargo build --target wasm32-wasip1 --release
cargo build --target wasm32-wasip2 --release
wasm-tools validate target/wasm32-wasip1/release/wasi_boundary_smoke.wasm
wasm-tools validate target/wasm32-wasip2/release/wasi_boundary_smoke.wasm
wasm-tools component wit target/wasm32-wasip2/release/wasi_boundary_smoke.wasm
wasmtime run target/wasm32-wasip1/release/wasi_boundary_smoke.wasm 12
wasmtime run target/wasm32-wasip2/release/wasi_boundary_smoke.wasm 12
```

Both runs should print `144` and exit successfully; component inspection should
show a command world including `wasi:cli/run`. No `component new` is needed.
Arguments after the artifact are guest arguments, not Wasmtime flags.

Negative and capability checks (the marked commands are **expected failures**):

```sh
wasmtime run target/wasm32-wasip2/release/wasi_boundary_smoke.wasm 65536
# Expected: nonzero exit with square overflow, not wrapped output.
mkdir fixture
printf 'allowed\n' > fixture/input.txt
wasmtime run target/wasm32-wasip2/release/wasi_boundary_smoke.wasm 12 fixture/input.txt
# Expected: nonzero exit; the file exists but no directory was granted.
wasmtime run --dir=fixture target/wasm32-wasip2/release/wasi_boundary_smoke.wasm 12 fixture/input.txt
# Expected: allowed, then 144, on separate lines; only fixture is preopened.
```

Check exit status and the relevant diagnostic, not merely “some failure.” A
missing file, missing runtime, or unknown import is not proof of denied authority.
Run the same policy cases for every supported host/interface version.

## Deployment and failure triage

| Symptom | Inspect before changing code |
|---|---|
| Fetch/streaming instantiation fails | HTTP status, Wasm MIME type (`application/wasm`), URL/base path, CORS, CSP, correct JS loader mode |
| Export missing or wrong signature | Stale glue/Wasm pairing, generated declarations, target output kind |
| Unknown import | Missing JS glue, wrong WASI preview, unsupplied custom WIT interface; inspect imports rather than stubbing them |
| Unsupported opcode / validation failure | Compiler/LLVM feature defaults and runtime support, including SIMD/atomics; local compiler upgrade can change minimum runtime |
| Browser freezes | Main-thread CPU loop/blocking or reentrant state access; async does not move work to a worker |
| Pointer/view corruption | Memory growth, freed allocation, aliasing, length/initialization error; prefer a safe copy |
| WASI file failure | Actual preopen and guest path, permission, encoding, and file existence |
| Trap/panic without useful context | Debug build or retained debug info, browser console/panic hook, runtime backtrace support |

Deploy generated JS and Wasm atomically with matching cache keys; avoid a cached
old wrapper loading a new binary. Test production base paths and content-security
policy, not only localhost. Threaded browser builds additionally require a secure
context and cross-origin isolation compatible with SharedArrayBuffer; validate
COOP/COEP and embedded resource policy using the actual browser deployment.

Use dev builds or explicit release debug information during diagnosis; stripping
symbols too early discards evidence. A console panic hook improves messages but
does not recover from a panic or convert it into your Result protocol. Standard
Wasm targets default to aborting panics; nondefault unwinding needs the documented
toolchain/runtime setup, not simply an assumption that `catch_unwind` works.

Measure download/compressed size, initialization, peak memory, and representative
end-to-end latency before choosing size profiles, LTO, wasm-opt, or batching.
Retest the optimized artifact; no particular flag or allocator guarantees a
smaller/faster outcome. Delegate measured tuning to **rust-performance** if installed.

Sources: [wasm-pack build](https://wasm-bindgen.github.io/wasm-pack/book/commands/build.html),
[binding deployment](https://wasm-bindgen.github.io/wasm-bindgen/reference/deployment.html),
[rustc target/feature/panic behavior](https://doc.rust-lang.org/rustc/platform-support/wasm32-unknown-unknown.html),
[Wasmtime CLI](https://docs.wasmtime.dev/cli-options.html),
[Wasmtime security](https://docs.wasmtime.dev/security.html).
