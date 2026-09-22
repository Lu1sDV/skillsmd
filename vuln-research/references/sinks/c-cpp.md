# C/C++ Sinks & Memory-Safety Bug Classes

> Source-level C/C++ review catalog, distilled from the Trail of Bits Testing Handbook
> (`appsec.guide/docs/languages/c-cpp/`) and the ToB `c-review` cluster taxonomy. Covers what
> `sinks/systems.md` only sketches: the granular memory-safety, arithmetic, syscall, concurrency,
> and platform-specific bug classes a native-code audit must walk.
>
> **Representative, not exhaustive** (house doctrine): a "sink" is any operation that does
> something dangerous with attacker-influenced data or state — listed or not. Custom wrappers
> (`safe_copy()` → `memcpy`) defeat name matching; prefer graph-discovered reach
> (`reachableByFlows`) with this catalog as one seed.
>
> **For compiled binaries / firmware / kernel** load `references/binary/binary-stack-triggers.md`
> instead — this file is **source-level** C/C++. **For Linux/Windows kernel drivers** neither
> applies in full; treat the syscall/concurrency rows as starting points only.

## Normalization — how C/C++ findings land in DuckDB

This file is **knowledge**, not an output sink. Every callsite it helps you find is recorded the
normal way: the orchestrator (sole writer) flushes candidate `sinks` rows (with `evidence_path` /
`evidence_line`) and, when a source→sink DAG closes, candidate `gr_findings` rows. A memory-safety
crash reproduced under a sanitizer enters as `gr_findings(finding_kind='fuzz_crash')` via the
`boundary_fuzz_lane` contract (`references/v2/fuzzing-lane.md`) — G4 is satisfied by the
reproducer + sanitizer report. No bug class here promotes to `confirmed` without the five-gate
Confirm. Subagents emit row-shaped events; they never write files.

---

## Cluster 1 — Buffer write sinks (spatial memory safety)

| Sink / pattern | Why it's dangerous |
|---|---|
| `strcpy`, `strcat`, `sprintf`, `gets`, `scanf("%s")` | No bound — classic overflow. Banned-function list. |
| `memcpy`, `memmove`, `memset` with attacker-influenced length | OOB write if length unchecked or computed by overflowing arithmetic. |
| `strncpy` / `strncat` / `snprintf` | NUL-termination traps: `strncpy` does not terminate on truncation; `strncat`'s n is *remaining* space not buffer size; `snprintf` returns *would-have-written* length (use it as an index → OOB). |
| `strlen` on non-terminated buffer | Reads past the buffer; pair with the `strcpy` that produced it. |
| Overlapping `memcpy` source/dest | UB; silent corruption. |
| Flexible array members / trailing VLAs | Size computed from a tainted header field → undersized allocation, then full-size write. |
| `alloca` / VLA with tainted size | Stack exhaustion / stack clash. |

Always check the **size source** and the **termination guarantee**, not just the call.

## Cluster 2 — Object lifecycle (temporal memory safety)

- **Use-after-free** — pointer used after `free`; double-free; UAF via dangling iterator/reference; free in error path then fall through.
- **NULL deref** — unchecked `malloc`/`calloc`/`realloc` return; `realloc` returning NULL leaking the original; function returning NULL on error path the caller ignores.
- **Uninitialized data** — stack struct used before all fields set; partial init then read; `realloc` growth region not zeroed.
- **Memory leaks** — error-path early return before `free`; ownership ambiguity across API boundary. (For C/C++, leaks are a **first-class fuzz objective** — enable LSan; see `fuzzing-lane.md`.)

## Cluster 3 — Arithmetic & type

- **Integer overflow / underflow** — `size = count * width` wrapping → undersized alloc → heap overflow. Signed overflow is UB. `int` truncation on assignment to `short`/`char`.
- **Signed/unsigned confusion & OOB comparisons** — `if (len < size)` with mixed signedness; negative `int` promoted to huge `size_t` in an allocation or `memcpy`.
- **NULL/zero conflation** — `0` used where `NULL` or sentinel meant; `memset` length vs value swapped.
- **Type confusion** — `union` punning on tainted tag; `void*` cast to wrong struct; C++ `reinterpret_cast` / `static_cast` down a wrong hierarchy.
- **Operator precedence / UB** — `a & b == c`, shift by ≥ width, `*p++` ambiguity, strict-aliasing violations, UB the compiler may delete (e.g. removed null/overflow checks).

