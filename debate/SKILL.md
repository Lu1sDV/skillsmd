---
name: debate
description: >
  Use when a technical decision has 2–4 nameable positions and the user wants
  a recommendation, not open-ended exploration. Triggers include "X vs Y",
  "A or B", "pick one", "contested trade-off", adversarial review, and
  decide-between requests. Skip when analysis is open-ended (use
  superpowers:brainstorming) or the question has no real contest. Keywords:
  debate, decision, contested, trade-off, versus, steelman, adversarial,
  argue.
disable-model-invocation: true
argument-hint: [topic or "A vs B"]
---

# Debate

Runs a bounded, structured multi-agent debate on a contested decision and returns a single recommended answer (or an honest "no clear winner" when positions are genuinely tied).

This skill is self-contained and uses Claude Code's native subagent primitives — no external team-manager dependency.

## When to use this vs `superpowers:brainstorming`

| Use `debate` when | Use `brainstorming` when |
|---|---|
| Positions are nameable upfront (A vs B, or 2–4 named options) | Analysis is open-ended; positions emerge from exploration |
| You want a decision | You want a trade-off map and recommendation from parallel lenses |
| The question is contested (multiple defensible answers exist) | You need Explorer/Analyst/Critic working in parallel without messaging |

If the topic is open-ended design ("design our notification system") or has no real contest ("should we use version control"), stop and suggest the alternative.

## Team Composition

**Fixed at 4 agents** for binary and 3-position topics:

| Slot | Role | Spawn mechanism |
|---|---|---|
| Debater A | Pinned to Position A for the entire run | `Agent(subagent_type="general-purpose", name="debater-a", run_in_background=true, ...)` |
| Debater B | Pinned to Position B for the entire run | `Agent(subagent_type="general-purpose", name="debater-b", run_in_background=true, ...)` |
| Debater C | Pragmatist (binary) OR Position C (3-option) | `Agent(subagent_type="general-purpose", name="debater-c", run_in_background=true, ...)` |
| Judge | Neutral synthesizer; never argues a side | `Agent(subagent_type="general-purpose", name="judge", run_in_background=true, ...)` |

For 4-position topics, add a 5th debater slot. This is the only case the team exceeds 4.

**Pinning is the primary collapse defense.** Debaters may not change position regardless of argument quality. Their job is to argue the best case for their side; the judge finds truth.

See [role-prompts](references/role-prompts.md) for the exact prompt templates used when spawning each slot.

## Subagent mechanics (Claude Code)

This skill relies on three native tools:

- **`Agent`** — spawn a subagent. Use `name` to make it addressable, `run_in_background: true` so it waits for follow-up `SendMessage` calls instead of completing after its first reply.
- **`SendMessage`** — push new content into a named background agent (`to: <agent name>`) during phases 2–4.
- **`TaskStop`** / **`TaskList`** — find and terminate the background agents during Phase 5 cleanup.

Spawn the debaters **in a single message** with multiple parallel `Agent` tool calls so their openings run concurrently (Phase 1 does not allow cross-talk anyway). The Judge is also spawned in parallel but given no work until Phase 4.

**Do not** let subagents message each other directly. All inter-agent traffic is orchestrated by the lead session via `SendMessage`. This preserves the phase gates.

## Workflow

Copy this checklist into your working notes and check off phases as you complete them:

```
- [ ] Phase 0: Framing & user confirmation
- [ ] Phase 1: Opening statements (parallel spawn, no messaging)
- [ ] Phase 2: Rebuttal round (targeted SendMessage)
- [ ] Phase 3: Steelman swap round
- [ ] Phase 4: Judge synthesis → decision document
- [ ] Phase 5: Cleanup (TaskStop all background agents)
```

### Phase 0 — Framing & confirmation

1. Parse `$ARGUMENTS` as the topic. If empty, ask the user for one.
2. Infer 2–4 positions from the topic. Examples:
   - `"monorepo vs polyrepo"` → 2 positions + pragmatist
   - `"Postgres vs MySQL vs SQLite for this workload"` → 3 positions
