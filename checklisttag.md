# 🏷️ Tagging Checklist — MH-COST-V FinTech Analyzer

> **4 tag bắt buộc cho mọi resource:**
> - `Owner` = teamlead@email.com
> - `Environment` = dev
> - `CostCenter` = G<số nhóm>
> - `Application` = FinTechAnalyzer

---

## ⚡ Ưu tiên tag trước (tốn tiền nhiều nhất)

- [ ] RDS Primary
- [ ] RDS Standby
- [ ] RDS Read Replica
- [ ] ElastiCache AZ-1
- [ ] ElastiCache AZ-2
- [ ] NAT Gateway AZ-1
- [ ] Lambda — Market_Updater
- [ ] Lambda — Asset_Router
- [ ] Lambda — Anomaly_Logging_Service
- [ ] Lambda — Data_Aggregation_Worker

---

## 🖥️ Compute — Lambda Functions

- [ ] Lambda — `Market_Updater`
- [ ] Lambda — `Asset_Router`
- [ ] Lambda — `Anomaly_Logging_Service`
- [ ] Lambda — `Data_Aggregation_Worker`

---

## 🌐 Networking

- [ ] API Gateway
- [ ] NAT Gateway AZ-1
- [ ] Firewall Endpoint AZ-1
- [ ] Firewall Endpoint AZ-2
- [ ] VPC Endpoint — Private Application Subnet (VPC-1)
- [ ] VPC Endpoint — Isolated Private Subnet (VPC-2)

---

## 🗄️ Storage & Database

- [ ] EFS — File System
- [ ] EFS — Mount Target AZ-1
- [ ] RDS Primary (AZ-1, VPC-2) — tag `keep=true` thêm
- [ ] RDS Standby (AZ-2, VPC-2) — tag `keep=true` thêm
- [ ] RDS Read Replica — **KHÔNG tag `keep=true`** (con mồi MH-COST-A)
- [ ] RDS Proxy AZ-1
- [ ] RDS Proxy AZ-2
- [ ] ElastiCache AZ-1
- [ ] ElastiCache AZ-2

---

## 📨 Messaging & Queue

- [ ] SQS — Dead-letter queue
- [ ] SQS — Top10_Alerts
- [ ] SQS — Standard_Alerts
- [ ] SNS Topic

---

## ⚙️ Operations & Backup

- [ ] EventBridge — 1-minute cronjob trigger
- [ ] EventBridge — End of session cronjob trigger
- [ ] AWS Backup Vault — VPC-1
- [ ] AWS Backup Vault — VPC-2
- [ ] CloudWatch Dashboard

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
