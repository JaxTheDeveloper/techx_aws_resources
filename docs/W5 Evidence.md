#MH1

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


 ## MH4 — API Gateway + Auth + Throttling

**API Gateway Resource Tree:** [API Gateway Resource Tree](../assets/MH4_source_tree.png)
**Usage Plan:** [Usage Plan](../assets/MH4_usage_plan.png)
**API Key:** [API Key](../assets/MH4_api_key.png)
**Request Có Xác Thực (200):** [Request Có Xác Thực (200)](../assets/MH4_200.png)
**Request Không Có Xác Thực (403):** [Request Không Có Xác Thực (403)](../assets/MH4_403.png)
**Thay Đổi Code Ứng Dụng ở FE:** [Thay Đổi Code Ứng Dụng ở FE](../assets/MH4_code_change.png)