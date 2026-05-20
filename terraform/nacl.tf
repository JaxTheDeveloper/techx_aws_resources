###############################################################################
# VPC1 - Private Application Subnets
###############################################################################
resource "aws_network_acl" "vpc1_private_app" {
  vpc_id = aws_vpc.vpc1.id
  subnet_ids = [
    aws_subnet.vpc1_az1_private_app.id,
    # aws_subnet.vpc1_az2_private_app.id,
  ]

  # Inbound Rules
  # Allow HTTPS from VPC1 AZ1 private-app subnet
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "10.1.0.0/18"
    from_port  = 443
    to_port    = 443
  }

  # Allow HTTPS from VPC1 AZ2 private-app subnet
  ingress {
    rule_no    = 101
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "10.1.64.0/18"
    from_port  = 443
    to_port    = 443
  }

  # Allow ephemeral return traffic from VPC2 (database responses via TGW)
  ingress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc2_cidr
    from_port  = 1024
    to_port    = 65535
  }

  # Allow ephemeral return traffic from internet (via NAT/firewall)
  ingress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound Rules
  # Allow HTTPS outbound to internet
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow ephemeral ports outbound (return traffic to clients)
  egress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name        = "${var.project_name}-nacl-vpc1-private-app"
    Environment = var.environment
  }
}

###############################################################################
# VPC1 - Firewall Subnets
###############################################################################
resource "aws_network_acl" "vpc1_firewall" {
  vpc_id = aws_vpc.vpc1.id
  subnet_ids = [
    aws_subnet.vpc1_az1_firewall.id,
    # aws_subnet.vpc1_az2_firewall.id,
  ]

  # Inbound Rules
  # Allow HTTPS from VPC1 AZ1 private-app subnet
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "10.1.0.0/18"
    from_port  = 443
    to_port    = 443
  }

  # Allow HTTPS from VPC1 AZ2 private-app subnet
  ingress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "10.1.64.0/18"
    from_port  = 443
    to_port    = 443
  }

  # Allow HTTP from VPC1 AZ1 private-app subnet
  ingress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "10.1.0.0/18"
    from_port  = 80
    to_port    = 80
  }

  # Allow HTTP from VPC1 AZ2 private-app subnet
  ingress {
    rule_no    = 130
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "10.1.64.0/18"
    from_port  = 80
    to_port    = 80
  }

  # Allow ephemeral return traffic from public/NAT AZ1 subnet (10.1.128.0/24)
  ingress {
    rule_no    = 140
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "10.1.128.0/24"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow ephemeral return traffic from public/NAT AZ2 subnet (10.1.129.0/24)
  ingress {
    rule_no    = 150
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "10.1.129.0/24"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound Rules
  # Allow HTTPS to public/NAT AZ1 subnet (10.1.128.0/24)
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "10.1.128.0/24"
    from_port  = 443
    to_port    = 443
  }

  # Allow HTTPS to public/NAT AZ2 subnet (10.1.129.0/24)
  egress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "10.1.129.0/24"
    from_port  = 443
    to_port    = 443
  }

  # Allow HTTP to public/NAT AZ1 subnet (10.1.128.0/24)
  egress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "10.1.128.0/24"
    from_port  = 80
    to_port    = 80
  }

  # Allow HTTP to public/NAT AZ2 subnet (10.1.129.0/24)
  egress {
    rule_no    = 130
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "10.1.129.0/24"
    from_port  = 80
    to_port    = 80
  }

  # Allow ephemeral return traffic to VPC1 AZ1 private-app subnet
  egress {
    rule_no    = 140
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "10.1.0.0/18"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow ephemeral return traffic to VPC1 AZ2 private-app subnet
  egress {
    rule_no    = 150
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "10.1.64.0/18"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name        = "${var.project_name}-nacl-vpc1-firewall"
    Environment = var.environment
  }
}

###############################################################################
# VPC2 - Isolated Database Subnets
###############################################################################
resource "aws_network_acl" "vpc2_isolated" {
  vpc_id = aws_vpc.vpc2.id
  subnet_ids = [
    aws_subnet.vpc2_az1_isolated.id,
    # aws_subnet.vpc2_az2_isolated.id,
  ]

  # Inbound Rules
  # Allow all TCP from VPC1 (app subnets via TGW)
  ingress {
    rule_no    = 50
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc1_cidr
    from_port  = 0
    to_port    = 65535
  }

  # Explicit deny all remaining traffic
  ingress {
    rule_no    = 100
    action     = "deny"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Outbound Rules
  # Allow all TCP back to VPC1 (return traffic)
  egress {
    rule_no    = 50
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc1_cidr
    from_port  = 0
    to_port    = 65535
  }

  # Explicit deny all remaining traffic
  egress {
    rule_no    = 100
    action     = "deny"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name        = "${var.project_name}-nacl-vpc2-isolated"
    Environment = var.environment
  }
}
