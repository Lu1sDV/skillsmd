---
name: oauth-audit
description: >-
  Use when auditing OAuth 2.0 / OIDC implementations against RFC 9700 (OAuth
  Security BCP), reviewing client or authorization-server code, evaluating
  PKCE / state / redirect-URI handling, hardening token exchange and refresh
  flows, or triaging suspected OAuth vulnerabilities (CWE-352 CSRF, CWE-287
  broken auth).
---

# OAuth 2.0 / OIDC Security Audit

Formal review workflow for OAuth 2.0 and OpenID Connect implementations. Maps every finding to a normative source (RFC 9700 §, OWASP, CWE) and produces a severity-rated report — not a generic "best practices" summary.

## Quick Reference

| What | Details |
|------|---------|
| **Primary spec** | [RFC 9700](https://www.rfc-editor.org/rfc/rfc9700.txt) — OAuth 2.0 Security Best Current Practice (Jan 2025) |
| **Adjacent specs** | RFC 6749 (core), RFC 6750 (bearer), RFC 7636 (PKCE), RFC 9207 (`iss` mix-up), RFC 8414 (AS metadata), RFC 7009 (revocation) |
| **OWASP** | A07:2025 Authentication Failures, A01:2025 Broken Access Control |
| **CWE** | CWE-352 (CSRF), CWE-287 (broken auth), CWE-601 (open redirect), CWE-384 (session fixation) |
| **Deprecated grants** | Implicit (`response_type=token`), Resource Owner Password Credentials |
| **Always required for public clients** | PKCE with `S256` (never `plain`) |
| **Mix-up defence** | RFC 9207 `iss` parameter or per-AS distinct redirect URIs |

## When to Use

- Reviewing an OAuth/OIDC client integration (login-with-Google/GitHub/Azure, mobile, SPA, CLI)
- Auditing an authorization-server or resource-server implementation
- Triaging a suspected OAuth-related vulnerability or incident
- Hardening token storage, refresh-token rotation, or scope handling
- Pre-launch security gate before exposing a new OAuth client publicly

**When NOT to use:**
- Pure session-cookie auth without OAuth — use a generic auth-review skill
- SAML / WS-Fed federation — different spec family
- API-key / HMAC-signed request auth — out of scope

## Prerequisites

- Read access to the codebase implementing the OAuth flow
- Knowledge of which provider(s) are integrated and the registered redirect URIs
- For AS audits: access to AS configuration / metadata endpoint
- Authorisation to review the system (internal review or signed engagement)

## Workflow

Produce a severity-rated finding report mapped to RFC 9700 sections, OWASP Top 10, and CWE. Keep `SKILL.md` as the operating workflow; load [`references/jwt-security.md`](references/jwt-security.md) only when JWT signature, key-selection, token-purpose, cookie, or claim-validation depth is needed.

### 1. Scope the Review

Before reading any code, establish:

- **Role under review**: client, authorization server, resource server, or combination
- **Client type**: public (SPA, mobile, native, CLI — *cannot* keep a secret) or confidential (server-side with stored secret)
- **Grant types in use**: authorization code, authorization code + PKCE, client credentials, device code, refresh token. Flag implicit / ROPC immediately as findings.
- **Provider trust model**: single AS, multiple AS, federated, BYO-IDP
- **Token surfaces**: where access tokens, ID tokens, and refresh tokens are stored, transmitted, and logged

Record this in the report header — every finding must be evaluated against this scope.

### 2. Locate the OAuth Surface

Identify in the codebase:

- Authorization request construction (where `response_type`, `state`, `code_challenge`, `scope` are assembled)
- Redirect URI registration list and runtime validation
- Callback / token-exchange endpoint
- Token storage (memory, cookie, localStorage, server session, DB)
- Refresh-token rotation / revocation logic
- ID-token signature, `iss`, `aud`, `nonce`, and `exp` validation
- Logout / revocation calls to the AS

Use grep patterns: `state=`, `code_challenge`, `redirect_uri`, `Bearer `, `localStorage.*token`, `id_token`, `jwks`, `client_secret`.

### 3. Evaluate Against the Checklist

Load [`references/audit-checklist.md`](references/audit-checklist.md) for the detailed checklist, rating rubric, BAD/GOOD state example, report template, and common audit mistakes. Apply the checklist IDs exactly and cite every finding with code location plus RFC/CWE/OWASP references.

### 4. Report

Use the report template in [`references/audit-checklist.md`](references/audit-checklist.md). No finding is complete without: checklist ID, code location, RFC section, and CWE or OWASP mapping.

## Hand-offs

- For **JWT signature / claim validation depth** (alg confusion, `kid`/JWKS handling, claim validation, token-purpose confusion, cookie hardening, lifetime), load [`references/jwt-security.md`](references/jwt-security.md). Treat it as a heuristic pattern catalog; final OAuth findings still need the required RFC/CWE/OWASP citation from this skill's report rules.
- For **session-fixation, cookie security, CSRF on non-OAuth endpoints**, hand off to a generic web-auth review.
- For **SSRF in token-introspection / JWKS-fetch**, hand off to `ssrf-testing`.
- For **broader OWASP Top 10 sweep**, hand off to a general security-review skill — this skill is OAuth-only by design.

## References

- [RFC 9700 — OAuth 2.0 Security Best Current Practice](https://www.rfc-editor.org/rfc/rfc9700.txt)
- [RFC 6749 — OAuth 2.0 Authorization Framework](https://www.rfc-editor.org/rfc/rfc6749)
- [RFC 7636 — PKCE](https://www.rfc-editor.org/rfc/rfc7636)
- [RFC 9207 — `iss` parameter for mix-up defence](https://www.rfc-editor.org/rfc/rfc9207)
- [RFC 8252 — OAuth 2.0 for Native Apps](https://www.rfc-editor.org/rfc/rfc8252)
- [OWASP OAuth Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/OAuth_Cheat_Sheet.html)
- [OWASP Top 10 A07:2025 — Authentication Failures](https://owasp.org/Top10/2025/A07_2025-Authentication_Failures/)
- [PortSwigger — OAuth 2.0 Authentication Vulnerabilities](https://portswigger.net/web-security/oauth)
- [CWE-352 CSRF](https://cwe.mitre.org/data/definitions/352.html), [CWE-287 Improper Authentication](https://cwe.mitre.org/data/definitions/287.html), [CWE-601 Open Redirect](https://cwe.mitre.org/data/definitions/601.html)
