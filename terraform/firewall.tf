# ══════════════════════════════════════════════════════════════════════════════
# MH2 — AWS NETWORK FIREWALL (Path A)
#
# W5 requirement: Any EC2 or Lambda reaching internet via NAT Gateway
# must have Network Firewall deployed between private subnet and NAT GW.
#
# Traffic path (Ingress VPC):
#   Private Subnet → Firewall Endpoint → NAT Gateway → Internet
#
# This file creates:
#   1. Internet Gateway + NAT Gateway (in Ingress VPC public subnet)
#   2. Firewall subnet + Security Group
#   3. Stateful rule group (domain-based egress allowlist)
#   4. Firewall policy + AWS Network Firewall
#   5. Route tables updated to force traffic through firewall
# ══════════════════════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────────────────────
# 1. Internet Gateway — Ingress VPC
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_internet_gateway" "ingress" {
  vpc_id = aws_vpc.ingress.id

  tags = {
    Name = "${var.project_name}-igw-ingress"
    Tier = "ingress"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# 2. Public Subnet + NAT Gateway (Ingress VPC)
#
# NAT Gateway lives in a public subnet (has IGW route).
# Private subnets route 0.0.0.0/0 → Firewall Endpoint → NAT GW → IGW.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_subnet" "ingress_public" {
  count = 2

  vpc_id                  = aws_vpc.ingress.id
  cidr_block              = cidrsubnet("10.1.128.0/17", 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-ingress-public-subnet-${count.index + 1}"
    Tier = "ingress-public"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "${var.project_name}-eip-nat"
  }
}

resource "aws_nat_gateway" "ingress" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.ingress_public[0].id

  tags = {
    Name = "${var.project_name}-nat-gw"
    Tier = "ingress"
  }

  depends_on = [aws_internet_gateway.ingress]
}

# Public subnet route table — NAT GW subnet needs IGW route
resource "aws_route_table" "ingress_public" {
  vpc_id = aws_vpc.ingress.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ingress.id
  }

  tags = {
    Name = "${var.project_name}-rtb-ingress-public"
  }
}

resource "aws_route_table_association" "ingress_public" {
  count          = 2
  subnet_id      = aws_subnet.ingress_public[count.index].id
  route_table_id = aws_route_table.ingress_public.id
}

# ──────────────────────────────────────────────────────────────────────────────
# 3. Firewall Subnet (/28 — minimum size for Network Firewall)
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_subnet" "firewall" {
  vpc_id            = aws_vpc.ingress.id
  cidr_block        = "10.1.200.0/28"
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "${var.project_name}-firewall-subnet"
    Tier = "firewall"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# 4. Stateful Rule Group — Domain-based egress allowlist
#
# W5 requires: at least one stateful rule group.
# This allowlist permits only specific domains outbound.
# Everything else is implicitly denied (default drop).
#
# Evidence Pack: show an ALLOWED request in Flow Logs
#                and a BLOCKED request in Alert Logs.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_networkfirewall_rule_group" "egress_domain_allowlist" {
  name     = "${var.project_name}-egress-domain-allowlist"
  type     = "STATEFUL"
  capacity = 100

  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [var.ingress_vpc_cidr, var.app_vpc_cidr]
        }
      }
    }

    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets = [
          # Allow AWS service endpoints (for SDK calls)
          ".amazonaws.com",
          # Allow your application domains — add more as needed
          ".cloudfront.net",
        ]
      }
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = {
    Name = "${var.project_name}-egress-domain-allowlist"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# 5. Firewall Policy
#
# - STRICT_ORDER: rules evaluated top-to-bottom, first match wins
# - Default stateless action: FORWARD to stateful engine
# - Alert Logs enabled: blocked requests appear in CloudWatch
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_networkfirewall_firewall_policy" "main" {
  name = "${var.project_name}-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.egress_domain_allowlist.arn
      priority     = 1
    }

    stateful_default_actions = ["aws:drop_strict", "aws:alert_strict"]

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = {
    Name = "${var.project_name}-firewall-policy"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# 6. AWS Network Firewall
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_networkfirewall_firewall" "main" {
  name                = "${var.project_name}-network-firewall"
  vpc_id              = aws_vpc.ingress.id
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn

  subnet_mapping {
    subnet_id = aws_subnet.firewall.id
  }

  tags = {
    Name = "${var.project_name}-network-firewall"
    MH   = "MH2-Path-A"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# 7. Firewall Logging — Alert Logs to CloudWatch
#
# W5 requires: show a blocked request in Alert Logs.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "firewall_alerts" {
  name              = "/aws/network-firewall/${var.project_name}/alerts"
  retention_in_days = var.flow_log_retention_days

  tags = {
    Name = "${var.project_name}-firewall-alert-logs"
  }
}

resource "aws_networkfirewall_logging_configuration" "main" {
  firewall_arn = aws_networkfirewall_firewall.main.arn

  logging_configuration {
    log_destination_config {
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall_alerts.name
      }
    }

    log_destination_config {
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
      log_destination = {
        logGroup = aws_cloudwatch_log_group.flow_logs_ingress.name
      }
    }
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# 8. Route Tables — Force traffic through Firewall Endpoint
#
# Traffic path:
#   Private subnet → 0.0.0.0/0 → Firewall Endpoint
#   Firewall subnet → 0.0.0.0/0 → NAT Gateway
#   NAT Gateway subnet → 0.0.0.0/0 → IGW
#
# The firewall endpoint ID is retrieved from the sync_states output.
# ──────────────────────────────────────────────────────────────────────────────

locals {
  # Extract the firewall endpoint ID from the first AZ sync state
  firewall_endpoint_id = tolist(aws_networkfirewall_firewall.main.firewall_status[0].sync_states)[0].attachment[0].endpoint_id
}

# Firewall subnet → NAT Gateway
resource "aws_route_table" "firewall" {
  vpc_id = aws_vpc.ingress.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ingress.id
  }

  tags = {
    Name = "${var.project_name}-rtb-firewall"
  }
}

resource "aws_route_table_association" "firewall" {
  subnet_id      = aws_subnet.firewall.id
  route_table_id = aws_route_table.firewall.id
}

# Private ingress subnets → Firewall Endpoint
resource "aws_route" "ingress_private_to_firewall" {
  count                  = length(aws_subnet.ingress)
  route_table_id         = aws_route_table.ingress.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.firewall_endpoint_id
}

# ──────────────────────────────────────────────────────────────────────────────
# 9. Outputs — for Evidence Pack
# ──────────────────────────────────────────────────────────────────────────────

output "network_firewall_arn" {
  description = "ARN of the Network Firewall — use in Evidence Pack MH2"
  value       = aws_networkfirewall_firewall.main.arn
}

output "firewall_alert_log_group" {
  description = "CloudWatch Log Group for firewall Alert Logs (blocked requests)"
  value       = aws_cloudwatch_log_group.firewall_alerts.name
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.ingress.id
}
