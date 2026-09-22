# C/C++/Java Concolic Bypass Lane (`concolic_bypass_lane`)

> **Load when:** running Phase 0.75 Defense Pre-Break on a C, C++, or Java target and the
> `defenses` inventory includes regex filters, sanitizer functions, or allowlist guards
> protecting attacker-target dangerous functions; or when the orchestrator needs to
> understand how the lane discovers guarded functions, builds the target for symbolic
> execution, solves guard path constraints, and verifies bypass inputs.
>
> **Strategy:** `concolic_bypass_lane` (seeded in `db/seed/strategies.yml`; id assigned by harness on schema init)
> **Phase:** 0.75 — Defense Pre-Break
> **Tiers:** Mandatory-attempt at **DEEP** only (C/C++/Java targets)

---

## Purpose

The lane enumerates attacker-target dangerous functions that are guarded by a regex filter,
sanitizer, or allowlist, then uses **directed symbolic + concolic execution** to solve the
guard's path constraints and synthesize a concrete input that passes the guard yet reaches
the target function. That solved input is replayed through the instrumented build to confirm
the bypass. A confirmed bypass is stored as `defense_bypasses(reproduced=true)` with the
solver's path-constraint log as exhaustion evidence.

This lane is distinct from `isolation_fuzz_lane` by **technique**: where `isolation_fuzz_lane`
uses corpus mutation to probe a wrapped defense, this lane uses constraint-solving to
analytically defeat the guard. It is also distinct from the FS/SF concolic hybrid in
`fuzzing-lane.md §3a`, which is a **coverage-stall escalation** inside Phase 1.5 fuzzing;
this lane is a **dedicated pre-break lane** that runs at Phase 0.75 before any Hunt agent
spawns, targeting guard evasion specifically.

---

## Position in Phase 0.75

Phase 0.75 runs the following lanes. The concolic bypass lane runs after `defense_base_lane`
has populated `defenses` and `critical_fn_reach` has been partially populated by Phase 0:

1. `defense_base_lane` — enumerate defenses, populate `defenses` rows
2. `defense_context_verification_lane` — confirm each defense fires at its callsites
3. `isolation_fuzz_lane` (DEEP + MEDIUM) — mutation-based bypass probe per isolation-eligible defense
4. `html_sanitizer_bypass_lane` (MEDIUM + DEEP) — HTML-specific corpus-run bypass (PHP/JS targets)
5. **`concolic_bypass_lane`** (DEEP, C/C++/Java) — constraint-solving guard evasion

The lane reads `defenses`, `critical_fn_reach`, `input_slices`, and `sources` rows that the
earlier lanes have populated. Scheduling it late in Phase 0.75 ensures those rows exist.

---

## Discovery — Guarded Function Enumeration

The lane builds its working set from the **union of three** sources. Every guarded dangerous
function becomes a working-set entry; a function found by more than one source ranks higher.

### Source 1 — Reuse existing `defenses` rows

Read `defenses` rows with `reachability ∈ {proven, suspected}` for the current target,
selecting those whose callsite is on a path from an untrusted `sources` row to a
`critical_functions` row. These are guards on attacker-reachable dangerous functions —
the highest-value targets. Set discovery source label `'reuse_defenses'`.

### Source 2 — Pattern sweep over the target source

AST/grep sweep for guard-shaped constructs protecting dangerous function calls:

| Language | Guard patterns |
|---|---|
| C / C++ | `if (regex_match(…))`, `if (validate(…))`, `if (strncmp/memcmp/strcmp(…))`, filter wrappers around `execve`, `system`, `mmap`, `memcpy`, `sprintf`, format-string sinks |
| Java | `if (Pattern.matches(…))`, `if (sanitize(…))`, filter checks before `Runtime.exec`, `ProcessBuilder`, `ObjectInputStream.readObject`, `Statement.execute`, JNDI lookups, path-construction sinks |

Each match that is not already a `defenses` row → emit a new `defenses` row with
`discovery_method = 'pattern_sweep'`. Matches already in `defenses` get their `discovery_confidence`
updated (multi-source table, same as `html_sanitizer_bypass_lane`).

### Source 3 — AST + taint over `input_slices` and `critical_fn_reach`

Walk existing `input_slices` and `critical_fn_reach` rows to find functions that:

- appear on a taint path from a `sources` row to a `critical_functions` row, **and**
- have a taint role of `validate` or `transform` immediately upstream of the dangerous call

Each such function not already in the working set → emit a `defenses` row with
`discovery_method = 'ast_taint'`, `discovery_confidence = 0.7` (or 1.0 if also found by
pattern sweep).

### Confidence scoring

| Sources that found this guard | `discovery_confidence` |
|---|---|
| Only one source | 0.4 |
| Two sources agree | 0.7 |
| All three agree | 1.0 |

---

