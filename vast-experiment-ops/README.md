# vast-experiment-ops

Error-informed playbook for running and reporting ML experiments on rented
Vast.ai GPU instances.

Covers three failures observed in practice — CUDA cuDNN TF32 breaking strict
FP32 equivalence checks that pass on CPU, SSH welcome banners corrupting JSON
metrics, and overclaimed held-out/test status in tuning reports — plus the
reporting and instance-hygiene rules that keep results trustworthy. Observed
failures and preventive safeguards are labeled separately.

## Install

```bash
cp -r vast-experiment-ops ~/.claude/skills/
```

Or via the marketplace:

```
/plugin install vast-experiment-ops@Lu1sDV/skillsmd
```

## Contents

- [`SKILL.md`](SKILL.md) — quick reference, three observed failure cases with
  fixes and verification steps, reporting checklist, instance hygiene
