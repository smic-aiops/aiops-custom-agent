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

KEYCLOAK_SKIP_CURRENT_SERVICE="false"
KEYCLOAK_LAST_STATUS=""
SERVICE_URLS_JSON=""

tfvars_var_name_for_service() {
  case "$1" in
    exastro-web) echo "exastro_web_oidc_idps_yaml" ;;
    exastro-api) echo "exastro_api_oidc_idps_yaml" ;;
    sulu) echo "sulu_oidc_idps_yaml" ;;
    keycloak) echo "keycloak_oidc_idps_yaml" ;;
    odoo) echo "odoo_oidc_idps_yaml" ;;
    pgadmin) echo "pgadmin_oidc_idps_yaml" ;;
    gitlab) echo "gitlab_oidc_idps_yaml" ;;
    growi) echo "growi_oidc_idps_yaml" ;;
    cmdbuild-r2u) echo "cmdbuild_r2u_oidc_idps_yaml" ;;
    orangehrm) echo "orangehrm_oidc_idps_yaml" ;;
    zulip) echo "zulip_oidc_idps_yaml" ;;
    *) echo "" ;;
  esac
}

item_in_list() {
  local target="$1"
  shift
  for item in "$@"; do
    if [[ "${item}" == "${target}" ]]; then
      return 0
    fi
  done
  return 1
}

