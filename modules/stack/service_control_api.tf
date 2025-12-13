locals {
  service_control_api_name       = "${local.name_prefix}-svc-control-api"
  service_control_lambda_name    = "${local.name_prefix}-svc-control"
  service_control_lambda_role    = "${local.name_prefix}-svc-control-lambda"
  service_control_api_stage_name = "$default"
  service_control_api_log_group  = "/aws/apigw/${local.name_prefix}-svc-control-api"
  service_control_keycloak_issuer = "${local.keycloak_base_url_effective}/realms/${local.control_site_keycloak_realm}"
  service_control_api_service_flags = {
    n8n          = var.create_n8n
    zulip        = var.create_zulip
    exastro-web  = var.create_exastro_web_server
    exastro-api  = var.create_exastro_api_admin
    sulu         = var.create_sulu
    keycloak     = var.create_keycloak
    odoo         = var.create_odoo
    phpmyadmin   = var.create_phpmyadmin
    pgadmin      = var.create_pgadmin
    gitlab       = var.create_gitlab
    growi        = var.create_growi
    orangehrm    = var.create_orangehrm
    cmdbuild-r2u = var.create_cmdbuild_r2u
  }
  service_control_enabled = var.create_ecs && var.enable_service_control && anytrue(values(local.service_control_api_service_flags))
  service_control_api_services = {
    for k, v in {
      n8n          = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.name_prefix}-n8n"
      zulip        = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.name_prefix}-zulip"
      exastro-web  = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.name_prefix}-exastro-web"
      exastro-api  = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.name_prefix}-exastro-api"
      sulu         = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.name_prefix}-sulu"
      keycloak     = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.name_prefix}-keycloak"
      odoo         = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.name_prefix}-odoo"
      phpmyadmin   = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.name_prefix}-phpmyadmin"
      pgadmin      = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.name_prefix}-pgadmin"
      gitlab       = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.name_prefix}-gitlab"
      growi        = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.name_prefix}-growi"
      orangehrm    = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.name_prefix}-orangehrm"
      cmdbuild-r2u = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.name_prefix}-cmdbuild-r2u"
    } : k => v if lookup(local.service_control_api_service_flags, k, false)
  }
  service_control_target_groups = {
    for k, v in {
      n8n          = try(aws_lb_target_group.n8n[0].arn, "")
      zulip        = try(aws_lb_target_group.zulip[0].arn, "")
      exastro-web  = try(aws_lb_target_group.exastro_web[0].arn, "")
      exastro-api  = try(aws_lb_target_group.exastro_api_admin[0].arn, "")
      sulu         = try(aws_lb_target_group.sulu[0].arn, "")
      keycloak     = try(aws_lb_target_group.keycloak[0].arn, "")
      odoo         = try(aws_lb_target_group.odoo[0].arn, "")
      phpmyadmin   = try(aws_lb_target_group.phpmyadmin[0].arn, "")
      pgadmin      = try(aws_lb_target_group.pgadmin[0].arn, "")
      gitlab       = try(aws_lb_target_group.gitlab[0].arn, "")
      growi        = try(aws_lb_target_group.growi[0].arn, "")
      orangehrm    = try(aws_lb_target_group.orangehrm[0].arn, "")
      cmdbuild-r2u = try(aws_lb_target_group.cmdbuild_r2u[0].arn, "")
    } : k => v if lookup(local.service_control_api_service_flags, k, false)
  }
  service_control_api_cluster_arn = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${local.ecs_cluster_name}"
  service_control_schedule_prefix = local.service_control_ssm_path
  service_control_autostop_alarm_sources = {
    "exastro-web" = {
      policy = aws_appautoscaling_policy.exastro_web_idle_scale_to_zero
      rule   = "count-jp-exastro-web"
    }
    "exastro-api" = {
      policy = aws_appautoscaling_policy.exastro_api_idle_scale_to_zero
      rule   = "count-jp-exastro-api"
    }
    sulu = {
      policy = aws_appautoscaling_policy.sulu_idle_scale_to_zero
      rule   = "count-jp-sulu"
    }
    n8n = {
      policy = aws_appautoscaling_policy.n8n_idle_scale_to_zero
      rule   = "count-jp-n8n"
    }
    pgadmin = {
      policy = aws_appautoscaling_policy.pgadmin_idle_scale_to_zero
      rule   = "count-jp-pgadmin"
    }
    phpmyadmin = {
      policy = aws_appautoscaling_policy.phpmyadmin_idle_scale_to_zero
      rule   = "count-jp-phpmyadmin"
    }
    odoo = {
      policy = aws_appautoscaling_policy.odoo_idle_scale_to_zero
      rule   = "count-jp-odoo"
    }
    gitlab = {
      policy = aws_appautoscaling_policy.gitlab_idle_scale_to_zero
      rule   = "count-jp-gitlab"
    }
    zulip = {
      policy = aws_appautoscaling_policy.zulip_idle_scale_to_zero
      rule   = "count-jp-zulip"
    }
    keycloak = {
      policy = aws_appautoscaling_policy.keycloak_idle_scale_to_zero
      rule   = "count-jp-keycloak"
    }
    growi = {
      policy = aws_appautoscaling_policy.growi_idle_scale_to_zero
      rule   = "count-jp-growi"
    }
    "cmdbuild-r2u" = {
      policy = aws_appautoscaling_policy.cmdbuild_r2u_idle_scale_to_zero
      rule   = "count-jp-cmdbuild-r2u"
    }
    orangehrm = {
      policy = aws_appautoscaling_policy.orangehrm_idle_scale_to_zero
      rule   = "count-jp-orangehrm"
    }
  }
  service_control_autostop_alarm_configs = {
    for svc, cfg in local.service_control_autostop_alarm_sources : svc => {
      alarm_name = "${local.name_prefix}-${svc}-idle"
      rule_name  = cfg.rule
      policy_arn = length(cfg.policy) > 0 ? cfg.policy[0].arn : ""
    }
  }
}

