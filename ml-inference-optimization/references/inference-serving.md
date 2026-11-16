# Inference Serving Engines

Consolidated reference for **vLLM**, **SGLang**, **TensorRT-LLM**, and **llama.cpp**.

---

## 1. Engine Selection Matrix

| Engine | Hardware | Core Mechanism | Best Workload | Quantization | Default OpenAI Port |
|---|---|---|---|---|---|
| **vLLM** | NVIDIA, AMD ROCm, Intel, TPU | PagedAttention + continuous batching | General high-throughput APIs, offline batching | AWQ, GPTQ, FP8, HQQ | `8000` (`vllm serve`) |
| **SGLang** | NVIDIA, AMD ROCm | RadixAttention (tree-based KV prefix cache) | Agents, shared system prompts, JSON/regex/grammar | FP8, AWQ, GPTQ | `30000` (`sglang.launch_server`) |
| **TensorRT-LLM** | NVIDIA only (A100/H100/GB200) | Compiled TRT engines + in-flight batching | Maximum NVIDIA throughput / lowest latency | FP8, INT4 (AWQ/GPTQ), FP4 | `8000` (`trtllm-serve`) |
| **llama.cpp** | CPU, Apple Silicon (Metal), CUDA, ROCm | Pure C/C++ GGUF + hybrid layer offload | Local/edge, Mac M-series, CPU-only, constrained GBNF | GGUF (`Q2_K`–`Q8_0`) | `8080` (`./llama-server`) |

---

## 2. vLLM (PagedAttention & Continuous Batching)

### Install & Quick Start

```bash
pip install vllm

# OpenAI-compatible server
vllm serve meta-llama/Llama-3-8B-Instruct --port 8000
```

```python
# Offline batch inference
from vllm import LLM, SamplingParams

llm = LLM(
    model="meta-llama/Llama-3-8B-Instruct",
    tensor_parallel_size=2,
    gpu_memory_utilization=0.9,
    max_model_len=4096,
)
sampling = SamplingParams(temperature=0.7, top_p=0.95, max_tokens=512)
outputs = llm.generate(["Explain quantum computing"], sampling)
print(outputs[0].outputs[0].text)
```

### Production Server Flags & Quantization

```bash
# Production server with prefix caching, chunked prefill, and Prometheus metrics
vllm serve meta-llama/Llama-3-8B-Instruct \
  --host 0.0.0.0 \
  --port 8000 \
  --gpu-memory-utilization 0.9 \
  --max-model-len 8192 \
  --max-num-seqs 512 \
  --enable-prefix-caching \
  --enable-chunked-prefill \
  --enable-metrics \
  --metrics-port 9090

# Quantized 70B serving (AWQ / GPTQ / FP8)
vllm serve TheBloke/Llama-2-70B-AWQ \
  --quantization awq \
  --tensor-parallel-size 1 \
  --gpu-memory-utilization 0.95

# Docker deployment
docker run --gpus all -p 8000:8000 vllm/vllm-openai:latest \
  --model meta-llama/Llama-3-8B-Instruct \
  --gpu-memory-utilization 0.9 \
  --enable-prefix-caching
```

### Monitoring & Troubleshooting

- **Prometheus metrics** (`curl http://localhost:9090/metrics | grep vllm`):
  - `vllm:time_to_first_token_seconds` (TTFT)
  - `vllm:num_requests_running`
  - `vllm:gpu_cache_usage_perc`
- **OOM on load**: Lower `--gpu-memory-utilization 0.7`, lower `--max-model-len 4096`, or switch to `--quantization awq|gptq|fp8`.
- **High TTFT (>1s)**: Enable `--enable-prefix-caching` (repeated prefixes) and `--enable-chunked-prefill` (long prompts).
- **Tensor parallelism**: `--tensor-parallel-size` must be a power of 2 (e.g., 1, 2, 4, 8).
- **Speculative decoding**: `--speculative-model DRAFT_MODEL`.

---

## 3. SGLang (RadixAttention & Structured Generation)

Automatic prefix caching via a radix tree of KV blocks, plus FSM-accelerated structured decoding.

### Install & Launch Server

```bash
pip install "sglang[all]"
# Optional FlashInfer kernels for CUDA 12.1:
pip install "sglang[all]" flashinfer -i https://flashinfer.ai/whl/cu121/torch2.4/

# Launch OpenAI-compatible server (RadixAttention enabled by default)
python -m sglang.launch_server \
  --model-path meta-llama/Meta-Llama-3-8B-Instruct \
  --port 30000 \
  --enable-radix-cache

# Multi-GPU + speculative decoding
python -m sglang.launch_server \
  --model-path meta-llama/Meta-Llama-3-70B-Instruct \
  --tp 4 \
  --speculative-model meta-llama/Meta-Llama-3-8B-Instruct \
  --speculative-num-steps 5 \
  --port 30000
```

### Structured Generation & Agent Workflows

