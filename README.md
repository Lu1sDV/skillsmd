# skillsmd

Personal skills collection for Claude Code.

## Installation

### Claude Code

You can register this repository as a Claude Code Plugin marketplace by running the following command in Claude Code:

```
/plugin marketplace add Lu1sDV/skillsmd
```

Then, to install a specific set of skills:

1. Select **Browse and install plugins**
2. Select **Lu1sDV/skillsmd**
3. Select the skill you want (e.g. `zeroclaw`, `ctfd`, `glitchtip`, `skillsmp-search`)
4. Select **Install now**

Alternatively, directly install a plugin via:

```
/plugin install zeroclaw@Lu1sDV/skillsmd
/plugin install ctfd@Lu1sDV/skillsmd
/plugin install glitchtip@Lu1sDV/skillsmd
/plugin install photon-geocoder@Lu1sDV/skillsmd
/plugin install test-engineering@Lu1sDV/skillsmd
/plugin install web-performance-optimization@Lu1sDV/skillsmd
/plugin install ofelia@Lu1sDV/skillsmd
/plugin install skillsmp-search@Lu1sDV/skillsmd
/plugin install tavily-web@Lu1sDV/skillsmd
/plugin install telethon-development@Lu1sDV/skillsmd
/plugin install ssrf-testing@Lu1sDV/skillsmd
/plugin install vuln-research@Lu1sDV/skillsmd
/plugin install cook@Lu1sDV/skillsmd
/plugin install zero-dof@Lu1sDV/skillsmd
/plugin install llm-domain-speedrun@Lu1sDV/skillsmd
```

After installing the plugin, you can use the skill by just mentioning it. For instance, if you install the `zeroclaw` plugin from the marketplace, you can ask Claude Code to do something like: "Use the zeroclaw skill to deploy my agent infrastructure"

### Clone and install

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/zeroclaw ~/.claude/skills/
cp -r skillsmd/ctfd ~/.claude/skills/
cp -r skillsmd/glitchtip ~/.claude/skills/
cp -r skillsmd/photon-geocoder ~/.claude/skills/
cp -r skillsmd/test-engineering ~/.claude/skills/
cp -r skillsmd/web-performance-optimization ~/.claude/skills/
cp -r skillsmd/ofelia ~/.claude/skills/
cp -r skillsmd/skillsmp-search ~/.claude/skills/
cp -r skillsmd/tavily-web ~/.claude/skills/
cp -r skillsmd/telethon-development ~/.claude/skills/
cp -r skillsmd/ssrf-testing ~/.claude/skills/
cp -r skillsmd/vuln-research ~/.claude/skills/
cp -r skillsmd/cook ~/.claude/skills/
cp -r skillsmd/zero-dof ~/.claude/skills/
cp -r skillsmd/llm-domain-speedrun ~/.claude/skills/
```

### npx

```bash
npx skills add Lu1sDV/skillsmd
```

### Verify

In Claude Code, check the skill is loaded:

```
What skills are available?
```

Or invoke directly:

```
/zeroclaw
```

## Skills

| Skill | Path | Description |
|-------|------|-------------|
| **zeroclaw** | `zeroclaw/` | Build, configure, deploy ZeroClaw AI agent infrastructure |
| **ctfd** | `ctfd/` | Develop, debug, deploy CTFd platform — plugins, themes, Docker stack, testing |
| **glitchtip** | `glitchtip/` | Deploy, configure, integrate GlitchTip error tracking and uptime monitoring |
| **photon-geocoder** | `photon-geocoder/` | Geocoding, reverse geocoding, and address autocomplete via Photon/OSM API |
| **test-engineering** | `test-engineering/` | Framework-agnostic test strategy, automation planning, coverage analysis |
| **web-performance-optimization** | `web-performance-optimization/` | Lighthouse scores, Core Web Vitals, page load and rendering optimization |
| **ofelia** | `ofelia/` | Docker job scheduler — cron for containers via INI files or Docker labels |
| **skillsmp-search** | `skillsmp-search/` | Search 11,000+ community skills and install them locally |
| **tavily-web** | `tavily-web/` | Web search, extraction, crawling, and AI-powered research via Tavily API (curl only) |
| **telethon-development** | `telethon-development/` | Telethon MTProto client — FloodWait handling, mocking, session management, DB integration |
| **ssrf-testing** | `ssrf-testing/` | SSRF testing and prevention — detection, cloud metadata exploitation, filter bypass, defense strategies |
| **vuln-research** | `vuln-research/` | Vulnerability research, security auditing, code analysis — 30+ attack domains, 12-language sink catalog, SAST/DAST, chaining, PoC/report |
| **cook** | `cook/` | Composable agent orchestration — review loops, repeat passes, parallel races, vs comparisons, ralph task-list progression |
| **zero-dof** | `zero-dof/` | Zero-DOF programming — executable oracles, opposing constraints, mandatory playbooks, gaming prevention for LLM coding agents |
| **llm-domain-speedrun** | `llm-domain-speedrun/` | LLM-assisted domain speedrun learning — structured protocol for rapidly bridging knowledge gaps using an LLM as a private tutor |
