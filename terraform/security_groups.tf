###############################################################################
# VPC-1 — LAMBDA SECURITY GROUP
# No inbound (triggered by API Gateway/EventBridge)
# Outbound: EFS (2049), RDS Proxy in VPC2 (5432), AWS services (443)
###############################################################################

resource "aws_security_group" "lambda_sg" {
  name        = "${var.project_name}-lambda-sg"
  description = "Lambda functions - no inbound, controlled outbound only"
  vpc_id      = aws_vpc.vpc1.id

  # Inbound: allow HTTPS from self (Lambda-to-Lambda within same SG)
  ingress {
    description = "Allow HTTPS from Lambda functions (self)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
  }

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
# Mount target for EFS. Only accepts NFS (2049) from Lambda SG
# No outbound needed — EFS responds on same connection
###############################################################################

resource "aws_security_group" "efs_sg" {
  name        = "${var.project_name}-efs-sg"
  description = "EFS mount target - NFS inbound from private app subnets only"
  vpc_id      = aws_vpc.vpc1.id

  # Inbound: NFS from AZ-1 private app subnet
  ingress {
    description = "NFS from AZ-1 private app subnet"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_az1_private_app_cidr]
  }

  # Inbound: NFS from AZ-2 private app subnet
  ingress {
    description = "NFS from AZ-2 private app subnet"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_az2_private_app_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-efs-sg"
    Environment = var.environment
    Purpose     = "EFS mount target security group"
  }
}

###############################################################################
# VPC-2 — VPC ENDPOINT SECURITY GROUP
# Accepts HTTPS from RDS Proxy (Secrets Manager lookups)
###############################################################################

resource "aws_security_group" "vpc2_endpoint_sg" {
  name        = "${var.project_name}-vpc2-endpoint-sg"
  description = "VPC-2 interface endpoint - HTTPS from RDS Proxy only"
  vpc_id      = aws_vpc.vpc2.id

  ingress {
    description     = "HTTPS from RDS Proxy"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_proxy_sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-vpc2-endpoint-sg"
    Environment = var.environment
    Purpose     = "VPC-2 interface endpoint security group"
  }
}

###############################################################################
# VPC-2 — RDS PROXY SECURITY GROUP
# Accepts connections from Lambda (VPC-1) only via peering
# Connects out to RDS PostgreSQL inside VPC-2
###############################################################################

resource "aws_security_group" "rds_proxy_sg" {
  name        = "${var.project_name}-rds-proxy-sg"
  description = "RDS Proxy - accept from Lambda VPC only, connect to RDS"
  vpc_id      = aws_vpc.vpc2.id

  # Inbound: PostgreSQL from VPC-1 (Lambda via peering)
  ingress {
    description = "PostgreSQL from Lambda in VPC-1"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }

  # Outbound: HTTPS to Secrets Manager via VPC-2 interface endpoint
  egress {
    description     = "HTTPS to Secrets Manager VPC endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc2_endpoint_sg.id]
  }

  # Outbound: PostgreSQL to RDS SG
  egress {
    description     = "PostgreSQL to RDS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_sg.id]
  }

  # Outbound: PostgreSQL to RDS subnet CIDR
  egress {
    description = "PostgreSQL to VPC-2 subnet"
    from_port   = 5432
    to_port     = 5432
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
# Only accepts from RDS Proxy. No outbound — DB never initiates connections
###############################################################################

resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "RDS PostgreSQL - accept from RDS Proxy only"
  vpc_id      = aws_vpc.vpc2.id

  # Inbound: PostgreSQL from RDS Proxy SG
  ingress {
    description     = "PostgreSQL from RDS Proxy"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_proxy_sg.id]
  }

  # Inbound: PostgreSQL from VPC-1 Lambda (direct, via peering)
  ingress {
    description = "PostgreSQL from Lambda functions in VPC-1"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
    Purpose     = "RDS PostgreSQL security group"
  }
}


###############################################################################
# VPC-1 — VPC ENDPOINT SECURITY GROUP
# Protects VPC Interface Endpoints (SQS, SNS). Only Lambda can send HTTPS
###############################################################################

resource "aws_security_group" "vpc1_endpoint_sg" {
  name        = "${var.project_name}-vpc1-endpoint-sg"
  description = "Allow inbound HTTPS from VPC1 Lambda to SQS/SNS endpoints"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    description     = "HTTPS from Lambda SG"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-vpc1-endpoint-sg"
    Environment = var.environment
    Purpose     = "VPC-1 interface endpoint security group"
  }
}


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

output "vpc1_endpoint_sg_id" {
  description = "Security Group ID for VPC-1 Interface Endpoints"
  value       = aws_security_group.vpc1_endpoint_sg.id
}

output "vpc2_endpoint_sg_id" {
  description = "Security Group ID for VPC-2 Interface Endpoints"
  value       = aws_security_group.vpc2_endpoint_sg.id
}
