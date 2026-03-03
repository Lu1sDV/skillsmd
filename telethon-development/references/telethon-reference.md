# Telethon Reference — Detailed Patterns

Heavy reference companion to the main SKILL.md.

## FloodWaitError Wrapper Patterns

These are **implementation patterns** — not importable from Telethon. Implement in your project's client utilities.

### Decorator (single async calls)

```python
import functools
from telethon.errors import FloodWaitError

def flood_safe(max_retries=3):
    def decorator(func):
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            for attempt in range(max_retries):
                try:
                    return await func(*args, **kwargs)
                except FloodWaitError as e:
                    if attempt == max_retries - 1:
                        raise
                    await asyncio.sleep(e.seconds)
        return wrapper
    return decorator

@flood_safe(max_retries=3)
async def fetch_entity(client, chat_id):
    return await client.get_entity(chat_id)
```

### Iterator Wrapper (async iteration with checkpoint resume)

```python
async def iter_with_flood_retry(iter_factory, max_retries=3, resume_checkpoint=None):
    checkpoint = resume_checkpoint
    for attempt in range(max_retries):
        try:
            async for item in iter_factory(offset_id=checkpoint or 0):
                if hasattr(item, "id"):
                    checkpoint = item.id
                yield item
            return
        except FloodWaitError as e:
            if attempt == max_retries - 1:
                raise
            await asyncio.sleep(e.seconds)
            # Resumes from checkpoint on next iteration

# Usage
async for msg in iter_with_flood_retry(
    lambda offset_id=0: client.iter_messages(chat, limit=1000, offset_id=offset_id),
    max_retries=3, resume_checkpoint=last_id,
):
    process(msg)
```

### Takeout Sessions (heavy participant scraping)

```python
from telethon.errors import TakeoutInitDelayError

try:
    async with client.takeout() as takeout:
        async for user in takeout.iter_participants(chat, wait_time=10):
            process(user)
except TakeoutInitDelayError as e:
    await asyncio.sleep(e.seconds)  # Telegram enforces a delay between takeouts
```

## Test Mocking Patterns

### Mock Client Fixture

```python
@pytest.fixture
def mock_telethon_client() -> MagicMock:
    client = MagicMock()
    client.connect = AsyncMock(return_value=True)
    client.disconnect = AsyncMock()
    client.is_connected = MagicMock(return_value=True)
    client.get_me = AsyncMock(return_value=MagicMock(id=123456, username="testuser"))
    # iter_messages is sync MagicMock wrapping async — allows replacement with async generators
    client.iter_messages = MagicMock(return_value=AsyncMock())
    client.iter_participants = MagicMock(return_value=AsyncMock())
    client.get_entity = AsyncMock()
    return client
```

### Async Generator for iter_messages

```python
async def mock_iter_messages(**kwargs):
    for msg in [mock_msg_1, mock_msg_2, mock_msg_3]:
        yield msg

mock_telethon_client.iter_messages = mock_iter_messages
```

### RPC Call Mocking (client(Request()))

```python
# Single call
mock_client.return_value = mock_updates_object

# Sequential calls (e.g. pagination)
results = [page_1_result, empty_result]
idx = 0
async def async_call(*args, **kwargs):
    nonlocal idx
    result = results[idx]; idx += 1
    return result
type(mock_client).__call__ = lambda self, *a, **kw: async_call(*a, **kw)
```

### Telethon Types with spec= (isinstance-compatible mocks)

```python
from telethon.tl.types import Channel, User, ChannelParticipantAdmin

channel = MagicMock(spec=Channel)       # isinstance(channel, Channel) == True
user = MagicMock(spec=User)
admin = MagicMock(spec=ChannelParticipantAdmin)
```

### Mock Document Attributes (class name pattern)

```python
video_attr = MagicMock()
video_attr.__class__.__name__ = "DocumentAttributeVideo"
video_attr.round_message = False
doc = MagicMock(attributes=[video_attr])
```

### FloodWaitError Construction

```python
FloodWaitError(request=None, capture=0.01)   # Minimal wait (fast tests)
FloodWaitError(request=None, capture=0)      # Zero wait
FloodWaitError(None, capture=120)            # Realistic 2-minute wait
```

## Entity & Type Patterns

### Channel Type Detection

```python
def resolve_channel_type(entity) -> str:
    if getattr(entity, "gigagroup", False): return "gigagroup"
    if getattr(entity, "megagroup", False): return "supergroup"
    if getattr(entity, "broadcast", False): return "channel"
    return "group"
```

### Identifier Parsing (all Telegram link formats)

```python
import re

def parse_telegram_identifier(value: str) -> tuple[str, str]:
    """Returns (type, identifier): type is 'invite', 'username', or 'id'."""
    m = re.match(r"https?://t\.me/\+(.+)", value)
    if m: return ("invite", m.group(1))
    m = re.match(r"https?://t\.me/joinchat/(.+)", value)
    if m: return ("invite", m.group(1))
    m = re.match(r"https?://t\.me/(\w+)", value)
    if m: return ("username", m.group(1))
    if value.startswith("@"): return ("username", value[1:])
    if value.lstrip("-").isdigit(): return ("id", value)
    return ("username", value)
```

### Peer ID Extraction

```python
from telethon.tl.types import PeerChannel, PeerChat, PeerUser

def extract_peer_id(peer) -> int | None:
    if peer is None: return None
    if isinstance(peer, PeerUser): return peer.user_id
    if isinstance(peer, PeerChat): return peer.chat_id
    if isinstance(peer, PeerChannel): return peer.channel_id
    return None
```

