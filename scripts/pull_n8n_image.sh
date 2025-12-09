#!/usr/bin/env bash
set -euo pipefail

# Pull the upstream n8n image, retag it locally, and extract the filesystem snapshot.
# This script mirrors the n8n portion of pull_local_images.sh so it can be run independently.
#
# Optional environment variables:
#   AWS_PROFILE        : Used only when reading terraform outputs that call AWS (default: Admin-AIOps)
#   N8N_IMAGE          : Override upstream image (default: n8nio/n8n:<tag>)
#   N8N_IMAGE_TAG      : Version/tag for upstream image (default: terraform output n8n_image_tag or "latest")
#   LOCAL_PREFIX       : Local Docker tag prefix (default: local)
#   LOCAL_IMAGE_DIR    : Directory to store exported filesystems (default: terraform output local_image_dir or ./images)
#   IMAGE_ARCH         : Platform passed to docker pull (default: terraform output image_architecture or linux/amd64)

tf_output_raw() {
  terraform output -lock=false -raw "$1" 2>/dev/null || true
}

if [ -z "${AWS_PROFILE:-}" ]; then
  AWS_PROFILE="$(tf_output_raw aws_profile)"
fi
AWS_PROFILE="${AWS_PROFILE:-Admin-AIOps}"
export AWS_PROFILE

if [ -z "${N8N_IMAGE_TAG:-}" ]; then
  N8N_IMAGE_TAG="$(tf_output_raw n8n_image_tag || true)"
fi
N8N_IMAGE_TAG="${N8N_IMAGE_TAG:-latest}"
if [ -z "${IMAGE_ARCH:-}" ]; then
  IMAGE_ARCH="$(tf_output_raw image_architecture)"
fi
IMAGE_ARCH="${IMAGE_ARCH:-linux/amd64}"
if [ -z "${LOCAL_IMAGE_DIR:-}" ]; then
  LOCAL_IMAGE_DIR="$(tf_output_raw local_image_dir)"
fi
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
N8N_IMAGE="${N8N_IMAGE:-n8nio/n8n:${N8N_IMAGE_TAG}}"

pull_and_tag() {
  local src="$1" dst="$2"
  echo "[n8n] Pulling ${src}..."
  docker pull --platform "${IMAGE_ARCH}" "${src}"
  echo "[n8n] Tagging ${src} as ${dst}"
  docker tag "${src}" "${dst}"
}

extract_fs() {
  local tag="$1" outdir="$2"
  mkdir -p "${outdir}"
  local cid
  cid="$(docker create "${tag}")"
  echo "[n8n] Exporting filesystem of ${tag} into ${outdir}"
  docker export "${cid}" | tar -C "${outdir}" -xf -
  docker rm "${cid}" >/dev/null
}

main() {
  mkdir -p "${LOCAL_IMAGE_DIR}"
  pull_and_tag "${N8N_IMAGE}" "${LOCAL_PREFIX}/n8n:latest"
  extract_fs "${LOCAL_PREFIX}/n8n:latest" "${LOCAL_IMAGE_DIR}/n8n"
  mkdir -p docker/n8n
  cat > docker/n8n/Dockerfile <<EOF
ARG BASE_IMAGE=${N8N_IMAGE}
FROM \${BASE_IMAGE}

USER root
RUN set -eux; \
    if command -v apk >/dev/null 2>&1; then \
      apk add --no-cache postgresql15-client; \
    elif command -v apt-get >/dev/null 2>&1; then \
      apt-get update; \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends postgresql-client; \
      rm -rf /var/lib/apt/lists/*; \
    elif command -v yum >/dev/null 2>&1; then \
      yum install -y postgresql; \
      yum clean all; \
    else \
      echo "No supported package manager found to install psql" >&2; \
      exit 1; \
    fi

# Drop privileges back to the n8n user
USER 1000:1000
EOF
  echo "[n8n] Wrote docker/n8n/Dockerfile based on ${N8N_IMAGE}"
  echo "[n8n] Done. Local tag: ${LOCAL_PREFIX}/n8n:latest"
}

main "$@"
