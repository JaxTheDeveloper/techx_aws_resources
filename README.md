# xbrain AWS Multi-VPC Networking — Terraform

Provisions the complete three-VPC networking and security layer for the xbrain
serverless telemetry platform.

## Architecture Overview

```
Internet
   │  (CloudFront, Route 53, WAF — managed services, no VPC)
   ▼
┌──────────────────────────────┐
│  VPC 1 — Ingress (10.1.0.0/16) │
│  execute-api VPC Endpoint    │
│  API Gateway VPC Link ENIs   │
└──────────────┬───────────────┘
               │ VPC Peering
               ▼
┌──────────────────────────────────────────────────────────┐
│  VPC 2 — Application (10.2.0.0/16)                       │
│  Lambda: Telemetry_Read_API, Operator_Command_API,       │
│          Data_Aggregation_Worker, Anomaly_Logging_Service │
│  Endpoints: S3 (GW), SNS, STS, Bedrock, CloudWatch Logs  │
└──────────────┬───────────────────────────────────────────┘
               │ VPC Peering
               ▼
┌──────────────────────────────────────────────────────────┐
│  VPC 3 — Database (10.3.0.0/16)                          │
│  RDS Proxy + RDS PostgreSQL (multi-AZ)                   │
│  Endpoints: Secrets Manager (Interface), S3 (GW)         │
└──────────────────────────────────────────────────────────┘
```

> **No Transit Gateway needed.** Two VPC peering connections (Ingress↔App,
> App↔DB) cover all required paths. The Database VPC deliberately has no
> route to the Ingress VPC — the DB layer can never be reached from the edge.

## What this creates (~50 resources)

### VPCs & Subnets

| Resource            | CIDR                          | Details                                |
| ------------------- | ----------------------------- | -------------------------------------- |
| Ingress VPC         | `10.1.0.0/16`                 | API Gateway edge, execute-api endpoint |
| Ingress Subnets × 2 | `10.1.0.0/24`, `10.1.1.0/24`  | VPC Link ENIs, multi-AZ                |
| Application VPC     | `10.2.0.0/16`                 | Lambda functions, private, multi-AZ    |
| App Subnets × 2     | `10.2.0.0/18`, `10.2.64.0/18` | Lambda VPC config                      |
| Database VPC        | `10.3.0.0/16`                 | RDS Proxy + RDS, fully isolated        |
| DB Subnets × 2      | `10.3.0.0/24`, `10.3.1.0/24`  | No internet route                      |

### VPC Peering

| Connection             | Purpose                         |
| ---------------------- | ------------------------------- |
| Ingress ↔ Application  | API Gateway VPC Link to Lambda  |
| Application ↔ Database | Lambda to RDS Proxy (port 5432) |

### NACLs (one per VPC)

| NACL        | Inbound                                                                 | Outbound                                                   |
| ----------- | ----------------------------------------------------------------------- | ---------------------------------------------------------- |
| Ingress     | 443 from 0.0.0.0/0, ephemeral                                           | 443 to App VPC, ephemeral                                  |
| Application | 443 from Ingress VPC, 443+ephemeral from App VPC, ephemeral from DB VPC | 443 to endpoints, 5432 to DB VPC, ephemeral to Ingress VPC |
| Database    | 5432 from App VPC, ephemeral intra-VPC                                  | 443+5432 intra-VPC, ephemeral to App VPC                   |

### Security Groups

| SG                  | VPC     | Inbound                    | Outbound                                               |
| ------------------- | ------- | -------------------------- | ------------------------------------------------------ |
| `sg-lambda`         | App     | None                       | :5432 to DB VPC CIDR; :443 to App VPC CIDR (endpoints) |
| `sg-app-vpce`       | App     | :443 from Lambda SG        | —                                                      |
| `sg-rds-proxy`      | DB      | :5432 from App VPC CIDR    | :5432 to RDS SG; :443 to DB VPC CIDR (SM endpoint)     |
| `sg-rds-postgresql` | DB      | :5432 from RDS Proxy SG    | None                                                   |
| `sg-db-vpce`        | DB      | :443 from RDS Proxy SG     | —                                                      |
| `sg-ingress-vpce`   | Ingress | :443 from Ingress VPC CIDR | —                                                      |

### VPC Endpoints

| Endpoint              | Type      | VPC     | Consumer                                 |
| --------------------- | --------- | ------- | ---------------------------------------- |
| execute-api           | Interface | Ingress | API Gateway private integration          |
| S3 (Gateway)          | Gateway   | App     | Lambda S3 operations                     |
| SNS                   | Interface | App     | Lambda to CAPCOM/EECOM/FIDO alert topics |
| STS                   | Interface | App     | Lambda IAM auth tokens for RDS Proxy     |
| Bedrock Runtime       | Interface | App     | Chatbot Lambda to Bedrock                |
| Bedrock Agent Runtime | Interface | App     | RAG Knowledge Base queries               |
| CloudWatch Logs       | Interface | App     | Lambda structured logging                |
| Secrets Manager       | Interface | DB      | RDS Proxy to fetch master password       |
| S3 (Gateway)          | Gateway   | DB      | RDS automated snapshot exports           |

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with a profile that has VPC, EC2, and RDS permissions
- `aws_region` must match where your Lambda, RDS Proxy, and RDS resources will be deployed

## Deploy

```bash
# 1. Initialise providers
terraform init

# 2. Preview the plan
terraform plan

# 3. Apply (creates ~50 resources)
terraform apply
```

## Key Outputs

After `apply`, Terraform prints the IDs you need in downstream modules:

```
# Pass to every Lambda VPC config:
app_vpc_id              to Lambda VpcConfig.VpcId
app_subnet_ids          to Lambda VpcConfig.SubnetIds
sg_lambda_id            to Lambda VpcConfig.SecurityGroupIds

# Pass to RDS Proxy:
db_subnet_ids           to RDS Proxy SubnetIds
sg_rds_proxy_id         to RDS Proxy VpcSecurityGroupIds

# Pass to RDS instance:
db_subnet_group_name    to RDS SubnetGroup parameter
sg_rds_postgresql_id    to RDS VpcSecurityGroupIds

# Pass to API Gateway VPC Link:
ingress_vpc_id          to VpcLink VpcId
ingress_subnet_ids      to VpcLink SubnetIds
```

## Using outputs in other modules

```hcl
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "your-tfstate-bucket"
    key    = "xbrain/networking/terraform.tfstate"
    region = "us-west-2"
  }
}

# Lambda module references:
# data.terraform_remote_state.networking.outputs.app_vpc_id
# data.terraform_remote_state.networking.outputs.app_subnet_ids
# data.terraform_remote_state.networking.outputs.sg_lambda_id

# RDS Proxy module references:
# data.terraform_remote_state.networking.outputs.db_subnet_ids
# data.terraform_remote_state.networking.outputs.sg_rds_proxy_id
```

## Destroy

```bash
terraform destroy
```

> **Note:** Destroy removes all networking. Ensure Lambda, RDS Proxy, and RDS
> resources are torn down first or the destroy will fail on dependency conflicts.
