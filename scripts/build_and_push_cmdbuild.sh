#!/usr/bin/env bash
set -euo pipefail

# Push CMDBuild and CMDBuild Ready2Use images to ECR by tagging the local exports from pull_cmdbuild_image.sh.
# Optional environment variables:
#   AWS_PROFILE, AWS_ACCOUNT_ID, AWS_REGION, ECR_PREFIX
#   ECR_REPO_CMDBUILD, ECR_REPO_CMDBUILD_R2U
#   LOCAL_PREFIX, LOCAL_IMAGE_DIR, IMAGE_ARCH (platform label only)

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
ECR_REPO_CMDBUILD="${ECR_REPO_CMDBUILD:-cmdbuild}"
ECR_REPO_CMDBUILD_R2U="${ECR_REPO_CMDBUILD_R2U:-cmdbuild-r2u}"
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-$(tf_output_raw local_image_dir)}"
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"
IMAGE_ARCH="${IMAGE_ARCH:-$(tf_output_raw image_architecture)}"
IMAGE_ARCH="${IMAGE_ARCH:-linux/amd64}"

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
    echo "[cmdbuild] Created ECR repo: ${repo}"
  fi
}

ensure_local_image() {
  local name="$1"
  local img="${LOCAL_PREFIX}/${name}:latest"
  if ! docker image inspect "${img}" >/dev/null 2>&1; then
    echo "[cmdbuild] Local image ${img} not found. Run scripts/pull_cmdbuild_image.sh first."
    exit 1
  fi
}

tag_and_push() {
  local name="$1" repo="$2"
  local ecr_uri="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${repo}"
  local local_img="${LOCAL_PREFIX}/${name}:latest"
  ensure_repo "${repo}"
  ensure_local_image "${name}"
  echo "[cmdbuild] Tagging ${local_img} as ${ecr_uri}:latest"
  docker tag "${local_img}" "${ecr_uri}:latest"
  docker push "${ecr_uri}:latest"
  echo "[cmdbuild] Pushed ${ecr_uri}:latest"
}

main() {
  login_ecr
  tag_and_push "cmdbuild" "${ECR_PREFIX}/${ECR_REPO_CMDBUILD}"
  tag_and_push "cmdbuild-r2u" "${ECR_PREFIX}/${ECR_REPO_CMDBUILD_R2U}"
}

main "$@"
