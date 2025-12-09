#!/usr/bin/env bash
set -euo pipefail

# Create or update a Keycloak OIDC client for a given service and store the
# client_id / client_secret in SSM Parameter Store.
#
# Usage:
#   ./scripts/create_keycloak_client_for_service.sh
#   SERVICE_NAME env is optional; if not set, all values from
#   `terraform output enabled_services` are processed in order.
# Env (optional):
#   AWS_PROFILE            - defaults to terraform output aws_profile or Admin-AIOps
#   AWS_REGION             - defaults to terraform output region or ap-northeast-1
#   NAME_PREFIX            - defaults to terraform output name_prefix or prod-aiops
#   KEYCLOAK_BASE_URL      - defaults to https://keycloak.<hosted_zone_name>
#   KEYCLOAK_REALM         - defaults to master
#   KEYCLOAK_ADMIN_USER    - defaults to SSM /<name_prefix>/keycloak/admin/username
#   KEYCLOAK_ADMIN_PASSWORD- defaults to SSM /<name_prefix>/keycloak/admin/password
#   KC_ADMIN_USER_PARAM    - override SSM param name for admin username (default from terraform output or /<name_prefix>/keycloak/admin/username)
#   KC_ADMIN_PASS_PARAM    - override SSM param name for admin password (default from terraform output or /<name_prefix>/keycloak/admin/password)
#   REDIRECT_URIS          - comma-separated list; default https://<svc>.<hosted_zone_name>/*
#   WEB_ORIGINS            - comma-separated list; default https://<svc>.<hosted_zone_name>
#   ROOT_URL               - default https://<svc>.<hosted_zone_name>
#   CLIENT_NAME            - display name (default: <service-name>)
#   CLIENT_ID_PARAM        - SSM path for client_id (default: /<name_prefix>/<svc>/oidc/client_id)
#   CLIENT_SECRET_PARAM    - SSM path for client_secret (default: /<name_prefix>/<svc>/oidc/client_secret)
#
# Requirements: aws cli, jq, curl

