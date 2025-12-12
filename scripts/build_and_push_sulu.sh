#!/usr/bin/env bash
set -euo pipefail

# Build the sulu image by layering config/migrations on shinsenter/sulu:php8.4 and push the final image to ECR.
# Falls back to retagging the locally cached image if the build context is missing.
# Optional environment variables:
#   AWS_PROFILE, AWS_ACCOUNT_ID, AWS_REGION, ECR_PREFIX, ECR_REPO_SULU
#   LOCAL_PREFIX, SULU_CONTEXT, SULU_IMAGE_TAG, IMAGE_ARCH, SULU_IMAGE

if [ -z "${AWS_PROFILE:-}" ]; then
  AWS_PROFILE="$(terraform output -raw aws_profile 2>/dev/null || true)"
fi
AWS_PROFILE="${AWS_PROFILE:-Admin-AIOps}"
export AWS_PROFILE

if [ -z "${AWS_ACCOUNT_ID:-}" ]; then
  AWS_ACCOUNT_ID="$(aws --profile "${AWS_PROFILE}" sts get-caller-identity --query Account --output text)"
fi
AWS_REGION="${AWS_REGION:-ap-northeast-1}"
if [ -z "${ECR_PREFIX:-}" ]; then
  ECR_PREFIX="$(terraform output -raw ecr_namespace 2>/dev/null || echo "aiops")"
fi
if [ -z "${ECR_REPO_SULU:-}" ]; then
  ECR_REPO_SULU="$(terraform output -raw ecr_repo_sulu 2>/dev/null || echo "sulu")"
fi
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
SULU_CONTEXT="${SULU_CONTEXT:-./docker/sulu}"

if [ -z "${SULU_IMAGE_TAG:-}" ]; then
  SULU_IMAGE_TAG="$(terraform output -raw sulu_image_tag 2>/dev/null || echo "php8.4")"
fi
if [ -z "${SULU_IMAGE:-}" ]; then
  SULU_IMAGE="shinsenter/sulu:${SULU_IMAGE_TAG}"
fi
if [ -z "${IMAGE_ARCH:-}" ]; then
  IMAGE_ARCH="$(terraform output -raw image_architecture 2>/dev/null || echo "linux/amd64")"
fi

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

build_or_retag() {
  local context="$1" ecr_uri="$2" tag="$3"
  local fallback="${LOCAL_PREFIX}/sulu:latest"

  if [ -d "${context}" ]; then
    echo "[sulu] Building ${tag} from ${context} (${IMAGE_ARCH})..."
    docker build \
      --platform "${IMAGE_ARCH}" \
      --label "org.opencontainers.image.title=sulu" \
      --label "org.opencontainers.image.version=${tag}" \
      --label "org.opencontainers.image.vendor=${ECR_PREFIX}" \
      --build-arg SULU_IMAGE="${SULU_IMAGE}" \
      -t "${ecr_uri}:latest" \
      "${context}"
  else
    if ! docker image inspect "${fallback}" >/dev/null 2>&1; then
      echo "[sulu] Context ${context} not found and fallback image ${fallback} missing. Run scripts/pull_sulu_image.sh first."
      exit 1
    fi
    echo "[sulu] Context ${context} missing; re-tagging ${fallback} -> ${ecr_uri}:latest"
    docker tag "${fallback}" "${ecr_uri}:latest"
  fi
}

main() {
  local repo="${ECR_PREFIX}/${ECR_REPO_SULU}"
  local ecr_uri="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${repo}"

  login_ecr
  ensure_repo "${repo}"
  build_or_retag "${SULU_CONTEXT}" "${ecr_uri}" "${SULU_IMAGE_TAG}"
  docker push "${ecr_uri}:latest"
  echo "[sulu] Pushed ${ecr_uri}:latest"
}

main "$@"
