# Best-model finder

Condensed from the upstream [`huggingface-best` skill](https://github.com/huggingface/skills/blob/main/skills/huggingface-best/SKILL.md)
(huggingface/skills, Apache-2.0). Finds the best models for a task via official
HF benchmark leaderboards, enriched with size/license data and filtered for the
user's device.

## Step 1: Parse the request

Extract:
- **Task**: coding, math/reasoning, chat, OCR, RAG/retrieval, speech recognition,
  image classification, multimodal, agents, etc.
- **Device**: hardware constraints (Apple Silicon unified memory, GPU VRAM,
  CPU-only, cloud/no constraint).

No device mentioned → skip all size filtering, rank purely by score.
Genuinely ambiguous task → ask one clarifying question.

### Device → max parameter budget

Use available memory (unified RAM for Apple Silicon, VRAM for discrete GPUs):

- **fp16 max params (B)** ≈ memory (GB) ÷ 2
- **Q4 max params (B)** ≈ memory (GB) × 2

Examples: 16GB → 8B fp16 / 32B Q4 · 24GB VRAM → 12B fp16 / 48B Q4 · 8GB → 4B fp16 / 16B Q4.

## Step 2: Find relevant benchmark datasets

```bash
curl -s -H "Authorization: Bearer $(cat ~/.cache/huggingface/token)" \
  "https://huggingface.co/api/datasets?filter=benchmark:official&limit=500" \
  | jq '[.[] | {id, tags, description}]'
```

(With `HF_TOKEN` set, use `-H "Authorization: Bearer $HF_TOKEN"` instead.)

Select datasets matching the task by id, tags, and description. Aim for
comprehensive coverage — if 5 benchmarks clearly cover the task, use all 5.
CLI equivalent: `hf datasets list --filter benchmark:official`.

## Step 3: Fetch top models from leaderboards

For each selected benchmark:

```bash
curl -s -H "Authorization: Bearer $(cat ~/.cache/huggingface/token)" \
  "https://huggingface.co/api/datasets/<namespace>/<repo>/leaderboard" \
  | jq '[.[:15] | .[] | {rank, modelId, value, verified}]'
```

Collect model IDs and scores across benchmarks. On error (404, 401, …) skip
that leaderboard and note it in the output.
CLI equivalent: `hf datasets leaderboard <namespace>/<repo> --limit 15 --json`.

## Step 4: Enrich with model metadata

For the top 10–15 candidates:

```bash
hf models info org/model --json | jq '{safetensors, tags, cardData}'
# or: curl -s -H "Authorization: Bearer $HF_TOKEN" https://huggingface.co/api/models/org/model
```

Extract:
- **Parameters**: `safetensors.total` → B (7_241_748_480 → "7.2B").
- **License**: card tags (`license:apache-2.0`, `license:mit`, …).
- No `safetensors` field → parse size from the model name ("7b", "8b", "70b", …).

## Step 5: Filter and rank

With a device:
1. Drop models far over the fp16 budget.
2. Keep models that fit only at Q4 (capacity ≈ 4× the fp16 budget) flagged "Q4 only".
3. A highly-ranked model slightly over budget stays, with a "needs Q4" note —
   never silently drop it.

Without a device: no size filtering.

Rank by benchmark score descending; keep the top 5–8. Include proprietary
models (GPT, Claude, Gemini) if they appear on leaderboards, flagged
"API only / not self-hostable"; exclude them only if the user asked for
local/open models.

## Step 6: Output

Comparison table:

```markdown
| # | Model | Params | [Benchmark 1] | [Benchmark 2] | License | On device |
|---|-------|--------|---------------|---------------|---------|-----------|
| ⭐1 | [org/name](https://huggingface.co/org/name) | 7B | 85.2% | — | Apache 2.0 | Yes (fp16) |
| 2 | [org/name](https://huggingface.co/org/name) | 13B | 83.1% | 71.5% | MIT | Q4 only |
| 3 | [org/name](https://huggingface.co/org/name) | 70B | 90.0% | 81.0% | Llama | Too large |
```

- Link model names to `https://huggingface.co/<model_id>`; `—` where not evaluated.
- Star the top pick with ⭐. "On device": `Yes (fp16)`, `Q4 only`, `Too large`, `API only`.

Follow-up: ask "Would you like to run **[top pick]**?" If yes:
- **Locally** — ask the device if unknown, give setup instructions.
- **On HF Jobs** — https://huggingface.co/docs/huggingface_hub/en/guides/jobs

## Error handling

- Leaderboard missing/unauthorized → skip, note "leaderboard unavailable".
- No `safetensors` metadata → parse size from the model name.
- No benchmarks match the task, or all leaderboards fail → fall back to
  popularity search and say so explicitly:
  `hf models list --filter <task> --sort trending_score --limit 15`
  (or `GET /api/models?filter=<task>&sort=trendingScore`). Results are by
  popularity, not benchmark score.
