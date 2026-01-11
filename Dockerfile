# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.5.1-base

# Install SageAttention dependencies
RUN pip install triton sageattention

# install custom nodes into comfyui (first node with --mode remote to fetch updated cache)
RUN comfy node install --exit-on-fail comfyui_essentials --mode remote

# Install custom nodes that were in unknown_registry
RUN cd /comfyui/custom_nodes && \
    # KJNodes - provides PatchSageAttentionKJ
    git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    # VideoHelperSuite - provides VHS_VideoCombine
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    # Easy-Use - provides easy mathInt, easy int, easy seed, easy clearCacheAll, easy cleanGpuUsed, etc.
    git clone https://github.com/yolain/ComfyUI-Easy-Use.git && \
    # Frame-Interpolation - provides RIFE VFI
    git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git && \
    # rgthree-comfy - provides Power Lora Loader (rgthree)
    git clone https://github.com/rgthree/rgthree-comfy.git && \
    # ReActor - provides ReActorRestoreFace
    git clone https://github.com/Gourieff/comfyui-reactor-node.git && \
    # ComfyUI-WD14-Tagger or other WAN nodes if needed
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git

# Install dependencies for custom nodes
RUN cd /comfyui/custom_nodes/ComfyUI-Frame-Interpolation && pip install -r requirements.txt || true
RUN cd /comfyui/custom_nodes/comfyui-reactor-node && pip install -r requirements.txt || true
RUN cd /comfyui/custom_nodes/ComfyUI-Easy-Use && pip install -r requirements.txt || true
RUN cd /comfyui/custom_nodes/ComfyUI-KJNodes && pip install -r requirements.txt || true

# download models into comfyui
RUN comfy model download --url https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors --relative-path models/diffusion_models --filename wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors
RUN comfy model download --url https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors --relative-path models/diffusion_models --filename wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors
RUN comfy model download --url https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors --relative-path models/text_encoders --filename umt5_xxl_fp8_e4m3fn_scaled.safetensors
RUN comfy model download --url https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors --relative-path models/vae --filename wan_2.1_vae.safetensors
RUN comfy model download --url https://huggingface.co/jasonot/mycomfyui/blob/main/rife47.pth --relative-path models/checkpoints --filename rife47.pth
RUN comfy model download --url https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.1/RealESRGAN_x2plus.pth --relative-path models/upscale_models --filename RealESRGAN_x2plus.pth
RUN comfy model download --url https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/model.safetensors --relative-path models/clip_vision --filename clip-vit-large-patch14.safetensors
# RUN # Could not find URL for Wan\Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1-low_noise.safetensors
# RUN # Could not find URL for Wan\Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1-high_noise.safetensors
RUN comfy model download --url https://github.com/TencentARC/GFPGAN/releases/download/v1.3.0/GFPGANv1.4.pth --relative-path models/facerestore_models --filename GFPGANv1.4.pth

# Download face restore models for ReActor
RUN mkdir -p /comfyui/models/facerestore_models && \
    wget -q https://github.com/sczhou/CodeFormer/releases/download/v0.1.0/codeformer.pth -O /comfyui/models/facerestore_models/codeformer-v0.1.0.pth || true

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/