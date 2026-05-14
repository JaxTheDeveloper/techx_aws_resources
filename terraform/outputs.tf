# ──────────────────────────────────────────────────────────────────────────────
# Outputs — values consumed by other Terraform modules or referenced
# when configuring API Gateway, Lambda, RDS Proxy, and RDS resources.
# ──────────────────────────────────────────────────────────────────────────────

# ══════════════════════════════════════════════════════════════════════════════
# VPC IDs & CIDRs
# ══════════════════════════════════════════════════════════════════════════════

output "ingress_vpc_id" {
  description = "ID of the Ingress VPC (API Gateway VPC Link, execute-api endpoint)"
  value       = aws_vpc.ingress.id
}

output "ingress_vpc_cidr" {
  description = "CIDR block of the Ingress VPC"
  value       = aws_vpc.ingress.cidr_block
}

output "app_vpc_id" {
  description = "ID of the Application VPC (Lambda functions) — pass to every Lambda VPC config"
  value       = aws_vpc.app.id
}

output "app_vpc_cidr" {
  description = "CIDR block of the Application VPC"
  value       = aws_vpc.app.cidr_block
}

output "db_vpc_id" {
  description = "ID of the Database VPC (RDS Proxy + RDS PostgreSQL)"
  value       = aws_vpc.db.id
}

output "db_vpc_cidr" {
  description = "CIDR block of the Database VPC"
  value       = aws_vpc.db.cidr_block
}

# ══════════════════════════════════════════════════════════════════════════════
# Subnet IDs
# ══════════════════════════════════════════════════════════════════════════════

output "ingress_subnet_ids" {
  description = "IDs of the Ingress VPC subnets (one per AZ)"
  value       = aws_subnet.ingress[*].id
}

output "app_subnet_ids" {
  description = "IDs of the Application VPC private subnets — Lambda VpcConfig.SubnetIds"
  value       = aws_subnet.app[*].id
}

output "db_subnet_ids" {
  description = "IDs of the Database VPC isolated subnets — RDS SubnetGroup / RDS Proxy SubnetIds"
  value       = aws_subnet.db[*].id
}

output "db_subnet_group_name" {
  description = "Name of the RDS DB subnet group — RDS instance parameter"
  value       = aws_db_subnet_group.main.name
}

# ══════════════════════════════════════════════════════════════════════════════
# Route Table IDs
# ══════════════════════════════════════════════════════════════════════════════

output "rtb_ingress_id" {
  description = "Route table ID for the Ingress VPC"
  value       = aws_route_table.ingress.id
}

output "rtb_app_id" {
  description = "Route table ID for the Application VPC"
  value       = aws_route_table.app.id
}

output "rtb_db_id" {
  description = "Route table ID for the Database VPC"
  value       = aws_route_table.db.id
}

# ══════════════════════════════════════════════════════════════════════════════
# VPC Peering Connection IDs
# ══════════════════════════════════════════════════════════════════════════════

output "peering_ingress_to_app_id" {
  description = "VPC Peering connection ID: Ingress VPC ↔ Application VPC"
  value       = aws_vpc_peering_connection.ingress_to_app.id
}

output "peering_app_to_db_id" {
  description = "VPC Peering connection ID: Application VPC ↔ Database VPC"
  value       = aws_vpc_peering_connection.app_to_db.id
}

# ══════════════════════════════════════════════════════════════════════════════
# Security Group IDs
# ══════════════════════════════════════════════════════════════════════════════

output "sg_lambda_id" {
  description = "Security group ID for Lambda functions (Application VPC) — Lambda VpcConfig.SecurityGroupIds"
  value       = aws_security_group.lambda.id
}

output "sg_rds_proxy_id" {
  description = "Security group ID for RDS Proxy (Database VPC) — RDS Proxy VpcSecurityGroupIds"
  value       = aws_security_group.rds_proxy.id
}

