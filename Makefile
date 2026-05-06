MAKEFILE_TARGETS := $(shell awk 'BEGIN {FS = ":.*## "}; /^[A-Za-z0-9_.-]+:.*## / {print $$1}' $(firstword $(MAKEFILE_LIST)) | sort -u)

.PHONY: $(MAKEFILE_TARGETS)

LLAMA_DIR ?= llama.cpp
LLAMA_REPO ?= https://github.com/ggml-org/llama.cpp.git
LLAMA_BUILD_TYPE ?= Release
LLAMA_INSTALL_PREFIX ?= $(abspath ./llama_cpp_rl)
LLAMA_BUILD_DIR_BASE ?= build
LLAMA_HOST ?= 0.0.0.0
LLAMA_PORT ?= 9000
VLLM_HOST ?= 0.0.0.0
VLLM_PORT ?= 9010
VLLM_DOWNLOAD_DIR ?= models/hf
VLLM_ARGS ?=

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*## "}; /^[A-Za-z0-9_.-]+:.*## / {printf "  %-32s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

llama-clone: ## Clone llama.cpp into $(LLAMA_DIR)
	@if [ -d "$(LLAMA_DIR)/.git" ]; then \
		echo "llama.cpp already present at $(LLAMA_DIR)"; \
	else \
		git clone "$(LLAMA_REPO)" "$(LLAMA_DIR)"; \
	fi

llama-update: ## Update llama.cpp in $(LLAMA_DIR)
	@if [ -d "$(LLAMA_DIR)/.git" ]; then \
		git -C "$(LLAMA_DIR)" pull --ff-only; \
	else \
		echo "No git repo found at $(LLAMA_DIR). Run 'make llama-clone' first."; \
		exit 1; \
	fi

llama-build-nvidia: ## Build llama.cpp with NVIDIA CUDA
	@cmake -S "$(LLAMA_DIR)" -B "$(LLAMA_BUILD_DIR_BASE)-cuda" -G Ninja \
		-DCMAKE_BUILD_TYPE="$(LLAMA_BUILD_TYPE)" \
		-DCMAKE_INSTALL_PREFIX="$(LLAMA_INSTALL_PREFIX)" \
		-DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=ON -DLLAMA_BUILD_SERVER=ON \
		-DLLAMA_CUDA=ON
	@cmake --build "$(LLAMA_BUILD_DIR_BASE)-cuda" --config "$(LLAMA_BUILD_TYPE)" -j $$(nproc)
	@cmake --install "$(LLAMA_BUILD_DIR_BASE)-cuda" --config "$(LLAMA_BUILD_TYPE)"

llama-build-amd-vulkan: ## Build llama.cpp with AMD Vulkan
	@cmake -S "$(LLAMA_DIR)" -B "$(LLAMA_BUILD_DIR_BASE)-vulkan" -G Ninja \
		-DCMAKE_BUILD_TYPE="$(LLAMA_BUILD_TYPE)" \
		-DCMAKE_INSTALL_PREFIX="$(LLAMA_INSTALL_PREFIX)" \
		-DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=ON -DLLAMA_BUILD_SERVER=ON \
		-DGGML_CLBLAST=ON -DGGML_VULKAN=ON
	@cmake --build "$(LLAMA_BUILD_DIR_BASE)-vulkan" --config "$(LLAMA_BUILD_TYPE)" -j $$(nproc)
	@cmake --install "$(LLAMA_BUILD_DIR_BASE)-vulkan" --config "$(LLAMA_BUILD_TYPE)"

llama-build-amd-rocm: ## Build llama.cpp with AMD ROCm (HIP)
	@cmake -S "$(LLAMA_DIR)" -B "$(LLAMA_BUILD_DIR_BASE)-rocm" -G Ninja \
		-DCMAKE_BUILD_TYPE="$(LLAMA_BUILD_TYPE)" \
		-DCMAKE_INSTALL_PREFIX="$(LLAMA_INSTALL_PREFIX)" \
		-DCMAKE_HIP_COMPILER="$$(hipconfig -l)/clang" \
		-DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=ON -DLLAMA_BUILD_SERVER=ON \
		-DGGML_HIP=ON
	@cmake --build "$(LLAMA_BUILD_DIR_BASE)-rocm" --config "$(LLAMA_BUILD_TYPE)" -j $$(nproc)
	@cmake --install "$(LLAMA_BUILD_DIR_BASE)-rocm" --config "$(LLAMA_BUILD_TYPE)"

unsloth-studio-install: ## Install Unsloth Studio
	@curl -fsSL https://unsloth.ai/install.sh | sh

unsloth-studio-update: ## Update Unsloth Studio
	@unsloth studio update

debug-check-gpu: ## Inspect detected GPU hardware and drivers
	@printf '\n== PCI display devices ==\n'
	@lspci | grep -i -E "vga|3d|display" || echo "No display devices found via lspci"
	@printf '\n== Display hardware details ==\n'
	@if command -v lshw >/dev/null 2>&1; then \
		if [ "$$(id -u)" -eq 0 ]; then \
			lshw -C display; \
		elif command -v sudo >/dev/null 2>&1; then \
			sudo lshw -C display; \
		else \
			echo "lshw found, but root privileges are required. Run: sudo lshw -C display"; \
		fi; \
	else \
		echo "lshw not installed"; \
	fi
	@printf '\n== NVIDIA GPUs ==\n'
	@if command -v nvidia-smi >/dev/null 2>&1; then \
		nvidia-smi; \
	else \
		echo "nvidia-smi not installed or no NVIDIA driver detected"; \
	fi
	@printf '\n== AMD ROCm GPUs ==\n'
	@if command -v rocminfo >/dev/null 2>&1; then \
	  rocminfo | grep -i "Marketing Name:" \
