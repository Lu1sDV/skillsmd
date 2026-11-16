# Cloud GPU Infrastructure

Practical guide to running ML training, batch jobs, and inference endpoints on Modal, SkyPilot, and Lambda Labs.

## Platform selection

| Need | Platform | Why |
|---|---|---|
| Serverless GPU, scale-to-zero, Python-native APIs/batch | **Modal** | Sub-second cold starts, pay-per-second, no YAML or VMs |
| Multi-cloud cost optimization, spot auto-recovery, multi-node | **SkyPilot** | Picks cheapest cloud/region across 20+ providers, `sky jobs` failover |
| Dedicated SSH instances, persistent NFS, InfiniBand clusters | **Lambda Labs** | Pre-installed Lambda Stack, no egress fees, 1-Click Slurm clusters |

---

## Modal (Serverless GPU)

Python-native serverless compute with container image caching, persistent `Volume`s, `Secret`s, and web endpoints.

```bash
pip install modal
modal setup                  # Authenticate via browser
modal run script.py          # Execute once and exit
modal serve script.py        # Dev server with live reload
modal deploy script.py       # Persistent cloud deployment
modal app logs my-app        # Stream logs
```

### GPU functions, classes, volumes & secrets

```python
import os
import modal

app = modal.App("ml-job")
image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install("git")
    .pip_install("torch", "transformers", "accelerate")
)
volume = modal.Volume.from_name("model-cache", create_if_missing=True)

@app.cls(
    gpu=["H100", "A100-80GB"],       # Fallback list; also "A10G", "L40S", "H100:4" (multi-GPU)
    image=image,
    volumes={"/models": volume},
    secrets=[modal.Secret.from_name("huggingface")],
    timeout=3600,
    container_idle_timeout=300,
    allow_concurrent_inputs=10,
    retries=3,
)
class InferenceService:
    @modal.enter()
    def load_model(self):
        # Runs once per container warm-up
        from transformers import pipeline
        self.pipe = pipeline("text-generation", model="gpt2", device=0, token=os.environ["HF_TOKEN"])

    @modal.method()
    def generate(self, prompt: str) -> str:
        return self.pipe(prompt, max_length=100)[0]["generated_text"]

@app.local_entrypoint()
def main():
    print(InferenceService().generate.remote("Hello"))
```

### Web endpoints, batching & fan-out

- **REST endpoint:** Decorate with `@modal.fastapi_endpoint(method="POST")` for single functions, or `@modal.asgi_app()` for full FastAPI apps.
- **Dynamic batching:** `@modal.batched(max_batch_size=32, wait_ms=100)` on an `async def` taking `list[...]`.
- **Parallel map:** `list(process_item.map(items))` fans out across parallel containers.
- **Volumes persistence:** Always call `volume.commit()` after writing files to a `modal.Volume` so changes persist across containers.
- **Secrets:** `modal secret create huggingface HF_TOKEN=hf_xxx`.
- **Scheduling:** `@app.function(schedule=modal.Cron("0 0 * * *"))` or `modal.Period(hours=1)`.

---

## SkyPilot (Multi-Cloud Orchestration)

Unified YAML and CLI for launching, auto-stopping, and spot-recovering ML workloads across AWS, GCP, Azure, Kubernetes, Lambda, RunPod, and 20+ providers.

```bash
pip install "skypilot[aws,gcp,azure,kubernetes]"
sky check                    # Verify configured cloud credentials
```

### Core CLI commands

| Command | Purpose |
|---|---|
| `sky launch -c mycluster task.yaml` | Provision cluster and run task (`--dryrun` shows cheapest cloud choice) |
| `sky exec mycluster task.yaml` | Run task on existing cluster (skips `setup`) |
| `sky status -a` | List clusters and costs |
| `sky autostop mycluster -i 30 --down` | Auto-terminate after 30 min idle |
| `sky stop mycluster` / `sky down mycluster` | Stop (keep disk) / terminate cluster |
| `sky jobs launch -n my-job task.yaml` | Managed job with automatic spot preemption recovery |
| `sky jobs queue` / `sky jobs logs my-job` / `sky jobs cancel my-job` | Manage spot-recovered jobs |
| `sky serve up -n svc service.yaml` | Deploy autoscaling inference service (`sky serve status`) |

### Multi-node distributed training + spot recovery YAML

