resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true # must have for Interface VPC Endpoint
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "vpc_az1_private_app" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.vpc_az1_private_app_cidr
  availability_zone = local.az_1

  tags = {
    Name        = "${var.project_name}-vpc-az1-private-app"
    Environment = var.environment
    Tier        = "Private-Application"
  }
}

resource "aws_subnet" "vpc_az2_private_app" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.vpc_az2_private_app_cidr
  availability_zone = local.az_2

  tags = {
    Name        = "${var.project_name}-vpc-az2-private-app"
    Environment = var.environment
    Tier        = "Private-Application"
  }
}


