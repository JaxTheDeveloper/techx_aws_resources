###############################################################################
# VPC FLOW LOGS — MH1
# Both VPCs ship ALL traffic to CloudWatch at 1-minute aggregation interval.
###############################################################################

resource "aws_iam_role" "flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.project_name}-vpc-flow-logs-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}

###############################################################################
# VPC-1 (App) Flow Log
###############################################################################

resource "aws_cloudwatch_log_group" "vpc1_flow_logs" {
  name              = "/aws/vpc/flow-logs/${lower(var.project_name)}-app"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-vpc1-flow-logs"
    Environment = var.environment
  }
}

resource "aws_flow_log" "vpc1" {
  vpc_id                   = aws_vpc.vpc1.id
  traffic_type             = "ALL"
  iam_role_arn             = aws_iam_role.flow_logs.arn
  log_destination          = aws_cloudwatch_log_group.vpc1_flow_logs.arn
  max_aggregation_interval = 60

  tags = {
    Name        = "${var.project_name}-vpc1-flow-log"
    Environment = var.environment
  }
}

###############################################################################
# VPC-2 (DB) Flow Log
###############################################################################

resource "aws_cloudwatch_log_group" "vpc2_flow_logs" {
  name              = "/aws/vpc/flow-logs/${lower(var.project_name)}-db"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-vpc2-flow-logs"
    Environment = var.environment
  }
}

resource "aws_flow_log" "vpc2" {
  vpc_id                   = aws_vpc.vpc2.id
  traffic_type             = "ALL"
  iam_role_arn             = aws_iam_role.flow_logs.arn
  log_destination          = aws_cloudwatch_log_group.vpc2_flow_logs.arn
  max_aggregation_interval = 60

  tags = {
    Name        = "${var.project_name}-vpc2-flow-log"
    Environment = var.environment
  }
}
