#!/usr/bin/env bash

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

echo "Configure Ollama Firewall"

echo "Copy firewall script to /usr/local/bin/ollama-firewall.sh"
yes | sudo cp -rf "$(dirname "$0")/ollama-firewall.sh" /usr/local/bin/ollama-firewall.sh
sudo chmod 0755 /usr/local/bin/ollama-firewall.sh

echo "Creating systemd service for Ollama firewall"
sudo tee /etc/systemd/system/ollama-firewall.service > /dev/null << EOF
[Unit]
Description=Restrict Ollama access
After=network-online.target docker.service
Wants=network-online.target
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ollama-firewall.sh apply
ExecStop=/usr/local/bin/ollama-firewall.sh remove
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

echo "Systemd service created at /etc/systemd/system/ollama-firewall.service"
sudo systemctl daemon-reload
sudo systemctl enable --now ollama-firewall.service