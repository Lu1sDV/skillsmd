# Research sources and admission decisions

Maintainer record for the Rust safety/security expansion, researched 2026-11-03.
This file is optional provenance, not material to preload during every review.
The five topic references contain the operational guidance and local examples.

## Evidence policy

1. **Rust Reference and standard-library contracts** decide language/API claims.
   Official library/runtime documentation decides that dependency's contract.
   Check the consuming version, feature set, target, edition, and configuration.
2. **Established engineers and maintainers** explain mechanisms and supply review
   ideas. Their proposals, historical examples, implementation details, and
   research models are not automatically stabilized language guarantees.
3. **Community skills, directories, advisories, and issue discussions** supply
   discovery leads and concrete failure shapes. Verify the particular claim at
   its primary contract; popularity, branding, or an automated SAFE badge is not
   a correctness review. An advisory establishes its described affected scope,
   not that every call to the named API is vulnerable.
4. **Execution evidence** establishes only the tested inputs/build/target. Keep
   source verification, static reasoning, runtime reproduction, and model-checking
   results distinct. Unknown is neither a vulnerability nor proof of safety.

Research used `parallel-cli` search and full-content extraction. Nine scout lanes
covered language contracts, lifecycle, FFI/handles, availability, OS inputs,
concurrency, verification, expert blind spots, and community skills. Scouts could
not execute the CLI; the coordinator ran it and supplied the saved JSON results
for source reconciliation. Search snippets were leads, not admitted evidence.

The research archive contains the CLI responses and full-page extracts, with URL
and SHA-256 indexing. It is kept outside the installed bundle; consumers do not
need a large vendored copy of std documentation. Source links below are primary
or original-author URLs. Unless pinned, a URL is a moving page inspected on the
research date, not a frozen version guarantee.

## Primary sources by admitted claim

