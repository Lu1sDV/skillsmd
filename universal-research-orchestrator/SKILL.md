---
name: universal-research-orchestrator
description: Use when starting research, audit, or investigation tasks needing multi-source coverage — security/sink research, codebase audits, framework deep-dives, market comparison, or any "exhaustive / most complete / long horizon" request. Triggers on "audit", "investigate", "research", "find vulns", "exhaustive", "long horizon", "deep dive", "most complete".
---

# Universal Research Orchestrator

## Overview

Domain-agnostic 5-phase research pipeline:
SEARCH (parallel lanes) → SYNTHESIZE → PRODUCE → VALIDATE → ARCHIVE.

**Three rules:**
1. NEVER implement before gathering context.
2. NEVER stop at first result.
3. SYNTHESIZE before acting.

## Pipeline at a Glance

```
Phase 0: Calibrate scope    — domain, depth, output target
Phase 1: Search (parallel)  — 8–12 lanes, deep navigation, autonomous lanes
Phase 2: Synthesize         — cross-reference, verify, gap-fill
Phase 3: Produce            — structured output with citations
Phase 4: Validate           — completeness, citations, examples, confidence
Phase 5: Archive            — curl all source URLs, build _index.json
         Todo tracking      — real-time across all phases
```

---

## Phase 0: Scope Calibration

Confirm before searching. Default to **comprehensive** when the user says
"most complete", "exhaustive", or "long horizon".

- **Domain?** security / codebase / framework / market / general → ask if unclear
- **Depth?** summary / comprehensive / exhaustive → default comprehensive
- **Output target?** file path, format, citation style → ask if unclear
- **Include basics?** Default no — focus on niche, non-obvious, edge cases

---

## Phase 1: SEARCH — Maximize Coverage

### 1.1 Lane Decomposition

Break the target into **8–12 orthogonal research lanes**, each a standalone
parallel agent.

- **Orthogonal**: each lane targets a distinct surface; redundancy wastes agents.
- **2:1 directed-to-autonomous ratio**: for every 2 lanes with specific search terms, leave 1 lane with full research autonomy.
- **Minimum 8 lanes**. 10–12 is ideal.
- **Ecosystem coverage**: internals, stdlib/framework, community patterns, bleeding-edge, parser/serialization.

### 1.2 Agent Prompt Template (load-bearing)

Every parallel agent receives this structure. Adapt CONTEXT and lane-specific
TASK; do NOT modify MUST DO / MUST NOT DO.

```
1. TASK: [atomic, specific goal — one research lane]
2. EXPECTED OUTCOME: [N techniques/findings with concrete examples]
3. REQUIRED TOOLS: [web search, web fetch, grep, glob — as appropriate]
4. MUST DO:
   - Search real sources: writeups, docs, CVEs, papers, GitHub issues, CTF solutions
   - When you find a promising URL, FETCH the entire resource
   - Extract ALL relevant content from that resource, not just the headline
   - Provide concrete examples for EVERY finding
   - Cite exact source URLs, authors, dates
5. MUST NOT DO:
   - Stop at the first 3–5 results
   - Summarize without examples
   - Invent or hallucinate findings
   - Skip resources mid-read — navigate the whole thing
   - Return without at least one full-resource deep-read
6. CONTEXT: [domain, technical level, constraints]
```

**Autonomous lane variant** (for ~⅓ of lanes):
```
You have FULL research autonomy. No specific search terms beyond [domain].
Find obscure techniques/patterns that surprised even experienced practitioners.
Dig into corners of [domain] that are rarely documented.
```

### 1.3 Parallel Spawning

All agents spawn in a **single parallel batch** — never sequential.

```
# CORRECT — single message:
spawn(lane="class confusion",     prompt=..., background=true)
spawn(lane="race conditions",     prompt=..., background=true)
spawn(lane="stdlib hidden sinks", prompt=..., background=true)
...  # all 8–12 in ONE message

# WRONG — defeats parallelism:
spawn(...)  # wait for result
spawn(...)  # then next
```

Agent count by domain: security/framework research **8–12**; codebase
exploration **2–4 code-search + 2–4 web-research**; general **4–8**.

### 1.4 Deep Resource Navigation

