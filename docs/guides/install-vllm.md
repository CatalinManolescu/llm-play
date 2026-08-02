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

