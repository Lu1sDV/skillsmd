---
name: vuln-research
description: >
  Use when performing vulnerability research, security auditing, code analysis,
  bug bounty hunting, CTF challenges, penetration testing, or exploit development.
  Covers source audit across 30+ attack domains, sink analysis for 12 languages,
  SAST/DAST integration, vulnerability chaining, and proof-of-concept development.
  Triggers: vuln assessment, pentest, bug bounty, security audit, find vulns,
  exploit, ctf, code audit, hunt bugs, 0-day, SAST, DAST, taint analysis.
---

# Vulnerability Research

> **Think Beyond This Document**
>
> This skill is a structured starting point, not a ceiling. Real-world vulnerabilities
> and CTF challenges routinely defy checklists. The best exploit chains come from
> creative, unconstrained thinking — connecting behaviors the developer never imagined
> interacting. **Do not limit your research to what is cataloged here.** Treat every
> assumption as testable, every "impossible" path as merely untested, and every
> protection as a puzzle to be solved. The most dangerous bugs live in the gaps
> between documented categories. Read the code. Understand the runtime. Invent your
> own attack classes.

## Philosophy

Find the bug. Prove the bug. Chain the bug. Every claim needs a working exploit or it's noise.

The phases below are a **recommended workflow, not a rigid sequence** — skip, reorder, or loop as the target demands. The sink catalogs are **representative, not exhaustive** — new frameworks ship new dangerous functions daily. If you find a sink not listed here, it's still a sink. The checklists exist to prevent forgetting the obvious, not to replace thinking.

---

## Domain Reference Map

Load references on-demand based on the active testing domain. **Do not load all files at once.**

| Domain | Reference File | Load When |
|--------|---------------|-----------|
| SQLi, NoSQL, SSTI, CRLF, LDAP, XPath, LaTeX Injection, CSV Injection, XSLT Injection | `references/injection-attacks.md` | Testing injection vectors |
| XSS, Prototype Pollution, CORS, XS-Leaks, CSTI, postMessage | `references/client-side-attacks.md` | Testing client-side attacks |
| RCE, SSRF, XXE, File Ops, Deserialization | `references/server-side-attacks.md` | Testing server-side attacks |
| Auth, Access Control, OAuth, Logic, Race, Crypto | `references/auth-access-logic.md` | Testing auth & business logic |
| Smuggling, Cache, WebSocket, GraphQL, DNS, Cloud, Encoding, ReDoS, Supply Chain, HTML Smuggling, Prompt Injection | `references/protocol-infra-attacks.md` | Testing protocols & infrastructure |
| Sinks router + SAST/DAST rules | `references/sinks-catalog.md` | Code audit entry point — routes to per-language sink files |
| PHP sinks | `references/sinks/php.md` | PHP code audit (exec, callbacks, type juggling, phar deser) |
| Python sinks | `references/sinks/python.md` | Python code audit (exec, pickle, SSTI, subprocess) |
| Node.js sinks | `references/sinks/javascript.md` | JS/Node code audit (child_process, prototype pollution) |
| Java sinks | `references/sinks/java.md` | Java code audit (Runtime, JNDI, ysoserial, format-specific deser) |
| Ruby sinks | `references/sinks/ruby.md` | Ruby code audit (system/eval, Marshal, ActiveRecord) |
| .NET sinks | `references/sinks/dotnet.md` | .NET code audit (Process.Start, BinaryFormatter, Json.NET) |
| Systems sinks (Go/Rust/C/Elixir) | `references/sinks/systems.md` | Systems code audit (memory corruption, os/exec, ETF deser) |
| Mobile sinks (Android/iOS) | `references/sinks/mobile.md` | Mobile code audit (WebView, intents, URL schemes) |
| Vulnerability chaining, scanning tools, blind spots | `references/chaining-advanced-techniques.md` | Building exploit chains, tool augmentation |
| Formal audit, PoC development, report writing | `references/audit-poc-report.md` | **On-demand only** — when asked for audit/PoC/report |

---

## Phase 1: Recon

