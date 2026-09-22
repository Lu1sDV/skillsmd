-- vuln-research migration 0025 — promising-lane static-analysis feed-forward
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: any DuckDB-backed static-analysis subagent (Phase 1 Hunt, Agent Sweep S2,
-- Phase 0.75 code-reading, Phase L3/L4 when DuckDB-backed) MAY, opportunistically and
-- non-mandatorily, surface a *promising lane* — a concrete new investigation direction
-- worth a dedicated lane (e.g. "custom template engine → SSTI-fuzz lane @ render()").
-- A promising lane PERSISTS and becomes a ranked candidate direction the NEXT round picks
-- up first; it does NOT spawn work in the run that surfaced it (feed-forward only, the
-- methodology_blind_spots action model). A positive lead is modeled as its OWN concept,
-- distinct from a methodology_blind_spots gap (negative) and a suspicious_points region
-- hypothesis (vuln_class@region). Four additive pieces:
--   (1) promising_lanes — NEW table. One row per surfaced lead. NK
--       (target_id, proposed_lane_kind, region_hash) → lane_hash UNIQUE is the dedup/merge
--       key: a re-flush or two-lanes-same-lead hits ON CONFLICT DO NOTHING and the
--       orchestrator bumps dedup_cluster_size (the suspicious_points precedent). region_hash
--       carries the '__TARGET_WIDE__' sentinel when the lead is unanchored. proposed_lane_kind
--       / vuln_class are OPEN vocab → free TEXT (the strategy/lane-name doctrine); severity is
--       the CLOSED gr_findings vocab → NULL-permitting CHECK. The promise composite and the
--       est_severity weight are NEVER stored — only raw factor signals (novelty,
--       reachability_prior, ledger_history_factor, severity) are, mirroring the
--       critical_functions.factor_* / phase0_priorities.factor_* never-store rule.
--   (2) pl_severity_weight(sev) MACRO — the one place the severity→numeric mapping lives
--       (the sp_signed_rank precedent). Read-time, inspectable. NULL/unknown → 0.5 (neutral).
--   (3) v_promising_lanes_ranked — read-time ranking, NO stored score (the
--       v_critical_fn_ranked / v_suspicious_points_ranked / v_promise_ranked precedent).
--       promise = novelty × est_severity × reachability_prior × ledger_history_factor (the
--       Perpetual Loop formula), COALESCE-neutral (missing factor = 1.0) so a sparsely-scored
--       lead still ranks instead of zeroing out. Ordering is ordinal: unconsumed directions
--       first → not-already-covered first → promise DESC → dedup_cluster_size DESC → created_at.
--       overlaps_sp_id / overlaps_finding_id drive a read-time already_covered flag + down-rank
--       (never delete — no silent loss).
--   (4) v_coverage — restate (CREATE OR REPLACE; idempotent, FK-free): append the SIGNAL
--       metric 'promising_lanes_unpromoted' (static-analysis leads not yet carried into a
--       later round as a lane). Like methodology_blindspots_unpromoted / fuzz_runs_skipped it
--       is a count-free inspect-SIGNAL, NOT an auto-red: the latest round always has
--       unconsumed directions by construction.
--
-- NON-MANDATORY SIDE-OUTPUT (the suspicious_points / cpg_coverage precedent): this is NOT a
-- new mandatory roster lane, NOT in v_required_deep_lanes, NOT a blocking gate, and adds NO
-- new v_phase_status phase row (a side-output is not a phase). Its only v_coverage metric is
-- the inspect-SIGNAL above.
--
-- FRESH-TABLE NOTE (the 0010/0015/0017/0018 pattern): promising_lanes is a NEW table, so its
-- inline NOT NULL / CHECK / UNIQUE constraints are safe on this upgrade path and match
-- db/schema.sql byte-for-byte. No existing CHECK is widened.
--
-- ORDERING: targets (0001), round_ledger (0001/0002), agent_steps (0001), gr_findings and
-- suspicious_points (0010) all exist earlier, so the promising_lanes FKs (target_id, round_id,
-- agent_step_id, overlaps_sp_id, overlaps_finding_id, and the promoted_to_round_id self-forward
-- reference to round_ledger) resolve cleanly when this is applied last. v_coverage was created
-- earlier (0006) and last widened by 0023; CREATE OR REPLACE VIEW is idempotent + FK-free
-- (DuckDB replaces the whole body), so the full body is restated here. db/schema.sql carries
-- the identical definitions (schema_mirror parity).

