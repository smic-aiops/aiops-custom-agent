#!/usr/bin/env bash
set -euo pipefail

# Pull the OrangeHRM image, retag it locally, and export its filesystem.
# Environment overrides:
#   AWS_PROFILE        : Terraform/AWS profile (default: terraform output aws_profile or Admin-AIOps)
#   ORANGEHRM_IMAGE    : Full upstream image (default: orangehrm/orangehrm:<tag>)
#   ORANGEHRM_IMAGE_TAG: Image tag (default: terraform output orangehrm_image_tag or 5.8)
#   LOCAL_PREFIX       : Local tag prefix (default: local)
#   LOCAL_IMAGE_DIR    : Directory for exported filesystems (default: terraform output local_image_dir or ./images)
#   IMAGE_ARCH         : Platform passed to docker pull (default: terraform output image_architecture or linux/amd64)
#   ORANGEHRM_ADDON_URLS: Space/comma separated addon URLs to cache into the image (default: empty)
#   ORANGEHRM_ADDON_TARGET: Path inside the image to place downloaded addons (default: /opt/orangehrm-addons)

tf_output_raw() {
  terraform output -lock=false -raw "$1" 2>/dev/null || true
}

if [ -z "${AWS_PROFILE:-}" ]; then
  AWS_PROFILE="$(tf_output_raw aws_profile)"
fi
AWS_PROFILE="${AWS_PROFILE:-Admin-AIOps}"
export AWS_PROFILE

IMAGE_ARCH="${IMAGE_ARCH:-$(tf_output_raw image_architecture)}"
IMAGE_ARCH="${IMAGE_ARCH:-linux/amd64}"
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-$(tf_output_raw local_image_dir)}"
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
ORANGEHRM_IMAGE_TAG="${ORANGEHRM_IMAGE_TAG:-$(tf_output_raw orangehrm_image_tag)}"
ORANGEHRM_IMAGE_TAG="${ORANGEHRM_IMAGE_TAG:-5.8}"
ORANGEHRM_IMAGE="${ORANGEHRM_IMAGE:-orangehrm/orangehrm:${ORANGEHRM_IMAGE_TAG}}"
ORANGEHRM_ADDON_TARGET="${ORANGEHRM_ADDON_TARGET:-/opt/orangehrm-addons}"

pull_and_tag() {
  local name="$1" src="$2" dst="$3"
  echo "[${name}] Pulling ${src}..."
  docker pull --platform "${IMAGE_ARCH}" "${src}"
  echo "[${name}] Tagging ${src} as ${dst}"
  docker tag "${src}" "${dst}"
}

parse_addon_urls() {
  local raw="${1:-}" cleaned=() url
  raw="${raw//,/ }"
  for url in ${raw}; do
    if [ -n "${url}" ]; then
      cleaned+=("${url}")
    fi
  done
  printf "%s\n" "${cleaned[@]:-}"
}

download_addons() {
  local dest="$1"; shift
  local urls=("$@")
  rm -rf "${dest}"
  mkdir -p "${dest}"
  local idx=1 url filename
  for url in "${urls[@]}"; do
    filename="$(basename "${url%%\?*}")"
    filename="${filename:-addon-${idx}.zip}"
    echo "[orangehrm:addon] Downloading ${url} -> ${filename}"
    curl -fL --retry 3 --connect-timeout 15 --max-time 300 -o "${dest}/${filename}" "${url}"
    idx=$((idx + 1))
  done
}

copy_addons_into_container() {
  local cid="$1" src_dir="$2" target_dir="$3"
  if [ ! -d "${src_dir}" ] || [ -z "$(find "${src_dir}" -maxdepth 1 -type f 2>/dev/null)" ]; then
    echo "[orangehrm:addon] No addon files to copy into container."
    return
  fi
  echo "[orangehrm:addon] Copying addons into container ${cid}:${target_dir}"
  docker cp "${src_dir}/." "${cid}:${target_dir}/"
}

extract_fs() {
  local name="$1" tag="$2" outdir="$3"
  rm -rf "${outdir}"
  mkdir -p "${outdir}"
  local cid
  cid="$(docker create "${tag}")"
  echo "[${name}] Exporting filesystem of ${tag} into ${outdir}"
  docker export "${cid}" | tar -C "${outdir}" -xf -
  docker rm "${cid}" >/dev/null
}

main() {
  mkdir -p "${LOCAL_IMAGE_DIR}"
  local base_tag="${LOCAL_PREFIX}/orangehrm:base"
  local final_tag="${LOCAL_PREFIX}/orangehrm:latest"
  pull_and_tag "orangehrm" "${ORANGEHRM_IMAGE}" "${base_tag}"

  local addons=()
  while IFS= read -r url; do
    addons+=("${url}")
  done < <(parse_addon_urls "${ORANGEHRM_ADDON_URLS:-}")

  if [ "${#addons[@]}" -gt 0 ]; then
    local addon_cache="${LOCAL_IMAGE_DIR}/orangehrm-addons"
    download_addons "${addon_cache}" "${addons[@]}"
    local cid
    cid="$(docker create "${base_tag}")"
    copy_addons_into_container "${cid}" "${addon_cache}" "${ORANGEHRM_ADDON_TARGET}"
    docker commit "${cid}" "${final_tag}" >/dev/null
    docker rm "${cid}" >/dev/null
    echo "[orangehrm:addon] Embedded ${#addons[@]} file(s) into ${final_tag} at ${ORANGEHRM_ADDON_TARGET}"
  else
    docker tag "${base_tag}" "${final_tag}"
  fi

  extract_fs "orangehrm" "${final_tag}" "${LOCAL_IMAGE_DIR}/orangehrm"
  echo "[orangehrm] Done. Local tag: ${final_tag}"
}

main "$@"
