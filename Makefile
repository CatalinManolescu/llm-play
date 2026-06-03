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
VLLM_PORT ?= 9100
VLLM_DOWNLOAD_DIR ?= models/hf
VLLM_ARGS ?=

LLAMA_SERVE_VARS := \
	LLAMA_ARG_ALIAS \
	LLAMA_ARG_HOST \
	LLAMA_ARG_PORT \
	LLAMA_ARG_TEMP \
	LLAMA_ARG_CTX_SIZE \
	LLAMA_ARG_PRESENCE_PENALTY \
	LLAMA_ARG_REPEAT_PENALTY \
	LLAMA_ARG_FLASH_ATTN \
	LLAMA_ARG_N_PREDICT \
	LLAMA_ARG_MIN_P \
	LLAMA_ARG_TOP_P \
	LLAMA_ARG_TOP_K \
	LLAMA_ARG_BATCH \
	LLAMA_ARG_UBATCH \
	LLAMA_ARG_N_GPU_LAYERS \
	LLAMA_ARG_JINJA \
	LLAMA_ARG_CACHE_PROMPT \
	LLAMA_ARG_CACHE_RAM \
	LLAMA_ARG_REASONING \
	LLAMA_ARG_UI \
	LLAMA_ARG_MMAP \
	LLAMA_ARG_CACHE_TYPE_K \
	LLAMA_ARG_CACHE_TYPE_V \
	LLAMA_CHAT_TEMPLATE_KWARGS

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*## "}; /^[A-Za-z0-9_.-]+:.*## / {printf "  %-32s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

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

unsloth-studio-install: ## Install Unsloth Studio
	@curl -fsSL https://unsloth.ai/install.sh | sh

unsloth-studio-update: ## Update Unsloth Studio
	@unsloth studio update

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


llama-serve-vars: ## Print llama-serve variable names
	@printf '%s\n' $(LLAMA_SERVE_VARS)

llama-serve: export LLAMA_ARG_HOST ?= $(LLAMA_HOST)
llama-serve: export LLAMA_ARG_PORT ?= $(LLAMA_PORT)
# temperature; default 0.8; 0.0 = greedy, 1.0 = typical, >1.0 more random
llama-serve: export LLAMA_ARG_TEMP ?= 0.8
# prompt context size; 0 = loaded from model, -1 = no limit
llama-serve: export LLAMA_ARG_CTX_SIZE ?= 0
# 0.0 disables the presence penalty; default 0.0
llama-serve: export LLAMA_ARG_PRESENCE_PENALTY ?= 0.0
# 1.0 disables the repeat penalty; default 1.0
llama-serve: export LLAMA_ARG_REPEAT_PENALTY ?= 1.0
 # -1 = infinity; default -1 (no limit)
llama-serve: export LLAMA_ARG_N_PREDICT ?= -1
# 0.0 disables min-p; default 0.05
llama-serve: export LLAMA_ARG_MIN_P ?= 0.0
# 1.0 disables top-p; default 0.95
llama-serve: export LLAMA_ARG_TOP_P ?= 1.0
# 0 disables top-k; default 40
llama-serve: export LLAMA_ARG_TOP_K ?= 0
# logical maximum batch size; default 2048
llama-serve: export LLAMA_ARG_BATCH ?= 2048
# physical maximum batch size; default 512
llama-serve: export LLAMA_ARG_UBATCH ?= 512
# max GPU layers; auto|all|number, default auto; set to 999 to use GPU for all layers
llama-serve: export LLAMA_ARG_N_GPU_LAYERS ?= 999
# jinja template engine; enabled by default
llama-serve: export LLAMA_ARG_JINJA ?= true
# prompt cache; enabled by default
llama-serve: export LLAMA_ARG_CACHE_PROMPT ?= true
# cache RAM in MiB; -1 = no limit, 0 = disable
llama-serve: export LLAMA_ARG_CACHE_RAM ?= 8192
# on|off|auto
llama-serve: export LLAMA_ARG_REASONING ?= auto
llama-serve: export LLAMA_ARG_THINK_BUDGET ?= -1
llama-serve: LLAMA_CHAT_TEMPLATE_KWARGS ?=
# web UI; enabled by default
llama-serve: export LLAMA_ARG_UI ?= false
# whether to memory-map model; enabled by default
llama-serve: export LLAMA_ARG_MMAP ?= on
# on|off|auto; default auto
llama-serve: export LLAMA_ARG_FLASH_ATTN ?= off
# KV cache K type; f32|f16|bf16|q8_0|q4_0|q4_1|iq4_nl|q5_0|q5_1; default: f16
llama-serve: export LLAMA_ARG_CACHE_TYPE_K ?= f16
# KV cache V type; f32|f16|bf16|q8_0|q4_0|q4_1|iq4_nl|q5_0|q5_1; default: f16
llama-serve: export LLAMA_ARG_CACHE_TYPE_V ?= f16
llama-serve: export LLAMA_ARG_FIT_TARGET ?= 1536
llama-serve: ## Run llama-server with a model path (MODEL=...)
	@env | grep -E '^(LLAMA_ARG|LLAMA_CHAT_TEMPLATE_KWARGS)' | sort
	@if [ -z "$(MODEL)" ]; then \
		echo "MODEL is required. Example:"; \
		echo "  make llama-serve MODEL=models/gpt-oss/gpt-oss-20b-mxfp4.gguf LLAMA_ARG_ALIAS=gpt-oss"; \
		exit 1; \
	fi
	@llama-server --temp $(LLAMA_ARG_TEMP) \
		--min-p $(LLAMA_ARG_MIN_P) --top-p $(LLAMA_ARG_TOP_P) \
		--presence-penalty $(LLAMA_ARG_PRESENCE_PENALTY) --repeat-penalty $(LLAMA_ARG_REPEAT_PENALTY) \
		-m "$(MODEL)" $(if $(LLAMA_CHAT_TEMPLATE_KWARGS),--chat-template-kwargs '$(LLAMA_CHAT_TEMPLATE_KWARGS)') $(KWARGS)

