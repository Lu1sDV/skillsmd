# Agent Sweep Methodology Reference

> **On-demand** — load when running Agent Sweep or Hybrid mode.

---

## Overview

The Agent Sweep methodology replaces domain-partitioned analysis with **file-iteration and independent verification**. Instead of assigning agents to attack categories (SQLi, XSS, SSRF), you iterate across every source file and let the LLM's latent knowledge of bug classes drive discovery. A separate verification pass filters noise.

This approach is based on the Carlini methodology: discovery loop → verification loop → dedup → chain assembly.

**Why it works:**
- LLMs encode the complete library of documented bug classes (stale pointers, integer mishandling, type confusion, allocator grooming, deserialization chains, injection variants)
- Each source file as a starting point subtly randomizes inference, preventing convergence into local maxima
- Exploit outcomes are straightforwardly testable success/failure trials
- Agents never get bored and will search indefinitely

---

## Phase S1: Source Tree Segmentation

### File Enumeration

```bash
# Enumerate all source files, excluding vendored/generated code
find . -type f \( -name '*.py' -o -name '*.js' -o -name '*.ts' -o -name '*.php' \
  -o -name '*.rb' -o -name '*.java' -o -name '*.go' -o -name '*.rs' -o -name '*.c' \
  -o -name '*.cpp' -o -name '*.cs' -o -name '*.ex' -o -name '*.exs' -o -name '*.swift' \
  -o -name '*.kt' -o -name '*.scala' \) \
  -not -path '*/node_modules/*' \
  -not -path '*/vendor/*' \
  -not -path '*/dist/*' \
  -not -path '*/.git/*' \
  -not -path '*/build/*' \
  -not -path '*/target/*' \
  -not -path '*/__pycache__/*' \
  -not -path '*/generated/*' \
  > source_files.txt
```

### Prioritization by Attention Deficit

Score each file/module and sort descending (highest deficit = audit first):

| Factor | Weight | How to Measure |
|--------|--------|---------------|
| **Processes external input** | 3x | Grep for HTTP handlers, file parsers, deserialization, socket reads |
| **No security commits** | 2x | `git log --format='%s' -- <file> \| grep -ic 'secur\|vuln\|cve\|xss\|sqli'` returns 0 |
| **No adjacent tests** | 2x | No `*_test.*`, `*_spec.*`, `test_*` file for this module |
| **Legacy/stale code** | 1.5x | No modifications in 2+ years: `git log --since="2 years ago" -- <file>` is empty |
| **Unglamorous domain** | 1x | Parsers, format handlers, config loaders, migration scripts, protocol adapters |

### Batch Strategy

- **Small codebase (<500 files):** one file per agent, full parallel sweep
- **Medium codebase (500–5000 files):** cluster by directory, one agent per directory
- **Large codebase (>5000 files):** prioritize top 20% by attention deficit score, sweep in rounds

---

## Phase S2: Discovery Loop

### Agent Prompt Template

For each source file `${FILE}`, spawn a parallel agent with:

```
You are performing a security audit on a codebase. Your goal is to find
exploitable vulnerabilities starting from this file:

${FILE}

Instructions:
1. Read the file and understand its purpose, inputs, and outputs
2. Follow imports/requires to understand the data flow from this file
3. Consider ALL bug classes — not just web vulns:
   - Memory corruption (buffer overflow, use-after-free, integer overflow)
   - Injection (SQL, NoSQL, SSTI, command, LDAP, XPath, XSLT, CRLF)
   - Deserialization (pickle, Marshal, unserialize, Java ObjectInputStream, JSON.NET)
   - Logic flaws (auth bypass, race conditions, TOCTOU, mass assignment)
   - Type confusion, prototype pollution, allocator grooming
   - Cryptographic misuse (weak RNG, ECB mode, hardcoded keys, nonce reuse)
   - File operations (path traversal, zip slip, symlink following)
   - SSRF, XXE, open redirects usable in chains
4. For each finding, trace the COMPLETE source-to-sink path
5. Assess exploitability: can an attacker actually reach and control this?

Write your findings to ${FILE}.vuln.md using this format for each vulnerability:

## [SEVERITY] Vuln Title
- **Type:** CWE-XXX — bug class name
- **Location:** file:line — function name
- **Source:** where attacker input enters
- **Sink:** where the dangerous operation occurs
- **Trace:** source → transform1 → transform2 → sink
- **Controllability:** High/Medium/Low — what the attacker controls
- **Defense layers:** what mitigations exist (if any)
- **Suggested payload:** concrete exploit input
- **Impact:** what an attacker gains

If you find nothing exploitable, write "No exploitable vulnerabilities found"
with a brief explanation of why (e.g., no external input reaches this code).
```

