**Flowlogs**

Set up VPC Flow Logs for both VPCs (App and DB) to monitor all network traffic passing through ENI.

- **Aggregation Interval:** 1 minute (To ensure the highest real-time accuracy).
- **Destination:** CloudWatch Logs Group `/aws/vpc/flow-logs/xbrain-w5-app` and `/aws/vpc/flow-logs/xbrain-w5-db`.

[image1]: ../assets/flowlogs1.png
[image2]: ../assets/flowlogs2.png

Separating Log Groups for each VPC and setting a 1-minute interval makes troubleshooting and auditing more accurate, meeting observability requirements.  
[image3]: ../assets/flowlogs3.png

[image4]: ../assets/flowlogs4.png

Use CloudWatch Logs Insights to query and confirm that traffic from the App Tier (VPC1) has successfully connected to the Database Tier (VPC2).

**Evidence analysis:**

- **Source IP:** 10.1.47.229 (Located within the VPC1 subnet).
- **Destination IP:** 10.2.0.116 (Located within the VPC2 subnet \- where RDS is hosted).
- **Destination Port:** 5432 (PostgreSQL protocol).
- **Action: ACCEPT**.

[image5]: ../assets/flowlogs5.png

Implement granular security controls within the Database VPC to enforce the Principle of Least Privilege and prevent lateral movement.

**Evidence Analysis:**

- **Source IP:** 10.2.0.150 (Internal resource within DB VPC).
- **Destination IP:** 10.2.1.158 (Database instance).
- **Destination Port:** 5432 (PostgreSQL).
- **Action:** **REJECT**.

[image6]: ../assets/flowlogs6.png

---

# MH4 — API Gateway + Auth + Throttling

### 1. API Gateway Resource Tree:
The structural deployment tree and Stage configuration for the w5-BE-api on AWS API Gateway. The active prod stage exposes two core routes mapped to their respective backend services: POST /market-push for ingesting data streams and GET /reader-asset for retrieving database payloads.
 ![API Gateway Resource Tree](../assets/MH4_source_tree.png)
### 2. Usage Plan:
Throttling and quota configuration for the w5-usage-plan (ID: eeo2tc). It establishes strict API utilization boundaries—setting a steady rate of 20 requests per second, a maximum burst of 50 requests, and a monthly quota of 50,000 requests—enforced across the prod stage of the w5-BE-api.
 ![Usage Plan](../assets/MH4_usage_plan.png)
### 3. API Key:
Configuration details of the AWS API Gateway API Key named w5-api-key in an Active status. The key has been successfully created and linked to the w5-usage-plan, allowing authenticated access to the target API stage.
 ![API Key](../assets/MH4_api_key.png)
### 4. Request Có Xác Thực (200):
Successful end-to-end integration test of the GET /reader-asset endpoint returning an HTTP/1.1 200 OK status code. The API Gateway successfully authenticates the request via the x-api-key header and passes it to the Lambda function, which fetches and returns the raw JSON payload from the Amazon RDS PostgreSQL database (w5).
 ![Request Có Xác Thực (200)](../assets/MH4_200.png)
### 5. Request Không Có Xác Thực (403):
Verification of the API Gateway's built-in security and authentication mechanism. When a client attempts to invoke the /reader-asset endpoint without a valid API Key in the headers, the Gateway automatically blocks the request and rejects it with an HTTP/1.1 403 Forbidden error to protect backend resources.
 ![Request Không Có Xác Thực (403)](../assets/MH4_403.png)
### 6. Thay Đổi Code Ứng Dụng ở FE:
Frontend source code implementation for the asynchronous requestJson function using the Native Fetch API. The base URL is configured dynamically via the VITE_API_BASE_URL environment variable to target the AWS API Gateway endpoint, automatically appending standard application/json content-type headers
 ![Thay Đổi Code Ứng Dụng ở FE](../assets/MH4_code_change.png)

---

# MH5:

## Serverless Scaling Pattern — Handle Load Correctly

### Why choose Async Invocation + Dead Letter Queue?

Lambda runs on a schedule and scans for price anomalies. If it crashes mid-run -> we don't want to lose the data we've already processed. With async invocation and dead letter queue, we can ensure that our data is not lost even if the function crashes. Lambda will automatically retry the failed invocations and send the failed events to the dead letter queue so that we can investigate and fix the issue. This is better than synchronous invocation because it allows the function to continue processing other events while waiting for the failed ones to be retried.

---

## Evidence

### 1. Lambda Configuration — Async Invocation + DLQ

`AnomalyLoggingService` is configured with **Retry attempts: 2** and **Dead-letter queue: AnomalyLoggingService_DLQ**. This means on failure, Lambda retries 2 more times (3 total) before sending the event to SQS.

![Lambda async invocation config](../assets/anomaly-service-dlq-config.png)

---

### 2. Failed Invocation Result (Test tab)

A manual test invocation from the Lambda console shows **"Executing function: failed"** with `OperationalError: unable to open database file`. This is the intentional failure used to demonstrate the retry + DLQ pattern.

![Failed invocation detail](../assets/failed-invocation-result.png)

---

### 3. CloudWatch Logs — 3 Retry Attempts

CloudWatch shows **3 separate START/END/REPORT entries** for the same `RequestId: a0dad215-dc0c-4917-a341-c3ff9af16da7`, each with `Status: error`. This confirms Lambda attempted the invocation 3 times (original + 2 retries) before giving up.

![CloudWatch 3 retry attempts - overview](../assets/cloudwatch-3-retries-overview.png)

![CloudWatch 3 retry attempts - detail](../assets/cloudwatch-3-retries-detail.png)

---

### 4. Failed Event in DLQ

After all 3 attempts failed, the original event was automatically sent to `AnomalyLoggingService_DLQ`. The message body contains the original EventBridge scheduled event payload, confirming nothing was silently lost.

![DLQ message list](../assets/dlq-message-list.png)

![DLQ message body](../assets/dlq-message-body.png)
