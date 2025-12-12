import json
import math
import os
from datetime import datetime, timedelta, timezone

import boto3

ecs = boto3.client("ecs")
ssm = boto3.client("ssm")
cloudwatch = boto3.client("cloudwatch")

CLUSTER_ARN = os.environ["CLUSTER_ARN"]
SERVICE_CONTROL_SERVICE_KEYS = json.loads(os.environ.get("SERVICE_CONTROL_SERVICE_KEYS", "[]"))
SERVICE_CONTROL_SCHEDULE_SERVICES = json.loads(os.environ.get("SERVICE_CONTROL_SCHEDULE_SERVICES", "[]"))
SERVICE_CONTROL_NAME_PREFIX = os.environ.get("SERVICE_CONTROL_NAME_PREFIX", "")
SERVICE_CONTROL_SSM_PATH = os.environ.get("SERVICE_CONTROL_SSM_PATH", "")
SERVICE_ARNS_SSM_PARAMETER = os.environ.get("SERVICE_ARNS_SSM_PARAMETER", "")
AUTOSTOP_ALARMS_SSM_PARAMETER = os.environ.get("SERVICE_CONTROL_AUTOSTOP_ALARMS_SSM_PARAMETER", "")
SERVICE_CONTROL_AUTOSTOP_POLICY_ARNS_RAW = json.loads(os.environ.get("SERVICE_CONTROL_AUTOSTOP_POLICY_ARNS") or "{}")
START_DESIRED = int(os.environ.get("START_DESIRED", "1"))
JST_OFFSET = int(os.environ.get("SERVICE_CONTROL_SCHEDULE_TIMEZONE_OFFSET", "9"))
SERVICE_CONTROL_AUTOSTOP_ALARM_REGION = os.environ.get("SERVICE_CONTROL_AUTOSTOP_ALARM_REGION", "")
SERVICE_CONTROL_AUTOSTOP_WAF_NAME = os.environ.get("SERVICE_CONTROL_AUTOSTOP_WAF_NAME", "")
SERVICE_CONTROL_AUTOSTOP_ALARM_PERIOD_SECONDS = int(os.environ.get("SERVICE_CONTROL_AUTOSTOP_ALARM_PERIOD_SECONDS", "300"))
SERVICE_CONTROL_AUTOSTOP_ALARM_PERIOD_MINUTES = SERVICE_CONTROL_AUTOSTOP_ALARM_PERIOD_SECONDS / 60
SERVICE_CONTROL_AUTOSTOP_ALARM_NAMESPACE = os.environ.get("SERVICE_CONTROL_AUTOSTOP_ALARM_NAMESPACE", "AWS/WAFV2")
SERVICE_CONTROL_AUTOSTOP_ALARM_METRIC_NAME = os.environ.get("SERVICE_CONTROL_AUTOSTOP_ALARM_METRIC_NAME", "CountedRequests")
SERVICE_CONTROL_AUTOSTOP_ALARM_STATISTIC = os.environ.get("SERVICE_CONTROL_AUTOSTOP_ALARM_STATISTIC", "Sum")
SERVICE_CONTROL_AUTOSTOP_ALARM_COMPARISON_OPERATOR = os.environ.get("SERVICE_CONTROL_AUTOSTOP_ALARM_COMPARISON_OPERATOR", "LessThanOrEqualToThreshold")
SERVICE_CONTROL_AUTOSTOP_ALARM_THRESHOLD = float(os.environ.get("SERVICE_CONTROL_AUTOSTOP_ALARM_THRESHOLD", "0"))
SERVICE_CONTROL_AUTOSTOP_ALARM_TREAT_MISSING_DATA = os.environ.get("SERVICE_CONTROL_AUTOSTOP_ALARM_TREAT_MISSING_DATA", "notBreaching")


def _parse_cluster_arn(cluster_arn):
    try:
        parts = cluster_arn.split(":")
        region = parts[3] if len(parts) > 3 else ""
        account = parts[4] if len(parts) > 4 else ""
        cluster = parts[5].split("/", 1)[1] if len(parts) > 5 and "/" in parts[5] else parts[5] if len(parts) > 5 else ""
        return region, account, cluster
    except Exception:  # pylint: disable=broad-except
        return "", "", ""