## Build and Instrumentation

The lane **drives the target's own build**. This is mandatory: the concolic engine runs on
the target's actual code under instrumentation, not a stub or a mock.

Build artifacts live under `.vuln-research/build/` at the audited repo root. The lane is
responsible for producing the instrumented build; if the build genuinely cannot be produced
(missing toolchain, encrypted proprietary SDK, platform mismatch), the lane records a
skip-with-reason.

### C / C++

1. **LLVM bitcode build** — recompile with `clang -emit-llvm` (or `wllvm`/`gclang` for
   complex build systems) to produce per-TU bitcode. Link into a whole-program `.bc` file.
2. **SymCC instrumentation** — recompile with the SymCC compiler plugin (LLVM pass) to
   produce a shadow-execution binary alongside the concrete binary.
3. **KLEE / SymQEMU fallback** — if SymCC is unavailable, run KLEE directly on the bitcode;
   for binaries without source, use SymQEMU over the concrete binary.
4. Build products written to `.vuln-research/build/<target_slug>/`.

### Java

1. **Bytecode + driver** — compile (or use the existing `.class`/`.jar`) plus a concolic
   driver class that exercises the guarded entry point with a symbolic input.
2. **JVM concolic engine** — run a JVM concolic engine (e.g., JBSE, Soot-based analysis,
   or an available JVM symbolic execution framework) over the bytecode + driver.
3. Java concolic tooling is thinner than C/C++ — best-effort skip-with-reason is allowed
   when no engine fits the JVM version or bytecode format (record `skip_reason` and the
   engines checked).
4. Build products written to `.vuln-research/build/<target_slug>/`.

---

## Directed Symbolic + Concolic Execution

For each guarded dangerous function in the working set:

1. **Identify the guard's path constraint** — from the guard's source (AST + taint), extract
   the boolean predicate the input must satisfy to pass the guard. This becomes the
   solver target.
2. **Direct the engine at the guard** — configure the concolic engine to focus on the guard's
   branch: for SymCC, instrument the guard function directly; for KLEE, use `--entry-point`
   and a harness that calls the guard with a symbolic buffer; for JVM engines, direct the
   driver to the guard method.
3. **Solve for a bypass input** — let the engine explore paths through the guard. The goal
   is a **concrete input** that:
   - satisfies the guard's accepting predicate (passes the guard), **and**
   - reaches the target dangerous function (passes the guard → lands at the dangerous call)
4. **Collect the solved input** — the engine's path-constraint log + the concrete input
   bytes are the solver evidence.

Per-target timeout is enforced (stored as `run_config.value` for key
`concolic_bypass_timeout_s`). SMT solver query counts and per-target runtime are recorded in
`coverage_json`. Escalate to a wider solver budget only where marginal path coverage gain
is still positive; otherwise log the uncovered guard constraints as a `coverage_frontier`
artifact and stop.

---

## Bypass Confirmation

A solved input is not a confirmed bypass until it is **replayed**:

1. Run the solved concrete input through the **instrumented build** (same binary produced
   in § Build and Instrumentation).
2. Verify three conditions hold:
   - **Guard passed** — the guard function returns an accepting result for this input
   - **Target reached** — execution reaches the target dangerous function (via coverage
     tracing or dynamic instrumentation)
   - **No sanitizer abort** — the concrete execution completes without ASan/UBSan abort on
     the guard's own logic (false-bypass guard)
3. If all three hold → `defense_bypasses(reproduced=true)` with the solver's
   path-constraint log as `exhaustion_log` (or sidecar if > 16 KB).
4. If any condition fails → the input is a solver artifact, not a confirmed bypass; record
   as `inconclusive` with the failure reason in `evidence_json`.

---

## Result Storage

### Per-bypass rows — `defense_bypasses`

Each confirmed bypass → one `defense_bypasses` row:

| Column | Value |
|---|---|
| `defense_id` | FK → `defenses.id` of the guard under test |
| `reproduced` | `true` (replay confirmed all three conditions) |
| `exhaustion_log` | solver path-constraint log (inline ≤ 16 KB; sidecar path otherwise) |
| `payload` | the solved concrete bypass input bytes |
| `payload_technique` | `'concolic_constraint_solve'` |
| `round_id` | FK → current `round_ledger.id` |

PASS (no bypass found after exhausting the solver budget) produces no `defense_bypasses`
row — only a lane exhaustion record (§ Lane-Done Gate).

### Solver artifacts — `fuzz_artifacts`

The solver's intermediate work (SMT query logs, coverage frontiers, unsolved guard
constraints) is stored as `fuzz_artifacts` rows:

| `artifact_kind` | Contents |
|---|---|
| `coverage_frontier` | guard constraint clauses the solver did not exhaust |
| `engine_state` | concolic engine checkpoint (for resume) |
| `crash_reproducer` | the solved bypass input (also stored inline in `defense_bypasses.payload`) |

