# 🏷️ Tagging Checklist — FinTech Analyzer W6

> **4 tag bắt buộc cho mọi resource:**
>
> - `Owner` = teamlead@email.com
> - `Environment` = dev
> - `CostCenter` = G<số nhóm>
> - `Application` = FinTechAnalyzer

---

## VPC & Networking

### VPC

- [ ] `aws_vpc.vpc1` — VPC-1 (Application)
- [ ] `aws_vpc.vpc2` — VPC-2 (Database)

### Subnets — VPC1

- [ ] `aws_subnet.vpc1_az1_public` — Public AZ1
- [ ] `aws_subnet.vpc1_az1_private_app` — Private App AZ1
- [ ] `aws_subnet.vpc1_az1_firewall` — Firewall AZ1

### Subnets — VPC2

- [ ] `aws_subnet.vpc2_az1_isolated` — Isolated AZ1
- [ ] `aws_subnet.vpc2_az2_isolated` — Isolated AZ2

### Gateways

- [ ] `aws_internet_gateway.vpc1_igw` — Internet Gateway
- [ ] `aws_nat_gateway.vpc1_az1` — NAT Gateway AZ1
- [ ] `aws_eip.vpc1_az1_nat` — Elastic IP for NAT

### VPC Peering

- [ ] `aws_vpc_peering_connection.vpc1_to_vpc2` — VPC Peering

### Route Tables — VPC1

- [ ] `aws_route_table.vpc1_public` — Public RT
- [ ] `aws_route_table.vpc1_private_app_az1` — Private App RT AZ1
- [ ] `aws_route_table.vpc1_firewall_az1` — Firewall RT AZ1

### Route Tables — VPC2

- [ ] `aws_route_table.vpc2_isolated_az1` — Isolated RT AZ1

### NACLs

- [ ] `aws_network_acl.vpc1_public` — Public NACL
- [ ] `aws_network_acl.vpc1_private_app` — Private App NACL
- [ ] `aws_network_acl.vpc1_firewall` — Firewall NACL
- [ ] `aws_network_acl.vpc2_isolated` — Isolated NACL

---

## Security Groups

- [ ] `aws_security_group.lambda_sg` — Lambda SG
- [ ] `aws_security_group.efs_sg` — EFS SG
- [ ] `aws_security_group.rds_proxy_sg` — RDS Proxy SG
- [ ] `aws_security_group.rds_sg` — RDS PostgreSQL SG
- [ ] `aws_security_group.vpc1_endpoint_sg` — VPC1 Endpoint SG
- [ ] `aws_security_group.vpc2_endpoint_sg` — VPC2 Endpoint SG

---

## Compute — Lambda Functions

- [ ] `Market_Updater` Lambda function
- [ ] `Asset_Router` Lambda function
- [ ] `Anomaly_Logging_Service` Lambda function
- [ ] `Data_Aggregation_Worker` Lambda function

---

## Storage

### EFS

- [ ] EFS File System
- [ ] EFS Mount Target AZ1

### S3

- [ ] `aws_s3_bucket.frontend` — Frontend bucket
- [ ] `aws_cloudfront_distribution.frontend` — CloudFront distribution

---

## Database — VPC2

- [ ] RDS Primary instance (`keep=true`)
- [ ] RDS Standby instance (`keep=true`)
- [ ] RDS Read Replica (NO `keep=true` — dùng làm demo MH-COST-A)
- [ ] `aws_db_subnet_group.rds` — DB Subnet Group
- [ ] RDS Proxy AZ1
- [ ] RDS Proxy AZ2
- [ ] ElastiCache AZ1
- [ ] ElastiCache AZ2

---

## Messaging & Queue

- [ ] SQS — Dead Letter Queue
- [ ] SQS — Top10_Alerts
- [ ] SQS — Standard_Alerts
- [ ] SNS Topic

---

## Operations & Monitoring

### EventBridge

- [ ] EventBridge Rule — 1-minute cronjob trigger
- [ ] EventBridge Rule — End of session cronjob trigger
- [ ] EventBridge Rule — Cost Guard daily schedule (MH-COST-A)
- [ ] EventBridge Rule — Self-Healing Security Guard (MH-SEC)

### CloudWatch

- [ ] CloudWatch Log Group — VPC1 Flow Logs
- [ ] CloudWatch Log Group — VPC2 Flow Logs
- [ ] CloudWatch Log Group — Firewall Alert
- [ ] CloudWatch Log Group — Firewall Flow
- [ ] CloudWatch Dashboard (MH-OBS)
- [ ] CloudWatch Alarm (MH-OBS)

### Flow Logs

- [ ] `aws_flow_log.vpc1` — VPC1 Flow Log
- [ ] `aws_flow_log.vpc2` — VPC2 Flow Log

### IAM Roles

- [ ] `aws_iam_role.flow_logs` — Flow Logs Role
- [ ] IAM Role — Cost Guard Lambda (MH-COST-A)
- [ ] IAM Role — Self-Healing Lambda (MH-SEC)

---

## Backup

- [ ] AWS Backup Vault — VPC1
- [ ] AWS Backup Vault — VPC2

---

## VPC Endpoints

- [ ] VPC Endpoint — VPC1 (SQS/SNS)
- [ ] VPC Endpoint — VPC2 (Secrets Manager)

---

## ✅ Activate trong Billing Console (bắt buộc cho MH-COST-V)

- [ ] Activate tag `Owner` trong Billing → Cost allocation tags
- [ ] Activate tag `Application` trong Billing → Cost allocation tags

---

## 📊 Progress

- Total resources: 55
- Tagged: 0
- Remaining: 55
