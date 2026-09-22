-- schema.sql — generated mirror of the canonical db/schema.sql; keeps the harness binary self-contained.
-- Go's //go:embed cannot reach paths outside the package directory, so db/schema.sql is copied here verbatim.
-- Do NOT hand-edit. Regenerate from repo root after editing db/schema.sql:
--   { sed -n '1,4p' db/harness/schema.sql; cat db/schema.sql; } > /tmp/vrschema && mv /tmp/vrschema db/harness/schema.sql
-- vuln-research DuckDB schema (v2)
-- Canonical source: references/v2/pipeline-architecture.md
-- Conventions:
--   * Every CREATE uses IF NOT EXISTS (idempotent).
--   * Natural keys (NK) enforced via UNIQUE constraints.
--   * ENUM-style fields enforced via CHECK (col IN (...)).
-- CHECK-enum vs free-TEXT doctrine: use a CHECK(... IN (...)) enum ONLY for a
-- closed, low-cardinality vocabulary the pipeline is guaranteed to stay within
-- (e.g. confirmation_status, reach_status, obs_kind). For label spaces that are
-- open or evolve as lanes are added (strategy/lane names, free-form stage labels,
-- richly-worded severities from external scorers), prefer free TEXT plus a
-- documented canonical set and, where useful, a seed-row insert — mirroring the
-- existing skip_reason precedent. A too-tight CHECK has crashed mid-run flushes
-- and forced DB rebuilds; loosen toward free TEXT when in doubt.
--   * gr_findings is the canonical findings table; confirmed_vulns is a VIEW (R1).
--   * payload_sidecar_path: set when payload > 16 KB (A1); points into db/sidecars/<hash>,
--     where <hash> is the content SHA-256 ONLY — never a symbol_path / evidence_path /
--     payload-derived name. Those are attacker-influenced and would allow a write to
--     traverse out of db/sidecars/. Same rule for body_sidecar_path (agent_observations).
--   * Table order: dependencies created before referencers.

------------------------------------------------------------
-- Schema version (B1)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS schema_version (
  version INTEGER PRIMARY KEY,
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  description TEXT
);

INSERT INTO schema_version (version, description)
VALUES
  (1, 'initial v2-consolidated schema'),
  (2, 'critical-function registry, forward data-flow, rich logging, bypass feed-forward'),
  (3, 'fuzzing lane (Phase 1.5): fuzz_runs per-run config, coverage, mandatory-attempt accounting'),
  (4, 'eval harness (Tier 1): eval_corpus / eval_run / eval_result'),
  (5, 'knowledge architecture: finding_sightings / recurrence_counter / weakness_classes / call_edges / scoring_config / mutation_log + ranking/acceptance/history views'),
  (6, 'coverage views: v_phase_status + v_coverage'),
  (7, 'lane-coverage gate: v_required_deep_lanes + v_lane_coverage; agent_steps.status += scheduled,skipped'),
  (8, 'fuzz artifacts: resumable seed/corpus/checkpoint storage + boundary_fuzz_lane v2 strategy seed'),
  (9, 'html sanitizer bypass lane: defenses/defense_bypasses sanitizer columns + sanitizer_bypass_runs table + strategy 11'),
  (10, 'suspicious point screening tier: SP tables + EAV factors + sp_factor_config + read-time percentile-rank score view + factor-coverage view'),
  (11, 'dual LLM seed-corpus lanes (Phase 1.4): strategies 12/13 + run_config knob table + v_required_deep_lanes roster'),
  (12, 'per-file vuln-probability rating (Phase 0): file_vuln_ratings companion table (phase0_priorities CHECK is closed) + read-time v_file_vuln_ranked order-only view'),
  (13, 'C/C++/Java concolic guard-evasion lane (Phase 0.75): strategy 14 + defense_bypasses concolic_solver/guard_kind columns + v_required_deep_lanes roster'),
  (14, 'preliminary-inventory completeness: v_coverage contradiction signals (guards/validator/dangerous-sink) + preliminary_enumeration_lane strategy 15 at phase0_decompose in v_required_deep_lanes'),
  (15, 'LLMxCPG: execution_path slice_kind (schema.sql) + query_attempts table for CPGQL query-gen feedback loop'),
  (16, 'completion-gate context + recon-floor signals: v_observation_coverage per-phase view + v_coverage metrics executed_steps_without_observation and defenses_below_validator_cf_floor'),
  (17, 'slice-end codebase slice-coverage: cpg_slice_coverage table (raw + frontier denominators) + v_cpg_slice_coverage + non-mandatory cpg_coverage strategy (id 16) + v_coverage.slices_without_codebase_coverage gate'),
  (18, 'post-Hunt methodology blind-spot sweep (Phase 1.6): methodology_blind_spots table (gap_class process|coverage, content-hash union-dedup merge, promoted_to_round_id feed-forward) + v_methodology_blindspots_ranked + two mandatory DEEP lanes (ids 17/18) under phase1_6_blindspot + v_phase_status row + v_coverage.methodology_blindspots_unpromoted signal'),
  (19, 'logic_guard defense_type (authz/complex-logic escalation: cross_user_object_ref, missing_function_authz, broken_state_machine, confused_deputy_param_tamper) — canonical db/schema.sql carries the widened 4-way defenses.defense_type CHECK; DuckDB cannot widen the FK-referenced CHECK on the upgrade path (enforced app-side, per the 0009 precedent); catalogue widened separately at catalogue_version 2'),
  (20, 'per-target memory & recall (v0.27.0): v_fact_hitscore composite hit-score ranking over agent_observations+recurrence_counter+gr_findings+defense_bypasses + v_fact_similar trigram-Jaccard approximate-recall view + scoring_config recurrence-scope weight rows (w_rec/w_outcome/w_reuse/w_conf/approx_recall_floor) + fetch(9) refutations feed-forward'),
  (21, 'Perpetual Loop mode: self-firing unbounded discovery loop (DMN generate → Salience promote → Executive pursue → Confirm → Learn) as a thin reuse layer — strategies.created_at/updated_at (guarded-upsert seed; DuckDB v1.1.3 has no triggers) + v_promise_ranked read-time salience view (promise = novelty × est_severity × reachability_prior × ledger_history_factor, derived from existing columns, no new table) + four NON-MANDATORY strategy rows (ids 19–22, absent from v_required_deep_lanes per the cpg_coverage precedent). Executive REUSES Phase 2 Confirm + L5; Learn IS round_ledger + recurrence_counter.'),
  (22, 'fuzz-coverage aim & tracking (v0.29.0): v_coverage gates fuzz_runs_without_coverage_measurement (a ran fuzz_runs row whose coverage_json records no edges/blocks/function_coverage — the dynamic mirror of slices_without_codebase_coverage) and fuzz_skips_unrecorded (a boundary_fuzz_lane step that ran or was documented-skipped but emitted no fuzz_runs row) + v_fuzz_coverage read-time per-run code-coverage rollup (edges/function_coverage_pct/uncovered-frontier extracted from coverage_json across round_id, never stored) + fuzzing-lane §8 promotes a coverage measurement and uncovered_frontier[] to REQUIRED on a ran row, with a plateau+escalation-exhausted saturation criterion (no magic %-floor, mirroring cpg_slice_coverage)'),
  (23, 'audit hardening (v0.30.0): (1) v_current_round helper view + round-scoped v_lane_coverage + v_observation_coverage — gates evaluate only the CURRENT round so round 2+ cannot be permanently satisfied by round 1 work; (2) lanes_stuck_running gate in v_lane_coverage + v_coverage — a lane stuck in status=running (OOM/crash) surfaces as explicit failure, not ok; (3) confirmed_without_refutation gate in v_coverage — mirrors confirmed_without_critic, enforcing the refute-before-confirm mandate mechanically; (4) fuzz_runs_without_coverage_measurement fixed to use json_extract value-presence instead of gameable NOT LIKE substring; (5) v_phase_status phase1_4_seed row + phase vocab unified to phase0_75_prebreak across v_phase_status/v_required_deep_lanes/v_observation_coverage'),
  (24, 'FuzzGPT history-driven lane (v0.36.0): new MANDATORY DEEP strategy fuzzgpt_history_lane (id 24) at phase1_4_seed in v_required_deep_lanes — history-driven LLM fuzzing (FuzzGPT, Deng et al., arXiv:2304.02014) that COEXISTS with the dual llm_seed_corpus_lane_a/b (does not replace them). Generator mode emits fuzz_artifacts(seed_initial) feeding boundary_fuzz_lane; a target-agnostic differential-oracle sub-mode emits QUARANTINED gr_findings(finding_kind=''differential_divergence'', severity NULL, confirmation_status=''unconfirmed'') kept OUT of the HIGH/MED/LOW severity rankings until triage promotes them to ''candidate''. confirmation_status CHECK widened to add ''unconfirmed'' (closed-vocab enum member; canonical fresh-DB schema carries the 4-value CHECK; DuckDB cannot widen the inline CHECK on the upgrade path so the migration enforces it app-side per the 0019 precedent and inserts no unconfirmed row). The N/A rankings-classification is the documented free-TEXT/NULL state (finding_kind free-TEXT + severity NULL), NOT a new severity enum value. v_coverage.lanes_stuck_running inlined lane list += fuzzgpt_history_lane.'),
  (25, 'promising-lane static-analysis feed-forward (v0.38.0): promising_lanes table — opportunistic, non-mandatory side-output any DuckDB-backed static lane (Phase 1 Hunt + Agent Sweep S2 + Phase 0.75 code-reading + Phase L3/L4) MAY emit, modeling a POSITIVE lead (a concrete next-round investigation direction) distinct from a methodology_blind_spots gap (negative) and a suspicious_points region hypothesis. NK (target_id, proposed_lane_kind, region_hash) → lane_hash UNIQUE dedup/merge (ON CONFLICT bumps dedup_cluster_size); proposed_lane_kind/vuln_class free TEXT, severity NULL-permitting CHECK; raw promise factors stored (novelty/reachability_prior/ledger_history_factor/severity), composite NEVER stored. pl_severity_weight macro + v_promising_lanes_ranked read-time ranking (promise = novelty × est_severity × reachability_prior × ledger_history_factor, COALESCE-neutral; unconsumed→not-already-covered→promise DESC→dedup→created_at). overlaps_sp_id/overlaps_finding_id read-time already_covered flag + down-rank (never delete). promoted_to_round_id feed-forward closure. Feed-forward only (the methodology_blind_spots action model): NOT a mandatory lane, NOT in v_required_deep_lanes, NO blocking gate, NO v_phase_status row; only v_coverage.promising_lanes_unpromoted inspect-SIGNAL. Round-entry fetch (10) in round-feedforward.md.'),
  (26, 'prior-art intake (v0.39.0): cves + writeups tables (target-scoped CVE/advisory + writeup inventory for the bug-bounty-mode Phase L-1 prior_art_intake_lane, strategy 25, MANDATORY when a scope is provided) + promising_lanes.derived_from_cve_id/derived_from_writeup_id nullable provenance FK columns (ADD COLUMN ... INTEGER on the upgrade path with NO inline FK per the 0009/0013 precedent; canonical schema.sql carries the enforced REFERENCES, pre-validated in put.go fkRefs). cves.source CLOSED vocab (nvd|ghsa|osv|exploit-db) CHECK, NK (target_id,cve_id,source); writeups NK (target_id,url), nullable related_cve_id FK. The lane DISTILS prior art into promising_lanes consumed by round 1 via round-entry fetch (10); distillation-first per-source provenance (coverage_json sources_queried[]+counts), NOT "store every CVE". prior_art_intake_lane appended to v_required_deep_lanes under NEW phase_l1_prior_art; v_phase_status gains the phase_l1_prior_art row (rows_populated = cves+writeups) at phase_seq -1. Documented-skip fallback (agent_steps.status=skipped + termination_reason) when no scope/network — the Phase L0 precedent — satisfies the roster gate. No new v_coverage gate (distillation-first proof lives in coverage_json, not a blocking metric).'),
  (27, 'mandatory regex mapping (v0.39.0): regexes table — whole-tree, finding-agnostic 5th enumerated category emitted by preliminary_enumeration_lane (pattern_src/flags/file/symbol_path/line/language + role CLOSED 7-value CHECK guard|validator|filter|parser|extractor|router|other + defense_id nullable FK to defenses; NK target_id+file+line+pattern_src). INVENTORY-ONLY: ReDoS/bypass/fuzz analysis is DEFERRED to the defense-bypass + fuzz lanes that consume this table. NEW HARD-RED v_coverage.regexes_unmapped gate: preliminary_enumeration_lane ran (>=1 success/exhausted step) but zero regexes rows => RED (count-free EXISTS/NOT-EXISTS, no %-floor; mandatory, unlike the promising_lanes_unpromoted SIGNAL; the slices_without_codebase_coverage gate shape but RED-on-absence). preliminary_enumeration_lane coverage_json gains regexes_found + the regex-construction patterns_run[]. MANDATORY "every single regex must be mapped" clause added to bypass-catalogue / pipeline-architecture Bypass Doctrine / SKILL.md.'),
  (28, 'overlooked-lane self-audit (v0.39.0): NEW DEEP-only MANDATORY meta-lane overlooked_lane_audit_lane (strategy 26) runs LAST after Phase 1.6. NO DDL — reuses promising_lanes/agent_steps/strategies/v_coverage/v_required_deep_lanes. Two self-questions (generative "more high-yield lanes?" + audit "erroneously ignored a lane?") answered via a DB-grounded TRIPLE REFERENCE (roster-vs-agent_steps diff; emitted-but-unpromoted promising_lanes; v_coverage/enumeration signals + optional open methodology_blind_spots). ALWAYS emits a promising_lanes row per confirmed overlooked/ignored lane; cap-gated SPAWNS top-N-by-promise IN-RUN up to cap = the existing fetch-budgets.yml promising_lanes row_cap × tier multiplier (NO new constant); overflow feeds forward; acting stamps promoted_to_round_id (the in-run spawn is the bounded exception to feed-forward-only). Appended to v_required_deep_lanes under NEW phase phase1_7_self_audit; v_phase_status gains the phase1_7_self_audit row (rows_populated = executed overlooked_lane_audit_lane steps) at phase_seq 6.5 (between blindspot and confirm).'),
  (29, 'justification gate + DB hardening (v0.40.0, migration 0029 / TIER 2 T2-01..T2-16): the completion gate moves from PROCESS-coverage to OUTCOME-justification. NEW TABLES (each with its own CREATE SEQUENCE + DEFAULT nextval + CHECK(id>0)): impact_proofs (T2-07, the CONSUMER-HARM ledger — consumer_symbol/harm_class/reachability_evidence_ref/proven_reachability/mechanism_cap/severity_basis; a sink reached is NOT a consumer harmed), closures (T2-08, the hard pre-spawn barrier — surface_hash/closure_kind dead_end|exhausted|refuted_class/closed_in_round/reopen_condition, consulted by Phase 0.5 roster materialization), sp_spawn_decisions (T2-09, makes the SP ranking a CONSUMED artifact — sp_id/round_id/rank_at_decision/spawned/decided_at). NEW VIEWS: v_promotion_coverage (T2-01, per confirmed finding emit JUSTIFIED only if refutation overcome + non-null severity + critic eligibility=OK + backing SP with non-null oracle & gate_ok, else UNJUSTIFIED; done predicate = 0 UNJUSTIFIED), v_phase_status REDEFINED to a tri-state phase_status not_run|incomplete|complete ANDing each phase row-count with its own gap metric (T2-02, ran kept for back-compat), v_justification_coverage (T2-07, red-flags any confirmed finding lacking an impact_proofs row), v_sp_oracle_coverage (T2-06 HARD-RED, a kept SP with an applicable oracle and no recorded oracle execution => RED), v_invariant_promotion_coverage (T2-14 HARD-RED, RED while any reusable high-confidence invariant observation has neither a triage-invariants.md promotion entry nor a promotion_skipped reason), v_empty_result (T2-15, the EMPTY_RESULT terminal — confirmed=0 AND candidate=0 AND all high-recall lanes ran: a named verdict, not red). NEW v_coverage METRICS: confirmed_without_promotion_provenance (T2-03, confirmed rows with no mutation_log status_transition => RED), ranked_sps_never_consumed (T2-04, gate_ok top-K SP in a round lacking an sp_spawn_decisions row => RED), roster_steps_missing_for_current_round (T2-05, required lanes with no agent_steps row in the current round via the round-keyed sentinel => RED). NEW COLUMNS: gr_findings.confirmation_rigor_tier (T2-12, shallow|independent|reproduced stamped at promotion) + content_fingerprint on every hash-keyed/NK-deduped table (T2-13, sha256 of the semantic row, non-unique, for content-checked dedup). DDL: per-table CREATE SEQUENCE seq_<table> + id DEFAULT nextval (T2-10, removes the COALESCE(MAX(id))+1 silent-drop collision; each table its own id-space) + CHECK(id>0) / CHECK(col IS NULL OR col>0) on every PK and FK (T2-16, kills the magic-zero FK sentinel; unset = NULL not 0). The round-keyed roster sentinel convention (T2-11): the orchestrator materializes one agent_steps row per required lane per round with step_hash = ''plan-roster-<lane>-r<round_id>'' (round_id in the hashed natural key) so a round-2 roster insert cannot ON CONFLICT DO NOTHING against round-1. DuckDB v1.1.3 has NO triggers — these are views/tables/columns/sequences ONLY; enforcement (the vrdb promote / close-step / content-checked-dedup verbs) is the Go harness''s job (TIER 3). All inline CHECKs / DEFAULT nextval are carried by the FRESH-DB schema; migration 0029 adds the same objects forward with the DuckDB-ALTER caveats noted in its header (a fresh v2 DB gets the full inline CHECKs; the upgrade path adds columns/sequences additively and enforces the new CHECKs app-side per the 0009/0019/0024 precedent).')
ON CONFLICT DO NOTHING;

------------------------------------------------------------
-- Targets / sources / sinks (§2.1)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS targets (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  repo_url TEXT NOT NULL,
  commit_sha TEXT NOT NULL,
  language TEXT NOT NULL,
  scanned_at TIMESTAMP NOT NULL,
  UNIQUE (repo_url, commit_sha)
);

------------------------------------------------------------
-- Round ledger (schema v2) — cross-run "rounds" for feed-forward. One row per
-- (target, round, audit_run). A later round reads the prior round's
-- priors/seed/coverage instead of recomputing them, and chains rounds via
-- parent_round_id. See references/v2/round-feedforward.md.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS round_ledger (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  round_no INTEGER NOT NULL,
  audit_run_id TEXT NOT NULL,
  effort_tier TEXT
    CHECK (effort_tier IS NULL OR effort_tier IN ('low', 'medium', 'deep')),
  parent_round_id INTEGER REFERENCES round_ledger(id),
  started_at TIMESTAMP NOT NULL,
  ended_at TIMESTAMP,
  -- JSON summaries the next round reads at entry (references/v2/round-feedforward.md):
  priors_fetched_json TEXT,   -- what was pulled from prior rounds (counts + ids)
  seed_summary_json TEXT,     -- carried-forward bypasses / critical fns / dead-ends
  coverage_carry_json TEXT,   -- slice coverage already achieved -> skip on re-run
  UNIQUE (target_id, round_no, audit_run_id)
);

CREATE TABLE IF NOT EXISTS sources (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  source_kind TEXT NOT NULL,
  symbol_path TEXT NOT NULL,
  evidence_path TEXT,
  evidence_line INTEGER,
  rank_score REAL,
  UNIQUE (target_id, symbol_path, source_kind)
);

CREATE TABLE IF NOT EXISTS sinks (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  sink_category TEXT NOT NULL,
  symbol_path TEXT NOT NULL,
  evidence_path TEXT,
  evidence_line INTEGER,
  rank_score REAL,
  UNIQUE (target_id, symbol_path, sink_category)
);

------------------------------------------------------------
-- Defenses (§2.7, S1) — must precede gr_findings and agent_steps FKs
-- defense_type is one of 4 concrete, stored per-target types:
--   sanitizer_function | blacklist | allowlist  — input-filter defenses (defeat => injection)
--   logic_guard                                 — a complex logical / authorization check
--     whose DEFEAT yields escalation rather than injection: cross-user object access
--     (IDOR/BOLA), missing function-level authz (BFLA), broken workflow/state machines,
--     and confused-deputy / parameter-tampering. The guard IS the access control (e.g.
--     `if (obj.owner_id == current_user)`), so its "bypass" is an authz/logic flaw; Phase
--     0.75 breaks it finding-agnostically like any other defense, and the catalogue carries
--     its families under defense_type='logic_guard' (db/catalogue/bypasses.json).
-- defense_type intentionally excludes 'generic'. Unlike logic_guard (a real per-target
-- guard), 'generic' is a bypass-catalogue-only classification for cross-cutting techniques
-- (type juggling, length manipulation, charset confusion); it is unioned into Stage-A lane
-- queries via `OR defense_type = 'generic'` against the catalogue, never stored as a
-- defenses row.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS defenses (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  defense_type TEXT NOT NULL
    CHECK (defense_type IN ('sanitizer_function', 'blacklist', 'allowlist', 'logic_guard')),
  tier TEXT NOT NULL
    CHECK (tier IN ('tier1', 'tier2')),
  symbol_path TEXT NOT NULL,
  parsed_logic_json TEXT,
  callsite_count INTEGER,
  sink_proximity REAL,
  source_count_gated INTEGER,
  rank_score REAL,
  isolation_cost_json TEXT,
  isolation_eligible BOOLEAN,
  -- Fine-grained sanitizer characterization (migration 0009, html_sanitizer_bypass_lane).
  -- These are a fine-grained SUPERSET of the coarse defense_type (3-way) above —
  -- NOT a widening of it; defense_type is intentionally left as-is. All CHECKs are
  -- NULL-permitting (col IS NULL OR col IN (...)), matching the effort_tier precedent.
  -- On the upgrade path (0009) these are added with NO CHECK (DuckDB ADD COLUMN+CHECK
  -- is unsupported); the categoricals are enforced app-side there.
  mechanism TEXT
    CHECK (mechanism IS NULL OR mechanism IN ('escape', 'strip', 'allowlist', 'denylist', 'regex_filter', 'validator', 'markdown_safe')),
  enforcement_mode TEXT
    CHECK (enforcement_mode IS NULL OR enforcement_mode IN ('transform', 'reject', 'filter')),
  input_context TEXT
    CHECK (input_context IS NULL OR input_context IN ('html_text', 'attribute', 'url', 'css', 'js')),
  fail_mode TEXT
    CHECK (fail_mode IS NULL OR fail_mode IN ('fail_open', 'fail_closed')),
  library_origin TEXT
    CHECK (library_origin IS NULL OR library_origin IN ('builtin', 'framework', 'thirdparty', 'custom')),
  reachability TEXT
    CHECK (reachability IS NULL OR reachability IN ('proven', 'suspected', 'none')),
  discovery_method TEXT
    CHECK (discovery_method IS NULL OR discovery_method IN ('reuse', 'pattern_sweep', 'ast_taint')),
  discovery_confidence REAL,
  UNIQUE (target_id, symbol_path, defense_type)
);

------------------------------------------------------------
-- regexes (migration 0027). MANDATORY whole-tree regex inventory — the 5th enumerated category
-- emitted by preliminary_enumeration_lane. One row per (target, file, line, pattern_src) regex
-- literal / constructor found ANYWHERE in the in-scope tree. INVENTORY-ONLY: ReDoS / bypass /
-- fuzz analysis is DEFERRED to the defense-bypass + fuzz lanes that consume this table (every
-- regex must be mapped so they can find bypasses for and fuzz it). role is the CLOSED 7-value
-- classification (guard|validator|filter — defense-shaped; parser|extractor|router — structural;
-- other). defense_id is a NULLABLE FK set when the regex IS a defense regex (links to defenses).
-- language / flags are OPEN free TEXT (per-language detection vocab). Large pattern bodies sidecar
-- (pattern_sidecar_path, the A1 16 KB rule). The v_coverage.regexes_unmapped HARD-RED gate fires
-- when preliminary_enumeration_lane ran but this table is empty.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS regexes (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  pattern_src TEXT NOT NULL,                               -- the raw regex source text
  pattern_sidecar_path TEXT,                              -- set when pattern_src > 16 KB (A1)
  flags TEXT,                                              -- i/m/s/g/x... as written
  file TEXT NOT NULL,
  symbol_path TEXT,
  line INTEGER,
  language TEXT,                                           -- OPEN free TEXT (per-language detection vocab)
  role TEXT NOT NULL                                       -- CLOSED 7-value classification
    CHECK (role IN ('guard', 'validator', 'filter', 'parser', 'extractor', 'router', 'other')),
  defense_id INTEGER REFERENCES defenses(id),             -- nullable: set when the regex IS a defense regex
  created_at TIMESTAMP NOT NULL,
  UNIQUE (target_id, file, line, pattern_src)             -- NK: one row per (target, location, pattern)
);

