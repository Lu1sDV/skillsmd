# FuzzGPT History-Driven Lane — Methodology (Phase 1.4, DEEP)

Operational how-to for `fuzzgpt_history_lane`. The doctrine (lane identity, modes, the `N/A`+`unconfirmed` quarantine, recording contracts, gates) is `references/v2/fuzzgpt-history-lane.md`; the preserved verbatim depth set with exact templates/formulas/tables is `references/fuzzgpt/` (start at its `README.md`). This file is the step-by-step.

FuzzGPT-derived: Deng et al., arXiv:2304.02014. The paper's FS/ZS variants are reproduced faithfully; fine-tuning (FT) is replaced by the embedding-retrieval pathway (RT).

**Core idea.** Historical bug-triggering programs contain rare, valuable *code ingredients* — special values (`NaN`, `inf`, `INT_MAX`, empty/oversized inputs), edge-case shapes/sizes, 0-size dimensions, unconventional use of the target — that ordinary LLM generation never produces. LLMs trained on GitHub generate *typical* programs; fuzzing wants *unusual* ones. This lane closes the gap by priming the LLM with the target's real past bugs instead of asking it to "be creative."

**"Fuzz target" here = the unit you steer generation toward** (API / compiler flag / SQL feature / syscall / opcode / protocol field), **not** the libFuzzer harness (`references/methodology/fuzz-harness-craft.md`). See the disambiguation table in `references/v2/fuzzgpt-history-lane.md` § 0.

---

## When to run / skip

| Situation | Action |
|-----------|--------|
| Target has a public issue tracker, closed PRs with code blocks, or a CVE history with reproductions | **Run** (mine the history) |
| Target is brand new / closed-source binary with **no** minable bug history | **Skip-with-reason** (`agent_steps.status='skipped'`, `termination_reason='no_minable_bug_history'`) |
| History is thin but nonzero | Run; if ZS is starved (too few real snippets), prefer FS; the no-history ChatGPT instruct variant is the weakest *attempt* but still not a skip |

DEEP-mandatory: run or documented-skip (the `boundary_fuzz_lane` rule). The lane is in `v_required_deep_lanes` at `phase1_4_seed`; zero steps + no skip = BLOCKING `MISSING`.

---

## Step 1 — MINE (sonnet/haiku; out-of-band subprocess)

Crawl the target repo's **issues and PRs** for bug-triggering code. Use `gh` (verbatim one-liners in `references/fuzzgpt/pipeline.md` § 3.1.1):

```bash
gh issue list -R <owner>/<repo> --label bug --state all --limit 2000 \
  --json number,title,body > issues.json
gh pr list -R <owner>/<repo> --state closed --limit 2000 \
  --json number,title,body,commits > prs.json
```

