FROM runpod/worker-comfyui:5.1.0-base

RUN pip install --no-cache-dir triton sageattention insightface onnxruntime-gpu

# Create a startup script that runs before ComfyUI
RUN echo '#!/bin/bash\n\
rm -rf /comfyui/models /comfyui/custom_nodes\n\
ln -s /runpod-volume/workspace/runpod-slim/ComfyUI/models /comfyui/models\n\
ln -s /runpod-volume/workspace/runpod-slim/ComfyUI/custom_nodes /comfyui/custom_nodes\n\
exec "$@"' > /start.sh && chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
CMD ["python", "-u", "/rp_handler.py"]
