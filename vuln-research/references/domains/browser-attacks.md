# Browser Attacks Reference

Attacks exploiting the **browser security model** — cross-origin policies, navigation behavior, caching architecture, connection management, rendering pipeline, and content security policy enforcement.

---

## Clickjacking & UI Redressing

### DoubleClickjacking (2024)

A new UI redressing attack class by Paulos Yibelo that bypasses ALL known clickjacking protections including `X-Frame-Options`, CSP `frame-ancestors`, and `SameSite: Lax/Strict` cookies.

**Mechanism:**
1. Attacker page opens a new window with a button (e.g., "Click to verify")
2. On first click of a double-click: `mousedown` event fires immediately (before `onclick`), attacker swaps the top window content to expose a sensitive action (OAuth authorize, account settings)
3. On second click: victim unknowingly clicks the now-exposed sensitive button
4. Exploits timing difference between `mousedown` (fires immediately on press) and `onclick` (waits for complete click-release cycle) — works regardless of double-click speed

**Key properties:**
- No iframes needed — bypasses `X-Frame-Options` and `frame-ancestors`
- No cross-site cookies needed — bypasses `SameSite` protections
- Works on virtually every website with OAuth or sensitive one-click actions
- Affects platforms: Salesforce, Slack, Shopify, and most OAuth-based services
- Improvement by Jorian: victim can click anywhere on page to trigger (not just a specific button)

**Defenses:**
- Disable critical buttons until intentional user gesture detected (e.g., mouse movement or key press)
- Use `onclick` handlers (not `mousedown`) for sensitive actions
- Require explicit confirmation dialogs for destructive/sensitive operations

Source: Paulos Yibelo, 2024.

### SVG Filter Clickjacking 2.0 (2025)

Cross-origin pixel reading via SVG filter primitives applied to iframes in Chrome. Bypasses X-Frame-Options, CSP `frame-ancestors`, and all frame-busting defenses.

**Mechanism:**
1. SVG filter primitives (`feColorMatrix`, `feDisplacementMap`, `feBlend`, `feComposite`) can be applied to cross-origin iframes
2. Composing primitives into logic gates (AND, OR, XOR) creates a Turing-complete computation layer in the rendering engine
3. Attacker overlay reads real UI state (dialog open, checkbox checked, OTP displayed) and dynamically adjusts fake UI
4. Pixel data can be encoded into QR codes generated entirely within SVG filters

