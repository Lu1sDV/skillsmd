# refurbisher

A coding-agent skill for delivering the requested outcome while leaving less software
and operational responsibility to maintain.

Before a substantial new subsystem, dependency, rewrite, or growing set of workarounds,
the agent checks the premise that makes that machinery seem necessary. It inspects the
current system, identifies mature neighboring fields when useful, and obtains evidence
that can change the implementation.

The same judgment applies to a small critical function: subtle numerical, encoding,
ownership, or recovery behavior can warrant finding an established implementation and
its regression history before writing a fresh version.

The result may be a configuration repair, deletion, better use of an installed component,
a narrow port, adoption of an existing system, or justified new code. Research is part of
execution: the agent continues with the authorized work once the decision is supported.

## What it teaches

- Discover useful search vocabulary from the structure of a problem.
- Treat cross-domain analogies as hypotheses with transfer conditions.
- Prefer an inquiry that can remove work over a catalog of familiar tool names.
- Compare total ownership cost, including services, state, updates, and recovery.
- Inspect external code and provenance proportionately to the intended reuse.
- Find small reusable mechanisms inside mature OSS and preserve their assumptions.
- Keep clear, bounded local changes local.

It does not require candidate quotas, repository trust scores, a research report,
or an approval pause for routine implementation choices.

## Examples

- A fairness problem leads the agent to investigate resource scheduling in networks,
  operating systems, or storage, then test which assumptions fit the job workload.
- A proposed IR extractor becomes a check of which program facts the consumer needs.
- Poor retrieval answers lead to tracing where evidence disappears before adding models.
- A platform request becomes an investigation of which capabilities already exist and
  which responsibility the project really needs to own.
- A short numerical predicate or checksum combiner leads to a complete, tested primitive
  instead of fresh edge-case patches or another service.

See [SKILL.md](SKILL.md) for the core guidance,
[worked investigations](references/worked-examples.md) for ten cases with distinct takeaways,
[the search playbook](references/search-playbook.md) for discovery, and
[the reuse review](references/reuse-review.md) for material external adoption.

## Manual installation

Copy this directory into the skill directory used by your coding agent. For Claude Code,
from a checkout containing this skill:

```bash
cp -r refurbisher ~/.claude/skills/
```

Use the skill explicitly with a request such as:
"Use refurbisher to improve this subsystem before adding another layer."
