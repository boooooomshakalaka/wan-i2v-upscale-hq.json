# Multi-stage build for SageAttention
# Stage 1: Build SageAttention wheel
FROM nvidia/cuda:12.4.1-devel-ubuntu22.04 AS sage_build

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential build tools and Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3.10-dev \
    python3-pip \
    git \
    build-essential \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install build tools
RUN python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel

# Install PyTorch first (required for building SageAttention)
RUN pip3 install --no-cache-dir \
    torch==2.4.0 \
    torchvision==0.19.0 \
    --index-url https://download.pytorch.org/whl/cu124

# Install packaging tools needed for SageAttention build
RUN pip3 install --no-cache-dir packaging ninja

# Clone and build SageAttention
WORKDIR /build
RUN git clone https://github.com/thu-ml/SageAttention.git && \
    cd SageAttention && \
    pip3 wheel --no-deps -w /wheels .

# Stage 2: Final runtime image
FROM runpod/worker-comfyui:5.1.0-base

# Install the pre-built SageAttention wheel
COPY --from=sage_build /wheels/*.whl /tmp/
RUN pip install --no-cache-dir /tmp/*.whl && rm -rf /tmp/*.whl

# Set working directory
WORKDIR /comfyui

# Expose ComfyUI port
EXPOSE 8188

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8188/ || exit 1

# Start ComfyUI
CMD ["python", "-u", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
