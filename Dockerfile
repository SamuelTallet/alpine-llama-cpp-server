# Build stage.
# Using a lightweight Alpine Linux base image for a minimal final image size.
FROM alpine:3.21 AS build

# The target platform, set by Docker Buildx.
ARG TARGETPLATFORM

# The LLaMA.cpp git tag, passed by the GitHub Action, to checkout and compile.
ARG LLAMA_GIT_TAG

# Set the working directory.
WORKDIR /opt/llama.cpp

# Copy the bigstack.c source file for building the thread stack fix.
COPY source/bigstack.c /tmp/bigstack.c

# Compile the official LLaMA.cpp HTTP Server.
RUN \
    # Since my GitHub Action uses QEMU for the ARM64 build, I need to disable the native build.
    # Otherwise, the build will fail. See: https://github.com/ggml-org/llama.cpp/issues/10933
    # The CPU architecture is set to "armv8-a" because it's the one used by the Raspberry Pi 3+.
    # On AMD64, I target AVX2 to run on most CPUs.
    if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        set -- -DGGML_CPU_ARM_ARCH=armv8-a; \
    else \
        set -- -DGGML_SSE42=ON -DGGML_AVX=ON -DGGML_AVX2=ON -DGGML_FMA=ON -DGGML_F16C=ON -DGGML_BMI2=ON; \
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
    openssl-dev=~3.3 && \
    # Checkout the llama.cpp repository to the wanted version (git tag).
    # A shallow clone (--depth 1) is used to minimize the data transfer.
    git clone -b ${LLAMA_GIT_TAG} --depth 1 https://github.com/ggml-org/llama.cpp . && \
    # Configure the CMake build system.
    cmake -B build \
    # Disable the native build and set the target CPU. See the notes above.
    -DGGML_NATIVE=OFF \
    "$@" \
    # Build only the llama-server executable.
    -DLLAMA_BUILD_SERVER=ON \
    # Don't build the embedded web interface to save space.
    -DLLAMA_BUILD_WEBUI=OFF \
    # Include the GGML lib inside this executable to ease deployment...
    -DBUILD_SHARED_LIBS=OFF && \
    # Compile the llama-server target in Release mode for a production use, using all cores.
    cmake --build build --target llama-server --config Release --parallel "$(nproc)" && \
    # Remove non-essential symbols from this executable to save space.
    strip build/bin/llama-server && \
    # Copy this executable in a safe place...
    cp build/bin/llama-server /opt && \
    # Build a small shared library that overrides pthread_create to use 8MB stacks.
    # musl libc hardcodes thread stacks at 128KB, which causes std::regex stack overflows
    # when cpp-httplib parses long redirect URLs (e.g. HuggingFace Xet storage).
    gcc -shared -fPIC -o /opt/bigstack.so /tmp/bigstack.c -ldl && \
    strip /opt/bigstack.so && \
    # before cleaning all other build files.
    rm -rf /opt/llama.cpp/* && \
    # Remove build dependencies since they are useless now.
    apk del .build-deps

# Final stage.
# Starting a new stage to create a smaller, cleaner image containing only the runtime env.
FROM alpine:3.21

# Set the working directory.
WORKDIR /opt/llama.cpp

# Install runtime dependencies: C++, OpenSSL & OpenMP.
RUN apk add --no-cache \
    libstdc++=~14.2 \
    libssl3=~3.3 \
    libcrypto3=~3.3 \
    libgomp=~14.2

# Copy the compiled llama-server executable and the stack-size fix from the build stage.
COPY --from=build /opt/llama-server /opt/bigstack.so ./

# Server will listen on 8080.
ENV LLAMA_ARG_PORT=8080
EXPOSE 8080

# Preload the stack-size fix, then run the LLaMA.cpp HTTP Server.
ENV LD_PRELOAD=/opt/llama.cpp/bigstack.so

CMD [ "/opt/llama.cpp/llama-server", "--host", "0.0.0.0", "--no-ui" ]
# 0.0.0.0 allows the server to be accessible from outside the container.
