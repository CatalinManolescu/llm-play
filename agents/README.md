# Agents

Small, educational LLM agent examples and Python runtimes using an OpenAI-compatible Chat Completions API.

## Layout

```text
examples/         Self-contained YAML agents and mock tools.
runtimes/python/  Minimal Python implementations of common agent loops.
```

## Examples

- [Order support](examples/order-support-agent/agent.yaml): look up customers and their orders.
- [Travel planning](examples/travel-agent/agent.yaml): search mock flights, hotels, and activities.

## Python runtimes

- [Simple agent](runtimes/python/simple-agent/README.md): direct LLM -> tool -> LLM loop.
- [Planner agent](runtimes/python/planner-agent/README.md): creates a plan before using tools.
- [Plan-execute agent](runtimes/python/plan-execute-agent/README.md): creates a structured plan and executes one specified tool per step.

Each runtime has its own setup instructions and local `.venv`. To run the order-support example with the simple runtime, first set up its environment as described in its README, then run this command from this directory:

```shell
runtimes/python/simple-agent/.venv/bin/python runtimes/python/simple-agent/runtime.py \
	--url http://localhost:8000/v1 \
	--api-key local \
	--model Qwen/Qwen3-8B \
	--agent examples/order-support-agent/agent.yaml \
	--prompt "What is the status of Alice's latest order?"
```

## Agent YAML

An agent definition provides a `name`, natural-language `instructions`, and a `tools` list. Each tool declares its name, description, Python function import path, and JSON-schema parameters. The runtime loads the YAML file, imports the configured functions, and exposes them to the model.