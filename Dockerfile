# Build stage.
# Using a lightweight Alpine Linux base image for a minimal final image size.
FROM alpine:3.21 AS build

# The target platform, set by Docker Buildx.
ARG TARGETPLATFORM

# The LLaMA.cpp git tag, passed by the GitHub Action, to checkout and compile.
ARG LLAMA_GIT_TAG

# Set the working directory.
WORKDIR /opt/llama.cpp

# Compile the official LLaMA.cpp HTTP Server.
RUN \
    # Since my GitHub Action uses QEMU for the ARM64 build, I need to disable the native build.
    # Otherwise, the build will fail. See: https://github.com/ggml-org/llama.cpp/issues/10933
    # The CPU architecture is set to "armv8-a" because it's the one used by the Raspberry Pi 3+.
    if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        export GGML_NATIVE=OFF; \
        export GGML_CPU_ARM_ARCH="armv8-a"; \
    else \
        export GGML_NATIVE=ON; \
        export GGML_CPU_ARM_ARCH=""; \
    fi && \
    # Install build dependencies.
    # Using --no-cache to avoid caching the Alpine packages index
    # and --virtual to group build dependencies for easier cleanup.
    apk add --no-cache --virtual .build-deps \
    git=~2.47 \
    g++=~14.2 \
    make=~4.4 \
    cmake=~3.31 \
    linux-headers=~6.6 \
    curl-dev=~8.12 && \
    # Checkout the llama.cpp repository to the wanted version (git tag).
    # A shallow clone (--depth 1) is used to minimize the data transfer.
    git clone -b ${LLAMA_GIT_TAG} --depth 1 https://github.com/ggml-org/llama.cpp . && \
    # To save space, empty the index.html that will be embedded in the llama-server executable.
    touch tools/server/public/index.html && \
    gzip -f tools/server/public/index.html && \
    # Configure the CMake build system.
    cmake -B build \
    # On AMD64, use the native build; but on ARM64, disable it.
    -DGGML_NATIVE=${GGML_NATIVE} \
    # On ARM64, set the CPU architecture to "armv8-a". See the note above.
    -DGGML_CPU_ARM_ARCH=${GGML_CPU_ARM_ARCH} \
    # Enable building only the llama-server executable.
    -DLLAMA_BUILD_SERVER=ON \
    # Enable support for cURL during build to allow the download of GGUF model at first run.
    -DLLAMA_CURL=ON \
    # Include the GGML lib inside this executable to ease deployment...
    -DBUILD_SHARED_LIBS=OFF && \
    # Compile the llama-server target in Release mode for a production use.
    cmake --build build --target llama-server --config Release && \
    # Remove non-essential symbols from this executable to save some space.
    strip build/bin/llama-server && \
    # Copy this executable in a safe place...
    cp build/bin/llama-server /opt && \
    # before cleaning all other build files.
    rm -rf /opt/llama.cpp/* && \
    # Remove build dependencies since they are useless now.
    apk del .build-deps

# Final stage.
# Starting a new stage to create a smaller, cleaner image containing only the runtime environment.
FROM alpine:3.21

# Set the working directory.
WORKDIR /opt/llama.cpp

# Install runtime dependencies: C++, cURL & OpenMP.
RUN apk add --no-cache \
    libstdc++=~14.2 \
    libcurl=~8.12 \
    libgomp=~14.2

# Copy the compiled llama-server executable from the build stage to the current working directory.
COPY --from=build /opt/llama-server .

# Server will listen on 8080.
EXPOSE 8080

# Run the LLaMA.cpp HTTP Server.
CMD [ "sh", "-c", "/opt/llama.cpp/llama-server --host 0.0.0.0 --no-webui" ]

# Notes for the above command:
# - The host is set to 0.0.0.0 to allow HTTP access outside the container.
# - The --no-webui flag is used to disable the embedded web interface. Cf. emptied out index.html
