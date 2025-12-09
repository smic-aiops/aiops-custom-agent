#!/usr/bin/env bash
set -euo pipefail

# Pull the GROWI image, retag it locally, export its filesystem, and optionally download plugins so they can be baked into a follow-up build.
# Environment overrides:
#   AWS_PROFILE      : Terraform/AWS profile (default: terraform output aws_profile or Admin-AIOps)
#   GROWI_IMAGE      : Full upstream image (default: weseek/growi:<tag>)
#   GROWI_IMAGE_TAG  : Image tag (default: terraform output growi_image_tag or 7.3.8)
#   LOCAL_PREFIX     : Local tag prefix (default: local)
#   LOCAL_IMAGE_DIR  : Directory for exported filesystems (default: terraform output local_image_dir or ./images)
#   IMAGE_ARCH       : Platform passed to docker pull (default: terraform output image_architecture or linux/amd64)
#   GROWI_PLUGIN_APPROVAL_URL : Archive URL for workflow/approval plugin (zip/tar.{gz,bz2,xz}); skip when unset
#   GROWI_PLUGIN_DRAWIO_URL   : Archive URL for draw.io plugin (zip/tar.{gz,bz2,xz}); skip when unset
#   GROWI_PLUGIN_URLS         : Optional space/comma separated list of name=url pairs (overrides the two vars above)
#   CA_BUNDLE_URL   : URL of RDS/DocumentDB CA bundle (default: AWS global bundle)
#   CA_BUNDLE_PATH  : Where to store the downloaded CA bundle inside the build context (default: docker/growi/rds-combined-ca-bundle.pem)
#   CA_BUNDLE_DEST  : Path inside the image to copy the CA bundle to (default: /etc/ssl/certs/rds-combined-ca-bundle.pem)

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
GROWI_IMAGE_TAG="${GROWI_IMAGE_TAG:-$(tf_output_raw growi_image_tag)}"
GROWI_IMAGE_TAG="${GROWI_IMAGE_TAG:-7.3.8}"
GROWI_IMAGE="${GROWI_IMAGE:-weseek/growi:${GROWI_IMAGE_TAG}}"
PLUGIN_ROOT=""
CA_BUNDLE_URL="${CA_BUNDLE_URL:-https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem}"
CA_BUNDLE_PATH="${CA_BUNDLE_PATH:-docker/growi/rds-combined-ca-bundle.pem}"
CA_BUNDLE_DEST="${CA_BUNDLE_DEST:-/etc/ssl/certs/rds-combined-ca-bundle.pem}"

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
  docker export "${cid}" | tar -C "${outdir}" -xf -
  docker rm "${cid}" >/dev/null
}

extract_archive() {
  local archive="$1" dest="$2"
  python - "$archive" "$dest" <<'PY'
import sys
import tarfile
import zipfile
from pathlib import Path

archive, dest = sys.argv[1:]
dest_path = Path(dest)
dest_path.mkdir(parents=True, exist_ok=True)

if tarfile.is_tarfile(archive):
    with tarfile.open(archive) as tf:
        tf.extractall(dest_path)
elif zipfile.is_zipfile(archive):
    with zipfile.ZipFile(archive) as zf:
        zf.extractall(dest_path)
else:
    sys.exit("Unsupported archive format")
PY
}

