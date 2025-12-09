#!/usr/bin/env bash
set -euo pipefail

# Redeploy zulip ECS service by forcing a new deployment.
#
# Environment overrides:
#   AWS_PROFILE, AWS_REGION, NAME_PREFIX

if [ -z "${AWS_PROFILE:-}" ]; then
  AWS_PROFILE="$(terraform output -raw aws_profile 2>/dev/null || true)"
fi
AWS_PROFILE="${AWS_PROFILE:-Admin-AIOps}"
export AWS_PROFILE

AWS_REGION="${AWS_REGION:-ap-northeast-1}"

if [ -z "${NAME_PREFIX:-}" ]; then
  NAME_PREFIX="$(terraform output -raw name_prefix 2>/dev/null || true)"
fi
NAME_PREFIX="${NAME_PREFIX:-prod-aiops}"

if [ -z "${ECS_CLUSTER_NAME:-}" ]; then
  ECS_CLUSTER_NAME="$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "${NAME_PREFIX}-ecs")"
fi

SERVICE_NAME="${NAME_PREFIX}-zulip"

echo "[zulip] Forcing new deployment for ${SERVICE_NAME} in ${ECS_CLUSTER_NAME}"
aws ecs update-service \
  --cluster "${ECS_CLUSTER_NAME}" \
  --service "${SERVICE_NAME}" \
  --force-new-deployment \
  --region "${AWS_REGION}" >/dev/null

echo "[zulip] Redeploy triggered."
