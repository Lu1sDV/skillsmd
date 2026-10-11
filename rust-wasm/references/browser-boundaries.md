# Browser bindings and data boundaries

## Packaging is not target selection

Use `wasm32-unknown-unknown` for the conventional wasm-bindgen browser path.
It supplies `core`, `alloc`, and only partly functional `std`; the target alone
imports no browser APIs. `wasm-bindgen` generates JS glue, `js-sys` binds JS
built-ins, and `web-sys` binds Web APIs. Enable only the `web-sys` features needed
by the methods and types you use; inherited DOM methods may also need `Node` or
`HtmlElement`. See [rustc](https://doc.rust-lang.org/rustc/platform-support/wasm32-unknown-unknown.html)
and the [DOM binding example](https://wasm-bindgen.github.io/wasm-bindgen/examples/dom.html).

For a browser library, use `crate-type = ["cdylib", "rlib"]`: the former produces
the foreign-loadable artifact, the latter permits ordinary Rust library use.
A WASI command can instead be a binary crate; not all Wasm projects are libraries.

| wasm-pack output | Consumer | Initialization concern |
|---|---|---|
| `--target web` | Native browser ES module | Import generated JS; await its default initializer before calling exports |
| `--target bundler` | A compatible configured bundler | Verify its Wasm loading support; “uses Vite/webpack” alone is insufficient |
| `--target nodejs` | Node CommonJS | Consume generated package with `require`; no browser DOM |

`wasm-pack build` uses release by default; select `--dev` while debugging.
Keep `pkg/*.js`, `*.wasm`, declarations, and package metadata from the same build.
When invoking wasm-bindgen CLI directly, match its version to the crate; do not
pair stale generated glue with a rebuilt module. Preserve lockfiles and record
tool versions. The [build manual](https://wasm-bindgen.github.io/wasm-pack/book/commands/build.html)
is marked unpublished: use installed `wasm-pack build --help` to confirm options,
not newly documented flags as a guarantee about an older release.

## Boundary contract

The [binding type guide](https://wasm-bindgen.github.io/wasm-bindgen/reference/types.html)
is authoritative for the pinned wasm-bindgen version. Do not infer an ABI from
Rust types alone.

| Boundary value | Decide explicitly |
|---|---|
| Integer input from JS | Generated bindings may truncate, wrap, or coerce non-finite values; validate as `f64`, or check a `JsValue` before conversion |
| `u64` / `i64` | Use the binding's `BigInt` representation, or an explicitly encoded string; plain JSON cannot encode BigInt without a policy |
| Text | Rust UTF-8 byte lengths differ from JS UTF-16 code-unit lengths; define length limits and normalization needs |
| Numeric buffer | Numeric slices/vectors use typed-array bindings; arbitrary generic `Vec<T>` is not a universal JS Array conversion |
| Structured object | Select explicit fields/validation, or a chosen serialization adapter; Serde is not magically enabled by wasm-bindgen |
| Rust object exported as JS class | Define ownership and disposal; generated `free()` invalidates the Rust allocation; do not retain/use freed handles |
| Error | Stable code plus bounded safe message if callers branch on it; do not make user-visible stack traces the API |

For strict JS *type* validation, use `JsValue` and inspect it: a numeric parameter
alone may still accept JS coercions before Rust sees it. For range validation of
numbers, `f64` retains fraction/NaN information that an integer parameter loses.
[Numeric conversion rules](https://wasm-bindgen.github.io/wasm-bindgen/reference/types/numbers.html)
explain why `fn set_size(n: u32)` is not input validation.

### Host-executable boundary example

This is domain code, not a simulated browser. The first function accepts only
integral, finite dimensions within an explicit application limit. The second
rejects invalid byte shape before modifying anything; alpha is preserved. Input
limits are a contract, not an assertion that every image should use this limit.
The assertions run on the host with no dependencies; they do not test JS glue.

```rust
#[derive(Debug, PartialEq, Eq)]
enum ImageError {
    Dimension,
    Shape,
}

fn dimension(number: f64) -> Result<u32, ImageError> {
    if !number.is_finite()
        || !(1.0..=4096.0).contains(&number)
        || number.fract() != 0.0
    {
        return Err(ImageError::Dimension);
    }
    Ok(number as u32)
}

fn grayscale_rgba(
    bytes: &mut [u8],
    width: f64,
    height: f64,
) -> Result<(), ImageError> {
    let width = usize::try_from(dimension(width)?)
        .map_err(|_| ImageError::Dimension)?;
    let height = usize::try_from(dimension(height)?)
        .map_err(|_| ImageError::Dimension)?;
    let expected = width.checked_mul(height)
        .and_then(|pixels| pixels.checked_mul(4))
        .ok_or(ImageError::Shape)?;
    if bytes.len() != expected {
        return Err(ImageError::Shape);
    }
    for pixel in bytes.chunks_exact_mut(4) {
        let gray = (299 * u32::from(pixel[0])
            + 587 * u32::from(pixel[1])
            + 114 * u32::from(pixel[2])) / 1000;
        pixel[..3].fill(gray as u8);
    }
    Ok(())
}

assert_eq!(dimension(4096.0), Ok(4096));
for invalid in [0.0, -1.0, 1.5, 4097.0, f64::NAN, f64::INFINITY] {
    assert_eq!(dimension(invalid), Err(ImageError::Dimension));
}
let mut pixels = [255, 0, 0, 23, 0, 255, 0, 99];
assert_eq!(grayscale_rgba(&mut pixels, 2.0, 1.0), Ok(()));
assert_eq!(pixels, [76, 76, 76, 23, 149, 149, 149, 99]);
let unchanged = pixels;
assert_eq!(grayscale_rgba(&mut pixels, 1.0, 1.0), Err(ImageError::Shape));
assert_eq!(pixels, unchanged);
assert_eq!(grayscale_rgba(&mut pixels, 1.5, 1.0), Err(ImageError::Dimension));
assert_eq!(pixels, unchanged);
assert_eq!(grayscale_rgba(&mut [], 1.0, 1.0), Err(ImageError::Shape));
```

This computes an encoded-channel weighted grayscale, not a color-managed
linear-light luminance transform. At the actual JS adapter, enforce a byte limit
before copying large input when possible, then call the validated domain function.
Integration tests must check whether the selected mutable-slice binding copies
changes back into the caller's array; do not assume shared memory from `&mut`.

## Memory and object lifetime

Safe typed-array bindings are the default. A JS typed-array view into Wasm memory
is not a Rust borrow. A view can outlive its allocation, alias a Rust reference,
or become stale/detached after memory growth. The unsafe
[`Uint8Array::view`](https://docs.rs/js-sys/latest/js_sys/struct.Uint8Array.html#method.view)
API therefore requires an explicit lifetime and mutation protocol.

If a measured hot path truly requires direct memory access, document allocation
identity, initialized length, capacity, permitted writers, reentrancy, growth,
view refresh, and exactly-once deallocation. A pointer plus length from JS is not
proof that it names a valid Rust allocation. `Vec::with_capacity` creates capacity,
not initialized elements; forgetting it leaks and does not transfer a usable
allocator contract to JS. Hand off raw-memory design to **rust-unsafe-ffi** if installed.

For callbacks, store the Rust closure with the object that owns the event listener.
Unregister it before drop. A closure leaked with `forget` will not provide orderly
teardown. If JS can call back synchronously, release `RefCell` borrows or other
exclusive state access before making that call; reentrancy is possible without
multiple threads.

## DOM and asynchronous work

Use `web_sys::window()` only when the contract is a browser window. A worker can
use Web APIs without having `window.document`; Node has neither browser DOM nor
window. Check optional document/body/element lookups and return errors. Use
`set_text_content` for untrusted text, not `set_inner_html`. Select required
`web-sys` features explicitly as in the [official DOM example](https://wasm-bindgen.github.io/wasm-bindgen/examples/dom.html).

For fetch:

1. Construct the request and attach an abort signal if cancellation is part of
   the API. Do not embed secrets into public client-side Wasm.
2. Await the host Promise with the project's supported bridge. The established
   `wasm_bindgen_futures::JsFuture::from(promise)` path remains documented;
   newer `js-sys` versions also support direct Promise awaiting. Pin dependencies
   before selecting newer APIs.
3. Handle rejection (network/CORS/abort) separately from an HTTP response with
   `ok() == false`. Fetch does not reject merely because a server returned 404.
4. Validate content type, payload size, parse result, and domain schema as required.
5. Return `Result`; exported async `Err` rejects the returned JS Promise. Attach
   a JS rejection handler at the application boundary.
6. On cancellation, call the host abort operation explicitly and define whether
   stale results are discarded. Promise rejection and future drop are not a
   general cancellation protocol.

The [Promise/Future guide](https://wasm-bindgen.github.io/wasm-bindgen/reference/js-promises-and-rust-futures.html)
documents conversion semantics. `spawn_local` schedules on the local JS executor;
it does not make a long CPU loop nonblocking. Workers can isolate such work, but
worker messages, transferable buffers, and shutdown require their own contract.
Shared-memory threads are a separate feature, not a consequence of `async fn`.
