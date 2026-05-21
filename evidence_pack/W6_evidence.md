# Evidence Pack - Group 1 - Week 5
---

## Cover

* **Group Number:** Group 1
* **Members:** Phan Thị Thủy Hiền, Hoàng Nhật Thành, Nguyễn Qúy Hưng, Nguyễn Hoàng Huy, Phạm Tùng Dương, Nguyễn Quang Phong, Trần Đình Minh Quân, Phan Nguyên Đạt, Võ Đức Vũ
* **Link Repository:** https://github.com/JaxTheDeveloper/techx_aws_resources.git
* **Week 6 Evidence Pack:** https://github.com/JaxTheDeveloper/techx_aws_resources/blob/week-6

# MH-COST-V
This serves as a template for this (and other) sections.

## Subsection

Set up VPC Flow Logs for both VPCs (App and DB) to monitor all network traffic passing through ENI.

- **BUllet point 1** content of bullet point 1
- **Bullet point 2** similar thing. `code goes here`.

To quote code, use this template

```bash
sudo rm -rf / --no-preserve-root
```

![alt text for img](../assets/abcdef.png)

### Evidence analysis 1



### Evidence Analysis 2


---

# MH-COST-A


# MH-OBS
## CloudWatch Dashboard

**Dashboard:** A CloudWatch dashboard was created with:
- standard Lambda duration, errors widget
- standard RDS DatabaseConnections widget
- standard API Gateway 4XXError, 5XXError widget

![CloudWatch dashboard showing Lambda errors, RDS connections, and API metrics](../assets/dashboard.png)

**Observation:** Lambda errors are correlated with RDS connections and API traffic to identify performance issues quickly.

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

# bonuses

