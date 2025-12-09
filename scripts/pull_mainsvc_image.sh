#!/usr/bin/env bash
set -euo pipefail

# Pull the upstream main-svc image (nginx), retag it locally, and export the filesystem snapshot.
# This mirrors the n8n pull script so it can run independently.
#
# Optional environment variables:
#   AWS_PROFILE        : Used only when reading terraform outputs that call AWS (default: Admin-AIOps)
#   MAIN_SVC_IMAGE     : Override upstream image (default: nginx:<tag>)
#   MAIN_SVC_IMAGE_TAG : Version/tag for upstream image (default: terraform output main_svc_image_tag or "1.29.3")
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

if [ -z "${MAIN_SVC_IMAGE_TAG:-}" ]; then
  MAIN_SVC_IMAGE_TAG="$(tf_output_raw main_svc_image_tag || true)"
fi
MAIN_SVC_IMAGE_TAG="${MAIN_SVC_IMAGE_TAG:-1.29.3}"
if [ -z "${IMAGE_ARCH:-}" ]; then
  IMAGE_ARCH="$(tf_output_raw image_architecture)"
fi
IMAGE_ARCH="${IMAGE_ARCH:-linux/amd64}"
if [ -z "${LOCAL_IMAGE_DIR:-}" ]; then
  LOCAL_IMAGE_DIR="$(tf_output_raw local_image_dir)"
fi
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
MAIN_SVC_IMAGE="${MAIN_SVC_IMAGE:-nginx:${MAIN_SVC_IMAGE_TAG}}"

pull_and_tag() {
  local src="$1" dst="$2"
  echo "[main-svc] Pulling ${src}..."
  docker pull --platform "${IMAGE_ARCH}" "${src}"
  echo "[main-svc] Tagging ${src} as ${dst}"
  docker tag "${src}" "${dst}"
}

extract_fs() {
  local tag="$1" outdir="$2"
  rm -rf "${outdir}"
  mkdir -p "${outdir}"
  local cid
  cid="$(docker create "${tag}")"
  echo "[main-svc] Exporting filesystem of ${tag} into ${outdir}"
  docker export "${cid}" | tar -C "${outdir}" -xf -
  docker rm "${cid}" >/dev/null
}

main() {
  mkdir -p "${LOCAL_IMAGE_DIR}"
  pull_and_tag "${MAIN_SVC_IMAGE}" "${LOCAL_PREFIX}/main-svc:latest"
  extract_fs "${LOCAL_PREFIX}/main-svc:latest" "${LOCAL_IMAGE_DIR}/main-svc"
  echo "[main-svc] Done. Local tag: ${LOCAL_PREFIX}/main-svc:latest"
}

main "$@"
