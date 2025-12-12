#!/usr/bin/env bash
set -euo pipefail

## Pull helper for shinsenter/sulu images used as the sulu service base.
## This is mostly useful for caching the upstream image so builds that rely on it can fall back to a local tag.
##
## Optional environment variables:
##   AWS_PROFILE        : Used only when reading terraform outputs that call AWS (default: Admin-AIOps)
##   SULU_IMAGE_TAG     : Tag for shinsenter/sulu (default: terraform output sulu_image_tag or "php8.4")
##   SULU_IMAGE         : Override upstream image (default: shinsenter/sulu:<tag>)
##   LOCAL_PREFIX       : Local Docker tag prefix (default: local)
##   LOCAL_IMAGE_DIR    : Directory to store exported filesystems (default: terraform output local_image_dir or ./images)
##   IMAGE_ARCH         : Platform passed to docker pull (default: terraform output image_architecture or linux/amd64)

tf_output_raw() {
  terraform output -lock=false -raw "$1" 2>/dev/null || true
}

if [ -z "${AWS_PROFILE:-}" ]; then
  AWS_PROFILE="$(tf_output_raw aws_profile)"
fi
AWS_PROFILE="${AWS_PROFILE:-Admin-AIOps}"
export AWS_PROFILE

if [ -z "${SULU_IMAGE_TAG:-}" ]; then
  SULU_IMAGE_TAG="$(tf_output_raw sulu_image_tag || true)"
fi
SULU_IMAGE_TAG="${SULU_IMAGE_TAG:-php8.4}"
if [ -z "${IMAGE_ARCH:-}" ]; then
  IMAGE_ARCH="$(tf_output_raw image_architecture)"
fi
IMAGE_ARCH="${IMAGE_ARCH:-linux/amd64}"
if [ -z "${LOCAL_IMAGE_DIR:-}" ]; then
  LOCAL_IMAGE_DIR="$(tf_output_raw local_image_dir)"
fi
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
SULU_IMAGE="${SULU_IMAGE:-shinsenter/sulu:${SULU_IMAGE_TAG}}"

pull_and_tag() {
  local src="$1" dst="$2"
  echo "[sulu] Pulling ${src}..."
  docker pull --platform "${IMAGE_ARCH}" "${src}"
  echo "[sulu] Tagging ${src} as ${dst}"
  docker tag "${src}" "${dst}"
}

extract_fs() {
  local tag="$1" outdir="$2"
  rm -rf "${outdir}"
  mkdir -p "${outdir}"
  local cid
  cid="$(docker create "${tag}")"
  echo "[sulu] Exporting filesystem of ${tag} into ${outdir}"
  docker export "${cid}" | tar -C "${outdir}" -xf -
  docker rm "${cid}" >/dev/null
}

main() {
  mkdir -p "${LOCAL_IMAGE_DIR}"
  pull_and_tag "${SULU_IMAGE}" "${LOCAL_PREFIX}/sulu:latest"
  extract_fs "${LOCAL_PREFIX}/sulu:latest" "${LOCAL_IMAGE_DIR}/sulu"
  echo "[sulu] Done. Local tag: ${LOCAL_PREFIX}/sulu:latest"
}

main "$@"
