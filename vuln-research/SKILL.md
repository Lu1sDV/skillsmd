---
name: vuln-research
description: >
  Use when performing vulnerability research, security auditing, code analysis,
  bug bounty hunting, CTF challenges, penetration testing, or exploit development.
  Covers source audit across 30+ attack domains, sink analysis for 12 languages,
  SAST/DAST integration, vulnerability chaining, and proof-of-concept development.
  Triggers: vuln assessment, pentest, bug bounty, security audit, find vulns,
  exploit, ctf, code audit, hunt bugs, 0-day, SAST, DAST, taint analysis,
  CI/CD pipeline security, GitHub Actions, Terraform, Traefik,
  n8n workflow, OpenTelemetry, supply chain attack, agent sweep,
  find me zero days, sweep everything, automated vuln discovery,
  binary analysis, reverse engineering, firmware audit, kernel driver,
  memory corruption, ROP, fuzzing harness, patch diffing.
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

**The Bitter Lesson, applied:** Vulnerability research has historically been 20% computer science and 80% solving giant, domain-specific jigsaw puzzles — learning font internals, memory allocator behavior, protocol edge cases. LLMs are universal jigsaw solvers. They encode the complete library of documented bug classes and vast correlations across source code. The structured methodology below channels this capability; the Agent Sweep mode unleashes it. Use both.

**Attention was load-bearing:** Much of the Internet's security has rested not on sound engineering alone, but on the scarcity of elite attention. Most code has never been seriously audited. Agent sweep economics change this — you can aim at everything, not just high-status targets.

The phases below are a **recommended workflow, not a rigid sequence** — skip, reorder, or loop as the target demands. The sink catalogs are **representative, not exhaustive** — new frameworks ship new dangerous functions daily. If you find a sink not listed here, it's still a sink. The checklists exist to prevent forgetting the obvious, not to replace thinking.

---

## Mode Selection

Choose a mode based on scope and intent before starting work:

| Mode | When to Use | Flow |
|------|-------------|------|
| **Targeted Audit** | Scoped engagement, specific components, compliance-driven | Phase 0 → Phases 1–7 below (existing workflow) |
| **Agent Sweep** | Full source tree available, maximize coverage, "find me everything" | Phase 0 → Phases S1–S4 → feeds into Phase 6 (Chaining) + Phase 7 (Gate) |
| **Hybrid** | Best of both — sweep for discovery, structured for exploitation | Phase 0 → Agent Sweep for discovery → Crown Jewel Mapping on findings → Phases 5–7 |
| **Swarm Pipeline** | Multi-agent SAST with effort tiers; invoked via `/vuln-swarm <path> [--effort=low\|medium\|deep] [--freeform=detached\|grounded]` | See `references/swarm-pipeline.md` § Effort Tiers. LOW = Phase 0 + freeform + Phase 3-lite; MEDIUM = full module fan-out + 2-check; DEEP = static-first lane + slice-type fan-out + 3-check + cross-slice reconciliation. |

**Phase 0 (Latest Commits Security Review)** runs first in every mode whenever the target has git history — a brownfield-only recency pass executed by a single focused subagent before the broader audit begins. See Phase 0 below.

**Default routing:**
- "audit this codebase" / "find vulns" (unscoped) → **Hybrid**
- "check the auth module" / specific component → **Targeted Audit**
- "find me zero days" / "sweep everything" → **Agent Sweep**

---

## Agent Sweep Mode (Phases S1–S4)

> Load `references/agent-sweep.md` for full prompt templates, scoring rubrics, and integration details.

When the goal is maximum coverage across a full source tree, use file-iteration with independent verification instead of domain-partitioned analysis. This is the Carlini methodology adapted for Claude Code.

### Phase S1: Source Tree Segmentation

