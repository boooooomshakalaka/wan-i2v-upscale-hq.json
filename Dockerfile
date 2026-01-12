# ✅ MUST have a base image
FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

ARG COMFYUI_DIR=/comfyui
WORKDIR ${COMFYUI_DIR}

# Basic runtime + build tooling for CUDA extensions (SageAttention)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip \
    git \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    build-essential \
    cmake \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --upgrade pip setuptools wheel

# --- Install ComfyUI itself (if your base image doesn't already include it) ---
# If your base image already has ComfyUI, REMOVE this block.
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git ${COMFYUI_DIR}

# ---- Install Torch (you may need to pin this to your chosen CUDA build) ----
# If your base image already has torch with CUDA, REMOVE this block.
RUN python3 -m pip install --index-url https://download.pytorch.org/whl/cu121 torch torchvision torchaudio

# ---- SageAttention (builds CUDA extension) ----
RUN python3 -m pip install -U "git+https://github.com/thu-ml/SageAttention.git"

# ---- Custom nodes used by your workflow ----
WORKDIR ${COMFYUI_DIR}/custom_nodes
RUN git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git comfyui-kjnodes && \
    git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git comfyui-easy-use && \
    git clone --depth 1 https://github.com/rgthree/rgthree-comfy.git rgthree-comfy && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git comfyui-videohelpersuite && \
    git clone --depth 1 https://github.com/Gourieff/ComfyUI-ReActor.git comfyui-reactor && \
    git clone --depth 1 https://github.com/M1kep/ComfyLiterals.git ComfyLiterals

RUN find . -maxdepth 2 -name requirements.txt -print -exec python3 -m pip install -r {} \;

# Default command (adjust to your serverless entrypoint/handler if needed)
WORKDIR ${COMFYUI_DIR}
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--use-sage-attention"]
