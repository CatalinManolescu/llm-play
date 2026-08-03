# Simple Agent Runtime

This runtime demonstrates a direct LLM -> tool -> LLM loop using an OpenAI-compatible Chat Completions API.

## Setup

```shell
uv venv .venv --python 3.12 --seed --managed-python --prompt "simple-agent-3.12"
uv pip install --python .venv/bin/python -r requirements.txt
```

## Run the order-support example

Run this command from this directory:

```shell
.venv/bin/python runtime.py \
	--url http://localhost:8000/v1 \
	--api-key local \
	--model Qwen/Qwen3-8B \
	--agent ../../../examples/order-support-agent/agent.yaml \
	--prompt "What is the status of Alice's latest order?"
```

The runtime loads the YAML agent, lets the model choose tools, executes the requested Python functions, then sends the results back until the model returns a final answer.