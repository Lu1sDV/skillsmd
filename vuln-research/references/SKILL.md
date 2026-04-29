---
name: comprehensive-python-sink-research-workflow
description: >
  Master skill documenting the complete workflow for exhaustive security sink
  research, from parallel agent spawning through structured citation and source
  archival. Covers the full lifecycle: research → synthesis → formatting →
  validation → archival. Use as reference for any "most complete" security
  analysis project.
---

# Comprehensive Python Sink Research Workflow

> **Session**: 2026-04-29
> **Scope**: Build the most complete Python security sinks catalog with structured
> JSON citations and full source archival.
> **Output**: 95 niche findings, 3,705-line catalog, 91 archived sources, 5 reusable skills.

---

## Phase 0: User Intent & Constraints

**Original Request**: "I'm interested in niche ignored sinks (class confusions,
prototypes, race-conditions in python). Spawn 10 parallel research subagents that
learn tricks from non-obvious writeups & CTF caveats. Ignore well-understood bugs.
Leave 4 subagents full research autonomy."

**Subsequent Requests**:
- Resume/restart research (multiple rounds)
- Write findings to `vuln-research/references/sinks/python.md`
- Navigate entire resources when found
- Create agnostic skill from prompts
- JSON citations on every finding
- Long-horizon task with todo tracking
- Save source of findings (per citation)
- Create skill per message/instruction

**Hard Constraints**:
- Every finding MUST have JSON citation with source URL
- Focus on niche/ignored, not well-known (SQLi, XSS, RCE basics excluded)
- Full resource navigation (no summaries)
- Parallel research only (no sequential agent spawning)

---

## Phase 1: Parallel Research Swarm (2 Rounds)

### Round 1: Initial Discovery (10 Librarian Agents)

| Agent | Lane | Focus |
|-------|------|-------|
| A1 | Class Confusion | `__class__.__init__.__globals__`, metaclass abuse, MRO manipulation |
| A2 | Prototype Pollution | `setattr` chains, `__globals__` traversal, pydash/pymongo variants |
| A3 | Race Conditions | `filelock` TOCTOU, `tempfile.mktemp`, `shutil.move` atomicity |
| A4 | Async/Generator | `gi_frame.f_globals`, coroutine frame escape, `asyncio.Task` UAF |
| A5 | Stdlib Hidden Sinks | `ast.literal_eval`, `ctypes` overflow, `http.server` redirect |
| A6 | CTF Tricks | Decorator AST bypass, ZIP polyglots, `breakpoint()` abuse |
| A7 | Type Confusion | `isinstance` fast-path, ABC cache corruption, `register()` bypass |
| A8 | Serialization | `memoryview` UAF, `pandas.eval()`, protobuf recursion |
| A9 | Numeric/String | `statistics.stdev()` infinity, `re` catastrophic backtracking |
| A10 | Obscure Internals | `_posixsubprocess.fork_exec`, `antigravity` hijack, `/proc/self/mem` |

