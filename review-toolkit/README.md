> **Repository checkout:** The self-contained skills are at [`../review-code/`](../review-code/) and [`../review-pr/`](../review-pr/). Run tools here as `python3 review-toolkit/...` from the repository root. This suite uses [`IN_REPO.md`](IN_REPO.md) to direct canonical generation into those root directories. The standalone ZIP retains the `skillsmd/` layout documented below.

# Review tools v2 — `review-code` and `review-pr`

This is a complete, standalone **source package** for two evidence-first review skills and slash-command adapters for **Pi**, **Oh My Pi (OMP)**, **OpenAI Codex**, and **Claude Code**. Python **3.9+**, standard library only for the package tools. It does not need external services to install. It does not install or upgrade the harness programs themselves.

## What changed in v2

1. **Monotonic allocation:** domain reviewer count cannot decrease when file count or changed-line count increases. A change of at least **2,000 changed lines** gets at least two independent domain passes, even when it has only one or two files.
2. **Risk-aware review:** after inspecting concrete changed code/contracts, a verified high-risk change gets **one extra independent targeted risk reviewer** at NORMAL, DEEP and ULTRA. Multiple risk signals are consolidated; an unverified name/keyword never adds a reviewer automatically. DEEP/ULTRA each add a separate holistic reviewer.
3. **One canonical source:** `src/shared/*.md` is the only authoring source of common protocol, allocation, property checks, ULTRA ledger, priority and reporting rules. `src/review-code.md` and `src/review-pr.md` supply just the distinct framing. `tools/build_skills.py` compiles self-contained `skills/review-*/SKILL.md`. The installer compiles on every invocation, preventing stale generated copies from overriding source edits.
4. **Version-pinned harness checks:** `harnesses/versions.json` is the only version-pin source. `tools/check_harnesses.py` can verify local executable versions (strict/JSON modes) and generate a GitHub Actions CI matrix for exact published versions. The workflow also checks installed file layouts. Neither preflight nor CI pretends to prove live model calls or independent subagent launches.

## Quick start — source zip

Unzip `review-tools-v2.zip`, enter the extracted directory containing `skillsmd`, then:

```bash
python3 skillsmd/tools/build_skills.py --check
python3 skillsmd/tools/review_plan.py --files 3 --changed-lines 500 --depth DEEP --human
python3 skillsmd/tools/check_harnesses.py --target all
python3 skillsmd/install.py install --target all --with-reviewer --dry-run
python3 skillsmd/install.py install --target all --with-reviewer
```

For the standalone distributor, no extraction is necessary to install:

```bash
python3 review-tools-install.py extract skillsmd
python3 review-tools-install.py install --target all --with-reviewer --dry-run
python3 review-tools-install.py install --target all --with-reviewer
```

**The bare slash commands:** Pi `/review-code` and `/review-pr`; OMP `/review-code` and `/review-pr`; Claude Code `/review-code` and `/review-pr`. **Codex:** preferred native `$review-code` and `$review-pr` skill invocations. Codex's legacy prompts, when user-scoped, are `/prompts:review-code` and `/prompts:review-pr`. Codex legacy custom prompts are deprecated: prefer native skills.

Example arguments:

```text
/review-code NORMAL --staged
/review-code DEEP --base main --head HEAD
/review-pr ULTRA --base main --head HEAD
$review-pr DEEP --base main --head HEAD       # Codex native skill
/prompts:review-pr DEEP --base main --head HEAD # Codex legacy user prompt
```

Depth `NORMAL` is the default. All depths use exactly the same six-column P0–P3 findings table, the same eight-part evidence gate and strict trigger/impact comment instructions.

## Per-harness install and upgrade

Install:

```bash
python3 skillsmd/install.py install --target pi --with-reviewer
python3 skillsmd/install.py install --target omp
python3 skillsmd/install.py install --target codex --with-reviewer
python3 skillsmd/install.py install --target claude-code --with-reviewer
```

Upgrade after replacing the local `skillsmd` source with a newer package:

```bash
python3 skillsmd/install.py upgrade --target pi --with-reviewer
python3 skillsmd/install.py upgrade --target omp
python3 skillsmd/install.py upgrade --target codex --with-reviewer
python3 skillsmd/install.py upgrade --target claude-code --with-reviewer
```

You may use `python3 review-tools-install.py install|upgrade` with the same flags directly. These commands **do not fetch new releases**: run the installer *from the new package* to upgrade. `--target all` works for user or project scope. Run `--dry-run` first. An installation manifest tracks only owned resources; unrelated files are left alone. Conflicts with untracked or locally modified content block the operation before any target is touched. `--force` backs up conflicts before changing them; use it only after inspecting the dry run.

**Migrating from an earlier installer:** the prior package's exact manifest could not be recovered in this environment. If its installed files are not recognized as owned by v2, this installer treats them as user-owned and refuses to overwrite. Preview first, then use `--force` to back up and replace the desired v2 command/skill files. Never assume an invisible migration silently succeeded.

### Scope and paths

