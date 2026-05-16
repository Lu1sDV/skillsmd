---
name: joern
description: Use when auditing code for vulnerabilities, assessing change impact, tracing dataflow, finding callers/callees of a function, mapping a refactor's blast radius, hunting sinks across a large codebase, or needing repeatable interprocedural queries over a Code Property Graph. Triggers: "joern", "CPG", "code property graph", "blast radius", "dataflow", "taint trace", "who calls X", "callgraph", "dead code", "find sinks", "interprocedural".
license: MIT
origin: Originally from https://github.com/Starknight-one/joern-skil — adapted via Lu1sDV/find-ctfs (2026-05-16).
---

# Joern Code Property Graph Analysis

## Overview

Joern parses source code into a **Code Property Graph (CPG)** — AST + CFG + dataflow merged into one queryable graph. After a one-time build (~30s–several min depending on codebase size), all subsequent queries are interactive and avoid repeated `grep`/`find`/manual call-tracing.

**Core principle:** Pay the parse cost once, then ask the same codebase arbitrarily many structural / interprocedural questions instantly.

**Companion to CodeQL:** Joern is faster to set up and supports 14+ languages; CodeQL has stronger taint libraries for Java/JS/Python. Use joern for fast structural sweeps, CodeQL for deep canned taint suites.

## When to Use

- Pre-refactor: "what breaks if I change this function?" → `blast_radius`
- Vuln research: "every call into `Runtime.exec` reachable from an HTTP handler" → `reachableBy`
- Unknown codebase: "what are the public entry points / sinks of this module?"
- Patch diffing: build CPGs for pre/post commits, query the diff for new sinks
- When `grep` is too coarse (catches comments, string literals, false matches)

## When NOT to Use

- Single-file question — just `Read` it
- Codebase too small to justify CPG build (<20 files)
- You need a one-shot answer the LSP can give faster (`lsp_find_references`)

## Setup

Joern is a CLI. Install once:

```bash
# Linux
curl -L https://github.com/joernio/joern/releases/latest/download/joern-cli.zip -o /tmp/joern.zip
unzip /tmp/joern.zip -d ~/joern && export PATH="$HOME/joern/joern-cli:$PATH"

# macOS
brew install joern
```

Requires Java 21+.

## Core Workflow

### 1. Build a CPG (once per codebase / commit)

```bash
# Auto-detect language
joern-parse <path-to-src> --output cpg.bin

# Force a frontend (faster, fewer surprises)
joern-parse <path-to-src> --frontend javasrc2cpg   --output cpg.bin
joern-parse <path-to-src> --frontend jssrc2cpg     --output cpg.bin
joern-parse <path-to-src> --frontend pysrc2cpg     --output cpg.bin
joern-parse <path-to-src> --frontend gosrc2cpg     --output cpg.bin
joern-parse <path-to-src> --frontend c2cpg         --output cpg.bin   # C/C++
```

Frontends: `c2cpg`, `javasrc2cpg`, `jssrc2cpg`, `pysrc2cpg`, `gosrc2cpg`, `kotlin2cpg`, `rubysrc2cpg`, `swiftsrc2cpg`, `csharpsrc2cpg`, `php2cpg`, plus binary frontends (`ghidra2cpg`, `jimple2cpg`).

### 2. Query interactively or via script

```bash
# REPL
joern
joern> importCpg("cpg.bin")
joern> cpg.method.name("exec").caller.name.l

# Headless one-shot
joern --script query.sc --param cpgFile=cpg.bin
```

### 3. Common queries (CPG Query Language / Scala-DSL)

```scala
// Blast radius — who transitively calls method `getCursor`?
cpg.method.name("getCursor").caller.repeat(_.caller)(_.emit.times(3)).name.dedup.l

// All sinks: any call to Runtime.exec/ProcessBuilder
cpg.call.methodFullName("(?i).*(Runtime.exec|ProcessBuilder).*").l

// Dataflow: from any HTTP param to exec()
def src = cpg.parameter.name("(?i).*(req|request|params).*")
def snk = cpg.call.methodFullName(".*exec.*")
snk.reachableByFlows(src).p

// Callers of a function with file:line
cpg.method.name("spawn_worker").caller.location.toJsonPretty

// Methods in a directory
cpg.method.filename(".*scripts/adw/decompose/.*").name.l

// Dead code candidates (no callers, not exported)
cpg.method.internal.where(_.caller.size(0)).name.l   // ⚠ false positives: callbacks, framework hooks, API handlers
```

### 4. Save scripts under version control

Drop reusable queries into `.joern/queries/*.sc` and run headless:

```bash
joern --script .joern/queries/find_ssrf_sinks.sc --param cpgFile=cpg.bin > findings.json
```

## Quick Reference

| Goal | Query |
|------|-------|
| Find a method | `cpg.method.name("X").l` |
| Direct callers | `cpg.method.name("X").caller.l` |
| Transitive callers (depth 3) | `cpg.method.name("X").caller.repeat(_.caller)(_.emit.times(3)).l` |
| Callees | `cpg.method.name("X").callee.l` |
| All calls to a fully-qualified target | `cpg.call.methodFullName(".*target.*").l` |
| Param → sink dataflow | `snk.reachableByFlows(src).p` |
| File-scoped query | `.filename(".*path/.*")` |
| External (3rd-party) vs internal | `.external` / `.internal` |
| Location (file:line) | `.location` or `.lineNumber` |

## CPG Hygiene

- **Stale CPG** is the #1 footgun. Rebuild after any meaningful source change. Tie the build to a git commit hash:
  `joern-parse src --output cpg-$(git rev-parse --short HEAD).bin`
- Large codebases: `--max-num-def 2000` to cap dataflow expansion, or use `--exclude-regex` to skip vendored/`node_modules` paths.
- For monorepos: build per-module CPGs; cross-module queries take exponentially longer.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Querying stale CPG after edits | Rebuild. Verify with `cpg.metaData.l` (timestamp) before trusting results. |
| Wrong frontend → empty graph | Check `cpg.method.size` immediately after import; if 0 you picked the wrong language. |
| Treating `dead_code` results as ground truth | Always cross-check: framework callbacks (Flask routes, Spring `@RequestMapping`, JS event handlers) look dead but aren't. |
| Forgetting `.l` to materialize | `cpg.method.name("X")` returns a Steps traversal; `.l` evaluates to a list. |
| Dataflow returns nothing | Default `reachableByFlows` respects taint semantics — make sure source/sink are *Call/Parameter nodes*, not method nodes. |
| Confusing `methodFullName` vs `name` | `name` = bare identifier; `methodFullName` = fully qualified incl. signature. Sinks usually need `methodFullName`. |
| Building CPG in source tree | Always output to a separate `.joern/` dir; CPG files are large and shouldn't be committed. |

## Project Integration

- Pre-build CPGs per target audit under `.joern/<target>/cpg.bin` (excluded from git via `.gitignore`).
- Store reusable queries in `.joern/queries/` and reference from finding write-ups so reviewers can re-run.
- Pair with `vuln-research` skill: joern produces structured `reachableByFlows` evidence that subagents can include in `verdict.md`.
- Complement `codeql` skill: run joern for fast structural sweeps, escalate to CodeQL when deeper taint suite coverage is needed.

## References

- Official docs: https://docs.joern.io
- CPG Query Language: https://docs.joern.io/cpgql/
- Frontend list: https://docs.joern.io/frontends
- Query database (curated examples): https://queries.joern.io
