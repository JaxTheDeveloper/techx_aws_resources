resource "aws_security_group" "lambda_sg" {
  name        = "lambda-backend-sg"
  description = "Security group for Backend Lambda function"
  vpc_id      = aws_vpc.vpc.id

  # To Bedrock Endpoint and DynamoDB
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lambda-backend-sg"
  }
}

resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "vpc-endpoint-sg"
  description = "Security group for Interface VPC Endpoints"
  vpc_id      = aws_vpc.vpc.id

  # Only allow lambda funcs in lambda_sg group
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  # Response to Lambda
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-endpoint-sg"
  }
}


