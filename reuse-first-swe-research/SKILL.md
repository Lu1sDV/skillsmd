---
name: reuse-first-swe-research
description: >-
  Research how to implement a new or existing software engineering project with
  maximum verified reuse and minimum reinvention. Classify the project's change
  constraints, research and audit adaptive domain-specific decompositions,
  discover internal and external reusable implementations, verify source code
  and compatibility, evaluate reuse modes, and recommend a maintainable
  implementation or migration blueprint. Use for repository-first solution
  research, platform/library selection, feature extension, modernization,
  replacement decisions, or requirements-to-implementation mapping in any
  software domain or permitted technology stack.
---

# Reuse-First Software Engineering Research

## Purpose and governing principles
Research **how to implement the user's requested software outcome** with the largest amount of **verified, suitable reuse** and the least unnecessary original code, integration work, operational burden and long-term maintenance. Deliver **one coherent implementation or change recommendation** (or a reasoned no-change decision), not disconnected product suggestions.

- **The user's goal governs.** Preserve their requirements, source documents, priorities, constraints, terminology and requested deliverable. Do not allow the features of a popular platform to redefine the goal.
- **New and existing projects require different investigations.** A new project mainly needs solution-space discovery and assembly; an existing project first needs evidence of current behavior, internal assets, change constraints and safe modification boundaries. Treat this as a difference in *constraints and available evidence*, not merely a project label.
- **Maximum reuse is not maximum imports.** Reuse can mean adopting a platform, importing a package, retaining existing code, integrating a component or borrowing verified logic. Prefer smaller, compatible solutions when integration and maintenance overhead outweigh superficial coverage.
- **Research the decomposition.** The correct domain boundaries and research granularity are contextual. They must be investigated, audited and revised as evidence emerges, not imposed from a universal taxonomy.
- **Evidence before recommendations.** Distinguish product claims, documentation, verified source/tests and actually executed checks. Never invent repository paths, imports, implementation status, test outcomes or coverage numbers.
- **All-in-one is an option, not a mandate.** Look for complete working systems early. Adopt one when it satisfies hard constraints and wins the reuse-to-complexity comparison. For existing projects, retaining or extending the current system may be the true all-in-one answer.

## Applicability and user authority
Use for software-engineering reuse research, whether the user is starting a project, adding a feature, integrating a subsystem, improving an existing application, or considering migration/replacement. Do **not** assume a language, framework, application domain, platform topology, project size or fixed number of research tracks. Prefer open-source implementations where the user requests or prioritizes them; assess other license models only within the stated constraints.

Source and instruction priority for research:
1. User's objectives, exact requirements, acceptance criteria, constraints and evaluation preferences.
2. User-supplied specifications, domain decomposition, codebases, artifacts, status claims and architecture documentation; retain provenance and flag contradictions.
3. Observed or verifiable current behavior, code, tests, published APIs, operational constraints and external integration contracts.
4. Current official documentation, canonical repositories, release evidence, package metadata, reference projects and trustworthy specialist sources.
5. Researcher inference and proposed additions, always **explicitly marked as proposals**.

Where current implementation contradicts documentation, report both, explain the evidence, and do not silently declare either the intended requirement. If documents mention `N` competencies/dimensions without definitions, do not invent them or claim `N/N` coverage. Record `MISSING_INPUTS` and continue with the verifiable subset.

## Shared process: classify before decomposing or searching

### Phase 0 — Determine the investigation context
Extract from the request and available materials:
- **Objective and scope:** build, add, integrate, improve, migrate, replace, retain, or assess; what success means.
- **Existing implementation:** absent, present, partially present, inaccessible, or unknown; which components already exist.
- **Preservation constraints:** existing behavior, interfaces, users, data, performance, deployments, security rules and compatibility obligations that must survive changes.
- **Integration topology:** upstream/downstream systems, external standards, data stores, APIs, deployment and operational dependencies.
- **Change freedom:** permitted redesign, constraints on downtime/data migration, ability to replace existing code, time and delivery risk.
- **Technical and legal envelope:** allowed ecosystems, licenses, infrastructure, staffing, cost, privacy, security and operational requirements.

