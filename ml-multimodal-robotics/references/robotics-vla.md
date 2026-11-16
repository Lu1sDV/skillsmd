# Robotics Vision-Language-Action (VLA) Reference

Consolidated engineering reference for **OpenPI (`pi0`, `pi0-fast`, `pi0.5`)**, **OpenVLA-OFT / OFT+**, and **NVIDIA Cosmos Policy**.

## Policy selection

| Framework | Models / Backbones | Action Head | Primary Use Cases |
|---|---|---|---|
| **OpenPI** | `pi0`, `pi0-fast`, `pi0.5` | Flow-matching / autoregressive tokens | JAX or PyTorch fine-tuning on LeRobot/RLDS; WebSocket serving for ALOHA, DROID, LIBERO |
| **OpenVLA-OFT / OFT+** | `openvla/openvla-7b` + LoRA (rank 32) | Continuous L1 regression or diffusion | High-precision LIBERO (~97%) and real-world ALOHA (OFT+ with FiLM + 3 cameras) |
| **Cosmos Policy** | `Cosmos-Policy-*-Predict2-2B` | Cosmos Tokenizer + autoregressive action tokens | Headless EGL simulation evaluation & latency profiling on LIBERO and RoboCasa |

---

## OpenPI (`pi0`, `pi0-fast`, `pi0.5`)

### Setup & Verification

```bash
git clone --recurse-submodules https://github.com/Physical-Intelligence/openpi.git
cd openpi
GIT_LFS_SKIP_SMUDGE=1 uv sync
GIT_LFS_SKIP_SMUDGE=1 uv pip install -e .
uv run python -c "from openpi.training import config as _config; print(_config.get_config('pi05_droid').name)"
```

### Training loop invariant
After every config, dataset, or transform change, run all four steps in order:
1. Compute norm stats -> 2. Train -> 3. Serve checkpoint -> 4. Validate inference.

### JAX fine-tuning (primary)

Select and adapt a `TrainConfig` in `src/openpi/training/config.py` (e.g., `pi05_libero`, `pi0_libero`, `pi0_fast_libero`, `pi0_aloha_pen_uncap`, `pi05_droid_finetune`, `pi05_full_droid_finetune`), matching `weight_loader` to `model_type`.

```bash
# 1. Compute normalization statistics (CPU or 1x GPU, ~8 GB)
uv run scripts/compute_norm_stats.py --config-name <config_name>
# For RLDS datasets, add: --group rlds

# 2. Launch JAX training (~40-60 GB VRAM; set fsdp_devices=4 in TrainConfig for multi-GPU)
XLA_PYTHON_CLIENT_MEM_FRACTION=0.9 uv run scripts/train.py <config_name> \
  --exp-name=<run_name> --overwrite
```

### PyTorch training & JAX-to-PyTorch conversion

OpenPI PyTorch requires patching the installed `transformers` package:

```bash
cp -r ./src/openpi/models_pytorch/transformers_replace/* \
  .venv/lib/python3.11/site-packages/transformers/

# Convert JAX checkpoint to PyTorch
uv run examples/convert_jax_model_to_pytorch.py \
  --checkpoint_dir <jax_checkpoint_dir> \
  --config_name <config_name> \
  --output_path <pytorch_checkpoint_dir>

# Single-GPU or DDP training
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
uv run torchrun --standalone --nnodes=1 --nproc_per_node=<num_gpus> \
  scripts/train_pytorch.py <config_name> --exp_name <run_name>
```

*Gotcha*: Reapply `transformers_replace` after any `uv sync` or `pip install` that touches `transformers` (or run `uv cache clean transformers` first).

### Policy serving & remote client

```bash
# Preset environment (ALOHA, ALOHA_SIM, DROID, LIBERO)
uv run scripts/serve_policy.py --env DROID

# Explicit checkpoint
uv run scripts/serve_policy.py policy:checkpoint \
  --policy.config=<config_name> \
  --policy.dir=checkpoints/<config_name>/<run_name>/<step>
```

```python
# Client in robot environment:
# pip install "openpi-client @ git+https://github.com/Physical-Intelligence/openpi.git#subdirectory=packages/openpi-client"
from openpi_client import websocket_client_policy

client = websocket_client_policy.WebsocketClientPolicy(host="localhost", port=8000)
result = client.infer({"image": img_array, "state": state_array, "prompt": "pick up the cup"})
actions = result["actions"]  # (chunk_size, action_dim)
```

