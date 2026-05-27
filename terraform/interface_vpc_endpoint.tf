resource "aws_vpc_endpoint" "bedrock_runtime" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.bedrock-runtime"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.vpc_az1_private_app.id,
    aws_subnet.vpc_az2_private_app.id
  ]

  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    Name = "bedrock-runtime-endpoint"
  }
}
