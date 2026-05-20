# ══════════════════════════════════════════════════════════════════════════════
# INGRESS VPC SECURITY GROUPS
# ══════════════════════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────────────────────
# SG: VPC Endpoints — Ingress VPC
#
# Hosts the execute-api Interface Endpoint. Accepts HTTPS from within the
# Ingress VPC CIDR only.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_security_group" "ingress_vpc_endpoints" {
  name        = "${var.project_name}-sg-ingress-vpce"
  description = "Shared SG for Interface VPC Endpoints in the Ingress VPC"
  vpc_id      = aws_vpc.ingress.id

  ingress {
    description = "HTTPS from Ingress VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.ingress_vpc_cidr]
  }

  tags = {
    Name = "${var.project_name}-sg-ingress-vpce"
    Tier = "ingress"
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# APPLICATION VPC SECURITY GROUPS
# ══════════════════════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────────────────────
# SG: Lambda
#
# Inbound:  None — Lambda is event-driven (API GW, EventBridge, SQS triggers).
#           It never acts as a server receiving direct TCP connections.
# Outbound: Port 5432 to RDS Proxy SG (Database VPC, via peering).
#           Port 443  to Interface VPC Endpoints within the Application VPC
#                       (SNS, STS, Bedrock Runtime, Bedrock Agent, CW Logs).
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-sg-lambda"
  description = "Security group for Lambda functions in the Application VPC"
  vpc_id      = aws_vpc.app.id

  tags = {
    Name = "${var.project_name}-sg-lambda"
    Tier = "application"
  }
}

# No inbound rules — Lambda is event-driven, never a server.

# Lambda to RDS Proxy across the App↔DB VPC peering connection
resource "aws_security_group_rule" "lambda_egress_to_rds_proxy" {
  type              = "egress"
  description       = "Lambda to RDS Proxy (PostgreSQL) across App-to-DB VPC peering"
  security_group_id = aws_security_group.lambda.id
  cidr_blocks       = [var.db_vpc_cidr]
  protocol          = "tcp"
  from_port         = 5432
  to_port           = 5432
}

# Lambda to Interface VPC Endpoints inside the Application VPC (HTTPS)
resource "aws_security_group_rule" "lambda_egress_https_endpoints" {
  type              = "egress"
  description       = "Lambda to Interface VPC Endpoints (SNS, STS, Bedrock, CloudWatch Logs)"
  security_group_id = aws_security_group.lambda.id
  cidr_blocks       = [var.app_vpc_cidr]
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
}

# ──────────────────────────────────────────────────────────────────────────────
# SG: VPC Endpoints — Application VPC
#
# Shared SG for all Interface Endpoints in the Application VPC.
# Accepts HTTPS from Lambda SG (preferred, SG-reference) and from the full
# Application VPC CIDR (covers any future Lambda or compute that joins
# this VPC without a dedicated SG).
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_security_group" "app_vpc_endpoints" {
  name        = "${var.project_name}-sg-app-vpce"
  description = "Shared SG for Interface VPC Endpoints in the Application VPC"
  vpc_id      = aws_vpc.app.id

  tags = {
    Name = "${var.project_name}-sg-app-vpce"
    Tier = "application"
  }
}

resource "aws_security_group_rule" "app_vpce_ingress_from_lambda" {
  type                     = "ingress"
  description              = "HTTPS from Lambda SG"
  security_group_id        = aws_security_group.app_vpc_endpoints.id
  source_security_group_id = aws_security_group.lambda.id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
}

