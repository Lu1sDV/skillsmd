# 0xdea Semgrep Rules — C/C++ Vulnerability Research Pack

> Marco Ivaldi's (`raptor@0xdeadbeef.info`) community C/C++ Semgrep rule set, purpose-built for
> **vulnerability research** — not compliance. 50 rules covering the full native-code bug taxonomy:
> buffer overflows, integer arithmetic, format strings, memory management, command injection, race
> conditions, privilege management, and DoS. All rules carry CWE/OWASP metadata and severity tiers.
>
> **Reuse-first doctrine**: before authoring a custom rule for a C/C++ sink, check this pack. If a
> rule exists and matches, reuse it — authoring a duplicate is waste
> (`references/methodology/semgrep-rule-authoring.md` §When to author vs reuse). This file is the
> companion catalog; the ingest contract lives in `references/methodology/tool-ingest-recipes.md`
> §2 and §2.1.

Source: <https://github.com/0xdea/semgrep-rules>

---

## Invocation — three severity tiers

```bash
# clone once; reference from audit workspace
git clone https://github.com/0xdea/semgrep-rules "$TOOLS_DIR/0xdea-semgrep-rules"

# Tier 1 — quick wins (ERROR only; lowest FP rate)
semgrep --severity ERROR \
  --config "$TOOLS_DIR/0xdea-semgrep-rules/rules" "$TARGET_SRC"

# Tier 2 — recommended scan (ERROR + WARNING)
semgrep --severity ERROR --severity WARNING \
  --config "$TOOLS_DIR/0xdea-semgrep-rules/rules" "$TARGET_SRC"

# Tier 3 — full scan (includes INFO/noisy rules; expect more FP)
semgrep --config "$TOOLS_DIR/0xdea-semgrep-rules/rules" "$TARGET_SRC"
```

Add `--no-git-ignore` to scan files regardless of `.gitignore` tracking status (common in firmware /
vendor trees where source is extracted, not checked out).

**Layer with the official registry pack for C/C++:**
```bash
semgrep --severity ERROR --severity WARNING \
  --config p/c --config p/cpp \
  --config "$TOOLS_DIR/0xdea-semgrep-rules/rules" \
  --json --output "$AUDIT_DIR/semgrep-c.json" \
  "$TARGET_SRC"
```

### SARIF output + VS Code SARIF Explorer workflow

```bash
semgrep --sarif \
  --sarif-output "$AUDIT_DIR/SEMGREP.sarif" \
  --config "$TOOLS_DIR/0xdea-semgrep-rules/rules" \
  "$TARGET_SRC"
# open the directory in VS Code; open SEMGREP.sarif with the SARIF Explorer extension
code "$TARGET_SRC"
```

SARIF output is machine-readable and ingests cleanly via the shared contract
(`tool-ingest-recipes.md` §0 and §2) — prefer SARIF over scraped stdout for orchestrator ingest.

---

## Rule catalog

All rule IDs use the `raptor-` prefix. Severity key: **E** = ERROR (Tier 1), **W** = WARNING
(Tier 2), **I** = INFO (Tier 3 / full scan only).

### Buffer overflows

| Rule ID | Sv | CWE | What it flags |
|---|---|---|---|
| `raptor-insecure-api-gets` | **E** | CWE-120 | Use of `gets` (unconditionally dangerous) |
| `raptor-insecure-api-strcpy-strcat` | W | CWE-120 | `strcpy`, `stpcpy`, `strcat` — no bound |
| `raptor-insecure-api-sprintf-vsprintf` | W | CWE-120 | `sprintf`, `vsprintf` — no bound |
| `raptor-insecure-api-scanf` | W | CWE-120 | `scanf` family without width specifier |
| `raptor-incorrect-use-of-strncat` | W | CWE-120 | Wrong size arg to `strncat` (n = remaining, not total) |
| `raptor-use-of-source-size-in-copy` | W | CWE-120 | Source size passed to `strncpy`/`memcpy`/`snprintf` — should be dest size |
| `raptor-incorrect-use-of-sizeof` | W | CWE-131 | `sizeof` applied to a pointer, not its target |
| `raptor-unterminated-string-strncpy` | W | CWE-170 | No explicit NUL after `strncpy`/`stpncpy` |
| `raptor-off-by-one` | W | CWE-193, CWE-787 | Array index == size; `strlen`-based index with no `+1`; `strncat` without `−1` |
| `raptor-unsafe-ret-snprintf-vsnprintf` | W | CWE-120 | `snprintf` return used as write index (returns *would-have-written* length) |
| `raptor-unsafe-ret-strlcpy-strlcat` | W | CWE-120 | `strlcpy`/`strlcat` return used unsafely (returns *desired* length, not copied) |
| `raptor-pointer-subtraction` | W | CWE-469 | Pointer subtraction to determine size (UB on non-contiguous objects) |
| `raptor-write-into-stack-buffer` | W | CWE-121 | Direct write into a stack-allocated buffer |

