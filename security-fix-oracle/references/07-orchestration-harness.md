# Orchestration Harness

How the agent fan-out works, model routing, idempotency, and batch sizing.
For phase-level detail see [01-mining-triage.md](./01-mining-triage.md) through [04-cross-language.md](./04-cross-language.md).
For the per-file harness manifest see [../harness/README.md](../harness/README.md).

---

## Two Orchestration Styles

### 1. Workflow-tool scripts (`.wf.js`)

Used for phases that are large, uniform fan-outs: message triage (phase 1), diff triage (phase 1 diff pass), re-gate (phase 2), non-Ruby confirm (phase 4).

**Runtime contract** — each `.wf.js` runs inside a workflow engine that exposes three globals:

| Global | Signature | What it does |
|--------|-----------|--------------|
| `agent(prompt, opts)` | `opts: {model, schema, label, phase}` | Spawns one subagent; blocks until it returns a schema-validated JSON result |
| `parallel(thunks[])` | `() => Promise` array | Fans out all thunks concurrently; collects results |
| `phase(title)` | string | Groups subsequent `agent` calls under a named phase in the UI |

**Args-normalization idiom** — args may arrive as a JSON string or a plain object depending on how the workflow is invoked. All three scripts normalize identically:

```js
let A = args
if (typeof A === 'string') { try { A = JSON.parse(A) } catch (e) { A = {} } }
if (!A || typeof A !== 'object') A = {}
```

Always do this before destructuring args; callers are not guaranteed to pre-parse.

**Per-batch slice pattern** — the harness precomputes all `[idx, start, end]` triples, then maps them over `parallel()`:

```js
const batches = []
for (let i = 0; i < N; i++)
  batches.push([i, i * BATCH, Math.min(TOTAL, (i + 1) * BATCH)])

const results = (await parallel(
  batches.map(([idx, start, end]) => () =>
    agent(prompt(idx, start, end), { label: `tag:b${idx}`, phase: 'X', model: '...', schema: RESULT_SCHEMA })
  )
)).filter(Boolean)
```

Each subagent receives only its slice — either a `sed -n 'start,endp'` line range (JSONL manifests) or a Python slice expression `json.load(...)[start:end]` (JSON arrays). Subagent context stays small regardless of total corpus size.

**RESULT_SCHEMA contract** — every `.wf.js` declares a JSON Schema object and passes it as `schema:`. The workflow engine enforces the schema on the subagent's return value before handing it back to `parallel`. This means:

- `results` elements are always typed correctly — no ad-hoc `.?.` nullchecks needed beyond `.filter(Boolean)` for timed-out slots.
- Aggregation in the outer script (`results.reduce(...)`) is safe.
- Adding a field to the schema is the only change needed to thread new telemetry through all batches.

The minimal common shape across all three scripts:

```json
{
  "batch": int,
  "processed": int,
  "out_file": string,
  "notes": string
}
```

Phase-specific counts (`security_fixes`, `security_confirmed`, `flipped_to_nonsecurity`, …) are additive fields on top.

---

### 2. Main-loop agent waves

Used for phases where no `.wf.js` wrapper exists or where work is dispatched interactively: CVSS scoring (phase 6), SZZ attribution (phase 7), and ad-hoc re-runs.

**Empirical concurrency cap: ~16 subagents per message.** Beyond that, the orchestrator's output-summary window fills, subagent results get truncated, and context windows begin to overlap. Stay at or below 16 per wave.

**Wave loop pattern:**

```
dispatch wave 1 (≤16 subagents) → wait for all to return
→ aggregate/checkpoint results to disk
→ find next uncompleted batch
→ dispatch wave 2 (≤16)
→ repeat until done
```

Each wave is a single orchestrator message. Aggregation between waves is a Python script run (e.g., `cvss_aggregate.py`) that writes a checkpoint to disk — so a crash between waves loses at most one wave of work.

**Finding the next uncompleted batch** — generic glob snippet:

```bash
# Completed batches leave files like phase-0042.jsonl
# Find the highest completed index, start the next wave from there + 1
ls analysis/phase-*.jsonl 2>/dev/null \
  | sed 's/.*phase-//' | sed 's/\.jsonl//' \
  | sort -n | tail -1
```

Or in Python:
```python
import glob, re
done = {int(re.search(r'(\d+)', f).group(1))
        for f in glob.glob('analysis/phase-*.jsonl')}
next_batch = max(done) + 1 if done else 0
```

---

## Model Routing

Route the cheapest adequate model per task. Paying for Sonnet/Opus to run `git diff` is waste.