------------------------------------------------------------
-- (1) promising_lanes (schema v25) — see db/schema.sql for the full column rationale.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS promising_lanes (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  round_id INTEGER REFERENCES round_ledger(id),            -- nullable: single-shot audit need not open a round
  agent_step_id INTEGER REFERENCES agent_steps(id),        -- emitting lane/step (provenance)
  proposed_lane_kind TEXT NOT NULL,                        -- OPEN vocab (free TEXT): the strategy/lane to run (ssti_fuzz, custom_orm_sqli, ...)
  vuln_class TEXT,                                          -- OPEN vocab descriptive: bug class targeted (ssti/sqli/deser/...); NOT in NK
  region_hash TEXT NOT NULL,                               -- normalized anchor hash; '__TARGET_WIDE__' sentinel when unanchored
  symbol_path TEXT,                                        -- human-readable region anchor (nullable for target-wide)
  evidence_path TEXT,
  evidence_line INTEGER,
  title TEXT NOT NULL,                                     -- one-line direction name
  body TEXT NOT NULL,                                      -- VERBOSE lane writeup: why promising + how to pursue next round
  body_sidecar_path TEXT,                                  -- set when body > 16 KB (A1)
  -- promise factors (raw signals; composite computed read-time — NEVER stored):
  novelty REAL,                                            -- 0..1: how new vs already-explored (ledger)
  reachability_prior REAL,                                 -- 0..1: attacker-reachability prior
  ledger_history_factor REAL,                              -- cross-round multiplier (down-weight exhausted families); orchestrator-seeded from feed-forward
  severity TEXT                                            -- CLOSED enum; est_severity factor derived read-time
    CHECK (severity IS NULL OR severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
  trigger_evidence_json TEXT,                              -- structured spark provenance (source/sink/slice/observation ids)
  trigger_evidence_sidecar_path TEXT,                      -- set when trigger_evidence_json > 16 KB (A1)
  -- overlap cross-links (orchestrator-stamped at flush when a same-target region+class match exists):
  overlaps_sp_id INTEGER REFERENCES suspicious_points(id),
  overlaps_finding_id INTEGER REFERENCES gr_findings(id),
  dedup_cluster_size INTEGER NOT NULL DEFAULT 1,           -- idempotent merge-hit count (lanes + rounds)
  promoted_to_round_id INTEGER REFERENCES round_ledger(id),-- feed-forward closure: set when a LATER round consumes this as a lane
  lane_hash TEXT NOT NULL,                                 -- stable hash over (target_id, proposed_lane_kind, region_hash) — NK/dedup/merge key
  created_at TIMESTAMP NOT NULL,
  UNIQUE (lane_hash)
);

------------------------------------------------------------
-- (2) pl_severity_weight — the one place the severity→numeric mapping lives (the
-- sp_signed_rank precedent). Read-time, inspectable. NULL/unknown → 0.5 (neutral).
------------------------------------------------------------
CREATE OR REPLACE MACRO pl_severity_weight(sev) AS
  CASE sev WHEN 'CRITICAL' THEN 1.0 WHEN 'HIGH' THEN 0.75 WHEN 'MEDIUM' THEN 0.5 WHEN 'LOW' THEN 0.25 ELSE 0.5 END;

------------------------------------------------------------
-- (3) v_promising_lanes_ranked (v25) — read-time ranking, NO stored score (the
-- v_critical_fn_ranked / v_suspicious_points_ranked / v_promise_ranked precedent).
-- promise = novelty × est_severity × reachability_prior × ledger_history_factor (the
-- Perpetual Loop formula), COALESCE-neutral so a sparsely-scored lead still ranks.
-- Identical to db/schema.sql.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_promising_lanes_ranked AS
SELECT
  id, target_id, round_id, proposed_lane_kind, vuln_class, symbol_path, severity,
  novelty, reachability_prior, ledger_history_factor,
  pl_severity_weight(severity) AS est_severity,
  -- promise = novelty × est_severity × reachability_prior × ledger_history_factor (Perpetual Loop formula).
  -- COALESCE-neutral (missing factor = 1.0) so a sparsely-scored lead still ranks instead of zeroing out.
  COALESCE(novelty, 1.0)
    * pl_severity_weight(severity)
    * COALESCE(reachability_prior, 1.0)
    * COALESCE(ledger_history_factor, 1.0) AS promise,
  (overlaps_sp_id IS NOT NULL OR overlaps_finding_id IS NOT NULL) AS already_covered,
  (promoted_to_round_id IS NULL) AS open_direction,
  dedup_cluster_size, promoted_to_round_id, created_at
FROM promising_lanes
ORDER BY
  (promoted_to_round_id IS NULL) DESC,                              -- unconsumed directions first (next-round worklist)
  (overlaps_sp_id IS NOT NULL OR overlaps_finding_id IS NOT NULL),  -- already-covered leads LAST (FALSE=0 sorts first)
  promise DESC,                                                     -- continuous promise score
  dedup_cluster_size DESC,                                          -- recurrence across lanes/rounds
  created_at;

------------------------------------------------------------
-- (4) v_coverage — append the promising_lanes_unpromoted SIGNAL metric. Full body
-- restated; all branches through fuzz_skips_unrecorded are byte-identical to 0023 /
-- db/schema.sql. The new metric is an inspect-SIGNAL (like methodology_blindspots_unpromoted),
-- NOT an auto-red: the latest round always has unconsumed directions by construction.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_coverage AS
SELECT metric, value, note FROM (
  SELECT 'distinct_target_ids' AS metric, (SELECT count(DISTINCT target_id) FROM gr_findings) AS value,
         'expect exactly 1 per single-target audit; >1 means target_id drift across lanes' AS note
  UNION ALL SELECT 'findings_total', (SELECT count(*) FROM gr_findings),
         'all candidate+confirmed+refuted findings'
  UNION ALL SELECT 'findings_candidate_open', (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'candidate'),
         'still unconfirmed; Confirm phase incomplete if >0 at report time'
  UNION ALL SELECT 'findings_confirmed', (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'confirmed'),
         'promoted findings (the registry)'
  UNION ALL SELECT 'confirmed_missing_severity', (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'confirmed' AND severity IS NULL),
         'confirmed finding with no severity set — Proof/critic gap'
  UNION ALL SELECT 'confirmed_without_critic', (SELECT count(*) FROM gr_findings f WHERE f.confirmation_status = 'confirmed' AND NOT EXISTS (SELECT 1 FROM critic_findings c WHERE c.finding_id = f.id)),
         'confirmed finding that never went through the REPORT critic'
  -- confirmed_without_refutation (v0.30, C08-A-F1): mechanical enforcement of the
  -- refute-before-confirm mandate. Mirrors confirmed_without_critic. A finding is
  -- "refuted" when at least one refutations row exists for it whose agent_step
  -- ran and FAILED to refute (i.e. the refutation attempt was made — the row
  -- existing proves an adversarial pass ran). Count-free. > 0 => RED.
  UNION ALL SELECT 'confirmed_without_refutation',
    (SELECT count(*) FROM gr_findings f
     WHERE f.confirmation_status = 'confirmed'
       AND NOT EXISTS (SELECT 1 FROM refutations r WHERE r.finding_id = f.id)),
    'confirmed finding with no refutations row — refute-before-confirm mandate violated (RED)'
  UNION ALL SELECT 'defenses_total', (SELECT count(*) FROM defenses),
         'defense inventory size'
  UNION ALL SELECT 'defenses_without_bypass_attempt', (SELECT count(*) FROM defenses d WHERE NOT EXISTS (SELECT 1 FROM defense_bypasses b WHERE b.defense_id = d.id)),
         'defense with zero bypass attempts — Phase 0.75 pre-break gap'
  UNION ALL SELECT 'fuzz_runs_total', (SELECT count(*) FROM fuzz_runs),
         'dynamic runs incl. documented skips'
  UNION ALL SELECT 'fuzz_runs_skipped', (SELECT count(*) FROM fuzz_runs WHERE skip_reason IS NOT NULL),
         'runs skipped — confirm each skip_reason is honest'
  UNION ALL SELECT 'slices_total', (SELECT count(*) FROM input_slices),
         'planned input slices'
  UNION ALL SELECT 'sources_total', (SELECT count(*) FROM sources),
         'attacker-controllable input vectors'
  UNION ALL SELECT 'sinks_total', (SELECT count(*) FROM sinks),
         'dangerous sink calls'
  -- Completeness contradiction signals (v0.20): detect UNDER-population of the
  -- Phase-0 inventories by contradiction — rows that prove a missing inventory
  -- entry must exist. Count-free, no magic-constant floor. > 0 => enumeration gap.
  UNION ALL SELECT 'guards_on_paths_without_defense_row',
    (SELECT count(*) FROM critical_fn_reach r
     WHERE r.guard_path_json IS NOT NULL AND r.guard_path_json <> '' AND r.guard_path_json <> '[]'
       AND NOT EXISTS (
         SELECT 1 FROM defenses d
         WHERE d.symbol_path <> '' AND r.guard_path_json LIKE '%' || d.symbol_path || '%')),
    'guard on a reach path has no defenses row — Phase 0 defense enumeration under-populated'
  UNION ALL SELECT 'validator_cfs_without_defense_link',
    (SELECT count(*) FROM critical_functions cf
     WHERE cf.cf_category = 'validator_sanitizer' AND cf.defense_id IS NULL),
    'validator/sanitizer critical-fn has no defenses row — defense enumeration gap'
  UNION ALL SELECT 'dangerous_sink_cfs_without_sink_row',
    (SELECT count(*) FROM critical_functions cf
     WHERE cf.cf_category = 'dangerous_sink' AND cf.sink_id IS NULL),
    'dangerous-sink critical-fn has no sinks row — sink enumeration gap'
  -- Context-persistence + recon-floor signals (v0.23).
  -- (a) executed_steps_without_observation: step-level mirror of
  --     v_observation_coverage. Count of EXECUTED agent_steps
  --     (running/success/exhausted/failed/timed_out) that hung ZERO
  --     agent_observations — the per-step view of a context-logging blackout. >0 =>
  --     at least one step ran but saved no context into the DB.
  UNION ALL SELECT 'executed_steps_without_observation',
    (SELECT count(*) FROM agent_steps st
     WHERE st.status IN ('running','success','exhausted','failed','timed_out')
       AND NOT EXISTS (SELECT 1 FROM agent_observations o WHERE o.agent_step_id = st.id)),
    'executed agent_step with zero agent_observations — context-logging blackout (mirror of v_observation_coverage)'
  -- (b) defenses_below_validator_cf_floor: recon UNDER-ENUMERATION floor. Every
  --     distinct validator/sanitizer critical_function IS a defense callsite, so the
  --     stored defenses inventory can never legitimately be SMALLER than the count of
  --     distinct validator/sanitizer CFs. GREATEST(distinct_validator_cfs -
  --     defenses_total, 0) is the shortfall size; >0 => wholesale defense
  --     under-storage. Conservative absolute floor — distinct from the 0014 linkage
  --     signals (validator_cfs_without_defense_link etc.), which fire on UNLINKED
  --     defenses; THIS fires on absolute under-count even when every stored defense
  --     is fully linked.
  UNION ALL SELECT 'defenses_below_validator_cf_floor',
    GREATEST(
      (SELECT count(DISTINCT cf.symbol_path) FROM critical_functions cf
       WHERE cf.cf_category = 'validator_sanitizer')
      - (SELECT count(*) FROM defenses), 0),
    'stored defenses fewer than distinct validator/sanitizer CFs — recon defense under-enumeration floor (shortfall size; >0 = RED)'
  -- (c) slices_without_codebase_coverage (v0.24): the "SAVE coverage when slices
  --     end" gate. If any input_slices row exists for the audit but NO
  --     cpg_slice_coverage row was ever written, the union-of-slices codebase
  --     coverage was never measured/saved => 1 (RED). Count-free EXISTS/NOT EXISTS —
  --     no %-floor, no magic constant; it enforces only that the measurement is
  --     saved, never how high it must be (slicing is selective by design, so a low
  --     % is inspected via v_cpg_slice_coverage, not auto-failed).
  UNION ALL SELECT 'slices_without_codebase_coverage',
    CASE WHEN EXISTS (SELECT 1 FROM input_slices)
          AND NOT EXISTS (SELECT 1 FROM cpg_slice_coverage)
         THEN 1 ELSE 0 END,
    'input_slices exist but no cpg_slice_coverage row — codebase slice-coverage was never measured/saved when slices ended (RED)'
  -- Methodology blind-spot feed-forward signal (v0.25): merged Phase-1.6 directions not
  -- yet consumed by a later round as a lane. SIGNAL, not auto-red — the latest round always
  -- has unconsumed directions by construction; inspect via v_methodology_blindspots_ranked.
  UNION ALL SELECT 'methodology_blindspots_unpromoted',
    (SELECT count(*) FROM methodology_blind_spots WHERE promoted_to_round_id IS NULL),
    'merged methodology blind-spots not yet carried into a later round as a direction/lane — SIGNAL not auto-red (expected on the latest round); confirm each was considered as a next-round lane'
  -- lanes_stuck_running (v0.30, P2 completeness critic): count of agent_steps in
  -- status='running' that belong to a required DEEP lane in the current round.
  -- A non-zero value means a HEAVY lane (e.g. cpg_coverage / JVM) OOM'd or crashed
  -- and was never cleaned up. RED when > 0.
  -- Lane names are inlined (v_required_deep_lanes and v_lane_coverage are defined
  -- after v_coverage in schema order, so they cannot be referenced here directly).
  UNION ALL SELECT 'lanes_stuck_running',
    (SELECT count(*) FROM agent_steps st
     JOIN strategies s ON s.id = st.strategy_id
     WHERE st.status = 'running'
       AND s.name IN (
         'preliminary_enumeration_lane','forward_slice_lane','backward_sink_lane',
         'critical_function_dataflow_lane','defense_base_lane',
         'defense_context_verification_lane','isolation_fuzz_lane',
         'html_sanitizer_bypass_lane','concolic_bypass_lane',
         'llm_seed_corpus_lane_a','llm_seed_corpus_lane_b','fuzzgpt_history_lane','boundary_fuzz_lane',
         'methodology_blindspot_lane_a','methodology_blindspot_lane_b','report_critic'
       )
       AND (
         (st.round_id IS NULL AND NOT EXISTS (SELECT 1 FROM round_ledger))
         OR st.round_id IS NOT DISTINCT FROM (
           SELECT cr.round_id FROM v_current_round cr
           WHERE cr.target_id = (
             SELECT target_id FROM round_ledger WHERE id = st.round_id LIMIT 1
           )
           LIMIT 1
         )
       )),
    'required DEEP lane steps stuck in status=running in current round — a crashed/OOM lane that was never cleaned up (RED when > 0)'
  -- Fuzz-coverage gates (v0.29, gate fixed v0.30): the DYNAMIC mirror of slices_without_codebase_coverage.
  -- Both are count-free and carry NO %-floor (engine coverage is selective by design — a
  -- low % is inspected via v_fuzz_coverage, never auto-failed). They enforce only that
  -- (1) every EXECUTED fuzz run actually MEASURED coverage, and (2) every executed/skipped
  -- boundary_fuzz_lane step is ACCOUNTED by a fuzz_runs row (mandatory-attempt discipline).
  -- v0.30 fix (C09-A-F1): replaced gameable NOT LIKE '%edges%' substring test with
  -- json_extract value-presence check — identical to the check v_fuzz_coverage uses.
  -- A run is unmeasured only when ALL three json_extract results are NULL/absent.
  UNION ALL SELECT 'fuzz_runs_without_coverage_measurement',
    (SELECT count(*) FROM fuzz_runs
     WHERE skip_reason IS NULL
       AND TRY_CAST(json_extract_string(coverage_json, '$.edges')             AS BIGINT) IS NULL
       AND TRY_CAST(json_extract_string(coverage_json, '$.blocks')            AS BIGINT) IS NULL
       AND TRY_CAST(json_extract_string(coverage_json, '$.function_coverage') AS DOUBLE) IS NULL),
    'a fuzz_runs row that RAN (skip_reason IS NULL) records no coverage measurement in coverage_json (none of edges/blocks/function_coverage present as extractable values) — coverage was never measured for an executed fuzz run (RED; the dynamic mirror of slices_without_codebase_coverage — count-free, no %-floor)'
  UNION ALL SELECT 'fuzz_skips_unrecorded',
    (SELECT count(*) FROM agent_steps st
     JOIN strategies s ON s.id = st.strategy_id AND s.name = 'boundary_fuzz_lane'
     WHERE st.status IN ('success','exhausted','failed','timed_out','skipped')
       AND NOT EXISTS (SELECT 1 FROM fuzz_runs fr WHERE fr.agent_step_id = st.id)),
    'a boundary_fuzz_lane step that ran or was documented-skipped but emitted NO fuzz_runs row — Phase 1.5 mandatory-attempt accounting gap (RED): every run incl. a skip must record a fuzz_runs row'
  -- Promising-lane feed-forward signal (v0.25 / migration 0025): static-analysis leads not
  -- yet carried into a later round as a lane. SIGNAL, not auto-red — the latest round always
  -- has unconsumed directions by construction; inspect via v_promising_lanes_ranked.
  UNION ALL SELECT 'promising_lanes_unpromoted',
    (SELECT count(*) FROM promising_lanes WHERE promoted_to_round_id IS NULL),
    'static-analysis leads not yet carried into a later round as a lane — SIGNAL not auto-red (expected on the latest round); inspect via v_promising_lanes_ranked'
) t
ORDER BY metric;

INSERT INTO schema_version (version, description)
VALUES (25, 'promising-lane static-analysis feed-forward (v0.38.0): promising_lanes table — opportunistic, non-mandatory side-output any DuckDB-backed static lane (Phase 1 Hunt + Agent Sweep S2 + Phase 0.75 code-reading + Phase L3/L4) MAY emit, modeling a POSITIVE lead (a concrete next-round investigation direction) distinct from a methodology_blind_spots gap (negative) and a suspicious_points region hypothesis. NK (target_id, proposed_lane_kind, region_hash) → lane_hash UNIQUE dedup/merge (ON CONFLICT bumps dedup_cluster_size); proposed_lane_kind/vuln_class free TEXT, severity NULL-permitting CHECK; raw promise factors stored (novelty/reachability_prior/ledger_history_factor/severity), composite NEVER stored. pl_severity_weight macro + v_promising_lanes_ranked read-time ranking (promise = novelty × est_severity × reachability_prior × ledger_history_factor, COALESCE-neutral; unconsumed→not-already-covered→promise DESC→dedup→created_at). overlaps_sp_id/overlaps_finding_id read-time already_covered flag + down-rank (never delete). promoted_to_round_id feed-forward closure. Feed-forward only (the methodology_blind_spots action model): NOT a mandatory lane, NOT in v_required_deep_lanes, NO blocking gate, NO v_phase_status row; only v_coverage.promising_lanes_unpromoted inspect-SIGNAL. Round-entry fetch (10) in round-feedforward.md.')
ON CONFLICT DO NOTHING;
