# Agentic Spec Driven Development

A standalone skill for establishing an authorized behavior contract and keeping agentic
implementation, tests and completion claims aligned with it. Risk-proportionate by default:
no compulsory document pipeline, council, separate verifier or new runtime.

## Install

From the published repository:

```bash
npx skills add Lu1sDV/skillsmd --skill agentic-spec-driven-development
```

Or copy the complete bundle from a local checkout:

```bash
cp -r agentic-spec-driven-development ~/.claude/skills/
```

Keep `references/` with `SKILL.md`. All linked guidance lives inside this folder; sibling
skills, OpenSpec, Spec Kit and Kiro are optional, not dependencies. Installation does not
configure tool permissions or a sandbox.

## Use

Explicit invocation examples:

- “Use agentic-spec-driven-development to clarify team sharing before implementation.”
- “Use agentic-spec-driven-development to reconcile this API spec with the existing behavior.”
- “Use agentic-spec-driven-development for this approved retention amendment and handoff.”

The description is written for natural discovery; automatic activation is unverified.
Explicit-use exercises do not establish triggering in a particular client. Verify it
separately, and avoid loading two SDD skills with conflicting governance.

## What it does

| Concern | Default |
|---|---|
| Contract | What changes, what remains, acceptance basis, open decisions |
| Readiness | Judged per consequential action: information, authority and required evidence kept separate; no score or status file |
| Process depth | Consequences and uncertainty, not file counts or time estimates |
| Approval | Actual scope and explicit holds; existing project gates still govern |
| Existing specs | Amend the contract of record, not a duplicate SPEC.md |
| Delegation | Shared decisions, ownership, durable handoff and integrated evidence |
| Verification | Stage-relative, delivered-state evidence with actual check status |
| Persistence | Existing project model; otherwise a dated change record |

A fully specified cosmetic edit does not acquire a new spec. A prototype touching real
customer data does not become low-risk because it is called a prototype. A complete bug
investigation need not repair the defect, but must not report defective software as fixed.

## Bundle

- [SKILL.md](SKILL.md): complete core workflow and critical boundaries.
- [Contracts and examples](references/contracts-and-examples.md): optional compact form,
  login trust decision, concurrent refunds, retention amendment, a new project, a vague
  performance request, cutover versus mixed versions and a design choice.
- [Lifecycle and handoffs](references/lifecycle-and-handoffs.md): approvals, conflicts,
  existing spec tools, amendments, resumption and maintained versus historical records.
- [Verification](references/verification.md): oracle provenance, stage distinctions,
  legitimate test changes, real statuses and completion reporting.
- [Sources and decisions](references/sources-and-decisions.md): public evidence, alternatives,
  admission rationale, limitations and evaluation design; maintainer-only reading.
- [Scenario cases](evals/scenarios.json): prompts and expected outcomes for disposable exercises.

## Validation and limits

From the `skillsmd` checkout, the existing static checker can inspect the entrypoint:

```bash
python skill-smell-checker/scripts/check_static_smells.py \
  agentic-spec-driven-development/SKILL.md --pretty
```

Static conformance and model review are not proof of workflow effectiveness. Run scenario
prompts in fresh contexts; keep expected outcomes with the grader. Compare with an otherwise
identical no-skill run when assessing incremental value. Do not give the baseline less task
information or mistake forced skill loading for natural discovery.

### Exercised verification — 2026-11-04

- Parsed YAML, matching folder/name, description limits, six scenario records and all
  13 local Markdown links. A complete copied bundle retained its local references.
- Existing static smell checker: zero findings or warnings across five checks.
  Independent semantic review: 20 absent, one uncertain (third-person wording versus
  the repository's required “Use when” opening). Confirmed review defects were fixed.
- Final native tool-use pilot: four scenarios, one fresh-context run per arm. The
  agent-facing copy excluded `evals/`; the complete copy was checked separately.

| Arm | Scenarios meeting the declared outcomes |
|---|---:|
| Explicitly loaded skill | 4/4 |
| No additional task-specific skill | 4/4 |

The exercised paths preserved an implementation hold, amended local retention while
keeping rollout/staging unresolved, reproduced a defect without repairing or suppressing
it, and corrected actual CLI help without new specification ceremony. The coordinator
also executed the resulting programs/reproductions and checked protected files.

This author-run diagnostic establishes those exercised behaviors, **not incremental
benefit**: the baseline also passed. Both arms retained the host's normal governing
instructions. Automatic triggering, repeated-run reliability, the two remaining scenario
cases, live integrations and cross-client behavior were not tested.

A later revision added the readiness check, design-comparison prompt and examples 4–7.
They come from a review of the skill; their effect was not measured. Single explicit-use
observations and agent review do not establish activation, reliable omission detection,
concurrency or mixed-version safety, capacity, interruption recovery or host enforcement.

The skill is behavioral guidance. Host/CI/OS permissions provide enforcement, and their
capabilities vary. No universal SDD benefit, statistical reliability, cross-client discovery,
production safety, or superiority over existing skills is claimed.

## Sources and attribution

Original synthesis informed by Addy Osmani's agent skills, Spec Kit, Kiro, OpenSpec,
Tech Leads Club, specification-by-example practice, and research on test oracles and
agent evaluation. Public links and source-specific limitations are in
[sources and decisions](references/sources-and-decisions.md). No third-party templates,
scripts or private council transcripts are redistributed in this bundle.
