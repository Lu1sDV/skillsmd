---
name: ml-eval-safety
description: >
  Use when benchmarking LLMs or code models, or adding runtime guardrails and
  safety alignment. Covers lm-evaluation-harness (lm_eval, MMLU, GSM8K,
  HellaSwag, vLLM/HF/API backends), BigCode Evaluation Harness (HumanEval,
  MBPP, MultiPL-E, pass@k), NeMo Evaluator SDK (Docker/Slurm/VLM/safety
  harnesses), Prompt Guard (jailbreak and RAG injection detection), LlamaGuard
  (S1-S6 input/output moderation), NeMo Guardrails (Colang flows, PII masking),
  and Constitutional AI (self-critique SFT and RLAIF).
---

# ML Evaluation & Safety

Two focused references. Open only the reference the task needs; do not preload both.

| Task / Tool | Read |
|---|---|
| Benchmarking LLMs or code models: `lm_eval`, `bigcode-evaluation-harness` (`pass@k`), `nemo-evaluator-launcher`, vLLM/HF/API/Slurm evals | [Evaluation reference](references/evaluation.md) |
| Safety guardrails & alignment: Prompt Guard, LlamaGuard, NeMo Guardrails (Colang, Presidio PII), Constitutional AI (self-critique, RLAIF) | [Safety & guardrails reference](references/safety-guardrails.md) |

## What each covers

- **Evaluation** (`references/evaluation.md`) — Standard academic LLM benchmarking with `lm-evaluation-harness`, unit-tested code benchmarking (`pass@k`, MultiPL-E Docker sandboxing) with BigCode Evaluation Harness, and containerized multi-backend orchestration (Docker, Slurm, VLMs, safety) with NeMo Evaluator SDK.
- **Safety & Guardrails** (`references/safety-guardrails.md`) — Defense-in-depth runtime filtering with Prompt Guard (86M injection/jailbreak classifier), LlamaGuard (7B-8B S1-S6 content moderation), NeMo Guardrails (Colang flows, custom actions, PII masking), and offline Constitutional AI (self-critique + RLAIF).

## Universal rules

- **Pin evaluation parameters**: Always record `num_fewshot`, `temperature` (`0.0` for deterministic evals), `dtype`, `max_new_tokens`/`max_length_generation`, chat-template flags (`--apply_chat_template` / `--instruction_tokens`), and exact task names before comparing scores.
- **Sandbox code execution**: Never run untrusted model-generated code on a production host; use BigCode's `--generation_only` stage followed by Docker evaluation (`--allow_code_execution`).
- **Check VRAM & tokens before launching**: Verify GPU memory (e.g., 7B bf16 ~14-16 GB, 8-bit ~7-8 GB) and export required auth env vars (`HF_TOKEN`, `NGC_API_KEY`) rather than passing secrets on the CLI.
- **Chunk long inputs for 512-token classifiers**: Prompt Guard truncates at 512 tokens; use overlapping sliding windows on long RAG documents so trailing injections are not missed.
- **Verify outputs directly**: Inspect generated result files (`results.json`, `results.yml`) and guardrail action outputs rather than assuming a run succeeded.
- **Use forward slashes** in all file paths and never use backslash paths.