### Integer overflows

| Rule ID | Sv | CWE | What it flags |
|---|---|---|---|
| `raptor-integer-wraparound` | W | CWE-190, CWE-128, CWE-131 | Integer wraparound expressions (often in allocation size computation) |
| `raptor-unsafe-strlen` | W | CWE-190, CWE-197 | `strlen` return cast to `short`/`char` — truncates on long strings |
| `raptor-integer-truncation` | W | CWE-197 | Truncation on assignment to narrower integer type |
| `raptor-signed-unsigned-conversion` | W | CWE-195, CWE-196 | Signed/unsigned conversion errors (negative → huge `size_t`) |
| `raptor-incorrect-unsigned-comparison` | W | CWE-697 | Checking if an unsigned variable is negative (always false) |

### Format strings

| Rule ID | Sv | CWE | What it flags |
|---|---|---|---|
| `raptor-format-string-bugs` | **E** | CWE-134 | Non-literal format string in `printf`/`fprintf`/`snprintf`/`syslog`/`err`/`warn` family |

### Memory management

| Rule ID | Sv | CWE | What it flags |
|---|---|---|---|
| `raptor-insecure-api-alloca` | **E** | CWE-676, CWE-1325 | Use of `alloca` — stack exhaustion / stack clash with tainted size |
| `raptor-use-after-free` | **E** | CWE-416 | Pointer read/write/return/pass after `free` |
| `raptor-double-free` | **E** | CWE-415 | Calling `free` twice on the same pointer |
| `raptor-incorrect-use-of-free` | **E** | CWE-590 | Calling `free` on stack-allocated or non-heap memory |
| `raptor-unchecked-ret-malloc` | W | CWE-476 | Unchecked return of `malloc`/`calloc`/`realloc` (NULL deref on OOM) |
| `raptor-putenv-stack-var` | W | CWE-686 | `putenv` with a stack-allocated variable (dangling pointer in env after return) |
| `raptor-ret-stack-address` | W | CWE-562 | Returning the address of a stack-allocated variable |
| `raptor-mismatched-memory-management` | W | CWE-762 | C alloc/free mismatch (`malloc`+`delete`, `new`+`free`) |
| `raptor-mismatched-memory-management-cpp` | W | CWE-762 | C++ `new`/`delete[]` / `new[]`/`delete` mismatch |
| `raptor-memory-address-exposure` | W | CWE-200 | Leaking internal memory addresses (info-leak, ASLR defeat) |

### Command injection

| Rule ID | Sv | CWE | What it flags |
|---|---|---|---|
| `raptor-command-injection` | **E** | CWE-78, CWE-88, CWE-676 | Tainted arg to `system()` or `popen()` |

### Race conditions

| Rule ID | Sv | CWE | What it flags |
|---|---|---|---|
| `raptor-insecure-api-access-stat` | W | CWE-367 | TOCTOU: `access`/`stat`/`lstat` check before use |
| `raptor-insecure-api-mktemp-tmpnam-tempnam` | W | CWE-377, CWE-367 | Insecure temp-file creation (race between name gen and open) |
| `raptor-insecure-api-signal` | W | CWE-364 | `signal()` — unreliable; use `sigaction()` |

### Privilege management

| Rule ID | Sv | CWE | What it flags |
|---|---|---|---|
| `raptor-incorrect-order-setuid-setgid` | **E** | CWE-696 | `setuid`/`setgid`/`setgroups` called in wrong order (drop supplementary groups first) |
| `raptor-unchecked-ret-setuid-seteuid` | W | CWE-273 | Unchecked return of `setuid`/`seteuid` (drop failure goes undetected) |

### Denial of service

| Rule ID | Sv | CWE | What it flags |
|---|---|---|---|
| `raptor-regex-dos` | W | CWE-400 | Regex with exponential backtracking potential (ReDoS) |

### Miscellaneous (C/C++)

