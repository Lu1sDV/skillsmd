# hf CLI reference

Condensed from the upstream [`hf-cli` skill](https://github.com/huggingface/skills/blob/main/skills/hf-cli/SKILL.md)
(huggingface/skills, Apache-2.0), generated there with `huggingface_hub v2.4.0`.
Only common flags are listed; `hf <command> --help` has the full options and
real-world examples. Regenerate upstream with `hf skills add --force`.

Install: `curl -LsSf https://hf.co/cli/install.sh | bash -s` · Update: `hf update`

`hf` replaces the deprecated `huggingface-cli`. All auth commands are under `hf auth`.

## Core commands

| Command | Purpose |
|---|---|
| `hf download REPO_ID` | Download repo files. `--type model\|dataset\|space\|kernel --revision --include --exclude --local-dir --cache-dir --force-download --dry-run --max-workers` |
| `hf upload REPO_ID` | Upload a file or folder. `--type --revision --private --include --exclude --delete --commit-message --commit-description --create-pr --every FLOAT` (periodic re-upload) |
| `hf cp SRC DST` | Copy between local paths, repos, and buckets |
| `hf sync` | Sync a local directory with a bucket. `--delete --dry-run --include --exclude --existing --ignore-existing` |
| `hf env` / `hf version` | Environment / version info |

## auth

`hf auth login` (browser or token from huggingface.co/settings/tokens; `--add-to-git-credential`),
`logout`, `whoami`, `switch`, `list`, `token` (prints the current token to stdout).

## buckets

| Command | Purpose |
|---|---|
| `hf buckets create BUCKET_ID` | `--private --region us\|eu --exist-ok` |
| `hf buckets list` | List buckets or files. `--tree --recursive --search --human-readable` |
| `hf buckets info / settings / move / delete` | Inspect, visibility (`--private/--public`), rename, delete (`--yes`) |
| `hf buckets cp / sync / remove` | Transfer and delete files. `remove --recursive --dry-run --include --exclude` |

## cache

| Command | Purpose |
|---|---|
| `hf cache list` | Cached repos/revisions. `--revisions --filter --sort size\|accessed\|modified\|name --limit` |
| `hf cache prune` | Remove detached revisions and incomplete downloads. `--dry-run --yes` |
| `hf cache rm TARGETS` | Remove cached repos/revisions/files. `--dry-run --yes` |
| `hf cache verify REPO_ID` | Checksum verification. `--type --revision --local-dir --fail-on-missing-files --fail-on-extra-files` |

## collections

`create TITLE` (`--namespace --private --exists-ok`), `list` (`--owner --item --sort lastModified|trending|upvotes`),
`info`, `update` (`--title --description --private --theme`), `delete`,
`add-item SLUG ITEM_ID ITEM_TYPE` (`--note --exists-ok`), `update-item`, `delete-item`.

## datasets

| Command | Purpose |
|---|---|
| `hf datasets list` | Search datasets or list repo files. `--search --author --filter --sort downloads\|likes\|trending_score\|... --tree --recursive` |
| `hf datasets info / card DATASET_ID` | Metadata / README. `card --metadata --text` |
| `hf datasets parquet DATASET_ID` | Parquet file URLs. `--subset --split` |
| `hf datasets sql SQL` | DuckDB SQL over dataset parquet URLs |
| `hf datasets leaderboard DATASET_ID` | Model benchmark scores. Find leaderboards: `hf datasets list --filter benchmark:official` |

## discussions (discussions + pull requests)

`list REPO_ID` (`--status open|closed|merged|draft|all --kind discussion|pull_request`),
`info`, `create --title` (`--pull-request --body --body-file --attach`),
`comment` / `edit` (`--body --body-file --attach`), `diff`, `merge`, `close`, `reopen`, `rename`.
All take `--type model|dataset|space|kernel`; destructive ones take `--yes`.

## endpoints (Inference Endpoints)

| Command | Purpose |
|---|---|
| `hf endpoints catalog list / deploy` | Deploy from the Model Catalog. `--repo --recipe --accelerator cpu\|gpu\|neuron --gguf-file` |
| `hf endpoints deploy NAME --repo ...` | Deploy from a Hub repo. Key: `--accelerator --instance-size --instance-type --region --engine vllm\|sglang\|tei\|tgi\|llamacpp\|custom --min-replica --max-replica --scale-to-zero-timeout --type public\|authenticated\|private --env --secrets` |
| `hf endpoints list / describe / update / delete` | Manage endpoints. `--namespace` |
| `hf endpoints pause / resume / scale-to-zero` | Lifecycle |
| `hf endpoints hardware` | Available hardware. `--vendor --region --accelerator --all` |

## extensions

`search` (GitHub topic `hf-extension`), `install REPO_ID`, `list`, `exec NAME`, `update`, `remove`.

## jobs

| Command | Purpose |
|---|---|
| `hf jobs run IMAGE COMMAND` | Run a Job. `--flavor` (cpu-basic…a100x8, h200x8, rtx-pro-6000x8), `--env --secrets --env-file --secrets-file --volume --timeout --attempts --detach --dry-run --expose --ssh` |
| `hf jobs uv run SCRIPT` | Run a UV script (local file or URL) on HF infra. Same plus `--with --python --image` |
| `hf jobs list / inspect / logs / stats` | `logs --follow --tail`, `stats --follow`, `list --status --label --name` |
| `hf jobs wait JOB_IDS` | Block until terminal state. `--timeout` |
| `hf jobs cancel / rerun / labels / expose / ssh / hardware` | Manage running Jobs |
| `hf jobs scheduled run SCHEDULE IMAGE COMMAND` | Cron-style scheduling. Also `scheduled uv run`, `list`, `inspect`, `reschedule`, `suspend`, `resume`, `trigger`, `delete`, `labels` |

## models

`hf models list` (`--search --author --filter --pipeline-tag --num-parameters --inference-provider --warm --sort downloads|likes|trending_score|... --tree --recursive`),
`hf models info MODEL_ID` (`--expand`; includes `safetensors` parameter counts),
`hf models card MODEL_ID` (`--metadata --text`).

## papers

`hf papers list` (`--date --week --month --submitter --sort publishedAt|trending`),
`search QUERY`, `info PAPER_ID`, `read PAPER_ID` (paper as markdown).

## repos

| Command | Purpose |
|---|---|
| `hf repos create REPO_ID` | `--type --sdk --template --private --exist-ok`; Space options: `--flavor --sleep-time --secrets --env --volume` |
| `hf repos list` | All repos with storage info. `--namespace --type --search --explore` |
| `hf repos delete REPO_ID` | Irreversible. `--yes --missing-ok` |
| `hf repos duplicate / move / settings` | Copy, rename namespace, visibility/gating (`--gated auto\|manual\|false --private --public`) |
| `hf repos delete-files REPO_ID PATTERNS` | `--commit-message --create-pr` |
| `hf repos branch create / delete`, `tag create / list / delete` | Git-style refs |

## sandbox (experimental, on HF Jobs)

`create` (`--pool` for cheap shared VMs, `--flavor --idle-timeout --env --secrets --volume --forward-hf-token`),
`exec SANDBOX_ID COMMAND` (streams output, propagates exit code),
`spawn` (background process, returns pid), `process ls / kill`,
`cp SRC DST` (docker-style local↔sandbox), `kill` (`--all`),
`pool create / ls / delete` (warm host pools).

## skills

`hf skills add` (`--global --dest --force`), `list`, `preview`, `update` — manage HF's own agent skills.

## spaces

| Command | Purpose |
|---|---|
| `hf spaces list / info / card / search` | Browse; `search` is semantic. `--sdk --filter --include-non-running` |
| `hf spaces logs SPACE_ID` | `--build --follow --tail` |
| `hf spaces restart / pause / wait` | `restart --factory-reboot`, `wait --timeout` |
| `hf spaces dev-mode / ssh / hot-reload` | Dev-mode container access; hot-reload a Python file without rebuild (`--local-file`) |
| `hf spaces settings SPACE_ID` | `--hardware cpu-basic\|zero-a10g\|t4-small\|... --sleep-time` |
| `hf spaces secrets / variables add\|list\|delete` | Secret values are write-only |
| `hf spaces volumes list / set / delete` | Persistent storage |
| `hf spaces hardware / templates / zero-gpu quota` | Options and quota |

## webhooks

`create --watch TEXT` (`--url --job-id --domain repo|discussion --secret`),
`list`, `info`, `update`, `enable`, `disable`, `delete`.

## Common options

- `--format json` (or `--json`) for scripting; also `agent`, `quiet` (one ID per line), default human/table.
- `--revision` — branch, tag, or commit hash.
- `--type` — `model`, `dataset`, `space`, or `kernel`.
- `--token` — prefer the `HF_TOKEN` env var instead.
- `--namespace` — org/user scope on jobs, endpoints, sandboxes.
- `--dry-run` / `--yes` — preview / skip confirmation on destructive commands.

## Mounting repos as filesystems

`hf-mount` mounts repos/buckets locally with on-demand fetch (no download).
Install: `brew install hf-mount` or binaries from https://github.com/huggingface/hf-mount/releases

```bash
hf-mount start repo openai-community/gpt2 /tmp/gpt2          # read-only repo
hf-mount start --hf-token $HF_TOKEN bucket myuser/my-bucket /tmp/data  # read-write bucket
hf-mount status && hf-mount stop /tmp/data
```