REGION, ACCOUNT_ID, CLUSTER_NAME = _parse_cluster_arn(CLUSTER_ARN)
NAME_PREFIX = (
    SERVICE_CONTROL_NAME_PREFIX
    or (CLUSTER_NAME[:-4] if CLUSTER_NAME.endswith("-ecs") else CLUSTER_NAME)
).strip("-")


def _service_arn(service_key):
    if not REGION or not ACCOUNT_ID or not CLUSTER_NAME or not service_key:
        return ""
    return f"arn:aws:ecs:{REGION}:{ACCOUNT_ID}:service/{CLUSTER_NAME}/{NAME_PREFIX}-{service_key}"


def _load_service_arns():
    if SERVICE_ARNS_SSM_PARAMETER:
        try:
            resp = ssm.get_parameter(Name=SERVICE_ARNS_SSM_PARAMETER)
            return json.loads(resp["Parameter"]["Value"])
        except ssm.exceptions.ParameterNotFound:
            print({"warning": "service arns parameter not found", "parameter": SERVICE_ARNS_SSM_PARAMETER})
        except Exception as exc:  # pylint: disable=broad-except
            print({"warning": "failed to load service arns", "parameter": SERVICE_ARNS_SSM_PARAMETER, "error": str(exc)})
    keys = SERVICE_CONTROL_SERVICE_KEYS or SERVICE_CONTROL_SCHEDULE_SERVICES
    return {svc: _service_arn(svc) for svc in keys}


def _load_autostop_policies():
    if SERVICE_CONTROL_AUTOSTOP_POLICY_ARNS_RAW:
        return SERVICE_CONTROL_AUTOSTOP_POLICY_ARNS_RAW
    if AUTOSTOP_ALARMS_SSM_PARAMETER:
        try:
            resp = ssm.get_parameter(Name=AUTOSTOP_ALARMS_SSM_PARAMETER)
            raw = json.loads(resp["Parameter"]["Value"])
            return {svc: cfg.get("policy_arn") for svc, cfg in raw.items() if cfg.get("policy_arn")}
        except ssm.exceptions.ParameterNotFound:
            print({"warning": "autostop alarms parameter not found", "parameter": AUTOSTOP_ALARMS_SSM_PARAMETER})
        except Exception as exc:  # pylint: disable=broad-except
            print({"warning": "failed to load autostop alarms", "parameter": AUTOSTOP_ALARMS_SSM_PARAMETER, "error": str(exc)})
    return {}


SERVICE_ARNS = _load_service_arns()
SERVICE_CONTROL_AUTOSTOP_POLICIES = _load_autostop_policies()


DEFAULT_SCHEDULE = {
    "enabled": False,
    "start_time": "09:00",
    "stop_time": "22:00",
    "idle_minutes": 60,
}



def _schedule_parameter_name(service_key):
    return f"{SERVICE_CONTROL_SSM_PATH.rstrip('/')}/{service_key}/schedule"


def _parse_time(value, fallback):
    try:
        parts = value.split(":")
        if len(parts) != 2:
            raise ValueError
        hours = int(parts[0])
        minutes = int(parts[1])
        return hours * 60 + minutes
    except Exception:
        return fallback


def _get_schedule(service_key):
    if not SERVICE_CONTROL_SSM_PATH:
        return None
    try:
        resp = ssm.get_parameter(Name=_schedule_parameter_name(service_key))
        return json.loads(resp["Parameter"]["Value"])
    except ssm.exceptions.ParameterNotFound:
        return None
    except Exception:
        return None


def _put_schedule(service_key, schedule):
    if not SERVICE_CONTROL_SSM_PATH:
        return
    ssm.put_parameter(
        Name=_schedule_parameter_name(service_key),
        Value=json.dumps(schedule),
        Type="String",
        Overwrite=True,
    )


def _ensure_schedule(service_key):
    schedule = _get_schedule(service_key)
    if not schedule:
        schedule = dict(DEFAULT_SCHEDULE)
        _put_schedule(service_key, schedule)
        return schedule
    needs_update = schedule.get("idle_minutes") != DEFAULT_SCHEDULE["idle_minutes"]
    normalized = {**DEFAULT_SCHEDULE, **schedule}
    if needs_update:
        _put_schedule(service_key, normalized)
    return normalized


