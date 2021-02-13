provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "iam_for_lambda" {
  name = var.lambda_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "terraform_lambda" {
  function_name = var.lambda_function_name

  filename = var.lambda_zip_file
  source_code_hash = filebase64sha256(var.lambda_zip_file)

  handler = "lambda_function.lambda_handler"
  role    = aws_iam_role.iam_for_lambda.arn
  runtime = "ruby2.7"
  timeout = 30

  environment {
    variables = {
      JWT_ISSUER = var.jwt_issuer,
      JWT_SECRET = var.jwt_secret,
      VALID_KEY = var.valid_key
    }
  }
}

############ API Gateway ############

resource aws_api_gateway_rest_api api {
  description = var.api_description
  name        = var.api_name
}


resource aws_api_gateway_resource proxy {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

resource aws_api_gateway_method proxy_any {
  authorization = "NONE"
  http_method   = "ANY"
  resource_id   = aws_api_gateway_resource.proxy.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  api_key_required = true
}

resource aws_api_gateway_method get {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  api_key_required = true
}


resource aws_api_gateway_integration proxy_any {
  content_handling        = "CONVERT_TO_TEXT"
  http_method             = aws_api_gateway_method.proxy_any.http_method
  integration_http_method = "POST"
  resource_id             = aws_api_gateway_resource.proxy.id
  rest_api_id             = aws_api_gateway_rest_api.api.id
  timeout_milliseconds    = var.api_timeout
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.terraform_lambda.invoke_arn
}

resource aws_api_gateway_integration get {
  content_handling        = "CONVERT_TO_TEXT"
  http_method             = aws_api_gateway_method.get.http_method
  integration_http_method = "POST"
  resource_id             = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id             = aws_api_gateway_rest_api.api.id
  timeout_milliseconds    = var.api_timeout
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.terraform_lambda.invoke_arn
}

resource aws_lambda_permission invoke {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_deployment" "phony_adt" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy_any.id,
      aws_api_gateway_method.get.id,
      aws_api_gateway_integration.proxy_any.id,
      aws_api_gateway_integration.get.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "development" {
  deployment_id = aws_api_gateway_deployment.phony_adt.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "development"
}

## Create API Key
resource "aws_api_gateway_api_key" "development_key" {
  name = "phony_adt_development_key"
}

resource "aws_api_gateway_usage_plan" "dev_usage_plan" {
  name = "Development Usage Plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.development.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "dev" {
  key_id        = aws_api_gateway_api_key.development_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.dev_usage_plan.id
}