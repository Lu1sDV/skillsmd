# Tool Run-and-Ingest Recipes (Tier 4 — SAST/AST output → DuckDB hypotheses)

> **Load when**: a DEEP or MEDIUM run has CodeQL / Semgrep / ast-grep available and you need to turn their *native output* into `gr_findings` / `sinks` / `input_slices` row events. Companion to `references/phases/tool-integration-matrix.md` (which tool, in what priority) and `references/methodology/joern-forward-slicing.md` (the Joern layer, which has its own cookbook). This doc is the **priority-2/3** recipe: run the tool, parse its real output, ingest it as candidates.
>
> **Two rules govern every recipe here.** (1) A tool hit is a **hypothesis**, never a finding — it lands at `confirmation_status='candidate'` and earns promotion only through the five-gate Confirm (`references/v2/confirmation-rigor-doctrine.md`). (2) **Coverage is computed from the tool's own output, never self-reported** — the run records what was actually scanned (rules × files × KLOC, parse failures), so a later round knows what ground was covered and what was skipped.

This file exists because "run Semgrep and look at the results" was previously prose with no contract. The orchestrator needs the *exact* command, the *exact* parse, and the *exact* serialization into DuckDB row events — and it needs every hit to enter the same skeptical pipeline an LLM hunt hit does, so a green Semgrep run never inflates the confirmed-vuln count.

---

## 0. The shared ingest contract

Every tool below produces results that name a `(file, line, rule, severity)` and sometimes a dataflow path. They all ingest the same way:

1. **The orchestrator runs the tool** (agents never shell out to a scanner directly — single-writer discipline) and captures structured output (SARIF / JSON), never scraped stdout.
2. **Each result → a `gr_findings` row event** at `confirmation_status='candidate'`, `agent_step_id` = the ingest step. Because `gr_findings` has **no file/line/cwe column**, the location and CWE live inside the `payload` JSON (same convention as a fuzz crash, `references/v2/fuzzing-lane.md` § 6a).
3. **Resolve `(file,line)` to a `sinks` / `sources` row** so the finding joins the existing map: if a `sinks` row already has that `evidence_path`/`evidence_line`, set `sink_id`; else emit a *candidate* `sinks` row first and reference it. A dataflow result resolves both ends (source + sink) and additionally emits an `input_slices` row for the path.
4. **`finding_kind`** is free TEXT (no CHECK enum), so use a stable, tool-tagged value: `codeql_path`, `semgrep_taint`, `semgrep_pattern`, `astgrep_pattern`. This keeps a tool-sourced hypothesis distinguishable from an LLM-sourced one at triage time.
5. **`finding_hash`** is derived by the orchestrator at flush over the resolved `(target_id, sink_id|source_id, finding_kind, normalized-location)` — the agent never supplies it. This is what dedups the same hit seen by two tools (§ 4).
6. **Severity is preliminary** — the tool's severity maps to `gr_findings.severity` as triage only; Confirm decides the verdict.

The provenance block that every tool result carries in `payload`:

```jsonc
{"kind": "gr_findings", "row": {
  "target_id": 1,
  "finding_kind": "semgrep_taint",
  "sink_id": 42, "source_id": 17,            // resolved per § 0.3 (null → candidate sink/source emitted alongside)
  "agent_step_id": 91,
  "confirmation_status": "candidate",
  "config_state": "unknown",
  "severity": "HIGH",                         // preliminary, from the tool
  "payload": {
    "evidence_path": "app/handlers/user.go", "evidence_line": 88,
    "cwe": "CWE-89",                          // derived per the tool's rule metadata (§§ 1–2)
    "tool": "semgrep", "tool_version": "1.x", "rule_id": "go.lang.security.sqli.raw-query",
    "message": "Untrusted input concatenated into SQL query",
    "dataflow_path": [ /* see § 2 — present for taint-mode results */ ],
    "raw_result_ref": "db/sidecars/<finding_hash>.sarif-fragment"   // oversize raw spills here
  }
}}
```

---

## 1. CodeQL — SARIF path queries → `gr_findings` + `input_slices`

CodeQL's value is **inter-procedural path queries** with a maintained query pack. Run a security-extended analysis and ingest the SARIF.

