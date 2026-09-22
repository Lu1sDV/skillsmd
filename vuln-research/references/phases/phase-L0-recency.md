# Phase L0 — Recency Subagent Prompt & PATCH SEEDS

Load this file when Phase L0 (Latest Commits Security Review) fires — i.e. the target has git history and the orchestrator is dispatching the single recency-review subagent. The prompt block is verbatim; the PATCH SEEDS schema is the optional deliverable for downstream multi-agent runs.

---

### Subagent Prompt

Spawn exactly one agent with this prompt:

> You are performing a **focused, narrow-scope** security review of this repository's most recent commits. Inspect repo signals first — tag recency, branch divergence from `main`/`master`, commit cadence, CHANGELOG or release notes — then choose the most informative commit range yourself (e.g., last N commits, since last tag, or branch diff against main). **State the chosen range and justification before reviewing.**
>
> For every file touched by the selected commits, analyze **only the changed hunks and their immediate call graph**. Do not audit code the commits did not touch — that is Phase L3's and Agent Sweep's job, not yours. Consider all bug classes — injection, memory corruption, auth bypass, deserialization, race conditions, type confusion, logic flaws, missing authorization, unsafe defaults, exposed secrets, regressions that reintroduce previously-fixed CVEs, and weakened security controls (removed validators, loosened regex, new `@ts-ignore`/`# type: ignore` on security-adjacent code).
>
> For each finding write: vuln type, affected function/file, source→sink trace, controllability, exploitability assessment (High/Medium/Low), and a suggested payload or PoC direction. Flag commits that touch security-adjacent paths (auth, crypto, input parsing, session handling, access control, deser, SSRF-prone callers) even when no bug is found — the auditor needs to know where recent changes raise risk.
>
> **Fix-bypass analysis (n-day vector):** when a commit *fixes* a security bug, do not trust the fix. Enumerate inputs, encodings, types, code paths, sanitizers and state-machine transitions the patch does **not** cover (e.g., alternate decoder, sibling endpoint, case/normalization differential, race window, deeper nesting, non-string type, second-order sink) and attempt to reach the original sink despite the patch. Incomplete patches are one of the highest-yield n-day sources — treat every security fix as a hypothesis "this specific path is now blocked," then try to falsify it. Apply also the "there ALWAYS is a bypass" paradigm.
>
> Stay **very accurate and very focused**: no speculation, no "theoretical" findings without a controllability trace, no drift into untouched code. If the chosen range surfaces no real vulnerabilities, say so explicitly and list which security-adjacent files were examined so the rest of the audit can trust the recency pass.
>
> **Tooling:** Prefer LSP (`goToDefinition`, `findReferences`, `hover`) when available for resolving the call graph of changed hunks — recency review is high-signal precisely because it stays anchored to actually-touched call sites. Use Grep/Glob for discovery (locating files, finding string patterns), then read enough surrounding context to validate framework wiring, guards, and dynamic dispatch.

### Optional Deliverable: PATCH SEEDS

When a downstream phase will fan out parallel agents (Agent Sweep, Swarm Pipeline, or any multi-agent audit that benefits from hypothesis templates), Phase L0 can emit a second artifact alongside the findings: a **PATCH SEEDS** list extracted from the same commit range. Each seed is a recently-fixed bug or tightened control that downstream agents use as a hypothesis template — "is an unfixed variant of this pattern present elsewhere in the tree?"

Each PATCH SEED record:

| Field | Content |
|-------|---------|
| `affected_file` | Path touched by the fix commit |
| `affected_hunk` | Hunk range or line numbers of the actual fix |
| `fix_summary` | One sentence describing what the patch changed and why |
| `bug_class` | Canonical class label (e.g., `sql-injection`, `missing-authz`, `path-traversal`) |
| `variant_query` | A grep-friendly or structural-search-friendly string downstream agents can use to locate analogous sites |

Emit seeds only for commits that actually fix a bug or tighten a control — not refactors, not style changes, not dependency bumps unless the bump closes a CVE. A seed without a clear `variant_query` is low-value; drop it rather than weaken the set.
