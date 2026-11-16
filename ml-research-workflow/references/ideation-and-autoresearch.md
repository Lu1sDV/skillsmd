# Ideation & Autonomous Research

Distilled from `autoresearch`, `brainstorming-research-ideas`, and `creative-thinking-for-research`.

---

## 1. Autonomous Research Loop (`autoresearch`)

A two-loop architecture for running end-to-end autonomous AI research projects from literature survey to paper draft.

### Workspace Layout

```text
{project}/
├── research-state.yaml       # Central state tracking
├── research-log.md           # Decision timeline
├── findings.md               # Evolving narrative synthesis (project memory)
├── literature/               # Paper summaries + survey.md
├── src/                      # Reusable utilities, plotting, data loaders
├── data/                     # Raw result CSVs/JSONs (store checkpoints externally)
├── experiments/{slug}/       # protocol.md, code/, results/, analysis.md
├── to_human/                 # Progress HTML/PDF reports
└── paper/                    # Final paper draft
```

### `research-state.yaml` Schema

```yaml
project:
  title: ""
  question: ""
  status: active              # active | paused | concluded
  started: ""                 # ISO date
  domain: ""
literature:
  key_papers: []              # {id, title, authors, year, relevance}
  open_problems: []
  evidence_gaps: []
hypotheses: []                # {id, statement, status, motivation, parent, priority}
experiments:
  proxy_metric: ""
  baseline_value: null
  best_value: null
  total_runs: 0
  trajectory: []              # {run_id, hypothesis, metric_value, delta, wall_time_min, change_summary}
outer_loop:
  cycle: 0
  last_direction: null        # deepen | broaden | pivot | conclude
  last_reflection: ""
```

### Two-Loop Execution

1. **Bootstrap (once, lightweight)**
   - Search literature across multiple sources: Exa MCP (`web_search_exa`), Semantic Scholar (`pip install semanticscholar`), arXiv (`pip install arxiv`), CrossRef. Save one summary per paper + `literature/survey.md`.
   - Identify gaps and form initial testable hypotheses.
   - Lock the proxy metric and baseline upfront (computable in minutes, not hours).

2. **Inner Loop (fast, autonomous, repeating)**
   - Pick highest-priority untested hypothesis.
   - Write `protocol.md` (change, prediction, rationale) and commit to git **before** running (`research(protocol): {hypothesis}`).
   - Run experiment, then sanity-check before trusting metrics (convergence, no NaN/Inf, baseline reproduction, spot-check data).
   - Measure proxy metric and record in `experiments/{slug}/` and `trajectory`. Label clearly: **CONFIRMATORY** (in protocol) vs **EXPLORATORY** (discovered mid-run).
   - Positive → keep and explain *why*. Negative → log what it rules out and what it suggests.

3. **Outer Loop (periodic reflection, every ~5-10 runs or on stall)**
   - Review results since last reflection, cluster by change type, and identify underlying mechanisms.
   - Update `findings.md` (Current Understanding, Patterns/Insights, Lessons & Constraints, Open Questions).
   - Quality test for `findings.md`: after 30 inner-loop runs, a human should be able to write a paper abstract from it.
   - Choose direction:
     - **DEEPEN**: supported result raises sub-hypotheses (`H1.1`, `H1.2`).
     - **BROADEN**: solid results open adjacent root hypotheses.
     - **PIVOT**: core assumption invalidated or unexpected finding is more promising → return to literature.
     - **CONCLUDE**: strongly supported finding (or coherent negative results), ablations/error analysis complete, `findings.md` forms a paper backbone.

### Agent Continuity & Git Protocol

- **Claude Code continuity**: set up `/loop 20m` reading `research-state.yaml` and `findings.md` on each tick to prevent idling.
- **OpenClaw continuity**: create a 20-minute `cron.add` job (`everyMs: 1200000`, `sessionTarget: "current"`).
- **Git commit convention** (hard rule: never combine protocol and results in one commit):
  - `research(init): {project} — {question}`
  - `research(protocol): {hypothesis}`
  - `research(results): {hypothesis} — {outcome}`
  - `research(reflect): {direction} — {reason}`
  - `research(paper): {title}`
- **Progress reporting**: generate HTML (or PDF via `weasyprint` / `playwright pdf` / `wkhtmltopdf`) in `to_human/` with the question, trajectory chart, key plots, and narrative.

---

## 2. Structured Brainstorming (`brainstorming-research-ideas`)

Ten ideation lenses for moving from vague curiosity to testable proposals.

### Ten Frameworks

