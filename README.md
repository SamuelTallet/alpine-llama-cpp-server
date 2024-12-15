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
- Environments with limited disk space or low bandwidth.
- Servers that cannot do GPU-accelerated inference, e.g. a CPU-only VPS or a Raspberry Pi.

## Examples

#### Standalone

You can start a local standalone HTTP inference server who listens at the port 50000 and leverages the [Qwen2.5-Coder 1.5B quantized model](https://huggingface.co/bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF) available on Hugging Face (HF) with:

```bash
docker run --name alpine-llama --publish 50000:8080 \
    --env LLAMA_ARG_HF_REPO=bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF \
    --env LLAMA_ARG_HF_FILE=Qwen2.5-Coder-1.5B-Instruct-Q4_K_M.gguf \
    --env LLAMA_API_KEY=sk-xxxx \
    --env LLAMA_ARG_ALIAS=qwen2.5-coder-1.5b \
    samueltallet/alpine-llama-cpp-server
```

Once the GGUF model file is downloaded from HF (and cached in the Docker container filesystem), you can query your local endpoint using the official [OpenAI TS & JS API library](https://www.npmjs.com/package/openai).

For instance, you can execute the following Node.js script to extract the metadata of a product description as a JSON object according to a predefined schema:

```js
// extract_product_meta.mjs
import OpenAI from "openai";

const inferenceClient = new OpenAI({
  // In a real project, you should use environment variables
  // instead of these hardcoded values:
  apiKey: "sk-xxxx",
  baseURL: "http://127.0.0.1:50000/v1",
});

const productDescription = `UrbanShoes 3.0: These brown and green shoes,
suitable for casual wear, are made of apple leather and recycled rubber.
They are priced at only €654.90.`; // 👈😄 This is not a typo.

const productSchema = {
  properties: {
    name: { type: "string" },
    materials: { type: "array", items: { type: "string" } },
    colors: { type: "array", items: { type: "string" } },
    price: { type: "number" },
    currency: { type: "string", enum: ["USD", "EUR", "GBP"] },
  },
  required: ["name", "materials", "colors", "price", "currency"],
};

async function extractProductMeta() {
  const response = await inferenceClient.chat.completions.create({
    messages: [
      { role: "user", content: productDescription }
    ],
    model: "qwen2.5-coder-1.5b",
    temperature: 0.2,
    response_format: {
      type: "json_schema",
      json_schema: {
        strict: true,
        schema: productSchema,
      },
    },
  });

  console.log(response.choices[0].message.content);
}

extractProductMeta();
// > { "name": "UrbanShoes 3.0", "materials": ["apple leather", "recycled rubber"], "colors": ["brown", "green"], "price": 654.90, "currency": "EUR" }
```

## License

Project licensed under MIT. See the [LICENSE](https://github.com/SamuelTallet/alpine-llama-cpp-server/blob/main/LICENSE) file for details.

## Copyright

© 2024 Samuel Tallet
