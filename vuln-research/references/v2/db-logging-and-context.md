# DB Logging & Context Capture (C6)

> Operational guidance for swarm agents + orchestrator on **what reasoning to persist** so context survives across phases and rounds. Source of truth: `db/schema.sql` (`agent_observations` table) + this doc. Companion: `references/v2/round-feedforward.md` (how the next round *reads* what this one logged).

The old pipeline persisted **outcomes** (`gr_findings`, `refutations`, `defense_bypasses`) but threw away **reasoning**. Every round re-derived the same dead-ends, re-made the same assumptions, and re-walked the same already-cleared paths, because the *why* evaporated when an agent's context window closed. `agent_observations` fixes that: agents log structured reasoning artifacts as first-class rows, and the next round fetches them instead of rediscovering them.

This is the persistence half of the user's ask "saving context into DB and more efficient fetching in next rounds." The fetch half is `round-feedforward.md`.

---

## 1. The `agent_observations` contract

Every observation is one row, emitted as a queue event (single-writer rule: agents never open DuckDB). The orchestrator flushes per phase under the phase transaction, same as findings.

**Flush incrementally per lane, not batched to phase-end.** "Per phase" is the transaction boundary — it does **not** mean the orchestrator holds every lane's events in the in-memory queue until the phase closes. As each lane completes, the orchestrator drains that lane's events and writes its `agent_steps` status transition (`scheduled → running → completed`/`skipped`) **and** its row-events (observations, findings, refutations) right then, still as the sole writer. This narrows the queue-loss window to a single in-flight lane: on an OOM/crash mid-phase, at most that one lane is lost rather than the whole phase's queue. **Resume** reads `agent_steps.status` + `round_ledger` to re-enter at the last completed lane and re-spawn only `scheduled`/`running` lanes. The motivating failure: OOM-resumed runs that batched to phase-end produced no output and left lanes `MISSING` in the gate because the queue died with the process. The human-facing doctrine is in `SKILL.md` § Single-writer rule.

```jsonc
{"kind": "agent_observations", "row": {
  "target_id": 1,
  "agent_step_id": 88,             // FK → the agent_steps row that produced it
  "obs_kind": "dead_end",
  "symbol_path": "pkg/parse.decodeFrame",
  "evidence_path": "parse/frame.go", "evidence_line": 210,
  "body": "len prefix is bounds-checked against cap before alloc; no integer overflow here",
  "confidence": 0.9,
  "reusable": true,
  "obs_hash": "<sha256 of agent_step_id|obs_kind|symbol_path|body — canonicalized per §4>"
}}
```

`body_sidecar_path` replaces inline `body` when the observation exceeds 16 KB (e.g. a full intermediate trace) — same spill rule as `gr_findings.payload_sidecar_path`, sidecar under `db/sidecars/`. The sidecar filename MUST be the content SHA-256 (`db/sidecars/<hash>`) and nothing else — never `symbol_path`, `evidence_path`, or any other caller-supplied string, which are attacker-influenced and could traverse out of `db/sidecars/`. The orchestrator (single writer) computes the path; the agent never supplies it.

---

## 2. `obs_kind` taxonomy — when to emit which

