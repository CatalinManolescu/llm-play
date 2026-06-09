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
VLLM_DOCKER_HF_CACHE ?= $(HOME)/.cache/huggingface
VLLM_DOCKER_ARGS ?=
HF_ACCOUNT ?= unsloth
HF_TOKEN ?=
HF_API_URL ?= https://huggingface.co/api/models

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
	  rocminfo | grep -i "Marketing Name:"; \
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

hf-ls: export HF_ACCOUNT ?= unsloth
hf-ls: ## List Hugging Face models for an account (HF_ACCOUNT=...)
	@if [ -z "$(HF_ACCOUNT)" ]; then \
		echo "HF_ACCOUNT is required. Example:"; \
		echo "  make hf-ls HF_ACCOUNT=unsloth"; \
		exit 1; \
	fi
	@if ! command -v jq >/dev/null 2>&1; then \
		echo "jq is required. Install jq and try again." >&2; \
		exit 1; \
	fi
	@models="$$(curl -fsSL -H "User-Agent: llm-makefile-hf-ls" $(if $(HF_TOKEN),-H "Authorization: Bearer $(HF_TOKEN)") "$(HF_API_URL)?author=$(HF_ACCOUNT)&full=true&limit=1000" | jq -r '.[] | (.modelId // .id // empty) | split("/")[-1]' | sort)"; \
	if [ -n "$$models" ]; then \
		printf '%s\n' "$$models"; \
	else \
		echo "No models found for Hugging Face account: $(HF_ACCOUNT)" >&2; \
		exit 1; \
	fi

hf-gguf-ls: export HF_ACCOUNT ?= unsloth
hf-gguf-ls: ## List GGUF files for a Hugging Face model (HF_ACCOUNT=... MODEL=...)
	echo "$(HF_ACCOUNT)"
	@if [ -z "$(HF_ACCOUNT)" ]; then \
		echo "HF_ACCOUNT is required. Example:"; \
		echo "  make hf-gguf-ls HF_ACCOUNT=unsloth MODEL=Qwen3.6-35B-A3B-GGUF"; \
		exit 1; \
	fi
	@if [ -z "$(MODEL)" ]; then \
		echo "MODEL is required. Example:"; \
		echo "  make hf-gguf-ls HF_ACCOUNT=unsloth MODEL=Qwen3.6-35B-A3B-GGUF"; \
		exit 1; \
	fi
	@if ! command -v jq >/dev/null 2>&1; then \
		echo "jq is required. Install jq and try again." >&2; \
		exit 1; \
	fi
	@files="$$(curl -fsSL -H "User-Agent: llm-makefile-hf-gguf-ls" $(if $(HF_TOKEN),-H "Authorization: Bearer $(HF_TOKEN)") "$(HF_API_URL)/$(HF_ACCOUNT)/$(MODEL)" | jq -r '.siblings[]? | (.rfilename // .filename // empty) | select(test("\\.gguf$$"; "i"))' | sort)"; \
	if [ -n "$$files" ]; then \
		printf '%s\n' "$$files"; \
	else \
		echo "No GGUF files found for Hugging Face model: $(HF_ACCOUNT)/$(MODEL)" >&2; \
		exit 1; \
	fi

hf-gguf-download: export HF_ACCOUNT ?= unsloth
hf-gguf-download: ## Download a GGUF file from Hugging Face (HF_ACCOUNT=... MODEL=... GGUF_FILE=...)
	@if [ -z "$(MODEL)" ]; then \
		echo "MODEL is required. Example:"; \
		echo "  make hf-gguf-download HF_ACCOUNT=unsloth MODEL=Qwen3.6-35B-A3B-GGUF GGUF_FILE=Qwen3.6-35B-A3B-Q8_0.gguf"; \
		exit 1; \
	fi
	@if [ -z "$(GGUF_FILE)" ]; then \
		echo "GGUF_FILE is required. Example:"; \
		echo "  make hf-gguf-download HF_ACCOUNT=unsloth MODEL=Qwen3.6-35B-A3B-GGUF GGUF_FILE=Qwen3.6-35B-A3B-Q8_0.gguf"; \
		exit 1; \
	fi

	download_path="$(DOWNLOAD_PATH)"; \
	if [ -z "$$download_path" ]; then \
		download_path="models/$(HF_ACCOUNT)/$(MODEL)"; \
	fi; \
	dest="$$download_path/$(GGUF_FILE)"; \
	mkdir -p "$$(dirname "$$dest")"; \
	curl -fL -H "User-Agent: llm-makefile-hf-gguf-download" $(if $(HF_TOKEN),-H "Authorization: Bearer $(HF_TOKEN)") \
		-o "$$dest" "https://huggingface.co/$(HF_ACCOUNT)/$(MODEL)/resolve/main/$(GGUF_FILE)?download=true"; \
	printf 'Downloaded %s\n' "$$dest"

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
# whether to enable KV cache offloading (default: enabled)
llama-serve: export LLAMA_ARG_KV_OFFLOAD ?= off
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
		LLAMA_ARG_CACHE_RAM=1024 \
		LLAMA_ARG_TEMP=0,6 \
		LLAMA_ARG_FLASH_ATTN=on

