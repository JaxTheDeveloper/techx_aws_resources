# 🏷️ Tagging Checklist — MH-COST-V FinTech Analyzer

> **4 tag bắt buộc cho mọi resource:**
> - `Owner` = teamlead@email.com
> - `Environment` = dev
> - `CostCenter` = G<số nhóm>
> - `Application` = FinTechAnalyzer

---

## ⚡ Ưu tiên tag trước (tốn tiền nhiều nhất)

- [x] RDS Primary
- [ ] RDS Standby (doesnt have)
- [x] RDS Read Replica 
- [ ] ElastiCache AZ-1 (doesnt have)
- [x] NAT Gateway AZ-1
- [x] Lambda — Market_Updater
- [x] Lambda — Asset_Router
- [x] Lambda — Anomaly_Logging_Service
- [x] Lambda — Data_Aggregation_Worker

---

## 🖥️ Compute — Lambda Functions

- [x] Lambda — `Market_Updater`
- [x] Lambda — `Asset_Router`
- [x] Lambda — `Anomaly_Logging_Service`
- [x] Lambda — `Data_Aggregation_Worker`

---

## 🌐 Networking

- [x] API Gateway
- [x] NAT Gateway AZ-1
- [x] Firewall 
- [ ] VPC Endpoint — Private Application Subnet (VPC-1) (doesnt have)
- [ ] VPC Endpoint — Isolated Private Subnet (VPC-2) (doesnt have)

---

## 🗄️ Storage & Database

- [ X ] EFS — File System
- [x] RDS Primary (AZ-1, VPC-2) — tag `keep=true` thêm
- [x] RDS Read Replica — **KHÔNG tag `keep=true`** (con mồi MH-COST-A)
- [x] RDS Proxy AZ-1 (RDS Proxy không thể tag được, đổi strategy sang: Tag Secrets Manager (tại RDS Proxy lấy Secrets Manager -> Access tới RDS) và IAM Role
- [ ] ElastiCache AZ-1 (doesnt have)

---

## 📨 Messaging & Queue

- [ x ] SQS — Dead-letter queue
- [ x ] SQS — Top10_Alerts
- [ x ] SQS — Standard_Alerts
- [ x ] SNS Topic

---

## ⚙️ Operations & Backup

- [x] EventBridge — 1-minute cronjob trigger
- [x] EventBridge — End of session cronjob trigger
- [ ] AWS Backup Vault — VPC-1
- [ ] AWS Backup Vault — VPC-2
- [ ] CloudWatch Dashboard (Doesnt see)

---

## ✅ Bắt buộc sau khi tag xong (MH-COST-V)

- [ ] Vào **Billing Console → Cost allocation tags**
- [ ] Activate tag `Owner`
- [ ] Activate tag `Application`
- [ ] Chờ 24h → vào Cost Explorer filter theo tag → screenshot

---

## 📊 Progress Tracker

| Category | Total | Done | Remaining |
|----------|-------|------|-----------|
| Lambda | 4 | 0 | 4 |
| Networking | 6 | 0 | 6 |
| Storage & DB | 9 | 0 | 9 |
| Messaging | 4 | 0 | 4 |
| Operations | 5 | 0 | 5 |
| **Total** | **28** | **0** | **28** |
