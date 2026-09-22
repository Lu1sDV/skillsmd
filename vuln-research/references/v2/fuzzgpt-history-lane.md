# FuzzGPT History-Driven Lane (Phase 1.4, DEEP-mandatory) — FuzzGPT

> A **history-driven LLM input-generation modality** that runs in Phase 1.4 (beside the dual seed-corpus lanes, before Phase 1.5 Fuzzing). Its job: prime an LLM with the **target's own historical bug-triggering code** to generate unusual, edge-case programs/inputs that ordinary LLM generation never produces, emit them as `fuzz_artifacts(artifact_kind='seed_initial')` for `boundary_fuzz_lane` to consume, and — when a reference/alternative implementation exists — run a **target-agnostic differential oracle** whose divergences are quarantined as `N/A`+`unconfirmed` findings until triage shows a security path. Source of truth: `db/schema.sql` (`fuzz_artifacts` + `gr_findings`) + this doc + the operational lane doc `references/methodology/fuzzgpt-history-driven-lane.md` + the preserved reference set `references/fuzzgpt/`.
>
> FuzzGPT-derived: Deng et al., *Large Language Models are Edge-Case Fuzzers: Testing Deep Learning Libraries via FuzzGPT*, [arXiv:2304.02014](https://arxiv.org/abs/2304.02014). The paper's FS/ZS variants are reproduced faithfully; **fine-tuning (FT) is replaced by an embedding-retrieval pathway (RT)**.
>
> This is **methodology, not a bundled fuzzer.** Generator output feeds the host's installed engines via `boundary_fuzz_lane`; the only shipped code is the deterministic RT *example selector* in `engines/fuzzgpt-retrieval/` (precedented by `engines/html-sanitizer-bypass/`), which never opens DuckDB. Like every other lane, agents emit row events to the queue and the orchestrator is the single DuckDB writer.

---

## 0. Lane identity — `fuzzgpt_history_lane`, distinct from `llm_seed_corpus_lane` and `boundary_fuzz_lane`

Phase 1.4 now has **three** mandatory DEEP seed-generation lanes, plus the Phase 1.5 fuzzer that consumes their output. Keeping `fuzzgpt_history_lane` distinct from the dual seed-corpus lanes is deliberate — they are different *techniques* that produce the same artifact kind.

| | **`fuzzgpt_history_lane`** (this doc) | **`llm_seed_corpus_lane_a/b`** | **`boundary_fuzz_lane`** |
|---|---|---|---|
| Strategy seed | id 24 | ids 12 / 13 | id 10 |
| Phase | **1.4** (before fuzzing) | **1.4** (before fuzzing) | **1.5** (between Hunt and Confirm) |
| Tier | DEEP only | DEEP only | DEEP only |
| Technique | **History-driven** — mine the target's bug history, label each snippet's fuzz target, generate edge-case programs (FS CoT / ZS / RT) | Synthesize seeds from the target's **input-format families** (LLM stochasticity dual) | Coverage-guided mutation/symbolic over harnessed boundaries |
| Default output | `fuzz_artifacts(artifact_kind='seed_initial')` | `fuzz_artifacts(artifact_kind='seed_initial')` | `fuzz_runs` + `fuzz_artifacts` (+ `gr_findings` `fuzz_crash`/`fuzz_divergence`) |
| Extra oracle | **Target-agnostic differential** (in-lane sub-mode) → quarantined `gr_findings` | none | sanitizer abort / invariant break |
| Mandatory? | **Yes** — run or skip-with-reason (§ 1) | **Yes** — run or skip-with-reason | **Yes** — run or skip-with-reason |

`fuzzgpt_history_lane` **coexists with** the dual seed-corpus lanes; it does **not** replace them. All three emit `seed_initial` artifacts into the same content-hash-deduped corpus that `boundary_fuzz_lane` resumes from (`references/v2/fuzzing-lane.md` § 1a + § 6d): history-driven edge-case programs, input-format-family seeds, and existing in-tree seeds are complementary layers. A history-driven seed carries rare *code ingredients* mined from real past bugs (special values like `NaN`/`inf`/`INT_MAX`, 0-size dimensions, oversized/empty inputs, unconventional API/feature use) that neither format-family synthesis nor blind mutation tends to produce.

### The "fuzz target" disambiguation (read this)

FuzzGPT's **"fuzz target"** is the **unit generation is steered toward** — an API (the paper's DL study), a compiler flag/optimization pass, a SQL feature, an SMT theory, a syscall/ioctl, a bytecode opcode, a parser/format field, or a protocol message type. This is **NOT** the libFuzzer *harness* sense of "fuzz target" used in `references/v2/fuzzing-lane.md` and `references/methodology/fuzz-harness-craft.md` (the `LLVMFuzzerTestOneInput`-style entry point a coverage fuzzer drives). Throughout `references/fuzzgpt/`, **wherever the docs say "API," read "fuzz target"** in this unit sense; `evaluation.md` keeps "API" verbatim because it reports the paper's actual PyTorch/TensorFlow numbers.

