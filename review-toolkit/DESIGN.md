# Design decisions and follow-on improvements

## Decisions accepted for v2

**Monotonic reviewer allocation.** The earlier first-match schedule could lower reviewer counts at 500 changed lines. The v2 domain quota uses the monotonic envelope of the original thresholds, with a 2,000-line floor of two independent passes. It is monotonic in both files and changed lines. This is a deliberate revised policy, not a hidden interpretation of the v1 formula.

**Targeted risk reviewer.** This is additive at every depth when the selected change demonstrably alters a high-risk path, and remains zero without grounded evidence. File names are hints, not proofs. Multiple categories feed one dedicated independent reviewer, limiting cost without trivializing risk. A reviewer working twice on one giant file is still genuinely independent only if the assignments are run separately with independent context/tool work.

**DEEP and ULTRA unchanged in philosophy.** DEEP adds one holistic reviewer and a bounded adversarial property matrix. ULTRA also adds an exhaustive, sequential instruction ledger per owner with parallel owners and sequential global reconciliation. The finding gate, reported priorities, table, and targeted risk reviewer are invariant.

**Canonical policy.** `src/shared` is the *only editable shared policy*. The two output skills are generated to be self-contained for all four harnesses. Their identical common fragments are mechanical build artifacts, not separately edited sources. The build command is deterministic; `--check` detects drift.

**Pinned smoke checks.** `harnesses/versions.json` owns the four exact release pins. A local command verifies installed binary version; CI checks an exact package install and path shape. This is not a substitute for credentialed end-to-end model, agent and CLI testing. Updating versions requires rerunning the tests, not just accepting a new `latest` tag.

## Production review report

Six columns: ID, P0–P3 priority, area, precise location, single-paragraph trigger/evidence/impact, smallest useful remedy. A small summary table records scope/depth, requested/completed independent reviewers, evidence and limitations, and disposition. Blank findings are allowed and preferable to low-conviction noise. Cosmetic changes, unproven failure hypotheses, pre-existing problems, and intentional changes are not automatically flagged.

## Migration caveat

This v2 tree was reconstructed because the previous scratch filesystem was unavailable. The earlier generated standalone installer cannot be inspected from the current environment. The new installer therefore treats untracked installed content as user-owned until it matches generated v2 bytes or the user passes `--force`, which backs it up first. Do not claim a manifest-preserving v1-to-v2 migration was tested.

## Potential next steps (not enabled)

- A credentialed smoke workflow that invokes the actual slash commands in disposable repositories and checks native domain/risk/holistic spawn events, not only prompts.
- A held-out regression benchmark to measure finding recall, false positives and useful structural suggestions.
- Optional machine-readable JSON findings emitted alongside the fixed Markdown table.
- A stricter `risk-evidence.json` exchange between the coordinator and planner, validated against a frozen diff hash. Today risk evidence is a human/agent assertion, not a cryptographic proof.
