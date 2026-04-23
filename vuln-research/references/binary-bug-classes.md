# Binary Code Analysis — Part 2: Dynamic Analysis, Fuzzing & Bug Classes

> Load when you have triaged the target (see `binary-triage-and-re.md`) and now need to **find bugs** — running dynamic analysis, writing fuzz harnesses, applying bug-class checklists, and shaping a binary-level taint DAG.
>
> Paired files:
> - `binary-triage-and-re.md` — mode selection, triage, formats/arch quick-ref, toolchain, static RE.
> - `binary-exploit-and-specialties.md` — patch diffing, firmware/kernel/driver specialties, exploitation primitives, anti-analysis, mitigations, output format.
> - `binary-code-analysis.md` — thin index that routes triggers to one of the three files.

---

## Table of Contents

5. [Dynamic Analysis & Fuzzing](#dynamic-fuzzing)
6. [Memory Corruption Bug Classes](#memory-corruption)
7. [Concurrency Bugs at the Machine Level](#concurrency-binary)
8. [Integer, Type, and Sign Bugs](#integer-bugs)
9. [Uninitialized Memory & Info Leaks](#uninit-leaks)
10. [Binary-Level Taint Framework](#binary-taint)
15. [Gotchas — Things Source Audit Misses](#gotchas)

---

<a id="dynamic-fuzzing"></a>
## 5. Dynamic Analysis & Fuzzing

Static RE shows what the binary *might* do; dynamic analysis shows what it does. Use both.

### Minimal dynamic loop

```bash
# 1. Reproduce normal operation under a debugger
gdb -ex 'run --config ./normal.conf' ./target

# 2. Observe the interesting syscalls
strace -f -e trace=network,file,signal,process -o trace.log ./target
ltrace -f -o ltrace.log ./target
perf trace -e 'syscalls:*' ./target    # richer, cgroup-aware

# 3. Trace memory operations
valgrind --tool=memcheck --track-origins=yes --num-callers=50 ./target
valgrind --tool=helgrind ./target   # data races
valgrind --tool=drd     ./target    # alternative race detector

# 4. With sanitizers (requires rebuild or suitable binary)
ASAN_OPTIONS=abort_on_error=1:halt_on_error=1:detect_leaks=1 ./target
UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1 ./target
TSAN_OPTIONS='history_size=7 second_deadlock_stack=1' ./target
```

### Fuzzing harness checklist

1. **Pick the smallest reachable entry.** Fuzz the parser, not `main`. Expose it via a `LLVMFuzzerTestOneInput` shim.
2. **Make the harness deterministic.** No network, no time-based branches, no `/dev/urandom` without seeding.
3. **Instrument.** libFuzzer / AFL++ require SanitizerCoverage; closed-source → Jackalope, WinAFL, or FRIDA-based fuzzers (Frida-Fuzzer, FuzzBench's indirect mode).
4. **Seed from reality.** Use actual corpora (public capture files, sample docs, golden test inputs) not synthetic minimized inputs.
5. **Start with ASan + UBSan.** Heap corruption + integer UB catches 80% of C/C++ bugs cheaply. Add MSan only if ASan is clean.
6. **Measure coverage, not just crashes.** `llvm-cov show` or Lighthouse. Stalled coverage → dictionary, structure-aware mutators, grammar fuzzers (Nautilus, Grammarinator).
7. **Triage crashes with `creduce` / `llvm-reduce`.** Never attach an unreduced 2 MB reproducer to a report.
8. **Prefer in-process fuzzing where possible.** 1000× throughput vs. fork-exec.

### Structure-aware fuzzing

Raw-bytes fuzzing is weak for structured inputs (PDF, X.509, protobuf, DNS, media codecs). Use:

- `libprotobuf-mutator` for protobuf / JSON / YAML
- **Nautilus** or **Grammarinator** for CFG-based grammars
- **Fuzzilli** for JavaScript engines
- **FuzzGen** for library API sequences
- Custom mutators via `LLVMFuzzerCustomMutator`

### When fuzzing is the wrong tool

- Logic / auth bugs
- State-dependent bugs across long sessions (unless harness exposes state as fuzz input)
- Cryptographic correctness bugs (use differential testing + Wycheproof)
- Algorithmic complexity / ReDoS (use targeted input generation)

---

<a id="memory-corruption"></a>
## 6. Memory Corruption Bug Classes

Each class is characterized by a **primitive** (what you get) and a **detection signature** (what to look for statically and dynamically).

### 6.1 Stack buffer overflow

- **Primitive:** Overwrite saved return address, saved frame pointer, adjacent locals, stack cookies (if bypassable), exception records.
- **Static tells:** `strcpy`, `strcat`, `sprintf`, `gets`, `scanf("%s")`, `memcpy(local_buf, user, user_len)`, `read(fd, local_buf, huge_const)`.
- **Decompiler tells:** stack frame with large `char buf[N]`, followed by unchecked length copy using a user-controlled length.
- **Mitigations to consider:** Stack canaries (`__stack_chk_fail`), ASLR/PIE, NX, Intel CET / shadow stacks, ARM BTI + PAC.
- **Dynamic detection:** ASan (SEGV + "stack-buffer-overflow"), Valgrind, fortify-source runtime aborts.

### 6.2 Heap buffer overflow

- **Primitive:** Overwrite adjacent heap chunks, chunk metadata, vtable pointers in adjacent objects, tcache/fastbin pointers.
- **Static tells:** `malloc(user_size)` followed by `memcpy(buf, user, other_size)`, off-by-one in loop bounds, wrong allocator pair (`new[]` freed with `delete`), double-allocation without zeroing.
- **Allocator matters:** glibc ptmalloc, musl, jemalloc, tcmalloc, Windows LFH/segment heap, macOS nano-zone — the exploitation primitives differ per allocator.
- **Detection:** ASan is best. For production binaries without sanitizers: electric fence, GWP-ASan, scudo.

### 6.3 Use-after-free (UAF)

- **Primitive:** Read/write a freed object; if attacker can reallocate the slot with controlled data, this gives arbitrary read/write or vtable hijack.
- **Static tells:** `free(obj); ...; obj->field`, `delete p; ...; p->method()`, callback fires after cleanup, references held across async boundaries, stale weak pointers promoted back to strong.
- **Refcount UAF:** Double-release, release on error path, missing AddRef on assignment — audit any hand-rolled refcount.
- **Detection:** ASan (`heap-use-after-free`). For kernel UAF: KASAN + KFENCE.

### 6.4 Double free

- **Primitive:** Corrupt allocator metadata → arbitrary write.
- **Static tells:** Two `free()` paths sharing a pointer without nulling, copy constructor that re-releases, error paths that free then continue.
- **Detection:** ASan, libc's own `double free or corruption` abort, Windows heap `HEAP_VALIDATE_PARAMETERS`.

### 6.5 Type confusion

- **Primitive:** Access object as wrong class → reads/writes land on wrong fields; if a method is dispatched, vtable hijack.
- **Static tells:** `reinterpret_cast`, C-style `(Foo*)` on polymorphic input, unchecked `dynamic_cast`-style tag dispatch, union member accessed without tag check, `std::variant` access via wrong alternative.
- **Classic context:** Browser engines (SpiderMonkey, V8, WebKit), JIT engines, scripting VMs, protocol parsers that reuse a tagged struct.
- **Detection:** HWASan + UBSan `vptr` + LLVM CFI (runtime type checking).

### 6.6 Out-of-bounds read

- **Primitive:** Leak data → bypass ASLR, disclose heap metadata, cookie, session keys.
- **Static tells:** `memcpy(out, buf, user_len)` with insufficient bound, wide char bounds confused with byte bounds, loop that walks past `\0` terminator, `read` that doesn't check return value.
- **Detection:** ASan (`heap-buffer-overflow READ`), page-boundary canaries.

### 6.7 Format string bug

- **Primitive:** Arbitrary read (`%s`, `%x`), arbitrary write (`%n`, `%hn`, `%hhn`).
- **Static tells:** `printf(user)`, `fprintf(stderr, user)`, `syslog(prio, user)`, `snprintf(buf, n, user)` — any `*printf` family where the format argument is attacker-controlled.
- **Gotcha:** glibc's `%n` may be disabled via `_FORTIFY_SOURCE` or `SELINUX_PRINTF_DISABLE` — verify before exploiting.
- **Detection:** `-Wformat -Wformat-security` catches static cases; UBSan and runtime format-string protection for dynamic.

### 6.8 Missing bounds check on user-supplied index

- **Primitive:** Out-of-bounds read/write scaled by sizeof(element).
- **Static tells:** `array[user_idx]` where `user_idx` arrived unchecked, negative index via signed-unsigned confusion, truncation from `size_t` to `int`.
- **Decompiler hint:** Look for the absence of a comparison on the path from input to dereference.

### 6.9 Command injection via `execve`/`system`/`popen` (native)

- Treat as the source-side sink, but verify with binary: `strings` shows `/bin/sh -c`, imports include `system`, `execve`, `posix_spawn`. Decompile the call site to confirm arguments include attacker-controlled substrings concatenated into a command string.

---

<a id="concurrency-binary"></a>
## 7. Concurrency Bugs at the Machine Level

Source-level race audits miss everything the compiler and hardware add: reorderings, non-atomic word writes, signal delivery mid-instruction, weak memory models. Binary audit catches these.

### 7.1 Data races

- **Primitive:** Non-deterministic state; in C/C++ data races are **undefined behavior**, so the compiler may generate code that "appears correct" but becomes wrong after a later optimization pass.
- **Static tells in the binary:** Shared global (`.data`/`.bss`) accessed from functions invoked by different thread entrypoints (`pthread_create`, `std::thread`, `CreateThread`, Grand Central Dispatch blocks). No `LOCK` prefix on x86 RMW. No `DMB`/`DSB`/`acquire`/`release` fences on ARM.
- **Detection:** **ThreadSanitizer** (TSan) is the only low-false-positive tool. Helgrind and DRD are usable fallbacks for unmodified binaries.
- **Unique binary findings:** Torn writes on misaligned 64-bit variables on 32-bit architectures; `volatile` used as a lock substitute; compiler-elided checks that source inspection assumed were atomic.

### 7.2 TOCTOU — syscall and filesystem

- **Primitive:** Race between check and use on a resource an attacker can swap (`open` after `access`, `stat` + `open` on a path with a removable component, `ptrace` attach between `fork` and `exec`).
- **Binary tells:** Consecutive syscalls `access → open`, `stat → chown`, `lstat → open`, `readlink → open`, or any `<check> <path>; <use> <path>` pair where `<path>` contains a directory the attacker controls.
- **Correct pattern:** `openat(dirfd, file, O_NOFOLLOW | O_CLOEXEC)` then `fstat` on the fd. Never re-resolve the path after the check.
- **Also:** Double-fetch from user space in kernel code — kernel reads the same userland pointer twice and the user changes it in between. KASAN does not catch this; use KCSAN + targeted tests.

### 7.3 Signal-handler re-entrancy

- **Primitive:** Signal interrupts non-async-signal-safe code → corrupted allocator state → exploitable.
- **Binary tells:** `signal()` / `sigaction()` installs a handler; handler body calls `malloc`, `printf`, `syslog`, `longjmp` without `sigsetjmp`, touches shared non-`sig_atomic_t` globals, or re-enters the allocator.
- **SIGALRM + longjmp** is a classic — see CVE-2006-5051 (OpenSSH signal race).
- **Detection:** Manual audit of every handler + `LD_PRELOAD` shim that checks async-signal-safety. No generic tool catches this well.

### 7.4 Compiler reorderings and weak memory

- **ARMv8, Power, RISC-V:** Weakly ordered — stores may become visible out of program order to other cores. Source-level "first set flag, then write data" can execute as "write data, then set flag" in binary.
- **Binary tells:** Absence of `dmb ish` / `lwsync` / `fence` between the producer's data write and flag write; consumer lacks `dmb ish` / `lwsync` / `fence` between flag read and data read.
- **x86:** Strong ordering covers most cases but **StoreLoad** still requires `mfence` or `lock`-ed op.
- **Audit rule:** Any lock-free code on non-x86 is a review target. On x86, focus on seqlocks, lock-free queues, and RCU implementations.

### 7.5 `volatile` as synchronization

Almost always wrong. `volatile` prevents the compiler from caching the variable in a register but provides **no** inter-thread ordering, no atomicity. Binary tell: concurrent code with `volatile` and no `LOCK` prefix / memory barrier → race.

### 7.6 Double-checked locking without atomics

Classic broken pattern. Only safe with C++11 `std::atomic` with explicit ordering, or C11 `_Atomic`, or platform primitives (`__atomic_*`, `Interlocked*`). Binary tell: two loads of a singleton pointer with a mutex in between and no `LOCK`/`DMB` on the fast path.

### 7.7 Async-cancel-safety

Pthread cancellation can fire at any deferred cancellation point. Handler runs. Cleanup pushes must be paired with pops. Missing `pthread_cleanup_pop(1)` on an error path → resource leak becomes state corruption.

---

<a id="integer-bugs"></a>
## 8. Integer, Type, and Sign Bugs

Source audit can miss these; binary audit often reveals them because the bug *is* the ABI.

| Bug | Primitive | Static binary tell |
|-----|-----------|-------------------|
| Unsigned wrap | Allocation too small → heap overflow | `size = user * n` with no overflow check, followed by `malloc(size)` |
| Signed overflow | Undefined behavior → compiler elides subsequent bounds check | `i * c` where both are `int`, bound check `i < N` after the multiply |
| Truncation | Large value silently narrowed → bounds bypass | `uint32_t → int`, `size_t → int`, `uint64_t → uint32_t` assignments |
| Sign confusion | Negative user input passes `x < MAX` but fails `x >= 0` | `int` user index, compared only against upper bound |
| Type-width mismatch | 32-bit length, 64-bit pointer arithmetic | `memcpy(dst, src, (int)len)` on a `size_t len` with high bit set |
| Off-by-one on ptr arithmetic | Heap / stack OOB by 1 byte | `for (i=0; i<=n; i++)` writing to `buf[i]` where `buf` has `n` elements |
| Incorrect `sizeof` | Under-allocation | `malloc(sizeof(Foo*))` instead of `sizeof(Foo)`, `sizeof(array)` inside function |
| Bool as int | Bitmask confusion | `if (flags == TRUE)` where `TRUE` is `1` but flag is `0x80` |

Compile with `-fsanitize=integer,signed-integer-overflow` for dynamic detection. Rust's default is overflow-checked in debug, wrapping in release — always test release for overflow bugs in Rust.

---

<a id="uninit-leaks"></a>
## 9. Uninitialized Memory & Info Leaks

- **Primitive:** Stale stack/heap bytes leak to attacker → defeat ASLR, disclose canary, session cookie, key.
- **Static tells:** Structs returned to userland/network without `memset` / `bzero`; partial field initialization with `= { .x = 1 }` C99 designators leaving padding uninit; `union` reads of a wider member than was written; kernel ioctl response structures with padding.
- **Kernel context:** `copy_to_user(&s, sizeof(s))` on a struct with padding → uninit bytes from kernel stack leak.
- **Detection:** **MSan** is the only practical tool. Rebuild with `-fsanitize=memory`. For kernel: KMSAN.
- **Hardening:** `-ftrivial-auto-var-init=zero`, `INIT_STACK_ALL_ZERO` (kernel), `FillMemoryWithZero` attribute — assume this is NOT enabled unless proven.

---

<a id="binary-taint"></a>
## 10. Binary-Level Taint Framework

Adapt the Phase 4 taint strategy to the binary domain. The framework shape matches source audit, but the node vocabulary changes.

**Sources (binary):**

- Syscalls returning attacker data: `read`, `recv`, `recvfrom`, `recvmsg`, `readv`, `preadv`, `mq_receive`
- File I/O on attacker-controlled files: `fread`, `fgets`, `mmap` over user file
- IPC / shared memory: `shmat`, `mmap` on `/dev/shm` entry, D-Bus message body, Mach messages, Binder transactions
- IOCTLs: `ioctl(fd, cmd, &userbuf)` — userbuf is source; kernel IOCTL handler receives via `copy_from_user`
- Environment / command line: `getenv`, `argv`, `envp`
- Registry / config: `RegQueryValueEx`, registry API on Windows
- Device input: USB endpoints, PCI config space, Bluetooth HCI events, NFC APDUs

**Primitives (nodes between source and sink):**

- Length computation (`size = a * b + c`) — check for overflow
- Bounds check (`if (len > MAX) bail`) — verify the check dominates the sink
- Sanitizer / validator call (`validate_utf8`, `parse_asn1`) — verify it actually rejects
- Buffer allocation (`malloc(computed_size)`)
- Copy (`memcpy`, `strncpy`, `memmove`) — compare source len, dest len, requested len
- Decode / parse (`inflate`, `base64_decode`, `ASN1_d2i_*`) — length mutates after decode
- Dispatch (vtable call, function-pointer call, `switch (tag)`) — is the tag trusted?

**Sinks (binary):**

- Memory-corrupting primitives from § 6
- Command execution: `execve`, `system`, `posix_spawn`, `CreateProcess`, `ShellExecute`, `WinExec`
- Code loading: `dlopen`, `LoadLibrary`, `NSCreateObjectFileImageFromMemory`
- Write to executable memory: `mprotect(…PROT_WRITE|PROT_EXEC…)`, `VirtualProtect`, JIT code buffers
- Kernel: `copy_to_user` from attacker-controlled kernel buffer, raw pointer deref without `access_ok`, uninit fields crossing the boundary

**DAG integration.** Treat each node as a DAG entry consistent with `references/dag-reasoning.md`: every intermediate node carries `{id, primitive ∈ {taint, cfg, alias, constraint, abi}, parent_ids, code_ref}`. A node labeled `abi` cites the calling convention / register / struct layout being relied upon — e.g., *"rsi holds `len` per System V AMD64; stored to stack slot at rbp-0x20, later passed to `memcpy` as 3rd arg (rdx)"*. DAGs that do not close from an untrusted source to a memory-corrupting or code-executing sink are not findings.

---

<a id="gotchas"></a>
## 15. Gotchas — Things Source Audit Misses

These belong in discovery because each one is a place a source-only reviewer falsely clears a site. Check them before concluding "no bug."

1. **Compiler-inserted checks are not guaranteed.** `_FORTIFY_SOURCE` only applies where the compiler can infer a constant destination size. Variable-length destinations → no check.
2. **`memset` to zero on sensitive data may be optimized out.** Compilers remove dead stores. Use `explicit_bzero`, `memset_s`, or `SecureZeroMemory`. Source-level audit does not catch the elision.
3. **Inline assembly violates the abstract machine.** Source-level taint stops at `asm` blocks. Binary-read the block.
4. **Lazy PLT resolution** is the classic "retk2plt" attack surface — first call to an imported function goes through resolver with attacker-influenced `RESOLVE_MAP`.
5. **TLS (Thread Local Storage) callbacks run before `main`** on Windows PE — malicious binaries hide logic here; benign binaries may hide anti-debug here.
6. **Constructors (`__attribute__((constructor))`, `.init_array`)** run before `main`. Audit them separately.
7. **Custom allocators.** The application may wrap `malloc` — the real allocator is in application code, not libc. Audit the wrapper for its own class of bugs.
8. **String copies that "look safe".** `strncpy` does **not** null-terminate if the source is ≥ n bytes; `strlcpy` does but isn't in glibc. `snprintf` returns the would-be length, not what was written. Source audit misses these; binary audit confirms by looking at the next instruction.
9. **Alignment assumptions.** `memcpy` is not valid for transferring atomic variables. 64-bit load/store on 32-bit ARM is not atomic. Structs with `__attribute__((packed))` disable natural alignment — subsequent casts can SIGBUS on strict-alignment CPUs.
10. **Calling convention confusion.** `stdcall` vs `cdecl`, `fastcall`, `__thiscall`, ARM AAPCS with VFP — wrong convention → stack not cleaned up → later corruption looks like random memory. Always check the convention before inferring control flow.
11. **Exception unwinding is code.** C++ destructors run on unwind. A bug in a destructor is reachable on every thrown exception. `.eh_frame` is attacker-relevant.
12. **Static linking hides the real library version.** `ldd` is silent on statically linked libs. Identify via Rich Header (PE), BuildID (ELF), or string signatures — then look up known CVEs.
13. **Binary may be instrumented.** CFG / CFI instrumentation, compiler profiling (`-fprofile-arcs`), sanitizer hooks change observed behavior. A stripped sanitizer-compiled binary has unusual control flow that is not the product's logic.
14. **Endianness at ABI boundaries.** MIPS big-endian, ARM big-endian E variants, AVR32 — network bytes vs. host bytes confusion causes bugs that look harmless in source.

---

**Next:** once you have a candidate bug with a binary-level taint DAG, hand off to `binary-exploit-and-specialties.md` for patch diffing / firmware-kernel specialties, exploitation primitive proof, and the structured output format.
