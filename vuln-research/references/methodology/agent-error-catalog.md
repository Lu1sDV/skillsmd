# Agent Error Catalog — Mandatory Pre-Hunt Read

> **Load when**: Read this **before** any hunt / swarm starts, every campaign. These are the modal failure modes a vuln-research run re-discovers if it starts blind. The point is to begin a campaign *knowing* the recurring mistakes and the guardrail that now prevents each, rather than re-learning them at report time.

Every error below maps to a guardrail already in the skill (or in the implementation plan). They cluster under **three root-flaws** — the *shape* of the machine, not missing sentences. A campaign that respects the three root-flaw fixes (subtractive feedback, justification-axis gates, a reducer sized to the run) avoids the whole catalog; the per-row guardrails are the local instances.

---

## Root-Flaw 1 — Open-loop on precision (the 300→3-4 disease)

*Every feedback edge is additive (find more); none is subtractive (stop flagging this shape). Refutation suppression is instance-keyed and revocable, so the same generator re-emits the same false shape forever. Fix: a signature-keyed negative edge into generation + closures as a hard barrier.*

| Error | Root cause | Guardrail that now prevents it |
|---|---|---|
| **Mass-emit without inline kill** (`refutations_attempted=0`; MED/LOW emitted with no refutation) | Rigorous refutation was DEEP-only; emit had no refute step | Mandatory inline refutation at **all** tiers; discovery emits the one refuting fact; `refutations_attempted>0` gate (INV-07, standing contract) |
| **Self-refutation laundered as confirmation** (a MEDIUM "refutation" = same agent re-walking its own trace) | Confirmed rows are tier-flattened; refuter == discoverer allowed | Independent refutation (refuter lane ≠ discoverer lane) at all tiers + `confirmation_rigor_tier` stamp so priors discount it (INV-07) |
| **Lane into a closed surface** (re-hunt `dead_end`/refuted surfaces; duplicated lanes) | Closures recorded as soft advice / down-rank, not a barrier; new lanes decided from a compaction summary, not DB history | Blocking pre-spawn ledger dedup + `closures` table; a lane on an open closure is scheduled `skipped`; trust `git merge-base --is-ancestor` not `presentAtPinned` (INV-09) |
| **Sunk-cost grinding on a negative channel** (each clean result spawns a bigger next attempt) | Negative-result escalation had no stopping rule | Negative-result stopping rule: after N clean attempts on a channel, write a `closures` row and **stop** — a negative result must not spawn a more elaborate attempt |
| **Over-generalizing a one-off** (a single deref-in-throw seed turned into dead invariant guards; 11/12 FP) | One-off pattern generalized into a standing rule | Only a vuln when the null/error branch is **live** from attacker input; promote an invariant only after generalize-then-promote (INV registry discipline) |
| **Re-litigation without a new signal** (refuted leads re-opened on no new evidence) | Divergence doctrine permits free re-litigation with only a region-novelty damper | Re-open requires a *fired* reopen-condition (code moved / new caller / new analogy), not LLM discretion; signature-keyed down-rank of the *shape*, not just the region |

## Root-Flaw 2 — Gates measure the wrong axis (the severity-inflation & RCE-FP disease)

*Every gate is a presence/coverage predicate; none measures whether a claim is justified or harmful. Severity is a free upstream enum typed at emit, phases before reachability and consumer-harm exist (they never get computed). Fix: a justification-axis gate, severity computed at read-time, reachability/consumer as owned phases.*

