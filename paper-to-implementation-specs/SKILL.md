---
name: paper-to-implementation-specs
description: >-
  Turn technical research papers into source-grounded implementation specifications and reviewed execution checklists. Use when a user wants to implement or reproduce a paper, adapt a methodology to a different subject or environment, derive an engineering plan from research, or review whether a paper-based implementation plan is complete and actionable. Reconstruct the method, identify assumptions and missing details, specify dependencies and acceptance criteria, review fidelity and coverage, and produce a checklist. Support faithful reproduction, method adaptation, and concept-inspired designs.
---

# Paper to Implementation Specs

Convert a technical paper into an implementable, auditable specification for the user's actual goal. Preserve the method's reasoning and limitations while making every consequential implementation decision visible.

## Resources

- Read [Specification template](references/spec-template.md) when writing the initial draft. Retain its required sections; condense inapplicable sections with a brief reason.
- Read [Review rubric](references/review-rubric.md) before reviewing the draft and again when assessing whether material findings have been resolved.

## Operating rules

- Complete the sequence: establish scope, inspect sources, reconstruct the method, assess adaptation and feasibility, write a draft, review and revise it, then derive the execution checklist.
- Write the initial draft before reviewing it. Revise that draft into the final specification and preserve substantive findings and their disposition in a review record. Avoid duplicate full documents unless requested.
- Deliver the reviewed specification, review record, and checklist together by default. Honor the user's destination, format, language, and existing project conventions; use the available document/file workflow when a saved deliverable is requested.
- Plan the implementation. Execute the proposed methodology only when the user also requests execution. Clearly distinguish source inspection, mathematical reasoning, specification walkthroughs, and checks actually run.
- Keep published results, proposed targets, expected artifacts, and measured results distinct. Never promise that reproducing or adapting a method guarantees its reported benefit.
- Match depth to consequential decisions. Do not require repetitive documentation for trivial actions.
- Use available source-reading, browsing, PDF, repository, and artifact tools as appropriate. Do not assume a particular connector, external account, or runtime exists.

## 1. Establish the application and scope

Extract the following from the request and visible context:

- Paper or papers, links/files, and requested versions.
- Target subject, inputs, users, or application under **Apply to**.
- Plan goal, deliverables, success measures, constraints, and explicit exclusions.
- Target environment, available tools, data, equipment, compute, expertise, and budget/time constraints when relevant.
- Desired maturity: demonstrator, research implementation, or production implementation.

Select and state one relationship to the paper:

| Mode | Preserve or establish | Evaluate against |
|---|---|---|
| Faithful reproduction | The selected original method and experimental conditions; disclose unavoidable deviations. | The source procedure and comparable reference results. |
| Method adaptation | The core mechanism and its necessary assumptions; justify changes. | The target application and evidence that the adaptation preserves what matters. |
| Concept-inspired implementation | The particular ideas reused and the new design built around them. | The new design's own requirements and experiments. |

Keep mode separate from implementation maturity. If the user only says to implement a paper, provisionally use faithful reproduction of its method; determine which experiments are in scope from the request. Do not silently expand to all benchmarks or production deployment.

Proceed with explicit, low-impact assumptions. Ask a focused question only when ambiguity materially changes the method, application, or feasibility and available context cannot resolve it. Complete useful source analysis and unblocked planning first. Never silently choose a new application or invent available resources.

## 2. Inspect and pin the evidence

1. Identify the exact title, authors, paper link, version/date, and identifiers where available. Pin the version used instead of silently mixing revisions.
2. Read the full paper, including methodology, evaluation, limitations, and relevant appendices. Inspect figures, tables, algorithms, and equations when they affect implementation. If extraction is damaged or ambiguous, inspect the visual source or mark the detail unresolved.
3. Inventory inspected sources with stable IDs, versions/commits when available, precise locators, access status, and their role. Mark partially read or inaccessible sources honestly.
4. Follow supplements, author code/configurations, and cited methods only as far as necessary to resolve material implementation or evaluation decisions. Prefer primary sources; do not perform an unrestricted literature survey.
5. Inspect implementation details in the actual artifact when available. An abstract, repository landing page, or uninspected citation does not establish those details.
6. Record disagreements between the paper, code, versions, or other sources. Preserve both claims, the consequence, and the chosen interpretation or blocker. Do not silently treat code as overriding the paper or vice versa.