### Execution Strategy

- **Parallel agents:** spawn as many as compute allows — agents are fully independent
- **Stochastic coverage:** running the same file multiple times with different sampling may surface different bugs. For high-priority files (high attention deficit + high exposure), consider 2–3 passes
- **Follow imports:** agents should trace `require`/`import`/`include` chains from their starting file into dependent modules — the file is the anchor, not the boundary
- **Time budget:** set a per-file timeout (suggest 3–5 minutes per file for discovery). Files that time out go into a "deep dive" queue for targeted audit

### Include Test Files

Test files reveal:
- Expected invariants that may not be enforced in production code
- Edge cases the developers considered (and those they didn't)
- Mock configurations that expose real service interfaces
- Fixtures containing realistic data shapes that inform payload construction

---

## Phase S3: Verification Loop

### Why Separate Verification

The discovery agent is incentivized to find bugs — it may over-report. A fresh agent with the explicit job of *disproving* the finding corrects this bias.

### Verification Prompt Template

```
You received an inbound vulnerability report. Your job is to VERIFY or REJECT it.

Report: ${FILE}.vuln.md

Instructions:
1. Read the vulnerability report carefully
2. Read the actual source code at the specified location
3. Trace the source-to-sink path YOURSELF — do not trust the report's trace
4. For each claimed vulnerability, answer:
   a. Does the source (attacker input) actually exist and is it reachable?
   b. Does the data survive all transforms, sanitizers, and type checks?
   c. Is the sink actually dangerous in this context?
   d. Are there defense layers the report missed (framework auto-escaping,
      WAF rules, type system constraints, runtime config)?
   e. Is this an intended feature, not a bug? (admin RCE via plugin = intended)

Classify each finding:
- **Confirmed** — you independently verified the source-to-sink path is exploitable
- **Plausible-Needs-Dynamic** — path exists but requires runtime confirmation
  (race condition timing, heap layout, config-dependent behavior)
- **False Positive** — report is wrong (dead code, sanitized path, intended feature,
  incorrect trace, framework protection the report missed)

Write your verification to ${FILE}.verified.md with your classification,
reasoning, and any corrections to the original report.
```

### Expected Filtration Rates

| Bug Class | Typical Discovery→Verified Rate | Notes |
|-----------|-------------------------------|-------|
| SQL injection | 50–70% survive | ORMs and parameterized queries cause many FPs |
| Command injection | 60–80% survive | Easier to verify — sink is obvious |
| Deserialization | 70–90% survive | If the sink exists and input reaches it, usually real |
| Logic flaws (auth, IDOR) | 40–60% survive | Context-dependent, harder to verify statically |
| Memory corruption | 30–50% survive | Requires understanding allocator state, mitigations |
| XSS | 40–60% survive | Framework auto-escaping causes many FPs |
| Race conditions | 20–40% survive | Timing-dependent, most need dynamic confirmation |

---

## Phase S4: Dedup, Cluster, Feed Forward

### Deduplication

Multiple starting files often discover the same underlying vulnerability from different angles. Deduplicate by:
1. **Same sink function + same source** → merge into single finding (keep the best trace)
2. **Same sink function + different sources** → keep as separate findings (multiple entry points increase severity)
3. **Same bug class + same module** → review for shared root cause (e.g., one missing sanitizer affects multiple routes)

### Clustering

Group verified findings for chain analysis:
- **By component:** all vulns in the auth module → look for auth bypass chains
- **By bug class:** all injection findings → look for second-order injection patterns
- **By data flow:** findings sharing common data paths → look for reader+writer chains
- **By severity tier:** prioritize P0/P1 clusters for immediate exploitation

### Feed Forward

Verified, deduplicated findings feed into the existing workflow:
- **Phase 6 (Chaining):** cluster findings and hunt for A→B chains (see `chaining-advanced-techniques.md`)
- **Phase 7 (Exploitability Gate):** every finding must still pass the four-question gate
- **Proof Collection:** confirmed findings need the same evidence standard as targeted audit findings

---

## Binary and Decompiled Code Analysis

When source code is unavailable, agent sweep still applies:

### Approach

1. **Lift binaries to IR or decompile** — use Ghidra, Binary Ninja, or IDA to produce pseudocode
2. **Treat decompiled output as source** — feed it through the same discovery loop
3. **Reason from assembly when needed** — LLMs can analyze assembly directly for patterns like:
   - Unchecked buffer sizes before `memcpy`/`strcpy`
   - Missing null checks after allocation
   - Integer overflow before allocation size calculation
   - Format string vulnerabilities (`printf(user_input)`)
   - Stack cookie absence or predictable canaries

### Closed Source is Not a Defense

Reversing was already mostly a speed bump. Agents can:
- Decompile and analyze at scale — no human patience required
- Reason about control flow graphs directly
- Cross-reference decompiled code with known vulnerability patterns from open-source analogues
- Identify the same bug classes in decompiled output as in source

---

## Integration with Targeted Audit

Agent Sweep and Targeted Audit are complementary:

| Dimension | Targeted Audit | Agent Sweep |
|-----------|---------------|-------------|
| **Coverage** | Deep on selected targets | Broad across entire codebase |
| **Precision** | High — human-guided taint tracing | Medium — needs verification loop |
| **Chain discovery** | Strong — systematic A→B hunting | Weak for chains — finds individual bugs, chains emerge from clustering |
| **Novel bug classes** | Possible — "invent your own attack classes" | Less likely — matches known patterns from training data |
| **Cost** | High attention per finding | High compute, low attention per finding |
| **Best for** | Scoped audits, compliance, exploit dev | "Find everything," broad surface, pre-audit discovery |

**Hybrid mode** — sweep first, then targeted audit on interesting clusters — is the highest-ROI approach for most engagements.

### Hybrid Workflow

1. Run Agent Sweep (S1–S4) across the full source tree
2. Cluster verified findings by component and severity
3. Apply Crown Jewel Mapping to the finding clusters (not the whole codebase)
4. Run Targeted Audit (Phases 3–7) on the highest-priority clusters
5. Build chains across clusters using Phase 6
6. Prove and report using Phase 7 + `audit-poc-report.md`

---

## Tuning and Iteration

### When to Re-Sweep

- After significant code changes (new release, major refactor)
- After fixing discovered vulnerabilities (regression check + new attack surface from fixes)
- With updated models (newer LLMs may find bugs previous versions missed)
- On previously timed-out files with larger time budgets

### Batch Size Tuning

- Start with single-file granularity for small codebases
- If findings per file are very low (<5% of files produce findings), increase batch size to directory-level
- If findings per file are very high (>30%), decrease batch size and increase verification rigor

### Multi-Pass Strategy

For critical targets, run multiple discovery passes:
- **Pass 1:** standard sweep with default prompt
- **Pass 2:** sweep with domain-specific hints (e.g., "focus on deserialization" or "focus on auth boundaries")
- **Pass 3:** sweep starting from test files and configuration files instead of source files
- Deduplicate across passes before verification
