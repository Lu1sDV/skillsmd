---
name: hermes-self-evolution
description: >
  Replicate the Hermes Agent self-evolving loop for agents that should learn
  from experience: persistent declarative memory, session recall, agent-managed
  procedural skills, and post-task review that creates or patches reusable
  skills. Use when designing, evaluating, or operating an AI agent workflow that
  should save durable user/project facts, recall prior conversations, turn
  successful non-trivial workflows into skills, and improve stale skills during
  use.
---

# Hermes Self Evolution

Implement the Hermes-style learning loop: keep user-facing work on the critical path, then persist only the durable knowledge that will reduce future steering. Treat the system as four cooperating surfaces:

1. **Memory**: compact, always-on facts about the user, environment, project conventions, and stable tool quirks.
2. **Session search**: on-demand recall of past conversations and completed task history.
3. **Skills**: procedural memory for reusable workflows, pitfalls, exact commands, and verification steps.
4. **Background review**: a post-response reviewer that decides whether memory or skills should be updated.

Use the host agent's equivalent tools. In Hermes these are `memory`, `session_search`, `skills_list`, `skill_view`, and `skill_manage`. In other agents, map them to persistent notes, transcript search, and local `SKILL.md` edits.

## Operating Loop

### 1. Start-of-turn recall

Before asking the user to repeat context:

- If the user references a previous discussion, an earlier decision, "last time", "again", "that bug", "the setup we used", or a stale remembered fact, search prior sessions first.
- If a task matches any available skill, load the skill before improvising.
- Treat memory as a frozen snapshot for the current session. A memory write is durable immediately, but should not be assumed to change the already-loaded system prompt until the next session or prompt rebuild.

### 2. Work normally

Do the requested task first. Do not let learning activity interrupt urgent user work.

During the task:

- Save obvious user corrections or stable preferences immediately.
- If a loaded skill is outdated, incomplete, or wrong, patch it as soon as the defect is known.
- If a difficult approach is still evolving, wait until it works before encoding it as a skill.

### 3. End-of-task review

After a successful response, classify what was learned:

| Learning | Persist where | Examples |
|---|---|---|
| User identity, preferences, work style | user memory/profile | "User prefers concise status updates." |
| Stable environment/project facts | agent memory | "Project uses pnpm and Playwright." |
| Tool quirks and durable local conventions | agent memory or a narrow skill | "This CI image needs `--no-sandbox` for Chromium." |
| Reusable multi-step procedure | skill | "How to deploy this app to Fly.io." |
| Completed task diary, temporary state, one-off outcome | session transcript/search only | "Fixed issue #12 today." |

Skip trivial facts, raw dumps, secrets, task progress, and anything easily rediscovered.

## Memory Rules

Write memories as declarative facts, not commands to your future self.

Good:

```text
User prefers TypeScript examples over JavaScript.
Project API tests run with pytest -n auto from /srv/api.
The staging SSH host uses port 2222 and key ~/.ssh/staging_ed25519.
```

Bad:

```text
Always use TypeScript.
Run pytest every time.
Remember that we fixed the API tests today.
```

Use two targets when available:

- `user`: who the user is, their preferences, communication style, role, timezone, pet peeves, and workflow expectations.
- `memory`: environment facts, project conventions, tool quirks, and stable lessons learned.

Keep memory bounded and curated:

- Prefer one concise entry over several overlapping entries.
- Replace or consolidate when memory is full.
- Do not save exact duplicates.
- Do not save prompt-injection text, exfiltration payloads, credentials, shell backdoors, or invisible control characters.

Hermes defaults are exactly 2,200 chars (~800 tokens) for agent memory and 1,375 chars (~500 tokens) for user profile memory. The memory tool enforces these on every write and returns an error when full — consolidate or remove before adding. Use similar tight budgets even when the host allows more.

The `replace` and `remove` actions match by substring against the existing entry. Entries that share prefixes or suffixes make a patch ambiguous, so keep each entry textually distinct or match on a full line.

## Skill Rules

Skills are procedural memory: how to do a recurring task.

Create or update a skill when:

