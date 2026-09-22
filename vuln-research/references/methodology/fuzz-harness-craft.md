# Fuzz Harness Craft

> The *craft* layer under the fuzzing lane: how to write a harness that actually reaches the bug,
> how to remove the obstacles that stop the fuzzer, and how to know it's working. Distilled from
> the Trail of Bits Testing Handbook fuzzing skills (harness-writing, fuzzing-obstacles,
> fuzzing-dictionary, coverage-analysis, address-sanitizer). The *lane* — when it runs, what it
> records, the coverage gate — is `references/v2/fuzzing-lane.md`; seed generation is
> `references/v2/seed-corpus-generation-lane.md` (input-format-family synthesis) and
> `references/v2/fuzzgpt-history-lane.md` (`fuzzgpt_history_lane` — history-driven LLM
> fuzzing, FuzzGPT/arXiv:2304.02014, which mines the target's bug history into edge-case
> `seed_initial` programs). This file is the technique those lanes apply. Note: "fuzz target"
> here means the **libFuzzer harness entry point**; in the fuzzgpt sense it means the **unit
> generation is steered toward** (API/flag/SQL-feature/syscall/opcode/field) — see the
> disambiguation in `references/v2/fuzzgpt-history-lane.md` § 0.

## Normalization — artifacts vs DuckDB rows

Harnesses, corpora, dictionaries, and instrumented builds are **legitimate disk artifacts**: they
live under the workspace fuzz/build dirs (`.vuln-research/fuzz/`, `.vuln-research/build/` per the
workspace convention) and are referenced from `fuzz_artifacts` rows (`artifact_kind` =
`seed_initial` / `corpus` / `checkpoint` / `coverage_frontier` / `dictionary`). This does **not**
relax the single-writer rule: a subagent never writes the DB and never writes audit *data* files —
the orchestrator (sole writer) records every `fuzz_runs` row (engine + sanitizer config, coverage
measurement, `uncovered_frontier[]`, `skip_reason`) and every crash/leak as
`gr_findings(finding_kind='fuzz_crash'|'fuzz_divergence')`. A memory-safety crash or a
deterministic LSan leak is G4-satisfied by construction (reproducer input + sanitizer report);
it still re-enters the five-gate Confirm for severity and intended-feature gating.

## Step 1 — pick the entry point

Best targets: parsers, file-format decoders, protocol handlers, deserializers, validation
routines, FFI shims — high branch count, clear byte-in interface. These are the same
"high-value boundaries" the fuzzing lane harnesses.

## Step 2 — minimal harness, then structure the input

```cpp
// libFuzzer (C/C++)
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    if (size < MIN || size > MAX) return 0;   // validate before touching data
    target_function(data, size);
    return 0;                                  // never return non-zero
}
```

For typed/multi-field APIs, don't hand-cast — use **FuzzedDataProvider** (C/C++) or the
**`arbitrary`** crate (Rust) so every bit-flip yields a valid, mutable input:

```cpp
FuzzedDataProvider fdp(data, size);
auto n   = fdp.ConsumeIntegral<uint32_t>();
auto str = fdp.ConsumeBytesWithTerminator<char>(32, 0xFF);
```

