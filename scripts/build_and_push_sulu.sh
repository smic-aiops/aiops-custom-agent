#!/usr/bin/env bash
set -euo pipefail

tf_output_raw() {
  terraform output -lock=false -raw "$1" 2>/dev/null || true
}

if [ -z "${AWS_PROFILE:-}" ]; then
  AWS_PROFILE="$(tf_output_raw aws_profile)"
fi
AWS_PROFILE="${AWS_PROFILE:-Admin-AIOps}"
export AWS_PROFILE

if [ -z "${AWS_ACCOUNT_ID:-}" ]; then
  AWS_ACCOUNT_ID="$(aws --profile "${AWS_PROFILE}" sts get-caller-identity --query Account --output text)"
fi

AWS_REGION="${AWS_REGION:-ap-northeast-1}"
if [ -z "${ECR_PREFIX:-}" ]; then
  ECR_PREFIX="$(tf_output_raw ecr_namespace)"
fi
if [ -z "${ECR_REPO_SULU:-}" ]; then
  ECR_REPO_SULU="$(tf_output_raw ecr_repo_sulu)"
fi
if [ -z "${ECR_REPO_SULU_NGINX:-}" ]; then
  ECR_REPO_SULU_NGINX="$(tf_output_raw ecr_repo_sulu_nginx)"
fi
ECR_PREFIX="${ECR_PREFIX:-aiops}"
ECR_REPO_SULU="${ECR_REPO_SULU:-sulu}"
ECR_REPO_SULU_NGINX="${ECR_REPO_SULU_NGINX:-sulu-nginx}"

SULU_IMAGE_TAG="${SULU_IMAGE_TAG:-$(tf_output_raw sulu_image_tag)}"
SULU_IMAGE_TAG="${SULU_IMAGE_TAG:-3.0.0}"
SULU_CONTEXT="${SULU_CONTEXT:-./docker/sulu}"
SULU_NGINX_CONTEXT="${SULU_NGINX_CONTEXT:-${SULU_CONTEXT}/nginx}"
SULU_SOURCE_DIR="${SULU_SOURCE_DIR:-${SULU_CONTEXT}/source}"
IMAGE_ARCH="${IMAGE_ARCH:-$(tf_output_raw image_architecture)}"
IMAGE_ARCH="${IMAGE_ARCH:-linux/amd64}"

ensure_context() {
  local context="$1" name="$2"
  if [ ! -d "${context}" ]; then
    echo "[sulu:${name}] Context ${context} is missing." >&2
    exit 1
  fi
  if [ ! -f "${context}/Dockerfile" ]; then
    echo "[sulu:${name}] Dockerfile missing in ${context}; rerun scripts/pull_sulu_image.sh or add a Dockerfile." >&2
    exit 1
  fi
}

ensure_source_dir() {
  if [ ! -d "${SULU_SOURCE_DIR}" ]; then
    echo "[sulu:php] Source directory ${SULU_SOURCE_DIR} is missing; run scripts/pull_sulu_image.sh first." >&2
    exit 1
  fi
}

login_ecr() {
  aws --profile "${AWS_PROFILE}" ecr get-login-password --region "${AWS_REGION}" \
    | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
}

ensure_repo() {
  local repo="$1"
  if ! aws --profile "${AWS_PROFILE}" ecr describe-repositories --repository-names "${repo}" --region "${AWS_REGION}" >/dev/null 2>&1; then
    aws --profile "${AWS_PROFILE}" ecr create-repository \
      --repository-name "${repo}" \
      --image-scanning-configuration scanOnPush=true \
      --region "${AWS_REGION}" >/dev/null
    echo "[sulu] Created ECR repo: ${repo}"
  fi
}

build_image() {
  local context="$1" ecr_uri="$2" label="$3" extra_args="$4"
  echo "[sulu:${label}] Building ${ecr_uri}:latest from ${context} (${IMAGE_ARCH})..."
  docker build \
    --platform "${IMAGE_ARCH}" \
    --label "org.opencontainers.image.version=${SULU_IMAGE_TAG}" \
    --label "org.opencontainers.image.title=Sulu PHP" \
    ${extra_args:-} \
    -t "${ecr_uri}:latest" \
    "${context}"
}

push_image() {
  local ecr_uri="$1" label="$2"
  docker push "${ecr_uri}:latest"
  docker tag "${ecr_uri}:latest" "${ecr_uri}:${SULU_IMAGE_TAG}"
  docker push "${ecr_uri}:${SULU_IMAGE_TAG}"
  echo "[sulu:${label}] Pushed ${ecr_uri}:latest and ${ecr_uri}:${SULU_IMAGE_TAG}"
}

main() {
  ensure_context "${SULU_CONTEXT}" "php"
  ensure_context "${SULU_NGINX_CONTEXT}" "nginx"
  ensure_source_dir

  local repo_php="${ECR_PREFIX}/${ECR_REPO_SULU}"
  local repo_nginx="${ECR_PREFIX}/${ECR_REPO_SULU_NGINX}"
  local ecr_uri_php="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${repo_php}"
  local ecr_uri_nginx="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${repo_nginx}"

  login_ecr
  ensure_repo "${repo_php}"
  ensure_repo "${repo_nginx}"

  build_image "${SULU_CONTEXT}" "${ecr_uri_php}" "php" "--build-arg SULU_VERSION=${SULU_IMAGE_TAG}"
  push_image "${ecr_uri_php}" "php"
  build_image "${SULU_NGINX_CONTEXT}" "${ecr_uri_nginx}" "nginx"
  push_image "${ecr_uri_nginx}" "nginx"
}

main "$@"