| Phase | Task type | Model | Rationale |
|-------|-----------|-------|-----------|
| 1 message triage | Title + body classification, 189k commits | **Haiku** | Coarse default-deny; text-only, no code reasoning needed; cost dominates at scale |
| 2 re-gate suspects | Title + body re-judgment, ~1k noise commits | **Haiku** | Same text-only signal; cheap confirmation pass |
| 1 diff triage | Ruby diff judgement for candidate set | **Haiku** | Candidates already filtered; diff is Ruby-only, bounded size |
| 4 non-Ruby confirm | JS/Vue/HAML/Go diff — is this actually an XSS fix? | **Sonnet** | Needs real reasoning: v-html semantics, DOMPurify bypass patterns, GraphQL authz |
| 6 CVSS scoring | Structured scoring from vuln record | **Sonnet** | Rubric is detailed; scoring errors compound downstream |
| 3 fetch diffs | `git show`, network I/O | **No model** | Pure shell/Python I/O — `fetch_diffs.py` |
| 3 SHA repair | Re-anchor commits to canonical SHAs | **No model** | `fix_shas.py` — deterministic git lookup |
| 4 prep non-Ruby | Filter + diff-inject into input JSON | **No model** | `prep_nonruby.py` — file I/O + JSON assembly |
| 5 build parquet | Merge JSONL → Parquet | **No model** | `build_parquet.py` — pandas I/O |
| 6 aggregate CVSS | Average scores, emit stats | **No model** | `cvss_aggregate.py` — arithmetic |
| 7 SZZ | Blame walk, inducing-commit lookup | **No model** | `szz.py`, `szz_parquet.py` — git graph traversal |

**Rule:** pure I/O and deterministic math need no model — don't pay for a subagent to run `git`.

---

## Idempotency + Resume

Every component in the pipeline is safe to re-run:

- **Subagents** — on startup, read the output file, collect existing `sha` values, skip them (`count as skipped_existing`). Partial batches resume from the last written line.
- **Python aggregators** (`cvss_aggregate.py`, `build_parquet.py`) — overwrite their output from the latest on-disk JSONL state. Re-running after adding new JSONL files is always safe.
- **Prep/slice scripts** (`prep_nonruby.py`, etc.) — overwrite their slice files. Re-slicing with updated inputs is safe.

Therefore:
- Safe to re-run any single phase without touching other phases.
- Safe to run `cvss_aggregate.py` mid-run to checkpoint partial CVSS results.
- Safe to resume a crashed wave: find the highest completed batch index, dispatch the next N batches.
- Safe to add more subagent batch files and re-aggregate — the aggregator merges all `*.jsonl` it finds.

---

## JSONL-Append Discipline

All subagents write output as JSON Lines (one object per commit, appended as processing proceeds):

1. **Append after each item** — not at the end. If the subagent times out or crashes, all lines written so far survive.
2. **`json.dumps` always** — never construct JSON by string concatenation. Raw newlines inside values corrupt the JSONL stream.
3. **Small context per subagent** — each agent reads only its assigned slice. For JSONL manifests: `sed -n '${start+1},${end}p' manifest.jsonl`. For JSON arrays: `python3 -c "import json,sys; json.dump(json.load(open('input.json'))[${start}:${end}], sys.stdout)"`. Neither loads the full corpus into the subagent's context.
4. **Resume check** — at the top of each agent, before processing: read the output file if it exists, extract written SHAs into a set, skip any input item whose SHA is already present.

---

## Batch Sizing

Sized to the model's context and per-row payload (diff rows are much larger than title rows):

| Pass | Batch size | Payload per row | Sizing rationale |
|------|-----------|-----------------|------------------|
| Phase 1 message | 80 | Title + body (~100–400 tokens) | Text-only; Haiku context headroom is large; bigger batches reduce total agent count |
| Phase 1 diff | 25 | Ruby diff (up to ~500 lines) | Diff payload dominates; 25 × ~300 token avg diff ≈ 7,500 tokens of data |
| Phase 2 re-gate | 60 | Title + body (noise subset) | Smaller payload than diff; higher batch safe |
| Phase 4 non-Ruby | 18 | Multi-language diff, pre-capped | Diffs can be larger and multi-file; tighter batch keeps Sonnet focused |
| Phase 6 CVSS | 30 | Structured vuln record (~200 tokens) | Moderate payload; Sonnet; 30 keeps per-batch error surface small |

Bigger is not better: tighter batches survive context limits and give finer resume granularity. A batch of 18 that crashes loses 18 items; a batch of 200 loses 200.

---

## Run Order

```
Phase 1a  [.wf.js]  gitlab_haiku_analysis  mode=message   — triage 189k commit messages
              ↓  (build candidate set from is_security_fix=true rows)
Phase 1b  [.wf.js]  gitlab_haiku_analysis  mode=diff      — diff triage on candidate set only
              ↓
Phase 2   [.wf.js]  haiku_regate                           — strip noise from suspect rows
              ↓
Phase 3   [py]      fetch_diffs.py + fix_shas.py           — fetch diffs, re-anchor SHAs
              ↓
Phase 4   [py+wf]   prep_nonruby.py → nonruby_analyze.wf.js — non-Ruby diff confirm (Sonnet)
              ↓
Phase 5   [py]      build_parquet.py                       — merge JSONL → Parquet dataset
             / \
Phase 6   [waves]   CVSS scoring (Sonnet, ~16/wave)        ← can run in parallel after Phase 3
Phase 7   [py]      szz.py + szz_parquet.py                ← can run in parallel after Phase 3
```

Phases 6 and 7 only need the diff/commit metadata produced by Phase 3; they are independent of each other and can run concurrently once diffs exist on disk.