# 		rocminfo; \
	else \
		echo "rocminfo not installed"; \
	fi
	@printf '\n== AMD PCI devices ==\n'
	@lspci | grep -i amd || echo "No AMD PCI devices found"
	@printf '\n== OpenGL renderer ==\n'
	@if command -v glxinfo >/dev/null 2>&1; then \
		glxinfo | grep "OpenGL renderer" || echo "OpenGL renderer not reported"; \
	else \
		echo "glxinfo not installed"; \
	fi
	@printf '\n== Vulkan devices ==\n'
	@if command -v vulkaninfo >/dev/null 2>&1; then \
		vulkaninfo | grep "deviceName" || echo "Vulkan device names not reported"; \
	else \
		echo "vulkaninfo not installed"; \
	fi

watch-cpu-mem: ## Watch CPU and memory usage
	@if command -v htop >/dev/null 2>&1; then \
		htop; \
	else \
		echo "htop not installed"; \
		exit 1; \
	fi

watch-gpu: ## Watch GPU and VRAM usage
	@if command -v nvtop >/dev/null 2>&1; then \
		nvtop; \
	else \
		echo "nvtop not installed"; \
		exit 1; \
	fi

llama-serve: export LLAMA_ARG_HOST ?= $(LLAMA_HOST)
llama-serve: export LLAMA_ARG_PORT ?= $(LLAMA_PORT)
llama-serve: export LLAMA_ARG_CTX_SIZE ?= 0
llama-serve: export LLAMA_ARG_N_PREDICT ?= -1
llama-serve: export LLAMA_ARG_BATCH ?= 2048
llama-serve: export LLAMA_ARG_UBATCH ?= 2048
llama-serve: export LLAMA_ARG_N_GPU_LAYERS ?= 999
llama-serve: export LLAMA_ARG_JINJA ?= true
llama-serve: export LLAMA_ARG_CACHE_PROMPT ?= true
llama-serve: ## Run llama-server with a model path (MODEL=...)
	@env | grep LLAMA_ARG | sort
	@if [ -z "$(MODEL)" ]; then \
		echo "MODEL is required. Example:"; \
		echo "  make llama-serve MODEL=models/gpt-oss/gpt-oss-20b-mxfp4.gguf LLAMA_ARG_ALIAS=gpt-oss"; \
		exit 1; \
	fi
	@llama-server --temp 0.5 \
		-m "$(MODEL)"

llama-serve-gpt-oss-20b: ## Run llama.cpp for openai/gpt-oss-20b
	@$(MAKE) llama-serve \
	  MODEL=models/gpt-oss/gpt-oss-20b-mxfp4.gguf \
	  LLAMA_ARG_ALIAS=gpt-oss

vllm-serve: ## Run vLLM with a Hugging Face model (MODEL=...)
	@if [ -z "$(MODEL)" ]; then \
		echo "MODEL is required. Example:"; \
		echo "  make vllm-serve MODEL=Qwen/Qwen2.5-14B"; \
		exit 1; \
	fi
	@mkdir -p "$(VLLM_DOWNLOAD_DIR)"
	vllm serve "$(MODEL)" --host "$(VLLM_HOST)" --port "$(VLLM_PORT)" \
		--download-dir "$(VLLM_DOWNLOAD_DIR)" --enable-auto-tool-choice \
		--gpu-memory-utilization 0.95 --enforce-eager \
		$(VLLM_ARGS)

vllm-serve-openai-gpt-oss-20b: ## Run vLLM for openai/gpt-oss-20b
	@export HSA_NO_SCRATCH_RECLAIM=1
	@export AMDGCN_USE_BUFFER_OPS=0
	@export VLLM_ROCM_USE_AITER=1
	@export VLLM_ROCM_QUICK_REDUCE_QUANTIZATION=INT4
	@export HSA_NO_SCRATCH_RECLAIM=1
	@export PYTORCH_TUNABLEOP_ENABLED=0
	@$(MAKE) vllm-serve \
		MODEL="openai/gpt-oss-20b" \
		VLLM_ARGS="--max-num-batched-tokens 2048 --max-num-seqs 20 --tool-call-parser openai \
		--no-enable-prefix-caching --tensor_parallel_size 1 \
		--attention-backend ROCM_AITER_UNIFIED_ATTN -cc.pass_config.fuse_rope_kvcache=True -cc.use_inductor_graph_partition=True"

vllm-serve-qwen2.5-coder-7b: ## Run vLLM for Qwen/Qwen2.5-Coder-7B
	@$(MAKE) vllm-serve \
		MODEL="Qwen/Qwen2.5-Coder-7B" \
		VLLM_ARGS=" --max-num-batched-tokens 2048 --max-num-seqs 2 --tool-call-parser hermes"

vllm-serve-qwen2.5-coder-14b: ## Run vLLM for Qwen/Qwen2.5-Coder-14B
	@$(MAKE) vllm-serve \
		MODEL="Qwen/Qwen2.5-Coder-14B" \
		VLLM_ARGS="--max-model-len 16k --max-num-batched-tokens 2048 --max-num-seqs 2 --tool-call-parser hermes"

vllm-serve-qwen3.5-9b: ## Run vLLM for Qwen/Qwen3.5-9B
	@$(MAKE) vllm-serve \
		MODEL="Qwen/Qwen3.5-9B" \
		VLLM_ARGS="--max-num-batched-tokens 2048 --max-num-seqs 2 --tool-call-parser qwen3_coder"

test: ## Echo the current model name
	@echo "... $(MODEL)"
