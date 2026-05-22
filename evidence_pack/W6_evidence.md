# Evidence Pack - Group 1 - Week 6

---

## Cover

- **Group Number:** Group 1
- **Members:** Phan Thị Thủy Hiền, Hoàng Nhật Thành, Nguyễn Qúy Hưng, Nguyễn Hoàng Huy, Phạm Tùng Dương, Nguyễn Quang Phong, Trần Đình Minh Quân, Phan Nguyên Đạt, Võ Đức Vũ
- **Link Repository:** https://github.com/JaxTheDeveloper/techx_aws_resources.git
- **Week 6 Evidence Pack:** https://github.com/JaxTheDeveloper/techx_aws_resources/blob/week-6

# MH-COST-V

## Component 1 - Tagging Strategy Document

Below is the image of resourceGroups, is where all the tagged resources are grouped by their tags.

![Resource Group Image no1](../assets/resourceGroup.png)
![Resource Group Image no2](../assets/resourceGroup1.png)

To ensure data integrity within AWS Cost Explorer and Billing reports, every resource must be tagged with the following four keys. Case sensitivity is strictly enforced.

![Tagging Image](../assets/TagEditor1.png)

| Tag Key         | Description                                                                                    | Allowed Values                         | Workshop Value          |
| :-------------- | :--------------------------------------------------------------------------------------------- | :------------------------------------- | :---------------------- |
| **Owner**       | The email address of the individual or team accountable for the resource’s cost and lifecycle. | Valid organizational email string      | `masteremail@gmail.com` |
| **Application** | The logical name of the project or workload stack. Used for cost grouping.                     | `Xbrain-w6-project`, `Shared-Services` | `Xbrain-w6-project`     |
| **CostCenter**  | Internal billing code used to allocate cloud spend to specific departmental budgets.           | `G1`                                   | `G1`                    |
| **Environment** | Defines the operational stage and risk profile of the resource.                                | `dev`, `prod`, `staging`, `test`       | `dev`                   |

### Real-World Enforcement & Compliance

In a production-grade AWS environment, we move beyond manual checks to automated "guardrails" that ensure 100% compliance:

#### A. Proactive Prevention (SCPs)

We implement **Service Control Policies (SCPs)** at the AWS Organization level. These policies explicitly `Deny` actions like `ec2:RunInstances` or `s3:CreateBucket` if the mandatory tags (e.g., `Owner`, `Application`) are missing from the request. This makes it impossible to deploy "orphan" resources.

#### B. Standards Enforcement (Tag Policies)

To prevent typos or inconsistent casing (e.g., `Dev` vs `dev`), we use **AWS Tag Policies**. These enforce the exact "Allowed Values" defined in the table above. Any tag that doesn't match the pre-defined list is rejected by the API.

#### C. Terraform (Infrastructure as Code)

All infrastructure is deployed via **Terraform**. We utilize the `default_tags` feature in the AWS Provider block. This ensures that every resource automatically inherits the correct `Application`, `CostCenter`, and `Environment` tags at the moment of creation, reducing the burden on individual developers.

## Component 3 - Cost monitoring tools

### AWS Budget

We use **AWS Budget** to set up cost monitoring and alerts. Budget allows us to define spending thresholds and receive notifications when costs exceed these limits.

We set the Period to Monthly, so the budget is calculated monthly. Make sure to choose **Recurring budget** so that everytime it's the first day of the month, the budget is reset.

![Creating Budget](../assets/CreateBudget.png)

For option "Aggregate costs by", we choose "Unblended costs". Since this is a workshop environment, we use unblended costs to get the most accurate cost monitoring.

