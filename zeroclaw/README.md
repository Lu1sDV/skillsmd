# zeroclaw skill

Claude Code skill for working with [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw) — a Rust-based autonomous AI assistant infrastructure.

## What it covers

- CLI command reference (onboard, agent, daemon, gateway, auth, channels)
- Configuration (`~/.zeroclaw/config.toml` — providers, memory, runtime, channels, security)
- Installation (Homebrew, bootstrap, source, pre-built binaries)
- Architecture (trait-driven swappable subsystems)
- Authentication (API keys, OAuth device flow, multi-profile)
- Memory system (hybrid vector + FTS5 search, no external vector DB)
- Deployment patterns (daemon, webhook gateway, Docker sandbox)
- Migration from OpenClaw
- Troubleshooting & security

## ZeroClaw Documentation Tree

Source: [`docs/README.md`](https://github.com/zeroclaw-labs/zeroclaw/blob/main/docs/README.md)

### Quick Start

| Task | Document |
|------|----------|
| Install & quick start | `README.md#quick-start` |
| One-command bootstrap | `docs/one-click-bootstrap.md` |
| macOS updates/uninstall | `docs/getting-started/macos-update-uninstall.md` |
| Command lookup | `docs/commands-reference.md` |
| Configuration defaults | `docs/config-reference.md` |
| Custom providers/endpoints | `docs/custom-providers.md` |
| Z.AI / GLM setup | `docs/zai-glm-setup.md` |
| LangGraph patterns | `docs/langgraph-integration.md` |
| Day-2 operations | `docs/operations-runbook.md` |
| Troubleshooting | `docs/troubleshooting.md` |
| Matrix E2EE setup | `docs/matrix-e2ee-guide.md` |
| Category browse | `docs/SUMMARY.md` |

### Collections

- `docs/getting-started/README.md`
- `docs/reference/README.md`
- `docs/operations/README.md`
- `docs/security/README.md`
- `docs/hardware/README.md`
- `docs/contributing/README.md`
- `docs/project/README.md`

### Reference

- `docs/commands-reference.md` — command workflow lookup
- `docs/providers-reference.md` — provider IDs, aliases, credentials
- `docs/channels-reference.md` — channel capabilities, setup
- `docs/config-reference.md` — config keys, secure defaults
- `docs/custom-providers.md` — custom provider templates
- `docs/zai-glm-setup.md` — Z.AI/GLM endpoint matrix
- `docs/langgraph-integration.md` — fallback integration patterns

### Security & Reliability

- `docs/security/README.md`
- `docs/agnostic-security.md`
- `docs/frictionless-security.md`
- `docs/sandboxing.md`
- `docs/audit-logging.md`
- `docs/resource-limits.md`
- `docs/security-roadmap.md`

### Contributing

- `CONTRIBUTING.md`
- `docs/pr-workflow.md`
- `docs/reviewer-playbook.md`
- `docs/ci-map.md`
- `docs/actions-source-policy.md`

### Localized Docs

- `docs/README.zh-CN.md` (简体中文)
- `docs/README.ja.md` (日本語)
- `docs/README.ru.md` (Русский)
- `docs/README.fr.md` (Français)
- `docs/i18n/vi/README.md` (Tiếng Việt)

## Install

Copy `zeroclaw/` into `~/.claude/skills/`.

## Triggers

Activates when working with ZeroClaw setup, configuration, deployment, channel binding, provider integration, memory backends, or migration tasks.
