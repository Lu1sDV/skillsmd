# ml-interpretability

Mechanistic interpretability skill cluster covering activation caching, hook-based interventions, causal tracing, interchange intervention training, and sparse autoencoders across **TransformerLens**, **nnsight**, **pyvene**, and **SAELens**. [SKILL.md](SKILL.md) routes to two focused references, loaded only when needed:

- [references/hooks-and-patching.md](references/hooks-and-patching.md) — activation caching, hook points, causal tracing, direct logit attribution, remote NDIF execution, and declarative interventions (`TransformerLens`, `nnsight`, `pyvene`).
- [references/sparse-autoencoders.md](references/sparse-autoencoders.md) — loading and training SAEs, feature attribution, steering/ablation, and troubleshooting (`SAELens`).

## Install and use

Copy the complete `ml-interpretability/` directory into your agent's skills directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ml-interpretability ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ml-interpretability@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ml-interpretability
```

Examples:
- "Run an activation patching sweep across layers and token positions on gpt2-small with TransformerLens."
- "Use nnsight with remote=True on NDIF to inspect layer 40 activations of Llama-3.1-70B."
- "Train a TopK sparse autoencoder on layer 8 of gpt2-small with SAELens and steer with a feature."

## Sources and adaptation

Condensed from four upstream skills in [Orchestra-Research/AI-Research-SKILLs](https://github.com/Orchestra-Research/AI-Research-SKILLs) (MIT, commit `773a52944ba4747a18bd4ae9ade53fff041adcbc`, see [LICENSE.upstream](LICENSE.upstream)):

- `04-mechanistic-interpretability/transformer-lens/SKILL.md`
- `04-mechanistic-interpretability/nnsight/SKILL.md`
- `04-mechanistic-interpretability/pyvene/SKILL.md`
- `04-mechanistic-interpretability/saelens/SKILL.md`

These references are distilled engineering summaries, not verbatim copies. Validation: static skill-smell checks via `check_static_smells.py` and local markdown link verification.
