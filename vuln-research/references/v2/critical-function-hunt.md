# Critical-Function Hunt (C5)

> Operational guidance for the swarm + orchestrator when building the **ranked critical-function registry** that drives forward data-flow. Source of truth: `db/schema.sql` (`critical_functions` table) + this doc; extends [`references/v2/pipeline-architecture.md`](pipeline-architecture.md) § Slicing with a ranked front end and § Bypass with the `factor_bypass_prior` feed-forward hook.

A **critical function** is a function whose correct behavior a security property depends on — break it, skip it, or feed it the wrong input and a trust boundary moves. The hunt runs in **Phase 0 (Decompose)** as a first-class preliminary lane, *before* slice planning, so Phase 0.5 can plan forward data-flow lanes anchored on the ranked output. Every accepted candidate becomes one `critical_functions` row.

This pillar exists because the old pipeline jumped straight from sources/sinks to slicing. Auth checks, deserializers, and crypto verifiers that are neither a classic "source" nor a classic "sink" fell through the gap — yet they are exactly where logic bugs and bypasses live. The registry makes them first-class, ranked, and slice-anchored.

---

## 1. `cf_category` taxonomy

Each row carries exactly one `cf_category` (schema CHECK enum). Pick the **dominant** security role; a function that both validates and deserializes is categorized by what makes it security-critical here.

| `cf_category` | What it is | Why it is critical | Typical Joern generator (§4 of joern-forward-slicing.md) |
|---|---|---|---|
| `auth_check` | Decides *who* you are | Skipped/spoofed → impersonation | `name("(?i).*(authenticate|verify_?token).*")` |
| `access_control` | Decides *what* you may do | Skipped → IDOR / priv-esc | `name("(?i).*(authoriz|has_?role|check_?permission).*")` |
| `crypto_op` | Sign/verify/encrypt/decrypt | Weak/oracle → forgery, disclosure | `call.name("(?i).*(hmac|verify|decrypt|sign).*")` |
| `deserializer` | Bytes → live objects | Untrusted input → RCE | `call.name("(?i).*(readObject|loads|unmarshal).*")` |
| `validator_sanitizer` | Cleans/filters input | Bypassed → injection (this is the bypass-hunt anchor) | `name("(?i).*(validate|sanitiz|escape).*")` |
| `parser_decoder` | Reshapes untrusted bytes | Confusion/diff → smuggling, second-order | `call.name("(?i).*(parse|decode).*")` |
| `privileged_op` | Acts with elevated rights | Reached unprivileged → priv-esc | seed from crown-jewel map |
| `state_transition` | Advances a state machine | Out-of-order → logic bug, race | seed from crown-jewel map |
| `dangerous_sink` | Already a `sinks` row that *also* warrants ranking | Concentrates blast radius | join on `sinks.id` |
| `trust_boundary_transfer` | Hands data across a tenancy/zone edge | Confused-deputy, SSRF pivot | seed from L2 trust transitions |

`dangerous_sink` rows set `critical_functions.sink_id`; `validator_sanitizer` / auth rows that map to a known defense set `critical_functions.defense_id`. These joins are how the registry stays consistent with the existing `sinks` / `defenses` tables instead of duplicating them.

---

## 2. Evidence capture (mandatory)

A candidate is not written without evidence. Every row carries:

- `symbol_path` — fully-qualified, Joern-`fullName`-stable (e.g. `pkg.auth.CheckToken:bool(string)`), so it re-hashes identically next round and matches `critical_functions.symbol_path` ↔ `input_slices.critical_fn_id` joins.
- `evidence_path` + `evidence_line` — the definition site.
- `classification_evidence_json` — *why this category*: the matched signal (regex hit, decorator, crown-jewel link), the surrounding guard context, and the tool that proposed it. Shape:

```jsonc
{
  "proposed_by": "joern|semgrep|llm|crown_jewel_map",
  "signal": "method name matches authoriz.* ; called by 14 handlers",
  "category_rationale": "gates admin route group in routes/admin.go",
  "contested": false   // true when two categories plausibly apply; record both rationales
}
```

`classification_evidence_json` is the audit trail the Phase 2 confirm + Phase 5 critic read to challenge a misclassification. **Tool output is a hypothesis** (per tool-integration-matrix doctrine) — the LLM hunt agent confirms the category against the actual code before emitting the row.

---

## 3. Weighted ranking → `rank_score` → `rank_tier`

**Six** factors, each a normalized REAL in `[0,1]`. `rank_score` is their weighted sum (also `[0,1]`):

