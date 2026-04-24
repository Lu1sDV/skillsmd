# DAG-Structured Vulnerability Reasoning

> **Load when:** writing a finding's source→sink trace, running the JUDGE check in
> Swarm / Agent-Sweep verification, or gating a finding through Phase 7 and the
> reasoning behind "is this really exploitable?" needs to be auditable.
>
> **Based on:** *Evaluating and Enhancing the Vulnerability Reasoning Capabilities of
> Large Language Models* (Li Lu et al., 2026) — the DAGVul framework.

---

## Why This Exists

Linear chain-of-thought vulnerability analysis hallucinates. The paper's core finding:
**36.4% of correct LLM vulnerability verdicts are supported by incorrect reasoning** —
right answer, wrong logic. Left unchecked, the same LLM will also produce wrong answers
with confident-sounding logic, and you cannot tell them apart from the prose.

Inside vuln-research, this maps directly to three failure modes we already fight:

1. **Phase 4 taint traces that skip a step** ("input reaches the sink") without proving
   the taint survives every transform. Linear CoT hides the gap; DAG makes it impossible
   to omit.
2. **Swarm verification that agrees with the discovery agent's wording** rather than
   re-deriving the path. A structured DAG forces JUDGE to re-extract source nodes from
   code and fail closed when the graph does not close.
3. **Phase 7 findings that pass the Exploitability Gate because the narrative is
   persuasive**, not because controllability was mechanically demonstrated.

DAG reasoning replaces "explain why" with "draw the dependency graph of code facts."
Hallucinated edges have nowhere to hide: every inference must cite a parent node, and
every reasoning path must terminate at a defined sink.

---

## The Framework

Model the analysis as a directed acyclic graph `G = (V, E)` with three node types:

| Node Type | Contents | Example |
|-----------|----------|---------|
| **Source** | Ground facts extracted directly from code with line references. No inference. | `S1: [app.py:42] request.args["q"] — untrusted HTTP input` |
| **Intermediate** | A logical inference. MUST cite parent node IDs and name the program-analysis primitive it uses (taint, def-use, CFG, constraint). | `I2: [depends on S1, S3] q is concatenated into query string on line 57 (def-use chain)` |
| **Sink** | Terminal: either `verified_sink` (vulnerability confirmed) or `sanitized_sink` (safety proven). | `VERIFIED_SINK: [depends on I2, I4] SQLi — trigger: q=' OR '1'='1` |

**Admissibility rule.** A node `v` is admissible only when every parent `pa(v)` is
already established. No forward references, no circular dependencies, no "assume X" as
a silent parent — assumptions must appear as explicit source nodes flagged as such.

**Logical closure requirement.** Every source node must connect to at least one sink
through a complete path. If any source is a dead-end, the analysis is incomplete — say
so, do not paper over the gap with prose.

---

## The 12 Failure Patterns (Check Every Intermediate Node)

Before admitting any intermediate node, run these checks. The paper groups them into
four categories; the table below is the short-form checklist.

| # | Category | Failure Pattern | Red Flag |
|---|----------|----------------|----------|
| 1 | Focus | Wrong code region | Analyzing a function that the alleged taint never reaches |
| 2 | Focus | Wrong abstraction level | Debating library internals when the bug is in the caller (or vice versa) |
| 3 | Comprehension | Data-flow misread | Claiming `x = sanitize(y)` taints x when it actually launders it |
| 4 | Comprehension | Control-flow misread | Ignoring that the vulnerable branch requires `debug=True` |
| 5 | Comprehension | Intra-procedural semantics | Wrong about what a single function does (e.g., `strncpy` truncation behavior) |
| 6 | Comprehension | Inter-procedural semantics | Wrong about what a callee does — especially for wrappers around `exec`/`eval`/ORM |
| 7 | Logic | Incomplete evidence | Verdict without a full source→sink path |
| 8 | Logic | Spurious causality | "Dangerous function present" → "vulnerable" with no taint trace |
| 9 | Logic | Flawed premise | Source node asserts a fact the code does not actually establish |
| 10 | Logic | Contradiction | Intermediate node contradicts a previously-established parent |
| 11 | Generative | Hallucination | Citing a line number, flag, or API that does not exist in the code |
| 12 | Generative | Over-inference / redundancy | Chain of inferences that add nothing verifiable beyond the source nodes |

**Patterns #7 and #8 are the most common LLM failures in vuln-research.** If you only
internalize two checks, make it these: *no verdict without a complete path*, and
*dangerous-looking API is not a taint trace*.

