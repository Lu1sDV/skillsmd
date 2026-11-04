# refurbisher

A Claude Code skill that stops the agent from coding passively. Without it, a request for a
platform gets a platform scaffold. With it, the agent first asks who already did the hard
part:
- a product that mostly is the request;
- a standard for the category;
- a reference implementation;
- the exact module inside a mature project.

The agent tests the fit on a real case, names the precise gap, and comes back with
alternatives before writing anything. Reuse then happens by adopting, depending, forking,
porting or old-school copy-paste with attribution. Every source is vetted first, so
vibe-coded repositories never enter your codebase.

Small code, factual lookups and habits any good agent already has are out of scope.

## What it does

- **Triggers before the first scaffold:**
  - requests naming a category that probably exists (observability, error tracking, workflows);
  - requests too broad to fix the representation ("extract an IR");
  - security-critical infrastructure (sandboxes, auth, crypto), which is never improvised;
  - new but popular tasks that may already be standardized;
  - behavior defined by another product ("match Excel");
  - old hard problems inside new features;
  - implementations that keep failing.
- **Investigates:**
  1. Establishes the downstream questions.
  2. Finds candidates at every scale, reading current docs instead of memory.
  3. Maps one representative case into the candidate's data model, or prototypes the hardest query.
  4. Inspects deployment requirements and extension points.
  5. Names the missing capability.
- **Stops and gives alternatives:** adopt and adapt, extend, fork, port or build, with cost,
  license and lock-in. It recommends one and offers deeper research on the specific case.
- **Vets sources:**
  - hard gates: license (including source-available and open-core), nonexistent or typosquatted packages, unpatched critical advisories, archived repos, supply-chain red flags;
  - A–D trust tiers on two tracks: *established* and *young field* (for AI/ML);
  - authority overrides and demotions, always backed by named evidence;
  - vibe-code detection.
- **Integrates hygienically:**
  - an adapter you own around adopted platforms;
  - pinned dependencies;
  - `UPSTREAM.md` for vendored code;
  - SHA-pinned permalinks, license headers and upstream tests for copied code.

## Bundled script

`scripts/trust_signals.py` is stdlib-only Python 3.9+. It collects signals from the GitHub
REST and GraphQL APIs, the OpenSSF Scorecard API, ecosyste.ms, OSV and the npm registry.

```bash
python3 scripts/trust_signals.py encode/httpx+pypi:httpx sqlite/sqlite
python3 scripts/trust_signals.py npm:some-package
python3 scripts/trust_signals.py "https://github.com/python/cpython/blob/main/Lib/bisect.py#L1-L20"
python3 scripts/trust_signals.py --json --young-field org/new-ai-lib
```

It needs `gh auth login` or `GITHUB_TOKEN`: GraphQL has no anonymous access, and the
anonymous REST limit is 60 requests per hour. Targets run concurrently, at most 16 GitHub
requests at a time. A 4-candidate shortlist takes about 3 s.

## Installation

### Claude Code Plugin

```
/plugin install refurbisher@Lu1sDV/skillsmd
```

### npx

```bash
npx skills add Lu1sDV/skillsmd refurbisher
```

### Manual

```bash
cp -r refurbisher ~/.claude/skills/
```

## Usage

The skill triggers on its own when a request would make the agent scaffold something that
probably exists. You can also ask for it directly:

- "Build an observability platform for our agent harnesses."
- "Extract an intermediate representation from this codebase."
- "Run the commands our agent generates in a sandbox."
- "Should we depend on github.com/someone/fancy-agent-framework? Is it vibe-coded?"

## Files

```
refurbisher/
├── SKILL.md                              # triggers, investigation, alternatives, vetting, integration
├── references/
│   ├── worked-examples.md                # 12 investigations at the expected depth
│   ├── search-playbook.md                # products, standards, old systems, libraries, code to copy
│   ├── vibe-code-detection.md            # the sixth sense: channels, 5-minute protocol, verdicts
│   └── authority-calibration.md          # anchors, demotions, calibration examples, AI field
└── scripts/trust_signals.py              # signal collector and mechanical tiering
```
