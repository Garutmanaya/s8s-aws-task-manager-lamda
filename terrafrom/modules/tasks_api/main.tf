# This module packages the Lambda handlers, grants DynamoDB access,
# and exposes the task management API through API Gateway.

data "archive_file" "tasks_lambda_package" {
  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = "${path.module}/tasks_lambda.zip"
}

data "aws_region" "current" {}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_dynamodb_access" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:UpdateItem"
    ]
    resources = [var.tasks_table_arn]
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.project_name}-${var.environment}-tasks-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_dynamodb_access" {
  name   = "${var.project_name}-${var.environment}-tasks-dynamodb"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_dynamodb_access.json
}

# One router Lambda dispatches requests to the existing task handler files.
resource "aws_lambda_function" "tasks" {
  filename         = data.archive_file.tasks_lambda_package.output_path
  function_name    = "${var.project_name}-${var.environment}-tasks"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda_exec.arn
  source_code_hash = data.archive_file.tasks_lambda_package.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TASKS_TABLE = var.tasks_table_name
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway exposes authenticated CRUD-like routes for tasks.
resource "aws_api_gateway_rest_api" "tasks_api" {
  name = "${var.project_name}-${var.environment}-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_authorizer" "cognito" {
  name            = "${var.project_name}-${var.environment}-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.tasks_api.id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [var.user_pool_arn]
  identity_source = "method.request.header.Authorization"
}

resource "aws_api_gateway_resource" "tasks" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  parent_id   = aws_api_gateway_rest_api.tasks_api.root_resource_id
  path_part   = "tasks"
}

resource "aws_api_gateway_resource" "tasks_close" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  parent_id   = aws_api_gateway_resource.tasks.id
  path_part   = "close"
}

resource "aws_api_gateway_method" "get_tasks" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  resource_id   = aws_api_gateway_resource.tasks.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_method" "post_tasks" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  resource_id   = aws_api_gateway_resource.tasks.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_method" "put_tasks" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  resource_id   = aws_api_gateway_resource.tasks.id
  http_method   = "PUT"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_method" "post_close_task" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  resource_id   = aws_api_gateway_resource.tasks_close.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "get_tasks_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.tasks_api.id
  resource_id             = aws_api_gateway_resource.tasks.id
  http_method             = aws_api_gateway_method.get_tasks.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.tasks.invoke_arn
}

resource "aws_api_gateway_integration" "post_tasks_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.tasks_api.id
  resource_id             = aws_api_gateway_resource.tasks.id
  http_method             = aws_api_gateway_method.post_tasks.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.tasks.invoke_arn
}

resource "aws_api_gateway_integration" "put_tasks_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.tasks_api.id
  resource_id             = aws_api_gateway_resource.tasks.id
  http_method             = aws_api_gateway_method.put_tasks.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.tasks.invoke_arn
}

resource "aws_api_gateway_integration" "post_close_task_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.tasks_api.id
  resource_id             = aws_api_gateway_resource.tasks_close.id
  http_method             = aws_api_gateway_method.post_close_task.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.tasks.invoke_arn
}

# Explicit CORS support is required because the static frontend calls the API from another origin.
resource "aws_api_gateway_method" "tasks_options" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  resource_id   = aws_api_gateway_resource.tasks.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "tasks_options" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  resource_id = aws_api_gateway_resource.tasks.id
  http_method = aws_api_gateway_method.tasks_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "tasks_options" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  resource_id = aws_api_gateway_resource.tasks.id
  http_method = aws_api_gateway_method.tasks_options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "tasks_options" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  resource_id = aws_api_gateway_resource.tasks.id
  http_method = aws_api_gateway_method.tasks_options.http_method
  status_code = aws_api_gateway_method_response.tasks_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Authorization,Content-Type'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_method" "tasks_close_options" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  resource_id   = aws_api_gateway_resource.tasks_close.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "tasks_close_options" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  resource_id = aws_api_gateway_resource.tasks_close.id
  http_method = aws_api_gateway_method.tasks_close_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "tasks_close_options" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  resource_id = aws_api_gateway_resource.tasks_close.id
  http_method = aws_api_gateway_method.tasks_close_options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "tasks_close_options" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  resource_id = aws_api_gateway_resource.tasks_close.id
  http_method = aws_api_gateway_method.tasks_close_options.http_method
  status_code = aws_api_gateway_method_response.tasks_close_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Authorization,Content-Type'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tasks.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.tasks_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "tasks_api" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.tasks.id,
      aws_api_gateway_resource.tasks_close.id,
      aws_api_gateway_method.get_tasks.id,
      aws_api_gateway_method.post_tasks.id,
      aws_api_gateway_method.put_tasks.id,
      aws_api_gateway_method.post_close_task.id,
      aws_api_gateway_method.tasks_options.id,
      aws_api_gateway_method.tasks_close_options.id,
      aws_api_gateway_integration.get_tasks_lambda.id,
      aws_api_gateway_integration.post_tasks_lambda.id,
      aws_api_gateway_integration.put_tasks_lambda.id,
      aws_api_gateway_integration.post_close_task_lambda.id,
      aws_api_gateway_integration.tasks_options.id,
      aws_api_gateway_integration.tasks_close_options.id,
      aws_api_gateway_integration_response.tasks_options.id,
      aws_api_gateway_integration_response.tasks_close_options.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.get_tasks_lambda,
    aws_api_gateway_integration.post_tasks_lambda,
    aws_api_gateway_integration.put_tasks_lambda,
    aws_api_gateway_integration.post_close_task_lambda,
    aws_api_gateway_integration.tasks_options,
    aws_api_gateway_integration.tasks_close_options,
    aws_api_gateway_integration_response.tasks_options,
    aws_api_gateway_integration_response.tasks_close_options
  ]
}

resource "aws_api_gateway_stage" "tasks_api" {
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  deployment_id = aws_api_gateway_deployment.tasks_api.id
  stage_name    = var.environment
}
