---
name: ofelia
description: Use when scheduling tasks in Docker environments with Ofelia — configuring job-exec, job-run, job-local, job-service-run via INI files or Docker labels, cron scheduling, overlap prevention, logging to Slack/email/disk, Docker Compose integration, Swarm services, and troubleshooting scheduled container jobs
---

# Ofelia — Docker Job Scheduler

Modern, lightweight cron replacement for Docker. Executes commands inside containers via Docker API. Written in Go, configured via INI files or Docker container labels.

- Repo: https://github.com/mcuadros/ofelia
- Image: `mcuadros/ofelia:latest`
- License: MIT

## When to Use

- Scheduling recurring tasks inside Docker containers (backups, cleanup, reports)
- Replacing host-level cron with container-aware scheduling
- Configuring job-exec, job-run, job-local, or job-service-run via INI or Docker labels
- Setting up job logging, overlap prevention, or Slack/email notifications
- Running scheduled tasks in Docker Swarm services

## When NOT to Use

- Non-Docker environments — use standard cron or systemd timers instead
- Complex workflow orchestration (Airflow, Prefect) — Ofelia is single-job scheduling

## Quick Reference

| Concept | Summary |
|---------|---------|
| **job-exec** | Run command in existing container (`docker exec`) |
| **job-run** | Run command in new ephemeral container (`docker run`) |
| **job-local** | Run command on Ofelia host (or inside Ofelia container) |
| **job-service-run** | Run command as one-shot Swarm service |
| **Config methods** | INI file (`--config`) or Docker labels (`--docker`) |
| **Label format** | `ofelia.<JOB_TYPE>.<JOB_NAME>.<PARAM>=<VALUE>` |
| **Schedule syntax** | Go cron — `@every 10s`, `@hourly`, `0 1 * * *` (seconds optional) |
| **Overlap prevention** | `no-overlap = true` per job |

## Configuration Methods

### INI File

```ini
[global]
slack-webhook = https://hooks.slack.com/services/XXX
slack-only-on-error = true

[job-exec "flush-logs"]
schedule = @hourly
container = nginx-proxy
command = /bin/bash /flush-logs.sh
user = www-data
no-overlap = true
```

Launch: `ofelia daemon --config=/etc/ofelia.conf`

### Docker Labels

Labels go on the **target container** for `job-exec` (requires `ofelia.enabled=true`), or on the **Ofelia container** for `job-run`, `job-local`, `job-service-run`.

```yaml
labels:
  ofelia.enabled: "true"
  ofelia.job-exec.flush-logs.schedule: "@hourly"
  ofelia.job-exec.flush-logs.command: "/bin/bash /flush-logs.sh"
  ofelia.job-exec.flush-logs.user: "www-data"
  ofelia.job-exec.flush-logs.no-overlap: "true"
```

**Both methods can be combined** — INI for globals/local jobs, labels for exec jobs.

### Docker Compose — Typical Setup

```yaml
services:
  ofelia:
    image: mcuadros/ofelia:latest
    command: daemon --docker
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    depends_on:
      - app
    labels:
      # job-run and job-local labels go HERE (on ofelia)
      ofelia.job-run.backup.schedule: "0 2 * * *"
      ofelia.job-run.backup.image: "alpine:latest"
      ofelia.job-run.backup.command: "sh -c 'tar czf /backup/data.tar.gz /data'"
      ofelia.job-run.backup.volume: "/backup:/backup:rw"

  app:
    image: myapp:latest
    labels:
      # job-exec labels go HERE (on target container)
      ofelia.enabled: "true"
      ofelia.job-exec.migrate.schedule: "@daily"
      ofelia.job-exec.migrate.command: "python manage.py migrate --noinput"
```

### Docker Compose with INI File

```yaml
services:
  ofelia:
    image: mcuadros/ofelia:latest
    command: daemon --config=/etc/ofelia.conf --docker
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./ofelia.conf:/etc/ofelia.conf:ro
```

### Container Filtering

Limit label discovery to specific containers:

```yaml
command: daemon --docker -f label=com.docker.compose.project=${COMPOSE_PROJECT_NAME}
```

## Schedule Syntax

Uses Go's [robfig/cron](https://pkg.go.dev/github.com/robfig/cron/v3). Seconds field is **optional** (supported for backward compatibility).

| Expression | Meaning |
|-----------|---------|
| `@every 30s` | Every 30 seconds |
| `@every 5m` | Every 5 minutes |
| `@hourly` | Top of every hour |
| `@daily` / `@midnight` | Midnight daily |
| `@weekly` | Midnight Sunday |
| `0 1 * * *` | 1:00 AM daily (5-field, no seconds) |
| `0 0 1 * * *` | 1:00 AM daily (6-field, with seconds) |
| `*/5 * * * *` | Every 5 minutes |

**Gotcha**: Older Ofelia versions required 6-field (seconds first). Current versions accept both 5-field and 6-field. If migrating old configs, `0 0 1 * * *` (6-field) = `0 1 * * *` (5-field).

## Job Types

See `references/job-parameters.md` for complete parameter tables.

### job-exec

Runs inside an **existing running container**. Equivalent to `docker exec`.

Required: `schedule`, `command`, `container`

```ini
[job-exec "clear-cache"]
schedule = @hourly
container = redis-server
command = redis-cli FLUSHDB
user = redis
```

### job-run