Then, **out-of-band** (token-frugal — the agent never ingests the raw corpus, per the project harness doctrine): extract fenced code blocks, concatenate blocks per issue, keep the issue/PR **title** as the `Bug description`. Cleaning (do all): drop tracebacks/error text, drop REPL echo / printed-output lines, drop snippets failing a syntax check (`ast.parse` for Python; the target language's parser otherwise), drop snippets > 256 tokens.

Output: a set of `(code_snippet, title)` pairs.

## Step 2 — ANNOTATE (sonnet; imprecise labels are fine)

Each snippet exercises several fuzz targets, so the buggy one isn't directly extractable. Use **self-training**: manually label **K=6** seed snippets with the buggy fuzz-target name, then have the LLM label the rest with the 6-shot prompt at **`temperature=0`** (greedy). Template = Figure 3 in `references/fuzzgpt/pipeline.md`; the literal completion label is `Buggy API:` in the paper — **rename it to your unit** (`Buggy syscall:`, `Buggy SQL feature:`, `Buggy opcode:`, …) when retargeting.

Imprecise labels are acceptable (paper: 76% precision; mislabels still beat the ZS baseline) — they only *steer* the model toward a fuzz target; the bug often surfaces in a different one.

Output: the annotated corpus of `(target_unit, description, code)` triples.

## Step 3 — GENERATE (opus picks the variant; sonnet runs the loop)

Pick a variant (the **opus** judgment moment — wrong choice wastes the whole 100-progs-per-target budget):

- **Few-shot CoT (FuzzGPT-FS) — DEFAULT.** Prepend K=6 `(fuzz target, Bug description, code)` examples, then the target query with an empty `Bug description:`. CoT = model predicts the description first, then the code — this "reason then generate" step is what produces unusual programs. Highest fuzz-target + valid-program counts. (`references/fuzzgpt/prompt-templates.md` § 3.2.1.)
- **Zero-shot (FuzzGPT-ZS).** Reuse a real snippet verbatim — completion (truncate suffix, model finishes after `# The following code reveals a bug in {fuzz_target}`) or editing. Concrete bug ingredients survive into the new program. Lower valid-rate; needs a rich corpus. (`prompt-templates.md` § 3.2.2.)
- **Retrieval (RT) — the FT replacement.** Index the annotated corpus once (`engines/fuzzgpt-retrieval/`: `build_index`), then at generation time retrieve K=6 on-target triples (`select_examples`, MMR over top-N=30, λ=0.5, fallback-to-random below τ≈0.2) and feed them into the FS CoT template (Mode A) or a single snippet into the ZS path (Mode B). No GPU training; runs on any generator. The embedding backend is env-configured (no hardcoded keys). Full methodology: `references/fuzzgpt/retrieval.md`; selector + adapter usage: `engines/fuzzgpt-retrieval/README.md`.

**Generation contract (paper-exact, model-independent — keep unchanged):** `temperature=0.8`, `top_p=0.95`, `max_token=256`, K=6, **100 programs per fuzz target** (10 prompts × 10 generations; for RT call `select_examples` 10 times with varied seeds). Annotation stays `temperature=0`. Swap the *model* (Codex is retired) per `references/fuzzgpt/hyperparameters.md`'s modern mapping; keep the *settings*.

## Step 4 — EMIT seeds (generator path; no schema change)

Write the generated edge-case programs as `fuzz_artifacts(artifact_kind='seed_initial')` row events (inline if small, sidecar if large) — exactly like the dual seed-corpus lanes. They merge (content-hash dedup) with `llm_seed_corpus_lane_a/b` output and in-tree seeds into the corpus `boundary_fuzz_lane` resumes from (`references/v2/fuzzing-lane.md` § 1a, § 6d). A crash/leak/divergence that Phase 1.5 then finds becomes a `gr_findings(finding_kind='fuzz_crash'/'fuzz_divergence')` candidate **through the existing Phase 1.5 oracle + five-gate Confirm** — this lane does not rate it directly.

## Step 5 — DIFFERENTIAL ORACLE (Mode B; only when a reference/alternative context exists)

**Target-agnostic — NOT DL-specific.** Run a generated program (or a mined real one) under two supposedly-equivalent execution contexts and compare outputs beyond a tolerance:

| Axis | Pair |
|---|---|
| Impl A vs B | reference impl vs target; two parsers of one spec |
| Version N vs N+1 | pre/post upgrade or patch hunk |
| Optimization level | `-O0` vs `-O2` (EMI for compilers) |
| Config flag | two feature/config states that should agree |
| Backend / mode | engine A vs B; reverse-/forward-/numerical AD (the DL instance) |

Use a significance tolerance to absorb legitimate non-determinism (`references/fuzzgpt/oracles.md`). A divergence is **quarantined** (next section); triage of "real wrong-behavior vs tolerance, and is there a security path?" is the second **opus** judgment moment.

---

## The differential quarantine (decision record — see doctrine § 3)

Record a divergence as:

```
gr_findings.finding_kind        = 'differential_divergence'   (open free-TEXT vocab)
gr_findings.severity            = NULL                          (the "N/A" classification)
gr_findings.confirmation_status = 'unconfirmed'                 (quarantine; NOT 'candidate')
```

It stays **out of** the HIGH/MED/LOW rankings, the `confirmed_vulns` registry, and `findings_candidate_open`/`findings_confirmed` until triage shows a **security-impact path**. To promote: set `confirmation_status='candidate'` (entering the standard five-gate Confirm) and let Confirm/Proof + the Phase L7 gate assign a real `severity`. Divergences with no security path remain `unconfirmed` — a documented behavioral observation, consistent with *"working exploit or it's noise"* + the DoS exclusion. `unconfirmed` is a closed-vocab `confirmation_status` member; `N/A` severity is the free-TEXT/NULL state (NOT a new severity enum value) — per the `db/schema.sql` CHECK-enum-vs-free-TEXT doctrine.

---

## Observations to flush (DEEP observation-floor)

Every executed phase flushes ≥ 1 `agent_observations` row. Useful ones for this lane: corpus size after cleaning, labeling-precision spot-check, # fuzz targets covered, valid-rate, # generated seeds emitted, # differential divergences (and their triage verdict), and any `blind_spot` (a fuzz target with no mined history). A documented skip records `termination_reason` and an observation explaining why no history was minable.

## No-history fallback (weakest attempt — still not a skip)

If history is unusable, directly instruct an instruct-following model: system = `You are a {target} fuzzer.`, then ask for a program using `{fuzz_target}` *"in a way you have not seen in your training dataset"* / *"in a very creative way"* / *"in a non-conventional way"* (paper §7; `references/fuzzgpt/SKILL.md` no-history section). Lower valid-rate, broad coverage. Prefer history when available.

## Cross-references

- Doctrine: `references/v2/fuzzgpt-history-lane.md`
- Verbatim depth: `references/fuzzgpt/` (`pipeline`, `prompt-templates`, `retrieval`, `hyperparameters`, `oracles`, `evaluation`, `orchestration`)
- Consumes into: `references/v2/fuzzing-lane.md` (Phase 1.5 `boundary_fuzz_lane`)
- Sibling Phase 1.4 lane: `references/v2/seed-corpus-generation-lane.md`
- Harness craft (libFuzzer-*harness* sense of "fuzz target"): `references/methodology/fuzz-harness-craft.md`
- Binary fuzzing: `references/binary/binary-bug-classes.md` § 5
- Promotion machinery: `references/v2/confirmation-rigor-doctrine.md`
- RT selector + adapter: `engines/fuzzgpt-retrieval/`
