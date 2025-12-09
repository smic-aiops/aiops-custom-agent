#!/usr/bin/env bash
set -euo pipefail

# Pull the upstream Exastro IT Automation web server image and push it to ECR.
#
# Optional environment variables:
#   AWS_PROFILE, AWS_ACCOUNT_ID, AWS_REGION, ECR_PREFIX
#   ECR_REPO_EXASTRO_WEB_SERVER : ECR repo name (default: terraform output ecr_repo_exastro_it_automation_web_server or exastro-it-automation-web-server)
#   EXASTRO_WEB_SERVER_IMAGE    : Upstream image (default: terraform output exastro_it_automation_web_server_image_tag or exastro/exastro-it-automation-web-server:2.7.0)
#   IMAGE_ARCH                  : Platform for docker pull (default: terraform output image_architecture or linux/amd64)

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
if [ -z "${ECR_REPO_EXASTRO_WEB_SERVER:-}" ]; then
  ECR_REPO_EXASTRO_WEB_SERVER="$(terraform output -raw ecr_repo_exastro_it_automation_web_server 2>/dev/null || echo "exastro-it-automation-web-server")"
fi

if [ -z "${EXASTRO_WEB_SERVER_IMAGE:-}" ]; then
  EXASTRO_WEB_SERVER_IMAGE="$(terraform output -raw exastro_it_automation_web_server_image_tag 2>/dev/null || echo "exastro/exastro-it-automation-web-server:2.7.0")"
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
    echo "[exastro-web] Created ECR repo: ${repo}"
  fi
}

pull_and_tag() {
  local src="$1" dst="$2"
  echo "[exastro-web] Pulling ${src} (${IMAGE_ARCH})..."
  docker pull --platform "${IMAGE_ARCH}" "${src}"
  echo "[exastro-web] Tagging ${src} as ${dst}:latest"
  docker tag "${src}" "${dst}:latest"
}

main() {
  local repo="${ECR_PREFIX}/${ECR_REPO_EXASTRO_WEB_SERVER}"
  local ecr_uri="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${repo}"

  login_ecr
  ensure_repo "${repo}"
  pull_and_tag "${EXASTRO_WEB_SERVER_IMAGE}" "${ecr_uri}"
  docker push "${ecr_uri}:latest"
  echo "[exastro-web] Pushed ${ecr_uri}:latest"
}

main "$@"
