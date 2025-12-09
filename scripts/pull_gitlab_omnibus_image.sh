#!/usr/bin/env bash
set -euo pipefail

# Pull the upstream GitLab Omnibus image (17.11.7-ce.0 by default), tag it locally, and export the filesystem snapshot.
# Mirrors pull_n8n_image.sh for standalone usage.
#
# Optional environment variables:
#   AWS_PROFILE           : Default profile for Terraform/AWS reads (Admin-AIOps)
#   GITLAB_OMNIBUS_IMAGE  : Override upstream image (default gitlab/gitlab-ee:<tag>)
#   GITLAB_OMNIBUS_TAG    : Version tag (default 17.11.7-ce.0)
#   LOCAL_PREFIX          : Local tag prefix (default local)
#   LOCAL_IMAGE_DIR       : Directory for exported filesystems (default terraform local_image_dir or ./images)
#   IMAGE_ARCH            : Platform to pull (default terraform image_architecture or linux/amd64)

tf_output_raw() {
  terraform output -lock=false -raw "$1" 2>/dev/null || true
}

TAR_BIN="$(command -v gtar || command -v tar)"
if echo "$("$TAR_BIN" --version 2>/dev/null)" | grep -qi "gnu"; then
  TAR_FLAGS=(--delay-directory-restore --no-same-owner --no-same-permissions -C)
  SKIP_EXTRACT=0
else
  TAR_FLAGS=(-C)
  SKIP_EXTRACT=1
fi

if [[ -z "${AWS_PROFILE:-}" ]]; then
  AWS_PROFILE="$(tf_output_raw aws_profile)"
fi
AWS_PROFILE="${AWS_PROFILE:-Admin-AIOps}"
export AWS_PROFILE

GITLAB_OMNIBUS_TAG="${GITLAB_OMNIBUS_TAG:-$(tf_output_raw gitlab_omnibus_image_tag)}"
GITLAB_OMNIBUS_TAG="${GITLAB_OMNIBUS_TAG:-17.11.7-ce.0}"
IMAGE_ARCH="${IMAGE_ARCH:-$(tf_output_raw image_architecture)}"
IMAGE_ARCH="${IMAGE_ARCH:-linux/amd64}"
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-$(tf_output_raw local_image_dir)}"
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
GITLAB_OMNIBUS_IMAGE="${GITLAB_OMNIBUS_IMAGE:-gitlab/gitlab-ce:${GITLAB_OMNIBUS_TAG}}"

pull_and_tag() {
  local src="$1" dst="$2"
  echo "[gitlab-omnibus] Pulling ${src}..."
  docker pull --platform "${IMAGE_ARCH}" "${src}"
  echo "[gitlab-omnibus] Tagging ${src} as ${dst}"
  docker tag "${src}" "${dst}"
}

extract_fs() {
  local tag="$1" outdir="$2"
  rm -rf "${outdir}"
  mkdir -p "${outdir}"
  local cid
  cid="$(docker create "${tag}")"
  if [ "${SKIP_EXTRACT:-0}" -eq 1 ]; then
    echo "[gitlab-omnibus] Skipping filesystem export (tar limitations on this platform); image pull/tag complete."
  else
    echo "[gitlab-omnibus] Exporting filesystem of ${tag} into ${outdir}"
    docker export "${cid}" | "${TAR_BIN}" "${TAR_FLAGS[@]}" "${outdir}" -xf -
  fi
  docker rm "${cid}" >/dev/null
}

main() {
  mkdir -p "${LOCAL_IMAGE_DIR}"
  pull_and_tag "${GITLAB_OMNIBUS_IMAGE}" "${LOCAL_PREFIX}/gitlab-omnibus:latest"
  extract_fs "${LOCAL_PREFIX}/gitlab-omnibus:latest" "${LOCAL_IMAGE_DIR}/gitlab-omnibus"
  echo "[gitlab-omnibus] Done. Local tag: ${LOCAL_PREFIX}/gitlab-omnibus:latest"
}

main "$@"
