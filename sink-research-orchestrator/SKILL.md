---
name: sink-research-orchestrator
description: >
  Use when sink subagents encounter unseen languages or new technique categories
  that require fresh comprehensive research — not well-known sinks. Orchestrates
  parallel research swarms with structured JSON citations. Triggers: "comprehensive",
  "exhaustive", "most complete", "deep dive", "unseen language", "new technique
  category", "long horizon", "parallel research".
---

# Sink Research Orchestrator

> **When to use**: Load this reference when sink subagents encounter unseen languages or new technique categories that require fresh research — not well-known sinks.

> **Goal**: Produce the most complete, citable, and actionable analysis of a sink class or vulnerability family. Never stop at the first few hits. Read whole resources. Every finding must quote its source in structured JSON.

---

## Phase 0: Intent Clarification

Confirm the target before research begins:

| Question | Default |
|----------|---------|
| Language / ecosystem? | Whatever the target codebase uses |
| Technique categories? | All relevant categories, including niche and newly observed ones |
| Include well-known sinks? | No — prioritize unfamiliar, under-documented techniques |
| Citation format? | Structured JSON per finding |
| Output target? | A reference doc or sink catalog for the active language |
| Depth level? | Navigate full posts / writeups, not summaries |

If the request says “comprehensive”, “exhaustive”, or “most complete”, assume broad category coverage, JSON citations, and depth-first navigation.

---

## Phase 1: Parallel Research Swarm

### 1.1 Decompose the Topic

Break the target into 8–12 orthogonal research lanes. Each lane should be independent. Example lanes:

- Type / class confusion
- Property / prototype injection
- Race conditions and async escapes
- Runtime / serialization / parser abuse
- Filesystem / process edges
- Framework-specific gadgets

### 1.2 Spawn Agents in Parallel

Use parallel subagents for each lane.

**Each agent prompt must include:**

- Task: one atomic research goal.
- Expected outcome: concrete techniques, examples, and citations.
- Must do: find real writeups, read full resources, extract every relevant technique, and cite exact sources.
- Must not do: stop early, summarize without evidence, invent techniques, or skip important sections.
- Context: advanced sink research for a technical audience.

### 1.3 Autonomy Rule

Leave 3–4 subagents with full research autonomy:

- No narrow search terms beyond the category
- Ask them to find obscure techniques most developers have never seen
- Let them dig into edge cases, footnotes, and related links

---

## Phase 2: Result Collection & Synthesis

### 2.1 Wait for Completion

Do not poll. Wait for completion notifications, then collect results from the finished subagents.

### 2.2 Deduplicate & Cross-Reference

Build a synthesis that answers:

- Which techniques appeared in multiple lanes?
- Which techniques are unique to one lane?
- Are there contradictions across sources?
- What gaps remain after the first pass?

### 2.3 Verification Pass

For single-source findings, run a verification pass with a separate subagent:

- Confirm the behavior independently
- Prefer a second source or direct code evidence
- Mark false positives early

---

## Phase 3: Structured Output

### 3.1 Write to Target File

Write the final synthesis to the active sink reference or catalog file.

### 3.2 Format per Finding

```markdown
### <Title>
**Risk**: <One-line description>

```python
<Code example>
```
**Ref**: <Author — Title>.

```json
{ "sink_id": "CATEGORY-NNN", "category": "string", "title": "string", "severity": "critical|high|medium|low", "sources": [{ "type": "ctf_writeup|cve|issue|research_paper|blog_post|github_advisory", "url": "https://...", "title": "...", "author": "...", "date": "YYYY-MM-DD", "verified": true }], "detection_signature": "regex or structural pattern", "confidence": "confirmed|likely|theoretical" }
```
```

### 3.3 Category Prefixes

| Prefix | Category |
|--------|----------|
| RCE | Remote Code Execution |
| DESER | Deserialization |
| SSTI | Server-Side Template Injection |
| FILE | File Operations |
| SSRF | Server-Side Request Forgery |
| SQLI | SQL Injection |
| CLASS | Class Confusion / Type System |
| PROTO | Prototype / Property Injection |
| RACE | Race Conditions |
| ASYNC | Async / Generator |
| CTF | CTF / Sandbox Escape |
| STDLIB | Standard Library Hidden Sinks |
| CPYTHON | CPython Internals / Interpreter Bugs |
| SERIAL | Serialization Beyond Pickle |
| NUMERIC | Numeric / String Manipulation |
| PROTOCOL | Protocol / Parser Abuse |

---

## Phase 4: Long-Horizon Task Tracking

### 4.1 Create a Todo List Immediately

- Spawn parallel research subagents
- Collect and synthesize findings
- Write structured output with JSON citations
- Cross-reference and verify single-source findings
- Add detection signatures
- Validate that every finding has a citation

### 4.2 Update Todos Continuously

- Mark items in progress before work starts
- Mark them complete immediately after finishing
- Never batch status changes

### 4.3 Handoff Protocol

If interrupted, leave a concise handoff summary with completed work, current focus, next step, key files, blockers, and notes.

---

## Phase 5: Quality Gates

### Gate 1: Citation Completeness

Every `###` heading must have a JSON citation block.

### Gate 2: Source Verifiability

Every citation must include at least one URL. No uncited claims.

### Gate 3: Code Example Presence

Every finding must include a working or clearly illustrative code example.

### Gate 4: Confidence Calibration

- `confirmed`: multiple independent sources or direct evidence
- `likely`: one strong source plus solid reasoning
- `theoretical`: plausible mechanism without direct proof

---

## Anti-Patterns (Blocked)

| Anti-Pattern | Why Blocked |
|--------------|-------------|
| Stopping at first few results | Misses niche techniques |
| Summarizing without code | Unusable for practitioners |
| Skipping resources mid-read | Misses secondary techniques in the same source |
| No JSON citations | Unverifiable and hard to reuse |
| Single-source findings without verification | False positives |
| Batching todo updates | No real-time visibility |

> **Remember**: Great sink research is measured by depth, provenance, and actionability — not just the number of items collected.
