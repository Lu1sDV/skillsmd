# Agent-Native Research Artifacts (ARA)

Distilled from `ara-compiler`, `ara-research-manager`, and `ara-rigor-reviewer`.

An ARA packages research knowledge (papers, repos, logs, notes) into a falsifiable, agent-traversable directory with cross-layer bindings between claims, experiments, evidence, code, and exploration history.

---

## 1. ARA Directory Schema

```text
ara/
├── PAPER.md                        # YAML frontmatter + Layer Index
├── logic/
│   ├── problem.md                  # Observations (O1..), Gaps (G1..), Key Insight, Assumptions
│   ├── claims.md                   # Falsifiable claims (C01..) with Proof pointers
│   ├── concepts.md                 # >=5 formal definitions (Notation, Definition, Bounds)
│   ├── experiments.md              # >=3 declarative plans (Verifies C.., directional only — NO exact numbers)
│   ├── related_work.md             # Typed dependency graph (RW01..: imports/extends/bounds/baseline/refutes)
│   └── solution/
│       ├── architecture.md         # Component graph with inputs/outputs
│       ├── algorithm.md            # Math formulation + pseudocode + complexity
│       ├── constraints.md          # Boundary conditions and limitations
│       └── heuristics.md           # H01.. with Rationale, Sensitivity, Bounds, Code ref
├── src/
│   ├── configs/{training,model}.md # Hyperparameters with Value, Rationale, Search range, Sensitivity
│   ├── execution/{module}.py       # >=1 typed Python stub implementing novel contribution
│   └── environment.md              # Python, framework, hardware, dependencies, seeds
├── trace/
│   ├── exploration_tree.yaml       # Research DAG (>=8 nodes; includes dead_end & decision)
│   └── sessions/                   # Live PM session logs (session_index.yaml + YYYY-MM-DD_NNN.yaml)
├── evidence/
│   ├── README.md                   # Index mapping evidence files to claims
│   ├── tables/*.md                 # Raw source tables (exact values, never rounded)
│   └── figures/*.md                # Extracted quantitative figure data
└── staging/
    └── observations.yaml           # Unclassified observations pending maturity promotion
```

---

## 2. ARA Compiler (`ara-compiler`)

Ingests any research input (PDFs including appendices, GitHub repos, code, logs, notes, or dialogue) into a validated ARA.

### 7-Step Compilation Workflow

1. **Read all inputs** thoroughly — for PDFs include appendices; for repos prioritize `README` → core algorithm → configs → env.
2. **4-Stage Epistemic Chain-of-Thought**:
   - **Stage 1 — Semantic Deconstruction**: extract math, specs, configs, exact numbers (never rounded), citation roles, negative results/ablations, and implementation tricks. Capture source table/figure IDs + captions verbatim *before* summarizing; store filtered views as `derived_` / `subset_` files, never mislabeled as `Table N`.
   - **Stage 2 — Cognitive Mapping (`logic/`)**: separate `Statement` (strongest directly supported level) from `Evidence basis` and `Interpretation`. Keep `experiments.md` directional only (exact numbers belong in `evidence/`). Capture full citation footprint in `related_work.md`.
   - **Stage 3 — Physical Stubbing (`src/`)**: exact configs + ≥1 typed Python stub for the novel contribution (plus `rubric/requirements.md` if a PaperBench rubric is given).
   - **Stage 4 — Exploration Graph (`trace/exploration_tree.yaml`)**: ≥8 nodes, nested YAML DAG with `also_depends_on` cross-edges, declaring `support_level: explicit|inferred` (with source refs on `explicit` nodes).
3. **Generate all mandatory files**.
4. **Coverage check loop** (max 3 rounds, stop early if 0 patches): re-read source, diff against ARA, patch gaps (especially appendices and References).
5. **Validate (Seal Level 1)** and **fix/iterate** (typically 2-3 rounds).
6. **Report** artifact location, counts, and validation status.

### Seal Level 1 Structural Checks

- All mandatory directories and non-empty files exist; `PAPER.md` has YAML frontmatter + Layer Index.
- `concepts.md` has ≥5 concepts; `experiments.md` has ≥3 declarative plans (no exact result numbers).
- `claims.md` (`C01+`: Statement, Status, Falsification criteria, Proof), `experiments.md` (`E01+`: Verifies, Setup, Procedure, Expected outcome), and `heuristics.md` (`H01+`: Rationale, Sensitivity, Bounds, Code ref) all have required fields.
- `exploration_tree.yaml` parses as valid YAML with ≥8 nodes, includes `dead_end` and `decision` types, and declares `support_level`.
- **Bidirectional binding**: Claim `Proof` (`E01..`) ↔ Experiment `Verifies` (`C01..`), Heuristic `Code ref` → real files in `src/execution/`, Evidence filenames/captions match source IDs, and claims only cite experiments containing the compared measurements.

