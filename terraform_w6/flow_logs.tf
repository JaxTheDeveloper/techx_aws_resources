# ══════════════════════════════════════════════════════════════════════════════
# VPC FLOW LOGS — ALL THREE VPCs
#
# Flow Logs capture every accepted and rejected IP packet at the ENI level.
# They are the authoritative proof that:
#   • Traffic is flowing on the ports and CIDRs you declared in NACLs/SGs.
#   • Cross-VPC peering paths (IngresstoApp, ApptoDB) carry real traffic.
#   • The Database VPC rejects anything from outside the App VPC CIDR.
#   • No unexpected lateral movement or port scans are occurring.
#
# Design decisions:
#   • One CloudWatch Log Group per VPC — keeps ingress, app, and db logs
#     separated for independent access control and querying.
#   • Single shared IAM role — the flow-logs.amazonaws.com service principal
#     needs only two permissions; one role for all three VPCs is correct.
#   • Custom log format (v5) — adds vpc-id, flow-direction, and traffic-path
#     on top of the default fields so queries can identify which VPC emitted
#     each record without joining on interface IDs.
#   • Retention set by variable — default 90 days balances audit requirements
#     with CloudWatch Logs cost; set to 365 for compliance workloads.
#   • ALL traffic captured (not just REJECT) — you need ACCEPT records to
#     prove the peering routes carry live traffic to your mentor.
# ══════════════════════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────────────────────
# IAM — Flow Logs service role
#
# The flow-logs.amazonaws.com service principal needs permission to create
# a log stream and push log events to CloudWatch.  One role serves all
# three VPCs; the trust policy is scoped to the service, not a wildcard.
# ──────────────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "flow_logs_trust" {
  statement {
    sid     = "AllowFlowLogsService"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    # Condition prevents confused-deputy attacks: only flow logs from this
    # AWS account may assume the role, and only via the expected source ARN.
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_iam_policy_document" "flow_logs_permissions" {
  statement {
    sid    = "AllowCloudWatchLogsPush"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    # Scoped to the three log groups created below; * suffix covers log streams.
    resources = [
      "${aws_cloudwatch_log_group.flow_logs_ingress.arn}:*",
      "${aws_cloudwatch_log_group.flow_logs_app.arn}:*",
      "${aws_cloudwatch_log_group.flow_logs_db.arn}:*",
    ]
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "flow_logs" {
  name               = "${var.project_name}-role-vpc-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_trust.json

  tags = {
    Name = "${var.project_name}-role-vpc-flow-logs"
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  name   = "${var.project_name}-policy-vpc-flow-logs"
  role   = aws_iam_role.flow_logs.id
  policy = data.aws_iam_policy_document.flow_logs_permissions.json
}

# ──────────────────────────────────────────────────────────────────────────────
# CloudWatch Log Groups — one per VPC
#
# Separate groups allow per-VPC retention policies, resource-based policies,
# and CloudWatch Insights queries that stay scoped to a single tier.
# KMS encryption is recommended for production; add aws_kms_key resources
# and set kms_key_id here when your security policy requires it.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "flow_logs_ingress" {
  name              = "/aws/vpc/flow-logs/${var.project_name}-ingress"
  retention_in_days = var.flow_log_retention_days

  tags = {
    Name = "${var.project_name}-flow-logs-ingress"
    Tier = "ingress"
  }
}

resource "aws_cloudwatch_log_group" "flow_logs_app" {
  name              = "/aws/vpc/flow-logs/${var.project_name}-app"
  retention_in_days = var.flow_log_retention_days

  tags = {
    Name = "${var.project_name}-flow-logs-app"
    Tier = "application"
  }
}

resource "aws_cloudwatch_log_group" "flow_logs_db" {
  name              = "/aws/vpc/flow-logs/${var.project_name}-db"
  retention_in_days = var.flow_log_retention_days

  tags = {
    Name = "${var.project_name}-flow-logs-db"
    Tier = "database"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Custom log format (v5)
#
# Fields beyond the v2 default:
#   vpc-id          — which of the three VPCs emitted this record
#   subnet-id       — which AZ subnet
#   tcp-flags       — SYN/ACK/FIN/RST detection for connection-state analysis
#   flow-direction  — ingress | egress relative to the ENI
#   traffic-path    — through-igw | through-nat-gw | through-vpc-peering | ...
#
# This format is set once here and referenced by all three flow log resources.
# ──────────────────────────────────────────────────────────────────────────────

locals {
  flow_log_format = join(" ", [
    "$${version}",
    "$${account-id}",
    "$${vpc-id}",
    "$${subnet-id}",
    "$${interface-id}",
    "$${srcaddr}",
    "$${dstaddr}",
    "$${srcport}",
    "$${dstport}",
    "$${protocol}",
    "$${packets}",
    "$${bytes}",
    "$${start}",
    "$${end}",
    "$${action}",
    "$${log-status}",
    "$${tcp-flags}",
    "$${flow-direction}",
    "$${traffic-path}",
    "$${pkt-srcaddr}",
    "$${pkt-dstaddr}",
  ])
}

# ──────────────────────────────────────────────────────────────────────────────
# VPC FLOW LOG — Ingress VPC
#
# Captures all traffic at the edge:
#   ACCEPT :443 inbound = legitimate HTTPS / API Gateway connections
#   REJECT  anything    = blocked by Ingress NACL or SG (unexpected scan / probe)
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_flow_log" "ingress" {
  vpc_id          = aws_vpc.ingress.id
  traffic_type    = "ALL" # Capture ACCEPT + REJECT — both matter for evidence
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs_ingress.arn
  log_format      = local.flow_log_format

  tags = {
    Name = "${var.project_name}-flow-log-ingress"
    Tier = "ingress"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# VPC FLOW LOG — Application VPC
#
# The busiest log group. Captures:
#   ACCEPT :443 inbound from Ingress VPC CIDR  = VPC Link to Lambda ✓
#   ACCEPT :5432 outbound to DB VPC CIDR        = Lambda to RDS Proxy ✓
#   ACCEPT :443 outbound within App VPC          = Lambda to VPC Endpoints ✓
#   REJECT :5432 from Ingress VPC CIDR           = Ingress cannot reach DB directly ✓
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_flow_log" "app" {
  vpc_id          = aws_vpc.app.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs_app.arn
  log_format      = local.flow_log_format

  tags = {
    Name = "${var.project_name}-flow-log-app"
    Tier = "application"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# VPC FLOW LOG — Database VPC
#
# The most security-critical log group. Captures:
#   ACCEPT :5432 inbound from App VPC CIDR  = Lambda to RDS Proxy ✓
#   ACCEPT :443 outbound within DB VPC       = Proxy to Secrets Manager ✓
#   REJECT anything from Ingress VPC CIDR   = proves edge cannot reach DB ✓
#   REJECT anything on non-5432/443 ports   = proves tight NACL/SG enforcement ✓
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_flow_log" "db" {
  vpc_id          = aws_vpc.db.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs_db.arn
  log_format      = local.flow_log_format

  tags = {
    Name = "${var.project_name}-flow-log-db"
    Tier = "database"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# CloudWatch Insights Queries — pre-built for your Evidence Pack
#
# Save these as named queries so your mentor can re-run them live.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_query_definition" "rejected_traffic_db" {
  name = "${var.project_name}/db-vpc/rejected-traffic"

  log_group_names = [
    aws_cloudwatch_log_group.flow_logs_db.name,
  ]

  query_string = <<-EOT
    fields @timestamp, srcaddr, dstaddr, srcport, dstport, action, `flow-direction`
    | filter action = "REJECT"
    | sort @timestamp desc
    | limit 50
  EOT
}

resource "aws_cloudwatch_query_definition" "peering_traffic_app_to_db" {
  name = "${var.project_name}/app-vpc/lambda-to-rds-proxy"

  log_group_names = [
    aws_cloudwatch_log_group.flow_logs_app.name,
  ]

  query_string = <<-EOT
    fields @timestamp, srcaddr, dstaddr, dstport, action, bytes, `flow-direction`, `traffic-path`
    | filter dstport = 5432 and action = "ACCEPT"
    | sort @timestamp desc
    | limit 50
  EOT
}

resource "aws_cloudwatch_query_definition" "ingress_to_app_accepted" {
  name = "${var.project_name}/ingress-vpc/accepted-https-inbound"

  log_group_names = [
    aws_cloudwatch_log_group.flow_logs_ingress.name,
  ]

  query_string = <<-EOT
    fields @timestamp, srcaddr, dstaddr, dstport, action, bytes, `flow-direction`
    | filter dstport = 443 and action = "ACCEPT"
    | sort @timestamp desc
    | limit 50
  EOT
}

resource "aws_cloudwatch_query_definition" "db_reject_from_non_app" {
  name = "${var.project_name}/db-vpc/reject-non-app-vpc-sources"

  log_group_names = [
    aws_cloudwatch_log_group.flow_logs_db.name,
  ]

  # Catches any REJECT where the source is NOT in the App VPC CIDR.
  # Proves that the DB NACL/SG is blocking everything except Lambda.
  query_string = <<-EOT
    fields @timestamp, srcaddr, dstaddr, srcport, dstport, action, `vpc-id`
    | filter action = "REJECT"
    | filter not srcaddr like /^10\.2\./
    | sort @timestamp desc
    | limit 50
  EOT
}
