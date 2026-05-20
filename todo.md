# W6 Task Breakdown — Group 1 (XBrain)
> **Deadline: 17h30 21/5/2026**

## Áp dụng Feedback W5 (bắt buộc đề cập ở Part 1)

| # | Improvement cần apply |
|---|----------------------|
| 1 | **VPC connectivity:** Nêu rõ cơ chế kết nối VPC_1 ↔ VPC_2 là **Peering** |
| 2 | Bổ sung **Network Firewall trong evidence pack** |
| 3 | Làm phần **Alert Log** |

## 1. MH-COST-V — Cost Visibility & Attribution
@Phong 

| # | Task | Owner |
|---|------|-------|
| 1.1 | Tag tất cả billable resources với **4 key bắt buộc**: `Application=<value>`, `Owner=<value>`, `Environment=dev`, `CostCenter=G1` <br> Resources phải tag: Lambda (Market_Updater, Asset_Reader, Data_Aggregation_Worker), RDS `xbrain-postgresql`, EFS, API Gateway `w5-BE-api`, S3, NAT Gateway, Network Firewall | — |
| 1.2 | Vào **Billing Console → Cost allocation tags → Activate** cả 2 key `Owner` và `Application` — bước riêng biệt, không phải chỉ tag trên resource là đủ | — |
| 1.3 | Cấu hình **AWS Budgets daily $150** với SNS alert (tái dùng cho MH-COST-A) | — |
| 1.4 | Cấu hình **Cost Explorer filter**, chụp screenshot cho thấy chi phí theo tag dimension của bạn sau ít nhất 24 giờ data redeploy | — |
| 1.5 | Viết **1 đoạn phân tích top 3 cost driver** của project stack (NAT Gateway, RDS, Lambda/EFS thường là top) | — |
| 1.6 | Viết **1-page tagging strategy document**: các key được dùng, allowed values, cách enforce trong real account | — |

**Pass condition:** 
- [ ] 4 tag key trên tất cả billable resource
- [ ] cost allocation tags activated
- [ ] ≥1 cost monitoring tool configured
- [ ] baseline cost screenshot kèm quan sát viết tay (???)
- [ ] tagging doc

**Pitfall:** Tag resource mà quên activate trong Billing Console → tags không hiện trong Cost Explorer.

---

## 2. MH-COST-A — Cost Control & Action
@Hung, Hien

| # | Task | Owner |
|---|------|-------|
| 2.1 | Viết **Lambda CostGuard**: gọi `StopInstances` / `StopDBInstance`; least-privilege IAM role chỉ gồm `ec2:StopInstances` + `rds:StopDBInstance` | — |
| 2.2 | Tạo **EventBridge Scheduler cron daily** (ví dụ 20:00 UTC+7) trigger Lambda CostGuard | — |
| 2.3 | Deploy 1 **EC2 instance test** (t3.micro, không tag `keep=true`), để Lambda stop nó, chụp **before/after** + CloudTrail event `StopInstances` | — |
| 2.4 | Notify when **Budgets daily >= $150 → SNS topic → Lambda CostGuard** (same Lambda); test bằng publish message thủ công lên SNS, capture CloudTrail | — |
| 2.5 | Viết **ADR (Architecture Decision Record) ngắn** (3–5 câu) | — |

> Lambda CostGuard làm gì? Khi được invoke (bởi EventBridge schedule hoặc SNS từ Budgets), Lambda sẽ:
> - Gọi AWS API để liệt kê tất cả EC2 instances đang running trong account
> - Với mỗi instance, kiểm tra tag — nếu instance đó không có tag keep=true thì stop nó
> - Tương tự với RDS instances đang available

> Sample ADR: Budgets cost data có độ trễ ~8–24h so với thực tế spend, do đó trong môi trường workshop 48h, trigger từ Budgets sẽ không tự động fire khi bill thực sự chạm $150.
> Thay vào đó, nhóm đã kiểm chứng bằng cách publish test message thủ công lên SNS topic, invoke thành công Lambda CostGuard và ghi nhận CloudTrail event StopInstances.
> Trong production, Budgets sẽ tự fire khi daily spend vượt ngưỡng và toàn bộ workflow này sẽ hoạt động tự động mà không cần can thiệp thủ công.

