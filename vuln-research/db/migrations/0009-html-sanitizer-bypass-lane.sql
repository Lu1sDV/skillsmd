-- vuln-research migration 0009 — HTML sanitizer bypass lane
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: enriches the defense / bypass model for the new Phase-0.75 DEEP lane
-- `html_sanitizer_bypass_lane` and adds the per-sanitizer-run aggregate table
-- `sanitizer_bypass_runs`. Also registers strategy id 11 and the schema_version
-- row (version 9, after 0008-fuzz-artifacts-and-strategy-v2). Purely additive —
-- no existing column / CHECK / FK is altered.
--
-- CHECK-DIVERGENCE NOTE (mirrors the 0007 agent_steps.status precedent): the new
-- categorical columns on `defenses` and `defense_bypasses` are added here as
-- plain `ADD COLUMN IF NOT EXISTS ... TEXT` with NO CHECK. DuckDB cannot
-- `ADD COLUMN ... CHECK` nor `ADD CONSTRAINT` after the fact, and both tables are
-- FK-referenced (cannot be dropped + rebuilt). So the canonical fresh-DB path in
-- db/schema.sql carries the tightening CHECKs (all NULL-permitting,
-- `col IS NULL OR col IN (...)`), while this upgrade path stores the same columns
-- untyped. The categorical vocabularies are enforced app-side (engine + the
-- orchestrator's pre-flush validation) on the upgrade path. See the 0001-initial
-- NOTE block (strategies.name / severity / status loosenings) for the same
-- byte-alignment rationale.
--
-- ORDERING: defenses, defense_bypasses, targets, agent_steps and round_ledger are
-- all created by 0001, so the ALTERs and the new table resolve cleanly when this
-- is applied last. db/schema.sql carries the identical (CHECK-bearing) defs for
-- fresh DBs.
--
-- v_required_deep_lanes: this migration's CREATE OR REPLACE VIEW rewrites the
-- prior 8-row roster from 0007 (which had no html_sanitizer_bypass_lane) so the
-- DEEP gate begins enforcing the new mandatory lane. db/schema.sql carries the
-- identical 9-row definition for fresh DBs.

------------------------------------------------------------
-- defenses — fine-grained sanitizer characterization (8 cols).
-- mechanism is a fine-grained SUPERSET label, NOT a widening of the coarse
-- defense_type 3-way CHECK (which is left untouched).
-- No CHECK on this upgrade path (see CHECK-DIVERGENCE NOTE); db/schema.sql
-- enforces the categorical vocabularies.
------------------------------------------------------------
ALTER TABLE defenses ADD COLUMN IF NOT EXISTS mechanism TEXT;
ALTER TABLE defenses ADD COLUMN IF NOT EXISTS enforcement_mode TEXT;
ALTER TABLE defenses ADD COLUMN IF NOT EXISTS input_context TEXT;
ALTER TABLE defenses ADD COLUMN IF NOT EXISTS fail_mode TEXT;
ALTER TABLE defenses ADD COLUMN IF NOT EXISTS library_origin TEXT;
ALTER TABLE defenses ADD COLUMN IF NOT EXISTS reachability TEXT;
ALTER TABLE defenses ADD COLUMN IF NOT EXISTS discovery_method TEXT;
ALTER TABLE defenses ADD COLUMN IF NOT EXISTS discovery_confidence REAL;

------------------------------------------------------------
-- defense_bypasses — sanitizer-bypass classification (6 cols).
-- sink_reached / capability / injection_context / input_vector are closed enums
-- (CHECK lives in db/schema.sql); payload_technique / corpus_category are
-- free-vocab TEXT (no CHECK on either path) — the vocabulary grows as the corpus
-- is augmented (CHECK-vs-free-TEXT doctrine, db/schema.sql header).
------------------------------------------------------------
ALTER TABLE defense_bypasses ADD COLUMN IF NOT EXISTS sink_reached TEXT;
ALTER TABLE defense_bypasses ADD COLUMN IF NOT EXISTS capability TEXT;
ALTER TABLE defense_bypasses ADD COLUMN IF NOT EXISTS payload_technique TEXT;
ALTER TABLE defense_bypasses ADD COLUMN IF NOT EXISTS corpus_category TEXT;
ALTER TABLE defense_bypasses ADD COLUMN IF NOT EXISTS injection_context TEXT;
ALTER TABLE defense_bypasses ADD COLUMN IF NOT EXISTS input_vector TEXT;

------------------------------------------------------------
-- sanitizer_bypass_runs — one aggregate row per sanitizer (defense) corpus run
-- of the html_sanitizer_bypass_lane. Fresh table, so inline CHECK is fine here.
-- 3-valued run_verdict: 'bypassed' (>=1 payload reached a live sink),
-- 'clean' (full corpus, 0 hits — first-class stored robustness result),
-- 'inconclusive' (isolate/harness error; inconclusive_reason set).
-- emitted_bypass_ids: JSON array of defense_bypasses.id rows this run produced.
-- injection_contexts_json: JSON of which injection contexts were exercised.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sanitizer_bypass_runs (
  id INTEGER PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES targets(id),
  defense_id INTEGER NOT NULL REFERENCES defenses(id),
  agent_step_id INTEGER NOT NULL REFERENCES agent_steps(id),
  run_verdict TEXT NOT NULL
    CHECK (run_verdict IN ('bypassed', 'clean', 'inconclusive')),
  corpus_version TEXT,
  payloads_total INTEGER,
  payloads_bypassed INTEGER,
  runtime_ms INTEGER,
  injection_contexts_json TEXT,
  inconclusive_reason TEXT,
  emitted_bypass_ids TEXT,
  round_id INTEGER REFERENCES round_ledger(id),
  created_at TIMESTAMP,
  sanitizer_run_hash TEXT NOT NULL,
  UNIQUE (sanitizer_run_hash)
);

------------------------------------------------------------
-- Strategy registration (id 11 — next free non-seed id; seeds are 1..10).
------------------------------------------------------------
INSERT INTO strategies (id, name, description, version) VALUES
  (11, 'html_sanitizer_bypass_lane', 'Phase 0.75 (MEDIUM+DEEP) defense pre-break lane targeting HTML/markdown sanitizers. Discovers + characterizes sanitizer defenses (union of reuse / pattern-sweep / AST+taint), then runs the agnostic html-sanitizer-bypass engine (PHP isolate of REAL target sanitize() + jsdom oracle) over a fixed/versioned corpus; per-payload sink hits land in defense_bypasses, the 3-valued per-sanitizer verdict lands in sanitizer_bypass_runs.', 1)
ON CONFLICT (name) DO NOTHING;

------------------------------------------------------------
-- DEEP gate roster — add html_sanitizer_bypass_lane to the mandatory Phase-0.75
-- pre-break roster. CREATE OR REPLACE VIEW is idempotent and FK-free, so this is
-- clean to re-apply (mirrors how 0007 carries the view). The canonical
-- db/schema.sql carries the identical 9-row definition. MEDIUM tier-gating for
-- this lane lives in the tier table + prose (no net-new MEDIUM gate view), per D3.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_required_deep_lanes AS
SELECT * FROM (VALUES
  ('forward_slice_lane',                'phase1_hunt'),
  ('backward_sink_lane',                'phase1_hunt'),
  ('critical_function_dataflow_lane',   'phase1_hunt'),
  ('defense_base_lane',                 'phase0_75_prebreak'),
  ('defense_context_verification_lane', 'phase0_75_prebreak'),
  ('isolation_fuzz_lane',               'phase0_75_prebreak'),
  ('boundary_fuzz_lane',                'phase1_5_fuzz'),
  ('html_sanitizer_bypass_lane',        'phase0_75_prebreak'),
  ('report_critic',                     'phase5_report')
) AS t(lane_name, phase);

INSERT INTO schema_version (version, description)
VALUES (9, 'html sanitizer bypass lane: defenses/defense_bypasses sanitizer columns + sanitizer_bypass_runs table + strategy 11')
ON CONFLICT DO NOTHING;