Choose the investigation branch according to *actual constraints*:

| Context | Default research branch | Primary concern |
|---|---|---|
| No existing implementation, few inherited constraints | **New — solution-selection** | Discover complete existing solutions and compose the smallest feasible implementation. |
| New project with substantial external interfaces or imposed behavior | **New — integration-constrained** | Select reusable solutions while preserving required external contracts from day one. |
| Existing implementation with important behavior/contracts to preserve | **Existing — preservation-first** | Understand actual system, safeguard existing behavior and seek low-risk reuse/change seams. |
| Existing implementation with substantial redesign permitted | **Existing — redesign-permitted** | Inventory internal value, then objectively compare retention, selective changes and replacement. |
| New and existing areas in the same initiative | **Mixed** | Apply preservation-first research to constrained subsystems and new-solution research to unconstrained areas. |

Existence of a repository does **not** automatically mean it must be preserved; absence of a repository does **not** mean there are no external compatibility constraints. If the state is uncertain, record the uncertainty and use a provisional branch, without inventing access to the codebase. Research depth must reflect change impact; a small isolated feature does not require a full-enterprise archaeology exercise.

### Phase 1 — Inventory authoritative inputs and preserve requirements
- Inventory all available source files and revisions; record which claimed inventories or sections are missing.
- Build stable requirements records: `id | exact wording | source | acceptance criterion | priority/status | hard constraint? | capability owner | dependencies | cross-cutting tags`.
- Preserve important distinctions and negative requirements (e.g., unresolved ≠ negative; proposed ≠ implemented; an activity record ≠ authoritative state) **when actually present in the user's materials**, not as assumptions for every project.
- Distinguish `documented/current`, `explicitly deferred`, `proposed`, `unknown` for user-project scope. Candidate repository evidence has its own separate verification status.
- Classify functional versus nonfunctional requirements and system-wide invariants. Record contradictions explicitly; do not silently repair source materials.
- For existing projects, also maintain an **as-is evidence ledger**: `component | observed or documented behavior | source/test/runtime evidence | internal reuse potential | dependencies | change constraints | confidence`.
- Create `MISSING_INPUTS` for any promised but absent source definitions, code access, deployment constraints or measurement baselines. Never claim exhaustive coverage of unavailable items.

### Phase 2 — Research the best decomposition and research granularity
First determine the state of the user's decomposition:
- **Complete and authoritative:** preserve identifiers and structure; audit coverage, overlap and inconsistencies. Suggest changes **separately** without silently substituting them.
- **Partial:** keep the supplied portions; research missing capabilities and add proposed entries with clear provenance.
- **Absent:** research the domain, reference architectures, standards, established taxonomies and existing solutions to develop a provisional, testable capability map.

Select only relevant decomposition *types*: **problem** (needs), **capability** (what the system provides), **functional** (behaviors), **architectural** (responsibilities and interfaces), **implementation** (real components and reusable artifacts), and **work/research** (investigation units). They are not equivalent: conceptual capabilities are not automatically modules, services or repositories.

Compare plausible boundaries using context-appropriate factors: goal alignment, requirement coverage, domain correctness, cohesion, dependency coupling, modularity and composability, alignment with verified existing solutions, integration effort, change isolation/evolvability, verifiability, resource/operational constraints, and risk/uncertainty isolation. Follow **user-specified factors and weights first**; treat this list as candidate factors, not mandatory equal weights.

Choose **adaptive granularity**:
- Map requirements and acceptance criteria at the depth needed for exact verification.
- Group *research tasks* more coarsely when topics share sources, methods and decisions.
- Split units that are too heterogeneous, uncertain or broad for thorough evidence gathering; merge units whose separation only duplicates work.
- Optimize **researchability, cohesion, independence, decision usefulness and synthesis cost**; do not maximize the number of categories.
- Explicitly identify cross-cutting responsibilities, relationships and owners. Revisit decomposition when discovered implementations or change constraints reveal better boundaries.