When a search returns a promising URL: **fetch full content, extract every
distinct finding, not just the headline**. Read intro → all techniques →
conclusion. Never stop at a summary. Capture variants, caveats, and linked
issues.

### 1.5 Stop Conditions

Stop searching when:
- Same finding appears across 3+ independent sources
- 2 search iterations yielded no new useful data
- Direct answer found with high-confidence citation

### 1.6 Anti-Duplication

Once delegated to agents, do NOT perform the same search yourself.

---

## Phase 2: SYNTHESIZE

### 2.1 Collect Outputs

Wait for completion notifications. Do not poll.

### 2.2 Cross-Reference

| Question | Action |
|----------|--------|
| Appeared in multiple lanes? | Flag `confirmed` |
| Unique to one lane? | Flag `likely` — needs verification |
| Contradictions? | Resolve with targeted search |
| Gaps? | Note as blind spot; spawn gap-fill agent if critical |

### 2.3 Verification Pass

For findings with one source, spawn:
```
Verify this finding: [description]. Search for independent confirmation.
Return: CONFIRMED / PLAUSIBLE / FALSE POSITIVE with evidence.
```

### 2.4 Escalation

If findings are contradictory or high-stakes, halt and surface to the caller:
(a) competing claims, (b) evidence per side, (c) proposed resolution. Do not
proceed on a coin-flip.

### 2.5 Synthesis Document

3–10 bullets: target, key findings ranked by confidence, blind spots,
recommended next step.

---

## Phase 3: PRODUCE

### 3.1 Output Format by Domain

| Domain | Format |
|--------|--------|
| Security catalog | `### <Title>` + code example + JSON citation |
| Codebase audit | Architecture diagram + risk register + file index |
| Framework guide | Best practices + pitfalls + version matrix |
| Market research | Comparison matrix + recommendation + confidence |

### 3.2 Citation Schema (security catalog)

One JSON block per finding:
```json
{
  "id": "<lang>-<category>-<n>",
  "category": "type-confusion | race | stdlib-sink | parser | protocol | ...",
  "title": "<short, unique>",
  "source": [{"url": "...", "author": "...", "date": "YYYY-MM-DD"}],
  "confidence": "confirmed | likely | theoretical",
  "example": "<code, config, or command>",
  "archived_path": "sources/<id>/<filename>"
}
```
Validate every block parses. Double-escape backslashes in regex fields
(`\s` → `\\s`).

### 3.3 Dedup

Dedupe by title; keep the longest/most detailed version.

---

## Phase 4: VALIDATE — Quality Gates

1. **Completeness**: `grep -c "^###" file` == `grep -c '"source' file`.
2. **Verifiability**: every citation has a URL. No personal-knowledge claims.
3. **Examples**: every finding has a concrete code/config/command example.
4. **Confidence calibration**: `confirmed` = multi-source + working example; `likely` = one strong source; `theoretical` = plausible mechanism only.
5. **Deep-read audit**: sample 3 findings; verify the source URL was fully navigated, not just snippet-quoted.

---

## Phase 5: ARCHIVE — Source Preservation

URLs die. Archive every cited source.

1. Extract all unique URLs from citations
2. `curl -sL <url>` → `sources/<id>/<filename>.md`
3. Update each citation with `archived_path`
4. Build `_index.json`: `{id, url, archived_path, fetched_at, status}`
5. Budget bandwidth — full GitHub issue threads can run ~450KB each

---

## Todo Tracking

For any task with 3+ steps or parallel agents:

- Create todos at the start, one per phase or lane
- Mark `in_progress` BEFORE starting; `completed` IMMEDIATELY on finish — never batch
- Only one task `in_progress` at a time
- On interruption, write a handoff: completed / in-progress / next step / key files / blockers

---

## Anti-Patterns

| Anti-Pattern | Why Blocked |
|--------------|-------------|
| Implementing before gathering context | Builds wrong thing |
| Stopping at first 3–5 search results | Misses 80% of niche techniques |
| Spawning agents sequentially | Defeats parallel advantage |
| Same search terms across all lanes | Redundant coverage |
| No autonomous lanes | Misses findings no query would surface |
| Vague agent prompts (<5 lines) | Shallow, unusable results |
| Noting URL without extracting content | Citation without substance |
| Single-source findings without verification | False positives |
| No source archival | Findings become unverifiable when URLs die |