| `obs_kind` | Emit when | `reusable` default | Why it matters next round |
|---|---|---|---|
| `hypothesis` | You form a "this might be exploitable because…" before testing it | true if unresolved | Next round resumes an open hypothesis instead of re-forming it |
| `dead_end` | A path looked promising but is provably safe | **true** | The single highest-value reuse — stops re-walking cleared paths |
| `assumption` | You proceed assuming X (e.g. "config is vanilla") without proving it | true | Next round can test the assumption that gated a finding's severity |
| `invariant` | You confirm a property that holds (e.g. "all writes go through `auth.guard`") | **true** | Lets next round *skip* re-proving guards; also flags when a new commit breaks it |
| `partial_trace` | A trace you ran out of budget on | true | Resume point — pairs with `coverage_json` deferred_edges |
| `guard_observed` | A sanitizer/check on a path (even if not bypassed yet) | true | Feeds the thin Phase 3 Bypass-Recheck (and next round's Phase 0.75 Defense Pre-Break) targeting + `critical_functions` defense links |
| `tool_output` | Notable Joern/Semgrep result worth keeping (not a finding) | false | Avoids re-running the same expensive query |
| `note` | Free-form context that doesn't fit above | false | — |
| `blind_spot` | Something you could NOT examine (other-repo half, runtime-only state) | **true** | Next round (or a human) knows the coverage hole; mirrors Phase L3 Blind Spots block |

**The three load-bearing reusable kinds are `dead_end`, `invariant`, and `blind_spot`.** Logging these well is what makes round N+1 cheaper than round N. An agent that finishes a lane having logged zero `dead_end`/`invariant` rows almost certainly under-documented.

---

## 3. The `reusable` flag — what carries vs. what's ephemeral

`reusable BOOLEAN NOT NULL DEFAULT TRUE`. Set it deliberately:

- **Reusable (true):** facts about the *code* that stay true until the code changes — dead-ends, invariants, guards, blind spots, confirmed assumptions. The round-feedforward fetch (next round) pulls `WHERE reusable = true`.
- **Ephemeral (false):** facts about *this run's process* — mid-phase partial state already superseded, raw tool dumps, throwaway notes. Kept for this round's audit trail, not re-seeded.

When a later round observes that an `invariant` no longer holds (a commit broke the guard), it does **not** delete the old row — it emits a new `note`/`hypothesis` row citing the broken invariant's `obs_hash`. History is append-only; staleness is expressed by newer rows, not mutation. (The orchestrator may flip `reusable=false` on a superseded row at flush, but never deletes.)

---

## 4. Idempotency

`obs_hash` is `UNIQUE`, computed over `(agent_step_id, obs_kind, symbol_path, body)`. Canonicalize the four fields before hashing so distinct observations cannot collide: `symbol_path` is nullable, so a NULL MUST serialize to a fixed sentinel (an empty field, distinct from the literal string `"null"`), and the `|` join must be collision-free — length-prefix each field, or escape any `|` inside a value, so a `symbol_path` containing `|` cannot straddle into `body`. A collision here is silently dropped by `ON CONFLICT DO NOTHING`, losing a real observation. Replaying the *same* observation (crash recovery, re-flush) is the intended no-op of that same clause. Two agents independently reaching the same dead-end produce two rows (different `agent_step_id`) — that's intentional corroboration signal, not duplication.

---

## 5. Tier gating

| Tier | Logging depth |
|---|---|
| **LOW** | `dead_end` + `blind_spot` only (cheap, high-reuse). No hypotheses/partial traces. |
| **MEDIUM** | Above + `hypothesis`, `invariant`, `guard_observed`, `assumption`. |
| **DEEP** | All kinds, including `partial_trace` and `tool_output`, so a resumed DEEP round has full provenance. |

Logging is not free context budget — but `dead_end`/`invariant`/`blind_spot` are mandatory in **every** tier because their absence is what made the prior pipeline re-do work.

---

## 6. Cross-phase use within a single round

`agent_observations` is not only cross-round. Within one round:

- Phase 1 Hunt `guard_observed` rows tell the thin Phase 3 Bypass-Recheck — and, cross-round, the next round's Phase 0.75 Defense Pre-Break — exactly which sanitizers to attack (join on `symbol_path` → `defenses` / `critical_functions`). (The bulk of bypass work now runs *before* the Hunt in Phase 0.75; see `bypass-catalogue.md` § 6.)
- Phase 1 `dead_end` rows let Phase 2 Confirm skip re-tracing already-cleared paths.
- `blind_spot` rows feed the Phase 5 critic's eligibility check (a finding whose severity rests on an un-examined blind spot can't be `vanilla`-confident).

The `agent_steps.round_id` FK ties every observation's step to a `round_ledger` row, so a query can scope observations to "this round" or "all prior rounds" — see `round-feedforward.md`.

---

## 7. Enriching preliminary artifacts

`agent_observations` is also how **any hunt-phase agent, in every tier**, sharpens the *preliminary* artifacts that Phases 0/0.5 seeded — without ever opening DuckDB. Phase 0 decomposition and Phase 0.5 planning land first-pass rows: `sources`, `sinks`, `defenses`, `critical_functions`, and early `candidate` `gr_findings`. They are often thin — a sink with no proven reachability, a critical function ranked on heuristics alone, a defense whose `parsed_logic_json` was inferred. A hunt agent that learns something sharper about one of them is **encouraged to enrich it** rather than let the better knowledge die when its context window closes.