main() {
  SERVICE_NAME="${SERVICE_NAME:-${1:-}}"

  load_enabled_services

  SERVICES_TO_PROCESS=()
  if [[ -n "${SERVICE_NAME}" ]]; then
    SERVICES_TO_PROCESS=("${SERVICE_NAME}")
  else
    if (( ${#ENABLED_SERVICES[@]} > 0 )); then
      SERVICES_TO_PROCESS=("${ENABLED_SERVICES[@]}")
      echo "[info] SERVICE_NAME not provided; processing all enabled services: ${SERVICES_TO_PROCESS[*]}"
    else
      echo "SERVICE_NAME could not be determined; set SERVICE_NAME env or ensure terraform output enabled_services is available." >&2
      exit 1
    fi
  fi

  USER_CLIENT_NAME="${CLIENT_NAME:-}"
  USER_ROOT_URL="${ROOT_URL:-}"
  USER_REDIRECT_URIS="${REDIRECT_URIS:-}"
  USER_WEB_ORIGINS="${WEB_ORIGINS:-}"
  USER_CLIENT_ID_PARAM="${CLIENT_ID_PARAM:-}"
  USER_CLIENT_SECRET_PARAM="${CLIENT_SECRET_PARAM:-}"

  set_env_defaults_global
  ensure_deps
  load_keycloak_admin_params
  fetch_keycloak_admin_creds
  token="$(get_access_token)"

  for svc in "${SERVICES_TO_PROCESS[@]}"; do
    SERVICE_NAME="${svc}"
    set_service_defaults

    client_id="$(ensure_client "${token}")"
    secret="$(get_client_secret "${token}" "${client_id}")"

    put_ssm "${CLIENT_ID_PARAM}" "${SERVICE_NAME}"
    put_ssm "${CLIENT_SECRET_PARAM}" "${secret}"

    echo
    echo "[ok] Client '${SERVICE_NAME}' ensured in realm '${KEYCLOAK_REALM}'."
    echo "     client_id stored at ${CLIENT_ID_PARAM}"
    echo "     client_secret stored at ${CLIENT_SECRET_PARAM}"
    echo
    echo "Redirect URIs set to: ${REDIRECT_URIS}"
    echo "Web origins set to   : ${WEB_ORIGINS}"
    echo
  done
}

load_enabled_services() {
  ENABLED_SERVICES=()
  local json
  json="$(terraform output -json enabled_services 2>/dev/null || true)"
  if [[ -n "${json}" ]]; then
    while IFS= read -r svc; do
      [[ -n "${svc}" ]] && ENABLED_SERVICES+=("${svc}")
    done < <(echo "${json}" | jq -r '.[]' 2>/dev/null || true)
  fi
  if [[ -n "${SERVICE_NAME:-}" && ${#ENABLED_SERVICES[@]} -gt 0 ]]; then
    local match="false"
    for svc in "${ENABLED_SERVICES[@]}"; do
      if [[ "${svc}" == "${SERVICE_NAME}" ]]; then
        match="true"
        break
      fi
    done
    if [[ "${match}" != "true" ]]; then
      echo "[warn] SERVICE_NAME '${SERVICE_NAME}' not found in terraform output enabled_services; continuing anyway" >&2
    fi
  fi
}

set_env_defaults_global() {
  if [[ -z "${AWS_PROFILE:-}" ]]; then
    AWS_PROFILE="$(terraform output -raw aws_profile 2>/dev/null || true)"
  fi
  AWS_PROFILE="${AWS_PROFILE:-Admin-AIOps}"
  export AWS_PROFILE
  export AWS_PAGER=""

  if [[ -z "${AWS_REGION:-}" ]]; then
    AWS_REGION="$(terraform output -raw region 2>/dev/null || echo 'ap-northeast-1')"
  fi
  export AWS_REGION

  if [[ -z "${NAME_PREFIX:-}" ]]; then
    NAME_PREFIX="$(terraform output -raw name_prefix 2>/dev/null || true)"
  fi
  NAME_PREFIX="${NAME_PREFIX:-prod-aiops}"

  if [[ -z "${HOSTED_ZONE_NAME:-}" ]]; then
    HOSTED_ZONE_NAME="$(terraform output -raw hosted_zone_name 2>/dev/null || true)"
  fi
  if [[ -z "${HOSTED_ZONE_NAME}" ]]; then
    echo "HOSTED_ZONE_NAME is required; set env or ensure terraform output hosted_zone_name is available." >&2
    exit 1
  fi

  KEYCLOAK_BASE_URL="${KEYCLOAK_BASE_URL:-https://keycloak.${HOSTED_ZONE_NAME}}"
  KEYCLOAK_REALM="${KEYCLOAK_REALM:-master}"
}

load_keycloak_admin_params() {
  local creds user_param pass_param

  if [[ -z "${KC_ADMIN_USER_PARAM:-}" || -z "${KC_ADMIN_PASS_PARAM:-}" ]]; then
    creds="$(terraform output -json initial_credentials 2>/dev/null || true)"
    if [[ -n "${creds}" ]]; then
      user_param="$(echo "${creds}" | jq -r '.keycloak.username_ssm // empty' 2>/dev/null || true)"
      pass_param="$(echo "${creds}" | jq -r '.keycloak.password_ssm // empty' 2>/dev/null || true)"
    fi
  fi

  KC_ADMIN_USER_PARAM="${KC_ADMIN_USER_PARAM:-${user_param:-/${NAME_PREFIX}/keycloak/admin/username}}"
  KC_ADMIN_PASS_PARAM="${KC_ADMIN_PASS_PARAM:-${pass_param:-/${NAME_PREFIX}/keycloak/admin/password}}"
}

set_service_defaults() {
  local default_root
  default_root="https://${SERVICE_NAME}.${HOSTED_ZONE_NAME}"

  CLIENT_NAME="${USER_CLIENT_NAME:-${SERVICE_NAME}}"
  ROOT_URL="${USER_ROOT_URL:-${default_root}}"
  REDIRECT_URIS="${USER_REDIRECT_URIS:-${ROOT_URL}/*}"
  WEB_ORIGINS="${USER_WEB_ORIGINS:-${ROOT_URL}}"

  CLIENT_ID_PARAM="${USER_CLIENT_ID_PARAM:-/${NAME_PREFIX}/${SERVICE_NAME}/oidc/client_id}"
  CLIENT_SECRET_PARAM="${USER_CLIENT_SECRET_PARAM:-/${NAME_PREFIX}/${SERVICE_NAME}/oidc/client_secret}"
}

ensure_deps() {
  for cmd in aws jq curl; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      echo "Missing dependency: ${cmd}" >&2
      exit 1
    fi
  done
}

fetch_keycloak_admin_creds() {
  if [[ -z "${KEYCLOAK_ADMIN_USER:-}" ]]; then
    KEYCLOAK_ADMIN_USER="$(aws ssm get-parameter --with-decryption --name "${KC_ADMIN_USER_PARAM}" --query Parameter.Value --output text)"
  fi
  if [[ -z "${KEYCLOAK_ADMIN_PASSWORD:-}" ]]; then
    KEYCLOAK_ADMIN_PASSWORD="$(aws ssm get-parameter --with-decryption --name "${KC_ADMIN_PASS_PARAM}" --query Parameter.Value --output text)"
  fi
  if [[ -z "${KEYCLOAK_ADMIN_USER:-}" || -z "${KEYCLOAK_ADMIN_PASSWORD:-}" ]]; then
    echo "Keycloak admin credentials are required; check SSM parameters ${KC_ADMIN_USER_PARAM} and ${KC_ADMIN_PASS_PARAM}." >&2
    exit 1
  fi
}

get_access_token() {
  local url response token err desc
  url="${KEYCLOAK_BASE_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/token"
  response="$(
    curl -sS -X POST "${url}" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "grant_type=password" \
      --data-urlencode "client_id=admin-cli" \
      --data-urlencode "username=${KEYCLOAK_ADMIN_USER}" \
      --data-urlencode "password=${KEYCLOAK_ADMIN_PASSWORD}"
  )"
  token="$(echo "${response}" | jq -r '.access_token // empty' 2>/dev/null || true)"

  if [[ -z "${token}" || "${token}" == "null" ]]; then
    err="$(echo "${response}" | jq -r '.error // empty' 2>/dev/null || true)"
    desc="$(echo "${response}" | jq -r '.error_description // empty' 2>/dev/null || true)"
    echo "Failed to obtain access token from Keycloak at ${KEYCLOAK_BASE_URL} (realm: ${KEYCLOAK_REALM})." >&2
    [[ -n "${err}" ]] && echo "  error        : ${err}" >&2
    [[ -n "${desc}" ]] && echo "  description  : ${desc}" >&2
    if [[ -z "${err}" && -z "${desc}" && -n "${response}" ]]; then
      echo "  raw response : ${response}" >&2
    fi
    exit 1
  fi

  echo "${token}"
}

json_array_from_csv() {
  local csv="$1"
  jq -nc --arg csv "${csv}" '$csv | split(",") | map(gsub("^\\s+|\\s+$";"")) | map(select(. != ""))'
}

build_client_payload() {
  local redirects origins
  redirects="$(json_array_from_csv "${REDIRECT_URIS}")"
  origins="$(json_array_from_csv "${WEB_ORIGINS}")"
  jq -nc \
    --arg clientId "${SERVICE_NAME}" \
    --arg name "${CLIENT_NAME}" \
    --arg rootUrl "${ROOT_URL}" \
    --argjson redirectUris "${redirects}" \
    --argjson webOrigins "${origins}" \
    '{
      clientId: $clientId,
      name: $name,
      protocol: "openid-connect",
      publicClient: false,
      bearerOnly: false,
      standardFlowEnabled: true,
      implicitFlowEnabled: false,
      directAccessGrantsEnabled: false,
      serviceAccountsEnabled: false,
      rootUrl: $rootUrl,
      redirectUris: $redirectUris,
      webOrigins: $webOrigins,
      attributes: {
        "pkce.code.challenge.method": "S256"
      }
    }'
}

find_client_id() {
  local token="$1"
  local response id error_msg
  response="$(curl -sS -G "${KEYCLOAK_BASE_URL}/admin/realms/${KEYCLOAK_REALM}/clients" \
    -H "Authorization: Bearer ${token}" \
    --data-urlencode "clientId=${SERVICE_NAME}")"
  id="$(echo "${response}" | jq -r '
    if type == "array" then (.[0].id // empty)
    elif type == "object" then (.id // empty)
    else empty end
  ' 2>/dev/null || true)"
  if [[ -z "${id}" && -n "${response}" ]]; then
    error_msg="$(echo "${response}" | jq -r 'if has("error") then .error else empty end' 2>/dev/null || true)"
    if [[ -n "${error_msg}" ]]; then
      echo "[keycloak] Client lookup returned error: ${error_msg}" >&2
    else
      echo "[keycloak] Unexpected client lookup response: ${response}" >&2
    fi
  fi
  echo "${id}"
}

ensure_client() {
  local token="$1" id payload
  payload="$(build_client_payload)"
  id="$(find_client_id "${token}")"

  if [[ -z "${id}" ]]; then
    echo "[keycloak] Creating client ${SERVICE_NAME} in realm ${KEYCLOAK_REALM}..."
    curl -sS -X POST "${KEYCLOAK_BASE_URL}/admin/realms/${KEYCLOAK_REALM}/clients" \
      -H "Authorization: Bearer ${token}" \
      -H "Content-Type: application/json" \
      -d "${payload}" >/dev/null
    id="$(find_client_id "${token}")"
  else
    echo "[keycloak] Updating client ${SERVICE_NAME} in realm ${KEYCLOAK_REALM}..."
    curl -sS -X PUT "${KEYCLOAK_BASE_URL}/admin/realms/${KEYCLOAK_REALM}/clients/${id}" \
      -H "Authorization: Bearer ${token}" \
      -H "Content-Type: application/json" \
      -d "${payload}" >/dev/null
  fi

  if [[ -z "${id}" ]]; then
    echo "Failed to create or find client ${SERVICE_NAME}" >&2
    exit 1
  fi
  echo "${id}"
}

get_client_secret() {
  local token="$1" id="$2"
  local path
  path="$(python3 -c "import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1], safe=''))" "$id")/client-secret"
  curl -sS -X GET "${KEYCLOAK_BASE_URL}/admin/realms/${KEYCLOAK_REALM}/clients/${path}" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" | jq -r '.value'
}

put_ssm() {
  local name="$1" value="$2"
  aws ssm put-parameter \
    --name "${name}" \
    --type SecureString \
    --value "${value}" \
    --overwrite >/dev/null
}

main "$@"