main() {
  SERVICE_NAME="${SERVICE_NAME:-${1:-}}"

  load_enabled_services
  load_service_urls

  SERVICES_TO_PROCESS=()
  if [[ -n "${SERVICE_NAME}" ]]; then
    SERVICES_TO_PROCESS=("${SERVICE_NAME}")
  else
    if (( ${#ENABLED_SERVICES[@]} > 0 )); then
      SERVICES_TO_PROCESS=("${ENABLED_SERVICES[@]}")
      if ! item_in_list "service-control" "${SERVICES_TO_PROCESS[@]}"; then
        SERVICES_TO_PROCESS+=("service-control")
      fi
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
  USER_DIRECT_GRANTS_ENABLED="${DIRECT_GRANTS_ENABLED:-}"

  set_env_defaults_global
  ensure_deps
  load_keycloak_admin_params
  fetch_keycloak_admin_creds
  token="$(get_access_token)"

  for svc in "${SERVICES_TO_PROCESS[@]}"; do
    case "${svc}" in
      n8n)
        echo "[info] Skipping ${svc}; SSO client provisioning is not managed for this service."
        continue
        ;;
    esac
    KEYCLOAK_SKIP_CURRENT_SERVICE="false"
    SERVICE_NAME="${svc}"
    set_service_defaults

    client_internal_id="$(ensure_client "${token}")"
    if [[ "${KEYCLOAK_SKIP_CURRENT_SERVICE}" == "true" ]]; then
      echo "[warn] Skipping ${SERVICE_NAME} because Keycloak returned 502." >&2
      continue
    fi

    secret="$(get_client_secret "${token}" "${client_internal_id}")"
    if [[ "${KEYCLOAK_SKIP_CURRENT_SERVICE}" == "true" ]]; then
      echo "[warn] Skipping ${SERVICE_NAME} because Keycloak returned 502 when fetching client secret." >&2
      continue
    fi

    put_ssm "${CLIENT_ID_PARAM}" "${SERVICE_NAME}"
    if [[ -n "${secret}" ]]; then
      put_ssm "${CLIENT_SECRET_PARAM}" "${secret}"
    else
      echo "[info] No client_secret returned for ${SERVICE_NAME}; skipping secret storage (public client)."
    fi
    if [[ "${SERVICE_NAME}" == "phpmyadmin" && -n "${secret}" ]]; then
      update_tfvars_scalar "phpmyadmin_oidc_client_id" "${SERVICE_NAME}"
    fi
    update_tfvars_oidc_yaml "${SERVICE_NAME}" "${secret}"
    update_tfvars_client_secret "${SERVICE_NAME}" "${secret}"

    echo
    echo "[ok] Client '${SERVICE_NAME}' ensured in realm '${KEYCLOAK_REALM}'."
    echo "     client_id stored at ${CLIENT_ID_PARAM}"
    echo "     client_secret stored at ${CLIENT_SECRET_PARAM}"
    echo
    echo "Redirect URIs set to: ${REDIRECT_URIS}"
    echo "Web origins set to   : ${WEB_ORIGINS}"
    echo "PKCE                 : disabled (pkce.code.challenge.method cleared, required=false)"
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

load_service_urls() {
  SERVICE_URLS_JSON="$(terraform output -json service_urls 2>/dev/null || true)"
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
  local default_root default_redirect default_web_origin service_key service_url WEB_ORIGINS_VALUE REDIRECT_URIS_VALUE
  service_key="${SERVICE_NAME//-/_}"
  service_url=""
  if [[ -n "${SERVICE_URLS_JSON}" ]]; then
    service_url="$(echo "${SERVICE_URLS_JSON}" | jq -r --arg key "${service_key}" '.[$key] // empty' 2>/dev/null || true)"
  fi
  if [[ -n "${service_url}" ]]; then
    service_url="${service_url%/}"
  fi
  if [[ -n "${service_url}" ]]; then
    default_root="${service_url}"
  else
    default_root="https://${SERVICE_NAME}.${HOSTED_ZONE_NAME}"
  fi
  default_root="${default_root%/}"

  if [[ "${SERVICE_NAME}" == "service-control" ]]; then
    default_root="https://control.${HOSTED_ZONE_NAME}"
  fi

  CLIENT_NAME="${USER_CLIENT_NAME:-${SERVICE_NAME}}"
  ROOT_URL="${USER_ROOT_URL:-${default_root}}"
  ROOT_URL="${ROOT_URL%/}"
  default_web_origin="${ROOT_URL}"
  default_redirect="${ROOT_URL}/*"
  DIRECT_GRANTS_ENABLED="${USER_DIRECT_GRANTS_ENABLED:-false}"
  WEB_ORIGINS_VALUE="${USER_WEB_ORIGINS:-${default_web_origin}}"
  REDIRECT_URIS_VALUE="${USER_REDIRECT_URIS:-}"
  case "${SERVICE_NAME}" in
    service-control)
      CLIENT_NAME="${USER_CLIENT_NAME:-サービスコントロール}"
      DIRECT_GRANTS_ENABLED="true"
      local required_origin="https://control.${HOSTED_ZONE_NAME}"
      WEB_ORIGINS_VALUE="$(merge_csv_values "${WEB_ORIGINS_VALUE}" "${required_origin}")"
      if [[ -n "${USER_SERVICE_CONTROL_REDIRECT_URIS:-}" ]]; then
        REDIRECT_URIS_VALUE="${USER_SERVICE_CONTROL_REDIRECT_URIS}"
      fi
      ;;
    growi)
      default_redirect="${ROOT_URL}/_api/v3/auth/oidc/callback"
      ;;
    odoo)
      default_redirect="${ROOT_URL}/auth_oauth/signin"
      ;;
    gitlab)
      default_redirect="${ROOT_URL}/users/auth/openid_connect/callback"
      ;;
    zulip)
      default_redirect="${ROOT_URL}/complete/oidc/"
      ;;
    phpmyadmin)
      default_root="https://phpmyadmin.${HOSTED_ZONE_NAME}"
      default_redirect="https://phpmyadmin.${HOSTED_ZONE_NAME}/oauth2/idpresponse"
      default_web_origin="https://phpmyadmin.${HOSTED_ZONE_NAME}"
      ;;
  esac

  if [[ -z "${REDIRECT_URIS_VALUE}" ]]; then
    REDIRECT_URIS_VALUE="${default_redirect}"
  fi

  REDIRECT_URIS="${REDIRECT_URIS_VALUE:-${default_redirect}}"
  WEB_ORIGINS="${WEB_ORIGINS_VALUE:-${default_web_origin}}"

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

keycloak_curl() {
  local tmp status
  tmp="$(mktemp)"
  if ! status="$(curl -sS "$@" -o "${tmp}" -w "%{http_code}")"; then
    rm -f "${tmp}"
    KEYCLOAK_LAST_STATUS=""
    return 1
  fi
  KEYCLOAK_LAST_STATUS="${status}"
  cat "${tmp}"
  rm -f "${tmp}"
}

mark_keycloak_502_skip() {
  local action="$1"
  if [[ "${KEYCLOAK_LAST_STATUS}" == "502" ]]; then
    local svc="${SERVICE_NAME:-current service}"
    echo "[warn] Keycloak returned 502 during ${action}; skipping ${svc}." >&2
    KEYCLOAK_SKIP_CURRENT_SERVICE="true"
    return 0
  fi
  return 1
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
    keycloak_curl -X POST "${url}" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "grant_type=password" \
      --data-urlencode "client_id=admin-cli" \
      --data-urlencode "username=${KEYCLOAK_ADMIN_USER}" \
      --data-urlencode "password=${KEYCLOAK_ADMIN_PASSWORD}"
  )"
  if [[ "${KEYCLOAK_LAST_STATUS}" == "502" ]]; then
    echo "[warn] Keycloak token endpoint returned 502; aborting. Try again after Keycloak recovers." >&2
    exit 1
  fi
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
  jq -nc --arg csv "${csv}" '$csv | split(",") | map(gsub("^\\s+|\\s+$";"")) | map(gsub("^'\''|'\''$";"")) | map(select(. != ""))'
}

