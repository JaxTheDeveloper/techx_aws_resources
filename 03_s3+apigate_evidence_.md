# W3 Evidence — Networking & Presentation Layer
> Covers: CloudFront Distribution · S3 Buckets (WebStatic + Centralized Logging) · S3 Gateway VPC Endpoint · API Gateway

---

## Section 3 — Deployment Evidence

### 3.1 CloudFront Distribution

**Acceptance criterion:** Distribution deployed, WAF / Advanced DDoS protection enabled, default root object set, S3 origin locked down via OAC bucket policy.

**Screenshot 1 — Distribution overview + WAF Security tab**

![CloudFront distribution overview and WAF security panel](images/1.jpeg)

**Configuration notes:**
- Distribution name: `my-app-prod` (Standard price class — all edge locations for best performance).
- Distribution domain: `d37y8meyewnl01.cloudfront.net` · ARN: `arn:aws:cloudfront::062217319200:distribution/EJSZSS1WKOK9`.
- Default root object set to `index.html` — requests to `/` resolve to the static entry point without exposing the bucket path.
- **WAF enabled (Core protections — Monitor mode).** Advanced DDoS protection is shown as *Enabled* in the Security tab. We kept WAF in Monitor mode initially to baseline real traffic patterns before switching to Block mode, avoiding accidental blocks on legitimate users during the demo window.
- Standard logging and Cookie logging are both Off — we forward access logs to the Centralized Logging S3 bucket via the CloudWatch real-time log config instead (see screenshot 3 below).

**Screenshot 2 — CloudFront Logging tab (real-time log config attached)**

![CloudFront logging tab showing attached real-time access log configuration](images/9.jpeg)

**Configuration notes:**
- No S3 access log destination is attached (standard logging Off) — this is intentional. The distribution has 1 attached real-time access log (Cache behavior: Default `(*)`; Distribution status: *Enabled*) whose log config streams to CloudWatch Logs, giving lower-latency visibility than S3 batch delivery.
- The real-time log record is shown as *Disabled* at the cache-behavior level — this means the log config is attached but sampling rate can be tuned per behavior without deleting the config. We will enable it at 100% before the production handoff.

---

### 3.2 S3 — WebStatic Bucket (Origin for CloudFront)

**Acceptance criterion:** Bucket holds static frontend files, Block Public Access ON, OAC bucket policy restricts GetObject to the CloudFront distribution ARN only.

**Screenshot 3 — WebStatic bucket objects + Permissions tab (OAC policy)**

![WebStaticBucket S3 objects list and bucket policy](images/2.jpeg)

**Configuration notes:**
- Bucket name: `my-web-bucket-demo-testing`. Contains 4 top-level items: `assets/` folder, `favicon.ico`, `index.html` (430 B), and `fontname/` folder — exactly the build output of the static frontend.
- Block Public Access is **ON** (all public access blocked). Public access is intentionally denied at the bucket level; CloudFront is the only authorized reader.

**Screenshot 4 — Bucket policy + Block Public Access detail + ACL**

![Centralized Logging S3 bucket policy and OAC configuration](images/4.jpeg)

**Configuration notes:**
- Bucket policy enforces `PolicyForCloudFrontPrivateContent`: `Effect: Allow`, `Principal: cloudfront.amazonaws.com`, `Action: s3:GetObject`, `Resource: arn:aws:s3:::my-web-bucket-demo-testing/*`, conditioned on `AWS:SourceArn: arn:aws:cloudfront::062217319200:distribution/EJSZSS1WKOK9`. This is OAC (Origin Access Control) — the only way CloudFront can read objects; no direct public URL works.
- Object Ownership: **Bucket owner enforced** — ACLs are disabled; access is entirely policy-driven.
- Bucket Versioning: **Enabled** on this bucket (see "Bucket Versioning: Enabled" in the lower panel). MFA delete is Disabled — acceptable at this stage; we have no compliance mandate requiring it.

**Screenshot 5 — Properties tab: Default encryption, Object Lock, Lifecycle**

![S3 bucket properties showing encryption, Object Lock enabled, and lifecycle rule](images/5.jpeg)

**Configuration notes:**
- **Default encryption:** SSE-S3 (AWS-managed keys). Bucket Key is Enabled to reduce KMS API call costs. We chose SSE-S3 over a customer CMK because there is no current compliance mandate requiring key ownership, and AWS-managed rotation is automatic.
- **Object Lock: Enabled** (WORM model). Default retention is Disabled — Object Lock is on but no bucket-level default retention period is set; retention can be applied per-object if needed.
- **Lifecycle rule `Lifecycle-rule-demo` — Enabled, scope: Entire bucket:**
  - Day 0: Objects uploaded.
  - Day 30: Current versions → Glacier Instant Retrieval.
  - Day 760: Current versions expire (delete marker added).
  - Noncurrent versions: Day 7 → keep 1 newest, rest → Glacier Instant Retrieval; Day 30 → 0 newest retained, all others permanently deleted.
  - This rule manages cost for the logging bucket — hot-tier objects roll to cold storage and eventually expire without manual intervention.

