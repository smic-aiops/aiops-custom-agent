#!/usr/bin/env bash
set -euo pipefail

# Pull the Zulip image, retag it locally, and export its filesystem for local caching.
# Environment overrides:
#   ZULIP_IMAGE       : Full upstream image (default: zulip/docker-zulip:<tag>)
#   ZULIP_IMAGE_TAG   : Tag/version to pull (default: terraform output zulip_image_tag or "11.4-0")
#   LOCAL_PREFIX      : Local tag prefix (default: local)
#   LOCAL_IMAGE_DIR   : Directory to store exported filesystems (default: terraform output local_image_dir or ./images)
#   IMAGE_ARCH        : Platform passed to docker pull (default: terraform output image_architecture or linux/amd64)

if [ -z "${ZULIP_IMAGE_TAG:-}" ]; then
  ZULIP_IMAGE_TAG="$(terraform output -raw zulip_image_tag 2>/dev/null || echo "11.4-0")"
fi
if [ -z "${IMAGE_ARCH:-}" ]; then
  IMAGE_ARCH="$(terraform output -raw image_architecture 2>/dev/null || echo "linux/amd64")"
fi
if [ -z "${LOCAL_IMAGE_DIR:-}" ]; then
  LOCAL_IMAGE_DIR="$(terraform output -raw local_image_dir 2>/dev/null || true)"
fi
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
ZULIP_IMAGE="${ZULIP_IMAGE:-zulip/docker-zulip:${ZULIP_IMAGE_TAG}}"

pull_and_tag() {
  local src="$1" dst="$2"
  echo "[zulip] Pulling ${src}..."
  docker pull --platform "${IMAGE_ARCH}" "${src}"
  echo "[zulip] Tagging ${src} as ${dst}"
  docker tag "${src}" "${dst}"
}

extract_fs() {
  local tag="$1" outdir="$2"
  mkdir -p "${outdir}"
  local cid
  cid="$(docker create "${tag}")"
  echo "[zulip] Exporting filesystem of ${tag} into ${outdir}"
  docker export "${cid}" | tar -C "${outdir}" -xf -
  docker rm "${cid}" >/dev/null
}

main() {
  mkdir -p "${LOCAL_IMAGE_DIR}"
  pull_and_tag "${ZULIP_IMAGE}" "${LOCAL_PREFIX}/zulip:latest"
  extract_fs "${LOCAL_PREFIX}/zulip:latest" "${LOCAL_IMAGE_DIR}/zulip"
  echo "[zulip] Done. Local tag: ${LOCAL_PREFIX}/zulip:latest"
}

main "$@"
