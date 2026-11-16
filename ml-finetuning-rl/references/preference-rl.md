# Preference & Single-Node RL Reference (TRL, GRPO, SimPO)

Distilled guide to post-training alignment with Hugging Face TRL (`SFTTrainer`, `RewardTrainer`, `DPOTrainer`, `PPOTrainer`, `GRPOTrainer`), verifiable-reward GRPO workflows, and reference-free SimPO.

---

## 1. Method Selection

| Method | Data Required | Reference Model | Reward Model | Best For |
|---|---|---|---|---|
| **SFT** (`SFTTrainer`) | Prompt-completion pairs | No | No | Initial instruction following / format grounding |
| **DPO** (`DPOTrainer`) | `prompt`, `chosen`, `rejected` | Yes (2x VRAM) | No | Standard preference alignment |
| **SimPO** | `prompt`, `chosen`, `rejected` | **No** | No | Higher win-rate than DPO with less memory |
| **GRPO** (`GRPOTrainer`) | Prompts (+ optional ground truth) | Optional KL | **Function or model** | Verifiable tasks (math, code, XML/JSON format), reasoning |
| **PPO** | Prompts | Yes | Yes (separate) | Dense rewards, full critic-actor control |

VRAM rule of thumb (7B with LoRA): SFT ~16 GB, DPO ~24 GB, GRPO ~24 GB, PPO ~40 GB.

---

## 2. TRL Core Workflows

Install:
```bash
pip install trl transformers datasets peft accelerate
```

### SFT (`SFTTrainer` + `SFTConfig`)
```python
from trl import SFTTrainer, SFTConfig
from peft import LoraConfig

trainer = SFTTrainer(
    model="Qwen/Qwen2.5-0.5B",
    args=SFTConfig(
        output_dir="./sft-out",
        per_device_train_batch_size=4,
        learning_rate=2e-5,
        num_train_epochs=1,
        max_seq_length=1024,
    ),
    train_dataset=dataset,
    peft_config=LoraConfig(r=16, lora_alpha=32, target_modules="all-linear"),
)
trainer.train()
```

### Reward Model (`RewardTrainer`)
```python
from transformers import AutoModelForSequenceClassification, AutoTokenizer
from trl import RewardTrainer, RewardConfig

model = AutoModelForSequenceClassification.from_pretrained("Qwen2.5-0.5B-SFT", num_labels=1)
tokenizer = AutoTokenizer.from_pretrained("Qwen2.5-0.5B-SFT")

trainer = RewardTrainer(
    model=model,
    args=RewardConfig(output_dir="./rm-out", per_device_train_batch_size=2, learning_rate=1e-5),
    processing_class=tokenizer,
    train_dataset=preference_dataset,  # chosen/rejected pairs
)
trainer.train()
```

### DPO (`DPOTrainer` + CLI)
```python
from trl import DPOTrainer, DPOConfig

config = DPOConfig(
    output_dir="./dpo-out",
    per_device_train_batch_size=4,
    learning_rate=5e-7,
    beta=0.1,                  # Higher = closer to reference; lower = stronger alignment
    max_prompt_length=512,
    max_length=1024,
)
trainer = DPOTrainer(
    model=model,
    args=config,
    train_dataset=preference_dataset,
    processing_class=tokenizer,
)
trainer.train()
```
CLI equivalent:
```bash
trl dpo --model_name_or_path Qwen/Qwen2.5-0.5B-Instruct \
  --dataset_name argilla/Capybara-Preferences --output_dir ./dpo-out \
  --per_device_train_batch_size 4 --learning_rate 5e-7 --beta 0.1
```

### PPO CLI
```bash
python -m trl.scripts.ppo \
  --model_name_or_path Qwen2.5-0.5B-SFT \
  --reward_model_path Qwen2.5-0.5B-Reward \
  --dataset_name trl-internal-testing/descriptiveness-sentiment-trl-style \
  --output_dir ./ppo-out --learning_rate 3e-6 --total_episodes 10000
```

---

## 3. GRPO (`GRPOTrainer` & Verifiable Rewards)

GRPO samples `num_generations` completions per prompt and normalizes rewards within each group — no separate critic model required.

### Dataset & Reward Function Signatures
Prompts should be chat-formatted (`[{"role": "system", ...}, {"role": "user", ...}]`) with optional ground-truth columns (e.g., `answer`) passed via `**kwargs` to reward functions:

```python
import re

def correctness_reward(prompts, completions, answer, **kwargs) -> list[float]:
    responses = [c[0]["content"] for c in completions]
    return [2.0 if extract_answer(r) == gt else 0.0 for r, gt in zip(responses, answer)]

def format_reward(completions, **kwargs) -> list[float]:
    pattern = r"<reasoning>.*?</reasoning>\s*<answer>.*?</answer>"
    responses = [c[0]["content"] for c in completions]
    return [1.0 if re.search(pattern, r, re.DOTALL) else 0.0 for r in responses]
```
Design rules:
- Compose 3-5 diverse reward signals (correctness weight `2.0`, strict format `0.5-1.0`, partial/incremental format credit `0.25` per tag, length/style `-0.5` to `0.5`).
- Test each reward function independently on dummy completions before launching training.

### GRPO Configuration & Launch
```python
from trl import GRPOConfig, GRPOTrainer

config = GRPOConfig(
    output_dir="./grpo-out",
    learning_rate=5e-6,            # 5e-6 safe; 1e-5 faster but riskier
    per_device_train_batch_size=1,
    gradient_accumulation_steps=4,
    num_generations=8,             # 8-16 recommended; start at 4 if VRAM tight
    max_prompt_length=256,
    max_completion_length=512,
    bf16=True,
    optim="adamw_8bit",
    max_grad_norm=0.1,
    use_vllm=True,                 # Optional: major rollout speedup on large GPUs
)
trainer = GRPOTrainer(
    model=model,
    processing_class=tokenizer,
    reward_funcs=[format_reward, correctness_reward],
    args=config,
    train_dataset=dataset,
    peft_config=lora_config,
)
trainer.train()
```
CLI: `trl grpo --model_name_or_path Qwen/Qwen2-0.5B-Instruct --dataset_name trl-lib/tldr --output_dir ./grpo-out --num_generations 4`

### Critical GRPO Diagnostics
- **Loss increases during training**: Expected! In GRPO, loss reflects KL divergence from the initial policy. Track `reward`, `reward_std`, and `kl` instead of loss.
- **Mode collapse**: `reward_std -> 0` (identical completions). Increase `num_generations` or add partial-credit/diversity rewards.
- **KL explosion** (`kl > 0.5`): Lower `learning_rate` (e.g., `5e-6` -> `1e-6`) or increase KL penalty.

---

## 4. SimPO (Simple Preference Optimization)

SimPO eliminates the reference model by using length-normalized average log-probability as an implicit reward with a target reward margin (`gamma_beta_ratio`).

Install (`alignment-handbook`):
```bash
git clone https://github.com/huggingface/alignment-handbook.git
cd alignment-handbook && pip install .
pip install flash-attn --no-build-isolation
```

Config (`simpo.yaml`):
```yaml
model_name_or_path: meta-llama/Meta-Llama-3-8B-Instruct
torch_dtype: bfloat16
dataset_mixer:
  argilla/ultrafeedback-binarized-preferences-cleaned: 1.0

beta: 2.5                  # Reward scaling (2.0-10.0; 5.0 for math/code)
gamma_beta_ratio: 0.5      # Target margin (0-1; 0.7-0.8 for stronger separation)
loss_type: sigmoid         # sigmoid or hinge
sft_weight: 0.1            # >0 preserves capabilities on instruct models
learning_rate: 5e-7        # Critical range: 3e-7 to 1e-6
per_device_train_batch_size: 2
gradient_accumulation_steps: 4
num_train_epochs: 1
output_dir: ./outputs/llama3-8b-simpo
```

Launch with DeepSpeed ZeRO-3:
```bash
ACCELERATE_LOG_LEVEL=info accelerate launch \
  --config_file accelerate_configs/deepspeed_zero3.yaml \
  scripts/run_simpo.py training_configs/simpo.yaml
```

### Troubleshooting Preference & RL Runs
- **SimPO loss divergence**: Lower `learning_rate` to `3e-7` and `beta` to `1.0`.
- **SimPO capability forgetting**: Set `sft_weight: 0.1`.
- **DPO OOM**: Set `per_device_train_batch_size=1`, `max_length=512`, `gradient_accumulation_steps=8`, and enable `gradient_checkpointing`.
- **PPO instability**: Increase `kl_coef` (e.g., `0.05` -> `0.1`) and reduce `cliprange` (`0.2` -> `0.1`).
