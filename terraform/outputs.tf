# ─── Frontend ─────────────────────────────────────────────────────────────────

output "cloudfront_url" {
  description = "Public HTTPS URL for the DocHub frontend (share this with trainers)"
  value       = local.use_custom_domain ? "https://${var.custom_domain}" : "https://${aws_cloudfront_distribution.dochub.domain_name}"
}

output "custom_domain_url" {
  description = "Custom domain URL (empty if custom_domain is not configured)"
  value       = local.use_custom_domain ? "https://${var.custom_domain}" : ""
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (needed for cache invalidation)"
  value       = aws_cloudfront_distribution.dochub.id
}

output "frontend_bucket_name" {
  description = "S3 bucket name for static frontend files"
  value       = aws_s3_bucket.frontend.bucket
}

output "documents_bucket_name" {
  description = "S3 bucket name for tenant documents"
  value       = aws_s3_bucket.documents.bucket
}

# ─── API ──────────────────────────────────────────────────────────────────────

output "api_gateway_endpoint" {
  description = "API Gateway HTTP endpoint"
  value       = aws_apigatewayv2_api.dochub.api_endpoint
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.dochub.id
}

# ─── Auth ─────────────────────────────────────────────────────────────────────

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.dochub.id
}

output "cognito_app_client_id" {
  description = "Cognito App Client ID (use in frontend config)"
  value       = aws_cognito_user_pool_client.dochub.id
}

output "cognito_login_url" {
  description = "Cognito hosted UI login URL"
  value       = "https://${aws_cognito_user_pool_domain.dochub.domain}.auth.${var.aws_region}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.dochub.id}&response_type=code&scope=openid+email+profile&redirect_uri=${urlencode(local.use_custom_domain ? "https://${var.custom_domain}/callback" : "https://${aws_cloudfront_distribution.dochub.domain_name}/callback")}"
}

# ─── Network ──────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.vpc.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.vpc.cidr_block
}

output "private_subnet_az1_id" {
  description = "AZ-1 private subnet ID"
  value       = aws_subnet.vpc_az1_private_app.id
}

output "private_subnet_az2_id" {
  description = "AZ-2 private subnet ID"
  value       = aws_subnet.vpc_az2_private_app.id
}

# ─── AI / Data ────────────────────────────────────────────────────────────────

output "bedrock_kb_id" {
  description = "Bedrock Knowledge Base ID"
  value       = aws_bedrockagent_knowledge_base.dochub.id
}

output "bedrock_ds_id" {
  description = "Bedrock Knowledge Base Data Source ID"
  value       = aws_bedrockagent_data_source.dochub.data_source_id
}

output "bedrock_agent_id" {
  description = "Bedrock Agent ID"
  value       = aws_bedrockagent_agent.dochub.agent_id
}

output "bedrock_agent_alias_id" {
  description = "Bedrock Agent Alias ID"
  value       = aws_bedrockagent_agent_alias.dochub.agent_alias_id
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.dochub_docs.name
}

output "opensearch_collection_endpoint" {
  description = "OpenSearch Serverless collection endpoint"
  value       = aws_opensearchserverless_collection.vectors.collection_endpoint
}

# ─── KMS ──────────────────────────────────────────────────────────────────────

output "kms_key_arn" {
  description = "KMS CMK ARN used for S3 and DynamoDB encryption"
  value       = aws_kms_key.dochub_cmk.arn
}

output "kms_key_id" {
  description = "KMS CMK Key ID"
  value       = aws_kms_key.dochub_cmk.key_id
}

# ─── Lambda ───────────────────────────────────────────────────────────────────

output "backend_lambda_arn" {
  description = "Backend Lambda ARN"
  value       = aws_lambda_function.backend.arn
}

output "kb_sync_lambda_arn" {
  description = "KB Sync Lambda ARN"
  value       = aws_lambda_function.kb_sync.arn
}
