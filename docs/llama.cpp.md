# llama.cpp

Start server

```shell
LLAMA_HOST=127.0.0.1
LLAMA_PORT=9000
LLAMA_MODELS_LOCATION=

llama-server --host $LLAMA_HOST --port $LLAMA_PORT --temp 0.5 -ngl 99 -c 8192 --no-webui -a gpt-oss -m  gpt-oss/out/gpt-oss-20b-f16.gguf --jinja


```

Transform hf to gguf

```shell
python3 -m venv ~/.venv/llama
source ~/.venv/llama/bin/activate

git clone https://github.com/ggml-org/llama.cpp.git
pip install -r llama.cpp/requirements.txt

cd llama.cpp

# edit convert_hf_to_gguf_update.py and add the model if it is not there
vi convert_hf_to_gguf_update.py

huggingface-cli login
python3 convert_hf_to_gguf_update.py
```

Download model

Transform openai/gpt-oss-20b

```

```