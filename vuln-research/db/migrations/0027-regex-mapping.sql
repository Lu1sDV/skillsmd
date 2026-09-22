-- vuln-research migration 0027 — mandatory whole-tree regex mapping
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: every regex in the in-scope tree MUST be mapped, because downstream lanes find
-- bypasses for and fuzz them (ReDoS, validator/filter evasion). Regex mapping is folded into
-- preliminary_enumeration_lane as its 5th enumerated category — whole-tree, finding-agnostic,
-- INVENTORY-ONLY (NO ReDoS / bypass / fuzz analysis at map time; that is deferred to the
-- defense-bypass and fuzz lanes that consume this table). Two additive pieces:
--   (1) regexes — NEW table. One row per (target, file, line, pattern_src) regex literal /
--       constructor found anywhere in the tree. role is the CLOSED 7-value classification
--       (guard|validator|filter — defense-shaped; parser|extractor|router — structural; other).
--       defense_id is a NULLABLE FK set when the regex IS a defense regex (links to defenses).
--       language / pattern flags are OPEN free TEXT (per-language detection vocab). Large
--       pattern bodies sidecar (pattern_sidecar_path, the A1 rule).
--   (2) v_coverage — restate (CREATE OR REPLACE; idempotent, FK-free): append the NEW
--       'regexes_unmapped' HARD-RED gate. Unlike promising_lanes_unpromoted (a SIGNAL), regex
--       mapping is MANDATORY, so this is a hard contradiction gate: if preliminary_enumeration_lane
--       RAN (>=1 success/exhausted step) but ZERO regexes rows exist for the target, the
--       whole-tree regex inventory was skipped => 1 (RED). Count-free EXISTS/NOT-EXISTS — no
--       %-floor, no magic constant — mirroring slices_without_codebase_coverage's gate SHAPE but
--       RED-on-absence (mandatory) rather than SIGNAL. The gate cannot fire before the
--       enumeration lane runs (a pre-enumeration DB is never falsely red).
--
-- FRESH-TABLE NOTE (the 0010/0015/0017/0018/0025 pattern): regexes is a NEW table, so its inline
-- NOT NULL / CHECK / UNIQUE / FK constraints are safe on this upgrade path and match db/schema.sql
-- byte-for-byte. No existing CHECK is widened.
--
-- ORDERING: targets (0001) and defenses (0001) exist earlier, so regexes.target_id /
-- regexes.defense_id resolve when this is applied. v_coverage was created earlier (0006) and last
-- restated by 0025; CREATE OR REPLACE VIEW is idempotent + FK-free (DuckDB replaces the whole
-- body), so the full body is restated here. db/schema.sql carries the identical definitions
-- (schema_mirror parity).

------------------------------------------------------------
-- (1) regexes (schema v27) — whole-tree regex inventory. See db/schema.sql for full rationale.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS regexes (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  pattern_src TEXT NOT NULL,                                -- the raw regex source text
  pattern_sidecar_path TEXT,                               -- set when pattern_src > 16 KB (A1)
  flags TEXT,                                               -- i/m/s/g/x... as written
  file TEXT NOT NULL,
  symbol_path TEXT,
  line INTEGER,
  language TEXT,                                            -- OPEN free TEXT (per-language detection vocab)
  role TEXT NOT NULL                                        -- CLOSED 7-value classification
    CHECK (role IN ('guard', 'validator', 'filter', 'parser', 'extractor', 'router', 'other')),
  defense_id INTEGER REFERENCES defenses(id),              -- nullable: set when the regex IS a defense regex
  created_at TIMESTAMP NOT NULL,
  UNIQUE (target_id, file, line, pattern_src)              -- NK: one row per (target, location, pattern)
);

------------------------------------------------------------
-- (2) v_coverage — append the regexes_unmapped HARD-RED gate. Full body restated; all branches
-- through promising_lanes_unpromoted are byte-identical to 0025 / db/schema.sql.
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
  -- regexes_unmapped (v0.39.0 / migration 0027): C3 mandatory whole-tree regex-mapping gate.
  -- HARD-RED (NOT a SIGNAL like promising_lanes_unpromoted): if preliminary_enumeration_lane RAN
  -- (>=1 success/exhausted step) but ZERO regexes rows exist for the target, the mandatory
  -- whole-tree regex inventory was skipped => 1 (RED). Count-free EXISTS/NOT-EXISTS — no %-floor,
  -- no magic constant — mirroring slices_without_codebase_coverage's SHAPE but RED-on-absence
  -- (mandatory) not SIGNAL. The gate cannot fire before the enumeration lane runs.
  UNION ALL SELECT 'regexes_unmapped',
    CASE WHEN EXISTS (
           SELECT 1 FROM agent_steps st
           JOIN strategies s ON s.id = st.strategy_id AND s.name = 'preliminary_enumeration_lane'
           WHERE st.status IN ('success','exhausted'))
          AND NOT EXISTS (SELECT 1 FROM regexes)
         THEN 1 ELSE 0 END,
    'preliminary_enumeration_lane ran but no regexes rows — mandatory whole-tree regex inventory skipped (RED; the C3 completeness gate, count-free, no %-floor; unlike the promising_lanes_unpromoted SIGNAL this is mandatory)'
) t
ORDER BY metric;

INSERT INTO schema_version (version, description)
VALUES (27, 'mandatory regex mapping (v0.39.0): regexes table — whole-tree, finding-agnostic 5th enumerated category emitted by preliminary_enumeration_lane (pattern_src/flags/file/symbol_path/line/language + role CLOSED 7-value CHECK guard|validator|filter|parser|extractor|router|other + defense_id nullable FK to defenses; NK target_id+file+line+pattern_src). INVENTORY-ONLY: ReDoS/bypass/fuzz analysis is DEFERRED to the defense-bypass + fuzz lanes that consume this table. NEW HARD-RED v_coverage.regexes_unmapped gate: preliminary_enumeration_lane ran (>=1 success/exhausted step) but zero regexes rows => RED (count-free EXISTS/NOT-EXISTS, no %-floor; mandatory, unlike the promising_lanes_unpromoted SIGNAL; the slices_without_codebase_coverage gate shape but RED-on-absence). preliminary_enumeration_lane coverage_json gains regexes_found + the regex-construction patterns_run[]. MANDATORY "every single regex must be mapped" clause added to bypass-catalogue / pipeline-architecture Bypass Doctrine / SKILL.md.')
ON CONFLICT DO NOTHING;
