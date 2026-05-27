terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_1 = data.aws_availability_zones.available.names[0]
  az_2 = data.aws_availability_zones.available.names[1]
}
