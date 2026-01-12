# -------------------------
# Stage 1: build SageAttention wheel (needs nvcc)
# -------------------------
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04 AS sage_build

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip git \
    build-essential cmake ninja-build \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --upgrade pip setuptools wheel

# Install torch that matches CUDA 12.8 (pick the cu128 wheel index)
# If your base image already has torch, you can remove this block.
RUN python3 -m pip install --index-url https://download.pytorch.org/whl/cu128 \
    torch torchvision torchaudio

# Build wheel (disable build isolation to ensure it sees torch + CUDA)
RUN python3 -m pip wheel --no-build-isolation --no-deps \
    "git+https://github.com/thu-ml/SageAttention.git" -w /wheels


# -------------------------
# Stage 2: your actual ComfyUI runtime image
# -------------------------
FROM <YOUR_EXISTING_BASE_IMAGE>

ARG COMFYUI_DIR=/comfyui

# Install runtime deps (ffmpeg etc.) + python build tools not needed here
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ffmpeg libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Make sure pip is sane
RUN python3 -m pip install --upgrade pip

# Install SageAttention from the prebuilt wheel (no compilation here)
COPY --from=sage_build /wheels /tmp/wheels
RUN python3 -m pip install /tmp/wheels/*.whl && rm -rf /tmp/wheels

# ---- then your custom nodes (same as before) ----
WORKDIR ${COMFYUI_DIR}/custom_nodes
RUN git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git comfyui-kjnodes && \
    git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git comfyui-easy-use && \
    git clone --depth 1 https://github.com/rgthree/rgthree-comfy.git rgthree-comfy && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git comfyui-videohelpersuite && \
    git clone --depth 1 https://github.com/Gourieff/ComfyUI-ReActor.git comfyui-reactor && \
    git clone --depth 1 https://github.com/M1kep/ComfyLiterals.git ComfyLiterals

RUN find . -maxdepth 2 -name requirements.txt -print -exec python3 -m pip install -r {} \;