```bash
# 1. Build the database (compiled langs need the build command; interpreted ones don't).
codeql database create "$AUDIT_DIR/cdb" --language="$LANG" \
  --source-root "$TARGET_SRC" ${BUILD_CMD:+--command "$BUILD_CMD"}

# 2. Run the security pack; SARIF is the machine-readable contract (NOT the CSV).
codeql database analyze "$AUDIT_DIR/cdb" \
  codeql/"$LANG"-queries:codeql-suites/"$LANG"-security-extended.qls \
  --format=sarifv2.1.0 --output "$AUDIT_DIR/codeql.sarif" --sarif-add-snippets
```

**Parse SARIF → row events.** Each `runs[].results[]` entry:

| SARIF field | Maps to |
|---|---|
| `locations[0].physicalLocation` → `artifactLocation.uri` + `region.startLine` | `payload.evidence_path` / `evidence_line` → resolve to `sinks` row (§ 0.3) |
| `ruleId` + `rules[].properties.tags` (e.g. `external/cwe/cwe-089`) | `payload.cwe` (parse the `cwe-NNN` tag) + `finding_kind='codeql_path'` |
| `level` (`error`/`warning`/`note`) | preliminary `severity` (`error`→HIGH, `warning`→MEDIUM, `note`→LOW; bump to CRITICAL only on a memory-safety/RCE rule class) |
| `codeFlows[].threadFlows[].locations[]` | the **dataflow path** → one `input_slices` row (`slice_kind='forward_taint'`), source = first node, sink = last |
| `message.text` | `payload.message` |

A CodeQL `codeFlow` is a ready-made taint path: its first node resolves to a `sources` row, its last to a `sinks` row, and the ordered node list hashes into `input_slices.callee_set_hash` exactly like a Joern flow (`joern-forward-slicing.md` § 6). Ingesting it as an `input_slices` row means the path query result re-enters Phase 1/2 as a *slice to re-trace*, not a verdict.

```jsonc
{"kind": "input_slices", "row": {
  "target_id": 1, "source_id": 17, "critical_fn_id": null,
  "slice_kind": "forward_taint",
  "callee_set_hash": "<sha256 of ordered threadFlow location symbols>",
  "callee_count": 6,
  "representative_callees": ["readBody", "parseForm", "buildQuery", "db.Raw"],
  "coverage_json": {"source": "codeql", "rule_id": "go/sql-injection", "path_len": 6}
}}
```

### 1.1 Data-extension models — make CodeQL see project wrappers (do not skip)

CodeQL only flags flows whose sources/sinks/steps it *models*. Even Django/Spring/Express apps wrap
the framework (`def query(sql)` around the cursor, `runShell()` around `exec`), and an unmodeled
wrapper means the taint path silently dies at the wrapper — a **false-clean**, the most expensive
failure mode. Before trusting a low/zero-finding CodeQL run, author **data-extension** YAML models
for the project's own source/sink/summary wrappers:

```yaml
# extensions/app-sinks.yml — model a custom command-exec wrapper as a sink
extensions:
  - addsTo:
      pack: codeql/<lang>-all
      extensible: sinkModel
    data:
      # package, type, subtypes, name, signature, ext, input, kind
      - ["app.util", "Shell", false, "runShell", "(String)", "", "Argument[0]", "command-injection"]
```

Discover wrappers to model with the diagnostic source/sink-enumeration queries, then re-analyze
with `--threat-model` set and the extension pack on the search path. **Per-target** extension YAML
lives under the audit workspace at `.vuln-research/codeql-extensions/` (tool config, not audit
data — the `.vuln-research/rules/` Semgrep analogue in `semgrep-rule-authoring.md`); a model that
proves generally reusable graduates into a committed pack. **Modeling is part of the recipe, not
optional** — record each authored model as a **reusable `agent_observations` row**
(`obs_kind='detection_authored'`, `target_id`, the model path, the wrapper modeled) so it is
inspectable, single-writer-clean, and fed forward to the next round; a thin CodeQL run with no
modeling and no justification can't masquerade as coverage.

### 1.2 Run hygiene — three traps that produce false-clean

- **Database quality ≠ "it built."** A cached/partial build extracts nothing. Check baseline LoC
  > 0 and extractor errors < ~5%, and compare file counts to expected sources, before trusting any
  result. Fold the check into the run's `coverage_json` (`files_scanned`, `kloc_scanned`) — the
  shared ingest contract already rejects an `exhausted` step with no file count.
