# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.5.1-base

# Install SageAttention dependencies (small, fast)
RUN pip install --no-cache-dir triton sageattention

# Install registry custom nodes
RUN comfy node install --exit-on-fail comfyui_essentials --mode remote

# Install custom nodes (code only, no large files)
WORKDIR /comfyui/custom_nodes

RUN git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git
RUN git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
RUN git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git
RUN git clone --depth 1 https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git
RUN git clone --depth 1 https://github.com/rgthree/rgthree-comfy.git
RUN git clone --depth 1 https://github.com/Gourieff/comfyui-reactor-node.git
RUN git clone --depth 1 https://github.com/kijai/ComfyUI-WanVideoWrapper.git

# Install node dependencies (with cache cleanup)
RUN pip install --no-cache-dir insightface onnxruntime-gpu || true

# Clean up to reduce image size
RUN rm -rf /root/.cache/pip /tmp/*

WORKDIR /comfyui

# NO MODEL DOWNLOADS HERE - use network volume instead