def _current_minutes():
    now = datetime.now(timezone.utc) + timedelta(hours=JST_OFFSET)
    return now.hour * 60 + now.minute


def _should_be_active(schedule, current_minutes):
    if not schedule or not schedule.get("enabled"):
        return False
    start = _parse_time(schedule.get("start_time", "09:00"), 9 * 60)
    stop = _parse_time(schedule.get("stop_time", "22:00"), 22 * 60)
    if start <= stop:
        return start <= current_minutes < stop
    return current_minutes >= start or current_minutes < stop


def _describe_current_desired(service_arn):
    resp = ecs.describe_services(cluster=CLUSTER_ARN, services=[service_arn])
    services = resp.get("services") or []
    if not services:
        return None
    return services[0].get("desiredCount", 0)


def _update_desired(service_arn, desired):
    ecs.update_service(cluster=CLUSTER_ARN, service=service_arn, desiredCount=desired)


def _alarm_details(service_key):
    alarm_name = f"{NAME_PREFIX}-{service_key}-idle" if NAME_PREFIX else f"{service_key}-idle"
    rule_name = f"count-jp-{service_key}"
    return alarm_name, rule_name


def _update_idle_alarm(service_key, schedule, active):
    policy_arn = SERVICE_CONTROL_AUTOSTOP_POLICIES.get(service_key)
    if not policy_arn:
        return
    if not SERVICE_CONTROL_AUTOSTOP_WAF_NAME or not SERVICE_CONTROL_AUTOSTOP_ALARM_REGION:
        return
    alarm_name, rule_name = _alarm_details(service_key)
    idle_minutes = schedule.get("idle_minutes") if schedule else DEFAULT_SCHEDULE["idle_minutes"]
    try:
        idle_value = float(idle_minutes)
    except (TypeError, ValueError):
        idle_value = DEFAULT_SCHEDULE["idle_minutes"]
    evaluation_periods = max(1, math.ceil(idle_value / SERVICE_CONTROL_AUTOSTOP_ALARM_PERIOD_MINUTES))
    try:
        cloudwatch.put_metric_alarm(
            AlarmName=alarm_name,
            ComparisonOperator=SERVICE_CONTROL_AUTOSTOP_ALARM_COMPARISON_OPERATOR,
            EvaluationPeriods=evaluation_periods,
            MetricName=SERVICE_CONTROL_AUTOSTOP_ALARM_METRIC_NAME,
            Namespace=SERVICE_CONTROL_AUTOSTOP_ALARM_NAMESPACE,
            Period=SERVICE_CONTROL_AUTOSTOP_ALARM_PERIOD_SECONDS,
            Statistic=SERVICE_CONTROL_AUTOSTOP_ALARM_STATISTIC,
            Threshold=SERVICE_CONTROL_AUTOSTOP_ALARM_THRESHOLD,
            TreatMissingData=SERVICE_CONTROL_AUTOSTOP_ALARM_TREAT_MISSING_DATA,
            ActionsEnabled=not active,
            Dimensions=[
                {"Name": "WebACL", "Value": SERVICE_CONTROL_AUTOSTOP_WAF_NAME},
                {"Name": "Rule", "Value": rule_name},
                {"Name": "Region", "Value": SERVICE_CONTROL_AUTOSTOP_ALARM_REGION},
            ],
            AlarmActions=[policy_arn],
        )
    except Exception as exc:  # pylint: disable=broad-except
        print({"service": service_key, "alarm": alarm_name, "error": str(exc)})


def handler(event, context):
    current_minutes = _current_minutes()
    for service_key in SERVICE_CONTROL_SCHEDULE_SERVICES:
        service_arn = SERVICE_ARNS.get(service_key)
        if not service_arn:
            continue
        schedule = _ensure_schedule(service_key)
        active = _should_be_active(schedule, current_minutes)
        _update_idle_alarm(service_key, schedule, active)
        desired = START_DESIRED if active else 0
        current = _describe_current_desired(service_arn)
        if current is None:
            continue
        if current != desired:
            try:
                _update_desired(service_arn, desired)
            except Exception as exc:  # pylint: disable=broad-except
                print({"service": service_key, "error": str(exc)})
    return {"status": "ok", "timestamp": datetime.now(timezone.utc).isoformat()}
