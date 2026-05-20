variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as a prefix for all resources"
  type        = string
  default     = "xbrain-w5"
}

# ──────────────────────────────────────────────────────────────────────────────
# VPC CIDRs
# Three non-overlapping /16 blocks — one per tier.
# Using the 10.1–10.3 range keeps each VPC clearly separated and leaves
# 10.4+ free for future expansion (management VPC, monitoring VPC, etc.).
# ──────────────────────────────────────────────────────────────────────────────

variable "ingress_vpc_cidr" {
  description = "CIDR block for the Ingress VPC (API Gateway VPC Link, edge endpoints)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "app_vpc_cidr" {
  description = "CIDR block for the Application VPC (Lambda functions)"
  type        = string
  default     = "10.2.0.0/16"
}

variable "db_vpc_cidr" {
  description = "CIDR block for the Database VPC (RDS Proxy + RDS PostgreSQL)"
  type        = string
  default     = "10.3.0.0/16"
}

# ──────────────────────────────────────────────────────────────────────────────
# Subnet CIDRs
# ──────────────────────────────────────────────────────────────────────────────

variable "ingress_subnet_cidrs" {
  description = "CIDR blocks for the Ingress VPC subnets (one per AZ)"
  type        = list(string)
  default     = ["10.1.0.0/24", "10.1.1.0/24"]
}

variable "app_subnet_cidrs" {
  description = "CIDR blocks for the Application VPC private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.2.0.0/18", "10.2.64.0/18"]
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for the Database VPC isolated subnets (one per AZ)"
  type        = list(string)
  default     = ["10.3.0.0/24", "10.3.1.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to use (must match subnet count — 2 required)"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "tags" {
  description = "Common tags applied to every resource"
  type        = map(string)
  default = {
    Project     = "xbrain"
    ManagedBy   = "terraform"
    Environment = "production"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Flow Logs
# ──────────────────────────────────────────────────────────────────────────────

variable "flow_log_retention_days" {
  description = "CloudWatch Logs retention in days for VPC Flow Logs (all three VPCs). Set to 365 for compliance workloads."
  type        = number
  default     = 90

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.flow_log_retention_days)
    error_message = "retention_in_days must be a value accepted by CloudWatch Logs (e.g. 30, 60, 90, 180, 365)."
  }
}