llama-serve-gpt-oss-20b: ## Run llama.cpp for openai/gpt-oss-20b
	@$(MAKE) llama-serve \
	  MODEL=models/gpt-oss/gpt-oss-20b-mxfp4.gguf \
	  LLAMA_ARG_ALIAS=gpt-oss \
		LLAMA_ARG_TEMP=1

llama-serve-qwen3.6: export MODEL ?= models/unsloth/Qwen3.6-35B-A3B-GGUF/Qwen3.6-35B-A3B-UD-IQ4_NL_XL.gguf
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
llama-serve-qwen3.6-coder: export LLAMA_ARG_KV_OFFLOAD ?= on
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
	@$(MAKE) llama-serve-qwen3.6-coder-mtp \
	  MODEL=models/unsloth/Qwen3.6-35B-A3B-MTP-GGUF/Qwen3.6-35B-A3B-UD-IQ2_XXS.gguf \
	  LLAMA_ARG_ALIAS=qwen3.6-mini \
		LLAMA_ARG_PORT=9000 \
		LLAMA_ARG_CACHE_RAM=4096 \
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

vllm-docker-serve-rocm: export VLLM_DOCKER_IMAGE ?= vllm/vllm-openai-rocm:latest
vllm-docker-serve-rocm: export VLLM_DOCKER_NAME ?= vllm-openai-rocm
vllm-docker-serve-rocm: export MODEL ?= Qwen/Qwen3.6-35B-A3B
# vllm-docker-serve-rocm: export VLLM_SERVED_MODEL_NAME ?= qwen3.6-35b-a3b
vllm-docker-serve-rocm: export VLLM_GENERATION_CONFIG ?= {"temperature":0.6,"top_p":0.95}
vllm-docker-serve-rocm: export VLLM_GPU_MEMORY_UTILIZATION ?= 0.90
vllm-docker-serve-rocm: export VLLM_CPU_OFFLOAD_GB ?= 8
vllm-docker-serve-rocm: export VLLM_KV_CACHE_DTYPE ?= fp8
vllm-docker-serve-rocm: export VLLM_QUANTIZATION ?=
vllm-docker-serve-rocm: export VLLM_LOAD_FORMAT ?=
vllm-docker-serve-rocm: export VLLM_TOKENIZER ?=
vllm-docker-serve-rocm: export VLLM_MAX_MODEL_LEN ?= 4096 # 8192
vllm-docker-serve-rocm: export VLLM_MAX_NUM_BATCHED_TOKENS ?= 2048
vllm-docker-serve-rocm: export VLLM_MAX_NUM_SEQS ?= 20
vllm-docker-serve-rocm: export VLLM_ROCM_USE_AITER ?= 0
vllm-docker-serve-rocm: export VLLM_ROCM_USE_AITER_MOE ?= 0
vllm-docker-serve-rocm: export VLLM_ROCM_QUICK_REDUCE_QUANTIZATION ?= INT4
# ROCM_AITER_UNIFIED_ATTN
vllm-docker-serve-rocm: export VLLM_ATTENTION_BACKEND ?= ROCM_ATTN
vllm-docker-serve-rocm: export VLLM_USE_TRITON_FLASH_ATTN ?= 0
vllm-docker-serve-rocm: export FLASH_ATTENTION_TRITON_AMD_ENABLE ?= TRUE
vllm-docker-serve-rocm: export VLLM_REASONING_PARSER ?= qwen3
vllm-docker-serve-rocm: export VLLM_TOOL_CALL_PARSER ?= qwen3_coder
vllm-docker-serve-rocm: export VLLM_ARGS = \
	--tensor-parallel-size 1 \
	--reasoning-parser $(VLLM_REASONING_PARSER) \
	--max-model-len $(VLLM_MAX_MODEL_LEN) \
	--max-num-batched-tokens $(VLLM_MAX_NUM_BATCHED_TOKENS) \
	--max-num-seqs $(VLLM_MAX_NUM_SEQS) \
	--cpu-offload-gb $(VLLM_CPU_OFFLOAD_GB) \
	--kv-cache-dtype $(VLLM_KV_CACHE_DTYPE) \
	--enable-auto-tool-choice \
	--language-model-only \
	$(if $(VLLM_TOOL_CALL_PARSER),--tool-call-parser $(VLLM_TOOL_CALL_PARSER)) \
	$(if $(VLLM_ATTENTION_BACKEND),--attention-backend $(VLLM_ATTENTION_BACKEND)) \
	$(if $(VLLM_LOAD_FORMAT),--load-format $(VLLM_LOAD_FORMAT)) \
	$(if $(VLLM_TOKENIZER),--tokenizer $(VLLM_TOKENIZER)) \
	$(if $(VLLM_QUANTIZATION),--quantization $(VLLM_QUANTIZATION)) \

