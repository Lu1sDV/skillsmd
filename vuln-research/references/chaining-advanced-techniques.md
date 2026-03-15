# Chaining, Scanning & Advanced Techniques Reference

## Vulnerability Chaining

Single bugs are starting points. Real impact comes from chains.

### Chain Types

**Same-Origin Chains:** vulnerabilities in the same application that combine for greater impact.

**Trust-Based Chains:** exploiting trust relationships between services (internal APIs, SSO, cloud metadata).

**Credential-Based Chains:** extracting credentials from one vulnerability to unlock another attack surface.

### Chain Patterns

**Reader + Writer = RCE:**
- Path traversal reads DB creds → authenticate → exploit admin-only RCE
- SQLi reads file via `LOAD_FILE` → find write path → SQLi writes webshell via `INTO OUTFILE`
- SSRF to internal Redis → `SET` + `CONFIG SET dir/dbfilename` → webshell on disk
- XXE reads source code → find hardcoded key → forge auth token → access admin RCE

**Client-Side → Server-Side:**
- Stored XSS in admin panel → steal admin session → authenticated RCE
- CSRF disables security settings → opens door for further attacks
- XSS delivers CSRF payload → bypasses CSRF token protection
- Blind XSS fires in admin panel → exfiltrate admin API key → call privileged endpoints

**Escalation Chains:**
- IDOR + missing access control → mass data breach
- SSRF → cloud metadata → AWS keys → full infrastructure compromise
- Mass assignment (`role=admin`) → instant privilege escalation → access admin-only RCE
- Info disclosure (phpinfo, config leak, stack traces) → credentials → pivot
- Open redirect → OAuth token theft → account takeover
- Prototype pollution → RCE via child_process gadget
- HTTP request smuggling → bypass WAF → exploit backend vulnerability

**Race Condition Chains:**
- Double-spend on balance transfer
- Duplicate coupon redemption
- TOCTOU on file operations → arbitrary file write
- Concurrent registration → duplicate account with elevated privileges

**Deserialization Chains:**
- File upload (image with embedded Phar) → trigger file operation on `phar://` → deserialization → RCE
- SQLi → write Phar to disk via `INTO DUMPFILE` → trigger deserialization
- SSRF → access internal service → deserialization endpoint

**XSLT Injection Chains:**
- XSLT XXE reads config → find credentials → pivot to admin
- XSLT `document()` function → SSRF to internal services → credential theft
- PHP XSLT `php:function()` → `assert()` → RCE
- Java Xalan namespace → `Runtime.exec()` → RCE
- .NET `msxsl:script` → `Process.Start()` → system compromise

**Cache Poisoning Chains:**
- Open redirect + cache poisoning → cache redirect under `/main.js` → all visitors load attacker JS
- SSRF + cache poisoning → poison internal API responses
- Delimiter path confusion + static extension → cache authenticated responses for attacker retrieval
- XSS + Service Worker → persist malicious cache entries beyond poisoning window

**Prototype Pollution Chains:**
- Prototype pollution + EJS template → RCE (`escapeFunction` gadget)
- Prototype pollution + child_process → RCE via `NODE_OPTIONS` + `/proc/self/environ`
- Prototype pollution + DOMPurify → sanitizer bypass → stored XSS
- Prototype pollution + Express `body` overwrite → stored XSS via HTML injection

**Browser-Powered Desync Chains:**
- CL.0 + client-side desync → steal auth tokens without MITM
- Pause-based desync + first-request routing → access internal admin panels
- Client-side desync + cache poisoning → persist XSS via CDN

**iconv CVE-2024-2961 Chains:**
- PHP file read (LFI, XXE, SSRF) → `php://filter` with `convert.iconv.UTF-8.ISO-2022-CN-EXT` → heap overflow → RCE
- XXE on Magento (CVE-2024-34102) → file read → iconv → RCE (full chain demonstrated)
- Roundcube file read → iconv → RCE
- Key insight: ANY PHP file read is now a Critical RCE vector

**CSPT → CSRF Chains:**
- Client-Side Path Traversal source (user-controlled value in `fetch()` URL) → `../` traversal to state-changing endpoint → authenticated CSRF without traditional CSRF bypass
- CSPT + encoding bypass → WAF evasion → CSRF on protected endpoints
- Jupyter CSPT (CVE-2023-39968 + CVE-2024-22421) → auth token leakage → full access