Enrichment is not a new mechanism — it is an ordinary observation, anchored to the artifact by `symbol_path` (the same join key § 6 already uses for `guard_observed` → `defenses` / `critical_functions`). The agent emits the claim + evidence; it never writes the artifact row:

```jsonc
{"kind": "agent_observations", "row": {
  "target_id": 1,
  "agent_step_id": 91,
  "obs_kind": "guard_observed",        // hypothesis / invariant / guard_observed / note, per the § 2 taxonomy
  "symbol_path": "pkg/img.decodePNG",  // anchors the enrichment to the preliminary critical_functions / sink / defense row
  "evidence_path": "img/png.go", "evidence_line": 144,
  "body": "decodePNG is reachable from the unauth /upload handler in 2 hops; the Phase-0 heuristic score missed this route — rank should rise",
  "confidence": 0.85,
  "reusable": true,
  "obs_hash": "<orchestrator-derived>"
}}
```

**The agent proposes; the orchestrator disposes.** At phase flush the single writer joins enrichment observations to preliminary rows by `symbol_path` and, for ranked/typed fields, applies the change **only when the observation clears the same bar the field's own lane requires**:

| Enriched field | Applied only if the observation… |
|---|---|
| `critical_functions.rank_score` / `rank_tier` | carries reachability/usage evidence of the kind `critical-function-hunt.md § 5` scores on (not a bare assertion) |
| `defenses.parsed_logic_json` | cites the concrete check it observed, so an inferred parse is replaced by an evidenced one |
| `gr_findings` severity / `confirmation_status` | — never via enrichment; `confirmation_status` only moves through the Phase 2 five gates |

Enrichments that don't clear the bar stay as observation rows — audit trail and next-round fuel — without mutating the preliminary row. The append-only rule of § 3 holds throughout: the enrichment row is never deleted, and a superseded preliminary value is expressed by the newer row, not by silent overwrite.

Two guardrails keep this safe:

- **No agent writes an artifact table directly.** Enrichment is a *proposal* carried as an observation and applied by the orchestrator (single-writer rule, § 1). A subagent that opens DuckDB to `UPDATE critical_functions` is aborted and re-spawned with a queue handle only.
- **The anchor is `symbol_path`, never a row id the agent invented.** The orchestrator resolves the target row itself, so a stale or wrong id from an agent cannot redirect an enrichment onto an unrelated artifact.

This is the persistence side of the rule that *every* hunt agent — not a dedicated enrichment lane — owns the accuracy of the preliminary registry. See `commands/vuln-swarm.md` § Phase 1 for the orchestration side.

---

## 8. Finding identity & sightings (#1) — commit-independent dedup

`agent_observations` persists *reasoning*; `finding_sightings` persists the *life of a finding across commits*. A finding's identity is its `gr_findings.finding_hash` — derived from the Joern `fullName` natural key, **commit-independent** — so the same vulnerability seen at three commits shares one `finding_hash` and accrues three append-only `finding_sightings` rows, never three findings.

Each sighting is a queue event flushed by the orchestrator (single-writer rule; agents never derive the hash):

```jsonc
{"kind": "finding_sightings", "row": {
  "finding_hash": "<gr_findings.finding_hash — orchestrator-derived, commit-independent>",
  "target_id": 1,
  "agent_step_id": 88,
  "commit_sha": "bbbb",
  "body_hash": "<normalized enclosing-fn body hash — local change scope>",
  "slice_fingerprint": "<source->sink function-path fingerprint — non-local change scope>",
  "verdict": "needs_attention",      // candidate | confirmed | refuted | needs_attention
  "change_scope": "body_hash",       // NULL | initial | body_hash | slice_path | both
  "from_commit_sha": "aaaa",         // the prior sighting's identity, copied in so one
  "from_body_hash": "<prior>",       //   row tells the whole "moved from X to Y" story
  "from_slice_fingerprint": "<prior>",
  "sighting_hash": "<orchestrator-derived; idempotent replay via ON CONFLICT>"
}}
```

Two rules make sightings safe and useful:

