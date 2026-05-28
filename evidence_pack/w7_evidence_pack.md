# W7 Capstone Evidence Pack: AI Document Hub (DocHub)

## 1. Cover
* **Group:** Group 1
* **Members:** Phan Thị Thủy Hiền, Hoàng Nhật Thành, Nguyễn Qúy Hưng, Nguyễn Hoàng Huy, Phạm Tùng Dương, Nguyễn Quang Phong, Trần Đình Minh Quân, Phan Nguyên Đạt, Võ Đức Vũ
* **Live URL (HTTPS):** `https://docs4hub.tech`
* **GitHub Repo:** `https://github.com/JaxTheDeveloper/techx_aws_resources/tree/week-7-capstone#`
* **Total Spend:** `$0.47`

---

## 2. Pitch & Vision
AI Document Hub is a multi-tenant SaaS platform that helps legal and compliance teams manage, search, and cross-query thousands of contracts and policy documents.

* **The Problem:** Legal teams spend too much time searching for specific clauses scattered across dozens of different contract versions.
* **The AI Solution:** Automating information extraction and summarization based on strictly isolated tenant access rights.
* **Real-world parallel:** Our model learns from products like Harvey AI and Glean Workspace, specifically tackling the "document confusion" problem (where the AI mistakenly cites the wrong contract).

---

## 3. Architecture & Service Decisions

![Final Architecture Diagram](../assets/architecture.jpg)


Our system fulfills all 7 Mandatory Capabilities[cite: 4]:

| Mandatory Capability | Chosen Service | Rationale |
| :--- | :--- | :--- |
| **1. User Interface** | CloudFront + S3 Static | Provides a free public HTTPS URL, easy to deploy static frontend. |
| **2. App Compute** | API Gateway HTTP + Lambda | HTTP API is cheaper than REST API; Lambda has no idle cost and scales per request. |
| **3. AI / ML** | Bedrock Agent + KB (Haiku) | Agent allows calling a Lambda tool to filter documents by `tenant_id` before querying the Knowledge Base. |
| **4. Data Persistence** | DynamoDB (On-demand) | Stores document metadata (PK=`tenant_id`, SK=`sk`(docs_id)). Optimizes cost and speed for key-value queries. |
| **5. Object Storage** | S3 Bucket (Multi-tenant prefix) | Stores original document files with a `tenant_id/` prefix, Block Public Access enabled. |
| **6. Network** | VPC + VPC Endpoints | Isolates DB (not public-facing); uses Endpoints to call AWS services without NAT Gateway costs. |
| **7. Identity** | Cognito + IAM Least-privilege | IAM role only grants Read/Write to specific buckets/tables. Cognito issues JWTs to isolate tenants. |

