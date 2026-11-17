# ds-ml-discovery

Consolidated skill for scientific ML resource discovery, autonomous hypothesis-tree
optimization, and LLM-assisted textual hypothesis generation. [SKILL.md](SKILL.md)
is a short orchestrator that routes to one consolidated reference:

- [references/ml-discovery-and-hypotheses.md](references/ml-discovery-and-hypotheses.md) —
  decision matrix, workflows, and gotchas for **Hugging Science**
  (`huggingscience.co` + HF Hub), **Arbor** (Hypothesis Tree Refinement for
  autonomous optimization), and **HypoGeniC / HypoRefine** (`hypogenic==0.3.5`).

## Install and use

Copy the complete `ds-ml-discovery/` directory into your agent's skills
directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ds-ml-discovery ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ds-ml-discovery@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ds-ml-discovery
```

Examples:
- "Find a commit-pinned protein language model and dataset via Hugging Science."
- "Set up an Arbor Hypothesis Tree Refinement loop with dev/test evaluators and git worktrees."
- "Audit a labeled text dataset and configure a safe `hypogenic==0.3.5` hypothesis-generation run."

## Sources and adaptation

Condensed on 2026-11-16 from three upstream skills in
[K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills)
(MIT, commit `ec59a29a03d5c40f73ab40878df04860bc00e876`, see
[LICENSE.upstream](LICENSE.upstream)):

- `skills/hugging-science/SKILL.md`
- `skills/arbor/SKILL.md`
- `skills/hypogenic/SKILL.md`

This reference is a condensed derivative, not a vendored copy. Upstream
boilerplate, citation blocks, and references to unbundled helper scripts were
removed while preserving catalog endpoints, topic slugs, HTR coordinator/executor
contracts, `hypogenic==0.3.5` CLI/wrapper gotchas, and safety/split-hygiene rules.

Validation: YAML frontmatter, local reference links, and the five static
skill-smell checks (`check_static_smells.py`). External catalog endpoints,
Arbor runs, and HypoGeniC LLM wrappers were not executed live here.