- **`needs_attention` is a non-flapping verdict.** When code moves under a confirmed finding and does not cleanly re-confirm, the sighting records `needs_attention` — it does **not** move `gr_findings.confirmation_status` (no status flap) and produces **no** recurrence-counter delta (#2). Only a clean re-confirm/refute transitions status.
- **`change_scope` makes "what changed" inspectable** without a self-join: `body_hash` = the enclosing function moved locally; `slice_path` = the source→sink path changed; `both` = both; `initial` = first sighting. `v_finding_changes` surfaces every non-`initial` sighting; the `vrdb history <finding_hash>` CLI renders the full timeline.

---

## 9. Mutation meta-logging (#6) — every change is inspectable

Where §§1–8 capture *findings and reasoning*, `mutation_log` captures **the act of mutating the DB itself** — one append-only row per in-place change, written in the **same flush transaction** as the mutation it records, so the log can never drift from reality.

```jsonc
{"kind": "mutation_log", "row": {
  "target_id": 1,
  "table_name": "gr_findings",
  "row_key": "<finding_hash / natural-key hash of the mutated row>",
  "op": "status_transition",         // update | status_transition
  "delta_json": "{\"col\":\"confirmation_status\",\"before\":\"candidate\",\"after\":\"confirmed\"}",
  "round_id": 4, "phase": "phase2_confirm", "agent_step_id": 88, "tx_id": "<flush tx>",
  "mutation_hash": "<orchestrator-derived; idempotent replay via ON CONFLICT>"
}}
```

Scope and storage discipline (kept deliberately narrow so the log stays small and signal-dense):

- **Logged: in-place UPDATEs + status transitions only.** Plain inserts are *not* logged (the row's own existence is the record). **VIRTUAL generated columns are never logged** — only the input-factor UPDATEs that feed them (e.g. `weakness_classes.seen_count`, never the derived `systemic`).
- **`delta_json` is literal for small fields, hash-ref for large ones.** A small field stores `{"col","before","after"}` inline; a ≥16 KB sidecar-backed field stores `{"col","before_sha","after_sha"}` and the content lives in `db/sidecars/<sha>` — never the body. Rows stay small; sidecars are reused.
- **Append-only, no auto-prune.** Bounded by the hash-ref discipline, consistent with the `agent_observations` append-only rule (§3).

**Inspection surface = declarative VIEWs + thin `vrdb` subcommands** (query logic lives in SQL, the CLI is a wrapper):

| View / CLI | Answers |
|---|---|
| `v_finding_history` / `vrdb history <finding_hash>` | One per-finding timeline — interleaves #1's sighting `change_scope` events with this finding's `gr_findings` mutations, oldest first |
| `v_finding_changes` | Only the sightings where code moved (non-`initial` `change_scope`) |
| `v_round_diff` / `vrdb diff [--round N]` | Per-round mutation rollup — "what did this round change", counts by `(round_id, table_name, op)` |
| `vrdb log [--table T] [--limit N]` | Raw `mutation_log` rows, newest first — the audit firehose |

---

## 10. `vrdb exec` — DML verb for status transitions and payload enrichment

`vrdb exec "SQL" --db PATH` runs a single DML statement (UPDATE, DELETE, or INSERT) and emits one JSON line to stdout:

```json
{"rows_affected": 1}
```

This is the supported verb for finding status transitions and payload enrichment UPDATEs. Example — promoting a candidate to confirmed:

```sh
vrdb exec "UPDATE gr_findings SET confirmation_status='confirmed' WHERE id=42" --db audit.duckdb
# → {"rows_affected": 1}
```

A `rows_affected` value other than the expected count is an immediate signal that the predicate targeted wrong rows — treat it as an error, not a silent pass.

**Contrast with the other verbs:**

| Verb | Direction | Use for |
|---|---|---|
| `put TABLE --db PATH` | stdin JSONL → DB insert | Idempotent bulk insert of new rows |
| `fetch SQL --db PATH` | DB SELECT → stdout JSONL | Read / query; emits one JSON object per row |
| `exec SQL --db PATH` | DB DML → stdout `{"rows_affected": N}` | In-place mutations: status transitions, enrichment UPDATEs |

Previously, flush scripts performed UPDATEs by abusing `fetch` with side-effecting CTEs, or used a "sentinel-id" insert workaround. `exec` is the correct verb now — use it for any write that is not a fresh insert of a new row.

---

## 10a. Delegation receipts — verify the intended rows landed, never trust the report

The single-writer rule routes every persist through one path; under full delegation the
orchestrator never runs the write in its own context and so **never sees a silent no-op in its
own transcript**. That opens a distinct failure class: an agent (or a flush script) **reports
success while changing nothing** — a cached/idempotent executor that returns *"No new work.
Result already reported"*, or a remediation step that was *written but never executed* yet
emitted a written-style success. Neither is caught by reading the agent's report; both are only
caught by a *later forensic DB read*. The receipt check pulls that read forward.

**After any delegated DB write, the orchestrator MUST verify the specific intended rows landed
— by id or by hash — not trust the agent's success report.** Concretely:

- For an `exec` status transition / enrichment UPDATE, the report already carries
  `{"rows_affected": N}`; the orchestrator confirms `N` equals the **expected** count for the
  exact predicate. A mismatch (especially `rows_affected: 0` on an UPDATE that claimed success)
  is an immediate error, not a silent pass — the predicate targeted the wrong rows, or the
  intended row never existed.
- For a delegated `put`, the orchestrator re-fetches the intended natural keys / hashes and
  confirms each is present. A `put` summary's `skipped > 0` is benign idempotency (§ the Put
  contract), but `inserted == 0` on rows the orchestrator *believed were new* is a receipt
  failure to surface, not absorb.
- A delegated multi-step remediation reports per-step side-effects; the orchestrator verifies
  each claimed mutation against `mutation_log` (§ 9) in the same flush window — a step that
  reports done but wrote no `mutation_log` row never ran.

A "no new work / already reported" or written-but-never-run result is a **silent-no-op failure
class invisible under full delegation**; the receipt check is what makes it visible. This is
the persistence-layer counterpart to the orchestrator's single-writer authority: the single
writer owns not just *issuing* the write but *confirming it took effect*.

---

## 11. FK id-space pre-validation in `Put`

`Put` now validates every cross-table foreign-key column in each incoming row **before** the insert reaches DuckDB. For each FK column (e.g. `defense_bypasses.defense_id`), it queries the parent table (`defenses`) to confirm the referenced id exists. If the id is missing, `Put` rejects the row with a clear message:

```
Put: defense_bypasses.defense_id=62 references missing defenses.id (FK id-space mismatch)
```

instead of letting DuckDB surface a cryptic `key id:62 does not exist` at constraint-check time.

**What this catches.** The classic mistake is writing a `critical_functions.id` value into a `sink_id` or `defense_id` column — the tables share an integer id space so the value looks plausible but references the wrong table. Pre-validation catches this at write time, in the lane that produced the row, before the error propagates into later phases.

**Self-referential FKs are not pre-validated.** To avoid false positives when a batch contains rows that reference each other (e.g. `agent_steps.parent_step_id` where the parent is in the same batch), self-referential FK columns are skipped. Only cross-table FKs are checked.

**Practical guidance.** When a `Put` rejects a row with an FK mismatch error: (1) identify which column carries the wrong id, (2) fetch the correct parent-table id (`vrdb fetch "SELECT id FROM <parent> WHERE …" --db PATH`), (3) re-emit the row with the corrected FK value.

---

## 12. Coverage views — `v_phase_status`, `v_coverage`, `v_fact_hitscore`, and `v_fact_similar`

Four views defined in `db/schema.sql` are used by the orchestrator at round entry and completion. The first two are the DEEP completion gate (see `SKILL.md` § DEEP Completion Gate); the second two are the per-target memory & recall read surfaces (see `references/v2/round-feedforward.md` § 2 and § 5).

### Truncation `blind_spot` emission

When a fetch (3) budget cap drops reusable facts at **DEEP** tier, the orchestrator emits a `blind_spot` `agent_observations` row recording the shortfall:

```jsonc
{"kind": "agent_observations", "row": {
  "target_id": 1,
  "agent_step_id": <round-entry step id>,
  "obs_kind": "blind_spot",
  "symbol_path": null,
  "body": "N reusable dead_ends ranked below the round_entry budget cap; not seeded this round",
  "confidence": 1.0,
  "reusable": true,
  "obs_hash": "<orchestrator-derived>"
}}
```

This makes the truncation a tracked coverage hole: it is both inspectable now (`vrdb log` / `priors_fetched_json.truncated`) and re-surfaced by next round's fetch (3) `blind_spot` pull — so budget truncation never silently discards reusable signal. The `priors_fetched_json.truncated` map records `{"<source>": {"available": N, "loaded": M, "min_score_loaded": S}}` per source at round entry (see `round-feedforward.md` § 5).

### `v_fact_hitscore` — composite hit-score ranking

`v_fact_hitscore` ranks every reusable fact (from `agent_observations` where `reusable=TRUE` and `obs_kind IN ('dead_end','invariant','blind_spot','assumption')`) by a composite `hit_score`, so fetch (3) budget truncation keeps the objectively-most-useful rows:

```sql
-- Ordered fetch (3) — keeps highest-value facts when budget truncates.
SELECT obs_kind, symbol_path, body, confidence, hit_score
FROM v_fact_hitscore
WHERE target_id = ?
ORDER BY hit_score DESC
LIMIT ?;
```

Signals and weights (all externalized to `scoring_config` `scope='recurrence'`; no magic constants):

| Signal | Config key | Default weight | Derivation |
|---|---|---|---|
| `recurrence_norm` | `w_rec` | 0.50 (dominant) | Within-target `PERCENT_RANK` of corroboration count + `recurrence_counter.counter` |
| `led_to_outcome` | `w_outcome` | 0.25 | 1.0 if `symbol_path` lies on a confirmed `gr_findings` or reproduced `defense_bypasses` lineage |
| `reuse_effectiveness` | `w_reuse` | 0.15 | 1.0 for a `dead_end` whose path was NOT re-walked in the round it was seeded into (absence of re-walk rows) |
| `confidence_decayed` | `w_conf` | 0.10 | `max_confidence × (0.5)^rounds_since_last_corroboration` |

### `v_fact_similar` — approximate recall

`v_fact_similar` finds near-twin symbol_paths within the per-target fact set using trigram-Jaccard over the **full** `symbol_path` (split on `.`) plus a `slice_fingerprint` nearest-neighbor component. Deterministic SQL only — no embeddings, no external model:

```sql
-- Approximate recall — surface near-twin dead_ends as lower-priority leads.
SELECT symbol_path_a, symbol_path_b, path_jaccard, fp_match, similarity
FROM v_fact_similar
WHERE target_id = ?
ORDER BY similarity DESC;
```

The combined similarity is `0.7 × path_jaccard + 0.3 × fp_match`. The inclusion threshold is `scoring_config` `scope='recurrence'`, `config_key='approx_recall_floor'` (default 0.40). Facts recalled by approximate similarity are tagged `approximate` in the seed so the agent treats them as *leads to check*, not proven invariants — an `approximate` `dead_end` prioritizes inspecting the near-twin, it does not suppress the path.

Two views defined in `db/schema.sql` serve as the orchestrator's **DEEP completion gate** (see `SKILL.md` § DEEP Completion Gate for the full gate protocol).

**`v_phase_status`** — one row per pipeline phase, reporting row counts and a `ran` boolean:

```sh
vrdb fetch "SELECT * FROM v_phase_status" --db audit.duckdb
```

Each row indicates whether that phase produced any output. A phase with `ran = false` and no recorded preflight gap (`agent_observations` blind_spot) is a red gate — the orchestrator does not declare the audit done.

**`v_coverage`** — named gap metrics across the audit, inspected before declaring completion:

```sh
vrdb fetch "SELECT * FROM v_coverage" --db audit.duckdb
```

Key columns and what they signal:

| Column | Red-gate condition | Meaning |
|---|---|---|
| `findings_candidate_open` | `> 0` | Confirm (Phase 2) has unresolved candidates |
| `defenses_without_bypass_attempt` | `> 0` | Phase 0.75 did not cover every defense in the inventory |
| `guards_on_paths_without_defense_row` | `> 0` | A guard on a reach path has no `defenses` row → Phase 0 defense enumeration under-populated |
| `validator_cfs_without_defense_link` | `> 0` | A validator/sanitizer critical-fn has no `defenses` row → defense enumeration gap |
| `dangerous_sink_cfs_without_sink_row` | `> 0` | A dangerous-sink critical-fn has no `sinks` row → sink enumeration gap |
| `confirmed_without_critic` | `> 0` | A confirmed finding skipped the Phase 5 REPORT critic |
| `confirmed_missing_severity` | `> 0` | A confirmed finding has no severity set |
| `distinct_target_ids` | `> 1` | target_id drift — rows from multiple targets in one DB |
| `slices_without_codebase_coverage` | `> 0` | `input_slices` exist but no `cpg_slice_coverage` row — union-of-slices codebase coverage was never measured when slices ended (static side; count-free, no %-floor) |
| `fuzz_runs_without_coverage_measurement` | `> 0` | A `fuzz_runs` row that **ran** (`skip_reason IS NULL`) records no coverage measurement in `coverage_json` (none of `edges`/`blocks`/`function_coverage`) — an executed fuzz run never measured coverage (the dynamic mirror of `slices_without_codebase_coverage`) |
| `fuzz_skips_unrecorded` | `> 0` | A `boundary_fuzz_lane` step that ran or was documented-skipped emitted no `fuzz_runs` row — the Phase 1.5 mandatory attempt left no accounting |

The orchestrator must inspect each signal and either resolve it (re-run the missing phase, fix the FK, set the severity) or record an accepted-gap justification as an `agent_observations` row (`obs_kind: "blind_spot"`, `reusable: true`) before marking the audit complete. These are not auto-pass conditions.

Read fuzz code-coverage back with **`v_fuzz_coverage`** — the read-time per-run rollup (the dynamic analogue of `v_cpg_slice_coverage`): `edges` / `function_coverage_pct` / `functions_covered` / `uncovered_frontier_n` are extracted from each ran `fuzz_runs.coverage_json` (never stored), ordered by `(target_id, round_id, entry_point)` so the round-over-round coverage trend is one query. No percentage floor — a low % is inspected, not failed; the two gates above enforce only that coverage was *measured and accounted*. See `references/v2/fuzzing-lane.md` § 8/§ 8a.

---

## 13. DEEP lane roster: materialization, skip, and gate

This section covers the lifecycle of the mandatory DEEP lanes from Plan through gate check. The authoritative roster (and its count) is `v_required_deep_lanes(lane_name, phase)`; the per-lane ledger is `v_lane_coverage(lane_name, phase, strategy_id, steps_total, steps_scheduled, steps_executed, steps_skipped_documented, gate_status)` — both in `db/schema.sql`. The human-facing doctrine is in `SKILL.md` § Mandatory DEEP Lane Roster.

### Materialization (Phase 0.5)

For each lane in `v_required_deep_lanes`, the orchestrator inserts one `agent_steps` row at Plan time:

```jsonc
{
  "target_id": <audit target_id>,
  "strategy_id": <strategies.id WHERE name = lane_name>,
  "started_at": <plan time>,
  "status": "scheduled",
  "step_hash": "plan-roster-<lane_name>",
  "ended_at": null
}
```

`status='scheduled'` is a new `agent_steps.status` value meaning "Plan-materialized, not yet run." This sentinel row is what makes a never-spawned lane queryable — it stays `scheduled` with zero executed steps and is caught by the gate rather than silently absent.

### Execution

When a lane runs it either:

- Inserts its own real `agent_steps` row (`status='success'` / `'exhausted'` / etc.), OR
- Flips the scheduled sentinel row via:

```sh
vrdb exec "UPDATE agent_steps SET status='success', ended_at='<ts>', termination_reason='<…>' WHERE step_hash='plan-roster-<lane_name>'" --db PATH
```

Either way, `v_lane_coverage.steps_executed` becomes `> 0` and `gate_status` becomes `'ok'`.

### Documented skip

A legitimately N/A lane records `status='skipped'` with a non-empty `termination_reason` explaining why the lane does not apply to this target (e.g. "`boundary_fuzz_lane` skipped: pure-PHP target with no C extension or FFI boundary; no harnessable native code"). This is the lane-level skip reason — distinct from `fuzz_runs.skip_reason`, which is per fuzz run.

```sh
vrdb exec "UPDATE agent_steps SET status='skipped', ended_at='<ts>', termination_reason='<reason>' WHERE step_hash='plan-roster-<lane_name>'" --db PATH
```

A skipped lane produces `v_lane_coverage.steps_skipped_documented = 1` and `gate_status = 'skipped'` (waived).

### Gate query

Before declaring a DEEP audit complete, the orchestrator runs:

```sql
SELECT lane_name, phase, steps_executed, steps_skipped_documented, gate_status
FROM v_lane_coverage WHERE gate_status = 'MISSING';
```

Any row returned is a required DEEP lane that was neither executed nor documented-skipped — a HARD RED gate. The orchestrator does NOT declare done while any lane is `MISSING`. The three `gate_status` values: `'ok'` (≥1 executed step), `'skipped'` (documented N/A via `status='skipped'` + `termination_reason`), `'MISSING'` (blocks completion).