---

## Workflow

Use this when writing or re-verifying any non-trivial finding.

1. **Scope.** Name the function, file range, and (if known) CWE. Refuse to boil the
   ocean — one DAG per finding.
2. **Extract source nodes.** Enumerate ground facts with line refs. Buffer sizes, API
   signatures, variable types, input sources, security-relevant constants, allocation
   / free pairs. No inference yet.
3. **Build intermediate nodes.** For each, write `I<N>: [depends on <parents>] <claim>
   (<primitive>)`. Primitives include:
   - **Taint propagation** — untrusted data through assignments, params, returns
   - **Def-use** — where a value is defined, used, modified
   - **Control flow** — branches, loops, error paths that gate reachability
   - **Constraint solving** — conditions that must hold for the vulnerable path
   - **API contract** — documented behavior of an external call (e.g., parameterized
     query driver escapes before substitution)
4. **Run the 12-pattern check** on each intermediate node before moving on.
5. **Enforce topological ordering.** Do not assert a node whose parents are not yet
   established.
6. **Converge on a sink.** `verified_sink` requires the exact triggering condition
   and the full causal chain. `sanitized_sink` requires identifying the specific
   sanitizer / guard / bounds check with line reference.
7. **Validate closure.** Every source connects to a sink, or the analysis is flagged
   incomplete.
8. **Emit the report.** Verdict, DAG (node list with dependencies), line refs on
   every claim, CWE if applicable.

---

## Worked Examples

### Example 1 — Use-After-Free (CWE-416), VERIFIED

```c
void process_data(int *buf, int len) {
    for (int i = 0; i < len; i++)
        buf[i] = i * 2;
    free(buf);                // line 4
    // ... other operations ...
    printf("%d\n", buf[0]);   // line 6
}
```

```
S1: [line 1] buf is a caller-owned int* parameter
S2: [line 4] free(buf) deallocates the memory
S3: [line 6] buf[0] dereferences buf post-free

I1: [S1, S2] After free(buf), buf is a dangling pointer — address retained,
    memory invalid. (Memory lifecycle analysis)
I2: [I1]     No reassignment or null-guard of buf between lines 4–6; buf
    remains dangling. (Def-use: no re-definition of buf in [4..6])
I3: [I2, S3] Line 6 dereferences a dangling pointer. (Taint: dangling
    pointer reaches dereference operation)

VERIFIED_SINK: [I3] CWE-416 Use-After-Free.
  Trigger: free(buf) at line 4 followed by read buf[0] at line 6 with no
  intervening reallocation or guard.
```

### Example 2 — SQL Injection (CWE-89), SANITIZED

```python
def get_user(db, username):
    query = "SELECT * FROM users WHERE name = ?"
    cursor = db.execute(query, (username,))
    return cursor.fetchone()
```

```
S1: [line 1] username — external, untrusted parameter
S2: [line 2] query — static literal with "?" placeholder
S3: [line 3] db.execute(query, (username,)) — parameterized call

I1: [S1, S2] No def-use chain from username into the query string; query
    is a compile-time literal.
I2: [S2, S3] Driver receives query template and params separately; "?" is
    bound by the driver's parameterization engine, which escapes the value
    before substitution. (API contract analysis)

SANITIZED_SINK: [I1, I2] CWE-89 SQL injection prevented. Untrusted input
  never enters the query as executable SQL.
```

### Example 3 — Stack Buffer Overflow (CWE-787), VERIFIED via mismatched guard

```c
void copy_input(char *src) {
    char dest[64];
    int len = strlen(src);
    if (len < 128) {
        memcpy(dest, src, len);
    }
}
```

```
S1: [line 1] src — external char* parameter (untrusted)
S2: [line 2] dest — stack buffer of 64 bytes
S3: [line 3] len = strlen(src), len in [0 .. SIZE_MAX-1]
S4: [line 4] guard: len < 128
S5: [line 5] memcpy(dest, src, len)

I1: [S3, S4] Guard admits len in [0..127]. (Constraint solving)
I2: [S2, I1] dest has capacity 64; len up to 127. Values in [65..127]
    exceed capacity. (Bounds analysis)
I3: [I2, S5] memcpy writes up to 127 bytes into a 64-byte buffer,
    overflowing by up to 63 bytes on the stack.

VERIFIED_SINK: [I3] CWE-787 Out-of-bounds Write.
  Root cause: guard (len < 128) mismatches sizeof(dest) (64).
  Fix: guard on sizeof(dest), not the magic constant 128.
```

