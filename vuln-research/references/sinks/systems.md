# Systems Language Sinks — Go, Rust, C/C++, Elixir/Erlang

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

### RCE / Command Injection

`system()`, `popen()`, `exec*()` family (`execl`, `execle`, `execlp`, `execv`, `execve`, `execvp`), `wordexp()` (performs shell expansion), `dlopen()` / `dlsym()` (load arbitrary shared objects)

### Memory Corruption (leading to RCE)

**Buffer overflow:** `gets()` (never use), `strcpy()`, `strcat()`, `sprintf()`, `scanf()` family without width limits, `memcpy()` with unchecked size, `read()` into fixed buffer

**Format string:** `printf(user_input)`, `fprintf()`, `sprintf()`, `snprintf()`, `syslog()` with user-controlled format — read/write arbitrary memory via `%n`, `%x`, `%s`

**Integer overflow:** `malloc(user_controlled_size)`, array index from user input without bounds check, signed/unsigned confusion in length calculations

**Use-after-free:** `free()` followed by continued use, double `free()`, dangling pointers after `realloc()`

**Heap exploitation:** `malloc()`/`free()` metadata corruption, tcache poisoning, fastbin attack, House of Force, unlink exploit

### File Operations

`fopen()`, `open()`, `stat()` + `open()` (TOCTOU race), `access()` + `open()` (TOCTOU), `mktemp()` (predictable, use `mkstemp()`), `tmpnam()` (predictable), `realpath()` without post-check, `symlink()` / `link()` for symlink attacks

### SQLi

`sqlite3_exec()` with string concat, `mysql_query()` with `sprintf()`, `PQexec()` (libpq) with string building

### Additional C/C++ Sinks

- **Crypto:** `rand()` / `srand()` (predictable PRNG), `DES_ecb_encrypt()` (weak), `MD5()` / `SHA1()` for passwords
- **Race conditions:** `signal()` handlers with non-async-signal-safe functions, `fork()` + `exec()` without proper fd closing
- **Type confusion:** `void*` casts, union type punning, C++ `dynamic_cast` failing silently with `static_cast`

### CERT C Secure Coding Rules — Sinks by Category

Cross-reference for static-analysis triage. Rule IDs match the SEI CERT C Coding Standard; pair with CodeQL / Clang-Tidy / cppcheck / Coverity rule packs of the same name.

**COMMAND-INJECTION**
- ENV33-C: Do not call `system()`
- `system()` / `popen()`

**CRYPTO**
- MSC30-C: Do not use `rand()` for pseudorandom numbers
- MSC32-C: Properly seed PRNGs
- `rand()` / `srand()`

**ENVIRONMENT**
- ENV30-C: Do not modify the object referenced by the return value of certain functions
- ENV31-C: Do not rely on an environment pointer following an operation that may invalidate it
- ENV34-C: Do not store pointers returned by certain functions
- `getenv()` / `putenv()` / `setenv()`
- `strerror()` / `asctime()` / `tmpnam()` / `ctime()` — static buffer pointers

**FILE-IO**
- FIO32-C: Do not perform operations on devices that are only appropriate for files
- FIO34-C: Distinguish between characters read from a file and `EOF` / `WEOF`
- FIO37-C: Do not assume `fgets()` / `fgetws()` returns a nonempty string when successful
- FIO38-C: Do not copy a `FILE` object
- FIO39-C: Do not alternately input and output from a stream without an intervening flush or positioning call
- FIO40-C: Reset strings on `fgets()` / `fgetws()` failure
- FIO41-C: Do not call `getc()` / `putc()` / `getwc()` / `putwc()` with a stream argument that has side effects
- FIO42-C: Close files when they are no longer needed
- FIO44-C: Only use values for `fsetpos()` that are returned from `fgetpos()`
- FIO46-C: Do not access a closed file
- File operations on device files; `FILE` object copying; `fclose()` — close and re-use; `fsetpos()` with externally-supplied position

**FORMAT-STRING**
- FIO30-C: Exclude user input from format strings
- FIO47-C: Use valid format strings
- Uncontrolled format strings (`syslog`, `err`, `warn`); `printf()` / `fprintf()` / `vprintf()` with user-controlled format; format-specifier semantics

