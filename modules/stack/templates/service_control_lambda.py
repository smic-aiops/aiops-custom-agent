import json
import os
import re
import urllib.error
import urllib.parse
import urllib.request

import boto3

ecs = boto3.client("ecs")
elbv2 = boto3.client("elbv2")
ecr = boto3.client("ecr")
ssm = boto3.client("ssm")

CLUSTER_ARN = os.environ["CLUSTER_ARN"]
START_DESIRED = int(os.environ.get("START_DESIRED", "1"))
SERVICE_CONTROL_SSM_PATH = os.environ.get("SERVICE_CONTROL_SSM_PATH", "")
KEYCLOAK_BASE_URL = os.environ.get("KEYCLOAK_BASE_URL", "").rstrip("/")
KEYCLOAK_REALM = os.environ.get("KEYCLOAK_REALM", "").strip("/")
KEYCLOAK_CLIENT_ID = os.environ.get("KEYCLOAK_CLIENT_ID", "")
KEYCLOAK_ADMIN_USERNAME_PARAMETER = os.environ.get("KEYCLOAK_ADMIN_USERNAME_SSM_PARAMETER")
KEYCLOAK_ADMIN_PASSWORD_PARAMETER = os.environ.get("KEYCLOAK_ADMIN_PASSWORD_SSM_PARAMETER")
KEYCLOAK_TOKEN_ENDPOINT = f"{KEYCLOAK_BASE_URL}/realms/{KEYCLOAK_REALM}/protocol/openid-connect/token"
ODOO_ADMIN_USERNAME = os.environ.get("ODOO_ADMIN_USERNAME", "admin")
ODOO_ADMIN_PASSWORD_PARAMETER = os.environ.get("ODOO_ADMIN_PASSWORD_SSM_PARAMETER")
ORANGEHRM_ADMIN_USERNAME_PARAMETER = os.environ.get("ORANGEHRM_ADMIN_USERNAME_SSM_PARAMETER")
ORANGEHRM_ADMIN_PASSWORD_PARAMETER = os.environ.get("ORANGEHRM_ADMIN_PASSWORD_SSM_PARAMETER")


def _load_json_config(env_key, ssm_param_env_key, default=None):
    default = default or {}
    raw = os.environ.get(env_key)
    if raw:
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            print({"warning": f"{env_key} is not valid JSON"})
    param_name = os.environ.get(ssm_param_env_key)
    if param_name:
        try:
            resp = ssm.get_parameter(Name=param_name)
            return json.loads(resp["Parameter"]["Value"])
        except ssm.exceptions.ParameterNotFound:
            print({"warning": "ssm parameter not found", "parameter": param_name})
        except Exception as exc:  # pylint: disable=broad-except
            print({"warning": "failed to load ssm parameter", "parameter": param_name, "error": str(exc)})
    return default.copy() if isinstance(default, dict) else default


SERVICE_ARNS = _load_json_config("SERVICE_ARNS", "SERVICE_ARNS_SSM_PARAMETER", {})
TARGET_GROUP_ARNS = _load_json_config("TARGET_GROUP_ARNS", "TARGET_GROUP_ARNS_SSM_PARAMETER", {})


def _response(status, body):
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
        },
        "body": json.dumps(body),
    }


def _get_service_arn(service_key):
    service_arn = SERVICE_ARNS.get(service_key)
    if not service_arn:
        raise ValueError(f"unknown service: {service_key}")
    return service_arn


def _get_target_group_arn(service_key):
    # TG が未設定の場合もサービスの状態取得はできるよう None を返す
    return TARGET_GROUP_ARNS.get(service_key) or None


