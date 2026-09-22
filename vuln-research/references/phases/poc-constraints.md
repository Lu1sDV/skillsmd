# PoC Constraints (Mandatory)

> **Load when**: Load at Phase L5 (Exploitation) when building a PoC, OR when the five-gate doctrine's G4 reproduction-artifact gate is being evaluated.

The PoC must be a **realistic, end-to-end victim↔attacker interaction** against the **unmodified target running in a production-equivalent environment**.

> **⛔ ZERO MOCKING IN THE TESTING ENVIRONMENT — NO EXCEPTIONS**
>
> No mocked APIs. No simulated responses. No stub servers. No in-memory fakes. No patched binaries. No injected headers. No synthetic database states. No `DEBUG=true`. No test-only flags. No flipped feature toggles. No modified `docker-compose.yml` target services. **If the precondition does not exist in an unmodified production deployment, it is not a valid reproduction environment — and the finding cannot be confirmed.**

> **Fuzz-discovery exception (the two-build rule).** A *fuzz discovery* build MAY carry reach-only patches (checksum/magic stubs, `exit()`→`abort()`, RNG seeding, logging-off) — that is harness craft, not PoC mocking. But a fuzz crash stays **Candidate** until it replays on the **unmodified production build** (this G4 gate); a crash that only fires behind a stubbed check is refuted, and the shipped PoC bundle uses the unmodified target only. Full rule: `references/methodology/fuzz-harness-craft.md` § "The two-build rule".

> **🧪 Sanitizer-confirmed → vanilla-build reproduction is MANDATORY.** If a finding was confirmed under any sanitizer or instrumented runtime — ASan, MSan, TSan, UBSan, LSan, Valgrind/Memcheck, GWP-ASan, hardened/debug allocators, or equivalent — the sanitizer report is **diagnostic evidence only**: it proves the bug *class*, not real-world impact. The shipped PoC MUST additionally reproduce the issue on a **vanilla build carrying NO sanitizer instrumentation** (no `-fsanitize=*`, no debug/hardened allocator, standard optimization level). Sanitizers change allocator layout, insert redzones, and alter timing; a crash that fires *only* under instrumentation may be a sanitizer artifact, not an exploitable condition.
> - **Prefer an official release.** If the project ships official release binaries/builds, reproduce against that exact artifact — it is what users actually run — rather than a locally compiled vanilla build. Record the release version / tag / commit used.
> - **Diagnostic + impact, both required.** Ship the sanitizer report (proves the class) *and* the vanilla/release reproduction (proves real-world impact). The two are complementary, not interchangeable.
> - **If vanilla won't crash.** Some bugs (a few-byte OOB read, a benign-looking UAF) won't fault a vanilla build. Observable real-world impact must still be demonstrated on the vanilla/release build — crash, info leak, memory corruption, or control-flow divergence. A finding that manifests **only** under sanitizer instrumentation and shows no vanilla/release impact stays **Candidate** (or downgrades to a hardening/robustness note); it is not a confirmed vulnerability.

- If the target app ships with a `docker-compose.yml`: use it as-is. You may add a separate attacker/victim container on the **same network** (e.g. `docker run --network=<project>_default ...`), but never modify the target's own container definition, environment, config, or behavior.
- If the target app has **no** container setup: create two networks — one for the **victim** (running the unmodified app), one for the **attacker** (exploit tooling). The app runs identically to how it would in production.
- **No altered configs, no debug flags, no feature toggles.** The app must run as close to production as possible. If exploitation requires a non-default setting, that must be documented as a prerequisite, not baked into the environment.
- **Responsible disclosure principle:** nothing in the PoC environment changes the normal behavior of the application. If your exploit only works against a modified version of the app, it is not a confirmed vulnerability — it is a misconfiguration finding.

## Two Required PoC Forms

**Every confirmed finding ships two PoC forms.** Missing either → Candidate.

| Form | Audience | Description |
|------|----------|-------------|
| **Step-by-step (explanatory)** | Reviewer / triager / vendor | Narrative walkthrough: bug cause → source→sink trace → each exploit step with only necessary commands shown and explained. Reviewer understands the bug without running anything. |
| **Full bundled PoC** | Reproducer / CI / verification | Self-contained, one-command runnable package. Dependency versions pinned; no host-local state assumed; runs on a clean clone without manual setup steps beyond the documented prerequisites. Third party clones, runs, sees exploit work. |