1. **Enumerate** all source files — exclude vendored/generated code (`node_modules/`, `vendor/`, `dist/`, generated protobuf)
2. **Partition** into work units by directory/module (not by attack domain — that's Targeted mode)
3. **Prioritize** by Attention Deficit Score (see Phase 2 addition below) — least-examined, highest-exposure code first
4. **Include test files** — they reveal expected invariants that may not be enforced

### Phase S2: Discovery Loop

For each source file (or small cluster), spawn a parallel agent:

> "You are performing a security audit. Find exploitable vulnerabilities starting from `${FILE}`. Consider all bug classes — memory corruption, injection, logic flaws, auth bypass, deserialization, race conditions, type confusion, integer mishandling. Trace inputs from this file's entry points through the program. Write findings to `${FILE}.vuln.md` with: vuln type, affected function, source→sink trace, exploitability assessment, suggested payload."

**Design properties:**
- **File-anchored, not domain-anchored** — each agent starts from a file, not "look for SQLi." The LLM's latent bug-class knowledge drives discovery, not a checklist
- **Stochastic by construction** — different starting files produce different inference paths; running the same file twice may surface different bugs due to sampling
- **Follow imports** — agents aren't limited to their starting file; the file is the *anchor* that seeds exploration direction
- **Parallelizable** — agents are independent; scale linearly with compute

### Phase S3: Verification Loop

Feed each `.vuln.md` back through a **fresh agent** (not the discoverer — avoids confirmation bias):

> "You received an inbound vulnerability report in `${FILE}.vuln.md`. Verify this is actually exploitable. Trace the source→sink path yourself. Confirm controllability. Identify defense layers that might block it. Classify: **Confirmed** / **Plausible-Needs-Dynamic** / **False Positive**."

Expected filtration: ~40–60% of discovery findings survive verification.

#### 2-check variant (higher-confidence audits)

For audits that warrant stronger verification, upgrade the single-agent check to **two distinct checks executed as separate agent calls with separate prompts**. The two agents must not share a context window, and must not be told of each other's verdicts.

1. **RE-TRACE** — an independent source→sink walk. The agent receives the finding's location and is asked: *does the path exist as claimed? Can the source be controlled? Does the taint survive the transforms?* The agent produces its own trace from scratch without trusting the report's.

2. **JUDGE** — a semantic-correctness review. The agent receives the finding and its claimed root cause and is asked: *is the diagnosis correct? Is the bug class label accurate? Is the alleged data flow actually reachable in practice? Is the impact as stated, or over/under-claimed?*

Combine the two verdicts:
- **pass BOTH** → `Confirmed`
- **pass ONE** → `Candidate` (flag the disagreement in the report)
- **fail BOTH** → `False Positive`

Keeping the checks as **separate agent calls with separate prompts** is load-bearing. A single agent asked both questions collapses them into one mental pass and loses the independence that gives 2-check its precision. The full richer treatment — including how this plugs into weighted scoring — is in `references/swarm-pipeline.md` § Weighted Scoring.

**Structured JUDGE variant.** Instead of asking JUDGE "is this finding correct?" in free text, instruct it to build a DAG from scratch against the cited code: extract source nodes, build intermediate nodes with parent IDs and primitives, run the 12-pattern check, converge on a sink. A JUDGE pass that cannot close the graph from an untrusted source to a `verified_sink` is a **False Positive** verdict — no hedging. See `references/dag-reasoning.md` § "Phase S3 — Agent-Sweep Verification" for the exact prompt.

### Phase S4: Dedup, Cluster, Feed Forward

1. **Deduplicate** findings pointing to the same root cause from different starting files
2. **Cluster** by bug class and affected component
3. **Feed verified findings** into Phase 6 (Chaining) and Phase 7 (Exploitability Gate)
4. The sweep finds the raw bugs; the existing methodology scores, chains, and proves them

---

## Domain Reference Map

Load references on-demand based on the active testing domain. **Do not load all files at once.**

| Domain | Reference File | Load When |
|--------|---------------|-----------|
| SQLi, NoSQL, SSTI, CRLF, LDAP, XPath, LaTeX Injection, CSV Injection, XSLT Injection | `references/injection-attacks.md` | Testing injection vectors |
| XSS, Prototype Pollution, CORS, XS-Leaks, CSTI, postMessage | `references/client-side-attacks.md` | Testing client-side attacks |
| RCE, SSRF, XXE, File Ops, Deserialization | `references/server-side-attacks.md` | Testing server-side attacks |
| Auth, Access Control, OAuth, Logic, Race, Crypto | `references/auth-access-logic.md` | Testing auth & business logic |
| Smuggling, Cache, WebSocket, GraphQL, DNS, Cloud, Encoding, ReDoS, HTML Smuggling, Prompt Injection | `references/protocol-infra-attacks.md` | Testing protocols & infrastructure |
| CI/CD Pipelines, GitHub Actions, Supply Chain, Runner Security, Workflow Poisoning | `references/cicd-supply-chain.md` | Testing CI/CD and supply chain attacks |
| n8n, Zapier, Make.com, Power Automate, iPaaS, Webhooks, Workflow RCE, Credential Theft | `references/automation-platform-attacks.md` | Testing automation/iPaaS platforms |
| Traefik, Nginx, HAProxy, Reverse Proxy Bypass, Terraform State, Docker Socket, Container Escape | `references/infra-misconfig-attacks.md` | Testing infrastructure misconfigurations (proxy, IaC, containers) |
| OpenTelemetry, Prometheus, Grafana, Log Pipelines, Telemetry Poisoning, Collector SSRF, Cardinality Bombs | `references/observability-telemetry-attacks.md` | Testing observability/monitoring infrastructure |
| Sinks router + SAST/DAST rules | `references/sinks-catalog.md` | Code audit entry point — routes to per-language sink files |
| PHP sinks | `references/sinks/php.md` | PHP code audit (exec, callbacks, type juggling, phar deser) |
| Python sinks | `references/sinks/python.md` | Python code audit (exec, pickle, SSTI, subprocess) |
| Node.js sinks | `references/sinks/javascript.md` | JS/Node code audit (child_process, prototype pollution) |
| Java sinks | `references/sinks/java.md` | Java code audit (Runtime, JNDI, ysoserial, format-specific deser) |
| Ruby sinks | `references/sinks/ruby.md` | Ruby code audit (system/eval, Marshal, ActiveRecord) |
| .NET sinks | `references/sinks/dotnet.md` | .NET code audit (Process.Start, BinaryFormatter, Json.NET) |
| Systems sinks (Go/Rust/C/Elixir) | `references/sinks/systems.md` | Systems code audit (memory corruption, os/exec, ETF deser) |
| Mobile sinks (Android/iOS) | `references/sinks/mobile.md` | Mobile code audit (WebView, intents, URL schemes) |
| Binary / RE / firmware / kernel: triage, static RE, fuzzing, memory-corruption classes, binary-level races, patch diffing, exploit primitives, mitigations | `references/binary-code-analysis.md` (thin index → `binary-triage-and-re.md`, `binary-bug-classes.md`, `binary-exploit-and-specialties.md`) | Target is a compiled binary, firmware image, kernel/driver, closed-source blob, or native source whose ABI/compiler/ordering behavior matters. Load only the lifecycle file the active trigger cites (see Phase 3.5). |
| Vulnerability chaining, scanning tools, blind spots | `references/chaining-advanced-techniques.md` | Building exploit chains, tool augmentation |
| Formal audit, PoC development, report writing | `references/audit-poc-report.md` | **On-demand only** — when asked for audit/PoC/report |
| Agent sweep methodology, file iteration, verification loops | `references/agent-sweep.md` | Running Agent Sweep or Hybrid mode |
| Swarm pipeline: module decomposition, orthogonal strategies, three-stage pass, analog cascade, weighted scoring, Phase 4 continuous-learning | `references/swarm-pipeline.md` | Running the Swarm Pipeline command / hypothesis-driven multi-agent audit |
| DAG-structured vulnerability reasoning (DAGVul): source/intermediate/sink nodes, 12 failure-pattern taxonomy, logical closure | `references/dag-reasoning.md` | Writing a finding's source→sink trace, running the Swarm JUDGE check, or mechanically answering Phase 7 Exploitability Gate Q1–Q3 |

---

## Phase 0: Latest Commits Security Review

Before the broad audit begins, **spawn one focused subagent** to perform a narrow-scope security review of the repository's most recent commits. Recent diffs are the highest-signal starting surface in a brownfield target: they concentrate attacker-reachable new code, often touch security-adjacent paths (auth, routing, input parsing, config), and receive less scrutiny than older, stable modules. Reviewing them first primes the rest of the audit with concrete findings and calibrates the attack surface before Phase 1 (Recon) runs.

This is intentionally **single-agent and narrow-scope** — whole-tree coverage belongs in Agent Sweep (Phases S1–S4). Phase 0 exploits the recency signal without drifting into full-sweep territory. A swarm would dilute focus across the small commit surface and produce duplicated, low-signal findings.

### Subagent Prompt

Spawn exactly one agent with this prompt:

> You are performing a **focused, narrow-scope** security review of this repository's most recent commits. Inspect repo signals first — tag recency, branch divergence from `main`/`master`, commit cadence, CHANGELOG or release notes — then choose the most informative commit range yourself (e.g., last N commits, since last tag, or branch diff against main). **State the chosen range and justification before reviewing.**
>
> For every file touched by the selected commits, analyze **only the changed hunks and their immediate call graph**. Do not audit code the commits did not touch — that is Phase 3's and Agent Sweep's job, not yours. Consider all bug classes — injection, memory corruption, auth bypass, deserialization, race conditions, type confusion, logic flaws, missing authorization, unsafe defaults, exposed secrets, regressions that reintroduce previously-fixed CVEs, and weakened security controls (removed validators, loosened regex, new `@ts-ignore`/`# type: ignore` on security-adjacent code).
>
> For each finding write: vuln type, affected function/file, source→sink trace, controllability, exploitability assessment (High/Medium/Low), and a suggested payload or PoC direction. Flag commits that touch security-adjacent paths (auth, crypto, input parsing, session handling, access control, deser, SSRF-prone callers) even when no bug is found — the auditor needs to know where recent changes raise risk.
>
> Stay **very accurate and very focused**: no speculation, no "theoretical" findings without a controllability trace, no drift into untouched code. If the chosen range surfaces no real vulnerabilities, say so explicitly and list which security-adjacent files were examined so the rest of the audit can trust the recency pass.

### Optional Deliverable: PATCH SEEDS

When a downstream phase will fan out parallel agents (Agent Sweep, Swarm Pipeline, or any multi-agent audit that benefits from hypothesis templates), Phase 0 can emit a second artifact alongside the findings: a **PATCH SEEDS** list extracted from the same commit range. Each seed is a recently-fixed bug or tightened control that downstream agents use as a hypothesis template — "is an unfixed variant of this pattern present elsewhere in the tree?"

Each PATCH SEED record:

| Field | Content |
|-------|---------|
| `affected_file` | Path touched by the fix commit |
| `affected_hunk` | Hunk range or line numbers of the actual fix |
| `fix_summary` | One sentence describing what the patch changed and why |
| `bug_class` | Canonical class label (e.g., `sql-injection`, `missing-authz`, `path-traversal`) |
| `variant_query` | A grep-friendly or structural-search-friendly string downstream agents can use to locate analogous sites |

Emit seeds only for commits that actually fix a bug or tighten a control — not refactors, not style changes, not dependency bumps unless the bump closes a CVE. A seed without a clear `variant_query` is low-value; drop it rather than weaken the set.

### Fallbacks

| Condition | Behavior |
|-----------|----------|
| No `.git` directory / no git history | Skip Phase 0, proceed to Phase 1 |
| Fewer than 3 commits in history | Skip Phase 0, proceed to Phase 1 |
| Recent commits are docs-only or generated files only | Record `NO_CODE_CHANGES` with touched paths, proceed to Phase 1 |
| Subagent fails or times out | Log the failure, proceed to Phase 1 — do not retry inline |

### Feed-Forward

Phase 0 findings plug into the same downstream pipeline as Agent Sweep output:

1. **Dedup** against later Phase 3 (Source Audit) and any Agent Sweep results
2. **Feed** surviving findings into **Phase 6: Vulnerability Chaining**
3. **Gate** each finding through **Phase 7: Exploitability Gate** before reporting

Do not promote a Phase 0 finding to a reported vulnerability without passing Phase 7 — the exploitability gate applies equally to commit-sourced findings.

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
- PHP version (5.x / 7.x / 8.x) — gates which sinks are exploitable: `assert()` evals strings only in < 8.0, `preg_replace /e` only in < 7.0, loose type juggling `0 == "string"` only in < 8.0, `libxml_disable_entity_loader()` removed in 8.0 (XXE defaults safe), hex numeric strings `"0x1A" == 26` only in < 7.0. **Always qualify PHP findings with the version gate.**
- PHP config: `allow_url_include`, `allow_url_fopen`, `disable_functions`, `open_basedir`, `display_errors`, `file_uploads`, `session.upload_progress.enabled`
- Node.js: `--inspect` port, `NODE_ENV`, prototype pollution surface
- Python: debug mode (Werkzeug debugger PIN), pickle usage, SSTI surface
- Java: JNDI enabled, deserialization libraries, Expression Language version
- Container context: privileged mode, mounted volumes, exposed docker socket, inter-container network, environment secrets, Kubernetes service account tokens
- CDN / WAF fingerprint (Cloudflare, Akamai, ModSecurity rules — know what you're bypassing)
- Client-side: JS frameworks (React, Angular, Vue), bundler (webpack, vite), source maps available
- Dependency manifest: `package.json`, `composer.json`, `requirements.txt`, `Gemfile`, `pom.xml`, `go.mod`, `Cargo.toml`, `mix.exs`
- `patch-package` / `pnpm patch` / `yarn patch` overlays (`patches/*.patch`, `patches_*/*.patch`): read every patch in the tree and treat each removed/added hunk as security-relevant by default. Overlays silently mutate vendored SDK invariants (scoring rules, crypto surface, consent UX) and do not show up in dependency scanners. A patch that `export`s a previously-private crypto method, adjusts an auth scoreFlow, or deletes a `Confirm*` modal is a finding-generator by itself.
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

### Attention Deficit Mapping

After identifying crown jewels, identify the **least-examined** code — where bugs survive because nobody looked, not because the code is sound:

| Signal | High Attention (lower bug probability) | Low Attention (higher bug probability) |
|--------|---------------------------------------|---------------------------------------|
| **Security commits** | Has `fix: security`, CVE references, audit comments | No security-related commits in history |
| **Fuzzing/testing** | Fuzz targets exist, high test coverage | No fuzz corpus, low/no test coverage |
| **Code glamour** | Auth module, crypto, payment processing | Parser, format handler, protocol adapter, config loader, migration script |
| **External exposure** | Behind auth wall, internal-only | Processes attacker-controlled input (uploads, webhooks, public API) |
| **Code age** | Recently written/reviewed | Legacy code, "don't touch" modules, vendored-then-forgotten |

**Prioritize: high exposure + low attention.** These are the targets that have never seen a fuzzer. The crown jewels approach finds the highest-*impact* targets; attention deficit mapping finds the highest-*probability* targets. Use both.

Quick heuristics:
- `git log --format='%s' -- <path> | grep -ic 'secur\|vuln\|cve\|xss\|sqli\|inject'` — zero hits = never audited
- Check for adjacent `*_test.*`, `*_spec.*`, `fuzz_*` files — absence = untested
- `git log --diff-filter=M --since="2 years ago" -- <path>` — no recent changes = stale, possibly forgotten

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

Every module agent MUST conclude its report with a **Blind Spots** block: files it did not read, components absent from the repo but referenced elsewhere (other-repo Rust halves, dynamically-fetched configs, production-only artifacts), runtime states it could not observe (OIDC discovery docs, feature-flag evaluation), and dependencies whose behavior gates its findings' severity. Blind spots are first-class output, not footnotes. Phase 6 chain synthesis consumes this list to flag findings whose severity depends on external evidence.

---

## Phase 3.5: Technology Stack Discovery (Sink Loading)

Before taint analysis, identify **every language and framework in the stack** — most targets are polyglot:

1. **Enumerate languages**: scan file extensions, shebangs, `package.json`/`composer.json`/`pom.xml`/`go.mod`/`Cargo.toml`/`mix.exs`/`Gemfile`/`requirements.txt`
2. **Identify the stack layers**: e.g., PHP backend + Node.js build tooling + Python microservice + Java auth service
3. **Load matching sink files**: for each language present, load the corresponding `references/sinks/<lang>.md` — load multiple if the target is polyglot
4. **Load the SAST/DAST router**: `references/sinks-catalog.md` for cross-language Semgrep/CodeQL/SonarQube rules

**Example**: a Laravel app with React SSR and a Python ML microservice → load `sinks/php.md` + `sinks/javascript.md` + `sinks/python.md`

Do not skip minor languages in the stack — the weakest link is often the least-reviewed service.

**Binary / native artifacts in the stack — tiered loading across three lifecycle files.** Source-level sinks stop at the compiler; ABI, memory ordering, calling conventions, packers, and machine-level race windows require binary audit. The binary reference is split into three lifecycle files — **orient**, **find bugs**, **prove and report** — plus a thin routing index at `references/binary-code-analysis.md`. Load only what the trigger cites; never the whole triad by default.

| Trigger (any match → load) | File(s) and section(s) to read first |
|---|---|
| Target artifact is ELF / PE / Mach-O / WASM / dex / firmware blob / kernel module / bootloader / TEE payload | `references/binary-triage-and-re.md` § 1 → § 2 → § 2b |
| Source audit hit a `.so` / `.dll` / `.dylib` / static `.a` with no matching source | `references/binary-triage-and-re.md` § 2–4, then `references/binary-bug-classes.md` § 10 |
| Source is present but contains C / C++ / Rust `unsafe` / Go `cgo` / Zig / Objective-C / inline `asm!` where ABI or ordering changes semantics | `references/binary-bug-classes.md` § 6 + § 7 + § 15 |
| Hypothesis involves memory layout, stack alignment, calling convention, endianness, signal delivery mid-instruction, syscall atomicity, double-fetch, weak memory model | `references/binary-bug-classes.md` § 7 + § 8 + § 15 |
| N-day work: public advisory + patched vs. unpatched binary, no source diff | `references/binary-exploit-and-specialties.md` § 11 |
| Crash found but no source explanation — the bug may live in compiler output / linker glue / TLS callback / `.init_array` | `references/binary-triage-and-re.md` § 4 + `references/binary-bug-classes.md` § 15 |
| Packed, VM-protected, anti-debug, or otherwise obfuscated sample | `references/binary-exploit-and-specialties.md` § 13b |
| Building or claiming an exploit primitive (ROP/SROP/ret2dlresolve/JOP/heap grooming) | `references/binary-exploit-and-specialties.md` § 13 + § 14 |
| Firmware image / IoT / router / printer / camera / automotive ECU | `references/binary-exploit-and-specialties.md` § 12.1 |
| Kernel / driver / hypervisor / TEE target | `references/binary-exploit-and-specialties.md` § 12.2–12.5 + § 14 |
| Writing a fuzz harness or running dynamic analysis | `references/binary-bug-classes.md` § 5 |
| Building a binary-level taint DAG | `references/binary-bug-classes.md` § 10 |
| Writing a binary finding report | `references/binary-exploit-and-specialties.md` § 16 (DAG block required — ties back to Phase 7 Gate) |

**Do not load the whole triad by default.** On targets with no native component, none of the above triggers fire and these files stay off the token budget. On triggered targets, load only the subfile(s) the matched trigger cites. When no single trigger dominates, start with `references/binary-code-analysis.md` (thin index, ~60 lines) and fan out from there.

**Binary findings integrate with the source pipeline unchanged:** they feed **Phase 6 Chaining** as primitives (info-leak / arb-read / arb-write / control-flow) and pass **Phase 7 Exploitability Gate** via the same DAG form as source findings — with `primitive ∈ {taint, cfg, alias, constraint, abi}` and `abi` nodes citing the calling convention / register / struct layout being relied on. See `references/binary-bug-classes.md` § 10 (Binary-Level Taint Framework) and `references/binary-exploit-and-specialties.md` § 16 (Output Format) for the binary-specific DAG vocabulary.

### Tool-Integration Matrix (CPG / SAST / AST tooling)

For DEEP-tier Swarm Pipeline runs and any audit where a mechanical pre-pass is available, select in priority order:

| Priority | Tool | Representation | When to use |
|----------|------|----------------|-------------|
| 1 | **Joern** | Code Property Graph (AST + CFG + DFG + call graph) | Full inter-procedural taint, PDG cuts, call-chain slicing. Best when a queryable graph justifies indexing cost (large C/C++/Java/JS/Python targets). |
| 2 | **CodeQL** | Relational AST + dataflow library | Path queries from stdlib sources to sinks. SARIF output. Use when a pre-built query pack matches the stack. |
| 3 | **Semgrep + ast-grep** | Semantic patterns (Semgrep) + structural AST matching (ast-grep) | Cheapest rule-writing path. Semgrep for dataflow-aware rules; ast-grep for language-agnostic structural hunts. |
| 4 | **Fallback: `sinks/<lang>.md` grep** | Plain text | No CPG/SAST tooling available — the per-language sink files are ripgrep-ready. |

Outputs from layers 1–3 are packaged as SecuritySlice input packets (see `references/dag-reasoning.md` § SecuritySlice Input Packet) for LLM consumption. LLM agents treat tool hits as **hypotheses to verify**, never as findings to rubber-stamp.

**Why CPG over AST-first:** Raw AST lacks the security-relevant edges — data dependencies, control dependencies, call targets, aliasing. A CPG merges all four, which means one query answers "does untrusted input reach this sink under these guards?" without re-implementing dataflow per rule. See `references/swarm-pipeline.md` § Slice Types for the 11 slice cuts the tooling can emit.

---

## Phase 4: Taint Analysis

Three strategies — choose based on codebase size:

| Strategy | When | Method |
|----------|------|--------|
| **Source-forward** | Small codebase, few entry points | Trace from user input → through transforms → to sinks |
| **Sink-backward** | Large codebase, known dangerous functions | Start at sinks (see `sinks-catalog.md`) → trace backward to find controllable inputs |
| **Hybrid** | Medium codebase, complex data flow | Combine both: forward from sources AND backward from sinks, meet in the middle |
| **Circulatory tracing** | Any codebase, complement to other strategies | Map the full journey of every input through *all* program domains — not just to known sinks, but through every transformation and domain crossing |

**Controllability classification** for each sink parameter:
- **High**: Direct user input reaches sink with no sanitization
- **Medium**: Input reaches sink through partial transforms (encoding, type casting)
- **Low**: Input is significantly constrained but still partially controllable
- **Needs verification**: Theoretical path exists, requires dynamic confirmation

**Output filter internals:** When a template engine or framework marks output as "safe" or "escaped", verify HOW it escapes. Django's `|safe`, Twig's `|raw`, Rails' `html_safe`, React's `dangerouslySetInnerHTML`, and Jinja2's `|safe` all disable auto-escaping — but even auto-escaped output can be vulnerable in non-HTML contexts (JavaScript strings, CSS `url()`, HTML attributes without quotes). A filter labeled `is_safe` in Django means "this filter's output doesn't need further escaping" — it does NOT mean the output IS safe. Trace through the filter chain to confirm the escaping matches the output context.

**Circulatory tracing insight:** Vulnerabilities hide not in the obvious "security" parts of programs but where inputs cross into unexpected domains. Trace inputs through *every* domain boundary — not just to known sinks:
- HTTP parameter → YAML parser → object instantiation → method dispatch (Rails YAML RCE)
- Uploaded image → image library → font rendering subsystem → memory allocator (browser RCE)
- User string → template engine → compilation → code execution (SSTI)
- Config value → DNS resolver → network request → internal service (SSRF via config)

The domain knowledge needed is "arbitrary" — font internals, serialization formats, protocol edge cases. The LLM already encodes this. **Ask about every code path the input touches**, not just paths that look security-relevant.

Load `references/sinks-catalog.md` for the language router and SAST/DAST integration rules. It routes to per-language sink files — load only the language(s) matching the target codebase.

**DAG-structured trace (for high-stakes findings).** Free-prose source→sink narration is the single highest source of hallucinated findings — the DAGVul paper measured 36.4% of correct LLM vulnerability verdicts as supported by *incorrect* reasoning. When a finding will be reported (not just observed), restate its trace as a DAG: ground-truth source nodes with line refs → intermediate inference nodes that cite parent IDs and name the program-analysis primitive (taint, def-use, CFG, constraint, API contract) → a `verified_sink` or `sanitized_sink`. If the graph does not close from an untrusted source to a verified sink, the finding is not exploitable — move it to Observations rather than hedging. Load `references/dag-reasoning.md` for the framework, the 12 failure patterns to screen each intermediate node against, and worked examples.

---

## Phase 4.5: Static Analysis False Positive Calibration

SAST tools generate noise. Calibrate expectations before triaging:

| Severity | Typical False Positive Rate | Action |
|----------|---------------------------|--------|
| **P0/P1** (Critical/High) | 30–50% | Triage every finding manually — high FP rate but high impact when real |
| **P2** (Medium) | 50–70% | Batch triage, prioritize sinks with direct user input |
| **P3** (Low) | 70–90% | Skim for patterns, don't chase individual findings |

**Common false positive patterns:**
- **Dead code sinks**: Function exists but is never called from a reachable route
- **Framework-sanitized paths**: SAST flags `innerHTML` but React's JSX auto-escapes; flags `query()` but ORM parameterizes
- **Test file hits**: SAST scanning test fixtures, mock data, or example payloads
- **Vendor/third-party code**: Flagging sinks in `node_modules/`, `vendor/`, or vendored dependencies
- **Constant inputs**: Sink reached only with hardcoded/constant values, not user input

**Calibration workflow:**
1. Run SAST, sort by severity descending
2. For P0/P1: manually verify each — trace source to sink, confirm controllability
3. For P2/P3: sample 10 findings, measure FP rate, extrapolate to decide effort allocation
4. Suppress confirmed false positives with inline comments or tool-specific ignore rules
5. Track FP rate per rule — disable rules consistently above 90% FP in your stack

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

Before reporting ANY finding, answer these four questions:

1. **Can I control the input?** — Is user input actually controllable, or is it server-generated/hardcoded?
2. **Does it reach the sink?** — Does the tainted data survive all transforms, sanitizers, and WAF rules?
3. **Can I prove impact?** — Do I have a working payload that demonstrates real-world consequences?
4. **Where is the defense layer?** — Is the mitigation in the vulnerable code itself, in a framework layer (e.g. Django auto-escaping, Rails CSRF tokens), in runtime config (e.g. `disable_functions`, WAF rules), or in the deployment environment (e.g. network segmentation, read-only filesystem)? Framework and runtime defenses can be bypassed or misconfigured — verify the defense is actually active, not just assumed.

If any answer to questions 1-3 is **No** → move to Observations section (not confirmed vulnerabilities). For question 4, if a defense exists but you can bypass it, document the bypass as part of the finding.

**Mechanical gate via DAG.** Questions 1–3 map one-to-one onto a closed DAG: Q1 is "at least one source node typed as untrusted input", Q2 is "a complete path of intermediate nodes from source to sink", Q3 is "a `verified_sink` with a stated triggering condition". When a finding keeps shifting its controllability story, build the DAG — if it does not close, Q2 is **No** and the finding drops to Observations. Reference: `references/dag-reasoning.md`.

### Defense Layer Iteration

When a defense layer blocks exploitation, don't stop — treat it as **a new iteration of the same problem**:

1. **Identify the defense boundary** — sandbox, hardened allocator, kernel separation, WAF, hypervisor
2. **Treat the defense itself as a new attack surface** — it's software too, with its own bugs
3. **Apply the same methodology recursively** — sweep or audit the defense layer's code for bypasses
4. **Chain across boundaries** — vuln in app + sandbox escape + kernel bug = full-chain exploit

Layered defenses (hardened allocators, sandboxes, user/kernel barriers, virtualization) are iterated versions of the same problem. Agents can generate full-chain exploits by solving each layer independently and composing the results.

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

### Always-Rejected Findings (Do Not Report)

These are commonly submitted findings that bug bounty programs universally reject. Do not waste time reporting them unless they are part of a demonstrated exploit chain with proven impact:

| Finding | Why It's Rejected | When It Becomes Valid |
|---------|-------------------|---------------------|
| Missing security headers alone (`X-Frame-Options`, `X-Content-Type-Options`, `Strict-Transport-Security`) | No demonstrated impact — headers are defense-in-depth | Only if missing header is a **required prerequisite** in a working exploit chain (e.g., missing `X-Frame-Options` + clickjacking PoC with state change) |
| CORS wildcard (`Access-Control-Allow-Origin: *`) without credential exfiltration | Browsers block `*` + `withCredentials` — no cookie/token leakage | Only if combined with `Access-Control-Allow-Credentials: true` AND sensitive data exfiltrated in PoC |
| GraphQL introspection enabled alone | Introspection is a development feature, not a vulnerability | Only if introspection reveals mutations/fields that lead to demonstrated auth bypass or data leak |
| Open redirects without OAuth/auth chaining | Low impact — redirect to phishing page is social engineering, not a technical vuln | Only when chained: open redirect → OAuth token theft → ATO, or open redirect → SSRF filter bypass |
| SSRF with DNS-only callbacks (no response, no internal access) | Proves DNS resolution but not exploitability — most programs require demonstrated internal access or data exfil | Only if callback proves access to internal network (response data, cloud metadata, or internal service interaction) |
| Self-XSS (requires victim to paste payload in their own browser) | Attacker cannot trigger it remotely — requires social engineering the victim | Only when chained with cookie tossing, login CSRF, or clickjacking to deliver the payload without victim cooperation |
| Server/technology banner disclosure (`Server: Apache/2.4.51`, `X-Powered-By: PHP/8.1`) | Version information alone is not exploitable | Only if the disclosed version has a known, exploitable CVE AND you demonstrate the exploit working |
| Shell/exec sink where the "user-controlled" arg is a hardcoded string constant | Grep for the interpolated symbol; if it is assigned once to a string literal and never reassigned, the finding is a false positive. Dead-code guards (`if (false) { ... }`) that share a filename with a live sink are a common conflation trap | Only when dynamic user input is confirmed to flow into the sink at runtime |
| Regex-chain across modules where each link uses a different regex | Do not assume two regex constants "feed" each other just because they target the same domain. Confirm the data-flow path: source → regex A → transform → regex B. If A's output is not literally B's input, there is no chain | Only when the actual data-flow path source → regex A → regex B is traced end-to-end |

**Rule of thumb:** if the finding requires the phrase "an attacker could theoretically..." without a working PoC, it belongs in Observations, not Vulnerabilities.

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
- [ ] RSS/Atom/XML feed parsers (CDATA blocks bypass HTML sanitizers — `<![CDATA[<script>alert(1)</script>]]>` renders as HTML when feed content is displayed)
- [ ] Archive extraction endpoints (Zip Slip via `../` in filenames — `ZipArchive`, `PclZip`, `tar`, `unzip` without path validation)
- [ ] Runtime/language version gates (PHP < 8.0 type juggling, PHP < 7.0 `/e` modifier, Python 2 `input()` = `eval()`, Node.js `--inspect` open debugger)
- [ ] Template output filter internals (`|safe`, `|raw`, `html_safe`, `is_safe` — verify escaping matches the output context, not just that a filter is applied)

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