---

## Integration Points Inside vuln-research

### Phase 4 — Taint Analysis

Every "source reaches sink" claim in a finding should be expressible as a DAG. If the
write-up is prose-only, re-draft the source→sink trace as source / intermediate / sink
nodes before promoting the finding. The controllability classification (High / Medium /
Low / Needs verification) is easier to defend when the transforms appear as explicit
intermediate nodes with primitives attached.

### Phase S3 — Agent-Sweep Verification (2-check variant)

The **JUDGE** agent should not be asked "is this finding correct?" in free text. Give
it the discovery report and this instruction instead:

> Build a DAG for this finding from scratch. Extract source nodes from the cited code.
> Build intermediate nodes with parent IDs and primitives. Run the 12-pattern check
> on every intermediate node. Converge on a sink. If you cannot close the graph from
> an untrusted source to a `verified_sink`, the finding fails JUDGE — do not hedge.

A JUDGE pass that cannot close the graph is a *False Positive* verdict in the
2-check combine rule, regardless of how plausible the prose sounds.

### Phase 7 — Exploitability Gate

Questions 1–3 of the gate ("can I control the input?", "does it reach the sink?",
"can I prove impact?") are answered directly by a closed DAG:

- Q1 corresponds to at least one source node typed as untrusted input
- Q2 corresponds to a complete path of intermediate nodes from source to sink
- Q3 corresponds to a `verified_sink` with a stated triggering condition

If the DAG does not close, Q2 is **No** and the finding moves to Observations. This
is the mechanical version of the gate — use it when a finding feels right but the
controllability story keeps shifting.

---

## Best Practices

- **Do** extract every source node with an exact line reference before writing a
  single inference. Ground-truth first.
- **Do** write `[depends on S1, I2]` on every intermediate node. If it feels tedious,
  the finding was probably underspecified.
- **Do** construct a `sanitized_sink` when the analysis finds a guard that breaks the
  chain. Negative findings are findings.
