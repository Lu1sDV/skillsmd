# hermes-mr-watch

Safely adds GitLab merge requests to the Hermes lifecycle watcher on `ssh-vhs`.
Packages the exact no-agent script deployed on the remote host, keeps one
existing cron job, and verifies scheduling and Telegram delivery over SSH.

## Installation

### Claude Code Plugin

```text
/plugin install hermes-mr-watch@Lu1sDV/skillsmd
```

Or add the marketplace first:

```text
/plugin marketplace add Lu1sDV/skillsmd
```

### Manual

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/hermes-mr-watch ~/.claude/skills/
```

### npx

```bash
npx skills add Lu1sDV/skillsmd
```

## Usage

```text
Use hermes-mr-watch to add these confirmed GitLab MRs to the remote Hermes
watcher and verify the built-in scheduler and Telegram delivery.
```

```text
Use hermes-mr-watch to diagnose why the Hermes MR watcher missed a check or
created duplicate notifications.
```

## Included Files

| File | Purpose |
|---|---|
| `SKILL.md` | Quick-reference values, deployment workflow, verification gates |
| `scripts/watch_gitlab_mr_findings.remote.py` | Exact deployed `ssh-vhs` bytes; SHA-256 `b89101589751f24767990868070b910c2c57b05336f98973730a30ef5efb0716` |
| `scripts/watch_gitlab_mr_findings.py` | Deployed 69-IID combined CVSS watcher; phone-compact, merged-first, exact merge timestamp + SHA |
| `scripts/watch_gitlab_mrs.py` | Retired 2-MR legacy watcher, kept for rollback |
| `references/message-templates.md` | Alternative Telegram formats + chunking limits |
| `agents/openai.yaml` | Codex skill interface metadata |

## Verification

```bash
python hermes-mr-watch/scripts/watch_gitlab_mr_findings.py --self-test
python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py \
  hermes-mr-watch
```