merge_csv_values() {
  local base="${1:-}"
  shift
  python3 - <<'PY' "${base}" "$@"
import sys

parts = []
for raw in sys.argv[1:]:
    for item in raw.split(","):
        val = item.strip().strip("'\"")
        if val:
            parts.append(val)

seen = []
for val in parts:
    if val not in seen:
        seen.append(val)

print(",".join(seen))
PY
}

build_client_payload() {
  local redirects origins
  redirects="$(json_array_from_csv "${REDIRECT_URIS}")"
  origins="$(json_array_from_csv "${WEB_ORIGINS}")"
  local attributes_json='{"pkce.code.challenge.method":"","pkce.code.challenge.required":"false"}'
  local public_client="false"
  if [[ "${SERVICE_NAME}" == "service-control" ]]; then
    public_client="true"
  fi
  jq -nc \
    --arg clientId "${SERVICE_NAME}" \
    --arg name "${CLIENT_NAME}" \
    --arg rootUrl "${ROOT_URL}" \
    --argjson redirectUris "${redirects}" \
    --argjson webOrigins "${origins}" \
    --argjson attributes "${attributes_json}" \
    --argjson directGrants "${DIRECT_GRANTS_ENABLED}" \
    --argjson publicClient "${public_client}" \
    '{
      clientId: $clientId,
      name: $name,
      protocol: "openid-connect",
      publicClient: $publicClient,
      bearerOnly: false,
      standardFlowEnabled: true,
      implicitFlowEnabled: false,
      directAccessGrantsEnabled: $directGrants,
      serviceAccountsEnabled: false,
      rootUrl: $rootUrl,
      redirectUris: $redirectUris,
      webOrigins: $webOrigins,
      attributes: $attributes
    }'
}

find_client_id() {
  local token="$1"
  local response id error_msg
  response="$(keycloak_curl -G "${KEYCLOAK_BASE_URL}/admin/realms/${KEYCLOAK_REALM}/clients" \
    -H "Authorization: Bearer ${token}" \
    --data-urlencode "clientId=${SERVICE_NAME}")"
  if mark_keycloak_502_skip "client lookup"; then
    echo ""
    return
  fi
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
  if [[ "${KEYCLOAK_SKIP_CURRENT_SERVICE}" == "true" ]]; then
    return
  fi

  if [[ -z "${id}" ]]; then
    echo "[keycloak] Creating client ${SERVICE_NAME} in realm ${KEYCLOAK_REALM}..." >&2
    keycloak_curl -X POST "${KEYCLOAK_BASE_URL}/admin/realms/${KEYCLOAK_REALM}/clients" \
      -H "Authorization: Bearer ${token}" \
      -H "Content-Type: application/json" \
      -d "${payload}" >/dev/null
    if mark_keycloak_502_skip "client creation"; then
      return
    fi
    id="$(find_client_id "${token}")"
    if [[ "${KEYCLOAK_SKIP_CURRENT_SERVICE}" == "true" ]]; then
      return
    fi
  else
    echo "[keycloak] Updating client ${SERVICE_NAME} in realm ${KEYCLOAK_REALM}..." >&2
    keycloak_curl -X PUT "${KEYCLOAK_BASE_URL}/admin/realms/${KEYCLOAK_REALM}/clients/${id}" \
      -H "Authorization: Bearer ${token}" \
      -H "Content-Type: application/json" \
      -d "${payload}" >/dev/null
    if mark_keycloak_502_skip "client update"; then
      return
    fi
  fi

  if [[ -z "${id}" && "${KEYCLOAK_SKIP_CURRENT_SERVICE}" != "true" ]]; then
    echo "Failed to create or find client ${SERVICE_NAME}" >&2
    exit 1
  fi
  echo "${id}"
}

get_client_secret() {
  local token="$1" id="$2" response path
  path="$(python3 -c "import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1], safe=''))" "$id")/client-secret"
  response="$(keycloak_curl -X GET "${KEYCLOAK_BASE_URL}/admin/realms/${KEYCLOAK_REALM}/clients/${path}" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json")"
  if mark_keycloak_502_skip "client secret fetch"; then
    echo ""
    return
  fi
  echo "${response}" | jq -r '.value'
}

put_ssm() {
  local name="$1" value="$2"
  aws ssm put-parameter \
    --name "${name}" \
    --type SecureString \
    --value "${value}" \
    --overwrite >/dev/null
}

