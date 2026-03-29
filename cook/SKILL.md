---
name: cook
description: >
  Use when user says "cook", "let it cook", wants iterative refinement with
  quality gates, wants to race multiple approaches and pick the best, needs
  repeat passes, or wants autonomous task-list completion. Triggers: cook,
  let it cook, review loop, race approaches, ralph, iterate until done.
metadata:
  author: rjcorwin
  version: 1.0.0
  upstream: https://github.com/rjcorwin/cook
  tags: [cook, orchestration, review-loop, race, ralph, workflow, subagent, parallel, iterative]
---

# Cook — Composable Agent Orchestration

You are an orchestrator — delegate to subagents, never do work directly. Each subagent gets fresh context.

## Quick Reference

```sh
cook "Implement dark mode"                              # single work call
cook "Implement dark mode" review                       # review loop (max 3)
cook "Improve the design" x3                            # 3 sequential passes
cook "Implement dark mode" v3 pick "cleanest"           # race 3, pick best
cook "Auth with JWT" vs "Auth with sessions" pick "best security"
cook "Next task in PLAN.md" ralph 5 "DONE if all tasks complete, else NEXT"
cook "Implement dark mode" x3 review                    # 3 passes, then review
```

## Primitives

| Category | Operator | Effect |
|----------|----------|--------|
| **Work** | `"prompt"` | Single agent call — the core unit |
| **Loop** | `review [N]` | Review → gate → iterate (default max 3) |
| **Loop** | `xN` / `repeat N` | N sequential passes, each refining the last |
| **Loop** | `ralph N "gate"` | Outer gate for task-list progression (DONE/NEXT) |
| **Compose** | `vN` / `race N` | N identical branches in parallel worktrees |
| **Compose** | `vs` | 2+ different branches in parallel worktrees |
| **Resolve** | `pick` / `merge` / `compare` | Pick winner, synthesize all, or write comparison doc |

**Operators compose left to right.** Each wraps everything to its left.

**Reserved keywords**: `review`, `ralph`, `race`, `repeat`, `vs`, `pick`, `merge`, `compare`. `xN`/`vN` (N=digit) are shorthand. Bare number = max-iterations. Other quoted strings fill prompt slots.

## When to Use

- User explicitly asks to "cook" or "let it cook"
- Multiple iterations of refinement needed (review loops)
- Multiple competing approaches should be tried (races, vs)
- Task list needs sequential progression (ralph)
- User wants autonomous completion without manual review cycles

**Don't use when:** Simple one-shot change, or user wants to review each step interactively.

## Execution Patterns

### Work (no operators)

```
Agent(prompt: "<work prompt>")
```

### Review Loop

```
loop (max 3 or user-specified):
  1. Agent(prompt: "<work>" + previous feedback if any)
  2. Agent(prompt: "<review prompt>")  # default: check for High/Medium/Low issues
  3. No High issues → DONE. High issues + iterations left → ITERATE.
```

Default review uses `git diff` to inspect changes. See `references/spec.md` for full default prompts.

### Repeat (xN)

```
for pass in 1..N:
  Agent(prompt: "<work prompt>")   # each sees previous pass's state
```

### Ralph (task-list progression)

```
for task in 1..maxTasks:
  1. Execute inner pattern (work, work+review, etc.)
  2. Agent(prompt: "<ralph gate>")  # responds DONE or NEXT
```

### Race (vN) and vs

Create git worktrees per branch → run all agents in parallel (single message) → resolve with `pick`/`merge`/`compare` → clean up worktrees. See `references/spec.md` for worktree commands.

## Composition

```
"work" x3 review          →  3 repeat passes, then review loop
"work" review x3           →  review loop repeated 3 times
"work" review v3 pick      →  race 3 branches, each with review loop
"A" vs "B" pick "best" v3  →  3 independent A-vs-B races, best of winners
```

## Confirm Before Executing

Always confirm the parsed plan before running:

```
Plan: 3 repeat passes, then a review loop (max 3 iterations).
Work prompt: "Implement dark mode"
Proceed?
```

## Gotchas

- **Dirty worktree blocks race/vs**: Commit before using composition operators — git worktrees require clean state
- **Operator order matters**: `x3 review` (3 passes then review) ≠ `review x3` (review loop 3 times)
- **Ralph gate must say DONE or NEXT**: If gate prompt is ambiguous, ralph loops forever up to max
- **Never use `--sandbox none`**: Default `agent` sandbox preserves parent security boundaries
- **Rate limits**: Cook auto-retries on quota/rate-limit errors (configurable in `.cook/config.json`)

## CLI Alternative

Optional `npm install -g @let-it-cook/cli` adds terminal/CI usage with per-step agent/model overrides. Run `cook init` to create `COOK.md` and `.cook/config.json`. See `references/spec.md` for CLI flags.
