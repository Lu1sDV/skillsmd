# Auth, Access Control & Logic Reference

## Authentication & Session

### Source Audit Targets
- Type juggling in password/token comparisons (loose `==` vs strict `===`)
- Mass assignment on user models (empty guarded, missing fillable)
- Predictable password reset tokens (rand, mt_rand, uniqid, microtime)
- JWT `alg:none`, HS256/RS256 confusion, weak signing keys, `kid` header injection (path traversal, SQLi, command injection in `kid`)
- JWT claim confusion: `sub` vs `email`, nested JWT, JWK/JKU header abuse
- Session fixation, missing session regeneration after login
- Hardcoded credentials in config, env files, source, Docker images
- Cookie flags: missing httponly, secure, samesite
- Username enumeration via differential error messages, response timing, or response size
- No rate limiting on login, OTP, password reset
- Password reset poisoning via `Host` header / `X-Forwarded-Host` manipulation
- Account takeover via email change without re-authentication / re-verification
- Token leakage via `Referer` header to third-party resources
- Insecure "remember me" tokens (predictable, not invalidated on password change)
- 2FA bypass: backup codes brute-force, race condition on code verification, missing 2FA enforcement on alternative login flows (API, mobile), response manipulation (change `"success":false` to `true`)
- Registration with existing email using different unicode normalization (e.g., `admin@I` normalizing to `admin@i`)
- Null password / empty password bypass
- PHP `strcmp()` bypass with array input: `password[]=` → `strcmp(array, string)` returns `NULL`

### JWT — Expanded Attack Catalog

| Attack | Technique | Impact |
|--------|-----------|--------|
| **Signature bypass** | App uses `decode()` instead of `verify()` | Full token forgery |
| **alg:none** | Set `"alg": "none"` (+ case variations: `None`, `NONE`, `nOnE`) | Token without signature accepted |
| **Weak HMAC brute-force** | Offline: `HMAC(candidate, header+payload)` vs known sig | Forge tokens with cracked secret |
| **RSA-to-HMAC (RS256→HS256)** | Sign with server's RSA public key as HMAC secret | Full auth bypass |
| **ECDSA-to-HMAC (ES256→HS256)** | Two candidate public keys recoverable from single ECDSA sig | Full auth bypass |
| **kid path traversal** | `"kid": "../../../../dev/null"` — signs with empty string | Token forgery |
| **kid SQLi** | `"kid": "x' UNION SELECT '123' --"` — returns attacker key | Token forgery |
| **Embedded JWK (CVE-2018-0114)** | Embed own public key in `jwk` header — server uses it to verify | Full auth bypass |
| **JKU/X5U abuse** | Redirect to attacker-controlled key server | Full auth bypass |
| **Psychic Signature (CVE-2022-21449)** | Java ECDSA: `r=0, s=0` → any token valid. JDK < 17.0.3, 11.0.15, 8u331 | Universal bypass |
| **Audience confusion** | Token for Service A replayed against Service B in same trust domain | Cross-service access |
| **Nested JWT** | Outer JWE encryption stripped, server falls back to inner JWS | Encryption bypass |

**Tools:** jwt_tool, Hashcat mode 16500, rsa_sign2n (ECDSA key recovery), wallarm/jwt-secrets wordlist, Burp JWT Editor

---

## Access Control

### Source Audit Targets
- Missing auth middleware on routes
- IDOR via sequential/predictable IDs without ownership checks
- Horizontal privilege escalation (user A accessing user B data)
- Vertical privilege escalation (user accessing admin functions)
- Admin-only actions without role verification
- API endpoints without authentication
- GraphQL introspection exposing internal schema and mutations
- HTTP method/verb tampering: `GET` works where only `POST` is checked, `PUT`/`PATCH`/`DELETE` unprotected
- Path normalization bypass: `/admin/../admin`, `/./admin`, `//admin`, `/admin;param`, URL-encoded paths (`%2Fadmin`)
- Case sensitivity mismatch: `/Admin` vs `/admin` bypassing case-sensitive ACL with case-insensitive routing
- Parameter pollution: `?role=user&role=admin` — which wins depends on framework
- JSON parameter injection: sending `{"role":"admin"}` in request body alongside form data
- Force browsing: directly accessing `/admin/dashboard`, `/api/v1/internal/*`, `/debug/*`
- Referrer-based access control (trivially spoofed)
- IP-based access control bypass via `X-Forwarded-For`, `X-Real-IP`, `X-Original-URL`, `X-Rewrite-URL`
- Hop-by-hop header abuse: inject `Connection: X-Custom-IP-Authorization` — proxy strips the authorization header before it reaches backend, or inject `X-Custom-IP-Authorization: 127.0.0.1` that reaches backend when proxy doesn't strip it
- Common IP authorization headers to test: `X-Custom-IP-Authorization`, `X-Originating-IP`, `True-Client-IP`, `CF-Connecting-IP`, `X-Client-IP`, `Forwarded`, `X-Forwarded`, `X-Cluster-Client-IP`
- Nginx `$uri` vs `$request_uri` leading to ACL bypass with encoded chars
- GraphQL: batch queries to bypass rate limiting, mutation without authz, nested relationship traversal leaking data
- REST API mass assignment: sending `isAdmin: true` in profile update
- Insecure direct object reference via UUID guessing (v1 UUIDs contain timestamp + MAC)