| Claim group | Sources | Admission / limits |
|---|---|---|
| Any-safe-client soundness, validity, aliasing | [Reference UB](https://doc.rust-lang.org/reference/behavior-considered-undefined.html), [std pointers](https://doc.rust-lang.org/std/ptr/index.html) | Contract-level facts; exact aliasing/provenance models remain partly unsettled |
| Casts and union reads | [transmute](https://doc.rust-lang.org/std/mem/fn.transmute.html), [unions](https://doc.rust-lang.org/reference/items/unions.html) | Read/type validity matters; no blanket raw-cast or inactive-field UB rule |
| Initialization, manual drop, panic-safe state | [MaybeUninit](https://doc.rust-lang.org/std/mem/union.MaybeUninit.html), [ManuallyDrop](https://doc.rust-lang.org/std/mem/struct.ManuallyDrop.html), [drop_in_place](https://doc.rust-lang.org/std/ptr/fn.drop_in_place.html), [Nomicon exception safety](https://doc.rust-lang.org/nomicon/exception-safety.html) | Preserve valid initialized/live state through callbacks and unwind; do not rely on newer drop-then-move allowances on the 1.85 baseline |
| Forgotten guards and pinning | [forget](https://doc.rust-lang.org/std/mem/fn.forget.html), [Nomicon leaking](https://doc.rust-lang.org/nomicon/leaking.html), [Pin](https://doc.rust-lang.org/std/pin/index.html) | Leaks can be memory-safe; structural pinning/destruction needs the precise contract |
| Generic safe traits | [Read](https://doc.rust-lang.org/std/io/trait.Read.html#method.read), [ExactSizeIterator](https://doc.rust-lang.org/std/iter/trait.ExactSizeIterator.html), [Ord](https://doc.rust-lang.org/std/cmp/trait.Ord.html) | Concrete examples of the existing rule: arbitrary safe implementations cannot supply unchecked memory-safety proofs |
| Layout, niches, native exceptions | [type layout](https://doc.rust-lang.org/reference/type-layout.html), [Option representation](https://doc.rust-lang.org/std/option/index.html#representation), [Reference unwinding](https://doc.rust-lang.org/reference/panic.html#unwinding-across-ffi-boundaries) | Preserve type/target restrictions; Reference overrides older simplified unwind explanations |
| Debug checks, overflow, edition behavior | [debug_assert](https://doc.rust-lang.org/std/macro.debug_assert.html), [Cargo profiles](https://doc.rust-lang.org/cargo/reference/profiles.html), [if-let scope](https://doc.rust-lang.org/edition-guide/rust-2024/temporary-if-let-scope.html) | Effective configuration and edition, not debug/release folklore |
| Recursive values and parser guard scope | [serde_stacker](https://docs.rs/serde_stacker/latest/serde_stacker/), [serde_json Deserializer](https://docs.rs/serde_json/latest/serde_json/struct.Deserializer.html#method.disable_recursion_limit) | Adapters cover their own operations; a feature enabling an opt-out method is not the same as calling it; no universal depth limit adopted |
| Allocation/work/hash limits | [Vec](https://doc.rust-lang.org/std/vec/struct.Vec.html), [allocation errors](https://doc.rust-lang.org/std/alloc/fn.handle_alloc_error.html), [HashMap](https://doc.rust-lang.org/std/collections/struct.HashMap.html) | Fallible reserve is not a quota or universal recovery guarantee; fixed hashers change HashDoS assumptions |
| Panic and atomic protocols | [catch_unwind](https://doc.rust-lang.org/std/panic/fn.catch_unwind.html), [Mutex](https://doc.rust-lang.org/std/sync/struct.Mutex.html), [AtomicUsize (Rust 1.85)](https://doc.rust-lang.org/1.85.0/std/sync/atomic/struct.AtomicUsize.html), [Nomicon races](https://doc.rust-lang.org/nomicon/races.html) | Containment is not rollback; poison is advisory; atomic operations do not make a protocol atomic |
| Async interruption/admission | [Tokio select](https://docs.rs/tokio/latest/tokio/macro.select.html), [Semaphore](https://docs.rs/tokio/latest/tokio/sync/struct.Semaphore.html), [spawn_blocking](https://docs.rs/tokio/latest/tokio/task/fn.spawn_blocking.html) | Dependency-specific checks; verify the consuming Tokio version rather than freezing current defaults |
| I/O ownership | [OwnedFd](https://doc.rust-lang.org/std/os/fd/struct.OwnedFd.html), [BorrowedFd](https://doc.rust-lang.org/std/os/fd/struct.BorrowedFd.html), [FromRawFd](https://doc.rust-lang.org/std/os/fd/trait.FromRawFd.html), [std Unix I/O](https://doc.rust-lang.org/std/os/unix/io/index.html) | Descriptor ownership is not exclusive ownership of underlying storage; Unix example is not Windows evidence |
| Filesystem resolution | [Path](https://doc.rust-lang.org/std/path/struct.Path.html), [OpenOptions](https://doc.rust-lang.org/std/fs/struct.OpenOptions.html), [Linux openat2](https://man7.org/linux/man-pages/man2/openat2.2.html) | Lexical checks and final-component flags do not establish all-component confinement; Linux mechanism is platform-specific |
| Process execution | [Command](https://doc.rust-lang.org/std/process/struct.Command.html), [Windows argument splitting](https://doc.rust-lang.org/std/process/index.html#windows-argument-splitting), [Child](https://doc.rust-lang.org/std/process/struct.Child.html) | Literal arguments still have target-program semantics; child lifecycle and inherited authority matter |
| Windows batch version precedent | [CVE-2024-24576](https://blog.rust-lang.org/2024/04/09/cve-2024-24576/), [CVE-2024-43402](https://blog.rust-lang.org/2024/09/04/cve-2024-43402/) | Rust Security Response WG; 2024-04-09 and 2024-09-04. Historical fixes are not blanket shell-input safety |
| Identity and output | [lossy strings](https://doc.rust-lang.org/std/string/struct.String.html#method.from_utf8_lossy), [format](https://doc.rust-lang.org/std/macro.format.html), [BufWriter](https://doc.rust-lang.org/std/io/struct.BufWriter.html), [File sync](https://doc.rust-lang.org/std/fs/struct.File.html#method.sync_all) | Encoding, identity, delivery, and durability are distinct contracts |
| Verification limits | [Miri](https://github.com/rust-lang/miri), [sanitizers](https://doc.rust-lang.org/unstable-book/compiler-flags/sanitizer.html), [Loom](https://docs.rs/loom/latest/loom/), [Rust Fuzz Book](https://rust-fuzz.github.io/book/) | Models, instrumentation, inputs, and schedules limit conclusions; nightly/tool-specific settings must be pinned |
| Host execution/advisories | [build scripts](https://doc.rust-lang.org/cargo/reference/build-scripts.html), [proc macros](https://doc.rust-lang.org/reference/procedural-macros.html), [cargo-audit](https://github.com/rustsec/rustsec/tree/main/cargo-audit), [untrusted-project issue](https://github.com/rustsec/rustsec/issues/1342) | Read before running untrusted projects; a known-advisory scan is not source correctness or a sandbox |

## Original engineer sources

| Author / source | Date or edition | Contribution and limit |
|---|---|---|
| Ralf Jung, [Two Kinds of Invariants](https://www.ralfj.de/blog/2018/08/22/two-kinds-of-invariants.html) | 2018-08-22 | Distinguishes validity from safe-abstraction invariants; historical research explanation, not a replacement for current Reference contracts |
| Ralf Jung, [Pointers Are Complicated III](https://www.ralfj.de/blog/2022/04/11/provenance-exposed.html) | 2022-04-11; subsequent updates | Explains exposed versus strict provenance; proposed models are not frozen runtime semantics |
| Aria Desires / Beingessner, [Pre-Pooping Your Pants With Rust](https://faultlore.com/blah/everyone-poops/) | 2015-04-27 | Historical leak-amplification motivation; author points readers to the newer Nomicon chapter, which supplies operational guidance |
| Dan Gohman, [I/O safety proposal](https://internals.rust-lang.org/t/pre-rfc-i-o-safety/14585), [RFC 3128](https://rust-lang.github.io/rfcs/3128-io-safety.html) | 2021-04-28 / RFC start 2021-05-24 | Typed descriptor authority/ownership motivation; use current std APIs, not historical proposal names/analogies |
| Alice Ryhl, [Async: What is blocking?](https://ryhl.io/blog/async-what-is-blocking/) | 2020-12-21 | Cooperative scheduling and blocking review; no numeric universal scheduling threshold adopted |
| Mara Bos, [Rust Atomics and Locks: atomics](https://mara.nl/atomics/atomics.html) | [Online book](https://mara.nl/atomics/); edition date not relied on | RMW versus separate operations and protocol reasoning; std method contracts supply API details |
| David Tolnay, [serde_stacker](https://docs.rs/serde_stacker/latest/serde_stacker/) | Inspected 0.1.14 | Maintainer warning and iterative cleanup examples; no claim every serde format has identical guards |
| Nicholas Nethercote, [The Rust Performance Book: hashing](https://nnethercote.github.io/perf-book/hashing.html) | Undated moving page | Alternative-hasher tradeoff; default std HashMap security documentation is the contract |

Jon Gjengset video/search snippets and unfetched expert articles were not used to
establish facts. Reputation prioritizes a source; it does not verify an unseen
lecture, make an RFC stable, or resolve a version disagreement.

## GitHub and skill-directory survey

These are comparison sources, not installed dependencies. New wording and examples
were written against the API contracts above; no surveyed prompt/code was imported.
Retain each source's license/attribution requirements if copying it in future.

| Candidate | Provenance / license inspected | Decision |
|---|---|---|
| [Trail of Bits rust-review](https://github.com/trailofbits/skills/tree/711af095215ad4ecde5b90cd1d0124b3f1c4ca9e/plugins/rust-review) | Pinned `711af095215ad4ecde5b90cd1d0124b3f1c4ca9e`; CC BY-SA 4.0 | Useful bug-class/lifecycle leads; reject blanket cast/union rules, hardening-as-vulnerability and not-searched-as-cleared; no orchestration import |
| [Google unsafe_rust_review](https://github.com/google/rust-skills/blob/main/unsafe_rust_review/SKILL.md) | Google-hosted repo; [Apache-2.0 license](https://github.com/google/rust-skills/blob/main/LICENSE.md) | Relevant proof/evidence and hazard sections reviewed, not a full audit of the long skill. Keep local proof discipline; do not adopt its project conventions as Rust axioms or copy its size |
| [full-stack-skills unsafe/FFI](https://github.com/full-stack-skills/rust-skills/blob/main/skills/rust-unsafe-ffi/SKILL.md) | Frontmatter declares Apache-2.0 | Mostly existing coverage. Do not copy unconditional all-features commands or substitute mocked FFI for native verification |
| [mohitmishra786 rust-security](https://github.com/mohitmishra786/low-level-dev-skills/blob/main/skills/rust/rust-security/SKILL.md) | MIT repository; original checked after directory discovery | Audit/fuzzing leads checked against maintainers; reject the implication that Tree Borrows enables Miri data-race detection |
| [skills.sh Rust listing](https://www.skills.sh/google/rust-skills/unsafe-rust-review) | Directory, not semantic authority | Followed to original GitHub source; install counts and automated security badges not used as evidence |
| [skills.md public listing](https://skills.md/api/v1/skills) | Literal requested site; public listing inspected | No relevant Rust-safety entry found in that inspected listing; not a claim about all future/private entries |
| [SkillsMP](https://skillsmp.com/) | Public search returned a loading shell | Listing not verified; no credentials used and no content inferred |

## Explicit design decisions

- **Expand one bounded skill.** Keep memory/FFI depth; add availability/resources
  and input/OS boundary references. General concurrency, type diagnostics,
  performance, API architecture, and testing remain optional sibling handoffs.
- **Clean name cutover.** The published skill is `rust-safety`; update local
  installation/routing references rather than keep a duplicate compatibility skill.
  `vuln-research` is explicitly outside this change.
- **Keep the entrypoint small.** Route by task, preserve critical guards and
  completion requirements, and load detailed examples only on demand. This follows
  [official authoring guidance](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
  and the [Agent Skills format](https://agentskills.io/specification).
- **Avoid speculative coverage.** Secret zeroization/constant-time cryptography,
  generic business authorization, smart contracts, kernel policy, and browser/Wasm
  are not silently included. Add such topics only with a separately justified scope.
- **Preserve API soundness versus application impact.** A safe-client UB witness
  establishes unsoundness; it does not establish remote exploitability. Missing
  evidence is unverified, not safe, and a missing comment alone is not a memory bug.
- **Reject attractive shortcuts.** No universal safe recursion depth, type-name-only
  deserialization finding, lexical `safe_join` promise, unchecked size hint,
  panic-catcher-as-rollback claim, or passing-tool-as-proof claim.
- **Version doubt stays explicit.** Current and historical `ManuallyDrop` pages
  differ about the drop-then-move transition. No example relies on the newer
  allowance; consumer MSRV-specific claims require its documented contract.
  No experimental `TrustedLen`, `may_dangle`, or pinning API is prescribed as stable.
- **Preserve provenance.** Original StructWeave attribution and MIT notice remain
  in the bundle. Surveyed skill licenses are not assumed interchangeable with MIT.

## Verification scope

The README gives reproducible local commands and separates Rust doctests from a
real native C caller. New executable examples cover iterative destruction, bounded
atomic admission, rejection of an invalid safe-reader count, bounded-input errors,
and Unix descriptor ownership. Reviews must examine both the original unsafe/FFI
coverage and the expansion; source citations do not replace execution checks.

Miri/sanitizers, Windows-specific process/handle behavior, alternate architectures,
consumer Tokio applications, and a minimum-version compiler require their own
available environments. Report exactly which were exercised; no detection-quality,
recall, universal soundness, or complete security coverage is claimed.
