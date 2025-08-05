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

