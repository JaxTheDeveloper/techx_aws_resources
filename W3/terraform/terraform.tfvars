aws_region = "us-west-2"
project_name = "Xbrain-week-5"
environment = "prod"

vpc1_cidr = "10.1.0.0/16"
# 1
vpc1_az1_private_app_cidr = "10.1.0.0/18"
vpc1_az2_private_app_cidr = "10.1.64.0/18"
# 2
vpc1_az1_public_cidr = "10.1.128.0/24"
vpc1_az2_public_cidr = "10.1.129.0/24" 
# 3
vpc1_az1_firewall_cidr = "10.1.130.0/24"
vpc1_az2_firewall_cidr = "10.1.131.0/24" 

vpc2_cidr = "10.2.0.0/16"
vpc2_az1_isolated_cidr = "10.2.0.0/24"
vpc2_az2_isolated_cidr = "10.2.1.0/24"


