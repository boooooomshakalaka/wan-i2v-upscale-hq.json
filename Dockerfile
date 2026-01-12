FROM runpod/worker-comfyui:5.1.0-base

# Install Python dependencies that custom nodes need
RUN pip install --no-cache-dir \
    triton \
    sageattention \
    insightface \
    onnxruntime-gpu \
    opencv-python \
    scikit-image

# Create startup script properly
COPY <<EOF /start.sh
#!/bin/bash
rm -rf /comfyui/models /comfyui/custom_nodes 2>/dev/null || true
ln -sf /runpod-volume/workspace/runpod-slim/ComfyUI/models /comfyui/models
ln -sf /runpod-volume/workspace/runpod-slim/ComfyUI/custom_nodes /comfyui/custom_nodes
exec python -u /rp_handler.py
EOF

RUN chmod +x /start.sh

CMD ["/start.sh"]
