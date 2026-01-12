##############################
# Stage 1 — Build SageAttention
##############################
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04 AS sage_build
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    apt-get update --allow-releaseinfo-change \
      -o Acquire::Retries=5 \
      -o Acquire::http::Timeout="30" \
      -o Acquire::https::Timeout="30"; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg \
      python3 python3-pip git \
      build-essential cmake ninja-build; \
    rm -rf /var/lib/apt/lists/*


RUN python3 -m pip install --upgrade pip setuptools wheel

# Torch for CUDA 12.8 (required to compile SageAttention)
RUN python3 -m pip install --index-url https://download.pytorch.org/whl/cu128 \
    torch torchvision torchaudio

# Build SageAttention wheel
RUN python3 -m pip wheel --no-build-isolation --no-deps \
    "git+https://github.com/thu-ml/SageAttention.git" -w /wheels


##############################
# Stage 2 — Runtime Image
##############################
FROM runpod/worker-comfyui:5.1.0-base

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /comfyui

# Runtime OS deps
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install SageAttention (no compilation here)
COPY --from=sage_build /wheels /tmp/wheels
RUN python3 -m pip install /tmp/wheels/*.whl && rm -rf /tmp/wheels

##############################
# Custom Nodes (YOUR WORKFLOW)
##############################
WORKDIR /comfyui/custom_nodes

RUN git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git && \
    git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git && \
    git clone --depth 1 https://github.com/rgthree/rgthree-comfy.git && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    git clone --depth 1 https://github.com/Gourieff/ComfyUI-ReActor.git && \
    git clone --depth 1 https://github.com/M1kep/ComfyLiterals.git

# Install node Python deps
RUN python3 -m pip install --upgrade pip && \
    find . -name requirements.txt -exec python3 -m pip install -r {} \;

##############################
# Startup
##############################
WORKDIR /comfyui
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--use-sage-attention"]