---

### 3.3 S3 — Centralized Logging Bucket

**Acceptance criterion:** Separate bucket for CloudFront / application logs, Block Public Access ON, Versioning enabled, encryption enabled.

> **Note:** The Centralized Logging S3 bucket shares the same security baseline shown in screenshots 4 and 5 above (Block Public Access ON, Versioning Enabled, SSE-S3 encryption, Bucket Key enabled, Object Lock on). The bucket policy for this bucket does **not** have an OAC clause — it receives log delivery writes from the S3 Log Delivery group (shown in the ACL panel in screenshot 4) rather than CloudFront reads. The same lifecycle rule transitions logs to Glacier IR at Day 30 and expires them at Day 760, keeping long-term log storage costs predictable.

![placeholder — insert screenshot of Centralized Logging S3 bucket overview / Properties tab here]

---

### 3.4 API Gateway

**Acceptance criterion:** HTTP API (`w3-api-gateway`) deployed to a `prod` stage, IAM authorizer attached to all routes, Invoke URL live.

**Screenshot 6 — API Gateway prod stage + IAM Authorizer on routes**

![API Gateway prod stage details and IAM authorizer attached to routes](images/8.jpeg)

**Configuration notes:**
- API: `w3-api-gateway`. Stage: `prod`. Invoke URL: `https://5owejsc4jag.execute-api.us-west-2.amazonaws.com/prod`. Stage created and last updated April 24, 2026 at 1:43 AM.
- **Automatic Deployment: Enabled** — any change to the API configuration triggers a redeploy to `prod` automatically. Deployment ID `z1145e` is the current active build.
- **IAM Authorizer (`IAM (built-in)`, type: IAM)** is attached to all three routes:
  - `POST /aggregate` — IAM Auth
  - `POST /chat` — IAM Auth
  - `GET /telemetry` — IAM Auth
- All routes require a valid AWS SigV4-signed request. Unauthenticated calls receive `403 Forbidden` — this is the negative security test for API Gateway (see Section 7).
- No Stage Variables are set — environment-specific config (e.g., Lambda ARNs) is injected via Lambda environment variables rather than stage variables, keeping the stage config clean.

---

## Section 6 — VPC + Networking Evidence

### 6.1 S3 Gateway VPC Endpoint

**Acceptance criterion:** S3 Gateway Endpoint provisioned, labeled on diagram with route table entry, associated with application and isolated route tables.

**Screenshot 7 — VPC Endpoint detail + Route Tables**

![S3 Gateway VPC Endpoint detail showing route tables and status](images/6.jpeg)

**Configuration notes:**
- Endpoint ID: `vpce-0e31522bd693f3955`. Service name: `com.amazonaws.us-west-2.s3`. Endpoint type: **Gateway**. Status: **Available**. Created Thursday, April 23, 2026 at 23:12:46 GMT+7.
- VPC: `vpc-04DTf0d4be57508bf5 (w5-project)`. DNS record IP type: IPv4. Private DNS names enabled: No — Gateway endpoints route via prefix lists in route tables, not DNS; this is correct behavior for S3 Gateway endpoints.
- **Route tables associated (3 total):**
  - `rtb-05de4a67bf499477c (rtb-w5-appl…)` — application tier, 2 subnets
  - `rtb-05de6d6b76f640000 (rtb-w5-isolat…)` — isolated/database tier, 2 subnets
  - `rtb-0c76a21b3b0a35ec8` — Main route table, 0 subnets
- Traffic from EC2 instances and Lambda in the application tier to S3 (`my-web-bucket-demo-testing` and the Centralized Logging bucket) travels **entirely within the AWS network** via this endpoint — no NAT Gateway charge, no public internet path.
- We configured X this way because routing S3 traffic through a NAT Gateway costs ~$0.045/GB egress plus NAT hourly; a Gateway endpoint is free and keeps the data path private.

---

> **Diagram note:** The architecture diagram labels this endpoint as **"VPC Endpoint"** (component labeled `10` in the overview diagram, connected from the Lambda application tier to the S3 Centralized Logging bucket). The W3 diagram update must explicitly label this node as **"S3 Gateway Endpoint"** with the route table association `vpce-0e31522bd693f3955` per the MH4 acceptance criterion.

---

*Evidence captured: 2026-04-24. All screenshots taken from AWS Console (us-west-2) or CLI output. This file is the source of truth — slides derive from sections above.*
