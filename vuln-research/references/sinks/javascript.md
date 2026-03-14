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
- **NoSQL Injection:** `mongoose.find()` / `findOne()` with `$gt`, `$ne`, `$regex` from req.body, `mongodb` native driver with unsanitized query objects
- **ReDoS:** `new RegExp(user_input)`, `String.prototype.match()` / `.replace()` / `.search()` with user-controlled patterns
- **Module injection:** `require(userInput)` — dynamic module loading with attacker-controlled path; can load arbitrary native addons or reach `node_modules` gadgets
- **Prototype pollution via parse+merge:** `JSON.parse(userInput)` result spread/merged without sanitization introduces `__proto__` keys; pair with any recursive merge utility
- **WebSocket URL poisoning:** `new WebSocket(userInput)` — attacker controls WS endpoint, enables data exfiltration or connection to malicious server
- **Cookie injection / session fixation:** `document.cookie = userInput` — unsanitized value can set arbitrary cookies including `session` or `auth` tokens
- **WebSQL (deprecated, still present in Chromium-based apps):** `db.executeSql(userInput)` — SQL injection in client-side SQLite
- **Storage-based persistent XSS:** `localStorage.setItem(key, userInput)` — benign on write but creates a persistent XSS source if the stored value is later read and rendered unsanitized into the DOM
