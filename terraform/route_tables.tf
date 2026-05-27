resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "az1" {
  subnet_id      = aws_subnet.vpc_az1_private_app.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "az2" {
  subnet_id      = aws_subnet.vpc_az2_private_app.id
  route_table_id = aws_route_table.private.id
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "dynamodb-gateway-endpoint"
  }
}

