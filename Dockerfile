# Build stage.
# Using a lightweight Alpine Linux base image for a minimal final image size.
FROM alpine:3.20 AS build

# Set the working directory.
WORKDIR /opt/llama.cpp

# Install build dependencies necessary to compile the LLaMA.cpp HTTP Server.
# Using --no-cache to avoid caching the Alpine packages index
# and --virtual to group build dependencies for easier cleanup.
RUN apk add --no-cache --virtual .build-deps \
    git=~2.45 \
    g++=~13.2 \
    make=~4.4 \
    cmake=~3.29 \
    linux-headers=~6.6 \
    curl-dev=~8.11 && \
    # Clone the llama.cpp repository with a shallow depth of one level to reduce data transfer.
    git clone --depth=1 https://github.com/ggerganov/llama.cpp . && \
    # Configure the CMake build system.
    cmake -B build \
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
FROM alpine:3.20

# Set the working directory.
WORKDIR /opt/llama.cpp

# Install runtime dependencies: C++, cURL & OpenMP.
RUN apk add --no-cache \
    libstdc++=~13.2 \
    libcurl=~8.11 \
    libgomp=~13.2

# Copy the compiled llama-server executable from the build stage to the current working directory.
COPY --from=build /opt/llama-server .

# Server will listen on 8080.
EXPOSE 8080

# Run the LLaMA.cpp HTTP Server.
# Notice the host is set to 0.0.0.0 to allow HTTP access outside container.
CMD [ "sh", "-c", "/opt/llama.cpp/llama-server --host 0.0.0.0" ]
