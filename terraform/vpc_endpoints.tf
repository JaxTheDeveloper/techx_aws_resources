# ══════════════════════════════════════════════════════════════════════════════
# INGRESS VPC ENDPOINTS
# ══════════════════════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────────────────────
# EXECUTE-API INTERFACE ENDPOINT — Ingress VPC
#
# Enables the private REST/HTTP API Gateway to be reachable from within the
# Ingress VPC without traversing the public internet.
# API Gateway itself is a managed service outside any VPC; this endpoint
# creates the ENI bridge inside the Ingress VPC.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_vpc_endpoint" "execute_api" {
  vpc_id              = aws_vpc.ingress.id
  service_name        = "com.amazonaws.${var.aws_region}.execute-api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.ingress[*].id

  security_group_ids = [
    aws_security_group.ingress_vpc_endpoints.id,
  ]

  tags = {
    Name = "${var.project_name}-vpce-execute-api"
    Tier = "ingress"
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# APPLICATION VPC ENDPOINTS
#
# All Lambda-facing AWS service endpoints live here. Every call from a Lambda
# function to SNS, STS, Bedrock, or CloudWatch stays on the AWS backbone.
# ══════════════════════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────────────────────
# S3 GATEWAY ENDPOINT — Application VPC
#
# Free Gateway-type endpoint. Routes S3 traffic from Lambda entirely within
# the AWS network — no NAT Gateway charges, no public path.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_vpc_endpoint" "s3_app" {
  vpc_id            = aws_vpc.app.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.app.id,
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowFullS3Access"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject",
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-vpce-s3-gateway-app"
    Tier = "application"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# SNS INTERFACE ENDPOINT — Application VPC
#
# Allows Lambda (Data_Aggregation_Worker, Anomaly_Logging_Service) to publish
# SNS messages to CAPCOM_Alerts, EECOM_Alerts, and FIDO_Alerts topics
# without routing through NAT or the public internet.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_vpc_endpoint" "sns" {
  vpc_id              = aws_vpc.app.id
  service_name        = "com.amazonaws.${var.aws_region}.sns"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.app[*].id

  security_group_ids = [
    aws_security_group.app_vpc_endpoints.id,
  ]

  tags = {
    Name = "${var.project_name}-vpce-sns"
    Tier = "application"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# STS INTERFACE ENDPOINT — Application VPC
#
# Lambda functions use STS to generate short-lived SigV4 tokens (15 min)
# for IAM-authenticated RDS Proxy connections (TOKEN_GENERATION phase).
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.app.id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.app[*].id

  security_group_ids = [
    aws_security_group.app_vpc_endpoints.id,
  ]

  tags = {
    Name = "${var.project_name}-vpce-sts"
    Tier = "application"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# BEDROCK RUNTIME INTERFACE ENDPOINT — Application VPC
#
# Allows the Chatbot Backend Lambda to call Amazon Bedrock
# (InvokeModel / RetrieveAndGenerate) without public internet egress.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_vpc_endpoint" "bedrock_runtime" {
  vpc_id              = aws_vpc.app.id
  service_name        = "com.amazonaws.${var.aws_region}.bedrock-runtime"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.app[*].id

  security_group_ids = [
    aws_security_group.app_vpc_endpoints.id,
  ]

  tags = {
    Name = "${var.project_name}-vpce-bedrock-runtime"
    Tier = "application"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# BEDROCK AGENT RUNTIME INTERFACE ENDPOINT — Application VPC
#
# Used for Knowledge Base queries (RAG retrieve-and-generate pipeline).
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_vpc_endpoint" "bedrock_agent_runtime" {
  vpc_id              = aws_vpc.app.id
  service_name        = "com.amazonaws.${var.aws_region}.bedrock-agent-runtime"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.app[*].id

  security_group_ids = [
    aws_security_group.app_vpc_endpoints.id,
  ]

  tags = {
    Name = "${var.project_name}-vpce-bedrock-agent-runtime"
    Tier = "application"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# CLOUDWATCH LOGS INTERFACE ENDPOINT — Application VPC
#
# Lets Lambda emit structured logs to CloudWatch without NAT.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.app.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.app[*].id

  security_group_ids = [
    aws_security_group.app_vpc_endpoints.id,
  ]

  tags = {
    Name = "${var.project_name}-vpce-logs"
    Tier = "application"
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# DATABASE VPC ENDPOINTS
#
# Kept minimal and isolated. Only the services that the DB tier itself must
# call (Secrets Manager for RDS Proxy password rotation) are placed here.
# ══════════════════════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────────────────────
# SECRETS MANAGER INTERFACE ENDPOINT — Database VPC
#
# RDS Proxy uses this endpoint (over HTTPS/443) to fetch and rotate the
# master password without leaving the Database VPC. Placing it here — rather
# than in the Application VPC — means the Proxy never needs to traverse the
# peering connection just to get credentials.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.db.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.db[*].id

  security_group_ids = [
    aws_security_group.db_vpc_endpoints.id,
  ]

  tags = {
    Name = "${var.project_name}-vpce-secretsmanager"
    Tier = "database"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# S3 GATEWAY ENDPOINT — Database VPC
#
# Free Gateway-type endpoint. Allows RDS to export automated snapshots and
# Enhanced Monitoring data to S3 without leaving the AWS backbone.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_vpc_endpoint" "s3_db" {
  vpc_id            = aws_vpc.db.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.db.id,
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowRDSBackupsToS3"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-vpce-s3-gateway-db"
    Tier = "database"
  }
}
