resource "aws_vpc" "vpc2" {
  cidr_block           = var.vpc2_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc2"
    Environment = var.environment
  }
}

###############################################################################
# SUBNETS - Isolated Private (no internet access)
###############################################################################

resource "aws_subnet" "vpc2_az1_isolated" {
  vpc_id            = aws_vpc.vpc2.id
  cidr_block        = var.vpc2_az1_isolated_cidr
  availability_zone = local.az_1

  tags = {
    Name        = "${var.project_name}-vpc2-az1-isolated"
    Environment = var.environment
    Tier        = "Isolated-Private"
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

# resource "aws_subnet" "vpc2_az2_isolated" {
#   vpc_id            = aws_vpc.vpc2.id
#   cidr_block        = var.vpc2_az2_isolated_cidr
#   availability_zone = local.az_2
#
#   tags = {
#     Name        = "${var.project_name}-vpc2-az2-isolated"
#     Environment = var.environment
#     Tier        = "Isolated-Private"
#   }
# }