| Metric Name | What It Does (The Alarm Math) | Good For |
| :--- | :--- | :--- |
| **`Unblended`** | Looks at your raw, un-discounted daily bill. | Standard accounts where you pay exactly for what you use by the hour. |
| **`Amortized`** | Splits big upfront annual fees evenly over every single day. | Stopping "false alarm" alerts when a major subscription renews. |
| **`Blended`** | Averages your costs with all other team accounts in a big company. | High-level corporate overviews across multiple departments. |
| **`Net Unblended`** | Looks at your raw bill **after** subtracting free credits and coupons. | Tracking real out-of-pocket cash when using promo vouchers. |
| **`Net Amortized`** | Splits upfront fees evenly **and** subtracts free credits simultaneously. | Production environments to see your absolute, final bottom-line cost. |

![Creating Budget 2](../assets/CreateBudget1.png)

In this case, we setup a budget of 150$ monthly to monitor our AWS costs. We also configured a notification alert to be sent when costs exceed the thresholds.

- When **Forecasted cost > 66.66% ($99.99) of the $150**, it triggers a notification alert, which sent to the email address and also alerts the SNS (BudgetAlerts_Topic). This is the first warning threshold.
- When **Forecasted cost > 99.99% ($149.99) of the $150**, it triggers a notification alert, which sent to the email address and also alerts the SNS (BudgetAlerts_Topic). This is the final warning threshold.

Forecasted cost means it will predict the cost for the this month based on historical usage. And it will compare this forecasted cost with the budget threshold to trigger alerts. Thus, it helps us to detect and respond to cost spikes or anomalies before they exceed the budget.

![Budget Image](../assets/BudgetDetail.png)
![Budget Image 2](../assets/BudgetDetail1.png)

### Cost Anomaly Detection

Since we can't use Cost Allocation Tags, therefore, we use **AWS Cost Anomaly Detection** to monitor for unusual spending patterns. Anomaly detection helps identify cost spikes or outliers that may indicate a security breach or unexpected usage.

![Creating Cost Anomaly](../assets/creatingCostAnomaly.png)

Then we're gonna have to create a **Cost Anomaly Subscription** to receive notifications when anomalies are detected. This subscription will send alerts to the SNS topic (BudgetAlerts_Topic) and email address.

We can either set the threshold for the anomaly detection to be percent-based or absolute-based.

In this case, we set the threshold to be percent-based, so the anomaly detection will trigger when the actual cost exceeds 10% of the usual spent. For example: everyday we spend around $10, the threshold will be set to 10% of that, which is $1.

**Clarification**: In this week, this should just be testing so we can see if the anomaly detection is working as expected. But in reality, we should have a higher threshold to avoid false positives.

![Creating Cost Anomaly Subscription](../assets/creatingCostAnomalySub.png)

Below is the dashboard of the cost anomaly detection. Which would also have anomalies detected log over time.

![Cost Anomaly](../assets/costAnomaly.png)

---
# MH-COST-A

## Component (a), (c) — Stop Lambda & Demonstrated action
Before jumping into some testings, we need to take a look first: 
1. RDS instance isn't tagged `keep=true`
![RDS](../assets/rds.png) 
2. Ensure **least-privilege** IAM role to the "Stop Lambda" 
![Role](../assets/GuardLambdaRole.png)
![Policy](../assets/CostGuardPolicy.png)

> Actions like `StopDBInstance` and `StartDBInstance` change the state of our infrastructure. We will restrict these using a **Condition block**, so the Lambda can only touch our specific project.
git
---
For this component's testing, we just invoke Lambda manually: \
Before:
![RDS before being stopped](../assets/rds_before.png)
After: 
![RDS after being stopped](../assets/rds_after.png)
![RDS after being stopped](../assets/cloudtrail_comp_a.png) 

Done! 

## Component (b) — Daily scheduled trigger
Our work for this component follows this diagram below:
![alt text](../assets/daily_schedule_diagram.png)

Here is the **Scheduled Standard Rule using a Cron expression** used to trigger Lambda to stop RDS instance
![alt text](../assets/CostGuardDailySchedule_stop.png)
![alt text](../assets/CostGuardDailySchedule_stop_target.png)


