## JWT Authentication & Tenant Isolation Architecture

For the DocHub capstone, strict multi-tenant data isolation is the critical security property of the system. To guarantee that a bug in the handler code cannot leak cross-tenant data, we implemented a highly secure identity pipeline using Amazon Cognito, API Gateway, and FastAPI with Mangum.

Because identity is non-trivial and we needed a way to securely populate the tenant ID without relying on easily spoofed client headers, we chose an **Application Compute Extraction** approach.

Process overview:
![alt text](image-3.png)

### 1. Cognito Pre-Token Generation Lambda
![alt text](image-7.png)
![alt text](image-9.png)

`custom:tenant_id` is defined as a mutable string attribute. Email is required and Cognito-managed verification is enabled for sign-up. The custom attribute is useful for admin workflows, reporting, or as an additional user metadata source. 

![alt text](image-5.png)

We organize users into Cognito Groups (for example, `tenant-acme` and `tenant-globex`).
![alt text](image.png)
![alt text](image-1.png)
![alt text](image-2.png)

> Note: In our application, one user can belong to multiple `tenant` groups.
![Cognito Sign-up screenshot](image-4.png)

Instead of **relying on the client to declare its tenant**, we use a **Cognito Pre-Token Generation Lambda trigger**. That way, the issued ID token carries a trusted, server-controlled tenant identity claim instead of relying on client-supplied headers.
```python
import json

def lambda_handler(event, context):
    groups = (
        event.get("request", {})
        .get("groupConfiguration", {})
        .get("groupsToOverride", [])
    )
    if groups:
        event["response"]["claimsOverrideDetails"] = {
            "claimsToAddOrOverride": {
                "cognito:groups": ",".join(groups)
            }
        }
    return event
```

This Lambda runs during Cognito’s Pre-Token Generation trigger. 
![alt text](image-6.png)
It reads the user’s resolved Cognito groups from the login event, and if groups exist it adds or overrides the `cognito:groups` claim in the token response.

### 2. API Gateway Validation
The `dochub-http-api` routes configured with the `Dochub-Cognito-JWT-Authorizer`.
![API Gateway route authorization configuration](image-11.png)

Protected routes include `/upload`, `/query`, and `/docs/list`, while the health endpoint can remain open or use a separate policy. This demonstrates that authorization is enforced at the API route level, before the request reaches the backend.
![JWT authorizer details for DocHub-Cognito-JWT-Authorizer](image-10.png)

- The authorizer is a **JWT** authorizer with identity source set to `$request.header.Authorization`.
- The audience is the Cognito app client ID used by the frontend.
![alt text](image-12.png)
- No authorization scopes are required for these routes, so token validity alone is sufficient for access.

When the frontend sends an API request (for example, `/upload` or `/query`), it includes the JWT in the `Authorization: Bearer` header.
- API Gateway uses a **JWT Authorizer** to mathematically verify the token's signature against our Cognito User Pool.
- **Architectural Decision:**
  - We deliberately bypassed API Gateway's Parameter Mapping layer. API Gateway's mapping expression throws an `Invalid mapping expression specified` error when trying to parse claims containing a colon (like `cognito:groups`).
  - Instead, API Gateway validates the token and securely forwards the _raw, verified event payload_ directly to the backend.

### 3. FastAPI & Mangum Extraction

To read the verified token inside our backend, we use the `mangum` adapter, which wraps the FastAPI application to run on AWS Lambda.

- **Mangum** takes the raw AWS API Gateway event - which includes the fully decoded and validated JWT claims dictionary - and passes it into the FastAPI application context.
- Because standard Python dictionaries have no limitations on string keys with colons, our FastAPI backend seamlessly extracts `claims.get("cognito:groups")` to determine the exact `tenant_id`.
- The backend then uses this verified `tenant_id` to enforce strict isolation at the DynamoDB metadata layer and Bedrock vector store filtering layer.

### Why We Chose This Approach (Trade-offs)

- **Security First:** The FastAPI backend never has to guess if the user is spoofing an `x-tenant-id` HTTP header. It strictly trusts the claims verified by API Gateway.
- **Flexibility:** By handling the token extraction directly in the application compute layer (FastAPI), we successfully bypass API Gateway's rigid naming limitations while maintaining absolute tenant isolation.

### Summary
- This architecture ensures tenant identity is derived from a secure, Cognito-sanctioned source rather than untrusted request metadata. 
- The combination of Cognito Pre-Token Generation, API Gateway JWT validation, and Mangum-backed FastAPI extraction creates a robust pipeline where tenant isolation is enforced before any data access logic executes.
