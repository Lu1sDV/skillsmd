---
name: ctfd
description: Use when developing, debugging, deploying, or maintaining any CTFd instance or fork - Docker stack issues, plugin development, CSRF 302 errors, theme customization, database migrations, nginx proxy misconfig, SQLAlchemy 1.4 gotchas, pytest test infrastructure, or API 500 responses
---

# CTFd Development & Operations

CTFd is a Python 3.11 Flask-based Capture The Flag platform. SQLAlchemy 1.4, Redis, Jinja2 themes, plugin system.

## Architecture

```
nginx → ctfd (gunicorn+gevent) → MySQL/SQLite + Redis
         ├── plugins/          # Extensible plugin system
         └── themes/           # Jinja2 theme directories
```

## Quick Commands

```bash
# Docker stack
docker compose up --build -d          # Build + start
docker compose logs -f ctfd           # Stream logs
docker compose exec ctfd bash         # Shell in
docker compose down                   # Stop

# Testing
pytest -rf --cov=CTFd -n auto         # Full suite parallel

# Local dev
python serve.py                       # Debug server (port 4000)

# Database
flask db upgrade                      # Apply migrations
flask db migrate -m "description"     # Generate migration
```

## Docker Stack

| Service | Default Port | Purpose |
|---------|-------------|---------|
| ctfd | 8000 | Flask/Gunicorn, `REVERSE_PROXY=true` behind proxy |
| nginx | 80 | Reverse proxy, static files |
| cache | 6379 | Redis for sessions + config cache |

## Critical Gotchas

### 1. CSRF Protection (SILENT FAILURE)

All POST/PATCH/DELETE require `CSRF-Token` header matching `session["nonce"]`. **Without it, requests silently 302 redirect to login returning HTML instead of JSON.** No error message.

```javascript
// Extract from any authenticated page
headers: { 'CSRF-Token': init.csrfNonce, 'Content-Type': 'application/json' }
```

**Source:** `CTFd/utils/initialization/__init__.py`. JSON requests check header, form requests check `nonce` field.

### 2. Password Hashing (DATA CORRUPTION)

**ALWAYS** use `CTFd.utils.crypto.hash_password()`. CTFd uses `bcrypt_sha256` via passlib. Raw SQL UPDATE on password column causes `ValueError: not a valid bcrypt_sha256 hash` on next login — user is permanently locked out.

```python
from CTFd.utils.crypto import hash_password, verify_password
user.password = hash_password("newpass")  # CORRECT
# NEVER: user.password = "newpass"
```

### 3. SQLAlchemy 1.4 Legacy Style

CTFd uses SQLAlchemy 1.4, NOT 2.x. Use legacy query API:

```python
# CORRECT
User.query.filter_by(name="admin").first()
# WRONG (SA 2.x style)
db.session.execute(select(User).where(...))
```

### 4. Config Priority Chain

`Environment variables > config.ini > defaults`. Docker env vars in `docker-compose.yml` override everything. See `EnvInterpolation` in `config.py`.

### 5. Plugin requirements.txt

Plugin deps install at Docker build time via multi-stage Dockerfile. Add deps to `CTFd/plugins/<name>/requirements.txt`, NOT the root `requirements.txt`. Rebuild image after changes.

### 6. Git Submodules

CTFd may use submodules (e.g., plugins, docs). After clone:
```bash
git submodule update --init --recursive
```
Missing submodule init causes import errors at startup.

### 7. SECRET_KEY for Multi-Worker

Entrypoint refuses to start with `WORKERS > 1` unless `SECRET_KEY` env var or `.ctfd_secret_key` file exists. Single worker auto-generates a key, but it changes on restart (invalidating sessions).

```bash
head -c 64 /dev/urandom > .ctfd_secret_key
```

## Plugin Development

### Plugin Structure

```
CTFd/plugins/<name>/
├── __init__.py          # load(app) function — entry point
├── config.json          # Metadata (name, route)
├── requirements.txt     # Python dependencies
├── templates/<ns>/      # Jinja2 templates (namespaced!)
└── assets/              # Static files (JS/CSS)
```

### Key APIs

```python
# Register routes
@app.route('/my-plugin', methods=['GET'])
def view(): return render_template('my_ns/page.html')

# Override existing routes
app.view_functions['challenges.challenges_view'] = my_function

# Override templates
from CTFd.utils.plugins import override_template
override_template('scoreboard.html', custom_html)

# Register static assets — NO leading/trailing slashes
register_plugin_assets_directory(app, base_path="plugins/my-plugin/assets")

# Database models
class MyModel(db.Model):
    id = db.Column(db.Integer, primary_key=True)
# In load(): app.db.create_all()
```

