# Default two-file layout

Use only when the project has no spec system, contract of record or plan convention
(Spec Kit, OpenSpec, Kiro, ADRs, an API contract). Otherwise amend where the obligation
lives. Omit any section that does not apply; do not add empty headings.

```
specs/<change>/
├── spec.md             # WHAT: owner-approved behavior contract
└── implementation.md   # HOW: plan, guidelines, checklist, closeout evidence
```

The split follows authority. Changing `spec.md` is a contract amendment that needs the
owner. `implementation.md` is the agent's working plan; it needs approval only where it
would embody an open decision (§3).

## spec.md

```markdown
# <change>
Stage: <new behavior | regression | characterization | bug discovery | repair | refactoring>

## Contract
- Change: <observable outcome, for whom>
- Preserve / out of scope: <what stays unchanged>
- Acceptance basis: <what authorizes the expected result; where observed>
- Open decisions: <decision → work it blocks, owner>

## Capabilities
- A1: <behavior>. A1-check: <how it is observed>
- A2: <behavior> (needs: DB install (absent), B1 (partial)). A2-check: <...>

## Triggered concerns
<only the §2 rows that apply: security, data, interfaces, dependencies, failure ...>
```

## implementation.md

```markdown
# <change>: implementation

## Guidelines
<private names, structure, dependencies, configuration, hardening, conventions to follow>

## Decisions
<choice, decisive reason, material downside, evidence limits>

## Checklist
- [ ] C1 (A1): <instruction, written as an imperative the delivered state can be checked against>
- [ ] C2 (A1): <...>
- [ ] C3 (A2): <...>

## Closeout (filled after implementation)
| Item | Verbatim text | Evidence on delivered state | Status |
|---|---|---|---|
| C1 | <copied unchanged from Checklist> | <command run, file read, output observed> | done / not done / not run / blocked |
```

## Rules

- Every capability ID has at least one checklist item; every checklist item cites an ID or
  a Guidelines entry. Guidelines that must hold become checklist items.
- One checkable instruction per item, so a closeout row can pass or fail it.
- Never renumber an item others cite; append or amend. A changed item carries the §4
  change/rationale note.
- The Closeout table is produced by the §5 checklist closeout: one row per item, copied
  from the checklist, none reworded, merged or dropped.
