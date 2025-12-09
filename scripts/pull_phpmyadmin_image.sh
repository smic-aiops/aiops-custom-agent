#!/usr/bin/env bash
set -euo pipefail

# Pull the phpMyAdmin image, retag it locally, and export its filesystem.
# Environment overrides:
#   PHPMYADMIN_IMAGE     : Full upstream image (default: phpmyadmin:<tag>)
#   PHPMYADMIN_IMAGE_TAG : Tag/version to pull (default: 5.2.3 or terraform output phpmyadmin_image_tag)
#   LOCAL_PREFIX         : Local tag prefix (default: local)
#   LOCAL_IMAGE_DIR      : Directory to store exported filesystems (default: terraform output local_image_dir or ./images)
#   IMAGE_ARCH           : Platform passed to docker pull (default: terraform output image_architecture or linux/amd64)

if [ -z "${PHPMYADMIN_IMAGE_TAG:-}" ]; then
  PHPMYADMIN_IMAGE_TAG="$(terraform output -raw phpmyadmin_image_tag 2>/dev/null || echo "5.2.3")"
fi
if [ -z "${IMAGE_ARCH:-}" ]; then
  IMAGE_ARCH="$(terraform output -raw image_architecture 2>/dev/null || echo "linux/amd64")"
fi
if [ -z "${LOCAL_IMAGE_DIR:-}" ]; then
  LOCAL_IMAGE_DIR="$(terraform output -raw local_image_dir 2>/dev/null || true)"
fi
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
PHPMYADMIN_IMAGE="${PHPMYADMIN_IMAGE:-phpmyadmin:${PHPMYADMIN_IMAGE_TAG}}"

pull_and_tag() {
  local src="$1" dst="$2"
  echo "[phpmyadmin] Pulling ${src}..."
  docker pull --platform "${IMAGE_ARCH}" "${src}"
  echo "[phpmyadmin] Tagging ${src} as ${dst}"
  docker tag "${src}" "${dst}"
}

extract_fs() {
  local tag="$1" outdir="$2"
  mkdir -p "${outdir}"
  local cid
  cid="$(docker create "${tag}")"
  echo "[phpmyadmin] Exporting filesystem of ${tag} into ${outdir}"
  docker export "${cid}" | tar -C "${outdir}" -xf -
  docker rm "${cid}" >/dev/null
}

main() {
  mkdir -p "${LOCAL_IMAGE_DIR}"
  pull_and_tag "${PHPMYADMIN_IMAGE}" "${LOCAL_PREFIX}/phpmyadmin:latest"
  extract_fs "${LOCAL_PREFIX}/phpmyadmin:latest" "${LOCAL_IMAGE_DIR}/phpmyadmin"
  echo "[phpmyadmin] Done. Local tag: ${LOCAL_PREFIX}/phpmyadmin:latest"
}

main "$@"
