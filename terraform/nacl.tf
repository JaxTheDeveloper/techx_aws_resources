resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.vpc.id
  subnet_ids = [
    aws_subnet.vpc_az1_private_app.id,
    aws_subnet.vpc_az2_private_app.id
  ]

  # From internal VPC network
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.vpc.cidr_block
    from_port  = 443
    to_port    = 443
  }

  # Receive responses from other AWS services
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    # Ephemeral ports
    from_port = 1024
    to_port   = 65535
  }

  # Call HTTPS (port 443) to reach Bedrock/DynamoDB
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = aws_vpc.vpc.cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "private-subnet-nacl"
  }
}
