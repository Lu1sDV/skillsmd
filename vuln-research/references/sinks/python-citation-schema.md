---
name: python-sinks-citation-schema
description: >
  JSON citation schema for Python security sink findings in vuln-research.
  Every sink entry MUST include a citation block in this format.
---

# Python Sink Citation Schema

Every finding in `python.md` MUST end with a JSON citation block following this schema:

```json
{
  "sink_id": "string",           // Unique identifier: CATEGORY-NNN (e.g., RCE-001, CLASS-012)
  "category": "string",          // sink category from taxonomy
  "title": "string",             // Human-readable finding title
  "severity": "critical|high|medium|low|info",
  "affected_versions": ["string"], // Python versions affected
  "sources": [
    {
      "type": "ctf_writeup|cve|cpython_issue|research_paper|blog_post|github_advisory|github_issue|security_advisory|tool_exploit",
      "url": "string",           // Primary URL
      "title": "string",         // Source title
      "author": "string",        // Author/organization
      "date": "YYYY-MM-DD",      // Publication date
      "cve_id": "string",        // Optional: CVE-YYYY-NNNNN
      "gh_issue": "string",      // Optional: gh-NNNNNN or org/repo#NNNN
      "ghsa": "string",          // Optional: GHSA-XXXX-XXXX-XXXX
      "verified": true|false,    // Has a working PoC been verified?
      "tags": ["string"]         // Freeform tags for filtering
    }
  ],
  "related_cves": ["string"],    // Optional related CVEs
  "related_issues": ["string"],  // Optional related GitHub issues
  "detection_signature": "string", // Optional: grep/ast-grep pattern for detection
  "mitigation": "string",        // Optional: brief mitigation note
  "confidence": "confirmed|likely|theoretical" // Evidence quality
}
```

## Category Taxonomy

| Prefix | Category |
|--------|----------|
| RCE | Remote Code Execution |
| DESER | Deserialization |
| SSTI | Server-Side Template Injection |
| FILE | File Operations |
| SSRF | Server-Side Request Forgery |
| SQLI | SQL Injection |
| CLASS | Class Confusion / Type System |
| PROTO | Prototype / Property Injection |
| RACE | Race Conditions |
| ASYNC | Async / Generator |
| CTF | CTF / Sandbox Escape |
| STDLIB | Standard Library Hidden Sinks |
| CPYTHON | CPython Internals / Interpreter Bugs |
| SERIAL | Serialization Beyond Pickle |
| NUMERIC | Numeric / String Manipulation |
| PROTOCOL | Protocol / Parser Abuse |

## Example

```python
# Vulnerable code example here
```
**Ref**: idek 2022 CTF Pyjail & Pyjail Revenge Writeup.

```json
{
  "sink_id": "CTF-001",
  "category": "CTF",
  "title": "breakpoint() Exploitation via Builtin Overlay Removal",
  "severity": "high",
  "affected_versions": ["3.6+", "3.7+", "3.8+", "3.9+", "3.10+", "3.11+", "3.12+", "3.13+"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://crazymanarmy.github.io/2023/01/18/idek-2022-CTF-Pyjail-Pyjail-Revenge-Writeup/",
      "title": "idek 2022 CTF: Pyjail & Pyjail Revenge Writeup",
      "author": "crazymanarmy",
      "date": "2023-01-18",
      "verified": true,
      "tags": ["pyjail", "sandbox-escape", "breakpoint", "site-module"]
    }
  ],
  "related_cves": [],
  "related_issues": [],
  "detection_signature": "setattr\\(.*copyright.*__dict__.*globals",
  "mitigation": "Block or audit setattr() calls on site module objects",
  "confidence": "confirmed"
}
```