Creates a **new ephemeral container** from an image. Equivalent to `docker run --rm`. Can also start a stopped container (specify `container` instead of `image`).

Required: `schedule`, plus either `image` or `container`

```ini
[job-run "db-backup"]
schedule = 0 2 * * *
image = postgres:16-alpine
command = pg_dumpall -h db -U postgres > /backup/dump.sql
volume = /backups:/backup:rw
network = app-network
environment = PGPASSWORD=secret
delete = true
pull = true
```

### job-local

Runs on the **host running Ofelia**. When Ofelia is containerized, this runs inside the Ofelia container itself.

Required: `schedule`, `command`

```ini
[job-local "cleanup-tmp"]
schedule = @daily
command = find /tmp -mtime +7 -delete
dir = /tmp
```

### job-service-run

Creates a **one-shot Swarm service**. For Docker Swarm environments only.

Required: `schedule`, `image`

```ini
[job-service-run "swarm-task"]
schedule = 0,20,40 * * * *
image = ubuntu:latest
network = swarm_network
command = touch /tmp/example
delete = true
```

## Middleware (Per-Job and Global)

All middleware parameters can be set globally (`[global]` section / Ofelia container labels) or per-job. Per-job settings override global.

### Overlap Prevention

```ini
no-overlap = true
```

Skips execution if previous run is still active. Logs as "skipped".

### Slack Notifications

```ini
slack-webhook = https://hooks.slack.com/services/T00/B00/XXX
slack-only-on-error = true
```

### Email Notifications

```ini
smtp-host = smtp.gmail.com
smtp-port = 587
smtp-user = alerts@example.com
smtp-password = app-password
smtp-tls-skip-verify = false
email-to = ops@example.com
email-from = ofelia@%s
mail-only-on-error = true
```

`email-from` supports `%s` placeholder for hostname. Emails include stdout/stderr log attachments.

### Save to Disk

```ini
save-folder = /var/log/ofelia
save-only-on-error = false
```

Saves `<timestamp>_<jobname>.stdout.log`, `.stderr.log`, and `.json` (execution metadata).

## Environment Variables

### Docker Connection

| Variable | Description | Default |
|----------|-------------|---------|
| `DOCKER_HOST` | Docker daemon endpoint | `unix:///var/run/docker.sock` |
| `DOCKER_TLS_VERIFY` | Enable TLS (`1`) | unset |
| `DOCKER_CERT_PATH` | TLS certificate directory | unset |
| `DOCKER_API_VERSION` | Override API version | auto-negotiated |

### Socket Proxy (recommended for production)

```yaml
services:
  docker-proxy:
    image: tecnativa/docker-socket-proxy
    environment:
      CONTAINERS: 1
      POST: 1
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro

  ofelia:
    image: mcuadros/ofelia:latest
    command: daemon --docker
    environment:
      DOCKER_HOST: tcp://docker-proxy:2375
    depends_on:
      - docker-proxy
```

## CLI Commands

| Command | Description |
|---------|-------------|
| `ofelia daemon --config=/path/to/config.ini` | Run with INI config |
| `ofelia daemon --docker` | Run with Docker label config |
| `ofelia daemon --config=/path --docker` | Combined (both sources) |
| `ofelia daemon --docker -f label=KEY=VAL` | Filter containers |
| `ofelia validate --config=/path/to/config.ini` | Validate config without running |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| `job-exec` labels on Ofelia container | Put on **target** container with `ofelia.enabled=true` |
| `job-run` labels on target container | Put on **Ofelia** container (it creates new containers) |
| Ofelia starts before target containers | Use `depends_on` or start Ofelia last; label reading is at startup |
| 6-field cron not working | Current versions use 5-field by default; seconds are optional prefix |
| Container name mismatch | Use `docker ps` name, not service name (Compose prepends project name) |
| `environment` with multiple vars in labels | Use JSON array: `["FOO=bar", "BAZ=qux"]` |
| `volume` with multiple mounts in labels | Use JSON array: `["/a:/a:ro", "/b:/b:rw"]` |
| `no-overlap` not preventing overlap | Ensure parameter is on the **job**, not just globally |
| job-local runs inside container | Expected when Ofelia is containerized; mount host dirs if needed |
| Exit code -1 errors | Usually wrong `user` — try removing or changing the user parameter |
| Max time exceeded | Jobs have 24-hour hard limit; redesign long-running tasks |
| Image not found for job-run | Set `pull = true` (default) or ensure image exists locally |

## Gotchas

- **Label reading timing**: Ofelia reads labels at startup. If the target container isn't running yet, its `job-exec` labels won't be discovered. Use `depends_on` in Compose.
- **Dynamic label updates**: Ofelia polls for label changes when using `--docker`, but adding/removing containers requires the polling to detect changes.
- **Config keys are case-insensitive**: `Schedule`, `schedule`, and `SCHEDULE` all work.
- **Stdout/stderr buffer**: Limited to 10MB per stream per execution. Larger output is truncated (circular buffer).
- **job-run `delete` and `pull`**: Both default to `true` but are stored as strings internally due to a Go defaults library quirk — always quote in labels.
- **Docker auth**: For private registries, Ofelia reads `~/.docker/config.json` (or `$DOCKER_CONFIG`). Mount it into the container if using private images with `job-run`.
- **Swarm mode**: `job-service-run` creates a one-shot service with `RestartPolicy: none` and `MaxAttempts: 1`. The service is deleted after completion if `delete = true`.
