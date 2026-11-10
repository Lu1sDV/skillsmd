# Improve Codebase Architecture — evidence-backed

**Status:** skill design and static validation; **not yet benchmarked on a real repository**. Install the single `improve-codebase-architecture/` folder in `.claude/skills/` (or another compatible skills location). Invoke the skill directly. Its core method is included; other available skills may be used when useful but are not prerequisites. Review is read-only within the target repo; any domain-document change or implementation requires user authorization.

## File map

```text
improve-codebase-architecture/
  SKILL.md      # short executable orchestration; two-sentence peer dialogue
  METHOD.md     # G0–G5; recursive evidence, falsification, stopping
  COVERAGE.md   # sixteen 00–15 dimensions + fourteen D1–D14 decision lenses
  DESIGN.md     # deep-module and active domain-modeling rules
  EVAL.md       # agent regression/evaluation cases
  README.md     # provenance, use map, and audit
```

**Mission:** decide whether deepening is worth doing, not manufacture refactors. Focused reviews screen 00–15 and deepen only decision-relevant dimensions; comprehensive audits require explicit scope. The terminal review can recommend no refactor. Evidence collection and claims are separate from design preferences and repository edits.

## Design decisions

- **Consolidated method:** `METHOD.md` contains investigation and evidence rules; `COVERAGE.md` contains review dimensions and architectural lenses; `DESIGN.md` contains deep-module design and domain-modeling practices. Terminal reporting and evaluation are separate.
- **No required skill calls:** Core deep-module and domain-modeling rules are included; other skills may still be used when beneficial.
- **Domain modeling:** `DESIGN.md` covers ambiguity resolution, code-vs-domain contradiction handling, scenario probes, multi-context placement, authorized glossary updates, and a strict ADR offer gate. Domain modeling is not another mandatory broad scan: it deepens when meaning is disputed or a selected design changes the domain model.
- **Peer design:** `SKILL.md` sets evidence-led discussion, user ownership of decisions, and dependency ordering without scripted interviewing.
- **Consent:** glossary/ADR writes do not occur during read-only review. At the user-selected design phase, explicit permission may authorize inline term updates; ADRs are still offered individually. This protects repository state while keeping the original domain-modeling habit.

## Source use and quotation policy

Each entry gives a short quotation from the accessible source page/abstract, the rule it influenced, and its limits. Quotes are not certification of compliance or proof that full paid standards were consulted. The [Sxx] references here are **methodology sources**, never evidence about a user's codebase. The 00–15 headings are our synthesis, not an official standard's checklist.

