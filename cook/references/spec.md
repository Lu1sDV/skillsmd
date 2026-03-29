# Cook Operator Specification

Full grammar, nesting rules, and configuration reference.

## Grammar

```
cook "<work>" [xN | repeat N] [review ["<review>"] ["<gate>"] ["<iterate>"] [max-iterations]] \
     [ralph [N] "<ralph-gate>"] \
     [vN | race N | vs ... ] [resolver] ["<criteria>"] \
     [vN | race N] [resolver] ["<criteria>"]
```

**Reserved keywords**: `review`, `ralph`, `race`, `repeat`, `vs`, `pick`, `merge`, `compare`.
**Patterns**: `xN` and `vN` (N = digit) are shorthand for `repeat N` and `race N`.
**Duck typing**: A bare number is `max-iterations`. Any other quoted string fills the next prompt slot.

---

## xN / repeat N

Repeats everything to its left N times sequentially. Each pass sees previous output.

```sh
cook "work" x3                 # (work) ×3
cook "work" x3 review          # ((work) ×3 → review)
cook "work" review x3          # ((work → review) ×3)
cook "work" x3 review x3       # (((work) ×3 → review) ×3)
```

Expanded:

```
cook "work" x3:
  work → work → work

cook "work" x3 review:
  work → work → work → review → gate → (iterate if needed)

cook "work" review x3:
  Round 1: work → review → gate (until DONE)
  Round 2: work → review → gate (until DONE)
  Round 3: work → review → gate (until DONE)

cook "work" x3 review x3:
  Round 1: work×3 → review loop
  Round 2: work×3 → review loop
  Round 3: work×3 → review loop
```

`x1` is a no-op.

---

## Review

Adds a review → gate loop after work. On ITERATE, the iterate step runs, then review → gate repeats.

```
Pass 1:  work → review → gate
Pass 2+: iterate → review → gate   (if gate said ITERATE)
         exit                       (if gate said DONE)
```

### Positional shorthand

```sh
cook "<work>" "<review>" "<gate>" ["<iterate>"] [max-iterations]
```

### Explicit keyword

```sh
cook "work" review                                                    # defaults
cook "work" review 5                                                  # max 5 iterations
cook "work" review "Review for accessibility" "DONE if WCAG AA"       # custom prompts
cook "work" review "Review prompt" "Gate prompt" "Fix prompt" 5       # full custom
```

### Defaults

- **review**: "Review the work done in the previous step. Check the session log for what changed. Identify issues categorized as High, Medium, or Low severity."
- **gate**: "Based on the review, respond with exactly DONE or ITERATE on its own line, followed by a brief reason."
- **iterate**: reuses work prompt
- **max-iterations**: 3

---

## Ralph

Outer gate wrapping a cook. After inner pattern completes, ralph gate decides NEXT or DONE.

```sh
cook "<work>" [inner operators] ralph [N] "<ralph-gate>"
```

Ralph gate prompt is required. N = max tasks (default 100).

### Without review

```sh
cook "Read plan.md, do the next incomplete task" \
     ralph 5 "If all tasks in plan.md are [done] say DONE, else say NEXT"
```

```
Task 1: work → ralph gate (NEXT)
Task 2: work → ralph gate (NEXT)
...
Task N: work → ralph gate (DONE) → exit
```

### With review

```sh
cook "Read plan.md, do the next incomplete task" \
     review "Code review" "DONE if no high issues, else ITERATE" \
     ralph 5 "DONE if all tasks complete, else NEXT"
```

```
Task 1: work → review → gate (DONE) → ralph gate (NEXT)
Task 2: work → review → gate (DONE) → ralph gate (NEXT)
...
Task N: work → review → gate (DONE) → ralph gate (DONE) → exit
```

---

## vN / race N (Versions)

N identical cooks in parallel worktrees, resolved by a resolver.

```sh
cook "work" v3 pick "least lines changed"
cook "work" race 3 pick "least lines changed"     # equivalent
cook "work" v3                                      # pick is default resolver
cook "work" review v3 pick "cleanest"               # each branch gets review loop
cook "work" x3 v3 pick "best"                       # each branch gets 3 passes
```

`v1` is a no-op.

---

## vs

Two or more different cooks in parallel worktrees.

```sh
cook "Auth with JWT" vs "Auth with sessions" pick "best security"
cook "JWT" x3 vs "Sessions" x5 pick "best"                         # per-branch operators
cook "Build with React" review 3 vs "Build with Vue" review 5 merge "best DX"
```

---

## Resolvers

| Resolver | Behavior |
|----------|----------|
| `pick ["criteria"]` | Read all results, pick one winner. Merge winning branch. Default. |
| `merge ["criteria"]` | Synthesize all results into new implementation in fresh worktree. |
| `compare` | Write comparison to `.cook/compare-{session}.md`. No merge. Cannot chain. |

---

## Second-level Composition

After a resolver, the result can be versioned again:

```sh
cook "A" vs "B" pick "cleanest" v3 pick "most thorough"
```

Runs 3 independent A-vs-B races, then picks the best of the 3 winners.

---

## CLI Flags

```
--work PROMPT           Override work step prompt
--review PROMPT         Override review step prompt
--gate PROMPT           Override gate step prompt
--iterate PROMPT        Override iterate step prompt
--max-iterations N      Max review iterations (default: 3)
--agent AGENT           Default agent (claude|codex|opencode)
--model MODEL           Default model
--sandbox MODE          Sandbox mode (agent|docker, default: agent)
--work-agent AGENT      Work step agent override
--review-agent AGENT    Review step agent override
--gate-agent AGENT      Gate step agent override
--iterate-agent AGENT   Iterate step agent override
--ralph-agent AGENT     Ralph gate step agent override
--work-model MODEL
--review-model MODEL
--gate-model MODEL
--iterate-model MODEL
--ralph-model MODEL
--hide-request          Hide the templated request panel
--no-wait               Disable rate-limit recovery (fail immediately)
```

---

## Configuration: .cook/config.json

```json
{
  "agent": "claude",
  "sandbox": "agent",
  "steps": {
    "work":    { "agent": "codex",  "model": "gpt-5-codex" },
    "review":  { "agent": "claude", "model": "opus" },
    "gate":    {},
    "iterate": {},
    "ralph":   {}
  },
  "retry": {
    "enabled": true,
    "pollIntervalMinutes": 5,
    "maxWaitMinutes": 360
  },
  "env": ["CLAUDE_CODE_OAUTH_TOKEN"]
}
```

`ralph` step config controls the ralph gate agent/model/sandbox. Falls back to `gate` if not set.

---

## COOK.md Template Variables

| Variable | Description |
|----------|-------------|
| `${step}` | Current step: `work`, `review`, `gate`, `iterate`, or `ralph` |
| `${prompt}` | The prompt for this step |
| `${lastMessage}` | Output from the previous step |
| `${iteration}` | Current cook iteration number |
| `${maxIterations}` | Max cook iterations |
| `${ralphIteration}` | Current ralph task number (ralph only) |
| `${maxRalph}` | Max ralph tasks (ralph only) |
| `${logFile}` | Path to the session log file |

---

## COOK.md Example

```markdown
# COOK.md

## Project Instructions

## Agent Loop

Step: **${step}** | Iteration: ${iteration}/${maxIterations}

### Task
${prompt}

${lastMessage ? '### Previous Output\n' + lastMessage : ''}

### History
Session log: ${logFile}
Read the session log for full context from previous steps.
```