- **Use an explicit suite, never bare pack names.** Each pack's `defaultSuiteFile` applies hidden
  filters and can return zero. Reference `…-security-extended.qls` (and, for full coverage,
  `security-and-quality` **plus** `security-experimental` — the latter is excluded by the former).
  Layer Trail of Bits + Community packs when present; `security-extended` is the baseline, not the
  ceiling.
- **Zero findings → investigate, don't celebrate.** A clean run is a hypothesis about *tooling*
  (bad DB, missing models, wrong suite, silent filter), not about the code. Re-check the three
  above before recording the lane `exhausted`.

> **SARIF dedup hint.** When correlating CodeQL + Semgrep hits (§4), seed the `finding_hash`
> dedup with each result's `partialFingerprints` where present, falling back to
> `(ruleId, normalized-path, startLine, snippet)` — paths differ across environments, so never
> dedup on raw URI alone.

---

## 2. Semgrep — JSON results → `gr_findings` (+ `input_slices` for taint mode)

Semgrep is the cheapest dataflow-aware layer. Run with the registry security packs **plus** the repo's own packs (this project ships PHP rules — `sinks/` / SKILL.md), and emit JSON.

```bash
semgrep --config p/security-audit --config p/secrets \
  ${REPO_RULES:+--config "$REPO_RULES"} \
  --json --output "$AUDIT_DIR/semgrep.json" \
  --metrics=off --max-target-bytes 2000000 "$TARGET_SRC"
```

**Parse `results[]` → row events:**

| Semgrep JSON field | Maps to |
|---|---|
| `path` + `start.line` | `payload.evidence_path` / `evidence_line` → resolve to `sinks` row |
| `check_id` | `payload.rule_id`; `finding_kind` = `semgrep_taint` if `extra.dataflow_trace` present, else `semgrep_pattern` |
| `extra.metadata.cwe` (e.g. `["CWE-79: ..."]`) | `payload.cwe` (take the `CWE-NN` prefix) |
| `extra.severity` (`ERROR`/`WARNING`/`INFO`) | preliminary `severity` |
| `extra.dataflow_trace.taint_source` / `intermediate_vars` / `taint_sink` | the taint path → one `input_slices` row (`slice_kind='forward_taint'`) |
| `extra.lines` | `payload.message` evidence snippet |

When `extra.dataflow_trace` is present, Semgrep has already done source→sink taint — serialize it as an `input_slices` row the same way as the CodeQL `codeFlow` (§ 1). When it is a pure pattern match (no trace), it is a single-point hypothesis: emit the `gr_findings` candidate and a candidate `sinks` row, but **no** slice (there is no path to claim).

### 2.1 0xdea C/C++ pack — three-tier invocation

For C/C++ targets, layer the 0xdea rules on top of `p/c` + `p/cpp`. The pack uses severity tiers
as a precision dial: ERROR-only is the fastest, lowest-FP pass; full scan covers informational
rules that are useful for triage but noisy as findings.

```bash
# Tier 2 (recommended) — ERROR + WARNING, combined with official packs
semgrep --severity ERROR --severity WARNING \
  --config p/c --config p/cpp \
  --config "$TOOLS_DIR/0xdea-semgrep-rules/rules" \
  --sarif --sarif-output "$AUDIT_DIR/semgrep-c.sarif" \
  --metrics=off --no-git-ignore "$TARGET_SRC"
```

Parse the SARIF exactly per §2; the 0xdea rules carry `extra.metadata.cwe` in their SARIF output.
`finding_kind` is `semgrep_taint` when `extra.dataflow_trace` is present (rare for this pack —
most rules are pattern-mode), else `semgrep_pattern`.

**Candidate-point first pass** — before the full scan, run `raptor-interesting-api-calls` alone
to populate candidate `sinks` rows without generating finding noise:

```bash
semgrep --config "$TOOLS_DIR/0xdea-semgrep-rules/rules/c/interesting-api-calls.yaml" \
  --json --output "$AUDIT_DIR/candidate-points.json" "$TARGET_SRC"
# Each hit → candidate `sinks` row (not `gr_findings`); forward-slicing lanes trace reachability.
```

**Triage-helper rules** (`raptor-argv-envp-access`, `raptor-high-entropy-assignment`,
`raptor-bad-words`) produce candidate `sources` rows or attention-deficit map entries — never
`gr_findings` rows directly. See `references/methodology/0xdea-semgrep-rules.md` for the full
catalog, cluster-to-rule mapping, and the Ghidra-decompiler → Semgrep workflow for binary targets.

---

