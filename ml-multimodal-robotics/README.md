# ml-multimodal-robotics

Consolidated multimodal ML and vision-language-action (VLA) robotics skill.
[SKILL.md](SKILL.md) is a short orchestrator that routes to three independently
readable references, loaded only when the task needs them:

- [references/vision-language.md](references/vision-language.md) — CLIP, BLIP-2,
  LLaVA, and Segment Anything (SAM) for zero-shot classification, captioning,
  VQA, visual chat, and promptable/automatic segmentation.
- [references/generation-audio.md](references/generation-audio.md) — Stable
  Diffusion (Diffusers), Whisper (ASR), and AudioCraft (MusicGen, AudioGen,
  EnCodec) for image generation, transcription, and audio/music synthesis.
- [references/robotics-vla.md](references/robotics-vla.md) — OpenPI (`pi0`,
  `pi0-fast`, `pi0.5`), OpenVLA-OFT / OFT+, and NVIDIA Cosmos Policy for VLA
  fine-tuning, serving, and LIBERO/ALOHA/DROID/RoboCasa evaluation.

## Install and use

Copy the complete `ml-multimodal-robotics/` directory into your agent's skills
directory. For Claude Code, from this repository checkout:

```sh
mkdir -p ~/.claude/skills
cp -r ml-multimodal-robotics ~/.claude/skills/
```

Or via the marketplace / npx:

```sh
/plugin marketplace add Lu1sDV/skillsmd
/plugin install ml-multimodal-robotics@Lu1sDV/skillsmd
# or
npx skills add Lu1sDV/skillsmd ml-multimodal-robotics
```

Examples:
- "Use SAM to segment objects from bounding boxes and export to ONNX."
- "Transcribe this Spanish video to English subtitles with Whisper turbo."
- "Fine-tune OpenPI pi0.5 on a custom LeRobot dataset and serve it over WebSocket."
- "Evaluate OpenVLA-OFT on LIBERO-Spatial and verify train/eval flag parity."

## Sources and adaptation

Condensed from ten upstream skills in
[Orchestra-Research/AI-Research-SKILLs](https://github.com/Orchestra-Research/AI-Research-SKILLs)
(MIT, commit `773a52944ba4747a18bd4ae9ade53fff041adcbc`, see
[LICENSE.upstream](LICENSE.upstream)):

- `18-multimodal/clip/SKILL.md`
- `18-multimodal/blip-2/SKILL.md`
- `18-multimodal/llava/SKILL.md`
- `18-multimodal/segment-anything/SKILL.md`
- `18-multimodal/stable-diffusion/SKILL.md`
- `18-multimodal/whisper/SKILL.md`
- `18-multimodal/audiocraft/SKILL.md`
- `18-multimodal/openpi/SKILL.md` (+ `references/checkpoints-and-env-map.md`, `references/pytorch-gotchas.md`)
- `18-multimodal/openvla-oft/SKILL.md` (+ `references/config-troubleshooting.md`)
- `18-multimodal/cosmos-policy/SKILL.md`

These references are condensed, deduplicated derivatives preserving upstream
APIs, CLI commands, pinned versions, VRAM budgets, and troubleshooting gotchas.

Validation: YAML frontmatter, local reference links, and the five static
skill-smell checks (`check_static_smells.py`).
