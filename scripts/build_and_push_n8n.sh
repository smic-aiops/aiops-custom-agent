#!/usr/bin/env bash
set -euo pipefail

# Build (or re-tag) the n8n image and push it to ECR.
# Mirrors the n8n portion of build_and_push_ecr.sh for standalone usage.
#
# Optional environment variables:
#   AWS_PROFILE, AWS_ACCOUNT_ID, AWS_REGION, ECR_PREFIX, ECR_REPO_N8N
#   LOCAL_PREFIX, LOCAL_IMAGE_DIR, N8N_CONTEXT, N8N_DOCKERFILE, N8N_IMAGE_TAG, IMAGE_ARCH

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
if [ -z "${ECR_REPO_N8N:-}" ]; then
  ECR_REPO_N8N="$(terraform output -raw ecr_repo_n8n 2>/dev/null || echo "n8n")"
fi
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
if [ -z "${LOCAL_IMAGE_DIR:-}" ]; then
  LOCAL_IMAGE_DIR="$(terraform output -raw local_image_dir 2>/dev/null || true)"
fi
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"

if [ -z "${N8N_IMAGE_TAG:-}" ]; then
  N8N_IMAGE_TAG="$(terraform output -raw n8n_image_tag 2>/dev/null || echo "latest")"
fi
if [ -z "${IMAGE_ARCH:-}" ]; then
  IMAGE_ARCH="$(terraform output -raw image_architecture 2>/dev/null || echo "linux/amd64")"
fi
N8N_CONTEXT="${N8N_CONTEXT:-docker/n8n}"
N8N_DOCKERFILE="${N8N_DOCKERFILE:-${N8N_CONTEXT}/Dockerfile}"

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
    echo "[n8n] Created ECR repo: ${repo}"
  fi
}

build_or_retag() {
  local context="$1" dockerfile="$2" ecr_uri="$3" tag="$4"
  if [ -d "${context}" ] && [ -f "${dockerfile}" ]; then
    echo "[n8n] Building ${tag} from ${context} (${IMAGE_ARCH})..."
    docker build \
      --platform "${IMAGE_ARCH}" \
      --label "org.opencontainers.image.title=n8n" \
      --label "org.opencontainers.image.version=${tag}" \
      --label "org.opencontainers.image.vendor=${ECR_PREFIX}" \
      -t "${ecr_uri}:latest" \
      -f "${dockerfile}" "${context}"
  else
    local fallback="${LOCAL_PREFIX}/n8n:latest"
    if ! docker image inspect "${fallback}" >/dev/null 2>&1; then
      echo "[n8n] Local image ${fallback} not found. Run scripts/pull_n8n_image.sh first."
      exit 1
    fi
    echo "[n8n] Context ${context} missing; re-tagging ${fallback} -> ${ecr_uri}:latest"
    docker tag "${fallback}" "${ecr_uri}:latest"
  fi
}

main() {
  local repo="${ECR_PREFIX}/${ECR_REPO_N8N}"
  local ecr_uri="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${repo}"

  login_ecr
  ensure_repo "${repo}"
  build_or_retag "${N8N_CONTEXT}" "${N8N_DOCKERFILE}" "${ecr_uri}" "${N8N_IMAGE_TAG}"
  docker push "${ecr_uri}:latest"
  echo "[n8n] Pushed ${ecr_uri}:latest"
}

main "$@"
