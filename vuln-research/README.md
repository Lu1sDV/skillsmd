# vuln-research

Comprehensive vulnerability research skill for Claude Code. Covers source audit across 30+ attack domains, sink analysis for 12 programming languages, SAST/DAST integration, vulnerability chaining, and proof-of-concept development.

Built from real CTF challenges, bug bounty writeups, PayloadsAllTheThings, HackTricks, Web-CTF-Cheatsheet, PortSwigger Research, 50+ community cheatsheets/repositories, and Thomas Ptacek's [Vulnerability Research Is Cooked](https://sockpuppet.org/blog/2026/03/30/vulnerability-research-is-cooked/) (Agent Sweep mode, Carlini methodology).

## What It Does

- **7-phase methodology**: Recon → Crown Jewel Mapping → Source Audit → Tech Stack Discovery → Taint Analysis → Exploitation → Chaining → Exploitability Gate
- **30+ attack domains**: SQLi, NoSQL, SSTI, XSLT injection, XSS, prototype pollution, DOM clobbering, CSS exfiltration, RCE, SSRF, XXE, deserialization (Java/PHP/.NET/Python/Ruby/Node), HTTP smuggling, browser-powered desync, cache poisoning, OAuth/JWT attacks, race conditions, and more
- **12-language sink catalog**: PHP, Python, Node.js, Java, Ruby, .NET, Go, Rust, C/C++, Kotlin/Android, Elixir/Erlang, Swift/iOS — with per-language files for token-efficient loading
- **SAST/DAST integration**: Semgrep rule IDs, CodeQL query packs, SonarQube RSPEC references, DAST detection signatures
- **Vulnerability chaining**: 10+ chain pattern categories with impact amplifiers and composite risk scoring
- **On-demand audit framework**: OWASP/STRIDE/PASTA methodology, red team personas, PoC templates, CVSS scoring, structured report generation

## Structure

```
vuln-research/
├── SKILL.md                                    # Orchestrator (~247 lines) — routing + methodology
├── README.md                                   # This file
└── references/
    ├── injection-attacks.md                    # SQLi, NoSQL, SSTI, XSLT injection, CRLF, LDAP, XPath
    ├── client-side-attacks.md                  # XSS, Prototype Pollution, DOM Clobbering, CSS Exfiltration, CORS
    ├── server-side-attacks.md                  # RCE, SSRF, XXE, File Ops, Deserialization (expanded)
    ├── auth-access-logic.md                    # Auth, Access Control, OAuth/SSO, JWT, Logic, Race, Crypto
    ├── protocol-infra-attacks.md               # Smuggling, Browser Desync, Cache Poisoning, GraphQL, WebSocket, DNS, Cloud
    ├── sinks-catalog.md                        # Language router + SAST/DAST integration layer
    ├── chaining-advanced-techniques.md         # Chain patterns, scanning augmentation, blind spots checklist
    ├── agent-sweep.md                          # Agent Sweep methodology: Carlini discovery/verification loops
    ├── audit-poc-report.md                     # On-demand: formal audit, PoC development, report template
    └── sinks/                                  # Per-language sink catalogs (loaded on demand)
        ├── php.md                              # PHP — exec, callbacks, type juggling, phar deser, magic hashes
        ├── python.md                           # Python — exec, pickle, SSTI, subprocess
        ├── javascript.md                       # Node.js — child_process, prototype pollution, NoSQL, ReDoS
        ├── java.md                             # Java — Runtime, JNDI, ysoserial, format-specific deser
        ├── ruby.md                             # Ruby — system/eval, Marshal, ActiveRecord
        ├── dotnet.md                           # .NET — Process.Start, BinaryFormatter, Json.NET
        ├── systems.md                          # Go, Rust, C/C++, Elixir/Erlang
        └── mobile.md                           # Kotlin/Android, Swift/iOS
```

## Token Efficiency

The skill uses **two-tier progressive disclosure**:

1. **SKILL.md** (~247 lines) loads automatically — provides the full methodology and a routing table to reference files
2. **Domain reference files** load on-demand based on the active testing domain (injection, client-side, server-side, etc.)
3. **Per-language sink files** load on-demand based on the target codebase language — auditing a PHP app loads only `sinks/php.md` (119 lines) instead of the full 12-language catalog

This saves significant context window space compared to loading everything upfront. When auditing a PHP web app, you load SKILL.md + `injection-attacks.md` + `sinks/php.md` instead of a monolithic 2000+ line document.

## Installation

### Via Plugin Marketplace

```bash
# Add the skillsmd plugin source
/plugin marketplace add Lu1sDV/skillsmd

# Install the skill
/plugin install vuln-research@Lu1sDV/skillsmd
```

### Via npx

```bash
npx skills add Lu1sDV/skillsmd vuln-research
```

