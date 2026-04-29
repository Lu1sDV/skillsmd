# Python Sinks

---

## RCE

`os.system()`, `os.popen()`, `subprocess.call/check_call/check_output/run/Popen()`, `exec()`, `eval()`, `compile()`, `__import__('os').system()`, `importlib.import_module()`, `code.InteractiveInterpreter`, `pty.spawn()`, `commands.getoutput()` (Python 2)

---

## Deserialization

`pickle.loads()`, `pickle.load()`, `shelve.open()`, `yaml.load()` (without `Loader=SafeLoader`), `yaml.unsafe_load()`, `jsonpickle.decode()`, `dill.loads()`, `cloudpickle.loads()`, `marshal.loads()`, `cPickle.loads()` (Python 2), `_pickle.loads()` (C-accelerated pickle, same risk as `pickle.loads()`)

---

## SSTI

`jinja2.Template(user_input).render()`, `mako.template.Template(user_input).render()`, `tornado.template.Template(user_input).generate()`, `django.template.Template(user_input)` (rare but possible), `string.Template(user_input).substitute()` (limited)

---

## File Operations

`open()`, `os.path.*`, `shutil.*`, `tempfile.*` without proper cleanup, `zipfile.extractall()` (zip slip), `tarfile.extractall()` (tar slip with symlinks), `os.symlink()`, `pathlib.Path` operations

---

## SSRF

`requests.get/post()`, `urllib.request.urlopen()`, `http.client.HTTPConnection`, `httpx`, `aiohttp.ClientSession`, `urllib3`

---

## SQLi

`cursor.execute(f"SELECT * FROM users WHERE id={user_input}")`, `sqlalchemy.text()`, Django `raw()`, `extra()`, `RawSQL()`

---

## Additional Python Sinks

- **XXE:** `lxml.etree.parse()`, `lxml.etree.fromstring()` (external entities enabled by default), `xml.sax.parseString()` with custom handler, `defusedxml` missing
- **LDAP:** `python-ldap` `search_s()`, `ldap3` `connection.search()` with unsanitized filters
- **XSS:** `markupsafe.Markup()` wrapping user input, `jinja2` `|safe` filter on tainted data, Django `mark_safe()`
- **Path Traversal:** `os.path.join(base, user_input)` (does NOT prevent `../`), `send_file()`/`send_from_directory()` in Flask without validation

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
