###############################################################################
# outputs.tf
###############################################################################

# ── VPC-1 ────────────────────────────────────────────────────────────────────

output "vpc1_id" {
  description = "VPC-1 ID (Application VPC)"
  value       = aws_vpc.vpc1.id
}

output "vpc1_cidr" {
  description = "VPC-1 CIDR block"
  value       = aws_vpc.vpc1.cidr_block
}

output "vpc1_az1_public_subnet_id" {
  description = "VPC-1 AZ-1 Public Subnet ID"
  value       = aws_subnet.vpc1_az1_public.id
}

output "vpc1_az2_public_subnet_id" {
  description = "VPC-1 AZ-2 Public Subnet ID"
  value       = aws_subnet.vpc1_az2_public.id
}

output "vpc1_az1_private_app_subnet_id" {
  description = "VPC-1 AZ-1 Private Application Subnet ID"
  value       = aws_subnet.vpc1_az1_private_app.id
}

output "vpc1_az2_private_app_subnet_id" {
  description = "VPC-1 AZ-2 Private Application Subnet ID"
  value       = aws_subnet.vpc1_az2_private_app.id
}

output "vpc1_az1_firewall_subnet_id" {
  description = "VPC-1 AZ-1 Firewall Subnet ID"
  value       = aws_subnet.vpc1_az1_firewall.id
}

output "vpc1_az2_firewall_subnet_id" {
  description = "VPC-1 AZ-2 Firewall Subnet ID"
  value       = aws_subnet.vpc1_az2_firewall.id
}

output "vpc1_nat_gateway_az1_id" {
  description = "VPC-1 NAT Gateway AZ-1 ID"
  value       = aws_nat_gateway.vpc1_az1.id
}

output "vpc1_nat_gateway_az2_id" {
  description = "VPC-1 NAT Gateway AZ-2 ID"
  value       = aws_nat_gateway.vpc1_az2.id
}

# ── VPC-2 ────────────────────────────────────────────────────────────────────

output "vpc2_id" {
  description = "VPC-2 ID (Database VPC)"
  value       = aws_vpc.vpc2.id
}

output "vpc2_cidr" {
  description = "VPC-2 CIDR block"
  value       = aws_vpc.vpc2.cidr_block
}

output "vpc2_az1_isolated_subnet_id" {
  description = "VPC-2 AZ-1 Isolated Private Subnet ID"
  value       = aws_subnet.vpc2_az1_isolated.id
}

output "vpc2_az2_isolated_subnet_id" {
  description = "VPC-2 AZ-2 Isolated Private Subnet ID"
  value       = aws_subnet.vpc2_az2_isolated.id
}

# ── Transit Gateway ──────────────────────────────────────────────────────────

output "transit_gateway_id" {
  description = "Transit Gateway ID"
  value       = aws_ec2_transit_gateway.tgw.id
}

output "tgw_route_table_id" {
  description = "Transit Gateway Route Table ID"
  value       = aws_ec2_transit_gateway_route_table.main.id
}
