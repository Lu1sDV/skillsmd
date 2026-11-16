# Vision-Language & Segmentation Reference

Consolidated engineering reference for **CLIP**, **BLIP-2**, **LLaVA**, and **Segment Anything (SAM)**.

## Tool selection

| Task | Tool | Why |
|---|---|---|
| Zero-shot classification, image-text similarity, semantic search | **CLIP** | Fast dual-encoder embeddings; no text generation |
| Image captioning, concise VQA, image-text matching (ITM) | **BLIP-2** | Lightweight Q-Former bridging frozen ViT + OPT/FlanT5 |
| Multi-turn visual chat, instruction following, document QA | **LLaVA** | Instruction-tuned LLM + CLIP encoder; conversational |
| Promptable object masks (points, boxes) or auto-masking | **SAM** | Zero-shot class-agnostic segmentation; ONNX-exportable |

---

## CLIP (Contrastive Language-Image Pre-Training)

### Install

```bash
pip install git+https://github.com/openai/CLIP.git
pip install torch torchvision ftfy regex tqdm
```

### Models

| Model | Params | Speed | Quality |
|---|---|---|---|
| `RN50` | 102M | Fast | Good |
| `ViT-B/32` | 151M | Medium | Better (default) |
| `ViT-B/16` | ~150M | Slower | Higher spatial detail |
| `ViT-L/14` | 428M | Slow | Best |

### Zero-shot classification & normalized similarity

Always normalize image and text embeddings before computing cosine similarity.

```python
import torch
import clip
from PIL import Image

device = "cuda" if torch.cuda.is_available() else "cpu"
model, preprocess = clip.load("ViT-B/32", device=device)

image = preprocess(Image.open("photo.jpg")).unsqueeze(0).to(device)
labels = ["a dog", "a cat", "a bird", "a car"]
text = clip.tokenize(labels).to(device)

with torch.no_grad():
    logits_per_image, _ = model(image, text)
    probs = logits_per_image.softmax(dim=-1).cpu().numpy()

    # For retrieval / vector DB indexing:
    img_emb = model.encode_image(image)
    img_emb = img_emb / img_emb.norm(dim=-1, keepdim=True)
    txt_emb = model.encode_text(text)
    txt_emb = txt_emb / txt_emb.norm(dim=-1, keepdim=True)
    sim_matrix = img_emb @ txt_emb.T  # (N_img, N_txt)
```

### Gotchas & limits
- Use descriptive prompts (`"a photo of a {label}"`) rather than single bare nouns for better zero-shot accuracy.
- Whole-image embeddings only: no bounding boxes, weak spatial/counting reasoning, and struggles with fine-grained sub-categories.

---

## BLIP-2 (Frozen Encoder + Q-Former + LLM)

### Install

```bash
pip install transformers accelerate torch Pillow
# Optional (for ITM head and extract_features):
pip install salesforce-lavis
```

### Models & VRAM

| Model | LLM Backend | FP16 VRAM | INT8 VRAM | INT4 VRAM |
|---|---|---|---|---|
| `Salesforce/blip2-opt-2.7b` | OPT-2.7B | ~8 GB | ~5 GB | ~3 GB |
| `Salesforce/blip2-opt-6.7b` | OPT-6.7B | ~16 GB | ~9 GB | ~5 GB |
| `Salesforce/blip2-flan-t5-xl` | FlanT5-XL | ~10 GB | ~6 GB | ~4 GB |
| `Salesforce/blip2-flan-t5-xxl` | FlanT5-XXL | ~26 GB | ~14 GB | ~8 GB |

### Captioning, VQA & Quantization (Transformers)

```python
import torch
from PIL import Image
from transformers import Blip2Processor, Blip2ForConditionalGeneration, BitsAndBytesConfig

model_id = "Salesforce/blip2-flan-t5-xl"
processor = Blip2Processor.from_pretrained(model_id)

# Optional 4-bit quantization for lower VRAM
bnb_config = BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_compute_dtype=torch.float16)
model = Blip2ForConditionalGeneration.from_pretrained(
    model_id,
    quantization_config=bnb_config,  # or torch_dtype=torch.float16
    attn_implementation="flash_attention_2",  # optional if flash-attn installed
    device_map="auto",
)

image = Image.open("photo.jpg").convert("RGB")
# Captioning: omit text; VQA (FlanT5): format as "Question: ... Answer:"
inputs = processor(images=image, text="Question: What color is the car? Answer:", return_tensors="pt").to("cuda", torch.float16)

generated_ids = model.generate(**inputs, max_new_tokens=50, num_beams=5, no_repeat_ngram_size=2)
print(processor.batch_decode(generated_ids, skip_special_tokens=True)[0])
```

### Gotchas
- Always `.convert("RGB")` before passing PIL images.
- For batching with `text`, pass `padding=True` and a list of prompts matching `len(images)`.
- Reduce hallucinations by using `do_sample=False` with `num_beams=5` instead of high-temperature sampling.

---

## LLaVA (Large Language and Vision Assistant)

### Install

```bash
git clone https://github.com/haotian-liu/LLaVA
cd LLaVA && pip install -e .
```

### Models & VRAM (A100)