```yaml
name: llm-train

resources:
  accelerators: {H100: 8, A100-80GB: 8}
  any_of:
    - cloud: gcp
    - cloud: aws
    - cloud: azure
  use_spot: true
  spot_recovery: FAILOVER
  disk_size: 256
  autostop:
    idle_minutes: 30
    down: true

num_nodes: 4

workdir: .

file_mounts:
  /datasets:
    source: s3://my-bucket/datasets
    mode: MOUNT                # Stream read-heavy datasets
  /checkpoints:
    name: train-checkpoints
    store: s3
    mode: MOUNT_CACHED         # Fast local writes + async upload to S3

envs:
  HF_TOKEN: $HF_TOKEN

setup: |
  pip install torch transformers accelerate

run: |
  torchrun \
    --nnodes=$SKYPILOT_NUM_NODES \
    --nproc_per_node=$SKYPILOT_NUM_GPUS_PER_NODE \
    --node_rank=$SKYPILOT_NODE_RANK \
    --master_addr=$(echo "$SKYPILOT_NODE_IPS" | head -n1) \
    --master_port=12355 \
    train.py --checkpoint-dir /checkpoints --resume
```

**Storage modes:** `MOUNT` (stream cloud bucket), `COPY` (pre-fetch to local disk for random access), `MOUNT_CACHED` (local cache with async cloud sync for checkpoints/outputs).

---

## Lambda Labs (Dedicated GPU Cloud)

Dedicated on-demand GPU instances with pre-installed **Lambda Stack** (Ubuntu 22.04, CUDA 12.x, cuDNN, NCCL, PyTorch, TensorFlow, JAX), persistent NFS filesystems, and 1-Click InfiniBand Slurm clusters (16–512 GPUs).

### SSH & persistent storage

- Add an SSH key in the Lambda console before launching; wait 3–5 min (single GPU) or 10–15 min (multi-GPU).
- **Persistent filesystems** must be created in the **same region** and attached at **launch time**. Mounted at `/lambda/nfs/<FILESYSTEM_NAME>`.
- Local `/home/ubuntu/` SSD is fast but **ephemeral**—save checkpoints and datasets to `/lambda/nfs/...`.
- **Port forwarding** (only port 22 is open by default):
  ```bash
  ssh -L 8888:localhost:8888 -L 6006:localhost:6006 ubuntu@<INSTANCE_IP>
  ```

### Python API & REST CLI

```bash
pip install lambda-cloud-client
export LAMBDA_API_KEY="secret_..."
```

```python
import os
import lambda_cloud_client
from lambda_cloud_client.models import LaunchInstanceRequest, TerminateInstanceRequest

config = lambda_cloud_client.Configuration(
    host="https://cloud.lambdalabs.com/api/v1",
    access_token=os.environ["LAMBDA_API_KEY"],
)

with lambda_cloud_client.ApiClient(config) as client:
    api = lambda_cloud_client.DefaultApi(client)
    resp = api.launch_instance(LaunchInstanceRequest(
        region_name="us-west-1",
        instance_type_name="gpu_1x_h100_sxm5",
        ssh_key_names=["my-ssh-key"],
        file_system_names=["my-filesystem"],
        name="training-job",
    ))
    instance_id = resp.data.instance_ids[0]
    # Later: terminate (Lambda has NO auto-stop)
    api.terminate_instance(TerminateInstanceRequest(instance_ids=[instance_id]))
```

```bash
# List available instance types via curl
curl -u $LAMBDA_API_KEY: https://cloud.lambdalabs.com/api/v1/instance-types | jq

# Terminate via curl
curl -u $LAMBDA_API_KEY: -X POST https://cloud.lambdalabs.com/api/v1/instance-operations/terminate \
  -H "Content-Type: application/json" -d '{"instance_ids": ["<INSTANCE_ID>"]}'
```

### Multi-node 1-Click Clusters (Slurm + InfiniBand)

```bash
srun --nodes=4 --ntasks-per-node=8 --gpus-per-node=8 \
  torchrun --nnodes=4 --nproc_per_node=8 \
  --rdzv_backend=c10d --rdzv_endpoint=$MASTER_ADDR:29500 \
  train.py
```

**Cost control warning:** Lambda Labs instances do **not** auto-stop. Always terminate idle instances explicitly via console, API, or `curl`.
