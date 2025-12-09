import json
import os

import boto3

ecs = boto3.client("ecs")
elbv2 = boto3.client("elbv2")
ecr = boto3.client("ecr")

CLUSTER_ARN = os.environ["CLUSTER_ARN"]
SERVICE_ARNS = json.loads(os.environ["SERVICE_ARNS"])
TARGET_GROUP_ARNS = json.loads(os.environ.get("TARGET_GROUP_ARNS", "{}"))
START_DESIRED = int(os.environ.get("START_DESIRED", "1"))


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


def _update(service_arn, desired):
    ecs.update_service(cluster=CLUSTER_ARN, service=service_arn, desiredCount=desired)
    return _describe(service_arn)


def handler(event, context):
    route = event.get("requestContext", {}).get("http", {}).get("path", "")
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    params = event.get("queryStringParameters") or {}
    service_key = params.get("service")

    if method == "OPTIONS":
        return _response(200, {"message": "ok"})

    try:
        print({"route": route, "method": method, "service_key": service_key})
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
        return _response(404, {"message": "Not found"})
    except ValueError as exc:
        return _response(400, {"message": str(exc)})
    except Exception as exc:  # pylint: disable=broad-except
        # ここで何が起きたか分かるように詳細を返す
        print({"error": str(exc)})
        return _response(500, {"message": str(exc), "route": route, "service": service_key})
