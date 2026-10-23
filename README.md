# skillsmd

A collection of Claude Code skills — self-contained markdown files that give Claude specialized knowledge for specific tools, platforms, and workflows.

## Skills

| Skill | Description |
|-------|-------------|
| [codeql](codeql/) | CodeQL security analysis — interprocedural taint tracking, database build, data extensions, SARIF processing across 10 languages |
| [cook](cook/) | Composable agent orchestration — review loops, repeat passes, parallel races, vs comparisons, ralph task-list progression |
| [ctfd](ctfd/) | Develop, debug, deploy CTFd platform — plugins, themes, Docker stack, testing |
| [debate](debate/) | Bounded multi-agent debate for contested 2–4 position decisions — pinned debaters, steelman swap, judge synthesis |
| [feature-engineering](feature-engineering/) | Time series feature engineering — calendar features, cyclical encoding, rolling stats, differencing |
| [fuzzgpt](fuzzgpt/) | History-driven LLM fuzzing (FuzzGPT-derived, arXiv:2304.02014) — mine bug history, auto-label buggy APIs, few-shot/zero-shot/retrieval edge-case generation, crash + differential oracles; target-agnostic, pairs with vuln-research |
| [bug-bounty-reporting](bug-bounty-reporting/) | Write concise, human-sounding bug bounty reports with direct-impact PoCs, claim-to-evidence gates, transactional cleanup, and frozen-snapshot independent verification |
| [glitchtip](glitchtip/) | Deploy, configure, integrate GlitchTip error tracking and uptime monitoring |
| [joern](joern/) | Joern CPG analysis — interprocedural dataflow, blast-radius mapping, sink hunting, callgraph queries across 14+ languages |
| [hermes-mr-watch](hermes-mr-watch/) | Safely configure remote Hermes GitLab MR lifecycle watchers over SSH |
| [hermes-self-evolution](hermes-self-evolution/) | Hermes Agent-style self-evolving loop — memory, session recall, skill creation, and skill patching |
| [jev](jev/) | Write Jev judgment-model programs — noul/choice/score selection, instruction and criteria craft, minimal state, full HTTP API (POST /v1/systemone), confidence-gated composition, symptom-to-fix revision table |
| [llm-domain-speedrun](llm-domain-speedrun/) | LLM-assisted domain speedrun learning — structured protocol for rapidly bridging knowledge gaps |
| [oauth-audit](oauth-audit/) | OAuth 2.0/OIDC security audits — RFC 9700 checklist, PKCE/state/redirect handling, JWT claim review |
| [obsidian-spaced-repetition](obsidian-spaced-repetition/) | Manage Obsidian Spaced Repetition through the official CLI — flashcards, decks, review commands, and scheduling-safe note edits |
| [ofelia](ofelia/) | Docker job scheduler — cron for containers via INI files or Docker labels |
| [opengrep-rule-creator](opengrep-rule-creator/) | OpenGrep-first rule authoring — offline rule-writing docs, version-specific compatibility, four complex commented rules, and evidence-based publication gates |
| [photon-geocoder](photon-geocoder/) | Geocoding, reverse geocoding, and address autocomplete via Photon/OSM API |
| [python-idiomatic](python-idiomatic/) | Everyday Python — object semantics, iteration, decorators, exceptions, imports, environments and tooling |
| [python-algorithms](python-algorithms/) | Collection selection and all 17 Python algorithm patterns with invariants, complexity and boundary cases |
| [python-stdlib](python-stdlib/) | Standard-library APIs — iterators/caching, files/time, serialization/regex, records, cleanup, logging and subprocesses |
| [python-api-design](python-api-design/) | Python-native API design — typing, protocols, SOLID, consolidated design patterns, descriptors and class contracts |
| [python-concurrency](python-concurrency/) | Threads, processes, asyncio, cancellation, backpressure, shutdown, free threading and interpreter isolation |
| [python-tdd](python-tdd/) | Test-first Python — red-green-refactor, pytest/unittest, fixtures/doubles, properties, real boundaries and test CI |
| [python-system-design](python-system-design/) | Python application architecture — packages, WSGI/ASGI, frameworks, background jobs, transactions and configuration |
| [python-exploitation](python-exploitation/) | Offensive Python & CTF — pyjail/sandbox escape, builtins recovery, import/char blacklist bypass, pickle/marshal RCE, Jinja2/RestrictedPython SSTI, PEP 578 audit-hook bypass, bytecode crafting, 3.8–3.13 internals |
| [security-fix-oracle](security-fix-oracle/) | Mine a repo's git history into a labeled, leakage-free security-fix dataset — Haiku/Sonnet triage, merge-safe diff fetch, gold/weak tiers, CVSS 3.1 (LLM vector + procedural score), SZZ vulnerability-introducer attribution + skill-gap; runnable harness included |
| [skill-smell-checker](skill-smell-checker/) | Audit all 26 SKILL.md smells from arXiv:2607.01456 — 5 deterministic harness checks plus 21 evidence-backed semantic checks |
| [sink-research-orchestrator](sink-research-orchestrator/) | Orchestrate parallel research swarms for unseen sink languages/techniques — lane decomposition, structured JSON citations, quality gates |
| [skillsmp-search](skillsmp-search/) | Search 11,000+ community skills and install them locally |
| [rust-guidelines](rust-guidelines/) | Compact Rust API and engineering checklist — topic-based disclosure, explicit contracts, opt-in memory profiles, and verification |
| [rust-idiomatic](rust-idiomatic/) | Ownership and lifetimes, errors, iterators, strings, standard-library usage, and everyday Cargo/tooling workflows |
| [rust-algorithms](rust-algorithms/) | Collection selection and 17 algorithm patterns with Rust-specific invariants, complexity, and boundary cases |
| [rust-api-design](rust-api-design/) | Rust-native API design — enums versus traits, builders, typestate, newtypes, composition, and consolidated design patterns |
| [rust-type-diagnostics](rust-type-diagnostics/) | Advanced Rust type diagnosis — coercion sites and generic barriers, reference patterns, implied lifetime bounds, variance, exact `Any` downcasts, trait upcasting, and drop checking |
| [rust-concurrency](rust-concurrency/) | Threads, Send/Sync, locks, channels, async coordination, cancellation, shutdown, backpressure, and Rayon |
| [rust-performance](rust-performance/) | Writing and reviewing fast Rust plus evidence-first optimization — allocation/reuse, iterators, layout, hashing, async/backpressure, build profiles, Clippy gates, baselines, profiling, benchmarks, contention, and NUMA triage |
| [rust-tdd](rust-tdd/) | Test-first Rust development — red-green-refactor, regression fixes, property tests, test doubles, coverage, and testable design |
| [rust-macros](rust-macros/) | Declarative and procedural macros — matching, hygiene, generated APIs, diagnostics, expansion, and testing |
| [rust-unsafe-ffi](rust-unsafe-ffi/) | Unsafe proof obligations and native FFI — pointer validity, ownership, ABI/layout, unwinding, safe wrappers, and verification |
| [rust-wasm](rust-wasm/) | Browser WebAssembly and WASI/components — targets, JS bindings, boundary contracts, packaging, deployment, and testing |
| [ssrf-testing](ssrf-testing/) | SSRF testing and prevention — detection, cloud metadata exploitation, filter bypass, defense strategies |
| [tavily-web](tavily-web/) | Web search, extraction, crawling, and AI-powered research via Tavily API (curl only) |
| [telethon-development](telethon-development/) | Telethon MTProto client — FloodWait handling, mocking, session management, DB integration |
| [test-engineering](test-engineering/) | Framework-agnostic test strategy, automation planning, coverage analysis |
| [tri-model-consensus](tri-model-consensus/) | Tri-model adversarial consensus — route tasks to Claude+Codex+Gemini, cross-grade discrepancies, merge the strongest output |
| [universal-research-orchestrator](universal-research-orchestrator/) | Domain-agnostic 5-phase research pipeline — parallel 8–12 lane search, synthesis, citation, validation, source archival for exhaustive research tasks |
| [universal-skill-finder](universal-skill-finder/) | Search SkillsMP + skills.sh in one pass — merged results table with a Market column showing where each skill was found (skillsmp / skills.sh / both) |
| [vast-experiment-ops](vast-experiment-ops/) | Operate and report Vast.ai GPU experiments — TF32 FP32-equivalence failures on CUDA, SSH-banner-corrupted JSON metrics, accurate held-out/test-scope claims |
| [vuln-research](vuln-research/) | Vulnerability research, security auditing, code analysis — 30+ attack domains, 12-language sink catalog, SAST/DAST, chaining, PoC/report |
| [web-performance-optimization](web-performance-optimization/) | Lighthouse scores, Core Web Vitals, page load and rendering optimization |
| [zero-dof](zero-dof/) | Zero-DOF programming — executable oracles, opposing constraints, mandatory playbooks, gaming prevention for LLM coding agents |
| [zeroclaw](zeroclaw/) | Build, configure, deploy ZeroClaw AI agent infrastructure |

