---
name: telethon-development
description: Use when working with Telethon (Telegram MTProto client) — debugging FloodWaitError, mocking for tests, handling None-as-False boolean fields, entity resolution, rate limiting, session management, or version compatibility issues
---

# Telethon Development Patterns

Production patterns and gotchas for the Telethon Telegram MTProto client library.

## When to Use
- Debugging `FloodWaitError`, account bans, or flood wait cycling
- Mocking Telethon clients for unit/integration tests
- Storing Telethon data in a database (boolean normalization, serialization)
- Resolving/normalizing chat IDs before DB storage
- Handling new or version-specific Telethon types

## When NOT to Use
- Bot API (`python-telegram-bot`) — different library, different patterns
- Telethon v2 — major API changes; verify patterns still apply

## Critical Gotchas

| Gotcha | What Breaks | Fix |
|--------|-------------|-----|
| Boolean fields are `None` not `False` | NOT NULL DB columns | `getattr(obj, field, False) or False` |
| `isinstance()` fails with test mocks | Media/reaction type detection | `type(obj).__name__` string comparison |
| `iter_messages()` has no `max_date` | Date filtering silently skipped | Filter post-fetch: `if msg.date > max_date: continue` |
| `to_dict()` returns `bytes` in polls | JSONB serialization crashes | Base64-encode bytes before storage |
| New types missing in older versions | `ImportError` at startup | Guard with `try/except ImportError` |
| `ReactionCount.chosen` removed in 1.42 | `AttributeError` | `getattr(r, 'chosen_order', None) is not None` |
| `get_peer_id()` on non-standard objects | `TypeError` | try/except, fallback `getattr(entity, 'id', 0)` |
| `MessageDeleted` non-channel events | `chat_id` is `None` | Always guard `if event.chat_id is not None` |
| Stop listener before pool | Dangling handler errors | `listener.stop()` then `pool.stop()` |
| `aggressive=True` on `iter_participants` | Triggers flood waits faster | Use `ChannelParticipantsSearch("")` with pagination |
| 2FA detection is string-based | Missed 2FA prompts | Catch `SessionPasswordNeededError` explicitly |

## Session Management

Always use `StringSession` — never file sessions. Store in env vars; treat as passwords (full account access).

```python
from telethon import TelegramClient
from telethon.sessions import StringSession

client = TelegramClient(StringSession(os.getenv("TG_SESSION")), api_id, api_hash)
await client.connect()
if not await client.is_user_authorized():
    await client.send_code_request(phone)
    await client.sign_in(phone, code)
session_string = client.session.save()  # Save to env var after auth
```

## FloodWaitError Handling

The raw pattern (basis for all wrappers):
```python
except FloodWaitError as e:
    await asyncio.sleep(e.seconds)  # e.seconds = mandatory wait duration
    # then retry or rotate to next account
```

Three wrapper patterns — see [telethon-reference.md](references/telethon-reference.md) for implementations:

| Pattern | When to Use |
|---------|-------------|
| Decorator | Single async calls (`get_entity`, `get_messages`) |
| Iterator wrapper | `async for` loops — supports checkpoint resume on retry |
| Context manager | Complex control flow, manual checkpoint tracking |

## Type Detection (Mock-Safe)

Use class name strings — works with both real Telethon objects AND test mocks:

```python
attr_name = type(attr).__name__
if attr_name == "DocumentAttributeVideo":
    return "video_note" if getattr(attr, "round_message", False) else "video"

if type(reaction).__name__ == "ReactionEmoji":
    return reaction.emoticon
```

## Version Guards

Always guard imports for types added in recent Telethon versions:

```python
try:
    from telethon.tl.types import MessageMediaPaidMedia
except ImportError:
    MessageMediaPaidMedia = None
```

## Entity Resolution & ID Normalization

```python
from telethon.utils import get_peer_id

entity = await client.get_entity(identifier)  # str, int, or @username
normalized_id = get_peer_id(entity)            # Canonical ID for DB storage
```

See [telethon-reference.md](references/telethon-reference.md) for channel type detection and all link format parsing.

## Rate Limiting Guidelines

| Operation | Safe Rate | Risk |
|-----------|-----------|------|
| Messages in single chat | 1/second | Flood ban |
| Channel joins | 2-5s between | Account freeze |
| Participant scraping (no takeout) | Don't | Instant ban |
| Channels scraped per day | <200 | 24h soft ban |
| Mass avatar downloads | Don't | Ban after 3-5 |

Use **takeout sessions** for heavy participant scraping — see [telethon-reference.md](references/telethon-reference.md).

## Common Errors

| Error | Meaning | Handle |
|-------|---------|--------|
| `FloodWaitError` | Rate limited | Wait `e.seconds`, rotate account |
| `AuthKeyUnregisteredError` | Session invalid | Disable account permanently |
| `ChannelPrivateError` | No access | Skip, log |
| `ChatAdminRequiredError` | Need admin | Return empty, log |
| `UserAlreadyParticipantError` | Already joined | Not an error — treat as success |
| `InviteRequestSentError` | Needs approval | Log as pending |
| `PhoneNumberBannedError` | Account banned | Disable permanently |

## Test Mocking

See [telethon-reference.md](references/telethon-reference.md) for complete patterns:
- Mock client fixture with async generators
- RPC call mocking (`client(Request())`)
- `spec=` for `isinstance()` compatibility
- `FloodWaitError` construction: `FloodWaitError(request=None, capture=0.01)`
