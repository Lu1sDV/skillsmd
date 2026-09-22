# Binary Code Analysis — Part 1: Triage & Static RE

> Load when the target is a compiled binary, firmware image, kernel/driver, or a native-source codebase and you are **orienting**: deciding whether to enter binary mode, triaging the artifact, picking tools, or doing static reverse engineering.
>
> Paired files:
> - `binary-bug-classes.md` — dynamic analysis, fuzzing, memory-corruption / concurrency / integer / uninit bug classes, binary-level taint, gotchas.
> - `binary-exploit-and-specialties.md` — patch diffing, firmware/kernel/driver specialties, exploitation primitives, anti-analysis, mitigations, output format.
> - `binary-code-analysis.md` — thin index that routes triggers to one of the three files.

Source audit ends where the compiler begins. Inline assembly, compiler reorderings, symbol stripping, packed firmware, kernel internals, and closed-source blobs all demand machine-level reasoning. This file covers the "orient and read" half of that work.

---

## Table of Contents

1. [Mode Selection — When to Enter Binary Mode](#mode-selection)
2. [Target Triage](#target-triage)
2b. [Binary Formats & Architecture Quick Reference](#formats-arch)
3. [Toolchain](#toolchain)
4. [Static Reverse Engineering Workflow](#static-re)

---

<a id="mode-selection"></a>
## 1. Mode Selection — When to Enter Binary Mode

Enter binary mode when **any** of the following hold:

- Target artifact is an ELF / PE / Mach-O / WASM / dex / kernel module / firmware image / bootloader / embedded blob
- Source is present but compiled C / C++ / Rust `unsafe` / Go `cgo` / Zig / Objective-C / inline assembly meaningfully changes the observable semantics
- The bug hypothesis involves memory layout, calling convention, alignment, endianness, signal delivery, syscall atomicity, or ABI violation
- A library is distributed only as a shared object, static archive, or obfuscated JAR/APK with native code
- Patch-diff work: the public advisory and the patch are both binary-only
- The target is a closed-source daemon, driver, hypervisor, trusted-execution enclave, or firmware update
- Source-level sinks did not explain a known crash — the bug may live in compiler output or linker glue

Binary mode **co-exists** with source mode. A mixed engagement runs the source phases in parallel and lets binary findings feed back into the DAG as `verified_sink` nodes with explicit machine-level primitives.

---

<a id="target-triage"></a>
## 2. Target Triage

Before any heavy tooling, answer these six questions. Getting them wrong wastes hours.

| Question | One-liner to answer it |
|----------|-----------------------|
| What is it? | `file <binary>` — ELF/PE/Mach-O/script/firmware container |
| What arch & ABI? | `readelf -h`, `objdump -f`, `otool -h`, `rabin2 -I` |
| Stripped? | `nm <bin>`, `readelf -s`, `objdump -t` — no symbols → rely on strings + xrefs |
| What mitigations? | `checksec --file=<bin>` or `pwn checksec` — PIE, NX, Canary, RELRO, Fortify |
| What libraries / imports? | `ldd`, `readelf -d`, `otool -L`, PE imports via `pefile` / `rabin2 -i` |
| Packed / obfuscated? | Entropy scan (`binwalk -E`), section-name anomalies, UPX/ASPack signatures, VMProtect stubs |

Additional triage commands:

```bash
# ELF
file bin && readelf -hdnS bin && objdump -x bin | head -60
strings -n 8 bin | head -200
checksec --file=bin   # or: pwn checksec bin

# PE (Windows)
rabin2 -I bin         # or: pefile / DIE / CFF Explorer
rabin2 -i bin         # imports
rabin2 -z bin         # strings in data segments

# Mach-O
otool -hV bin && otool -L bin && otool -l bin

# Firmware container
binwalk -Me firmware.bin
binwalk -E firmware.bin       # entropy plot — high-entropy → encrypted/compressed

# Android APK (native portions)
apktool d app.apk && ls lib/*/  # per-ABI native libs
```

**Triage red flags (pause and investigate):**

- High entropy section with no import table → packed or encrypted
- `ptrace` / `IsDebuggerPresent` / `__attribute__((constructor))` anti-debug
- TLS callbacks on PE (execute before `main`)
- Custom section names (`.vmp0`, `.enigma`, `.tld`) → commercial protector
- Self-modifying code hints (`mprotect` / `VirtualProtect` with `PROT_EXEC`)
- `syscall` / `int 0x80` / `sysenter` direct issuance → userland sandbox-evasion or exploit primitive
- Legitimate-looking RWX regions → JIT engines (V8, SpiderMonkey, .NET Ready2Run) — audit the JIT separately

---

<a id="formats-arch"></a>
## 2b. Binary Formats & Architecture Quick Reference

Get format and architecture wrong and every subsequent byte is misread. Burn these tables in before deep RE.

### 2b.1 Executable formats

| Format | Platform | Key structures | Security-relevant sections |
|--------|----------|---------------|----------------------------|
| **ELF** | Linux/Unix/Android | `e_ident`, `e_entry`, program headers (LOAD / DYNAMIC / INTERP), section headers | `.text` code; `.data`/`.bss` writable; `.rodata` strings & jump tables; `.plt`/`.got[.plt]` (GOT-overwrite target unless Full RELRO); `.init_array`/`.fini_array` run before/after `main`; `.eh_frame` = code too |
| **PE / PE32+** | Windows | `MZ` DOS stub → `PE\0\0` NT header → Optional header → Data Directories → Section Table | `.text`; `.rdata`/`.data`; **IAT** (import overwrite); `.rsrc`; **TLS callbacks** (run before `main`); SEH/VEH tables; Authenticode sig |
| **Mach-O** | macOS / iOS | Mach header, load commands (`LC_SEGMENT_64`, `LC_MAIN`, `LC_LOAD_DYLIB`, `LC_CODE_SIGNATURE`) | `__TEXT.__text`/`__const`; `__DATA.__got`/`__data`; `__LINKEDIT`; `__swift5_types` (Swift metadata); code signature (SIP / Hardened Runtime gate attach) |
| **WASM** | Browser / wasm runtime | Module sections: type, import, function, memory, table, element, code, data | Imports cross host/guest boundary; linear memory is the only heap; indirect calls go through table — CFI is table-bounds-check |
| **Firmware blob** | Embedded | Often layered: bootloader + kernel + rootfs + overlay, possibly wrapped in vendor header | Peel with `unblob` (preferred) or `binwalk -Me`; watch for signature blocks (CHK/TRX/DLOB/custom) and vendor-specific magic |

### 2b.2 Architecture cheat sheet

| Arch | Endian | Calling convention — arg registers | Return | Key quirks |
|------|--------|-----------------------------------|--------|------------|
| x86 (32) | LE | `cdecl` / `stdcall` / `fastcall` — mostly stack | EAX | Caller vs callee cleanup diverges per convention |
| x86-64 | LE | SysV: RDI, RSI, RDX, RCX, R8, R9 · Win x64: RCX, RDX, R8, R9 + 32-byte shadow | RAX | **16-byte stack alignment required *before* `CALL`** (so `(RSP+8) % 16 == 0` at function entry). Misalignment crashes `movaps` inside libc — #1 "my ROP chain died" cause. Pad with an extra `ret` gadget. |
| ARM (A32/T32) | usually LE | AAPCS: R0–R3 args, R4–R11 saved, R12 IP, R13 SP, R14 LR, R15 PC | R0 | Thumb/ARM interworking via LSB of address; conditional exec on most insns |
| AArch64 | LE | AAPCS64: X0–X7 args, X8 indirect-return, X29 FP, X30 LR | X0 | PAC signs pointers (keyed); BTI enforces valid branch targets; weak memory model |
| MIPS | BE or LE | O32: $a0–$a3 args · N32/N64: $a0–$a7 | $v0 | **Branch delay slot** — insn after a branch *always* executes. Network gear often big-endian. |
| RISC-V | LE | a0–a7 (x10–x17) args, ra (x1) return, sp (x2) | a0 | Variable-width ISA (RVC compressed); weak memory model |
| PPC64 (LE/BE) | either | ABIv2 (LE): r3–r10 args; TOC via r2 | r3 | Function descriptors on BE; TOC pointer arithmetic |

### 2b.3 Language-family symbol recovery

Stripped-but-not-really: the runtime metadata almost always leaks enough to rebuild names.

| Language | Leak source | Tool |
|----------|-------------|------|
| Go | `runtime.pclntab`, `runtime.symtab`, build info | `GoReSym`, `redress`, `go_parser` (Ghidra) |
| Rust | panic strings disclose source paths; `.note.rust`; release-`-C strip=symbols` wipes | `rustfilt` for demangling; `cargo-show-asm` for cross-ref |
| Swift | `__swift5_types`, `__swift5_reflstr` | `swift demangle`, `dsdump` |
| C++ | RTTI `type_info` strings, vtable symbols | Ghidra *Class and Namespace* analysis; IDA Class Informer |
| .NET | Managed metadata unless ReadyToRun / NativeAOT | `dnSpy`, `ILSpy`; NativeAOT → treat as native Ghidra target |

---

<a id="toolchain"></a>
## 3. Toolchain

Pick tools that match the artifact, the budget, and the desired fidelity.

| Task | Primary | Secondary | Notes |
|------|---------|-----------|-------|
| Disassembly / decompilation | **Ghidra**, **IDA Pro**, **Binary Ninja** | radare2 / cutter, Hopper | Ghidra's decompiler is free and scriptable; IDA's Hex-Rays is highest fidelity on x86/ARM |
| Quick CLI RE | `objdump -dS`, `nm`, `readelf`, `rabin2 -R` | `radare2` interactive | Prefer CLI for diffing and grepping decompilations |
| Dynamic debugging (Linux) | `gdb` + **pwndbg** / **gef** / **peda** | `lldb`, `rr` (record-replay) | pwndbg is strongly preferred for exploit dev |
| Dynamic debugging (Windows) | WinDbg (+ pykd), x64dbg | OllyDbg (legacy), IDA debugger | WinDbg is mandatory for kernel work |
| Dynamic debugging (macOS) | lldb | — | Hardened Runtime + SIP restrict attach; codesign-allow target |
| Dynamic instrumentation | **Frida**, DynamoRIO, Pin, QBDI | Time Travel Debugging (WinDbg TTD) | Frida excels at mobile and quick hooks; DynamoRIO for shadow memory |
| Emulation | **Qiling**, **Unicorn**, qemu-user | AFL-QEMU | Qiling boots full rootfs images; Unicorn for surgical gadget emulation |
| Fuzzing | **AFL++**, **libFuzzer**, **honggfuzz** | Jackalope (closed-source), WinAFL, boofuzz (network) | Libfuzzer for in-process, AFL++ for file formats, honggfuzz for hardware counters |
| Sanitizer-guided audit | ASan, MSan, UBSan, TSan, HWASan | Valgrind (Memcheck, Helgrind, DRD) | TSan + libFuzzer is the cheapest real-world data-race finder |
| Symbolic / concolic | **angr**, **Triton**, **Manticore** | KLEE (LLVM bitcode), ESBMC | Use for solving constraints on reachable crashes, not blind discovery |
| Patch diffing | **BinDiff**, **Diaphora** | radiff2, Ghidra `BSim` | Always diff binaries from the same toolchain/compile flags |
| SMT / solver | Z3, CVC5 | — | Backs angr and Manticore |
| Coverage | lcov, SanitizerCoverage, DrCov, Lighthouse (IDA/Ghidra/Binja plugin) | — | Required for measuring fuzzer effectiveness |
| Firmware | **binwalk**, **unblob**, **firmwalker**, `ubireader`, `jefferson` | `extract-firmware.sh`, `cramfs-tools` | unblob is the modern binwalk replacement |
| Mobile — Android | jadx, **frida-tools**, MobSF, ghidra + `.so` | objection, apktool, Drozer | Always audit both Java/Kotlin and native `.so` per ABI |
| Mobile — iOS | Ghidra, Hopper, Frida, Objection | `ipatool`, `class-dump`, `dsdump` | Requires decrypted IPA (iPatool or jailbroken device) |

**Prefer headless / CLI over GUI.** Ghidra's `analyzeHeadless` + PyGhidra, `radare2 -A` with `r2pipe`, `objdump -dS`, `nm`, `readelf`, IDA batch scripts, and Binary Ninja headless all beat screenshot-driven workflow. Pipe decompilations into `grep`, diff them across versions, and keep the RE loop in text.

---

<a id="static-re"></a>
## 4. Static Reverse Engineering Workflow

The universal RE loop:

1. **Anchor on strings, imports, and constants.**
   - `strings -n 8 bin | grep -iE 'error|failed|%s|/tmp|sprintf|http|/proc'`
   - Format strings reveal function names — `"%s:%d: assertion failed"` → logging function → callers = high-value sites
   - Imports tell you the syscall surface: `system`, `execve`, `popen`, `LoadLibrary`, `dlopen`, `mmap(…RWX…)`, crypto imports
   - Magic constants (`0xdeadbeef`, `0xcafebabe`, SHA/AES S-box, CRC tables) identify algorithms — cross-reference against standard implementations

2. **Rebuild symbols.**
   - Strip a symbol set? → **FLIRT / Lumen / BSim** signature matching against known libc, OpenSSL, zlib, etc.
   - For C++: recover vtables (`readelf -a | grep vtable`, Ghidra's *Class and Namespace* analysis). RTTI strings are goldmines.
   - For Rust: `.note.rust` section, panic strings (`"index out of bounds: the len is..."`) disclose source paths. Rust binaries are usually symbol-rich unless `--release -C strip=symbols`.
   - For Go: `runtime.pclntab` holds full function names. Use `GoReSym` or `redress` to rebuild.
   - For Swift: demangle with `swift demangle`. Always dump the `__TEXT.__swift5_types` section.

3. **Identify `main` or equivalent entry.**
   - Not `_start` / `mainCRTStartup` — they are glue. Walk into `__libc_start_main`'s 1st arg (Linux) or the address passed to `BaseThreadInitThunk` (Windows).
   - Kernel modules: `module_init` / `DriverEntry` / `ProbeMember`.

4. **Map attack surface first, bugs second.**
   - Enumerate **input boundaries**: `recv`, `read`, `fread`, `getenv`, `argv`, IOCTLs, `DeviceIoControl`, socket accepts, named pipes, shared memory (`shmget`, `CreateFileMapping`), Mach ports (`mach_msg`).
   - For each, annotate: which thread / privilege / ACL / isolation boundary does the input cross?

5. **Trace forward to dangerous primitives** (see `binary-bug-classes.md` § Memory Corruption). Prefer xref-driven navigation over linear reading.

6. **Decompile + rename + comment aggressively.** The decompiler's quality scales with symbol quality you feed back. Every renamed variable pays back 10× in downstream clarity.

7. **Cross-check decompilation against disassembly.** Decompilers lie. Compiler optimizations (loop unrolling, tail-call, sibling-call, ret-protector, CFG split) routinely produce misleading pseudocode. When a bug hypothesis depends on a subtle control flow, **read the actual instructions**.

---

**Next:** once triage and static RE have identified attack surface and suspicious code, hand off to `binary-bug-classes.md` for dynamic analysis, fuzzing, and bug-class discovery; or to `binary-exploit-and-specialties.md` for patch diffing / kernel/firmware / exploitation primitives.