| Error | Root cause | Guardrail that now prevents it |
|---|---|---|
| **Over-claim without a consumer** (mechanism reaches sink, no consumer trusts the bytes → false HIGH/CRIT) | DAG terminates at `verified_sink`, never at a harmed consumer; completion gate checks severity *set*, not *justified* | Gate 5: name the default-config consumer that reads/dispatches/trusts the value, else auto-demote to Observation (INV-01); `consumer_graph` built in Phase 1.3 |
| **Severity typed at emit, never re-rated** (discovery agent writes the most optimistic class-only number) | `severity` is a writable enum stamped 2-3 phases early; no mandated re-rating point | Emit-time LOW floor + `config_state=unknown`; Confirm/Proof is the single re-rating authority via the read-time rubric (INV-02) |
| **Class-only severity** (`SSRF=High`, `RCE=Crit`, `OOB=High` from the class name alone) | Severity encoded by bug-class in three independent tables, no second factor | `final = base × reachability_cap × mechanism_cap × poc_evidence_gate`; class is a ceiling input, not a verdict (INV-02) |
| **RCE→DoS over-rating** (forward-linear / write-existence claimed as RCE; `setarch -R` ASLR-off treated as vanilla) | Severity from the *existence* of a write, not from address control | `mechanism_cap`: only a proven write-what-where, or read + demonstrated ASLR-defeat, lifts toward RCE; forward-linear caps at DoS (INV-02/03) |
| **Info-leak/OOB→over-rating under hardening** (wild read/write assumed to execute) | Severity from sanitizer class-string; `_LIBCPP_HARDENING_MODE`-style caps ignored | Hardened-allocator/bounds-checked `operator[]`/`.at()` OOB caps at DoS; only raw-ptr/`memcpy`/`.data()+idx` retains leak/WWW (INV-03) |
| **Read-primitive assumed to chain to RCE** | RCE needs a same-process, same-shot, dispatched write | Read + ASLR-defeat = HIGH info-leak, not RCE; pair the write, never assume it (INV-02) |
| **Reachability / unreachability miss** (DAG closed at wire-level, not at the trust boundary; "no local `checkAccess` ⇒ bypass") | No phase owns reachability; absence of a *local* guard read as absence of *any* guard | Phase 1.3 `reachable_surface` with proven/conditional/unreachable tiers; confirm central/planner enforcement before claiming bypass; reachability-cap on severity (INV-02) |
| **Dead-path / removed-caller treated as live** (guard-absence == live bug; exception/`LOGICAL_ERROR` guard counted as DoS) | Present-and-absent guard conflated with a live reachable path; caught `DB::Exception` ≠ uncaught signal | Verify a **live** attacker-reachable path drives the input; distinguish thrown/caught exception from uncaught signal; invariant guards are not live bugs (INV-06) |
| **DoS-scope contradiction** (default-exclude text vs in-scope policy) | Scope policy copied across ≥4 docs; reversal applied in none | Single-source `scope-policy.md`; DoS is a first-class severity-rated impact (INV-08) |

## Root-Flaw 3 — The reducer is smaller than the run (the verify-starvation & silent-pass disease)

*Confirmation is an unbudgeted consequence of recall-maxed discovery, and the only component with global truth must lossily compact mid-run. Discovery gets 14 guaranteed lanes, Confirm zero. Fix: budgeted interleaved Confirm, durable DB, delegation receipts, model routing, exhaustive defense enum.*