| Model | HF ID | FP16 VRAM | 4-bit VRAM | Speed |
|---|---|---|---|---|
| LLaVA-v1.5-7B | `liuhaotian/llava-v1.5-7b` | ~14 GB | ~4 GB | ~20 tok/s |
| LLaVA-v1.5-13B | `liuhaotian/llava-v1.5-13b` | ~28 GB | ~8 GB | ~12 tok/s |
| LLaVA-v1.6-34B | `liuhaotian/llava-v1.6-34b` | ~70 GB | ~18 GB | ~5 tok/s |

### Python inference & multi-turn chat

```python
import torch
from PIL import Image
from llava.model.builder import load_pretrained_model
from llava.mm_utils import get_model_name_from_path, process_images, tokenizer_image_token
from llava.constants import IMAGE_TOKEN_INDEX, DEFAULT_IMAGE_TOKEN
from llava.conversation import conv_templates

model_path = "liuhaotian/llava-v1.5-7b"
tokenizer, model, image_processor, _ = load_pretrained_model(
    model_path=model_path,
    model_base=None,
    model_name=get_model_name_from_path(model_path),
    load_4bit=True,  # or load_8bit=True
)

image = Image.open("image.jpg").convert("RGB")
image_tensor = process_images([image], image_processor, model.config).to(model.device, dtype=torch.float16)

conv = conv_templates["llava_v1"].copy()
conv.append_message(conv.roles[0], DEFAULT_IMAGE_TOKEN + "\nWhat is in this image?")
conv.append_message(conv.roles[1], None)

input_ids = tokenizer_image_token(conv.get_prompt(), tokenizer, IMAGE_TOKEN_INDEX, return_tensors="pt").unsqueeze(0).to(model.device)
with torch.inference_mode():
    output_ids = model.generate(input_ids, images=image_tensor, do_sample=True, temperature=0.2, max_new_tokens=512)

response = tokenizer.decode(output_ids[0], skip_special_tokens=True).strip()
```

### CLI & Gradio serving

```bash
python -m llava.serve.cli --model-path liuhaotian/llava-v1.5-7b --image-file image.jpg --query "What is in this image?"
python -m llava.serve.gradio_web_server --model-path liuhaotian/llava-v1.5-7b --load-4bit
```

### Gotchas
- Keep `temperature` low (`0.2`–`0.7`) to limit visual hallucinations.
- Weak at reading tiny text, precise spatial coordinates, and counting many small objects.

---

## Segment Anything Model (SAM)

### Install & Checkpoints

```bash
pip install git+https://github.com/facebookresearch/segment-anything.git
pip install opencv-python pycocotools matplotlib
# Or use HuggingFace: pip install transformers
```

Checkpoints (`https://dl.fbaipublicfiles.com/segment_anything/`):
- `vit_h` (`sam_vit_h_4b8939.pth`, 2.4 GB) — highest accuracy
- `vit_l` (`sam_vit_l_0b3195.pth`, 1.2 GB) — balanced
- `vit_b` (`sam_vit_b_01ec64.pth`, 375 MB) — fastest, lowest VRAM

### Promptable segmentation (`SamPredictor`)

`set_image()` computes the ViT image embedding once; subsequent `predict()` calls with points, boxes, or mask logits are fast.

```python
import cv2
import numpy as np
from segment_anything import sam_model_registry, SamPredictor

sam = sam_model_registry["vit_h"](checkpoint="sam_vit_h_4b8939.pth").to("cuda")
predictor = SamPredictor(sam)

image = cv2.cvtColor(cv2.imread("image.jpg"), cv2.COLOR_BGR2RGB)
predictor.set_image(image)

# Point prompt (1 = foreground, 0 = background) + optional box [x1, y1, x2, y2]
masks, scores, logits = predictor.predict(
    point_coords=np.array([[500, 375], [550, 400]]),
    point_labels=np.array([1, 0]),
    box=np.array([400, 300, 700, 600]),
    multimask_output=True,  # False when prompt is unambiguous
)
best_idx = np.argmax(scores)
best_mask = masks[best_idx]

# Iterative refinement using previous low-res logits:
masks, scores, _ = predictor.predict(
    point_coords=np.array([[500, 375], [550, 400], [480, 360]]),
    point_labels=np.array([1, 0, 1]),
    mask_input=logits[best_idx][None, :, :],
    multimask_output=False,
)
```

### Automatic mask generation & ONNX export

```python
from segment_anything import SamAutomaticMaskGenerator

mask_generator = SamAutomaticMaskGenerator(
    model=sam,
    points_per_side=32,          # Lower (e.g., 16) for speed; higher for small objects
    pred_iou_thresh=0.88,
    stability_score_thresh=0.95,
    min_mask_region_area=100,
)
masks = mask_generator.generate(image)  # list of dicts with segmentation, bbox, area, predicted_iou, stability_score
```

```bash
python scripts/export_onnx_model.py \
  --checkpoint sam_vit_h_4b8939.pth --model-type vit_h \
  --output sam_onnx.onnx --return-single-mask
```

### Gotchas
- Convert BGR (from `cv2.imread`) or grayscale medical scans to RGB before `set_image()`.
- For text-prompted segmentation, pair GroundingDINO boxes with SAM; for video tracking, use SAM 2.
