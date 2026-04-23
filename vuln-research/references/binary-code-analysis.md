# Binary Code Analysis — Index

> This reference has been split into three lifecycle-oriented files so agents can load only what the active hypothesis needs. Do **not** load all three by default — use the trigger table below to pick one.

Source audit ends where the compiler begins. Inline assembly, compiler reorderings, symbol stripping, packed firmware, kernel internals, and closed-source blobs all demand machine-level reasoning. The split files cover, in order, the three phases of binary-mode work: **orient → find bugs → prove and report**.

---

## The three files

| File | Scope | Sections |
|------|-------|----------|
| **`binary-triage-and-re.md`** — *orient and read* | Decide whether to enter binary mode; triage the artifact; know formats & ABI; pick tools; do static RE. | § 1 Mode Selection · § 2 Target Triage · § 2b Formats & Arch Quick-Ref · § 3 Toolchain · § 4 Static RE Workflow |
| **`binary-bug-classes.md`** — *find bugs* | Dynamic analysis, fuzzing, bug-class checklists, binary-level taint DAGs, gotchas that fool source-only audit. | § 5 Dynamic Analysis & Fuzzing · § 6 Memory Corruption · § 7 Concurrency at Machine Level · § 8 Integer/Type/Sign · § 9 Uninitialized Memory · § 10 Binary-Level Taint · § 15 Gotchas |
| **`binary-exploit-and-specialties.md`** — *prove and report* | N-day patch diffing, firmware/kernel/driver/TEE specialties, exploitation primitives, anti-analysis, mitigations, output format. | § 11 Patch Diffing · § 12 Firmware/Kernel/Driver · § 13 Exploitation Primitives · § 13b Anti-Analysis · § 14 Mitigations · § 16 Output Format |

---

## Trigger → file routing

Match the most-specific trigger first; load only the file(s) it cites.

| Trigger | Load |
|---------|------|
| Target is ELF / PE / Mach-O / WASM / dex / kernel module / firmware blob / bootloader / TEE payload, and you have not yet triaged it | `binary-triage-and-re.md` |
| You hit a `.so` / `.dll` / `.dylib` / static `.a` with no matching source — need to identify arch, symbols, mitigations | `binary-triage-and-re.md` |
| Source is present but C / C++ / Rust `unsafe` / Go `cgo` / Zig / Objective-C / inline `asm!` changes ABI or ordering semantics | `binary-bug-classes.md` |
| Hypothesis involves memory layout, stack alignment, calling convention, endianness, signal delivery, syscall atomicity, double-fetch, weak memory model | `binary-bug-classes.md` |
| Crash found but no source-level explanation — the bug may live in compiler output / linker glue / TLS callback / `.init_array` | `binary-triage-and-re.md` (§ 4) + `binary-bug-classes.md` (§ 15) |
| Writing or validating a fuzz harness | `binary-bug-classes.md` (§ 5) |
| Hunting memory corruption / UAF / type confusion / integer / uninit bugs | `binary-bug-classes.md` (§ 6–9) |
| Building a binary-level taint DAG from source syscall to sink | `binary-bug-classes.md` (§ 10) |
| N-day work: public advisory + patched vs. unpatched binary, no source diff | `binary-exploit-and-specialties.md` (§ 11) |
| Firmware image / IoT / router / printer / camera / automotive ECU | `binary-exploit-and-specialties.md` (§ 12.1) |
| Kernel / driver / hypervisor / TEE target | `binary-exploit-and-specialties.md` (§ 12.2–12.5) |
| Packed, VM-protected, anti-debug, or otherwise obfuscated sample | `binary-exploit-and-specialties.md` (§ 13b) |
| Building or claiming an exploit primitive (ROP / SROP / ret2dlresolve / JOP / heap grooming) | `binary-exploit-and-specialties.md` (§ 13 + § 14) |
| Writing up a binary finding for Phase 5/6/7 reporting | `binary-exploit-and-specialties.md` (§ 16) |

---

## Integration with the main skill

Binary findings feed the source pipeline unchanged:

- **Phase 6 Chaining** consumes binary primitives (info-leak / arb-read / arb-write / control-flow) exactly like source findings.
- **Phase 7 Exploitability Gate** accepts the same DAG form — each node carries `primitive ∈ {taint, cfg, alias, constraint, abi}`, and `abi` nodes cite the calling convention / register / struct layout being relied on.

See `binary-bug-classes.md` § 10 for the binary-taint vocabulary and `binary-exploit-and-specialties.md` § 16 for the structured output template.

**Policy:** do not load the whole triad by default. On a target with no native component, none of the triggers above fire and these files stay off the token budget.
