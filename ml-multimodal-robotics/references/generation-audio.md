# Image Generation & Audio Reference

Consolidated engineering reference for **Stable Diffusion (Diffusers)**, **Whisper (ASR)**, and **AudioCraft (MusicGen / AudioGen / EnCodec)**.

## Tool selection

| Task | Tool | Why |
|---|---|---|
| Text-to-image, img2img, inpainting, ControlNet, LoRA | **Stable Diffusion (Diffusers)** | Full local pipeline control across SD 1.5, SDXL, SD3, Flux |
| Multilingual speech transcription & translation to English | **Whisper** | 99 languages, timestamps, CLI/Python; `faster-whisper` for speed |
| Text-to-music, melody/style conditioning, sound effects | **AudioCraft** | MusicGen (32 kHz), AudioGen (16 kHz), EnCodec neural codec |

---

## Stable Diffusion (HuggingFace Diffusers)

### Install

```bash
pip install diffusers transformers accelerate torch
pip install xformers  # Optional: memory-efficient attention
```

### Pipelines & Schedulers

- **Pipelines**: `AutoPipelineForText2Image`, `AutoPipelineForImage2Image`, `AutoPipelineForInpainting`, `StableDiffusionControlNetPipeline`, `StableDiffusionXLPipeline`, `StableDiffusion3Pipeline`, `FluxPipeline`.
- **Schedulers**:

| Scheduler | Steps | Notes |
|---|---|---|
| `DPMSolverMultistepScheduler` | 15–25 | Fast, high quality default replacement |
| `UniPCMultistepScheduler` | 15–25 | Fast convergence |
| `EulerDiscreteScheduler` | 20–50 | Standard baseline |
| `EulerAncestralDiscreteScheduler` | 20–50 | Higher variation |
| `LCMScheduler` | 4–8 | Use with LCM-LoRA and `guidance_scale=1.0` |

### Text-to-Image, Schedulers & LoRA

```python
import torch
from diffusers import AutoPipelineForText2Image, DPMSolverMultistepScheduler

pipe = AutoPipelineForText2Image.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0",
    torch_dtype=torch.float16,
    variant="fp16",
).to("cuda")

pipe.scheduler = DPMSolverMultistepScheduler.from_config(pipe.scheduler.config)
pipe.enable_model_cpu_offload()  # or enable_sequential_cpu_offload() for tighter VRAM

# Optional: load and blend multiple LoRAs
pipe.load_lora_weights("lora1_repo", adapter_name="style")
pipe.load_lora_weights("lora2_repo", adapter_name="character")
pipe.set_adapters(["style", "character"], adapter_weights=[0.7, 0.5])

generator = torch.Generator(device="cuda").manual_seed(42)
image = pipe(
    prompt="A futuristic city with flying cars, cinematic lighting",
    negative_prompt="blurry, low quality, distorted",
    height=1024,
    width=1024,
    num_inference_steps=25,
    guidance_scale=7.5,
    generator=generator,
).images[0]
image.save("output.png")
```

### Img2Img, Inpainting & ControlNet

```python
# Img2Img: AutoPipelineForImage2Image
# result = pipe(prompt=..., image=init_image, strength=0.75).images[0]

# Inpainting: AutoPipelineForInpainting (white mask = region to fill)
# result = pipe(prompt=..., image=image, mask_image=mask).images[0]

# ControlNet (canny, openpose, depth, normal, mlsd, scribble)
from diffusers import StableDiffusionControlNetPipeline, ControlNetModel

controlnet = ControlNetModel.from_pretrained("lllyasviel/control_v11p_sd15_canny", torch_dtype=torch.float16)
cn_pipe = StableDiffusionControlNetPipeline.from_pretrained(
    "stable-diffusion-v1-5/stable-diffusion-v1-5",
    controlnet=controlnet,
    torch_dtype=torch.float16,
).to("cuda")
```

### VRAM optimization & common issues
- Memory savers: `pipe.enable_model_cpu_offload()`, `pipe.enable_attention_slicing()`, `pipe.enable_vae_slicing()`, `pipe.enable_vae_tiling()`, `pipe.enable_xformers_memory_efficient_attention()`.
- **Black/NaN images**: ensure consistent `torch.float16`/`bfloat16` across pipeline and custom VAE (`AutoencoderKL`), and check `safety_checker`.
- Dimensions (`height`, `width`) must be multiples of 8 (512 for SD 1.5, 1024 for SDXL).

---

## Whisper (Speech Recognition)

### Install

```bash
pip install -U openai-whisper
# Requires ffmpeg on PATH: sudo apt install ffmpeg (or brew install ffmpeg)
# Faster CTranslate2 backend (4x faster):
pip install faster-whisper
```

### Models & VRAM

