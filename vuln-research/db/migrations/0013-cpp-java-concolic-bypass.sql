-- vuln-research migration 0013 — C5 C/C++/Java concolic guard-evasion lane
--
-- Forward-only, idempotent. Safe to re-apply.
--
-- SCOPE: adds the mandatory Phase-0.75 (Defense Pre-Break) DEEP lane
-- `concolic_bypass_lane` (id 14 — next free after 1..13). C/C++/Java only. It
-- enumerates dangerous functions guarded by a regex/sanitizer (reusing `defenses`
-- + `critical_fn_reach` + AST/CPG), drives the TARGET's own build + instrumentation
-- (C/C++: LLVM bitcode for KLEE/SymCC; Java: bytecode + driver for a JVM concolic
-- engine), and runs directed symbolic+concolic execution that SOLVES the guard's
-- path constraints to synthesize an input which passes the guard yet reaches the
-- target function. That solved concrete input IS the bypass: replayed through the
-- instrumented build it passes the guard AND reaches the target fn.
--
-- OUTPUT REUSES EXISTING TABLES (no new table): a confirmed bypass lands in
-- defense_bypasses with reproduced=TRUE and the solver's path-constraint log stored
-- in the existing exhaustion_log column as exhaustion evidence; reachability lands
-- in critical_fn_reach (existing). We add only TWO categorical label columns to
-- defense_bypasses to record the concolic specifics (technique family + solver
-- engine) — following exactly how 0009 added columns to defense_bypasses
-- (ADD COLUMN IF NOT EXISTS ... TEXT, NO CHECK on the upgrade path; db/schema.sql
-- carries the NULL-permitting CHECK for fresh DBs).
--
-- CHECK-DIVERGENCE NOTE (mirrors 0009): the two new defense_bypasses columns are
-- added here as plain ADD COLUMN ... TEXT with NO CHECK (DuckDB cannot ADD a CHECK
-- post-hoc and defense_bypasses is FK-referenced so it cannot be dropped+rebuilt).
-- db/schema.sql carries the tightening NULL-permitting CHECK; the vocab is enforced
-- app-side on the upgrade path. concolic_solver is the closed engine vocab; the
-- existing free-TEXT payload_technique already covers the human technique label, so
-- no second free-vocab column is added.
--
-- ORDERING: defense_bypasses, critical_fn_reach, strategies, agent_steps are
-- created by 0001/0002; v_required_deep_lanes by 0007. All resolve cleanly when
-- this is applied last. db/schema.sql carries identical defs for fresh DBs.

------------------------------------------------------------
-- defense_bypasses — concolic specifics (2 cols). concolic_solver is a closed
-- engine enum (NULL-permitting CHECK in db/schema.sql; NO CHECK here). guard_kind
-- records what kind of guard the solver evaded. No CHECK on this upgrade path.
------------------------------------------------------------
ALTER TABLE defense_bypasses ADD COLUMN IF NOT EXISTS concolic_solver TEXT;
ALTER TABLE defense_bypasses ADD COLUMN IF NOT EXISTS guard_kind TEXT;

------------------------------------------------------------
-- Strategy registration (id 14 — next free after the 1..13 block).
------------------------------------------------------------
INSERT INTO strategies (id, name, description, version) VALUES
  (14, 'concolic_bypass_lane', 'Phase 0.75 (DEEP) C/C++/Java defense pre-break lane. Enumerates dangerous functions guarded by a regex/sanitizer (reusing defenses + critical_fn_reach + AST/CPG), drives the target''s own build + instrumentation (C/C++: LLVM bitcode for KLEE/SymCC; Java: bytecode + driver for a JVM concolic engine), then runs directed symbolic+concolic execution to SOLVE the guard''s path constraints and synthesize a guard-passing input that reaches the target fn. The solved concrete input is the bypass: replayed through the instrumented build it passes the guard AND reaches the target fn -> defense_bypasses(reproduced=TRUE) with the solver''s path-constraint log in exhaustion_log; reachability -> critical_fn_reach. Skip-with-reason only if the build genuinely can''t be produced or no concolic tool exists for the stack. Distinct from isolation_fuzz_lane by technique (constraint-solving, not mutation).', 1)
ON CONFLICT (name) DO NOTHING;

------------------------------------------------------------
-- DEEP gate roster — add concolic_bypass_lane to the mandatory Phase-0.75
-- pre-break roster (alongside isolation_fuzz_lane / html_sanitizer_bypass_lane).
-- CREATE OR REPLACE VIEW is idempotent + FK-free. db/schema.sql carries the
-- identical 12-row definition. Preserves the Phase-1.4 dual seed lanes added in 0011.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_required_deep_lanes AS
SELECT * FROM (VALUES
  ('forward_slice_lane',                'phase1_hunt'),
  ('backward_sink_lane',                'phase1_hunt'),
  ('critical_function_dataflow_lane',   'phase1_hunt'),
  ('defense_base_lane',                 'phase0_75_prebreak'),
  ('defense_context_verification_lane', 'phase0_75_prebreak'),
  ('isolation_fuzz_lane',               'phase0_75_prebreak'),
  ('html_sanitizer_bypass_lane',        'phase0_75_prebreak'),
  ('concolic_bypass_lane',              'phase0_75_prebreak'),
  ('llm_seed_corpus_lane_a',            'phase1_4_seed'),
  ('llm_seed_corpus_lane_b',            'phase1_4_seed'),
  ('boundary_fuzz_lane',                'phase1_5_fuzz'),
  ('report_critic',                     'phase5_report')
) AS t(lane_name, phase);

INSERT INTO schema_version (version, description)
VALUES (13, 'C/C++/Java concolic guard-evasion lane (Phase 0.75): strategy 14 + defense_bypasses concolic_solver/guard_kind columns + v_required_deep_lanes roster')
ON CONFLICT DO NOTHING;