Used for: `from_id`, `peer_id`, `saved_peer_id`, `reply_to_peer_id`, `forward_from_id`.

### Participant Role Detection (dual strategy for mock compatibility)

```python
def get_role(participant) -> str:
    # isinstance first (real Telethon objects)
    if isinstance(participant, (ChannelParticipantCreator, ChatParticipantCreator)):
        return "creator"
    if isinstance(participant, (ChannelParticipantAdmin, ChatParticipantAdmin)):
        return "admin"
    if isinstance(participant, ChannelParticipantBanned):
        return "banned"
    if isinstance(participant, ChannelParticipantLeft):
        return "left"
    # Fallback: class name for mocks
    name = participant.__class__.__name__
    if "Creator" in name: return "creator"
    if "Admin" in name: return "admin"
    if "Banned" in name: return "banned"
    if "Left" in name: return "left"
    return "member"
```

Use `getattr(rights, "manage_topics", False)` for newer admin/banned rights fields.

### Join/Leave Operations

```python
from telethon.tl.functions.channels import JoinChannelRequest, LeaveChannelRequest
from telethon.tl.functions.messages import ImportChatInviteRequest

updates = await client(ImportChatInviteRequest(hash_value))  # Join by invite hash
chat = updates.chats[0] if updates.chats else None

await client(JoinChannelRequest(entity))    # Join by username/entity
await client(LeaveChannelRequest(entity))   # Leave channel
await client.delete_dialog(entity)           # Leave basic Chat/group
```

### Raw Serialization for JSONB

```python
def make_serializable(obj):
    if isinstance(obj, bytes):
        import base64
        return base64.b64encode(obj).decode("ascii")
    if isinstance(obj, datetime):
        return obj.isoformat()
    if isinstance(obj, dict):
        return {k: make_serializable(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple)):
        return [make_serializable(v) for v in obj]
    return obj

raw = make_serializable(message.to_dict())
```

### Common Imports Reference

```python
from telethon import TelegramClient, events
from telethon.sessions import StringSession
from telethon.utils import get_peer_id
from telethon.errors import (
    FloodWaitError, AuthKeyUnregisteredError, ChannelPrivateError,
    ChatAdminRequiredError, PhoneNumberBannedError, UserDeactivatedBanError,
    UserAlreadyParticipantError, InviteHashExpiredError, InviteRequestSentError,
    SessionPasswordNeededError, TakeoutInitDelayError,
)
from telethon.tl.functions.channels import (
    JoinChannelRequest, LeaveChannelRequest, GetParticipantsRequest,
)
from telethon.tl.functions.messages import ImportChatInviteRequest
from telethon.tl.types import (
    Channel, Chat, User, Message,
    PeerChannel, PeerChat, PeerUser,
    MessageMediaDocument, MessageMediaPhoto, MessageMediaPoll,
    ChannelParticipantAdmin, ChannelParticipantCreator,
    ChannelParticipantBanned, ChannelParticipantLeft,
    ChannelParticipantsSearch,
)
# Version-guard these (Telethon 1.36+):
# MessageMediaGiveaway, MessageMediaGiveawayResults
# MessageMediaPaidMedia, MessageMediaToDo
# ReactionCustomEmoji, ReactionEmoji
```

## SQLAlchemy Integration

The patterns below are specific to **SQLAlchemy-backed projects**. They handle the mismatch between Telethon's data model and relational databases.

### Boolean Normalization (NOT NULL columns)

Telethon uses `None` for `False` on optional boolean flags. Normalize before DB insert:

```python
# Auto-discover boolean NOT NULL columns
_BOOL_NOT_NULL = frozenset(
    c.name for c in Model.__table__.columns
    if isinstance(c.type, Boolean) and not c.nullable
)

# Normalize after transform
for field in _BOOL_NOT_NULL:
    if result.get(field) is None:
        result[field] = False

# For individual fields
result[field] = getattr(user, field, False) or False
```

### SQLite JSONB Patching (test conftest.py — MUST be first import)

```python
# Patch BEFORE any model imports — replaces PostgreSQL types with SQLite equivalents
from sqlalchemy.dialects import postgresql
from sqlalchemy.dialects.sqlite import JSON as SQLiteJSON
from sqlalchemy import Text

postgresql.JSONB = SQLiteJSON    # JSONB → JSON
postgresql.TSVECTOR = Text       # TSVECTOR → Text
```

### Model Drift Detection

Detect when DB schema adds columns that the scraper doesn't extract:

```python
def validate_field_coverage() -> None:
    model_cols = {c.name for c in Model.__table__.columns}
    covered = _AUTO_MANAGED | _PKS | _DIRECT_SCALARS | set(_RENAMED) | _COMPUTED
    missing = model_cols - covered
    if missing:
        raise RuntimeError(f"Field drift detected! Uncovered: {sorted(missing)}")
```

Call at startup or in tests.

### Message Entity Extraction

```python
def extract_entities(entities) -> list[dict] | None:
    if not entities:
        return None
    return [
        {
            "type": type(e).__name__,
            "offset": e.offset,
            "length": e.length,
            **{k: v for k, v in vars(e).items()
               if k not in ("offset", "length") and not k.startswith("_")},
        }
        for e in entities
    ]
```
