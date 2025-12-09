#!/usr/bin/env bash
set -euo pipefail

# Build the main-svc image from the exported filesystem (images/main-svc) and push it to ECR.
# Falls back to retagging the local image produced by pull_mainsvc_image.sh if the export is missing.
#
# Optional environment variables:
#   AWS_PROFILE, AWS_ACCOUNT_ID, AWS_REGION, ECR_PREFIX, ECR_REPO_MAIN_SVC
#   LOCAL_PREFIX, MAIN_SVC_CONTEXT, MAIN_SVC_IMAGE_TAG, IMAGE_ARCH

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
if [ -z "${ECR_REPO_MAIN_SVC:-}" ]; then
  ECR_REPO_MAIN_SVC="$(terraform output -raw ecr_repo_main_svc 2>/dev/null || echo "main-svc")"
fi
LOCAL_PREFIX="${LOCAL_PREFIX:-local}"
MAIN_SVC_CONTEXT="${MAIN_SVC_CONTEXT:-./images/main-svc}"

if [ -z "${MAIN_SVC_IMAGE_TAG:-}" ]; then
  MAIN_SVC_IMAGE_TAG="$(terraform output -raw main_svc_image_tag 2>/dev/null || echo "latest")"
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
    echo "[main-svc] Created ECR repo: ${repo}"
  fi
}

build_or_retag() {
  local context="$1" ecr_uri="$2" tag="$3"
  local fallback="${LOCAL_PREFIX}/main-svc:latest"

  if [ -d "${context}" ]; then
    echo "[main-svc] Building ${tag} from ${context} (${IMAGE_ARCH})..."
    docker build \
      --platform "${IMAGE_ARCH}" \
      --label "org.opencontainers.image.title=main-svc" \
      --label "org.opencontainers.image.version=${tag}" \
      --label "org.opencontainers.image.vendor=${ECR_PREFIX}" \
      -t "${ecr_uri}:latest" \
      -f - "${context}" <<'EOF'
FROM scratch
COPY . /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
EOF
  else
    if ! docker image inspect "${fallback}" >/dev/null 2>&1; then
      echo "[main-svc] Context ${context} not found and fallback image ${fallback} missing. Run scripts/pull_mainsvc_image.sh first."
      exit 1
    fi
    echo "[main-svc] Context ${context} missing; re-tagging ${fallback} -> ${ecr_uri}:latest"
    docker tag "${fallback}" "${ecr_uri}:latest"
  fi
}

main() {
  local repo="${ECR_PREFIX}/${ECR_REPO_MAIN_SVC}"
  local ecr_uri="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${repo}"

  login_ecr
  ensure_repo "${repo}"
  build_or_retag "${MAIN_SVC_CONTEXT}" "${ecr_uri}" "${MAIN_SVC_IMAGE_TAG}"
  docker push "${ecr_uri}:latest"
  echo "[main-svc] Pushed ${ecr_uri}:latest"
}

main "$@"