Attach a source ID and a locator such as section/page, equation, figure, algorithm, table, appendix, or repository path and revision to consequential sourced instructions. For local inputs, use a stable filename and internal locator. Never fabricate a citation, version, commit, parameter, or experimental result.

Use these evidence statuses at the decision or instruction level; split mixed statements when necessary:

| Status | Meaning |
|---|---|
| Paper-stated | Explicit in the inspected paper or supplement. |
| Author-artifact | Explicit in an inspected author implementation, configuration, or dataset artifact. |
| Inferred | Derived from evidence but not explicitly specified; provide the reasoning. |
| Proposed choice | An engineering default or target introduced for this implementation. |
| Adaptation | An intentional departure for the target application. |
| Unresolved | Missing, ambiguous, contradictory, inaccessible, or insufficiently understood. |

When a gap remains, record what is unknown, affected tasks/claims, consequences, and the smallest investigation or decision that would resolve it. A proposed default must retain its proposed status. Do not conceal a methodological gap with a generic instruction such as “implement the standard approach.”

## 3. Reconstruct the methodology

Create a compact, implementation-relevant method model before expanding tasks:

- Problem formulation, inputs, outputs, and conditions of applicability.
- Core mechanism and the causal or mathematical reason each major component contributes.
- Equations, algorithms, objectives, decision rules, and invariants.
- Intermediate representations and important schemas, shapes, units, indexing, or state.
- Preconditions, assumptions, manual work, external dependencies, and limitations.
- Phase boundaries, branches, iteration, rejection paths, and stopping conditions.
- Evaluation setup, comparison conditions, metrics, and what the reported evidence supports.

Assign method-component IDs such as M01. Distinguish essential mechanisms from the authors' replaceable implementation choices, with evidence or an explicit inference.

Separate construction/training/calibration from application/inference/production when the method does. Include data sourcing, preparation, annotation, splitting, and contamination/leakage controls when relevant. Include human judgment and measurement procedures rather than assuming every stage is automated.

Translate implementation-critical mathematics or prose into operational definitions or pseudocode. Verify symbol meanings and important boundary cases. Mark unresolved derivations; do not claim comprehension of an unread or undeciphered mechanism.

## 4. Assess adaptation and feasibility

For each material adaptation, record the original component, target replacement, rationale, preserved mechanism, changed assumptions, affected tasks, and validation needed. Explain why the transformation is defensible. Treat transfer of reported benefits as a hypothesis.

For faithful reproduction, record deviations and their effect on comparability. For concept-inspired work, identify reused ideas and distinguish new claims from the paper's evidence.

Compare the authors' setup with the target setup. Identify unavailable artifacts, incompatible tools, resource constraints, and required expertise. Do not equate the paper's equipment with a verified minimum requirement.

Place inexpensive feasibility probes before expensive dependent work when they can resolve a material uncertainty. Label estimates as estimates and explain their basis; do not invent measured costs, timings, or capacity. Document scoped exclusions and their consequences.

## 5. Write the initial implementation draft

Use the specification template. Preserve the user's core headings: **Paper/methodology name**, **Paper link**, **Apply to**, **Plan goal**, **Environment**, **Tools**, and **Outcome expected with this methodology**.

Assign stable step IDs such as S01 and organize steps by dependencies and execution phases, not just the paper's section order. Parallelize only independent work. Represent meaningful branches and loops with conditions rather than flattening them into a misleading list.

For each material step provide:

