import json
import os

import boto3

ecs = boto3.client("ecs")


CLUSTER_ARN = os.environ["CLUSTER_ARN"]
SERVICE_NAME = os.environ["SERVICE_NAME"]
START_DESIRED = int(os.environ.get("START_DESIRED", "1"))


def _response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def _describe():
    resp = ecs.describe_services(cluster=CLUSTER_ARN, services=[SERVICE_NAME])
    svc = resp["services"][0]
    return {
        "desiredCount": svc.get("desiredCount", 0),
        "runningCount": svc.get("runningCount", 0),
        "status": svc.get("status", "UNKNOWN"),
    }


def _update(desired):
    ecs.update_service(cluster=CLUSTER_ARN, service=SERVICE_NAME, desiredCount=desired)
    return _describe()


def handler(event, context):
    route = event.get("requestContext", {}).get("http", {}).get("path", "")
    method = event.get("requestContext", {}).get("http", {}).get("method", "")

    try:
        if route.endswith("/status") and method == "GET":
            body = _describe()
            return _response(200, body)
        if route.endswith("/start") and method == "POST":
            body = _update(START_DESIRED)
            return _response(200, body)
        if route.endswith("/stop") and method == "POST":
            body = _update(0)
            return _response(200, body)
        return _response(404, {"message": "Not found"})
    except Exception as exc:  # pylint: disable=broad-except
        return _response(500, {"message": str(exc)})