**Key properties:**
- Operates at rendering/compositor level — not blocked by framing defenses
- Cross-origin pixel read violates same-origin policy at visual layer
- No current browser fix exists
- Enables interactive, state-aware clickjacking (adapts to victim's actual page content)

Source: Lyra Horse, 2025.

### Reverse Tabnabbing

When a page opens a link with `target="_blank"` without `rel="noopener"`, the opened page gets a reference to the opener via `window.opener`. The opened page can then navigate the opener to a phishing page:

```javascript
// In attacker-controlled page opened via target="_blank"
window.opener.location = "https://phishing.com/fake-login";
```

**Impact:** Victim sees their original tab has "navigated" to a login page and enters credentials.

**Modern status:** Most modern browsers set `noopener` by default for `target="_blank"` links (Chrome 88+, Firefox 79+, Safari 12.1+). Still relevant for:
- Older browser versions
- `window.open()` calls without `noopener` feature
- Frameworks that explicitly set `opener` reference
- Electron apps and WebViews

---

## XS-Leaks (Cross-Site Information Leaks)

Cross-site information leakage without XSS — a distinct attack class exploiting observable side effects of cross-origin requests.

### Timing and State Channels

**Cache timing:**
- Resource cache probing: request a cross-origin resource, measure load time — cached (fast) vs. not cached (slow) reveals prior visit
- Frame counting: `window.frames.length` differs based on authenticated vs. unauthenticated response content

**Error event differential:**
- `onload` vs. `onerror` on `<img>`, `<script>`, `<link>`: status code (200 vs. 403/404) leaks authentication state
- Cross-origin fetch redirects observable via final URL vs. error

**History probing:**
- `performance.getEntriesByName(url)` reveals whether browser fetched a resource
- CSS `:visited` colour difference measurable via `getComputedStyle` in some engines

**Navigation state:**
- `window.opener.frames` counting detects navigation state changes in popups
- `window.length` (frame count) changes as authenticated content loads iframes

### Connection Pool Ordering Oracle

Chrome limits connections to 256 total, 6 per origin. Pending requests sorted alphabetically by port/scheme/host. Exhaust pool → observe completion order to infer cross-origin redirect destinations (e.g., `a.target.com` vs `z.target.com`) without reading response. Leaks redirect targets, revealing auth state or user identity.

### Cross-Site ETag Length Leak

Libraries like `jshttp/etag` encode response size in hex: `W/"[size_hex]-[timestamp_hex]"`. When response crosses a hex boundary (e.g., `0xfff` → `0x1000`), ETag gains one byte. On repeat navigation, browser sends `If-None-Match` with previous ETag — extra byte pushes total headers over Node.js 16 KiB `--max-http-header-size` limit → `431 Request Header Fields Too Large` detectable cross-origin as binary oracle for response size inference.

### Spectre-Class Channels
- `SharedArrayBuffer` + `Atomics.wait` for high-resolution timing (requires COOP/COEP headers)
- CSS paint timing leaks via `PerformancePaintTiming` API on cross-origin frames
- `requestAnimationFrame` timing differential for CPU-intensive cross-origin renders

### Header-Based Leaks
- `Sec-Fetch-Site` header value inference: server behaviour differences based on same-site vs. cross-site fetch are observable
- CORS preflight outcome leaks endpoint existence (connection refused vs. 404 vs. CORS header present)

### Broadcast Channel Probing
- `BroadcastChannel` API: attacker page joins named channel, observes messages if victim page posts state updates
- Shared worker connections observable by message timing

### COOP Interactions
- Pages without `Cross-Origin-Opener-Policy` retain `window.opener` reference — attacker can poll `opener.location`, `opener.frames`
- Pages with `COOP: same-origin` break opener reference — observable as side channel (breaks attacker's probe)

### XS-Leak Oracle Patterns

**CORB (Cross-Origin Read Blocking) oracle:**
- Browser blocks cross-origin responses with `Content-Type: text/html` from being loaded as images/scripts
- If response Content-Type varies by authentication state (HTML when logged in, JSON/204 when not), the CORB block/allow difference is observable
- `<script src="https://target.com/profile">` → CORB error (HTML) vs successful load (non-HTML) leaks auth state
- Works even with proper CORS headers — CORB operates independently

**X-Frame-Options oracle:**
- Target page sets `X-Frame-Options: DENY` conditionally (e.g., only for authenticated users, only for certain content)
- `<iframe>` load success/failure observable via `onload`/`onerror` events
- Combine with URL parameters to create binary oracle: does resource X exist for this user?
- Frame counting (`window.frames.length`) reveals whether framed page loaded subframes

**Prototype pollution as XS-Leak gadget:**
- Pollute `Object.prototype` with properties that alter cross-origin request behavior
- Example: `Object.prototype.timeout = 1` causes `XMLHttpRequest` to timeout after 1ms — timing differential reveals response size
- Polluting `constructor` or `toString` on objects passed to `postMessage` → observable side effects in receiver

**Error-vs-success status oracle:**
- Cross-origin `<img>`, `<script>`, `<link>` fire `onload` (2xx) vs `onerror` (4xx/5xx)
- `fetch()` with `mode: 'no-cors'` → `response.type === 'opaque'` but timing still observable
- Redirect count detection: `performance.getEntriesByType('resource')` reveals `redirectCount` for same-origin, timing for cross-origin
- Status code groups distinguishable via response timing (200 fast from cache, 403 triggers error handler, 302 adds redirect latency)

### Impact
- Detect authentication state (logged in vs. logged out)
- Enumerate private resources (does `/admin/report/123` exist?)
- Extract user data cross-origin via repeated oracle queries
- De-anonymise users by probing personalized resource URLs

### Defenses
- `Cross-Origin-Opener-Policy: same-origin` — breaks window reference leaks
- `Cross-Origin-Embedder-Policy: require-corp` — required for SharedArrayBuffer
- Proper cache partitioning (Chrome 86+, Firefox 85+ partition caches per top-level origin)
- `SameSite=Lax/Strict` cookies — prevents cross-site requests from carrying credentials
- Constant-time responses regardless of authentication state
- `Vary: Cookie` with `Cache-Control: private` on authenticated resources

---

## CSP Bypass Techniques

### CSP Bypass via Allowlisted Analytics Exfiltration
- Applications with `connect-src` allowing analytics domains (e.g., `insights-collector.newrelic.com`) can be exploited by redirecting token POST to New Relic Custom Events API
- Exfiltrated data stored as queryable NRQL events — no CSP mutation needed
- Generalizes to any allowlisted third-party endpoint accepting arbitrary POST data

### CSP Nonce Bypass via bfcache / Disk Cache
1. CSS attribute selectors exfiltrate nonce from cached page
2. Cache-key manipulation forces browser to load modified content from disk cache
3. On back-navigation, bfcache serves old nonce with new injected content
4. Nonce-based CSP bypassed without server issuing same nonce twice

### CRLF Nested Response Splitting CSP Gadget
- First CRLF split injects HTTP response whose body contains a *second* CRLF split
- Second split emits truncated JavaScript executing in same origin
- `Content-Length`/`Transfer-Encoding` manipulation controls parser boundary
- Script appears same-origin → bypasses CSP entirely

---

## Browser-Powered Desync Attacks

**CL.0 technique:** backend ignores `Content-Length` entirely, treating request body as the start of the next request. Browser-compatible because the HTTP request is fully spec-compliant — no header smuggling needed.

**H2.0 technique:** same concept over HTTP/2 — requests without `Content-Length` use HTTP/2 frame-layer length. Backend misinterprets leftover body data. Demonstrated against amazon.com.

**Client-Side Desync (CSD) methodology:**
1. **Detect:** find endpoints where servers ignore Content-Length (static files, server-level redirects, error pages)
2. **Confirm:** use `fetch()` with `credentials: 'include'` and `mode: 'no-cors'` to poison authenticated connection pool. Chrome maintains separate pools for cookied vs non-cookied requests
3. **Exploit:** store auth tokens, inject impossible headers (User-Agent, Host), HEAD method stacking for XSS

**Pause-based desync:** send headers, pause 15+ seconds (exceeding server timeout), then send body. Vulnerable servers (Varnish `synth()`, Apache redirects) leave connection open with half-parsed state. ~90% success rate with proper padding.

**First-request validation bypass:** reverse proxies that apply Host-header whitelists only to the first request on a connection. Send whitelisted host first, then request internal sites on reused connection.

**First-request routing:** front-ends route all subsequent requests down the backend connection established by the first request's Host header — enables password-reset poisoning and admin panel access.

Source: James Kettle / PortSwigger Research, 2022.

---

## HTML Smuggling

Deliver malicious payloads through proxies and DLP controls by assembling the payload entirely in browser memory after page load — the payload never appears in the HTTP response body, only in JavaScript.

- **Blob URL technique:** `URL.createObjectURL(new Blob([payload], {type: 'application/octet-stream'}))` — browser assembles and auto-downloads file from JS-constructed bytes
- **Data URL technique:** `<a href="data:application/octet-stream;base64,..." download="evil.exe">` — equivalent effect, slightly older compatibility
- **Why it bypasses inspection:** network-layer content inspection (proxies, DLP, AV gateways) sees only the HTML/JS wrapper; payload bytes are only assembled in browser memory after JS executes
- **Red team use:** used in phishing and initial access campaigns to deliver implants through corporate proxies that inspect HTTP response bodies
- **Detection evasion:** split payload into multiple JS arrays joined at runtime; encode with custom XOR or base64 to avoid static signatures

---

## WebSocket Private Network Access (PNA) Gap

Browsers enforce Private Network Access preflight checks on HTTP requests but NOT on WebSocket upgrades:
- Public page can establish `ws://192.168.1.1/` connection without PNA preflight
- Access internal services, IoT devices, routers via WebSocket from attacker-controlled page
- Particularly dangerous for internal APIs that offer WebSocket interfaces
- **Status:** Chrome plans to enforce PNA on WebSockets, but not yet implemented as of 2025

---