| Rule ID | Sv | CWE | What it flags |
|---|---|---|---|
| `raptor-incorrect-use-of-memset` | W | CWE-688 | `memset` args in wrong order (value/size swapped) |
| `raptor-insecure-api-rand-srand` | W | CWE-338 | `rand`/`srand` — not cryptographically secure |
| `raptor-overlapping-source-destination` | W | CWE-119 | Source and destination overlap in `memcpy`/`strcpy` (UB) |
| `raptor-suspicious-assert` | W | CWE-617 | Size check via `assert` (stripped in release builds) |
| `raptor-interesting-api-calls` | W | CWE-676 | **Candidate-point scan** — all potentially dangerous API calls (see §Candidate-point scanner) |
| `raptor-unchecked-ret-scanf` | W | CWE-252 | Unchecked return of `scanf` family (unvalidated input count) |
| `raptor-insecure-api-ato` | W | CWE-676 | `atoi`/`atol`/`atof` — no error detection on invalid input |
| `raptor-high-entropy-assignment` | **I** | CWE-798 | Assignment of high-entropy value (possible hardcoded secret) |
| `raptor-argv-envp-access` | **I** | CWE-88 | `argv`/`envp` access (taint source enumeration — see §Triage helpers) |
| `raptor-missing-default-in-switch` | W | CWE-478 | Missing `default` case in `switch` |
| `raptor-missing-break-in-switch` | W | CWE-484 | Missing `break` in `switch` (unintentional fall-through) |
| `raptor-missing-return` | W | CWE-394 | Missing `return` in non-void function |
| `raptor-typos` | **I** | — | Operator/identifier typos with security implications (e.g., `=` vs `==` in condition) |

### Generic

| Rule ID | Sv | CWE | What it flags |
|---|---|---|---|
| `raptor-bad-words` | **I** | CWE-546, CWE-615 | Suspicious comments (`TODO`/`BUG`/`HACK`/`FIXME`/`CVE-`/`unsafe`/`overflow`) and credential keywords in source — see §Triage helpers |

---

## Candidate-point scanner — `raptor-interesting-api-calls`

Run this rule **alone** as the first pass on an unknown codebase. It is the Semgrep analogue of
`Rhabdomancer.java` (the companion Ghidra script): it flags every call to a potentially dangerous
API function without trying to determine reachability or taint. The result is a **candidate-point
map** — a ranked list of hot spots to backtrace from.

```bash
semgrep --config "$TOOLS_DIR/0xdea-semgrep-rules/rules/c/interesting-api-calls.yaml" \
  --json --output "$AUDIT_DIR/candidate-points.json" "$TARGET_SRC"
```

The rule covers (in one pass): strcpy/strcat/stpcpy family, printf family, scanf family, gets
family, env access (getenv/putenv/setenv), memcpy/memmove with non-constant length, alloca/allocf,
exec/system/spawn, open/pipe/read/recv, fork, rand/srand, tmp-file functions, file-op functions,
priv-management functions, string-conversion functions, kernel copy_from/to_user, and more.

Ingest each hit as a **candidate `sinks` row**, not a `gr_findings` row — these are locations, not
findings. The forward-slicing lanes (`references/methodology/forward-slicing-lanes.md`) then trace
source→sink reachability.

---

## Triage helpers

These low-severity rules are informational leads, not findings:

- **`raptor-argv-envp-access`** — enumerates every `argv[*]` / `envp[*]` access: the attacker's
  primary taint sources in CLI tools and suid binaries. Run at Tier 3 to build a source map before
  slicing. Ingest as candidate `sources` rows.

- **`raptor-high-entropy-assignment`** — finds likely hardcoded secrets (keys, tokens). Produces
  false positives on magic constants; worth a human scan pass before ingest.

- **`raptor-bad-words`** (`languages: generic`) — regex over source text for `TODO`/`BUG`/
  `HACK`/`FIXME`/`CVE-`/`unsafe`/`overflow`/`password`/`token`/`secret`. Run against any language.
  Surfaces developer self-annotations of known weak spots — high signal, high noise. Feed into the
  attention-deficit map (`references/phases/attention-deficit.md`), not directly into findings.

---

## Cluster-to-rule mapping (c-cpp.md alignment)