| Domain | A "fuzz target" is… | Example |
|--------|---------------------|---------|
| DL / numeric library (paper) | a library API | `torch.gather` |
| Compiler / interpreter | a flag / optimization pass / construct | `-O2`, loop-unrolling |
| DB engine | a SQL feature / function | window functions, `JSON_TABLE` |
| SMT solver | a theory / operator | bitvectors, `array-ext` |
| Kernel / runtime | a syscall / ioctl | `io_uring`, `ioctl(FS_IOC_…)` |
| Parser / file format | a format field / chunk | PNG `tEXt`, ELF section header |
| Network protocol | a message type / field | TLS extension, HTTP/2 frame |
| Bytecode VM | an opcode | `INVOKEDYNAMIC` |

---

## 1. Mandatory-attempt discipline (`boundary_fuzz_lane` rule)

DEEP **MUST** run this lane. It is not optional and not "best effort." Mirrors the boundary-fuzz discipline (`references/v2/fuzzing-lane.md` § 1). Two legitimate end states only:

1. **Ran** — the target's bug history was mined and at least one fuzz target was driven through generation; emitted `seed_initial` artifacts (and, if a reference/alternative context exists, ran the differential oracle). The lane records its `agent_steps` status transition and the generated artifacts/finding rows.
2. **Skipped-with-reason** — the target has **no minable bug history** (e.g. a fresh closed-source binary with no public issue tracker, commits, or reproductions), recorded as `agent_steps.status='skipped'` with a non-empty `termination_reason` (e.g. `no_minable_bug_history`). The orchestrator verifies the skip before accepting the lane as exhausted, exactly as it verifies a boundary-fuzz skip and bypass `exhaustion_log`.

The bar for skipping is **"there is no minable bug history for this target"**, never "mining is tedious." A target with a public issue tracker, closed PRs with code blocks, or a CVE history with reproductions is **not** a legitimate skip — the no-history ChatGPT instruct variant (`references/fuzzgpt/SKILL.md` no-history fallback; `references/fuzzgpt/evaluation.md` §7) is the weakest variant but is still an *attempt*, not a skip. LOW and MEDIUM do not run this lane (it is a DEEP escalation, like the other Phase 1.4/1.5 lanes).

A lane with zero `agent_steps` rows and no documented skip is a BLOCKING `gate_status='MISSING'` in `v_lane_coverage` (it is in `v_required_deep_lanes` at `phase1_4_seed`).

---

## 2. The two modes

### Mode A — Generator (default)

The history-driven generation pipeline. Five steps (full operational detail in `references/methodology/fuzzgpt-history-driven-lane.md`; templates/formulas in `references/fuzzgpt/`):

```
1. MINE      gh issues/PRs/commits → bug-triggering code snippets (+ titles)
2. ANNOTATE  6-shot self-training label of each snippet's buggy "fuzz target"
3. GENERATE  few-shot CoT (default) | zero-shot | retrieval (RT)  → edge-case programs
4. EMIT      write programs as fuzz_artifacts(artifact_kind='seed_initial')
5. (Phase 1.5) boundary_fuzz_lane consumes the merged corpus + applies crash/sanitizer oracles
```