## Cluster 4 — Syscall & libc return values

- Ignored / mis-handled return: `read`/`write` partial returns, `open`/`socket` returning `-1`, `malloc` NULL.
- **`errno`** read without checking the call failed, or clobbered by an intervening call before use.
- **`EINTR`** — blocking syscall not retried on signal interruption.
- **Negative return as length** — `read()`'s `-1` fed into a `size_t` buffer index.
- **Socket lifecycle** — half-closed / disconnected peer; `recv` returning 0 (orderly shutdown) treated as data.

## Cluster 5 — Concurrency

- **Race conditions / TOCTOU** — check-then-use on shared state or filesystem (`access()` then `open()`; `stat` then operate).
- **Thread safety** — shared mutable state without a lock; non-reentrant libc (`strtok`, `localtime`, static buffers) across threads.
- **Signal-handler safety** — non-async-signal-safe calls (`malloc`, `printf`) in a handler; `volatile sig_atomic_t` not used for flags.
- **Spinlock / mutex init** — used before init; double-init; init-order across translation units.

## Cluster 6 — Ambient state

- **Path / filesystem** — traversal via tainted path; symlink following; world-writable temp (`tmpfile` races, predictable `mktemp`); umask assumptions.
- **Privilege drop** — `setuid`/`setgid`/`setgroups` ordering and unchecked return (drop *supplementary* groups first; verify the drop took).
- **Environment** — `getenv` trusted for paths (`PATH`, `LD_*`, `IFS`) before exec; `system`/`popen` with env-influenced command.
- **DoS** — unbounded allocation / recursion driven by a tainted count or depth; algorithmic complexity (hash flooding, quadratic parse).

## Cluster 7 — Static hygiene

- **Exploit mitigations** — missing `_FORTIFY_SOURCE`, stack canaries, RELRO, PIE; these are not bugs but they gate exploitability — record as `defenses`.
- **`printf` family** — non-literal format string (`printf(user)`), missing `__attribute__((format))`, arg/spec count mismatch.
- **`va_start`/`va_end`** — unbalanced; reading more args than passed.
- **Misc libc traps** — `inet_aton`/`inet_addr` return semantics, `qsort` comparator returning `a-b` (overflow), `regcomp` not freed / catastrophic backtracking.

## Cluster 8 — C++ semantics (when `is_cpp`)

- **Static init order fiasco** — cross-TU global dependency.
- **Virtual functions** — call during ctor/dtor; missing virtual dtor on a base used polymorphically; vtable type confusion.
- **Smart pointers** — `unique_ptr` double-managed raw pointer; `shared_ptr` cycles (leak) and cross-thread refcount races; `weak_ptr` lock not checked.
- **Move semantics** — use-after-move; self-move; moved-from object read.
- **Iterator / reference invalidation** — mutating a container (`push_back`, `erase`) while holding an iterator/reference/pointer into it.
- **Lambda captures** — capture-by-reference of a local that outlives the lambda (dangling); `this` captured then object destroyed.
- **Exception safety** — leak on throw between alloc and ownership transfer; throwing dtor; partial state on exception.

## Cluster 9 — Windows userspace (when `is_windows`)

This is the surface `sinks/systems.md` omits entirely.

