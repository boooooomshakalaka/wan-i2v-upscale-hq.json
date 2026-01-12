FROM runpod/worker-comfyui:5.1.0-base

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1

WORKDIR /comfyui

# Runtime deps (video + healthcheck + OpenCV safety)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ffmpeg \
    curl \
    libgl1-mesa-glx \
    libglib2.0-0 \
  && rm -rf /var/lib/apt/lists/*

# Custom nodes required by your workflow
WORKDIR /comfyui/custom_nodes
RUN git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git && \
    git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git && \
    git clone --depth 1 https://github.com/rgthree/rgthree-comfy.git && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    git clone --depth 1 https://github.com/Gourieff/ComfyUI-ReActor.git && \
    git clone --depth 1 https://github.com/M1kep/ComfyLiterals.git

RUN find . -name requirements.txt -exec pip install --no-cache-dir -r {} \;

# Startup script: install SageAttention when the worker actually has a GPU
WORKDIR /comfyui
RUN printf '%s\n' \
'#!/usr/bin/env bash' \
'set -euo pipefail' \
'' \
'echo "[startup] Checking for GPU..."' \
'if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then' \
'  echo "[startup] GPU detected. Installing SageAttention (best-effort)..."' \
'  pip install --no-cache-dir -U sageattention || true' \
'else' \
'  echo "[startup] No GPU detected (build/test environment). Skipping SageAttention install."' \
'fi' \
'' \
'exec python -u main.py --listen 0.0.0.0 --port 8188' \
> /start.sh && chmod +x /start.sh

EXPOSE 8188

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8188/ || exit 1

CMD ["/start.sh"]