| Model | Params | English-only | Multilingual | Speed | VRAM |
|---|---|---|---|---|---|
| `tiny` | 39M | Yes | Yes | ~32x | ~1 GB |
| `base` | 74M | Yes | Yes | ~16x | ~1 GB |
| `small` | 244M | Yes | Yes | ~6x | ~2 GB |
| `medium` | 769M | Yes | Yes | ~2x | ~5 GB |
| `large` | 1550M | No | Yes | 1x | ~10 GB |
| `turbo` | 809M | No | Yes | ~8x | ~6 GB |

### Python & CLI usage

```python
import whisper

model = whisper.load_model("turbo")  # Best speed/quality balance
result = model.transcribe(
    "audio.mp3",
    language="en",                 # Specify to skip detection and speed up
    task="transcribe",             # Or "translate" (any language -> English)
    initial_prompt="Technical podcast on machine learning.",
    word_timestamps=True,
    temperature=(0.0, 0.2, 0.4, 0.6, 0.8, 1.0),
)
print(result["text"])
for seg in result["segments"]:
    print(f"[{seg['start']:.2f}s - {seg['end']:.2f}s] {seg['text']}")
```

```bash
whisper audio.mp3 --model turbo --output_format srt --language English
# Output formats: txt, srt, vtt, json
# Extract audio from video first if needed:
ffmpeg -i video.mp4 -vn -acodec pcm_s16le audio.wav
```

### Streaming / fast inference (`faster-whisper`)

```python
from faster_whisper import WhisperModel

model = WhisperModel("base", device="cuda", compute_type="float16")
segments, info = model.transcribe("audio.mp3", beam_size=5)
for seg in segments:
    print(f"[{seg.start:.2f}s -> {seg.end:.2f}s] {seg.text}")
```

### Gotchas
- Accuracy degrades on >30 min audio; chunk long files with `ffmpeg`.
- Whisper does not perform speaker diarization; pair with `pyannote.audio` if speaker labels are needed.

---

## AudioCraft (MusicGen, AudioGen, EnCodec)

### Install

```bash
pip install audiocraft
# Or via HuggingFace Transformers: pip install transformers torch torchaudio
```

### Models & VRAM

| Model | Size | Sample Rate | Use Case | FP16 VRAM |
|---|---|---|---|---|
| `facebook/musicgen-small` | 300M | 32 kHz | Fast text-to-music | ~2 GB |
| `facebook/musicgen-medium` | 1.5B | 32 kHz | Balanced text-to-music | ~4 GB |
| `facebook/musicgen-large` | 3.3B | 32 kHz | Best quality | ~8 GB |
| `facebook/musicgen-melody` | 1.5B | 32 kHz | Text + melody chroma | ~4 GB |
| `facebook/musicgen-stereo-medium` | 1.5B | 32 kHz | Stereo output | ~4 GB |
| `facebook/musicgen-style` | 1.5B | 32 kHz | Audio style transfer | ~4 GB |
| `facebook/audiogen-medium` | 1.5B | 16 kHz | Sound effects | ~4 GB |

### MusicGen, Melody, Style & AudioGen

```python
import torchaudio
from audiocraft.models import MusicGen, AudioGen

# Text-to-music
model = MusicGen.get_pretrained("facebook/musicgen-medium")
model.set_generation_params(duration=15, top_k=250, temperature=1.0, cfg_coef=3.0)
wav = model.generate(["epic orchestral soundtrack with strings and brass"])
torchaudio.save("music.wav", wav[0].cpu(), sample_rate=32000)

# Melody-conditioned
melody_model = MusicGen.get_pretrained("facebook/musicgen-melody")
melody_model.set_generation_params(duration=15)
melody, sr = torchaudio.load("melody.wav")
wav = melody_model.generate_with_chroma(["acoustic guitar folk song"], melody, sr)

# Sound effects (16 kHz)
sfx_model = AudioGen.get_pretrained("facebook/audiogen-medium")
sfx_model.set_generation_params(duration=5)
sfx = sfx_model.generate(["thunderstorm with heavy rain"])
torchaudio.save("sfx.wav", sfx[0].cpu(), sample_rate=16000)
```

For `musicgen-style`, configure `model.set_generation_params(cfg_coef=3.0, cfg_coef_beta=5.0)` and `model.set_style_conditioner_params(eval_q=3, excerpt_length=3.0)`, then call `model.generate_with_style(descriptions, style_audio, sr)`.

### Gotchas
- MusicGen outputs at **32 kHz**; AudioGen outputs at **16 kHz**. Resample inputs (e.g., for `CompressionModel.get_pretrained("facebook/encodec_32khz")`) to match the model's sample rate.
- Batch multiple prompts in a single `model.generate(descriptions)` call for throughput, and call `torch.cuda.empty_cache()` between long generations if hitting OOM.