- **Process creation** — `CreateProcess` with an unquoted path containing spaces (binary planting); search-order hijack; `lpCommandLine` injection.
- **DLL planting / search order** — `LoadLibrary` without a full path; missing `SetDefaultDllDirectories`; current-dir on the search path.
- **Path handling** — `\\?\` long-path and device-namespace tricks; `8.3` short names; trailing-dot/space normalization; canonicalization before vs after a check.
- **Installer / TOCTOU races** — writable intermediate dir during elevated install; symlink/junction redirection.
- **Token & privilege** — impersonation not reverted; `SeImpersonatePrivilege` abuse; missing `ImpersonateLoggedOnUser` return check; integrity-level confusion.
- **Service security** — weak service ACL (reconfigurable by non-admin); unquoted `ImagePath`; insecure `ServiceDacl`.
- **Named pipes / IPC** — missing `PIPE_REJECT_REMOTE_CLIENTS`; no client impersonation guard; predictable pipe name → squatting.
- **Crypto / RNG** — `rand()` for secrets; deprecated CryptoAPI; hardcoded keys/IVs.
- **Allocators** — `HeapAlloc`/`LocalAlloc` size arithmetic; mixing allocator families on free.

## Detection signatures (feed the tool layer)

| Bug class | Cheap signal | 0xdea rule IDs | Better signal |
|---|---|---|---|
| Buffer overflow | grep banned-function list | `raptor-insecure-api-gets` (E), `raptor-insecure-api-strcpy-strcat` (W), `raptor-insecure-api-sprintf-vsprintf` (W), `raptor-off-by-one` (W), `raptor-write-into-stack-buffer` (W) | CodeQL `cpp/Security/CWE-120`; ASan crash |
| Format string | `printf\s*\([^"]` non-literal first arg | `raptor-format-string-bugs` (E) | CodeQL CWE-134 |
| Use-after-free / double-free | manual lifetime trace | `raptor-use-after-free` (E), `raptor-double-free` (E), `raptor-incorrect-use-of-free` (E) | ASan UAF; CodeQL CWE-416; Joern reach |
| Integer overflow / truncation | `\*\s*\w+\s*\)` in alloc size | `raptor-integer-wraparound` (W), `raptor-integer-truncation` (W), `raptor-signed-unsigned-conversion` (W), `raptor-unsafe-strlen` (W) | UBSan `-fsanitize=integer`; CodeQL CWE-190 |
| TOCTOU / race | `access(` … `open(` proximity | `raptor-insecure-api-access-stat` (W), `raptor-insecure-api-mktemp-tmpnam-tempnam` (W) | manual; no reliable static signal |
| Command injection | `system\(` / `popen\(` | `raptor-command-injection` (E) | CodeQL CWE-78; taint trace |
| Privilege drop order | `setuid`/`setgid` call sites | `raptor-incorrect-order-setuid-setgid` (E), `raptor-unchecked-ret-setuid-seteuid` (W) | manual ordering check |
| Memory leak | — | `raptor-unchecked-ret-malloc` (W), `raptor-ret-stack-address` (W) | LSan / Valgrind on fuzz corpus |
| Candidate-point map | `raptor-interesting-api-calls` (W) — full dangerous-API sweep | → candidate `sinks` rows; slice for reachability | — |

Severity key: **E** = ERROR (Tier 1 / quick wins), **W** = WARNING (Tier 2 / recommended).
Full rule catalog and invocation: `references/methodology/0xdea-semgrep-rules.md`.

Run order per `references/phases/tool-integration-matrix.md`: Joern/CPG → CodeQL → Semgrep
(`p/c`, `p/cpp`, **0xdea** (`references/methodology/0xdea-semgrep-rules.md`) and **Trail of Bits**
packs — both carry vuln-research-grade C/C++ rules the official packs miss) + ast-grep → grep.
Ingest every hit as a `candidate` via `references/methodology/tool-ingest-recipes.md` §2 and §2.1.
Dynamic confirmation is the `boundary_fuzz_lane` job (`references/v2/fuzzing-lane.md`) — harness
the parser/FFI/decoder boundary, fuzz under ASan/UBSan/MSan/LSan, record the crash as a
`fuzz_crash` finding.

## Threat-model gate (borrowed from c-review)

Before chasing a class, fix the threat model — it prunes the catalog:

- **REMOTE** (network-reachable, attacker not on host): privilege-drop, env-var, and local-race
  classes are usually out of scope; buffer/arithmetic/parser classes are in.
- **LOCAL_UNPRIVILEGED** (attacker has a local account): TOCTOU, symlink, env, privilege-drop,
  service/pipe ACLs are in scope.
- Record the chosen model in the audit's `agent_observations` so a skipped class reads as a
  documented decision, not a silent omission.
