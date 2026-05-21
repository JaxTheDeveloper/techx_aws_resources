###############################################################################
# RDS DB SUBNET GROUP
# Requires at least 2 subnets in different AZs
###############################################################################

resource "aws_db_subnet_group" "rds" {
  name        = "${lower(var.project_name)}-rds-subnet-group"
  description = "RDS subnet group for ${var.project_name} - spans AZ1 and AZ2"

  subnet_ids = [
    aws_subnet.vpc2_az1_isolated.id,
    aws_subnet.vpc2_az2_isolated.id,
  ]

  tags = {
    Name        = "${var.project_name}-rds-subnet-group"
    Environment = var.environment
  }
}
