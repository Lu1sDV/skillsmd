# Sinks Catalog — Language Router + SAST/DAST Integration

Load the file matching the target codebase language. **Do not load all language files at once.**

| Language | File | Key Sink Categories |
|----------|------|---------------------|
| **PHP** | `sinks/php.md` | exec, callbacks, type juggling, magic hashes, disable_functions bypass, phar deser, file ops |
| **Python** | `sinks/python.md` | exec, pickle, SSTI, subprocess, SSRF |
| **Node.js / JavaScript** | `sinks/javascript.md` | child_process, prototype pollution, deser, NoSQL injection, ReDoS |
| **Java** | `sinks/java.md` | Runtime exec, JNDI, deser (ysoserial + format-specific), SpEL/OGNL/EL |
| **Ruby** | `sinks/ruby.md` | system/eval, Marshal/YAML deser, ActiveRecord SQLi, Kernel.open |
| **.NET / C#** | `sinks/dotnet.md` | Process.Start, BinaryFormatter, Json.NET TypeNameHandling, ysoserial.net |
| **Go, Rust, C/C++, Elixir/Erlang** | `sinks/systems.md` | os/exec, Command, memory corruption, format strings, ETF deser, atom exhaustion |
| **Kotlin/Android, Swift/iOS** | `sinks/mobile.md` | WebView, intents, URL schemes, data storage, certificate pinning |

---

## SAST/DAST Integration Layer

### Semgrep Rules

| Language | Rule Pack | Key Rules |
|----------|-----------|-----------|
| PHP | `p/php` | `php.lang.security.eval-use`, `php.lang.security.exec-use`, `php.lang.security.file-inclusion`, `php.lang.security.unserialize-use` |
| Python | `p/python` | `python.lang.security.audit.exec-use`, `python.flask.security.injection`, `python.django.security.injection.sql`, `python.lang.security.deserialization.avoid-pickle` |
| Node.js | `p/javascript`, `p/typescript` | `javascript.lang.security.audit.vm-injection`, `javascript.express.security.injection`, `javascript.lang.security.eval-with-expression` |
| Java | `p/java` | `java.lang.security.audit.command-injection`, `java.lang.security.deserialization`, `java.spring.security.injection`, `java.lang.security.audit.jndi-injection` |
| Ruby | `p/ruby` | `ruby.lang.security.eval-use`, `ruby.rails.security.injection`, `ruby.lang.security.command-injection` |
| Go | `p/golang` | `go.lang.security.audit.command-injection`, `go.lang.security.audit.sql-injection`, `go.lang.security.audit.path-traversal` |
| Rust | `p/rust` | `rust.lang.security.command-injection`, `rust.lang.security.sql-injection` |
| C/C++ | `p/c` | `c.lang.security.buffer-overflow`, `c.lang.security.format-string`, `c.lang.security.use-after-free` |

**Custom taint rules:** `pattern-sources` -> `pattern-sinks` -> `pattern-sanitizers` in Semgrep YAML.

### Third-Party Semgrep Rule Packs

Community-maintained rule packs that catch vulnerabilities the official `p/` packs miss:

| Rule Pack | Repository | Focus Area | Key Differentiator |
|-----------|------------|------------|-------------------|
| **Trail of Bits** | `trailofbits/semgrep-rules` | Go, Python, JS, Rust, C | Smart contract security, crypto misuse, unsafe FFI, concurrency bugs — written by audit team with real-world exploit experience |
| **0xdea** | `0xdea/semgrep-rules` | C/C++, Java, PHP, Python, JS | Vuln research-oriented rules: format strings, integer overflows, use-after-free patterns, deserialization sinks missed by official packs |
| **Decurity** | `Decurity/semgrep-smart-contracts` | Solidity, Vyper | Smart contract vulnerabilities: reentrancy, access control, oracle manipulation — if auditing Web3 |

**Usage:**
```bash
# Run third-party rules alongside official packs
semgrep --config p/python --config "https://semgrep.dev/r/trailofbits.python" .
# Or clone and run locally
semgrep --config ~/semgrep-rules/python/ .
```