### Mass Assignment Sinks by Framework

| Framework | Vulnerable Pattern | Safe Pattern |
|-----------|-------------------|--------------|
| Rails | `User.new(params[:user])` without `permit()` | `params.require(:user).permit(:name, :email)` |
| Django | `User(**request.POST.dict())` | Explicit field assignment or serializer with `fields` |
| Spring | `@ModelAttribute User user` binding all fields | `@InitBinder` with `setAllowedFields()` |
| Laravel | Empty `$guarded` or missing `$fillable` | `$fillable = ['name', 'email']` |
| Mongoose | `new User(req.body)` | Schema-level `select: false` + explicit fields |
| Express | `Object.assign(user, req.body)` | Destructure only allowed fields |

Impact: attackers set `is_admin=true`, `role=admin`, `email_verified=true`, `password=attacker_value`.

### Java Matrix Parameter ACL Bypass

Java frameworks (Spring, Tomcat) parse `;param=value` as matrix parameters, stripping them from the path for routing:
- `/admin;foo=bar` → routed to `/admin` handler
- Path-based ACL checks literal string `/admin;foo=bar` — doesn't match `/admin` rule → access granted
- **Affected:** Spring Security path matchers, Apache Tomcat, custom servlet filters using `getRequestURI()` (includes matrix params) vs `getServletPath()` (strips them)
- **Bypass:** `/admin;.css` may bypass both ACL (doesn't match `/admin`) and cache rules (ends in `.css`)

### mTLS Authentication Logic Flaws

Client certificate validation that checks certificate validity but not authorization:
- Server verifies certificate is cryptographically valid and not expired
- **Missing:** verification that the certificate's subject/CN/SAN matches an authorized identity
- Any valid client certificate (including self-signed if trust store is misconfigured) is accepted regardless of identity
- **Common in:** API gateways, service mesh (Istio/Linkerd), microservice-to-microservice authentication

---

## OAuth / SSO Attacks

- **Open redirect in redirect_uri:** steal authorization code via `redirect_uri=https://legit.com.attacker.com` or path traversal
- **redirect_uri bypass techniques:** subdomain matching (`*.legit.com`), path bypass (`/callback/../attacker`), parameter injection, fragment handling differences
- **Missing state parameter:** CSRF → attacker links their OAuth account to victim's session
- **Authorization code replay:** code used more than once, or stolen via referrer/logs
- **Token leakage:** access token in URL fragment leaked via Referrer header, browser history, logs
- **Scope escalation:** request elevated scopes after initial limited authorization
- **IdP confusion:** mix identity providers to impersonate users across services
- **SAML signature wrapping (XSW):** move signed assertion to unsigned position, insert attacker-controlled assertion where the application reads it
- **SAML comment injection:** `admin@evil.com<!---->.legit.com` → NameID parsed as `admin@evil.com` by SP but validated against `legit.com` by IdP (after comment removal)
- **SAML assertion replay:** if assertion lacks audience restriction or timestamp check, replay captured assertion to authenticate as victim
- **SAML signature exclusion:** strip the `<Signature>` element entirely — SP authenticates without verifying signature if it doesn't enforce signature presence

### Dirty Dancing — OAuth Account Hijacking via URL-Leak Gadgets (2022)

Frans Rosén's research shows that referrer-stripping mitigations in modern browsers can be bypassed through chaining multiple low-severity URL-leak gadgets for OAuth account takeover.

**Attack chain:**
1. Victim initiates OAuth login to target app
2. Referrer header leaks OAuth `state` or `code` parameter via cross-site navigation
3. Third-party XSS on any URL-leak gadget (postMessage, `window.referrer`, URL storage) intercepts the OAuth tokens
4. Attacker uses leaked token to complete OAuth flow → account takeover

**URL-leak gadgets observed:**
- `postMessage` receivers that echo `event.origin` or `event.source.location.href`
- URL storage in analytics scripts (GA, Facebook Pixel storing current URL)
- Image loading with URL-parameter reflection in error URLs
- `window.open()` return values navigated cross-origin
- Browser extensions that expose current tab URL via API

**Key insight:** These gadgets individually are Low/Informational severity. Chained with OAuth, they become Critical. Modern referrer-stripping (Cross-Origin-Request-Policy, Referrer-Policy) helps but doesn't eliminate all leak paths.

Source: Frans Rosén / Detectify, PortSwigger Top 10 Web Hacking Techniques of 2022 #1.

### OAuth Non-Happy Path — Referer-Based ATO (2024)

Oxrz's research chains a Referer header manipulation with OAuth flow behavior for account takeover.

**Mechanism:**
1. OAuth authorization redirect respects `Redirect URI` registered with IdP
2. Application trusts `Referer` header for post-login redirect destination
3. Attacker crafts login URL where `Referer` points to attacker-controlled page
4. After authorization, IdP redirects to app's callback which uses `Referer` to determine next page
5. OAuth `code` or `state` leaks via Referer to attacker domain
6. Attacker completes OAuth flow → ATO

**Key insight:** Application validates the OAuth redirect URI against the IdP registration, but the *post-login redirect* uses the Referer header (or a Referer-derivative) which is attacker-influenced.

Source: Oxrz / voorivex.team, PortSwigger Top 10 Web Hacking Techniques of 2024 #8.

### Hidden OAuth Attack Vectors — Spec-Diving for Undocumented Endpoints (2021)

Michael Stepankin's deep dive into OAuth and OpenID specifications reveals hidden endpoints and design flaws that enable enumeration, session poisoning, and SSRF.

**Undocumented endpoints discovered:**
- `/.well-known/oauth-authorization-server` — schema differences between implementations leak server info
- `/oauth2/device_authorization` — device code flow endpoints often unthrottled
- `/oauth2/sessions` — session management endpoints exposed without auth
- `/oauth2/keys` — JWKS endpoints leaking key rotation patterns

**Design flaw exploitation:**
1. OAuth `claims` parameter: `claims={"id_token":{"email":{"essential":true}}}` — returns user email in ID token even when scope doesn't include it
2. `request` parameter passing JWT with embedded request object → signature verification bypasses
3. `request_uri` parameter → SSRF via OAuth authorization request (server fetches the request object from attacker URL)

**Detection:**
- Use ActiveScan++ (updated wordlists) to fuzz OAuth `.well-known` endpoints
- Test all OAuth grant types against the authorization server, not just the intended flow
- Examine `claims`, `request`, and `request_uri` parameter behavior

Source: Michael Stepankin / PortSwigger Research, PortSwigger Top 10 Web Hacking Techniques of 2021 #5.

### Ticket Trick — Cross-System Helpdesk Trust Abuse (2017)

Inti De Ceukelaire's technique exploits implicit trust between issue trackers and the systems they integrate with — each system is secure in isolation but compromised when combined.

**Mechanism:**
1. Target company uses a helpdesk/ticketing system that trusts email domain for authentication
2. Attacker registers email address at a subdomain the company owns: `anything@company-org.atlassian.net`
3. Helpdesk sees `@company-org.atlassian.net` and grants employee-level access
4. Attacker accesses internal tickets, customer data, and integrated systems

**Why it works:**
- Issue trackers (Zendesk, Freshdesk, Jira Service Desk) authenticate users by email domain
- Many accept subdomains of the primary domain as valid proof of affiliation
- The trust boundary is the email domain, but the company doesn't control subdomains on SaaS platforms
- Independent systems (email, helpdesk, SSO) are each secure — the vulnerability emerges from their combination

**Affected systems:** Zendesk, Freshdesk, Atlassian, Salesforce Desk, and any helpdesk using email-domain-based authentication.

**Defense:** Helpdesks should verify domain ownership (DNS TXT records) and not accept subdomain-of-trusted-domain as proof.

Source: Inti De Ceukelaire / Intigriti, PortSwigger Top 10 Web Hacking Techniques of 2017 #3.

### SAML Implementation Weaknesses — Expanded

**Self-signed certificate acceptance (Zscaler-style, CVE-2025-54982):**
- SP accepts SAML assertions signed with any certificate (including attacker-generated self-signed certs)
- Attacker forges entire SAML assertion with victim's NameID, signs with own key
- SP validates signature cryptographically (it's valid!) but doesn't verify the signing certificate is from the trusted IdP
- Root cause: SP validates signature math but not certificate chain/thumbprint

**XML canonicalization attacks:**
- Different XML canonicalization methods (C14N, exc-C14N) handle whitespace, namespaces, and comments differently
- Attacker inserts content in areas that get removed by canonicalization before signing but preserved by the SP's XML parser
- Related: XML signature wrapping (XSW) with 8+ known variants (XSW1-XSW8)

**NameID format confusion:**
- IdP sends `email` format NameID but SP interprets as `persistent` identifier
- Attacker registers `admin@attacker.com` on IdP, SP maps `admin` as username

**Clock skew exploitation:**
- SP allows generous `NotBefore`/`NotOnOrAfter` window (often 5-10 minutes)
- Replay captured assertions within the validity window
- Some SPs don't check `NotOnOrAfter` at all

### SAML Parser Differential Attacks

Different XML libraries parse SAML assertions differently (libxml2 vs Java DOM vs .NET System.Xml). Craft assertions that validate on the IdP's parser but extract different identity on the SP's parser.

**Variants:**
- **Namespace prefix confusion:** different parsers resolve namespace prefixes differently — signature covers one interpretation, SP reads another
- **Comment injection in NameID:** `admin@evil.com<!--comment-->@legit.com` — some parsers strip comments before evaluation, others after
- **XML canonicalization differential:** C14N vs exc-C14N handle whitespace, namespaces, and comments differently — content removed by canonicalization before signing is preserved by SP's parser
- **XSW (XML Signature Wrapping) variants 1-8:** move signed assertion to unsigned position, insert attacker-controlled assertion where SP reads it

### Silver SAML

Compromise of the SAML signing certificate from AD FS or similar IdP infrastructure. With the signing key:
1. Forge arbitrary SAML assertions for any user
2. All federated services trust the forged assertions
3. Persistent access — survives password resets, MFA changes
4. **Detection:** monitor for SAML assertions signed with the same key but from unexpected sources; rotate signing certificates regularly

### WebAuthn Credential Binding Swap

Race condition during WebAuthn registration flow:
1. Victim initiates `navigator.credentials.create()` for their account
2. Attacker races to swap the credential public key between the browser's creation response and server verification
3. Server binds attacker's authenticator to victim's account
4. Attacker can now authenticate as victim using their own FIDO2 key

**Conditions:** server doesn't bind the challenge to a specific session atomically, or registration endpoint lacks proper CSRF protection.

### Okta bcrypt 72-Byte Truncation (CVE-2024-56167)

bcrypt truncates input at 72 bytes. Okta's authentication combined `username + delimiter + password` before hashing. If username ≥ 52 characters, the password portion is truncated or absent from the hash → authentication succeeds with **any password**.

**Impact:** Targeted account takeover for users with long usernames (email addresses with long domain names).

### Okta FastPass Phishing Bypass

Authentication flow manipulation in Okta Verify FastPass — skip device verification step via direct API request modification. Attacker intercepts the FastPass flow and modifies the authentication response to bypass the device binding check, completing authentication without possessing the registered device.

- **PKCE bypass:** downgrade from S256 to plain, or strip `code_verifier` entirely
- **Client secret exposure:** in mobile apps, SPAs, JavaScript bundles, `.env` files in public repos
- **Token substitution:** swap tokens between different OAuth clients to access unauthorized resources
- **Silent token refresh:** iframe-based silent auth with prompt=none for session riding
- **Mutable claims attack (account takeover):** apps identify users by mutable `email` instead of immutable `sub` claim — attacker changes email on IdP to match victim's email on relying party (Microsoft Azure AD `email` is user-controlled, `Object ID` mapped to `sub` is immutable)
- **Client confusion attack (implicit flow):** app fails to verify Access Token was issued for its Client ID — attacker creates own OAuth app, collects users' tokens, replays against vulnerable app
- **Scope upgrade attack:** AS incorrectly accepts `scope` parameter at token endpoint — malicious app upgrades scope when exchanging code for token
- **Redirect scheme hijacking (mobile):** multiple apps register identical custom URI schemes (`myapp://callback`) — malicious app intercepts authorization code; defense: PKCE + App Links (`autoVerify` + `/.well-known/assetlinks.json`)
- **Device code phishing:** attacker initiates device code flow, socially engineers victim to authorize at `https://provider.com/device`
- **redirect_uri bypass techniques expanded:** subdomain matching (`*.legit.com`), path bypass (`/callback/../attacker`), regex misconfiguration (`evil.com.example.com`), origin-only validation (checks domain not path)

### OAuth redirect_uri Bypass Patterns (Detailed)

| # | Pattern | Bypass Technique | Example |
|---|---------|-----------------|---------|
| 1 | `startsWith()` check | Append `../` or path traversal | `https://legit.com/callback/../attacker.com` |
| 2 | Hostname-only validation (no pathname) | Append arbitrary path | `https://legit.com/callback/../../attacker-controlled-path` |
| 3 | `fallback_redirect_uri` parameter | Some OAuth implementations accept a secondary redirect param when primary fails | `?redirect_uri=https://legit.com&fallback_redirect_uri=https://attacker.com` |
| 4 | Redirect from cookie | App reads redirect destination from cookie instead of `redirect_uri` param — cookie tossing from subdomain overwrites it | Set cookie `redirect=https://attacker.com` via subdomain XSS |
| 5 | `response_type=token` chain | Implicit flow puts token in fragment — combine with open redirect on `redirect_uri` domain to leak fragment to attacker | `redirect_uri=https://legit.com/open-redirect?url=https://attacker.com` |
| 6 | HTTP Parameter Pollution | `redirect_uri=https://legit.com&redirect_uri=https://attacker.com` — validator checks first, server uses last (or vice versa) | Framework-dependent: PHP uses last, ASP.NET uses first |
| 7 | Login CSRF as chain enabler | CSRF on login endpoint → force victim to authenticate as attacker → OAuth flow binds victim's IdP to attacker's session | Missing `state` param + login CSRF = ATO via OAuth binding |

**Key insight:** `redirect_uri` validation is a string matching problem with dozens of edge cases. Validators that do anything less than exact string comparison (===) are likely bypassable. Test all 7 patterns against any OAuth implementation.

### IPv6 Multi-@ Userinfo OAuth Redirect Bypass

IPv6 URL syntax combined with multi-`@` userinfo creates parser differentials:
- `https://attacker.com@[::1]/callback`
- OAuth validator parses host as `[::1]` (loopback — whitelisted)
- Browser interprets first `@` as userinfo delimiter → routes to `attacker.com`
- Authorization code exfiltrated to attacker infrastructure

**Variants:**
- `https://attacker.com%40[::1]/callback` (URL-encoded `@`)
- `https://user:pass@attacker.com@[::1]/callback` (nested userinfo)
- Combine with IPv6 zone ID: `https://attacker.com@[fe80::1%25lo]/callback`

### OAuth Device Code Phishing — Real-World Campaigns

**ShinyHunters / UNC6040 (2024-2025):** Large-scale campaign exploiting the OAuth 2.0 Device Authorization Grant:
1. Attacker initiates device code flow with Microsoft/Google, receives `device_code` + `user_code`
2. Phishing email or message instructs victim to visit `microsoft.com/devicelogin` and enter the user code
3. Victim authenticates normally on the legitimate provider's page — no credential theft, no fake login page
4. Attacker polls token endpoint with `device_code` and receives victim's access token + refresh token
5. Refresh token provides persistent access even after password change

**Why it works:**
- Victim interacts only with legitimate OAuth provider pages (not phishing)
- Device code flow designed for input-constrained devices (TVs, IoT) — no redirect_uri validation
- Most users don't recognize that authorizing a "device" grants token access
- Refresh tokens often have long/infinite lifetime

**Detection indicators:**
- Unusual device code flow requests from non-device user agents
- Token grants from device flow for users who don't use input-constrained devices
- Bulk device code requests from same IP

---

## Logic & Race Conditions

- CSRF on state-changing endpoints
- Race conditions on financial operations, coupon redemption, voting, inventory management
- Business logic: negative quantities, price manipulation, workflow step skipping, currency rounding abuse
- Integer overflow/underflow (especially in C-backed extensions, 32-bit systems)
- Double-spend / double-claim via concurrent requests (use threading/async to send N requests simultaneously)
- **HTTP/2 Single-Packet Attack:** send all parallel requests in a single TCP segment, eliminating network jitter and achieving true simultaneous server processing (~90% success rate vs ~5% with HTTP/1.1 for limit-overrun attacks). HTTP/1.1 equivalent: last-byte synchronization — send all but the last byte of N parallel requests, then flush final byte across all connections simultaneously. Tool: Turbo Intruder with `THREADED` engine. WebSocket variant: Turbo Intruder THREADED mode on N simultaneous WS connections.

### Race Condition Exploitation Patterns

**Limit-overrun:** Send N identical requests simultaneously to bypass server-side limits (coupon redemption, transfer, vote). Single-packet attack achieves ~1ms spread across 20-30 requests vs ~30ms with last-byte sync.

**Multi-endpoint races:** Different endpoints that read-then-write the same resource:
- `/transfer` + `/withdraw` on same balance
- `/apply-coupon` + `/checkout` (apply coupon after price calculated)
- `/update-email` + `/send-reset` (change email between check and send)

**Sub-state exploitation:** Attack the brief window (~1ms) when a single request transitions through intermediate states:
- Password reset: token generated → stored → email sent (race between token generation and sending)
- File upload: file written → validation → move/delete (access file before validation completes)
- Account creation: user created → role assigned (access with default/no role)

**Time-sensitive verification bypass:** Rate limits that use `timestamp > last_attempt + delay` — single-packet attack sends all requests at same timestamp, all pass the check.

- Missing idempotency on critical operations
- Time-of-check to time-of-use (TOCTOU) generalized across all resource types
- Inconsistent state across microservices: operation succeeds on service A, fails on service B, no rollback
- Replay attacks: capture and replay valid requests (lacking nonce/timestamp verification)
- Numeric precision attacks: floating point rounding in financial calculations, `0.1 + 0.2 != 0.3` edge cases
- Sign confusion: negative values bypassing minimum checks but interpreted as large positive in unsigned context
- Null/empty string vs missing parameter: different behavior paths
- Default deny vs default allow misconfiguration
- Workflow bypass: skip email verification by directly calling the post-verification endpoint
- Coupon / promo code stacking: apply multiple discounts that shouldn't combine
- Quantity manipulation in multi-step checkout: change quantity after price calculation but before payment
- Refund logic abuse: partial refunds exceeding original amount, refunding to different payment method

---

## Cryptography

- Weak hashing (MD5, SHA1 for passwords — use hashcat/john for cracking)
- Hardcoded encryption keys / IVs (search source, config files, Docker images)
- ECB mode usage (block patterns visible, block shuffling attacks)
- CBC padding oracle (decrypt ciphertext byte-by-byte via error oracle)
- CBC bit-flipping: XOR bits in ciphertext block N to alter plaintext block N+1
- Insecure random for security-sensitive values (PHP `rand()`, `mt_rand()`, Python `random`, Java `java.util.Random` — all predictable)
- Hash length extension attacks (MD5, SHA1, SHA256 — `secret||message||padding||attacker_data` produces valid hash without knowing secret; use `hashpumpy` / `hash_extender`)
- Known-plaintext in custom crypto schemes
- PRNG state recovery: Mersenne Twister state recoverable from 624 outputs, PHP `mt_rand()` seed brute-force (only 2^32 seeds)
- Nonce reuse in AES-GCM: recovers authentication key, enables forgery and decryption
- Key reuse in stream ciphers (XOR two ciphertexts → XOR of plaintexts → crib dragging)
- Bleichenbacher's attack on RSA PKCS#1 v1.5 padding
- Timing side-channels in comparison: non-constant-time `==` leaks string length and prefix matches
- Downgrade attacks: force negotiation of weaker cipher/protocol
- Custom crypto = broken crypto: always suspect hand-rolled encryption schemes
- Hash collision attacks: MD5 chosen-prefix collisions (practical), SHA1 collisions (SHAttered)
- Compression side-channels: CRIME (TLS compression), BREACH (HTTP compression) — response size reveals secret overlap with attacker-controlled input
- Elliptic curve parameter confusion: invalid curve attacks, point not on curve
- Symmetric key derivation from low-entropy input (password-based without proper KDF like bcrypt/scrypt/argon2)
- Format confusion: signing raw bytes vs JSON vs canonical form (same data, different representations, different signatures)
- **PCRE backtracking bypass (PHP):** send >1MB payload to exceed `pcre.backtrack_limit` causing `preg_match()` to return `false` instead of `0` — bypasses regex-based input validation
- **Widechar bypass (MySQL/PHP):** GBK encoding `%df'` eats the backslash from `addslashes()` — SQLi despite escaping
