# Binary Stack Triggers — Phase L3.5 Tiered Loading Map

Load this file when Phase L3.5 (Technology Stack Discovery / Sink Loading) detects compiled binaries, firmware, kernels, drivers, packed/obfuscated samples, or source that depends on ABI/memory-ordering semantics. Use the 13-row trigger table below to determine which of the three binary lifecycle files to load. Binary findings feed Phase L6 Chaining and pass Phase L7 Exploitability Gate via the same DAG form as source findings.

---

**Binary / native artifacts in the stack — tiered loading across three lifecycle files.** Source-level sinks stop at the compiler; ABI, memory ordering, calling conventions, packers, and machine-level race windows require binary audit. The binary reference is split into three lifecycle files — **orient**, **find bugs**, **prove and report** — plus a thin routing index at `references/binary/binary-code-analysis.md`. Load only what the trigger cites; never the whole triad by default.

| Trigger (any match → load) | File(s) and section(s) to read first |
|---|---|
| Target artifact is ELF / PE / Mach-O / WASM / dex / firmware blob / kernel module / bootloader / TEE payload | `references/binary/binary-triage-and-re.md` § 1 → § 2 → § 2b |
| Source audit hit a `.so` / `.dll` / `.dylib` / static `.a` with no matching source | `references/binary/binary-triage-and-re.md` § 2–4, then `references/binary/binary-bug-classes.md` § 10 |
| Source is present but contains C / C++ / Rust `unsafe` / Go `cgo` / Zig / Objective-C / inline `asm!` where ABI or ordering changes semantics | `references/binary/binary-bug-classes.md` § 6 + § 7 + § 15 |
| Hypothesis involves memory layout, stack alignment, calling convention, endianness, signal delivery mid-instruction, syscall atomicity, double-fetch, weak memory model | `references/binary/binary-bug-classes.md` § 7 + § 8 + § 15 |
| N-day work: public advisory + patched vs. unpatched binary, no source diff | `references/binary/binary-exploit-and-specialties.md` § 11 |
| Crash found but no source explanation — the bug may live in compiler output / linker glue / TLS callback / `.init_array` | `references/binary/binary-triage-and-re.md` § 4 + `references/binary/binary-bug-classes.md` § 15 |
| Packed, VM-protected, anti-debug, or otherwise obfuscated sample | `references/binary/binary-exploit-and-specialties.md` § 13b |
| Building or claiming an exploit primitive (ROP/SROP/ret2dlresolve/JOP/heap grooming) | `references/binary/binary-exploit-and-specialties.md` § 13 + § 14 |
| Firmware image / IoT / router / printer / camera / automotive ECU | `references/binary/binary-exploit-and-specialties.md` § 12.1 |
| Kernel / driver / hypervisor / TEE target | `references/binary/binary-exploit-and-specialties.md` § 12.2–12.5 + § 14 |
| Writing a fuzz harness or running dynamic analysis | `references/binary/binary-bug-classes.md` § 5 |
| Building a binary-level taint DAG | `references/binary/binary-bug-classes.md` § 10 |
| Writing a binary finding report | `references/binary/binary-exploit-and-specialties.md` § 16 (DAG block required — ties back to Phase L7 Gate) |

**Do not load the whole triad by default.** On targets with no native component, none of the above triggers fire and these files stay off the token budget. On triggered targets, load only the subfile(s) the matched trigger cites. When no single trigger dominates, start with `references/binary/binary-code-analysis.md` (thin index, ~60 lines) and fan out from there.

**Binary findings integrate with the source pipeline unchanged:** they feed **Phase L6 Chaining** as primitives (info-leak / arb-read / arb-write / control-flow) and pass **Phase L7 Exploitability Gate** via the same DAG form as source findings — with `primitive ∈ {taint, cfg, alias, constraint, abi}` and `abi` nodes citing the calling convention / register / struct layout being relied on. See `references/binary/binary-bug-classes.md` § 10 (Binary-Level Taint Framework) and `references/binary/binary-exploit-and-specialties.md` § 16 (Output Format) for the binary-specific DAG vocabulary.
