# Ofelia Job Parameters Reference

Complete parameter tables for all four job types. Parameters marked with **\*** are required.

> Configuration keys are **not case-sensitive**.

## Shared Parameters (All Job Types)

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `schedule` **\*** | String | Cron expression — `@every 10s`, `@hourly`, `0 1 * * *` | required |
| `command` | String | Command to execute | required (except job-run situation 2) |
| `no-overlap` | Boolean | Skip execution if previous run still active | `false` |
| `slack-webhook` | String | Slack incoming webhook URL | — |
| `slack-only-on-error` | Boolean | Only notify Slack on failure | `false` |
| `smtp-host` | String | SMTP server hostname | — |
| `smtp-port` | Integer | SMTP server port | — |
| `smtp-user` | String | SMTP username | — |
| `smtp-password` | String | SMTP password | — |
| `smtp-tls-skip-verify` | Boolean | Skip TLS certificate validation | `false` |
| `email-to` | String | Recipient address(es), comma-separated | — |
| `email-from` | String | Sender address (`%s` = hostname) | — |
| `mail-only-on-error` | Boolean | Only email on failure | `false` |
| `save-folder` | String | Directory for execution reports | — |
| `save-only-on-error` | Boolean | Only save reports on failure | `false` |

## job-exec Parameters

Runs inside an **existing running container** (like `docker exec`).

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `schedule` **\*** | String | Cron expression | required |
| `command` **\*** | String | Command to run inside container | required |
| `container` **\*** | String | Target container name | required |
| `user` | String | User to run as (`docker exec --user`) | `root` |
| `tty` | Boolean | Allocate pseudo-TTY (`docker exec -t`) | `false` |
| `environment` | String/Array | Environment variables (`FOO=bar`). INI: repeat key. Labels: JSON array `["FOO=bar","BAZ=qux"]`. **Requires Docker API >= 1.25** | — |

### Label placement

Labels go on the **target container**, not on Ofelia. The target container must also have `ofelia.enabled=true`.

## job-run Parameters

Creates a **new ephemeral container** (like `docker run --rm`), OR starts a stopped container.

**Situation 1** — new container from image: set `image` (and optionally `command`)
**Situation 2** — start stopped container: set `container` (no `image`)

| Parameter | Sits. | Type | Description | Default |
|-----------|-------|------|-------------|---------|
| `schedule` **\*** | 1,2 | String | Cron expression | required |
| `command` | 1 | String | Command to run | container default |
| `image` | 1 | String | Docker image (`nginx:latest`) | — |
| `container` | 2 | String | Existing stopped container name | — |
| `user` | 1 | String | User to run as | `root` |
| `tty` | 1,2 | Boolean | Allocate pseudo-TTY | `false` |
| `delete` | 1 | String | Remove container after completion (`docker run --rm`) | `"true"` |
| `pull` | 1 | String | Pull image before running | `"true"` |
| `network` | 1 | String | Connect container to this network | — |
| `hostname` | 1 | String | Set container hostname | — |
| `volume` | 1 | String/Array | Bind mounts (`/host:/container:ro`). INI: repeat key. Labels: JSON array | — |
| `volumes-from` | 1 | String/Array | Use volumes from another container. INI: repeat key. Labels: JSON array | — |
| `environment` | 1 | String/Array | Environment variables. INI: repeat key. Labels: JSON array | — |

### Label placement

Labels go on the **Ofelia container** (it creates the new containers).

### Notes

- `delete` and `pull` are strings (`"true"`/`"false"`), not booleans, due to a Go defaults library limitation
- When `pull = true` (default): pulls first, falls back to local. When `pull = false`: checks local first, pulls if not found
- Max job runtime: 24 hours (hardcoded)

## job-local Parameters

Runs on the **host running Ofelia**. When containerized, runs inside the Ofelia container.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `schedule` **\*** | String | Cron expression | required |
| `command` **\*** | String | Command to run | required |
| `dir` | String | Working directory for command | current directory |
| `environment` | String/Array | Environment variables (appended to existing env). INI: repeat key. Labels: JSON array | — |

### Label placement

Labels go on the **Ofelia container**.

### Notes

- Environment variables are **appended** to the existing process environment, not replacing it
- The command binary must be in `$PATH` (uses `exec.LookPath`)

## job-service-run Parameters

Creates a **one-shot Swarm service** (Docker Swarm mode required).

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `schedule` **\*** | String | Cron expression | required |
| `image` **\*** | String | Docker image for the service | required |
| `command` | String | Command to run | container default |
| `user` | String | User to run as | `root` |
| `tty` | Boolean | Allocate pseudo-TTY | `false` |
| `network` | String | Swarm network to attach | — |
| `delete` | String | Remove service after completion | `"true"` |

### Label placement

Labels go on the **Ofelia container**.

### Notes

- Service created with `RestartPolicy: none` and `MaxAttempts: 1` (true one-shot)
- Image is always pulled before creating the service
- If task state is `rejected`, exit code is forced to 255 even if container reported 0

## Global Section (INI) / Ofelia Container Labels

Global middleware settings apply to **all jobs** as defaults. Per-job settings override global.

### INI format

```ini
[global]
slack-webhook = https://hooks.slack.com/services/XXX
slack-only-on-error = true
save-folder = /var/log/ofelia
save-only-on-error = false
smtp-host = smtp.example.com
smtp-port = 587
smtp-user = alerts@example.com
smtp-password = secret
email-to = ops@example.com
email-from = ofelia@example.com
mail-only-on-error = true
```

### Label format (on Ofelia container)

```yaml
labels:
  ofelia.global.slack-webhook: "https://hooks.slack.com/services/XXX"
  ofelia.global.slack-only-on-error: "true"
  ofelia.global.save-folder: "/var/log/ofelia"
```