3. If inference yields fewer than 2 positions, or more than 4, stop and tell the user why (single-agent analysis, or too many positions — split or use `superpowers:brainstorming`).
4. Infer any obvious **out-of-scope** questions — adjacent topics the debate should NOT drift into (e.g. "which CI tool to adopt", "migration ordering"). If none are obvious, leave the field empty and let the user fill it in at confirmation.
5. Pick a default **length preset**:

   | Preset | Phases | When |
   |---|---|---|
   | `quick` | 1 → 4 (openings + judge, no rebuttal/steelman) | Low-stakes or user asks for a fast answer |
   | `standard` | 1 → 2 (×1) → 3 → 4 | **Default** |
   | `deep` | 1 → 2 (×N, default N=2) → 3 → 4 | High-stakes, "thorough" debate |
   | `custom` | explicit `rounds=<N>` override | Any N ≥ 0, where 0 collapses to `quick` and N ≥ 1 runs that many rebuttal rounds before the steelman swap |

   The user may override with `rounds=<N>` at confirmation. `N=0` is equivalent to `quick`; `N ≥ 1` runs exactly that many rebuttal rounds.
6. Present the proposed team, scope, and preset, then wait for user confirmation:

```
Debate: "<topic>"

Positions:
  A: <label>
  B: <label>
  C: <label or "Pragmatist / middle ground">

Out of scope (will NOT be debated):
  - <item 1 or "none inferred — add any if needed">
  - <item 2>

Team:     3 debaters + 1 neutral judge (4 Claude Code subagents, all run_in_background)
Preset:   <quick | standard | deep>
Rounds:   <N> rebuttal round(s) before steelman swap (0 for quick)
Protocol: opening → rebuttal ×N → steelman swap → judge synthesis
Output:   decision document with YAML frontmatter (ephemeral; optional save)

Shall I proceed, or would you like to change positions / scope / preset / rounds?
```

7. Loop on user corrections until confirmed. Do not spawn until confirmed.

### Phase 1 — Opening statements (parallel spawn)

Spawn all 4 subagents in **parallel** — a single assistant message with 4 `Agent` tool calls:

```
Agent(
  description="Debate: Debater A opening",
  subagent_type="general-purpose",
  name="debater-a",
  run_in_background=true,
  prompt="<Debater prompt template from references/role-prompts.md, filled in for Position A, Phase 1 only>"
)
Agent(... name="debater-b", ... Position B ...)
Agent(... name="debater-c", ... Position C or Pragmatist ...)
Agent(
  description="Debate: Judge standby",
  subagent_type="general-purpose",
  name="judge",
  run_in_background=true,
  prompt="<Judge prompt template from references/role-prompts.md. Explicitly instruct the judge to WAIT for the transcript in Phase 4 and produce no output yet — just acknowledge standby.>"
)
```

No inter-agent messaging in this phase — early messaging causes anchoring and collapses positions before they are stated.

Because each debater is `run_in_background=true`, its first output (the opening) arrives as a background notification. Collect all three openings before proceeding.

### Phase 2 — Rebuttal (×N rounds)

Skip this phase entirely when preset is `quick` (equivalently, `rounds=0`).

For each debater, forward the **other** debaters' prior-round outputs via `SendMessage` and ask for:

- Strongest counter to each other position
- Genuine concessions (points where opponents are right)
- Restatement of why their pinned position still holds

Example:
```
SendMessage(to="debater-a", message="<Rebuttal prompt from role-prompts.md, with verbatim openings from debater-b and debater-c attached>")
```

Send all three rebuttal prompts in a single message (parallel). Collect all rebuttals before proceeding.

**For `rounds > 1`** (deep / custom presets): repeat the loop. In round 2, forward each debater the verbatim round-1 rebuttals from the other debaters (not their openings). In round 3, forward round-2 rebuttals. Continue until `N` rounds are complete, collecting all three replies at each round before the next begins. The final judge transcript concatenates all rounds in order.

### Phase 3 — Steelman swap

Skip this phase entirely when preset is `quick`.

Assign each debater **one** opposing position (rotate-once: A→B, B→C, C→A) and ask them to write the best possible case for it, ignoring their own side.