### Custom Challenge Types

Extend `BaseChallenge`, implement: `create`, `read`, `update`, `delete`, `attempt`, `solve`, `fail`. Register in `CHALLENGE_CLASSES` dict. Model inherits from `Challenges` with `polymorphic_identity`. Frontend: `create.html`, `update.html`, `view.html` + matching `.js`.

### Custom Flag Types

Extend `BaseFlag`, implement `compare(chal_key_obj, provided) → bool`. Set `name` and `templates` dict. Register in `FLAG_CLASSES` dict.

### Plugin Loading Pitfalls

**Blueprint template_folder breaks core templates:** If a Blueprint uses `template_folder="templates"`, Flask may prioritize plugin templates over CTFd core. Fix: use `ChoiceLoader([core_loader, plugin_loader])`.

**Templates need namespace subdirectory:** Plugin templates at `plugins/<name>/templates/<namespace>/`. Without the `<namespace>` dir, templates shadow core or fail to load.

**register_plugin_assets_directory path format:**
```python
# CORRECT
register_plugin_assets_directory(app, base_path="plugins/my-plugin/assets")
# WRONG — causes 404
register_plugin_assets_directory(app, base_path="/plugins/my-plugin/assets/")
```

## Theme Development

### Theme Structure (Official)

```
themes/<name>/
├── assets/           # Uncompiled source (js/, scss/)
├── static/           # Compiled output (manifest.json auto-generated)
├── templates/        # Jinja2 templates (REQUIRED)
│   ├── base.html, challenges.html, challenge.html
│   ├── login.html, register.html, scoreboard.html
│   ├── settings.html, page.html, confirm.html
│   ├── components/   # navbar.html, errors.html, notifications.html
│   ├── macros/       # forms.html
│   ├── teams/        # team_enrollment, public, private, etc.
│   └── users/        # public, private, users listing
├── package.json
└── vite.config.js    # Build: Vite + Rollup, use Yarn
```

**Build:** `yarn install && yarn build` (or `yarn dev` for watch).
**Asset refs:** `{{ Assets.js('assets/js/index.js') }}` → resolves via manifest.
**JS stack:** Alpine.js (user-facing) + Vue.js (admin) + CTFd.js.

### Theme Gotchas

**Static files in `static/` NOT `assets/`:** URL route is `/themes/<name>/static/...`. Wrong directory = silent 404.

**Must extend `base.html`:** Direct HTML without extending breaks CSRF injection, asset pipeline, navigation:
```jinja2
{% extends "base.html" %}
{% block content %}...{% endblock %}
```

**Bootstrap class collisions:** CTFd base templates include Bootstrap. Namespace custom classes to avoid conflicts.

**Alpine.js registration timing:** `Alpine.data()` must run BEFORE `Alpine.start()`. If CTFd starts Alpine before theme JS loads, registrations silently fail. Use `defer` on Alpine script.

## Testing Infrastructure Gotchas

### Flask SERVER_NAME Breaks Subdomain Tests

Setting `SERVER_NAME = "localhost"` makes Flask reject non-localhost requests. **Set `SERVER_NAME = None`** in test config.

### CSRF Hook Crashes Test Helpers

The `before_request` CSRF hook fires for `client.get("/api/...")` in tests. If test doesn't seed a session nonce, it crashes. Mock the check or use `@app.test_request_context()`.

### CAPTCHA_ENABLED String Gotcha

`os.getenv("CAPTCHA_ENABLED")` returns string `"True"`, not bool. In tests: `os.environ["CAPTCHA_ENABLED"] = "False"` or recaptcha plugin crashes.

### pytest rootdir and confcutdir

Plugin tests need `--confcutdir=tests` or `--rootdir=.` in pytest.ini to prevent pytest from loading the wrong conftest.py from parent directories.

### max_overflow Incompatible with SQLite StaticPool

SQLAlchemy `StaticPool` (in-memory SQLite for tests) doesn't accept `max_overflow`. Set `SQLALCHEMY_MAX_OVERFLOW = None` in test config.

### Hyphenated Plugin Directories

Plugin dirs like `ctfd-my-plugin` are invalid Python identifiers. Import via:
```python
import importlib, sys
spec = importlib.util.spec_from_file_location(
    "ctfd_my_plugin", "CTFd/plugins/ctfd-my-plugin/__init__.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["ctfd_my_plugin"] = mod
```
**Warning:** Don't re-execute `spec.loader.exec_module(mod)` if already loaded — corrupts SQLAlchemy mapper.

### mock.patch() with Hyphenated Paths

