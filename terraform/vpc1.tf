###############################################################################
# vpc1.tf — VPC-1 Application Layer
# FIXED: private app subnets now route 0.0.0.0/0 → firewall endpoint (not NAT)
# Firewall endpoint routes are added in firewall.tf after firewall is created
###############################################################################

# VPC
resource "aws_vpc" "vpc1" {
  cidr_block           = var.vpc1_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc1"
    Environment = var.environment
  }
}

# INTERNET GATEWAY
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

# AZ-1
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

# AZ-2
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
# ROUTE TABLES
###############################################################################

# Public subnet: 0.0.0.0/0 → IGW (unchanged)
resource "aws_route_table" "vpc1_public" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc1_igw.id
  }

  route {
    cidr_block         = var.vpc2_cidr
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }

  tags = {
    Name        = "${var.project_name}-vpc1-rtb-public"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "vpc1_az1_public" {
  subnet_id      = aws_subnet.vpc1_az1_public.id
  route_table_id = aws_route_table.vpc1_public.id
}

resource "aws_route_table_association" "vpc1_az2_public" {
  subnet_id      = aws_subnet.vpc1_az2_public.id
  route_table_id = aws_route_table.vpc1_public.id
}

# FIXED: Private app AZ-1 — NO direct NAT route here
# 0.0.0.0/0 → firewall endpoint is added in firewall.tf
resource "aws_route_table" "vpc1_private_app_az1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block         = var.vpc2_cidr
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }

  tags = {
    Name        = "${var.project_name}-vpc1-rtb-private-app-az1"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "vpc1_az1_private_app" {
  subnet_id      = aws_subnet.vpc1_az1_private_app.id
  route_table_id = aws_route_table.vpc1_private_app_az1.id
}

# FIXED: Private app AZ-2 — NO direct NAT route here
resource "aws_route_table" "vpc1_private_app_az2" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block         = var.vpc2_cidr
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }

  tags = {
    Name        = "${var.project_name}-vpc1-rtb-private-app-az2"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "vpc1_az2_private_app" {
  subnet_id      = aws_subnet.vpc1_az2_private_app.id
  route_table_id = aws_route_table.vpc1_private_app_az2.id
}

# Firewall subnet AZ-1: 0.0.0.0/0 → NAT (correct — firewall sends traffic here)
resource "aws_route_table" "vpc1_firewall_az1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vpc1_az1.id
  }

  tags = {
    Name        = "${var.project_name}-vpc1-rtb-firewall-az1"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "vpc1_az1_firewall" {
  subnet_id      = aws_subnet.vpc1_az1_firewall.id
  route_table_id = aws_route_table.vpc1_firewall_az1.id
}

# Firewall subnet AZ-2: 0.0.0.0/0 → NAT
resource "aws_route_table" "vpc1_firewall_az2" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vpc1_az2.id
  }

  tags = {
    Name        = "${var.project_name}-vpc1-rtb-firewall-az2"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "vpc1_az2_firewall" {
  subnet_id      = aws_subnet.vpc1_az2_firewall.id
  route_table_id = aws_route_table.vpc1_firewall_az2.id
}

###############################################################################
# VPC ENDPOINTS
###############################################################################

resource "aws_vpc_endpoint" "vpc1_s3" {
  vpc_id            = aws_vpc.vpc1.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.vpc1_private_app_az1.id,
    aws_route_table.vpc1_private_app_az2.id,
  ]
  tags = {
    Name        = "${var.project_name}-vpc1-endpoint-s3"
    Environment = var.environment
  }
}

###############################################################################
# DEFAULT SECURITY GROUP — deny all
###############################################################################

resource "aws_default_security_group" "vpc1_default" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    Name        = "${var.project_name}-vpc1-default-sg-deny-all"
    Environment = var.environment
  }
}