- **Reason:** the method component, application requirement, or validation need it serves.
- **Task:** a concrete action.
- **Inputs and dependencies:** prerequisites, consumed artifacts, and their contracts.
- **How:** the procedure, equations/pseudocode/configuration, decision rules, and consequential edge cases needed to perform the work.
- **References and evidence status:** precise support plus clear provenance for any inference, choice, or adaptation.
- **Outcome expected:** the produced artifact/state and its relevant schema, units, or invariants.
- **Acceptance criteria:** verification procedure, expected evidence, and the origin of any threshold or tolerance.
- **Open issues/failure handling:** relevant missing decisions, blocked dependencies, rejection/retry behavior, and resolution work.

Decompose until a competent implementer can act without making an undisclosed methodological decision and a reviewer can identify evidence of completion. Let routine substeps inherit explicitly named parent rationale, references, and contracts; describe any differences. Avoid “implement X” or “evaluate quality” when the consequential procedure remains unspecified.

Include integration and evaluation tasks, not only component construction. Keep essential work and optional extensions visibly separate.

## 6. Specify verification and outcome evaluation

Cover three distinct questions:

1. Does the implementation execute and produce valid artifacts?
2. Does it correctly implement the selected method?
3. Does it achieve the target application outcome?

Select checks proportional to the claims: hand-checkable cases, numerical or structural invariants, reference comparisons, integration checks, suitable baselines, ablations, held-out evaluation, or experimental controls. Include uncertainty and repeatability requirements for stochastic results when relevant.

State the dataset or case selection, measurement procedure, comparison conditions, metric definitions, and acceptance rules. Identify the source of every consequential threshold: paper, user requirement, external source, or proposed target. Where a target cannot yet be justified, add a calibration/decision task rather than fabricate precision.

Prevent circular validation: avoid defining correctness solely by agreement with another output produced by the same unverified implementation. Do not infer empirical success from completed implementation tasks.

## 7. Review, revise, and decide readiness

Read the review rubric. Review against the actual sources, application scope, and latest draft.

Perform source-fidelity checks, bidirectional method/goal coverage, a representative input walkthrough, dependency/interface checks, feasibility checks, and backward tracing from success criteria to evidence-producing tasks.

When independent reviewers are available and complexity warrants them, give them source artifacts, the application requirements, and the draft. Do not feed them the author's preferred conclusions. Identify the review as self-review when no independent pass occurred; never manufacture reviewer agreement.

Record material findings with affected steps, evidence, importance, resolution, and remaining conditions. Revise the specification, then recheck affected sections and downstream tasks. Do not declare findings fixed without checking the revision. Use bounded review passes; if critical issues remain, expose them rather than loop indefinitely or claim completion.

Assign a verdict for the stated scope:

- **Ready to implement:** no unresolved implementation-blocking detail or dependency for that scope; empirical outcomes still require evaluation.
- **Ready subject to conditions:** explicit conditions have defined resolution tasks/gates; identify work that can proceed and work that must wait.
- **Blocked:** a critical method, evidence, evaluation, or resource gap prevents the selected goal; identify the smallest resolution and any independently useful work.

Qualify completeness by the selected scope and inspected sources. A review assesses the specification; it does not prove the method's scientific claims or that future execution will succeed.

## 8. Derive and deliver the execution checklist

Generate the checklist from the reviewed specification using the same step IDs and dependency order. Include implementation, integration, evaluation, and unresolved-condition resolution tasks. For each item provide the action, observable completion condition, evidence to retain, and pointer to the detailed step.

Keep new implementation tasks unchecked. Mark an item complete only when its own acceptance evidence exists; reading a paper, reviewing a plan, or reasoning through an example does not complete implementation.

Do not introduce new design decisions in the checklist. If checklist generation reveals a missing task or acceptance rule, amend the specification and review the change first.

Before delivery, check that every required component and goal is covered or explicitly excluded, every material step has inputs/outputs and acceptance evidence, citations support their claims, assumptions and blockers remain visible, and checklist IDs match the final specification.

Deliver the complete specification, review findings/dispositions, readiness verdict, and execution checklist. In the accompanying summary, state the mode, scope, major adaptation decisions, and material unresolved conditions. Do not describe planned checks as executed tests.
