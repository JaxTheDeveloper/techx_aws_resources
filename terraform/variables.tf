variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name used as a prefix for all resources"
  type        = string
  default     = "Xbrain-w5"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_az1_private_app_cidr" {
  description = "VPC AZ-1 Private Subnet CIDR"
  type        = string
  default     = "10.0.8.0/22"
}

variable "vpc_az2_private_app_cidr" {
  description = "VPC AZ-2 Private Subnet CIDR"
  type        = string
  default     = "10.0.12.0/22"
}