```bash
python3 skillsmd/install.py install --target claude-code --scope project --project-root /path/to/repo --with-reviewer
python3 skillsmd/install.py upgrade --target codex --scope project --project-root /path/to/repo --with-reviewer
```

| Target | User-scope resources | Project-scope resources | Entry points |
|---|---|---|---|
| Pi | `~/.pi/agent/{skills,prompts,agents}/` | `.pi/{skills,prompts,agents}/` | `/review-code`, `/review-pr` via prompt templates |
| OMP | `~/.omp/agent/{skills,commands}/` | `.omp/{skills,commands}/` | `/review-code`, `/review-pr` via command files |
| Codex | `~/.agents/skills/`, `~/.codex/{prompts,agents}/` | `.agents/skills/`, `.codex/agents/` | `$review-code`, `$review-pr` (user legacy `/prompts:...`) |
| Claude Code | `~/.claude/{skills,agents}/` | `.claude/{skills,agents}/` | `/review-code`, `/review-pr` native skills |

The package only provides Pi's **reviewer definition**. Pi's core deliberately omits the subagent execution tool, so install a compatible subagent extension or use an existing one before expecting parallel reviews. The official repository contains a subagent example. OMP **already bundles a reviewer agent**; this package intentionally does not replace it. Codex and Claude Code can use the optional `reviewer` definitions with their native agent tools. If a harness cannot actually dispatch independent workers, the skill requires accurate limitation reporting rather than simulated parallelism.

For active sessions, reload via Pi `/reload`, OMP `/reload-plugins` and restart/reload skill discovery as appropriate in Codex/Claude Code. Test the slash-command names in the harness itself; file installation alone does not prove interactive runtime behavior.

### Review quota example

```bash
python3 skillsmd/tools/review_plan.py --files 2 --changed-lines 2100 --depth ULTRA \
  --risk 'payments|billing/charges.py now stores rounded settlement values without fixed decimal' \
  --capacity 2
```

Expected: 2 domain + 1 independent risk + 1 independent holistic = **4 reviewers**, 2 concurrency waves. The planner accepts only a `category|specific evidence` risk signal, but cannot verify the evidence. The **reviewer** must establish it by reading the actual diff before including the risk. The domain quota remains monotonic in both count dimensions. Agent capacity changes waves, not requested quota.

## Version-pinned checks

The `harnesses/versions.json` snapshot is dated **2026-11-04** and pins **published baseline versions**, not necessarily the newest release. The pins are reference build targets, **not a claim that this environment ran those four CLIs**:

| Harness | Exact pin | Registry package |
|---|---|---|
| Pi | `0.85.1` | `@earendil-works/pi-coding-agent` |
| OMP | `18.15.0` | `@oh-my-pi/pi-coding-agent` |
| Codex | `0.166.0` | `@openai/codex` |
| Claude Code | `2.1.311` | `@anthropic-ai/claude-code` |

Check local installations:

```bash
python3 skillsmd/tools/check_harnesses.py --target all
python3 skillsmd/tools/check_harnesses.py --target codex --strict
python3 skillsmd/tools/check_harnesses.py --ci-matrix
python3 skillsmd/tools/check_harnesses.py --target all --json
```

A mismatch is informational without `--strict`; strict mode returns nonzero if missing, mismatched, or failed. To update pins, edit **only** `harnesses/versions.json`, run the test suite and CI. The workflow `skillsmd/.github/workflows/harness-pinned-smoke.yml` belongs at your **repository root** `.github/workflows/harness-pinned-smoke.yml` if your repository stores this package in a `skillsmd/` subdirectory. The workflow reads the versions matrix from JSON, installs exact versions into CI, checks `--version`, and validates installed paths. It does *not* authenticate, send code to a model, or assert end-to-end review quality.

## Editing the canonical policy

```bash
$EDITOR skillsmd/src/shared/03-gate-report.md
python3 skillsmd/tools/build_skills.py
python3 skillsmd/tools/build_skills.py --check
python3 -m unittest discover -s skillsmd/tests -v
python3 skillsmd/install.py upgrade --target all --with-reviewer --dry-run
```

Commit `src/` and the regenerated `skills/` outputs together. A CI check fails on drift. The installer itself recompiles from source every invocation, so even before regeneration, installations do not use stale content. To reassemble the self-extracting distributor and archive, run `python3 skillsmd/tools/make_distributor.py` from the archive root (the directory containing `skillsmd/`).

## Security and operational limits

- Reviewers must honor all applicable higher-priority and repository-specific instructions, load specialist skills first, read connected code, prove actual effects and avoid edits. Risk and edge-case hypotheses are **not** automatically reportable findings.
- The default reporting gate forbids flagging pre-existing and intentional behavior changes as newly introduced bugs. Current-state audits are a specifically labeled exception.
- Installer paths are fixed and manifest entries validated. Directory/symlink conflicts fail safely; `--force` creates on-disk backups of overwritten content. It does not clobber unrelated commands.
- The exact CLI pins are checked, and path layout is smoke tested. **Live subagent delegation, authenticated review execution, and actual slash-command discovery require your environment** and are not certified by the offline tests.
