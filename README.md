# LLM Setup Examples

This repository contains various local LLM deployment setups and configurations.

**Note**: Instructions are written for Ubuntu/Debian Linux systems with systemd.

## Available Setups

### Ollama + Open WebUI

Complete setup with remote access via tunnels (ngrok/Cloudflare).

- **Location**: `webui/`
- **Components**: Ollama, Open WebUI, tunnel services
- **Access**: Local and remote via HTTPS tunnels
- **Documentation**: [webui/README.md](webui/README.md)

### llama.cpp Setup

## Ollama Setup

### Installation

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### Basic Usage

```bash
# Start Ollama service
systemctl start ollama

# Pull and run a model
ollama pull llama3
ollama run llama3

# List available models
ollama list

# API endpoint check
curl http://localhost:11434/api/tags
```

### Configuration

#### Network Access

By default, Ollama only listens on localhost. For remote access or WebUI integration, configure it to accept external connections:

```bash
# Use the provided script
./utils/bash/configure-ollama-network.sh

# Or configure manually:
# Create /etc/systemd/system/ollama.service.d/override.conf with:
# [Service]
# Environment="OLLAMA_HOST=0.0.0.0:11434"
# Environment="OLLAMA_ORIGINS=*"
# Then: systemctl daemon-reload && systemctl restart ollama
```

#### Model Management

```bash
ollama pull llama4:maverick
ollama pull llama4:scout
ollama pull llama3:latest
ollama pull qwen3:latest
ollama pull deepseek-r1:latest
ollama pull deepseek-coder:latest

# Models are stored in: /usr/share/ollama/.ollama/models
```

## llama.cpp Setup

### Installation

```shell
sudo apt update
sudo apt install build-essential cmake ninja-build git wget ccache libcurl4-openssl-dev ninja-build libopenblas-dev libvulkan-dev vulkan-tools spirv-tools

# add vulkan-sdk
wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo tee /etc/apt/trusted.gpg.d/lunarg.asc
sudo wget -qO /etc/apt/sources.list.d/lunarg-vulkan-noble.list http://packages.lunarg.com/vulkan/lunarg-vulkan-noble.list
sudo apt update
sudo apt install vulkan-sdk

# Clone llama.cpp repository
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

# define path to install binaries
export LLAMA_CPP_HOME=$(realpath $PWD/../llama_cpp_rl)
mkdir -p "$LLAMA_CPP_HOME"

# Configure
# use -DLLAMA_CUDA=ON for NVIDIA GPUs and -DGGML_CLBLAST=ON for AMD
# -DLLAMA_VULKAN=ON for Vulkan support
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$LLAMA_CPP_HOME" -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=ON -DLLAMA_BUILD_SERVER=ON -DGGML_CLBLAST=ON -DGGML_VULKAN=ON

cmake --build build --config Release -j $(nproc)
cmake --install build --config Release

export PATH=${LLAMA_CPP_HOME}/bin:$PATH
export LD_LIBRARY_PATH="$LLAMA_CPP_HOME/lib:$LD_LIBRARY_PATH"
# persist
# echo "$LLAMA_CPP_HOME/lib" | sudo tee /etc/ld.so.conf.d/llama_cpp.conf
# sudo ldconfig

llama-cli --list-devices
```

### Basic Usage

```shell
mkdir -p $LLM_MODELS_LOCATION/gpt-oss
cd $LLM_MODELS_LOCATION/gpt-oss
```

#### Run Model

```shell
# https://huggingface.co/unsloth/gpt-oss-20b-GGUF/tree/main
hf download unsloth/gpt-oss-20b-GGUF --include "gpt-oss-20b-Q5_K_M.gguf" --local-dir "$LLM_MODELS_LOCATION/gpt-oss"

# --no-display-prompt                     don't print prompt at generation (default: false)
# -co,   --color                          colorise output to distinguish prompt and user input from generations
# --template "{{ .Prompt }}"
llama-cli -m gpt-oss-20b-Q5_K_M.gguf --gpu-layers 12 -p "Test"

# --no-webui
llama-server --host 127.0.0.1 --port 9000 --temp 0.5 -ngl 99 -c 8192 --jinja -a gpt-oss -m gpt-oss-20b-f16.gguf

```

