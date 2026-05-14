###############################################################################
# security_groups.tf — W5 MH2: Security Groups for Serverless Architecture
#
# Traffic chain:
#   API Gateway → Lambda (lambda_sg)
#                     ↓ port 2049      ↓ port 5432
#                 EFS (efs_sg)     RDS Proxy (rds_proxy_sg)
#                                       ↓ port 5432
#                                   RDS PostgreSQL (rds_sg)
###############################################################################


###############################################################################
# VPC-1 — LAMBDA SECURITY GROUP
# Lambda functions live here. No inbound (triggered by API Gateway/EventBridge).
# Outbound: EFS (2049), RDS Proxy in VPC2 (5432), AWS services (443).
###############################################################################

resource "aws_security_group" "lambda_sg" {
  name        = "${var.project_name}-lambda-sg"
  description = "Lambda functions — no inbound, controlled outbound only"
  vpc_id      = aws_vpc.vpc1.id

  # No inbound rules — Lambda is triggered by API Gateway / EventBridge, not HTTP

  # Outbound: reach EFS mount target in same VPC
  egress {
    description = "NFS to EFS mount target"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }

  # Outbound: reach RDS Proxy in VPC-2 via VPC Peering
  egress {
    description = "PostgreSQL to RDS Proxy in VPC-2"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc2_cidr]
  }

  # Outbound: reach AWS services (Bedrock, Secrets Manager, S3) via HTTPS
  egress {
    description = "HTTPS to AWS managed services and VPC endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-lambda-sg"
    Environment = var.environment
    Purpose     = "Lambda functions security group"
  }
}


###############################################################################
# VPC-1 — EFS SECURITY GROUP
# Mount target for EFS. Only accepts NFS (2049) from Lambda SG.
# No outbound needed — EFS responds on same connection.
###############################################################################

resource "aws_security_group" "efs_sg" {
  name        = "${var.project_name}-efs-sg"
  description = "EFS mount target — NFS inbound from Lambda SG only"
  vpc_id      = aws_vpc.vpc1.id

  # Inbound: NFS from Lambda only (SG reference — not CIDR)
  ingress {
    description     = "NFS from Lambda functions"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  # Outbound: allow responses back to Lambda
  egress {
    description     = "NFS responses back to Lambda"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  tags = {
    Name        = "${var.project_name}-efs-sg"
    Environment = var.environment
    Purpose     = "EFS mount target security group"
  }
}


###############################################################################
# VPC-2 — RDS PROXY SECURITY GROUP
# Accepts connections from Lambda (VPC-1) only via peering.
# Connects out to RDS PostgreSQL inside VPC-2.
###############################################################################

resource "aws_security_group" "rds_proxy_sg" {
  name        = "${var.project_name}-rds-proxy-sg"
  description = "RDS Proxy — accept from Lambda VPC only, connect to RDS"
  vpc_id      = aws_vpc.vpc2.id

  # Inbound: PostgreSQL from VPC-1 app subnets (Lambda via peering)
  ingress {
    description = "PostgreSQL from Lambda in VPC-1"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }

  # Outbound: PostgreSQL to RDS instances inside VPC-2
  egress {
    description = "PostgreSQL to RDS instances"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc2_cidr]
  }

  # Outbound: HTTPS to Secrets Manager (to fetch DB credentials)
  egress {
    description = "HTTPS to Secrets Manager VPC endpoint"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc2_cidr]
  }

  tags = {
    Name        = "${var.project_name}-rds-proxy-sg"
    Environment = var.environment
    Purpose     = "RDS Proxy security group"
  }
}


###############################################################################
# VPC-2 — RDS POSTGRESQL SECURITY GROUP
# Only accepts from RDS Proxy. No outbound — DB never initiates connections.
###############################################################################

resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "RDS PostgreSQL — accept from RDS Proxy only, no outbound"
  vpc_id      = aws_vpc.vpc2.id

  # Inbound: PostgreSQL from RDS Proxy only
  ingress {
    description     = "PostgreSQL from RDS Proxy only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_proxy_sg.id]
  }

  # No egress rules — RDS never initiates outbound connections

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
    Purpose     = "RDS PostgreSQL security group"
  }
}


###############################################################################
# NOTE: vpc2_endpoint_sg already defined in vpc2.tf — NOT repeated here
# to avoid Terraform duplicate resource conflict.
###############################################################################


###############################################################################
# OUTPUTS — export SG IDs for use in other modules (Lambda, EFS, RDS configs)
###############################################################################

output "lambda_sg_id" {
  description = "Security Group ID for Lambda functions"
  value       = aws_security_group.lambda_sg.id
}

output "efs_sg_id" {
  description = "Security Group ID for EFS mount targets"
  value       = aws_security_group.efs_sg.id
}

output "rds_proxy_sg_id" {
  description = "Security Group ID for RDS Proxy"
  value       = aws_security_group.rds_proxy_sg.id
}

output "rds_sg_id" {
  description = "Security Group ID for RDS PostgreSQL"
  value       = aws_security_group.rds_sg.id
}

output "vpc2_endpoint_sg_id" {
  description = "Security Group ID for VPC-2 Interface Endpoints (defined in vpc2.tf)"
  value       = aws_security_group.vpc2_endpoint_sg.id
}
