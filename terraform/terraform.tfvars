# ──────────────────────────────────────────────────────────────────────────────
# terraform.tfvars — override defaults here
# Do NOT commit this file to source control if it contains secrets.
# ──────────────────────────────────────────────────────────────────────────────

aws_region   = "us-west-2"
project_name = "xbrain-w5"

# ── VPC CIDRs (non-overlapping /16 blocks, one per tier) ──────────────────────
ingress_vpc_cidr = "10.1.0.0/16"
app_vpc_cidr     = "10.2.0.0/16"
db_vpc_cidr      = "10.3.0.0/16"

# ── Ingress VPC — API Gateway VPC Link subnets ────────────────────────────────
ingress_subnet_cidrs = ["10.1.0.0/24", "10.1.1.0/24"]

# ── Application VPC — Lambda subnets (private, multi-AZ) ─────────────────────
app_subnet_cidrs = ["10.2.0.0/18", "10.2.64.0/18"]

# ── Database VPC — RDS Proxy + RDS subnets (isolated) ────────────────────────
db_subnet_cidrs = ["10.3.0.0/24", "10.3.1.0/24"]

availability_zones = ["us-west-2a", "us-west-2b"]

tags = {
  Project     = "xbrain"
  ManagedBy   = "terraform"
  Environment = "production"
  Week        = "5"
}

# ── VPC Flow Logs ─────────────────────────────────────────────────────────────
# Retention period for all three Flow Log CloudWatch Log Groups.
# 90 days covers most audit requirements; raise to 365 for compliance.
flow_log_retention_days = 90
