output "vpc1_id" {
  description = "VPC"
  value       = aws_vpc.vpc.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.vpc.cidr_block
}

output "vpc_az1_private_subnet_id" {
  description = "VPC AZ-1 Private Subnet ID"
  value       = aws_subnet.vpc_az1_private_app.id
}

output "vpc_az2_private_subnet_id" {
  description = "VPC AZ-2 Private Subnet ID"
  value       = aws_subnet.vpc_az2_private_app.id
}
