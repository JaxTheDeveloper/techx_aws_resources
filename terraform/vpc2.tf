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