copy_extracted_dir() {
  local src_root="$1" dest="$2"
  local first_dir
  first_dir="$(find "${src_root}" -mindepth 1 -maxdepth 1 -type d | head -n 1 || true)"
  rm -rf "${dest}"
  mkdir -p "$(dirname "${dest}")"
  if [ -n "${first_dir}" ] && [ "$(find "${src_root}" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]; then
    mv "${first_dir}" "${dest}"
  else
    mkdir -p "${dest}"
    find "${src_root}" -mindepth 1 -maxdepth 1 -exec mv {} "${dest}"/ \;
  fi
}

download_plugin() {
  local name="$1" url="$2"
  if [ -z "${url}" ]; then
    echo "[growi][plugin:${name}] Skipped (no URL provided)"
    return
  fi
  local tmpdir archive dest extracted_dir
  tmpdir="$(mktemp -d)"
  archive="${tmpdir}/${name}.archive"
  dest="${PLUGIN_ROOT}/${name}"
  echo "[growi][plugin:${name}] Downloading ${url}"
  if ! curl -fL "${url}" -o "${archive}"; then
    echo "[growi][plugin:${name}] Download failed: ${url}" >&2
    rm -rf "${tmpdir}"
    return 1
  fi
  extracted_dir="${tmpdir}/unpacked"
  mkdir -p "${extracted_dir}"
  if ! extract_archive "${archive}" "${extracted_dir}"; then
    echo "[growi][plugin:${name}] Unsupported archive or extraction failed" >&2
    rm -rf "${tmpdir}"
    return 1
  fi
  copy_extracted_dir "${extracted_dir}" "${dest}"
  rm -rf "${tmpdir}"
  echo "[growi][plugin:${name}] Placed under ${dest}"
}

download_plugins() {
  local plugin_dir="${LOCAL_IMAGE_DIR}/growi/opt/growi/apps/app/tmp/plugins"
  mkdir -p "${plugin_dir}"
  PLUGIN_ROOT="${plugin_dir}"

  if [ -n "${GROWI_PLUGIN_URLS:-}" ]; then
    local list="${GROWI_PLUGIN_URLS//,/ }"
    for entry in ${list}; do
      local name="${entry%%=*}"
      local url="${entry#*=}"
      if [ -z "${name}" ] || [ "${name}" = "${url}" ]; then
        echo "[growi][plugin] Skip malformed entry: ${entry}" >&2
        continue
      fi
      download_plugin "${name}" "${url}" || echo "[growi][plugin:${name}] Failed; continuing without it" >&2
    done
  else
    download_plugin "growi-plugin-approval" "${GROWI_PLUGIN_APPROVAL_URL:-}" || echo "[growi][plugin:approval] Failed; continuing without it" >&2
    download_plugin "growi-plugin-drawio" "${GROWI_PLUGIN_DRAWIO_URL:-}" || echo "[growi][plugin:drawio] Failed; continuing without it" >&2
  fi
}

download_ca_bundle() {
  local url="$1" dest="$2"
  mkdir -p "$(dirname "${dest}")"
  if [ -s "${dest}" ]; then
    echo "[growi] CA bundle already present: ${dest}"
    return
  fi
  echo "[growi] Downloading CA bundle from ${url}"
  curl -fL "${url}" -o "${dest}"
}

write_dockerfile() {
  mkdir -p docker/growi
  mkdir -p docker/growi/plugins
  if [ -d "${PLUGIN_ROOT}" ] && [ "$(find "${PLUGIN_ROOT}" -mindepth 1 -maxdepth 1 | wc -l)" -gt 0 ]; then
    rm -rf docker/growi/plugins
    mkdir -p docker/growi/plugins
    cp -a "${PLUGIN_ROOT}/." docker/growi/plugins/
  fi

  cat > docker/growi/Dockerfile <<EOF
ARG BASE_IMAGE=${GROWI_IMAGE}
FROM \${BASE_IMAGE}

USER root
COPY plugins/ /opt/growi/apps/app/tmp/plugins/
COPY $(basename "${CA_BUNDLE_PATH}") ${CA_BUNDLE_DEST}
RUN set -eux; \
    chown -R 1000:1000 /opt/growi/apps/app/tmp/plugins

ENV NODE_EXTRA_CA_CERTS=${CA_BUNDLE_DEST}
EOF
  echo "[growi] Wrote docker/growi/Dockerfile (plugins copied into /opt/growi/apps/app/tmp/plugins)"
}

main() {
  mkdir -p "${LOCAL_IMAGE_DIR}"
  local tag="${LOCAL_PREFIX}/growi:latest"
  pull_and_tag "growi" "${GROWI_IMAGE}" "${tag}"
  extract_fs "growi" "${tag}" "${LOCAL_IMAGE_DIR}/growi"
  download_plugins
  download_ca_bundle "${CA_BUNDLE_URL}" "${CA_BUNDLE_PATH}"
  write_dockerfile
  echo "[growi] Done. Local tag: ${tag}"
}

main "$@"
