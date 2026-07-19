---
name: bug-bounty-reporting
description: >
  Use when an agent drafts, revises, freezes, or independently verifies a bug
  bounty vulnerability report, executable PoC, evidence bundle, CVSS rationale,
  or cleanup proof for HackerOne, Bugcrowd, Intigriti, or a vendor-managed
  program. The skill maps material claims to exact final-run artifacts.
---

# Bug Bounty Reporting

## Paramount Points

Verbatim; keep internal:

> 1. **Concise** - Triagers need simple language, no mince words. Straight to the point reports. Every word create cognitive burden
> 2. **Triagers are dumb and lazy** - They need ELI5 steps and easy to understand reports; reproduction must be done for the fastest and easiest to understand triaging possible.
> 3. **Do not talk like a Robot** - LLM written report patterns discourages triagers. Write reprots like a human would do.

## Status Rules

| Status | Required evidence |
|---|---|
| `draft` | Exact final PoC lacks full-live evidence |
| `full-live` | Exact final PoC produced uncut end-to-end evidence |
| `submission-ready` | Frozen full-live snapshot passed independent review |

## Workflow

0. Verify current terms: scope, eligibility, safe harbor, prohibited methods,
   limits, disclosure. Record source/date; unconfirmed = `blocked`, failed =
   `ineligible`.
1. Read [references/report-standard.md](references/report-standard.md).
2. Inventory version/config, roles, PoC, evidence, control, cleanup. Track
   report, PoC, manifest, review as `pending`, `complete`, or `blocked`; never
   invent.
3. Map claims to evidence; remove, narrow, or qualify unsupported claims.
4. Draft one linear repro with decisive outputs, pinned root cause, combined
   impact-and-severity, and concrete fix.
5. Require central config, preflight, collision refusal, assertions, evidence
   capture, secret-safe logs, and exact cleanup; reuse existing PoC tooling.
6. Freeze report, PoC, manifest with hashes/config; edits invalidate
   review/evidence.
7. One independent reviewer checks caveats/precedent, combined impact/severity
   evidence, and clean execution; the writer cannot self-certify.
8. Grant `submission-ready` only to frozen, full-live, independently approved
   snapshots; otherwise report blockers.

## Guardrails

- Use authorized targets, controlled accounts, synthetic data.
- Protect user data/credentials; use fingerprints.
- Never overstate impact, severity, lineage, precedent, or metadata as a usable
  secret.
- Delete only exact run-owned objects recorded in the cleanup ledger.
- Request one focused decision only when authorization, destructive live
  action, or materially ambiguous impact cannot be established. Otherwise
  continue and label gaps honestly.

## Completion Check

Do not finish silently with skipped gates. Confirm:

- The primary PoC proves the title and every material claim maps to frozen-run
  evidence.
- The report excerpt matches final-script output and the negative control proves
  the boundary.
- Cleanup handles success, failure, and catchable interruption.
- Hashes, version/config, report, PoC, and manifest agree.
- The independent frozen-snapshot review is complete, or the report remains
  explicitly `draft` or `blocked`.