**When to use:** Always layer third-party packs on top of official `p/` packs during code audits. Official packs optimize for low FP rate (conservative); third-party packs from security researchers optimize for coverage (catch more true positives, accept higher FP rate).

### Semgrep Pro Cross-File Taint Analysis

Semgrep OSS performs single-file analysis only. **Semgrep Pro** (formerly Semgrep Supply Chain) adds cross-file and cross-function taint tracking:

- Traces taint across function calls, module imports, and class hierarchies — catches ~250% more true positives than OSS on real codebases
- Supports inter-procedural analysis: `source → function_a() → function_b() → sink` detected even when functions are in different files
- Critical for frameworks with request/handler separation (Express routes → controller → model, Django views → forms → ORM)
- **Limitation:** requires Semgrep Pro license; OSS users can approximate with manual cross-file grep but will miss complex data flows

**Practical implication for audits:** if running Semgrep OSS and finding few results, it does NOT mean the codebase is clean — it means single-file analysis couldn't trace the taint. Either upgrade to Pro or supplement with manual cross-file taint tracing from the sink files.

### CodeQL Query Packs

| Language | Pack | Key Queries |
|----------|------|-------------|
| PHP | `codeql/php-queries` | `Security/CWE-089` (SQLi), `Security/CWE-078` (OS cmd), `Security/CWE-079` (XSS), `Security/CWE-502` (deser) |
| Python | `codeql/python-queries` | `Security/CWE-089`, `Security/CWE-078`, `Security/CWE-094` (code injection), `Security/CWE-502` |
| JavaScript | `codeql/javascript-queries` | `Security/CWE-089`, `Security/CWE-078`, `Security/CWE-079`, `Security/CWE-1321` (proto pollution) |
| Java | `codeql/java-queries` | `Security/CWE-089`, `Security/CWE-078`, `Security/CWE-502`, `Security/CWE-611` (XXE), `Security/CWE-074` (JNDI) |
| Ruby | `codeql/ruby-queries` | `Security/CWE-089`, `Security/CWE-078`, `Security/CWE-079`, `Security/CWE-502` |
| Go | `codeql/go-queries` | `Security/CWE-089`, `Security/CWE-078`, `Security/CWE-022` (path traversal), `Security/CWE-918` (SSRF) |
| C/C++ | `codeql/cpp-queries` | `Security/CWE-120` (buffer overflow), `Security/CWE-134` (format string), `Security/CWE-416` (use-after-free) |

### SonarQube RSPEC References

| Vulnerability | RSPEC Rule |
|--------------|------------|
| SQL Injection | S3649 |
| OS Command Injection | S2076 |
| Path Traversal | S2083 |
| XSS | S5131 |
| XXE | S2755 |
| Deserialization | S5135 |
| SSRF | S5144 |
| LDAP Injection | S2078 |
| Code Injection | S5334 |
| Weak Crypto | S5547 |
| Insecure Random | S2245 |

### DAST Detection Signatures

| Vulnerability | Detection Pattern |
|--------------|-------------------|
| SQLi | Single quote error, UNION response diff, time-based delay (`SLEEP(5)`/`pg_sleep(5)`/`WAITFOR DELAY`), boolean blind (true/false page diff) |
| XSS | Reflected payload in response body, DOM source-to-sink trace, CSP report-uri triggers |
| SSRF | DNS callback (Burp Collaborator, interactsh), timing difference for internal vs external hosts, error message differences |
| XXE | OOB DNS/HTTP callback from entity resolution, error messages containing file contents |
| RCE | Time-based (`sleep 5`), DNS callback (`` `nslookup attacker.com` ``), file creation verification |
| Path Traversal | `/etc/passwd` content in response, `C:\Windows\win.ini` content, error messages revealing file paths |
| Deserialization | Specific error messages (Java `ClassNotFoundException`, PHP `unserialize` warnings), DNS callback from gadget chain |
