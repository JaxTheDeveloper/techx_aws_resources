###############################################################################
# variables.tf
###############################################################################

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name used as a prefix for all resources"
  type        = string
  default     = "myproject"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
  default     = "prod"
}

###############################################################################
# VPC-1 CIDRs
###############################################################################

variable "vpc1_cidr" {
  description = "CIDR block for VPC-1 (application VPC)"
  type        = string
  default     = "10.1.0.0/16"
}

# AZ-1 subnets
variable "vpc1_az1_public_cidr" {
  description = "VPC-1 AZ-1 Public Subnet CIDR"
  type        = string
  default     = "10.1.128.0/24"
}

variable "vpc1_az1_private_app_cidr" {
  description = "VPC-1 AZ-1 Private Application Subnet CIDR"
  type        = string
  default     = "10.1.0.0/18"
}

variable "vpc1_az1_firewall_cidr" {
  description = "VPC-1 AZ-1 Firewall Subnet CIDR"
  type        = string
  default     = "10.1.130.0/24"
}

# AZ-2 subnets
variable "vpc1_az2_public_cidr" {
  description = "VPC-1 AZ-2 Public Subnet CIDR"
  type        = string
  default     = "10.1.129.0/24"
}

variable "vpc1_az2_private_app_cidr" {
  description = "VPC-1 AZ-2 Private Application Subnet CIDR"
  type        = string
  default     = "10.1.64.0/18"
}

variable "vpc1_az2_firewall_cidr" {
  description = "VPC-1 AZ-2 Firewall Subnet CIDR"
  type        = string
  default     = "10.1.131.0/24"
}

###############################################################################
# VPC-2 CIDRs
###############################################################################

variable "vpc2_cidr" {
  description = "CIDR block for VPC-2 (database/data VPC)"
  type        = string
  default     = "10.2.0.0/16"
}

variable "vpc2_az1_isolated_cidr" {
  description = "VPC-2 AZ-1 Isolated Private Subnet CIDR"
  type        = string
  default     = "10.2.0.0/24"
}

variable "vpc2_az2_isolated_cidr" {
  description = "VPC-2 AZ-2 Isolated Private Subnet CIDR"
  type        = string
  default     = "10.2.1.0/24"
}
