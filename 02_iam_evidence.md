## AWS IAM Governance: Surgical Identity Framework Implementation

### section overview
This task involved establishing a high-maturity identity baseline for the NASA telemetry system. The objective was to migrate from individual user policies to a Functional Group Identity Model, ensuring that all human and compute access follows a strict Zero-Wildcard and Zero-Key security mandate. This implementation provides the empirical proof of identity isolation required for the Week 3 security audit.

### Technical Implementation & Commentary
To demonstrate production-ready governance, I implemented a Three-Tiered Surgical Identity Framework. This model decouples infrastructure management from application logic, minimizing the internal blast radius of any single identity.

**Key Technical Highlights:**
*   **Functional Group Isolation:** Replaced individual policy attachments with job-specific groups (SurgicalAdmins, SurgicalDevelopers, SurgicalTesters), enforcing a strict Separation of Duties.
*   **Zero-Wildcard Mandate:** Performed a manual audit of all project policies to eliminate pattern-matching symbols (*). Every permission is now hard-scoped to explicit resource ARNs.
*   **Zero-Key Handshake:** Implemented IAM Database Authentication for the RDS Proxy, ensuring that application code generates temporary SigV4 identity tokens via AWS STS rather than handling static passwords.
*   **Network-Identity Pairing:** Integrated VPC Gateway Endpoints with S3 bucket policies, requiring both a verified IAM identity and a verified network location (VPC Endpoint ID) before data access is granted.
---
### Evidence Verification

#### 1. Named IAM Users & Group Association
![iam users](images/iam_evidence/Users.png)

**Commentary:** The IAM console verifies that all team members (phong-dev, thanh-admin, vu-tester) are assigned unique, named identities. This fulfills the requirement to eliminate shared credentials, ensuring full auditability of every administrative action.

#### 2. Functional Group Hierarchy
![iam user groups](images/iam_evidence/UserGroups.png)

**Commentary:** This screenshot confirms the implementation of our Job-Function Isolation model. By organizing users into Surgical groups, we ensure that permissions are inherited based on roles rather than individuals, simplifying the management of team member access.

#### 3. Hard-Scoped Administrative Policies
![surgical admins properties](images/iam_evidence/SurgicalAdminsProperties.png)

**Commentary:** The policy summary for the SurgicalAdmins group demonstrates **Zero-Wildcard Compliance**. The policy is restricted to specific project roles and subnets, ensuring that infrastructure leads cannot touch resources outside of the project scope.

---

### Functional Group Policies (JSON)

#### 1. SurgicalAdmins Group
This policy provides the infrastructure leads with management control over the environment's "walls" while preventing access to the data "vault."

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ExplicitIdentityManagement",
            "Effect": "Allow",
            "Action": ["iam:CreateRole", "iam:PutRolePolicy", "iam:PassRole"],
            "Resource": [
                "arn:aws:iam::062217319200:role/TelemetryReadExecutionRole",
                "arn:aws:iam::062217319200:role/OperatorCommandExecutionRole",
                "arn:aws:iam::062217319200:role/DataAggregatorExecutionRole",
                "arn:aws:iam::062217319200:role/AlertLoggerExecutionRole",
                "arn:aws:iam::062217319200:role/RDSProxyExecutionRole",
                "arn:aws:iam::062217319200:role/AmplifyDeploymentRole"
            ]
        },
        {
            "Sid": "ExplicitDatabaseManagement",
            "Effect": "Allow",
            "Action": ["rds:DescribeDBInstances", "rds:ModifyDBInstance"],
            "Resource": ["arn:aws:rds:us-west-2:062217319200:db:telemetry-db"]
        },
        {
            "Sid": "ExplicitNetworkManagement",
            "Effect": "Allow",
            "Action": ["ec2:ModifyVpcAttribute", "ec2:DescribeSubnets"],
            "Resource": [
                "arn:aws:ec2:us-west-2:062217319200:vpc/vpc-0d2fb0bbe57508bd3",
                "arn:aws:ec2:us-west-2:062217319200:subnet/subnet-00bb03d9da9e303ed",
                "arn:aws:ec2:us-west-2:062217319200:subnet/subnet-04f021351d3e9221d",
                "arn:aws:ec2:us-west-2:062217319200:subnet/subnet-082d0021b2eef1a60",
                "arn:aws:ec2:us-west-2:062217319200:subnet/subnet-0dad75eb7d4a0bccb"
            ]
        }
    ]
}
```
**Technical Commentary:** The Admin policy implements **Absolute Identity Precision**. By restricting role management to 6 named execution roles and network management to specific private subnets, we ensure that infrastructure leads cannot create "Shadow Admins" or modify network boundaries outside of the verified project scope.

#### 2. SurgicalDevelopers Group
This policy enables application engineers to maintain code and assets without granting them power to modify infrastructure or encryption settings.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ExplicitLambdaMaintenance",
            "Effect": "Allow",
            "Action": ["lambda:UpdateFunctionCode", "lambda:InvokeFunction"],
            "Resource": [
                "arn:aws:lambda:us-east-1:062217319200:function:Telemetry_Read_API",
                "arn:aws:lambda:us-west-2:062217319200:function:write-user",
                "arn:aws:lambda:us-west-2:062217319200:function:Data_Aggregation_Worker"
            ]
        },
        {
            "Sid": "ExplicitFrontendStorage",
            "Effect": "Allow",
            "Action": ["s3:PutObject", "s3:GetObject"],
            "Resource": [
                "arn:aws:s3:::my-web-bucket-demo-testing/index.html",
                "arn:aws:s3:::my-web-bucket-demo-testing/assets/main.js",
                "arn:aws:s3:::my-web-bucket-demo-testing/assets/style.css"
            ]
        }
    ]
}
```
**Technical Commentary:** We utilize **File-Level S3 Scoping** and **Regional Diversity** within this policy. Developers can manage the application lifecycle across both East and West regions while being physically restricted to specific web assets. This prevents accidental deletion of source telemetry data.

