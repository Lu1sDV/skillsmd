# ctfd skill

Claude Code skill for working with [CTFd](https://github.com/CTFd/CTFd) — a Python Flask-based Capture The Flag platform.

## What it covers

- Architecture (Flask + Gunicorn + MySQL/SQLite + Redis + nginx)
- Docker stack setup and commands
- Critical gotchas (CSRF silent 302, password hashing, SQLAlchemy 1.4, config priority, SECRET_KEY)
- Plugin development (structure, APIs, challenge types, flag types, loading pitfalls)
- Theme development (Vite build, Alpine.js/Vue.js, asset pipeline, Jinja2 templates)
- Testing infrastructure (pytest, Flask SERVER_NAME, CSRF in tests, SQLite StaticPool, hyphenated plugins)
- Playwright E2E patterns (networkidle hang, login selectors, CSRF nonce, setup redirect)
- Troubleshooting playbook (API returns HTML, 500s, container rebuilds, session invalidation)
- CTFd reference (user modes, scoring, visibility, flag types, config variables, webhooks, API auth, migrations)
- Code style (black, isort, ruff, prettier, SA 1.4 legacy query)

## CTFd Documentation

| Topic | Source |
|-------|--------|
| Official docs | `docs.ctfd.io` |
| API reference | `<instance>/api/v1/` (Swagger UI, enable with `SWAGGER_UI=True`) |
| Plugin dev guide | `docs.ctfd.io/docs/plugins/overview` |
| Theme dev guide | `docs.ctfd.io/docs/themes/overview` |
| GitHub repo | `github.com/CTFd/CTFd` |

## Install

Copy `ctfd/` into `~/.claude/skills/`.

## Triggers

Activates when developing plugins, customizing themes, debugging Docker stack issues, writing tests, handling CSRF problems, managing database migrations, or operating CTFd instances.