**Web Cache Deception → Account Takeover Chains:**
- WCD via delimiter confusion (`;`, `%23`, `%3f`) + static extension → cache authenticated response → attacker retrieves session/tokens → ATO
- ChatGPT WCD: `session.css` cached by CDN → session token exposed → full ATO
- Path normalization differential (CDN normalizes, origin doesn't) → cache dynamic auth response under static key → mass ATO

**CSS Injection Exfiltration Chains:**
- HTML injection (limited, no JS) → CSS `cross-fade()` nested exfiltration → leak CSRF token/session → CSRF/ATO
- CSS `@import` recursive chain → server-controlled delay → character-by-character secret extraction
- `:has()` selector + attribute prefix matching → extract hidden input values without JavaScript
- CSS injection in email client → `cross-fade()` → leak blob URLs (Proton Mail research)

**DOM Clobbering Chains:**
- HTML injection (sanitized, no scripts) → DOM clobbering `document.currentScript.src` → library loads from attacker URL → XSS
- DOM clobbering `form.attributes` → sanitizer bypass (DOMPurify) → stored XSS
- DOM clobbering + Webpack/Vite dev server → XSS in development environment → credential theft

**DoubleClickjacking Chains:**
- DoubleClickjacking on OAuth authorize endpoint → attacker app gains victim's access token → ATO
- DoubleClickjacking on account settings → change email/password → ATO
- DoubleClickjacking + OAuth device flow → authorize malicious device without victim awareness

**CPDoS Chains:**
- CPDoS + targeted resource selection → deny access to login page, password reset, or critical API endpoints
- CPDoS + social engineering → cache error on competitor's product page during launch

**SVG Filter Clickjacking Chains:**
- SVG filter pixel reading + cross-origin iframe → detect OTP/CSRF token rendered on page → automated exfiltration
- SVG filter + DoubleClickjacking → state-aware UI redressing adapts to victim's actual page content

**Cookie Tossing Chains:**
- Self-XSS on subdomain + cookie tossing → overwrite OAuth `state` cookie → OAuth CSRF → ATO
- Subdomain takeover + cookie tossing → hijack parent domain sessions

**SSRF Amplification Chains:**
- Blind SSRF + redirect loop error state → full response exfiltration (converts Low SSRF to High)
- SSRF + HTTP/2 CONNECT tunnel → raw TCP access to internal services (bypasses HTTP-level SSRF filters)

**AI Agent Chains:**
- Prompt injection via tool output (s1ngularity) → agent exfiltrates secrets → lateral movement via agent's API access
- Clinejection (source file poisoning) → AI assistant executes attacker code in developer's environment → supply chain compromise
- MCP tool description injection → agent calls attacker-controlled endpoints → data exfiltration

**Cloud/Container Escape Chains:**
- ECScape: ECS host networking + IMDSv1 → steal host IAM → cross-account pivot
- NVIDIAScape: GPU container + toolkit CVE → host escape → cluster compromise
- kro confused deputy → create privileged pod → escape to node → cluster admin

**SOAPwn Chains:**
- WSDL import + file:// scheme confusion → arbitrary file write → ASPX webshell → RCE (CVE-2025-34392)
- WSDL import + UNC path → NTLM relay → domain admin

**Next.js Cache Poisoning Chains:**
- Internal header injection (`x-now-route-matches`) → SSR misclassified as SSG → CDN caches authenticated response → data leak or stored XSS for all visitors

### Impact Amplifiers

Re-score severity in chain context:
- A **Low** open redirect becomes **High** when it enables OAuth token theft → account takeover
- A **Medium** SSRF becomes **Critical** when it reaches cloud metadata → full infrastructure compromise
- A **Low** info disclosure becomes **High** when it leaks credentials used for admin access
- A **Medium** stored XSS becomes **Critical** when it fires in an admin panel with RCE capability
- A **Low** prototype pollution becomes **Critical** when it enables `NODE_OPTIONS` RCE via child_process
- A **Low** CSS injection becomes **High** when `:has()` selectors extract CSRF tokens without JS
- A **Medium** cache poisoning becomes **Critical** with delimiter path confusion caching auth responses
- A **Low** DOM clobbering becomes **High** when it bypasses DOMPurify `attributes` enumeration → stored XSS
- A **Medium** XSLT injection becomes **Critical** when PHP `php:function()` reaches `system()`
- A **Low** file read (PHP) becomes **Critical** via iconv CVE-2024-2961 heap overflow → reliable RCE
- A **Low** HTML injection becomes **High** via CSS `cross-fade()` exfiltration → CSRF token theft → ATO
- A **Low** CSPT becomes **High** when traversal reaches state-changing API → authenticated CSRF
- A **Medium** WCD becomes **Critical** when caching session tokens → mass ATO (ChatGPT pattern)
- A **Low** DOM clobbering becomes **Critical** via `document.currentScript` → library hijack → stored XSS
- A **Low** DoubleClickjacking becomes **Critical** on OAuth authorize → access token theft → ATO
- A **Low** blind SSRF becomes **High** via redirect loop error state amplification → full response exfiltration
- A **Low** self-XSS on subdomain becomes **Critical** via cookie tossing → OAuth state hijack → ATO
- A **Medium** SVG filter injection becomes **Critical** via cross-origin pixel reading → OTP/token exfiltration
- A **Low** WSDL import becomes **Critical** via SOAPwn file:// scheme confusion → arbitrary file write → RCE
- A **Low** prompt injection becomes **Critical** when AI agent has tool access → data exfiltration or code execution
- A **Medium** Next.js header injection becomes **Critical** via cache poisoning → stored XSS affecting all visitors

### Composite Risk Scoring

For aggregate findings across an audit:

| Severity | Weight |
|----------|--------|
| Critical | 10 |
| High | 7 |
| Medium | 4 |
| Low | 1 |

**Score** = SUM(finding_weight) — use to compare overall security posture across audits.

---

## Scanning Augmentation

Layer automated tools over manual analysis:

### Dependency Scanning
- Snyk, npm audit, pip-audit, `composer audit` against lock files for known CVEs

### Static Analysis (SAST)
- Taint analysis: Semgrep, Psalm, PHPStan, Bandit, CodeQL for flows manual review missed
- See `sinks-catalog.md` for SAST rule IDs per language

### Dynamic Analysis (DAST)
- Nuclei templates for known CVE fingerprints
- Directory brute forcing for hidden endpoints (feroxbuster, ffuf, gobuster)
- HTTP security header audit
- Fuzzing: parameter fuzzing with wordlists, header fuzzing, method fuzzing

### Reconnaissance
- Subdomain enumeration (subfinder, amass, crt.sh)
- JavaScript analysis: extract endpoints from bundled JS, find secrets in source maps, identify client-side prototype pollution

### Hidden Parameter Discovery

Tools: `Arjun`, `ParamMiner` (Burp extension), `x8`, `GAP-Burp-Extension`

High-value hidden parameters to fuzz:
| Parameter | Effect |
|-----------|--------|
| `debug=1`, `_debug=true` | Verbose error output, stack traces |
| `test=true`, `testing=1` | Bypass rate limits, skip auth |
| `admin=1`, `role=admin` | Privilege escalation |
| `internal=true` | Expose internal endpoints |
| `verbose=1`, `trace=1` | Detailed logging in response |
| `source=true` | Source code disclosure |
| `callback=` | JSONP endpoint, potential XSS |

Technique: compare response length/status/timing with and without parameter to detect reflected or behavior-changing params.

Automated tools supplement, never replace, manual source review.

---

## Common Blind Spots (Full List)

Before declaring "done", verify you tested:

- Only testing as admin (test unauth first, then low-priv, then admin)
- Only testing GET params (check POST body, JSON body, headers, cookies, path segments, file upload names)
- Ignoring second-order bugs (stored safely, used unsafely later — especially in admin panels, logs, reports)
- Ignoring differential error messages (username enumeration, path disclosure, stack traces)
- Not testing rate limits (brute force login, OTP, password reset, API key enumeration)
- Skipping CORS check (`Access-Control-Allow-Origin: *` with credentials)
- Missing `.htaccess` / `.user.ini` upload as attack vector
- Not checking for `phar://` deserialization when `unserialize` isn't directly called
- Forgetting `php://filter` for source code disclosure via LFI
- Not testing file upload with double extensions, polyglot files, and content-type manipulation
- Assuming ORM means no SQLi (raw query methods bypass sanitization)
- Not checking WebSocket endpoints (often completely unauthenticated)
- Not trying content-type switching (JSON → XML for XXE, form-encoded for CSRF on JSON APIs)
- Forgetting HTTP/2-specific attacks (request smuggling, HPACK injection)
- Not testing for prototype pollution in Node.js applications
- Ignoring DNS rebinding for SSRF bypass
- Not checking for JNDI injection in Java applications (especially Log4j patterns)
- Skipping container/cloud metadata checks during SSRF testing
- Not testing alternative HTTP methods (PUT, DELETE, PATCH, OPTIONS)
- Ignoring `__proto__`, `constructor`, `prototype` in JSON inputs to Node.js
- Not checking for filter chain RCE when LFI exists but `allow_url_include` is off
- Forgetting that race conditions affect almost every state-changing operation, not just financial ones
- Not testing with different encodings and character sets simultaneously
- Not testing XSLT injection in XML processing endpoints (PHP `php:function()`, Java Xalan, .NET `msxsl:script`)
- Not checking for browser-powered desync (CL.0, H2.0) on static files and redirect endpoints
- Not testing CSS injection exfiltration via `:has()` selectors and `@import` chains
- Not checking DOM clobbering in SPAs with sanitized but named HTML elements
- Forgetting client-side prototype pollution via URL fragment (`#__proto__[x]=y`)
- Not testing cache delimiter path confusion (`;`, `.`, `%00`, `%0a` per framework)
- Skipping Service Worker cache pollution tests
- Not checking JWT audience (`aud`) claim validation across microservices
- Forgetting mutable claims (email vs sub) in OAuth identity mapping
- Not testing ECDSA psychic signature (CVE-2022-21449) on Java endpoints
- Ignoring edge compute cache (Lambda@Edge, Workers) returning stale auth responses
- Not testing Fastjson cache poisoning (`java.lang.Class` → bypass autoType)
- Forgetting `pearcmd.php` exploitation for LFI→RCE when PEAR is installed
- Not testing OPcache poisoning when `validate_timestamps=off`
- [ ] Not testing hop-by-hop header abuse for IP-based ACL bypass (`Connection: X-Custom-IP-Authorization`)
- [ ] Not testing argument injection via leading hyphen in `execFile`/`spawn` calls (no shell metacharacters needed — `curl -o`, `tar --checkpoint-action`, `ssh -o ProxyCommand`)
- [ ] Not testing SSRF with IPv6 zone identifiers (`http://[fe80::1%25eth0]/`)
- [ ] Not testing `jar:http://internal!/` for SSRF protocol filter bypass (Java)
- [ ] Not fuzzing for hidden parameters (`debug=1`, `admin=1`, `test=true`) with Arjun/ParamMiner
- [ ] Not testing mass assignment with framework-specific payloads (`is_admin=true`, `role=admin`, `email_verified=true`)
- [ ] Not testing `postMessage` receivers for missing origin validation (check `getEventListeners(window)`)
- [ ] Not testing CSTI in Angular/Vue/Handlebars client-side templates (distinct from XSS — uses `{{}}` interpolation, no HTML tags)
- [ ] Not testing DoubleClickjacking on OAuth authorize and account settings pages (bypasses X-Frame-Options, SameSite, CSP frame-ancestors)
- [ ] Not testing Client-Side Path Traversal (CSPT) — `../` in frontend `fetch()` URLs leading to CSRF
- [ ] Not testing iconv CVE-2024-2961 on PHP file read primitives (ANY file read → RCE via ISO-2022-CN-EXT)
- [ ] Not testing Web Cache Deception with delimiter confusion (`;`, `%23`, `%3f`, `%00`) + static extensions
- [ ] Not testing CPDoS (Cache Poisoned Denial of Service) via oversized headers, metacharacters, or response splitting
- [ ] Not testing CSS exfiltration via `cross-fade()` nesting in HTML injection contexts
- [ ] Not testing DOM clobbering of `document.currentScript` / `document.scripts` in frontend build tools
- [ ] Not testing GraphQL alias overloading and directive overloading for rate limit bypass and DoS
- [ ] Not testing Zip Slip in archive extraction (file upload → path traversal in archive entries)
- [ ] Not testing OAuth device code flow abuse (victim authorizes on legitimate provider page)
- [ ] Not testing SAML self-signed certificate acceptance (SP validates signature but not certificate chain)
- [ ] Not testing ORM smuggling (Beego filter overwrite, Prisma type confusion, Sequelize operator aliasing)
- [ ] Not testing reverse tabnabbing via `window.opener` in `window.open()` calls without `noopener`
- [ ] Not testing web timing attacks for hidden parameter discovery and SSRF confirmation
- [ ] Not testing SVG filter primitives for cross-origin pixel reading in Chrome (bypasses all framing defenses)
- [ ] Not testing cookie tossing from subdomains to hijack parent domain OAuth flows
- [ ] Not testing blind SSRF with redirect loops for error-state response leakage
- [ ] Not testing HTTP/2 CONNECT for TCP tunnel SSRF bypassing HTTP-level filters
- [ ] Not testing Next.js internal headers (`x-now-route-matches`, `__nextDataReq`) for cache poisoning
- [ ] Not testing AI coding assistants (Cline, Cursor, Copilot) for source file prompt injection
- [ ] Not testing MCP tool descriptions for prompt injection vectors
- [ ] Not testing ETag values for inode/size/timestamp information leakage
- [ ] Not testing Apache module interaction confusion (Filename/DocumentRoot/Handler confusion)
- [ ] Not testing WebSocket connections for Private Network Access (PNA) gap — no preflight enforced
- [ ] Not testing .NET WSDL import for SOAPwn file:// scheme confusion (CVE-2025-34392)
- [ ] Not testing abandoned S3 bucket names for supply chain hijacking
- [ ] Not testing SAML parser differentials across XML libraries (libxml2 vs Java DOM vs .NET)
- [ ] Not testing bcrypt 72-byte truncation with long usernames (Okta CVE-2024-56167 pattern)
- [ ] Not testing ORM relationship traversal (plORMbing) for blind data exfiltration via filter parameters
- [ ] Not testing Unicode normalization form differentials (NFC vs NFKC) for WAF bypass
- [ ] Not testing CSS `@font-face` `unicode-range` for text content exfiltration without JavaScript
