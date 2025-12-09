#!/usr/bin/env bash
set -euo pipefail

# Pull the Exastro IT Automation web server image, retag it locally, and export its filesystem.
# Environment overrides:
#   AWS_PROFILE                 : Used when terraform outputs need AWS access (default: Admin-AIOps)
#   EXASTRO_WEB_SERVER_IMAGE    : Full upstream image (default: terraform output exastro_it_automation_web_server_image_tag or exastro/exastro-it-automation-web-server:2.7.0)
#   LOCAL_PREFIX                : Local tag prefix (default: local)
#   LOCAL_IMAGE_DIR             : Directory to store exported filesystems (default: terraform output local_image_dir or ./images)
#   IMAGE_ARCH                  : Platform passed to docker pull (default: terraform output image_architecture or linux/amd64)

tf_output_raw() {
  terraform output -lock=false -raw "$1" 2>/dev/null || true
}

TAR_BIN="$(command -v gtar || command -v tar)"
if echo "$("$TAR_BIN" --version 2>/dev/null)" | grep -qi "gnu"; then
  TAR_FLAGS=(--delay-directory-restore --no-same-owner --no-same-permissions -C)
else
  TAR_FLAGS=(-C)
fi

if [ -z "${AWS_PROFILE:-}" ]; then
  AWS_PROFILE="$(tf_output_raw aws_profile)"
fi
AWS_PROFILE="${AWS_PROFILE:-Admin-AIOps}"
export AWS_PROFILE

if [ -z "${EXASTRO_WEB_SERVER_IMAGE:-}" ]; then
  EXASTRO_WEB_SERVER_IMAGE="$(tf_output_raw exastro_it_automation_web_server_image_tag || true)"
fi
EXASTRO_WEB_SERVER_IMAGE="${EXASTRO_WEB_SERVER_IMAGE:-exastro/exastro-it-automation-web-server:2.7.0}"
if [ -z "${IMAGE_ARCH:-}" ]; then
  IMAGE_ARCH="$(tf_output_raw image_architecture || true)"
fi
IMAGE_ARCH="${IMAGE_ARCH:-linux/amd64}"
if [ -z "${LOCAL_IMAGE_DIR:-}" ]; then
  LOCAL_IMAGE_DIR="$(tf_output_raw local_image_dir || true)"
fi
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"

pull_and_tag() {
  local src="$1" dst="$2"
  echo "[exastro-web] Pulling ${src} (${IMAGE_ARCH})..."
  docker pull --platform "${IMAGE_ARCH}" "${src}"
  echo "[exastro-web] Tagging ${src} as ${dst}"
  docker tag "${src}" "${dst}"
}

extract_fs() {
  local tag="$1" outdir="$2"
  rm -rf "${outdir}"
  mkdir -p "${outdir}"
  local cid
  cid="$(docker create "${tag}")"
  echo "[exastro-web] Exporting filesystem of ${tag} into ${outdir}"
  docker export "${cid}" | "${TAR_BIN}" "${TAR_FLAGS[@]}" "${outdir}" -xf -
  docker rm "${cid}" >/dev/null
}

main() {
  mkdir -p "${LOCAL_IMAGE_DIR}"
  pull_and_tag "${EXASTRO_WEB_SERVER_IMAGE}" "${LOCAL_PREFIX}/exastro-web:latest"
  extract_fs "${LOCAL_PREFIX}/exastro-web:latest" "${LOCAL_IMAGE_DIR}/exastro-web"
  echo "[exastro-web] Done. Local tag: ${LOCAL_PREFIX}/exastro-web:latest"
}

main "$@"