def _describe(service_arn):
    resp = ecs.describe_services(cluster=CLUSTER_ARN, services=[service_arn])
    services = resp.get("services", [])
    failures = resp.get("failures", [])
    if not services:
        reason = failures[0].get("reason", "NOT_FOUND") if failures else "NOT_FOUND"
        raise ValueError(f"service not found: {service_arn} ({reason})")
    svc = services[0]

    image = None
    image_tag = None
    ecr_latest_tag = None
    task_def_arn = svc.get("taskDefinition")
    if task_def_arn:
        try:
            td = ecs.describe_task_definition(taskDefinition=task_def_arn).get("taskDefinition", {})
            containers = td.get("containerDefinitions", [])
            target = next((c for c in containers if c.get("essential", True) and c.get("image")), None) or (containers[0] if containers else None)
            image = target.get("image") if target else None
            if image:
                image_tag = image.rsplit(":", 1)[-1] if ":" in image else image
                # ECR の最新タグを取得（イメージが ECR の場合のみ）
                try:
                    parts = image.split("/", 1)
                    if len(parts) == 2 and ".dkr.ecr." in parts[0]:
                        repository = parts[1].split(":")[0]
                        latest_detail = None
                        paginator = ecr.get_paginator("describe_images")
                        for page in paginator.paginate(repositoryName=repository, PaginationConfig={"PageSize": 100}):
                            for detail in page.get("imageDetails", []):
                                pushed = detail.get("imagePushedAt")
                                if not pushed:
                                    continue
                                if latest_detail is None or pushed > latest_detail.get("imagePushedAt"):
                                    latest_detail = detail
                        if latest_detail:
                            tags = latest_detail.get("imageTags") or []
                            ecr_latest_tag = tags[0] if tags else None
                except Exception as exc:  # pylint: disable=broad-except
                    print({"warning": "ecr_describe_images failed", "error": str(exc), "image": image})
        except Exception as exc:  # pylint: disable=broad-except
            print({"warning": "describe_task_definition failed", "error": str(exc)})

    return {
        "desiredCount": svc.get("desiredCount", 0),
        "runningCount": svc.get("runningCount", 0),
        "status": svc.get("status", "UNKNOWN"),
        "image": image,
        "imageTag": image_tag,
        "ecrLatestTag": ecr_latest_tag,
    }


def _describe_tg_health(tg_arn):
    resp = elbv2.describe_target_health(TargetGroupArn=tg_arn)
    health = resp.get("TargetHealthDescriptions", [])
    summary = {
        "healthy": 0,
        "unhealthy": 0,
        "initial": 0,
        "draining": 0,
        "unused": 0,
        "unknown": 0,
        "total": len(health),
    }
    details = []
    for h in health:
        state = h.get("TargetHealth", {}).get("State", "unknown")
        summary[state] = summary.get(state, 0) + 1
        details.append(
            {
                "id": h.get("Target", {}).get("Id"),
                "port": h.get("Target", {}).get("Port"),
                "state": state,
                "reason": h.get("TargetHealth", {}).get("Reason"),
                "description": h.get("TargetHealth", {}).get("Description"),
            }
        )
    return {"summary": summary, "targets": details}

def _load_ssm_parameter_value(name, label):
    if not name:
        return None
    try:
        resp = ssm.get_parameter(Name=name, WithDecryption=True)
        return resp.get("Parameter", {}).get("Value")
    except Exception as exc:  # pylint: disable=broad-except
        print({"warning": f"failed to load {label}", "parameter": name, "error": str(exc)})
        return None


def _get_db_credentials():
    username_param = os.environ.get("DB_USERNAME_SSM_PARAMETER")
    password_param = os.environ.get("DB_PASSWORD_SSM_PARAMETER")
    if not username_param or not password_param:
        return {"username": None, "password": None}
    return {
        "username": _load_ssm_parameter_value(username_param, "db username"),
        "password": _load_ssm_parameter_value(password_param, "db password"),
    }


def _get_keycloak_admin_credentials():
    return {
        "username": _load_ssm_parameter_value(KEYCLOAK_ADMIN_USERNAME_PARAMETER, "Keycloak admin username"),
        "password": _load_ssm_parameter_value(KEYCLOAK_ADMIN_PASSWORD_PARAMETER, "Keycloak admin password"),
    }

def _get_odoo_admin_credentials():
    return {
        "username": ODOO_ADMIN_USERNAME,
        "password": _load_ssm_parameter_value(ODOO_ADMIN_PASSWORD_PARAMETER, "Odoo admin password"),
    }


def _get_orangehrm_admin_credentials():
    return {
        "username": _load_ssm_parameter_value(ORANGEHRM_ADMIN_USERNAME_PARAMETER, "OrangeHRM admin username"),
        "password": _load_ssm_parameter_value(ORANGEHRM_ADMIN_PASSWORD_PARAMETER, "OrangeHRM admin password"),
    }


def _update(service_arn, desired):
    ecs.update_service(cluster=CLUSTER_ARN, service=service_arn, desiredCount=desired)
    return _describe(service_arn)

def _schedule_parameter_name(service_key):
    return f"{SERVICE_CONTROL_SSM_PATH.rstrip('/')}/{service_key}/schedule"

DEFAULT_SCHEDULE = {
    "enabled": False,
    "start_time": "17:00",
    "stop_time": "22:00",
    "weekday_start_time": "17:00",
    "weekday_stop_time": "22:00",
    "holiday_start_time": "08:00",
    "holiday_stop_time": "23:00",
    "idle_minutes": 60,
}
TIME_PATTERN = re.compile(r"^\d{2}:\d{2}$")

