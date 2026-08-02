# Install vLLM

Create an isolated Python environment and install vLLM with the ROCm wheel index:

```shell
uv venv .venv/vllm --python 3.12 --seed --managed-python
source .venv/vllm/bin/activate
uv pip install vllm --extra-index-url https://wheels.vllm.ai/rocm/
```

For a ROCm installation that also needs the explicit PyTorch and Triton packages:

```shell
uv pip install vllm triton triton_kernels torch torchvision --upgrade \
  --extra-index-url https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/ \
  --extra-index-url https://wheels.vllm.ai/rocm/
```

## Serve a Model with Make

After installation, the repository Makefile provides a wrapper around `vllm serve`:

```shell
make vllm-serve MODEL=Qwen/Qwen2.5-Coder-7B
```

The default server listens on port `9100` and downloads models under `models/hf`. Override these values when needed:

```shell
make vllm-serve \
  MODEL=Qwen/Qwen2.5-Coder-7B \
  VLLM_HOST=127.0.0.1 \
  VLLM_PORT=9100 \
  VLLM_ARGS="--max-model-len 8192"
```

For AMD ROCm systems with Docker available, use the Docker-backed server target:

```shell
make vllm-docker-serve-rocm MODEL=Qwen/Qwen3.6-35B-A3B
```

Review the target's GPU, cache, and model-length defaults before using it on a different AMD GPU.

