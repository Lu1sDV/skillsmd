# OAuth Audit Checklist and Report Template

### 3. Evaluate Against the Checklist

Walk the checklist in sequence. Rate each applicable item:

| Symbol | Meaning |
|--------|---------|
| ✅ | Compliant — requirement satisfied |
| ⚠️ | Partial — met with caveats / gaps |
| ❌ | Non-compliant — violated or missing |
| ➖ | N/A — does not apply to this role/type |
| ❓ | Unknown — cannot determine from inspection |

Mark every ❌ on a `MUST` / `MUST NOT` requirement as **Critical**. Every ❌ on `SHOULD` is **High** unless context downgrades it.

#### Deprecated Grants (D)
| # | Requirement | Level | RFC § |
|---|---|---|---|
| D1 | Resource Owner Password Credentials grant not used | MUST NOT | 2.4 |
| D2 | Implicit grant (`response_type=token`) not used | SHOULD NOT | 2.1.2 |

#### Redirect URI (R)
| # | Requirement | Level | RFC § |
|---|---|---|---|
| R1 | AS performs **exact string match** on registered redirect URIs (no wildcards / patterns) | MUST | 4.1 |
| R2 | Client endpoints are not open redirectors | MUST NOT | 4.11 |
| R3 | No HTTP scheme for authorization responses (loopback `http://127.0.0.1` allowed for native) | MUST NOT | 2.1 |
| R4 | AS rejects unknown `client_id` / `redirect_uri` *without* auto-redirecting | MUST NOT | 4.11 |
| R5 | No `http://localhost` matched by string when port varies (use loopback rule, not literal match) | MUST | RFC 8252 §7.3 |

#### CSRF & State (C)
| # | Requirement | Level | RFC § |
|---|---|---|---|
| C1 | Client uses PKCE, OIDC `nonce`, OR one-time `state` (one of the three) | MUST | 4.7 |
| C2 | `state` is cryptographically random (≥128 bits / `secrets.token_urlsafe(32)` equivalent) | MUST | 4.2.4 |
| C3 | `state` is invalidated after first use (single-use, not just compared) | SHOULD | 4.2.4 |
| C4 | `state` comparison uses constant-time equality (e.g. `hmac.compare_digest`) | SHOULD | 4.2.4 |

#### PKCE (P)
| # | Requirement | Level | RFC § |
|---|---|---|---|
| P1 | Public clients implement PKCE | MUST | 2.1.1 |
| P2 | Confidential clients implement PKCE | SHOULD | 2.1.1 |
| P3 | AS supports PKCE for all clients | MUST | 2.1.1 |
| P4 | AS enforces `code_verifier` whenever `code_challenge` was sent | MUST | 4.8 |
| P5 | AS rejects `code_verifier` when no `code_challenge` was sent (downgrade) | MUST | 4.8 |
| P6 | `code_challenge_method=S256` (never `plain`) | SHOULD | 2.1.1 |
| P7 | `code_verifier` is per-transaction and bound to the user agent | MUST | 2.1.1 |

#### Authorization Code Handling (A)
| # | Requirement | Level | RFC § |
|---|---|---|---|
| A1 | Authorization codes invalidated after first use | MUST | 4.2.4 |
| A2 | On code-replay, all tokens issued from that grant are revoked | SHOULD | 4.2.4 |
| A3 | OIDC clients validate `nonce` in ID Token | MUST | 2.1.1 |
| A4 | ID Token `iss`, `aud`, `exp`, signature all validated before trust | MUST | OIDC Core §3.1.3.7 |

#### Tokens (T)
| # | Requirement | Level | RFC § |
|---|---|---|---|
| T1 | Sender-constrained access tokens (mTLS / DPoP) where supported | SHOULD | 2.2 |
| T2 | Access tokens scoped to least privilege | SHOULD | 2.3 |
| T3 | Access tokens audience-restricted to a specific RS | SHOULD | 2.3 |
| T4 | Tokens never passed in URL query parameters or fragments | MUST NOT | 2.2 |
| T5 | Tokens never logged (access logs, error logs, telemetry) | MUST | 2.2 |
| T6 | Access tokens not stored in `localStorage` / `sessionStorage` (XSS-reachable) | SHOULD | 2.2 |