## 3. ast-grep — structural matches → candidate `sinks` / `sources`, not findings

ast-grep has **no dataflow** — it matches AST shapes. So its output is not a finding; it is a **sink/source candidate generator** that feeds the map the hunt and the slicing lanes consume. Treat an ast-grep hit as "here is a place worth slicing," never as "here is a bug."

```bash
# Structural sink discovery — e.g. raw query construction in Go.
ast-grep run --pattern '$DB.Raw($Q)' --lang go --json "$TARGET_SRC" > "$AUDIT_DIR/astgrep-sinks.json"
```

Each match → a **candidate `sinks` row** (or `sources` row for input-reading patterns), carrying `evidence_path`/`evidence_line` and a low initial `rank_score`. The critical-function hunt and the forward-slicing lanes then decide whether the candidate is reachable. If you ever emit an ast-grep hit straight to `gr_findings`, it must be `finding_kind='astgrep_pattern'` at `candidate` with **no** `sink_id`-implied path claim — but prefer the sink-candidate route, which keeps structural noise out of the findings table until a slice substantiates it.

---

## 4. Cross-tool correlation — corroboration, not duplication

Two tools flagging the same `(file, line, cwe)` is a **stronger** hypothesis, not two findings. The orchestrator's flush dedups by `finding_hash` (§ 0.5); when a second tool resolves to an existing finding's hash:

- Do **not** create a second `gr_findings` row. Append the second tool's provenance to the existing row's `payload.corroborated_by[]` (`{tool, rule_id}`).
- Raise the finding's preliminary `severity` toward the higher of the two, and if the location maps to a `critical_functions` row, nudge `factor_attention_deficit` down (it is clearly *not* under-examined) while treating multi-tool agreement as a reason to schedule its Confirm first.

Conversely, a hit **only one** tool finds, in code no other layer reaches, is not weaker by default — single-tool hits on under-audited modules are exactly where novel bugs hide. Correlation raises priority; it never gates a hypothesis out.

---

## 5. Coverage contract — compute it, do not assert it

The ingest step writes `agent_steps.coverage_json` from the tool's *own* run metadata, so "we ran SAST" is a measured claim. Required keys:

| Key | Derivation |
|---|---|
| `tool` / `tool_version` | from the binary |
| `rules_run` | SARIF `runs[].tool.driver.rules.length` / Semgrep `--verbose` rule count |
| `files_scanned` / `kloc_scanned` | tool stats (Semgrep `paths.scanned`; CodeQL DB source stats) |
| `files_skipped` | tool stats (`paths.skipped` + parse-failure list) — **non-empty is normal**; an empty skip list on a big polyglot repo means the scan under-ran |
| `parse_failures` | files the tool could not compile/parse → blind spots the next round inherits |
| `results_ingested` / `results_deduped` | counts after § 4 |

The orchestrator rejects an ingest step claiming `status='exhausted'` whose `coverage_json` lacks `files_scanned` or hides `parse_failures` — it rewrites it to `failed` / `termination_reason='incomplete_tool_coverage'`, the same gate the slicing lanes (`joern-forward-slicing.md` § 5) and the fuzzing lane (`references/v2/fuzzing-lane.md` § 8) apply. Self-reported "scan complete" with no file count is not coverage.

---

## 6. The hypothesis discipline (why none of this auto-confirms)

Tool hits enter the five-gate Confirm exactly like any other candidate (`references/v2/confirmation-rigor-doctrine.md`):

- **G1 taint reach** — is the flagged sink reachable from a real untrusted source? A Semgrep pattern match with no real source path, or a CodeQL result whose `codeFlow` originates in test fixtures, is **refuted** (`not_reachable`), not reported.
- **G2 defense gap** — does a Tier-1/2 defense on the path neutralize it? Cross-check the bypass catalogue (`references/v2/bypass-catalogue.md`); a SAST hit behind an effective sanitizer is a false positive.
- **G3 intended-feature filter** — is the hit in dev/debug/test-only code? Filter via `intended_feature_classification`.
- **G4 reproduction artifact** — Phase 4 Proof must still build a PoC; a SAST result alone never satisfies G4 (unlike a fuzz crash, which carries its repro input).

This is the whole point of ingesting tool output as candidates: a scanner's job is to **narrow where to look**, and the methodology's job is to prove or kill each lead. A clean SAST run is not a clean target; a noisy SAST run is not a vulnerable one. The tools widen the funnel; the five gates are what close it.
