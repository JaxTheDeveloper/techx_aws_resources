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

# resource "aws_subnet" "vpc1_az2_public" {
#   vpc_id                  = aws_vpc.vpc1.id
#   cidr_block              = var.vpc1_az2_public_cidr
#   availability_zone       = local.az_2
#   map_public_ip_on_launch = true
#   tags = {
#     Name        = "${var.project_name}-vpc1-az2-public"
#     Environment = var.environment
#     Tier        = "Public"
#   }
# }

# resource "aws_subnet" "vpc1_az2_private_app" {
#   vpc_id            = aws_vpc.vpc1.id
#   cidr_block        = var.vpc1_az2_private_app_cidr
#   availability_zone = local.az_2
#   tags = {
#     Name        = "${var.project_name}-vpc1-az2-private-app"
#     Environment = var.environment
#     Tier        = "Private-Application"
#   }
# }

# resource "aws_subnet" "vpc1_az2_firewall" {
#   vpc_id            = aws_vpc.vpc1.id
#   cidr_block        = var.vpc1_az2_firewall_cidr
#   availability_zone = local.az_2
#   tags = {
#     Name        = "${var.project_name}-vpc1-az2-firewall"
#     Environment = var.environment
#     Tier        = "Firewall"
#   }
# }

###############################################################################
# NAT GATEWAYS
###############################################################################

resource "aws_eip" "vpc1_az1_nat" {
  domain = "vpc"
  tags = {
    Name        = "${var.project_name}-vpc1-az1-nat-eip"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "vpc1_az1" {
  allocation_id = aws_eip.vpc1_az1_nat.id
  subnet_id     = aws_subnet.vpc1_az1_public.id
  tags = {
    Name        = "${var.project_name}-vpc1-az1-nat"
    Environment = var.environment
  }
}

# resource "aws_eip" "vpc1_az2_nat" {
#   domain = "vpc"
#   tags = {
#     Name        = "${var.project_name}-vpc1-az2-nat-eip"
#     Environment = var.environment
#   }
# }

# resource "aws_nat_gateway" "vpc1_az2" {
#   allocation_id = aws_eip.vpc1_az2_nat.id
#   subnet_id     = aws_subnet.vpc1_az2_public.id
#   tags = {
#     Name        = "${var.project_name}-vpc1-az2-nat"
#     Environment = var.environment
#   }
# }


