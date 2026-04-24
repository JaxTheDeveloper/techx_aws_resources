# W3 Evidence — API Gateway Layer
> Covers: API Gateway Deployment · Route Configurations · IAM Authorizer · Serverless Glue Triggers

---

## Section 5 & 7 — API Gateway Evidence

### 5.1 & 7.1 API Gateway Integration (Serverless Glue)

**Acceptance criterion:** HTTP API deployed to a `prod` stage, IAM authorizer attached to all routes, Invoke URL live. At least one trigger is demonstrated live: an API Gateway integration (HTTP call invokes the Lambda function).

**Screenshot 1 — API Gateway core routes and integrations**
![API Gateway Configuration and Lambda Integrations](images/api_gateway/apigateway_routes.png)

**Screenshot 2 — API Gateway prod stage details and IAM authorizers**
![API Gateway Stage and Route Authorizers](images/api_gateway/apigateway_stage_auth.png)

**Configuration notes:**
- **API Deployment:** API is successfully deployed. **Automatic Deployment** is Enabled, meaning any change to the API configuration triggers a redeploy to the `prod` stage automatically.
- **Stage Deployment:** Deployed to `prod` stage. No Stage Variables are set; environment-specific configurations (e.g., Lambda ARNs) are injected securely via Lambda environment variables instead.
- **IAM Authorizer:** The `IAM (built-in)` authorizer is attached properly to all core routes (e.g., `POST /aggregate`, `POST /chat`, `GET /telemetry`).  
- **Trigger Demonstrated:** HTTP calls securely invoke the backend Lambda functions. The API Gateway acts as the necessary serverless glue that seamlessly connects the application tier to the Bedrock AI and database layers.
- **Security Check:** All routes strictly require a valid AWS SigV4-signed request. 
- **Negative Security Test:** Any unauthenticated or improperly signed calls receive a `403 Forbidden` response. This behavior explicitly fulfills the negative security testing conditions for the W3 requirements, ensuring external/unauthorized traffic is blocked at the Gateway.