def _validate_time(value):
    if not isinstance(value, str) or not TIME_PATTERN.match(value):
        raise ValueError("time must be in HH:MM format")

def _get_schedule(service_key):
    if not SERVICE_CONTROL_SSM_PATH:
        return dict(DEFAULT_SCHEDULE)
    try:
        resp = ssm.get_parameter(Name=_schedule_parameter_name(service_key))
        payload = json.loads(resp["Parameter"]["Value"])
        return {**DEFAULT_SCHEDULE, **payload}
    except ssm.exceptions.ParameterNotFound:
        return dict(DEFAULT_SCHEDULE)

def _put_schedule(service_key, schedule):
    if not SERVICE_CONTROL_SSM_PATH:
        return
    ssm.put_parameter(
        Name=_schedule_parameter_name(service_key),
        Value=json.dumps(schedule),
        Type="String",
        Overwrite=True,
    )

def _update_schedule(service_key, payload):
    schedule = _get_schedule(service_key)
    if "enabled" in payload:
        schedule["enabled"] = bool(payload["enabled"])
    for key in ["start_time", "stop_time", "weekday_start_time", "weekday_stop_time", "holiday_start_time", "holiday_stop_time"]:
        if key in payload and payload[key] is not None:
            _validate_time(payload[key])
            schedule[key] = payload[key]
    if "idle_minutes" in payload and payload["idle_minutes"] is not None:
        schedule["idle_minutes"] = int(payload["idle_minutes"])
    _put_schedule(service_key, schedule)
    return schedule


def _proxy_keycloak_token(payload):
    if not KEYCLOAK_BASE_URL or not KEYCLOAK_REALM or not KEYCLOAK_CLIENT_ID:
        raise RuntimeError("Keycloak token proxy is not configured.")
    encoded = urllib.parse.urlencode({k: str(v) for k, v in payload.items()}).encode("utf-8")
    req = urllib.request.Request(
        KEYCLOAK_TOKEN_ENDPOINT,
        data=encoded,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.status, resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read().decode("utf-8")
    except urllib.error.URLError as exc:
        raise RuntimeError(f"Keycloak token request failed: {exc}") from exc


def handler(event, context):
    route = event.get("requestContext", {}).get("http", {}).get("path", "")
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    params = event.get("queryStringParameters") or {}
    service_key = params.get("service")

    if method == "OPTIONS":
        return _response(200, {"message": "ok"})

    try:
        print({"route": route, "method": method, "service_key": service_key})
        if route.endswith("/token") and method == "POST":
            payload = json.loads(event.get("body") or "{}")
            payload = {k: v for k, v in payload.items() if v is not None}
            payload["client_id"] = KEYCLOAK_CLIENT_ID
            try:
                status, raw_body = _proxy_keycloak_token(payload)
            except RuntimeError as exc:
                return _response(502, {"message": str(exc)})
            try:
                parsed = json.loads(raw_body)
            except json.JSONDecodeError:
                parsed = {"message": raw_body}
            return _response(status, parsed)
        if route.endswith("/db-credentials") and method == "GET":
            return _response(200, _get_db_credentials())
        if route.endswith("/keycloak-admin-credentials") and method == "GET":
            return _response(200, _get_keycloak_admin_credentials())
        if route.endswith("/odoo-admin-credentials") and method == "GET":
            return _response(200, _get_odoo_admin_credentials())
        if route.endswith("/orangehrm-admin-credentials") and method == "GET":
            return _response(200, _get_orangehrm_admin_credentials())
        service_arn = _get_service_arn(service_key)
        if route.endswith("/status") and method == "GET":
            body = _describe(service_arn)
            tg_arn = _get_target_group_arn(service_key)
            if tg_arn:
                body["targetGroupHealth"] = _describe_tg_health(tg_arn)
            return _response(200, body)
        if route.endswith("/start") and method == "POST":
            body = _update(service_arn, START_DESIRED)
            return _response(200, body)
        if route.endswith("/stop") and method == "POST":
            body = _update(service_arn, 0)
            return _response(200, body)
        if route.endswith("/schedule"):
            if method == "GET":
                return _response(200, _get_schedule(service_key))
            if method == "POST":
                payload = json.loads(event.get("body") or "{}")
                return _response(200, _update_schedule(service_key, payload))
        return _response(404, {"message": "Not found"})
    except ValueError as exc:
        return _response(400, {"message": str(exc)})
    except Exception as exc:  # pylint: disable=broad-except
        # ここで何が起きたか分かるように詳細を返す
        print({"error": str(exc)})
        return _response(500, {"message": str(exc), "route": route, "service": service_key})
