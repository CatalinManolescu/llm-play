# Plan-Execute Agent Runtime

This runtime separates planning from execution. The model creates a structured tool-call plan, the runtime executes one specified tool per step, and the model combines the tool results into a final answer.

## Setup

```shell
uv venv .venv --python 3.12 --seed --managed-python --prompt "plan-execute-agent-3.12"
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

The runtime prints the plan, each executed tool call and its result, then the final answer.