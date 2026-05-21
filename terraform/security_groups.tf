###############################################################################
# VPC-1 — LAMBDA SECURITY GROUP
###############################################################################
resource "aws_security_group" "lambda_sg" {
  name        = "${var.project_name}-lambda-sg"
  description = "Lambda functions - no inbound, controlled outbound only"
  vpc_id      = aws_vpc.vpc1.id

  tags = {
    Name        = "${var.project_name}-lambda-sg"
    Environment = var.environment
    Purpose     = "Lambda functions security group"
  }
}

resource "aws_security_group_rule" "lambda_ingress_self" {
  type              = "ingress"
  description       = "Allow HTTPS from Lambda functions (self)"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.lambda_sg.id
}

resource "aws_security_group_rule" "lambda_egress_efs" {
  type              = "egress"
  description       = "NFS to EFS mount target"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = [var.vpc1_cidr]
  security_group_id = aws_security_group.lambda_sg.id
}

resource "aws_security_group_rule" "lambda_egress_rds" {
  type              = "egress"
  description       = "PostgreSQL to RDS Proxy in VPC-2"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [var.vpc2_cidr]
  security_group_id = aws_security_group.lambda_sg.id
}

resource "aws_security_group_rule" "lambda_egress_https" {
  type              = "egress"
  description       = "HTTPS to AWS managed services and VPC endpoints"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda_sg.id
}

###############################################################################
# VPC-1 — EFS SECURITY GROUP
###############################################################################
resource "aws_security_group" "efs_sg" {
  name        = "${var.project_name}-efs-sg"
  description = "EFS mount target - NFS inbound from private app subnets only"
  vpc_id      = aws_vpc.vpc1.id

  tags = {
    Name        = "${var.project_name}-efs-sg"
    Environment = var.environment
    Purpose     = "EFS mount target security group"
  }
}

resource "aws_security_group_rule" "efs_ingress_az1" {
  type              = "ingress"
  description       = "NFS from AZ-1 private app subnet"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = [var.vpc1_az1_private_app_cidr]
  security_group_id = aws_security_group.efs_sg.id
}

resource "aws_security_group_rule" "efs_ingress_az2" {
  type              = "ingress"
  description       = "NFS from AZ-2 private app subnet"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = [var.vpc1_az2_private_app_cidr]
  security_group_id = aws_security_group.efs_sg.id
}

resource "aws_security_group_rule" "efs_egress_all" {
  type              = "egress"
  description       = "Allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.efs_sg.id
}

###############################################################################
# VPC-2 — RDS PROXY SECURITY GROUP
###############################################################################
resource "aws_security_group" "rds_proxy_sg" {
  name        = "${var.project_name}-rds-proxy-sg"
  description = "RDS Proxy - accept from Lambda VPC only, connect to RDS"
  vpc_id      = aws_vpc.vpc2.id

  tags = {
    Name        = "${var.project_name}-rds-proxy-sg"
    Environment = var.environment
    Purpose     = "RDS Proxy security group"
  }
}

resource "aws_security_group_rule" "rds_proxy_ingress_lambda" {
  type              = "ingress"
  description       = "PostgreSQL from Lambda in VPC-1"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [var.vpc1_cidr]
  security_group_id = aws_security_group.rds_proxy_sg.id
}

resource "aws_security_group_rule" "rds_proxy_egress_secrets" {
  type                     = "egress"
  description              = "HTTPS to Secrets Manager VPC endpoint"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpc2_endpoint_sg.id
  security_group_id        = aws_security_group.rds_proxy_sg.id
}

resource "aws_security_group_rule" "rds_proxy_egress_rds_sg" {
  type                     = "egress"
  description              = "PostgreSQL to RDS"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds_sg.id
  security_group_id        = aws_security_group.rds_proxy_sg.id
}

resource "aws_security_group_rule" "rds_proxy_egress_rds_cidr" {
  type              = "egress"
  description       = "PostgreSQL to VPC-2 subnet"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [var.vpc2_cidr]
  security_group_id = aws_security_group.rds_proxy_sg.id
}

###############################################################################
# VPC-2 — RDS POSTGRESQL SECURITY GROUP
###############################################################################
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "RDS PostgreSQL - accept from RDS Proxy only"
  vpc_id      = aws_vpc.vpc2.id

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
    Purpose     = "RDS PostgreSQL security group"
  }
}

resource "aws_security_group_rule" "rds_ingress_proxy" {
  type                     = "ingress"
  description              = "PostgreSQL from RDS Proxy"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds_proxy_sg.id
  security_group_id        = aws_security_group.rds_sg.id
}

resource "aws_security_group_rule" "rds_ingress_lambda" {
  type              = "ingress"
  description       = "PostgreSQL from Lambda functions in VPC-1"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [var.vpc1_cidr]
  security_group_id = aws_security_group.rds_sg.id
}

resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  description       = "Allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds_sg.id
}

###############################################################################
# VPC-2 — VPC ENDPOINT SECURITY GROUP
###############################################################################
resource "aws_security_group" "vpc2_endpoint_sg" {
  name        = "${var.project_name}-vpc2-endpoint-sg"
  description = "VPC-2 interface endpoint - HTTPS from RDS Proxy only"
  vpc_id      = aws_vpc.vpc2.id

  tags = {
    Name        = "${var.project_name}-vpc2-endpoint-sg"
    Environment = var.environment
    Purpose     = "VPC-2 interface endpoint security group"
  }
}

resource "aws_security_group_rule" "vpc2_endpoint_ingress_proxy" {
  type                     = "ingress"
  description              = "HTTPS from RDS Proxy"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds_proxy_sg.id
  security_group_id        = aws_security_group.vpc2_endpoint_sg.id
}

resource "aws_security_group_rule" "vpc2_endpoint_egress_all" {
  type              = "egress"
  description       = "Allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vpc2_endpoint_sg.id
}

###############################################################################
# VPC-1 — VPC ENDPOINT SECURITY GROUP
###############################################################################
resource "aws_security_group" "vpc1_endpoint_sg" {
  name        = "${var.project_name}-vpc1-endpoint-sg"
  description = "Allow inbound HTTPS from VPC1 Lambda to SQS/SNS endpoints"
  vpc_id      = aws_vpc.vpc1.id

  tags = {
    Name        = "${var.project_name}-vpc1-endpoint-sg"
    Environment = var.environment
    Purpose     = "VPC-1 interface endpoint security group"
  }
}

resource "aws_security_group_rule" "vpc1_endpoint_ingress_lambda" {
  type                     = "ingress"
  description              = "HTTPS from Lambda SG"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_sg.id
  security_group_id        = aws_security_group.vpc1_endpoint_sg.id
}

resource "aws_security_group_rule" "vpc1_endpoint_egress_all" {
  type              = "egress"
  description       = "Allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vpc1_endpoint_sg.id
}

###############################################################################
# OUTPUTS
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