- **Few-shot (FS, default):** prepend K=6 `(fuzz target, Bug description, code)` examples; CoT — the model predicts a `Bug description:` first, then the code. Highest fuzz-target + valid-program counts in the paper. (`references/fuzzgpt/prompt-templates.md` § 3.2.1.)
- **Zero-shot (ZS):** reuse a real snippet verbatim (completion: truncate suffix, model finishes; or editing). Concrete bug ingredients survive into the new program. (`prompt-templates.md` § 3.2.2.)
- **Retrieval (RT):** the FT replacement. Embed the annotated corpus once, retrieve the K=6 most relevant triples for the target unit at generation time, feed them into the FS CoT template (Mode A) or a single snippet into the ZS completion path (Mode B). No GPU training. The deterministic cosine+MMR selector ships in `engines/fuzzgpt-retrieval/` (`build_index` / `select_examples`, fallback-to-random below τ); the pluggable embedding adapter is env-configured (no hardcoded keys). Full methodology: `references/fuzzgpt/retrieval.md`.

**Recording contract (generator):** generated programs are `fuzz_artifacts(artifact_kind='seed_initial')` rows (inline if small, sidecar if large), exactly like the dual seed-corpus lanes — **no schema change** on this path (`seed_initial` is canonical since migration 0008). They flow into `boundary_fuzz_lane`'s resume protocol; a resulting crash/leak/divergence becomes a `gr_findings(finding_kind='fuzz_crash'/'fuzz_divergence')` candidate **through the existing Phase 1.5 oracle + five-gate Confirm** — this lane does not assign severity to generator output directly.

### Mode B — Target-agnostic differential oracle (in-lane sub-mode)

