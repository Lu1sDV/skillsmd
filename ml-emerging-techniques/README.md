# ml-emerging-techniques

Consolidated skill for emerging LLM scaling, compression, merging, and fast
decoding techniques. [SKILL.md](SKILL.md) is a short orchestrator that routes to
two independently readable references, loaded only when the task needs them:

- [references/architecture-scaling.md](references/architecture-scaling.md) —
  Mixture of Experts (MoE) architectures, routing, load balancing, DeepSpeed
  expert parallelism, and long-context extension (RoPE, YaRN, ALiBi, position
  interpolation, FlashAttention).
- [references/compression-and-merging.md](references/compression-and-merging.md) —
  Knowledge distillation (logit, response, MiniLLM reverse KLD), model pruning
  (Wanda, SparseGPT, N:M 2:4 sparsity), model merging (`mergekit` linear, SLERP,
  Task Arithmetic, TIES, DARE, AdaMMS coefficient tuning), and speculative
  decoding (draft models, Medusa, Lookahead decoding, vLLM).

## Install and use

Copy the complete `ml-emerging-techniques/` directory into your agent's skills
directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ml-emerging-techniques ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ml-emerging-techniques@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ml-emerging-techniques
```

Examples:
- "Configure DeepSpeed MoE training with 8 experts and router load balancing."
- "Extend a Mistral-7B model to 64k context using YaRN in HuggingFace."
- "Write a mergekit DARE-TIES config to combine a math and chat Mistral-7B."
- "Set up 2:4 Wanda pruning or vLLM speculative decoding with a 7B draft model."

## Sources and adaptation

Condensed on 2026-11-16 from six upstream skills in
[Orchestra-Research/AI-Research-SKILLs](https://github.com/Orchestra-Research/AI-Research-SKILLs)
(MIT, commit `773a52944ba4747a18bd4ae9ade53fff041adcbc`, see
[LICENSE.upstream](LICENSE.upstream)):

- `19-emerging-techniques/moe-training/SKILL.md` (plus `references/architectures.md`, `references/training.md`, `references/inference.md`)
- `19-emerging-techniques/long-context/SKILL.md` (plus `references/rope.md`, `references/extension_methods.md`, `references/fine_tuning.md`)
- `19-emerging-techniques/knowledge-distillation/SKILL.md` (plus `references/minillm.md`)
- `19-emerging-techniques/model-pruning/SKILL.md` (plus `references/wanda.md`)
- `19-emerging-techniques/model-merging/SKILL.md` (plus `references/methods.md`, `references/examples.md`, `references/evaluation.md`, `references/coefficient-tuning.md`)
- `19-emerging-techniques/speculative-decoding/SKILL.md` (plus `references/medusa.md`, `references/lookahead.md`)

These references are condensed derivatives, not vendored copies: boilerplate
sections and redundant code blocks were deduplicated while preserving real APIs,
CLI flags, formulas, and hyperparameter guidelines.

Validation: YAML frontmatter, local reference links, and the five static
skill-smell checks via `check_static_smells.py`.
