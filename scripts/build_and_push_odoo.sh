#!/usr/bin/env bash
set -euo pipefail

# Push Odoo image to ECR by tagging the local export produced by pull_odoo_image.sh.

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
if [ -z "${ECR_REPO_ODOO:-}" ]; then
  ECR_REPO_ODOO="$(terraform output -raw ecr_repo_odoo 2>/dev/null || echo "odoo")"
fi
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
if [ -z "${LOCAL_IMAGE_DIR:-}" ]; then
  LOCAL_IMAGE_DIR="$(terraform output -raw local_image_dir 2>/dev/null || true)"
fi
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"

if [ -z "${ODOO_IMAGE_TAG:-}" ]; then
  ODOO_IMAGE_TAG="$(terraform output -raw odoo_image_tag 2>/dev/null || echo "latest")"
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
    echo "[odoo] Created ECR repo: ${repo}"
  fi
}

ensure_local_image() {
  local img="${LOCAL_PREFIX}/odoo:latest"
  if ! docker image inspect "${img}" >/dev/null 2>&1; then
    echo "[odoo] Local image ${img} not found. Run scripts/pull_odoo_image.sh first."
    exit 1
  fi
}

main() {
  local repo="${ECR_PREFIX}/${ECR_REPO_ODOO}"
  local ecr_uri="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${repo}"
  local local_img="${LOCAL_PREFIX}/odoo:latest"

  login_ecr
  ensure_repo "${repo}"
  ensure_local_image

  echo "[odoo] Tagging ${local_img} as ${ecr_uri}:latest"
  docker tag "${local_img}" "${ecr_uri}:latest"
  docker push "${ecr_uri}:latest"
  echo "[odoo] Pushed ${ecr_uri}:latest"
}

main "$@"