---

## Defeated-Defense Feed-Forward

When a guard's bypass is confirmed (`defense_bypasses.reproduced=true`), the guard's
`defenses` row enters the **defeated-defense set** exactly as other Phase 0.75 lanes
produce it. Three consumers are unchanged:

1. **Hunt (Phase 1)** — hunters do not treat a path "protected" by a defeated guard as
   blocked.
2. **Confirm G2** — a defeated guard is non-neutralising for G2 purposes.
3. **Critical-function pre-rank** — if the bypassed guard maps to a `critical_functions`
   row (via `defense_id` / `symbol_path`), the orchestrator raises `factor_bypass_prior`,
   recomputes `rank_score`, and schedules supplementary slices at the 0.75→1 boundary.

---

## Lane-Done Gate

The lane is complete when every `defenses` row in the working set with
`reachability ∈ {proven, suspected}` has either:

1. A stored `defense_bypasses` row (`reproduced ∈ {true, false}`), **or**
2. A documented skip or exhaustion record — `agent_steps.status ∈ {exhausted, skipped}`
   with a non-empty `termination_reason` explaining why the guard was not solved (e.g.,
   `'solver_budget_exhausted'`, `'build_failed'`, `'no_concolic_engine'`,
   `'timeout'`).

The DEEP-tier gate is enforced by `v_required_deep_lanes`. The lane is mandatory for C/C++
and Java DEEP runs. The orchestrator rejects a DEEP completion that has no
`concolic_bypass_lane` step for a C/C++/Java target (unless a skip-with-reason is recorded
at the lane level, not per-guard).

A lane-level skip (as opposed to a per-guard skip) is recorded when:

- The target's build cannot be produced (missing toolchain, encrypted SDK)
- No concolic engine is available for the stack and version

A lane-level skip requires `coverage_json.checked[]` listing the engines and build methods
attempted, mirroring the skip discipline in `fuzzing-lane.md` §1.

---

## Row-Shape Invariants

- `target_id` is copied from the pinned audit value.
- `defense_bypasses.defense_id` holds a `defenses.id` value — never a `sinks.id`,
  `sources.id`, or `critical_functions.id`. The harness FK pre-validator rejects a
  wrong-id-space value before insert.
- `exhaustion_log` is written by the orchestrator at flush; the lane agent emits it as a
  field in the row event. Oversize logs spill to `db/sidecars/<hash>` and the path is
  stored in `payload_sidecar_path`.
- `agent_steps` uses the same status semantics as other Phase 0.75 lanes: `success`
  (bypass found + reproduced), `exhausted` (full solver budget, no bypass), `skipped`
  (build/engine unavailable), `failed` / `timed_out`.
- Per-guard solver artifacts are flushed as `fuzz_artifacts` rows with `agent_step_id`
  linking back to the lane's `agent_steps` row.
- `defense_bypasses` rows emitted by this lane carry `round_id`; the orchestrator
  populates it at flush, not the lane agent.

**Engine stdout → DuckDB column mapping (flush-time):**

- Lane agent emits `defense_symbol` (the guard's `symbol_path`) and `bypass_input_b64`
  (the solved input). The orchestrator resolves `defense_symbol` → `defenses.id` and
  writes that id to `defense_id`; `bypass_input_b64` is decoded and stored as
  `payload` (or spilled to sidecar). Columns `target_id`, `agent_step_id`, `round_id`
  are not in engine output — the orchestrator populates them from run context at flush.

---

## References

- Engine home: `engines/` (precedent from `engines/html-sanitizer-bypass/`; C5 build +
  concolic harness lives at `engines/concolic-bypass/` or under `.vuln-research/build/`)
- Schema: `db/schema.sql` — `defenses` (discovery columns), `defense_bypasses`
  (`reproduced`, `exhaustion_log`, `payload_technique`), `critical_fn_reach` (reachability
  input), `fuzz_artifacts` (solver artifacts)
- Migration: `db/migrations/0013-cpp-java-concolic-bypass.sql`
- Strategy seed: `db/seed/strategies.yml` — `concolic_bypass_lane`
- Gate view: `v_required_deep_lanes` in `db/schema.sql` (DEEP blocking gate)
- Related lanes: `references/methodology/html-sanitizer-bypass-lane.md` (structural
  template), `references/v2/fuzzing-lane.md` §3a (FS/SF concolic hybrid — Phase 1.5
  coverage-stall escalation; distinct from this lane's guard-evasion purpose)
- Defense discovery: `references/v2/bypass-catalogue.md` (Stage A–C fetch protocol,
  exhaustion contract)
- Tooling: SymCC (`https://github.com/eurecom-s3/symcc`), KLEE, SymQEMU for C/C++;
  JBSE and Soot-based engines for Java
