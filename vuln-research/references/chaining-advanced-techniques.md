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
