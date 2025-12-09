#!/usr/bin/env bash
set -euo pipefail

# Pull the Odoo image, retag it locally, export its filesystem, and refresh the
# Japanese localization addons directory.
# Environment overrides:
#   ODOO_IMAGE         : Full upstream image (default: odoo:<tag>)
#   ODOO_IMAGE_TAG     : Tag/version to pull (default: terraform output odoo_image_tag or 17.0)
#   LOCAL_PREFIX       : Local tag prefix (default: local)
#   LOCAL_IMAGE_DIR    : Directory to store exported filesystems (default: terraform output local_image_dir or ./images)
#   IMAGE_ARCH         : Platform passed to docker pull (default: terraform output image_architecture or linux/amd64)
#   TARGET_DIR         : Destination for JP addons (default: ${LOCAL_IMAGE_DIR:-./images}/odoo/extra-addons/jp)
#   OIDC_TARGET_DIR    : Destination for auth_oidc addon (default: ${LOCAL_IMAGE_DIR:-./images}/odoo/extra-addons/auth_oidc)
#   OIDC_REPO          : Source repo for auth_oidc (default: OCA/server-auth)
#   OIDC_BRANCH        : Branch to pull (default: <major.minor> from ODOO_IMAGE_TAG, fallback 17.0)
#   OCA_TARGET_DIR     : Destination for OCA addons (default: ${LOCAL_IMAGE_DIR:-./images}/odoo/extra-addons)
#   OCA_GANTT_REPO     : Repo for Gantt addons (default: OCA/project)
#   OCA_GANTT_BRANCH   : Branch for Gantt addons (default: <major.minor> from ODOO_IMAGE_TAG, fallback 17.0)
#   OCA_TIMESHEET_REPO : Repo for timesheet addons (default: OCA/hr-timesheet)
#   OCA_TIMESHEET_BRANCH: Branch for timesheet addons (default: <major.minor> from ODOO_IMAGE_TAG, fallback 17.0)
#   CLEAN_TARGET       : If "true", wipe TARGET_DIR before copying addons
#   FETCH_METHOD       : sparse_git (default) or tarball fallback for addon sources

if [ -z "${ODOO_IMAGE_TAG:-}" ]; then
  ODOO_IMAGE_TAG="$(terraform output -raw odoo_image_tag 2>/dev/null || echo "17.0")"
fi
if [ -z "${IMAGE_ARCH:-}" ]; then
  IMAGE_ARCH="$(terraform output -raw image_architecture 2>/dev/null || echo "linux/amd64")"
fi
if [ -z "${LOCAL_IMAGE_DIR:-}" ]; then
  LOCAL_IMAGE_DIR="$(terraform output -raw local_image_dir 2>/dev/null || true)"
fi
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
EXTRA_ADDONS_DIR="${LOCAL_IMAGE_DIR}/odoo/extra-addons"
ODOO_IMAGE="${ODOO_IMAGE:-odoo:${ODOO_IMAGE_TAG}}"
ODOO_VERSION="${ODOO_VERSION:-${ODOO_IMAGE_TAG}}"
ODOO_MAJOR_MINOR="$(printf '%s' "${ODOO_VERSION}" | awk -F. '{print $1"."$2}')"
TARGET_DIR="${TARGET_DIR:-${EXTRA_ADDONS_DIR}/jp}"
OIDC_ADDON_NAME="${OIDC_ADDON_NAME:-auth_oidc}"
OIDC_TARGET_DIR="${OIDC_TARGET_DIR:-${EXTRA_ADDONS_DIR}/${OIDC_ADDON_NAME}}"
OIDC_REPO="${OIDC_REPO:-OCA/server-auth}"
OIDC_BRANCH="${OIDC_BRANCH:-${ODOO_MAJOR_MINOR}}"
OIDC_FALLBACK_BRANCH="${OIDC_FALLBACK_BRANCH:-17.0}"
OCA_TARGET_DIR="${OCA_TARGET_DIR:-${EXTRA_ADDONS_DIR}}"
OCA_GANTT_REPO="${OCA_GANTT_REPO:-OCA/project}"
OCA_GANTT_BRANCH="${OCA_GANTT_BRANCH:-${ODOO_MAJOR_MINOR}}"
OCA_GANTT_FALLBACK_BRANCH="${OCA_GANTT_FALLBACK_BRANCH:-17.0}"
OCA_TIMESHEET_REPO="${OCA_TIMESHEET_REPO:-OCA/hr-timesheet}"
OCA_TIMESHEET_BRANCH="${OCA_TIMESHEET_BRANCH:-${ODOO_MAJOR_MINOR}}"
OCA_TIMESHEET_FALLBACK_BRANCH="${OCA_TIMESHEET_FALLBACK_BRANCH:-17.0}"
CLEAN_TARGET="${CLEAN_TARGET:-false}"

