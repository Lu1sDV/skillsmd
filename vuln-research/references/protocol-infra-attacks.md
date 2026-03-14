# Protocol & Infrastructure Attacks Reference

## HTTP Request Smuggling

- **CL.TE:** front-end uses Content-Length, back-end uses Transfer-Encoding — inject a second request body
- **TE.CL:** front-end uses Transfer-Encoding, back-end uses Content-Length — reverse of above
- **TE.TE:** both use Transfer-Encoding but one can be confused with obfuscation: `Transfer-Encoding: chunked`, `Transfer-Encoding : chunked`, `Transfer-Encoding: xchunked`, `Transfer-Encoding: chunked\r\nTransfer-Encoding: identity`, tab/space before value
- **HTTP/2 downgrade smuggling (H2.CL, H2.TE):** HTTP/2 front-end converts to HTTP/1.1 for back-end — `content-length` and `transfer-encoding` headers in HTTP/2 pseudo-headers get rewritten
- **Request splitting via CRLF in HTTP/2 header values** (`:method`, `:path`, custom headers)
- **Impacts:** bypass front-end security controls, access internal endpoints, poison web cache, hijack other users' requests, deliver reflected XSS without user interaction
- **Detection:** send ambiguous requests, measure response timing/content for desync confirmation
- **Exploitation:** prefix smuggled request with `GET /admin HTTP/1.1`, or smuggle `Transfer-Encoding: chunked` to split subsequent user requests
- **Connection-state attacks:** first request changes connection state (auth, routing), second request inherits it
- **WebSocket smuggling:** upgrade request desync allows tunneling arbitrary traffic through WebSocket connection

### Browser-Powered Desync Attacks

**CL.0 technique:** backend ignores `Content-Length` entirely, treating request body as the start of the next request. Browser-compatible because the HTTP request is fully spec-compliant — no header smuggling needed.

**H2.0 technique:** same concept over HTTP/2 — requests without `Content-Length` use HTTP/2 frame-layer length. Backend misinterprets leftover body data. Demonstrated against amazon.com.

**Client-Side Desync (CSD) methodology:**
1. **Detect:** find endpoints where servers ignore Content-Length (static files, server-level redirects, error pages)
2. **Confirm:** use `fetch()` with `credentials: 'include'` and `mode: 'no-cors'` to poison authenticated connection pool. Chrome maintains separate pools for cookied vs non-cookied requests
3. **Exploit:** store auth tokens, inject impossible headers (User-Agent, Host), HEAD method stacking for XSS

**Pause-based desync:** send headers, pause 15+ seconds (exceeding server timeout), then send body. Vulnerable servers (Varnish `synth()`, Apache redirects) leave connection open with half-parsed state. ~90% success rate with proper padding.

**First-request validation bypass:** reverse proxies that apply Host-header whitelists only to the first request on a connection. Send whitelisted host first, then request internal sites on reused connection.

**First-request routing:** front-ends route all subsequent requests down the backend connection established by the first request's Host header — enables password-reset poisoning and admin panel access.

---

## Web Cache Poisoning & Deception

- **Cache poisoning:** inject unkeyed headers (`X-Forwarded-Host`, `X-Original-URL`, `X-Forwarded-Scheme`) that alter response content but aren't in cache key → serve malicious content to other users
- **Cache deception:** trick authenticated user into visiting `https://target.com/account/settings/nonexistent.css` → cache stores authenticated response → attacker retrieves cached page
- **Path confusion:** `/api/user/profile%2F..%2F..%2Fstatic/cached.js` — cache sees `.js` extension, caches; origin processes path differently
- **Fat GET:** send GET request with body containing parameters that alter response but cache ignores body
- **Parameter cloaking:** exploit `utm_content`, `;` as parameter separator in some frameworks, parameter pollution with different cache key behavior
- **Unkeyed headers for poisoning:** `X-Forwarded-Host`, `X-Host`, `X-Forwarded-Server`, `X-Original-URL`, `X-Rewrite-URL`, `X-Forwarded-Prefix`
- **Cache key normalization differences:** cache normalizes case/encoding differently than origin → bypass cache key matching
- **Vary header abuse:** force different `Vary` combinations to poison specific cache entries

