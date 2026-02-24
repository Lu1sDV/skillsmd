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
/plugin install skillsmp-search@Lu1sDV/skillsmd
```

After installing the plugin, you can use the skill by just mentioning it. For instance, if you install the `zeroclaw` plugin from the marketplace, you can ask Claude Code to do something like: "Use the zeroclaw skill to deploy my agent infrastructure"

### Clone and install

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/zeroclaw ~/.claude/skills/
cp -r skillsmd/ctfd ~/.claude/skills/
cp -r skillsmd/glitchtip ~/.claude/skills/
cp -r skillsmd/metaskills/skillsmp-search ~/.claude/skills/
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
| **skillsmp-search** | `metaskills/skillsmp-search/` | Search 11,000+ community skills and install them locally |
