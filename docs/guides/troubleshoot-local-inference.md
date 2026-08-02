# Troubleshoot Local Inference

## Check the Runtime

Confirm the service, model files, and API endpoint before changing model settings:

```shell
systemctl status ollama
ollama list
curl http://localhost:11434/api/tags
llama-cli --list-devices
```

## Check llama.cpp Chat Templates

When a model produces malformed output, inspect the template shipped with the model:

```shell
less chat_template.jinja
```

Use `--jinja` for models that require a Jinja chat template. Confirm that the selected model file matches the intended tokenizer and template.

## Check Memory and Offload

Reduce context size, GPU layers, or batch size when the process exhausts available memory. See [Resource Requirements](../concepts/llm-fundamentals/resource-requirements.md) for swap and offload guidance.