**Pass condition:** Lambda deployed (least-privilege) + daily EventBridge schedule + ≥1 resource thực sự bị stop bởi Lambda với CloudTrail before/after + Budgets→SNS→Lambda wired + latency ADR.

**Pitfall:** Budget chỉ gửi email mà không stop resource → không đủ điều kiện MH-COST-A.

---

## 3. MH-OBS — CloudWatch Observability
> **Generate data trước ngày demo (thứ 5)** — alarm ở `INSUFFICIENT_DATA` vào thứ 6 = mất điểm

@Huy, Dat, Duong

| # | Task | Owner |
|---|------|-------|
| 3.1 | Publish custom metrics — thứ gì đó ứng dụng của bạn đo và publish tường minh bằng `PutMetricData` API. Nghĩ về cái ứng dụng của bạn làm ở tầng business logic| — |
| 3.2 | Tạo **CloudWatch Dashboard** với 3 widget: <br> (1) custom metric widget — ghi rõ tên metric <br> (2) RDS `DatabaseConnections` <br> (3) Lambda error rate | — |
| 3.3 | Tạo **CloudWatch Alarm** trên RDS `DatabaseConnections > 20` → SNS action; invoke Asset_Reader vài lần để alarm ở trạng thái `OK` hoặc `ALARM`, **không được để `INSUFFICIENT_DATA`** vào ngày demo | — |
| 3.4 | Bật access logging cho API Gateway w5-BE-api (format JSON). Gọi thử ít nhất 10–15 request lên /reader-asset và /market-push để có data trong log. Vào CloudWatch → Log Insights → chọn log group /aws/apigateway/w5-BE-api → viết 2 query (ex: Top slowest endpoints & 4xx/5xx error patterns), chạy từng cái, xác nhận kết quả trả về ít nhất 5 rows, sau đó nhấn Save và đặt tên xbrain-api-slowest-endpoints và xbrain-api-4xx-5xx-patterns | — |
 
**Pass condition:** Dashboard với custom metric widget + ≥2 standard metric widget. Alarm ở `OK` hoặc `ALARM`. Log Insights query saved với ≥5 result rows.

**Pitfall:** Tạo alarm nhưng không invoke app để generate metric data → `INSUFFICIENT_DATA` vào ngày demo.

---

## 4. MH-SEC — Self-Healing Security Guard
> Implement sớm để có thời gian test vòng lặp detect→fix

@Vu, Quan

| # | Task | Owner |
|---|------|-------|
| 4.1 | Viết **SecurityGuard Lambda**: detect SG ingress rule `0.0.0.0/0` port 22 → gọi `RevokeSecurityGroupIngress`; least-privilege IAM role chỉ gồm `ec2:RevokeSecurityGroupIngress` + `ec2:DescribeSecurityGroups` *(path SG phù hợp nhất với stack đã có hardened SGs)* | — |
| 4.2 | Tạo **EventBridge rule** trigger trên CloudTrail event `AuthorizeSecurityGroupIngress` (near-realtime remediation) | — | — |
| 4.3 | **Demo loop:** <br> (1) Thêm rule `0.0.0.0/0:22` vào `lambda-sg` → chụp **before screenshot** (rule đang tồn tại) <br> (2) Lambda auto-revoke → chụp **after screenshot** (rule đã biến mất) <br> (3) CloudTrail event `RevokeSecurityGroupIngress` confirming fix | — |
| 4.4 | **Supporting control — Path A (KMS CMK):** Tạo CMK `alias/xbrain-rds-prod`, bật auto rotation, apply vào RDS `xbrain-postgresql`, verify CloudTrail `kms:GenerateDataKey` từ `rds.amazonaws.com` | — |
| 4.5 | Viết **1–2 câu security-cost trade-off**: *"CMK costs $1/month — justified vì mọi decrypt event đều logged với IAM principal, đáp ứng audit trail requirement của financial market data"* | — |
| 4.6 | Viết **security threat paragraph**: misconfiguration là gì (open SSH), blast radius nếu không fix (lateral movement vào Lambda private subnet → access RDS qua TGW) | — |

**Pass condition:** Lambda + trigger deployed (least-privilege) + demonstrated detect→fix loop với before/after + CloudTrail của fix API call + 1 supporting preventive control + security-cost statement.

**Pitfall:** Security control chỉ detect/log/alert nhưng không fix → không đạt MH-SEC. Điểm được chấm dựa trên CloudTrail event của fix API call.