llama-serve-autocomplete: export LLAMA_ARG_PORT ?= 9001
llama-serve-autocomplete: ## Run llama.cpp for code completion
	@$(MAKE) llama-serve \
	  MODEL=models/jetbrains/mellum-4b-dpo-all-q8_0.gguf \
	  LLAMA_ARG_ALIAS=mellum \
		LLAMA_ARG_TEMP=0,6 \
		LLAMA_ARG_FLASH_ATTN=on

llama-serve-gpt-oss-20b: ## Run llama.cpp for openai/gpt-oss-20b
	@$(MAKE) llama-serve \
	  MODEL=models/gpt-oss/gpt-oss-20b-mxfp4.gguf \
	  LLAMA_ARG_ALIAS=gpt-oss \
		LLAMA_ARG_TEMP=1

llama-serve-qwen3.6: export MODEL ?= models/unsloth/Qwen3.6-35B-A3B-UD-IQ4_NL_XL.gguf
llama-serve-qwen3.6: export LLAMA_ARG_ALIAS ?= qwen3.6
llama-serve-qwen3.6: export LLAMA_ARG_PORT ?= 9010
llama-serve-qwen3.6: export LLAMA_ARG_UI ?= true
llama-serve-qwen3.6: export LLAMA_ARG_TEMP ?= 1
llama-serve-qwen3.6: export LLAMA_ARG_TOP_P ?= 0.95
llama-serve-qwen3.6: export LLAMA_ARG_PRESENCE_PENALTY ?= 1.5
llama-serve-qwen3.6: export LLAMA_ARG_FLASH_ATTN ?= on
llama-serve-qwen3.6: export LLAMA_ARG_N_PREDICT ?= 32768
llama-serve-qwen3.6: export LLAMA_ARG_NO_MMAP ?= on
llama-serve-qwen3.6: export LLAMA_ARG_MLOCK ?= on
# llama-serve-qwen3.6: export LLAMA_ARG_SPEC_TYPE ?= draft-mtp
# llama-serve-qwen3.6: export LLAMA_ARG_SPEC_DRAFT_N_MAX ?= 2
llama-serve-qwen3.6: ## Run llama.cpp Qwen3.6 for general usage with default model Qwen3.6-35B-A3B-UD-IQ4_NL_XL
	@$(MAKE) llama-serve \
		LLAMA_ARG_TOP_K=20 \
		LLAMA_ARG_MIN_P=0 \
		LLAMA_ARG_REPEAT_PENALTY=1.0 \
		KWARGS="--fit off"

llama-serve-qwen3.6-coder: export LLAMA_ARG_ALIAS ?= qwen3.6-coder
llama-serve-qwen3.6-coder: export LLAMA_ARG_PORT ?= 9020
llama-serve-qwen3.6-coder: export LLAMA_ARG_UI ?= true
llama-serve-qwen3.6-coder: export LLAMA_ARG_TEMP ?= 0.6
llama-serve-qwen3.6-coder: export LLAMA_ARG_FLASH_ATTN ?= on
# llama-serve-qwen3.6-coding: export LLAMA_ARG_CACHE_TYPE_K ?= q8_0
# llama-serve-qwen3.6-coding: export LLAMA_ARG_CACHE_TYPE_V ?= q8_0
llama-serve-qwen3.6-coder: export LLAMA_ARG_THINK_BUDGET ?= 16384
llama-serve-qwen3.6-coder: ## Run llama.cpp Qwen3.6 for coding tasks
	@$(MAKE) llama-serve-qwen3.6 \
		LLAMA_ARG_PRESENCE_PENALTY=0.0

llama-serve-qwen3.6-coder-mtp: export LLAMA_ARG_SPEC_TYPE ?= draft-mtp
llama-serve-qwen3.6-coder-mtp: export LLAMA_ARG_SPEC_DRAFT_N_MAX ?= 2
llama-serve-qwen3.6-coder-mtp: ## Run llama.cpp Qwen3.6 for coding tasks with MTP
	@$(MAKE) llama-serve-qwen3.6-coder \
		LLAMA_ARG_UI=true

llama-serve-qwen3.6-instruct: ## Run llama.cpp Qwen3.6 Instruct (non-thinking)
	@$(MAKE) llama-serve-qwen3.6 \
		LLAMA_ARG_TEMP=0.7 \
		LLAMA_ARG_TOP_P=0.8 \
		LLAMA_ARG_PRESENCE_PENALTY=1.5 \
		LLAMA_CHAT_TEMPLATE_KWARGS='{"enable_thinking":false}'

llama-serve-qwen3.6-mini: ## Run llama.cpp for Qwen3.6-35B-A3B-UD-IQ2
	@$(MAKE) llama-serve-qwen3.6-coder \
	  MODEL=models/unsloth/Qwen3.6-35B-A3B-UD-IQ2_M.gguf \
	  LLAMA_ARG_ALIAS=qwen3.6-mini \
		LLAMA_ARG_PORT=9000 \
		LLAMA_ARG_UI=true \
		LLAMA_ARG_TEMP=1 \
		LLAMA_ARG_FLASH_ATTN=on

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