This setup is used to invoke Lambda to start RDS instance
![alt text](../assets/CostGuardDailySchedule_start.png)
![alt text](../assets/CostGuardDailySchedule_start_target.png)
Here is the IAM Role of EventBridge
![alt text](../assets/EventBridgeIAMRole.png)

Event logs in CloudTrail (Look at the time): 
![alt text](../assets/stop_db_schedule.png)
![alt text](../assets/start_db_schedule.png)

## Component (d) — Cost-driven path
Our work for this component follows this diagram below:
![alt text](../assets/CostAlertDiagram.png)

Wire to SNS topic `BudgetAlerts_Topic`
![alt text](../assets/alert_1.png)
![alt text](../assets/alert_2.png)
![alt text](../assets/lamda_sns_policy.png)
![alt text](../assets/lambda_sns_policy_detailed.png)



# MH-OBS

## CloudWatch Dashboard

**Dashboard:** A CloudWatch dashboard was created with:

- Custom metric AssetReadLatency, DBWriteLatency, EndToEndIngestionLatency widget
- Standard metric Lambda errors widget
- Standard metric RDS DatabaseConnections widget
- Standard metric API Gateway 4XXError, 5XXError widget

![CloudWatch dashboard showing Lambda errors, RDS connections, and API metrics](../assets/dashboard.png)

**Observation:** Lambda errors are correlated with RDS connections and API traffic to identify performance issues quickly.
### Custom Metrics: Application Performance Monitoring

To gain deeper visibility into application-level performance beyond standard AWS infrastructure metrics, we implemented three custom CloudWatch metrics that track the complete data flow journey:

#### 1. AssetReadLatency — Database Read Performance

**Purpose:** Measures the time taken to read data from the database and return it to the application layer.

**Metric Details:**
- **Namespace:** `XBrain/AssetManagement`
- **Metric Name:** `AssetReadLatency`
- **Unit:** Milliseconds
- **Dimension:** 

**What it measures:** The duration from when the Lambda function initiates a database query until the data is fully retrieved and ready to be processed. This includes:
- Database connection establishment time
- Query execution time
- Data retrieval and serialization time

![AssetReadLatency metric showing database read performance over time](../assets/AcessReadLatency.jpg)

**Observation:** This metric helps identify database performance bottlenecks. Spikes in read latency may indicate:
- Database connection pool exhaustion
- Slow queries requiring optimization
- Network latency between Lambda and RDS
- Database resource contention (CPU/Memory/IOPS)

---

#### 2. DBWriteLatency — Database Write Performance

**Purpose:** Measures the time taken for Lambda to connect to the database and complete a write operation — from the moment the write begins until it is fully committed.

**Metric Details:**
- **Namespace:** `XBrain/AssetManagement`
- **Metric Name:** `DBWriteLatency`
- **Unit:** Milliseconds
- **Dimension:**

**What it measures:** The complete database write cycle, including:
- Database connection acquisition from the pool
- Transaction initiation
- Data validation and transformation
- Write operation execution (INSERT/UPDATE)
- Transaction commit and acknowledgment

![DBWriteLatency metric showing database write performance over time](../assets/DBWriteLatency.jpg)

**Observation:** This metric is critical for understanding write performance and data persistence reliability. High write latency may indicate:
- Database write throughput limits (IOPS exhaustion)
- Lock contention on database tables
- Large transaction sizes requiring optimization
- Network latency or connection pool issues

**Typical Baseline:**
- **Good:** < 50ms for simple writes
- **Acceptable:** 50-200ms for complex transactions
- **Investigate:** > 200ms consistently



---

#### 3. EndToEndIngestionLatency — Complete Request Journey

**Purpose:** Measures the total end-to-end latency from when the client sends a POST request until Lambda processes it completely and returns a response.

**Metric Details:**
- **Namespace:** `XBrain/AssetManagement`
- **Metric Name:** `EndToEndIngestionLatency`
- **Unit:** Milliseconds
- **Dimension:**