**Autonomy Allocation**: Agents A7–A10 had full autonomy ("find obscure techniques
most developers have never heard of").

**Result**: Initial merged report `python_niche_sinks_research.md` with 40+ techniques.

### Round 2: Deep Dive (10 Librarian Agents with webfetch)

Same lane decomposition, but with explicit `webfetch` instructions:
- Read entire blog posts, not summaries
- Extract secondary techniques from same resource
- Navigate CTF writeups fully (all solve stages)

**Result**: Expanded to 80+ techniques with full PoC code and exact citations.

### Anti-Patterns Enforced

| Blocked | Why |
|---------|-----|
| Stopping at first 5 search results | Misses niche findings |
| Summarizing without code | Unusable for practitioners |
| Skipping resources mid-read | Misses secondary techniques |
| Sequential agent spawning | Defeats parallel advantage |

---

## Phase 2: Synthesis & Document Creation

### Main Catalog: `python.md`

**Structure**:
```
# Python Sinks
## [Category] — Well-Known
<inline code list of common sinks>

## [Category] — Niche / Hidden
### <Finding Title>
**Risk**: <Description>

```python
<PoC code>
```
**Ref**: <Author — Title>.

```json
<citation block>
```
```

**Final Stats**:
- 95 niche findings (deduplicated from 98 parsed)
- 15 categories: RCE, DESER, SSTI, FILE, SSRF, SQLI, CLASS, PROTO, RACE, ASYNC, CTF, STDLIB, CPYTHON, PROTOCOL, NUMERIC
- 3,705 lines
- Zero duplicate sink_ids
- Every `###` heading has exactly one JSON block

### JSON Citation Schema

```json
{
  "sink_id": "CATEGORY-NNN",
  "category": "CLASS|CPython|CTF|...",
  "title": "Human-readable name",
  "severity": "critical|high|medium|low",
  "affected_versions": ["3.8+", "3.9+"],
  "sources": [
    {
      "type": "ctf_writeup|cve|github_issue|blog_post|...",
      "url": "https://...",
      "title": "...",
      "author": "...",
      "date": "YYYY-MM-DD",
      "cve_id": "CVE-YYYY-NNNNN",
      "gh_issue": "gh-NNNNNN",
      "archived_path": "sources/CATEGORY-NNN/filename.md",
      "verified": true,
      "tags": ["pyjail", "sandbox-escape"]
    }
  ],
  "related_cves": ["CVE-..."],
  "related_issues": ["gh-..."],
  "detection_signature": "regex pattern",
  "mitigation": "brief note",
  "confidence": "confirmed|likely|theoretical"
}
```

### Category Taxonomy (16 prefixes)

| Prefix | Category | Count |
|--------|----------|-------|
| RCE | Remote Code Execution | 4 |
| DESER | Deserialization | 4 |
| SSTI | Server-Side Template Injection | 3 |
| FILE | File Operations | 8 |
| SSRF | Server-Side Request Forgery | 1 |
| SQLI | SQL Injection | 1 |
| CLASS | Class Confusion / Type System | 14 |
| PROTO | Prototype / Property Injection | 4 |
| RACE | Race Conditions | 3 |
| ASYNC | Async / Generator | 6 |
| CTF | CTF / Sandbox Escape | 12 |
| STDLIB | Standard Library Hidden Sinks | 14 |
| CPYTHON | CPython Internals | 16 |
| SERIAL | Serialization Beyond Pickle | (merged into DESER) |
| NUMERIC | Numeric / String Manipulation | 1 |
| PROTOCOL | Protocol / Parser Abuse | 4 |

---

## Phase 3: Parallel Reformatting (6 Sections)

Because `python.md` grew to 1,232 lines, JSON citation insertion was split across
6 parallel `task(category="deep")` agents:

| Section | Lines | Agent | Duration |
|---------|-------|-------|----------|
| 1 | 1–200 | Sisyphus-Junior | 5m 29s |
| 2 | 201–400 | Sisyphus-Junior | 4m 02s |
| 3 | 401–600 | Sisyphus-Junior | 6m 36s |
| 4 | 601–800 | Sisyphus-Junior | 6m 28s |
| 5 | 801–1000 | Sisyphus-Junior | 4m 39s |
| 6 | 1001–end | Sisyphus-Junior | 5m 39s |

**Deduplication**: 3 findings appeared in multiple sections (ZIP polyglot,
`__loader__`, `dir()` escape). Longest version kept.

**JSON Validation**: All 95 blocks parse successfully. Two required escape-fixing
for regex patterns (`\s`, `\*`, `\(` in `detection_signature` fields).

---

## Phase 4: Source Archival

### Problem
Citations with only URLs are fragile. If `blog.example.com` shuts down, the
finding becomes unverifiable.

### Solution
Capture full text of every unique source URL and store alongside citation.

### Workflow
1. **Extract URLs**: Parse all JSON blocks → 92 unique URLs
2. **Fetch**: `curl -sL` each URL to `sources/<sink_id>/<filename>.md`
3. **Update Citations**: Add `archived_path` to each source object
4. **Index**: `sources/_index.json` maps all archives

### Results
- **Archived**: 91/92 URLs (99%)
- **Failed**: `bittripping.com` (permanently offline)
- **Total Size**: ~15MB of archived content
- **Largest Files**: GitHub issues (~450KB each due to full thread content)

### Directory Structure
```
vuln-research/references/sinks/sources/
├── _fetch_plan.json          # URL → sink_id mapping
├── _index.json               # Archive inventory with sizes
├── CLASS-001/
│   └── blog.abdulrah33m.com_prototype-pollution-in-python.md
├── CTF-002/
│   └── maplebacon.org_2024_02_dicectf2024-irs.md
├── CTF-003/
│   ├── blog.antoine.rocks_ictf-2024-pyjails.md
│   └── wachter-space.de_csaw23-python-jail-escape.md
└── ... (91 total)
```

---

## Phase 5: Skill Extraction

Five reusable skills created from user's explicit instructions:

### 1. `parallel-research-swarm`
**Trigger**: "spawn N agents", "parallel research", "full research autonomy"
**Core**: Decompose into 8–12 lanes (8 directed + 4 autonomous). Mandatory
6-section agent prompt. Parallel spawning only.

### 2. `json-citation`
**Trigger**: "quote source in json", "structured citation", "cite in json"
**Core**: Formal schema with sink_id taxonomy, 16 categories, confidence levels,
validation rules (headings == JSON blocks).

### 3. `source-archival`
**Trigger**: "save the source", "per citation per finding", "archive citations"
**Core**: URL extraction, curl fetch, `archived_path` linkage, size limits,
`_index.json` inventory.

### 4. `long-horizon-research`
**Trigger**: "long horizon", "most complete", "track progress"
**Core**: Mandatory todo lists, real-time updates, handoff protocol for
interruptions, recovery after resumption.

---

## Key Decisions & Lessons

### What Worked
- **Parallel research swarm**: 20 agents across 2 rounds found techniques no
  single agent would have discovered
- **Full resource navigation**: Extracting secondary techniques from same posts
  doubled finding count
- **JSON citations**: Structured provenance makes findings verifiable and
  machine-parseable
- **Source archival**: Proves value immediately — `bittripping.com` was already
  dead
- **Section-based reformatting**: Splitting 1,232-line file across 6 parallel
  agents cut wall-clock time by ~6×

### What Was Hard
- **JSON escape handling**: Regex patterns in `detection_signature` required
  double-escaping (`\s` → `\\s`) for JSON validity
- **Duplicate findings**: 3 techniques appeared in multiple sections due to
  overlapping categories (e.g., ZIP polyglot in both CTF and PROTOCOL)
- **Dead URLs**: `bittripping.com` unreachable despite multiple retries
- **Source size**: GitHub issue pages are massive (~450KB); curl captures full
  HTML including comments

### Patterns Observed
- **Re-entrancy dominates**: Every major CPython bug involves `__del__`/`__eq__`/
  `__getattribute__` callbacks running while C code holds stale pointers
- **AST gaps**: Decorators, subscripts (`[]`), augmented assignments (`+=`)
  compile to different AST nodes than direct calls
- **Free-threaded Python (3.13t)**: Entirely new concurrency bug class

---

## Complete Artifact Inventory

### Main Documents
- `vuln-research/references/sinks/python.md` — 3,705 lines, 95 findings
- `vuln-research/references/sinks/python-citation-schema.md` — JSON schema reference
- `python_niche_sinks_research.md` — Initial merged research report

### Source Archives
- `vuln-research/references/sinks/sources/` — 91 archived files (~15MB)
- `vuln-research/references/sinks/sources/_index.json` — Archive inventory
- `vuln-research/references/sinks/sources/_fetch_plan.json` — Fetch metadata

### Skills (Project-Local)
- `.claude/skills/parallel-research-swarm/SKILL.md`
- `.claude/skills/json-citation/SKILL.md`
- `.claude/skills/source-archival/SKILL.md`
- `.claude/skills/long-horizon-research/SKILL.md`
- `.claude/skills/comprehensive-sink-research/SKILL.md` (aggregated)

### Skills (Global)

### Session Files
- `python-section-1.md` through `python-section-6.md` — Reformatted slices

---

## Reproduction Checklist

To reproduce this workflow on a new topic:

1. [ ] Create todo list (`long-horizon-research`)
2. [ ] Decompose into 8–12 lanes (`parallel-research-swarm`)
3. [ ] Spawn 10–12 `task(category="deep", run_in_background=True)` agents
4. [ ] Wait for `<system-reminder>`, collect via `background_output()`
5. [ ] Deduplicate by title, keep longest version
6. [ ] Write main catalog with well-known + niche sections
7. [ ] Split into sections for parallel JSON insertion
8. [ ] Spawn section agents with explicit line ranges
9. [ ] Merge sections, deduplicate, reassign sink_ids
10. [ ] Validate: `grep -c "^###"` == `grep -c "sink_id"`
11. [ ] Extract URLs, fetch with curl, save to `sources/`
12. [ ] Update JSON blocks with `archived_path`
13. [ ] Create `_index.json` inventory
14. [ ] Extract skills from workflow patterns

---

*Documented: 2026-04-29*
*Research Agents: 20 parallel librarian agents*
*Total Findings: 95 niche Python sinks with full provenance*
