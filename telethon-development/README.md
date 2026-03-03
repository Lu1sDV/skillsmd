# telethon-development skill

Claude Code skill for working with [Telethon](https://github.com/LonamiWebs/Telethon) — the Python MTProto client for Telegram.

## What it covers

- Critical gotchas: boolean `None`-as-`False` fields, `isinstance()` failures with mocks, missing `max_date` on iterators
- `FloodWaitError` handling — decorator, iterator wrapper, and context manager patterns
- Session management with `StringSession` (env var storage)
- Rate limiting guidelines and safe operation thresholds
- Entity resolution and canonical ID normalization for DB storage
- Version guards for types added in newer Telethon releases
- Test mocking — async generators, RPC call mocking, `spec=`-compatible fixtures
- SQLAlchemy integration — boolean normalization, JSONB serialization, model drift detection
- Common error table with recommended handling per error type

## Install

Copy `telethon-development/` into `~/.claude/skills/`.

Or install via:

```bash
npx skills add Lu1sDV/skillsmd
```

## Triggers

Activates when debugging `FloodWaitError`, account bans, or flood cycling; mocking Telethon clients for tests; storing Telethon data in a database; resolving/normalizing chat IDs; or handling version-specific Telethon types.