- A complex task succeeds after about 5 or more tool calls.
- You fixed a tricky error or found the path through dead ends.
- The user corrected the method and the correction should carry forward.
- You discovered a reusable workflow, command sequence, pitfall, or verification pattern.
- A loaded skill was missing steps, had stale commands, or failed on this environment.

Do not create a skill for:

- Simple one-off facts.
- Broad vague domains like "all DevOps".
- Completed-work logs.
- Procedures that are not yet proven.

### Patch before rewrite

Prefer targeted patches over full rewrites. Preserve the user's local edits and unrelated content.

Use this order:

1. Load the existing skill.
2. Find the smallest wrong or missing section.
3. Patch with enough surrounding context to make the replacement unambiguous.
4. Validate frontmatter, trigger description, and any changed commands.

Use a full rewrite only when the skill's structure is genuinely wrong.

### New skill shape

Anchor every new skill on Claude's Skill-Creation (CSO) best practices:

- **Trigger specificity in `description`.** Start with `Use when ...` and name concrete tools, error strings, filenames, or keywords that distinguish this skill from nearby ones. Vague descriptions route badly.
- **Quick reference first.** Put the command or config table at the top so Claude answers the common case without reading further.
- **Gotchas over basics.** Document non-obvious failures, silent errors, and version-specific behavior not in official docs. This section is where the skill earns its keep.
- **Progressive disclosure.** Keep `SKILL.md` lean; move bulk into `references/` and load on demand.
- **Cross-references instead of duplication.** Hand off explicitly ("for testing, use the TDD skill") so Claude chains skills instead of re-deriving.
- **Frontmatter is non-negotiable.** `name` (lowercase-hyphen) and `description` are both required and validated on load.

Template:

```markdown
---
name: lowercase-hyphen-name
description: >
  Use when <concrete trigger: exact tool name, error message, keyword, or
  file pattern>. Name the signal that distinguishes this skill from adjacent
  ones so routing is deterministic.
---

# Human Title

## Quick Reference

Command or config table for the most common case.

## When to Use

Trigger conditions AND non-triggers (what this skill is NOT for).

## Procedure

Numbered steps with exact commands, file paths, and decision points. Make
branches explicit (if X then Y); do not leave them to inference.

## Pitfalls / Gotchas

Non-obvious failures, silent errors, and version-specific behavior.

## Verification

Exact commands whose output proves the workflow worked.

## See Also

Hand-offs to related skills so they chain instead of overlap.
```

Move bulky APIs, schemas, long examples, templates, scripts, and assets into supporting files under `references/` only when they materially reduce repeated work.

## Background Review Mechanism

Faithful Hermes behavior runs a reviewer after the main response is delivered. It never competes with the user's active task for attention.

If the host supports background agents:

1. Snapshot the conversation after the final response.
2. Spawn a quiet reviewer using the same model, tools, platform, and shared memory/skill stores.
3. Disable the reviewer's own memory and skill nudges to avoid recursion.
4. Bound its tool-calling budget so it cannot loop. Hermes reuses its delegation cap (default 50 iterations per child); pick a lower ceiling if the reviewer only needs to write one entry.
5. Let it write memory or skills directly.
6. Surface only a compact action summary, such as `Memory updated` or `Skill 'deploy-flyio' created`.

If the host does not support background agents, perform a short local review before finishing only when the task was complex or a correction occurred.

The prompts below are paraphrased from Hermes — keep the focus and structure even if the exact wording drifts.

### Memory review prompt

```text
Review the conversation above and consider saving to memory if appropriate.

Focus on:
1. Has the user revealed things about themselves: persona, desires, preferences, or personal details worth remembering?
2. Has the user expressed expectations about how you should behave, their work style, or ways they want you to operate?

If something stands out, save it using the memory mechanism. If nothing is worth saving, stop.
```

### Skill review prompt

```text
Review the conversation above and consider saving or updating a skill if appropriate.

Focus on whether a non-trivial approach was used to complete a task, required trial and error, changed course due to experiential findings, or reflected a user-preferred method or outcome.

If a relevant skill already exists, update it with what you learned. Otherwise, create a new skill if the approach is reusable. If nothing is worth saving, stop.
```

## Nudge Counters