---

## 3. Live Research Project Manager (`ara-research-manager`)

A **post-task epilogue** recorder. **CRITICAL**: never load or write `ara/` during active task execution — run only *after* the user's request is complete so working context stays uncontaminated.

### Event Extraction & Provenance

Scan conversation history and route events:
- **Decision / Experiment / Dead End / Pivot** → `trace/exploration_tree.yaml` (+ `evidence/` for experiment results)
- **Claim** → `logic/claims.md`
- **Heuristic** → `logic/solution/heuristics.md`
- **Observation** → `staging/observations.yaml`
- **AI Action** → `trace/sessions/YYYY-MM-DD_NNN.yaml` only (skip routine reads, typos, git/pip commands)

| Provenance Tag | Meaning |
|---|---|
| `user` | User explicitly stated or confirmed |
| `ai-suggested` | AI inferred without explicit user confirmation (default when uncertain) |
| `ai-executed` | AI performed the action (wrote code, ran command) |
| `user-revised` | AI suggested, user corrected |

**Rules**: never upgrade `ai-suggested` to `user`; append rather than overwrite; read existing files first for next IDs; validate YAML after writes.

### Maturity Tracker (Epilogue)

- 3+ observations on the same topic → promote to appropriate layer as `ai-suggested`.
- Observation with experimental evidence → promote to `evidence/`.
- Observation contradicting a claim → flag `<!-- CONFLICT: contradicts C{XX} -->`.
- Stale observations (3+ sessions) → flag `stale: true`.

---

## 4. Semantic Epistemic Review (`ara-rigor-reviewer`)

**Seal Level 2**: runs only after Seal Level 1 passes. Evaluates epistemic soundness using artifact files only (no external URLs, no code execution, no re-checking Level 1 links). Writes `level2_report.json` at the artifact root.

### Fixed Read Order

`PAPER.md` → `logic/claims.md` → `logic/experiments.md` → `logic/problem.md` → `logic/concepts.md` → `logic/solution/*` → `logic/related_work.md` → `trace/exploration_tree.yaml` → `evidence/README.md` → spot-check 2-3 `evidence/tables/` or `figures/`.

### Six Review Dimensions (Scored 1-5)

| Dimension | What It Evaluates |
|---|---|
| **D1. Evidence Relevance** | Does cited evidence substantively match claim type? (causal → isolating ablation; generalization → heterogeneous tests; improvement → baseline comparison) |
| **D2. Falsifiability Quality** | Are falsification criteria actionable, non-tautological, scope-matched, and independently testable? |
| **D3. Scope Calibration** | Check over-claiming ("all models/datasets" vs. narrow eval), under-claiming (evidence without claims), explicit assumptions, and boundary conditions |
| **D4. Argument Coherence** | Logical arc `observations → gaps → insight → solution → claims → evidence`; every motivated gap addressed; no cross-layer contradictions |
| **D5. Exploration Integrity** | Specific `failure_mode` + transferable `lesson` on dead ends; real alternatives on decisions; no claim advocating a `dead_end`/`pivot` node; genuine negative results |
| **D6. Methodological Rigor** | Adequate/recent baselines, component ablations, statistical reporting (variance/CIs/run count), metric-claim alignment, reproducible setup |

### Findings & Overall Grade

- Record findings (`F01..`) sorted by severity (`critical`, `major`, `minor`, `suggestion`) with **verbatim `evidence_span`** quotes (omit only for absence findings), `observation`, `reasoning`, and constructive `suggestion`.
- Every weakness must pair with an actionable suggestion; support must flow through `Proof → experiments.md → evidence/` (prose agreement does not count).

| Grade | Condition (Mean of D1-D6) |
|---|---|
| **Strong Accept** | `mean >= 4.5` AND no dimension `< 3` |
| **Accept** | `mean >= 3.8` AND no dimension `< 2` |
| **Weak Accept** | `mean >= 3.0` AND no dimension `< 2` |
| **Weak Reject** | `mean >= 2.0` AND (`mean < 3.0` OR any dimension `< 2`) |
| **Reject** | `mean < 2.0` OR any dimension `= 1` |