### Phase 3N — New-project investigation: solution-space first
Use for unconstrained new areas (including new subsystems inside mixed projects):
1. Translate the desired capability map into **hard requirements, measurable acceptance criteria and integration contracts**.
2. Search **complete existing platforms and functioning end-to-end reference implementations first**; verify the actual domain fit before exploring independent libraries.
3. For each promising anchor, map native capability, official integration, example-only behavior and missing requirements.
4. Research mature libraries, plugins, components and code only for the **gaps**; avoid assembling a large catalog before testing anchor feasibility.
5. Compare feasible minimal, modular and integrated architectures. Assess duplication of authorities/state, integration edges, runtime/deployment needs, security, extensibility and maintenance.
6. Produce an implementable path beginning from an existing working base when justified, with a small end-to-end acceptance slice and explicit replaceable seams.

For **integration-constrained new projects**, investigate inherited external contracts, data formats, identity/access boundaries, organizational standards and operational dependencies *before* accepting an anchor. New code does not imply freedom to ignore the surrounding ecosystem.

### Phase 3E — Existing-project investigation: current-state first
Use when any meaningful implementation already exists. **Do not recommend replacement technologies before investigating what is being replaced**, to the extent that access and evidence permit.

1. **Software archaeology:** inspect repository structure, modules, services, source-level behavior, API routes/commands, integrations, dependency manifests, versions, data schema/migrations, tests/fixtures and deployment configuration. Use observed runtime behavior and operational evidence where available; never claim code was executed unless it was.
2. **As-is vs to-be map:** link desired requirements to already implemented, partially implemented, absent and unverified behavior. Identify which existing behavior is mandatory to preserve and which is intentionally changeable.
3. **Internal reuse inventory:** identify valuable existing functions, components, adapters, services, frameworks, tests, data models, documentation and configurations; inspect actual quality and licensing. Determine whether reuse, extraction or consolidation is safer than replacement.
4. **Behavioral baseline:** review characterization/regression tests, public contracts, data invariants, event semantics and critical edge cases. Where evidence is insufficient, propose characterization tests before making risky modifications.
5. **Change boundaries:** identify extension points, dependency seams, feature flags, abstraction boundaries, service interfaces, tightly coupled state, database ownership and high-blast-radius dependencies.
6. **Targeted external research:** investigate mature external solutions for **verified gaps**, duplication reduction and justified modernization. Compare retain, configure/extend, reuse internally, extract, integrate, refactor, incrementally replace, wholly replace and retire at the relevant scope.
7. **Safe transition analysis:** consider compatibility, downstream consumers, data migration, side-by-side operation, rollback, release sequencing, availability, deployment and operational disruption. Use an incremental replacement pattern only when the specific case benefits.
8. **Recommend a change path:** show retained assets, proposed changes, regression/safety gates, migration/rollback plan and the least risky feasible reuse strategy. **No change** is a legitimate conclusion when it best meets the goal.

For **redesign-permitted existing projects**, still account for valuable internal assets, but do not elevate preservation into an artificial hard constraint. Compare whole-system replacement only where evidence makes it reasonable, including total migration and transition cost.

### Phase 3M — Mixed initiatives
When some components are established and others novel, apply **3E to components with preservation obligations** and **3N to new or unconstrained capability areas**. Maintain one unified requirement ledger and an explicit map of cross-boundary interfaces. Do not force the entire initiative into a single project label.

### Phase 4 — Discover external reuse options (shared evidence protocol)
Across the applicable branch, investigate in order of likely **net reuse value**:
1. Complete maintained platforms/products and *working* end-to-end reference projects for the appropriate scope.
2. Directly importable libraries and supported APIs.
3. Official integrations/plugins and ready-to-use components.
4. Appropriately licensed reference source, tests, workflows, configurations and templates.
5. Lightweight adapters or wrappers where unavoidable.
6. New logic **only after demonstrating a verified gap** and defining its acceptance test.

