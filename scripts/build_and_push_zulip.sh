#!/usr/bin/env bash
set -euo pipefail

# Build (or re-tag) and push the Zulip image to ECR.
# If a build context is not provided, this script re-tags the local/zulip:latest image
# produced by scripts/pull_zulip_image.sh and pushes it.
#
# Environment overrides:
#   AWS_PROFILE, AWS_REGION, ECR_PREFIX, ECR_REPO_ZULIP, LOCAL_PREFIX, IMAGE_ARCH, ZULIP_CONTEXT

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
if [ -z "${ECR_REPO_ZULIP:-}" ]; then
  ECR_REPO_ZULIP="$(terraform output -raw ecr_repo_zulip 2>/dev/null || echo "zulip")"
fi
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
if [ -z "${IMAGE_ARCH:-}" ]; then
  IMAGE_ARCH="$(terraform output -raw image_architecture 2>/dev/null || echo "linux/amd64")"
fi
ZULIP_CONTEXT="${ZULIP_CONTEXT:-docker/zulip}"

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
    echo "[zulip] Created ECR repo: ${repo}"
  fi
}

ensure_local_image() {
  local img="${LOCAL_PREFIX}/zulip:latest"
  if ! docker image inspect "${img}" >/dev/null 2>&1; then
    echo "[zulip] Local image ${img} not found. Run scripts/pull_zulip_image.sh first."
    exit 1
  fi
}

main() {
  local repo="${ECR_PREFIX}/${ECR_REPO_ZULIP}"
  local ecr_uri="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${repo}"
  local local_img="${LOCAL_PREFIX}/zulip:latest"

  login_ecr
  ensure_repo "${repo}"

  if [ -d "${ZULIP_CONTEXT}" ]; then
    echo "[zulip] Building from context ${ZULIP_CONTEXT} (${IMAGE_ARCH})..."
    docker build --platform "${IMAGE_ARCH}" -t "${ecr_uri}:latest" "${ZULIP_CONTEXT}"
  else
    ensure_local_image
    echo "[zulip] Context ${ZULIP_CONTEXT} missing; re-tagging ${local_img} -> ${ecr_uri}:latest"
    docker tag "${local_img}" "${ecr_uri}:latest"
  fi

  echo "[zulip] Pushing ${ecr_uri}:latest"
  docker push "${ecr_uri}:latest"
  echo "[zulip] Pushed ${ecr_uri}:latest"
}

main "$@"
