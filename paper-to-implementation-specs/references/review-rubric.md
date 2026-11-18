# Review rubric

Use this rubric to review an actual draft against its sources and target application. Report findings and dispositions; a checked review form alone does not establish correctness.

## 1. Establish the review basis

- Identify the exact draft, source versions, mode, implementation maturity, goal, and exclusions.
- Inspect the relevant sources directly. State access limits and identify whether the review is independent or a self-review.
- Distinguish checking a specification, reasoning through a case, and executing an implementation.
- Focus on material method, execution, and evaluation defects. Do not invent criticism to fill a quota.

## 2. Check source fidelity and evidence

- Verify that consequential procedural claims, equations, parameters, and assumptions have specific supporting locators.
- Check symbol meanings, dimensions, units, indexing, optimization direction, boundary conditions, and algorithm order where relevant.
- Look for details that have been inferred, adapted, or introduced as choices but labeled as source requirements.
- Inspect essential appendices, figures, author artifacts, and delegated methods where the draft depends on them.
- Check that referenced artifacts were actually inspected, versions are consistent, and source conflicts remain visible.
- Ensure unknowns are not hidden behind confident prose or generic implementation instructions.
- Confirm that reported results retain their experimental conditions and are not converted into guaranteed outcomes.

## 3. Check method and goal coverage in both directions

Walk from every required method component and application goal to its implementation and verification tasks.

Walk from every material task back to its method component, goal, validation need, or justified engineering purpose.

Check for omitted initialization, preprocessing, manual procedures, construction/training, application/inference, integration, measurement, rejection paths, loops, and stopping conditions as applicable.

Check whether exclusions and simplified components change the selected goal, claimed fidelity, or comparability. Require a stated consequence rather than silently accepting the omission.

For adaptation, verify the preserved mechanism, changed assumptions, and experiments needed to justify transfer. For concept-inspired designs, check that new claims rely on their own evidence.

## 4. Walk through execution and interfaces

Choose a representative input and trace its proposed path through the entire workflow. Use a small hand-checkable case when possible. Include a consequential failure or edge case when it tests an important assumption.

At every handoff, check:

- The input exists and its producer is identified.
- Format, type, shape, units, indexing, state, and identifiers agree.
- Preconditions are satisfied and information is not used before it is available.
- Branches and retries have conditions, and iterations have stopping rules.
- Outputs provide what the next task and final evaluation require.
- Failure handling does not silently change the method or conceal rejected cases.

Check dependency cycles: legitimate iterative algorithms need an initial state and a stopping rule; accidental prerequisite cycles need correction.

Record the walkthrough's findings without claiming that planned code was executed.

## 5. Check feasibility and scope

- Compare the target environment with actual requirements and available evidence.
- Identify missing data, artifacts, tooling, compute/equipment, human expertise, or manual effort.
- Check that the authors' setup is not presented as a proven minimum requirement.
- Prefer an early, inexpensive feasibility probe when it resolves a significant uncertainty.
- Ensure estimates are labeled and grounded; do not turn guesses into measured facts.
- Keep optional extensions and production concerns proportional to the user's requested scope.

## 6. Trace success criteria backward

For each intended claim, locate the procedure and tasks that produce the evidence needed to assess it.

Check separately for valid execution, faithful method implementation, and application benefit. Confirm that each material task has an observable acceptance condition and evidence artifact.

Check case/data selection, baseline suitability, metric definitions, threshold origins, comparison conditions, relevant controls, repeatability, uncertainty, and data contamination/leakage risks as applicable.

Reject circular reasoning in which an unverified implementation is its own only reference. Verify that evaluation does not merely confirm a formatting property while claiming scientific success.

Where a threshold or reference is missing, require an explicit decision/calibration task or a qualified verdict.

## 7. Record, resolve, and recheck findings

For each finding record:

- The concrete defect or gap and why it matters.
- The source evidence or reasoning and affected step IDs.
- Importance: blocking, major, or minor.
- The correction, investigation, or scoped exclusion.
- The result of checking the revised draft, or the remaining condition and its gate.

Prioritize findings that change the method, invalidate evaluation, or prevent execution. Correct related downstream tasks and acceptance criteria when a source interpretation changes.

Use bounded review iterations. Recheck material fixes and their consequences; expose any unresolved blockers rather than endlessly re-reviewing or relabeling uncertainty as certainty.

## 8. Assess readiness and checklist consistency

Use the readiness definitions in SKILL.md. Qualify the verdict by scope and inspected evidence.

- Ready to implement: no unresolved implementation-blocking gap for that scope.
- Ready subject to conditions: explicit gates and resolution tasks identify what can proceed and what must wait.
- Blocked: a critical missing method, evidence, evaluation, or resource requirement prevents the selected goal.

Ensure every checklist task maps to the latest reviewed specification, respects dependencies, includes its completion condition and evidence, and retains blockers or conditions. Check that no new decisions were introduced during checklist generation.

Leave unperformed implementation tasks unchecked. A passed specification review is not evidence that the implementation exists or achieves the claimed result.

Finish with the justified verdict, material resolved findings, remaining conditions, and the smallest next actions needed.