```
rank_score = w_reachability       * factor_reachability
           + w_blast_radius        * factor_blast_radius
           + w_privilege_delta     * factor_privilege_delta
           + w_attention_deficit   * factor_attention_deficit
           + w_bypass_prior        * factor_bypass_prior
           + w_recurrence_prior    * factor_recurrence_prior     # the 6th factor (#2)
```

> **Weights are externalized, not inline (R23).** The `w_*` coefficients live in the shared `scoring_config` table (seeded from `db/seed/scoring.yml`), and the canonical ranking is the **`v_critical_fn_ranked` VIEW** (`rank_score_computed`), which joins `scoring_config` at read time. Editing a weight there reorders results with **zero code change** — the determinism-by-construction rule. The stored `critical_functions.rank_score` column is retained for feed-forward compatibility, but the view is authoritative. The default seed: reachability 0.25, blast 0.22, privilege 0.18, attention 0.13, bypass 0.10, recurrence 0.12 (sum 1.00).

| Factor | Meaning | How to score at hunt time |
|---|---|---|
| `factor_reachability` | Can attacker input reach it? | **Estimate** in Phase 0 (is it on a request path? behind auth?); **refined** in Phase 0.5/1 from `critical_fn_reach` (1.0 if any `reaches`, 0.0 if all `blocked`, 0.5 if `unproven`). Set `source_reachable` boolean alongside. |
| `factor_blast_radius` | How much depends on it? | Fan-in: `min(1.0, callIn.size / 20)` (Joern `callIn`, §4). Crown-jewel callers count double. Reuses the same resolved `call_edges` substrate as recurrence propagation (§7). |
| `factor_privilege_delta` | Does it gate a privilege/trust transition? | 1.0 if it crosses a tenancy/role boundary, 0.5 if same-zone sensitive, 0.0 otherwise. `privileged_op` / `access_control` / `trust_boundary_transfer` default ≥ 0.5. |
| `factor_attention_deficit` | How under-audited? | Phase L2 Attention-Deficit Score for the defining module (`references/phases/attention-deficit.md`), normalized to `[0,1]`. |
| `factor_bypass_prior` | Was a bypass found at/near it before? | **Cross-round feed-forward** — see § 5. Starts at 0.0; raised when a `defense_bypasses` row cascades onto this CF (this round) or a prior round carried one (`carried_from_bypass_id`). |
| `factor_recurrence_prior` | Has this function (or a hot call-neighbor) recurred as confirmed across rounds? | **Recurrence feed-forward** — see § 7. Derived from `recurrence_counter` (normalized self counter + one-hop call-neighbor boost). A function near repeatedly-confirmed findings ranks up. |

| `rank_tier` | `rank_score` | Drives (Phase 0.5 planning) |
|---|---|---|
| `tier1` | ≥ 0.66 | **Both** data-flow directions: source→CF (`critical_fn_reach`) **and** CF→downstream (`critical_fn_forward` slice). Every applicable `slice_kind`. |
| `tier2` | 0.33 – 0.65 | One direction — CF→downstream forward slice (bounded depth). Source-reach computed only if cheap. |
| `tier3` | < 0.33 | Recorded, not sliced unless a cascade (§5) promotes it. Kept so next round sees it without re-discovering. |

Tiering is **relative within the target** when scores cluster: if everything lands < 0.33, still promote the top-2 by `rank_score` to tier2 so the run is never starved of data-flow anchors (mirrors the attention-deficit floor in vuln-swarm.md § 0.5).

---

## 4. Idempotency

`cf_hash` is `UNIQUE` and computed over `(target_id, symbol_path, cf_category)`. Re-running the hunt over the same `commit_sha` updates factors/score in place via `ON CONFLICT DO NOTHING` + a follow-up factor refresh, never duplicates. `symbol_path` uses Joern `fullName` precisely so the hash is stable across rounds — a renamed-but-equivalent symbol is a new row by design (it *is* a different function).

---

## 5. `factor_bypass_prior` — the cross-round feed-forward hook (Ask 5)

This is the mechanism that stops the bypass hunt from being a dead end. When **Phase 0.75 (Defense Pre-Break)** confirms a `defense_bypasses` row — or, later and finding-specifically, the thin Phase 3 recheck does:

1. The orchestrator finds the `critical_functions` row whose `defense_id` / `symbol_path` matches the broken defense.
2. It raises that CF's `factor_bypass_prior` toward 1.0 and **re-computes `rank_score`**, which can promote the CF a tier.
3. The promotion re-plans that CF's data-flow lanes **before the Hunt dispatches this round** (intra-run cascade) so a higher-tier CF gets the fuller both-directions data-flow treatment it now deserves. Because pre-break runs *after* Phase 0.5 but *before* Phase 1, the re-rank lands in time to shape the Hunt; a late finding-specific break in the thin Phase 3 recheck (after the Hunt) instead carries to the next round via step 4.
4. The `defense_bypasses.carried_from_bypass_id` + `round_ledger` linkage lets the **next round** seed `factor_bypass_prior` from the start — see `references/v2/round-feedforward.md`.

