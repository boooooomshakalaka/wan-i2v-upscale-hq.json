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
    git clone --depth 1 https://github.com/Gourieff/comfyui-reactor-node.git && \
    git clone --depth 1 https://github.com/M1kep/ComfyLiterals.git

# Install custom node dependencies
RUN find . -name requirements.txt -exec pip install --no-cache-dir -r {} \;

WORKDIR /comfyui

# Advanced startup script with network storage support
RUN printf '%s\n' \
'#!/usr/bin/env bash' \
'set -euo pipefail' \
'' \
'# Marker files for installation tracking' \
'SAGE_MARKER_LOCAL="/tmp/.sageattention_installed"' \
'SAGE_MARKER_NETWORK="/workspace/.sageattention_installed"' \
'' \
'echo "========================================="' \
'echo " ComfyUI Serverless Startup"' \
'echo "========================================="' \
'' \
'# Check for GPU' \
'echo "[startup] Checking for GPU..."' \
'if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then' \
'  GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)' \
'  echo "[startup] ✓ GPU detected: $GPU_NAME"' \
'  ' \
'  # Determine which marker to use' \
'  if [ -d "/workspace" ] && [ -w "/workspace" ]; then' \
'    echo "[startup] ✓ Network storage available at /workspace"' \
'    SAGE_MARKER="$SAGE_MARKER_NETWORK"' \
'  else' \
'    echo "[startup] ⓘ Using local storage for cache"' \
'    SAGE_MARKER="$SAGE_MARKER_LOCAL"' \
'  fi' \
'  ' \
'  # Install SageAttention if needed' \
'  if [ ! -f "$SAGE_MARKER" ]; then' \
'    echo "[startup] Installing SageAttention..."' \
'    START_TIME=$(date +%s)' \
'    ' \
'    if pip install --no-cache-dir sageattention 2>&1 | tee /tmp/sage_install.log; then' \
'      touch "$SAGE_MARKER"' \
'      END_TIME=$(date +%s)' \
'      DURATION=$((END_TIME - START_TIME))' \
'      echo "[startup] ✓ SageAttention installed in ${DURATION}s"' \
'    else' \
'      echo "[startup] ⚠ SageAttention install failed"' \
'      echo "[startup] ⚠ Check logs: /tmp/sage_install.log"' \
'      echo "[startup] ⓘ ComfyUI will start anyway (some nodes may not work)"' \
'    fi' \
'  else' \
'    echo "[startup] ✓ SageAttention already installed (cached)"' \
'  fi' \
'  ' \
'  # Verify installation' \
'  if python -c "import sageattention; print(\"  Version:\", sageattention.__version__)" 2>/dev/null; then' \
'    echo "[startup] ✓ SageAttention import successful"' \
'  else' \
'    echo "[startup] ⚠ SageAttention import failed"' \
'  fi' \
'else' \
'  echo "[startup] ⓘ No GPU detected"' \
'  echo "[startup] ⓘ This is normal for build/test environments"' \
'  echo "[startup] ⓘ SageAttention will be installed on first GPU run"' \
'fi' \
'' \
'echo "========================================="' \
'echo " Starting ComfyUI on port 8188"' \
'echo "========================================="' \
'exec python -u main.py --listen 0.0.0.0 --port 8188' \
> /start.sh && chmod +x /start.sh

EXPOSE 8188

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8188/ || exit 1

CMD ["/start.sh"]