**Chosen Optional Capability:** **Advanced Security (#10)** - KMS CMK encryption for S3 and DynamoDB, with Key Rotation enabled.

---

## 4. Cost Discipline

**Cost Explorer Charts (Filtered by `Team=G1` tag):**

1. **Day 1 EOD:**
![Cost Day 1](../assets/cost_day1.png)[cite: 3, 4]

1. **Day 2 EOD:**
![Cost Day 2](../assets/cost_day2.png)[cite: 3, 4]

1. **Friday Morning (Pre-demo):**
![Cost Demo](../assets/cost_demo.png)[cite: 3, 4]

* **Total 48h Spend:** `$1.77`[cite: 1, 4]
* **Top 3 Cost Drivers:**[cite: 4]
  1. **VPC Interface Endpoints:** `$1.25` (2 endpoints x $0.013/hr x 48h) to securely call Bedrock and Secrets Manager[cite: 1, 4].
  2. **Bedrock AI Invocations:** `$0.28` (Haiku retrieve + generate for testing)[cite: 4].
  3. **KMS CMK:** `$0.07` (Prorated 48h fee for 1 key)[cite: 1, 4].
* **Observation:** Fixed infrastructure costs (Endpoints) account for the majority of the spend compared to actual AI invocations[cite: 4]. By avoiding a NAT Gateway, the team saved approximately ~$2.83 over 48 hours[cite: 1].

---

## 5. Security (Advanced Security Option + Mandatory Identity)

### 5a. Identity & Access — Cognito JWT (Mandatory #7)

The team implemented full Cognito User Pool authentication with JWT-based tenant isolation:

| Attribute | Value |
| :--- | :--- |
| **User Pool ID** | `us-west-2_K0TYLG8fa` |
| **App Client** | `DocHub` (`1uh766250hjcjmfum1hmapcbim`) |
| **Custom Domain** | `https://docs4hub.tech` (ACM cert — Bonus Path C) |
| **Auth Flow** | Authorization Code Grant → `id_token` JWT issued to frontend |
| **Social IdP** | Google OAuth 2.0 (federated via OIDC; `email` + `sub` mapped) |
| **Sign-in options** | Email + Password · Sign in with Google |
| **Custom attribute** | `custom:tenant_id` (String, mutable) — stamped on every user, extracted from JWT claims by Lambda to scope all document queries |
| **Email verification** | Required before first sign-in (Cognito-assisted confirmation) |
| **Token revocation** | Enabled — invalidates refresh tokens on logout |
| **MFA** | Disabled (accepted trade-off — see §6.5 Decision 3) |
| **Self-service recovery** | Email only |

**How JWT enforces multi-tenancy end-to-end:**
1. User logs in → Cognito issues `id_token` with `custom:tenant_id` claim embedded
2. Frontend sends `Authorization: Bearer <id_token>` on every API request
3. API Gateway JWT Authorizer validates the token signature against Cognito's JWKS endpoint (`https://cognito-idp.us-west-2.amazonaws.com/us-west-2_K0TYLG8fa/.well-known/jwks.json`)
4. Lambda reads `tenant_id` from the validated claims — never trusts the client header alone
5. Vector store search and DynamoDB queries are both filtered by this `tenant_id` (defense in depth)

![Cognito User Pool Overview](../assets/cognito_userpool.png)
![App Client DocHub](../assets/cognito_app_client.png)
![Custom Attribute tenant_id](../assets/cognito_group_for_tenant.png)
![Google Identity Provider](../assets/cognito_google_idp.png)
![Hosted Login Page at docs4hub.tech](../assets/cognito_login_page.png)

---

### 5b. Advanced Security — KMS CMK + Key Rotation (Optional #10)
The team implemented a deep security strategy alongside the mandatory IAM least-privilege[cite: 4]:

* **IAM & Least-privilege:** Lambda Execution Role is strictly scoped to specific resources, with no `*` wildcards[cite: 4].
![IAM Least Privilege Policy](../assets/iam_least_privilege.png)[cite: 4]

* **KMS CMK (Encryption at rest) & Key Rotation:** Created a Customer Managed Key to encrypt S3 buckets/DynamoDB and enabled automatic key rotation[cite: 4].
![KMS Key Rotation Enabled](../assets/kms_rotation_enabled.png)[cite: 4]

---

## 6. Monitoring & Pre-flight
The system fully complies with all Pre-flight check requirements[cite: 4]:

* **Budget Alert:** Configured SNS to send an email when costs exceed `$80` (80% of the `$100` cap), email subscription confirmed[cite: 1, 3, 4].
![Budget Alert Confirmed](../assets/budget_alert.png)[cite: 4]

* **Cost Anomaly Detection:** Monitor enabled since prep days[cite: 3, 4].
![Cost Anomaly Enabled](../assets/cost_anomaly.png)[cite: 4]

---

## 6.5 Measurement & Decisions (Crucial Section)

**DECISION 1: Use S3 Vectors as the Bedrock KB Vector Store instead of OpenSearch Serverless.**[cite: 4]

* **ALTERNATIVES CONSIDERED:**
  * OpenSearch Serverless — Eliminated because: The minimum baseline cost is 2 OCUs, roughly `$27.65` for 48 hours in ap-southeast-1, consuming nearly 29% of the budget and jeopardizing Bonus Path H (under `$30`)[cite: 1, 4].
* **MEASUREMENT:**
  * S3 Vectors fixed OCU cost = `$0`[cite: 4].
  * Total actual storage + query cost (50 queries) measured via Cost Explorer = `$0.01`[cite: 1, 4].
* **EVIDENCE:**
![S3 Vectors Cost](../assets/cost_explorer_s3vectors.png)[cite: 4]
* **TRADE-OFF ACCEPTED:**
  * S3 Vectors lacks the complex query customization and advanced metadata filtering capabilities found in OpenSearch Serverless[cite: 1, 4].

**DECISION 2: Handle Multi-tenant Filtering using a Bedrock Agent Tool instead of direct KB Metadata Filtering.**[cite: 4]

* **ALTERNATIVES CONSIDERED:**
  * Direct Bedrock KB (Retrieve) without Agent — Eliminated because: It lacks flexible pre-retrieval filtering logic, making it difficult to enforce strict tenant authorization and increasing the risk of cross-tenant data leakage[cite: 4].
* **MEASUREMENT:**
  * "Wrong-document return" rate (tenant A's document returned to tenant B) = `0%` (0/20 test queries) after wrapping the logic in a Lambda action group[cite: 4].
* **EVIDENCE:**
![Agent Latency and Flow](../assets/agent_latency_cloudwatch.png)[cite: 4]
* **TRADE-OFF ACCEPTED:**
  * Incurred additional InvokeAgent costs and higher system latency compared to standard InvokeModel calls, accepting this to guarantee absolute tenant isolation at the application logic layer[cite: 4].

**DECISION 3: Use Cognito User Pool with Google OAuth + `custom:tenant_id` attribute for multi-tenant identity, instead of hardcoded test users or header-only auth.**

* **ALTERNATIVES CONSIDERED:**
  * Hardcoded test user (`X-Tenant-Id` header, no real auth) — Eliminated because: any client can spoof the header value, meaning a malicious user of tenant-A could set `X-Tenant-Id: tenant-B` and read their documents. No verifiable identity = cross-tenant data leakage risk, which is the #1 threat for a multi-tenant SaaS.
  * IAM-only access (signed URLs per tenant) — Eliminated because: generating and rotating per-tenant IAM credentials does not scale and adds key management overhead with no UX benefit over Cognito Groups.
  * Cognito without Google OAuth (email/password only) — Eliminated because: adding Google federated sign-in cost zero extra setup time (OIDC mapping: `email→email`, `sub→username`) and reduces friction for real users; trainers can log in without creating a new account.

* **MEASUREMENT:**
  * Cross-tenant leakage rate in 20 manual test queries = `0%` — `tenant_id` extracted from JWT claim, not header, so spoofing is blocked at the token validation layer (API Gateway JWT Authorizer).
  * 7 test users confirmed working (5 email/password + 2 Google OAuth) — visible in Cognito console.
  * JWT → `tenant_id` claim extraction latency overhead = `~0 ms` (in-memory claim parsing inside Lambda, no extra AWS API call).
  * Cognito cost for < 50K MAU = `$0` (free tier; does not affect Bonus Path H eligibility).

* **EVIDENCE:**
  * `../assets/cognito_userpool.png` — User Pool overview (7 users, created May 27)
  * `../assets/cognito_group_for_tenant.png` — `custom:tenant_id` attribute defined on User Pool
  * `../assets/cognito_google_idp.png` — Google provider with `email` + `sub` attribute mapping
  * `../assets/cognito_login_page.png` — Hosted UI at `https://docs4hub.tech` showing Google + email sign-in

* **TRADE-OFF ACCEPTED:**
  * MFA is **disabled** (`No MFA` enforcement). For legal/compliance users in production, TOTP MFA would be mandatory. For the 48h hackathon demo, the friction of requiring a TOTP app during trainer testing outweighs the security gain. Noted as a Phase 2 requirement.
  * Google OAuth requires maintaining a live Google Cloud OAuth app client secret. If the secret rotates or the Google project is suspended post-demo, login breaks. Accepted for hackathon scope; Secrets Manager rotation would be the production fix.

---

## 7. Lessons Learned
After 48 hours of building a multi-tenant document system, the team learned two major lessons[cite: 4]:

1. **Document Confusion is a severe problem:** Similar to what Harvey AI engineers faced, our AI initially cited clauses from older contracts frequently[cite: 4]. Configuring strict Metadata Filtering (`tenant_id`) on the Knowledge Base is absolutely mandatory to solve this[cite: 4].
2. **Hidden network architecture costs:** The team almost deployed a NAT Gateway (which would cost ~$2.83/48h), but ultimately decided to use VPC Interface/Gateway Endpoints (saving significant budget)[cite: 1, 4]. Next time, the team will thoroughly review network components during the design phase.

---

## 8. Teardown Plan (Deadline: Sun 1/6 EOD)
The team will delete resources in the following exact order to avoid dependency errors[cite: 3, 4]:

1. Delete CloudFormation stacks (if IaC was used)[cite: 3].
2. Delete Lambda functions and API Gateway (Stages & APIs)[cite: 3].
3. Delete Bedrock Agent and Knowledge Base[cite: 3].
4. Empty S3 Buckets (must be emptied before deletion), then Delete Buckets[cite: 3].
5. Delete DynamoDB table.
6. Delete Cognito User Pool[cite: 3].
7. Schedule deletion for KMS CMK (requires at least a 7-day waiting period)[cite: 3].
8. Delete CloudWatch dashboards, alarms, and log groups[cite: 3].
9. Delete VPC last: Subnets -> Security Groups -> Route Tables -> VPC[cite: 3].

*(We will commit the file `docs/teardown_confirmed.png` showing an empty Cost Explorer on Monday, June 2nd to fulfill this requirement)*[cite: 3, 4].