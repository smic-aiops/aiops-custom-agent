#!/usr/bin/env bash
set -euo pipefail

# Pull the pgAdmin image, retag it locally, and export its filesystem.
# Environment overrides:
#   PGADMIN_IMAGE       : Full upstream image (default: hdpage/pgadmin4:<tag>)
#   PGADMIN_IMAGE_TAG   : Tag/version to pull (default: 9.10.0 or terraform output pgadmin_image_tag)
#   LOCAL_PREFIX        : Local tag prefix (default: local)
#   LOCAL_IMAGE_DIR     : Directory to store exported filesystems (default: terraform output local_image_dir or ./images)
#   IMAGE_ARCH          : Platform passed to docker pull (default: terraform output image_architecture or linux/amd64)

if [ -z "${PGADMIN_IMAGE_TAG:-}" ]; then
  PGADMIN_IMAGE_TAG="$(terraform output -raw pgadmin_image_tag 2>/dev/null || echo "9.10.0")"
fi
if [ -z "${IMAGE_ARCH:-}" ]; then
  IMAGE_ARCH="$(terraform output -raw image_architecture 2>/dev/null || echo "linux/amd64")"
fi
if [ -z "${LOCAL_IMAGE_DIR:-}" ]; then
  LOCAL_IMAGE_DIR="$(terraform output -raw local_image_dir 2>/dev/null || true)"
fi
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
# Official pgAdmin image on Docker Hub
PGADMIN_IMAGE="${PGADMIN_IMAGE:-dpage/pgadmin4:${PGADMIN_IMAGE_TAG}}"

pull_and_tag() {
  local src="$1" dst="$2"
  echo "[pgadmin] Pulling ${src}..."
  docker pull --platform "${IMAGE_ARCH}" "${src}"
  echo "[pgadmin] Tagging ${src} as ${dst}"
  docker tag "${src}" "${dst}"
}

extract_fs() {
  local tag="$1" outdir="$2"
  mkdir -p "${outdir}"
  local cid
  cid="$(docker create "${tag}")"
  echo "[pgadmin] Exporting filesystem of ${tag} into ${outdir}"
  docker export "${cid}" | tar -C "${outdir}" -xf -
  docker rm "${cid}" >/dev/null
}

main() {
  mkdir -p "${LOCAL_IMAGE_DIR}"
  pull_and_tag "${PGADMIN_IMAGE}" "${LOCAL_PREFIX}/pgadmin:latest"
  extract_fs "${LOCAL_PREFIX}/pgadmin:latest" "${LOCAL_IMAGE_DIR}/pgadmin"
  echo "[pgadmin] Done. Local tag: ${LOCAL_PREFIX}/pgadmin:latest"
}

main "$@"
