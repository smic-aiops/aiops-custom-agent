#!/usr/bin/env bash
set -euo pipefail

# Pull the Keycloak image, retag it locally, and export its filesystem.
# Environment overrides:
#   KEYCLOAK_IMAGE       : Full upstream image (default: docker.io/keycloak/keycloak:<tag>)
#   KEYCLOAK_IMAGE_TAG   : Tag/version to pull (default: terraform output keycloak_image_tag or 26.4.7)
#   LOCAL_PREFIX         : Local tag prefix (default: local)
#   LOCAL_IMAGE_DIR      : Directory to store exported filesystems (default: terraform output local_image_dir or ./images)
#   IMAGE_ARCH           : Platform passed to docker pull (default: terraform output image_architecture or linux/amd64)

tf_output_raw() {
  terraform output -lock=false -raw "$1" 2>/dev/null || true
}

TAR_BIN="$(command -v gtar || command -v tar)"
if echo "$("$TAR_BIN" --version 2>/dev/null)" | grep -qi "gnu"; then
  TAR_FLAGS=(--delay-directory-restore --no-same-owner --no-same-permissions -C)
else
  TAR_FLAGS=(-C)
fi

if [ -z "${KEYCLOAK_IMAGE_TAG:-}" ]; then
  KEYCLOAK_IMAGE_TAG="$(tf_output_raw keycloak_image_tag || true)"
fi
KEYCLOAK_IMAGE_TAG="${KEYCLOAK_IMAGE_TAG:-26.4.7}"
if [ -z "${IMAGE_ARCH:-}" ]; then
  IMAGE_ARCH="$(tf_output_raw image_architecture || true)"
fi
IMAGE_ARCH="${IMAGE_ARCH:-linux/amd64}"
if [ -z "${LOCAL_IMAGE_DIR:-}" ]; then
  LOCAL_IMAGE_DIR="$(tf_output_raw local_image_dir || true)"
fi
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
KEYCLOAK_IMAGE="${KEYCLOAK_IMAGE:-docker.io/keycloak/keycloak:${KEYCLOAK_IMAGE_TAG}}"

pull_and_tag() {
  local src="$1" dst="$2"
  echo "[keycloak] Pulling ${src}..."
  docker pull --platform "${IMAGE_ARCH}" "${src}"
  echo "[keycloak] Tagging ${src} as ${dst}"
  docker tag "${src}" "${dst}"
}

extract_fs() {
  local tag="$1" outdir="$2"
  rm -rf "${outdir}"
  mkdir -p "${outdir}"
  local cid
  cid="$(docker create "${tag}")"
  echo "[keycloak] Exporting filesystem of ${tag} into ${outdir}"
  docker export "${cid}" | "${TAR_BIN}" "${TAR_FLAGS[@]}" "${outdir}" -xf -
  docker rm "${cid}" >/dev/null
}

main() {
  mkdir -p "${LOCAL_IMAGE_DIR}"
  pull_and_tag "${KEYCLOAK_IMAGE}" "${LOCAL_PREFIX}/keycloak:latest"
  extract_fs "${LOCAL_PREFIX}/keycloak:latest" "${LOCAL_IMAGE_DIR}/keycloak"
  echo "[keycloak] Done. Local tag: ${LOCAL_PREFIX}/keycloak:latest"
}

main "$@"
