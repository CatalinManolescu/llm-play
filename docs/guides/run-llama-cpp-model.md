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
