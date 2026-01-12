# ---- Custom nodes + SageAttention ----
ARG COMFYUI_DIR=/comfyui
WORKDIR ${COMFYUI_DIR}

# OS deps: video + common runtime libs + build toolchain for CUDA extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    build-essential \
    cmake \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# (Optional but often helpful) ensure pip tooling is up to date
RUN python3 -m pip install --upgrade pip setuptools wheel

# ---- Install SageAttention (builds CUDA extension) ----
# Builds against the torch/cuda in your image.
# Official repo: thu-ml/SageAttention
RUN python3 -m pip install -U "git+https://github.com/thu-ml/SageAttention.git"  \
    && python3 -m pip show sageattention || true

# ---- Custom nodes used by your workflow ----
WORKDIR ${COMFYUI_DIR}/custom_nodes
RUN git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git comfyui-kjnodes && \
    git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git comfyui-easy-use && \
    git clone --depth 1 https://github.com/rgthree/rgthree-comfy.git rgthree-comfy && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git comfyui-videohelpersuite && \
    git clone --depth 1 https://github.com/Gourieff/ComfyUI-ReActor.git comfyui-reactor && \
    git clone --depth 1 https://github.com/M1kep/ComfyLiterals.git ComfyLiterals

# Install python requirements for nodes that provide requirements.txt
RUN find . -maxdepth 2 -name requirements.txt -print -exec python3 -m pip install -r {} \;
