# ml-research-workflow

Consolidated ML and systems research lifecycle skill: autonomous experiment
orchestration, structured ideation, paper writing, publication-quality plotting,
conference talks, and Agent-Native Research Artifacts (ARA). [SKILL.md](SKILL.md)
routes to three independently readable references, loaded only when the task needs
them:

- [references/ideation-and-autoresearch.md](references/ideation-and-autoresearch.md)
  — two-loop `autoresearch` orchestration, `research-state.yaml` schema, 10
  brainstorming frameworks, and 8 cognitive-science creativity frameworks.
- [references/paper-writing-and-talks.md](references/paper-writing-and-talks.md)
  — ML/AI and 12-page systems paper blueprints, zero-hallucination citation
  verification, Gemini + `matplotlib`/`seaborn` plotting, and Beamer/`python-pptx`
  conference talk generation.
- [references/research-artifacts.md](references/research-artifacts.md) — ARA
  universal compiler (`ara/`), Seal Level 1 structural checks, post-task Live PM
  provenance logging, and 6-dimension Seal Level 2 rigor review.

## Install and use

Copy the complete `ml-research-workflow/` directory into your agent's skills
directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ml-research-workflow ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ml-research-workflow@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ml-research-workflow
```

Examples:
- "Set up an autoresearch workspace and run a two-loop investigation on KV-cache quantization."
- "Brainstorm non-incremental research angles on test-time compute using constraint manipulation."
- "Draft a NeurIPS paper from this repo and verify all BibTeX citations via Semantic Scholar and CrossRef."
- "Compile this paper PDF and GitHub repo into a validated `ara/` artifact and run a Seal Level 2 rigor review."

## Sources and adaptation

Condensed on 2026-11-16 from ten upstream skills in
[Orchestra-Research/AI-Research-SKILLs](https://github.com/Orchestra-Research/AI-Research-SKILLs)
(MIT, commit `773a52944ba4747a18bd4ae9ade53fff041adcbc`, see
[LICENSE.upstream](LICENSE.upstream)):

- `0-autoresearch-skill/SKILL.md` — workspace layout, `research-state.yaml`, two-loop orchestration, git protocol, and continuity loops.
- `21-research-ideation/brainstorming-research-ideas/SKILL.md` — 10 ideation frameworks, two-sentence pitch, and diverge-converge-refine workflow.
- `21-research-ideation/creative-thinking-for-research/SKILL.md` — 8 cognitive-science frameworks and 90-minute creative protocol.
- `20-ml-paper-writing/ml-paper-writing/SKILL.md` — Narrative Principle, 5-sentence abstract, Semantic Scholar + CrossRef DOI citation workflow, LaTeX template & format conversion rules.
- `20-ml-paper-writing/systems-paper-writing/SKILL.md` — 12-page OSDI/SOSP/ASPLOS/NSDI/EuroSys structural blueprint, writing patterns, and rule-of-three evaluation.
- `20-ml-paper-writing/academic-plotting/SKILL.md` — Gemini diagram styles/prompts and colorblind-safe `matplotlib`/`seaborn` chart workflows.
- `20-ml-paper-writing/presenting-conference-talks/SKILL.md` — poster/spotlight/oral/invited slide structures, Beamer, and `python-pptx` workflows.
- `22-agent-native-research-artifact/compiler/SKILL.md` — 4-stage epistemic compilation, ARA schema, and Seal Level 1 validation.
- `22-agent-native-research-artifact/research-manager/SKILL.md` — post-task epilogue provenance logging and maturity tracker.
- `22-agent-native-research-artifact/rigor-reviewer/SKILL.md` — 6-dimension Seal Level 2 semantic review and grading rubric.

Validation: YAML frontmatter, local reference links, and the five static
skill-smell checks via `check_static_smells.py`.