For **existing projects**, do not let an external all-in-one platform override the prior internal-reuse and transition assessment. Prefer targeted additions where complete replacement would introduce unnecessary compatibility, migration or operational costs. Find options beyond user-supplied seed repositories, but do not recommend every interesting package.

### Phase 5 — Verify repositories, components and claims
For each serious candidate record:
- Canonical repository URL, official docs/package link, precise edition/license and reuse/copying obligations; separate OSS from paid-only functionality.
- Verifiable release/version/date, maintenance indicators, allowed ecosystem/runtime support and meaningful dependency constraints. Date volatile claims.
- **Actual** source paths, modules, public API names/imports, CLI commands, configurations and tests for claimed behavior, with source links and code references.
- Whether the capability is **Native (N)**, **Integration (I)**, **Reference/example (R)**, **Unsupported (U)** or **Not verified (?)**; do not equate a demo with native support.
- Evidence level: `documentation-verified`, `source-verified`, `test-executed`, or `unverified`. A test in a repo is not the same as a test you ran.
- Functional and semantic boundaries, input assumptions, operational requirements, performance limits, known failures, compatibility and commercial restrictions.
- For existing-code assets, link the same evidence to the actual internal source and preservation conditions, and clearly label access limitations.

Never invent API symbols, imports, files, licenses, releases, functionality, executed test results, benchmarks or coverage metrics. Cite important conclusions; distinguish source observations from recommendations.

### Phase 6 — Map requirements to implementations and reusable assets
For **every supplied exact requirement**, maintain a traceable row:
`ID | exact wording | source | acceptance criterion | current internal implementation (if any) | proposed implementation | canonical repo/internal source + verified API/test path | N/I/R/U/? | evidence level | required inputs/assumptions | automation full/partial/human | reuse route | custom gap | integration/change implications | acceptance test | scope/maturity`.

A vaguely relevant metric or API does not satisfy a requirement unless its **behavioral semantics** meet the acceptance criterion. Keep unknown coverage separate from known gaps. Do not invent unavailable numbered dimensions or change source IDs.

Inventory concrete assets by **direct import**, **configuration/official integration**, **retention/internal reuse**, **licensed reference adaptation**, **component integration/extraction**, **thin compatibility wrapper**, and **last-resort custom code**. For each, document required interfaces, dependencies, license, provenance and test strategy. Show runnable examples only for verified APIs. For existing projects, mark assets to **keep / extend / extract / replace / retire / investigate** and state why.

## Required weighted evaluation — four reuse modes

**Self-contained requirement:** All weighting data and scoring instructions appear below. Do not request, reference, or depend on an external CSV, worksheet, or companion file for this evaluation.


When no user-supplied evaluation profile supersedes it, use the following **default four-mode weighting matrix** to evaluate each *feasible candidate implementation and reuse mode* for a specific requirement or coherent solution. This matrix is **in addition to** the `N/I/R/U/?` functional feature matrix, not a substitute for source-exact coverage verification.

- **FI — Full Import:** consume an existing package/platform as a maintained dependency through public APIs, configuration and supported integrations.
- **CR — Code Reuse:** legally copy or adapt verified source-code units, tests or templates into the target project, with applicable license obligations.
- **LR — Logic Reuse:** adapt documented algorithms/ideas or reimplement verified logic where direct import or copying is not feasible. Track independent implementation effort and IP restrictions; do not prefer it merely because a numerical score is higher.
- **CoR — Component Reuse:** embed, extract or integrate a separable, existing subsystem/component through a defined interface (including existing plugins/adapters). Record its operational/dependency boundary.

**Original weights (as supplied; not yet percentages):**

