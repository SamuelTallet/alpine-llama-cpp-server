<div align="center">
  <img width="250px" height="auto" src="https://github.com/SamuelTallet/alpine-llama-cpp-server/blob/main/assets/alpine-llama-image-size-rounded-with-bubbles-500px.png?raw=true">
  
  Alpine LLaMA is an ultra-compact Docker image (less than 10 MB), providing a [LLaMA.cpp](https://github.com/ggerganov/llama.cpp) HTTP server for language model inference.
</div>
<div align="center">
  <img alt="Available on Docker Hub" src="https://img.shields.io/badge/available_on-dockerhub-2496ed?style=flat&logo=docker&color=%232496ed">
  <img alt="Docker Image Size" src="https://img.shields.io/docker/image-size/samueltallet/alpine-llama-cpp-server?style=flat&color=%236db33f">
</div>

## Use cases

This Docker image is particularly suited for:
- Servers that cannot do GPU-accelerated inference, e.g. a CPU-only VPS.
- Environments with limited disk space or low bandwidth.

## Examples

#### Standalone, online model

You can start a local standalone HTTP inference server who listens at the port 50000 and leverages a Qwen2.5-Coder 1.5B quantized model hosted, for example on [Hugging Face](https://huggingface.co/):

```bash
docker run --name alpine-llama -p 50000:8080 -e LLAMA_ARG_MODEL_URL=https://huggingface.co/bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-1.5B-Instruct-Q4_K_M.gguf -e LLAMA_ARG_CTX_SIZE=2048 samueltallet/alpine-llama-cpp-server
```

Once the GGUF model file is downloaded (and cached in the Docker container filesystem), you can query the OpenAI-compatible Chat Completions API endpoint exposed:

```bash
curl http://127.0.0.1:50000/v1/chat/completions \
  -d '{
    "messages": [
      { "role": "user", "content": "Explain GraphDB with simple words." }
    ],
    "temperature": 0.3,
    "max_tokens": 100
  }'
# > GraphDB is a type of database that stores and manages data in a way that is similar to the way people think about things in the world. It uses a graph data model, which means that it stores data in nodes and edges, where nodes represent entities and edges represent relationships between those entities [...]
```

## License

Project licensed under MIT. See the [LICENSE](https://github.com/SamuelTallet/alpine-llama-cpp-server/blob/main/LICENSE) file for details.

## Copyright

© 2024 Samuel Tallet
