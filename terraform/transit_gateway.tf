###############################################################################
# transit_gateway.tf — Transit Gateway connecting VPC-1 and VPC-2
###############################################################################

###############################################################################
# TRANSIT GATEWAY
###############################################################################

resource "aws_ec2_transit_gateway" "tgw" {
  description                     = "Transit Gateway connecting VPC-1 (App) and VPC-2 (DB)"
  amazon_side_asn                 = 64512
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = {
    Name        = "${var.project_name}-tgw"
    Environment = var.environment
  }
}

###############################################################################
# TGW ATTACHMENTS
###############################################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc1" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpc1.id
  subnet_ids = [
    aws_subnet.vpc1_az1_private_app.id,
    aws_subnet.vpc1_az2_private_app.id,
  ]

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name        = "${var.project_name}-tgw-attach-vpc1"
    Environment = var.environment
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc2" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpc2.id
  subnet_ids = [
    aws_subnet.vpc2_az1_isolated.id,
    aws_subnet.vpc2_az2_isolated.id,
  ]

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name        = "${var.project_name}-tgw-attach-vpc2"
    Environment = var.environment
  }
}

###############################################################################
# TGW ROUTE TABLE
###############################################################################

resource "aws_ec2_transit_gateway_route_table" "main" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  tags = {
    Name        = "${var.project_name}-tgw-rtb"
    Environment = var.environment
  }
}

# Associate both attachments to the same route table
resource "aws_ec2_transit_gateway_route_table_association" "vpc1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route_table_association" "vpc2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

# Propagate VPC CIDRs into TGW route table
resource "aws_ec2_transit_gateway_route_table_propagation" "vpc1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpc2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}
