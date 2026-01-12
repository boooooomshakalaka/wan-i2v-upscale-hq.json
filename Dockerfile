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

# Improved startup script with caching
RUN printf '%s\n' \
'#!/usr/bin/env bash' \
'set -euo pipefail' \
'' \
'SAGE_MARKER="/tmp/.sageattention_installed"' \
'' \
'echo "[startup] Checking for GPU..."' \
'if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then' \
'  echo "[startup] ✓ GPU detected"' \
'  ' \
'  # Only install SageAttention if not already installed' \
'  if [ ! -f "$SAGE_MARKER" ]; then' \
'    echo "[startup] Installing SageAttention..."' \
'    if pip install --no-cache-dir -U sageattention 2>&1 | tee /tmp/sage_install.log; then' \
'      touch "$SAGE_MARKER"' \
'      echo "[startup] ✓ SageAttention installed successfully"' \
'    else' \
'      echo "[startup] ⚠ SageAttention install failed (workflow may still work)"' \
'      cat /tmp/sage_install.log' \
'    fi' \
'  else' \
'    echo "[startup] ✓ SageAttention already installed"' \
'  fi' \
'  ' \
'  # Verify installation' \
'  if python -c "import sageattention" 2>/dev/null; then' \
'    echo "[startup] ✓ SageAttention import successful"' \
'  else' \
'    echo "[startup] ⚠ SageAttention import failed"' \
'  fi' \
'else' \
'  echo "[startup] ⓘ No GPU detected (build/test environment)"' \
'  echo "[startup] ⓘ Skipping SageAttention install"' \
'fi' \
'' \
'echo "[startup] Starting ComfyUI..."' \
'exec python -u main.py --listen 0.0.0.0 --port 8188' \
> /start.sh && chmod +x /start.sh

EXPOSE 8188

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8188/ || exit 1

CMD ["/start.sh"]