#### Refresh Tokens (RT)
| # | Requirement | Level | RFC § |
|---|---|---|---|
| RT1 | Public-client refresh tokens are sender-constrained OR rotated | MUST | 2.2 |
| RT2 | Refresh tokens bound to scope and resource server | MUST | 2.2 |
| RT3 | Replay of an already-rotated refresh token revokes the entire token family | MUST | 2.2 |
| RT4 | Refresh tokens stored server-side, never exposed to the browser | SHOULD | 2.2 |
| RT5 | Logout calls the AS revocation endpoint (RFC 7009) | SHOULD | RFC 7009 |

#### Client Authentication (CA)
| # | Requirement | Level | RFC § |
|---|---|---|---|
| CA1 | Confidential clients authenticate to the token endpoint | SHOULD | 2.5 |
| CA2 | Asymmetric methods preferred (mTLS, `private_key_jwt`) over `client_secret` | RECOMMENDED | 2.5 |
| CA3 | Client secrets not committed to source control or shipped to the browser | MUST | 2.5 |

#### Mix-Up & Multi-AS (M)
| # | Requirement | Level | RFC § |
|---|---|---|---|
| M1 | Clients accepting multiple AS verify `iss` (RFC 9207) OR use distinct redirect URIs per AS | MUST | 4.4 |
| M2 | `state` is bound to the intended AS | SHOULD | 4.4 |

#### Transport & Headers (TH)
| # | Requirement | Level | RFC § |
|---|---|---|---|
| TH1 | End-to-end TLS for all OAuth endpoints | RECOMMENDED | 2.6 |
| TH2 | Reverse proxies sanitise inbound security headers | MUST | 4.13 |
| TH3 | No HTTP 307 / 308 redirects that forward credentials | MUST NOT | 4.12 |
| TH4 | `Referrer-Policy: no-referrer` on authorization endpoints | RECOMMENDED | 4.2 |
| TH5 | No third-party scripts/resources on AS authorization pages | SHOULD NOT | 4.2 |

#### Browser-Specific (B)
| # | Requirement | Level | RFC § |
|---|---|---|---|
| B1 | `postMessage` handlers strictly verify `origin` and `source` | MUST | 4.17 |
| B2 | AS authorization endpoint does not enable CORS | MUST NOT | 2.6 |
| B3 | Token endpoint MAY enable CORS for direct-access flows | MAY | 2.6 |

#### Identity / Account-Linking (I)
| # | Requirement | Level | Source |
|---|---|---|---|
| I1 | `sub` claim namespaced by issuer (`google\|123` not `123`) before account linking | MUST | OIDC §5.7 |
| I2 | Accounts never auto-linked across providers by email alone | SHOULD | OWASP Cheatsheet |
| I3 | JWKS cached with TTL (≤24h) and re-fetched on unknown `kid` | SHOULD | RFC 7517 |

### 4. Confirm With Concrete Code Patterns

For each ❌ or ⚠️, attach a code reference and (where useful) a BAD → GOOD diff. Example for the most common finding (C1+C2+C4 — missing or weak `state`):

**BAD** — no `state`, account-takeover via OAuth CSRF:
```python
@app.route("/login/provider")
def oauth_login():
    auth_url = (f"{PROVIDER}?client_id={CID}"
                f"&redirect_uri={CB}&response_type=code")  # no state
    return redirect(auth_url)

@app.route("/callback")
def oauth_callback():
    code = request.args.get("code")
    token = exchange_code_for_token(code)  # blindly trusts the code
    log_user_in(token)                     # victim now logged into attacker's account
```

