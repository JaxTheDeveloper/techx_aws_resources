# ─── HTTP API ─────────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_api" "dochub" {
  name          = "${var.project_name}-http-api"
  protocol_type = "HTTP"
  description   = "DocHub backend API"

  cors_configuration {
    allow_origins  = ["*"]
    allow_methods  = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers  = ["Authorization", "Content-Type", "X-Amz-Date", "X-Api-Key"]
    expose_headers = ["Content-Length"]
    max_age        = 300
  }

  tags = { Name = "${var.project_name}-http-api" }
}

# ─── Stage ────────────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.dochub.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      ip                      = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      httpMethod              = "$context.httpMethod"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      protocol                = "$context.protocol"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }

  tags = { Name = "${var.project_name}-api-stage" }
}

resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/apigateway/${var.project_name}"
  retention_in_days = 7
  tags              = { Name = "${var.project_name}-apigw-logs" }
}

# ─── JWT Authorizer (Cognito) ─────────────────────────────────────────────────

resource "aws_apigatewayv2_authorizer" "cognito_jwt" {
  api_id           = aws_apigatewayv2_api.dochub.id
  authorizer_type  = "JWT"
  name             = "DocHub-Cognito-JWT-Authorizer"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.dochub.id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.dochub.id}"
  }
}

# ─── Lambda Integration ───────────────────────────────────────────────────────

resource "aws_apigatewayv2_integration" "backend" {
  api_id                 = aws_apigatewayv2_api.dochub.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.backend.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000
}

resource "aws_lambda_permission" "apigw_backend" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.dochub.execution_arn}/*/*"
}

# ─── Routes ───────────────────────────────────────────────────────────────────

# Public health check — no auth
resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.dochub.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

# Protected routes — JWT required
resource "aws_apigatewayv2_route" "upload" {
  api_id             = aws_apigatewayv2_api.dochub.id
  route_key          = "POST /upload"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
  target             = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

resource "aws_apigatewayv2_route" "query" {
  api_id             = aws_apigatewayv2_api.dochub.id
  route_key          = "POST /query"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
  target             = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

resource "aws_apigatewayv2_route" "docs_list" {
  api_id             = aws_apigatewayv2_api.dochub.id
  route_key          = "GET /docs/list"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
  target             = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

# CORS preflight
resource "aws_apigatewayv2_route" "options" {
  api_id    = aws_apigatewayv2_api.dochub.id
  route_key = "OPTIONS /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.backend.id}"
}
