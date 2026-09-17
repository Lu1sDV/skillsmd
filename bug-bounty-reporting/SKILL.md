---
name: bug-bounty-reporting
description: >
  A skill for creating a report in a bug bounty vulnerability assessment.Use when an agent drafts, revises, freezes, or independently verifies a bug
  bounty vulnerability report for source code, application or live assesment, executable PoC, CVSS or cleanup proof for HackerOne, Bugcrowd, Intigriti, or a vendor-managed program.
---

# Bug Bounty Reporting

## Paramount Points

Verbatim; keep internal:

> 1. **Concise** - Triagers need simple language, no mince words. Straight to the point reports. Every word create cognitive burden
> 2. **Triagers are lazy** - They need ELI5 steps and easy to understand reports; reproduction must be done for the fastest and easiest to understand triaging possible.
> 3. **Do not talk like a Robot** - LLM written report patterns discourages triagers. Write reprots like a human would do.

## Status Rules

| Status | Required evidence |
|---|---|
| `draft` | Exact final PoC lacks full-live evidence |
| `full-live` | Exact final PoC produced uncut end-to-end evidence |
| `submission-ready` | Frozen full-live snapshot passed independent review |

## Workflow

Give the triager the easiest, most seamless triage experience possible. They already have the report open and a VM to run things in, so don't make them transfer files and reconstruct state by hand.

Give the team an easy triage and remediation-retest experience. They have to hand the bug to devs (who often work without a proxy) and later confirm their fix works. A re-runnable POC lets them do both. Yes, this can eat into retest payouts, but Justin's take is that overall throughput is worth more than grabbing at a $50 retest right now.

Give yourself an easy way to visualize and validate what your hackbot reports. If you're running a bot, your life is triage: you open the queue, read the finding, drop the POC script into your terminal, watch the output, and click report. A weak POC is also the single best motivator to improve: nothing sharpens your skill like being annoyed at your own unreadable output. 

Codify the Report, Then Unit-Test It

The mental model behind the whole skill is a combination of two ideas.

First, codify the report. The POC should be a holistic, self-narrating experience. It sets the scene (this app does XYZ, here's who we are) and walks through the logic: the attacker (low-privilege user) can't reach the data via this route, then can reach it via that route. Use attacker and victim as your labels, not user1/user2. It removes all ambiguity about session ownership, and you show it with the actual HTTP requests. Done right, you barely need the written report; the POC itself explains why the finding is a vulnerability. 

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