Identify the full technology stack before touching anything:
- Language, runtime version, framework, template engine
- ORM / database layer and database engine
- Web server and its configuration (Apache, Nginx, Caddy, IIS, LiteSpeed)
- Reverse proxy / load balancer (HAProxy, Traefik, AWS ALB — each parses HTTP differently)
- Auth mechanism (session, JWT, OAuth, SAML, WebAuthn, custom)
- File upload support, allowed types, size limits
- API style (REST, GraphQL, SOAP, JSON-RPC, gRPC-Web, WebSocket)
- Debug mode status, verbose error pages, stack traces
- PHP config: `allow_url_include`, `allow_url_fopen`, `disable_functions`, `open_basedir`, `display_errors`, `file_uploads`, `session.upload_progress.enabled`
- Node.js: `--inspect` port, `NODE_ENV`, prototype pollution surface
- Python: debug mode (Werkzeug debugger PIN), pickle usage, SSTI surface
- Java: JNDI enabled, deserialization libraries, Expression Language version
- Container context: privileged mode, mounted volumes, exposed docker socket, inter-container network, environment secrets, Kubernetes service account tokens
- CDN / WAF fingerprint (Cloudflare, Akamai, ModSecurity rules — know what you're bypassing)
- Client-side: JS frameworks (React, Angular, Vue), bundler (webpack, vite), source maps available
- Dependency manifest: `package.json`, `composer.json`, `requirements.txt`, `Gemfile`, `pom.xml`, `go.mod`, `Cargo.toml`, `mix.exs`
- Known CVEs in detected versions (check NVD, Snyk DB, GitHub Advisories)

Map every user input vector:
- URL parameters, path segments, fragments
- Request body (form-encoded, JSON, XML, multipart)
- HTTP headers (Host, X-Forwarded-For, Referer, User-Agent, Accept-Language, custom headers)
- Cookies
- File upload content and metadata (filename, content-type, EXIF)
- WebSocket messages
- DNS records (for DNS rebinding)
- API field names (for mass assignment)

Map every endpoint. Build a table of routes, methods, auth requirements, and parameters before testing.

---

## Phase 2: Crown Jewel Mapping

Before testing, identify maximum-damage targets:

1. **Data assets**: PII stores, payment processing, admin credentials, API keys
2. **Privilege boundaries**: admin panels, role escalation paths, multi-tenant isolation
3. **Trust transitions**: internal services, SSO providers, cloud metadata endpoints
4. **Business logic**: financial operations, state machines, approval workflows

Attack the highest-value targets first.

---

## Phase 3: Source Audit

Run parallel agents, each focused on one attack domain. Every agent traces **source to sink** — user input reaching a dangerous function.

| Attack Category | Key Targets | Reference |
|----------------|-------------|-----------|
| **Injection** (SQLi, NoSQL, SSTI, CRLF, LDAP, XPath) | Query builders, template renders, header construction | `injection-attacks.md` |
| **Client-Side** (XSS, Proto Pollution, CORS) | Output contexts, deep merge, origin validation | `client-side-attacks.md` |
| **Server-Side** (RCE, SSRF, XXE, File Ops, Deser) | Command exec, URL fetching, XML parsing, file I/O, object deser | `server-side-attacks.md` |
| **Auth & Logic** (Auth, ACL, OAuth, Race, Crypto) | Session mgmt, role checks, token flows, concurrent ops, key mgmt | `auth-access-logic.md` |
| **Protocol & Infra** (Smuggling, Cache, WS, GraphQL, DNS, Cloud) | HTTP parsing, cache keys, WS handlers, query depth, metadata | `protocol-infra-attacks.md` |

---

## Phase 3.5: Technology Stack Discovery (Sink Loading)

Before taint analysis, identify **every language and framework in the stack** — most targets are polyglot:

1. **Enumerate languages**: scan file extensions, shebangs, `package.json`/`composer.json`/`pom.xml`/`go.mod`/`Cargo.toml`/`mix.exs`/`Gemfile`/`requirements.txt`
2. **Identify the stack layers**: e.g., PHP backend + Node.js build tooling + Python microservice + Java auth service
3. **Load matching sink files**: for each language present, load the corresponding `references/sinks/<lang>.md` — load multiple if the target is polyglot
4. **Load the SAST/DAST router**: `references/sinks-catalog.md` for cross-language Semgrep/CodeQL/SonarQube rules

**Example**: a Laravel app with React SSR and a Python ML microservice → load `sinks/php.md` + `sinks/javascript.md` + `sinks/python.md`

Do not skip minor languages in the stack — the weakest link is often the least-reviewed service.

---

## Phase 4: Taint Analysis

Three strategies — choose based on codebase size:

| Strategy | When | Method |
|----------|------|--------|
| **Source-forward** | Small codebase, few entry points | Trace from user input → through transforms → to sinks |
| **Sink-backward** | Large codebase, known dangerous functions | Start at sinks (see `sinks-catalog.md`) → trace backward to find controllable inputs |
| **Hybrid** | Medium codebase, complex data flow | Combine both: forward from sources AND backward from sinks, meet in the middle |

**Controllability classification** for each sink parameter:
- **High**: Direct user input reaches sink with no sanitization
- **Medium**: Input reaches sink through partial transforms (encoding, type casting)
- **Low**: Input is significantly constrained but still partially controllable
- **Needs verification**: Theoretical path exists, requires dynamic confirmation

Load `references/sinks-catalog.md` for the language router and SAST/DAST integration rules. It routes to per-language sink files — load only the language(s) matching the target codebase.

---

## Phase 5: Exploitation

**Priority tiers** — don't waste time on Medium findings if Critical ones exist:

| Tier | Severity | Examples |
|------|----------|----------|
| **P0** | Critical | RCE (webshell, deser, SSTI, command injection, eval, JNDI) |
| **P1** | High | SQLi, SSRF, auth bypass, arbitrary file read, IDOR w/ sensitive data, XXE |
| **P2** | Medium | Stored XSS, CSRF on critical actions, race conditions, mass assignment, proto pollution, smuggling |
| **P3** | Low | Reflected XSS, info disclosure, missing headers, CORS misconfig, open redirect |

For each finding: identify source → trace transforms → confirm sink reach → craft payload → prove impact.

---

## Phase 6: Vulnerability Chaining

Single bugs are starting points. Real impact comes from chains.

**Chain patterns** (full catalog in `references/chaining-advanced-techniques.md`):
- **Reader + Writer = RCE**: path traversal → read creds → auth → admin RCE
- **Client → Server**: stored XSS → steal admin session → authenticated RCE
- **Escalation**: IDOR + missing ACL → mass breach; SSRF → cloud metadata → AWS keys
- **Race conditions**: double-spend, TOCTOU file ops, concurrent privilege escalation
- **Deserialization**: file upload → phar:// trigger → deser → RCE

**Impact amplifiers**: Re-score severity in chain context. A Low open redirect becomes High when it enables OAuth token theft → account takeover.

---

## Phase 7: Exploitability Gate

Before reporting ANY finding, answer these three questions:

1. **Can I control the input?** — Is user input actually controllable, or is it server-generated/hardcoded?
2. **Does it reach the sink?** — Does the tainted data survive all transforms, sanitizers, and WAF rules?
3. **Can I prove impact?** — Do I have a working payload that demonstrates real-world consequences?

If any answer is **No** → move to Observations section (not confirmed vulnerabilities).

---

## Proof Collection (Summary)

Every reported vulnerability MUST include:

1. **Confidence Score (1-10)** — exploitability certainty
2. **Exploitability Likelihood (High/Medium/Low)** — how likely is real-world exploitation given attack complexity, auth requirements, and conditions
3. **Auth Level** — Unauthenticated / Authenticated (specify minimum role) / Multi-level (specify each)
4. **Intent Verification Gate** — double-check this is NOT an intended feature (admin RCE via plugin upload = intended; editor accessing admin plugin upload = real bug). See full gate in `audit-poc-report.md`
5. **Intent Classification** — Actual bug / Intended feature / Design weakness
6. **Justification** — who has access? Is this expected for that role? Would fixing it break legitimate workflows?
7. **Exact payload** — copy-pasteable, not screenshots
8. **Server response** — proving impact
9. **Video recording** — full exploit chain end-to-end

Low-confidence findings (score <= 3) → **Observations** section. Intended features flagged as design weaknesses → also Observations.

Full proof methodology and report template in `references/audit-poc-report.md` (load when writing reports).

---

## Blind Spots Checklist (Top 10)

Before declaring "done", verify you tested:

- [ ] Unauthenticated access (not just admin)
- [ ] POST body, JSON body, headers, cookies, path segments (not just GET params)
- [ ] Second-order injection (stored safely, used unsafely later)
- [ ] Rate limiting (brute force login, OTP, password reset)
- [ ] Content-type switching (JSON → XML for XXE, form-encoded for CSRF)
- [ ] WebSocket endpoints (often completely unauthenticated)
- [ ] Prototype pollution in Node.js JSON inputs
- [ ] Cloud metadata during SSRF testing
- [ ] ORM raw query methods (ORM != no SQLi)
- [ ] Race conditions on ALL state-changing operations

Full blind spots list in `references/chaining-advanced-techniques.md`.

---

## On-Demand: Audit / PoC / Report

> **Trigger**: Load `references/audit-poc-report.md` when the user requests:
> - Formal security audit (OWASP/STRIDE/PASTA framework)
> - Proof-of-concept development methodology
> - Vulnerability report generation
> - Red team simulation with attacker personas
> - CVSS scoring and risk assessment

This section is intentionally not auto-loaded to save tokens during standard research.

---

> **Remember:** The best researchers don't follow checklists —
> they understand systems deeply enough to invent new attack classes. This document
> gives you the vocabulary. The creativity is yours. Question every assumption.
> Test every boundary. The flag is always one weird trick away.
