# Benchmark llama.cpp

Run prompt-processing and token-generation measurements with `llama-bench`:

```shell
llama-bench --flash-attn 1 \
  --model ./gpt-oss-20b-Q5_K_M.gguf -pg 1024,256
```

The benchmark reports prompt processing (`pp`) and text generation (`tg`) throughput in tokens per second. Record the model file, backend, GPU-layer count, flash-attention setting, context size, and hardware alongside results so measurements remain comparable.

Example result shape:

```text
| model | size | params | backend | ngl | fa | test | t/s |
| ----- | ---: | -----: | ------- | --: | --: | ---- | --: |
| gpt-oss Q5_K_M | 10.90 GiB | 20.91 B | Vulkan | 99 | 1 | pp512 | 249.19 |
```
