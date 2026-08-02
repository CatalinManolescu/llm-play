# Convert Models to GGUF

Create an isolated environment for llama.cpp conversion tools:

```shell
python3 -m venv ~/.venv/llama
source ~/.venv/llama/bin/activate

git clone https://github.com/ggml-org/llama.cpp.git
pip install -r llama.cpp/requirements.txt
```

Update model support metadata when required:

```shell
cd llama.cpp
python3 convert_hf_to_gguf_update.py
```

Authenticate with Hugging Face and download a source model:

```shell
huggingface-cli login
hf download openai/gpt-oss-20b --local-dir ./gpt-oss-20b
```

Convert it to F16 GGUF:

```shell
python3 llama.cpp/convert_hf_to_gguf.py ./gpt-oss-20b \
  --outfile ./gpt-oss-20b/out/gpt-oss-20b-f16.gguf \
  --outtype f16
```

Quantize the converted model with the installed `llama-quantize` binary:

```shell
llama-quantize ./gpt-oss-20b/out/gpt-oss-20b-f16.gguf \
  ./gpt-oss-20b/out/gpt-oss-20b-Q4_K_M.gguf Q4_K_M
```

## Further Reading

- [GGUF conversion discussion](https://github.com/ggml-org/llama.cpp/discussions/7927)