```
SendMessage(to="debater-a", message="<Steelman swap instruction for Position B>")
SendMessage(to="debater-b", message="<Steelman swap instruction for Position C>")
SendMessage(to="debater-c", message="<Steelman swap instruction for Position A>")
```

This is the single most important sycophancy antidote: it forces engagement with opposing logic without asking debaters to change position.

Collect all steelmans before proceeding.

### Phase 4 — Judge synthesis

Send the Judge agent the full structured transcript (openings + all rebuttal rounds + steelmans, or openings-only for `quick`) along with scope and preset metadata:

```
SendMessage(to="judge", message="<Full concatenated transcript>

Produce the decision document exactly per references/decision-doc-template.md. YAML frontmatter required (topic, date, positions, out_of_scope, recommendation, tied_on_axis, confidence, rounds, preset) followed by all 6 sections. ≥2 irreducible trade-offs required even when recommending a clear winner. 'No clear winner on axis X' is a valid output. Write the dissenting position charitably.")
```

The judge must:

- Emit the YAML frontmatter block first, then the 6 sections in order
- Include **at least 2 irreducible trade-offs** even when recommending a clear winner
- Return `"no clear winner on axis X"` if positions are genuinely tied — this is a valid output, not a failure
- Write the dissenting position charitably

### Phase 5 — Cleanup

All 4 subagents are background tasks. The lead session owns cleanup:

1. `TaskList()` — list all active tasks and identify the 4 subagent task IDs by name (`debater-a`, `debater-b`, `debater-c`, `judge`).
2. For each, call `TaskStop(task_id=<id>)`.
3. Verify with another `TaskList()` that none remain active.

Do **not** delegate cleanup to a subagent. The lead session owns it.

Render the judge's decision document in the chat. Do not persist to disk (ephemeral by default).

## Output

The final decision document has **YAML frontmatter** (topic, date, positions, out_of_scope, recommendation, tied_on_axis, confidence, rounds, preset) followed by exactly these sections (see [decision-doc-template](references/decision-doc-template.md)):

1. **Decision** — the recommendation, or "no clear winner on axis X"
2. **Confidence** — low / medium / high + one-sentence justification
3. **Key reasoning** — 3–5 bullets
4. **Irreducible trade-offs** — ≥2 bullets the decision does NOT resolve
5. **What would change this decision** — evidence or conditions that would flip it
6. **Dissenting position** — one charitable paragraph from the strongest losing side

The frontmatter makes decisions grep-friendly later (e.g. finding all `recommendation: Monorepo` or `confidence: low` decisions).

## Failure Modes

See [failure-catalog](references/failure-catalog.md) for detection and handling of:

- Malformed debater output
- Subagent error / timeout mid-run
- Topic that should be rejected as open-ended or non-contested
- Judge declaring a genuine tie
- Phase 0 inference producing the wrong positions
- Background subagent fails to respond to `SendMessage`

## Anti-Patterns

- **Don't let debaters change position.** Pinning is the primary collapse defense; if you relax it, you lose the whole point of the skill.
- **Don't skip Phase 0 confirmation.** Debating the wrong framing wastes tokens and produces confident-wrong output.
- **Don't use `debate` for open-ended analysis.** That is `superpowers:brainstorming`'s job — hand off early.
- **Don't let the judge also debate.** Neutrality is structural, not requested. The judge is spawned as a separate subagent with its own context.
- **Don't paper over ties.** "No clear winner on axis X" is a valid, honest output.
- **Don't skip the steelman swap round.** It is the cheapest sycophancy antidote available.
- **Don't forget to `TaskStop` background subagents.** Leaked background tasks consume tokens and clutter `TaskList`.
- **Don't persist transcripts by default.** Ephemeral is the contract; the user can copy what they want from chat.
- **Don't use inter-subagent SendMessage pingpong.** Only the lead session sends messages; subagents never message each other. The lead drives turn-based exchange.
- **Don't spawn debaters with `run_in_background=false`.** Foreground subagents exit after their first reply, which breaks Phase 2 onward. Always `run_in_background=true` for the debaters and judge.
- **Don't exceed 4 agents for binary / 3-option topics.** Scale only to 5 for 4-option topics; beyond that, split the question or use `superpowers:brainstorming`.
