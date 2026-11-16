# ml-eval-safety

Consolidated skill for LLM and code-model evaluation alongside runtime safety guardrails and Constitutional AI alignment. [SKILL.md](SKILL.md) routes to two independently readable references, loaded only when needed:

- [references/evaluation.md](references/evaluation.md) — `lm-evaluation-harness` (`lm_eval`), BigCode Evaluation Harness (`pass@k`, MultiPL-E), and NeMo Evaluator SDK (`nemo-evaluator-launcher`).
- [references/safety-guardrails.md](references/safety-guardrails.md) — Prompt Guard (86M), LlamaGuard (7B-8B), NeMo Guardrails (Colang, Presidio PII), and Constitutional AI (self-critique SFT + RLAIF).

## Install and use

Copy the complete `ml-eval-safety/` directory into your agent's skills directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ml-eval-safety ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ml-eval-safety@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ml-eval-safety
```

Examples:
- "Benchmark meta-llama/Llama-2-7b-hf on MMLU and GSM8K with lm_eval using vLLM."
- "Run HumanEval pass@1 and pass@100 safely with BigCode Evaluation Harness."
- "Add Prompt Guard and LlamaGuard input/output filtering inside NeMo Guardrails."

## Sources and adaptation

Distilled from seven upstream skills in [Orchestra-Research/AI-Research-SKILLs](https://github.com/Orchestra-Research/AI-Research-SKILLs) (MIT, commit `773a52944ba4747a18bd4ae9ade53fff041adcbc`, see [LICENSE.upstream](LICENSE.upstream)):

- `11-evaluation/lm-evaluation-harness`
- `11-evaluation/bigcode-evaluation-harness`
- `11-evaluation/nemo-evaluator`
- `07-safety-alignment/llamaguard`
- `07-safety-alignment/prompt-guard`
- `07-safety-alignment/nemo-guardrails`
- `07-safety-alignment/constitutional-ai`
