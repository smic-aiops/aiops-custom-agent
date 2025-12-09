#!/usr/bin/env bash
set -euo pipefail

# Build (or re-tag) the GROWI image and push it to ECR.
# Optional environment variables:
#   AWS_PROFILE, AWS_ACCOUNT_ID, AWS_REGION, ECR_PREFIX, ECR_REPO_GROWI
#   LOCAL_PREFIX, LOCAL_IMAGE_DIR, IMAGE_ARCH, GROWI_CONTEXT, GROWI_DOCKERFILE
#   GROWI_IMAGE_TAG, GROWI_BASE_IMAGE

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
ECR_PREFIX="${ECR_PREFIX:-$(tf_output_raw ecr_namespace)}"
ECR_PREFIX="${ECR_PREFIX:-aiops}"
ECR_REPO_GROWI="${ECR_REPO_GROWI:-$(tf_output_raw ecr_repo_growi)}"
ECR_REPO_GROWI="${ECR_REPO_GROWI:-growi}"
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-$(tf_output_raw local_image_dir)}"
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"
IMAGE_ARCH="${IMAGE_ARCH:-$(tf_output_raw image_architecture)}"
IMAGE_ARCH="${IMAGE_ARCH:-linux/amd64}"
GROWI_CONTEXT="${GROWI_CONTEXT:-docker/growi}"
GROWI_DOCKERFILE="${GROWI_DOCKERFILE:-${GROWI_CONTEXT}/Dockerfile}"
GROWI_IMAGE_TAG="${GROWI_IMAGE_TAG:-$(tf_output_raw growi_image_tag)}"
GROWI_IMAGE_TAG="${GROWI_IMAGE_TAG:-7.3.8}"
GROWI_BASE_IMAGE="${GROWI_BASE_IMAGE:-weseek/growi:${GROWI_IMAGE_TAG}}"

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
    echo "[growi] Created ECR repo: ${repo}"
  fi
}

ensure_local_image() {
  local img="${LOCAL_PREFIX}/growi:latest"
  if ! docker image inspect "${img}" >/dev/null 2>&1; then
    echo "[growi] Local image ${img} not found. Run scripts/pull_growi_image.sh first."
    exit 1
  fi
}

build_or_retag() {
  local context="$1" dockerfile="$2" ecr_uri="$3"
  if [ -d "${context}" ] && [ -f "${dockerfile}" ]; then
    echo "[growi] Building ${ecr_uri}:latest from ${dockerfile} (${IMAGE_ARCH})..."
    docker build \
      --platform "${IMAGE_ARCH}" \
      --label "org.opencontainers.image.title=growi" \
      --label "org.opencontainers.image.version=${GROWI_IMAGE_TAG}" \
      --label "org.opencontainers.image.vendor=${ECR_PREFIX}" \
      --build-arg "BASE_IMAGE=${GROWI_BASE_IMAGE}" \
      -t "${ecr_uri}:latest" \
      -f "${dockerfile}" "${context}"
  else
    local fallback="${LOCAL_PREFIX}/growi:latest"
    ensure_local_image
    echo "[growi] Context ${context} missing; re-tagging ${fallback} -> ${ecr_uri}:latest"
    docker tag "${fallback}" "${ecr_uri}:latest"
  fi
}

main() {
  local repo="${ECR_PREFIX}/${ECR_REPO_GROWI}"
  local ecr_uri="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${repo}"

  login_ecr
  ensure_repo "${repo}"
  build_or_retag "${GROWI_CONTEXT}" "${GROWI_DOCKERFILE}" "${ecr_uri}"
  docker push "${ecr_uri}:latest"
  echo "[growi] Pushed ${ecr_uri}:latest"
}

main "$@"
