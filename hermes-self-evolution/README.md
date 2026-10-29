# Hermes Self Evolution

Design an agent workflow that retains durable facts, recalls earlier sessions,
and turns verified procedures into reusable skills. Use it when repeated work,
user corrections, or stale instructions should improve future behavior without
filling persistent memory with task logs.

## Use

```text
Use $hermes-self-evolution to review this agent workflow and define what belongs in memory, session history, and reusable skills.
```

The [skill workflow](SKILL.md) covers recall, targeted skill updates, bounded
post-task review, and verification of saved changes. Map those responsibilities
to the memory, search, and skill-management tools available in the host agent.

## Contents

- [Operating loop](SKILL.md#operating-loop): recall, complete the task, then review durable learning.
- [Failure modes and verification](SKILL.md#failure-modes): avoid premature capture, duplicate skills, and unverified persistence.
- [Agent metadata](agents/openai.yaml): display information and an example prompt.
- [Source model](SKILL.md#source-model): attribution and primary links to Nous Research's Hermes Agent.

## Install

Copy the complete `hermes-self-evolution/` folder into the skill directory
recognized by your agent so the entry point and metadata travel together.