| Error | Root cause | Guardrail that now prevents it |
|---|---|---|
| **Vanilla-build skip** (mem-corruption confirmed on local/ASan tree, never re-validated on the official release binary) | Guards differ across builds; local/ASan ≠ official | Sanitizer→vanilla reproduction mandatory; prefer the exact official release artifact; sanitizer report is diagnostic-only (INV-05) |
| **Native-client / `local`-tool confound** (client parses input locally → crash & "leak" are client-side; single-process local always dies) | A bundled CLI client / single-process tool has its own parser and dies as one process | Drive over the deployed network protocol; PID-gone + port-refused + fresh-query-rejected decisive; plant server-only secrets (INV-04) |
| **Crash-already-fixed not checked** (PoC effort spent on an n-day) | No publication/merge-base gate before investing | Run `merge-base` + public-issue search **before** PoC; fixed/published = ineligible |
| **SP-oracle skip / lane drift** (answer an easier nearby question; SP never adjudicated) | Coverage gate checks the lane *ran*, not that the *oracle* ran | Execute the SP's own oracle; every kept SP reaches `{graduated, refuted_benign, oracle_unrun}`; `v_sp_oracle_coverage` HARD-RED (INV-06) |
| **Promotion gap** (≥MED `dag=true` observation never graduated to a finding or a recorded refutation) | Completion gate checks coverage+persistence, not promotion | Every `dag=true` ∧ ≥MED observation → candidate finding or recorded refutation; `v_promotion_coverage` (INV-06) |
| **Rogue executor inflates `confirmed`** (broad executor marks rows confirmed with 0 PoCs; 10→33) | Executor allowed to write `confirmed`; mis-routing | Executor never marks confirmed; `vrdb promote` is the only path to confirmed + born-confirmed lockout; executor = always standard tier (INV-12) |
| **Model mis-routing** (analysis on the cheap tier; executor on the strong tier) | Cost-saving instinct on the reasoning tier; agent/model ambiguity | All analysis/triage/confirm/critic → strongest model; executor/recon/search → standard tier; rule prepended to every lane prompt (INV-12) |
| **Observation / roster lapses** ("emphasis on a lane" misread as "skip the rest"; 8/13 lanes skipped; flush optional) | Insert-only observations table, no forced flush; partial roster tolerated | `vrdb close-step --observations` transactional flush; reject close of a required DEEP lane with 0 dead_end/invariant/blind_spot rows; materialize the full roster |
| **Under-enumeration of defenses** (finding-anchored, not finding-agnostic) | Defenses enumerated around expected findings; gate measures bypass coverage, not completeness | Finding-agnostic exhaustive defense sweep across all layers **before** the hunt; a small `defenses` count relative to surface size is an explicit red flag |
| **Swarm DB row-shape pitfalls** (FK confusion, `target_id` drift, insert-only status flips) | CF ids 100+ vs small sink/defense tables; loop-index reuse; `vrdb put` insert-only | Validate JSONL pre-flush; assert `sink_id ≤ max`; pin `target_id`; UPSERT/`vrdb promote` for status flips; per-table sequences |
| **Silent-no-op with success report** (a delegated write that never landed, reported as done) | No post-action verification that intended side-effects landed; invisible under full delegation | Delegation receipts: orchestrator verifies the specific intended rows landed (by id/hash) after each delegated write, never trusts the agent's success report |
| **Resume = replay-without-reconciliation** (re-ran the OOM-killing config 3×) | Resume restores intent but never checks "is what I'm about to re-run the thing that just failed?" | Resume reconciliation: before re-launch, diff the intended config against the last-failure config; refuse a blind replay; require the cap/cause to have changed |
| **Effort-order inversion** (highest-yield vein audited last; "RCE=Crit by class" front-loaded a zero-yield geometry vein) | Lane scheduling had no yield-history feedback | Yield-weighted scheduling: feed per-vein confirmed-yield history into the next round's priority; effort order tracks yield, not bug-class prestige |
| **Host OOM / box-kill** (heavy loops not out-of-band; no RAM precheck) | No standing launch cap; corpus ingested in-context | Heavy loops out-of-band (compact row result); `systemd-run MemoryMax` + concurrency=1 + flock in the launch path (INV-11) |
| **DB corruption / can't reopen** (single-writer flush didn't prevent metadata corruption) | No forced durable point, no reopen self-test, no snapshot | `vrdb checkpoint` at every phase boundary + `vrdb snapshot` before HEAVY lanes + integrity probe & auto-restore on `Open` |
| **Workflow starvation misread** ("no StructuredOutput" read as a prompt bug — really 429 / 64k-out / 200K-in caps) | Self-refutation contract starves the verifier; opus bursts hit session limits; size caps invisible | Lanes emit every candidate (doubts → `refutation_note`); read the jsonl tail for 429; resume via `resumeFromRunId`; map-reduce synthesis under the output cap |

---

A campaign that has read this catalog before the hunt should never present a HIGH without a named consumer, a "crash" verified only on a local CLI client, an RCE claim from write-existence, or a lane on a surface already closed in the ledger. Each row is a guardrail to *check you are obeying*, not a mistake to re-discover.
