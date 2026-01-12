# ---- Custom nodes for your workflow ----
# Expect ComfyUI already present in the image.
ARG COMFYUI_DIR=/comfyui
WORKDIR ${COMFYUI_DIR}

# System deps often needed (video + general build)
# (If your base image is not Debian/Ubuntu, adjust package manager.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Put node repos here
WORKDIR ${COMFYUI_DIR}/custom_nodes

# Clone the node packs used by your workflow
RUN git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git comfyui-kjnodes && \
    git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git comfyui-easy-use && \
    git clone --depth 1 https://github.com/rgthree/rgthree-comfy.git rgthree-comfy && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git comfyui-videohelpersuite && \
    git clone --depth 1 https://github.com/Gourieff/ComfyUI-ReActor.git comfyui-reactor && \
    git clone --depth 1 https://github.com/M1kep/ComfyLiterals.git ComfyLiterals

# Install python requirements for every custom node repo that provides one
# (Robust: doesn't fail if a repo has no requirements.txt)
RUN python3 -m pip install --upgrade pip && \
    find . -maxdepth 2 -name requirements.txt -print -exec python3 -m pip install -r {} \;

# Optional: if your base image is slim, these help avoid runtime surprises
# RUN python3 -m pip install -U setuptools wheel