| Evaluation criterion | FI | CR | LR | CoR |
|---|---:|---:|---:|---:|
| Functional coverage and domain fit | 15 | 8 | 10 | 9 |
| Behavioral correctness and edge cases | 4 | 8 | 19 | 5 |
| Language, framework, runtime compatibility | 9 | 7 | 1 | 13 |
| Architectural fit and coupling | 12 | 7 | 2 | 8 |
| Modularity, extraction seams, API contracts | 5 | 15 | 12 | 15 |
| Code clarity and documentation | 3 | 9 | 12 | 5 |
| Automated tests and reproducibility | 8 | 9 | 18 | 6 |
| License and intellectual property | 10 | 10 | 7 | 10 |
| Dependency footprint and lock-in | 5 | 6 | 2 | 5 |
| Maintenance, community and roadmap | 5 | 3 | 1 | 4 |
| Performance and UX/accessibility quality | 2 | 2 | 3 | 7 |
| Integration effort and time-to-value | 2 | 2 | 3 | 7 |
| **User-supplied column total** | **80** | **86** | **90** | **94** |

**Important normalization:** Although described as percentages, the supplied columns total **FI 80, CR 86, LR 90, CoR 94**, rather than 100. **Do not change the individual supplied weights or pretend they total 100%.** Treat them as *relative priority points* and normalize **within each reuse-mode column** for comparison:

- `normalized_weight(criterion, mode) = 100 × supplied_weight(criterion, mode) / column_total(mode)`.
- Give each criterion an **evidence-backed score from 0 to 5** (`0` unsupported/fails; `1` major deficiencies; `2` partial with major work; `3` adequate; `4` strong; `5` excellent and verified). Explain what each score means **for the actual requirement**; scores are evaluations, **not measured repository facts**.
- `weighted_score_0_to_100(mode) = 100 × Σ(weight_i,mode × score_i,mode) / (5 × Σ weight_i,mode)` using **all 12** original rows. Equivalently, `Σ(normalized_weight_i,mode × score_i,mode / 5)`.
- If evidence is missing, record `?` and **do not invent a score**. Report a defensible **possible score interval**: unknown items contribute `0` to the lower bound and `5` to the upper bound, plus **verified-weight share** `Σ weights_scored / Σ weights_all`. Do not present an interval or provisional midpoint as a fully verified ranking.
- Apply **hard gates first**: exact behavioral/semantic requirements, legally compatible licensing, essential security/privacy, and demonstrably feasible interfaces/runtime. A candidate failing a gate is **ineligible**, even with a high weighted score. A license score does not override legal feasibility.
- Evaluate the mode actually proposed; do not assume every repository supports all four modes. Clearly mark `not applicable` modes. Avoid rewarding code copying or reimplementation solely because it scores well: the overall target remains **maximum verified reuse and minimum original code/integration/maintenance**.
- Cite specific evidence for every nontrivial criterion score (docs, source, tests, releases, dependency metadata or verified measurements). Label untested correctness, unverified runtime compatibility and unmeasured performance/UX as unknown rather than guessing.

**Mandatory scorecard fields:** `requirement/solution ID | repository/asset | reuse mode (FI/CR/LR/CoR) | hard-gate status | 12 criterion scores (0–5/?) | source evidence per score | normalized weighted score or interval (0–100) | verified-weight share | integration/custom-code implications | decision/rationale`.

Present a **ranked reuse-mode scorecard** for feasible shortlisted candidates, and a **mode-by-mode comparison** where multiple reuse strategies are feasible. Keep the separate feature matrix `N/I/R/U/?`. For architecture alternatives, explain how the selected requirement-level modes compose into one system and show overall integration burden; **do not average mode scores across unrelated requirements as a fabricated architecture-completeness score**. Requirement importance must come from the source, otherwise disclose an explicit neutral assumption.

### Phase 7 — Apply weighted reuse evaluation and context-specific decision gates
**The twelve-criterion FI/CR/LR/CoR matrix above is a default evaluation profile**, not a mandatory override of the user's methodology. If the user supplies alternative criteria or weights, follow them, record changes, and normalize appropriately. When a mode is irrelevant, mark it `not applicable` rather than forcing a score. The evidence and hard-gate requirements remain.

