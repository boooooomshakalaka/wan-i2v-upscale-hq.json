# =========================
# Stage 1: Build SageAttention wheel
# =========================
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6;8.9;9.0;12.0" \
    FORCE_CUDA=1 \
    MAX_JOBS=4

# Build deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3.10-dev \
    python3-pip \
    git \
    build-essential \
    cmake \
    ninja-build \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Make python/python3 available
RUN ln -sf /usr/bin/python3.10 /usr/bin/python && \
    ln -sf /usr/bin/python3.10 /usr/bin/python3

# Pip tooling - CRITICAL: These must be installed for --no-build-isolation to work
RUN python -m pip install --no-cache-dir --upgrade \
    pip setuptools wheel packaging ninja

# PyTorch (CUDA 12.8) - MUST be installed before building SageAttention
RUN pip install --no-cache-dir \
    torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu128

# Build SageAttention with proper flags
WORKDIR /build
RUN git clone --depth 1 https://github.com/thu-ml/SageAttention.git

WORKDIR /build/SageAttention

# THE KEY FIX: Use --no-build-isolation so it can see PyTorch
RUN pip wheel --no-build-isolation --no-deps --verbose -w /wheels .

# Verify wheel exists
RUN ls -lah /wheels/ && \
    test -f /wheels/*.whl || (echo "ERROR: SageAttention wheel not found!" && exit 1)


# =========================
# Stage 2: Runtime image (RunPod ComfyUI worker)
# =========================
FROM runpod/worker-comfyui:5.1.0-base

ENV PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive

# Runtime deps (video + OpenCV safety + healthcheck)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install SageAttention wheel
COPY --from=builder /wheels/*.whl /tmp/wheels/
RUN pip install --no-cache-dir /tmp/wheels/*.whl && \
    rm -rf /tmp/wheels

# Verify SageAttention import
RUN python -c "import sageattention; print('✓ SageAttention successfully installed')" || \
    (echo "✗ ERROR: Failed to import SageAttention" && exit 1)

# ---- Custom nodes required by your workflow ----
WORKDIR /comfyui/custom_nodes

# Clone custom nodes with shallow history
RUN git clone --depth 1 https://github.com/Kijai/ComfyUI-KJNodes.git && \
    git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git && \
    git clone --depth 1 https://github.com/rgthree/rgthree-comfy.git && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    git clone --depth 1 https://github.com/Gourieff/comfyui-reactor-node.git && \
    git clone --depth 1 https://github.com/M1kep/ComfyLiterals.git

# Install python deps for custom nodes (with error tolerance)
RUN for dir in */; do \
        if [ -f "$dir/requirements.txt" ]; then \
            echo "Installing requirements for $dir"; \
            pip install --no-cache-dir -r "$dir/requirements.txt" || echo "Warning: Some deps failed for $dir"; \
        fi; \
    done

WORKDIR /comfyui
EXPOSE 8188

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8188/ || exit 1

CMD ["python", "-u", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