### Manual

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/vuln-research ~/.claude/skills/
```

### Verify

```
What skills are available?
```

## Usage

The skill activates on keywords like "vuln assessment", "pentest", "bug bounty", "security audit", "find vulns", "exploit", "ctf", "code audit", "SAST", "DAST", "taint analysis".

### Standard Research

SKILL.md loads automatically, reference files load as needed based on the attack domain being tested:

```
Audit this codebase for vulnerabilities
```

```
Find injection vectors in the user registration flow
```

```
Perform taint analysis on this PHP application
```

### Formal Audit / PoC / Report

Ask explicitly to load the audit framework — e.g.:

```
Generate a vulnerability report for this application
```

```
Develop a PoC for the SSRF finding
```

```
Run a formal security audit using OWASP methodology
```

This loads `audit-poc-report.md` with OWASP/STRIDE/PASTA frameworks, red team personas, PoC script templates, proof collection requirements, and structured report format with CVSS scoring.

## Languages Covered

| Language | Sink File | Key Categories |
|----------|-----------|----------------|
| PHP | `sinks/php.md` | exec, 25+ callback sinks, type juggling, phar deser, disable_functions bypass, magic hashes |
| Python | `sinks/python.md` | exec, pickle, SSTI (Jinja2/Mako/Tornado), subprocess, SSRF |
| Node.js | `sinks/javascript.md` | child_process, prototype pollution, node-serialize, NoSQL injection, ReDoS |
| Java | `sinks/java.md` | Runtime exec, JNDI (Log4Shell), 25+ ysoserial chains, format-specific deser (Fastjson/SnakeYAML/Hessian) |
| Ruby | `sinks/ruby.md` | system/eval, Marshal/YAML deser, ActiveRecord SQLi, Kernel.open |
| .NET | `sinks/dotnet.md` | Process.Start, BinaryFormatter, Json.NET TypeNameHandling, ysoserial.net |
| Go | `sinks/systems.md` | os/exec, template injection, filepath.Join pitfalls |
| Rust | `sinks/systems.md` | Command, unsafe blocks, eval crates (rhai/rlua), sqlx format injection |
| C/C++ | `sinks/systems.md` | Buffer overflow, format strings, heap exploitation, TOCTOU races |
| Elixir/Erlang | `sinks/systems.md` | Port.open, Code.eval_string, ETF deser, atom exhaustion |
| Kotlin/Android | `sinks/mobile.md` | WebView bridges, intent injection, exported components, data storage |
| Swift/iOS | `sinks/mobile.md` | WKWebView, URL scheme handling, Keychain, ATS exceptions |

## SAST/DAST Integration

The `sinks-catalog.md` router includes cross-language tooling references:

| Tool | Coverage |
|------|----------|
| **Semgrep** | Rule packs per language (`p/php`, `p/python`, `p/java`, etc.) with specific rule IDs |
| **CodeQL** | Query packs with CWE-mapped queries (SQLi, OS cmd, deser, XXE, proto pollution) |
| **SonarQube** | RSPEC rule references (S3649 SQLi, S2076 cmd injection, S5135 deser, etc.) |
| **DAST signatures** | Detection patterns for SQLi, XSS, SSRF, XXE, RCE, path traversal, deserialization |

## Attack Coverage Highlights

### Novel / Advanced Techniques

- **XSLT injection**: PHP `php:function()` → RCE, Java Xalan `Runtime.exec()`, Saxon XSLT 2.0, .NET `msxsl:script`
- **Browser-powered desync**: CL.0, H2.0, client-side desync, pause-based desync, first-request routing
- **CSS injection exfiltration**: `:has()` selectors, `@import` recursive chains, font-face unicode-range, ligature-based text extraction
- **DOM clobbering**: DOMPurify `cid:` protocol bypass, `attributes` property clobbering, SVG namespace confusion
- **Prototype pollution RCE**: `NODE_OPTIONS` + `/proc/self/environ`, EJS `escapeFunction`, Kibana CVE-2019-7609, 50+ client-side gadgets
- **Cache poisoning**: Delimiter path confusion (Spring `;`, Rails `.`, OpenLiteSpeed `%00`), CDN normalization differentials
- **JWT attacks**: Psychic signature (CVE-2022-21449), embedded JWK, ECDSA key recovery, audience confusion
- **OAuth advanced**: Mutable claims account takeover, client confusion, scope upgrade, redirect scheme hijacking

### Vulnerability Chaining

10+ chain pattern categories: Reader+Writer=RCE, Client→Server escalation, SSRF→cloud metadata→infrastructure compromise, race condition exploitation, deserialization chains, XSLT chains, cache poisoning chains, browser desync chains, prototype pollution chains.

### Blind Spots Checklist

25+ commonly missed testing areas including XSLT injection, browser desync, CSS injection, DOM clobbering, client-side prototype pollution, cache delimiter confusion, JWT audience validation, mutable OAuth claims, Service Worker pollution, and more.
