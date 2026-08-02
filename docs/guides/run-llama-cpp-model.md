# Run a Model with llama.cpp

Set a model location and start with a GGUF model that is already available locally.

```shell
export LLM_MODELS_LOCATION=/path/to/models
mkdir -p "$LLM_MODELS_LOCATION/gpt-oss"
cd "$LLM_MODELS_LOCATION/gpt-oss"
```

Run a CLI prompt:

```shell
llama-cli -m gpt-oss-20b-Q5_K_M.gguf --gpu-layers 12 -p "Test"
```

Start an OpenAI-compatible server:

```shell
llama-server --host 127.0.0.1 --port 9000 --temp 0.5 \
  -ngl 99 -c 8192 --jinja -a gpt-oss \
  -m gpt-oss-20b-f16.gguf
```

Use `--no-webui` when the embedded Web UI is not needed. Adjust `--gpu-layers`, context size, and model path for the available hardware.

## Run with Make

The repository Makefile wraps `llama-server` and exposes the main settings as `LLAMA_ARG_*` variables:

```shell
make llama-serve \
  MODEL=models/gpt-oss/gpt-oss-20b-mxfp4.gguf \
  LLAMA_ARG_ALIAS=gpt-oss \
  LLAMA_ARG_PORT=9000
```

Useful model presets are also available when their model files exist locally:

```shell
make llama-serve-gpt-oss-20b
make llama-serve-qwen3.6
make llama-serve-qwen3.6-coder
```

List the configurable server variable names with:

```shell
make llama-serve-vars
```
