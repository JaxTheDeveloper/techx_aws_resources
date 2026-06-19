resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.vpc.id
  subnet_ids = [
    aws_subnet.vpc_az1_private_app.id,
    aws_subnet.vpc_az2_private_app.id
  ]

  # ── INGRESS ──────────────────────────────────────────────────────────────────

  # Allow HTTPS from within VPC (Lambda → VPC endpoint ingress)
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = aws_vpc.vpc.cidr_block
    from_port  = 443
    to_port    = 443
  }

  # Allow ephemeral return ports from AWS services responses
  ingress {
    rule_no    = 200
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # ── EGRESS ───────────────────────────────────────────────────────────────────

  # Allow Lambda to call AWS services on 443
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow ephemeral return traffic back to Lambda within VPC
  egress {
    rule_no    = 200
    protocol   = "tcp"
    action     = "allow"
    cidr_block = aws_vpc.vpc.cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  tags = { Name = "${var.project_name}-private-nacl" }
}
