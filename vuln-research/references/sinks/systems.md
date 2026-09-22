# Systems Language Sinks — Go, Rust, Elixir/Erlang

---

## Go Sinks

### RCE

`os/exec.Command()`, `os/exec.CommandContext()`, `syscall.Exec()`, `syscall.StartProcess()`, `os.StartProcess()`

**Indirect RCE:**
`plugin.Open()` (load arbitrary .so), `reflect` package for dynamic method invocation, `go/ast` + `go/parser` for code generation from tainted input, CGo `C.system()` / `C.popen()`

### SQLi

`database/sql` `db.Query()` / `db.Exec()` with `fmt.Sprintf()` interpolation, `gorm.Raw()`, `gorm.Exec()` with string concat, `sqlx.DB.Query()` with string building, `ent` framework `.Where()` with raw predicates

### SSRF

`net/http.Get()`, `net/http.Post()`, `net/http.Client.Do()`, `net/http.NewRequest()` with user-controlled URL, `resty.New().R().Get()`, `fasthttp.Do()`

### Path Traversal

`os.Open()`, `os.ReadFile()` (Go 1.16+), `filepath.Join()` (does NOT prevent `..` — use `filepath.Clean()` + prefix check), `http.ServeFile()`, `http.FileServer()`, `ioutil.ReadFile()`

### Deserialization

`encoding/gob.Decoder.Decode()` (type confusion), `encoding/json.Unmarshal()` into `interface{}` (type assertion bypass), `yaml.Unmarshal()` with custom types, `protobuf` with reflection-based field access

### Template Injection

`text/template.Execute()` (no auto-escaping — use `html/template` instead), `html/template` with `.JS`, `.URL`, `.CSS` types bypassing escaping, `template.FuncMap` with dangerous functions registered

### Additional Go Sinks

- **XXE:** Go's `encoding/xml` is safe by default (no external entity processing), but third-party XML libraries (`libxml2` bindings) may be vulnerable
- **LDAP:** `go-ldap/ldap` `Search()` with unsanitized filter strings
- **Crypto:** `crypto/rand` vs `math/rand` (math/rand is predictable), `crypto/md5` / `crypto/sha1` for password hashing

---

## Rust Sinks

### RCE

`std::process::Command::new()`, `std::process::Command::arg()` with unsanitized input, shell invocation via `Command::new("sh").arg("-c").arg(user_input)`

**Indirect RCE:**
`libloading::Library::new()` (dynamic library loading), `dlopen` via FFI, `std::ffi` for C interop with unsafe blocks, `eval` crates (e.g., `rhai`, `rlua`, `mlua`) executing user-provided scripts

### SQLi

`sqlx::query()` with `format!()` interpolation, `diesel::sql_query()` with string concat, `rusqlite::Connection::execute()` with format strings, `tokio-postgres` `client.query()` with string building, `sea-orm` `Statement::from_string()` with user input

### Path Traversal

`std::fs::read_to_string()`, `std::fs::File::open()`, `std::path::Path::join()` (does NOT prevent `..`), `tokio::fs::read()`, `actix-files::NamedFile::open()` without path validation

### Deserialization

`serde_json::from_str()` into `serde_json::Value` (type confusion), `bincode::deserialize()` (memory safety in unsafe contexts), `serde_yaml::from_str()`, `rmp-serde` (MessagePack), `ciborium` (CBOR) — Rust memory safety prevents many deser attacks but logic bugs remain

### SSRF

`reqwest::get()`, `reqwest::Client::get()`, `hyper::Client::get()`, `ureq::get()`, `surf::get()`, `isahc::get()`

### Template Injection

`tera::Tera::render()` with user-controlled template strings, `askama` (compile-time templates — generally safe), `handlebars-rust` with user-registered helpers, `liquid` templates from user input

### Additional Rust Sinks

- **Unsafe blocks:** `unsafe { }` with user-influenced pointer arithmetic, buffer indexing, or FFI calls
- **Integer overflow:** debug mode panics, release mode wraps — `wrapping_add()` vs checked arithmetic
- **Format string:** `format!()` is safe (compile-time checked), but `log::info!("{}", user_controlled_format_string)` can leak info if format string is tainted

---

## C/C++ Sinks

Moved to the dedicated source-level catalog: **`references/sinks/c-cpp.md`** — buffer-write sinks,
object lifecycle (UAF / NULL / uninit / leak), integer & type confusion, syscall / `errno` / `EINTR`,
concurrency & TOCTOU, ambient-state (privilege-drop / env / path), C++ semantics, Windows userspace,
CERT-C category mappings, and the threat-model gate. For compiled binaries / firmware / kernel use
`references/binary/binary-stack-triggers.md` instead.

---

## Elixir/Erlang Sinks

### RCE

`System.cmd()`, `Port.open()` with `:spawn` or `:spawn_executable`, `:os.cmd()` (Erlang), `Code.eval_string()`, `Code.eval_quoted()`, `Code.compile_string()`, `:erlang.apply/3` with tainted module/function, `EEx.eval_string()` (template evaluation)

### SQLi

Ecto `fragment()` with string interpolation, `Ecto.Adapters.SQL.query()` with string concat, raw SQL via `Repo.query()` with user input

### SSTI

`EEx.eval_string(user_input)` (Embedded Elixir templates), `Solid.parse(user_input)` (Liquid templates in Elixir)

### Deserialization

`:erlang.binary_to_term()` (Erlang Term Format — can instantiate arbitrary atoms, exhaust atom table, or trigger function calls), `Plug.Crypto.non_executable_binary_to_term()` is the safe alternative, `ETF` over distribution protocol (Erlang clustering)

### File Operations

`File.read()`, `File.write()`, `File.stream!()`, `Path.expand()` with user input, `Path.join()` without sanitization (allows `..`)

### SSRF

`HTTPoison.get()`, `Tesla.get()`, `Finch.request()`, `Req.get()`, `:httpc.request()` (Erlang), `Mint.HTTP.connect()`

### Additional Elixir/Erlang Sinks

- **Atom exhaustion:** `String.to_atom(user_input)` (atoms are never garbage collected — DoS via atom table overflow; use `String.to_existing_atom()`)
- **Distribution protocol:** Erlang distribution uses a shared cookie for auth — if cookie is leaked/weak, full RCE on any node in the cluster
- **Phoenix-specific:** `Phoenix.Controller.redirect(conn, external: user_input)` (open redirect), `raw()` in templates (XSS)