For **new projects**, evaluate domain fit, end-to-end coverage, compatibility among selected components, time to a working vertical slice, duplicate dependencies and operational footprint.

For **existing projects**, additionally evaluate **behavioral preservation, internal asset value, change blast radius, API/data/schema compatibility, regression risk, migration feasibility, coexistence, rollback and operational continuity**. These can be hard gates where required, not merely small adjustments to criterion weights. Score the actual proposed modification in its real context. Compare no-change/retain/extend options with external replacement rather than scoring only new packages.

Do not compare incompatible weighted scores as if they were empirically measured facts. Never allow a strong weighted score to override failed hard gates or unsupported assumptions. Do not fabricate equal requirement importance when a priority structure has been supplied.

### Phase 8 — Compare architectures and change strategies
The comparison set must match the project context; do **not** impose a single fixed architecture contest in every request.

| Investigation | Minimum alternatives to consider when applicable |
|---|---|
| New project | **A Minimal:** least-operational-footprint working solution; **B Modular:** small compatible component stack; **C Integrated anchor:** existing complete platform/reference project plus proven gaps. |
| Existing project | **Retain/extend:** preserve assets, configure/add features; **Refactor/extract:** change internal boundaries while keeping contracts; **Replace/migrate:** targeted or broader replacement with transition plan. Include **no change** where appropriate. |
| Mixed | Compare alternatives **per affected subsystem**, then evaluate one coherent target and migration/integration plan. |

Compare verified hard-requirement coverage, behavioral correctness, legal feasibility, security, API/runtime compatibility, integration edges, internal reuse, operational overhead, change risk, maintainability, reversibility and long-term evolution. Do not claim a platform's general feature breadth equals satisfaction of the user's specific requirements.

**Decision precedence:**
1. Reject alternatives violating hard functional, behavioral, legal, security or operational constraints.
2. Maximize **verified** fulfillment of required functionality and preservation obligations.
3. Among viable options, minimize original code, unnecessary integrations, duplicate authority/state, migration risk and long-term maintenance.
4. Prefer a maintained complete solution or retained integrated system when it wins this comparison; otherwise select the smallest composable change.
5. Keep genuinely useful replaceable seams without adding abstractions solely for appearance.

### Phase 9 — Produce an implementation or change blueprint
**Always:** one recommended implementation path, selected existing assets/repositories, exact verified dependencies where available, proposed interfaces, responsibilities, risk register, acceptance criteria, source of authoritative state, and unverified assumptions. Label a suggested repository tree as **proposed**; do not confuse it with verified file paths. Specify **minimum unavoidable original code**, not invented lines-of-code counts.

**New-project blueprint:** selected anchor and add-ons, architecture/data flows, working end-to-end starting point, minimal adapters, deployment envelope, test hooks and staged integration beginning with a vertical slice.

**Existing-project blueprint:** current-state summary; retain/extend/extract/refactor/replace decisions by component; constraints and affected consumers; characterization/regression tests; reversible steps; coexistence or data migration if applicable; rollback and release/operational safeguards. Never propose a migration plan as if it were already executed.

**Mixed blueprint:** combine these treatments while identifying all preservation-sensitive boundaries and shared contracts.

### Phase 10 — Audit completeness and evidence limits
- Crosswalk every **available** supplied requirement to verified coverage, partial coverage, explicit gap or unknown evidence.
- Crosswalk cross-cutting guarantees to the components/policies responsible for them.
- Reconcile the original decomposition, researched alternatives and final implementation mapping without silently omitting source-defined items.
- Separate `covered / partially covered / unsupported / unverified / not supplied`. Describe any needed human review, additional source access, execution testing, measurements or further investigations.
- Recheck significant links, license claims, version/runtime constraints, actual import symbols, denominator/score formulas and original statuses.
- For existing projects, specifically recheck preservation constraints, migration/rollback feasibility, regression evidence and internal asset decisions.
- Do not count tutorials, optional integrations or paid-only extensions as built-in open-source capabilities.

