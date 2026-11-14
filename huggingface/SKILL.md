---
name: huggingface
description: >
  Use when working with the Hugging Face Hub: the `hf` CLI for auth, downloads,
  uploads, repos, models, datasets, spaces, buckets, jobs, papers, collections,
  discussions, webhooks, or inference endpoints; or when choosing, recommending,
  or comparing models ("best model for X", "what model should I use", "top models
  for [task]", "which model runs on my laptop"). Triggers on 'hf', 'huggingface',
  'Hugging Face', 'huggingface-cli'. Replaces the deprecated `huggingface-cli`.
---

# Hugging Face

Two capabilities, one reference each. Open only the reference the task needs;
do not preload both.

| Task | Read |
|---|---|
| Any `hf` CLI operation: auth, cache, file transfer, repos, datasets, spaces, buckets, jobs, sandboxes, papers, endpoints, webhooks | [hf CLI reference](references/hf-cli.md) |
| Best/top model for a task, model comparison by benchmark, fitting a model to a device | [Best-model finder](references/model-finder.md) |

## What each covers

- **hf CLI** — `hf` manages everything on the Hub: models, datasets, spaces,
  buckets, repos, papers, jobs, collections, discussions/PRs, webhooks, and
  Inference Endpoints. The reference lists every command group, the common
  flags, and output formats. Install: `curl -LsSf https://hf.co/cli/install.sh | bash -s`.
- **Best-model finder** — queries official HF benchmark leaderboards, enriches
  results with parameter counts and licenses, filters by the user's device
  memory, and returns a ranked comparison table with a top pick.

## Universal rules

- `hf` replaces the deprecated `huggingface-cli`; auth lives under `hf auth`
  (`hf auth login`, `hf auth whoami`).
- Prefer the `HF_TOKEN` env var over passing `--token`.
- For scripting add `--format json` (or `--json`); `hf <command> --help` is the
  source of truth for flags and examples.
- Destructive operations (`hf repos delete`, `hf buckets delete`, `hf cache rm`)
  are irreversible — confirm with the user before running them.