- **Do not** flag a dangerous API as vulnerable without a taint trace to it
  (pattern #8, spurious causality — the most common LLM failure here).
- **Do not** skip inter-procedural analysis. A callee that sanitizes must appear as
  a node, or the DAG is incomplete (pattern #6).
- **Do not** conflate multiple vulnerability paths into one DAG. One DAG per finding;
  multiple paths → multiple DAGs.
- **Do not** hedge when the graph fails to close. Incomplete causal chain is
  **evidence of safety, not evidence of vulnerability**.

---

## Error Handling

| Situation | What to do |
|-----------|-----------|
| Code context is a snippet only | Model external assumptions as explicit source nodes and flag as `ASSUMED`; carry the flag into the report |
| Language semantics ambiguous (C UB, JS coercion, Python dynamic typing) | Cite the language standard and model the ambiguity as a conditional branch / pair of intermediate nodes |
| Multiple independent paths to the same sink | One DAG per path; do not merge |
| Inter-procedural callee source unavailable | `ASSUMED` source node; lower confidence score; note it in the Blind Spots block |

---

## Limitations

- Best for **clear causal chains**: memory corruption, injection, auth bypass,
  deserialization. Weaker for timing side-channels, statistical leaks, and bugs that
  need dynamic runtime state.
- **Inter-procedural depth** is bounded by available code. External library behavior
  enters the graph as assumption nodes, which cap certainty.
- **Static by construction.** Concurrency bugs (race conditions, TOCTOU) need thread
  interleaving reasoning that a static DAG handles awkwardly — use the DAG for the
  per-interleaving slice and enumerate interleavings separately.
- **Language nuance** (C UB, JS type coercion, Python descriptor protocol) requires
  domain expertise beyond the structural method.

---

## § SecuritySlice Input Packet

The **SecuritySlice** is the structured input format module-agents receive from the DEEP-tier static-first lane (`references/swarm-pipeline.md` § Static-First Lane). It is the structural mirror of the DAG output format — a pre-built hypothesis with enough mechanical content that the LLM can focus on *judging* reachability and exploitability rather than reconstructing the graph from raw source.

### Packet schema

```json
{
  "slice_id": "string — stable id, e.g., joern-<hash> or codeql-<query>-<result>",
  "target_cwe_hypothesis": "string — tool's guess, e.g., CWE-89 SQL injection",
  "slice_type": "taint | sink-backward | source-forward | control-dependence | pdg | changed-code | auth-check | bounds-check | allocator-free | lock-unlock | crypto-use",
  "entrypoints": ["file:line — how execution reaches this slice (HTTP handler, IPC, CLI parse, etc.)"],
  "source_nodes": [
    {"file:line": "...", "kind": "http_param | cookie | header | file | db_row | env | ipc | ...", "symbol": "name of var / field"}
  ],
  "candidate_sink_nodes": [
    {"file:line": "...", "api": "e.g., mysql_query / os.system / eval", "arity": "int", "tainted_arg_index": "int"}
  ],
  "dataflow_path_fragments": [
    {"from": "file:line", "to": "file:line", "edge_kind": "assign | call-arg | return | field-read | field-write | alias", "transform": "optional — sanitizer / cast / format"}
  ],
  "control_guards_on_path": [
    {"file:line": "...", "predicate": "e.g., isAuthenticated(user) / strlen(x) < 256", "must_be_true_for_reach": "bool"}
  ],
  "sanitizers_seen": [
    {"file:line": "...", "api": "e.g., htmlspecialchars / prepare / escapeshellarg", "adequate_for_sink": "bool | unknown"}
  ],
  "relevant_code_spans": [
    {"file": "path", "start_line": "int", "end_line": "int", "why": "one-line justification — why this span matters to the slice"}
  ],
  "assumptions": ["string — unresolved facts the tool could not prove, e.g., 'assumes config.DEBUG=false'"],
  "discoverer_strategy": "joern | codeql | semgrep | ast-grep | fallback-grep",
  "confidence_prior": "float in [0,1] — tool's own confidence before LLM review"
}
```

### Relationship to the output DAG

A SecuritySlice packet is **input** to the LLM; the reasoning DAG (§ The Framework above) is the LLM's **output**. The mapping is near-isomorphic:

| SecuritySlice field | DAG counterpart |
|---------------------|-----------------|
| `source_nodes[]` | DAG source nodes |
| `dataflow_path_fragments[]` + `control_guards_on_path[]` | DAG intermediate nodes with `pa(v)` edges |
| `sanitizers_seen[]` | DAG sanitizer-node candidates (LLM must judge adequacy, producing `sanitized_sink` if adequate) |
| `candidate_sink_nodes[]` | DAG `verified_sink` or `sanitized_sink` (LLM decides) |
| `assumptions[]` | DAG assumption leaves that cap certainty |
| `control_guards_on_path[]` with `must_be_true_for_reach: false` | 12-pattern failure risk — wrong-condition check (LLM must verify) |

### Required LLM response shape

Given a SecuritySlice packet, the LLM emits:

1. A full DAG per § The Framework (sources → intermediates → verified_sink or sanitized_sink)
2. An explicit **verdict on each assumption**: promoted to fact (with evidence), downgraded to unresolved (capping certainty), or refuted (killing the slice)
3. A **sanitizer-adequacy judgment** for every `sanitizers_seen` entry
4. A **12-pattern check pass** (per § The 12 Failure Patterns) — enumerate each pattern and declare "not present" or "present → node invalidated"
5. Final classification: `VERIFIED | SANITIZED | UNREACHABLE | ASSUMPTION_BOUNDED`

### Use across tiers

| Tier | SecuritySlice packet source |
|------|------------------------------|
| LOW | Not used — freeform agents work from raw source |
| MEDIUM | Optional — agents receive call-chain slices but not the full structured packet |
| DEEP | **Required** — static-first lane produces one packet per candidate slice; module-agents consume packets as primary input |

### Why a structured packet over raw code

Per CPRVul: naive context append (dumping call graphs and raw files into the LLM context) degrades performance. A structured SecuritySlice lets the LLM:

- Skip rediscovering the path (already traced by the tool)
- Focus tokens on *judgment* (sanitizer adequacy, guard correctness, assumption validity) rather than *retrieval*
- Produce a DAG that structurally mirrors the packet, making mechanical verification (Phase 2.5 DAG-independent check) tractable

---

## Reference

- **Paper:** Li Lu, Yanjie Zhao, Hongzhou Rao, Kechi Zhang, Haoyu Wang. *Evaluating
  and Enhancing the Vulnerability Reasoning Capabilities of Large Language Models*
  (2026). [arXiv:2602.06687](https://arxiv.org/abs/2602.06687v1)
- **Core claims to remember:** the 36.4% wrong-reasoning rate, the 12 failure-pattern
  taxonomy, the node admissibility rule (`pa(v)` must be established), and the
  logical closure requirement.
