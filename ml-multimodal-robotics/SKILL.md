---
name: ml-multimodal-robotics
description: >
  Use when working with multimodal ML models or vision-language-action (VLA)
  robotics policies: zero-shot image-text matching and retrieval (CLIP), image
  captioning and VQA (BLIP-2), conversational visual chat (LLaVA), promptable
  segmentation (Segment Anything / SAM), text-to-image diffusion and LoRA/ControlNet
  (Stable Diffusion / Diffusers), speech transcription and translation (Whisper),
  music and sound-effect generation (AudioCraft / MusicGen / AudioGen), or robot
  policy fine-tuning, serving, and simulation eval (OpenPI pi0/pi0.5, OpenVLA-OFT,
  NVIDIA Cosmos Policy on LIBERO, ALOHA, DROID, RoboCasa).
---

# Multimodal ML & Robotics VLA

Three domain references, one per workflow family. Open only the reference the
task needs; do not preload all.

| Task / Tool | Read |
|---|---|
| CLIP, BLIP-2, LLaVA, Segment Anything (SAM) — zero-shot classification, captioning, VQA, visual chat, promptable/auto segmentation | [Vision-language & segmentation](references/vision-language.md) |
| Stable Diffusion (Diffusers), Whisper, AudioCraft (MusicGen, AudioGen, EnCodec) — image generation, LoRA/ControlNet, ASR, audio/music generation | [Image generation & audio](references/generation-audio.md) |
| OpenPI (`pi0`, `pi0-fast`, `pi0.5`), OpenVLA-OFT / OFT+, NVIDIA Cosmos Policy — VLA fine-tuning, norm stats, WebSocket/HTTP serving, LIBERO/ALOHA/DROID/RoboCasa eval | [Robotics VLA policies](references/robotics-vla.md) |

## What each covers

- **Vision-language & segmentation** — tool selection across CLIP, BLIP-2,
  LLaVA, and SAM; model variants and FP16/INT8/INT4 VRAM budgets; point/box/mask
  prompting and ONNX export for SAM.
- **Image generation & audio** — Diffusers pipelines, schedulers, LoRA
  blending, ControlNet, and VRAM offloading; Whisper model sizing, CLI/Python
  transcription, and `faster-whisper`; AudioCraft MusicGen (text/melody/style),
  AudioGen, and EnCodec sample-rate rules.
- **Robotics VLA policies** — OpenPI JAX/PyTorch fine-tuning, `compute_norm_stats.py`,
  `transformers_replace` patching, and WebSocket serving; OpenVLA-OFT/OFT+
  pinned dependencies, LoRA merging, and train/eval flag parity; Cosmos Policy
  LIBERO/RoboCasa evaluation with headless EGL rendering.

## Universal rules

- **Verify hardware and VRAM before loading**: select FP16, BF16, 8-bit/4-bit
  quantization, or CPU offloading to fit available GPU memory rather than
  defaulting to FP32.
- **Enforce train/eval parity in VLA pipelines**: after any config or dataset
  change in OpenPI, recompute norm stats before training; in OpenVLA-OFT, keep
  `use_film`, `num_images_in_input`, `use_proprio`, `lora_rank`, `unnorm_key`,
  and `image_aug`/`center_crop` aligned between training and eval/deploy.
- **Align headless rendering GPUs**: for MuJoCo/LIBERO/RoboCasa evaluations,
  set `CUDA_VISIBLE_DEVICES`, `MUJOCO_EGL_DEVICE_ID`, `MUJOCO_GL=egl`, and
  `PYOPENGL_PLATFORM=egl` together before launching.
- **Verify outputs and artifacts**: check actual generated files, log metrics,
  checkpoint `norm_stats` keys, and server health rather than assuming success.
- **Use forward slashes**: never use backslash paths in commands or prose.
