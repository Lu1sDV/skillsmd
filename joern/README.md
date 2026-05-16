# joern

Joern Code Property Graph (CPG) analysis skill for Claude Code — interprocedural dataflow tracing, blast-radius mapping, sink hunting, and callgraph queries across 14+ languages.

Originally from [`Starknight-one/joern-skil`](https://github.com/Starknight-one/joern-skil), adapted via `Lu1sDV/find-ctfs`.

## What it does

- Builds a CPG from source once, then answers arbitrary structural/interprocedural questions instantly
- Traces taint flows from HTTP parameters to dangerous sinks (`exec`, shell, SQL, etc.)
- Maps blast radius before refactors ("what breaks if I change this function?")
- Finds dead code candidates, undocumented entry points, and cross-module call chains
- Saves reusable `.sc` query scripts for repeatable evidence in audit write-ups

## When to use vs CodeQL

| | Joern | CodeQL |
|---|---|---|
| Setup speed | Fast (one `joern-parse` command) | Slower (database build + pack install) |
| Language support | 14+ incl. binary frontends | 10 (no binary) |
| Taint suite depth | Moderate (manual queries) | Deep (canned suites for Java/JS/Python) |
| Best for | Fast structural sweeps, blast radius | Deep taint audits with community query packs |

Use Joern for fast sweeps; escalate to `codeql` skill for comprehensive taint analysis.

## Installation

### Claude Code Plugin

```
/plugin install joern@Lu1sDV/skillsmd
```

### Manual

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/joern ~/.claude/skills/
```

### npx

```bash
npx skills add Lu1sDV/skillsmd joern
```

## Prerequisites

- Java 21+
- Joern CLI — install via:

```bash
# Linux
curl -L https://github.com/joernio/joern/releases/latest/download/joern-cli.zip -o /tmp/joern.zip
unzip /tmp/joern.zip -d ~/joern && export PATH="$HOME/joern/joern-cli:$PATH"

# macOS
brew install joern
```

## Usage

Trigger phrases: `"joern"`, `"CPG"`, `"code property graph"`, `"blast radius"`, `"dataflow"`, `"taint trace"`, `"who calls X"`, `"callgraph"`, `"find sinks"`, `"interprocedural"`.
