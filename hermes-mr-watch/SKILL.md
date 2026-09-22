---
name: hermes-mr-watch
description: >
  Use when adding GitLab MRs to the Hermes watcher on ssh-vhs, editing or
  redeploying watch_gitlab_mr_findings.py, diagnosing missed/duplicate MR
  status messages in Telegram, or verifying the Hermes no-agent cron.
---

# Hermes MR Watch

## Quick Reference

| Thing | Value |
|---|---|
| SSH host | `ssh-vhs` = `deploy@100.91.148.117` (Docker; no Podman) |
| Hermes CLI | `docker exec hermes-agent /opt/hermes/.venv/bin/hermes` |
| Cron job ID | `80ec6fe4bf4f` — every 30m, no-agent |
| Script (remote) | `/home/deploy/.hermes/scripts/watch_gitlab_mr_findings.py` — SHA-256 `b89101589751f24767990868070b910c2c57b05336f98973730a30ef5efb0716` |
| Deployed source/snapshot | [scripts/watch_gitlab_mr_findings.py](scripts/watch_gitlab_mr_findings.py) and [scripts/watch_gitlab_mr_findings.remote.py](scripts/watch_gitlab_mr_findings.remote.py) — identical reviewed bytes |
| Corpus | 69 IIDs: 14 `LIVE-CONFIRMED`, 55 `SECURITY-FINDINGS`; CVSS co-located in `MR_CONFIG` |
| Legacy pair-watcher | `watch_gitlab_mrs.py` + job `d2cd1c6a687f` retired; rollback only |
| State/lock | `/opt/data/.gitlab-mr-findings-watch-v1.{json,lock}` (0600) |
| Delivery | `telegram:-1003963190927:2` (`github mr` topic) |

Current remote output is the phone-compact combined Security + CVSS +
Readiness + Timeline format. Merged MRs sort first and always show GitLab's
exact `merged_at` and the 12-character merge SHA:

```text
1. 🚨 !249009 MERGED — WHEN 2026-08-21T21:53:29.839Z — SHA d4bd29af8a75
```

The compact form is deliberate: the full-card corpus was 35,722 bytes and
timed out during Telegram delivery; the deployed 9,534-byte form delivers
successfully through Hermes chunking.

## Add one IID

Add one entry to `MR_CONFIG`; `IIDS` is derived and must not be edited:

```python
"250584": {"analysis": "LIVE-CONFIRMED", "cvss": (7.1,)},
```

- `analysis`: use `LIVE-CONFIRMED` only with frozen confirmation evidence;
  otherwise use `SECURITY-FINDINGS`.
- `cvss`: every frozen CVSS v3.1 base score for that MR: `(7.1,)` for one,
  `(6.8, 4.7)` for multiple, or `()` when not scored. Never use `0`, infer a
  score from severity, or publish a partial list as the MR maximum.
- The message prints the maximum score/rating and, for multiple findings, every
  score. Update any count-bearing cron metadata, then verify the IID and CVSS in
  the deployed bytes and a built-in run.

## Workflow

1. **Audit before touching anything:** `hermes cron list --all`, raw
   `~/.hermes/cron/jobs.json`, script SHA-256 vs this package, recent runs. One job only.
2. **Change IIDs** only through `MR_CONFIG` as specified above, then:
   - local gates: `python -m py_compile scripts/watch_gitlab_mr_findings.py && python scripts/watch_gitlab_mr_findings.py --self-test`
   - backup remote script + `jobs.json` to a private dir under `~/.hermes/backups/`
   - scp to `/home/deploy/.hermes/scripts/watch_gitlab_mr_findings.py`, chmod 700
   - verify remote `sha256sum` equals local hash
3. **Verify live:** run `docker exec -u 1000:1000 hermes-agent
   /opt/hermes/.venv/bin/hermes cron run 80ec6fe4bf4f`, then wait for a built-in
   scheduler tick and re-check `cron list` shows the same single job.
4. **Delivery proof** is a Hermes send acknowledgement (JSON with
   `success:true` + `message_id`). Watcher stdout alone proves nothing about
   Telegram. Never resend an old proof.

## Rules

- Update the existing job in place; never create a second watcher.
- Script path in cron must be relative to `~/.hermes/scripts/`
  (`watch_gitlab_mr_findings.py`) — absolute paths fail.
- Run every mutating Hermes CLI command (`cron edit`, `cron run`) as
  `docker exec -u 1000:1000`. Running it as root rewrites 0600 `jobs.json`
  and watcher state as `root:root`, stopping the UID-1000 scheduler with
  `PermissionError`.
- Per-MR fetch failure → `check failed` line for that MR, siblings still
  reported, **exit 0**. Nonzero exit = Hermes replaces output with a watchdog
  alert (this bit us once).
- Persist state before stdout; malformed state fails closed preserving bytes;
  lock contention exits silently.
- No credentials or Telegram API calls inside the script — Hermes delivers
  stdout.
- Hermes auto-chunks stdout over ~4000 chars into multiple Telegram messages
  ("preserved for chunking adapter" in gateway.log). Longer templates mean more
  fragments per tick — see `references/message-templates.md`.

## Verification

```bash
# local
python scripts/watch_gitlab_mr_findings.py --self-test

# remote
ssh ssh-vhs 'sha256sum ~/.hermes/scripts/watch_gitlab_mr_findings.py'  # == package hash
docker exec -u 1000:1000 hermes-agent /opt/hermes/.venv/bin/hermes cron list --all
docker exec -u 1000:1000 hermes-agent /opt/hermes/.venv/bin/hermes cron runs 80ec6fe4bf4f --limit 5
```

Pass = self-test green, hashes match, exactly one enabled job, latest built-in
run completed with the numbered heartbeat lines.
