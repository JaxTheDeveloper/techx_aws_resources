resource "aws_security_group" "lambda_sg" {
  name        = "${var.project_name}-lambda-sg"
  description = "Security group for Backend Lambda functions"
  vpc_id      = aws_vpc.vpc.id

  # Lambda initiates all connections — no inbound needed
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS to VPC endpoints and AWS services"
  }

  tags = { Name = "${var.project_name}-lambda-sg" }
}

resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "${var.project_name}-vpc-endpoint-sg"
  description = "Security group for Interface VPC Endpoints"
  vpc_id      = aws_vpc.vpc.id

  # Only Lambda SG can hit the endpoints — SG-to-SG, no CIDR
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
    description     = "HTTPS from Lambda SG only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Return traffic to Lambda"
  }

  tags = { Name = "${var.project_name}-vpc-endpoint-sg" }
}
