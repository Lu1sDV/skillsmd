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

---

## Proof Collection

Every reported vulnerability MUST include:

1. **Confidence Score (1-10)** — how confident you are this is a real, exploitable issue
2. **Intent Analysis** — classify each finding as:
   - **Intended feature**: functionality working as designed (e.g., admin uploading plugins, superuser SSH access, debug endpoints behind auth). Do NOT report these as vulnerabilities.
   - **Actual bug**: unintended behavior that violates security assumptions
3. **Justification** — brief reasoning for the intent classification, considering:
   - Who has access? (admin vs. unprivileged user vs. unauthenticated)
   - Is this a documented/expected capability of that role?
   - Would "fixing" it break legitimate functionality?

Low-confidence findings (score <= 3) go under a separate **Observations** section, not mixed in with confirmed vulnerabilities.

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
**Intent:** Actual bug / Intended feature

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
