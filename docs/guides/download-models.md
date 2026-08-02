# Download Models

Use this guide to discover models and download existing GGUF files from Hugging Face. Use [Convert Models to GGUF](convert-models-to-gguf.md) when you need to convert a source model yourself.

## Discover Models with Make

The repository Makefile can inspect Hugging Face repositories. Install `jq` first:

```shell
sudo apt install jq
```

List models for an account:

```shell
make hf-ls HF_ACCOUNT=unsloth
```

List GGUF files in a model repository:

```shell
make hf-gguf-ls \
  HF_ACCOUNT=unsloth \
  MODEL=Qwen3.6-35B-A3B-GGUF
```

## Download a GGUF File

Download one file into the repository model directory:

```shell
make hf-gguf-download \
  HF_ACCOUNT=unsloth \
  MODEL=Qwen3.6-35B-A3B-GGUF \
  GGUF_FILE=Qwen3.6-35B-A3B-Q8_0.gguf
```

By default, the file is stored under `models/<account>/<model>/`. Set `DOWNLOAD_PATH` to override the destination.

Set `HF_TOKEN` for private or gated repositories:

```shell
make hf-gguf-download \
  HF_ACCOUNT=unsloth \
  MODEL=Qwen3.6-35B-A3B-GGUF \
  GGUF_FILE=Qwen3.6-35B-A3B-Q8_0.gguf \
  HF_TOKEN="$HF_TOKEN"
```
