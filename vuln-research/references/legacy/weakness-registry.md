# Weakness Registry

> **SUPERSEDED — pre-v2 fallback only.** This on-disk JSONL/Markdown registry is the persistence layer from the pre-v2 pipeline. Under v2, `gr_findings.confirmation_status = 'confirmed'` IS the registry; no `.vuln-registry/` directory is written or read. Load this file ONLY when auditing a target whose working tree already contains a `.vuln-registry/` directory from a prior pre-v2 audit run. For all new v2 audits, use `references/v2/confirmation-rigor-doctrine.md` and the DuckDB persistence layer. Phase numbers in this document use the legacy L-prefixed scheme (Phase L6/L7/L8) which does NOT map to the v2 Phase 0–5 pipeline.

> **On-demand (legacy only)** — load when starting a new audit on a target whose root contains a `.vuln-registry/` directory from a prior pre-v2 run. The registry is the persistent, graph-structured record of confirmed weaknesses found in **this target**, used as priors for future audits and as the discovery substrate for cross-finding relationships.

---

## What it is

A per-target, on-disk graph of confirmed weaknesses, written by the audit pipeline and read by future audits as priors. Lives at `<target-repo>/.vuln-registry/` — never in the user's home, never shared across targets. Audit findings stay attached to the target they came from.

The registry is **standalone**: plain JSONL + Markdown, no database, no external service, no PentestX dependency. `grep`, `jq`, and Read are sufficient to query it.

The registry stores **only Confirmed weaknesses** — findings that already passed the existing verification machinery (Phase L7 Exploitability Gate, plus 2-check or 3-check verification when running Swarm). No separate registry-only verification gate. If the existing pipeline says Confirmed, the weakness is registry-eligible.

---

## Layout

```
<target-repo>/
└── .vuln-registry/
    ├── README.md              # human entry point — explains the registry, regenerated each write
    ├── weaknesses.jsonl       # one weakness node per line (canonical record)
    ├── relations.jsonl        # one edge per line (graph relationships)
    ├── index.md               # rendered human-readable index, regenerated from JSONL
    └── nodes/
        └── <weakness-id>.md   # full per-weakness writeup with trace, payload, defenses
```

Add `.vuln-registry/` to the target's `.gitignore` by default unless the user explicitly opts in to versioning it (sensitive findings should not be committed without thought). The skill should remind the user once when the registry is first created.

---

## Node schema (weaknesses.jsonl)

One JSON object per line:

```json
{
  "id": "W-<sha1-12>",
  "title": "<short imperative description>",
  "bug_class": "<canonical class, e.g. command-injection>",
  "cwe": "<CWE-NNN if known, else null>",
  "sink": "<sink symbol, e.g. subprocess.Popen>",
  "source_class": "<http-param|cookie|header|file-content|db-row|config|env|...>",
  "source_to_sink_trace": "<one-line trace, parents implicit by ordering>",
  "file_line": "<path/to/file.ext:NNN>",
  "module": "<module name from decomposition, or directory if untagged>",
  "controllability": "high|medium|low",
  "defense_layers_observed": ["<defense or 'none'>", "..."],
  "phase7_status": "confirmed",
  "discovered_by_mode": "targeted|sweep|swarm-low|swarm-medium|swarm-deep",
  "discovered_by_strategy": "<source-forward|sink-backward|seed-hypothesis-driven|free-form|trust-boundary|state-machine|null>",
  "discoverer_slice_type": "<slice type if from swarm, else null>",
  "first_seen_at": "<ISO-8601>",
  "last_seen_at": "<ISO-8601>",
  "seen_count": <int, ≥1>,
  "git_commit": "<commit hash at first sighting>",
  "tags": ["<freeform>", "..."]
}
```

### ID generation (deterministic, dedup-safe)

```
id = "W-" + sha1(f"{bug_class}|{sink}|{normalized_file_line}").hexdigest()[:12]
```

`normalized_file_line` strips the line number to the function or top-level construct (use LSP `goToDefinition` enclosing scope when available; fall back to file path only if scope detection fails). This means the same logical bug at the same site keeps a stable ID even if line numbers shift. Re-finding it bumps `seen_count` and `last_seen_at` rather than creating a duplicate node.

---

## Edge schema (relations.jsonl)

One edge per line:

```json
{
  "from": "<weakness id>",
  "to": "<weakness id>",
  "type": "<edge type>",
  "evidence": "<short rationale, what the synthesis agent observed>",
  "created_at": "<ISO-8601>",
  "audit_id": "<audit run id, for traceability>"
}
```

### Edge types

