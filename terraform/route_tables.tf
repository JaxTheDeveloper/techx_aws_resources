###############################################################################
# VPC1 
###############################################################################

# Public Route Table (shared by both AZs public subnets)
resource "aws_route_table" "vpc1_public" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc1_igw.id
  }

  route {
    cidr_block         = var.vpc2_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc2.id
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

# resource "aws_route_table_association" "vpc1_az2_public" {
#   subnet_id      = aws_subnet.vpc1_az2_public.id
#   route_table_id = aws_route_table.vpc1_public.id
# }

# Private App Route Table AZ-1
resource "aws_route_table" "vpc1_private_app_az1" {
  vpc_id = aws_vpc.vpc1.id
  
  route {
    cidr_block                = var.vpc2_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc2.id
  }

  # firewall endpoint injected separately via aws_route in network_firewall.tf
  # (vpce- ID is only known after firewall creation)
  tags = {
    Name        = "${var.project_name}-vpc1-rtb-private-app-az1"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "vpc1_az1_private_app" {
  subnet_id      = aws_subnet.vpc1_az1_private_app.id
  route_table_id = aws_route_table.vpc1_private_app_az1.id
} 

# Private App Route Table AZ-2 
# resource "aws_route_table" "vpc1_private_app_az2" {
#   vpc_id = aws_vpc.vpc1.id

#   route {
#     cidr_block                = var.vpc2_cidr
#     vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc2.id
#   }

#   tags = {
#     Name        = "${var.project_name}-vpc1-rtb-private-app-az2"
#     Environment = var.environment
#   }
# }

# resource "aws_route_table_association" "vpc1_az2_private_app" {
#   subnet_id      = aws_subnet.vpc1_az2_private_app.id
#   route_table_id = aws_route_table.vpc1_private_app_az2.id
# }

# Firewall Route Table AZ-1
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

# Firewall Route Table AZ-2
# resource "aws_route_table" "vpc1_firewall_az2" {
#   vpc_id = aws_vpc.vpc1.id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.vpc1_az2.id
#   }

#   tags = {
#     Name        = "${var.project_name}-vpc1-rtb-firewall-az2"
#     Environment = var.environment
#   }
# }

# resource "aws_route_table_association" "vpc1_az2_firewall" {
#   subnet_id      = aws_subnet.vpc1_az2_firewall.id
#   route_table_id = aws_route_table.vpc1_firewall_az2.id
# }

###############################################################################
# VPC2 
###############################################################################

resource "aws_route_table" "vpc2_isolated_az1" {
  vpc_id = aws_vpc.vpc2.id

  route {
    cidr_block                = var.vpc1_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc2.id
  }

  tags = {
    Name        = "${var.project_name}-vpc2-rtb-isolated-az1"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "vpc2_az1_isolated" {
  subnet_id      = aws_subnet.vpc2_az1_isolated.id
  route_table_id = aws_route_table.vpc2_isolated_az1.id
}

# resource "aws_route_table" "vpc2_isolated_az2" {
#   vpc_id = aws_vpc.vpc2.id

#   route {
#     cidr_block                = var.vpc1_cidr
#     vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc2.id
#   }

#   tags = {
#     Name        = "${var.project_name}-vpc2-rtb-isolated-az2"
#     Environment = var.environment
#   }
# }

# resource "aws_route_table_association" "vpc2_az2_isolated" {
#   subnet_id      = aws_subnet.vpc2_az2_isolated.id
#   route_table_id = aws_route_table.vpc2_isolated_az2.id
# }