### Delimiter-Based Path Confusion

| Framework | Delimiter | Example |
|-----------|-----------|---------|
| Spring (Java) | `;` (matrix variable) | `/MyAccount;var=val` resolves to `/MyAccount` |
| Rails | `.` (format) | `/MyAccount.css` strips extension |
| OpenLiteSpeed | `%00` (null byte) | Truncates path |
| Nginx (rewrite) | `%0a` (newline) | Acts as delimiter |

CDN caches based on full URL including delimiter; origin strips it — dynamic content cached as static.

### Normalization Differentials

| CDN | Behavior | Vulnerability |
|-----|----------|---------------|
| CloudFlare | Doesn't normalize before rules + recognizes many extensions | Static extension padding |
| Azure / Imperva | Normalize before rules + treat dots as significant | Path traversal injection |
| Google Cloud / Fastly | Don't normalize before rules | Unnormalized traversal payloads |

**Pattern:** request `/account/../../home` — cache normalizes to `/home` (stores it), origin follows traversal to serve `/account` content under `/home` key.

### Multi-Layer Encoding Confusion
`GET /%3F%3Fstatic.js` (double-encoded `?`) — cache decodes once, sees `.js` (static); origin decodes twice, interprets as query parameter. Dynamic content cached under static key.

### Hash Fragment Exploitation
`#` behaves differently across servers: most strip it, some CDNs treat as delimiter, Azure normalizes through it — enables key confusion attacks.

### Cache-What-Where Escalation
Chain unexploitable vulnerability (e.g., parameter-dependent open redirect) with cache poisoning: cache redirect response under popular resource key like `/main.js`. All visitors load attacker-controlled JS.

### CDN-Specific Attack Indicators

| CDN | Indicator Headers | Key Vectors |
|-----|-------------------|-------------|
| **Cloudflare** | `CF-Cache-Status` | Uncommon extensions (.webp, .avif) bypass; Cache Deception Armor |
| **Akamai** | `Server-Timing: cdn-cache` | `X-Cache-Key` header injection; auth/unauth response diff |
| **Fastly** | `X-Fastly-Cache` | VCL manipulation; stale content via TTL abuse |
| **AWS CloudFront** | `X-Amz-Cf-Id` | Lambda@Edge logic bypass; API Gateway cached without auth |

### Emerging Cache Techniques (2025+)
- **Edge compute exploitation:** Lambda@Edge, Cloudflare Workers responding from cache without revalidation
- **`stale-while-revalidate` abuse:** extends poison lifetime via cache directives
- **Service Worker cache pollution:** manipulate browser Cache API to persist malicious responses
- **GraphQL cache abuse:** improperly keyed query bodies allowing response substitution
- **SPA/SSR poisoning:** client-rendered pages cached at CDN with user-specific data
- **Hop-by-hop header confusion:** `Connection`, `TE`, `Keep-Alive` cached improperly

---

## GraphQL Attacks

- **Introspection:** `{__schema{types{name,fields{name,args{name}}}}}` to map entire API surface
- **Disabled introspection bypass:** try `__type`, `__typename`, field suggestion error messages leak schema info, GET vs POST for introspection
- **Batch queries:** `[{"query":"..."},{"query":"..."},...]` — bypass rate limiting, brute force in single request
- **Nested query DoS:** deeply nested relationships `{users{posts{comments{author{posts{comments...}}}}}}` — resource exhaustion
- **Alias-based attacks:** `{a1:user(id:1){secret} a2:user(id:2){secret} ...}` — mass IDOR in single query
- **Mutation abuse:** unauthorized mutations, mass assignment via mutation input types
- **Directive injection:** `@include(if:true)`, `@skip`, custom directives with side effects
- **Subscription abuse:** WebSocket-based subscriptions leaking real-time data without authz
- **SQL injection in resolvers:** `sort`, `filter`, `where` arguments passed to raw queries
- **CSRF on GraphQL:** mutations via GET (query string), or POST with `Content-Type: application/x-www-form-urlencoded`
- **Field suggestion information disclosure:** sending `{user{passw}}` → error says "Did you mean password?"

