# skillsmd

A collection of Claude Code skills — self-contained markdown files that give Claude specialized knowledge for specific tools, platforms, and workflows.

## Skills

| Skill | Description |
|-------|-------------|
| [cook](cook/) | Composable agent orchestration — review loops, repeat passes, parallel races, vs comparisons, ralph task-list progression |
| [ctfd](ctfd/) | Develop, debug, deploy CTFd platform — plugins, themes, Docker stack, testing |
| [debate](debate/) | Bounded multi-agent debate for contested 2–4 position decisions — pinned debaters, steelman swap, judge synthesis |
| [feature-engineering](feature-engineering/) | Time series feature engineering — calendar features, cyclical encoding, rolling stats, differencing |
| [glitchtip](glitchtip/) | Deploy, configure, integrate GlitchTip error tracking and uptime monitoring |
| [hermes-self-evolution](hermes-self-evolution/) | Hermes Agent-style self-evolving loop — memory, session recall, skill creation, and skill patching |
| [llm-domain-speedrun](llm-domain-speedrun/) | LLM-assisted domain speedrun learning — structured protocol for rapidly bridging knowledge gaps |
| [oauth-audit](oauth-audit/) | OAuth 2.0/OIDC security audits — RFC 9700 checklist, PKCE/state/redirect handling, JWT claim review |
| [ofelia](ofelia/) | Docker job scheduler — cron for containers via INI files or Docker labels |
| [photon-geocoder](photon-geocoder/) | Geocoding, reverse geocoding, and address autocomplete via Photon/OSM API |
| [sink-research-orchestrator](sink-research-orchestrator/) | Orchestrate parallel research swarms for unseen sink languages/techniques — lane decomposition, structured JSON citations, quality gates |
| [skillsmp-search](skillsmp-search/) | Search 11,000+ community skills and install them locally |
| [ssrf-testing](ssrf-testing/) | SSRF testing and prevention — detection, cloud metadata exploitation, filter bypass, defense strategies |
| [tavily-web](tavily-web/) | Web search, extraction, crawling, and AI-powered research via Tavily API (curl only) |
| [telethon-development](telethon-development/) | Telethon MTProto client — FloodWait handling, mocking, session management, DB integration |
| [test-engineering](test-engineering/) | Framework-agnostic test strategy, automation planning, coverage analysis |
| [tri-model-consensus](tri-model-consensus/) | Tri-model adversarial consensus — route tasks to Claude+Codex+Gemini, cross-grade discrepancies, merge the strongest output |
| [vuln-research](vuln-research/) | Vulnerability research, security auditing, code analysis — 30+ attack domains, 12-language sink catalog, SAST/DAST, chaining, PoC/report |
| [web-performance-optimization](web-performance-optimization/) | Lighthouse scores, Core Web Vitals, page load and rendering optimization |
| [zero-dof](zero-dof/) | Zero-DOF programming — executable oracles, opposing constraints, mandatory playbooks, gaming prevention for LLM coding agents |
| [zeroclaw](zeroclaw/) | Build, configure, deploy ZeroClaw AI agent infrastructure |

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