**What it measures:** The complete request lifecycle, including:
- API Gateway request routing time
- Lambda cold start (if applicable)
- Request payload parsing and validation
- Business logic execution
- Database write operation (DBWriteLatency above)
- Response serialization
- API Gateway response delivery

**Relationship to other metrics:**
```
EndToEndIngestionLatency = 
    API Gateway Latency +
    Lambda Initialization (cold start) +
    Request Processing +
    DBWriteLatency +
    Response Generation
```

**Observation:** This is the most important metric from a user experience perspective, as it represents what the end user actually experiences. By comparing this metric with DBWriteLatency, we can identify where time is being spent:

- If `EndToEndIngestionLatency ≈ DBWriteLatency`: Database is the bottleneck
- If `EndToEndIngestionLatency >> DBWriteLatency`: Overhead in API Gateway, Lambda cold starts, or application logic

**Typical Baseline:**
- **Excellent:** < 100ms (warm Lambda, simple write)
- **Good:** 100-500ms (warm Lambda, complex write)
- **Acceptable:** 500-1000ms (cold start included)
- **Investigate:** > 1000ms consistently

---

### Custom Metrics Dashboard Integration

These three custom metrics are integrated into the CloudWatch dashboard alongside standard infrastructure metrics, providing a complete view of system health:

**Dashboard Layout:**
```
┌─────────────────────────────────────────────────────────┐
│              Application Performance Dashboard          │
├─────────────────────────────────────────────────────────┤
│  Lambda Errors        │  Lambda Duration                │
│  (Standard)           │  (Standard)                     │
├─────────────────────────────────────────────────────────┤
│  RDS DatabaseConnections                                │
│  (Standard)                                             │
├─────────────────────────────────────────────────────────┤
│  API Gateway 4XX      │  API Gateway 5XX                │
│  (Standard)           │  (Standard)                     │
├─────────────────────────────────────────────────────────┤
│  AssetReadLatency     │  DBWriteLatency                 │
│  (Custom)             │  (Custom)                       │
├─────────────────────────────────────────────────────────┤
│  EndToEndIngestionLatency                               │
│  (Custom)                                               │
└─────────────────────────────────────────────────────────┘
```

**Correlation Analysis:**
By monitoring these metrics together, we can quickly identify the root cause of performance issues:

1. **High EndToEndIngestionLatency + Normal DBWriteLatency**
   → Issue: Lambda cold starts, API Gateway latency, or application logic
   → Action: Optimize Lambda memory, implement provisioned concurrency, or refactor code

2. **High DBWriteLatency + High RDS DatabaseConnections**
   → Issue: Database connection pool exhaustion or resource contention
   → Action: Increase connection pool size, optimize queries, or scale RDS

3. **High AssetReadLatency + Normal RDS CPU**
   → Issue: Slow queries or missing database indexes
   → Action: Analyze query execution plans, add indexes, or optimize queries

4. **Spikes in all custom metrics + API Gateway 5XX errors**
   → Issue: System-wide performance degradation or outage
   → Action: Check RDS health, Lambda throttling, or network issues

## CloudWatch Alarm

![CloudWatch alarm in ALARM state](../assets/alarm.png)
CloudWatch Metric Over-Threshold Evaluation & State Trigger

---

![CloudWatch alarm action configured to SNS](../assets/alarm_sns.png)
Amazon SNS Downstream Notification Output

**Observation:**
CloudWatch Alarm is configured to monitor the `Errors` metric at the compute tier. The application was actively triggered to generate real datapoints and avoid the `INSUFFICIENT_DATA` state.
Upon breaching the threshold, the alarm executes a precise state transition to trigger the downstream Amazon SNS action.


## CloudWatch Logs Insights Queries

### Query 1: Lambda Error Spikes by 5-Minute Window