| Type | Meaning |
|------|---------|
| `variant-of` | Same root pattern, different site. Both nodes share bug_class + sink, differ in source or location. |
| `co-occurs-with` | Found in the same audit run / same module. Weak signal, but useful for cluster mining. |
| `enables` | This weakness chains into the target weakness (Phase L6 chain output). Directional. |
| `bypasses` | The source weakness's exploit path bypasses the defense represented by the target weakness's mitigation. Rare but high-signal. |
| `dedup-of` | This node is a duplicate detected post-hoc; supersedes a previous ID. Used when ID normalization changes or scope detection improves. |

Edges are **append-only**. If a relation is later judged wrong, write a new edge with type `retracts` pointing at the bad edge's `from→to` pair, with evidence explaining the retraction. Do not mutate `relations.jsonl`.

---

## Per-node writeup (nodes/<id>.md)

Each node gets a human-readable companion file. Minimum sections:

```markdown
# <title>

- **ID:** W-<sha1-12>
- **Bug class:** <class>  ·  **CWE:** <CWE-NNN>
- **Sink:** `<sink>`  ·  **Source class:** <class>
- **Location:** `<file:line>`
- **Status:** Confirmed (<discovery_mode>)
- **First seen:** <date>  ·  **Last seen:** <date>  ·  **Seen count:** <N>

## Source → Sink Trace

<one-paragraph or DAG-style trace; cite line numbers>

## Controllability

<High/Medium/Low + what the attacker controls>

## Defense Layers Observed

<list defenses present and whether they were bypassed>

## Suggested Payload

<copy-pasteable payload or PoC fragment>

## Related Weaknesses

<auto-rendered from relations.jsonl: variant-of, enables, co-occurs-with edges>

## Audit Trail

<one entry per sighting: audit_id, mode, date, commit>
```

The node markdown is the place where the trace, payload, and human reasoning live. The JSONL line is the index entry that makes the graph queryable.

---

## Write phase: Registry Promotion

Registry writing is a **single phase** that runs after every mode's existing verification gates conclude. It does not introduce new verification — it consumes verdicts already produced.

### Trigger points

| Mode | Trigger |
|------|---------|
| **Targeted Audit** | After Phase L7 Exploitability Gate marks a finding Confirmed |
| **Agent Sweep** | After Phase S3 verification marks a finding Confirmed (or 2-check passes both) |
| **Swarm Pipeline (LOW)** | After Phase L3 synthesis emits to `confirmed.md` |
| **Swarm Pipeline (MEDIUM/DEEP)** | After weighted scoring places the finding in `confirmed.md` AND Phase L7 gate passes |

### Procedure

For each Confirmed finding `F`:

1. **Compute ID** per the deterministic rule above.
2. **Lookup**: read `weaknesses.jsonl` and check whether `F.id` exists.
   - **Exists** → bump `seen_count`, update `last_seen_at`, append the new sighting to the node's Audit Trail in `nodes/<id>.md`. Do not append a new JSONL line — rewrite the matching line in place (atomic write to a temp file, then rename).
   - **New** → append a new line to `weaknesses.jsonl`, write `nodes/<id>.md`.
3. **Compute relations** against existing nodes:
   - Same `bug_class` + same `sink`, different `file_line` → emit `variant-of` edge.
   - Same `audit_id` and same `module` → emit `co-occurs-with` edge to every other Confirmed finding in this audit (cap at 5 most-related to avoid quadratic blowup; rank by signal overlap: shared bug_class > shared sink > shared module).
   - If Phase L6 (Chaining) emitted a chain that includes `F` and another Confirmed finding `G` → emit `enables` edge from the earlier-stage weakness to the later-stage one.
   - Append edges to `relations.jsonl`.
4. **Regenerate** `index.md` and `README.md` from the current JSONL state. These files are derived; never edit them by hand.

### Atomicity

All writes go through write-temp-then-rename to avoid corrupting the registry mid-audit. Concurrent audits on the same target are not supported in v1 — emit a `.vuln-registry/.lock` file at write-phase start, refuse to start if one exists less than 10 minutes old, clean up on exit.

---

## Read phase: Loading the registry as priors

When starting any audit, **before Phase 1 (Recon)**:

1. Check for `<target>/.vuln-registry/`. If absent, skip — first audit on this target.
2. Load `index.md` (≤ 200 lines, summary view) into the orchestrator agent's context. Do not bulk-load `weaknesses.jsonl` — it can grow unbounded.
3. For each downstream agent (Phase 2a in Swarm, Phase S2 in Sweep, Phase 3 in Targeted), inject a **priors block** in the prompt:

> **Prior weaknesses confirmed in this target.** The following weaknesses were found and confirmed in past audits of this exact repository. Treat them as hypotheses — not facts — to focus your search. Variants of these patterns may exist at sites the previous audits did not touch. Sites previously fixed should be reverified to confirm the fix held.
>
> <inject relevant subset: filter by module if the agent has a module assignment, by language if Sweep, by suspected_risks if Swarm Phase 1 emitted them>
>
> The full registry lives at `.vuln-registry/`. Read individual `nodes/<id>.md` files when you need the full trace for a specific prior.

4. **Phase 0 (Recency Review)** also reads the registry: any commit that touches a `file_line` from the registry is automatically flagged for security-sensitive review, even if the commit looks routine.

### Filtering injected priors

Do not dump the entire registry into every agent's prompt. Filter:

- **By module / file-glob match** — if the agent's scope is `auth/**`, inject only weaknesses with `module: auth-*` or `file_line` matching the scope.
- **By language match** — Sweep agents looking at Python files don't need PHP weaknesses.
- **By recency** — prefer weaknesses with `last_seen_at` in the last 12 months over older entries; older entries may have been fixed.
- **By size cap** — never inject more than 20 priors into one agent. If filtering yields more, rank by `seen_count` desc then `last_seen_at` desc and truncate.

---

## Querying the registry

Standard queries the orchestrator and human reviewers should be able to run:

| Query | Command |
|-------|---------|
| All weaknesses | `cat .vuln-registry/weaknesses.jsonl \| jq -c .` |
| By bug class | `jq -c 'select(.bug_class == "sql-injection")' .vuln-registry/weaknesses.jsonl` |
| By module | `jq -c 'select(.module == "auth-service")' .vuln-registry/weaknesses.jsonl` |
| By sink | `jq -c 'select(.sink == "subprocess.Popen")' .vuln-registry/weaknesses.jsonl` |
| Variants of one weakness | `jq -c 'select(.from == "W-abc123" and .type == "variant-of")' .vuln-registry/relations.jsonl` |
| Chains involving a weakness | `jq -c 'select((.from == "W-abc123" or .to == "W-abc123") and .type == "enables")' .vuln-registry/relations.jsonl` |
| Recurring weaknesses (likely systemic) | `jq -c 'select(.seen_count >= 3)' .vuln-registry/weaknesses.jsonl` |

The orchestrator agent should run these as part of Phase 0 / Phase 1 to surface registry context, not just dump `index.md`.

---

## Privacy and safety

- The registry is **per-target** and lives **in the target repo's working tree**. It does not phone home, sync, or leak across targets.
- The skill MUST add `.vuln-registry/` to `.gitignore` by default. If the repo lacks `.gitignore`, create one. Never commit the registry without the user's explicit opt-in — confirmed weaknesses are sensitive.
- When sharing a registry (e.g. for handoff to another auditor), the user is responsible for redacting payloads, customer data, or anything else that should not leave their environment. The skill should warn about this when the registry is first created.

---

## What the registry is NOT

- **Not a global vulnerability database.** Use NVD, GHSA, CVE for that. The registry is just *this target's* confirmed findings over time.
- **Not a substitute for the per-audit report.** `confirmed.md`, `findings.json`, the formal audit report — those are the deliverables. The registry is the longitudinal record that compounds across audits.
- **Not a self-modifying skill mechanism.** Phase 4 (skill-improvements) still proposes changes to the skill itself; the registry only captures findings about the *target*. The two are orthogonal.
- **Not authoritative for fix verification.** A weakness in the registry being older than the last commit does not mean it was fixed — it means nobody has re-verified. Re-verification is a separate audit step. `seen_count` and `last_seen_at` are sighting metrics, not fix-status metrics.

---

## Integration with existing phases

| Existing phase | Registry interaction |
|----------------|----------------------|
| Phase L0 (Recency Review) | **Read**: flag commits touching registry `file_line` entries. |
| Phase L1 (Recon) | **Read**: load `index.md` summary into orchestrator context. |
| Phase L2 (Crown Jewels + Attention Deficit) | **Read**: registry hits in a module raise that module's priority. |
| Phase L3 (Source Audit) / S2 / Swarm 2a | **Read**: filtered priors injected per agent. |
| Phase L6 (Chaining) | **Read+Write**: registry chains seed candidate chains; new chains emit `enables` edges. |
| Phase L7 (Exploitability Gate) | **Pass-through**: gate runs unchanged; only Confirmed verdicts feed the registry. |
| Phase L8 (Registry Promotion) | **Write**: this is the legacy registry-write phase — single responsibility, no verification, only persistence. Under v2 this step is replaced by the `gr_findings.confirmation_status = 'confirmed'` DuckDB write. |

---

> **Remember:** The registry compounds value over repeated audits of the same target. The first audit writes a few nodes; the tenth audit walks in with a graph of known patterns, recurring weaknesses, and proven chains. The registry is only as good as the verification gates upstream — keep them honest.