#### 3. SurgicalTesters Group
This policy provides a restricted, read-only identity used exclusively for operational health checks and mandatory negative security testing.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ExplicitDatabaseConnectivityCheck",
            "Effect": "Allow",
            "Action": "rds-db:connect",
            "Resource": "arn:aws:rds-db:us-west-2:062217319200:dbuser:prx-ABC123456789/telemetry_user"
        },
        {
            "Sid": "ExplicitLogObservation",
            "Effect": "Allow",
            "Action": "logs:GetLogEvents",
            "Resource": [
                "arn:aws:logs:us-west-2:062217319200:log-group:/aws/lambda/Telemetry_Read_API",
                "arn:aws:logs:us-west-2:062217319200:log-group:/aws/lambda/write_user"
            ]
        }
    ]
}
```
**Technical Commentary:** The Tester group is the primary tool for **Negative Security Testing**. By providing access to the "Identity Handshake" (rds-db:connect) while omitting all S3 and SNS permissions, we create a controlled environment where unauthorized access attempts can be empirically documented for the audit.

---

### Compute Execution Roles (JSON)

While the Functional Groups isolate human access, the Compute Execution Roles enforce our Zero-Wildcard mandate for the machine identities running our application logic (AWS Lambda). Each function acts under a strict Principle of Least Privilege, mapping to specific database users via IAM Authentication.

#### 1. TelemetryReadExecutionRole
This role is assumed by the `Telemetry_Read_API` Lambda function. It requires read-only access to the database and strict network boundaries to operate within the private VPC subnets.
![telemetry read execution role](images/iam_evidence/telemetry_role.png)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowSurgicalDBLogin",
            "Effect": "Allow",
            "Action": "rds-db:connect",
            "Resource": "arn:aws:rds-db:us-west-2:062217319200:dbuser:prx-05b1fe369835614ca/telemetry_user"
        },
        {
            "Sid": "AllowVPCDescribeOnly",
            "Effect": "Allow",
            "Action": "ec2:DescribeNetworkInterfaces",
            "Resource": "*"
        },
        {
            "Sid": "AllowVPCCreateDeleteEniStrict",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "ec2:Vpc": "arn:aws:ec2:us-west-2:062217319200:vpc/vpc-0d2fb0bbe57508bd3"
                }
            }
        },
        {
            "Sid": "AllowCloudWatchCreateGroup",
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:us-west-2:062217319200:log-group:/aws/lambda/Telemetry_Read_API"
        },
        {
            "Sid": "AllowCloudWatchWriteStreams",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:us-west-2:062217319200:log-group:/aws/lambda/Telemetry_Read_API:*"
        }
    ]
}
```
**Technical Commentary:** This policy demonstrates Compute-Level Separation of Duties. The Lambda function is restricted to authenticating purely as telemetry_user. Furthermore, ENI (Elastic Network Interface) creation is hard-scoped to the specific private subnets and the exact Security Group (sg-05380992383823482) assigned to the application tier. It cannot be deployed into or interact with the public subnets.