**Log group:** `/aws/lambda/AssetReader`  
**Saved query:** `W6_OBS_Lambda_Error_Spikes`

**Purpose:** Detect Lambda error spikes in 5-minute windows for rapid incident response.

**Query:**

```cloudwatch
fields @timestamp, @message
| filter @message like /ERROR/
| stats count(*) as error_count by bin(5m)
| sort @timestamp desc
```

**Result:**

![Lambda error spike detection showing error count aggregated by 5-minute bins](../assets/query1.jpeg)

**Observation:** This query groups Lambda `AssetReader` errors into 5-minute windows. It helps the team see whether backend failures are isolated or recurring instead of manually opening individual log streams.

---

### Query 2: Top Rejected IPs from VPC Flow Logs

**Log group:** `/aws/vpc/flow-logs/xbrain-w5-app`  
**Saved query:** `W6_OBS_VPC_Top_Rejected_IPs`

**Purpose:** Identify source IPs with rejected network traffic to detect blocked requests, security group issues, or suspicious traffic.

**Query:**

```cloudwatch
filter action = "REJECT"
| stats count(*) as rejected_count by srcAddr
| sort rejected_count desc
| limit 10
```

**Result:**

![Top 10 rejected source IPs from VPC Flow Logs, sorted by rejection count](../assets/query2.jpeg)

**Observation:** This query ranks source IPs by rejected traffic count. It helps the team decide whether rejected traffic is expected security enforcement or a network/security group misconfiguration affecting legitimate traffic.

# MH-SEC

### 1. Architecture Overview

To ensure automated operations discipline (Ops Hygiene) and cloud data security control, the team deployed a Self-Healing mechanism based on the Event-Driven Architecture model with the following components:

- **AWS CloudTrail**: Acts as a monitor for all API calls that mutate infrastructure configuration.
- **Amazon EventBridge Rule**: A real-time event filter, continuously intercepting the `PutBucketPublicAccessBlock` API structure streamed from CloudTrail.
- **AWS Lambda (Python 3.12 - boto3)**: Acts as an automated remediation robot, operating with a Least-Privilege IAM Role, enforcing the re-activation of the public access block feature immediately upon detecting a violation.

---

### 2. Infrastructure Integration

Below is the visual evidence demonstrating that Amazon EventBridge has successfully connected as a Trigger for the management Lambda function:

![Image 1](../assets/Self-Healing1.jpg)

### 2.1. Least-Privilege IAM Policy Configuration

To ensure the intrinsic security of the automation system, the healing Lambda function is attached to an IAM Role that strictly adheres to the principle of least privilege, completely preventing any risk of privilege abuse:

![Image 6](../assets/Self-Healing6.jpg)

_Configuration Analysis:_

- **Action Restriction (Actions):** The policy only grants exactly 3 minimal permissions to read/write the S3 Public Access configuration and basic CloudWatch logging permissions. It does not use broad administrative permissions (`s3:*`).
- **Resource Restriction (Resources):** The S3 operation permissions are strictly locked to the exact ARNs of the 2 project buckets (`myproduct-kb-...` and `s3-backend-dependency-files`), completely eliminating any possibility of accidentally impacting other resources in the account.

---

### 3. Before / After Automation Test

#### Step A: Intentionally creating a security violation (BEFORE State)

Acting as an employee executing an incorrect procedure or a hacker intentionally exposing data, the **Block Public Access** feature on the S3 Bucket is disabled to put the system into a high-risk state:

![Image 2](../assets/Self-Healing2.jpg)

#### Step B: Automated system detection and remediation (AFTER State)

Without any manual intervention from administrators, within less than 1 minute, the Event-Driven loop triggered the Lambda function to enforce and revert the security block configuration back to an absolute safe state:

![Image 3](../assets/Self-Healing3.jpg)

---

### 4. CloudTrail Validation