## Python skill suite

Seven task-oriented skills consolidate the [17 StructWeave Python guides](https://github.com/nirajkvinit/StructWeave-Algorithms/tree/0b88a786ef09681717a805d9f7e0b195ab610f6c/languages/python),
pinned at Python-content commit `0b88a786ef09681717a805d9f7e0b195ab610f6c`.
Each bundle installs independently and contains its own progressive references,
usage/installation README, runnable examples, source/adaptation map, and upstream
MIT notice. The existing `python-exploitation` skill remains separate and unchanged.

| Macro-topic | Skill | Source chapters |
|---|---|---|
| Language, idioms and everyday tooling | [python-idiomatic](python-idiomatic/) | 01 syntax, 03 idioms; general tooling from 08; language pitfalls from 13–14 |
| Data structures and algorithms | [python-algorithms](python-algorithms/) | 02 collections, all 17 patterns in 04; algorithm APIs from 05 |
| Standard-library boundaries | [python-stdlib](python-stdlib/) | 05 utilities, 16 production standard library |
| Typing, API contracts and design patterns | [python-api-design](python-api-design/) | 06 typing, 09 SOLID, 10–12 creational/structural/behavioral patterns; class pitfalls from 13–14 |
| Concurrency and parallel execution | [python-concurrency](python-concurrency/) | 07 concurrency/async; relevant traps from 13–14 |
| Test-driven development | [python-tdd](python-tdd/) | 17 TDD; testing/test CI from 08 and test pitfalls from 13 |
| Application and service architecture | [python-system-design](python-system-design/) | 15 system design |

Consolidation decisions:

- Group by activation task; distribute interview traps and anti-patterns to the
  relevant domain rather than create overlapping skills.
- Keep typing/SOLID/patterns together as API contracts, separate from service
  runtime, transaction and deployment boundaries.
- Merge the two stdlib catalogues; keep algorithm invariants in python-algorithms.
- Keep TDD standalone; general environment/debug/lint/profiling stays in
  python-idiomatic, while test execution and test CI belong to python-tdd.
- Keep bundles independent, preserve explicit version gates, and record source
  corrections instead of copying forecasts or universal safety/speed claims.

Run the `python3 -m doctest` commands in each bundle's README from the checkout or
an isolated copied bundle. Non-doctest framework, process, static-checker and
optional-dependency recipes declare their prerequisites separately. Existing CI
discovers `SKILL.md` files automatically; no hand-maintained manifest is added.

### Authoring review

Reviewed against [Anthropic's skill authoring guidance](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).
Entrypoints now contain routing, workflows and essential guards; detailed examples
and API catalogues load on demand. All 26 references remain directly reachable from
their skill, with contents lists for navigation.

| Measure | Before review | After review | Reduction |
|---|---:|---:|---:|
| Combined `SKILL.md` body words | 7,605 | 3,629 | 52.3% |

Unique examples were moved intact; only the duplicate mutable-default example and
generic return-42 TaskGroup example were removed. Descriptions retain the repository's
required `Use when` opening rather than adopting the guide's third-person preference.

### Python suite verification

Verified on 2026-10-23 with CPython 3.14.8 after the concision review:

- Two independent final reviews covered all seven bundles; no actionable findings
  remain. All entrypoints passed YAML and the five static skill-smell checks.
- Isolated installs passed 693 doctest checks and 247 local link/anchor checks;
  licenses and all retained executable fences match the reviewed baseline.
- Eight pytest/Hypothesis cases, `spawn`/`forkserver` process pools and the
  interpreter-executor recipe passed. The relocated threshold mutant failed at
  the intended boundary, then the original passed. Both concurrency regressions
  remain exercised.
- Seven fresh-context routing probes selected the intended skill and reference.
  These probes do not establish Haiku/Sonnet/Opus cross-model effectiveness.
- Older Python versions, Windows, free-threaded builds, optional frameworks/brokers,
  static-checker acceptance and production deployment remain unverified.

## Rust skill suite

Eight task-oriented skills consolidate the [18 StructWeave Rust guides](https://github.com/nirajkvinit/StructWeave-Algorithms/tree/49e7f127eaf0fc71694a4b53f31ac3a2b8cdb168/languages/rust).
The existing `rust-performance` remains the ninth Rust skill; it owns measured
optimization rather than duplicating the new skills' correctness workflows.

The compact [rust-guidelines](rust-guidelines/) checklist complements these nine
skills with API and engineering review guidance; its six references load by topic.

[rust-type-diagnostics](rust-type-diagnostics/) adds focused compiler/type
reasoning drawn from a full review of *Advanced Rust* and checked against primary
Rust documentation. Its four topic references cover coercions and patterns,
implied bounds and variance, type erasure, and drop checking. It hands ordinary
ownership, API design, concurrency, performance, and unsafe/FFI work back to the
existing skills rather than repeating their workflows. The source book is not
bundled; original examples and a correction/source map are included.

| Catalogue chapters | Primary destination |
|---|---|
| 01 syntax, 02 ownership, 05 idioms, 17 standard library | `rust-idiomatic`; synchronization routes to `rust-concurrency` |
| 03 data structures, 04 algorithm patterns | `rust-algorithms` |
| 06 concurrency | `rust-concurrency` |
| 07 tooling | General project workflow in `rust-idiomatic`; test execution and test CI in `rust-tdd` |
| 08 SOLID, 09–11 design patterns, 12 anti-patterns | `rust-api-design`; domain-specific pitfalls live beside the relevant workflow |
| 13 interview traps | Distributed into the corresponding domain references, not a separate interview skill |
| 14 macros | `rust-macros` |
| 15 unsafe/FFI | `rust-unsafe-ffi` |
| 16 WebAssembly | `rust-wasm` |
| 18 test-driven development | `rust-tdd` |

Consolidation decisions:

- Group by activation task, not by textbook category. Syntax and standard-library
  tables are references; SOLID and GoF categories inform concrete API choices.
- Keep TDD standalone: test-first development is a workflow, not a Cargo option.
- Keep macros, unsafe/FFI, and Wasm separate: generated syntax, native memory
  safety, and target/runtime integration require different checks.
- Preserve individual installation: each new bundle contains its references,
  source attribution, and the upstream MIT notice. Handoffs name optional skills
  rather than requiring sibling directories.
- Treat StructWeave as source material, not a correctness oracle. Adapted guidance
  records preconditions and version assumptions; unsupported empirical claims and
  blanket performance prescriptions are not carried over.

Each new skill's README documents checkout-based installation and example checks.
The existing CI discovers `SKILL.md` files automatically for validation and manifest
generation; no hand-maintained skill manifest is required.

### Rust suite verification

Verified on 2026-10-11 with Rust 1.98.1:

- Eight independent reviewer audits completed. The macro review found a generated
  primitive-name shadowing defect; the corrected recipe includes a downstream
  regression case, reproduced failing before the fix and passing afterward.
- All eight bundles passed YAML metadata, upstream-notice, and isolated-copy
  installation checks; 133 local documentation links resolved without siblings.
- 71 Rustdoc checks passed across 24 documents, including intentional compile
  failures. The TDD example's documented boundary bug produced the intended
  assertion failure.
- The complete procedural-macro Cargo consumer and real C-to-Rust ABI caller ran
  successfully. Browser/WASI runtimes, Miri, sanitizers, and other optional
  ecosystem recipes were not executed; their prerequisites and commands remain
  explicit in the relevant references. This is not an MSRV certification.

## Commands

Some skills ship companion slash commands that orchestrate multi-phase agent pipelines. Commands own pipeline shape and handoff contracts; the paired skill owns taxonomy and judgment.

| Command | Ships With | Purpose |
|---------|-----------|---------|
| [/vuln-swarm](vuln-research/commands/vuln-swarm.md) | [vuln-research](vuln-research/) | 5-phase SAST swarm with recency + patch seeds, module decomposition, orthogonal-strategy fan-out, 2-check verification, analog cascade + weighted scoring synthesis, and a continuous-learning feedback pass |

## Installation

### Claude Code Plugin (recommended)

```
/plugin marketplace add Lu1sDV/skillsmd
```

Then select **Browse and install plugins** → **Lu1sDV/skillsmd** → choose the skill you want.

Or install directly:

```
/plugin install <skill-name>@Lu1sDV/skillsmd
```

### Manual

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/<skill-name> ~/.claude/skills/
```

### npx

```bash
npx skills add Lu1sDV/skillsmd
```

### Verify

In Claude Code:

```
What skills are available?
```
