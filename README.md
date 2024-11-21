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

#### Standalone

You can start a local standalone HTTP inference server who listens at the port 50000 and leverages the [SmolLM2 1.7B quantized model](https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF) available on Hugging Face (HF) with this:

```bash
docker run --name alpine-llama --publish 50000:8080 --env LLAMA_ARG_HF_REPO=HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF --env LLAMA_ARG_HF_FILE=smollm2-1.7b-instruct-q4_k_m.gguf --env LLAMA_API_KEY=sk-xxxx --env LLAMA_ARG_ALIAS=smollm2-1.7b samueltallet/alpine-llama-cpp-server
```

Once the GGUF model file is downloaded from HF (and cached in the Docker container filesystem), you can query your local endpoint using the official [OpenAI TS & JS API library](https://www.npmjs.com/package/openai):

```js
import OpenAI from 'openai'

const client = new OpenAI({
  apiKey: 'sk-xxxx', // Warning: in production, use a strong key.
  baseURL: 'http://127.0.0.1:50000/v1',
})

async function runInference() {
  const stream = await client.chat.completions.create({
    messages: [
      { role: 'user', content: 'Summarize Alice In Wonderland.' },
    ],
    model: 'smollm2-1.7b',
    temperature: 0.5,
    stream: true,
    max_tokens: 100,
  })

  for await (const chunk of stream) {
    process.stdout.write(chunk.choices[0]?.delta?.content || '')
  }
}

runInference()
// > Alice in Wonderland is a children's novel written by Lewis Carroll, published in 1865. The story follows Alice as she falls down a rabbit hole and enters a fantastical world inhabited by strange creatures, talking animals, and absurd situations. Alice must navigate this bizarre realm, encountering a cast of eccentric characters, including the Cheshire Cat, the March Hare, and the Dormouse [...]
```

## License

Project licensed under MIT. See the [LICENSE](https://github.com/SamuelTallet/alpine-llama-cpp-server/blob/main/LICENSE) file for details.

## Copyright

© 2024 Samuel Tallet
