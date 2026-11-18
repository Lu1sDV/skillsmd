# Specification template

Use this structure for the initial draft and the reviewed final specification. Replace angle-bracket fields with actual content. Preserve the required headings; compress irrelevant sections with a reason. Use tables only where they clarify mappings. Do not leave empty placeholders in the delivered plan.

## Contents

- [Identity and application](#identity-and-application)
- [Evidence and method](#evidence-and-method)
- [Workflow and verification](#workflow-and-verification)
- [Review and checklist](#review-and-checklist)

## Identity and application

```markdown
# <Method name>: Implementation specification

Status: <Initial draft | Reviewed revision>
Scope/version: <Specification revision and selected source version>

## Paper/methodology name

<Exact title, method name, authors, and identifiers where available.>
<Identify multiple papers and the role of each if applicable.>

### Paper link

<Primary paper URL or supplied local filename. Exact version/date.>

## Apply to

- Mode: <Faithful reproduction | Method adaptation | Concept-inspired implementation>
- Target subject/application: <Specific intended setting>
- Target inputs and outputs: <Concrete descriptions>
- Implementation maturity: <Demonstrator | Research implementation | Production implementation>
- In scope: <Selected mechanisms and experiments>
- Exclusions: <Excluded components/experiments and consequences>

## Plan goal

<What the user wants to obtain and how the deliverable will be used.>
<Measurable success conditions, their origins, and unresolved target decisions.>
<Keep the original paper's goal distinct from this application's goal.>

## Environment

| Requirement | Authors' setup, if relevant | Target setup | Availability/evidence | Gap or action |
|---|---|---|---|---|
| <Data, compute, storage, equipment, expertise, etc.> | <Source> | <Known or unresolved> | <Verified/provided/assumed> | <Task or none> |

<Constraints and feasibility decisions. Label cost/time/resource estimates and their basis.>

## Tools

| Role | Tool or dependency | Version/revision | Basis for selection | Compatibility/availability |
|---|---|---|---|---|
| <Required capability> | <Known tool or unresolved choice> | <Verified or unknown> | <Source or proposed choice> | <Evidence or resolution task> |

## Outcome expected with this methodology

- Deliverable: <Artifact/state the completed implementation should produce>
- Expected benefit: <Application hypothesis and rationale>
- Comparison: <Appropriate baseline/reference and conditions>
- Success evidence: <Measurements and acceptance rules>
- Limits: <What the paper or selected scope cannot establish>
```

## Evidence and method

```markdown
## Sources and evidence

| Source ID | Source/version | Exact link or file | Inspected material and locators | Access status/role |
|---|---|---|---|---|
| SRC-01 | <Paper/version> | <URL/file> | <Sections/equations/figures/pages> | <Read/partial/inaccessible; role> |

Evidence statuses: Paper-stated; Author-artifact; Inferred; Proposed choice; Adaptation; Unresolved.

<Material source conflicts, interpretations, and consequences. Attach precise locators to the actual claims in later sections.>

## Reconstructed methodology

### Problem, assumptions, and mechanism

<Problem formulation, applicability conditions, causal/mathematical mechanism, and limitations.>

### Component model

| Component ID | Purpose and mechanism | Inputs | Outputs/invariants | Source/status |
|---|---|---|---|---|
| M01 | <Essential function> | <Representation> | <Contract> | <Locator and status> |

### Procedures and phase boundaries

<Operational definitions of equations, algorithms, objectives, and important parameters.>
<Construction/training/calibration versus application/inference phases, when relevant.>
<Manual work, branches, rejection paths, iteration, and stopping conditions.>

### Original evaluation and interpretation

<What was measured, under what conditions, and what those measurements support.>
<Separate reported findings from assumptions or new application claims.>

## Adaptation decisions and reproduction deviations

| Original component/assumption | Target decision | Reason | Preserved mechanism | Changed assumption or comparability | Required evidence |
|---|---|---|---|---|---|
| <M01 and source> | <Replacement/deviation> | <Application constraint> | <What remains valid> | <Consequence> | <Validation task> |

<For a faithful reproduction without known deviations, say so. For concept-inspired work, identify precisely which ideas are reused and which claims are new.>

## Assumptions, unresolved questions, and feasibility gates

| Issue/assumption | Evidence status | Consequence | Affected steps/claims | Smallest resolution | Blocking condition |
|---|---|---|---|---|---|
| <Specific unknown or assumption> | <Status> | <Impact> | <IDs> | <Inspection/probe/decision> | <What can proceed and what must wait> |

<Retain unknowns even when a provisional default is proposed.>
```

## Workflow and verification

```markdown
## Implementation workflow

### Dependency and phase overview

| Step | Phase | Depends on | Consumes | Produces | Gate/branch/loop |
|---|---|---|---|---|---|
| S01 | <Phase> | <IDs or none> | <Artifact> | <Artifact> | <Condition or none> |

<Use a compact diagram only if relationships are clearer than in the table.>

### S01 — <Concrete task name>

#### Reason

<Method component, application requirement, or validation need. Explain why this step contributes.>

#### Task

<Concrete action and selected scope.>

#### Inputs and dependencies

<Prerequisite step IDs, input artifacts, availability, schema/shape/units/state, and relevant preconditions.>

#### How

1. <Executable procedure or meaningful substep.>
2. <Algorithm, pseudocode, equations, configuration, or manual decision procedure.>
3. <Consequential branches, edge cases, iteration, or stopping rules.>

<Specify which parent fields routine substeps inherit and any differences.>

#### References and evidence status

<Source IDs plus exact locators for consequential instructions.>
<Label proposed choices, inferences, adaptations, and unresolved details separately.>

#### Outcome expected

<Produced artifact/state, identifier or location when known, and relevant contracts/invariants.>

#### Acceptance criteria

- Verification: <Specific procedure/case/measurement>
- Pass condition: <Observable requirement; identify source of thresholds/tolerances>
- Evidence to retain: <Output, comparison, record, or result>
- Verification status: <Planned | Reasoned walkthrough | Executed, with actual evidence>

#### Open issues and failure handling

<Missing decisions, rejection/retry/fallback behavior, or "None identified for this step.">
<Identify downstream work that must wait if this step fails.>

<Repeat for all material steps, including integration and evaluation.>

## Validation and evaluation strategy

| Claim or requirement | Check/experiment | Cases/data and selection | Reference/baseline | Metric and acceptance origin | Evidence-producing steps |
|---|---|---|---|---|---|
| <Execution validity, method fidelity, or target benefit> | <Procedure> | <Selection/split/control> | <Reference> | <Definition and source/proposal> | <Step IDs> |

<Include relevant repeatability, uncertainty, contamination controls, and comparability constraints.>
<Specify what cannot be concluded from a component check or completed workflow.>

## Coverage map

| Method component or application goal | Implementation steps | Validation evidence/steps | Included or excluded, with reason |
|---|---|---|---|
| <M01 or goal> | <IDs> | <Acceptance/evaluation reference> | <Status> |
```

## Review and checklist

```markdown
## Review record

- Reviewed revision and scope: <Exact draft/revision>
- Review type: <Self-review | Independent review | Combined>
- Sources/parts actually checked: <Coverage and any access limits>
- Walkthrough: <Representative input, major handoffs, findings; label as reasoning unless executed>

| Finding | Importance | Evidence and affected steps | Resolution/change | Recheck result or open condition |
|---|---|---|---|---|
| <Specific defect or gap> | <Blocking/major/minor> | <Locator/IDs> | <Action> | <Verified disposition> |

<Do not invent findings, independent reviewers, or agreement. Record no material findings if that is the actual outcome, with the review's limits.>

### Readiness verdict

<Ready to implement | Ready subject to conditions | Blocked>

<Justification for the stated scope, material remaining conditions, resolution tasks, and work that can proceed.>
<Distinguish specification readiness from empirical success and from actual implementation completion.>

## Checklist-based implementation plan

<Derive from the reviewed workflow in dependency order. Keep unperformed implementation work unchecked.>

- [ ] **S01 — <Action>.** Prerequisites: <IDs/none>. Complete when: <Acceptance condition>. Retain: <Evidence>. Details: <S01 section>.
- [ ] **S02 — <Action>.** Prerequisites: <IDs>. Complete when: <Acceptance condition>. Retain: <Evidence>. Details: <S02 section>.

<Include integration, outcome evaluation, and condition-resolution tasks. Optional extensions must be labeled optional and cannot obscure required work.>
```
