# Reinforcement Learning: Stable Baselines3 & PufferLib

Guide to single-agent RL with `stable-baselines3` (`2.9.0`) and high-throughput environment vectorization / PuffeRL training with `pufferlib` (`3.0.0`, `4.0`, `5.0`).

## Tool Selection

| Need | Tool | Notes |
|---|---|---|
| **Standard single-agent RL** (PPO, SAC, DQN, TD3, DDPG, A2C) | `stable-baselines3==2.9.0` | PyTorch `>=2.8`, Gymnasium `>=0.29.1,<2.0`; `sb3-contrib` for `MaskablePPO`, `RecurrentPPO`, `CrossQ`, `QR-DQN` |
| **High-throughput C/CUDA or multi-agent vectorization** | `pufferlib` | Choose profile explicitly: `5.0` (native C/CUDA), `3.0.0` (PyPI Gymnasium/PettingZoo + Torch PuffeRL), or pinned `4.0` |

---

## Stable Baselines3 (`stable-baselines3==2.9.0`, Python 3.10+)

```bash
uv pip install "stable-baselines3==2.9.0"
uv pip install "stable-baselines3[extra]==2.9.0"   # TensorBoard, ale-py for Atari, etc.
uv pip install "gymnasium[mujoco]"                  # MuJoCo continuous control
```

### Algorithm Selection

| Algorithm | Action Spaces | Policy | Best For |
|---|---|---|---|
| **PPO / A2C** | `Box`, `Discrete`, flat `MultiDiscrete`, `MultiBinary` | On-policy | General purpose, multiprocessing (`SubprocVecEnv`) |
| **SAC / TD3 / DDPG** | `Box` (continuous) | Off-policy | Sample-efficient continuous control |
| **DQN** | `Discrete` | Off-policy | Discrete action spaces |
| **HER** (`HerReplayBuffer`) | Goal-conditioned (`Dict` obs) | Off-policy wrapper | Sparse-reward goal environments exposing `observation`, `achieved_goal`, `desired_goal`, vectorized `compute_reward` |

### Core Training, Vectorization & Persistence

```python
import gymnasium as gym
from stable_baselines3 import PPO
from stable_baselines3.common.env_util import make_vec_env
from stable_baselines3.common.vec_env import VecNormalize

# DummyVecEnv (sequential) or SubprocVecEnv (parallel, guard under if __name__ == "__main__":)
env = make_vec_env("Pendulum-v1", n_envs=4, seed=0)
env = VecNormalize(env, norm_obs=True, norm_reward=True)

model = PPO("MlpPolicy", env, verbose=1, device="cpu", seed=0)  # CPU often faster for MlpPolicy on small envs
model.learn(total_timesteps=25000)

# Save BOTH model and VecNormalize stats
model.save("ppo_pendulum")
model.get_vec_normalize_env().save("vec_normalize.pkl")
env.close()

# Evaluation: build matching base env, load stats, freeze training=False & norm_reward=False
eval_env = make_vec_env("Pendulum-v1", n_envs=1, seed=20000)
eval_env = VecNormalize.load("vec_normalize.pkl", eval_env)
eval_env.training = False
eval_env.norm_reward = False
model = PPO.load("ppo_pendulum", env=eval_env, device="cpu")
```

### Custom Environments & Gotchas
- **Gymnasium contract**: Inherit `gymnasium.Env`; implement `reset(seed, options) -> (obs, info)` and `step(action) -> (obs, reward, terminated, truncated, info)`. Validate with `check_env(env, warn=True)`.
- **Spaces**: `Discrete` / `MultiDiscrete` with `start != 0` are **not** supported.
- **Images**: Default CNN expects `np.uint8` in `[0, 255]` (channel-first preferred; auto-divided by 255). For pre-normalized float images, use channel-first layout + `policy_kwargs={"normalize_images": False}`.
- **VecEnv API**: `reset()` returns `obs` only (`vec_env.reset_infos` for infos); `step()` returns 4-tuple `(obs, rewards, dones, infos)` and auto-resets—final pre-reset obs is in `infos[i]["terminal_observation"]`.
- **Replay buffers**: `model.save()` does **not** save off-policy replay buffers; call `save_replay_buffer()` / `load_replay_buffer()` separately. Resume training with `learn(..., reset_num_timesteps=False)`.
- **Off-policy throughput**: With step-based `train_freq`, `gradient_steps=-1` matches gradient steps to `train_freq * n_envs` after warmup—benchmark before assuming speedup.
- **Callbacks**: `EvalCallback`, `CheckpointCallback`, `StopTrainingOnRewardThreshold`, `ProgressBarCallback`, `CallbackList`, or subclass `BaseCallback` (`_on_step()` returns `False` to stop).
- **Schedules & multi-input**: Pass `learning_rate=lambda progress_remaining: progress_remaining * lr0`; use `"MultiInputPolicy"` for `Dict` observation spaces.