- **Interleaved fuzzing** — first byte selects the operation; tests related ops under one shared
  corpus. Good for CRUD/arithmetic families; keep formats narrow (don't fuzz PNG and TCP together).
- **Structure-aware** — `arbitrary` (Rust) or libprotobuf-mutator (C/C++) when the format is too
  structured for raw bytes to get past the parser.

Per-engine entry points: libFuzzer `LLVMFuzzerTestOneInput`; AFL++ persistent
`while (__AFL_LOOP(N))`; cargo-fuzz `fuzz_target!(|data: &[u8]|)`; Atheris
`atheris.Fuzz()` over `TestOneInput(data)`; Go `f.Fuzz(func(t, b []byte){...})`.

## Step 3 — obey the harness rules (or the campaign is wasted)

| Rule | Why |
|---|---|
| Handle every input size | fuzzer sends empty/tiny/huge — harness must not crash itself |
| Never call `exit()` | kills the fuzzer process; use `abort()` in the SUT for real faults |
| Maintain determinism | same input → same behavior, or crashes don't reproduce |
| Reset global/static state per iteration | otherwise crashes depend on iteration N, not the input |
| Be fast (100s–1000s exec/s) | no logging, no blocking I/O, mock the network |
| Free everything; join threads | leaks/threads exhaust the campaign |
| Narrow targets | one format per harness so the corpus stays useful |

## Step 4 — remove fuzzing obstacles (patch the SUT)

The SUT often blocks the fuzzer; patch it in the fuzz build (not production):

- **Checksums / magic / signature checks** — stub them to always pass (e.g. `return CRC_OK`), or
  the fuzzer wastes all energy guessing a 32-bit constant. Re-validate crashes against the
  *unpatched* target before reporting (a checksum-stub-only crash may be unreachable in prod).
- **`exit()` in the SUT** → `abort()` so libFuzzer/ASan catch it.
- **Non-determinism** — seed `rand()`/PRNG from fuzz bytes; mock time/PID/`/dev/urandom`.
- **Heavy logging** — compile it out for speed.

### The two-build rule (reconciles patch-to-reach with the L5 ZERO-MOCKING doctrine)

Fuzz-harness patching and the mandatory ZERO-MOCKING PoC doctrine (`references/phases/poc-constraints.md`)
are **not** in conflict — they apply to two different builds:

1. **Discovery build (patch allowed, reach-only).** The fuzz build MAY apply reach-only patches —
   checksum/magic/length stubs, `exit()`→`abort()`, RNG seeding from fuzz bytes, logging-off.
   Nothing that *creates* a bug; only what lets the fuzzer past a wall. Every applied patch is
   recorded in the `fuzz_runs.coverage_json` config so the patch set is auditable.
2. **Candidate, not confirmed.** A crash from the discovery build enters as
   `gr_findings(finding_kind='fuzz_crash')` at `confirmation_status='candidate'` — never confirmed
   on the strength of the patched build alone.
3. **Unmodified replay is the G4 gate.** Confirm's reproduction gate (G4) REQUIRES the crash to
   replay on the **unmodified production build**. If it replays → G4 satisfied. If it cannot
   replay unmodified (it only existed behind a stubbed checksum) → it is **refuted / demoted to an
   Observation**, not a finding.
4. **The L5 PoC bundle uses the unmodified target only** — zero mocking, per `poc-constraints.md`.
   The discovery patch never appears in the shipped PoC.

So: patch freely to *find*, prove on the *unmodified* build to *confirm*. A stubbed-checksum crash
that won't reproduce on the real binary is exactly the false positive this rule kills.

> **Unmodified ≠ sanitizer-free — a third, separate condition.** "Unmodified" above means *no
> reach patches*; the discovery harness is still typically an `-fsanitize=*` build. Confirmation
> additionally requires the crash (or observable impact) to replay on a **vanilla, non-sanitizer
> build** — ideally the official release artifact. The sanitizer report proves the bug *class*; the
> non-instrumented reproduction proves real-world *impact*. A crash that fires only under sanitizer
> instrumentation stays Candidate. Full rule: `references/phases/poc-constraints.md`
> § "Sanitizer-confirmed → vanilla-build reproduction is MANDATORY".

## Step 5 — break magic-value walls with a dictionary

Coverage that flat-lines at a `if (buf == 0x7F454C46)` wall means the fuzzer can't guess the
constant. Extract magic values / tokens / keywords into a dictionary and feed it
(`-dict=` libFuzzer / AFL++). Persist it as a `fuzz_artifacts(artifact_kind='dictionary')` ref.

```
# magic.dict
"\x7F\x45\x4C\x46"
keyword_login
```

## Step 6 — sanitizers (detect more than just segfaults)

| Sanitizer | Catches | Flag |
|---|---|---|
| **ASan** | OOB read/write, use-after-free, double-free | `-fsanitize=address` |
| **UBSan** | integer overflow, shift UB, alignment, bad casts | `-fsanitize=undefined` (`,integer`) |
| **MSan** | use of uninitialized memory | `-fsanitize=memory` (separate build) |
| **LSan** | leaks — a **first-class** C/C++ objective | on by default with ASan; `detect_leaks=1` |

Build `-g -O1` for usable stack traces. Rust: cargo-fuzz wires sanitizers; add Miri for UB on the
unit level. JVM: Jazzer. Go: `go test -fuzz` + the race detector.

## Step 7 — measure coverage (technique; the contract lives in the lane)

Coverage is how you know the harness reaches the target. Workflow:

```bash
# build instrumented, run corpus, report
clang++ -fprofile-instr-generate -fcoverage-mapping -O1 harness.cc -o cov
LLVM_PROFILE_FILE=c.profraw ./cov corpus/
llvm-profdata merge -sparse c.profraw -o c.profdata
llvm-cov report ./cov -instr-profile=c.profdata
```

Use the **post-campaign corpus** for coverage (reproducible), not live fuzzer stats. Fork per
input when the corpus contains crashers so coverage still generates. A flat plateau →
add dictionary entries / seeds (`seed-corpus-generation-lane.md`) or improve the harness; each
uncovered frontier function is fed forward so the next round fuzzes it first.

What a run must *record* about coverage — the gated objective (measurement +
`uncovered_frontier[]`), the saturation/stopping criterion, and the DB gates that enforce it —
is owned by `references/v2/fuzzing-lane.md` §8/§8a. This file is the technique; that section is
the contract. Don't re-assert the thresholds here.

## Adjacent: crypto testing (when the target ships crypto)

Two ToB techniques worth a lane-level note (not a mandatory lane): **Wycheproof** test vectors for
known crypto-API edge cases (weak curves, signature malleability, padding), and **constant-time
testing** (dudect/`ctgrind`/`timecop`) for secret-dependent branches/timing in comparisons and
key handling. Treat a Wycheproof failure or a measured timing leak as a `gr_findings` candidate
with the reproducer as its G4 artifact.

## Where this plugs in

- **Phase 1.5 `boundary_fuzz_lane`** — applies Steps 1–7 at each high-value boundary.
- **Phase 0.75 `isolation_fuzz_lane`** — same craft, scoped to one isolated defense + bypass corpus.
- **Phase 1.4 seed lanes** — Step 5 dictionaries complement synthesized seeds.