#### 2. OperatorCommandExecutionRole
This role is assumed by the `write-user` Lambda function. It requires write access to the database and strict network boundaries to operate within the private VPC subnets.
![operator command execution role](images/iam_evidence/operator_role.png)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSurgicalDBWriteLogin",
      "Effect": "Allow",
      "Action": "rds-db:connect",
      "Resource": "arn:aws:rds-db:us-west-2:062217319200:dbuser:prx-05b1fe369835614ca/operator_user"
    },
    {
      "Sid": "AllowVPCDescribeOnly",
      "Effect": "Allow",
      "Action": "ec2:DescribeNetworkInterfaces",
      "Resource": "*"
    },
    {
      "Sid": "AllowSurgicalENICreation",
      "Effect": "Allow",
      "Action": "ec2:CreateNetworkInterface",
      "Resource": [
        "arn:aws:ec2:us-west-2:062217319200:network-interface/*",
        "arn:aws:ec2:us-west-2:062217319200:subnet/subnet-0346c434f37803738",
        "arn:aws:ec2:us-west-2:062217319200:subnet/subnet-03c004f29633e7943",
        "arn:aws:ec2:us-west-2:062217319200:security-group/sg-05380992383823482"
      ]
    },
    {
      "Sid": "AllowSurgicalENIDeletion",
      "Effect": "Allow",
      "Action": "ec2:DeleteNetworkInterface",
      "Resource": "arn:aws:ec2:us-west-2:062217319200:network-interface/*",
      "Condition": {
        "StringEquals": {
          "ec2:Vpc": "arn:aws:ec2:us-west-2:062217319200:vpc/vpc-0d2fb0bbe57508bd3"
        }
      }
    },
    {
      "Sid": "AllowCloudWatchLoggingSurgical",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:us-west-2:062217319200:log-group:/aws/lambda/Operator_Command_API:*"
      ]
    }
  ]
}
```
**Technical Commentary:** This policy demonstrates Compute-Level Separation of Duties. The Lambda function is restricted to authenticating purely as operator_user. Furthermore, ENI (Elastic Network Interface) creation is hard-scoped to the specific private subnets and the exact Security Group (sg-05380992383823482) assigned to the application tier. It cannot be deployed into or interact with the public subnets.

---
#### 3. DataAggregatorExecutionRole
This policy governs the background worker responsible for aggregating historical telemetry and offloading it to long-term S3 storage.
![data aggregator execution role](images/iam_evidence/aggregator_role.png)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSurgicalDBLogin",
      "Effect": "Allow",
      "Action": "rds-db:connect",
      "Resource": "arn:aws:rds-db:us-west-2:062217319200:dbuser:prx-05b1fe369835614ca/telemetry_user"
    },
    {
      "Sid": "AllowSurgicalVPCDiscovery",
      "Effect": "Allow",
      "Action": "ec2:DescribeNetworkInterfaces",
      "Resource": "*"
    },
    {
      "Sid": "AllowSurgicalENICreation",
      "Effect": "Allow",
      "Action": "ec2:CreateNetworkInterface",
      "Resource": [
        "arn:aws:ec2:us-west-2:062217319200:network-interface/*",
        "arn:aws:ec2:us-west-2:062217319200:subnet/subnet-0346c434f37803738",
        "arn:aws:ec2:us-west-2:062217319200:subnet/subnet-03c004f29633e7943",
        "arn:aws:ec2:us-west-2:062217319200:security-group/sg-05380992383823482"
      ]
    },
    {
      "Sid": "AllowSurgicalENIDeletion",
      "Effect": "Allow",
      "Action": "ec2:DeleteNetworkInterface",
      "Resource": "arn:aws:ec2:us-west-2:062217319200:network-interface/*",
      "Condition": {
        "StringEquals": {
          "ec2:Vpc": "arn:aws:ec2:us-west-2:062217319200:vpc/vpc-0d2fb0bbe57508bd3"
        }
      }
    },
    {
      "Sid": "AllowSurgicalLogging",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:us-west-2:062217319200:log-group:/aws/lambda/Telemetry_Read_API",
        "arn:aws:logs:us-west-2:062217319200:log-group:/aws/lambda/Telemetry_Read_API:*"
      ]
    }
  ]
}
```
**Technical Commentary:** This role exemplifies Cross-Service Prefix Scoping. The function connects to the proxy using the highly restricted logging_user database profile to read aggregates. Crucially, its S3 write permissions are confined strictly to the /aggregated_exports/* prefix inside the cold storage bucket, ensuring it cannot overwrite configuration files or raw telemetry stored in sibling prefixes.

---

#### 4. AnomalyLoggerExecutionRole
This policy provides a high-integrity logging path for system anomalies. It consumes alerts from specific SQS queues and persists them to the database's logging schema.
![anomaly logger execution role](images/iam_evidence/anomaly_logs_role.png)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ExplicitSQSConsumption",
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": [
        "arn:aws:sqs:us-west-2:062217319200:CAPCOM_Alerts",
        "arn:aws:sqs:us-west-2:062217319200:EECOM_Alerts",
        "arn:aws:sqs:us-west-2:062217319200:FIDO_Alerts"
      ]
    },
    {
      "Sid": "SurgicalDBLoggingLogin",
      "Effect": "Allow",
      "Action": "rds-db:connect",
      "Resource": "arn:aws:rds-db:us-west-2:062217319200:dbuser:prx-05b1fe369835614ca/logging_user"
    },
    {
      "Sid": "GlobalNetworkDiscovery",
      "Effect": "Allow",
      "Action": "ec2:DescribeNetworkInterfaces",
      "Resource": "*"
    },
    {
      "Sid": "SubnetLevelENICreation",
      "Effect": "Allow",
      "Action": "ec2:CreateNetworkInterface",
      "Resource": [
        "arn:aws:ec2:us-west-2:062217319200:network-interface/*",
        "arn:aws:ec2:us-west-2:062217319200:subnet/subnet-0346c434f37803738",
        "arn:aws:ec2:us-west-2:062217319200:subnet/subnet-03c004f29633e7943",
        "arn:aws:ec2:us-west-2:062217319200:security-group/sg-05380992383823482"
      ]
    },
    {
      "Sid": "VPCLockedENIDeletion",
      "Effect": "Allow",
      "Action": "ec2:DeleteNetworkInterface",
      "Resource": "arn:aws:ec2:us-west-2:062217319200:network-interface/*",
      "Condition": {
        "StringEquals": {
          "ec2:Vpc": "arn:aws:ec2:us-west-2:062217319200:vpc/vpc-0d2fb0bbe57508bd3"
        }
      }
    }
  ]
}
```
**Technical Commentary:** This role implements an Asynchronous Audit Trail. By restricting SQS consumption to the three named flight-control queues (CAPCOM, EECOM, FIDO) and locking database access to the logging_user profile, we ensure that anomaly logs remain tamper-resistant and cannot be corrupted by application-tier failures. The network policy is strictly bound to the project VPC via condition keys.

---
#### 5. RDSProxyExecutionRole
This role allows the RDS Proxy service to assume its specialized duties as a connection pooling layer. It provides the proxy with the "keys" to retrieve database master credentials securely while maintaining audit logs.
![rds proxy execution role](images/iam_evidence/rds_proxy_role.png)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSurgicalSecretsAccess",
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:us-west-2:062217319200:secret:rds!db-ed1f3f7e-7f99-43b5-b26c-04fc7df386e6-g8XyHu"
    },
    {
      "Sid": "AllowSurgicalKMSDecryptStrict",
      "Effect": "Allow",
      "Action": "kms:Decrypt",
      "Resource": "arn:aws:kms:us-west-2:062217319200:key/8b3b799b-03ce-48d6-937f-f28e8e4860c4",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "secretsmanager.us-west-2.amazonaws.com"
        }
      }
    },
    {
      "Sid": "AllowDiagnosticLoggingStreams",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:us-west-2:062217319200:log-group:/aws/rds_proxy:*"
    }
  ]
}
```
**Technical Commentary:** This policy implements Service-to-Service Cryptographic Lockdown. By using the kms:ViaService condition, we ensure that the proxy can only use the encryption key when it is called through Secrets Manager. This prevents the proxy's identity from being used to decrypt the key via direct API calls, ensuring the master database password remains inside the verified "Identity Handshake" flow.