output "sg_rds_postgresql_id" {
  description = "Security group ID for RDS PostgreSQL (Database VPC) — RDS instance VpcSecurityGroupIds"
  value       = aws_security_group.rds_postgresql.id
}

output "sg_app_vpc_endpoints_id" {
  description = "Security group ID shared by Interface VPC Endpoints in the Application VPC"
  value       = aws_security_group.app_vpc_endpoints.id
}

output "sg_db_vpc_endpoints_id" {
  description = "Security group ID shared by Interface VPC Endpoints in the Database VPC"
  value       = aws_security_group.db_vpc_endpoints.id
}

output "sg_ingress_vpc_endpoints_id" {
  description = "Security group ID for the execute-api Interface Endpoint in the Ingress VPC"
  value       = aws_security_group.ingress_vpc_endpoints.id
}

# ══════════════════════════════════════════════════════════════════════════════
# VPC Endpoint IDs
# ══════════════════════════════════════════════════════════════════════════════

output "vpce_execute_api_id" {
  description = "ID of the execute-api Interface VPC Endpoint (Ingress VPC)"
  value       = aws_vpc_endpoint.execute_api.id
}

output "vpce_s3_app_id" {
  description = "ID of the S3 Gateway VPC Endpoint (Application VPC)"
  value       = aws_vpc_endpoint.s3_app.id
}

output "vpce_sns_id" {
  description = "ID of the SNS Interface VPC Endpoint (Application VPC)"
  value       = aws_vpc_endpoint.sns.id
}

output "vpce_sts_id" {
  description = "ID of the STS Interface VPC Endpoint (Application VPC)"
  value       = aws_vpc_endpoint.sts.id
}

output "vpce_bedrock_runtime_id" {
  description = "ID of the Bedrock Runtime Interface VPC Endpoint (Application VPC)"
  value       = aws_vpc_endpoint.bedrock_runtime.id
}

output "vpce_bedrock_agent_runtime_id" {
  description = "ID of the Bedrock Agent Runtime Interface VPC Endpoint (Application VPC)"
  value       = aws_vpc_endpoint.bedrock_agent_runtime.id
}

output "vpce_logs_id" {
  description = "ID of the CloudWatch Logs Interface VPC Endpoint (Application VPC)"
  value       = aws_vpc_endpoint.logs.id
}

output "vpce_secretsmanager_id" {
  description = "ID of the Secrets Manager Interface VPC Endpoint (Database VPC)"
  value       = aws_vpc_endpoint.secretsmanager.id
}

output "vpce_s3_db_id" {
  description = "ID of the S3 Gateway VPC Endpoint (Database VPC)"
  value       = aws_vpc_endpoint.s3_db.id
}

# ══════════════════════════════════════════════════════════════════════════════
# VPC Flow Logs
# ══════════════════════════════════════════════════════════════════════════════

output "flow_log_ingress_id" {
  description = "Flow Log resource ID for the Ingress VPC"
  value       = aws_flow_log.ingress.id
}

output "flow_log_app_id" {
  description = "Flow Log resource ID for the Application VPC"
  value       = aws_flow_log.app.id
}

output "flow_log_db_id" {
  description = "Flow Log resource ID for the Database VPC"
  value       = aws_flow_log.db.id
}

output "flow_log_group_ingress" {
  description = "CloudWatch Log Group name for Ingress VPC Flow Logs"
  value       = aws_cloudwatch_log_group.flow_logs_ingress.name
}

output "flow_log_group_app" {
  description = "CloudWatch Log Group name for Application VPC Flow Logs"
  value       = aws_cloudwatch_log_group.flow_logs_app.name
}

output "flow_log_group_db" {
  description = "CloudWatch Log Group name for Database VPC Flow Logs"
  value       = aws_cloudwatch_log_group.flow_logs_db.name
}

output "flow_log_iam_role_arn" {
  description = "ARN of the IAM role used by all three VPC Flow Logs"
  value       = aws_iam_role.flow_logs.arn
}