MODULES=(
  l10n_jp
  l10n_jp_reports
  l10n_jp_zengin
  l10n_jp_ubl_pint
)

pull_and_tag() {
  local src="$1" dst="$2"
  echo "[odoo] Pulling ${src}..."
  docker pull --platform "${IMAGE_ARCH}" "${src}"
  echo "[odoo] Tagging ${src} as ${dst}"
  docker tag "${src}" "${dst}"
}

extract_fs() {
  local tag="$1" outdir="$2"
  mkdir -p "${outdir}"
  local cid
  cid="$(docker create "${tag}")"
  echo "[odoo] Exporting filesystem of ${tag} into ${outdir}"
  docker export "${cid}" | tar -C "${outdir}" -xf -
  docker rm "${cid}" >/dev/null
}

fetch_sparse_git() {
  local tmp="$1"
  git -c init.defaultBranch=main init "${tmp}" >/dev/null
  git -C "${tmp}" remote add origin https://github.com/odoo/odoo.git >/dev/null
  git -C "${tmp}" config core.sparseCheckout true
  git -C "${tmp}" sparse-checkout init --cone >/dev/null
  git -C "${tmp}" sparse-checkout set "${MODULES[@]/#/addons/}" >/dev/null

  if git -C "${tmp}" fetch --depth=1 --no-tags origin "refs/tags/${ODOO_VERSION}" --prune --prune-tags --force >/dev/null 2>&1; then
    git -C "${tmp}" checkout --progress --force FETCH_HEAD >/dev/null
    return 0
  fi

  if git -C "${tmp}" fetch --depth=1 --no-tags origin "refs/heads/${ODOO_VERSION}" --prune --prune-tags --force >/dev/null 2>&1; then
    git -C "${tmp}" checkout --progress --force FETCH_HEAD >/dev/null
    return 0
  fi

  return 1
}

fetch_tarball() {
  local tmp="$1"
  local tarball="${tmp}/odoo.tar.gz"
  local nightly_url="https://nightly.odoo.com/${ODOO_VERSION}/nightly/src/odoo_${ODOO_VERSION}.latest.tar.gz"
  local github_url="https://github.com/odoo/odoo/archive/refs/tags/${ODOO_VERSION}.tar.gz"

  echo "[odoo] Trying nightly tarball: ${nightly_url}"
  if curl -fL --connect-timeout 10 --max-time 600 -o "${tarball}" "${nightly_url}"; then
    :
  else
    echo "[odoo] Nightly tarball unavailable, falling back to GitHub tag: ${github_url}"
    curl -fL --connect-timeout 10 --max-time 600 -o "${tarball}" "${github_url}"
  fi

  echo "[odoo] Extracting tarball..."
  tar -xzf "${tarball}" -C "${tmp}"
  local dir
  dir="$(find "${tmp}" -maxdepth 1 -type d -name "odoo-*")"
  if [ -z "${dir}" ]; then
    echo "[odoo] Failed to locate extracted source" >&2
    exit 1
  fi
  echo "${dir}"
}

fetch_addons() {
  local tmp dir src
  tmp="$(mktemp -d)"
  TMP_ADDONS_DIR="${tmp}"
  trap 'rm -rf "${TMP_ADDONS_DIR:-}"' EXIT

  mkdir -p "${TARGET_DIR}"
  if [ "${CLEAN_TARGET}" = "true" ]; then
    for m in "${MODULES[@]}"; do
      rm -rf "${TARGET_DIR}/${m}"
    done
  fi

  if [ "${FETCH_METHOD:-sparse_git}" = "sparse_git" ]; then
    echo "[odoo] Fetching addons via sparse checkout (GitHub, version ${ODOO_VERSION})"
    if fetch_sparse_git "${tmp}"; then
      src="${tmp}/addons"
    else
      echo "[odoo] Sparse checkout failed; falling back to tarball download."
      dir="$(fetch_tarball "${tmp}")"
      src="${dir}/addons"
    fi
  else
    dir="$(fetch_tarball "${tmp}")"
    src="${dir}/addons"
  fi

  if [ ! -d "${src}" ]; then
    echo "[odoo] addons directory not found at ${src}" >&2
    exit 1
  fi

  for m in "${MODULES[@]}"; do
    if [ -d "${src}/${m}" ]; then
      echo "[odoo] Copying ${m} -> ${TARGET_DIR}/${m}"
      rm -rf "${TARGET_DIR:?}/${m}"
      cp -a "${src}/${m}" "${TARGET_DIR}/"
    else
      echo "[odoo] WARNING: module ${m} not found for version ${ODOO_VERSION}" >&2
    fi
  done

  echo "[odoo] Done. Add '${TARGET_DIR}' to Odoo addons path (e.g., /mnt/extra-addons) when building or running the container."
}