`mock.patch("CTFd.plugins.ctfd-my-plugin.config.X")` fails. Use `patch.object(sys.modules["ctfd_my_plugin"], "X", ...)`.

## Playwright E2E Patterns

### networkidle Never Completes

CTFd has persistent SSE connections. `waitUntil: "networkidle"` hangs forever. Use `domcontentloaded`:
```python
await page.goto(url, wait_until="domcontentloaded")
```

### Login Form Selector

CTFd login uses `input#_submit` (underscore prefix), NOT `button[type=submit]`:
```python
await page.fill("input#name", "admin")
await page.fill("input#password", "admin")
await page.click("input#_submit")
```

### CSRF Nonce in E2E Tests

```python
nonce = await page.evaluate("() => init.csrfNonce")
```

### First-Time Setup Redirect

Fresh CTFd redirects all pages to `/setup`. Tests must detect and complete setup first.

## Troubleshooting Playbook

### API Returns HTML Instead of JSON

**Cause:** Missing `CSRF-Token` header or expired session → 302 redirect to login.
**Fix:** Include `CSRF-Token` and `Content-Type: application/json` headers.

### Admin Page Returns 500

**Cause:** Template not found, broken asset path, or missing DB table.
**Fix:** Check logs. Plugin templates at `plugins/<name>/templates/<namespace>/`. Run `flask db upgrade`.

### Container Won't Start / Rebuild Fails

**Cause:** Stale image cache, SELinux denials, port conflict.
**Fix:** `docker compose down && docker compose build --no-cache && docker compose up -d`

### Multi-Worker Sessions Invalidated on Restart

**Cause:** No persistent `SECRET_KEY`.
**Fix:** Set `SECRET_KEY` env var or create `.ctfd_secret_key` file.

### Plugin DB Tables Missing

**Cause:** `db.create_all()` runs at plugin load but won't run migrations.
**Fix:** `flask db upgrade` for schema changes.

### Import Errors at Startup

**Cause:** Submodules not initialized.
**Fix:** `git submodule update --init --recursive`

## CTFd Reference

### Core Concepts

- **User Modes:** `teams` or `users` — set at setup, switching loses all submissions
- **Scoring:** Standard (fixed) or Dynamic (parabolic decay: `value = ((min-init)/(decay²)) * (solves²) + init`)
- **Visibility:** Challenge/Score/Account/Registration each independently public/private/admins-only
- **Tie-breaking:** Lower solve ID in DB wins (first-to-solve advantage)

### Flag Types

| Type | How It Works |
|------|-------------|
| **Static** | Exact string match (case-sensitive by default) |
| **Regex** | Python regex pattern match (test with Pythex) |
| **HTTP** | Delegates to external endpoint; POST `{"submission":"..."}`, 202=correct |
| **Programmable** | Python `check(x) → bool` (Hosted/Enterprise only) |

### Configuration Variables

| Variable | Purpose |
|----------|---------|
| `SECRET_KEY` | Session signing |
| `DATABASE_URL` | DB URI (default: SQLite; MySQL recommended for prod) |
| `REDIS_URL` | Redis URI for cache/sessions |
| `REVERSE_PROXY` | `True`/`False` or ProxyFix settings |
| `UPLOAD_PROVIDER` | `filesystem` or `s3` |
| `UPLOAD_FOLDER` | Default: `CTFd/uploads` |
| `LOG_FOLDER` | Default: `CTFd/logs` |
| `APPLICATION_ROOT` | Subdirectory mount (e.g., `/ctfd`) |
| `SERVER_SENT_EVENTS` | Enable SSE notifications |
| `SWAGGER_UI` | Enable `/api/v1/` docs |
| `MAIL_*` | SMTP config |
| `AWS_*` | S3 upload config |

### Webhooks

4 events: `user_created`, `team_created`, `challenge_solved`, `first_blood`. HMAC-SHA256 endpoint validation. Signature: `CTFd-Webhook-Signature: t=<timestamp>,v1=<hmac>`.

### API Authentication

Token-based: `Authorization: Token <access_token>`. Generated in Settings → Access Tokens (30-day default). Swagger UI at `/api/v1/`.

### Database Migrations

SQLite auto-builds from models (no migrations needed). MySQL requires Alembic migrations. Plugin tables: `app.db.create_all()` in `load()`.

## Code Style

- **Python:** black + isort (profile=black) + ruff
- **JS/CSS:** prettier
- **Templates:** Jinja2, extend `admin/base.html` for admin pages
- **API responses:** `{"success": true, "data": ...}` or `{"success": false, "error": "..."}`
- **SQLAlchemy:** 1.4 legacy query style only