# ══════════════════════════════════════════════════════════════════════════════
# DATABASE VPC SECURITY GROUPS
# ══════════════════════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────────────────────
# SG: RDS Proxy
#
# Inbound:  Port 5432 from Application VPC CIDR (Lambda across VPC peering).
#           Cannot reference the Lambda SG directly because it lives in a
#           different VPC; CIDR-based rule is the correct approach here.
# Outbound: Port 5432 to RDS PostgreSQL SG (same VPC, SG-reference safe).
#           Port 443  to Secrets Manager Interface Endpoint (DB VPC, CIDR).
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_security_group" "rds_proxy" {
  name        = "${var.project_name}-sg-rds-proxy"
  description = "Security group for RDS Proxy - accepts PostgreSQL from Application VPC only"
  vpc_id      = aws_vpc.db.id

  tags = {
    Name = "${var.project_name}-sg-rds-proxy"
    Tier = "database"
  }
}

# Inbound from Lambda (Application VPC CIDR — cross-VPC, no SG reference possible)
resource "aws_security_group_rule" "rds_proxy_ingress_from_app_vpc" {
  type              = "ingress"
  description       = "PostgreSQL from Lambda (Application VPC CIDR via peering)"
  security_group_id = aws_security_group.rds_proxy.id
  cidr_blocks       = [var.app_vpc_cidr]
  protocol          = "tcp"
  from_port         = 5432
  to_port           = 5432
}

# Outbound to RDS PostgreSQL (same VPC, SG-reference)
resource "aws_security_group_rule" "rds_proxy_egress_to_rds" {
  type                     = "egress"
  description              = "RDS Proxy to RDS PostgreSQL (native DB login)"
  security_group_id        = aws_security_group.rds_proxy.id
  source_security_group_id = aws_security_group.rds_postgresql.id
  protocol                 = "tcp"
  from_port                = 5432
  to_port                  = 5432
}

# Outbound to Secrets Manager Interface Endpoint within the Database VPC
resource "aws_security_group_rule" "rds_proxy_egress_secrets_manager" {
  type              = "egress"
  description       = "RDS Proxy to Secrets Manager VPC Endpoint (fetch master password)"
  security_group_id = aws_security_group.rds_proxy.id
  cidr_blocks       = [var.db_vpc_cidr]
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
}

# ──────────────────────────────────────────────────────────────────────────────
# SG: RDS PostgreSQL
#
# Inbound:  Port 5432 from RDS Proxy SG only (same VPC, SG-reference).
# Outbound: None — the core DB instance never initiates outbound connections.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_security_group" "rds_postgresql" {
  name        = "${var.project_name}-sg-rds-postgresql"
  description = "Security group for RDS PostgreSQL - accepts only from RDS Proxy SG"
  vpc_id      = aws_vpc.db.id

  tags = {
    Name = "${var.project_name}-sg-rds-postgresql"
    Tier = "database"
  }
}

resource "aws_security_group_rule" "rds_postgresql_ingress_from_proxy" {
  type                     = "ingress"
  description              = "PostgreSQL from RDS Proxy SG only"
  security_group_id        = aws_security_group.rds_postgresql.id
  source_security_group_id = aws_security_group.rds_proxy.id
  protocol                 = "tcp"
  from_port                = 5432
  to_port                  = 5432
}

# Intentionally no egress rules — RDS instance is fully isolated outbound.

# ──────────────────────────────────────────────────────────────────────────────
# SG: VPC Endpoints — Database VPC
#
# Hosts the Secrets Manager Interface Endpoint used by RDS Proxy.
# Accepts HTTPS from the RDS Proxy SG only (tightest possible scope).
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_security_group" "db_vpc_endpoints" {
  name        = "${var.project_name}-sg-db-vpce"
  description = "Shared SG for Interface VPC Endpoints in the Database VPC (Secrets Manager)"
  vpc_id      = aws_vpc.db.id

  tags = {
    Name = "${var.project_name}-sg-db-vpce"
    Tier = "database"
  }
}

resource "aws_security_group_rule" "db_vpce_ingress_from_rds_proxy" {
  type                     = "ingress"
  description              = "HTTPS from RDS Proxy SG (Secrets Manager password fetch)"
  security_group_id        = aws_security_group.db_vpc_endpoints.id
  source_security_group_id = aws_security_group.rds_proxy.id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
}