fetch_oidc_addon() {
  local tmp tarball branch repo base dir src
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp:-}"' RETURN

  repo="${OIDC_REPO}"
  branch="${OIDC_BRANCH}"
  tarball="${tmp}/oidc.tar.gz"

  echo "[odoo] Fetching ${OIDC_ADDON_NAME} from ${repo}@${branch}"
  if ! curl -fL --connect-timeout 10 --max-time 600 -o "${tarball}" "https://github.com/${repo}/archive/refs/heads/${branch}.tar.gz"; then
    echo "[odoo] Branch ${branch} not found; falling back to ${OIDC_FALLBACK_BRANCH}"
    branch="${OIDC_FALLBACK_BRANCH}"
    curl -fL --connect-timeout 10 --max-time 600 -o "${tarball}" "https://github.com/${repo}/archive/refs/heads/${branch}.tar.gz"
  fi

  echo "[odoo] Extracting ${repo}@${branch}"
  tar -xzf "${tarball}" -C "${tmp}"
  base="$(basename "${repo}")"
  dir="$(find "${tmp}" -maxdepth 1 -type d -name "${base}-*" | head -n1)"
  if [ -z "${dir}" ]; then
    echo "[odoo] Failed to locate extracted ${repo} source" >&2
    exit 1
  fi

  src="${dir}/${OIDC_ADDON_NAME}"
  if [ ! -d "${src}" ]; then
    echo "[odoo] ${OIDC_ADDON_NAME} not found in ${repo}@${branch}" >&2
    exit 1
  fi

  echo "[odoo] Copying ${OIDC_ADDON_NAME} -> ${OIDC_TARGET_DIR}"
  mkdir -p "$(dirname "${OIDC_TARGET_DIR}")"
  rm -rf "${OIDC_TARGET_DIR}"
  cp -a "${src}" "${OIDC_TARGET_DIR}"
}

fetch_oca_repo_modules() {
  local repo="$1" branch="$2" fallback_branch="$3" target_base="$4"; shift 4
  local modules=("$@")
  local tmp tarball base dir src

  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp:-}"' RETURN

  tarball="${tmp}/repo.tar.gz"
  echo "[odoo] Fetching ${repo}@${branch} modules: ${modules[*]}"
  if ! curl -fL --connect-timeout 10 --max-time 600 -o "${tarball}" "https://github.com/${repo}/archive/refs/heads/${branch}.tar.gz"; then
    echo "[odoo] Branch ${branch} not found; falling back to ${fallback_branch}"
    branch="${fallback_branch}"
    curl -fL --connect-timeout 10 --max-time 600 -o "${tarball}" "https://github.com/${repo}/archive/refs/heads/${branch}.tar.gz"
  fi

  tar -xzf "${tarball}" -C "${tmp}"
  base="$(basename "${repo}")"
  dir="$(find "${tmp}" -maxdepth 1 -type d -name "${base}-*" | head -n1)"
  if [ -z "${dir}" ]; then
    echo "[odoo] Failed to locate extracted ${repo} source" >&2
    exit 1
  fi

  mkdir -p "${target_base}"
  for m in "${modules[@]}"; do
    src="${dir}/${m}"
    if [ ! -d "${src}" ]; then
      echo "[odoo] WARNING: module ${m} not found in ${repo}@${branch}" >&2
      continue
    fi
    if [ "${CLEAN_TARGET}" = "true" ]; then
      rm -rf "${target_base:?}/${m}"
    fi
    echo "[odoo] Copying ${m} -> ${target_base}/${m}"
    rm -rf "${target_base:?}/${m}"
    cp -a "${src}" "${target_base}/"
  done
}

fetch_gantt_addons() {
  local modules=("web_gantt" "project_gantt")
  fetch_oca_repo_modules "${OCA_GANTT_REPO}" "${OCA_GANTT_BRANCH}" "${OCA_GANTT_FALLBACK_BRANCH}" "${OCA_TARGET_DIR}" "${modules[@]}"
}

fetch_timesheet_addons() {
  local modules=("hr_timesheet")
  fetch_oca_repo_modules "${OCA_TIMESHEET_REPO}" "${OCA_TIMESHEET_BRANCH}" "${OCA_TIMESHEET_FALLBACK_BRANCH}" "${OCA_TARGET_DIR}" "${modules[@]}"
}

main() {
  mkdir -p "${LOCAL_IMAGE_DIR}"
  pull_and_tag "${ODOO_IMAGE}" "${LOCAL_PREFIX}/odoo:latest"
  extract_fs "${LOCAL_PREFIX}/odoo:latest" "${LOCAL_IMAGE_DIR}/odoo"
  fetch_addons
  fetch_oidc_addon
  fetch_gantt_addons
  fetch_timesheet_addons
  echo "[odoo] Done. Local tag: ${LOCAL_PREFIX}/odoo:latest"
}

main "$@"
