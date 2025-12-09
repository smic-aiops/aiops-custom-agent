#!/usr/bin/env bash
set -euo pipefail

# Build (or re-tag) a GitLab Omnibus image and push it to ECR. Defaults to 17.11.7-ce.0.
#
# Optional environment variables:
#   AWS_PROFILE           AWS_ACCOUNT_ID AWS_REGION ECR_PREFIX
#   ECR_REPO_GITLAB_OMNIBUS LOCAL_PREFIX LOCAL_IMAGE_DIR
#   GITLAB_OMNIBUS_CONTEXT GITLAB_OMNIBUS_DOCKERFILE
#   GITLAB_OMNIBUS_TAG IMAGE_ARCH

if [[ -z "${AWS_PROFILE:-}" ]]; then
  AWS_PROFILE="$(terraform output -raw aws_profile 2>/dev/null || true)"
fi
AWS_PROFILE="${AWS_PROFILE:-Admin-AIOps}"
export AWS_PROFILE

if [[ -z "${AWS_ACCOUNT_ID:-}" ]]; then
  AWS_ACCOUNT_ID="$(aws --profile "${AWS_PROFILE}" sts get-caller-identity --query Account --output text)"
fi
AWS_REGION="${AWS_REGION:-ap-northeast-1}"
ECR_PREFIX="${ECR_PREFIX:-$(terraform output -raw ecr_namespace 2>/dev/null || echo "aiops")}"
ECR_REPO_GITLAB_OMNIBUS="${ECR_REPO_GITLAB_OMNIBUS:-gitlab-omnibus}"
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
IMAGE_ARCH="${IMAGE_ARCH:-$(terraform output -raw image_architecture 2>/dev/null || echo "linux/amd64")}"

LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-$(terraform output -raw local_image_dir 2>/dev/null || true)}"
LOCAL_IMAGE_DIR="${LOCAL_IMAGE_DIR:-./images}"

GITLAB_OMNIBUS_TAG="${GITLAB_OMNIBUS_TAG:-$(terraform output -raw gitlab_omnibus_image_tag 2>/dev/null || echo "17.11.7-ce.0")}"
GITLAB_OMNIBUS_CONTEXT="${GITLAB_OMNIBUS_CONTEXT:-docker/gitlab-omnibus}"
GITLAB_OMNIBUS_DOCKERFILE="${GITLAB_OMNIBUS_DOCKERFILE:-${GITLAB_OMNIBUS_CONTEXT}/Dockerfile}"
GITLAB_OMNIBUS_IMAGE="${GITLAB_OMNIBUS_IMAGE:-gitlab/gitlab-ce:${GITLAB_OMNIBUS_TAG}}"

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
    echo "[gitlab-omnibus] Created ECR repo: ${repo}"
  fi
}

build_or_retag() {
  local context="$1" dockerfile="$2" ecr_uri="$3" tag="$4"
  if [[ -d "${context}" && -f "${dockerfile}" ]]; then
    echo "[gitlab-omnibus] Building ${tag} from ${context} (${IMAGE_ARCH})..."
    docker build \
      --platform "${IMAGE_ARCH}" \
      --label "org.opencontainers.image.title=gitlab-omnibus" \
      --label "org.opencontainers.image.version=${tag}" \
      --label "org.opencontainers.image.vendor=${ECR_PREFIX}" \
      -t "${ecr_uri}:latest" \
      -f "${dockerfile}" "${context}"
  else
    local fallback="${LOCAL_PREFIX}/gitlab-omnibus:latest"
    if ! docker image inspect "${fallback}" >/dev/null 2>&1; then
      echo "[gitlab-omnibus] Local image ${fallback} not found. Run scripts/pull_gitlab_omnibus_image.sh first."
      exit 1
    fi
    echo "[gitlab-omnibus] Context ${context} missing; re-tagging ${fallback} -> ${ecr_uri}:latest"
    docker tag "${fallback}" "${ecr_uri}:latest"
  fi
}

main() {
  local repo="${ECR_PREFIX}/${ECR_REPO_GITLAB_OMNIBUS}"
  local ecr_uri="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${repo}"

  login_ecr
  ensure_repo "${repo}"
  build_or_retag "${GITLAB_OMNIBUS_CONTEXT}" "${GITLAB_OMNIBUS_DOCKERFILE}" "${ecr_uri}" "${GITLAB_OMNIBUS_TAG}"
  docker push "${ecr_uri}:latest"
  echo "[gitlab-omnibus] Pushed ${ecr_uri}:latest"
}

main "$@"
