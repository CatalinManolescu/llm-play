#!/usr/sbin/env bash

echo "Configuring Ollama for external access"

sudo mkdir -p /etc/systemd/system/ollama.service.d/

sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null << EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_ORIGINS=*"
EOF

echo "Configuration file created at /etc/systemd/system/ollama.service.d/override.conf"

echo "Reloading systemd and restarting Ollama"
sudo systemctl daemon-reload
sudo systemctl restart ollama

echo "Ollama configured for external access on 0.0.0.0:11434"
echo "You can verify with: curl http://localhost:11434/api/tags"
