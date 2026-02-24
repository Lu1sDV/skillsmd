# glitchtip skill

Claude Code skill for working with [GlitchTip](https://glitchtip.com/) — an open-source, Sentry-compatible error tracking and uptime monitoring platform.

## What it covers

- Deployment (Docker Compose, Kubernetes/Helm, managed platforms)
- Configuration (all environment variables — required, email, retention, cache, security)
- SDK integration (58 Sentry SDKs across 18 languages, DSN setup, sampling)
- Uptime monitoring (Ping, GET, POST, Heartbeat)
- Integrations (GitLab, Grafana, webhooks, email alerts)
- Social authentication (GitHub, GitLab, Google, Microsoft, OIDC/Keycloak)
- File storage (S3, Azure Blob, GCS, local)
- CLI tool (gtc)
- Troubleshooting

## GlitchTip Documentation Tree

Source: [glitchtip.com/documentation](https://glitchtip.com/documentation)

### Core Docs

| Topic | URL |
|-------|-----|
| Getting Started | `glitchtip.com/documentation/getting-started` |
| Installation | `glitchtip.com/documentation/install` |
| Error Tracking | `glitchtip.com/documentation/error-tracking` |
| Uptime Monitoring | `glitchtip.com/documentation/uptime-monitoring` |
| Integrations | `glitchtip.com/documentation/integrations` |
| SDK Docs | `glitchtip.com/sdkdocs` |
| API Reference | `app.glitchtip.com/api/docs` |
| FAQ | `glitchtip.com/documentation/frequently-asked-questions` |

### Development & Operations

| Topic | URL |
|-------|-----|
| Contributing | `glitchtip.com/documentation/contribute` |
| Hosted Architecture | `glitchtip.com/documentation/hosted-architecture` |
| Backend Repo | `gitlab.com/glitchtip/glitchtip-backend` |
| CLI Tool | `pypi.org/project/glitchtip-cli` |

## Install

Copy `glitchtip/` into `~/.claude/skills/`.

## Triggers

Activates when deploying, configuring, integrating SDKs, setting up uptime monitors, configuring alerts, managing social auth, or troubleshooting GlitchTip instances.
