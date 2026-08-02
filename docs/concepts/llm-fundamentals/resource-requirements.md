# Local LLM Resource Requirements

Local inference depends on model size, quantization, context length, batch size, and backend. Keep enough VRAM and system memory for the model, runtime, and operating system.

## Inspect Memory and Swap

```shell
free -h
swapon --show
```

If more swap is required, the repository helper can resize the configured swap image:

```shell
./utils/bash/swap-resize
```

A manual 64 GiB example is:

```shell
sudo swapoff /swap.img
sudo dd if=/dev/zero of=/swap.img bs=1G count=64 status=progress
sudo chmod 600 /swap.img
sudo mkswap /swap.img
sudo swapon /swap.img
```

Swap is a fallback for memory pressure, not a replacement for adequate VRAM or RAM. Start with conservative context and offload settings, then increase them while monitoring memory use.
