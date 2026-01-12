FROM runpod/worker-comfyui:5.5.1-base

RUN pip install --no-cache-dir triton sageattention

RUN comfy node install --exit-on-fail comfyui_essentials --mode remote

WORKDIR /comfyui/custom_nodes
RUN git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git
RUN git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
RUN git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git
RUN git clone --depth 1 https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git
RUN git clone --depth 1 https://github.com/rgthree/rgthree-comfy.git
RUN git clone --depth 1 https://github.com/Gourieff/comfyui-reactor-node.git
RUN git clone --depth 1 https://github.com/kijai/ComfyUI-WanVideoWrapper.git

WORKDIR /comfyui

# Symlink models to network volume
RUN rm -rf /comfyui/models && \
    ln -s /runpod-volume/workspace/runpod-slim/ComfyUI/models /comfyui/models

RUN rm -rf /root/.cache/pip /tmp/*