update_tfvars_client_secret() {
  local service="$1" secret="$2" var_name
  if [[ -z "${secret}" ]]; then
    return
  fi
  case "${service}" in
    zulip) var_name="zulip_oidc_client_secret" ;;
    phpmyadmin) var_name="phpmyadmin_oidc_client_secret" ;;
    *) return ;;
  esac
  update_tfvars_scalar "${var_name}" "${secret}"
}

update_tfvars_scalar() {
  local var_name="$1" value="$2" tfvars_file
  if [[ -z "${value}" ]]; then
    return
  fi
  if [[ "${SKIP_TFVARS_UPDATE:-}" == "true" ]]; then
    return
  fi
  tfvars_file="${TFVARS_FILE:-terraform.tfvars}"
  if [[ ! -f "${tfvars_file}" ]]; then
    echo "[warn] tfvars file '${tfvars_file}' not found; skipping ${var_name} update." >&2
    return
  fi
  echo "[info] Updating ${tfvars_file} (${var_name}) with current Keycloak client info."
  TFVARS_FILE_PATH="${tfvars_file}" TFVARS_VAR_NAME="${var_name}" TFVARS_VALUE="${value}" python3 - <<'PY'
import json
import os
import re

file_path = os.environ["TFVARS_FILE_PATH"]
var_name = os.environ["TFVARS_VAR_NAME"]
value = os.environ["TFVARS_VALUE"]
line = f"{var_name} = {json.dumps(value)}"

with open(file_path, "r", encoding="utf-8") as f:
    data = f.read()

pattern = re.compile(rf'^{re.escape(var_name)}\s*=.*$', re.MULTILINE)
if pattern.search(data):
    new_data = pattern.sub(line, data, count=1)
else:
    if data and not data.endswith("\n"):
        data += "\n"
    if data and not data.endswith("\n\n"):
        data += "\n"
    new_data = data + line + "\n"

with open(file_path, "w", encoding="utf-8") as f:
    f.write(new_data)
PY
}

update_tfvars_oidc_yaml() {
  local service="$1" secret="$2" var_name tfvars yaml tfvars_file
  if [[ -z "${secret}" ]]; then
    return
  fi
  if [[ "${SKIP_TFVARS_UPDATE:-}" == "true" ]]; then
    return
  fi
  var_name="$(tfvars_var_name_for_service "${service}")"
  if [[ -z "${var_name}" ]]; then
    return
  fi
  tfvars_file="${TFVARS_FILE:-terraform.tfvars}"
  if [[ ! -f "${tfvars_file}" ]]; then
    echo "[warn] tfvars file '${tfvars_file}' not found; skipping ${var_name} update." >&2
    return
  fi
  yaml="$(build_service_idps_yaml "${service}" "${service}" "${secret}")"
  if [[ -z "${yaml}" ]]; then
    echo "[warn] Could not build idps YAML for ${service}; skipping tfvars update." >&2
    return
  fi
  echo "[info] Updating ${tfvars_file} (${var_name}) with current Keycloak credentials."
  TFVARS_FILE_PATH="${tfvars_file}" TFVARS_VAR_NAME="${var_name}" TFVARS_BLOCK_CONTENT="${yaml}" python3 - <<'PY'
import os
import re

file_path = os.environ["TFVARS_FILE_PATH"]
var_name = os.environ["TFVARS_VAR_NAME"]
content = os.environ["TFVARS_BLOCK_CONTENT"].rstrip() + "\n"
block = f"{var_name} = <<YAML\n{content}YAML\n"
with open(file_path, "r", encoding="utf-8") as f:
    data = f.read()
pattern = re.compile(rf'^{re.escape(var_name)}\s*=\s*<<YAML.*?\nYAML\n', re.MULTILINE | re.DOTALL)
if pattern.search(data):
    new_data = pattern.sub(block, data, count=1)
else:
    if data and not data.endswith("\n"):
        data += "\n"
    if data and not data.endswith("\n\n"):
        data += "\n"
    new_data = data + block
with open(file_path, "w", encoding="utf-8") as f:
    f.write(new_data)
PY
}

build_service_idps_yaml() {
  local service="$1" client_id="$2" secret="$3"
  if [[ -z "${service}" || -z "${client_id}" || -z "${secret}" ]]; then
    echo ""
    return
  fi
  cat <<EOF
keycloak: {oidc_url: ${KEYCLOAK_BASE_URL}/realms/${KEYCLOAK_REALM}, display_name: Keycloak, client_id: ${client_id}, secret: ${secret}, api_url: ${KEYCLOAK_BASE_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/userinfo, extra_params: {scope: "openid email profile"}}
EOF
}

main "$@"