------------------------------------------------------------
-- Critical functions (schema v2) — ranked registry of security-critical
-- functions (the crown jewels of the call graph). Populated by the
-- critical-function hunt (references/v2/critical-function-hunt.md) and used as
-- anchors for the forward data-flow lane (critical_fn_forward slices). A
-- critical function may itself BE a sink or defense (soft links sink_id /
-- defense_id); cf_category records *why* it is critical.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS critical_functions (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  symbol_path TEXT NOT NULL,
  cf_category TEXT NOT NULL
    CHECK (cf_category IN (
      'auth_check',
      'access_control',
      'crypto_op',
      'deserializer',
      'validator_sanitizer',
      'parser_decoder',
      'privileged_op',
      'state_transition',
      'dangerous_sink',
      'trust_boundary_transfer'
    )),
  evidence_path TEXT,
  evidence_line INTEGER,
  sink_id INTEGER REFERENCES sinks(id),
  defense_id INTEGER REFERENCES defenses(id),
  source_reachable BOOLEAN,
  -- Ranking factors (references/v2/critical-function-hunt.md § Ranking).
  -- factor_bypass_prior is the cross-round feed-forward hook: a prior round's
  -- reproduced bypass against this function raises its criticality this round.
  factor_reachability REAL,
  factor_blast_radius REAL,
  factor_attention_deficit REAL,
  factor_privilege_delta REAL,
  factor_bypass_prior REAL,
  -- factor_recurrence_prior is the 6th ranking factor (migration 0005, #2):
  -- norm(recurrence_counter self tally) + hot call-neighbor boost. Recompute the
  -- weighted rank via v_critical_fn_ranked (weights live in scoring_config).
  factor_recurrence_prior REAL,
  rank_score REAL,
  rank_tier TEXT
    CHECK (rank_tier IS NULL OR rank_tier IN ('tier1', 'tier2', 'tier3')),
  classification_evidence_json TEXT,
  cf_hash TEXT NOT NULL,
  UNIQUE (cf_hash)
);

------------------------------------------------------------
-- Strategies (§2.3, B4)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS strategies (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  name TEXT NOT NULL UNIQUE, -- free TEXT: the lane vocabulary is open/extensible; seed rows define the canonical set (CHECK removed v0.14 — see doctrine note at top of file)
  description TEXT NOT NULL,
  version INTEGER NOT NULL,
  -- v0.28 (migration 0021): provenance timestamps. DuckDB v1.1.3 has NO triggers and
  -- NO `ON UPDATE CURRENT_TIMESTAMP`, so updated_at is moved by the GUARDED UPSERT on the
  -- seed below (DO UPDATE … updated_at = CURRENT_TIMESTAMP, change-guarded by a WHERE that
  -- fires only when description/version actually differ). created_at is set once and
  -- preserved across re-seeds (excluded.created_at is never written). strategies has no FK
  -- columns, so this UPDATE path avoids the DuckDB v1.1.3 ART-index FK-UPDATE bug.
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Strategy seed. agent_steps.strategy_id FK requires these rows to exist; the seed is
-- idempotent via a GUARDED UPSERT (ON CONFLICT (name) DO UPDATE … WHERE changed — v0.28):
-- a re-seed of an unchanged row is a no-op (created_at + updated_at both preserved); a real
-- description/version change moves updated_at to CURRENT_TIMESTAMP while keeping created_at.
-- IDs 1..22 are currently occupied by seed rows; DuckDB does not auto-increment INTEGER
-- PRIMARY KEY, so any future strategy must pick the next free id (>= 23). Source of truth
-- for the description / version values: db/seed/strategies.yml.
INSERT INTO strategies (id, name, description, version) VALUES
  (1, 'forward_slice_lane',                'Trace taint forward from a source through its callee set toward declared sinks.',                                     1),
  (2, 'backward_sink_lane',                'Trace controllability backward from a sink to find which sources reach it.',                                          1),
  (3, 'defense_base_lane',                 'Run the three-stage bypass-hunting protocol against a ranked defense (consumes the global DuckDB bypass catalogue).', 1),
  (4, 'defense_context_verification_lane', 'Confirm whether a flagged bypass actually flows from a real source to a real sink through this slice.',               1),
  (5, 'isolation_fuzz_lane',               'Stage 3 of bypass-hunting: cost-gated isolation harness fuzzing of a single isolated defense + its bypass corpus.',    1),
  (6, 'autoload_seed_lane',                'Phase-entry seed of top-K=10 knowledge chunks into the agent prompt context.',                                        1),
  (7, 'autoload_expand_lane',              'Lazy on-demand expand of additional knowledge chunks (cap 50 per agent_step).',                                       1),
  (8, 'report_critic',                     'Phase 5 critic. Runs comprehension / eligibility / attack-scenario checks over each confirmed finding.',              1),
  (9, 'critical_function_dataflow_lane',   'Forward data-flow from ranked critical functions AND from attacker-controllable sources toward them; records critical_fn_reach + critical_fn_forward slices.', 1),
  (10, 'boundary_fuzz_lane',               'Phase 1.5 (DEEP) mandatory boundary fuzzing: harness selected parser/FFI/decoder/protocol boundaries for crashes or divergences; records fuzz_runs + emits fuzz_crash/fuzz_divergence findings.', 2),
  (11, 'html_sanitizer_bypass_lane',       'Phase 0.75 (MEDIUM+DEEP) defense pre-break lane targeting HTML/markdown sanitizers. Discovers + characterizes sanitizer defenses (union of reuse / pattern-sweep / AST+taint), then runs the agnostic html-sanitizer-bypass engine (PHP isolate of REAL target sanitize() + jsdom oracle) over a fixed/versioned corpus; per-payload sink hits land in defense_bypasses, the 3-valued per-sanitizer verdict lands in sanitizer_bypass_runs.', 1),
  -- Migration 0011 — C2 dual LLM seed-corpus lanes (ids 12, 13). Identical-by-design;
  -- diversity from LLM stochasticity; content-hash-deduped union feeds boundary_fuzz_lane.
  (12, 'llm_seed_corpus_lane_a',           'Phase 1.4 (DEEP) preliminary LLM seed-corpus generator (instance A of an identical-by-design dual pair with llm_seed_corpus_lane_b). Independently synthesizes initial fuzz seeds from the target''s input-format families; emits fuzz_artifacts(artifact_kind=''seed_initial''). The content-hash-deduped UNION of lane A + lane B feeds boundary_fuzz_lane (Phase 1.5); diversity arises purely from LLM stochasticity (the two lanes share one prompt/strategy). Per-lane stop condition: input-format-family coverage target OR per-lane seed token budget (run_config), whichever first.', 1),
  (13, 'llm_seed_corpus_lane_b',           'Phase 1.4 (DEEP) preliminary LLM seed-corpus generator (instance B of an identical-by-design dual pair with llm_seed_corpus_lane_a). Independently synthesizes initial fuzz seeds from the target''s input-format families; emits fuzz_artifacts(artifact_kind=''seed_initial''). The content-hash-deduped UNION of lane A + lane B feeds boundary_fuzz_lane (Phase 1.5); diversity arises purely from LLM stochasticity (the two lanes share one prompt/strategy). Per-lane stop condition: input-format-family coverage target OR per-lane seed token budget (run_config), whichever first.', 1),
  -- Migration 0013 — C5 C/C++/Java concolic guard-evasion lane (id 14).
  (14, 'concolic_bypass_lane',             'Phase 0.75 (DEEP) C/C++/Java defense pre-break lane. Enumerates dangerous functions guarded by a regex/sanitizer (reusing defenses + critical_fn_reach + AST/CPG), drives the target''s own build + instrumentation (C/C++: LLVM bitcode for KLEE/SymCC; Java: bytecode + driver for a JVM concolic engine), then runs directed symbolic+concolic execution to SOLVE the guard''s path constraints and synthesize a guard-passing input that reaches the target fn. The solved concrete input is the bypass: replayed through the instrumented build it passes the guard AND reaches the target fn -> defense_bypasses(reproduced=TRUE) with the solver''s path-constraint log in exhaustion_log; reachability -> critical_fn_reach. Skip-with-reason only if the build genuinely can''t be produced or no concolic tool exists for the stack. Distinct from isolation_fuzz_lane by technique (constraint-solving, not mutation).', 1),
  -- Migration 0014 — preliminary-inventory completeness enumeration lane (id 15).
  (15, 'preliminary_enumeration_lane',     'Phase 0 (Decompose) exhaustive, finding-agnostic enumeration lane. Whole-tree sweep that populates sources, sinks, defenses, and critical_functions COMPLETELY before any finding is chased — every attacker-controllable input, every dangerous callee, every sanitizer/blacklist/allowlist callsite, every security-critical function — recorded because it exists in scope, never because a smell led to it. Records what it swept in coverage_json (files_swept, patterns_run, semgrep_callsites_seen, sources_found/sinks_found/defenses_found counts) so the v_coverage completeness contradiction signals (guards_on_paths_without_defense_row, validator_cfs_without_defense_link, dangerous_sink_cfs_without_sink_row) have a denominator. Ranking (v_critical_fn_ranked, phase0_priorities) orders this complete set; it never narrows what is enumerated.', 1),
  -- Migration 0017 — slice-end CODEBASE coverage (id 16). NON-MANDATORY: deliberately
  -- ABSENT from v_required_deep_lanes (enforced instead by v_coverage.slices_without_codebase_coverage).
  (16, 'cpg_coverage',                     'Slice-end CODEBASE coverage measurement (NON-MANDATORY — deliberately not in v_required_deep_lanes). After the Hunt''s slicing lanes flush for a (target, round), measures in Joern — over the UNION of every input_slices node set — how much of the codebase the slices collectively touched: a RAW ratio (first-party methods, cpg.method.isExternal(false)) and a FRONTIER ratio (attacker-reachable ∪ sink-bearing ∪ critical-function methods). Writes one cpg_slice_coverage row (integer counts only; percentages are computed by v_cpg_slice_coverage, never stored), and emits each uncovered FRONTIER method as a reusable agent_observations(obs_kind=''blind_spot'') anchored on symbol_path so the NEXT round slices it first (round feed-forward). Enforcement is the count-free gate v_coverage.slices_without_codebase_coverage (slices exist but no coverage row => RED), never a percentage floor.', 1),
  -- Migration 0018 — Phase 1.6 post-Hunt methodology blind-spot sweep (ids 17, 18).
  -- Identical-by-design dual pair (the id-12/13 precedent); diversity from LLM stochasticity;
  -- content-hash union-deduped into methodology_blind_spots; feeds the NEXT round. MANDATORY DEEP.
  (17, 'methodology_blindspot_lane_a',     'Phase 1.6 (DEEP) post-Hunt methodology blind-spot sweep (instance A of an identical-by-design dual pair with methodology_blindspot_lane_b). Runs AFTER all discovery sweeps (Phase 1 Hunt + Phase 1.5 Fuzzing) for a (target, round). Single goal: "find any blind spot in our codebase-analysis methodology" — critiquing BOTH process gaps (HOW we analyzed: bug classes never checked, lanes that should exist but do not, assumptions left untested, source/sink/defense types not enumerated) AND coverage gaps (WHAT this run never reached). Emits methodology_blind_spots rows (gap_class in process|coverage) + one companion reusable agent_observations(obs_kind=''blind_spot''). The content-hash-deduped UNION of lane A + lane B is the merge; agreement=''both'' marks gaps both lanes independently flagged. Diversity arises purely from LLM stochasticity (the two lanes share one prompt/strategy). The merged, ranked directions FEED FORWARD into the next round (v_methodology_blindspots_ranked); they do NOT spawn work this run.', 1),
  (18, 'methodology_blindspot_lane_b',     'Phase 1.6 (DEEP) post-Hunt methodology blind-spot sweep (instance B of an identical-by-design dual pair with methodology_blindspot_lane_a). Runs AFTER all discovery sweeps (Phase 1 Hunt + Phase 1.5 Fuzzing) for a (target, round). Single goal: "find any blind spot in our codebase-analysis methodology" — critiquing BOTH process gaps (HOW we analyzed: bug classes never checked, lanes that should exist but do not, assumptions left untested, source/sink/defense types not enumerated) AND coverage gaps (WHAT this run never reached). Emits methodology_blind_spots rows (gap_class in process|coverage) + one companion reusable agent_observations(obs_kind=''blind_spot''). The content-hash-deduped UNION of lane A + lane B is the merge; agreement=''both'' marks gaps both lanes independently flagged. Diversity arises purely from LLM stochasticity (the two lanes share one prompt/strategy). The merged, ranked directions FEED FORWARD into the next round (v_methodology_blindspots_ranked); they do NOT spawn work this run.', 1),
  -- Migration 0021 — Perpetual Loop mode (ids 19–22). NON-MANDATORY: deliberately ABSENT
  -- from v_required_deep_lanes (the cpg_coverage precedent) so normal DEEP audits never block
  -- on them. One round = DMN generate (divergent) → Salience promote (top-K by promise) →
  -- Executive pursue (REUSES Phase 2 Confirm + L5 PoC) → Learn (round_ledger + recurrence).
  (19, 'perpetual_dmn_generate',           'Perpetual Loop generation register (NON-MANDATORY — deliberately NOT in v_required_deep_lanes). Runs the existing Agent Sweep S2 / Phase 1 Hunt agents in an explicit DIVERGENT register: mandatory divergence, cross-domain analogy, surface unproven hunches, and FREE re-litigation of previously-refuted leads when a new angle/analogy/ledger signal justifies another look. "A round emitting only safe, already-known candidates has malfunctioned." This is the ONLY place the divergent flavor lives; Salience + Executive stay strictly sober. Emits suspicious_points / gr_findings(candidate) candidates for the round. See references/methodology/perpetual-loop-mode.md.', 1),
  (20, 'perpetual_salience_promote',       'Perpetual Loop salience gate (NON-MANDATORY, sober). Ranks the round''s divergent candidates by promise = novelty × est_severity × reachability_prior × ledger_history_factor and promotes the top-K. Implemented as the READ-TIME view v_promise_ranked derived from existing suspicious_point_factor / gr_findings columns — NO new tables, mirroring the v_suspicious_points_ranked / v_critical_fn_ranked never-store rule. See references/methodology/perpetual-loop-mode.md.', 1),
  (21, 'perpetual_executive_pursue',       'Perpetual Loop executive lane (NON-MANDATORY, sober). Pursues each promoted candidate to a verdict by REUSING the existing Phase 2 five-gate Confirm (refute-by-default, references/v2/confirmation-rigor-doctrine.md) + L5 PoC constraints (zero-mocking, vanilla real PoC). NO new confirm path is built — a HIGH/CRIT confirmation here counts toward the loop''s N target. See references/methodology/perpetual-loop-mode.md.', 1),
  (22, 'perpetual_ledger_learn',           'Perpetual Loop learning ledger (NON-MANDATORY, sober). IS the existing round_ledger + round feed-forward + recurrence_counter — no new ledger table. Per-attack-class/region hit-miss biases the NEXT Core round (down-weight exhausted families, surface under-explored regions); this ledger down-weighting is the loop''s only damper. The loop self-fires across turns via ScheduleWakeup and is unbounded until N HIGH/CRIT confirmed (default 20, overridable) or user interrupt; dry rounds are reported, not halting. See references/methodology/perpetual-loop-mode.md.', 1),
  -- Migration 0024 — FuzzGPT history-driven lane (id 24). MANDATORY DEEP at phase1_4_seed
  -- (coexists with llm_seed_corpus_lane_a/b, the id-12/13 dual). Generator mode emits
  -- fuzz_artifacts(seed_initial) feeding boundary_fuzz_lane; the target-agnostic differential
  -- sub-mode emits gr_findings(finding_kind='differential_divergence', severity NULL,
  -- confirmation_status='unconfirmed') — the QUARANTINED N/A classification, kept out of the
  -- severity rankings until triage promotes it. FuzzGPT, Deng et al., arXiv:2304.02014.
  (24, 'fuzzgpt_history_lane',              'Phase 1.4 (DEEP) history-driven LLM fuzzing lane (FuzzGPT, Deng et al., arXiv:2304.02014; coexists with — does NOT replace — the dual llm_seed_corpus_lane_a/b). Mines the target''s own historical bug-triggering code (gh issues/PRs/commits), auto-labels each snippet''s buggy "fuzz target" (the unit generation is steered toward — API / compiler flag / SQL feature / syscall / opcode / protocol field; NOT a libFuzzer harness), then generates unusual edge-case programs via few-shot CoT / zero-shot / retrieval (RT) generation. Two modes: (1) GENERATOR (default) emits edge-case programs as fuzz_artifacts(artifact_kind=''seed_initial'') that feed boundary_fuzz_lane (Phase 1.5) + the existing crash/sanitizer oracles + five-gate Confirm; no schema change on this path. (2) DIFFERENTIAL ORACLE (in-lane sub-mode, target-agnostic — NOT DL-specific) compares any pair of supposedly-equivalent execution contexts (impl A vs B, version N vs N+1, optimization level, config flag, reference implementation); a divergence is QUARANTINED as gr_findings(finding_kind=''differential_divergence'', severity=NULL, confirmation_status=''unconfirmed'') — the N/A classification — and stays OUT of the HIGH/MED/LOW severity rankings until triage shows a security-impact path that promotes it to ''candidate'' (reusing the existing exploitability gate / five-gate Confirm). Mandatory-attempt at DEEP: "skipped — no minable bug history" (e.g. a fresh closed-source binary) is a legitimate documented-skip end state. See references/v2/fuzzgpt-history-lane.md + references/methodology/fuzzgpt-history-driven-lane.md + references/fuzzgpt/ + engines/fuzzgpt-retrieval/.', 1),
  (25, 'prior_art_intake_lane', 'Phase L-1 (DEEP, bug-bounty-mode MANDATORY when a target scope is provided) prior-art intake lane. Runs BEFORE Phase 0 decompose. Mines public prior art keyed on the scope identifiers (vendor/product/version/CPE): CVEs from NVD/GHSA/OSV/exploit-db + web writeups, persists cves + writeups rows, and DISTILS the high-yield leads into promising_lanes (derived_from_cve_id/derived_from_writeup_id provenance; region_hash=''__TARGET_WIDE__'' for unanchored leads) consumed by round 1 via round-entry fetch (10). Distillation-first per-source provenance gate: coverage_json records sources_queried[] + per-source counts (NOT "all CVEs"). DOCUMENTED-SKIP end state (agent_steps.status=''skipped'' + termination_reason) when no scope is provided or a source is unreachable — the Phase L0 fallback precedent — so the roster gate is satisfied without network. See references/methodology/prior-art-intake-lane.md.', 1),
  (26, 'overlooked_lane_audit_lane', 'DEEP-only MANDATORY meta-lane, runs LAST after Phase 1.6 methodology_blind_spots has flushed. Two self-questions: (a) GENERATIVE — are there MORE high-yield lanes never considered? (b) AUDIT — did we ERRONEOUSLY IGNORE a lane that should have spawned (a skipped/unpromoted lane whose documented skip reason no longer holds)? Detection is a DB-GROUNDED TRIPLE REFERENCE (SQL diffs, not free-form): (1) strategies/roster (v_required_deep_lanes) vs covering agent_steps; (2) emitted-but-unpromoted promising_lanes (v_promising_lanes_ranked open_direction); (3) v_coverage/enumeration uncovered signals (+ optional open methodology_blind_spots). ALWAYS emits a promising_lanes row per confirmed overlooked/ignored lane; then cap-gated SPAWNS the top-N-by-promise IN-RUN up to cap = the promising_lanes row_cap (db/seed/fetch-budgets.yml) × tier multiplier (NO magic constant); overflow FEEDS FORWARD; acting stamps promoted_to_round_id. The in-run spawn is the bounded exception to the feed-forward-only promising_lanes doctrine. See references/methodology/overlooked-lane-audit-lane.md.', 1)
ON CONFLICT (name) DO UPDATE SET
  description = excluded.description,
  version = excluded.version,
  updated_at = now()  -- DuckDB v1.1.3 parses a bare CURRENT_TIMESTAMP in DO UPDATE SET as a column ref; now() is the function form
WHERE strategies.description IS DISTINCT FROM excluded.description
   OR strategies.version IS DISTINCT FROM excluded.version;

------------------------------------------------------------
-- run_config (migration 0011) — generic open key-value operational-config home.
-- No closed CHECK (the key space is open, unlike scoring_config.scope), so DB-native
-- operational knobs land here without a DuckDB constraint rebuild. C2's dual
-- seed-corpus lanes read their per-lane token budget + format-family coverage target
-- from here (DB-native determinism — NOT fetch-budgets.yml, NOT scoring_config).
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS run_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT
);

-- C2 seed-budget knobs. seed_token_budget_per_lane mirrors phase1_5_fuzz's 12000.
-- Per-lane stop condition: format-family coverage target reached OR token budget
-- spent, whichever first; both tier-scaled by the existing LOW/MED/DEEP multipliers.
INSERT INTO run_config (key, value, description) VALUES
  ('seed_token_budget_per_lane',        '12000', 'C2: per-lane LLM seed-corpus token budget (mirrors phase1_5_fuzz 12000); tier-scaled by LOW/MED/DEEP. Stop condition: coverage target OR this budget, whichever first.'),
  ('seed_format_family_coverage_target','0.80',  'C2: input-format-family coverage target for the dual seed-corpus lanes (fraction of identified format families seeded). Stop condition: this target OR the per-lane token budget, whichever first.')
ON CONFLICT (key) DO NOTHING;

------------------------------------------------------------
-- Input slices (§2.3, R5)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS input_slices (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  -- source_id: the attacker-controllable source a slice is anchored on. Set for
  -- every source-anchored slice_kind (forward_taint, backward_sink,
  -- defense_callsite). NULL ONLY for a pure 'critical_fn_forward' slice, which is
  -- anchored on critical_fn_id instead (direction B — trace forward FROM the
  -- critical function itself, no originating source). Nullable since schema v2;
  -- the slice_anchor CHECK below enforces exactly-one-of with critical_fn_id.
  source_id INTEGER REFERENCES sources(id),
  -- critical_fn_id: set ONLY on slice_kind='critical_fn_forward' slices, naming
  -- the critical function the forward slice starts from. NULL for every
  -- source-anchored slice_kind (references/methodology/forward-slicing-lanes.md
  -- § Critical-Function Data-Flow).
  critical_fn_id INTEGER REFERENCES critical_functions(id),
  callee_set_hash TEXT NOT NULL,
  -- 'execution_path' (schema v15) is the LLMxCPG execution-path-first slice: a
  -- source-anchored slice produced by the bounded CPGQL query-generation loop that
  -- isolates the concrete execution path from attacker input to a candidate sink
  -- (arXiv:2507.16585). It rides the slice_anchor ELSE branch (source-anchored).
  slice_kind TEXT NOT NULL
    CHECK (slice_kind IN ('forward_taint', 'backward_sink', 'defense_callsite', 'critical_fn_forward', 'execution_path')),
  callee_count INTEGER NOT NULL,
  representative_callees TEXT,
  -- slice_anchor: exactly one of source_id / critical_fn_id is set, keyed by
  -- slice_kind. 'critical_fn_forward' is CF-anchored (source_id NULL); every
  -- other kind is source-anchored (critical_fn_id NULL). Direction A (forward
  -- from a source toward a CF) is a forward_taint slice whose reach lands in
  -- critical_fn_reach — NOT a critical_fn_forward slice.
  CHECK (
    CASE slice_kind
      WHEN 'critical_fn_forward' THEN critical_fn_id IS NOT NULL AND source_id IS NULL
      ELSE source_id IS NOT NULL AND critical_fn_id IS NULL
    END
  ),
  UNIQUE (target_id, callee_set_hash, slice_kind)
);

------------------------------------------------------------
-- Critical-function reachability (schema v2) — which attacker-controllable
-- sources reach which ranked critical functions. The coverage ledger for the
-- "forward from all attacker inputs toward critical functions" half of the
-- data-flow lane (references/methodology/forward-slicing-lanes.md).
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS critical_fn_reach (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  critical_fn_id INTEGER NOT NULL REFERENCES critical_functions(id),
  source_id INTEGER NOT NULL REFERENCES sources(id),
  slice_id INTEGER REFERENCES input_slices(id),
  reach_status TEXT NOT NULL
    CHECK (reach_status IN ('reaches', 'blocked', 'unproven')),
  hop_count INTEGER,
  guard_path_json TEXT,   -- guards/defenses encountered along the path
  reach_hash TEXT NOT NULL,
  UNIQUE (reach_hash)
);

------------------------------------------------------------
-- Intended-feature classification (§2.8, R3, R6)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS intended_feature_classification (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  sink_id INTEGER NOT NULL REFERENCES sinks(id),
  is_documented_behavior BOOLEAN,
  precondition_strictness TEXT NOT NULL
    CHECK (precondition_strictness IN ('trivial', 'authed', 'privileged', 'admin_only')),
  observed_role_at_sink TEXT NOT NULL
    CHECK (observed_role_at_sink IN ('anonymous', 'user', 'admin', 'service')),
  classification_evidence_json TEXT,
  classified_at TIMESTAMP NOT NULL,
  UNIQUE (sink_id)
);

------------------------------------------------------------
-- Agent steps (§2.3) — FKs into defenses + strategies + input_slices
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS agent_steps (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  strategy_id INTEGER NOT NULL REFERENCES strategies(id),
  slice_id INTEGER REFERENCES input_slices(id),
  defense_id INTEGER REFERENCES defenses(id),
  parent_step_id INTEGER REFERENCES agent_steps(id),
  round_id INTEGER REFERENCES round_ledger(id),
  started_at TIMESTAMP NOT NULL,
  ended_at TIMESTAMP,
  -- 'scheduled' = Plan-materialized roster step not yet run; 'skipped' = lane deliberately N/A (requires termination_reason). See v_lane_coverage + the DEEP completion gate.
  status TEXT NOT NULL
    CHECK (status IN ('scheduled', 'running', 'success', 'exhausted', 'failed', 'timed_out', 'skipped')),
  termination_reason TEXT,
  coverage_json TEXT,
  step_hash TEXT NOT NULL,
  UNIQUE (step_hash)
);

------------------------------------------------------------
-- Agent observations (schema v2) — rich per-step research log. The "save
-- context into the DB" layer: hypotheses tried, dead-ends ruled out,
-- assumptions made, invariants discovered, blind spots flagged. Rows with
-- reusable=TRUE are fetched by later rounds to suppress redundant work
-- (references/v2/db-logging-and-context.md, references/v2/round-feedforward.md).
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS agent_observations (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  agent_step_id INTEGER NOT NULL REFERENCES agent_steps(id),
  obs_kind TEXT NOT NULL
    CHECK (obs_kind IN (
      'hypothesis',
      'dead_end',
      'assumption',
      'invariant',
      'partial_trace',
      'guard_observed',
      'tool_output',
      'note',
      'blind_spot'
    )),
  symbol_path TEXT,
  evidence_path TEXT,
  evidence_line INTEGER,
  body TEXT NOT NULL,
  body_sidecar_path TEXT,   -- set when body > 16 KB (A1); points into db/sidecars/<hash>
  confidence REAL,
  reusable BOOLEAN NOT NULL DEFAULT TRUE,
  obs_hash TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL,
  UNIQUE (obs_hash)
);

------------------------------------------------------------
-- Query attempts (schema v15) — backs the LLMxCPG-Q-style bounded CPGQL
-- query-generation feedback loop (arXiv:2507.16585): generate a CPGQL query ->
-- run it against the code property graph -> feed the result/error back ->
-- retry (≤3) -> dead_end. One row per attempt, so a slice's provenance is the
-- ordered trail of queries that produced (or failed to produce) it. status is
-- the genuinely-closed verdict vocabulary (valid | syntax_error | empty) carried
-- as a CHECK enum; joern_error captures the raw engine diagnostic on a failed run.
--
-- slice_id is nullable: an attempt may PRECEDE a successful slice (a syntax_error /
-- empty attempt produces no slice at all, and the retry that finally succeeds is
-- what mints the input_slices row). query_text holds the CPGQL inline; when it
-- exceeds 16 KB it is offloaded to query_sidecar_path (mirrors the
-- agent_observations.body_sidecar_path convention — db/sidecars/<content-SHA-256>).
-- Idempotency: attempt_hash UNIQUE makes a replayed attempt a no-op; the natural
-- (target_id, agent_step_id, attempt_no) key pins the bounded retry sequence.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS query_attempts (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  agent_step_id INTEGER NOT NULL REFERENCES agent_steps(id),
  slice_id INTEGER REFERENCES input_slices(id),   -- nullable; an attempt may precede a successful slice
  attempt_no INTEGER NOT NULL,
  query_text TEXT,                                 -- the CPGQL; sidecar when >16 KB
  query_sidecar_path TEXT,                         -- mirrors agent_observations.body_sidecar_path convention
  status TEXT NOT NULL
    CHECK (status IN ('valid', 'syntax_error', 'empty')),
  joern_error TEXT,
  created_at TIMESTAMP NOT NULL,
  attempt_hash TEXT NOT NULL,                      -- idempotency
  UNIQUE (attempt_hash),
  UNIQUE (target_id, agent_step_id, attempt_no)
);

------------------------------------------------------------
-- cpg_slice_coverage (schema v17) — CODEBASE slice-coverage, measured WHEN THE
-- HUNT'S SLICING LANES END. Distinct from the two coverage signals already in the
-- schema: the per-slice agent_steps.coverage_json measures how thoroughly ONE slice
-- was walked, and v_lane_coverage measures WHICH lanes ran. Neither answers "of the
-- whole codebase, what fraction did the UNION of all slices touch?" — a swarm can
-- slice a handful of functions perfectly while most of the attack surface is never
-- sliced. This table persists that union as measured integer counts; the percentages
-- are computed read-time by v_cpg_slice_coverage (never a stored, magic-constant %).
-- One row per (target_id, round_id), written by a non-mandatory 'cpg_coverage'
-- agent_step (NOT in v_required_deep_lanes) — agent_step_id back-links it.
--
-- WHY MEASURED IN JOERN, NOT DERIVED FROM THE DB: input_slices.representative_callees
-- is deliberately TRUNCATED, so the true distinct-method UNION across slices cannot be
-- reconstructed from stored rows. The cpg_coverage step emits this row from a single
-- slice-end CPGQL aggregate over the union of every slice's nodes — recipe in
-- references/methodology/joern-forward-slicing.md § "Codebase slice-coverage".
--
-- TWO DENOMINATORS, both stored as integer counts (the % is the view's job):
--   * RAW   (methods_total/covered): all first-party methods (cpg.method.isExternal(false)).
--           The literal "% on codebase" — the honest baseline.
--   * FRONTIER (frontier_total/covered): security-relevant methods = attacker-reachable
--           ∪ sink-bearing ∪ critical-function. This is the BUG-FINDING signal; it is
--           what feeds round-over-round prioritization. Every uncovered frontier method
--           is also emitted as a reusable agent_observations(obs_kind='blind_spot')
--           anchored on symbol_path, so the NEXT round slices it first.
-- coverage_basis records the provenance of both denominators (not a magic constant).
-- files_*/nodes_* are companion granularities (NULL when not measured); per_kind_json
-- breaks covered methods down by slice_kind for change-visibility. This is NOT a
-- threshold gate — a low % is selective-slicing-by-design, inspected (via
-- v_cpg_slice_coverage) not auto-failed; the only gate is
-- v_coverage.slices_without_codebase_coverage (slices exist but this row is absent =>
-- the measurement was skipped when slices ended).
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cpg_slice_coverage (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  round_id INTEGER REFERENCES round_ledger(id),       -- nullable: a single-shot audit need not open a round
  agent_step_id INTEGER REFERENCES agent_steps(id),   -- nullable: the 'cpg_coverage' step that measured this (provenance)
  methods_total INTEGER NOT NULL,                     -- RAW denominator: first-party CPG methods (cpg.method.isExternal(false).size)
  methods_covered INTEGER NOT NULL,                   -- RAW numerator: distinct first-party methods in the UNION of all slice nodes
  frontier_total INTEGER NOT NULL,                    -- FRONTIER denominator: attacker-reachable ∪ sink-bearing ∪ critical-function methods
  frontier_covered INTEGER NOT NULL,                  -- FRONTIER numerator: distinct frontier methods in the UNION of all slice nodes
  files_total INTEGER,                                -- companion file granularity (NULL when not measured)
  files_covered INTEGER,
  nodes_total INTEGER,                                -- companion raw PDG-node breadth (NULL when not measured)
  nodes_covered INTEGER,
  per_kind_json TEXT,                                 -- covered-method counts by slice_kind {execution_path,forward_taint,backward_sink,critical_fn_forward}
  coverage_basis TEXT NOT NULL DEFAULT 'raw=first_party_methods;frontier=reachable+sink+cf',  -- provenance of both denominators (not a magic constant)
  measured_at TIMESTAMP NOT NULL,
  coverage_hash TEXT NOT NULL,                        -- idempotency (mirrors query_attempts.attempt_hash / critical_fn_reach.reach_hash)
  CHECK (methods_covered  <= methods_total),          -- a union can never exceed its denominator
  CHECK (frontier_covered <= frontier_total),
  UNIQUE (coverage_hash),
  UNIQUE (target_id, round_id)
);

------------------------------------------------------------
-- methodology_blind_spots (schema v18) — the merged output of the Phase 1.6 post-Hunt
-- methodology blind-spot sweep. AFTER all discovery sweeps finish for a (target, round)
-- — Phase 1 Hunt + (DEEP) Phase 1.5 Fuzzing — two IDENTICAL, INDEPENDENT agents
-- (methodology_blindspot_lane_a / _b, ids 17/18; the id-12/13 dual-seed precedent) answer
-- one question: "find any blind spot in our codebase-analysis methodology". Their output is
-- MERGED here by content-hash union-dedup, becoming ranked candidate directions/lanes that
-- FEED FORWARD into the NEXT round (round-feedforward fetch (8)); they do NOT spawn work
-- this run.
--   * gap_class is the "clearly separated" axis: 'process' = HOW we analyzed (bug classes
--     never checked, lanes that should exist but do not, assumptions left untested,
--     source/sink/defense types not enumerated); 'coverage' = WHAT this run never reached.
--     This keeps the meta-pass output DISTINCT from the existing frontier-coverage
--     agent_observations(obs_kind='blind_spot') rows emitted by cpg_coverage (id 16).
--   * blindspot_hash UNIQUE is the merge/dedup key (hash over target_id + gap_class +
--     normalized identity). The second lane's identical row hits ON CONFLICT DO NOTHING;
--     the orchestrator then flips agreement -> 'both' and bumps dedup_cluster_size — that
--     is the union-dedup merge (agreement='both' = a confidence signal: both lanes
--     independently flagged the same gap). dedup_cluster_size also accrues across rounds.
--   * promoted_to_round_id is set when a LATER round consumes this direction as a lane —
--     the feed-forward closure + change-visibility (which prior gaps actually became work).
--   * obs_kind is NOT widened: each row also emits one companion reusable
--     agent_observations(obs_kind='blind_spot') so the every-phase observation-flush gate
--     and the existing round-feedforward fetch (3) both see it; separation lives in
--     gap_class here, not in a new enum value (no CHECK rebuild).
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS methodology_blind_spots (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  round_id INTEGER REFERENCES round_ledger(id),          -- nullable: a single-shot audit need not open a round
  agent_step_id INTEGER REFERENCES agent_steps(id),      -- the merge step / emitting lane (provenance)
  gap_class TEXT NOT NULL                                -- the "clearly separated" axis
    CHECK (gap_class IN ('process', 'coverage')),
  title TEXT NOT NULL,                                   -- one-line direction name
  body TEXT NOT NULL,                                    -- the blind spot + why it matters as a next-round lane
  body_sidecar_path TEXT,                                -- set when body > 16 KB (A1)
  proposed_lane TEXT,                                    -- candidate strategies.name this direction would become (nullable)
  symbol_path TEXT,                                      -- optional anchor (a coverage gap often names a method/region)
  evidence_path TEXT,
  evidence_line INTEGER,
  agreement TEXT NOT NULL DEFAULT 'single'               -- 'both' = both lanes independently flagged it (merge signal)
    CHECK (agreement IN ('single', 'both')),
  dedup_cluster_size INTEGER NOT NULL DEFAULT 1,         -- idempotent merge-hit count (lanes + rounds)
  promoted_to_round_id INTEGER REFERENCES round_ledger(id),  -- set when a LATER round consumes this as a direction/lane (feed-forward closure)
  blindspot_hash TEXT NOT NULL,                          -- stable hash over (target_id, gap_class, normalized identity) — the union-dedup/merge key
  created_at TIMESTAMP NOT NULL,
  UNIQUE (blindspot_hash)
);

------------------------------------------------------------
-- Phase-0 priorities (§2.2, B2)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS phase0_priorities (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  artifact_kind TEXT NOT NULL
    CHECK (artifact_kind IN ('source', 'sink', 'defense', 'slice', 'critical_function')),
  artifact_id INTEGER NOT NULL,
  tier TEXT NOT NULL
    CHECK (tier IN ('tier1', 'tier2', 'tier3')),
  factor_callsite_count REAL,
  factor_taint_reach REAL,
  factor_sink_proximity REAL,
  factor_source_count REAL,
  factor_severity_potential REAL,
  factor_tier_weight REAL,
  factor_recent_change_velocity REAL,
  factor_test_coverage_inverse REAL,
  factor_external_exposure REAL,
  composite_score REAL,
  UNIQUE (target_id, artifact_kind, artifact_id)
);

------------------------------------------------------------
-- Findings (§2.4, R1) — canonical name = gr_findings
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gr_findings (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  sink_id INTEGER REFERENCES sinks(id),
  source_id INTEGER REFERENCES sources(id),
  defense_id INTEGER REFERENCES defenses(id),
  agent_step_id INTEGER NOT NULL REFERENCES agent_steps(id),
  finding_kind TEXT NOT NULL,
  -- payload kept inline iff ≤ 16 KB; otherwise NULL and sidecar path set (A1).
  payload TEXT,
  payload_sidecar_path TEXT,
  confirmation_status TEXT NOT NULL
    -- 'unconfirmed' (v0.36, migration 0024) is the QUARANTINE status for the
    -- fuzzgpt_history_lane target-agnostic DIFFERENTIAL-oracle sub-mode: a divergence
    -- between two supposedly-equivalent execution contexts (impl A vs B, version N vs
    -- N+1, optimization level, config flag, reference impl) is a candidate finding but
    -- NOT yet a security finding. It is held as 'unconfirmed' with severity NULL (the
    -- "N/A" classification — see the severity CHECK below) so it stays OUT of the
    -- confirmed_vulns view, the findings_candidate_open / confirmed_* gates, and every
    -- severity ranking until triage shows a security-impact path; promotion moves it to
    -- 'candidate' and into the standard five-gate Confirm. confirmation_status is a
    -- closed, low-cardinality vocabulary (the doctrine's CHECK-enum criterion); it is
    -- NOT FK-referenced by another table's CHECK, so the canonical fresh-DB schema
    -- carries the widened 4-value CHECK directly. DuckDB cannot widen this inline CHECK
    -- in place on the upgrade path, so migration 0024 enforces 'unconfirmed' app-side
    -- there (the 0019 precedent); it inserts no 'unconfirmed' row itself.
    CHECK (confirmation_status IN ('candidate', 'confirmed', 'refuted', 'unconfirmed')),
  -- severity is the SECURITY rating vocabulary and is deliberately CLOSED — it feeds the
  -- ranking/report views, so it stays {LOW,MEDIUM,HIGH,CRITICAL} and is NOT widened with
  -- an "N/A" member (per the CHECK-enum-vs-free-TEXT doctrine at the top of this file:
  -- a too-tight rank vocab must not be polluted, and DuckDB cannot widen a rank-bearing
  -- CHECK in place). The "N/A" classification for quarantined differential findings is
  -- therefore the DOCUMENTED FREE-TEXT/NULL state — finding_kind='differential_divergence'
  -- (open vocab, alongside fuzz_crash/fuzz_divergence) with severity = NULL — never a new
  -- severity enum value. severity becomes a real rating only when triage promotes the
  -- finding to 'candidate' and Confirm/Proof assigns one.
  severity TEXT
    CHECK (severity IS NULL OR severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
  -- Deployment-configuration provenance for the proof attached to this finding.
  -- Gate 4 (Reproduction artifact, references/confirmation-rigor-doctrine.md)
  -- requires this to be set before promotion to confirmed. Phase 5 eligibility
  -- check turns 'non_vanilla' into WARNING + required_config_delta and 'unknown'
  -- (or NULL) into CRITICAL.
  config_state TEXT
    CHECK (config_state IS NULL OR config_state IN ('vanilla', 'non_vanilla', 'unknown')),
  -- confirmation_rigor_tier (v0.40.0, migration 0029, T2-12 / S-P12): the strength of the
  -- refutation/confirmation evidence STAMPED at promotion, so downstream consumers (priors,
  -- recurrence, cross-audit memory, the calibration register) can DISCOUNT a weakly-tested
  -- confirmation instead of laundering it into a strong prior. Set ONLY by the `vrdb promote`
  -- verb (Tier 3) at the candidate→confirmed transition; NULL for candidate/refuted/unconfirmed
  -- rows. Closed, low-cardinality vocab (the doctrine's CHECK-enum criterion): 'shallow' =
  -- single-pass / same-lane refutation; 'independent' = refuter lane/strategy ≠ discoverer
  -- (the all-tier independence mandate, T1-08); 'reproduced' = a vanilla PoC overcame the
  -- refutation on the real deployed surface. DuckDB cannot widen this inline CHECK in place on
  -- the upgrade path, so migration 0029 adds the column with NO CHECK there (the 0009/0019
  -- precedent — enforced app-side / by the promote verb); the fresh-DB schema carries the CHECK.
  confirmation_rigor_tier TEXT
    CHECK (confirmation_rigor_tier IS NULL OR confirmation_rigor_tier IN ('shallow', 'independent', 'reproduced')),
  finding_hash TEXT NOT NULL,
  UNIQUE (finding_hash)
);

CREATE OR REPLACE VIEW confirmed_vulns AS
  SELECT * FROM gr_findings WHERE confirmation_status = 'confirmed';

------------------------------------------------------------
-- Suspicious Point screening tier (migration 0010). A domain-agnostic, high-recall,
-- region-level vulnerability HYPOTHESIS that screens attacker-relevant code regions
-- BEFORE the gr_findings confirmation tier. Scored deterministically read-time from a
-- growing, coverage-gated catalog of weighted criteria; graduates into a
-- gr_findings(candidate) when its taint-reach DAG closes or a reproduction lands.
-- Spec: .omc/specs/deep-interview-suspicious-point-pipeline.md §4-§5.
-- Placed after gr_findings/confirmed_vulns because suspicious_points FKs graduated_finding_id.
--
-- suspicious_points carries NO confirmation_status, NO PoC columns, NO stored score
-- (all by design — gr_findings owns confirmation; the SP composite is read-time only,
-- mirroring the v_critical_fn_ranked never-store rule). Dedup is DB-native: the UNIQUE
-- natural key + ON CONFLICT increments dedup_cluster_size (no LLM deduplicator agent).
-- screening_verdict is the one genuinely-closed vocab here, carried as a NULL-permitting
-- CHECK (effort_tier precedent); vuln_class / oracle / lane / factor_name are open vocab
-- (free TEXT + sp_factor_config seed rows), never CHECK enums.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS suspicious_points (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  round_id INTEGER REFERENCES round_ledger(id),
  agent_step_id INTEGER REFERENCES agent_steps(id),
  symbol_path TEXT NOT NULL,        -- function/region anchor
  region_hash TEXT NOT NULL,        -- stable hash of normalized control-flow description
  description TEXT NOT NULL,        -- control-flow LANDMARKS, not line numbers (LLMs hallucinate line#s)
  vuln_class TEXT NOT NULL,         -- open vocab: heap_overflow | sqli | ssrf | xss | sanitizer_bypass | ...
  oracle TEXT,                      -- open vocab: sanitizer_crash | differential | assertion | response_diff | invariant
  lane TEXT,                        -- emitting strategy/lane name (by-name link to strategies)
  screening_verdict TEXT
    CHECK (screening_verdict IS NULL OR screening_verdict IN ('kept', 'screened_out')),
  graduated_finding_id INTEGER REFERENCES gr_findings(id),  -- set on graduation; NULL while pre-candidate
  dedup_cluster_size INTEGER DEFAULT 1,                     -- idempotent merge-hit count
  created_at TIMESTAMP,
  UNIQUE (target_id, symbol_path, vuln_class, lane, region_hash)
);

-- EAV factor store (§4.2). raw_value is producer-emitted (gates use 0/1). The
-- normalized/percentile value is NOT stored — computed read-time in v_suspicious_points_ranked.
CREATE TABLE IF NOT EXISTS suspicious_point_factor (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  sp_id INTEGER NOT NULL REFERENCES suspicious_points(id),
  factor_name TEXT NOT NULL,        -- open vocab, seeded in sp_factor_config
  raw_value REAL,                   -- producer-emitted raw value (gates use 0/1)
  evidence_ref TEXT,                -- provenance pointer (observation/slice/cf/git/etc.)
  producer_lane TEXT,               -- which lane/step produced it (coverage tracking)
  created_at TIMESTAMP,
  UNIQUE (sp_id, factor_name)
);

-- The catalog + knobs (§4.3). A DEDICATED table (NOT scoring_config, whose scope is a
-- closed CHECK DuckDB cannot widen in place). weight=0 = registered but inert (lets a
-- criterion be added before its producer exists). direction +1 boost | -1 penalty.
-- is_gate = hard 0/1 floor condition (not percentile-ranked). factor_name is open vocab.
CREATE TABLE IF NOT EXISTS sp_factor_config (
  factor_name TEXT PRIMARY KEY,
  weight REAL NOT NULL DEFAULT 0,
  direction INTEGER NOT NULL DEFAULT 1,
  is_gate BOOLEAN NOT NULL DEFAULT FALSE,
  expected_producer TEXT,
  description TEXT
);

-- sp_signed_rank (§4.4) — the per-factor signed-rank transform, the one place the
-- formula lives (the "stored-procedure substitute"). Boost (+1) keeps the within-round
-- percentile rank; penalty (-1) inverts it to (1 - rank). Degenerate-population neutral
-- 0.5 is computed in the view (where the window context is available) and passed in.
CREATE OR REPLACE MACRO sp_signed_rank(direction, rank) AS
  CASE WHEN direction = -1 THEN 1.0 - rank ELSE rank END;

-- sp_factor_config seed (§5 criteria catalog). Source-1 + Source-2 factors active;
-- gate factors weighted nonzero so v_sp_factor_coverage tracks their producers (the
-- score view excludes is_gate from the weighted sum regardless). Source-3 (NEW) factors
-- registered at weight=0 (inert until producers land). Gates: oracle_applicable,
-- reachable_from_entry, taint_reach_G1. Penalties (direction=-1): intended_feature_G3,
-- proven_invariant.
INSERT INTO sp_factor_config (factor_name, weight, direction, is_gate, expected_producer, description) VALUES
  ('dangerous_sink_class',     0.12, 1, FALSE, 'sinks (Phase 0)',                         'Source-1: sink belongs to a dangerous sink class'),
  ('attacker_input_influence', 0.12, 1, FALSE, 'sources + taint (Phase 0-1)',             'Source-1: degree of attacker control over the region input'),
  ('uncertain_protection',     0.10, 1, FALSE, 'defenses gap analysis (Phase 0.75)',      'Source-1: protection presence is uncertain / gappy'),
  ('oracle_applicable',        1.00, 1, TRUE,  'oracle catalog per vuln_class (new)',     'Source-1 GATE: a usable oracle exists for this vuln_class'),
  ('reachable_from_entry',     1.00, 1, TRUE,  'call graph / critical_fn_reach (Phase 0-1)','Source-1 GATE: region is reachable from an entry point'),
  ('recall_band',              0.08, 1, FALSE, 'emitting lane verdict',                   'Source-1: emitting lane recall-band confidence'),
  ('factor_recurrence_prior',  0.14, 1, FALSE, 'round feed-forward',                      'Source-2: cross-round recurrence prior (hi)'),
  ('factor_bypass_prior',      0.14, 1, FALSE, 'defense_bypasses cross-round',            'Source-2: prior reproduced bypass prior (hi)'),
  ('critical_fn_rank',         0.10, 1, FALSE, 'v_critical_fn_ranked',                    'Source-2: critical-function rank score'),
  ('taint_reach_G1',           1.00, 1, TRUE,  'Confirm gate 1',                          'Source-2 GATE: taint reaches the sink (Confirm G1)'),
  ('defense_gap_G2',           0.08, 1, FALSE, 'Confirm gate 2',                          'Source-2: defense-gap signal (Confirm G2)'),
  ('intended_feature_G3',      0.10, -1, FALSE,'intended_feature_classification',         'Source-2 PENALTY: region is an intended feature (Confirm G3)'),
  ('blind_spot',               0.06, 1, FALSE, 'agent_observations / coverage carry',     'Source-2: flagged blind spot / deferred edge'),
  ('sink_severity',            0.08, 1, FALSE, 'sinks',                                   'Source-2: sink severity'),
  ('config_reachable',         0.06, 1, FALSE, 'config_state',                            'Source-2: reachable under a plausible config'),
  ('change_churn',             0.00, 1, FALSE, 'git (Phase L0 recency)',                  'Source-3: recent change churn'),
  ('call_depth',               0.00, 1, FALSE, 'call graph (Phase 0)',                    'Source-3: call depth'),
  ('guard_distance',           0.00, 1, FALSE, 'static analysis (new producer)',          'Source-3: distance to nearest guard'),
  ('complexity',               0.00, 1, FALSE, 'static metric (new producer)',            'Source-3: cyclomatic / cognitive complexity'),
  ('taint_fanin',              0.00, 1, FALSE, 'taint graph',                             'Source-3: taint fan-in count'),
  ('oracle_count',             0.00, 1, FALSE, 'oracle catalog',                          'Source-3: number of applicable oracles'),
  ('dedup_cluster_size',       0.00, 1, FALSE, 'suspicious_points (DB-native)',           'Source-3: idempotent merge-hit count'),
  ('failed_poc_attempts',      0.00, 1, FALSE, 'PoC/fuzz loop',                           'Source-3: failed PoC/fuzz attempt count'),
  ('proximity_to_confirmed',   0.00, 1, FALSE, 'call-graph distance to confirmed_vulns',  'Source-3: proximity to a confirmed vuln'),
  ('sink_class_base_rate',     0.00, 1, FALSE, 'eval_corpus history',                     'Source-3: historical base rate for this sink class'),
  ('proven_invariant',         0.00, -1, FALSE,'agent_observations(obs_kind=invariant)',  'Source-3 PENALTY: a proven invariant blocks the bug')
ON CONFLICT (factor_name) DO NOTHING;

-- v_suspicious_points_ranked (§4.4) — read-time within-round percentile-rank composite.
-- NEVER stored (mirrors v_critical_fn_ranked). Gate factors (is_gate): hard 0/1 — any
-- unsatisfied gate (raw_value not > 0) floors gate_ok=FALSE and composite_score=0.
-- Non-gate factors: PERCENT_RANK() within (target_id, round_id, factor_name); degenerate
-- population (n<=1 OR zero-variance min=max) -> deterministic neutral 0.5; penalties
-- invert via sp_signed_rank. composite = SUM(weight * signed_rank) over non-gate, gated.
CREATE OR REPLACE VIEW v_suspicious_points_ranked AS
WITH factor_rows AS (
  SELECT
    sp.id AS sp_id,
    sp.target_id,
    sp.round_id,
    spf.factor_name,
    spf.raw_value,
    cfg.weight,
    cfg.direction,
    cfg.is_gate,
    PERCENT_RANK() OVER (
      PARTITION BY sp.target_id, sp.round_id, spf.factor_name
      ORDER BY spf.raw_value
    ) AS pct_rank,
    COUNT(*) OVER (
      PARTITION BY sp.target_id, sp.round_id, spf.factor_name
    ) AS pop_n,
    MIN(spf.raw_value) OVER (
      PARTITION BY sp.target_id, sp.round_id, spf.factor_name
    ) AS pop_min,
    MAX(spf.raw_value) OVER (
      PARTITION BY sp.target_id, sp.round_id, spf.factor_name
    ) AS pop_max
  FROM suspicious_points sp
  JOIN suspicious_point_factor spf ON spf.sp_id = sp.id
  JOIN sp_factor_config cfg        ON cfg.factor_name = spf.factor_name
),
scored AS (
  SELECT
    sp_id,
    target_id,
    round_id,
    is_gate,
    weight,
    direction,
    raw_value,
    CASE WHEN pop_n <= 1 OR pop_min = pop_max THEN 0.5 ELSE pct_rank END AS norm_rank
  FROM factor_rows
)
SELECT
  sp.id,
  sp.target_id,
  sp.round_id,
  sp.symbol_path,
  sp.vuln_class,
  sp.lane,
  sp.screening_verdict,
  sp.graduated_finding_id,
  COALESCE(
    BOOL_AND(CASE WHEN s.is_gate THEN COALESCE(s.raw_value, 0) > 0 ELSE TRUE END),
    TRUE
  ) AS gate_ok,
  CASE
    WHEN COALESCE(
      BOOL_AND(CASE WHEN s.is_gate THEN COALESCE(s.raw_value, 0) > 0 ELSE TRUE END),
      TRUE
    )
    THEN COALESCE(
      SUM(CASE WHEN NOT s.is_gate THEN s.weight * sp_signed_rank(s.direction, s.norm_rank) ELSE 0 END),
      0
    )
    ELSE 0
  END AS composite_score
FROM suspicious_points sp
LEFT JOIN scored s ON s.sp_id = sp.id
GROUP BY
  sp.id, sp.target_id, sp.round_id, sp.symbol_path, sp.vuln_class,
  sp.lane, sp.screening_verdict, sp.graduated_finding_id;

-- v_sp_factor_coverage (§4.5) — per-factor producer coverage gate (mirrors v_lane_coverage).
-- For each sp_factor_config row with weight <> 0, report whether ANY suspicious_point_factor
-- row populated it: 'ok' / 'MISSING'. Makes a never-populated active factor a queryable delta
-- rather than a silently-neutral 0.5. Inert (weight=0) factors are excluded.
CREATE OR REPLACE VIEW v_sp_factor_coverage AS
SELECT
  cfg.factor_name,
  cfg.weight,
  cfg.is_gate,
  cfg.expected_producer,
  COUNT(spf.id) AS rows_populated,
  CASE WHEN COUNT(spf.id) > 0 THEN 'ok' ELSE 'MISSING' END AS coverage_status
FROM sp_factor_config cfg
LEFT JOIN suspicious_point_factor spf ON spf.factor_name = cfg.factor_name
WHERE cfg.weight <> 0
GROUP BY cfg.factor_name, cfg.weight, cfg.is_gate, cfg.expected_producer;

------------------------------------------------------------
-- Prior-art intake (migration 0026). Target-scoped public prior art mined by the bug-bounty-mode
-- Phase L-1 prior_art_intake_lane (strategy 25): CVEs (NVD/GHSA/OSV/exploit-db) + web writeups,
-- keyed on the scope identifiers (vendor/product/version/CPE). DISTILLATION-FIRST: the lane stores
-- what it finds and distils the high-yield leads into promising_lanes (derived_from_cve_id /
-- derived_from_writeup_id provenance). cves.source is the CLOSED provenance vocab; the same CVE
-- from two sources is two provenance rows (NK target_id+cve_id+source). cves is declared BEFORE
-- writeups so writeups.related_cve_id resolves; both precede promising_lanes so its derived_from_*
-- FKs resolve. Large raw payloads / patterns sidecar (the A1 16 KB rule).
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cves (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  cve_id TEXT NOT NULL,                                     -- 'CVE-2024-1234' / 'GHSA-xxxx'; OPEN free TEXT (multi-source ids)
  product TEXT,                                             -- vendor/product label from scope
  cpe TEXT,                                                 -- optional CPE 2.3 string
  version_range TEXT,
  cvss REAL,
  summary TEXT,
  source TEXT NOT NULL                                      -- CLOSED provenance vocab
    CHECK (source IN ('nvd', 'ghsa', 'osv', 'exploit-db')),
  published_at TIMESTAMP,
  raw_ref TEXT,                                             -- url / advisory id / raw-json pointer
  raw_sidecar_path TEXT,                                    -- set when raw_ref payload > 16 KB (A1)
  created_at TIMESTAMP NOT NULL,
  UNIQUE (target_id, cve_id, source)                        -- NK: same CVE from two sources = two provenance rows
);

------------------------------------------------------------
-- writeups (migration 0026). One row per (target, url) web writeup. source/bug_class are OPEN
-- free TEXT; related_cve_id is a NULLABLE FK to cves (a writeup may pin a CVE).
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS writeups (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  url TEXT NOT NULL,
  title TEXT,
  source TEXT,                                              -- OPEN free TEXT: blog/hackerone/gh/twitter
  summary TEXT,
  bug_class TEXT,                                           -- OPEN vocab descriptive (ssti/sqli/...) — mirrors promising_lanes.vuln_class
  related_cve_id INTEGER REFERENCES cves(id),              -- nullable: a writeup may pin a CVE
  created_at TIMESTAMP NOT NULL,
  UNIQUE (target_id, url)                                   -- NK: one row per (target, url)
);

------------------------------------------------------------
-- Promising-lane static-analysis feed-forward (migration 0025). A POSITIVE static-analysis
-- LEAD: a concrete new investigation direction worth a dedicated lane (e.g. "custom template
-- engine → SSTI-fuzz lane @ render()") that any DuckDB-backed static lane (Phase 1 Hunt +
-- Agent Sweep S2 + Phase 0.75 code-reading + Phase L3/L4) MAY opportunistically, non-mandatorily
-- surface. It PERSISTS and becomes a ranked candidate direction the NEXT round picks up first;
-- it does NOT spawn work in the run that surfaced it (feed-forward only, the
-- methodology_blind_spots action model). A lead is its OWN concept — distinct from a
-- methodology_blind_spots gap (negative) and a suspicious_points region hypothesis
-- (vuln_class@region). Placed AFTER gr_findings and suspicious_points because it FKs both
-- (overlaps_finding_id / overlaps_sp_id).
--
-- promising_lanes carries NO stored composite (the promise score + est_severity weight are
-- read-time only in v_promising_lanes_ranked, mirroring the v_critical_fn_ranked /
-- v_suspicious_points_ranked never-store rule); only the raw factor signals are stored (like
-- critical_functions.factor_* / phase0_priorities.factor_*). Dedup is DB-native: the UNIQUE
-- lane_hash natural key + ON CONFLICT increments dedup_cluster_size (the suspicious_points
-- precedent). proposed_lane_kind / vuln_class are open vocab (free TEXT, per the strategy/lane
-- name doctrine); severity is the closed gr_findings vocab, carried as a NULL-permitting CHECK.
-- region_hash carries the '__TARGET_WIDE__' sentinel when the lead is unanchored. Overlaps with
-- existing trackers are flagged + down-ranked read-time, NEVER deleted (no silent loss).
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS promising_lanes (
  id INTEGER PRIMARY KEY CHECK (id > 0),
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
  -- prior-art provenance (migration 0026; nullable): set when this lead was DISTILLED from a
  -- Phase L-1 CVE / writeup. Canonical fresh-create carries the enforced FK; the upgrade path
  -- adds the column with NO inline FK (0009/0013 precedent) and put.go fkRefs pre-validates.
  derived_from_cve_id INTEGER REFERENCES cves(id),
  derived_from_writeup_id INTEGER REFERENCES writeups(id),
  lane_hash TEXT NOT NULL,                                 -- stable hash over (target_id, proposed_lane_kind, region_hash) — NK/dedup/merge key
  created_at TIMESTAMP NOT NULL,
  UNIQUE (lane_hash)
);

-- pl_severity_weight — the one place the severity→numeric mapping lives (the sp_signed_rank
-- precedent). Read-time, inspectable. NULL/unknown → 0.5 (neutral).
CREATE OR REPLACE MACRO pl_severity_weight(sev) AS
  CASE sev WHEN 'CRITICAL' THEN 1.0 WHEN 'HIGH' THEN 0.75 WHEN 'MEDIUM' THEN 0.5 WHEN 'LOW' THEN 0.25 ELSE 0.5 END;

-- v_promising_lanes_ranked — read-time ranking, NO stored score (the v_critical_fn_ranked /
-- v_suspicious_points_ranked / v_promise_ranked precedent). promise = novelty × est_severity ×
-- reachability_prior × ledger_history_factor (the Perpetual Loop formula), COALESCE-neutral so
-- a sparsely-scored lead still ranks. Ordering is ordinal: unconsumed directions first →
-- not-already-covered first → promise DESC → dedup_cluster_size DESC → created_at.
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
-- v_promise_ranked (migration 0021) — Perpetual Loop SALIENCE GATE. Read-time, within-round
-- percentile ranking of the round's divergent candidates by the promise formula
--   promise = novelty × est_severity × reachability_prior × ledger_history_factor
-- NO stored score, NO new table — mirrors the v_suspicious_points_ranked / v_critical_fn_ranked
-- never-store rule and ranks the existing suspicious_points the DMN register emitted. The
-- four promise factors are derived from columns that already exist:
--   • novelty            ← suspicious_points: NOT yet graduated AND low merge count. A region
--                          never promoted to a finding and rarely re-seen is the under-explored
--                          (novel) end. Mapped as 1/dedup_cluster_size, floored at the graduated
--                          set (graduated => novelty contribution 0; the loop wants new ground).
--   • est_severity       ← suspicious_point_factor.raw_value WHERE factor_name='dangerous_sink_class'
--                          (the sink-danger raw signal; the only pre-Confirm severity proxy we
--                          store — true severity is set later by Confirm/Proof on gr_findings).
--   • reachability_prior ← suspicious_point_factor.raw_value WHERE factor_name='reachable_from_entry'
--                          (the existing Source-1 reachability GATE raw value, reused as a prior).
--   • ledger_history_factor ← suspicious_point_factor.raw_value WHERE factor_name='factor_recurrence_prior'
--                          (the cross-round round-feed-forward / round_ledger recurrence signal;
--                          this IS the ledger-bias input — no new ledger column).
-- Each factor is percentile-ranked within (target_id, round_id) so the product is scale-free
-- and the top-K promotion is deterministic; degenerate population (n<=1 OR zero-variance) →
-- neutral 0.5 (the v_suspicious_points_ranked rule). A missing factor row → neutral 0.5 so a
-- candidate is never silently floored to 0 by a producer that has not run yet.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_promise_ranked AS
WITH base AS (
  SELECT
    sp.id AS sp_id,
    sp.target_id,
    sp.round_id,
    sp.symbol_path,
    sp.vuln_class,
    sp.lane,
    sp.graduated_finding_id,
    -- novelty raw: under-explored regions score high; already-graduated regions score 0.
    CASE WHEN sp.graduated_finding_id IS NOT NULL THEN 0.0
         ELSE 1.0 / GREATEST(COALESCE(sp.dedup_cluster_size, 1), 1) END AS novelty_raw,
    MAX(CASE WHEN spf.factor_name = 'dangerous_sink_class'    THEN spf.raw_value END) AS est_severity_raw,
    MAX(CASE WHEN spf.factor_name = 'reachable_from_entry'    THEN spf.raw_value END) AS reachability_raw,
    MAX(CASE WHEN spf.factor_name = 'factor_recurrence_prior' THEN spf.raw_value END) AS ledger_raw
  FROM suspicious_points sp
  LEFT JOIN suspicious_point_factor spf ON spf.sp_id = sp.id
  GROUP BY sp.id, sp.target_id, sp.round_id, sp.symbol_path, sp.vuln_class,
           sp.lane, sp.graduated_finding_id, sp.dedup_cluster_size
),
ranked AS (
  SELECT
    *,
    PERCENT_RANK() OVER (PARTITION BY target_id, round_id ORDER BY novelty_raw)                       AS novelty_pr,
    PERCENT_RANK() OVER (PARTITION BY target_id, round_id ORDER BY COALESCE(est_severity_raw, 0))      AS severity_pr,
    PERCENT_RANK() OVER (PARTITION BY target_id, round_id ORDER BY COALESCE(reachability_raw, 0))      AS reach_pr,
    PERCENT_RANK() OVER (PARTITION BY target_id, round_id ORDER BY COALESCE(ledger_raw, 0))            AS ledger_pr,
    COUNT(*) OVER (PARTITION BY target_id, round_id) AS pop_n
  FROM base
)
SELECT
  sp_id,
  target_id,
  round_id,
  symbol_path,
  vuln_class,
  lane,
  graduated_finding_id,
  -- degenerate population (n<=1) → neutral 0.5 per factor (the percentile-rank precedent).
  (CASE WHEN pop_n <= 1 THEN 0.5 ELSE novelty_pr  END) AS novelty,
  (CASE WHEN pop_n <= 1 THEN 0.5 ELSE severity_pr END) AS est_severity,
  (CASE WHEN pop_n <= 1 THEN 0.5 ELSE reach_pr    END) AS reachability_prior,
  (CASE WHEN pop_n <= 1 THEN 0.5 ELSE ledger_pr   END) AS ledger_history_factor,
  (CASE WHEN pop_n <= 1 THEN 0.5 ELSE novelty_pr  END)
    * (CASE WHEN pop_n <= 1 THEN 0.5 ELSE severity_pr END)
    * (CASE WHEN pop_n <= 1 THEN 0.5 ELSE reach_pr    END)
    * (CASE WHEN pop_n <= 1 THEN 0.5 ELSE ledger_pr   END) AS promise
FROM ranked
ORDER BY promise DESC, sp_id;

------------------------------------------------------------
-- file_vuln_ratings (migration 0012) — C4 preliminary per-FILE P(critical/high)
-- rating that ORDERS (never gates) the Phase-0 audit worklist and reranks as
-- analysis surfaces signal. COMPANION TABLE rather than a phase0_priorities
-- extension because phase0_priorities.artifact_kind is a CLOSED CHECK
-- ('source','sink','defense','slice','critical_function') DuckDB cannot widen in
-- place — the spec's "closed CHECK = unavoidable new table" trigger. The unit is the
-- FILE (the file's AST is evidence the heuristic/LLM reads, not a separate score).
-- Stores RAW factors only; the composite is read-time in v_file_vuln_ranked
-- (mirrors v_suspicious_points_ranked / v_critical_fn_ranked no-stored-score rule).
-- A cheap heuristic rates EVERY in-scope file (reusing attention-deficit signals);
-- LLM triage is spent only on the ambiguous MIDDLE band. ORDER-ONLY: no row is ever
-- excluded — low scores just sort last. band is the one closed vocab, NULL-permitting
-- CHECK here (the upgrade path 0012 adds it with NO CHECK and enforces app-side).
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS file_vuln_ratings (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  round_id INTEGER REFERENCES round_ledger(id),
  agent_step_id INTEGER REFERENCES agent_steps(id),
  file_path TEXT NOT NULL,
  band TEXT
    CHECK (band IS NULL OR band IN ('hot', 'cold', 'ambiguous')),  -- hot/cold = settled by cheap heuristic; ambiguous = sent to LLM triage
  -- Preliminary scores (RAW factors; composite computed read-time).
  heuristic_score REAL,          -- cheap heuristic P(crit/high), every file
  llm_score REAL,                -- LLM-triage P(crit/high), ambiguous-middle band only
  -- Cheap-heuristic raw factors (reuse the attention-deficit signal family).
  factor_security_commit_churn REAL,  -- recent security-relevant commit density
  factor_test_coverage_inverse REAL,  -- inverse of fuzzing/testing presence
  factor_code_glamour REAL,           -- parser/crypto/auth/serialization "glamour"
  factor_external_exposure REAL,      -- attacker-reachable entry surface
  factor_code_age REAL,               -- staleness / un-revisited age signal
  factor_cpg_signal REAL,             -- available CPG/static signal (optional producer)
  -- Analysis-derived feedback factors (start NULL; filled as analysis surfaces
  -- signal -> the view reranks; a cold file can escalate to hot).
  factor_sp_region_density REAL,      -- suspicious_points anchored in this file
  factor_finding_proximity REAL,      -- gr_findings in / near this file
  factor_reachable_sink_count REAL,   -- reachable sinks located in this file
  created_at TIMESTAMP,
  UNIQUE (target_id, round_id, file_path)
);

-- v_file_vuln_ranked (migration 0012) — read-time hottest-first ordering. NEVER
-- stores a composite (mirrors v_suspicious_points_ranked). Within each
-- (target_id, round_id) the raw factors are PERCENT_RANK()'d and summed with fixed
-- weights; the preliminary heuristic/LLM scores AND the analysis-derived feedback
-- factors all contribute, so reranking is automatic as the feedback columns fill.
-- ORDER-ONLY: every rated file appears (no WHERE drops rows); low scores sort last.
-- llm_score COALESCEs over heuristic_score so heuristic-settled files still carry
-- their preliminary signal. Degenerate single-file population -> neutral 0.5.
CREATE OR REPLACE VIEW v_file_vuln_ranked AS
WITH ranked AS (
  SELECT
    fvr.id,
    fvr.target_id,
    fvr.round_id,
    fvr.file_path,
    fvr.band,
    COALESCE(fvr.llm_score, fvr.heuristic_score) AS prelim_score,
    PERCENT_RANK() OVER (PARTITION BY fvr.target_id, fvr.round_id ORDER BY COALESCE(fvr.llm_score, fvr.heuristic_score)) AS r_prelim,
    PERCENT_RANK() OVER (PARTITION BY fvr.target_id, fvr.round_id ORDER BY COALESCE(fvr.factor_sp_region_density, 0))    AS r_sp,
    PERCENT_RANK() OVER (PARTITION BY fvr.target_id, fvr.round_id ORDER BY COALESCE(fvr.factor_finding_proximity, 0))    AS r_find,
    PERCENT_RANK() OVER (PARTITION BY fvr.target_id, fvr.round_id ORDER BY COALESCE(fvr.factor_reachable_sink_count, 0)) AS r_sink,
    COUNT(*) OVER (PARTITION BY fvr.target_id, fvr.round_id) AS pop_n
  FROM file_vuln_ratings fvr
)
SELECT
  id,
  target_id,
  round_id,
  file_path,
  band,
  prelim_score,
  CASE WHEN pop_n <= 1 THEN 0.5 ELSE
    0.55 * r_prelim
  + 0.20 * r_sp
  + 0.15 * r_find
  + 0.10 * r_sink
  END AS rank_score
FROM ranked;

------------------------------------------------------------
-- Refutations (§2.4)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS refutations (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  finding_id INTEGER NOT NULL REFERENCES gr_findings(id),
  agent_step_id INTEGER NOT NULL REFERENCES agent_steps(id),
  refutation_reason TEXT NOT NULL
    CHECK (refutation_reason IN (
      'not_reachable',
      'sanitized',
      'intended_feature',
      'wrong_role',
      'preconditions_unmet',
      'env_required',
      'other'
    )),
  evidence_json TEXT,
  created_at TIMESTAMP NOT NULL,
  UNIQUE (finding_id, agent_step_id, refutation_reason)
);

------------------------------------------------------------
-- Audit outcomes (§2.4, A3a, R7)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_outcomes (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  audit_run_id TEXT NOT NULL,
  outcome TEXT NOT NULL
    CHECK (outcome IN ('TP', 'FP', 'DUP', 'INTENDED', 'UNREACHABLE', 'INCONCLUSIVE')),
  finding_id INTEGER REFERENCES gr_findings(id),
  notes_json TEXT,
  created_at TIMESTAMP NOT NULL,
  UNIQUE (audit_run_id, finding_id)
);

------------------------------------------------------------
-- Critic findings (§2.5, C4, R2)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS critic_findings (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  finding_id INTEGER NOT NULL REFERENCES gr_findings(id),
  check_kind TEXT NOT NULL
    CHECK (check_kind IN ('comprehension', 'eligibility', 'attack_scenario')),
  severity TEXT NOT NULL
    CHECK (severity IN ('OK', 'INFO', 'WARNING', 'CRITICAL')),
  message TEXT NOT NULL,
  evidence_json TEXT,
  created_at TIMESTAMP NOT NULL,
  UNIQUE (finding_id, check_kind)
);

------------------------------------------------------------
-- Defense bypasses (§2.7, S2/S3)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS defense_bypasses (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  defense_id INTEGER NOT NULL REFERENCES defenses(id),
  agent_step_id INTEGER NOT NULL REFERENCES agent_steps(id),
  technique TEXT NOT NULL,
  -- bypass_family: catalogue family id from db/catalogue/bypasses.json (e.g.
  -- 'sanitizer.double_encoding'). `technique` is the human label; bypass_family
  -- is the catalogue-anchored key used for cross-round reuse + dedup (S2).
  bypass_family TEXT,
  payload TEXT,
  payload_sidecar_path TEXT,
  -- parsed_logic_json: the defense's parsed decision logic this bypass defeats
  -- (snapshot of defenses.parsed_logic_json at attempt time).
  parsed_logic_json TEXT,
  -- exhaustion_log: proof the technique space was covered for this defense —
  -- which catalogue families were tried/skipped and why. See
  -- references/v2/bypass-catalogue.md § Exhaustion Log.
  exhaustion_log TEXT,
  severity TEXT NOT NULL
    CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
  reproduced BOOLEAN NOT NULL,
  sink_reach_finding_id INTEGER REFERENCES gr_findings(id),
  isolation_harness_ran BOOLEAN NOT NULL,
  isolation_findings_json TEXT,
  -- stage_reached: how deep the hunt went on this defense (depth ladder).
  stage_reached TEXT, -- free TEXT (no CHECK): bypass lanes emit richer depth labels (e.g. exploit_constructed, exhausted, confirmed_safe, theory); canonical ladder is stage_a/stage_b/stage_c/isolation_fuzz but the column does not enforce it
  -- Feed-forward linkage (Ask 5): a reproduced bypass spawns bypass_derived
  -- sources and re-enters Hunt. cascade_emitted_* record what it emitted so a
  -- later round or the critic can trace the cascade. carried_from_bypass_id +
  -- round_id support cross-round reuse: a prior round's bypass pre-seeds this one.
  cascade_emitted_finding_ids TEXT,
  cascade_emitted_source_ids TEXT,
  carried_from_bypass_id INTEGER REFERENCES defense_bypasses(id),
  round_id INTEGER REFERENCES round_ledger(id),
  -- Sanitizer-bypass classification (migration 0009, html_sanitizer_bypass_lane).
  -- Closed enums (NULL-permitting CHECK, effort_tier precedent); the upgrade path
  -- (0009) adds these with NO CHECK and enforces app-side.
  sink_reached TEXT
    CHECK (sink_reached IS NULL OR sink_reached IN ('script_exec', 'event_handler', 'url_scheme', 'css_expression', 'dom_clobbering')),
  capability TEXT
    CHECK (capability IS NULL OR capability IN ('xss_exec', 'open_redirect', 'html_injection')),
  injection_context TEXT
    CHECK (injection_context IS NULL OR injection_context IN ('html_text', 'attribute_value', 'url_attr', 'css', 'js_context')),
  input_vector TEXT
    CHECK (input_vector IS NULL OR input_vector IN ('markdown_link', 'img_src', 'autolink', 'raw_html', 'url_param')),
  -- payload_technique / corpus_category are FREE TEXT (no CHECK on either path):
  -- the vocabulary grows as the corpus is augmented (CHECK-vs-free-TEXT doctrine).
  -- Canonical/initial payload_technique vocabulary: double_encoding, mxss,
  -- mutation_xss, namespace_confusion, comment_breakout, attribute_breakout,
  -- protocol_smuggling, charset_confusion, nesting_overflow, malformed_markup.
  -- Canonical corpus_category = the source family filename (corpus_data/<family>.json).
  payload_technique TEXT,
  corpus_category TEXT,
  -- Concolic guard-evasion specifics (migration 0013, concolic_bypass_lane).
  -- concolic_solver is a closed engine enum (NULL-permitting CHECK; the upgrade path
  -- (0013) adds it with NO CHECK and enforces app-side). guard_kind is the closed
  -- guard-category vocab. The human technique label reuses the existing free-TEXT
  -- payload_technique; the solver's path-constraint log reuses exhaustion_log.
  concolic_solver TEXT
    CHECK (concolic_solver IS NULL OR concolic_solver IN ('klee', 'symcc', 'symqemu', 'jdart', 'coastal', 'other')),
  guard_kind TEXT
    CHECK (guard_kind IS NULL OR guard_kind IN ('regex', 'sanitizer', 'length_check', 'allowlist', 'denylist', 'other')),
  bypass_hash TEXT NOT NULL,
  UNIQUE (bypass_hash)
);

------------------------------------------------------------
-- sanitizer_bypass_runs (migration 0009) — one aggregate row per sanitizer
-- (defense) corpus run of the html_sanitizer_bypass_lane. 3-valued run_verdict:
-- 'bypassed' (>=1 payload reached a live sink for its injection_context),
-- 'clean' (full corpus, 0 hits — first-class stored robustness result; later
-- rounds read an existing clean verdict for the same (defense, corpus_version)
-- and skip re-running — the Parsedown 46k->0 case), 'inconclusive' (isolate /
-- harness error; inconclusive_reason set). emitted_bypass_ids is a JSON array of
-- the defense_bypasses.id rows this run produced. injection_contexts_json records
-- which injection contexts were exercised. Created after defense_bypasses so the
-- defenses / agent_steps / round_ledger FK parents all exist.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sanitizer_bypass_runs (
  id INTEGER PRIMARY KEY CHECK (id > 0),
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
-- Fuzzing lane (Phase 1.5, DEEP-only). Each row is one fuzz run against one
-- entry point: the engine + sanitizer config, whether a pre-existing pipeline
-- was reused, coverage/skip accounting, and the crashes/divergences it emitted.
-- Results themselves are gr_findings rows (finding_kind='fuzz_crash' or
-- 'fuzz_divergence'); this table is the
-- per-run metadata + mandatory-attempt accounting. See references/v2/fuzzing-lane.md.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fuzz_runs (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  agent_step_id INTEGER NOT NULL REFERENCES agent_steps(id),
  -- entry_point: the harnessed boundary fuzzed (parser fn, FFI shim, decoder,
  -- protocol/session handler).
  -- NULL only on a skipped run (skip_reason set, coverage_json explains why).
  entry_point TEXT,
  -- engine: fuzzer/driver used — 'afl++', 'libfuzzer', 'honggfuzz', 'cargo-fuzz',
  -- 'go-test-fuzz', 'jazzer', 'klee', 'symcc', 'miri', or 'none' on a skip.
  engine TEXT NOT NULL,
  -- sanitizers: JSON array of sanitizers enabled — e.g. '["asan","ubsan"]',
  -- '["msan"]', '["jazzer"]'. JSON-in-TEXT to match the schema's other array
  -- columns (cascade_emitted_*); '[]' on a skip.
  sanitizers TEXT,
  -- reused_existing_pipeline: TRUE when recon found prior fuzzing infra
  -- (OSS-Fuzz target, in-tree fuzz harness, seed corpus) and this run reused it
  -- rather than building fresh. The lane MUST check for this first.
  reused_existing_pipeline BOOLEAN NOT NULL DEFAULT FALSE,
  -- existing_pipeline: JSON snapshot of the recon — what fuzzing infra already
  -- existed (oss_fuzz, in_tree_targets[], corpora_paths[], build_integration).
  existing_pipeline TEXT,
  -- coverage_json: the fuzz_coverage_json contract — {surface, attempted[],
  -- reason, edges, runtime_s}. On a skip it records the non-fuzzable surface and
  -- why (mirrors defense_bypasses.exhaustion_log). The orchestrator verifies this
  -- log before accepting the lane as exhausted.
  coverage_json TEXT,
  -- skip_reason: set when the mandatory lane was skipped on a non-fuzzable target.
  -- Canonical values: 'no_native_code', 'no_parsers_or_ffi', 'interpreted_only',
  -- 'no_harnessable_entrypoint', 'no_stateful_protocol_surface',
  -- 'no_harnessable_state_oracle', 'env_unavailable', 'other'. Free TEXT (no CHECK)
  -- so the value set can grow without a DuckDB constraint rebuild.
  skip_reason TEXT,
  crash_count INTEGER NOT NULL DEFAULT 0,
  -- emitted_finding_ids: JSON array of gr_findings.id rows this run produced
  -- (finding_kind='fuzz_crash' or 'fuzz_divergence'), so a result traces back to its run. Parallels
  -- defense_bypasses.cascade_emitted_finding_ids.
  emitted_finding_ids TEXT,
  round_id INTEGER REFERENCES round_ledger(id),
  created_at TIMESTAMP,
  fuzz_run_hash TEXT NOT NULL,
  UNIQUE (fuzz_run_hash)
);

------------------------------------------------------------
-- Fuzz artifacts / resumability (schema v8). Each row is a content-addressed
-- seed, retained corpus input, dictionary, checkpoint, engine-state summary,
-- symbolic testcase, state trace, or crash/divergence reproducer associated with
-- a fuzz run. Store retained/resumable artifacts, not every attempted mutation
-- by default; all large/binary payloads spill through db/sidecars/<hash>.
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fuzz_artifacts (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  fuzz_run_id INTEGER REFERENCES fuzz_runs(id),
  agent_step_id INTEGER REFERENCES agent_steps(id),
  round_id INTEGER REFERENCES round_ledger(id),
  -- artifact_kind is free TEXT. Canonical values include: seed_initial,
  -- seed_retained, seed_symbolic, seed_replay, corpus_manifest,
  -- queue_checkpoint, dictionary, engine_state, coverage_frontier, state_trace,
  -- crash_reproducer, attempted_input_sample.
  artifact_kind TEXT NOT NULL,
  label TEXT,
  content_hash TEXT NOT NULL,
  payload TEXT,
  payload_sidecar_path TEXT,
  metadata_json TEXT,
  parent_content_hash TEXT,
  created_at TIMESTAMP,
  UNIQUE (target_id, artifact_kind, content_hash)
);

------------------------------------------------------------
-- Autoloading knowledge layer (§2.6, C3)
------------------------------------------------------------
CREATE TABLE IF NOT EXISTS knowledge_chunks (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  source TEXT NOT NULL,
  chunk_key TEXT NOT NULL,
  body TEXT NOT NULL,
  version INTEGER NOT NULL,
  UNIQUE (source, chunk_key, version)
);

CREATE TABLE IF NOT EXISTS knowledge_seed_log (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  agent_step_id INTEGER NOT NULL REFERENCES agent_steps(id),
  chunk_id INTEGER NOT NULL REFERENCES knowledge_chunks(id),
  loaded_at TIMESTAMP NOT NULL,
  load_mode TEXT NOT NULL
    CHECK (load_mode IN ('seed', 'expand'))
);

CREATE TABLE IF NOT EXISTS knowledge_acceptance (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  chunk_id INTEGER NOT NULL REFERENCES knowledge_chunks(id),
  ref_count INTEGER NOT NULL,
  repeat_suppressions INTEGER NOT NULL,
  staleness_days INTEGER NOT NULL,
  growth_rate REAL,
  accepted BOOLEAN NOT NULL,
  decided_at TIMESTAMP NOT NULL
);

------------------------------------------------------------
-- Eval harness (Tier 1 measurement) — COMPLEMENTARY benchmarking, not the
-- product. The prose methodology finds bugs; these tables just score whether a
-- methodology change moved recall / FP-per-KLOC against a labeled CVE corpus.
-- Design: docs/superpowers/specs/2026-05-21-eval-harness-design.md
-- Decoupled from the audit: the harness emits a manifest and ingests whatever
-- gr_findings the prose audit produced — it never spawns an audit itself.
------------------------------------------------------------

-- One labeled target + its clean control + ground-truth fix hunks (inline JSON).
-- Vulnerable target = vuln_commit (fix_commit~1); clean control = fix_commit.
CREATE TABLE IF NOT EXISTS eval_corpus (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  source TEXT NOT NULL
    CHECK (source IN ('cvefixes', 'vul4j', 'primevul', 'custom')),
  cve_id TEXT NOT NULL,
  repo_url TEXT NOT NULL,
  vuln_commit TEXT NOT NULL,           -- fix_commit~1: the bug is present here
  fix_commit TEXT NOT NULL,            -- the clean control: bug provably gone
  primary_cwe TEXT,
  language TEXT,
  -- ground_truth_json: [{file,line_start,line_end,cwe,is_primary}] — the fix
  -- hunk(s); exactly one entry flagged is_primary for the target-level rollup.
  ground_truth_json TEXT NOT NULL,
  added_at TIMESTAMP NOT NULL,
  UNIQUE (source, cve_id, repo_url)
);

-- One ingested audit result for a (corpus, mode, seed). findings_json is a
-- snapshot of the audit's gr_findings resolved to file/line + derived CWE.
CREATE TABLE IF NOT EXISTS eval_run (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  corpus_id INTEGER NOT NULL REFERENCES eval_corpus(id),
  manifest_uid TEXT NOT NULL,          -- groups the runs emitted by one manifest
  mode TEXT NOT NULL
    CHECK (mode IN ('vuln', 'control')),
  seed INTEGER NOT NULL,
  tier TEXT
    CHECK (tier IS NULL OR tier IN ('low', 'medium', 'deep')),
  kloc_scanned REAL,
  -- findings_json: [{hash,kind,cwe,file,line,severity,status}]
  findings_json TEXT NOT NULL,
  ingested_at TIMESTAMP NOT NULL,
  UNIQUE (manifest_uid, corpus_id, mode, seed)
);

-- Computed metrics + match decisions for one manifest (overall + per-target).
-- Two-track: recall on vuln targets, fp_per_kloc on clean controls only.
CREATE TABLE IF NOT EXISTS eval_result (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  manifest_uid TEXT NOT NULL,
  scope TEXT NOT NULL
    CHECK (scope IN ('overall', 'target')),
  scope_key TEXT NOT NULL,             -- 'all' for overall, else corpus_id
  recall_at_1 REAL,
  recall_at_k REAL,
  fp_per_kloc REAL,
  refound_fixed_rate REAL,             -- controls that re-flag the fixed location
  -- matches_json: [{finding_hash,gt_idx,grade,decided_by,rationale}]
  matches_json TEXT,
  computed_at TIMESTAMP NOT NULL,
  UNIQUE (manifest_uid, scope, scope_key)
);

------------------------------------------------------------
-- Knowledge architecture (B5, migration 0005). Six DB-native mechanisms:
-- #1 finding-identity, #2 recurrence-rank, #3 codebase-knowledge,
-- #4 intelligent-fetch, #5 external-knowledge, #6 db-metalogging.
-- Spec: .omc/specs/deep-interview-vr-knowledge-arch.md. Principles: determinism by
-- construction (weights externalized to scoring_config — knobs, not magic constants),
-- append-only history (sightings + mutation_log), content-addressed sidecars reused.
------------------------------------------------------------

-- #4/#5/#2 — the single shared weight surface; every read-time score joins it.
CREATE TABLE IF NOT EXISTS scoring_config (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  scope TEXT NOT NULL
    CHECK (scope IN ('rank_score', 'acceptance', 'recurrence')),
  config_key TEXT NOT NULL,
  weight REAL NOT NULL,
  description TEXT,
  UNIQUE (scope, config_key)
);

INSERT INTO scoring_config (id, scope, config_key, weight, description) VALUES
  (1,  'rank_score', 'w_reachability',       0.25, 'critical_functions.factor_reachability'),
  (2,  'rank_score', 'w_blast_radius',       0.22, 'critical_functions.factor_blast_radius'),
  (3,  'rank_score', 'w_privilege_delta',    0.18, 'critical_functions.factor_privilege_delta'),
  (4,  'rank_score', 'w_attention_deficit',  0.13, 'critical_functions.factor_attention_deficit'),
  (5,  'rank_score', 'w_bypass_prior',       0.10, 'critical_functions.factor_bypass_prior'),
  (6,  'rank_score', 'w_recurrence_prior',   0.12, 'critical_functions.factor_recurrence_prior (#2)'),
  (7,  'acceptance', 'w_ref_count',          0.40, 'knowledge_acceptance.ref_count (+)'),
  (8,  'acceptance', 'w_growth_rate',        0.20, 'knowledge_acceptance.growth_rate (+)'),
  (9,  'acceptance', 'w_staleness_days',     0.25, 'knowledge_acceptance.staleness_days (-)'),
  (10, 'acceptance', 'w_repeat_suppressions',0.15, 'knowledge_acceptance.repeat_suppressions (-)'),
  (11, 'recurrence', 'w_nbr',                0.50, 'one-hop call-neighbor propagation weight'),
  -- Hit-score weights (v0.27.0, migration 0020) — recurrence-family ranking;
  -- reuse scope='recurrence' (no CHECK widen; spec §3.1 / §8).
  -- w_rec is dominant (0.50): corroboration count is the most objective signal.
  -- w_outcome (0.25): a fact that contributed to a confirmed finding is high-value.
  -- w_reuse (0.15): objective suppression — dead_end not re-walked is proven useful.
  -- w_conf (0.10): confidence + staleness decay; lowest because it is partially subjective.
  -- approx_recall_floor: Jaccard similarity floor for v_fact_similar inclusion (0.40 = 40%).
  (12, 'recurrence', 'w_rec',                0.50, 'v_fact_hitscore: recurrence_norm weight (dominant — within-target percentile of corroboration count + recurrence_counter)'),
  (13, 'recurrence', 'w_outcome',            0.25, 'v_fact_hitscore: led_to_outcome weight — fact symbol_path lies on lineage of a confirmed gr_findings or reproduced defense_bypasses'),
  (14, 'recurrence', 'w_reuse',              0.15, 'v_fact_hitscore: reuse_effectiveness weight — dead_end seeded into a round whose symbol_path was NOT re-walked that round (absence of re-walk rows)'),
  (15, 'recurrence', 'w_conf',               0.10, 'v_fact_hitscore: confidence_decayed weight — agent_observations.confidence decayed by rounds since last corroboration'),
  (16, 'recurrence', 'approx_recall_floor',  0.40, 'v_fact_similar: minimum Jaccard similarity floor for approximate-recall inclusion (0.0=off, 1.0=exact-only); tunable per target via UPDATE')
ON CONFLICT DO NOTHING;

-- #1 finding-identity — append-only per-observation rows; commit-independent finding_hash.
CREATE TABLE IF NOT EXISTS finding_sightings (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  finding_hash TEXT NOT NULL REFERENCES gr_findings(finding_hash),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  agent_step_id INTEGER REFERENCES agent_steps(id),
  commit_sha TEXT NOT NULL,
  body_hash TEXT,
  slice_fingerprint TEXT,
  verdict TEXT NOT NULL
    CHECK (verdict IN ('candidate', 'confirmed', 'refuted', 'needs_attention')),
  change_scope TEXT
    CHECK (change_scope IS NULL OR change_scope IN ('initial', 'body_hash', 'slice_path', 'both')),
  changed_from_sighting_id INTEGER REFERENCES finding_sightings(id),
  from_commit_sha TEXT,
  from_body_hash TEXT,
  from_slice_fingerprint TEXT,
  observed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  sighting_hash TEXT NOT NULL,
  UNIQUE (sighting_hash)
);

-- #3 (3b substrate) — resolved Joern-CPG call/dataflow edges; only resolved edges inserted.
CREATE TABLE IF NOT EXISTS call_edges (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  caller_symbol TEXT NOT NULL,
  callee_symbol TEXT NOT NULL,
  edge_kind TEXT NOT NULL
    CHECK (edge_kind IN ('call', 'dataflow')),
  edge_hash TEXT NOT NULL,
  UNIQUE (edge_hash)
);

-- #3 (3a) — systemic-weakness rollup; `systemic` is a passive generated flag (no ranking influence).
CREATE TABLE IF NOT EXISTS weakness_classes (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  bug_class TEXT NOT NULL,
  sink_category TEXT NOT NULL,
  seen_count INTEGER NOT NULL DEFAULT 0,
  systemic BOOLEAN GENERATED ALWAYS AS (seen_count >= 3) VIRTUAL,
  wc_hash TEXT NOT NULL,
  UNIQUE (wc_hash)
);

-- #2 recurrence-rank — the materialized confirmation-weighted accumulator (orchestrator UPDATEs).
CREATE TABLE IF NOT EXISTS recurrence_counter (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id),
  finding_hash TEXT,
  symbol_path TEXT NOT NULL,
  counter REAL NOT NULL DEFAULT 0,
  neighbor_boost REAL NOT NULL DEFAULT 0,
  last_status TEXT,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  counter_key TEXT NOT NULL,
  UNIQUE (counter_key)
);

-- #6 db-metalogging — append-only per-mutation audit (UPDATEs + status transitions only).
CREATE TABLE IF NOT EXISTS mutation_log (
  id INTEGER PRIMARY KEY CHECK (id > 0),
  target_id INTEGER REFERENCES targets(id),
  table_name TEXT NOT NULL,
  row_key TEXT NOT NULL,
  op TEXT NOT NULL
    CHECK (op IN ('update', 'status_transition')),
  delta_json TEXT NOT NULL,
  round_id INTEGER REFERENCES round_ledger(id),
  phase TEXT,
  agent_step_id INTEGER REFERENCES agent_steps(id),
  tx_id TEXT,
  mutated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  mutation_hash TEXT NOT NULL,
  UNIQUE (mutation_hash)
);

------------------------------------------------------------
-- impact_proofs (v0.40.0, migration 0029, T2-07 / S-P02/S-P04/S-V11). The
-- CONSUMER-HARM ledger: one row per confirmed finding naming the default-config
-- component that READS / DISPATCHES / TRUSTS the tainted value and the harm it
-- suffers. A sink reached is NOT a consumer harmed (Gate 5 doctrine, T1-02): a
-- confirmed finding with NO impact_proofs row is UNJUSTIFIED (v_justification_coverage,
-- v_promotion_coverage). severity is a CONTRACT, not an automatic function: the Confirm agent
-- MUST DERIVE severity from the exploitability-gate rubric over this proof's
-- harm_class × proven_reachability × mechanism_cap and RECORD that derivation in severity_basis
-- (the harness does not compute severity — it records the agent-derived rating + its basis).
--   • consumer_symbol      — the default-config component harmed (sink-less authz/IDOR
--                            classes name the privileged operation reached past the guard).
--   • harm_class           — open vocab (rce|info_leak|dos|authz_bypass|ssrf|data_tamper|…);
--                            free TEXT because the harm taxonomy evolves per attack domain.
--   • reachability_evidence_ref — pointer (observation/slice/critical_fn_reach/PoC id) proving
--                            the consumer is reachable under default config.
--   • proven_reachability  — closed tri-state: how strong the reachability evidence is.
--   • mechanism_cap        — closed vocab: the build-hardening ceiling on the primitive
--                            (dos_only = hardened-allocator/bounds-checked container/sanitizer
--                            abort caps memory-unsafety at DoS; leak = raw-pointer/memcpy/linear
--                            write retains info-leak; write_what_where = proven arbitrary write;
--                            none = no mechanism cap applies, e.g. logic/authz classes).
--   • severity_basis       — free-TEXT note recording how severity was derived from the rubric.
-- DuckDB cannot widen the inline CHECKs on the upgrade path, so migration 0029 creates the
-- table with the same inline CHECKs ONLY on a fresh v2 DB (the table is NEW, so the fresh
-- CREATE carries them in both schema.sql and the migration).
------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS seq_impact_proofs START 1;
CREATE TABLE IF NOT EXISTS impact_proofs (
  id INTEGER PRIMARY KEY DEFAULT nextval('seq_impact_proofs') CHECK (id > 0),
  finding_id INTEGER NOT NULL REFERENCES gr_findings(id) CHECK (finding_id > 0),
  consumer_symbol TEXT NOT NULL,             -- default-config component that reads/dispatches/trusts the value
  harm_class TEXT NOT NULL,                  -- OPEN vocab: rce|info_leak|dos|authz_bypass|ssrf|data_tamper|...
  reachability_evidence_ref TEXT,            -- pointer proving the consumer is reachable under default config
  proven_reachability TEXT
    CHECK (proven_reachability IS NULL OR proven_reachability IN ('proven', 'conditional', 'unproven')),
  mechanism_cap TEXT
    CHECK (mechanism_cap IS NULL OR mechanism_cap IN ('dos_only', 'leak', 'write_what_where', 'none')),
  severity_basis TEXT,                       -- free-TEXT note: how severity was derived from the rubric
  content_fingerprint TEXT,                  -- sha256 of the semantic row (non-unique; content-checked dedup, T2-13)
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  proof_hash TEXT NOT NULL,                  -- idempotency / dedup natural key
  UNIQUE (proof_hash)
);

------------------------------------------------------------
-- closures (v0.40.0, migration 0029, T2-08 / S-P09, NEW-4). The hard pre-spawn
-- BARRIER: a typed, durable record that a surface is closed, consulted by Phase 0.5
-- roster materialization (T1-06). A lane targeting an open closure whose reopen_condition
-- has NOT fired is scheduled 'skipped', not run — closure is a scheduling constraint, not
-- advice. Re-opening requires the reopen_condition to FIRE (e.g. the code under the slice
-- moved), never an LLM's discretion. The negative-result stopping rule (T1-13) writes a
-- closures row after N clean attempts on a channel so sunk-cost escalation stops.
--   • surface_hash    — stable hash of the closed surface (symbol/region/strategy-family).
--   • closure_kind    — closed tri-vocab: dead_end | exhausted | refuted_class.
--   • closed_in_round — the round_ledger row that closed it (feed-forward provenance).
--   • reopen_condition — free TEXT: the concrete fact that must fire to reopen (e.g.
--                        'code under src/x moved since <sha>'); NULL = permanently closed.
------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS seq_closures START 1;
CREATE TABLE IF NOT EXISTS closures (
  id INTEGER PRIMARY KEY DEFAULT nextval('seq_closures') CHECK (id > 0),
  target_id INTEGER NOT NULL REFERENCES targets(id) CHECK (target_id > 0),
  surface_hash TEXT NOT NULL,                -- stable hash of the closed surface
  closure_kind TEXT NOT NULL
    CHECK (closure_kind IN ('dead_end', 'exhausted', 'refuted_class')),
  closed_in_round INTEGER REFERENCES round_ledger(id) CHECK (closed_in_round IS NULL OR closed_in_round > 0),
  reopen_condition TEXT,                      -- free TEXT: fact that must fire to reopen; NULL = permanent
  evidence_ref TEXT,                          -- pointer to the attempts/observations that justified closure
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (target_id, surface_hash, closure_kind)   -- NK: one closure per (target, surface, kind)
);

------------------------------------------------------------
-- sp_spawn_decisions (v0.40.0, migration 0029, T2-09 / S-D03). Makes the SP ranking a
-- CONSUMED artifact: the orchestrator MUST write one row each time it picks (or declines)
-- a lane for a suspicious_point in a round. Without this, v_suspicious_points_ranked is a
-- read-time sort key wired to no spawn decision — the ranking has zero effect unless some
-- agent voluntarily queries it. The v_coverage.ranked_sps_never_consumed metric (T2-04)
-- goes RED when a gate_ok top-K SP in a round has no decision row, surfacing an unconsumed
-- ranking. rank_at_decision snapshots the composite rank at pick time (the score is never
-- stored on suspicious_points; this is the only persisted rank trace).
------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS seq_sp_spawn_decisions START 1;
CREATE TABLE IF NOT EXISTS sp_spawn_decisions (
  id INTEGER PRIMARY KEY DEFAULT nextval('seq_sp_spawn_decisions') CHECK (id > 0),
  sp_id INTEGER NOT NULL REFERENCES suspicious_points(id) CHECK (sp_id > 0),
  round_id INTEGER REFERENCES round_ledger(id) CHECK (round_id IS NULL OR round_id > 0),
  rank_at_decision INTEGER,                   -- composite rank snapshot at pick time (1 = top)
  spawned BOOLEAN NOT NULL,                   -- TRUE = a lane was spawned for this SP; FALSE = declined
  decided_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (sp_id, round_id)                    -- NK: one decision per (SP, round)
);

------------------------------------------------------------
-- Per-table sequences (v0.40.0, migration 0029, T2-10 / S-D04, S-D08) + content_fingerprint
-- (T2-13 / S-D07). Two ADDITIVE retrofits to the existing tables, applied after every
-- CREATE TABLE above so the targets exist:
--
--   (1) SEQUENCES. Each id PK gets its own DuckDB sequence and a DEFAULT nextval(...), so
--       the harness no longer needs the app-side COALESCE(MAX(id),0)+1 read (Tier 3 T3-08)
--       whose concurrent-reader race silently DROPS rows under ON CONFLICT DO NOTHING. Each
--       table gets its OWN id-space, so a transposed id from another table is far more likely
--       out-of-range and caught by FK pre-validation. The DEFAULT only fires for inserts that
--       OMIT id; the harness still MAY pass an explicit id (back-compat), so this is purely
--       additive. DuckDB ≥0.9 supports CREATE SEQUENCE + ALTER COLUMN … SET DEFAULT; both are
--       additive DDL that works on a fresh build AND (per migration 0029) on the upgrade path.
--   (2) content_fingerprint. sha256 of the full SEMANTIC row (NON-unique), so the harness can,
--       on an ON CONFLICT against a *_hash / NK, COMPARE bodies and REJECT a hash-collision
--       whose content differs (Tier 3 T3-04) instead of silently DROPPING a distinct bug
--       (the "3 crashes → 1 row" over-dedup). Added to every hash-keyed table. NULL-permitting
--       (the harness fills it; legacy rows stay NULL). Purely additive ADD COLUMN.
--
-- NK-only tables without a *_hash column (suspicious_points uses a composite NK) still get a
-- fingerprint so the content-checked-dedup path is uniform.
------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS seq_targets START 1;
ALTER TABLE targets ALTER COLUMN id SET DEFAULT nextval('seq_targets');
CREATE SEQUENCE IF NOT EXISTS seq_round_ledger START 1;
ALTER TABLE round_ledger ALTER COLUMN id SET DEFAULT nextval('seq_round_ledger');
CREATE SEQUENCE IF NOT EXISTS seq_sources START 1;
ALTER TABLE sources ALTER COLUMN id SET DEFAULT nextval('seq_sources');
CREATE SEQUENCE IF NOT EXISTS seq_sinks START 1;
ALTER TABLE sinks ALTER COLUMN id SET DEFAULT nextval('seq_sinks');
CREATE SEQUENCE IF NOT EXISTS seq_defenses START 1;
ALTER TABLE defenses ALTER COLUMN id SET DEFAULT nextval('seq_defenses');
CREATE SEQUENCE IF NOT EXISTS seq_regexes START 1;
ALTER TABLE regexes ALTER COLUMN id SET DEFAULT nextval('seq_regexes');
CREATE SEQUENCE IF NOT EXISTS seq_critical_functions START 1;
ALTER TABLE critical_functions ALTER COLUMN id SET DEFAULT nextval('seq_critical_functions');
CREATE SEQUENCE IF NOT EXISTS seq_strategies START 1;
ALTER TABLE strategies ALTER COLUMN id SET DEFAULT nextval('seq_strategies');
CREATE SEQUENCE IF NOT EXISTS seq_input_slices START 1;
ALTER TABLE input_slices ALTER COLUMN id SET DEFAULT nextval('seq_input_slices');
CREATE SEQUENCE IF NOT EXISTS seq_critical_fn_reach START 1;
ALTER TABLE critical_fn_reach ALTER COLUMN id SET DEFAULT nextval('seq_critical_fn_reach');
CREATE SEQUENCE IF NOT EXISTS seq_intended_feature_classification START 1;
ALTER TABLE intended_feature_classification ALTER COLUMN id SET DEFAULT nextval('seq_intended_feature_classification');
CREATE SEQUENCE IF NOT EXISTS seq_agent_steps START 1;
ALTER TABLE agent_steps ALTER COLUMN id SET DEFAULT nextval('seq_agent_steps');
CREATE SEQUENCE IF NOT EXISTS seq_agent_observations START 1;
ALTER TABLE agent_observations ALTER COLUMN id SET DEFAULT nextval('seq_agent_observations');
CREATE SEQUENCE IF NOT EXISTS seq_query_attempts START 1;
ALTER TABLE query_attempts ALTER COLUMN id SET DEFAULT nextval('seq_query_attempts');
CREATE SEQUENCE IF NOT EXISTS seq_cpg_slice_coverage START 1;
ALTER TABLE cpg_slice_coverage ALTER COLUMN id SET DEFAULT nextval('seq_cpg_slice_coverage');
CREATE SEQUENCE IF NOT EXISTS seq_methodology_blind_spots START 1;
ALTER TABLE methodology_blind_spots ALTER COLUMN id SET DEFAULT nextval('seq_methodology_blind_spots');
CREATE SEQUENCE IF NOT EXISTS seq_phase0_priorities START 1;
ALTER TABLE phase0_priorities ALTER COLUMN id SET DEFAULT nextval('seq_phase0_priorities');
CREATE SEQUENCE IF NOT EXISTS seq_gr_findings START 1;
ALTER TABLE gr_findings ALTER COLUMN id SET DEFAULT nextval('seq_gr_findings');
CREATE SEQUENCE IF NOT EXISTS seq_suspicious_points START 1;
ALTER TABLE suspicious_points ALTER COLUMN id SET DEFAULT nextval('seq_suspicious_points');
CREATE SEQUENCE IF NOT EXISTS seq_suspicious_point_factor START 1;
ALTER TABLE suspicious_point_factor ALTER COLUMN id SET DEFAULT nextval('seq_suspicious_point_factor');
CREATE SEQUENCE IF NOT EXISTS seq_cves START 1;
ALTER TABLE cves ALTER COLUMN id SET DEFAULT nextval('seq_cves');
CREATE SEQUENCE IF NOT EXISTS seq_writeups START 1;
ALTER TABLE writeups ALTER COLUMN id SET DEFAULT nextval('seq_writeups');
CREATE SEQUENCE IF NOT EXISTS seq_promising_lanes START 1;
ALTER TABLE promising_lanes ALTER COLUMN id SET DEFAULT nextval('seq_promising_lanes');
CREATE SEQUENCE IF NOT EXISTS seq_file_vuln_ratings START 1;
ALTER TABLE file_vuln_ratings ALTER COLUMN id SET DEFAULT nextval('seq_file_vuln_ratings');
CREATE SEQUENCE IF NOT EXISTS seq_refutations START 1;
ALTER TABLE refutations ALTER COLUMN id SET DEFAULT nextval('seq_refutations');
CREATE SEQUENCE IF NOT EXISTS seq_audit_outcomes START 1;
ALTER TABLE audit_outcomes ALTER COLUMN id SET DEFAULT nextval('seq_audit_outcomes');
CREATE SEQUENCE IF NOT EXISTS seq_critic_findings START 1;
ALTER TABLE critic_findings ALTER COLUMN id SET DEFAULT nextval('seq_critic_findings');
CREATE SEQUENCE IF NOT EXISTS seq_defense_bypasses START 1;
ALTER TABLE defense_bypasses ALTER COLUMN id SET DEFAULT nextval('seq_defense_bypasses');
CREATE SEQUENCE IF NOT EXISTS seq_sanitizer_bypass_runs START 1;
ALTER TABLE sanitizer_bypass_runs ALTER COLUMN id SET DEFAULT nextval('seq_sanitizer_bypass_runs');
CREATE SEQUENCE IF NOT EXISTS seq_fuzz_runs START 1;
ALTER TABLE fuzz_runs ALTER COLUMN id SET DEFAULT nextval('seq_fuzz_runs');
CREATE SEQUENCE IF NOT EXISTS seq_fuzz_artifacts START 1;
ALTER TABLE fuzz_artifacts ALTER COLUMN id SET DEFAULT nextval('seq_fuzz_artifacts');
CREATE SEQUENCE IF NOT EXISTS seq_knowledge_chunks START 1;
ALTER TABLE knowledge_chunks ALTER COLUMN id SET DEFAULT nextval('seq_knowledge_chunks');
CREATE SEQUENCE IF NOT EXISTS seq_knowledge_seed_log START 1;
ALTER TABLE knowledge_seed_log ALTER COLUMN id SET DEFAULT nextval('seq_knowledge_seed_log');
CREATE SEQUENCE IF NOT EXISTS seq_knowledge_acceptance START 1;
ALTER TABLE knowledge_acceptance ALTER COLUMN id SET DEFAULT nextval('seq_knowledge_acceptance');
CREATE SEQUENCE IF NOT EXISTS seq_eval_corpus START 1;
ALTER TABLE eval_corpus ALTER COLUMN id SET DEFAULT nextval('seq_eval_corpus');
CREATE SEQUENCE IF NOT EXISTS seq_eval_run START 1;
ALTER TABLE eval_run ALTER COLUMN id SET DEFAULT nextval('seq_eval_run');
CREATE SEQUENCE IF NOT EXISTS seq_eval_result START 1;
ALTER TABLE eval_result ALTER COLUMN id SET DEFAULT nextval('seq_eval_result');
CREATE SEQUENCE IF NOT EXISTS seq_scoring_config START 1;
ALTER TABLE scoring_config ALTER COLUMN id SET DEFAULT nextval('seq_scoring_config');
CREATE SEQUENCE IF NOT EXISTS seq_finding_sightings START 1;
ALTER TABLE finding_sightings ALTER COLUMN id SET DEFAULT nextval('seq_finding_sightings');
CREATE SEQUENCE IF NOT EXISTS seq_call_edges START 1;
ALTER TABLE call_edges ALTER COLUMN id SET DEFAULT nextval('seq_call_edges');
CREATE SEQUENCE IF NOT EXISTS seq_weakness_classes START 1;
ALTER TABLE weakness_classes ALTER COLUMN id SET DEFAULT nextval('seq_weakness_classes');
CREATE SEQUENCE IF NOT EXISTS seq_recurrence_counter START 1;
ALTER TABLE recurrence_counter ALTER COLUMN id SET DEFAULT nextval('seq_recurrence_counter');
CREATE SEQUENCE IF NOT EXISTS seq_mutation_log START 1;
ALTER TABLE mutation_log ALTER COLUMN id SET DEFAULT nextval('seq_mutation_log');

-- content_fingerprint on every hash-keyed / NK-deduped table (T2-13). NULL-permitting,
-- non-unique; the harness fills it and uses it for the content-checked dedup reject path.
ALTER TABLE critical_functions   ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE critical_fn_reach    ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE agent_steps          ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE agent_observations   ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE query_attempts       ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE cpg_slice_coverage   ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE methodology_blind_spots ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE gr_findings          ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE suspicious_points    ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE promising_lanes      ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE defense_bypasses     ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE sanitizer_bypass_runs ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE fuzz_runs            ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE fuzz_artifacts       ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE finding_sightings    ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE call_edges           ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE weakness_classes     ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE recurrence_counter   ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;
ALTER TABLE mutation_log         ADD COLUMN IF NOT EXISTS content_fingerprint TEXT;

-- #4 — rank_score recomputed read-time from the six factors x externalized weights.
CREATE OR REPLACE VIEW v_critical_fn_ranked AS
WITH w AS (
  SELECT
    MAX(weight) FILTER (WHERE config_key = 'w_reachability')      AS w_reach,
    MAX(weight) FILTER (WHERE config_key = 'w_blast_radius')      AS w_blast,
    MAX(weight) FILTER (WHERE config_key = 'w_privilege_delta')   AS w_priv,
    MAX(weight) FILTER (WHERE config_key = 'w_attention_deficit') AS w_attn,
    MAX(weight) FILTER (WHERE config_key = 'w_bypass_prior')      AS w_bypass,
    MAX(weight) FILTER (WHERE config_key = 'w_recurrence_prior')  AS w_recur
  FROM scoring_config WHERE scope = 'rank_score'
)
SELECT
  cf.*,
  COALESCE(cf.factor_reachability, 0)      * w.w_reach
  + COALESCE(cf.factor_blast_radius, 0)     * w.w_blast
  + COALESCE(cf.factor_privilege_delta, 0)  * w.w_priv
  + COALESCE(cf.factor_attention_deficit, 0)* w.w_attn
  + COALESCE(cf.factor_bypass_prior, 0)     * w.w_bypass
  + COALESCE(cf.factor_recurrence_prior, 0) * w.w_recur AS rank_score_computed
FROM critical_functions cf CROSS JOIN w;

-- #5 — acceptance as a read-time sort key (never a gate); signals min-max normalized.
CREATE OR REPLACE VIEW v_chunk_acceptance AS
WITH w AS (
  SELECT
    MAX(weight) FILTER (WHERE config_key = 'w_ref_count')           AS w_ref,
    MAX(weight) FILTER (WHERE config_key = 'w_growth_rate')         AS w_growth,
    MAX(weight) FILTER (WHERE config_key = 'w_staleness_days')      AS w_stale,
    MAX(weight) FILTER (WHERE config_key = 'w_repeat_suppressions') AS w_supp
  FROM scoring_config WHERE scope = 'acceptance'
),
m AS (
  SELECT
    MAX(ref_count)           AS max_ref,
    MAX(growth_rate)         AS max_growth,
    MAX(staleness_days)      AS max_stale,
    MAX(repeat_suppressions) AS max_supp
  FROM knowledge_acceptance
),
latest AS (
  SELECT ka.*
  FROM knowledge_acceptance ka
  JOIN (
    SELECT chunk_id, MAX(decided_at) AS mx FROM knowledge_acceptance GROUP BY chunk_id
  ) t ON t.chunk_id = ka.chunk_id AND t.mx = ka.decided_at
)
SELECT
  c.id AS chunk_id, c.source, c.chunk_key, c.version,
  ( w.w_ref    * COALESCE(la.ref_count, 0)           / NULLIF(m.max_ref, 0)
  + w.w_growth * COALESCE(la.growth_rate, 0)         / NULLIF(m.max_growth, 0)
  - w.w_stale  * COALESCE(la.staleness_days, 0)      / NULLIF(m.max_stale, 0)
  - w.w_supp   * COALESCE(la.repeat_suppressions, 0) / NULLIF(m.max_supp, 0)
  ) AS acceptance_score
FROM knowledge_chunks c
LEFT JOIN latest la ON la.chunk_id = c.id
CROSS JOIN w CROSS JOIN m;

-- #3 — structural code map (byproduct projection): CFs joined to outgoing resolved edges.
CREATE OR REPLACE VIEW v_code_map AS
SELECT
  cf.target_id,
  cf.symbol_path,
  cf.cf_category,
  cf.rank_tier,
  ce.callee_symbol,
  ce.edge_kind
FROM critical_functions cf
LEFT JOIN call_edges ce
  ON ce.target_id = cf.target_id AND ce.caller_symbol = cf.symbol_path;

-- #6 — per-finding unified timeline (sightings + gr_findings mutations).
CREATE OR REPLACE VIEW v_finding_history AS
SELECT
  fs.finding_hash,
  'sighting'                 AS event_kind,
  fs.observed_at             AS event_at,
  fs.commit_sha,
  fs.verdict,
  fs.change_scope,
  fs.changed_from_sighting_id,
  CAST(NULL AS TEXT)         AS op,
  CAST(NULL AS TEXT)         AS delta_json
FROM finding_sightings fs
UNION ALL
SELECT
  ml.row_key                 AS finding_hash,
  'mutation'                 AS event_kind,
  ml.mutated_at              AS event_at,
  CAST(NULL AS TEXT)         AS commit_sha,
  CAST(NULL AS TEXT)         AS verdict,
  CAST(NULL AS TEXT)         AS change_scope,
  CAST(NULL AS INTEGER)      AS changed_from_sighting_id,
  ml.op,
  ml.delta_json
FROM mutation_log ml
WHERE ml.table_name = 'gr_findings';

-- #1/#6 — only sightings where the code moved under the finding.
CREATE OR REPLACE VIEW v_finding_changes AS
SELECT
  finding_hash,
  commit_sha,
  change_scope,
  changed_from_sighting_id,
  from_commit_sha, from_body_hash, from_slice_fingerprint,
  body_hash, slice_fingerprint,
  observed_at
FROM finding_sightings
WHERE change_scope IS NOT NULL AND change_scope <> 'initial';

-- #6 — coarse per-round mutation rollup.
CREATE OR REPLACE VIEW v_round_diff AS
SELECT
  round_id,
  table_name,
  op,
  COUNT(*)        AS n_mutations,
  MIN(mutated_at) AS first_at,
  MAX(mutated_at) AS last_at
FROM mutation_log
GROUP BY round_id, table_name, op;

------------------------------------------------------------
-- v_current_round (v0.30): for each target_id, the MAX(id) from round_ledger
-- (the "active" round). Targets with no round_ledger rows get round_id = NULL,
-- which preserves single-shot (round_id IS NULL everywhere) audit behaviour.
-- Used by v_lane_coverage and v_observation_coverage to scope gate evaluation
-- to the CURRENT round only, so a lane that ran in round 1 cannot permanently
-- satisfy a round-2+ gate.
-- A data row "belongs to the current round" when:
--   row.round_id = current_round.round_id   (multi-round)
--   OR (row.round_id IS NULL AND current_round.round_id IS NULL)  (single-shot)
------------------------------------------------------------
CREATE OR REPLACE VIEW v_current_round AS
SELECT
  target_id,
  MAX(id) AS round_id   -- NULL when no round_ledger rows exist (single-shot)
FROM round_ledger
GROUP BY target_id;

------------------------------------------------------------
-- v_phase_status (v0.14, updated v0.30, redefined v0.40 / T2-02 / S-D11): one row per
-- pipeline phase with how many rows it has produced AND a TRI-STATE phase_status. The
-- orchestrator's DEEP completion gate reads this to refuse "done" while a phase that
-- should have fired is empty OR ran-but-incomplete.
-- v0.30 changes:
--   • phase0_75_prebreak_and_recheck renamed to phase0_75_prebreak (unified token
--     across v_phase_status / v_required_deep_lanes / v_observation_coverage).
--   • phase1_4_seed row added (keyed on fuzz_artifacts WHERE artifact_kind='seed_initial'),
--     making the LLM seed-corpus phase gate-visible and joinable.
-- v0.40 change (T2-02 / S-D11): the old boolean `ran` conflated "phase produced ANY row"
-- with "phase ran correctly" — phase2_confirm.ran was TRUE off a single refutations row
-- even with 50 candidates still open, and the per-gap metric was a DISJOINT check the
-- orchestrator had to remember to AND in itself. v_phase_status now carries a tri-state
-- `phase_status`:
--     not_run    — rows_populated = 0 (phase never fired)
--     incomplete — rows_populated > 0 BUT the phase's OWN gap metric > 0 (fired but unfinished)
--     complete   — rows_populated > 0 AND gap metric = 0 (fired and finished its mandate)
-- so `SELECT ... WHERE phase_status <> 'complete'` is the WHOLE gate — no separate metric
-- to cross-check. `gap` is the phase's own shortfall count (the metric wired below);
-- `ran` is RETAINED (= rows_populated > 0) for back-compat with existing consumers.
-- Phases with no applicable gap metric (prior-art, plan, seed/fuzz/blindspot/self-audit,
-- proof) use gap = 0, so for them complete ≡ ran (they have no separate completeness
-- mandate beyond producing rows). The wired gap metrics:
--     phase0_decompose   — recon under-enumeration floor (defenses < distinct validator CFs)
--     phase0_75_prebreak — defenses with zero bypass attempt
--     phase1_hunt        — open candidates not yet confirmed/refuted
--     phase2_confirm     — open candidates still unconfirmed at confirm time
--     phase5_report      — confirmed findings that never went through the critic
------------------------------------------------------------
CREATE OR REPLACE VIEW v_phase_status AS
SELECT
  phase_seq,
  phase,
  rows_populated,
  (rows_populated > 0) AS ran,        -- back-compat boolean (= rows_populated > 0)
  gap,                                 -- the phase's own shortfall count (0 = no gap)
  CASE
    WHEN rows_populated = 0 THEN 'not_run'
    WHEN gap > 0            THEN 'incomplete'
    ELSE                        'complete'
  END AS phase_status
FROM (
  SELECT -1 AS phase_seq, 'phase_l1_prior_art' AS phase,
         (SELECT count(*) FROM cves) + (SELECT count(*) FROM writeups) AS rows_populated,
         0 AS gap
  UNION ALL SELECT 0, 'phase0_decompose',
         (SELECT count(*) FROM sources) + (SELECT count(*) FROM sinks)
       + (SELECT count(*) FROM defenses) + (SELECT count(*) FROM critical_functions),
         -- gap: recon defense under-enumeration floor (defenses_below_validator_cf_floor).
         GREATEST(
           (SELECT count(DISTINCT cf.symbol_path) FROM critical_functions cf
            WHERE cf.cf_category = 'validator_sanitizer')
           - (SELECT count(*) FROM defenses), 0)
  UNION ALL SELECT 1, 'phase0_5_plan',
         (SELECT count(*) FROM input_slices) + (SELECT count(*) FROM critical_fn_reach),
         0
  UNION ALL SELECT 2, 'phase0_75_prebreak',
         (SELECT count(*) FROM defense_bypasses),
         -- gap: defenses with zero bypass attempt (defenses_without_bypass_attempt).
         (SELECT count(*) FROM defenses d
          WHERE NOT EXISTS (SELECT 1 FROM defense_bypasses b WHERE b.defense_id = d.id))
  UNION ALL SELECT 3, 'phase1_hunt',
         (SELECT count(*) FROM gr_findings),
         -- gap: open candidates not yet confirmed/refuted (Hunt feeds Confirm).
         (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'candidate')
  UNION ALL SELECT 4, 'phase1_4_seed',
         (SELECT count(*) FROM fuzz_artifacts WHERE artifact_kind = 'seed_initial'),
         0
  UNION ALL SELECT 5, 'phase1_5_fuzz',
         (SELECT count(*) FROM fuzz_runs),
         0
  UNION ALL SELECT 6, 'phase1_6_blindspot',
         (SELECT count(*) FROM methodology_blind_spots),
         0
  UNION ALL SELECT 6.5, 'phase1_7_self_audit',
         (SELECT count(*) FROM agent_steps st
          JOIN strategies s ON s.id = st.strategy_id AND s.name = 'overlooked_lane_audit_lane'
          WHERE st.status IN ('success','exhausted')),
         0
  UNION ALL SELECT 7, 'phase2_confirm',
         (SELECT count(*) FROM refutations),
         -- gap: candidates still open (unconfirmed) when Confirm is supposed to have drained.
         (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'candidate')
  UNION ALL SELECT 8, 'phase4_proof',
         (SELECT count(*) FROM audit_outcomes),
         0
  UNION ALL SELECT 9, 'phase5_report',
         (SELECT count(*) FROM critic_findings),
         -- gap: confirmed findings that never went through the REPORT critic.
         (SELECT count(*) FROM gr_findings f
          WHERE f.confirmation_status = 'confirmed'
            AND NOT EXISTS (SELECT 1 FROM critic_findings c WHERE c.finding_id = f.id))
) t
ORDER BY phase_seq;

------------------------------------------------------------
-- v_coverage (v0.14): gap finder. Each row is a named coverage metric the
-- orchestrator inspects before declaring a DEEP audit complete. `note` explains
-- how to read an anomalous value. Signals, not hard failures — but the
-- orchestrator MUST look.
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
  -- confirmed_without_promotion_provenance (v0.40 / migration 0029 / T2-03 / S-D02, C21):
  -- a confirmed gr_findings row that has NO mutation_log op='status_transition' row recording
  -- the candidate→confirmed flip. The ONLY legitimate path to 'confirmed' is the `vrdb promote`
  -- verb (Tier 3 T3-01), which writes that status_transition row in the same tx. A confirmed
  -- finding lacking it was flipped OUT-OF-BAND (a born-confirmed Put, the 10→33 inflation) and
  -- is unjustified at the provenance level. mutation_log.row_key is the finding_hash (per
  -- v_finding_history). Count-free; > 0 => RED.
  UNION ALL SELECT 'confirmed_without_promotion_provenance',
    (SELECT count(*) FROM gr_findings f
     WHERE f.confirmation_status = 'confirmed'
       AND NOT EXISTS (
         SELECT 1 FROM mutation_log ml
         WHERE ml.table_name = 'gr_findings'
           AND ml.op = 'status_transition'
           AND ml.row_key = f.finding_hash)),
    'confirmed finding with no mutation_log status_transition row — flipped to confirmed OUT-OF-BAND (not via the vrdb promote verb); born-confirmed inflation (RED when > 0)'
  -- ranked_sps_never_consumed (v0.40 / migration 0029 / T2-04 / S-D03): a suspicious_point
  -- that is gate_ok=TRUE and in the TOP-K composite_score for its (target, round) but has NO
  -- sp_spawn_decisions row — i.e. the ranking that named it a top lead was never CONSUMED by a
  -- spawn decision. Without this the four ranked views are read-time sort keys wired to no
  -- spawn step; the ranking has zero effect unless an agent voluntarily queries it. K is the
  -- per-(target,round) decile (top 10%, min 1) of gate_ok SPs — a relative cut, no magic
  -- constant. Count-free; > 0 => RED (the orchestrator must record a decision for each ranked
  -- top SP, even if the decision is spawned=FALSE/declined).
  UNION ALL SELECT 'ranked_sps_never_consumed',
    (SELECT count(*) FROM (
       SELECT r.id, r.target_id, r.round_id,
              ROW_NUMBER() OVER (
                PARTITION BY r.target_id, r.round_id ORDER BY r.composite_score DESC
              ) AS rk,
              CEIL(0.10 * COUNT(*) OVER (PARTITION BY r.target_id, r.round_id)) AS topk
       FROM v_suspicious_points_ranked r
       WHERE r.gate_ok = TRUE
     ) ranked
     WHERE ranked.rk <= GREATEST(ranked.topk, 1)
       AND NOT EXISTS (
         SELECT 1 FROM sp_spawn_decisions d
         WHERE d.sp_id = ranked.id
           AND d.round_id IS NOT DISTINCT FROM ranked.round_id)),
    'a gate_ok top-K (per target/round) ranked suspicious_point with no sp_spawn_decisions row — the ranking was never consumed by a spawn decision (RED when > 0)'
  -- roster_steps_missing_for_current_round (v0.40 / migration 0029 / T2-05, T2-11 / S-D09):
  -- a required DEEP lane (v_required_deep_lanes) with NO agent_steps row in the CURRENT round.
  -- The round-keyed roster sentinel convention (T2-11): the orchestrator materializes one
  -- agent_steps sentinel per required lane per round with step_hash='plan-roster-<lane>-r<round_id>'
  -- (round_id IN the hashed natural key) so a round-2 materialization cannot ON CONFLICT DO
  -- NOTHING against round-1's globally-UNIQUE sentinel. A swallowed round-2 roster insert then
  -- surfaces HERE as a missing current-round step rather than masquerading as a documented
  -- skip. "Current round" = v_current_round (NULL=NULL match for single-shot audits). Count-free;
  -- > 0 => RED.
  -- Lane names are inlined (v_required_deep_lanes is defined AFTER v_coverage in schema
  -- order, so it cannot be referenced here — the lanes_stuck_running precedent). Kept in
  -- sync with the v_required_deep_lanes roster (report_critic excluded — it is the confirm/
  -- report critic, not a hunt-roster lane materialized at Plan).
  UNION ALL SELECT 'roster_steps_missing_for_current_round',
    (SELECT count(*) FROM (VALUES
       ('prior_art_intake_lane'),('preliminary_enumeration_lane'),('forward_slice_lane'),
       ('backward_sink_lane'),('critical_function_dataflow_lane'),('defense_base_lane'),
       ('defense_context_verification_lane'),('isolation_fuzz_lane'),('html_sanitizer_bypass_lane'),
       ('concolic_bypass_lane'),('llm_seed_corpus_lane_a'),('llm_seed_corpus_lane_b'),
       ('fuzzgpt_history_lane'),('boundary_fuzz_lane'),('methodology_blindspot_lane_a'),
       ('methodology_blindspot_lane_b'),('overlooked_lane_audit_lane')
     ) AS req(lane_name)
     JOIN strategies s ON s.name = req.lane_name
     WHERE NOT EXISTS (
       SELECT 1 FROM agent_steps st
       WHERE st.strategy_id = s.id
         AND (
           (st.round_id IS NULL AND NOT EXISTS (SELECT 1 FROM round_ledger))
           OR st.round_id IS NOT DISTINCT FROM (
             SELECT cr.round_id FROM v_current_round cr
             WHERE cr.target_id = (
               SELECT target_id FROM round_ledger WHERE id = st.round_id LIMIT 1
             )
             LIMIT 1
           )
         ))),
    'a required DEEP lane with no agent_steps row in the CURRENT round — a swallowed round-keyed roster sentinel (step_hash plan-roster-<lane>-r<round_id>); the lane was never materialized this round (RED when > 0)'
) t
ORDER BY metric;

------------------------------------------------------------
-- v_required_deep_lanes (v0.15): the mandatory lane roster for a DEEP audit.
-- Each of these strategies MUST either execute >=1 agent_step OR record a
-- documented skip (status='skipped' + termination_reason) — see the DEEP
-- Completion Gate in SKILL.md. autoload_seed/expand (knowledge plumbing) and the
-- confirm/proof phases are intentionally NOT here: the former are infrastructure,
-- the latter are gated by v_phase_status + v_coverage instead.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_required_deep_lanes AS
SELECT * FROM (VALUES
  ('prior_art_intake_lane',             'phase_l1_prior_art'),  -- migration 0026 (C1; documented-skip when no scope/network — Phase L0 precedent)
  ('preliminary_enumeration_lane',      'phase0_decompose'),  -- migration 0014 (enumeration completeness)
  ('forward_slice_lane',                'phase1_hunt'),
  ('backward_sink_lane',                'phase1_hunt'),
  ('critical_function_dataflow_lane',   'phase1_hunt'),
  ('defense_base_lane',                 'phase0_75_prebreak'),  -- unified token (was phase0_75_prebreak_and_recheck in v_phase_status pre-v0.30)
  ('defense_context_verification_lane', 'phase0_75_prebreak'),
  ('isolation_fuzz_lane',               'phase0_75_prebreak'),
  ('html_sanitizer_bypass_lane',        'phase0_75_prebreak'),
  ('concolic_bypass_lane',              'phase0_75_prebreak'),  -- migration 0013 (C5)
  ('llm_seed_corpus_lane_a',            'phase1_4_seed'),       -- migration 0011 (C2)
  ('llm_seed_corpus_lane_b',            'phase1_4_seed'),       -- migration 0011 (C2)
  ('fuzzgpt_history_lane',              'phase1_4_seed'),       -- migration 0024 (history-driven LLM fuzzing; coexists with the dual seed-corpus lanes)
  ('boundary_fuzz_lane',                'phase1_5_fuzz'),
  ('methodology_blindspot_lane_a',      'phase1_6_blindspot'),  -- migration 0018 (post-Hunt meta pass)
  ('methodology_blindspot_lane_b',      'phase1_6_blindspot'),  -- migration 0018 (post-Hunt meta pass)
  ('overlooked_lane_audit_lane',        'phase1_7_self_audit'), -- migration 0028 (C2; runs after phase1_6_blindspot)
  ('report_critic',                     'phase5_report')
) AS t(lane_name, phase);

------------------------------------------------------------
-- v_lane_coverage (v0.15, updated v0.30): per-required-lane execution ledger for
-- the DEEP gate. Joins the mandatory roster to strategies -> agent_steps and
-- classifies each lane. v0.30 changes:
--   • Round-scoped: only steps belonging to the CURRENT round (per v_current_round)
--     are counted. A lane that ran in round 1 does NOT satisfy round 2+. Single-shot
--     audits (round_id IS NULL everywhere) behave exactly as before.
--   • gate_status 'ok' requires status IN ('success','exhausted') — a lane stuck in
--     'running' (OOM/crash) is NOT ok; 'failed'/'timed_out' surface as explicit
--     non-ok steps (counted in steps_failed) rather than silently satisfying the gate.
--   • steps_stuck_running: count of steps in status='running' in the current round
--     (a crashed/OOM HEAVY lane). Used by the lanes_stuck_running gate in v_coverage.
-- Gate classification:
--   'ok'      >=1 step with status IN ('success','exhausted') in current round
--   'skipped' 0 ok steps but a documented skip (status='skipped' + termination_reason)
--             in current round
--   'MISSING' neither — a required lane defined but never spawned this round.
--             The DEEP completion gate BLOCKS on any 'MISSING' row.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_lane_coverage AS
WITH current_steps AS (
  -- Steps in the current round for each target.
  -- For single-shot audits (no round_ledger rows), cr.round_id IS NULL and we
  -- include steps where st.round_id IS NULL (same NULL=NULL match via IS NOT DISTINCT FROM).
  SELECT st.*
  FROM agent_steps st
  LEFT JOIN v_current_round cr ON cr.target_id = (
    -- Derive target_id from the strategy's steps; agent_steps has no direct target_id,
    -- so we join through strategies -> the step's own round_id dimension.
    -- We use a correlated subquery: if there are any round_ledger rows for this DB,
    -- restrict to the max round; otherwise include all (single-shot).
    SELECT target_id FROM round_ledger
    WHERE id = st.round_id
    LIMIT 1
  )
  WHERE st.round_id IS NOT DISTINCT FROM (
    -- current round_id for this step's target, or NULL for single-shot
    SELECT cr2.round_id FROM v_current_round cr2
    WHERE cr2.target_id = (
      SELECT target_id FROM round_ledger WHERE id = st.round_id LIMIT 1
    )
    LIMIT 1
  )
  -- Include steps with NULL round_id when there are no round_ledger rows at all
  -- (single-shot: no target is registered in round_ledger yet).
  OR (st.round_id IS NULL AND NOT EXISTS (SELECT 1 FROM round_ledger))
)
SELECT
  r.lane_name,
  r.phase,
  s.id AS strategy_id,
  COUNT(st.id)                                                                        AS steps_total,
  COUNT(*) FILTER (WHERE st.status = 'scheduled')                                    AS steps_scheduled,
  COUNT(*) FILTER (WHERE st.status IN ('success','exhausted','failed','timed_out',
                                       'running'))                                    AS steps_executed,
  COUNT(*) FILTER (WHERE st.status IN ('success','exhausted'))                       AS steps_ok,
  COUNT(*) FILTER (WHERE st.status IN ('failed','timed_out'))                        AS steps_failed,
  COUNT(*) FILTER (WHERE st.status = 'running')                                      AS steps_stuck_running,
  COUNT(*) FILTER (WHERE st.status = 'skipped'
                   AND st.termination_reason IS NOT NULL
                   AND st.termination_reason <> '')                                  AS steps_skipped_documented,
  CASE
    WHEN COUNT(*) FILTER (WHERE st.status IN ('success','exhausted')) > 0
      THEN 'ok'
    WHEN COUNT(*) FILTER (WHERE st.status = 'skipped'
                          AND st.termination_reason IS NOT NULL
                          AND st.termination_reason <> '') > 0
      THEN 'skipped'
    ELSE 'MISSING'
  END AS gate_status
FROM v_required_deep_lanes r
LEFT JOIN strategies s ON s.name = r.lane_name
LEFT JOIN current_steps st ON st.strategy_id = s.id
GROUP BY r.lane_name, r.phase, s.id;

------------------------------------------------------------
-- v_observation_coverage (v0.23): per-phase CONTEXT-persistence gate. The
-- recurring failure this catches: a phase that executed real work (>=1 executed
-- agent_step) but persisted ZERO agent_observations — the "save context into the
-- DB" layer was skipped, so the round's hypotheses / dead-ends / invariants are
-- lost and later rounds cannot suppress redundant work. v_phase_status only sees
-- the phase's own output tables; it cannot see a context-logging blackout.
--
-- Phase is derived the same way the DEEP gate derives it: agent_steps ->
-- strategies -> v_required_deep_lanes (the mandatory roster IS the phase map).
-- One row per roster phase. An "executed" step is status in
-- (running/success/exhausted/failed/timed_out) — identical to v_lane_coverage.
--   executed_steps      = executed agent_steps attributable to the phase
--   observations_total  = agent_observations hung off those executed steps
--   gate_status:
--     'not_run'        executed_steps = 0  (phase never did work here — soft)
--     'NO_OBSERVATION' executed_steps > 0 AND observations_total = 0 (HARD RED:
--                      a phase ran but logged no context)
--     'ok'             executed_steps > 0 AND observations_total > 0
-- Read-time, FK-free, idempotent (CREATE OR REPLACE).
------------------------------------------------------------
CREATE OR REPLACE VIEW v_observation_coverage AS
WITH phase_steps AS (
  -- Round-scoped (v0.30): only steps in the current round per v_current_round.
  -- Single-shot audits (no round_ledger rows) include all steps (round_id IS NULL).
  SELECT
    r.phase                                        AS phase,
    st.id                                          AS step_id
  FROM v_required_deep_lanes r
  JOIN strategies s   ON s.name = r.lane_name
  JOIN agent_steps st ON st.strategy_id = s.id
   AND st.status IN ('running','success','exhausted','failed','timed_out')
   AND (
     -- single-shot: no round_ledger rows at all
     (st.round_id IS NULL AND NOT EXISTS (SELECT 1 FROM round_ledger))
     OR
     -- multi-round: step belongs to the current round for its target
     st.round_id IS NOT DISTINCT FROM (
       SELECT cr.round_id FROM v_current_round cr
       WHERE cr.target_id = (
         SELECT target_id FROM round_ledger WHERE id = st.round_id LIMIT 1
       )
       LIMIT 1
     )
   )
),
phase_list AS (
  SELECT DISTINCT phase FROM v_required_deep_lanes
)
SELECT
  pl.phase                                                   AS phase,
  COUNT(DISTINCT ps.step_id)                                 AS executed_steps,
  COUNT(o.id)                                                AS observations_total,
  CASE
    WHEN COUNT(DISTINCT ps.step_id) = 0 THEN 'not_run'
    WHEN COUNT(o.id) = 0               THEN 'NO_OBSERVATION'
    ELSE 'ok'
  END                                                        AS gate_status
FROM phase_list pl
LEFT JOIN phase_steps ps        ON ps.phase = pl.phase
LEFT JOIN agent_observations o  ON o.agent_step_id = ps.step_id
GROUP BY pl.phase
ORDER BY pl.phase;

------------------------------------------------------------
-- v_cpg_slice_coverage (v17) — read-time CODEBASE slice-coverage %. Divides the
-- stored integer counts so every percentage is computed, never a persisted magic
-- constant (DB-native determinism: covered/total, NULLIF guards an empty CPG / empty
-- frontier). One row per stored (target_id, round_id) measurement. frontier_covered_pct
-- is the load-bearing bug-finding ratio (how much of the attack surface was sliced);
-- methods_covered_pct is the honest "% on codebase" baseline; files/nodes are companion
-- granularities. A trend over round_id is the round-over-round coverage signal
-- (change-visibility). db/schema.sql and db/migrations/0017 carry identical definitions.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_cpg_slice_coverage AS
SELECT
  target_id,
  round_id,
  frontier_covered,
  frontier_total,
  ROUND(100.0 * frontier_covered / NULLIF(frontier_total, 0), 1) AS frontier_covered_pct,
  methods_covered,
  methods_total,
  ROUND(100.0 * methods_covered  / NULLIF(methods_total, 0), 1)  AS methods_covered_pct,
  files_covered,
  files_total,
  ROUND(100.0 * files_covered    / NULLIF(files_total, 0), 1)    AS files_covered_pct,
  nodes_covered,
  nodes_total,
  ROUND(100.0 * nodes_covered    / NULLIF(nodes_total, 0), 1)    AS nodes_covered_pct,
  per_kind_json,
  coverage_basis,
  measured_at
FROM cpg_slice_coverage
ORDER BY target_id, round_id;

------------------------------------------------------------
-- v_fuzz_coverage (v22) — read-time per-run fuzz code-coverage rollup, the DYNAMIC
-- analogue of v_cpg_slice_coverage. One row per EXECUTED fuzz_runs row (skip_reason IS
-- NULL); the coverage numbers are EXTRACTED read-time from coverage_json (json_extract,
-- never a stored/duplicated column — DB-native determinism). `edges`/`blocks` is the
-- universal relative-progress signal; `function_coverage_pct` + `functions_covered` are
-- the code-coverage signal (NULL when the engine could not emit them); `uncovered_frontier_n`
-- counts the frontier the run did NOT reach (the next-round feed-forward worklist).
-- Ordering by (target_id, round_id, entry_point) makes the round-over-round trend —
-- "did coverage actually grow?" — directly queryable. There is NO %-floor here (a low %
-- is inspected, not failed — the cpg_slice_coverage precedent); the only gates are
-- v_coverage.fuzz_runs_without_coverage_measurement + fuzz_skips_unrecorded.
-- db/schema.sql and db/migrations/0022 carry identical definitions.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_fuzz_coverage AS
SELECT
  fr.target_id,
  fr.round_id,
  fr.entry_point,
  fr.engine,
  fr.reused_existing_pipeline,
  TRY_CAST(json_extract_string(fr.coverage_json, '$.edges')  AS BIGINT) AS edges,
  TRY_CAST(json_extract_string(fr.coverage_json, '$.blocks') AS BIGINT) AS blocks,
  TRY_CAST(json_extract_string(fr.coverage_json, '$.function_coverage_pct') AS DOUBLE) AS function_coverage_pct,
  TRY_CAST(json_extract_string(fr.coverage_json, '$.functions_covered')     AS BIGINT) AS functions_covered,
  json_array_length(json_extract(fr.coverage_json, '$.uncovered_frontier')) AS uncovered_frontier_n,
  json_extract_string(fr.coverage_json, '$.seed_source') AS seed_source,
  json_extract_string(fr.coverage_json, '$.hybrid_mode') AS hybrid_mode,
  TRY_CAST(json_extract_string(fr.coverage_json, '$.runtime_s') AS BIGINT) AS runtime_s,
  fr.crash_count,
  fr.created_at
FROM fuzz_runs fr
WHERE fr.skip_reason IS NULL
ORDER BY fr.target_id, fr.round_id, fr.entry_point;

------------------------------------------------------------
-- v_methodology_blindspots_ranked (v18) — read-time ranking of the merged Phase-1.6
-- methodology blind-spots, NO stored score (the v_critical_fn_ranked / v_suspicious_points_ranked
-- precedent). Ordering is purely ordinal — no magic constant: unconsumed directions first
-- (open_direction — the next-round worklist), both-lane agreement above single, then
-- recurrence (dedup_cluster_size), then gap_class, then created_at. Identical to migration 0018.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_methodology_blindspots_ranked AS
SELECT
  id,
  target_id,
  round_id,
  gap_class,
  title,
  proposed_lane,
  symbol_path,
  agreement,
  dedup_cluster_size,
  promoted_to_round_id,
  (promoted_to_round_id IS NULL) AS open_direction,
  created_at
FROM methodology_blind_spots
ORDER BY
  (promoted_to_round_id IS NULL) DESC,             -- unconsumed directions first (the next-round worklist)
  CASE agreement WHEN 'both' THEN 0 ELSE 1 END,    -- both-lane agreement outranks single-lane
  dedup_cluster_size DESC,                         -- recurrence across lanes/rounds
  gap_class,
  created_at;

------------------------------------------------------------
-- v_fact_hitscore (migration 0020) — composite hit-score ranking over reusable
-- facts (agent_observations) so fetch-budget truncation keeps the objectively-most-
-- useful rows instead of arbitrary ones. Fully derived — no new table, no new
-- write-path. Weights are externalized to scoring_config scope='recurrence'
-- (keys w_rec/w_outcome/w_reuse/w_conf) so they are tunable per target without a
-- code change; normalization is data-derived (PERCENT_RANK within target_id), never
-- a magic constant. Pattern: v_critical_fn_ranked (weights via CTE, CROSS JOIN).
--
-- Signals (per spec §3.1):
--   recurrence_norm   (w_rec, dominant): within-target PERCENT_RANK of the
--     corroboration count (distinct agent_steps independently producing the same
--     symbol_path) folded with recurrence_counter.counter for the same symbol_path.
--   led_to_outcome    (w_outcome): 1 if the symbol_path appears in any confirmed
--     gr_findings or reproduced defense_bypasses lineage for the same target.
--   reuse_effectiveness (w_reuse): 1 for a dead_end that was seeded into a round
--     (round_id IS NOT NULL on the step) AND whose symbol_path has NO new dead_end
--     or partial_trace row produced in that same round — the suppression held.
--     Measured as ABSENCE of re-walk rows, not an agent assertion.
--   confidence_decayed (w_conf): observation confidence decayed by the number of
--     rounds since the last corroboration (rounds_since_last = current max round -
--     the round of the most recent step that logged this symbol_path; decay = 1/2^n).
--
-- NEVER stores a composite (mirrors v_critical_fn_ranked / v_suspicious_points_ranked).
-- Scoped to per-target (all joins carry target_id). Fetch (3) reads ORDER BY hit_score DESC.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_fact_hitscore AS
WITH
-- Weight vector from scoring_config scope='recurrence' (same pattern as v_critical_fn_ranked).
w AS (
  SELECT
    MAX(weight) FILTER (WHERE config_key = 'w_rec')     AS w_rec,
    MAX(weight) FILTER (WHERE config_key = 'w_outcome') AS w_outcome,
    MAX(weight) FILTER (WHERE config_key = 'w_reuse')   AS w_reuse,
    MAX(weight) FILTER (WHERE config_key = 'w_conf')    AS w_conf
  FROM scoring_config WHERE scope = 'recurrence'
),
-- Base: one row per (target_id, symbol_path) for reusable observations.
-- corroboration_count = distinct agent_steps that independently logged the same symbol_path.
-- rc_counter = recurrence_counter.counter for the same symbol_path (0 if absent).
base AS (
  SELECT
    ao.target_id,
    ao.symbol_path,
    ao.obs_kind,
    COUNT(DISTINCT ao.agent_step_id)        AS corroboration_count,
    MAX(ao.confidence)                       AS max_confidence,
    MAX(st.round_id)                         AS last_round_id,
    COALESCE(MAX(rc.counter), 0)             AS rc_counter
  FROM agent_observations ao
  JOIN agent_steps st  ON st.id = ao.agent_step_id
  LEFT JOIN recurrence_counter rc
         ON rc.target_id = ao.target_id AND rc.symbol_path = ao.symbol_path
  WHERE ao.reusable = TRUE
    AND ao.symbol_path IS NOT NULL
    AND ao.obs_kind IN ('dead_end', 'invariant', 'blind_spot', 'assumption')
  GROUP BY ao.target_id, ao.symbol_path, ao.obs_kind
),
-- Current max round_id per target (for staleness decay denominator).
max_round AS (
  SELECT target_id, MAX(id) AS max_round_id FROM round_ledger GROUP BY target_id
),
-- recurrence_norm: PERCENT_RANK of (corroboration_count + rc_counter) within target.
normed AS (
  SELECT
    b.*,
    PERCENT_RANK() OVER (
      PARTITION BY b.target_id
      ORDER BY (b.corroboration_count + b.rc_counter)
    ) AS recurrence_norm
  FROM base b
),
-- led_to_outcome: 1 if symbol_path is on any confirmed finding or reproduced bypass
-- for this target; 0 otherwise.
outcome AS (
  SELECT DISTINCT target_id, symbol_path FROM (
    SELECT f.target_id, s.symbol_path
    FROM gr_findings f
    JOIN sinks s ON s.id = f.sink_id
    WHERE f.confirmation_status = 'confirmed'
    UNION ALL
    SELECT f.target_id, src.symbol_path
    FROM gr_findings f
    JOIN sources src ON src.id = f.source_id
    WHERE f.confirmation_status = 'confirmed'
    UNION ALL
    SELECT st.target_id, d.symbol_path
    FROM defense_bypasses db2
    JOIN agent_steps st ON st.id = db2.agent_step_id
    JOIN defenses d     ON d.id  = db2.defense_id
    WHERE db2.reproduced = TRUE
  ) t
),
-- reuse_effectiveness: for dead_end rows, 1 if the symbol_path has NO re-walk
-- (no new dead_end or partial_trace) in the same round it was seeded into.
-- A dead_end is "seeded" = its agent_step has a round_id set. Re-walk = a DIFFERENT
-- agent_step in the same round also produced a dead_end/partial_trace on that path.
reuse AS (
  SELECT DISTINCT
    ao.target_id,
    ao.symbol_path,
    1 AS reuse_effective
  FROM agent_observations ao
  JOIN agent_steps st ON st.id = ao.agent_step_id
  WHERE ao.obs_kind = 'dead_end'
    AND ao.reusable = TRUE
    AND ao.symbol_path IS NOT NULL
    AND st.round_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM agent_observations ao2
      JOIN agent_steps st2 ON st2.id = ao2.agent_step_id
      WHERE ao2.target_id   = ao.target_id
        AND ao2.symbol_path = ao.symbol_path
        AND ao2.obs_kind   IN ('dead_end', 'partial_trace')
        AND st2.round_id    = st.round_id
        AND ao2.id         <> ao.id
    )
)
SELECT
  n.target_id,
  n.symbol_path,
  n.obs_kind,
  n.corroboration_count,
  n.rc_counter,
  n.recurrence_norm,
  CASE WHEN o.symbol_path IS NOT NULL THEN 1.0 ELSE 0.0 END          AS led_to_outcome,
  COALESCE(CAST(r.reuse_effective AS REAL), 0.0)                      AS reuse_effectiveness,
  -- confidence_decayed: max_confidence * (1/2)^rounds_since_last
  COALESCE(n.max_confidence, 0.5) *
    POWER(0.5, GREATEST(0,
      COALESCE(mr.max_round_id, n.last_round_id) - COALESCE(n.last_round_id, 0)
    ))                                                                AS confidence_decayed,
  -- hit_score: weighted sum (mirrors v_critical_fn_ranked arithmetic)
  COALESCE(w.w_rec,     0.50) * n.recurrence_norm
  + COALESCE(w.w_outcome, 0.25) * CASE WHEN o.symbol_path IS NOT NULL THEN 1.0 ELSE 0.0 END
  + COALESCE(w.w_reuse,   0.15) * COALESCE(CAST(r.reuse_effective AS REAL), 0.0)
  + COALESCE(w.w_conf,    0.10) *
    ( COALESCE(n.max_confidence, 0.5) *
      POWER(0.5, GREATEST(0,
        COALESCE(mr.max_round_id, n.last_round_id) - COALESCE(n.last_round_id, 0)
      ))
    )                                                                 AS hit_score
FROM normed n
LEFT JOIN outcome o    ON o.target_id = n.target_id AND o.symbol_path = n.symbol_path
LEFT JOIN reuse r      ON r.target_id = n.target_id AND r.symbol_path = n.symbol_path
LEFT JOIN max_round mr ON mr.target_id = n.target_id
CROSS JOIN w;

------------------------------------------------------------
-- v_fact_similar (migration 0020) — DB-native trigram-Jaccard approximate recall.
-- Finds near-twin symbol_paths within the per-target reusable fact set so a
-- dead_end on 'pkg.parse.decodeFrameV1' surfaces when walking 'pkg.parse.decodeFrameV2'.
-- Deterministic SQL only — no embeddings, no external model (spec §3.4 / §7).
--
-- Similarity = trigram-Jaccard over the FULL symbol_path (whole path, so
-- package/module structure contributes): split both paths on '.', compute
--   jaccard = |intersect(tokens_A, tokens_B)| / |distinct(concat(tokens_A, tokens_B))|
-- A slice-fingerprint nearest-neighbor component adds 1.0 when both facts share
-- the same slice_fingerprint (from the most recent finding_sightings row for the
-- symbol_path), 0.0 otherwise. The combined similarity is:
--   similarity = 0.7 * path_jaccard + 0.3 * fp_match
-- Threshold gate: approx_recall_floor from scoring_config scope='recurrence'
-- (default 0.40 = 40% path Jaccard). Pairs below the floor are excluded.
--
-- Output: one row per (target_id, symbol_path_a, symbol_path_b) pair that clears
-- the floor. The orchestrator uses this to surface approximate hits as leads tagged
-- 'approximate' (not as suppressors — an approximate dead_end is a prioritization
-- hint, not a proven invariant; spec §3.4). Self-pairs (a=b) are excluded.
-- NEVER stores a score. Scoped per-target.
------------------------------------------------------------
CREATE OR REPLACE VIEW v_fact_similar AS
WITH
-- Floor knob from scoring_config.
floor AS (
  SELECT COALESCE(MAX(weight), 0.40) AS approx_recall_floor
  FROM scoring_config WHERE scope = 'recurrence' AND config_key = 'approx_recall_floor'
),
-- Distinct reusable facts with their token list (split on '.').
facts AS (
  SELECT DISTINCT
    ao.target_id,
    ao.symbol_path,
    string_split(ao.symbol_path, '.') AS tokens
  FROM agent_observations ao
  WHERE ao.reusable = TRUE
    AND ao.symbol_path IS NOT NULL
    AND ao.obs_kind IN ('dead_end', 'invariant', 'blind_spot', 'assumption')
),
-- Most recent slice_fingerprint per (target_id, symbol_path) from finding_sightings.
fp AS (
  SELECT
    fs.target_id,
    f.sink_id,
    -- Anchor on the gr_finding's source/sink path; approximate via symbol_path match
    -- through agent_steps -> agent_observations join.
    ao.symbol_path,
    fs.slice_fingerprint
  FROM finding_sightings fs
  JOIN gr_findings f  ON f.finding_hash = fs.finding_hash
  JOIN agent_steps st ON st.id = fs.agent_step_id
  JOIN agent_observations ao
       ON ao.agent_step_id = st.id
      AND ao.symbol_path IS NOT NULL
  WHERE fs.slice_fingerprint IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY fs.target_id, ao.symbol_path
    ORDER BY fs.observed_at DESC
  ) = 1
),
-- Cartesian self-join within target for candidate pairs.
pairs AS (
  SELECT
    a.target_id,
    a.symbol_path  AS symbol_path_a,
    b.symbol_path  AS symbol_path_b,
    a.tokens       AS tokens_a,
    b.tokens       AS tokens_b
  FROM facts a
  JOIN facts b ON b.target_id = a.target_id AND b.symbol_path > a.symbol_path
),
-- Compute path Jaccard and fingerprint match.
scored AS (
  SELECT
    p.target_id,
    p.symbol_path_a,
    p.symbol_path_b,
    -- Path Jaccard: |intersect| / |distinct union|
    CASE
      WHEN len(list_distinct(list_concat(p.tokens_a, p.tokens_b))) = 0 THEN 0.0
      ELSE CAST(len(list_intersect(p.tokens_a, p.tokens_b)) AS REAL) /
           CAST(len(list_distinct(list_concat(p.tokens_a, p.tokens_b))) AS REAL)
    END AS path_jaccard,
    -- Fingerprint match: 1.0 if both facts share the same non-null slice_fingerprint.
    CASE
      WHEN fpa.slice_fingerprint IS NOT NULL
       AND fpa.slice_fingerprint = fpb.slice_fingerprint THEN 1.0
      ELSE 0.0
    END AS fp_match
  FROM pairs p
  LEFT JOIN fp fpa ON fpa.target_id = p.target_id AND fpa.symbol_path = p.symbol_path_a
  LEFT JOIN fp fpb ON fpb.target_id = p.target_id AND fpb.symbol_path = p.symbol_path_b
)
SELECT
  s.target_id,
  s.symbol_path_a,
  s.symbol_path_b,
  s.path_jaccard,
  s.fp_match,
  -- Combined similarity (path dominates 0.7, fingerprint tie-breaks 0.3).
  0.7 * s.path_jaccard + 0.3 * s.fp_match AS similarity
FROM scored s
CROSS JOIN floor fl
WHERE (0.7 * s.path_jaccard + 0.3 * s.fp_match) >= fl.approx_recall_floor
ORDER BY s.target_id, similarity DESC;

------------------------------------------------------------
-- JUSTIFICATION GATE views (v0.40.0, migration 0029, TIER 2 T2-01/06/07/14/15).
--
-- The pre-v0.40 DEEP gate encoded PROCESS-coverage only (a required lane ran, a phase
-- logged ≥1 row, defenses enumerated) — a campaign that executed every lane and confirmed
-- ZERO justified findings was GREEN, and any lane could Put a born-'confirmed' row that the
-- gate counted without re-deriving (the Zuul false-green + the 10→33 inflation). These views
-- add the missing OUTCOME-justification layer. DuckDB v1.1.3 has NO triggers, so they are the
-- read-side gate; the WRITE-side invariant (only `vrdb promote` may set 'confirmed', in one tx
-- with refutation-overcome + critic-OK + severity + mutation_log) is the Go harness's job
-- (TIER 3 T3-01/T3-02). The two layers reinforce: the prose rubric is enforced by these views,
-- which are written only through the harness verb.
--
-- These views are placed LAST so they may freely reference gr_findings, refutations,
-- critic_findings, impact_proofs, suspicious_points, v_suspicious_points_ranked,
-- v_lane_coverage, agent_observations and mutation_log (all defined above).
------------------------------------------------------------

-- v_promotion_coverage (T2-01 / S-D01, S-P02, C18). The JUSTIFICATION gate. For each
-- confirmed gr_findings row, emit gate_status = JUSTIFIED only when ALL of (a)-(d) hold:
--   (a) ≥1 refutations row exists that was OVERCOME — the refute-before-confirm trail (a
--       refutations row pins that an adversarial pass ran; the finding is still 'confirmed',
--       so the refutation did not stick = overcome);
--   (b) severity IS NOT NULL;
--   (c) a critic_findings row with check_kind='eligibility' AND severity='OK';
--   (d) SP-CONDITIONAL backing-oracle: the SP tier is a SIDE-OUTPUT, not a mandatory origin
--       (findings are also born from Phase 1 Hunt, Phase 1.5 fuzz crashes
--       finding_kind='fuzz_crash', and Phase L0 commit review — with NO suspicious_points row).
--       So (d) is required ONLY WHEN the finding HAS a backing SP: a finding with NO backing
--       suspicious_point (graduated_finding_id = this finding) is judged on (a)-(c) alone; a
--       finding that DOES have a backing SP must additionally show that SP carries a non-null
--       oracle whose v_suspicious_points_ranked.gate_ok = TRUE. Formally:
--         NOT EXISTS(sp WHERE sp.graduated_finding_id=f.id)
--         OR EXISTS(sp WHERE sp.graduated_finding_id=f.id AND sp.oracle IS NOT NULL AND gate_ok).
-- else UNJUSTIFIED. Each missing-reason is surfaced so the orchestrator sees WHY. The "done"
-- predicate is `0 UNJUSTIFIED among confirmed` (a confirmed row that is UNJUSTIFIED is the
-- false-green this view exists to catch). Findings that are NOT 'confirmed' are excluded
-- (only the registry-bound rows must be justified).
CREATE OR REPLACE VIEW v_promotion_coverage AS
SELECT
  f.id            AS finding_id,
  f.target_id,
  f.finding_hash,
  f.severity,
  f.confirmation_rigor_tier,
  -- (a) refute-before-confirm trail overcome
  EXISTS (SELECT 1 FROM refutations r WHERE r.finding_id = f.id)                 AS has_refutation,
  -- (b) severity present
  (f.severity IS NOT NULL)                                                       AS has_severity,
  -- (c) critic eligibility = OK
  EXISTS (SELECT 1 FROM critic_findings c
          WHERE c.finding_id = f.id AND c.check_kind = 'eligibility'
            AND c.severity = 'OK')                                               AS has_critic_ok,
  -- (d) SP-CONDITIONAL backing oracle: satisfied either when the finding has NO backing SP at
  --     all, OR when its backing SP carries a non-null oracle that passed the SP gate.
  (NOT EXISTS (SELECT 1 FROM suspicious_points sp WHERE sp.graduated_finding_id = f.id)
   OR EXISTS (SELECT 1 FROM suspicious_points sp
              JOIN v_suspicious_points_ranked spr ON spr.id = sp.id
              WHERE sp.graduated_finding_id = f.id
                AND sp.oracle IS NOT NULL
                AND spr.gate_ok = TRUE))                                         AS has_backing_sp,
  CASE
    WHEN EXISTS (SELECT 1 FROM refutations r WHERE r.finding_id = f.id)
     AND f.severity IS NOT NULL
     AND EXISTS (SELECT 1 FROM critic_findings c
                 WHERE c.finding_id = f.id AND c.check_kind = 'eligibility'
                   AND c.severity = 'OK')
     AND (NOT EXISTS (SELECT 1 FROM suspicious_points sp WHERE sp.graduated_finding_id = f.id)
          OR EXISTS (SELECT 1 FROM suspicious_points sp
                     JOIN v_suspicious_points_ranked spr ON spr.id = sp.id
                     WHERE sp.graduated_finding_id = f.id
                       AND sp.oracle IS NOT NULL
                       AND spr.gate_ok = TRUE))
    THEN 'JUSTIFIED'
    ELSE 'UNJUSTIFIED'
  END AS gate_status
FROM gr_findings f
WHERE f.confirmation_status = 'confirmed';

-- v_justification_coverage (T2-07 / S-P02, S-P04, S-V11). The CONSUMER-HARM gate (Gate 5
-- doctrine, T1-02): a sink reached is NOT a consumer harmed. Red-flags any confirmed finding
-- lacking an impact_proofs row (the named default-config component that reads/dispatches/trusts
-- the tainted value + its harm). When the proof exists, severity is a CONTRACT, not an automatic
-- function: the Confirm agent MUST DERIVE severity from the exploitability-gate rubric over the
-- proof's harm_class × proven_reachability × mechanism_cap and record that derivation in
-- severity_basis (not a typed label); the proof's proven_reachability + mechanism_cap are
-- surfaced so a consumer of this view can recompute the read-time severity rubric (T1-03).
-- justification_status = JUSTIFIED only when a proof row
-- exists; else UNJUSTIFIED_NO_CONSUMER. Done predicate: 0 UNJUSTIFIED_NO_CONSUMER among confirmed.
CREATE OR REPLACE VIEW v_justification_coverage AS
SELECT
  f.id        AS finding_id,
  f.target_id,
  f.finding_hash,
  f.severity,
  ip.consumer_symbol,
  ip.harm_class,
  ip.proven_reachability,
  ip.mechanism_cap,
  (ip.id IS NOT NULL) AS has_impact_proof,
  CASE WHEN ip.id IS NOT NULL THEN 'JUSTIFIED' ELSE 'UNJUSTIFIED_NO_CONSUMER' END AS justification_status
FROM gr_findings f
LEFT JOIN impact_proofs ip ON ip.finding_id = f.id
WHERE f.confirmation_status = 'confirmed';

-- v_sp_oracle_coverage (T2-06 / S-P06, C19). HARD-RED SP-adjudication gate. Every KEPT
-- suspicious_point (screening_verdict='kept') that carries an APPLICABLE oracle (oracle IS NOT
-- NULL) must reach an adjudication exit: either it GRADUATED into a finding
-- (graduated_finding_id IS NOT NULL) OR an oracle-execution agent_step recorded a result for it
-- (an agent_observations row anchored on the SP's symbol_path whose obs_kind names a verdict-
-- bearing outcome: dead_end | invariant | partial_trace). A kept SP with an applicable oracle
-- and NEITHER exit is RED (oracle_unrun) — recall without a closing oracle is noise accumulation,
-- not a processed queue. Done predicate: 0 RED rows.
CREATE OR REPLACE VIEW v_sp_oracle_coverage AS
SELECT
  sp.id        AS sp_id,
  sp.target_id,
  sp.round_id,
  sp.symbol_path,
  sp.vuln_class,
  sp.oracle,
  (sp.graduated_finding_id IS NOT NULL) AS graduated,
  EXISTS (
    SELECT 1 FROM agent_observations o
    WHERE o.target_id = sp.target_id
      AND o.symbol_path = sp.symbol_path
      AND o.obs_kind IN ('dead_end', 'invariant', 'partial_trace')
  ) AS oracle_executed,
  CASE
    WHEN sp.graduated_finding_id IS NOT NULL THEN 'graduated'
    WHEN EXISTS (
      SELECT 1 FROM agent_observations o
      WHERE o.target_id = sp.target_id
        AND o.symbol_path = sp.symbol_path
        AND o.obs_kind IN ('dead_end', 'invariant', 'partial_trace')
    ) THEN 'adjudicated'
    ELSE 'RED_oracle_unrun'
  END AS adjudication_status
FROM suspicious_points sp
WHERE sp.screening_verdict = 'kept'
  AND sp.oracle IS NOT NULL;

-- v_invariant_promotion_coverage (T2-14 / F34/F35, Phase 6). HARD-RED learning-loop gate.
-- The 12-orphan disease: a campaign LEARNS a reusable, high-confidence invariant but it dies
-- in agent_observations and is never PROMOTED into the durable cross-target registry
-- (references/methodology/triage-invariants.md). This view is RED while any
-- agent_observations(obs_kind='invariant', reusable=TRUE, confidence high) has NEITHER a
-- promotion entry NOR a recorded promotion_skipped reason. DuckDB-side this view cannot read
-- the markdown file or the skip ledger directly; both signals are carried in
-- agent_observations as sibling rows on the SAME symbol_path:
--   • PROMOTED  — an obs_kind='note' row whose body starts 'invariant_promoted:' (written by
--                 the Phase 6 promotion step when it appends to triage-invariants.md);
--   • SKIPPED   — an obs_kind='note' row whose body starts 'promotion_skipped:' (the recorded
--                 reason a learned invariant was deliberately NOT promoted).
-- confidence is a REAL in agent_observations; "high" = confidence >= 0.75 (NULL excluded). An
-- invariant with neither sibling is RED (unpromoted_unexplained). Done predicate: 0 RED rows.
CREATE OR REPLACE VIEW v_invariant_promotion_coverage AS
SELECT
  inv.id        AS observation_id,
  inv.target_id,
  inv.symbol_path,
  inv.confidence,
  EXISTS (
    SELECT 1 FROM agent_observations p
    WHERE p.target_id = inv.target_id
      AND p.symbol_path IS NOT DISTINCT FROM inv.symbol_path
      AND p.obs_kind = 'note'
      AND p.body LIKE 'invariant_promoted:%'
  ) AS promoted,
  EXISTS (
    SELECT 1 FROM agent_observations s
    WHERE s.target_id = inv.target_id
      AND s.symbol_path IS NOT DISTINCT FROM inv.symbol_path
      AND s.obs_kind = 'note'
      AND s.body LIKE 'promotion_skipped:%'
  ) AS promotion_skipped,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM agent_observations p
      WHERE p.target_id = inv.target_id
        AND p.symbol_path IS NOT DISTINCT FROM inv.symbol_path
        AND p.obs_kind = 'note'
        AND p.body LIKE 'invariant_promoted:%'
    ) OR EXISTS (
      SELECT 1 FROM agent_observations s
      WHERE s.target_id = inv.target_id
        AND s.symbol_path IS NOT DISTINCT FROM inv.symbol_path
        AND s.obs_kind = 'note'
        AND s.body LIKE 'promotion_skipped:%'
    ) THEN 'resolved'
    ELSE 'RED_unpromoted_unexplained'
  END AS promotion_status
FROM agent_observations inv
WHERE inv.obs_kind = 'invariant'
  AND inv.reusable = TRUE
  AND inv.confidence IS NOT NULL
  AND inv.confidence >= 0.75;

-- v_empty_result (T2-15 / S-D01). The EMPTY_RESULT terminal — a NAMED verdict, NOT red.
-- An empty campaign (thoroughly searched, nothing justified) must be DISTINGUISHABLE from a
-- green run that found and justified a bug; both pass the process gates, so a separate terminal
-- is needed. One row, one boolean: is_empty_result is TRUE when:
--   • confirmed_count   = 0  (no confirmed findings)
--   • candidate_count   = 0  (no open candidates — the Confirm queue is drained, not abandoned)
--   • high_recall_lanes_all_ran  (no required DEEP lane is MISSING in v_lane_coverage — every
--     mandatory lane ran or was documented-skipped; an EMPTY_RESULT is only credible if the
--     high-recall sweep actually completed).
-- The orchestrator reports EMPTY_RESULT as a distinct outcome rather than an indistinguishable
-- green. This is NOT a gate failure — it is a legitimate, fully-searched-nothing-there verdict.
CREATE OR REPLACE VIEW v_empty_result AS
SELECT
  (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'confirmed') AS confirmed_count,
  (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'candidate') AS candidate_count,
  NOT EXISTS (SELECT 1 FROM v_lane_coverage WHERE gate_status = 'MISSING')   AS high_recall_lanes_all_ran,
  CASE
    WHEN (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'confirmed') = 0
     AND (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'candidate') = 0
     AND NOT EXISTS (SELECT 1 FROM v_lane_coverage WHERE gate_status = 'MISSING')
    THEN TRUE ELSE FALSE
  END AS is_empty_result,
  CASE
    WHEN (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'confirmed') = 0
     AND (SELECT count(*) FROM gr_findings WHERE confirmation_status = 'candidate') = 0
     AND NOT EXISTS (SELECT 1 FROM v_lane_coverage WHERE gate_status = 'MISSING')
    THEN 'EMPTY_RESULT' ELSE 'NON_EMPTY'
  END AS terminal_state;
