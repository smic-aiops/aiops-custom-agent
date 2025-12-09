locals {
  service_control_api_name       = "${local.name_prefix}-svc-control-api"
  service_control_lambda_name    = "${local.name_prefix}-svc-control"
  service_control_lambda_role    = "${local.name_prefix}-svc-control-lambda"
  service_control_api_stage_name = "$default"
  service_control_api_service_flags = {
    n8n          = var.create_n8n
    zulip        = var.create_zulip
    exastro-web  = var.create_exastro_web_server
    exastro-api  = var.create_exastro_api_admin
    main_svc     = var.create_main_svc
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
      main_svc     = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.name_prefix}-main-svc"
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
      main_svc     = try(aws_lb_target_group.main_svc[0].arn, "")
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
}

data "archive_file" "service_control_lambda" {
  type        = "zip"
  source_file = "${path.module}/templates/service_control_lambda.py"
  output_path = "${path.module}/templates/service_control_lambda.zip"
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

resource "aws_lambda_function" "service_control" {
  count = local.service_control_enabled ? 1 : 0

  function_name = local.service_control_lambda_name
  role          = aws_iam_role.service_control[0].arn
  handler       = "service_control_lambda.handler"
  runtime       = "python3.12"
  timeout       = 10

  filename         = data.archive_file.service_control_lambda.output_path
  source_code_hash = data.archive_file.service_control_lambda.output_base64sha256

  environment {
    variables = {
      CLUSTER_ARN       = local.service_control_api_cluster_arn
      SERVICE_ARNS      = jsonencode(local.service_control_api_services)
      TARGET_GROUP_ARNS = jsonencode(local.service_control_target_groups)
      START_DESIRED     = "1"
    }
  }

  tags = merge(local.tags, { Name = local.service_control_lambda_name })
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

resource "aws_apigatewayv2_route" "service_control" {
  for_each = local.service_control_enabled ? {
    "GET /status" = "GET /status",
    "POST /start" = "POST /start",
    "POST /stop"  = "POST /stop"
  } : {}

  api_id    = aws_apigatewayv2_api.service_control[0].id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.service_control[0].id}"
}

resource "aws_apigatewayv2_stage" "service_control" {
  count = local.service_control_enabled ? 1 : 0

  api_id      = aws_apigatewayv2_api.service_control[0].id
  name        = local.service_control_api_stage_name
  auto_deploy = true

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