vllm-docker-serve-rocm: ## Run vLLM ROCm Docker OpenAI server (MODEL=...)
	@if [ -z "$(MODEL)" ]; then \
		echo "MODEL is required. Example:"; \
		echo "  make vllm-docker-serve-rocm MODEL=Qwen/Qwen3-0.6B"; \
		exit 1; \
	fi
	@mkdir -p "$(or $(VLLM_DOCKER_HF_CACHE),$(HOME)/.cache/huggingface)"
	docker run --rm \
		--name "$(VLLM_DOCKER_NAME)" \
		--group-add=video \
		--cap-add=SYS_PTRACE \
		--security-opt seccomp=unconfined \
		--device /dev/kfd \
		--device /dev/dri \
		-v "$(CURDIR):/workspace" \
		-w /workspace \
		-v "$(or $(VLLM_DOCKER_HF_CACHE),$(HOME)/.cache/huggingface):/home/vllm/.cache/huggingface" \
		--env "HF_TOKEN=$(HF_TOKEN)" \
		--env "PYTORCH_ALLOC_CONF=expandable_segments:True" \
		--env "PYTORCH_TUNABLEOP_ENABLED=0" \
		--env "HSA_NO_SCRATCH_RECLAIM=1" \
		--env "AMDGCN_USE_BUFFER_OPS=0" \
		--env "HSA_OVERRIDE_GFX_VERSION=11.5.0" \
		--env "VLLM_ROCM_USE_AITER=$(VLLM_ROCM_USE_AITER)" \
		--env "VLLM_ROCM_USE_AITER_MOE=$(VLLM_ROCM_USE_AITER_MOE)" \
		--env "VLLM_ROCM_QUICK_REDUCE_QUANTIZATION=$(VLLM_ROCM_QUICK_REDUCE_QUANTIZATION)" \
		--env "VLLM_USE_TRITON_FLASH_ATTN=$(VLLM_USE_TRITON_FLASH_ATTN)" \
		--env "FLASH_ATTENTION_TRITON_AMD_ENABLE=$(FLASH_ATTENTION_TRITON_AMD_ENABLE)" \
		-p "$(VLLM_PORT):8000" \
		--ipc=host $(VLLM_DOCKER_ARGS) \
		$(VLLM_DOCKER_IMAGE) \
		"$(MODEL)" \
		--gpu-memory-utilization $(VLLM_GPU_MEMORY_UTILIZATION) \
		--no-enable-prefix-caching \
		$(if $(VLLM_GENERATION_CONFIG),--override-generation-config '$(VLLM_GENERATION_CONFIG)') \
		$(VLLM_ARGS)

vllm-serve-openai-gpt-oss-20b: ## Run vLLM for openai/gpt-oss-20b
	@export HSA_NO_SCRATCH_RECLAIM=1
	@export AMDGCN_USE_BUFFER_OPS=0
	@export VLLM_ROCM_USE_AITER=1
	@export VLLM_ROCM_QUICK_REDUCE_QUANTIZATION=INT4
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