---

## WebSocket Attacks

- **Missing authentication:** WebSocket upgrade happens without auth, or auth checked only at handshake not per-message
- **Cross-site WebSocket hijacking (CSWSH):** `Origin` header not validated on upgrade — attacker's page opens WebSocket to target, inherits victim's cookies
- **Message injection:** if WebSocket messages are reflected or stored, inject XSS payloads, SQL queries, or command sequences
- **Smuggling through WebSocket:** after upgrade, tunnel arbitrary HTTP through the WebSocket connection past reverse proxy
- **No rate limiting on WebSocket messages:** brute force, DoS
- **Insecure deserialization of WebSocket messages:** JSON, MessagePack, protobuf with type confusion
- **Missing TLS:** `ws://` instead of `wss://` enables MITM
- **Socket.io specific:** event name injection, room/namespace authorization bypass, acknowledgment function abuse

---

## DNS Attacks

- **DNS rebinding:** attacker domain resolves to attacker IP (passes Same-Origin check), then TTL expires and re-resolves to `127.0.0.1` — browser sends authenticated requests to localhost
- **Subdomain takeover:** dangling CNAME/A records pointing to deprovisioned cloud resources (S3 buckets, Heroku, GitHub Pages, Azure, Shopify, Fastly, etc.) — attacker claims the resource, controls the subdomain
- **DNS cache poisoning:** inject false DNS records (less relevant for web app CTFs, but relevant for infrastructure challenges)
- **Zone transfer (AXFR):** misconfigured DNS server allows full zone download, revealing internal hostnames

---

## Container & Cloud-Specific Attacks

- **Docker socket exposure:** `/var/run/docker.sock` mounted in container → create new privileged container, mount host filesystem
- **Container escape:** `--privileged` flag → mount host devices, abuse cgroups; `CAP_SYS_ADMIN` → mount/remount; `CAP_NET_RAW` → ARP spoof
- **Kubernetes:** service account token at `/var/run/secrets/kubernetes.io/serviceaccount/token` → enumerate pods, secrets, exec into other containers
- **Cloud metadata SSRF:** AWS IMDSv1 at `169.254.169.254/latest/meta-data/iam/security-credentials/ROLE` → temporary AWS credentials
- **AWS-specific:** S3 bucket misconfiguration (public read/write/list), Lambda environment variable leakage, API Gateway bypass
- **GCP-specific:** metadata server at `metadata.google.internal`, service account key files, Cloud Functions source download
- **Azure-specific:** `169.254.169.254/metadata/identity/oauth2/token`, managed identity exploitation
- **Environment variable secrets:** dump env via SSRF, SSTI, debug endpoints, `/proc/self/environ`, `phpinfo()`
- **CI/CD pipeline attacks:** secrets in build logs, artifact poisoning, workflow injection

---

## OAuth / SSO — Advanced Attacks

### Mutable Claims Attack (Account Takeover)
Apps identify users by mutable fields (`email`, display name) instead of immutable `sub` claim. Attacker changes email on IdP to match victim's email on the relying party. Microsoft Azure AD allows user-controlled `email` modification; `Object ID` is immutable.

### Client Confusion Attack (Implicit Flow)
App fails to verify Access Token was issued for its Client ID. Attacker creates own OAuth app, collects legitimate users' tokens, replays them against vulnerable app that accepts tokens without audience validation.

### Scope Upgrade Attack
Authorization Server incorrectly accepts `scope` parameter in Access Token Request (token endpoint). Malicious app obtains code with limited scope, upgrades scope at token exchange.

### Redirect Scheme Hijacking (Mobile)
Multiple apps register identical custom URI schemes (e.g., `myapp://callback`). Malicious app intercepts redirect carrying authorization code. Defense: PKCE + App Links (Android `autoVerify` with `/.well-known/assetlinks.json`) + iOS Associated Domains.

