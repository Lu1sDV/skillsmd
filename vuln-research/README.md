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
├── SKILL.md                                    # Orchestrator — routing + methodology
├── README.md                                   # This file
├── commands/
│   └── vuln-swarm.md                           # Swarm Pipeline slash command (orchestration)
└── references/
    ├── injection-attacks.md                    # SQLi, NoSQL, SSTI, XSLT injection, CRLF, LDAP, XPath
    ├── client-side-attacks.md                  # XSS, Prototype Pollution, DOM Clobbering, CSS Exfiltration, CORS, CSTI, postMessage
    ├── browser-attacks.md                      # XS-Leaks, Clickjacking, CSP Bypass, Browser Desync, HTML Smuggling
    ├── server-side-attacks.md                  # RCE, SSRF, XXE, File Ops, Deserialization (expanded)
    ├── auth-access-logic.md                    # Auth, Access Control, OAuth/SSO, JWT, Logic, Race, Crypto
    ├── protocol-infra-attacks.md               # Smuggling, Cache Poisoning, GraphQL, WebSocket, DNS, Cloud, Encoding, ReDoS
    ├── sinks-catalog.md                        # Language router + SAST/DAST integration layer
    ├── chaining-advanced-techniques.md         # Chain patterns, scanning augmentation, blind spots checklist
    ├── agent-sweep.md                          # Agent Sweep methodology: Carlini discovery/verification loops
    ├── swarm-pipeline.md                       # Swarm Pipeline methodology: module decomposition, 3-stage pass, analog cascade, weighted scoring, Phase 4
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

## Swarm Pipeline Command

For deep, structured, multi-agent audits with a continuous-learning feedback loop, the skill ships a companion slash command:

```
/vuln-swarm <target-repo-path>
```

The command drives a 5-phase SAST pipeline:

1. **Recency pass + patch-seed extraction** — Phase 0 plus a hypothesis-template list for downstream agents
2. **Holistic map + module decomposition** — 8–15 modules drive parallel fan-out
3. **Parallel narrow analysis** — module agents (orthogonal strategies, three-stage internal pass) + a sink-hunter lane
4. **2-check verification** — every finding re-traced AND semantically judged in separate agent calls
5. **Synthesis** — dedup → analog cascade → weighted scoring → chaining → exploitability gate → split into `confirmed.md` / `candidates.md`

A final Phase 4 pass proposes evidence-grounded additions back to the skill itself.

The command owns pipeline shape and the handoff contract; the skill owns taxonomy (sinks, bug classes, gates). Full methodology lives in `references/swarm-pipeline.md`. This is distinct from Agent Sweep mode (`references/agent-sweep.md`) — Agent Sweep is file-iteration with single-check verification; the Swarm Pipeline is module-structured with two-check verification, analog cascade, and the Phase 4 learning loop. Both coexist.

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

## CFG / AST / CPG Tooling

For deep-tier audits (`/vuln-swarm --effort=deep`) the pipeline runs a **static-first lane** that front-loads a mechanical CPG/PDG/taint pass before any LLM agent inspects a promoted module. The skill integrates four tool layers in priority order:

| Priority | Tool | Representation | Use Case |
|----------|------|----------------|----------|
| 1 | **[Joern](https://joern.io/)** | Code Property Graph (AST + CFG + DFG + call graph) | Full-program inter-procedural taint, PDG cuts, call-chain slicing. Best for C/C++/Java/JS/Python when a queryable graph is worth the indexing cost. |
| 2 | **[CodeQL](https://codeql.github.com/)** | Relational AST + dataflow library | Path queries from standard-library sources to sinks. SARIF output. Best when a pre-built query pack matches the stack (`javascript-security-and-quality`, `python-security-extended`, etc.). |
| 3 | **[Semgrep](https://semgrep.dev/) + [ast-grep](https://ast-grep.github.io/)** | Semantic patterns (Semgrep) + structural AST matching (ast-grep) | Cheapest rule-writing path. Combine for coverage: Semgrep for dataflow-aware rules, ast-grep for language-agnostic structural hunts. |
| 4 | **Fallback: `sinks/<lang>.md` grep catalog** | Plain text | When no CPG/SAST tooling is available — the per-language sink files are ripgrep-ready and enumerate every documented dangerous API. |

Outputs from layers 1–3 are consumed as **pre-built slices** packaged in the SecuritySlice input-packet format (source nodes, sink node, path, control guards, sanitizers seen) — LLM agents treat them as hypotheses to verify, not findings to rubber-stamp.

**Why CPG over AST-first?** For security analysis, raw AST lacks the edges that matter: data dependencies, control dependencies, call targets, and aliasing. A CPG merges all four, which means a single query answers "does untrusted input reach this sink under these guards?" without re-implementing dataflow per rule. The skill's `references/swarm-pipeline.md` § Slice Types documents 11 security-relevant slice cuts the tooling can emit (taint, sink-backward, source-forward, control-dependence, pdg, changed-code, auth-check, bounds-check, allocator-free, lock-unlock, crypto-use).

LOW and MEDIUM tiers do **not** require CFG/CPG tooling — they operate on source reads and the skill's sink catalogs directly. DEEP tier uses whichever layer is available and records the choice in `2-static/<module>.sarif` (or tool-native equivalent).

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

## References

### PortSwigger Top 10 Web Hacking Techniques (2017–2025)

The following annual research roundups were analyzed in full. Each technique cataloged above is sourced from these articles and the original research papers they cite.

- **2017:** James Kettle et al., "[Top 10 Web Hacking Techniques of 2017](https://portswigger.net/research/top-10-web-hacking-techniques-of-2017)". Panel: Kettle, Heyes, Grégoire, Rosén, Dalili. Notable: A New Era of SSRF (Orange Tsai #1), Web Cache Deception (Omer Gil #2), Ticket Trick (Inti De Ceukelaire #3).
- **2018:** James Kettle et al., "[Top 10 Web Hacking Techniques of 2018](https://portswigger.net/research/top-10-web-hacking-techniques-of-2018)". Panel: Kettle, Grégoire, Dalili, Filedescriptor. Notable: Breaking Parser Logic (Orange Tsai #1), Practical Web Cache Poisoning (Kettle #2), ESI Injection (#3), Prototype Pollution in Node.js (#4).
- **2019:** James Kettle et al., "[Top 10 Web Hacking Techniques of 2019](https://portswigger.net/research/top-10-web-hacking-techniques-of-2019)". Panel: Kettle, Grégoire, Dalili, Filedescriptor. Notable: Cached and Confused: Web Cache Deception (#1), Cross-Site Leaks (#2), SSRF on PDF generators (#3), Meta-Programming RCE in Jenkins (Orange Tsai #4).
- **2020:** James Kettle et al., "[Top 10 Web Hacking Techniques of 2020](https://portswigger.net/research/top-10-web-hacking-techniques-of-2020)". Panel: Kettle, Grégoire, Dalili, Filedescriptor. Notable: H2C Smuggling (Jake Miller #1), XSS for PDFs (Gareth Heyes #2), Attacking Secondary Contexts (Sam Curry #3), When TLS Hacks You (#4), NAT Slipstreaming (Samy Kamkar #5).
- **2021:** James Kettle et al., "[Top 10 Web Hacking Techniques of 2021](https://portswigger.net/research/top-10-web-hacking-techniques-of-2021)". Panel: Kettle, Grégoire, Dalili, Filedescriptor. Notable: Dependency Confusion (Alex Birsan #1), HTTP/2: The Sequel is Always Worse (Kettle #2), ProxyLogon Exchange Attack Surface (Orange Tsai #3), Client-Side Prototype Pollution (#4).
- **2022:** James Kettle et al., "[Top 10 Web Hacking Techniques of 2022](https://portswigger.net/research/top-10-web-hacking-techniques-of-2022)". Panel: Kettle, Grégoire, Dalili, Filedescriptor. Notable: Dirty Dancing OAuth Account Hijacking (Frans Rosén #1), Browser-Powered Desync Attacks (Kettle #2), Zimbra Memcache Injection (#3), Hacking the Cloud with SAML (Felix Wilhelm #4).
- **2023:** James Kettle et al., "[Top 10 Web Hacking Techniques of 2023](https://portswigger.net/research/top-10-web-hacking-techniques-of-2023)". Panel: Kettle, Grégoire, Dalili, Filedescriptor. Notable: Smashing the State Machine: Race Conditions (Kettle #1), Exploiting Hardened .NET Deserialization (#2), SMTP Smuggling (Timo Longin #3), PHP Filter Chains File Read (#4).
- **2024:** James Kettle et al., "[Top 10 Web Hacking Techniques of 2024](https://portswigger.net/research/top-10-web-hacking-techniques-of-2024)". Panel: Kettle, Grégoire, Dalili, STÖK, LiveOverflow. Notable: Confusion Attacks: Apache HTTP Server (Orange Tsai #1), SQL Injection Isn't Dead: Protocol Level (#2), TE.0 HTTP Request Smuggling (#3), WorstFit Unicode (Orange Tsai #4), DOMPurify mXSS (#5).
- **2025:** James Kettle et al., "[Top 10 Web Hacking Techniques of 2025](https://portswigger.net/research/top-10-web-hacking-techniques-of-2025)". Panel: Kettle, Grégoire, Dalili, STÖK, LiveOverflow. Notable: Successful Errors: SSTI Error-Based Techniques (#1), ORM Leaking (#2), Novel SSRF via HTTP Redirect Loops (#3), Unicode Normalization WAF Bypass (#4), SOAPwn .NET RCE (#5).

These articles are the authoritative community-curated source for novel web security research methodology. Each year's full nomination list contains 40–120+ additional entries beyond the top 10 — see individual articles for complete nomination lists.