### Target-class PoC form requirements

The bundled form content varies by target class. Use the row matching your finding:

| Target class | Form-2 bundled PoC requirements | Realism Gate minimum |
|---|---|---|
| **Web / server** | `docker compose up && ./poc.sh`; compose file, scripts, payloads, README with one command. No `DEBUG=true` on target service. | App runs unmodified; no mocked APIs; callback container on shared network for OOB proof. |
| **Binary / memory-safety** | Minimized reproducer input + sanitizer report (ASan / MSan / UBSan) **and** the reproduction on a **non-sanitizer vanilla build** (prefer the official release artifact) + exact command for each. Include both build invocations (the `-fsanitize=*` diagnostic build and the no-instrumentation build) and the exact binary version / tag / commit. | Sanitizer output confirms the class (heap-use-after-free, stack-buffer-overflow, etc.) **and** the crash / observable impact reproduces on an unpatched, **non-instrumented** vanilla (or official-release) build; no source modifications. A sanitizer-only crash with no vanilla impact is not confirmed. |
| **Fuzz crash** | Minimized corpus entry (produced by `afl-tmin` / `libFuzzer -minimize_crash`) + sanitizer or crash log excerpt + reproduction via a **non-sanitizer build** of the harness/target. Include the harness invocation command for each build. | Crash reproduces without the fuzzer — via direct invocation with the minimized input — **and** on a non-instrumented (no `-fsanitize=*`) build, ideally the official release; include `ASAN_OPTIONS=detect_leaks=0` or equivalent only for the diagnostic build. |
| **Library (no server)** | Minimal driver program (< 30 lines) that calls the vulnerable API + expected output / crash. Pinned library version in dependency manifest. | Driver compiles and runs on a clean checkout with only standard toolchain; no vendored patches. |
| **Mobile (Android / iOS)** | APK/IPA + ADB / `xcrun simctl` invocation script that triggers the finding, or a Frida script with step-by-step. Include target OS version and device class (emulator or real device, model). | App installed from the unmodified release artifact (store build or released APK/IPA); no recompilation, no debug builds unless the finding only manifests in debug mode (which must be stated as a prerequisite). |

## Attacker Scenario Harness

The bundled PoC directory described above (class-specific form per the table above) **is the
attacker scenario harness** — the gold standard of proof for any finding in this pipeline.

**Every finding is non-confirmed by default until an attacker scenario harness demonstrates
exploitation against the unmodified target.** The burden is on the analyst to produce the
harness; a finding without one remains a candidate regardless of how strong the static or
dynamic evidence is.

This is not a new gate. The existing Realism Gate (SKILL.md § Phase L8 Proof Collection)
and Gate 4 (reproduction artifact, `references/v2/confirmation-rigor-doctrine.md`) already
enforce this requirement. This section names the doctrine: **default-deny until a harness
proves otherwise.** The ZERO MOCKING rule above and the two-form PoC requirement are the
operational expression of that doctrine; they are unchanged.

### Schema enforcement intent

Gate 4 promotion in `gr_findings` signals harness completion via two fields:

| Field | Meaning |
|---|---|
| `repro_artifact_path` | Non-NULL pointer to the bundled PoC directory (or minimized reproducer for binary/fuzz findings). A NULL value means the harness has not been produced — the finding cannot leave Candidate. |
| `confirmed_without_harness` | Boolean gate signal. If TRUE, v_coverage flags this finding as `confirmed_without_harness` (a coverage red). A finding promoted to Confirmed while this signal is true has bypassed the harness requirement and must be re-examined. |

The v_coverage gate (`confirmed_without_harness > 0`) catches any finding where Gate 4 was
satisfied by a payload string alone rather than a runnable harness. See
`references/v2/confirmation-rigor-doctrine.md` § Gate 4 for the full gate definition.

## Cross-Reference

See `../phases/audit-poc-report.md` for the full proof checklist, Docker lab setup instructions, and Playwright templates; see `../phases/bug-bounty-triage.md` for the complete single-finding submission template and the gold-standard worked example.
