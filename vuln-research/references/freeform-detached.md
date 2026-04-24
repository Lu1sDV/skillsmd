# Freeform Analysis — Detached vs Grounded

The `/vuln-swarm --freeform=` flag selects the posture of any freeform-strategy agent in the pipeline (used as one of the orthogonal strategies in MEDIUM/DEEP Phase 2a, and as the primary analysis agent(s) in LOW). Default is **detached**.

## Why detached-by-default

Skill taxonomy is valuable for *directed* hunts — "is this a Java deserialization site?" — but it biases the freeform agent toward patterns the skill already knows. The freeform lane exists precisely to catch classes the skill does **not** enumerate: novel business-logic bugs, domain-specific invariants, trust boundaries the skill's boilerplate sources/sinks don't model, and framework-specific footguns that haven't reached the sink catalog yet.

Loading the skill into the freeform agent's context reliably causes it to reframe observations in skill-vocabulary and drop anomalies that don't fit a known bucket. Detaching it preserves the signal.

## Contract

### Detached (`--freeform=detached`)

**Inputs the agent receives:**
- Target repo slice(s) / code excerpts relevant to its module
- PATCH SEEDS from `0-seeds.json` filtered to its module (optional, as hypothesis templates only — no taxonomy labels attached)
- A minimal brief: "find security-relevant problems. Report file:line, root cause, impact, and a source→sink trace where applicable. Do not limit your search to known bug classes."

**Inputs the agent does NOT receive:**
- `vuln-research/SKILL.md` or its references
- `sinks-catalog.md` or per-language sink files
- Bug-class labels, severity rubrics, or exploitation gate criteria

**Output contract:**
- Same artifact shape as grounded (`2a-<module>-freeform.{md,json}` or LOW's single-agent output), but `bug_class` may be a free-text observation instead of a skill-enumerated class.
- Findings still flow through **Phase 2.5 verification** (re-trace + judge, plus DAG-independent in DEEP). Verification agents **are** grounded in the skill — they re-classify the finding into skill taxonomy where possible.
- Findings still flow through **Phase 7 (Exploitability Gate)** in synthesis.

### Grounded (`--freeform=grounded`)

**Inputs the agent receives:**
- Everything in detached, PLUS
- `vuln-research/SKILL.md` + relevant domain references + `sinks/<lang>.md` for the detected stack
- Explicit instruction that the skill's bug-class list is a starting frame, not a limit

**When to prefer grounded:**
- Target is a well-known stack with heavy skill coverage (Java web apps, Node.js services, PHP CMS) — the skill's sink catalog is likely to surface most real bugs and freeform divergence is low-value
- Auditor wants consistency of terminology across the report
- Time/token budget is tight and false-positive rate needs to be minimized

**When to prefer detached (default):**
- Target uses a domain-specific framework not covered in the skill
- Target has heavy business logic (payments, access control, multi-tenant boundaries)
- Target is an embedded/native/systems codebase where the skill's web-centric bug classes may underfit
- The audit is **exploratory** — goal is to find surprises, not to grade against a known rubric

## Trade-offs

| Dimension | Detached | Grounded |
|-----------|----------|----------|
| Novel-class recall | High | Low–medium |
| Known-class precision | Medium | High |
| Terminology consistency | Low (freeform prose) | High (skill-aligned) |
| False-positive rate before Phase 2.5 | Higher | Lower |
| Verification cost | Higher (more to re-classify) | Lower |
| Report coherence before synthesis | Lower | Higher |

Phase 2.5 and Phase 3 synthesis normalize both outputs into the same `findings.json` schema, so the downstream deliverable shape is identical. The difference is **what the agent sees before emitting**.

## Interaction with other strategies

The orthogonal-strategy rule (`references/swarm-pipeline.md` § Orthogonal Strategies) requires at least two distinct strategies across the Phase 2a agent pool. Freeform (detached or grounded) counts as **one** strategy. A DEEP run with four strategies (source-forward, sink-backward, seed-hypothesis, freeform) still satisfies the rule whether freeform is detached or grounded.

If `--freeform=detached` and the module has no PATCH SEEDS filtered to it, the freeform agent receives **only** the code slices and the minimal brief. This is intentional — true detachment means the agent forms its own priors from the code.
