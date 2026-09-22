# Impact-Scope Policy (single source of truth)

> **Load when**: deciding whether a finding's *impact class* is rankable at all — before triage, severity, or report. This file is the **single source of truth** for impact-class scope. Every other reference (`bug-bounty-triage.md`, `audit-poc-report.md`, the Phase 5 critic) **references** this policy instead of restating it; if a scope rule lives in two places, this one wins.

---

## The rule in one line

**An impact class is in scope when it is reproducibly demonstrated on the real deployed surface; the realism bar stays, the blanket exclusion goes.** Severity is then computed by the read-time rubric (`exploitability-gate.md`), never gated away at the door by impact class alone.

---

## DoS / availability is first-class

DoS / availability is a **first-class, severity-rated impact, not an auto-reject.** A reproducible, sustained server- or process-level outage — proven on the real deployed surface, from minimal attacker effort — is rankable alongside RCE / SSRF / injection and ranked normally by impact and reachability. There is no default-exclude row for it.

What survived from the old guidance is the **PoC realism bar**, not the exclusion:

| Still required (realism bar) | No longer a gate (the exclusion is gone) |
|---|---|
| **Sustained outage, not a slowdown.** A reproducible crash / hang / process-death / sustained unavailability — not a single degraded response or a few-millisecond delay. | ~~"Availability is excluded by default; move to Observations unless the program scope lists it."~~ — **removed.** Availability impact is ranked, not parked. |
| **Minimal attacker effort.** One request, or minimal concurrency — not a saturation flood that any traffic spike reproduces. | ~~"Pure rate-limit / resource-exhaustion / algorithmic-complexity / memory-leak / ReDoS findings are excluded."~~ — **removed as a blanket class exclusion.** Each is rated on whether it meets the realism bar (sustained outage from minimal effort), not auto-rejected. |
| **Proven on the real deployed surface.** A server-reachable crash is verified against the deployment the program actually runs, over the protocol it exposes, with process / liveness evidence — never a bundled CLI client's exit code in isolation (a client-side parser confound is not a server outage). | |

A finding that **meets** the realism bar is ranked by impact and reachability like any other class. A finding that **fails** it (mere slowdown, flood-only, or only a client-side crash) is an Observation — because it is not a sustained outage on the real surface, **not** because availability is out of scope.

> *Example (cited, agnostic):* a malformed-input parse path that reliably kills the whole server process — verified over the network protocol the deployment exposes, with the process confirmed dead by liveness check — is a rankable availability finding. A query that merely runs slowly, or a crash reproducible only in a bundled local CLI client, is not. (Observed on a columnar-database target; the rule is target-agnostic.)

---

## Program-specific exclusions are read from the engagement scope

This policy sets the **default skill posture** (availability is rankable). It does **not** override a specific engagement's published scope. Program- or engagement-specific exclusions — including any that *do* exclude availability, rate-limiting, or resource-exhaustion findings — are **read from the per-engagement scope at submission time, never hard-coded here.**

- Before writing a report, read the program's published scope and out-of-scope / known-issues lists (`bug-bounty-triage.md` § *Reading the Program's Scope*).
- If the engagement's scope **excludes** availability findings, that exclusion applies **for that engagement** — surfaced as a program rule, not as a skill default.
- If the engagement's scope is silent or **includes** availability, the default posture here governs: rank it on the realism bar.

The skill never bakes one program's exclusion list into its doctrine; it reads each engagement's scope and applies it on top of this default.

---

## Cross-references

| Need to | Read |
|---|---|
| Compute severity once an impact class is in scope | `references/phases/exploitability-gate.md` (read-time rubric) |
| Run the pre-submission triage funnel (incl. program scope) | `references/phases/bug-bounty-triage.md` |
| Check Submission-N/A / Always-Rejected eligibility classes | `references/phases/audit-poc-report.md` § Submission N/A, § Always-Rejected |
| See the durable cross-target invariant behind this policy | `references/methodology/triage-invariants.md` (DoS-scope invariant) |
