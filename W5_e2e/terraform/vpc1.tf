resource "aws_vpc" "vpc1" {
  cidr_block           = var.vpc1_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc1"
    Environment = var.environment
  }
}

###############################################################################
# INTERNET GATEWAY
###############################################################################

resource "aws_internet_gateway" "vpc1_igw" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name        = "${var.project_name}-vpc1-igw"
    Environment = var.environment
  }
}

###############################################################################
# SUBNETS
###############################################################################

resource "aws_subnet" "vpc1_az1_public" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = var.vpc1_az1_public_cidr
  availability_zone       = local.az_1
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.project_name}-vpc1-az1-public"
    Environment = var.environment
    Tier        = "Public"
  }
}

resource "aws_subnet" "vpc1_az1_private_app" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = var.vpc1_az1_private_app_cidr
  availability_zone = local.az_1
  tags = {
    Name        = "${var.project_name}-vpc1-az1-private-app"
    Environment = var.environment
    Tier        = "Private-Application"
  }
}

resource "aws_subnet" "vpc1_az1_firewall" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = var.vpc1_az1_firewall_cidr
  availability_zone = local.az_1
  tags = {
    Name        = "${var.project_name}-vpc1-az1-firewall"
    Environment = var.environment
    Tier        = "Firewall"
  }
}

resource "aws_subnet" "vpc1_az2_public" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = var.vpc1_az2_public_cidr
  availability_zone       = local.az_2
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.project_name}-vpc1-az2-public"
    Environment = var.environment
    Tier        = "Public"
  }
}

resource "aws_subnet" "vpc1_az2_private_app" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = var.vpc1_az2_private_app_cidr
  availability_zone = local.az_2
  tags = {
    Name        = "${var.project_name}-vpc1-az2-private-app"
    Environment = var.environment
    Tier        = "Private-Application"
  }
}

resource "aws_subnet" "vpc1_az2_firewall" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = var.vpc1_az2_firewall_cidr
  availability_zone = local.az_2
  tags = {
    Name        = "${var.project_name}-vpc1-az2-firewall"
    Environment = var.environment
    Tier        = "Firewall"
  }
}

###############################################################################
# NAT GATEWAYS (one per AZ)
###############################################################################

resource "aws_eip" "nat_az1" {
  domain = "vpc"
  tags = {
    Name        = "${var.project_name}-vpc1-nat-eip-az1"
    Environment = var.environment
  }
}

resource "aws_eip" "nat_az2" {
  domain = "vpc"
  tags = {
    Name        = "${var.project_name}-vpc1-nat-eip-az2"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "vpc1_az1" {
  allocation_id = aws_eip.nat_az1.id
  subnet_id     = aws_subnet.vpc1_az1_public.id
  depends_on    = [aws_internet_gateway.vpc1_igw]
  tags = {
    Name        = "${var.project_name}-vpc1-natgw-az1"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "vpc1_az2" {
  allocation_id = aws_eip.nat_az2.id
  subnet_id     = aws_subnet.vpc1_az2_public.id
  depends_on    = [aws_internet_gateway.vpc1_igw]
  tags = {
    Name        = "${var.project_name}-vpc1-natgw-az2"
    Environment = var.environment
  }
}

###############################################################################
# VPC ENDPOINTS
###############################################################################

# Security group for all VPC Interface Endpoints in VPC1
resource "aws_security_group" "vpc1_endpoint_sg" {
  name        = "${var.project_name}-vpc1-endpoint-sg"
  description = "Allow HTTPS from private app subnets to Interface Endpoints"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    description = "HTTPS from private app subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      var.vpc1_az1_private_app_cidr,
      var.vpc1_az2_private_app_cidr,
    ]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }

  tags = {
    Name        = "${var.project_name}-vpc1-endpoint-sg"
    Environment = var.environment
  }
}

# CloudWatch Logs — for VPC Flow Logs
resource "aws_vpc_endpoint" "vpc1_logs" {
  vpc_id              = aws_vpc.vpc1.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [
    aws_subnet.vpc1_az1_private_app.id,
    aws_subnet.vpc1_az2_private_app.id,
  ]
  security_group_ids  = [aws_security_group.vpc1_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-vpc1-endpoint-logs"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "vpc1_events" {
  vpc_id              = aws_vpc.vpc1.id
  service_name        = "com.amazonaws.${var.aws_region}.events"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [
    aws_subnet.vpc1_az1_private_app.id,
    aws_subnet.vpc1_az2_private_app.id,
  ]
  security_group_ids  = [aws_security_group.vpc1_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-vpc1-endpoint-events"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "vpc1_sqs" {
  vpc_id              = aws_vpc.vpc1.id
  service_name        = "com.amazonaws.${var.aws_region}.sqs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [
    aws_subnet.vpc1_az1_private_app.id,
    aws_subnet.vpc1_az2_private_app.id,
  ]
  security_group_ids  = [aws_security_group.vpc1_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-vpc1-endpoint-sqs"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "vpc1_sns" {
  vpc_id              = aws_vpc.vpc1.id
  service_name        = "com.amazonaws.${var.aws_region}.sns"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [
    aws_subnet.vpc1_az1_private_app.id,
    aws_subnet.vpc1_az2_private_app.id,
  ]
  security_group_ids  = [aws_security_group.vpc1_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-vpc1-endpoint-sns"
    Environment = var.environment
  }
}


###############################################################################
# DEFAULT SECURITY GROUP - deny all
###############################################################################

resource "aws_default_security_group" "vpc1_default" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    Name        = "${var.project_name}-vpc1-default-sg-deny-all"
    Environment = var.environment
  }
}
