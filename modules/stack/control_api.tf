locals {
  control_api_name       = "${local.name_prefix}-sulu-control-api"
  control_lambda_name    = "${local.name_prefix}-sulu-control"
  control_lambda_role    = "${local.name_prefix}-sulu-control-lambda"
  control_api_stage_name = "$default"
  sulu_service_name      = "${local.name_prefix}-sulu"
  ecs_cluster_arn        = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${local.ecs_cluster_name}"
  sulu_service_arn       = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.name_prefix}-sulu"
}

data "archive_file" "sulu_control_lambda" {
  type        = "zip"
  source_file = "${path.module}/templates/sulu_control_lambda.py"
  output_path = "${path.module}/templates/sulu_control_lambda.zip"
}

data "aws_iam_policy_document" "sulu_control_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sulu_control" {
  count              = var.enable_sulu_control_api && var.create_ecs && var.create_sulu ? 1 : 0
  name               = local.control_lambda_role
  assume_role_policy = data.aws_iam_policy_document.sulu_control_assume.json

  tags = merge(local.tags, { Name = local.control_lambda_role })
}

data "aws_iam_policy_document" "sulu_control_inline" {
  count = var.enable_sulu_control_api && var.create_ecs && var.create_sulu ? 1 : 0

  statement {
    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]
    resources = [
      local.sulu_service_arn,
      local.ecs_cluster_arn
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
  }
}

resource "aws_iam_policy" "sulu_control" {
  count  = var.enable_sulu_control_api && var.create_ecs && var.create_sulu ? 1 : 0
  name   = "${local.name_prefix}-sulu-control"
  policy = data.aws_iam_policy_document.sulu_control_inline[0].json
}

resource "aws_iam_role_policy_attachment" "sulu_control_basic" {
  count      = var.enable_sulu_control_api && var.create_ecs && var.create_sulu ? 1 : 0
  role       = aws_iam_role.sulu_control[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "sulu_control_inline" {
  count      = var.enable_sulu_control_api && var.create_ecs && var.create_sulu ? 1 : 0
  role       = aws_iam_role.sulu_control[0].name
  policy_arn = aws_iam_policy.sulu_control[0].arn
}

resource "aws_lambda_function" "sulu_control" {
  count = var.enable_sulu_control_api && var.create_ecs && var.create_sulu ? 1 : 0

  function_name = local.control_lambda_name
  role          = aws_iam_role.sulu_control[0].arn
  handler       = "sulu_control_lambda.handler"
  runtime       = "python3.12"
  timeout       = 10

  filename         = data.archive_file.sulu_control_lambda.output_path
  source_code_hash = data.archive_file.sulu_control_lambda.output_base64sha256

  environment {
    variables = {
      CLUSTER_ARN   = local.ecs_cluster_arn
      SERVICE_NAME  = local.sulu_service_name
      START_DESIRED = tostring(var.sulu_desired_count)
    }
  }

  tags = merge(local.tags, { Name = local.control_lambda_name })
}

resource "aws_apigatewayv2_api" "sulu_control" {
  count = var.enable_sulu_control_api && var.create_ecs && var.create_sulu ? 1 : 0

  name          = local.control_api_name
  protocol_type = "HTTP"

  cors_configuration {
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_origins = ["*"]
    allow_headers = ["*"]
  }

  tags = merge(local.tags, { Name = local.control_api_name })
}

resource "aws_apigatewayv2_integration" "sulu_control" {
  count = var.enable_sulu_control_api && var.create_ecs && var.create_sulu ? 1 : 0

  api_id                 = aws_apigatewayv2_api.sulu_control[0].id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.sulu_control[0].invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "sulu_control" {
  for_each = var.enable_sulu_control_api && var.create_ecs && var.create_sulu ? {
    "GET /status" = "GET /status",
    "POST /start" = "POST /start",
    "POST /stop"  = "POST /stop"
  } : {}

  api_id    = aws_apigatewayv2_api.sulu_control[0].id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.sulu_control[0].id}"
}

resource "aws_apigatewayv2_stage" "sulu_control" {
  count = var.enable_sulu_control_api && var.create_ecs && var.create_sulu ? 1 : 0

  api_id      = aws_apigatewayv2_api.sulu_control[0].id
  name        = local.control_api_stage_name
  auto_deploy = true

  tags = merge(local.tags, { Name = "${local.control_api_name}-stage" })
}

resource "aws_lambda_permission" "sulu_control" {
  count = var.enable_sulu_control_api && var.create_ecs && var.create_sulu ? 1 : 0

  statement_id  = "AllowAPIGatewayInvokeSuluControl"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sulu_control[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.sulu_control[0].execution_arn}/*/*"
}
