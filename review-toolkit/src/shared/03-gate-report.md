## What qualifies as a reportable finding

Treat these as defaults for a proposed change. More specific applicable review instructions can override them. Report a candidate only when **all eight** hold:

1. It meaningfully affects accuracy/correctness, security/privacy, availability, expected-load performance, data integrity, test reliability, or maintainability.
2. It is discrete, attributable, and actionable, not a vague theme or collection of unrelated problems.
3. Its fix is proportional to the repository's existing rigor and operational needs.
4. It is introduced by the selected change: demonstrate the delta against baseline. **Exception:** an expressly requested current-state codebase audit can report existing defects but must label the audit scope and must not claim they are new.
5. The author would likely fix it if informed.
6. It does not depend on hidden assumptions about intent, deployment, traffic, or surrounding code.
7. When another component is said to break, identify that concrete caller, contract, consumer or configuration and the mechanism; conjecture alone does not count.
8. It is not just a clearly intentional change to behavior.

Cross the evidence gate by attempting to **disprove** each plausible finding: check old code, all relevant callers, guards, alternatives, explicit requirements, tests, and practical triggering conditions. If you cannot substantiate it, do not downgrade speculation into P3; describe the missing evidence only in the concise limitations cell when it matters.

A missing test by itself is not always a bug; it becomes a finding when you can identify a material newly unprotected regression or broken documented test requirement with a credible failure scenario. A file crossing 1,000 lines is an investigation trigger only, not a finding by itself. Ignore cosmetic styling except when it obscures meaning or violates documented standards. A design/maintainability issue can qualify if a concrete current consequence and a better proportionate structure are demonstrated.

### Priorities

- **P0 Critical:** concrete and broadly applicable severe damage; immediate intervention is necessary, and preconditions are supported.
- **P1 High:** serious reachable defect that warrants prompt correction, with explicit trigger and impact.
- **P2 Normal:** meaningful defect or production-design regression to address in normal corrective work.
- **P3 Low:** narrower but still demonstrably worthwhile fix; no style nits or unsupported worries.

Use one priority per root cause, never an inflated one. Report **all** distinct qualifying findings; do not stop at the first and do not fill a quota. Order by P0 through P3, then by consequence.

### Mandatory final output: exactly the shared table format

Start with a two- or three-sentence **What this change does:** description (or **What was audited:** for an explicit current-state audit). Then this compact summary table, populated with truthful observed facts:

| Scope / depth | Parallel reviewers | Checks / evidence | Coverage / limitations | Disposition |
|---|---|---|---|---|
| `<base..head or path scope>; NORMAL/DEEP/ULTRA` | `domain requested/completed; risk requested/completed; holistic requested/completed` | `tests/commands performed and results; or not run` | `reviewed domains, blocked methods and important unknowns` | `Ready` or `Fix F1, F3` or `Incomplete verification` |

Then the **Findings** table with only these six columns:

| ID | Priority | Area | Location | Finding: trigger, evidence, impact | Smallest useful remedy |
|---|---|---|---|---|---|
| F1 | P1 | Correctness | `src/example.py:42–44` | If `<real input>`..., this introduced path..., so the named caller... | Change ... and add a targeted regression test. |

Every finding's *comment body* is **one brief natural-language paragraph**, with no manual line breaks except short code fragments. Begin with the input/environment/trigger when severity depends on it. State why the issue occurs and its actual consequence plainly; avoid praise, accusation, vague `consider`, and ungrounded certainty. Anchor to the smallest relevant changed-line range (or actual current file for an explicit audit). Make no code snippet longer than three lines.

When there are no qualifying findings, keep the six-column Findings table with one status row `— | — | — | — | No qualifying findings in the inspected scope. | —`. Do not create a finding ID, priority, or extra list of rejected hypotheses.

Only if a concrete replacement is short and useful, place a **separate** `F# suggestion` subsection after the table. Use fenced `suggestion` code blocks only for exact replacement lines; preserve the original leading spaces/tabs and outer indentation exactly, unless changing indentation is the necessary fix. Never include commentary inside a suggestion block. Use the table's remedy field otherwise.

Do not append extra sections full of discarded concerns, benign observations, hypothetical future risks, or celebratory text. A missing independent agent or incomplete specialist discovery belongs in the limitations field, not a fictitious finding. Never claim a check ran if it did not.