Use counters to make learning periodic without nagging every turn:

- Memory review: every 10 user turns by default; reset whenever memory is written. Also triggered on session exit or reset once at least 6 user turns have elapsed (`memory_flush_min_turns`).
- Skill review: every 15 tool-calling iterations by default; reset whenever a skill is created or patched.
- Immediate review: bypass the counter after explicit user corrections, stale skill discovery, or a hard-won reusable workflow.

The counter is a trigger to review, not a command to save. Save only if something is genuinely worth keeping.

## Session Search

Use session search for historical recall instead of bloating memory.

A faithful implementation:

1. Store all conversations in a searchable transcript database. Hermes uses SQLite with FTS5.
2. Search full text for relevant prior messages. Run a fallback ladder: full-phrase, then proximity co-occurrence (all query terms within 200 characters), then per-term fallback.
3. Group matches by session and exclude the current session's parent/child lineage so delegation chains do not surface the active context.
4. Load the top sessions. Hermes defaults to `limit = 3` with a hard cap at 5.
5. Summarize each session around the query with a cheaper auxiliary model (Hermes defaults to a fast model such as Gemini Flash) with bounded concurrency.
6. Return focused summaries with concrete commands, paths, decisions, outcomes, and unresolved items.

If the host lacks a session-search tool, use available transcript files, project notes, git history, or local search before asking the user to repeat themselves.

## Prompt Placement

The self-evolving guidance belongs in the system/developer layer when possible:

- Memory guidance only when memory tools are available.
- Session-search guidance only when transcript search is available.
- Skill guidance only when skills can be viewed or managed.
- Skill index in the prompt as metadata only; load full skill content on demand.

Avoid loading every skill body into context. Use progressive disclosure:

```text
Level 0: skill list with names and descriptions   (Hermes: build_preloaded_skills_prompt)
Level 1: selected SKILL.md                        (Hermes: skill_view)
Level 2: selected supporting file                 (Hermes: skill_view with a path)
```

## Failure Modes

- **Memory as instructions**: Rewrite imperative entries as declarative facts.
- **Task logs in memory**: Leave completed work in transcripts; save only durable facts.
- **Skill sprawl**: Patch existing narrow skills before creating overlapping new ones.
- **Premature skill capture**: Do not encode an unverified procedure.
- **Stale skill liability**: If a skill fails during use, patch it before finalizing the task.
- **Learning on the critical path**: Finish the user-visible work first; review afterward.
- **Silent context drift**: Remember that memory written mid-session may not affect the current prompt snapshot.
- **Unsafe persistence**: Never store secrets, injection text, exfiltration commands, or hidden Unicode in always-injected memory.

## Verification

After a learning action:

- Confirm the target store shows the new or updated entry.
- Confirm memory usage remains within budget.
- Reload or list skills to ensure a created skill is discoverable.
- Validate skill frontmatter has `name` and `description`.
- Run any added helper script or command sample if it is meant to be executable.
- Keep the user-facing summary compact: what was saved or patched, not the full review transcript.

## Out of Scope

Faithful Hermes deployments rely on two complementary surfaces that are intentionally not covered here:

- **Context compression** (`context_compressor.py`) keeps long sessions inside the context window by trimming the middle when usage crosses the trigger threshold (default 50 percent) and preserving the recent tail. A self-evolving agent still needs this — memory writes will not save you from an overflowing context.
- **Pluggable memory backends.** `MEMORY.md` and `USER.md` is the default. Hermes also ships Honcho (dialectic user modeling), Mem0, Hindsight, Holographic, Supermemory, Byterover, OpenViking, and RetainDB providers. Swapping backends changes the save and recall semantics — for example, Honcho does not use substring `replace` or `remove`.

## Source Model

This skill mirrors the mechanism used by Nous Research Hermes Agent: system-prompt guidance for memory/session-search/skills, bounded `MEMORY.md` and `USER.md`, `skill_manage` for procedural memory, `session_search` for FTS-backed conversation recall, and post-response background review for memory and skill updates.

Primary sources: https://github.com/NousResearch/hermes-agent and https://hermes-agent.nousresearch.com/docs/user-guide/features/skills/