### [S01] NASA — Systems Engineering Handbook, §4.3, Logical Decomposition
- **Source:** NASA, [4.3 Logical Decomposition](https://www.nasa.gov/reference/4-3-logical-decomposition/).
- **Source quotation:** “The process is recursive and iterative”.
- **Used for:** `METHOD.md` recursive goal → question → source-backed leaf and G0–G2; `COVERAGE.md` 00,05–06.
- **Scope/limit:** Parent-to-child requirements and function analysis, explicit inputs/outputs/failure modes, and iteration. NASA's method engineers systems; our bounded repository-review loop is a **derived adaptation**, not NASA's prescribed software-agent workflow.

### [S02] SEI — Goal/Question/Metric (GQM)
- **Source:** Carnegie Mellon SEI, [Selecting Measurement Data for Software Assurance Practices](https://www.sei.cmu.edu/blog/selecting-measurement-data-for-software-assurance-practices/).
- **Source quotation:** “establish a link between the software assurance target and the engineering practices”.
- **Used for:** `METHOD.md` goal/question/evidence chain; `COVERAGE.md` 02,11.
- **Scope/limit:** Questions and measurements should derive from a real goal. A code trace and interpretation are not automatically a quantitative metric; we use a qualitative GQM-style adaptation when measurement is unavailable.

### [S03] GSN Community Standard — Goal Structuring Notation
- **Source:** Assurance Case Working Group / Safety-Critical Systems Club, [GSN Standard (2021)](https://scsc.uk/resources/citation_r1386.html) and [standard overview](https://scsc.uk/gsn-standard).
- **Source quotation:** “guidance on current best practice in the use of the notation”.
- **Used for:** `METHOD.md` claim/defeater and evidence ledger; `METHOD.md` terminal traceability; `COVERAGE.md` 14.
- **Scope/limit:** Explicitly structured engineering arguments. Our text-based *lightweight assurance case* is **GSN-inspired**, not a formal GSN diagram or safety assurance certification. Deliberate counterevidence is an added reviewer rule.

### [S04] CMU SEI — Architecture Tradeoff Analysis Method (ATAM)
- **Source:** Carnegie Mellon SEI, [ATAM Collection](https://www.sei.cmu.edu/library/architecture-tradeoff-analysis-method-collection/) and [ATAM technical report](https://www.sei.cmu.edu/library/the-architecture-tradeoff-analysis-method/).
- **Source quotation:** “Risks are synthesized into a set of risk themes”.
- **Used for:** `METHOD.md` G3 scenario tradeoffs; `COVERAGE.md` 02,09,12.
- **Scope/limit:** Analyze architectural decisions under competing quality attribute scenarios and expose risks, sensitivities and tradeoff points. We do **not** claim to perform the formal nine-step, stakeholder-run ATAM assessment during every skill run.

### [S05] ISO/IEC/IEEE 42010:2022 — Architecture Description
- **Source:** ISO, [ISO/IEC/IEEE 42010:2022 official abstract](https://www.iso.org/standard/74393.html).
- **Source quotation:** “This document distinguishes the architecture of an entity of interest from an AD expressing that architecture.”
- **Used for:** `COVERAGE.md` 00–03 architecture views and scope; `METHOD.md` G0–G1.
- **Scope/limit:** Stakeholder concerns, architecture descriptions and viewpoints. **The standard explicitly does not prescribe architecting processes/methods or the architecture itself.** It is *not* authority for our recursive review algorithm.

### [S06] ISO/IEC 25010:2023 — Product Quality Model
- **Source:** ISO, [ISO/IEC 25010:2023 official abstract](https://www.iso.org/standard/78176.html).
- **Source quotation:** “The product quality model is composed of nine characteristics”.
- **Used for:** `COVERAGE.md` 02,08–09,12 quality screening; `METHOD.md` G3.
- **Scope/limit:** A structured **taxonomy** of product quality, not a fixed test suite or requirement that all characteristics be investigated equally. The detailed paid standard text was not needed to establish this use.

### [S07] arc42 — Architecture documentation and runtime-view guidance
- **Source:** arc42, [template sections](https://docs.arc42.org/) and [Runtime View, section 6](https://docs.arc42.org/section-6/).
- **Source quotation:** “It is not important to describe a large number of scenarios.”
- **Used for:** `COVERAGE.md` 03–04,06,13; `METHOD.md` optional before/after text sketches.
- **Scope/limit:** Useful documentation coverage and representative scenario views. The skill's 16-section dossier is **not** an arc42-conformant template; it extends and repurposes concepts for review.

### [S08] ISO/IEC/IEEE 29148:2018 — Requirements Engineering
- **Source:** ISO, [ISO/IEC/IEEE 29148:2018 official abstract](https://www.iso.org/standard/72089.html).
- **Source quotation:** “specifies the required information items produced through the implementation of the requirements processes”.
- **Used for:** `METHOD.md` question traceability and evidence leaves; `COVERAGE.md` 00,02,14.
- **Scope/limit:** Requirements processes and their information items. Our review leaf schema is an **engineering synthesis**, not a clause-by-clause implementation of this standard.

### [S09] IEEE 1012-2024 — Verification and Validation
- **Source:** IEEE Standards Association, [IEEE 1012-2024 description](https://standards.ieee.org/ieee/1012/7324/).
- **Source quotation:** “analysis, evaluation, review, inspection, assessment, and testing of products”.
- **Used for:** `METHOD.md` validation-status distinctions; `COVERAGE.md` 01,05,09–10,14.
- **Scope/limit:** Separating verification/validation purposes and methods. This package **does not claim IEEE 1012 compliance**, integrity-level assignment or independent V&V certification.

### [S10] OWASP — Application Security Verification Standard 5.0.0
- **Source:** OWASP, [ASVS official site](https://asvs.owasp.org/), stable 5.0.0 released 2025-05-30.
- **Source quotation:** “A framework of security requirements for designing, developing and testing modern web applications and web services.”
- **Used for:** `COVERAGE.md` 07 conditional web-app security checks.
- **Scope/limit:** Domain-specific security verification **when relevant**. Screening against ASVS categories is not an ASVS audit or certification.

### [S11] NIST SP 800-218 — Secure Software Development Framework (SSDF)
- **Source:** NIST, [SP 800-218 (2022)](https://csrc.nist.gov/pubs/sp/800/218/final).
- **Source quotation:** “a core set of high-level secure software development practices”.
- **Used for:** `COVERAGE.md` 07 secure-development and dependency context.
- **Scope/limit:** Development-process safeguards, not proof of a particular source file's authorization properties. Do not substitute SSDF for a threat-model/behavior trace.

### [S12] Research Data Alliance — FAIR Principles for Research Software (FAIR4RS)
- **Source:** RDA FAIR4RS working group, [FAIR4RS principles](https://www.rd-alliance.org/groups/fair-research-software-fair4rs-wg/outputs/fair-principles-for-research-software-fair4rs-principles-2/).
- **Source quotation:** “productivity, quality, reproducibility, and sustainability”.
- **Used for:** `COVERAGE.md` 08 research software reproducibility/reuse screening.
- **Scope/limit:** Research-software FAIRness and reuse. **Not** experimental-design validation, statistical correctness, dataset-leakage detection or an ML benchmarking protocol; those require domain-specific methods.

### [S13] Anthropic — Skill Authoring Best Practices
- **Source:** Anthropic, [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).
- **Source quotation:** “Split content into separate files when approaching this limit.”
- **Used for:** `SKILL.md` concise staged entry; selective references; `METHOD.md` terminal report checks; `EVAL.md`.
- **Scope/limit:** Progressive disclosure, clear steps, examples, validation and iterative evaluation. It does **not** establish that this particular skill design performs better without trials.

### [S14] OpenAI — Evaluate Agent Workflows
- **Source:** OpenAI, [Evaluate agent workflows](https://developers.openai.com/api/docs/guides/agent-evals).
- **Source quotation:** “Use traces, graders, datasets, and eval runs to improve agent quality.”
- **Used for:** `EVAL.md` trace-based paired regression evaluation.
- **Scope/limit:** Real execution traces and evaluations, *not* a guarantee that increased recursive detail is beneficial. Benchmark results must be measured.

### [S15] John Ousterhout — Stanford software-design teaching notes
- **Source:** John Ousterhout, Stanford University, [Modular Design](https://web.stanford.edu/~ouster/cgi-bin/cs190-winter18/lecture.php%3Ftopic%3DmodularDesign) and [author's book page](https://web.stanford.edu/~ouster/cgi-bin/aposd.php).
- **Source quotation:** “Goal: interface should be much simpler than the implementation”.
- **Used for:** `DESIGN.md` vocabulary, depth, information hiding and deletion test; `COVERAGE.md` D1–D14.
- **Scope/limit:** Deep modules and information hiding as a design philosophy. Our *depth-as-leverage* formulation and deletion-test usage are adapted from the **user-provided skill**, not directly required by Ousterhout's source.

### [S16] Martin Fowler — Legacy Seam, citing Michael Feathers
- **Source:** Martin Fowler, [Legacy Seam (2024)](https://martinfowler.com/bliki/LegacySeam.html); Michael Feathers, [Working Effectively with Legacy Code (Pearson)](https://www.pearson.com/en-us/subject-catalog/p/Feathers-FEATHERS-WORK-EFFECT-LEG-CODE-p-1/P200000008984/9780131177055), chapter 4, *The Seam Model*.
- **Source quotation:** “places where we can alter the behavior of the system without editing source code”.
- **Used for:** `DESIGN.md` seam/adapters and test fidelity; `COVERAGE.md` D5/D8.
- **Scope/limit:** A seam provides an enabling point for substituting behavior. **Neither source requires** the original skill's absolute “one adapter hypothetical, two real” rule; the revised skill treats adapter count as evidence, not a law.

### [S17] Matt Pocock — `domain-modeling` (original skill and documentation)
- **Source:** [Original documentation](https://github.com/mattpocock/skills/blob/main/docs/engineering/domain-modeling.md) and [GLOSSARY-FORMAT.md](https://github.com/mattpocock/skills/blob/main/skills/engineering/domain-modeling/GLOSSARY-FORMAT.md).
- **Source quotation:** “It is the active discipline, not the passive one.”
- **Used for:** `DESIGN.md` active ambiguity resolution, source contradictions, scenario tests, canonical terminology, multi-context glossary placement, lazy creation, inline approved edits and all-three ADR gating; `SKILL.md` G5. 
- **Scope/limit:** The active discipline and conventions are adapted, not copied as a separate skill. Some forks use `CONTEXT.md` rather than the current documentation's `GLOSSARY.md`; Use existing repository conventions without forced migration. No user permission for repository changes is inferred from the skill's mere invocation.

### [S18] Matt Pocock — `grilling` (original skill)
- **Source:** [Original SKILL.md](https://github.com/mattpocock/skills/blob/main/skills/productivity/grilling/SKILL.md).
- **Source quotation:** “The decisions are the user's”.
- **Used for:** `SKILL.md` peer discussion, factual research responsibility and dependency ordering.
- **Scope/limit:** Deliberately **does not preserve** mandated numbered question rounds, frontier batching or special Q1/Q2 format. Those were presentation/process constraints, not necessary to the architecture-review objective. Other skills remain optional.

## Dimension-to-source map

| Review dimensions | Foundations | Implementation |
|---|---|---|
| 00–02 Mission, snapshot and product goals | S01,S02,S05,S08,S09 | `METHOD.md` G0, `COVERAGE.md` 00–02 |
| 03–04 Architecture and inventory | S05,S07,S15 | `COVERAGE.md` 03–04, D1–D6 |
| 05–06 Data and execution | S01,S07,S09,S17 | `COVERAGE.md` 05–06; `DESIGN.md` domain rules |
| 07 Security | S10,S11 | `COVERAGE.md` 07, D10 |
| 08 Scientific contracts | S06,S12 | `COVERAGE.md` 08 |
| 09 Reliability and concurrency | S04,S06,S09 | `COVERAGE.md` 09; D8–D11 |
| 10–11 Status and hypotheses | S02,S03,S09 | `METHOD.md` G1–G2, `COVERAGE.md` 10–11 |
| 12 Improvements/tradeoffs | S04,S15,S16 | `METHOD.md` G3, `DESIGN.md` |
| 13 Prior decisions | S07,S17 | `COVERAGE.md` 13; `DESIGN.md` ADR gate |
| 14 Evidence index | S03,S08,S09 | `METHOD.md` ledger and `METHOD.md` |
| 15 Reviewers and outputs | S03,S13,S14 | `COVERAGE.md` 15; `METHOD.md`; `EVAL.md` |
| Post-selection peer design | S15,S16,S17,S18 | `SKILL.md` G5; `DESIGN.md` technical decision tests |

**Important distinctions:** ISO 42010 [S05] specifies architecture-description concerns, not this audit workflow. FAIR4RS [S12] supports research-software reuse, not empirical metric validity. GSN [S03] informs a lightweight claim-evidence argument, not formal assurance certification. Adapter-count and deletion-test rules are adapted heuristics, not an ISO requirement. Agent evaluations [S14] are needed to determine whether this skill actually improves results.

## Release checks

Static checks should verify YAML frontmatter; local links; exact coverage of all sixteen dimensions and fourteen lenses; no *mandatory* external skill dependency; glossary/ADR consent; valid methodology IDs; terminal output safety; and ZIP integrity. **Empirical claims remain unverified** until paired trials include a healthy repository, a deceptive thin adapter and a cross-context domain-language collision.