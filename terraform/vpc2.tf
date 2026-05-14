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

resource "aws_subnet" "vpc2_az2_isolated" {
  vpc_id            = aws_vpc.vpc2.id
  cidr_block        = var.vpc2_az2_isolated_cidr
  availability_zone = local.az_2

  tags = {
    Name        = "${var.project_name}-vpc2-az2-isolated"
    Environment = var.environment
    Tier        = "Isolated-Private"
  }
}

###############################################################################
# VPC ENDPOINT (Interface - for CloudWatch Logs / Secrets Manager etc.)
###############################################################################

resource "aws_security_group" "vpc2_endpoint_sg" {
  name        = "${var.project_name}-vpc2-endpoint-sg"
  description = "Allow HTTPS from isolated subnets to VPC Interface Endpoints"
  vpc_id      = aws_vpc.vpc2.id

  ingress {
    description = "HTTPS from VPC-2 isolated subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc2_cidr]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc2_cidr]
  }

  tags = {
    Name        = "${var.project_name}-vpc2-endpoint-sg"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "vpc2_logs" {
  vpc_id              = aws_vpc.vpc2.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [
    aws_subnet.vpc2_az1_isolated.id,
    aws_subnet.vpc2_az2_isolated.id,
  ]
  security_group_ids  = [aws_security_group.vpc2_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-vpc2-endpoint-logs"
    Environment = var.environment
  }
}

# Secrets Manager — required by RDS Proxy to retrieve DB credentials
resource "aws_vpc_endpoint" "vpc2_secretsmanager" {
  vpc_id              = aws_vpc.vpc2.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [
    aws_subnet.vpc2_az1_isolated.id,
    aws_subnet.vpc2_az2_isolated.id,
  ]
  security_group_ids  = [aws_security_group.vpc2_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-vpc2-endpoint-secretsmanager"
    Environment = var.environment
  }
}

###############################################################################
# DEFAULT SECURITY GROUP - deny all
###############################################################################

resource "aws_default_security_group" "vpc2_default" {
  vpc_id = aws_vpc.vpc2.id

  tags = {
    Name        = "${var.project_name}-vpc2-default-sg-deny-all"
    Environment = var.environment
  }
}