Attack chain:
1. Attacker initiates the OAuth flow with their own provider account, captures the `code` from the redirect.
2. Attacker tricks the victim into visiting `https://app/callback?code=ATTACKER_CODE` (image, link, iframe).
3. The app exchanges the attacker's `code`, binds the attacker's identity to the victim's session — victim is now logged into the **attacker's** account and any data they upload (CC numbers, files, search history) flows to the attacker.

**GOOD**:
```python
import secrets, hmac
from flask import session

@app.route("/login/provider")
def oauth_login():
    state = secrets.token_urlsafe(32)            # C2: ≥128 bits
    session["oauth_state"] = state               # bound to user agent
    auth_url = (f"{PROVIDER}?client_id={CID}"
                f"&redirect_uri={CB}&response_type=code"
                f"&state={state}")
    return redirect(auth_url)

@app.route("/callback")
def oauth_callback():
    received = request.args.get("state") or ""
    expected = session.pop("oauth_state", None)  # C3: single-use
    if not expected or not hmac.compare_digest(expected, received):  # C4: constant-time
        abort(403, "state mismatch")             # do NOT leak which side failed
    code = request.args.get("code")
    token = exchange_code_for_token(code)
    log_user_in(token)
```

Maintain a short library of these BAD/GOOD pairs for the most common findings (state, PKCE plain, open redirect, `localStorage` token, missing `aud`, missing PKCE-downgrade rejection).

### 5. Report

Always produce the report in this shape — it is the deliverable:

```
## OAuth Security Audit: <component / integration>

### Scope
- Role: <client | AS | RS>
- Client type: <public | confidential>
- Grant types: <code+PKCE, client_credentials, ...>
- Providers: <list>
- Reviewed paths: <file:line ranges>

### Summary
- Critical: N
- High: N
- Medium: N
- Low: N
- Compliant items: N / total

### Critical (MUST / MUST NOT violations)
- [C1, C2] No `state` parameter on `/auth/login`
  - Evidence: src/oauth/login.py:34
  - Impact: OAuth CSRF → account takeover (CWE-352)
  - Fix: generate `secrets.token_urlsafe(32)`, store in session, validate with `hmac.compare_digest`, single-use
  - Refs: RFC 9700 §4.7, OWASP A07:2025

### High (SHOULD violations or exploitable Mediums)
- ...

### Medium / Low
- ...

### Compliant
- ✅ Redirect URIs registered exactly (no wildcards) — R1
- ✅ ID Token `iss` and `aud` validated — A4
- ...

### Open Questions
- ❓ Could not determine whether refresh tokens rotate (RT1) — request access to AS config
```

Every finding cites: **(checklist ID, code location, RFC §, CWE / OWASP)**. No finding without a citation.

## Common Mistakes During the Audit

| Mistake | Reality |
|---|---|
| Treating `state` and PKCE as alternatives — "we have PKCE so we don't need state" | RFC 9700 §4.7 accepts either, but `state` also doubles as round-trip context; most teams want both |
| Approving `code_challenge_method=plain` because "the code is short-lived" | `plain` defeats PKCE on a malicious-app-on-device threat model — always require `S256` |
| Validating `iss` against a substring (`endswith("google.com")`) | Must be exact-match against the configured issuer URL; substring lets a sub-domain takeover impersonate the AS |
| Linking accounts by `email` claim across providers | Email is provider-asserted and not unique; namespace `sub` by issuer instead (I1) |
| Storing access tokens in `localStorage` because "we have a CSP" | XSS bypasses CSP via DOM injection routinely; tokens belong in memory or HttpOnly cookies (T6) |
| Skipping `aud` validation because "the JWT signature is valid" | A token signed by Google for *another* relying party is still signature-valid for you — `aud` is what binds it to your client |
| Accepting AS metadata over HTTP "for dev" | Metadata pinning to wrong issuer means every other check is moot |