---

## PufferLib (Version-Aware Profiles)

**Choose the profile before choosing an API:**

| Profile | Dependencies | Primary Use | CLI / Entrypoint |
|---|---|---|---|
| **Native `5.0`** (default branch) | Native C/CUDA toolchain; CPU builds eval-only | C/CUDA environments, native trainer | `./puffer train` (after building env; **no** Python emulation/vector API or `--slowly`) |
| **`pufferlib==3.0.0`** (PyPI sdist) | Python `>=3.9`, NumPy `<2`, Gymnasium `<=0.29.1`, PettingZoo `<=1.24.1`, Linux/macOS | Python/Gym/PettingZoo adaptation + Torch `PuffeRL` | `pufferl.PuffeRL(train_config, vecenv, policy)` |
| **Pinned `4.0`** (`2564763...`) | Python `>=3.10`, Torch `>=2.9` | C Ocean interface + optional Torch fallback (`--slowly`) | `puffer train ENV_NAME` / `puffer eval` / `puffer sweep` |

### Published `pufferlib==3.0.0` API

```python
import pufferlib.emulation
import pufferlib.vector
from pufferlib import pufferl

# Explicit wrappers (there is NO pufferlib.emulate(...) shortcut in 3.0.0)
def make_env():
    gym_env = ...  # reviewed Gymnasium instance
    return pufferlib.emulation.GymnasiumPufferEnv(gym_env)
    # Or for PettingZoo Parallel: pufferlib.emulation.PettingZooPufferEnv(pz_env)

vecenv = pufferlib.vector.make(
    make_env,
    backend=pufferlib.vector.Serial,   # validate Serial before Multiprocessing
    num_envs=4,
    seed=42,
)
# train_config must include environment name for checkpoint naming
trainer = pufferl.PuffeRL(train_config, vecenv, policy)
```

### Native `PufferEnv`, Policies & Safety Rules
- **Native `PufferEnv` (3.0)**: Set `single_observation_space`, `single_action_space`, and `num_agents` **before** `super().__init__(buf)`. Uses in-place vector buffers and returns separate terminal/truncation arrays + list of info dicts.
- **Policies**:
  - `3.0`: Torch modules sized from `single_observation_space` / `single_action_space`; use `encode_observations` / `decode_actions` for recurrent composition, and `pufferlib.pytorch.nativize_dtype` / `nativize_tensor` for structured emulation.
  - `4.0` Torch fallback (`--slowly`): `pufferlib.models.Policy(encoder=..., decoder=..., network=...)` with MLP, MinGRU, LSTM, or GRU.
- **Truncation & autoreset**: Preserve `terminated` (MDP terminal) vs `truncated` (time cutoff) and retain pre-reset observations—never bootstrap from the next episode. Note that `3.0` trainer has known edge cases with truncation and inactive-agent masks.
- **Multi-agent batching**: Batch length scales by agent slots, not `num_envs`.
- **Logging & checkpoints**: Neptune shut down on `2026-03-05`—do not configure it. For W&B, use `WANDB_API_KEY` env var only (never pass keys in CLI/INI/JSON/logs). Verify SHA-256 of `.pt`/`.bin` checkpoints before loading in a sandbox (`torch.load` unpickles arbitrary code); never reference `latest` in reproducible eval.
