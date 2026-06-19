# ─── VPC ──────────────────────────────────────────────────────────────────────

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true # required for Interface VPC Endpoints
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-vpc" }
}

# ─── Private Subnets (2 AZs) ──────────────────────────────────────────────────

resource "aws_subnet" "vpc_az1_private_app" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.vpc_az1_private_app_cidr
  availability_zone = local.az_1

  tags = {
    Name = "${var.project_name}-az1-private-app"
    Tier = "Private-Application"
  }
}

resource "aws_subnet" "vpc_az2_private_app" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.vpc_az2_private_app_cidr
  availability_zone = local.az_2

  tags = {
    Name = "${var.project_name}-az2-private-app"
    Tier = "Private-Application"
  }
}

# ─── Route Table (private — no IGW, no NAT) ───────────────────────────────────

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "${var.project_name}-private-rt" }
}

resource "aws_route_table_association" "az1" {
  subnet_id      = aws_subnet.vpc_az1_private_app.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "az2" {
  subnet_id      = aws_subnet.vpc_az2_private_app.id
  route_table_id = aws_route_table.private.id
}

# ─── Gateway Endpoints (free) ─────────────────────────────────────────────────

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = { Name = "${var.project_name}-s3-gw-endpoint" }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = { Name = "${var.project_name}-dynamodb-gw-endpoint" }
}

# ─── Interface Endpoints (paid ~$0.013/hr each) ───────────────────────────────

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
  tags               = { Name = "${var.project_name}-bedrock-runtime-endpoint" }
}

resource "aws_vpc_endpoint" "bedrock_agent" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.bedrock-agent-runtime"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    aws_subnet.vpc_az1_private_app.id,
    aws_subnet.vpc_az2_private_app.id
  ]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]
  tags               = { Name = "${var.project_name}-bedrock-agent-endpoint" }
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    aws_subnet.vpc_az1_private_app.id,
    aws_subnet.vpc_az2_private_app.id
  ]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]
  tags               = { Name = "${var.project_name}-cloudwatch-logs-endpoint" }
}

resource "aws_vpc_endpoint" "cloudwatch_monitoring" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.monitoring"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    aws_subnet.vpc_az1_private_app.id,
    aws_subnet.vpc_az2_private_app.id
  ]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]
  tags               = { Name = "${var.project_name}-cloudwatch-monitoring-endpoint" }
}