data "archive_file" "service_control_lambda" {
  type        = "zip"
  source_file = "${path.module}/templates/service_control_lambda.py"
  output_path = "${path.module}/templates/service_control_lambda.zip"
}

data "archive_file" "service_control_scheduler" {
  type        = "zip"
  source_file = "${path.module}/templates/service_control_scheduler.py"
  output_path = "${path.module}/templates/service_control_scheduler.zip"
}

data "aws_iam_policy_document" "service_control_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "service_control" {
  count              = local.service_control_enabled ? 1 : 0
  name               = local.service_control_lambda_role
  assume_role_policy = data.aws_iam_policy_document.service_control_assume.json

  tags = merge(local.tags, { Name = local.service_control_lambda_role })
}

data "aws_iam_policy_document" "service_control_inline" {
  count = local.service_control_enabled ? 1 : 0

  statement {
    actions = [
      "ecs:DescribeServices",
      "ecs:ListTagsForResource",
      "ecs:UpdateService",
      "ecs:DescribeTaskDefinition"
    ]
    resources = concat(
      values(local.service_control_api_services),
      [local.service_control_api_cluster_arn]
    )
  }

  statement {
    actions   = ["ecs:ListTasks"]
    resources = ["*"]
  }

  statement {
    actions   = ["ecs:DescribeTasks"]
    resources = ["*"]
  }

  statement {
    actions = [
      "elasticloadbalancing:DescribeTargetHealth"
    ]
    # AWS may not honor resource-level permissions for DescribeTargetHealth; allow all to avoid AccessDenied.
    resources = ["*"]
  }

  statement {
    actions = [
      "ecs:DescribeTaskDefinition"
    ]
    resources = ["*"]
  }

  # ECR イメージタグ取得
  statement {
    actions = [
      "ecr:DescribeImages"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "logs:FilterLogEvents"
    ]
    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter"
    ]
    resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${local.service_control_schedule_prefix}/*"]
  }
  statement {
    actions = [
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DescribeAlarms"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "service_control" {
  count  = local.service_control_enabled ? 1 : 0
  name   = "${local.name_prefix}-svc-control"
  policy = data.aws_iam_policy_document.service_control_inline[0].json
}

resource "aws_iam_role_policy_attachment" "service_control_basic" {
  count      = local.service_control_enabled ? 1 : 0
  role       = aws_iam_role.service_control[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "service_control_inline" {
  count      = local.service_control_enabled ? 1 : 0
  role       = aws_iam_role.service_control[0].name
  policy_arn = aws_iam_policy.service_control[0].arn
}

resource "aws_ssm_parameter" "service_control_service_arns" {
  count     = local.service_control_enabled && var.create_ssm_parameters ? 1 : 0
  name      = "${local.service_control_schedule_prefix}/service-arns"
  type      = "String"
  value     = jsonencode(local.service_control_api_services)
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-svc-control-service-arns" })
}

resource "aws_ssm_parameter" "service_control_target_group_arns" {
  count     = local.service_control_enabled && var.create_ssm_parameters ? 1 : 0
  name      = "${local.service_control_schedule_prefix}/target-group-arns"
  type      = "String"
  value     = jsonencode(local.service_control_target_groups)
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-svc-control-tg-arns" })
}

resource "aws_ssm_parameter" "service_control_autostop_alarms" {
  count = local.service_control_enabled && var.create_ssm_parameters ? 1 : 0
  name  = "${local.service_control_schedule_prefix}/autostop-alarms"
  type  = "String"
  value = jsonencode(
    {
      for svc, cfg in local.service_control_autostop_alarm_configs : svc => {
        alarm_name = cfg.alarm_name
        rule_name  = cfg.rule_name
        policy_arn = cfg.policy_arn
      } if cfg.policy_arn != ""
    }
  )
  overwrite = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-svc-control-autostop-alarms" })
}

resource "aws_lambda_function" "service_control" {
  count = local.service_control_enabled ? 1 : 0

  function_name = local.service_control_lambda_name
  role          = aws_iam_role.service_control[0].arn
  handler       = "service_control_lambda.handler"
  runtime       = "python3.12"
  timeout       = 10
  reserved_concurrent_executions = var.service_control_lambda_reserved_concurrency

  filename         = data.archive_file.service_control_lambda.output_path
  source_code_hash = data.archive_file.service_control_lambda.output_base64sha256

  environment {
    variables = merge(
      {
        CLUSTER_ARN              = local.service_control_api_cluster_arn
        START_DESIRED            = "1"
        SERVICE_CONTROL_SSM_PATH = local.service_control_schedule_prefix
        KEYCLOAK_BASE_URL        = local.keycloak_base_url_effective
        KEYCLOAK_REALM           = local.control_site_keycloak_realm
        KEYCLOAK_CLIENT_ID       = local.service_control_keycloak_client_id_effective
      },
      var.create_ssm_parameters ? {
        SERVICE_ARNS_SSM_PARAMETER      = aws_ssm_parameter.service_control_service_arns[0].name
        TARGET_GROUP_ARNS_SSM_PARAMETER = aws_ssm_parameter.service_control_target_group_arns[0].name
        } : {
        SERVICE_ARNS      = jsonencode(local.service_control_api_services)
        TARGET_GROUP_ARNS = jsonencode(local.service_control_target_groups)
      }
    )
  }

  tags = merge(local.tags, { Name = local.service_control_lambda_name })
}

resource "aws_lambda_function" "service_control_scheduler" {
  count = local.service_control_enabled ? 1 : 0

  function_name = "${local.name_prefix}-svc-control-scheduler"
  role          = aws_iam_role.service_control[0].arn
  handler       = "service_control_scheduler.handler"
  runtime       = "python3.12"
  timeout       = 60

  filename         = data.archive_file.service_control_scheduler.output_path
  source_code_hash = data.archive_file.service_control_scheduler.output_base64sha256

  environment {
    variables = merge(
      {
        CLUSTER_ARN                                   = local.service_control_api_cluster_arn
        SERVICE_CONTROL_SERVICE_KEYS                  = jsonencode(keys(local.service_control_api_services))
        SERVICE_CONTROL_NAME_PREFIX                   = local.name_prefix
        SERVICE_CONTROL_SCHEDULE_SERVICES             = jsonencode(local.service_control_services)
        SERVICE_CONTROL_SSM_PATH                      = local.service_control_schedule_prefix
        START_DESIRED                                 = "1"
        SERVICE_CONTROL_AUTOSTOP_ALARM_PERIOD_SECONDS = tostring(local.service_control_alarm_period_seconds)
        SERVICE_CONTROL_AUTOSTOP_ALARM_REGION         = var.region
        SERVICE_CONTROL_AUTOSTOP_WAF_NAME             = try(aws_wafv2_web_acl.alb[0].name, "")
      },
      var.create_ssm_parameters ? {
        SERVICE_ARNS_SSM_PARAMETER                    = aws_ssm_parameter.service_control_service_arns[0].name
        SERVICE_CONTROL_AUTOSTOP_ALARMS_SSM_PARAMETER = aws_ssm_parameter.service_control_autostop_alarms[0].name
        } : {
        SERVICE_CONTROL_AUTOSTOP_POLICY_ARNS = jsonencode(
          { for svc, cfg in local.service_control_autostop_alarm_configs : svc => cfg.policy_arn if cfg.policy_arn != "" }
        )
      }
    )
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-svc-control-scheduler" })
}

resource "aws_cloudwatch_event_rule" "service_control_scheduler" {
  count = local.service_control_enabled ? 1 : 0

  name                = "${local.name_prefix}-svc-control-scheduler"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "service_control_scheduler" {
  count     = local.service_control_enabled ? 1 : 0
  rule      = aws_cloudwatch_event_rule.service_control_scheduler[0].name
  target_id = "service-control-scheduler"
  arn       = aws_lambda_function.service_control_scheduler[0].arn
  input     = "{}"
}

resource "aws_lambda_permission" "service_control_scheduler" {
  count         = local.service_control_enabled ? 1 : 0
  statement_id  = "AllowEventBridgeInvokeServiceControlScheduler"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.service_control_scheduler[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.service_control_scheduler[0].arn
}

resource "aws_cloudwatch_log_group" "service_control_api" {
  count = local.service_control_enabled ? 1 : 0

  name              = local.service_control_api_log_group
  retention_in_days = 30

  tags = merge(local.tags, { Name = "${local.service_control_api_name}-api-logs" })
}

resource "aws_apigatewayv2_api" "service_control" {
  count = local.service_control_enabled ? 1 : 0

  name          = local.service_control_api_name
  protocol_type = "HTTP"

  cors_configuration {
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_origins = ["*"]
    allow_headers = ["*"]
  }

  tags = merge(local.tags, { Name = local.service_control_api_name })
}

resource "aws_apigatewayv2_integration" "service_control" {
  count = local.service_control_enabled ? 1 : 0

  api_id                 = aws_apigatewayv2_api.service_control[0].id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.service_control[0].invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_authorizer" "service_control_jwt" {
  count = local.service_control_enabled ? 1 : 0

  api_id           = aws_apigatewayv2_api.service_control[0].id
  name             = "${local.service_control_api_name}-jwt"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [
      local.service_control_keycloak_client_id_effective,
      "account"
    ]
    issuer   = local.service_control_keycloak_issuer
  }
}

resource "aws_apigatewayv2_route" "service_control" {
  for_each = local.service_control_enabled ? {
    "GET /status" = {
      route = "GET /status"
      auth  = true
    }
    "POST /start" = {
      route = "POST /start"
      auth  = true
    }
    "POST /stop" = {
      route = "POST /stop"
      auth  = true
    }
    "GET /schedule" = {
      route = "GET /schedule"
      auth  = true
    }
    "POST /schedule" = {
      route = "POST /schedule"
      auth  = true
    }
    "POST /token" = {
      route = "POST /token"
      auth  = false
    }
  } : {}

  api_id             = aws_apigatewayv2_api.service_control[0].id
  route_key          = each.value.route
  target             = "integrations/${aws_apigatewayv2_integration.service_control[0].id}"
  authorization_type = each.value.auth ? "JWT" : "NONE"
  authorizer_id      = each.value.auth ? aws_apigatewayv2_authorizer.service_control_jwt[0].id : null
}

resource "aws_apigatewayv2_stage" "service_control" {
  count = local.service_control_enabled ? 1 : 0

  api_id      = aws_apigatewayv2_api.service_control[0].id
  name        = local.service_control_api_stage_name
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.service_control_api[0].arn
    format = jsonencode({
      requestId          = "$context.requestId"
      requestTime        = "$context.requestTime"
      httpMethod         = "$context.httpMethod"
      path               = "$context.path"
      status             = "$context.status"
      integrationError   = "$context.integrationErrorMessage"
      errorMessage       = "$context.error.message"
      errorMessageString = "$context.error.messageString"
      routeKey           = "$context.routeKey"
      integrationStatus  = "$context.integrationStatus"
      responseLength     = "$context.responseLength"
      userAgent          = "$context.identity.userAgent"
      sourceIp           = "$context.identity.sourceIp"
    })
  }

  tags = merge(local.tags, { Name = "${local.service_control_api_name}-stage" })
}

resource "aws_lambda_permission" "service_control" {
  count = local.service_control_enabled ? 1 : 0

  statement_id  = "AllowAPIGatewayInvokeServiceControl"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.service_control[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.service_control[0].execution_arn}/*/*"
}