**INTEGER-OVERFLOW**
- INT30-C: Ensure unsigned integer operations do not wrap
- INT31-C: Ensure integer conversions do not lose or misinterpret data
- INT32-C: Ensure signed-integer operations do not overflow
- INT33-C: Ensure division / remainder operations do not divide by zero
- INT34-C: Do not shift by a negative number of bits or by `>= width`
- INT35-C: Use correct integer precisions
- INT36-C: Converting a pointer to integer or integer to pointer
- STR34-C: Cast characters to `unsigned char` before converting to larger integer sizes
- Integer arithmetic — overflow / wrap / truncation; pointer ↔ integer conversion; signed-char sign-extension

**MEMORY-CORRUPTION**
- ARR30-C / ARR32-C / ARR36-C / ARR37-C / ARR38-C / ARR39-C: out-of-bounds pointers/subscripts, VLA size ranges, pointer arithmetic across arrays, scaled-integer pointer arithmetic, invalid library-formed pointers
- DCL30-C: Declare objects with appropriate storage durations
- DCL38-C: Correct syntax for flexible array members
- EXP33-C: Do not read uninitialized memory
- EXP34-C: Do not dereference null pointers
- EXP36-C: Do not cast pointers into more strictly aligned pointer types
- EXP39-C: Do not access a variable through a pointer of an incompatible type
- EXP40-C: Do not modify constant objects
- EXP43-C: Avoid UB with `restrict`-qualified pointers
- MEM30-C / MEM31-C / MEM33-C / MEM34-C / MEM35-C / MEM36-C: use-after-free, memory leak, flexible-array-member alloc, `free()` on non-heap, under-allocation, `realloc()` alignment
- MSC33-C: `asctime()` with unvalidated `struct tm`
- MSC37-C: Non-void function must not fall off the end
- MSC39-C: Do not call `va_arg()` on an indeterminate `va_list`
- STR30-C / STR31-C / STR32-C / STR38-C: modify string literals, insufficient storage, non-terminated sequences, narrow/wide confusion
- `gets()` / `gets_s()`, `strcpy()` / `strcat()`, `strncpy()` / `strncat()`, `scanf()` family without width, `memcpy()` / `memmove()` / `memset()` with unchecked size, `malloc()` / `calloc()` / `realloc()` unchecked return, `free()` double-free / UAF, `asctime()` with unvalidated `struct tm`, `va_arg()` misuse

**MEMORY-CORRUPTION + FORMAT-STRING**
- `sprintf()` / `vsprintf()`

**RACE-CONDITION**
- CON30-C … CON41-C: TSS cleanup, lock-held mutex destruction, bit-field races, races when using library functions, shared-object storage duration, lock ordering, spurious-wake loops, condition-variable thread safety, double join/detach, repeated atomic reference in one expression, spurious-failure retry loops
- FIO45-C: TOCTOU on file access
- SIG31-C: No shared-object access in signal handlers
- SIG34-C: No `signal()` inside interruptible handlers
- Concurrency — mutex and thread primitives

**RACE-CONDITION + PATH-TRAVERSAL**
- TOCTOU — file existence check then open

**SIGNAL-UNSAFE**
- CON37-C: Do not call `signal()` in a multithreaded program
- SIG30-C: Call only async-signal-safe functions in handlers
- SIG35-C: Do not return from a computational-exception signal handler
- `signal()` — non-async-safe functions in handler

**STRING-MANIPULATION**
- Narrow / wide character-string confusion (see STR38-C)

**OTHER (correctness / UB / portability — worth triaging but rarely direct sinks)**
- DCL31-C / DCL36-C / DCL37-C / DCL39-C / DCL40-C / DCL41-C: declaration/linkage/reserved-identifier/trust-boundary/switch-case-label rules
- ENV32-C: Exit handlers must return normally
- ERR30-C / ERR32-C / ERR33-C: `errno` zeroing and checking, indeterminate `errno`, unhandled stdlib errors
- EXP30-C / EXP32-C / EXP35-C / EXP37-C / EXP42-C / EXP44-C / EXP45-C / EXP46-C: side-effect order, volatile-through-nonvolatile, temp-lifetime modify, wrong arg count/type, padding compare, `sizeof`/`_Alignof`/`_Generic` side effects, assignment in selection stmt, bitwise on Boolean
- FLP30-C / FLP32-C / FLP34-C / FLP36-C / FLP37-C: FP loop counters, domain/range errors, FP conversions in range, integral→FP precision, object-representation FP compare
- MSC38-C / MSC40-C: predefined-as-object, constraint violations
- PRE30-C / PRE31-C / PRE32-C: concatenated universal character name, side effects in unsafe macros, preprocessor directives inside function-like macro invocation
- STR37-C: character-handling function arg must be representable as `unsigned char`
- `exit()` handlers — `longjmp` / exceptions

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
