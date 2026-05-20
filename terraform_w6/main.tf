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

  default_tags {
    tags = var.tags
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# VPC 1 — INGRESS VPC
#
# Edge boundary of the platform. Hosts the API Gateway VPC Link ENIs and the
# execute-api Interface Endpoint so that private REST/HTTP APIs can be reached
# without traversing the public internet.
#
# No Lambda or DB resources live here; traffic is forwarded to the
# Application VPC via VPC Peering.
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_vpc" "ingress" {
  cidr_block           = var.ingress_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc-ingress"
    Tier = "ingress"
  }
}

resource "aws_subnet" "ingress" {
  count = length(var.ingress_subnet_cidrs)

  vpc_id            = aws_vpc.ingress.id
  cidr_block        = var.ingress_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-ingress-subnet-${count.index + 1}"
    Tier = "ingress"
  }
}

resource "aws_route_table" "ingress" {
  vpc_id = aws_vpc.ingress.id

  tags = {
    Name = "${var.project_name}-rtb-ingress"
  }
}

resource "aws_route_table_association" "ingress" {
  count          = length(aws_subnet.ingress)
  subnet_id      = aws_subnet.ingress[count.index].id
  route_table_id = aws_route_table.ingress.id
}

# ══════════════════════════════════════════════════════════════════════════════
# VPC 2 — APPLICATION VPC
#
# Houses all Lambda functions (Telemetry_Read_API, Operator_Command_API,
# Data_Aggregation_Worker, Anomaly_Logging_Service) in private multi-AZ
# subnets. All AWS-service calls (SNS, STS, Bedrock, CloudWatch Logs, S3)
# stay within the AWS network via Interface / Gateway VPC Endpoints.
#
# Receives traffic from the Ingress VPC (via peering) and initiates
# connections to the Database VPC (via peering).
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_vpc" "app" {
  cidr_block           = var.app_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # Required for Interface VPC Endpoints

  tags = {
    Name = "${var.project_name}-vpc-app"
    Tier = "application"
  }
}

resource "aws_subnet" "app" {
  count = length(var.app_subnet_cidrs)

  vpc_id            = aws_vpc.app.id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-app-subnet-${count.index + 1}"
    Tier = "application"
  }
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "${var.project_name}-rtb-app"
  }
}

resource "aws_route_table_association" "app" {
  count          = length(aws_subnet.app)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app.id
}

# ══════════════════════════════════════════════════════════════════════════════
# VPC 3 — DATABASE VPC
#
# Fully isolated data tier: RDS Proxy + RDS PostgreSQL (multi-AZ).
# Zero internet route — not even a NAT Gateway. The only inbound traffic
# accepted is PostgreSQL (5432) from the Application VPC CIDR.
# Secrets Manager access uses a dedicated Interface Endpoint kept here.
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_vpc" "db" {
  cidr_block           = var.db_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # Required for Secrets Manager Interface Endpoint

  tags = {
    Name = "${var.project_name}-vpc-db"
    Tier = "database"
  }
}

resource "aws_subnet" "db" {
  count = length(var.db_subnet_cidrs)

  vpc_id            = aws_vpc.db.id
  cidr_block        = var.db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-db-subnet-${count.index + 1}"
    Tier = "database"
  }
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.db.id

  tags = {
    Name = "${var.project_name}-rtb-db"
  }
}

resource "aws_route_table_association" "db" {
  count          = length(aws_subnet.db)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}

# RDS Subnet Group — must reference subnets inside the Database VPC
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Subnet group for RDS PostgreSQL (isolated private subnets, Database VPC)"
  subnet_ids  = aws_subnet.db[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# VPC PEERING — Ingress ↔ Application
#
# Allows API Gateway VPC Link (in Ingress VPC) to reach Lambda ENIs
# (in Application VPC). Traffic never leaves the AWS backbone.
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_vpc_peering_connection" "ingress_to_app" {
  vpc_id      = aws_vpc.ingress.id
  peer_vpc_id = aws_vpc.app.id
  auto_accept = true

  tags = {
    Name = "${var.project_name}-peer-ingress-to-app"
  }
}

# Route: Ingress VPC to Application VPC (outbound to Lambda)
resource "aws_route" "ingress_to_app" {
  route_table_id            = aws_route_table.ingress.id
  destination_cidr_block    = var.app_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.ingress_to_app.id
}

# Route: Application VPC to Ingress VPC (return traffic)
resource "aws_route" "app_to_ingress" {
  route_table_id            = aws_route_table.app.id
  destination_cidr_block    = var.ingress_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.ingress_to_app.id
}

# ══════════════════════════════════════════════════════════════════════════════
# VPC PEERING — Application ↔ Database
#
# Allows Lambda functions to reach RDS Proxy on port 5432.
# The Database VPC has no route back to the Ingress VPC — enforcing that
# the DB layer can never be reached directly from the edge.
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_vpc_peering_connection" "app_to_db" {
  vpc_id      = aws_vpc.app.id
  peer_vpc_id = aws_vpc.db.id
  auto_accept = true

  tags = {
    Name = "${var.project_name}-peer-app-to-db"
  }
}

# Route: Application VPC to Database VPC (Lambda initiates DB connection)
resource "aws_route" "app_to_db" {
  route_table_id            = aws_route_table.app.id
  destination_cidr_block    = var.db_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.app_to_db.id
}

# Route: Database VPC to Application VPC (return traffic: query results)
resource "aws_route" "db_to_app" {
  route_table_id            = aws_route_table.db.id
  destination_cidr_block    = var.app_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.app_to_db.id
}
