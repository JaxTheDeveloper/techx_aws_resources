terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "W7Capstone"
      Team        = var.team_tag
      Owner       = var.owner_email
      Environment = var.environment
    }
  }
}

# us-east-1 provider — required for WAF (CloudFront scope) and ACM (CloudFront cert)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "W7Capstone"
      Team        = var.team_tag
      Owner       = var.owner_email
      Environment = var.environment
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" { state = "available" }

locals {
  az_1        = data.aws_availability_zones.available.names[0]
  az_2        = data.aws_availability_zones.available.names[1]
  account_id  = data.aws_caller_identity.current.account_id
  name_prefix = lower(replace(var.project_name, "_", "-"))
}
