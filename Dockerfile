##############################
# Stage 1 — Build SageAttention wheel (needs nvcc)
##############################
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04 AS sage_build

ENV DEBIAN_FRONTEND=noninteractive
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

# Build for common NVIDIA arches incl. Ada (4090=sm_89) and Blackwell (5090 often sm_120)
ENV TORCH_CUDA_ARCH_LIST="89;90;120"

RUN set -eux; \
    apt-get update --allow-releaseinfo-change -o Acquire::Retries=5; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg \
      python3 python3-pip git \
      build-essential cmake ninja-build; \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --upgrade pip setuptools wheel

# IMPORTANT: cu128 stable wheels are not always present for every python/torch combo.
# Nightly cu128 is much more reliable for CUDA 12.8 images.
RUN python3 -m pip install --pre --index-url https://download.pytorch.org/whl/nightly/cu128 \
    torch torchvision torchaudio

# Sanity checks (so the log tells us immediately if torch/cuda is wrong)
RUN python3 - <<'PY'
import torch, os
print("torch:", torch.__version__)
print("cuda available:", torch.cuda.is_available())
print("cuda version:", torch.version.cuda)
print("CUDA_HOME:", os.environ.get("CUDA_HOME"))
PY

# Build SageAttention wheel (verbose output so failures are visible in RunPod logs)
RUN python3 -m pip wheel -v --no-build-isolation --no-deps \
    "git+https://github.com/thu-ml/SageAttention.git" -w /wheels