#### Benchmarck

```shell
> llama-bench --flash-attn 1 --model ./gpt-oss-20b-Q5_K_M.gguf -pg 1024,256
ggml_vulkan: Found 1 Vulkan devices:
ggml_vulkan: 0 = AMD Radeon Graphics (RADV GFX1150) (radv) | uma: 1 | fp16: 1 | bf16: 0 | warp size: 64 | shared memory: 65536 | int dot: 1 | matrix cores: KHR_coopmat
| model                          |       size |     params | backend    | ngl | fa |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | -: | --------------: | -------------------: |
| gpt-oss ?B Q5_K - Medium       |  10.90 GiB |    20.91 B | Vulkan     |  99 |  1 |           pp512 |        249.19 ± 1.42 |
| gpt-oss ?B Q5_K - Medium       |  10.90 GiB |    20.91 B | Vulkan     |  99 |  1 |           tg128 |         29.95 ± 0.06 |
| gpt-oss ?B Q5_K - Medium       |  10.90 GiB |    20.91 B | Vulkan     |  99 |  1 |    pp1024+tg256 |         98.56 ± 0.14 |

> llama-bench --flash-attn 1 --model ./gpt-oss-20b-F16.gguf -pg 1024,256
ggml_vulkan: Found 1 Vulkan devices:
ggml_vulkan: 0 = AMD Radeon Graphics (RADV GFX1150) (radv) | uma: 1 | fp16: 1 | bf16: 0 | warp size: 64 | shared memory: 65536 | int dot: 1 | matrix cores: KHR_coopmat
| model                          |       size |     params | backend    | ngl | fa |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | -: | --------------: | -------------------: |
| gpt-oss ?B F16                 |  12.83 GiB |    20.91 B | Vulkan     |  99 |  1 |           pp512 |        240.03 ± 2.56 |
| gpt-oss ?B F16                 |  12.83 GiB |    20.91 B | Vulkan     |  99 |  1 |           tg128 |         21.08 ± 0.05 |
| gpt-oss ?B F16                 |  12.83 GiB |    20.91 B | Vulkan     |  99 |  1 |    pp1024+tg256 |         76.14 ± 0.15 |
```

### Build gpt-oss-20b GGUF

```shell
python3 -m venv ~/.venv/llama
source ~/.venv/llama/bin/activate

git clone https://github.com/ggml-org/llama.cpp.git
pip install -r llama.cpp/requirements.txt

cd llama.cpp
# edit convert_hf_to_gguf_update.py and add the model if it is not there

huggingface-cli login
python3 convert_hf_to_gguf_update.py
# go back
cd -

# Download model repo
hf download openai/gpt-oss-20b --local-dir ./gpt-oss-20b
cd ./gpt-oss-20b

# Convert
mkdir -p out
python3 llama.cpp/convert_hf_to_gguf.py ./gpt-oss-20b --outfile out/gpt-oss-20b-f16.gguf --outtype f16


# Quantize
llama-quantize .out/gpt-oss-20b-f16.gguf .out/gpt-oss-20b-Q4_K_M.gguf Q4_K_M
```

#### Debug configuration

```shell
less chat_template.jinja

```

## System Requirements

### Memory Management

LLMs require significant RAM. If you need more swap space:

```bash
# Check current swap
swapon --show

# Resize swap to 64GB (example)
sudo swapoff /swap.img
sudo dd if=/dev/zero of=/swap.img bs=1G count=64 status=progress
sudo chmod 600 /swap.img
sudo mkswap /swap.img
sudo swapon /swap.img

# Or use the provided script
./utils/bash/swap-resize
```

## Resources

- [Ollama Documentation](https://github.com/ollama/ollama)
- [Ollama Configuration FAQ](https://github.com/ollama/ollama/blob/main/docs/faq.md)
- [llama.cpp guide](https://blog.steelph0enix.dev/posts/llama-cpp-guide/)
- [Vulkan - Getting started - Ubuntu](https://vulkan.lunarg.com/doc/view/latest/linux/getting_started_ubuntu.html)
- [How to convert HuggingFace model to GGUF format](https://github.com/ggml-org/llama.cpp/discussions/7927)

