# Local LLM Workbench

This repository contains local LLM deployment setups, model workflows, runtime guides, and AI governance documentation.

Instructions target Ubuntu or Debian Linux with systemd unless a guide says otherwise.

## Choose a Setup

There is no required runtime. Choose a guide based on your goal:

| Goal | Start here |
|---|---|
| Run a model with the simplest local workflow | [Install Ollama](docs/guides/install-ollama.md) |
| Use a browser-based interface | [Open WebUI setup](webui/README.md) |
| Build and tune a local GGUF runtime | [Build llama.cpp](docs/guides/build-llama-cpp.md) |
| Serve a model through an API-oriented runtime | [Install vLLM](docs/guides/install-vllm.md) |
| Convert a Hugging Face model to GGUF | [Convert models to GGUF](docs/guides/convert-models-to-gguf.md) |

For the complete list of available procedures, see the [guide index](docs/guides/README.md).

## Quick Start

For a browser-based local setup:

```bash
cd webui
cp .env.example .env
# Edit .env when using ngrok or Cloudflare tunnels.
docker compose up -d open-webui
```

See [webui/README.md](webui/README.md) for local access, tunnel configuration, and operations.

## Documentation

The [documentation index](docs/README.md) organizes the repository by intent:

- [Concepts](docs/concepts/): foundational LLM, RAG, agent, security, DevSecOps, and governance knowledge.
- [Guides](docs/guides/): installation, model conversion, inference, benchmarking, and troubleshooting procedures.
- [Reference](docs/reference/): agent guidance, governance material, standards, and schemas.
- [Prompts](docs/prompts/): reusable security, engineering, governance, and analysis prompts.
- [Research](docs/research/): research notes and investigations.
- [Assets](docs/assets/): diagrams and images used by the documentation.

## Repository Layout

| Path | Purpose |
|---|---|
| `docs/` | Concepts, guides, references, prompts, research, and documentation assets. |
| `models/` | Local model files and model-related resources. |
| `utils/` | Utility scripts for local LLM operations. |
| `webui/` | Docker Compose setup for Open WebUI and optional tunnels. |

## System Requirements

Local inference needs enough VRAM and system memory for the model, context, runtime, and operating system. See [local LLM resource requirements](docs/concepts/llm-fundamentals/resource-requirements.md) for memory, swap, and offload guidance.