```python
import sglang as sgl

sgl.set_default_backend(sgl.OpenAI("http://localhost:30000/v1"))

@sgl.function
def structured_extract(s, article, schema):
    s += f"Article: {article}\nExtract JSON:\n"
    s += sgl.gen("info", max_tokens=300, json_schema=schema)

# Also supports regex=... and EBNF grammar=... and tools=...
schema = {
    "type": "object",
    "properties": {"title": {"type": "string"}, "sentiment": {"type": "string", "enum": ["positive", "negative", "neutral"]}},
    "required": ["title", "sentiment"],
}
state = structured_extract.run(article="...", schema=schema)
print(state["info"])

# Continuous batching in Python
states = sgl.run_batch([
    structured_extract.bind(article="Doc 1", schema=schema),
    structured_extract.bind(article="Doc 2", schema=schema),
])
```

- **OpenAI SDK**: Point `OpenAI(base_url="http://localhost:30000/v1", api_key="EMPTY")` with `model="default"`.
- **Workload sweet spot**: Multi-turn chat, tool-calling agents with long system prompts, and few-shot prompts (5–10x speedup over uncached prefill).

---

## 4. TensorRT-LLM (NVIDIA Production Serving)

Maximum throughput and lowest latency on NVIDIA GPUs via TensorRT engine compilation, in-flight batching, paged KV cache, and CUDA graphs.

### Install & Launch

```bash
# Recommended: official NVIDIA container
docker pull nvidia/tensorrt_llm:latest

# Or pip (check CUDA/TensorRT compatibility matrix; e.g., CUDA 13.0 / TRT 10.13)
pip install tensorrt_llm
```

```bash
# Serve with in-flight batching and chunked context (OpenAI-compatible on port 8000)
trtllm-serve meta-llama/Meta-Llama-3-8B \
  --tp_size 4 \
  --max_batch_size 256 \
  --max_num_tokens 4096 \
  --enable_chunked_context \
  --max_chunked_prefill_length 2048 \
  --scheduler_policy max_utilization
```

### Python `LLM` API (Quantization, KV Cache, Speculative Decoding)

```python
from tensorrt_llm import LLM, SamplingParams

llm = LLM(
    model="meta-llama/Meta-Llama-3-70B",
    tensor_parallel_size=4,
    dtype="fp8",                          # "fp8" (H100), "int4_awq", "int4_gptq"
    quantization="fp8",                   # "fp8", "awq", "gptq"
    kv_cache_free_gpu_mem_fraction=0.9,
    enable_prefix_caching=True,
    enable_cuda_graph=True,
    # Optional speculative decoding:
    # speculative_model="meta-llama/Meta-Llama-3-8B",
    # num_speculative_tokens=5,
)
outputs = llm.generate(["Explain quantum computing"], SamplingParams(max_tokens=200, temperature=0.7))
print(outputs[0].text)
```

---

## 5. llama.cpp (CPU, Apple Silicon & Hybrid Edge Serving)

Zero-Python C/C++ runtime for GGUF models.

### Build & Install

```bash
# macOS / Linux package
brew install llama.cpp

# Or build from source
git clone https://github.com/ggml-org/llama.cpp && cd llama.cpp
make                  # CPU (AVX2/AVX512)
make GGML_METAL=1     # Apple Silicon (Metal)
make GGML_CUDA=1      # NVIDIA CUDA (older releases used LLAMA_CUDA=1)
make GGML_HIP=1       # AMD ROCm (older releases used LLAMA_HIP=1)
```

### CLI, Grammar & OpenAI-Compatible Server

```bash
# CLI inference with GPU layer offload (-ngl) and context (-c)
./llama-cli -m models/llama-3.1-8b-q4_k_m.gguf -ngl 35 -c 4096 -n 256 -p "Explain quantum computing"

# Constrained JSON output via GBNF grammar
./llama-cli -m models/model.gguf -p "Generate a person: " --grammar-file grammars/json.gbnf

# OpenAI-compatible server on port 8080
./llama-server -m models/llama-3.1-8b-q4_k_m.gguf --host 0.0.0.0 --port 8080 -ngl 35 -c 4096

# Or via llama-cpp-python
pip install llama-cpp-python
python -m llama_cpp.server --model models/model-q4_k_m.gguf --n_gpu_layers 35 --host 0.0.0.0 --port 8080
```

### Python Bindings & Hardware Tuning

```python
from llama_cpp import Llama

llm = Llama(
    model_path="./model-q4_k_m.gguf",
    n_ctx=4096,
    n_gpu_layers=35,   # 999 for full offload (e.g., Apple Silicon Metal); 0 for CPU-only
    n_threads=8,       # Match physical CPU cores (use 1 with Metal)
    n_batch=512,       # Prompt processing batch size
)
resp = llm.create_chat_completion(
    messages=[{"role": "user", "content": "Hello!"}],
    max_tokens=256,
)
```

- **Slow model loading**: Pass `--mmap` to `./llama-cli`.
- **OOM**: Reduce `-ngl` (offload fewer layers to GPU) or step down quantization (e.g., `Q4_K_M` -> `Q3_K_M`).