| `references/sinks/c-cpp.md` cluster | Primary 0xdea rules to run |
|---|---|
| Cluster 1 — Buffer write sinks | `raptor-insecure-api-gets`, `raptor-insecure-api-strcpy-strcat`, `raptor-insecure-api-sprintf-vsprintf`, `raptor-insecure-api-scanf`, `raptor-incorrect-use-of-strncat`, `raptor-use-of-source-size-in-copy`, `raptor-incorrect-use-of-sizeof`, `raptor-unterminated-string-strncpy`, `raptor-off-by-one`, `raptor-unsafe-ret-snprintf-vsnprintf`, `raptor-unsafe-ret-strlcpy-strlcat`, `raptor-write-into-stack-buffer` |
| Cluster 2 — Object lifecycle (UAF/double-free/leak) | `raptor-use-after-free`, `raptor-double-free`, `raptor-incorrect-use-of-free`, `raptor-unchecked-ret-malloc`, `raptor-putenv-stack-var`, `raptor-ret-stack-address`, `raptor-mismatched-memory-management`, `raptor-mismatched-memory-management-cpp`, `raptor-insecure-api-alloca` |
| Cluster 3 — Arithmetic & type | `raptor-integer-wraparound`, `raptor-unsafe-strlen`, `raptor-integer-truncation`, `raptor-signed-unsigned-conversion`, `raptor-incorrect-unsigned-comparison`, `raptor-pointer-subtraction` |
| Cluster 4 — Syscall / libc return values | `raptor-unchecked-ret-malloc`, `raptor-unchecked-ret-scanf`, `raptor-unchecked-ret-setuid-seteuid` |
| Cluster 5 — Concurrency / TOCTOU | `raptor-insecure-api-access-stat`, `raptor-insecure-api-mktemp-tmpnam-tempnam`, `raptor-insecure-api-signal` |
| Cluster 6 — Ambient state (env, privilege, path) | `raptor-incorrect-order-setuid-setgid`, `raptor-unchecked-ret-setuid-seteuid`, `raptor-command-injection`, `raptor-insecure-api-rand-srand`, `raptor-argv-envp-access` |
| Cluster 7 — Static hygiene (format, misc) | `raptor-format-string-bugs`, `raptor-incorrect-use-of-memset`, `raptor-overlapping-source-destination`, `raptor-suspicious-assert`, `raptor-missing-default-in-switch`, `raptor-missing-break-in-switch`, `raptor-missing-return`, `raptor-typos` |

---

## Ghidra decompiler → Semgrep workflow (binary targets)

When source is unavailable, use Ghidra to decompile the binary to C pseudocode, then run the
0xdea rules on the pseudocode output. This is the `Rhabdomancer.java` sister workflow:

1. **Decompile with Ghidra headless analyzer** — export pseudocode for all functions to `.c` files
   (see `references/binary/binary-stack-triggers.md` for the headless setup; the `ghidra` skill
   automates this).
2. **Run 0xdea rules on the pseudocode directory:**
   ```bash
   semgrep --severity ERROR --severity WARNING \
     --config "$TOOLS_DIR/0xdea-semgrep-rules/rules" \
     --no-git-ignore \
     --json --output "$AUDIT_DIR/semgrep-decompiled.json" \
     "$GHIDRA_EXPORT_DIR"
   ```
3. **Adjust FP expectations** — Ghidra pseudocode often introduces artificial casts, type
   mismatches, and synthetic variable names that trip arithmetic rules (`integer-truncation`,
   `signed-unsigned-conversion`). Tier-1 ERROR-only hits are most reliable on decompiled output.
4. **Ingest the same way** as source-level hits — `finding_kind='semgrep_pattern'` at
   `candidate`; `payload.evidence_path` points to the decompiled file, not the binary. Record
   `payload.tool_version` with the Ghidra version and the `analysis_context='decompiled'` key so
   triage knows the confidence is lower than native source.

Blog posts from the author: <https://hnsecurity.it/blog/automating-binary-vulnerability-discovery-with-ghidra-and-semgrep>

---

## Tuning and false-positive management

| Noisy rule | Mitigation |
|---|---|
| `raptor-interesting-api-calls` | Ingest as candidate *sinks*, not findings; triage by slice reachability |
| `raptor-high-entropy-assignment` | Manual review pass before ingest; suppress magic constants with `# nosemgrep` |
| `raptor-argv-envp-access` | Ingest as candidate *sources*; don't emit as `gr_findings` |
| `raptor-bad-words` | Feed attention-deficit map; no finding rows |
| `raptor-integer-truncation` / `raptor-signed-unsigned-conversion` on decompiled code | Tier-1 ERROR-only on decompiler output; demote these two rules to INFO when pseudocode is the source |

The author uses SARIF Explorer in VS Code to triage: save `--sarif-output`, open with the
`trailofbits.sarif-explorer` extension, filter by rule ID and path, and suppress FPs inline.

---

## Where this plugs in

- **Phase L3.5 (Tech-Stack Discovery / SAST layer)** — run Tier 2 (ERROR+WARNING) as the
  standard C/C++ Semgrep pass, layered on top of `p/c` + `p/cpp`. Run `raptor-interesting-api-calls`
  alone first to populate candidate sinks.
- **Phase L0 (Recency pass)** — run Tier 1 (ERROR) on changed files only for cheap regression
  coverage.
- **Binary / firmware targets** — Ghidra decompile then Tier 1 on pseudocode (see §Ghidra
  workflow above).
- **Ingest** — all hits via `references/methodology/tool-ingest-recipes.md` §2 and §2.1.
