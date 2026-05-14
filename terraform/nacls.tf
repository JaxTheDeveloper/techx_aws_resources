# ══════════════════════════════════════════════════════════════════════════════
# NACL 1 — INGRESS VPC
#
# Inbound:
#   443        — HTTPS from API Gateway / clients reaching VPC Link endpoints
#   1024-65535 — Ephemeral return traffic from the Application VPC
#
# Outbound:
#   443        — Forward HTTPS to Application VPC (Lambda via VPC Link)
#   1024-65535 — Return ephemeral traffic back to callers
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_network_acl" "ingress" {
  vpc_id     = aws_vpc.ingress.id
  subnet_ids = aws_subnet.ingress[*].id

  tags = {
    Name = "${var.project_name}-nacl-ingress"
    Tier = "ingress"
  }
}

# ---- Inbound rules ----

resource "aws_network_acl_rule" "ingress_inbound_https" {
  network_acl_id = aws_network_acl.ingress.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "ingress_inbound_ephemeral" {
  network_acl_id = aws_network_acl.ingress.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# ---- Outbound rules ----

resource "aws_network_acl_rule" "ingress_outbound_to_app_https" {
  network_acl_id = aws_network_acl.ingress.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.app_vpc_cidr
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "ingress_outbound_ephemeral" {
  network_acl_id = aws_network_acl.ingress.id
  rule_number    = 200
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# ══════════════════════════════════════════════════════════════════════════════
# NACL 2 — APPLICATION VPC
#
# Inbound:
#   443        — API calls arriving from the Ingress VPC (VPC Link → Lambda)
#   1024-65535 — Ephemeral return traffic from Database VPC (DB query results)
#                and from Interface VPC Endpoints within this VPC
#
# Outbound:
#   443        — Lambda → Interface VPC Endpoints (SNS, STS, Bedrock, Logs)
#   5432       — Lambda → RDS Proxy in Database VPC
#   1024-65535 — Return ephemeral traffic to Ingress VPC callers
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_network_acl" "app" {
  vpc_id     = aws_vpc.app.id
  subnet_ids = aws_subnet.app[*].id

  tags = {
    Name = "${var.project_name}-nacl-app"
    Tier = "application"
  }
}

# ---- Inbound rules ----

# HTTPS from Ingress VPC (API Gateway VPC Link traffic arriving at Lambda)
resource "aws_network_acl_rule" "app_inbound_https_from_ingress" {
  network_acl_id = aws_network_acl.app.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.ingress_vpc_cidr
  from_port      = 443
  to_port        = 443
}

# HTTPS from within the Application VPC (VPC Endpoint responses back to Lambda)
resource "aws_network_acl_rule" "app_inbound_https_local" {
  network_acl_id = aws_network_acl.app.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.app_vpc_cidr
  from_port      = 443
  to_port        = 443
}

# Ephemeral return traffic: DB query results back from Database VPC
resource "aws_network_acl_rule" "app_inbound_ephemeral_from_db" {
  network_acl_id = aws_network_acl.app.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.db_vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

# Ephemeral return traffic: Interface VPC Endpoint responses within this VPC
resource "aws_network_acl_rule" "app_inbound_ephemeral_local" {
  network_acl_id = aws_network_acl.app.id
  rule_number    = 210
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.app_vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

# ---- Outbound rules ----

# Lambda → Interface VPC Endpoints (SNS, STS, Bedrock Runtime, CloudWatch Logs)
resource "aws_network_acl_rule" "app_outbound_https_endpoints" {
  network_acl_id = aws_network_acl.app.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.app_vpc_cidr
  from_port      = 443
  to_port        = 443
}

# Lambda → RDS Proxy in the Database VPC
resource "aws_network_acl_rule" "app_outbound_postgres_to_db" {
  network_acl_id = aws_network_acl.app.id
  rule_number    = 200
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.db_vpc_cidr
  from_port      = 5432
  to_port        = 5432
}

# Ephemeral return traffic back to Ingress VPC callers
resource "aws_network_acl_rule" "app_outbound_ephemeral_to_ingress" {
  network_acl_id = aws_network_acl.app.id
  rule_number    = 300
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.ingress_vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

# ══════════════════════════════════════════════════════════════════════════════
# NACL 3 — DATABASE VPC
#
# Inbound:
#   5432       — RDS Proxy accepts connections from Lambda (Application VPC)
#   1024-65535 — Ephemeral return traffic (Secrets Manager endpoint responses
#                back to RDS Proxy, and intra-VPC RDS ↔ Proxy traffic)
#
# Outbound:
#   443        — RDS Proxy → Secrets Manager VPC Endpoint (fetch DB password)
#   5432       — RDS Proxy → RDS instance (cross-AZ failover path)
#   1024-65535 — Return traffic: query results back to Application VPC Lambda
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_network_acl" "db" {
  vpc_id     = aws_vpc.db.id
  subnet_ids = aws_subnet.db[*].id

  tags = {
    Name = "${var.project_name}-nacl-db"
    Tier = "database"
  }
}

# ---- Inbound rules ----

# PostgreSQL connections from Lambda (Application VPC)
resource "aws_network_acl_rule" "db_inbound_postgres_from_app" {
  network_acl_id = aws_network_acl.db.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.app_vpc_cidr
  from_port      = 5432
  to_port        = 5432
}

# Ephemeral return: Secrets Manager endpoint responses + intra-VPC Proxy↔RDS
resource "aws_network_acl_rule" "db_inbound_ephemeral" {
  network_acl_id = aws_network_acl.db.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.db_vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

# ---- Outbound rules ----

# RDS Proxy → Secrets Manager Interface Endpoint (within Database VPC)
resource "aws_network_acl_rule" "db_outbound_https_secretsmanager" {
  network_acl_id = aws_network_acl.db.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.db_vpc_cidr
  from_port      = 443
  to_port        = 443
}

# RDS Proxy → RDS instance (intra-VPC, cross-AZ failover path)
resource "aws_network_acl_rule" "db_outbound_postgres_intra" {
  network_acl_id = aws_network_acl.db.id
  rule_number    = 200
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.db_vpc_cidr
  from_port      = 5432
  to_port        = 5432
}

# Ephemeral return traffic: query results back to Application VPC Lambda
resource "aws_network_acl_rule" "db_outbound_ephemeral_to_app" {
  network_acl_id = aws_network_acl.db.id
  rule_number    = 300
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.app_vpc_cidr
  from_port      = 1024
  to_port        = 65535
}
