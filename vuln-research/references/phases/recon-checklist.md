# Phase L1 Recon Checklist

Load this file during Phase L1 (Recon) for the full stack-fingerprinting and input-vector enumeration. The always-loaded SKILL.md keeps a compressed summary; this file owns the detailed lists, runtime version gates, and config-flag specifics that gate exploitability per language.

---

## Technology Stack Enumeration

Identify the full technology stack before touching anything, for example:

- Language, runtime version, framework, template engine
- ORM / database layer and database engine
- Web server and its configuration (Apache, Nginx, Caddy, IIS, LiteSpeed)
- Reverse proxy / load balancer (HAProxy, Traefik, AWS ALB — each parses HTTP differently)
- Auth mechanism (session, JWT, OAuth, SAML, WebAuthn, custom)
- File upload support, allowed types, size limits
- API style (REST, GraphQL, SOAP, JSON-RPC, gRPC-Web, WebSocket)
- Debug mode status, verbose error pages, stack traces
- Container context: privileged mode, mounted volumes, exposed docker socket, inter-container network, environment secrets, Kubernetes service account tokens
- CDN / WAF fingerprint (Cloudflare, Akamai, ModSecurity rules — know what you're bypassing)
- Client-side: JS frameworks (React, Angular, Vue), bundler (webpack, vite), source maps available
- Dependency manifest: `package.json`, `composer.json`, `requirements.txt`, `Gemfile`, `pom.xml`, `go.mod`, `Cargo.toml`, `mix.exs`
- `patch-package` / `pnpm patch` / `yarn patch` overlays (`patches/*.patch`, `patches_*/*.patch`): read every patch in the tree and treat each removed/added hunk as security-relevant by default. Overlays silently mutate vendored SDK invariants (scoring rules, crypto surface, consent UX) and do not show up in dependency scanners. A patch that `export`s a previously-private crypto method, adjusts an auth scoreFlow, or deletes a `Confirm*` modal is a finding-generator by itself.
- Known CVEs in detected versions (check NVD, Snyk DB, GitHub Advisories)

## Runtime Version Gates

Version gates determine which sinks are actually exploitable on the running stack — qualify every finding with the relevant gate.

### Examples

- **PHP version** (5.x / 7.x / 8.x) — gates which sinks are exploitable: `assert()` evals strings only in < 8.0, `preg_replace /e` only in < 7.0, loose type juggling `0 == "string"` only in < 8.0, `libxml_disable_entity_loader()` removed in 8.0 (XXE defaults safe), hex numeric strings `"0x1A" == 26` only in < 7.0. **Always qualify PHP findings with the version gate.**
- **PHP config**: `allow_url_include`, `allow_url_fopen`, `disable_functions`, `open_basedir`, `display_errors`, `file_uploads`, `session.upload_progress.enabled`
- **Node.js**: `--inspect` port, `NODE_ENV`, prototype pollution surface
- **Python**: debug mode (Werkzeug debugger PIN), pickle usage, SSTI surface
- **Java**: JNDI enabled, deserialization libraries, Expression Language version
 
## Input Vector Map

Map every user input vector:

### Examples 

- URL parameters, path segments, fragments
- Request body (form-encoded, JSON, XML, multipart)
- HTTP headers (Host, X-Forwarded-For, Referer, User-Agent, Accept-Language, custom headers)
- Cookies
- File upload content and metadata (filename, content-type, EXIF)
- WebSocket messages
- DNS records (for DNS rebinding)
- API field names (for mass assignment)
- Server-Client interaction where one could be attacker-controlled

## Stateful / Protocol Surface Inventory

For any target that processes a sequence of inputs (protocols, WebSockets, GraphQL subscriptions, OAuth/OIDC flows, multi-step business workflows, CLIs with sessions, daemon/control sockets), collect the two-layer input model before fuzzing or taint tracing:

- **Messages**: concrete request/packet/event formats, message types, opcode/header fields, length/checksum/session-token dependencies
- **Traces**: valid and invalid sequences of messages; authenticated↔unauthenticated, setup→use→teardown, retry/error paths, and deep workflow states
- **Responses**: status codes, error classes, connection drops, page/API response similarity buckets, protocol alerts
- **State model source**: supplied specification/OpenAPI/protocol docs, sample traces from PCAPs/logs/client binaries, or inferred state machine
- **Abstraction functions**: how concrete messages map to message types and how concrete responses map to response/state classes

Seed stateful fuzzing with real traces first; then mutate both message fields and trace structure (reorder, drop, repeat, insert, splice, replay). Stateful coverage includes reached states, transitions, response classes, deep states, and spec/state-machine deviations — not just code edges.

## External / Passive Attack-Surface Enumeration

For live targets (bug bounty, DAST, coordinated-disclosure with a running instance), extend the recon pass with passive asset discovery before active testing. This section is **skip-if: source-only / no live target**.

### Asset & subdomain discovery

- **Wildcard scope reconciliation**: confirm which assets the program's policy covers. Wildcards (`*.example.com`) typically exclude third-party-hosted subdomains and CDN-fronted assets — read the policy, not just the domain list.
- **Passive subdomain enumeration**: crt.sh, Shodan, SecurityTrails, Censys, dnsx, subfinder, amass (`amass enum -passive`). Do not use active brute-force DNS enumeration unless the program explicitly permits it.
- **Live-host verification**: filter discovered subdomains through httpx / httprobe before spending hunt time on unreachable hosts.
- **Live-vs-staging fingerprinting**: identify which subdomains are production vs staging/dev. Dev environments often have debug flags enabled, verbose errors, and weaker auth — and may be in scope with a lower severity ceiling.

### Dependency & supply-chain surface

- Pull `package-lock.json`, `yarn.lock`, `composer.lock`, `Pipfile.lock`, `Cargo.lock`, `go.sum` if accessible (public repo, `.well-known`, or leaked via directory listing).
- Run `npm audit --json`, `pip-audit`, `safety`, `snyk test` against the lock file for known CVEs in the dependency tree.
- Check for abandoned CDN / S3 bucket names (subdomain or bucket name still referenced but ownership lapsed — supply-chain hijacking vector).
- `patch-package` / `pnpm patch` overlays (see Technology Stack Enumeration above) are especially high-value here: a patch that weakens a vendor security control is a direct finding generator.

### DNS / OSINT signals

- Reverse IP lookup to identify co-hosted assets sharing the same server.
- SPF / DMARC / DKIM records — absent or permissive records are a prerequisite check for email-spoofing chains (confirm program scope covers email infrastructure before reporting).
- MX records revealing third-party email providers that may have separate auth surfaces.
- Historical DNS (SecurityTrails, RiskIQ PassiveTotal) to find previously exposed IPs or retired subdomains still reachable.

## Endpoint Map

Map every endpoint. Build a table of routes, methods, auth requirements, and parameters before testing.
