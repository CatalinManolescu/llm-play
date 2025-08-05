# Open WebUI with Remote Access

A setup for Open WebUI with secure tunnel access using ngrok and Cloudflare tunnels.

## Architecture

```
Internet → Tunnel (ngrok/Cloudflare) → Open WebUI → Ollama
```

## Quick Start

```bash
# Get your environment ready
cp .env.example .env
# Edit .env with your tunnel tokens (see setup below)

# Start everything
docker compose up -d

# Or just the WebUI for local testing
docker compose up -d open-webui
```

Start with Open WebUI locally to verify your Ollama setup, then add tunnels as needed.

## Access

- **Local**: http://localhost:8000
- **ngrok**: Check http://localhost:4040 for your tunnel URL (URL changes on restart with free plan)
- **Cloudflare**: Your custom domain (persistent URL)

## Tunnel Setup

### Cloudflare Tunnels

Free tier available with persistent tunnels and DDoS protection.

1. Get an account at https://cloudflare.com
2. In Zero Trust dashboard (https://one.dash.cloudflare.com/), go to Networks > Tunnels
3. Create tunnel, choose "Cloudflared", name it whatever
4. Set **Service** to HTTP and **URL** to `open-webui:8080` (container port)
5. Add your domain/subdomain
6. Copy the token to your `.env` as `CLOUDFLARE_TUNNEL_TOKEN=your_token`

### ngrok

Quick setup for temporary access. Free plan has time and connection limits.

1. Sign up at https://ngrok.com
2. Get auth token from https://dashboard.ngrok.com/get-started/your-authtoken
3. Add to `.env`: `NGROK_AUTHTOKEN=your_token`

## Operations

```bash
# Check status of configured services
docker compose ps

# Restart everything
docker compose restart

# Just restart the tunnel (same for ngrok)
docker compose restart cloudflared

# Check logs
docker compose logs -f open-webui
docker compose logs -f cloudflared

# Stop the tunnels but keep WebUI running
docker compose stop ngrok cloudflared
```

## When (not If) Things Break

**Open WebUI won't start**:

- Check if Ollama is running: `ollama list`
- Make sure nothing else is using port 8000: `sudo lsof -i :8000`
- Try restart: `docker compose down && docker compose up -d open-webui`

**Cloudflare tunnel is down**:

- Check token status in Zero Trust dashboard
- Check logs: `docker compose logs cloudflared`
- Restart the tunnel: `docker compose restart cloudflared`

**ngrok disconnected**:

- Check plan limits https://dashboard.ngrok.com/usage
- Check connection limits at http://localhost:4040

**Can't reach WebUI through tunnel but local works**:

- Check tunnel configuration
- Verify domain settings in Cloudflare