### Device Code Phishing
Attacker initiates device code flow, socially engineers victim to authorize at `https://provider.com/device`.

### JWT — Expanded Attack Catalog

**Psychic Signature (CVE-2022-21449):** Java ECDSA — submit signature with `r=0, s=0` (Base64URL: `MAYCAQACAQA`). Affected JDK < 17.0.3, 11.0.15, 8u331. Any token accepted as valid.

**Embedded JWK (CVE-2018-0114):** attacker embeds own public key in token's `jwk` header. Server verifies signature using embedded key.

**JKU/X5U header abuse:** redirect to attacker-controlled key server. Bypass: file upload to trusted domain, open redirect chain, header injection.

**ECDSA key recovery:** two candidate public keys recoverable programmatically from a single ECDSA signature. Tool: `rsa_sign2n`.

**Audience (`aud`) confusion:** token issued for Service A replayed against Service B in same trust domain — exploitable when `aud` not validated per-service.

---

## Encoding & Parser Differential Attacks

- **Double encoding:** `%252e%252e%252f` → `%2e%2e%2f` → `../` — bypass WAF that decodes once but app decodes twice
- **Unicode normalization:** `ADMIN` (fullwidth) normalizes to `ADMIN`, `H` normalizes to `H`; case-folding differences between WAF and application
- **Overlong UTF-8:** `%c0%ae` for `.` — illegal but some parsers accept it
- **Charset confusion:** server declares `charset=utf-8` but parser handles `iso-8859-1` — different byte-to-character mapping
- **JSON parser differentials:** duplicate keys (first vs last wins), Unicode escapes (`\u0041` vs `A`), comments, trailing commas — one parser accepts what another rejects
- **HTTP header parsing differences:** proxy vs origin handle header folding, whitespace, duplicate headers differently
- **Multipart boundary confusion:** different parsers pick different boundaries, enabling parameter injection
- **Path normalization differences:** Windows (`\` vs `/`), IIS short filenames (`PROGRA~1`), URL-encoded path separators
- **Integer representation:** hex (`0x1A`), octal (`032`), scientific notation (`1e1`), leading zeros — different parsing across languages and functions
- **Null byte injection:** C-based string termination (`\0`) — PHP passes `%00` to C functions that truncate at null byte, while PHP string continues
- **Backslash normalization:** Java, .NET treat `\` as path separator on Windows but not Linux; URL `\` sometimes converted to `/`

---

## Regex Attacks (ReDoS & Bypass)

- **ReDoS (Regular Expression Denial of Service):** catastrophic backtracking in patterns like `(a+)+$`, `(a|a)+$`, `([a-zA-Z]+)*$` — exponential time with crafted input
- **Regex bypass:** backtracking abuse to bypass validation (input accepted by regex but malicious), anchoring issues (missing `^`/`$` allows payload around the match)
- **Line anchor bypass:** `^safe$` with multiline flag — inject `\nsafe\nmalicious`
- **Dot-star bypass:** `.` doesn't match `\n` by default — inject newlines to bypass patterns
- **Character class confusion:** `[a-z]` in some locales includes unexpected characters
- **Regex injection:** if user input is interpolated into regex pattern, inject `.*` or `()` for ReDoS or information extraction

---

## Dependencies & Supply Chain

- Known CVEs in dependency lock files (`package-lock.json`, `composer.lock`, `Gemfile.lock`, `requirements.txt`, `pom.xml`, `go.sum`, `Cargo.lock`)
- Outdated frameworks with public exploits
- Abandoned packages with unpatched vulns
- Dependency confusion / substitution attacks: private package name squatting on public registries
- Typosquatting: `loadsh` vs `lodash`, `reqeusts` vs `requests`
- Malicious post-install scripts in npm/pip packages
- Transitive dependency vulnerabilities (your deps' deps)
- Pinned to vulnerable version ranges
