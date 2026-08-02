# Install and Configure Ollama

These instructions target Ubuntu or Debian Linux with systemd.

## Install

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

## Start and Verify

```bash
systemctl start ollama
ollama pull llama3
ollama run llama3
ollama list
curl http://localhost:11434/api/tags
```

## Configure Network Access

Ollama listens on localhost by default. Use the repository helper when remote access or WebUI integration is required:

```bash
./utils/bash/configure-ollama-network.sh
```

Alternatively, create `/etc/systemd/system/ollama.service.d/override.conf`:

```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_ORIGINS=*"
```

Then reload and restart the service:

```bash
systemctl daemon-reload
systemctl restart ollama
```

Expose the service only on a trusted network or behind an authenticated reverse proxy.

## Manage Models

```bash
ollama pull llama4:maverick
ollama pull llama4:scout
ollama pull llama3:latest
ollama pull qwen3:latest
ollama pull deepseek-r1:latest
ollama pull deepseek-coder:latest
```

Models are commonly stored under `/usr/share/ollama/.ollama/models` when Ollama runs as a system service.

## Further Reading

- [Ollama documentation](https://github.com/ollama/ollama)
- [Ollama configuration FAQ](https://github.com/ollama/ollama/blob/main/docs/faq.md)