## Research-track planning and adaptive scope
For complex work, partition **research tasks** along cohesive capability families using shared source IDs and evidence conventions. Determine the *number* of tracks from depth, uncertainty, dependency structure and synthesis cost; **never assume a fixed three-track layout** or hardcode scientific/ML topics into an unrelated project. Keep the full technical requirements ledger detailed even when only a few research tasks are commissioned. Reconcile track findings into one implementation or change decision.

For small modifications, narrow the report and evidence gathering to the affected area and its risk boundaries. Do not demand an exhaustive platform search when internal reuse and a simple extension already fully satisfy the request.

## Default deliverables (adapt to user request and project context)
1. **Executive decision:** chosen reuse-first strategy, why it wins, alternatives, important unknowns and hard gates.
2. **Context and source inventory:** project classification, objectives, constraints, source-derived versus proposed requirements, `MISSING_INPUTS`, stable IDs.
3. **Research-backed decomposition:** appropriate capability/functional/architectural or other views, cross-cutting concerns, granularity justification and traceability.
4. **Existing-system assessment (if applicable):** evidence of current behavior, internal reuse inventory, behavioral baseline, change seams and preservation obligations.
5. **Candidate implementation matrix:** every substantive researched candidate, canonical source evidence, N/I/R/U/? and actual compatibility/maintenance facts.
6. **Requirement-to-implementation mapping:** exact supplied requirements and acceptance criteria mapped to internal/external assets or named gaps.
7. **Reuse inventory and weighted comparison:** usable imports/components/source/configurations/tests, FI/CR/LR/CoR scorecard with hard gates and unknown-score treatment (or user's replacement evaluation profile).
8. **Context-appropriate alternatives:** A/B/C for a new solution; retain/refactor/replace options for existing projects; hybrid if mixed.
9. **Single implementation/change blueprint:** chosen components, verified dependencies, adapters, staged integration or migration, regression/acceptance testing and rollback where applicable.
10. **Risk, uncertainty and evidence ledger:** unsupported behavior, legal/paid boundaries, source access limitations, non-automatable needs and primary references.

Do not add irrelevant sections merely to meet this list, but do not hide required traceability or verification results.

## Self-contained invocation template
Fill known fields; omit the rest. No external weighting CSV or companion evaluation file is needed.

```text
Apply the reuse-first-swe-research skill.

Project and desired outcome: {{project_and_goal}}
New, existing or mixed implementation: {{known_context_or_UNKNOWN}}
Authoritative requirements and acceptance criteria: {{documents_or_text}}
Existing code/repositories/interfaces (if any): {{sources_or_NOT_PROVIDED}}
Required behavior, APIs and data to preserve (if any): {{constraints_or_UNKNOWN}}
Permitted languages, frameworks and environments: {{requirements_or_UNSPECIFIED}}
Licensing, security, operational, resource and budget constraints: {{constraints_or_UNSPECIFIED}}
Priorities and evaluation weights: {{user_weights_or_USE_DEFAULT_FI_CR_LR_CoR}}
Preferred output/depth: {{deliverable_or_UNSPECIFIED}}

Research the most appropriate decomposition and granularity for this specific goal.
For new work, discover complete existing solutions first; for existing work, analyze
current behavior and internal reuse before recommending external replacement.
Verify candidates against canonical repositories, source, APIs, tests and licenses.
Compare feasible reuse modes and architectures, apply hard gates and report unknowns.
Return one evidence-backed minimum-reinvention implementation or change plan.
```

## Completion criteria
A research result is complete at the **requested scope** when: (a) all available source requirements are mapped to verified implementation, partial coverage or explicit unknown/gap; (b) significant repository and current-system claims have traceable evidence; (c) decomposition and granularity are defensible; (d) a feasible reusable implementation or change path is selected (or a justified no-change/no-feasible-option conclusion); (e) custom work, tests, risk and transition obligations are explicit; and (f) missing evidence and unavailable source-defined items are disclosed, not invented.