So a confirmed bypass does three things instead of one: it removes a defense from the Hunt's paths (and relaxes Confirm's G2), it re-ranks the critical function it broke, and it teaches the next round where to look first. Running it **pre-hunt** (Phase 0.75) is what lets the first two land *before* the Hunt rather than after it. That closes the loop the user flagged — "the bypass hunt was shallow and wasn't used after that."

---

## 6. Wiring summary

- **Phase 0 (Decompose):** run the hunt → emit `critical_functions` row events. Reachability is an estimate here.
- **Phase 0.5 (Plan):** read `critical_functions` ordered by `rank_score DESC`; plan `critical_fn_forward` slices + `critical_fn_reach` queries per the tier table (§3). Refine `factor_reachability` from results.
- **Phase 0.75 (Defense Pre-Break):** raise `factor_bypass_prior` on cascade (§5), re-ranking CFs *before* the Hunt; the thin Phase 3 recheck does the same for any finding-specific late break (which carries to the next round).
- **Cross-round:** `round-feedforward.md` re-seeds factors from the prior round's registry.
- **Promising-lane side-output (all phases):** if the hunt or a Phase 0.75 defense-reading lane spots a **promising lane** — a concrete new investigation direction worth a dedicated lane next round (e.g. a custom template engine → SSTI-fuzz, a hand-rolled deserializer → object-injection) — emit a `promising_lanes` row event. Feed-forward only (the next round picks it up via `v_promising_lanes_ranked`), non-mandatory, never chased this run. See `references/v2/pipeline-architecture.md` (Promising-Lane Feed-Forward).

Row event shape:

```jsonc
{"kind": "critical_functions", "row": {
  "target_id": 1, "symbol_path": "pkg.auth.CheckToken:bool(string)",
  "cf_category": "auth_check", "evidence_path": "auth/token.go", "evidence_line": 88,
  "defense_id": 12, "source_reachable": true,
  "factor_reachability": 1.0, "factor_blast_radius": 0.7, "factor_privilege_delta": 1.0,
  "factor_attention_deficit": 0.4, "factor_bypass_prior": 0.0, "factor_recurrence_prior": 0.0,
  "rank_score": 0.84, "rank_tier": "tier1",
  "classification_evidence_json": {"proposed_by": "joern", "signal": "callIn=14; gates /admin", "contested": false},
  "cf_hash": "<sha256 of target_id|symbol_path|cf_category>"
}}
```

---

## 7. `factor_recurrence_prior` — the recurrence feed-forward hook (#2)

The sibling of § 5: where `factor_bypass_prior` carries *broken-defense* signal forward, `factor_recurrence_prior` carries *confirmed-finding recurrence* forward, so a function that keeps producing real bugs — or that sits one call-hop from one that does — starts each round already ranked up.

The materialized accumulator is `recurrence_counter` (the one genuinely stateful table; everything else is computed read-time):

1. **Confirmation-weighted lifetime tally.** On each finding status transition the orchestrator moves the counter for the finding's enclosing-function node: confirmed `+1`, candidate `+0.3`, refuted `−1`. **`needs_attention` produces no delta** (a moved-but-unre-confirmed sighting must not inflate recurrence — see `db-logging-and-context.md` § 8). **No time-decay** — the tally is honest because #1's body-hash freeze stops a static finding from re-incrementing every round.
2. **One-hop call-graph propagation.** A hot node propagates a `neighbor_boost` to its 1-hop call-neighbors, weighted by `scoring_config` `w_nbr` (default 0.50). The neighbors come from **`call_edges`** — the *same* resolved Joern CPG edges `factor_blast_radius` walks for fan-in (§3). Shared substrate, no second graph.
3. **Sound under-approximation.** Only **resolved** edges exist in `call_edges`; an unresolvable call site (cross-repo other half, dynamic/reflective dispatch) emits a `blind_spot` observation instead of an edge, and **propagation never crosses a missing edge** — a prior can never be inflated by a fabricated neighbor.
4. **Derivation.** `factor_recurrence_prior` = normalized self `counter` + `neighbor_boost`, refreshed by the orchestrator at flush. Both `counter` and `neighbor_boost` move via an `ON CONFLICT (counter_key) DO UPDATE` accumulation — never the generic insert-only Put path.

The accumulation is the orchestrator's job (single writer). Lanes never touch `recurrence_counter`; they emit findings, and the status transitions those findings drive are what move the counter at flush.
