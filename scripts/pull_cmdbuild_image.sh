#!/usr/bin/env bash
set -euo pipefail

# Pull the CMDBuild images (application and Ready2Use), retag them locally, and export filesystem snapshots.
# Optional environment variables:
#   AWS_PROFILE            : Used when terraform outputs need AWS access (default: Admin-AIOps)
#   CMDBUILD_IMAGE         : Override upstream CMDBuild app image (default: itmicus/cmdbuild:<tag>)
#   CMDBUILD_IMAGE_TAG     : Tag for the CMDBuild app image (default: terraform output cmdbuild_image_tag or "4.1.0")
#   CMDBUILD_R2U_IMAGE     : Override upstream Ready2Use image (default: itmicus/cmdbuild:<tag>)
#   CMDBUILD_R2U_IMAGE_TAG : Tag for the Ready2Use image (default: terraform output cmdbuild_r2u_image_tag or "r2u-2.4-4.1.0")
#   LOCAL_PREFIX           : Local Docker tag prefix (default: local)
#   LOCAL_IMAGE_DIR        : Directory to store exported filesystems (default: terraform output local_image_dir or ./images)
#   IMAGE_ARCH             : Platform passed to docker pull (default: terraform output image_architecture or linux/amd64)

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

if [ -z "${CMDBUILD_IMAGE_TAG:-}" ]; then
  CMDBUILD_IMAGE_TAG="$(tf_output_raw cmdbuild_image_tag || true)"
fi
CMDBUILD_IMAGE_TAG="${CMDBUILD_IMAGE_TAG:-4.1.0}"
if [ -z "${CMDBUILD_R2U_IMAGE_TAG:-}" ]; then
  CMDBUILD_R2U_IMAGE_TAG="$(tf_output_raw cmdbuild_r2u_image_tag || true)"
fi
CMDBUILD_R2U_IMAGE_TAG="${CMDBUILD_R2U_IMAGE_TAG:-r2u-2.4-4.1.0}"
if [ -z "${IMAGE_ARCH:-}" ]; then
  IMAGE_ARCH="$(tf_output_raw image_architecture || true)"
fi
IMAGE_ARCH="${IMAGE_ARCH:-linux/amd64}"
if [ -z "${LOCAL_IMAGE_DIR:-}" ]; then
  LOCAL_IMAGE_DIR="$(tf_output_raw local_image_dir || true)"
fi
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
CMDBUILD_IMAGE="${CMDBUILD_IMAGE:-itmicus/cmdbuild:${CMDBUILD_IMAGE_TAG}}"
CMDBUILD_R2U_IMAGE="${CMDBUILD_R2U_IMAGE:-itmicus/cmdbuild:${CMDBUILD_R2U_IMAGE_TAG}}"

pull_and_tag() {
  local name="$1" src="$2" dst="$3"
  echo "[${name}] Pulling ${src}..."
  docker pull --platform "${IMAGE_ARCH}" "${src}"
  echo "[${name}] Tagging ${src} as ${dst}"
  docker tag "${src}" "${dst}"
}

extract_fs() {
  local name="$1" tag="$2" outdir="$3"
  rm -rf "${outdir}"
  mkdir -p "${outdir}"
  local cid
  cid="$(docker create "${tag}")"
  echo "[${name}] Exporting filesystem of ${tag} into ${outdir}"
  docker export "${cid}" | "${TAR_BIN}" "${TAR_FLAGS[@]}" "${outdir}" -xf -
  docker rm "${cid}" >/dev/null
}

main() {
  mkdir -p "${LOCAL_IMAGE_DIR}"

  pull_and_tag "cmdbuild" "${CMDBUILD_IMAGE}" "${LOCAL_PREFIX}/cmdbuild:latest"
  extract_fs "cmdbuild" "${LOCAL_PREFIX}/cmdbuild:latest" "${LOCAL_IMAGE_DIR}/cmdbuild"

  pull_and_tag "cmdbuild-r2u" "${CMDBUILD_R2U_IMAGE}" "${LOCAL_PREFIX}/cmdbuild-r2u:latest"
  extract_fs "cmdbuild-r2u" "${LOCAL_PREFIX}/cmdbuild-r2u:latest" "${LOCAL_IMAGE_DIR}/cmdbuild-r2u"

  echo "[cmdbuild] Done. Local tags:"
  echo "  - ${LOCAL_PREFIX}/cmdbuild:latest"
  echo "  - ${LOCAL_PREFIX}/cmdbuild-r2u:latest"
}

main "$@"
