```dockerfile
FROM runpod/worker-comfyui:5.1.0-base

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /comfyui

# OS deps (video + common OpenCV runtime libs)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
  && rm -rf /var/lib/apt/lists/*

# Pip tools
RUN python3 -m pip install --upgrade pip setuptools wheel

# SageAttention (best-effort; won't fail the build if it can't install)
RUN python3 -m pip install -U sageattention || true

# Custom nodes (your workflow)
WORKDIR /comfyui/custom_nodes
RUN git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git && \
    git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git && \
    git clone --depth 1 https://github.com/rgthree/rgthree-comfy.git && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    git clone --depth 1 https://github.com/Gourieff/ComfyUI-ReActor.git && \
    git clone --depth 1 https://github.com/M1kep/ComfyLiterals.git

# Install python deps for nodes that provide requirements.txt
RUN find . -name requirements.txt -exec python3 -m pip install -r {} \;

# Start ComfyUI
WORKDIR /comfyui
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
```
