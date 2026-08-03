# Planner Agent Runtime

This runtime asks the model for a plan before executing the request with the configured tools.

## Setup

```shell
uv venv .venv --python 3.12 --seed --managed-python --prompt "planner-agent-3.12"
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

The runtime prints the model's plan, then sends that plan back to the model as guidance while it calls tools and produces the final answer.