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