| # | Framework | Core Move | Best For |
|---|---|---|---|
| 1 | **Problem-First vs. Solution-First** | Pain point → method vs. capability → ≥2 genuine problems | Avoiding "hammer looking for a nail" |
| 2 | **Abstraction Ladder** | Move Up (generalize), Down (extreme constraints), Sideways (analogize) | Turning "+2% benchmark" into broader insight |
| 3 | **Tension & Contradiction Hunting** | List top desiderata pairs (e.g., Safety ↔ Capability); ask if trade-off is artifact or fundamental | High-impact framing |
| 4 | **Cross-Pollination** | Strip jargon, import structural mechanism from distant field (physics, economics, control theory) | Breaking out of subfield echo chambers |
| 5 | **The "What Changed?" Principle** | Revisit 3-10 yr old abandoned ideas; check invalidated assumptions (compute, scale, regulation, tooling) | Timely high-leverage ideas |
| 6 | **Failure Analysis & Boundary Probing** | Violate implicit eval assumptions (OOD, 10x/0.1x scale, adversarial, compositional, drift) | Challenging accepted methods |
| 7 | **The Simplicity Test** | Strip SOTA to 1 core idea; compare under equal compute/tuning | Exposing unnecessary complexity |
| 8 | **Stakeholder Rotation** | View system as End User, Developer, Theorist, Adversary, Ethicist, Regulator, Operator | Discovering unaddressed questions |
| 9 | **Composition & Decomposition** | Compose complementary methods OR decompose monolithic system to find bottleneck | Architectural novelty |
| 10 | **Explain-It Test** | Two-sentence pitch to a smart non-expert | Clarity & value-prop filter |

### Two-Sentence Pitch Template

> **Problem**: "[Domain] currently struggles with [specific problem], which matters because [concrete consequence]."
> **Insight**: "We [approach] by [key mechanism], which works because [reason]."

### Diverge → Converge → Refine Workflow

1. **Diverge (10-20 candidates)**: scan 5 tensions, 3 recent shifts, 2 method boundaries, 1 cross-domain analogy, 1 compose/decompose pair, and abstraction-ladder variants.
2. **Converge (filter to 3-5)**: apply kill criteria — fails Explain-It Test, no genuine problem/beneficiary, complexity unjustified (Simplicity Test), or infeasible with available compute.
3. **Refine (top 1)**: write two-sentence pitch, identify core tension, list 3 validation experiments, prepare response to strongest skeptic objection, and define a 2-week feasibility pilot.

---

## 3. Creative Thinking Frameworks (`creative-thinking-for-research`)

Eight cognitive-science frameworks for non-incremental breakthroughs.

| # | Framework | Cognitive Operation | Unblocks |
|---|---|---|---|
| 1 | **Combinatorial Creativity (Bisociation)** | Cross-product matrix of 5-10 primitives from Domain A × Domain B | Tunnel vision |
| 2 | **Problem Reformulation** | Change objective, formalism (graph → spectral), granularity, agent, timescale, or direction | Fixation |
| 3 | **Analogical Reasoning (Structure-Mapping)** | Strip nouns to relational/causal structure; map distant domain mechanism (not surface metaphor) | Tunnel vision |
| 4 | **Constraint Manipulation (Boden)** | Classify constraints as Hard, Soft, or Hidden; relax/tighten/drop hidden constraints (transformational) | Incrementalism |
| 5 | **Negation & Inversion (TRIZ)** | Negate "everyone knows" assumptions (e.g., exactness, labels, static params, consistency) | Self-censoring |
| 6 | **Abstraction Laddering (Polya)** | Generalize (results without explanation) vs. Specialize to extreme constraints (theory without grounding) | Stuck mid-project |
| 7 | **The Adjacent Possible (Kauffman)** | Map last 6-18 months of enablers (context length, 100x cheaper inference, open weights, tool use) | Analysis paralysis |
| 8 | **Janusian & Dialectical Thinking** | Hold A vs. B contradiction without choosing a side; synthesize a new abstraction (e.g., ZK proofs, grokking) | False dichotomy |

### 90-Minute Deep Ideation Protocol

1. **Map the Space (15m)**: list Hard/Soft/Hidden constraints (F4) + recent enablers (F7).
2. **Generate Disruptions (30m)**: negate 3 soft/hidden constraints (F5), build a bisociation matrix (F1), restate problem 3 ways (F2).
3. **Deepen Leads (30m)**: extract structural analogies + predictions (F3), climb/descend abstraction ladder (F6), synthesize binaries (F8).
4. **Evaluate (15m)**: apply the two-sentence test, then hand off surviving candidates to the Converge/Refine workflow.