### OpenPI troubleshooting & HPC tips
- **Exit code 137 (OOM kill) on server**: `export XLA_PYTHON_CLIENT_PREALLOCATE=false XLA_PYTHON_CLIENT_ALLOCATOR=platform`.
- **`rerun-sdk` wheel mismatch on `uv sync`**: `uv sync --no-dev --no-install-package rerun-sdk`.
- **Checkpoint download timeout**: install `gsutil`, delete stale `.lock` under `OPENPI_DATA_HOME`, and prefetch with `gsutil -m cp -r gs://openpi-assets/checkpoints/pi05_libero .`.
- **Cluster caches**: export `OPENPI_DATA_HOME`, `HF_HOME`, `XDG_CACHE_HOME`, `UV_CACHE_DIR`, `PIP_CACHE_DIR` to `/scratch/$USER/...`.

---

## OpenVLA-OFT and OFT+

### Setup (pinned versions)

Paper results are validated on **Python 3.10**, `torch==2.2.0`, `peft==0.11.1`, `robosuite==1.4.0`, `tensorflow==2.15.0`.

```bash
conda create -n openvla-oft python=3.10 -y && conda activate openvla-oft
git clone https://github.com/moojink/openvla-oft.git && cd openvla-oft
pip3 install torch==2.2.0 torchvision==0.17.0 torchaudio==2.2.0 robosuite==1.4.0
pip install -e .
pip install packaging ninja && pip install "flash-attn==2.5.5" --no-build-isolation
```

### Variants & Compute

| Variant | FiLM | Images (`num_images_in_input`) | Target | Eval VRAM | Train VRAM (8x A100) |
|---|---|---|---|---|---|
| **OFT** | `False` | 2 (front + wrist) | LIBERO sim | ~16 GB | ~27 GB/GPU |
| **OFT+** | `True` | 3 (high + left/right wrist) | ALOHA real | ~18 GB | ~35 GB/GPU |

### LIBERO evaluation & fine-tuning

```bash
# Eval pretrained checkpoint (e.g., moojink/openvla-7b-oft-finetuned-libero-spatial)
python experiments/robot/libero/run_libero_eval.py \
  --pretrained_checkpoint moojink/openvla-7b-oft-finetuned-libero-spatial \
  --task_suite_name libero_spatial --center_crop True --num_trials_per_task 50 --seed 7

# Fine-tune (RLDS datasets: libero_spatial_no_noops, libero_object_no_noops, libero_goal_no_noops, libero_10_no_noops)
torchrun --standalone --nnodes 1 --nproc-per-node 8 vla-scripts/finetune.py \
  --vla_path openvla/openvla-7b --data_root_dir /PATH/TO/RLDS/ \
  --dataset_name libero_spatial_no_noops --run_root_dir /YOUR/CHECKPOINTS/ \
  --use_l1_regression True --use_diffusion False --use_film False \
  --num_images_in_input 2 --use_proprio True --batch_size 8 --learning_rate 5e-4 \
  --num_steps_before_decay 100000 --max_steps 150005 --save_freq 10000 \
  --image_aug True --lora_rank 32

# Merge LoRA adapter for deployment (or re-merge when moving across GPU types)
python vla-scripts/merge_lora_weights_and_save.py \
  --base_checkpoint openvla/openvla-7b --lora_finetuned_checkpoint_dir /PATH/TO/CHECKPOINT_DIR
```

### ALOHA OFT+ workflow & server-client deployment

1. Preprocess with `experiments/robot/aloha/preprocess_split_aloha_data.py` and register RLDS entries in `prismatic/vla/datasets/rlds/oxe/{configs,transforms,mixtures}.py`.
2. Verify `prismatic/vla/constants.py` (ALOHA defaults: `NUM_ACTIONS_CHUNK=25`, `ACTION_DIM=14`, `PROPRIO_DIM=14`, `BOUNDS`). Note: `constants.py` auto-detects platform from command-line path tokens (`libero`, `aloha`, `bridge`).
3. Fine-tune with `--use_film True --num_images_in_input 3 --batch_size 4 --max_steps 100005`.
4. Serve and evaluate:

```bash
# GPU server (listens on http://<server-ip>:8777/act)
python vla-scripts/deploy.py \
  --pretrained_checkpoint /PATH/TO/CHECKPOINT/ \
  --use_l1_regression True --use_film True --num_images_in_input 3 \
  --use_proprio True --center_crop True --unnorm_key aloha_task_name

# Robot client
python experiments/robot/aloha/run_aloha_eval.py \
  --center_crop True --num_open_loop_steps 25 --use_vla_server True \
  --vla_server_url http://<SERVER_IP>:8777 --num_rollouts_planned 50 --max_steps 1500
```

### Critical train/eval parity invariants
Mismatches between training and eval/deploy cause silent accuracy drops:
- `use_l1_regression` / `use_diffusion` must match.
- `use_film`, `num_images_in_input`, `use_proprio`, and `lora_rank` must match.
- `image_aug=True` during training **requires** `center_crop=True` during eval/deploy.
- `--unnorm_key` must exist in `ckpt["norm_stats"]`.
- **Cross-GPU drop**: re-run `merge_lora_weights_and_save.py` on the target GPU architecture if success drops after moving checkpoints.

---

## NVIDIA Cosmos Policy

### Setup & Headless EGL Environment

Always export all four EGL/GPU variables together on headless nodes so MuJoCo rendering matches CUDA:

```bash
git clone https://github.com/NVlabs/cosmos-policy.git && cd cosmos-policy
# Recommended: enter official container from SETUP.md, then:
uv sync --extra cu128 --group libero --python 3.10
# For RoboCasa, also install the patched fork:
git clone https://github.com/moojink/robocasa-cosmos-policy.git
uv pip install -e robocasa-cosmos-policy
python -m robocasa.scripts.setup_macros && python -m robocasa.scripts.download_kitchen_assets

export CUDA_VISIBLE_DEVICES=0
export MUJOCO_EGL_DEVICE_ID=0
export MUJOCO_GL=egl
export PYOPENGL_PLATFORM=egl
```

### LIBERO evaluation (~16 GB VRAM)

```bash
uv run --extra cu128 --group libero --python 3.10 \
  python -m cosmos_policy.experiments.robot.libero.run_libero_eval \
    --config cosmos_predict2_2b_480p_libero__inference_only \
    --ckpt_path nvidia/Cosmos-Policy-LIBERO-Predict2-2B \
    --config_file cosmos_policy/config/config.py \
    --use_wrist_image True --use_proprio True \
    --normalize_proprio True --unnormalize_actions True \
    --dataset_stats_path nvidia/Cosmos-Policy-LIBERO-Predict2-2B/libero_dataset_statistics.json \
    --t5_text_embeddings_path nvidia/Cosmos-Policy-LIBERO-Predict2-2B/libero_t5_embeddings.pkl \
    --trained_with_image_aug True --chunk_size 16 --num_open_loop_steps 16 \
    --task_suite_name libero_10 --num_trials_per_task 1 \
    --local_log_dir cosmos_policy/experiments/robot/libero/logs/ \
    --seed 195 --randomize_seed False --deterministic True \
    --use_jpeg_compression True --flip_images True \
    --num_denoising_steps_action 5 --num_denoising_steps_future_state 1 --num_denoising_steps_value 1 \
    --data_collection False
```

### RoboCasa evaluation (~18 GB VRAM)

Use `cosmos_policy.experiments.robot.robocasa.run_robocasa_eval` with `--config cosmos_predict2_2b_480p_robocasa_50_demos_per_task__inference`, `--ckpt_path nvidia/Cosmos-Policy-RoboCasa-Predict2-2B`, `--num_wrist_images 1`, `--chunk_size 32`, `--num_open_loop_steps 16`, `--task_name TurnOffMicrowave`, and `--obj_instance_split A` (keep split, seed, and trial count fixed across comparisons).

### Gotchas
- **LIBERO interactive prompt (`EOFError`)**: pre-create `~/.libero/config.yaml` (or `$LIBERO_CONFIG_PATH/config.yaml`) with `benchmark_root` before headless runs.
- **`EGL_NOT_INITIALIZED` at shutdown**: treat as teardown noise unless exit code is non-zero.
- **Host Python binary failures**: fall back to the official Docker container in `SETUP.md`.
