variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name used as a prefix for all resources"
  type        = string
  default     = "dochub-w7"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "hackathon"
}

variable "team_tag" {
  description = "Team tag for cost allocation (e.g. G1)"
  type        = string
  default     = "G1"
}

variable "owner_email" {
  description = "Owner email for cost allocation tags"
  type        = string
}

# ─── VPC ──────────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_az1_private_app_cidr" {
  description = "VPC AZ-1 Private Subnet CIDR"
  type        = string
  default     = "10.0.10.0/22"
}

variable "vpc_az2_private_app_cidr" {
  description = "VPC AZ-2 Private Subnet CIDR"
  type        = string
  default     = "10.0.14.0/22"
}

# ─── Cognito / Auth ───────────────────────────────────────────────────────────

variable "google_oauth_client_id" {
  description = "Google OAuth 2.0 Client ID for Cognito federation"
  type        = string
  default     = ""
}

variable "google_oauth_client_secret" {
  description = "Google OAuth 2.0 Client Secret for Cognito federation"
  type        = string
  sensitive   = true
  default     = ""
}

# ─── Lambda ───────────────────────────────────────────────────────────────────

variable "lambda_memory_mb" {
  description = "Lambda memory in MB"
  type        = number
  default     = 512
}

variable "lambda_timeout_sec" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 60
}

# ─── Bedrock ──────────────────────────────────────────────────────────────────

variable "bedrock_foundation_model_id" {
  description = "Bedrock foundation model ID for the Agent / KB generate step"
  type        = string
  default     = "anthropic.claude-3-5-haiku-20241022-v1:0"
}

variable "bedrock_embedding_model_id" {
  description = "Bedrock embedding model ID for KB ingestion"
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

# ─── Budget / Cost ────────────────────────────────────────────────────────────

variable "budget_limit_usd" {
  description = "Total budget hard cap in USD"
  type        = string
  default     = "100"
}

variable "budget_alert_pct" {
  description = "Budget alert threshold as percentage (e.g. 80)"
  type        = number
  default     = 80
}
