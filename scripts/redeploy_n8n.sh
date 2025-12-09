#!/usr/bin/env bash
set -euo pipefail

# Redeploy n8n ECS service by forcing a new deployment.
# AWS_PROFILE resolution: env > terraform output aws_profile > Admin-AIOps.

if [ -z "${AWS_PROFILE:-}" ]; then
  AWS_PROFILE="$(terraform output -raw aws_profile 2>/dev/null || true)"
fi
AWS_PROFILE="${AWS_PROFILE:-Admin-AIOps}"
export AWS_PROFILE
export AWS_PAGER=""

REGION="$(terraform output -raw region 2>/dev/null || true)"
REGION="${REGION:-${AWS_REGION:-${AWS_DEFAULT_REGION:-ap-northeast-1}}}"

CLUSTER_JSON="$(terraform output -json ecs_cluster 2>/dev/null || true)"
CLUSTER_NAME="$(echo "${CLUSTER_JSON}" | jq -r '.name // empty')"
CLUSTER_NAME="${CLUSTER_NAME:-prod-aiops-ecs}"

NAME_PREFIX="${CLUSTER_NAME%-ecs}"
if [ -z "${NAME_PREFIX}" ] || [ "${NAME_PREFIX}" = "${CLUSTER_NAME}" ]; then
  NAME_PREFIX="prod-aiops"
fi

SERVICE_NAME="${NAME_PREFIX}-n8n"

# Use the current desired count to avoid accidental scaling changes.
CURRENT_DESIRED="$(aws ecs describe-services \
  --no-cli-pager \
  --region "${REGION}" \
  --cluster "${CLUSTER_NAME}" \
  --services "${SERVICE_NAME}" \
  --query 'services[0].desiredCount' \
  --output text 2>/dev/null || true)"
if [ "${CURRENT_DESIRED}" = "None" ] || [ -z "${CURRENT_DESIRED}" ]; then
  CURRENT_DESIRED=""
fi

echo "Using AWS_PROFILE=${AWS_PROFILE}, REGION=${REGION}, CLUSTER=${CLUSTER_NAME}, SERVICE=${SERVICE_NAME}, desired_count=${CURRENT_DESIRED:-<unchanged>}"

ARGS=(--no-cli-pager --region "${REGION}" --cluster "${CLUSTER_NAME}" --service "${SERVICE_NAME}" --force-new-deployment)
if [ -n "${CURRENT_DESIRED}" ]; then
  ARGS+=(--desired-count "${CURRENT_DESIRED}")
fi

aws ecs update-service "${ARGS[@]}"

echo "Triggered deployment for ${SERVICE_NAME}"
