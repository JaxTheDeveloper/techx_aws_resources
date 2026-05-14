###############################################################################
# nacl.tf — W5 MH2: Network ACLs
# VPC1 private app subnets + VPC2 isolated subnets
###############################################################################

###############################################################################
# VPC1 — Private Application Subnets NACL
###############################################################################

resource "aws_network_acl" "vpc1_private_app" {
  vpc_id = aws_vpc.vpc1.id
  subnet_ids = [
    aws_subnet.vpc1_az1_private_app.id,
    aws_subnet.vpc1_az2_private_app.id,
  ]

  # ── DENY rules (evaluated first — low rule numbers) ──────────────────────

  # Rule 50: DENY from blocked test CIDR (for negative test evidence pack)
  ingress {
    rule_no    = 50
    action     = "deny"
    protocol   = "-1"
    cidr_block = "192.168.99.0/24"
    from_port  = 0
    to_port    = 0
  }

  # Rule 60: DENY inbound SSH from internet
  ingress {
    rule_no    = 60
    action     = "deny"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # Rule 70: DENY inbound RDP from internet
  ingress {
    rule_no    = 70
    action     = "deny"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port  = 3389
    to_port    = 3389
  }

  # ── ALLOW rules ──────────────────────────────────────────────────────────

  # Rule 100: Allow HTTPS from within VPC1
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc1_cidr
    from_port  = 443
    to_port    = 443
  }

  # Rule 110: Allow return traffic from VPC2 (database responses via TGW)
  ingress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc2_cidr
    from_port  = 1024
    to_port    = 65535
  }

  # Rule 120: Allow ephemeral ports (return traffic from internet via NAT/firewall)
  ingress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound: allow all (firewall handles egress filtering)
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name        = "${var.project_name}-nacl-vpc1-private-app"
    Environment = var.environment
  }
}

###############################################################################
# VPC2 — Isolated Database Subnets NACL
###############################################################################

resource "aws_network_acl" "vpc2_isolated" {
  vpc_id = aws_vpc.vpc2.id
  subnet_ids = [
    aws_subnet.vpc2_az1_isolated.id,
    aws_subnet.vpc2_az2_isolated.id,
  ]

  # Rule 50: DENY all internet traffic (database layer must never be public)
  ingress {
    rule_no    = 50
    action     = "deny"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Rule 100: Allow inbound from VPC1 app subnets only (via Transit Gateway)
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc1_cidr
    from_port  = 0
    to_port    = 65535
  }

  # Outbound: allow responses back to VPC1 only
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc1_cidr
    from_port  = 0
    to_port    = 65535
  }

  tags = {
    Name        = "${var.project_name}-nacl-vpc2-isolated"
    Environment = var.environment
  }
}