Runs **when a reference or alternative execution context exists**. **Target-agnostic — NOT DL-specific** (the paper's CPU/GPU + autodiff differentials are just the DL instance). Compare any pair of supposedly-equivalent execution contexts and flag a divergence:

| Equivalence axis | "A vs B" pair (examples) |
|---|---|
| Implementation A vs B | two libraries/parsers implementing the same spec; a reference implementation vs the target |
| Version N vs N+1 | the target before/after an upgrade or a patch hunk |
| Optimization level | same program at `-O0` vs `-O2` (EMI / equivalence-modulo-inputs for compilers) |
| Config flag | same input under two config/feature-flag states that should agree |
| Backend / mode | engine A vs engine B for the same query; reverse- vs forward-mode vs numerical (the DL autodiff instance) |

A divergence beyond tolerance is a **candidate finding**, but it is a *correctness/behavioral* signal, not yet a *security* signal. See § 3 for the quarantine.

(Crash detection always applies and is not part of this differential sub-mode — a crash from a generated program is the generator path's `fuzz_crash`, routed through Phase 1.5 / Confirm as above. The oracle generalization table is `references/fuzzgpt/oracles.md`.)

---

## 3. Differential quarantine — the `N/A` classification + `unconfirmed` status

A differential divergence is recorded as a `gr_findings` row in a **quarantined** state so it stays out of the security severity machinery until proven:

```
finding_kind        = 'differential_divergence'   -- open free-TEXT vocab, alongside fuzz_crash / fuzz_divergence
severity            = NULL                          -- the "N/A" classification
confirmation_status = 'unconfirmed'                 -- the quarantine status (distinct from 'candidate')
```

**Why this placement (per the CHECK-enum-vs-free-TEXT doctrine at the top of `db/schema.sql`):**

- **`severity` is NOT widened with an `N/A` member.** It is the closed SECURITY-rating vocabulary `{LOW, MEDIUM, HIGH, CRITICAL}` that feeds the ranking/report views; polluting it with a non-severity member would corrupt every ranking, and DuckDB cannot widen a rank-bearing inline CHECK in place. The **"N/A" classification is the documented free-TEXT/NULL state**: `finding_kind='differential_divergence'` (open vocab) with `severity = NULL`. A severity is assigned only when triage promotes the finding and Confirm/Proof rates it.
- **`confirmation_status` DOES gain a fourth enum member**, `unconfirmed`, because it is a closed low-cardinality vocabulary (the doctrine's CHECK-enum criterion): `{candidate, confirmed, refuted, unconfirmed}`. `unconfirmed` is deliberately distinct from `candidate` — a `candidate` is a *security* hypothesis already inside the five-gate Confirm queue; an `unconfirmed` differential divergence is a *behavioral* observation that has **not** entered the security queue. (Schema mechanics: the canonical `db/schema.sql` carries the widened 4-way CHECK directly; on a legacy in-place upgrade DuckDB cannot widen the FK-bearing CHECK, so migration 0024 enforces `unconfirmed` app-side, the 0019 precedent.)

**It stays out of the rankings.** A NULL-severity `unconfirmed` row is counted by neither `findings_candidate_open` (which counts `confirmation_status='candidate'`) nor `findings_confirmed`, so it never appears in the HIGH/MED/LOW report rollups, the `confirmed_vulns` registry, or the DoS-excluded top-leads. It is honest progress, not a security finding.

**Promotion flow.** A divergence leaves quarantine only when triage demonstrates a **security-impact path** — the same bar as any finding: control an input, reach the divergence on a real attacker-reachable path, and show impact (memory unsafety, auth/logic divergence with a security consequence, an exploitable miscompilation, …). On promotion, set `confirmation_status='candidate'` (entering the standard five-gate Confirm, `references/v2/confirmation-rigor-doctrine.md`) and let Confirm/Proof + the Phase L7 exploitability gate assign a real `severity`. **No new confirm/promotion path is built** — promotion reuses the existing machinery. Divergences that never show a security path remain `unconfirmed` (a documented behavioral observation), consistent with the skill's *"working exploit or it's noise"* doctrine and the DoS exclusion.

---

## 4. Recording contracts (summary)

| What | Row | Notes |
|---|---|---|
| Lane execution | `agent_steps` (strategy_id → `fuzzgpt_history_lane`) | one per round; `success`/`exhausted` or `skipped` + `termination_reason` |
| Lane observations | `agent_observations` (≥ 1 per executed phase) | `dead_end` / `invariant` / `blind_spot` minimum (DEEP observation-floor gate) — e.g. corpus size, labeling precision sample, fuzz targets covered, divergences found |
| Generated edge-case programs | `fuzz_artifacts(artifact_kind='seed_initial')` | content-addressed; merged (content-hash dedup) with the dual seed-corpus + in-tree seeds; consumed by `boundary_fuzz_lane` |
| Crash/leak/divergence FROM a generated program (Phase 1.5) | `gr_findings(finding_kind='fuzz_crash'/'fuzz_divergence')` + `fuzz_runs` | via the boundary-fuzz oracle + five-gate Confirm, not assigned here |
| Differential divergence (Mode B) | `gr_findings(finding_kind='differential_divergence', severity=NULL, confirmation_status='unconfirmed')` | QUARANTINED (§ 3); promote to `candidate` only on a shown security path |

---

## 5. Model routing (orchestration)

If you run this lane as a multi-agent workflow, **opus bookends, cheap models fill the middle** (`references/fuzzgpt/orchestration.md`): spend opus on the two judgment moments — variant/strategy selection (which of FS/ZS/RT, K, budget) and **differential-oracle triage** (is a divergence a real wrong-behavior signal or acceptable tolerance/non-determinism — and does it have a security path?) — and run mining, annotation, indexing, generation loops, and crash-detection on sonnet/haiku. Steps 3–5 are parallel per fuzz target: one sonnet executor per fuzz target, funnel only the differential-divergence cases into one opus triage lane. (Orchestration tier ≠ generation-model choice; set independently.) In `find-ctfs`, run analysis/triage lanes on opus per the project precision doctrine.

---

## 6. Cross-references

- `references/methodology/fuzzgpt-history-driven-lane.md` — operational lane methodology (the how-to behind this doctrine).
- `references/fuzzgpt/` — preserved verbatim FuzzGPT reference set (`pipeline`, `prompt-templates`, `retrieval`, `hyperparameters`, `oracles`, `evaluation`, `orchestration`) + its `README.md` index + paper attribution.
- `references/v2/fuzzing-lane.md` — Phase 1.5 `boundary_fuzz_lane` that consumes this lane's seeds; § 1a is the seed-corpus feed-in contract.
- `references/v2/seed-corpus-generation-lane.md` — the sibling Phase 1.4 dual seed-corpus lanes (`llm_seed_corpus_lane_a/b`) this lane coexists with.
- `references/methodology/fuzz-harness-craft.md` — harness craft under the fuzzing lanes (the libFuzzer-*harness* sense of "fuzz target").
- `references/binary/binary-bug-classes.md` § 5 (fuzzing) — binary-target fuzzing; a history-driven seed corpus is an input to that fuzzing where a binary has a bug history.
- `references/v2/confirmation-rigor-doctrine.md` — the five-gate Confirm that promotion reuses.
- `engines/fuzzgpt-retrieval/` — the deterministic RT example selector + embedding adapter (never opens DuckDB).
