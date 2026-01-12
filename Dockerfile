FROM runpod/worker-comfyui:5.1.0-base

RUN pip install --no-cache-dir triton sageattention insightface onnxruntime-gpu

# Symlink to your existing network volume setup
RUN rm -rf /comfyui/models /comfyui/custom_nodes && \
    ln -s /runpod-volume/workspace/runpod-slim/ComfyUI/models /comfyui/models && \
    ln -s /runpod-volume/workspace/runpod-slim/ComfyUI/custom_nodes /comfyui/custom_nodes
