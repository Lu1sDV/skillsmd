# codeql

CodeQL analysis skill for Claude Code — interprocedural data flow and taint tracking across Python, JavaScript/TypeScript, Go, Java/Kotlin, C/C++, C#, Ruby, and Swift.

Originally from [`trailofbits/skills`](https://github.com/trailofbits/skills/tree/main/plugins/static-analysis/skills/codeql), adapted via `Lu1sDV/find-ctfs`.

## What it does

- Builds CodeQL databases (compiled and interpreted languages)
- Creates data extension models for project-specific sources/sinks CodeQL doesn't model by default
- Runs security query suites with explicit suite references (avoids silent query dropping)
- Processes SARIF output and investigates zero-finding results

## Installation

### Claude Code Plugin

```
/plugin install codeql@Lu1sDV/skillsmd
```

### Manual

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/codeql ~/.claude/skills/
```

### npx

```bash
npx skills add Lu1sDV/skillsmd codeql
```

## Usage

Trigger phrases: `"run codeql"`, `"codeql scan"`, `"codeql analysis"`, `"build codeql database"`, `"find vulnerabilities with codeql"`.

The skill auto-detects existing databases and guides you through:

1. **Build database** — traces the build or uses `build-mode=none` as a last resort
2. **Create data extensions** — models project-specific APIs as sources/sinks
3. **Run analysis** — executes explicit suite references across all installed packs (official + Trail of Bits + Community)

## Prerequisites

- `codeql` CLI on `$PATH` — [install guide](https://docs.github.com/en/code-security/codeql-cli/getting-started-with-the-codeql-cli/setting-up-the-codeql-cli)
- `jq` for SARIF processing
- Build toolchain for compiled languages (Java, C/C++, Go, C#)