To prove that the remediation action was completely executed by automated code (and not manually re-enabled by an administrator), below is the detailed event captured by CloudTrail, correctly recording the identity of the IAM Role attached to the Lambda function:

![Image 4](../assets/Self-Healing4.jpg)

![Image 5](../assets/Self-Healing5.jpg)

_Log Analysis:_

- **Event Name**: `PutBucketPublicAccessBlock`
- **User Identity**: `assumed-role/Lambda-S3-SelfHealing-Role/SelfHealing`
- **Conclusion**: The security operations robot has successfully completed the Near Real-Time healing cycle, fully satisfying the project requirements.

---

### 5. Supporting Preventive Control (Path A: KMS CMK)

To establish a defense-in-depth architecture, a proactive preventive control was implemented alongside the reactive S3 self-healing loop. The database layer (Amazon RDS) and its authentication layer (Secrets Manager via RDS Proxy) are encrypted using a Customer Managed Key (CMK).

**CMK Configuration & Automatic Rotation**
A dedicated symmetric KMS key (Alias: `xbrain-rds-prod`) was provisioned. To ensure long-term cryptographic hygiene, automatic key rotation is enabled (set to a 90-day period).
![KMS Key Rotation](../assets/SPC1.png)

**RDS At-Rest Encryption**
The `w6-db` instance is strictly configured to use the `xbrain-rds-prod` CMK for primary storage encryption, moving away from default AWS-managed keys to maintain full administrative control over the encryption material.
![RDS Encryption Config](../assets/SPC2.png)

**CloudTrail Validation of Active Cryptographic Usage**
To prove the CMK is actively encrypting and decrypting data in production, CloudTrail logs capture the exact `GenerateDataKey` and `Decrypt` API calls. The logs verify that `rds.amazonaws.com` and the assumed role for the RDS Proxy (`rds-proxy-role`) are actively interacting with the KMS key to securely handle database storage and secrets decryption.

_GenerateDataKey Event by RDS:_
![GenerateDataKey Event1](../assets/SPC3-2.png)
![GenerateDataKey Event](../assets/SPC3.png)

_Decrypt Event by RDS Proxy:_
![Decrypt Event1](../assets/SPC4-2.png)
![Decrypt Event](../assets/SPC4.png)

---

### 6. Risk Analysis & Cost Justification

Deploying the S3 automated remediation loop via EventBridge and Lambda incurs near-zero cost thanks to the serverless model, whereas maintaining a dedicated KMS Customer Managed Key (CMK) incurs a fixed fee of $1/month plus API call fees. This investment is entirely justified and safely within the $150 budget limit because the CMK enables automatic key rotation and generates a transparent audit trail on CloudTrail for every database-tier data decryption operation, meeting strict compliance standards that default AWS-managed keys cannot achieve.

# Bonuses
## Composite CloudWatch Alarm

**Objective:** Reduce "Alarm Fatigue" by ensuring the operations team is only notified during a correlated system degradation, rather than isolated metric spikes.

**Implementation & Evidence:**
We combined two individual metric alarms using strict `AND` logic. The notification action (SNS) is only configured on the Composite Alarm, while the child alarms remain silent to prevent alert spam.

* **CloudWatch Console:** The Composite Alarm successfully transitioned to the `In alarm` state because both child metric alarms (`DBWriteLatencyComponentAlarm` AND `AssetReadComponentAlarm`) breached their thresholds simultaneously.
* **Alert Delivery:** The SNS email notification proves the alert was successfully delivered to the team. The payload explicitly shows the Alarm Rule evaluating the `AND` condition: `ALARM("DBWriteLatencyComponentAlarm") AND ALARM("AssetReadComponentAlarm")`.

*Fig 1: Composite Alarm tracking child alarm states in the AWS Console.*
![Composite Alarm in CloudWatch Console](../assets/Bonus_CP1.png)

*Fig 2: Email notification triggered by the Composite Alarm.*
![SNS Email Notification](../assets/Bonus_CP2.png)
